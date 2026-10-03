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
	var colours := 0
	for name in consts:
		var value = consts[name]
		if value is Color:
			colours += 1
			var key: String = (value as Color).to_html(true)
			check(not seen.has(key), "%s duplicates %s (%s): one name per value" % [name, seen.get(key, ""), key])
			seen[key] = name
		elif value is Array:
			check(name.begins_with("GRAD_") and value.size() == 2 and value[0] is Color and value[1] is Color,
					"%s: gradient tokens are GRAD_ [from, to] colour pairs" % name)
		else:
			check((value is int or value is float) and value >= 0, "%s: a design token is a colour, a colour pair or a non-negative number" % name)
	check(colours >= 100, "palette has every colour the screens use (%d)" % colours)

	print("=== tokens ===")
	check(AppTheme.SPACE_XS < AppTheme.SPACE_SM and AppTheme.SPACE_SM < AppTheme.SPACE_MD \
			and AppTheme.SPACE_MD < AppTheme.SPACE_LG and AppTheme.SPACE_LG < AppTheme.SPACE_XL, "spacing scale ascends")
	check(AppTheme.TYPE_MICRO < AppTheme.TYPE_META and AppTheme.TYPE_META < AppTheme.TYPE_CAPTION \
			and AppTheme.TYPE_CAPTION < AppTheme.TYPE_BODY_SM and AppTheme.TYPE_BODY_SM < AppTheme.TYPE_BODY \
			and AppTheme.TYPE_BODY < AppTheme.TYPE_BODY_LG and AppTheme.TYPE_BODY_LG < AppTheme.TYPE_HEADING \
			and AppTheme.TYPE_HEADING < AppTheme.TYPE_TITLE and AppTheme.TYPE_TITLE < AppTheme.TYPE_DISPLAY, "type scale ascends")
	check(AppTheme.ELEVATION_FLAT < AppTheme.ELEVATION_REST and AppTheme.ELEVATION_REST < AppTheme.ELEVATION_CARD \
			and AppTheme.ELEVATION_CARD < AppTheme.ELEVATION_FLOAT, "elevation levels ascend")
	check(AppTheme.RADIUS_INNER < AppTheme.RADIUS, "inner radius nests inside the surface radius")
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
	check(not ring.draw_center and ring.border_width_top == 2 and ring.corner_radius_top_left == 6, "focus ring outline only")
	check(ring.expand_margin_left == 3.0, "focus ring sits outside the control")
	var font := AppTheme.ui_font(700)
	check(font.font_weight == 700 and font.font_names[0] == "Segoe UI", "ui_font weight and family")
	check(AppTheme.ui_font().font_weight == 500, "ui_font default weight")
	var desktop := PackedStringArray(["Segoe UI", "SF Pro Display", "Inter", "Roboto", "Helvetica Neue", "Arial", "sans-serif"])
	check(AppTheme.ui_font_names("Windows", "") == desktop, "Windows keeps the font list as is")
	check(AppTheme.ui_font_names("Android", "") == desktop, "Android keeps the font list as is")
	var mac := AppTheme.ui_font_names("macOS", "")
	check(mac[0] == "Segoe UI" and mac[1] == ".AppleSystemUIFont" and mac.slice(2) == desktop.slice(1),
		"macOS asks for its system UI font right after Segoe UI: %s" % str(mac))
	check(AppTheme.ui_font_names("Windows", "Arial")[0] == "Arial", "NEC_UI_FONT puts the forced font first (layout checks)")
	check(AppTheme.monospace_font().font_names[0] == "Consolas", "monospace_font family")
	var card := AppTheme.surface(AppTheme.SURFACE_BOTTOM, AppTheme.HAIRLINE, AppTheme.ELEVATION_CARD)
	check(card.shadow_size == AppTheme.ELEVATION_CARD and card.shadow_color == AppTheme.SHADOW_CARD, "surface elevation sets the shadow")
	check(card.corner_radius_top_left == AppTheme.RADIUS and card.border_width_top == AppTheme.BORDER_HAIRLINE, "surface radius and hairline")
	check(AppTheme.meta_font().spacing_glyph == AppTheme.TRACKING_META, "meta font is tracked")
	check(AppTheme.numeric_font().opentype_features.size() == 1, "numeric font turns on tabular figures")
	var primary := Button.new()
	AppTheme.style_primary_button(primary)
	var ghost := Button.new()
	AppTheme.style_ghost_button(ghost)
	for b: Button in [primary, ghost]:
		var normal := b.get_theme_stylebox("normal")
		for state in ["hover", "disabled"]:
			check(is_equal_approx(b.get_theme_stylebox(state).get_margin(SIDE_LEFT), normal.get_margin(SIDE_LEFT)), "button %s keeps the normal content box" % state)
		b.free()

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
