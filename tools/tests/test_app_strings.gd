extends SceneTree
## Screen text that names the NEC edition comes from data/edition.json (Edition),
## so switching editions is a data change:
##   - no shipped script writes the edition label in a string literal
##   - with a different edition loaded in memory, the header title, the menu
##     hero and the report headers name that edition
##
##   Godot --headless --path . --script tools/tests/test_app_strings.gd [-- --mobile-ui]
##
## Without --mobile-ui the suite also runs itself once with it.

var FAKE_EDITION := {"year": 2032, "short": "NEC 2032", "long": "NFPA 70, National Electrical Code, 2032 Edition", "dir": ""}

var failures: Array[String] = []
var checks := 0
var tag := "desktop"


func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: [%s] %s" % [tag, label])


func _initialize() -> void:
	var mobile := "--mobile-ui" in OS.get_cmdline_user_args()
	tag = "mobile" if mobile else "desktop"
	print("=== app strings (%s) ===" % tag)
	if not mobile:
		_no_edition_literals()
	var shipped := Edition.short_label()
	FAKE_EDITION["dir"] = str(Edition.data().get("dir", ""))
	Edition._data = FAKE_EDITION.duplicate()
	await _edition_on_screen(shipped)
	var child_ok := true
	if not mobile:
		child_ok = _run_mobile_child()
	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	print("RESULT: ", "PASS" if failures.is_empty() and child_ok else "FAIL")
	quit(0 if failures.is_empty() and child_ok else 1)


func _no_edition_literals() -> void:
	var labels := [Edition.short_label(), Edition.short_label().to_upper(), Edition.long_label()]
	var hits := PackedStringArray()
	for path in _scripts("res://src"):
		var n := 0
		for line in FileAccess.get_file_as_string(path).split("\n"):
			n += 1
			var code := line.strip_edges()
			if code.begins_with("#"):
				continue
			for l in labels:
				if l != "" and (code.contains("\"" + l) or code.contains(l + "\"")):
					hits.append("%s:%d" % [path, n])
	check(hits.is_empty(), "no script under src/ writes the edition label in a string: %s" % ", ".join(hits))


func _scripts(dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_scripts(dir.path_join(d)))
	return out


func _edition_on_screen(shipped: String) -> void:
	var main: Main = load("res://scenes/main.tscn").instantiate()
	main.audio_cfg_path = "user://test_app_strings_audio.cfg"
	main.session.bag_path = ""
	root.add_child(main)
	for i in 3:
		await process_frame
	var short := str(FAKE_EDITION["short"])
	var title_key := "title_short" if main.ui_mobile else "title"
	var want_title := MenuModel.fill(str(MenuModel.spec().get(title_key, "")), {"edition": short})
	check(want_title.begins_with(short), "menu title template starts with the edition (%s)" % want_title)
	var titles := _labels_with(main, want_title, false)
	check(titles >= 2, "header title and menu hero read '%s' (%d labels)" % [want_title, titles])
	check(_labels_with(main, shipped, true) == 0, "no label names %s while another edition is loaded" % shipped)
	check(ResultsView.standards_label() == short.to_upper() + " STANDARDS", "report header names the edition")
	main._start_quiz(1, main._practice_time(1), true, "Edition check")
	await process_frame
	ResultsView.show(main)
	check(main.article_label.text.ends_with(short.to_upper() + " STANDARDS"), "practice report header: %s" % main.article_label.text)
	ResultsView.show_listen(main)
	check(main.article_label.text.ends_with(short.to_upper() + " STANDARDS"), "listen summary header: %s" % main.article_label.text)
	main.queue_free()
	await process_frame


## Labels whose text is (or, with partial, contains) text.
func _labels_with(node: Node, text: String, partial: bool) -> int:
	var n := 0
	if node is Label:
		var t := (node as Label).text
		n = 1 if t == text or partial and t.contains(text) else 0
	for c in node.get_children():
		n += _labels_with(c, text, partial)
	return n


func _run_mobile_child() -> bool:
	var out: Array = []
	var code := OS.execute(OS.get_executable_path(),
			["--headless", "--path", ".", "--script", "tools/tests/test_app_strings.gd", "--", "--mobile-ui"], out, true)
	var text := ""
	for chunk in out:
		text += str(chunk)
	for line in text.split("\n"):
		if line.contains("FAIL:") or line.begins_with("checks:"):
			print("  [mobile] " + line.strip_edges())
	return code == 0
