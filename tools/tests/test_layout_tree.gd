extends SceneTree
## Node-tree golden test for both layouts: the whole tree the builders make
## (types, names, stored properties, theme overrides with their styleboxes and
## fonts, meta, signal connections) must match the checked-in snapshot.
## It exists so the builders can be moved or refactored and proven unchanged.
##
##   Godot --headless --path . --script tools/tests/test_layout_tree.gd [-- --mobile-ui] [--update]
##
## Without --mobile-ui the suite also runs itself once with it. --update
## rewrites the snapshot; review the diff before committing it.
##
## Computed layout (size, position, offsets inside containers) and the voice
## list are left out: they depend on the machine's fonts and installed voices,
## not on what the builder wrote.

const GOLDEN_DIR := "res://tools/tests/golden/"
const SKIP_PROPS := ["script", "size", "position", "global_position", "rotation", "scale", "pivot_offset",
		"scroll_horizontal", "scroll_vertical", "value", "min_value", "max_value", "page", "ratio"]
const SKIP_PREFIX := ["popup/", "item_", "metadata/"]
const CONTAINER_COMPUTED := ["offset_left", "offset_top", "offset_right", "offset_bottom",
		"anchor_left", "anchor_top", "anchor_right", "anchor_bottom", "layout_mode", "anchors_preset", "grow_horizontal", "grow_vertical"]

var failures: Array[String] = []
var checks := 0
var main: Node
var mobile := false


func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func _initialize() -> void:
	mobile = "--mobile-ui" in OS.get_cmdline_user_args()
	var update := "--update" in OS.get_cmdline_user_args()
	var layout := "mobile" if mobile else "desktop"
	print("=== layout tree (%s) ===" % layout)
	main = load("res://scenes/main.tscn").instantiate()
	main.audio_cfg_path = "user://test_layout_tree_audio.cfg"
	# Dumped from the ready signal, before any frame is processed: the entrance
	# and pulse tweens have not stepped yet, so animated values are still the
	# ones the code wrote.
	var lines := PackedStringArray()
	main.ready.connect(func(): _dump(main, 0, lines), CONNECT_ONE_SHOT)
	root.add_child(main)
	while lines.is_empty():
		await process_frame
	var text := "\n".join(lines) + "\n"
	var path := GOLDEN_DIR + "layout_tree_%s.txt" % layout
	if update:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(GOLDEN_DIR))
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(text)
		f.close()
		print("  wrote %s (%d lines)" % [path, lines.size()])
	else:
		check(FileAccess.file_exists(path), "snapshot %s exists (run with --update to create it)" % path)
		if FileAccess.file_exists(path):
			_compare(FileAccess.get_file_as_string(path).split("\n"), text.split("\n"))
	var child_ok := true
	if not mobile:
		child_ok = _run_mobile_child(update)
	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	print("RESULT: ", "PASS" if failures.is_empty() and child_ok else "FAIL")
	quit(0 if failures.is_empty() and child_ok else 1)


func _compare(want: PackedStringArray, got: PackedStringArray) -> void:
	check(want.size() == got.size(), "tree dump has %d lines, snapshot %d" % [got.size(), want.size()])
	var shown := 0
	for i in mini(want.size(), got.size()):
		if want[i] != got[i]:
			check(false, "line %d differs:\n      want: %s\n      got:  %s" % [i + 1, want[i].strip_edges(), got[i].strip_edges()])
			shown += 1
			if shown >= 8:
				print("  (further differences not shown)")
				return
	check(true, "tree matches snapshot")


func _dump(node: Node, depth: int, out: PackedStringArray) -> void:
	var pad := "  ".repeat(depth)
	var script: Script = node.get_script()
	out.append("%s%s <%s>%s" % [pad, node.name, node.get_class(), " " + script.resource_path if script != null else ""])
	var in_container := node.get_parent() is Container
	for p in node.get_property_list():
		var pname: String = p["name"]
		if not (int(p["usage"]) & PROPERTY_USAGE_STORAGE) or pname in SKIP_PROPS:
			continue
		if in_container and pname in CONTAINER_COMPUTED:
			continue
		if _skipped_prefix(pname) or _is_default(node, pname):
			continue
		out.append("%s  .%s = %s" % [pad, pname, _fmt(node.get(pname), 0)])
	for m in node.get_meta_list():
		out.append("%s  meta %s = %s" % [pad, m, _fmt(node.get_meta(m), 0)])
	for sig in node.get_signal_list():
		for c in node.get_signal_connection_list(sig["name"]):
			out.append("%s  on %s -> %s" % [pad, sig["name"], _fmt_callable(c["callable"])])
	for child in node.get_children():
		_dump(child, depth + 1, out)


