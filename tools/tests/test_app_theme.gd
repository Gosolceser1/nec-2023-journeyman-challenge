extends SceneTree
## AppTheme: the palette is the only place colour values live, one name per
## value, and the style/font factories build what the screens expect.

var failures: Array[String] = []
var checks := 0

func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func _init() -> void:
	print("=== palette ===")
	var consts: Dictionary = (AppTheme as Script).get_script_constant_map()
	var seen := {}
	for name in consts:
		var value = consts[name]
		check(value is Color, "%s is a Color" % name)
		if value is Color:
			var key: String = (value as Color).to_html(true)
			check(not seen.has(key), "%s duplicates %s (%s): one name per value" % [name, seen.get(key, ""), key])
			seen[key] = name
	check(consts.size() >= 100, "palette has every colour the screens use (%d)" % consts.size())
	# The look the screenshots are judged against.
	check(AppTheme.SKY_400 == Color("38bdf8"), "accent cyan is 38bdf8")
	check(AppTheme.BG_TOP == Color("020408") and AppTheme.BG_BOTTOM == Color("08101e"), "slate background gradient")
	check(AppTheme.EMERALD_400 == Color("34d399") and AppTheme.RED_500 == Color("ef4444"), "right/wrong colours")

	print("=== no colour literals outside AppTheme ===")
	var hex := RegEx.create_from_string("\"#?[0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?\"")
	for path in _gd_files("res://src"):
		if path.ends_with("/app_theme.gd"):
			continue
		var n := 0
		for line in FileAccess.get_file_as_string(path).split("\n"):
			if not line.strip_edges().begins_with("#") and hex.search(line) != null:
				n += 1
		check(n == 0, "%s has %d quoted hex colour(s); name them in AppTheme" % [path, n])

	print("=== factories ===")
	var box := AppTheme.panel_style(AppTheme.SLATE_900, AppTheme.SKY_400, 2, 9)
	check(box.bg_color == AppTheme.SLATE_900 and box.border_color == AppTheme.SKY_400, "panel_style colours")
	check(box.border_width_left == 2 and box.border_width_bottom == 2, "panel_style border width")
	check(box.corner_radius_top_left == 9 and box.corner_radius_bottom_right == 9, "panel_style radius")
	var ring := AppTheme.focus_ring(6)
	check(not ring.draw_center and ring.border_width_top == 1 and ring.corner_radius_top_left == 6, "focus ring outline only")
	check(ring.expand_margin_left == 2.0, "focus ring sits outside the control")
	var font := AppTheme.ui_font(700)
	check(font.font_weight == 700 and font.font_names[0] == "Segoe UI", "ui_font weight and family")
	check(AppTheme.ui_font().font_weight == 500, "ui_font default weight")
	check(AppTheme.monospace_font().font_names[0] == "Consolas", "monospace_font family")

	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)


func _gd_files(dir: String) -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_gd_files(dir.path_join(d)))
	return out