var _defaults := {}

## True when the value is what a fresh instance of the engine class has. Only
## plain engine values are compared; objects are always written out.
func _is_default(obj: Object, pname: String) -> bool:
	var cls := obj.get_class()
	if not _defaults.has(cls):
		var fresh = ClassDB.instantiate(cls) if ClassDB.can_instantiate(cls) else null
		var values := {}
		if fresh != null:
			for p in fresh.get_property_list():
				if int(p["usage"]) & PROPERTY_USAGE_STORAGE:
					values[p["name"]] = fresh.get(p["name"])
			if fresh is Node:
				fresh.free()
		_defaults[cls] = values
	var d: Dictionary = _defaults[cls]
	if not d.has(pname):
		return false
	var v = obj.get(pname)
	if v is Object or d[pname] is Object:
		return v == null and d[pname] == null
	return typeof(v) == typeof(d[pname]) and v == d[pname]


func _skipped_prefix(pname: String) -> bool:
	for pre in SKIP_PREFIX:
		if pname.begins_with(pre):
			return true
	return false


func _fmt_callable(c: Callable) -> String:
	var target := "?"
	if c.is_custom():
		return "lambda"
	var obj := c.get_object()
	if obj == main:
		target = "main"
	elif obj is Node and main.is_ancestor_of(obj):
		target = str(main.get_path_to(obj))
	elif obj != null:
		target = obj.get_class()
	var bound := c.get_bound_arguments()
	var args := ""
	if not bound.is_empty():
		var parts := PackedStringArray()
		for a in bound:
			parts.append(_fmt(a, 2))
		args = "(" + ", ".join(parts) + ")"
	return "%s.%s%s" % [target, c.get_method(), args]


func _fmt(v, depth: int) -> String:
	if v is Callable:
		return _fmt_callable(v)
	if v is Node:
		return "node:" + (str(main.get_path_to(v)) if main.is_ancestor_of(v) or v == main else v.get_class())
	if v is Object:
		if v == null:
			return "null"
		if depth >= 3:
			return "<%s>" % v.get_class()
		var parts := PackedStringArray()
		for p in v.get_property_list():
			var pname: String = p["name"]
			if not (int(p["usage"]) & PROPERTY_USAGE_STORAGE) or pname in ["script", "resource_path", "resource_name", "resource_local_to_scene"]:
				continue
			if pname.begins_with("metadata/") or _is_default(v, pname):
				continue
			var value = v.get(pname)
			if value is Object and v is Texture2D:
				continue
			parts.append("%s=%s" % [pname, _fmt(value, depth + 1)])
		if v is Texture2D:
			parts.append("size=%s" % str((v as Texture2D).get_size()))
		return "%s{%s}" % [v.get_class(), ", ".join(parts)]
	if v is Array:
		var parts := PackedStringArray()
		for x in v:
			parts.append(_fmt(x, depth + 1))
		return "[" + ", ".join(parts) + "]"
	if v is Dictionary:
		var parts := PackedStringArray()
		for k in v:
			parts.append("%s: %s" % [str(k), _fmt(v[k], depth + 1)])
		return "{" + ", ".join(parts) + "}"
	if v is PackedByteArray:
		return "bytes[%d]" % v.size()
	return var_to_str(v).replace("\n", "\\n")


func _run_mobile_child(update: bool) -> bool:
	var args := ["--headless", "--path", ".", "--script", "tools/tests/test_layout_tree.gd", "--", "--mobile-ui"]
	if update:
		args.append("--update")
	var out: Array = []
	var code := OS.execute(OS.get_executable_path(), args, out, true)
	var text := ""
	for chunk in out:
		text += str(chunk)
	for line in text.split("\n"):
		if line.contains("FAIL:") or line.contains("want:") or line.contains("got:") or line.begins_with("checks:") or line.contains("===") or line.contains("wrote"):
			print("  [mobile] " + line.strip_edges())
	return code == 0
