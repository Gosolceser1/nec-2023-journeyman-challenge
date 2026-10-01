extends SceneTree
## Hover tips: the engine default was a 50% black, borderless panel in Open
## Sans at ~12 px with no wrap, so on the navy menu the tip read as loose text
## over the tile beneath (often repeating it). Tooltip gives a solid panel,
## the UI font at >= 14 px on screen, wrapping and a bold title; tiles show a
## tip only when it adds to what they show; phones show none.
##
##   Godot --headless --path . --script tools/tests/test_tooltips.gd [-- --mobile-ui]
##
## Without --mobile-ui the suite also runs itself once with it.

var failures: Array[String] = []
var checks := 0
var main: Main


func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func _wait(sec: float) -> void:
	await create_timer(sec).timeout
	await process_frame


func _initialize() -> void:
	var mobile := "--mobile-ui" in OS.get_cmdline_user_args()
	if not mobile:
		_check_theme()
		await _check_builder()
		_check_wrap()
	print("=== in the app (%s) ===" % ("mobile" if mobile else "desktop"))
	main = load("res://scenes/main.tscn").instantiate()
	main.audio_cfg_path = "user://test_tooltips_audio.cfg"
	main.session.bag_path = ""
	root.add_child(main)
	await _wait(0.8)
	if mobile:
		_check_mobile()
	else:
		await _check_desktop()
	main.queue_free()
	await _wait(0.1)
	if not mobile:
		check(_run_mobile_child(), "mobile run passes")
	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)


func _check_theme() -> void:
	print("=== theme ===")
	var t := Tooltip.theme()
	var sb := t.get_stylebox("panel", "TooltipPanel") as StyleBoxFlat
	check(sb != null, "TooltipPanel has a StyleBoxFlat, not the engine default")
	if sb == null:
		return
	check(sb.bg_color.a >= 0.9, "panel is solid (alpha %.2f, engine default 0.5)" % sb.bg_color.a)
	check(sb.bg_color.get_luminance() < 0.1, "panel is dark")
	check(sb.border_width_top >= 1 and sb.border_color.a > 0.2, "panel has a visible border")
	check(sb.corner_radius_top_left >= 4, "panel has rounded corners")
	check(sb.shadow_size > 0 and sb.shadow_color.a > 0.2, "panel has a shadow")
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		check(sb.get_margin(side) - maxf(0.0, -sb.get_expand_margin(side)) >= AppTheme.SPACE_SM, "panel pads its text (side %d)" % side)
	check(t.get_font("font", "TooltipLabel") == AppTheme.ui_font(AppTheme.WEIGHT_MEDIUM), "tooltip text uses the UI font")
	var ink := t.get_color("font_color", "TooltipLabel")
	var ratio := _contrast(ink, sb.bg_color)
	check(ratio >= 7.0, "text contrast %.1f:1 >= 7:1 (WCAG AAA)" % ratio)
	check(t.get_font_size("font_size", "TooltipLabel") >= AppTheme.TYPE_BODY, "font size at least body text")
	# Desktop canvas scale at the window sizes the app is checked at.
	for size in [Vector2(1280, 720), Vector2(1024, 600), Vector2(1920, 1080), Vector2(900, 960)]:
		var scale := minf(size.x / Main.DESKTOP_MIN_CANVAS_WIDTH, size.y / 960.0)
		var px := Tooltip.font_size_for(scale)
		check(px * scale >= 13.5, "%dx%d: tooltip text %.1f px on screen (>= 13.5)" % [size.x, size.y, px * scale])
		check(px <= AppTheme.TYPE_TITLE, "%dx%d: tooltip font no bigger than a title" % [size.x, size.y])
	check(is_equal_approx(float(ProjectSettings.get_setting("gui/timers/tooltip_delay_sec", 0.5)), 0.5), "tooltip delay 0.5 s")


func _check_builder() -> void:
	print("=== builder ===")
	var long := "Formula cards • Every exam formula with a picture, what each letter means and a worked example, plus the units each answer comes out in"
	var tip := Tooltip.make(long)
	root.add_child(tip)
	await _wait(0.05)
	var title := tip.get_node_or_null("Title") as Label
	var body := tip.get_node_or_null("Body") as Label
	check(tip.visible and title != null and body != null, "'Title • description' makes a title and a body")
	if title != null and body != null:
		check(title.text == "Formula cards" and body.text.begins_with("Every exam formula"), "split at the first bullet")
		check(title.get_theme_font("font").get_font_weight() >= AppTheme.WEIGHT_BOLD, "title is bold")
		check(body.theme_type_variation == "TooltipLabel", "body uses the tooltip label style")
		check(body.autowrap_mode != TextServer.AUTOWRAP_OFF, "body wraps")
		check(tip.size.x <= Tooltip.MAX_EM * Tooltip.font_size() + 1.0, "tip no wider than %d em (%.0f px)" % [Tooltip.MAX_EM, tip.size.x])
		check(body.get_line_count() >= 2, "long description wraps onto %d lines" % body.get_line_count())
	tip.queue_free()
	var short := Tooltip.make("Click to enlarge")
	root.add_child(short)
	await _wait(0.05)
	var only := short.get_node_or_null("Body") as Label
	check(short.get_node_or_null("Title") == null and only != null, "plain text makes a body only")
	if only != null:
		check(only.get_line_count() == 1, "short tip stays on one line")
		check(short.size.x < Tooltip.MAX_EM * Tooltip.font_size() * 0.6, "short tip is compact (%.0f px)" % short.size.x)
	short.queue_free()
	var was := Tooltip.enabled
	Tooltip.enabled = false
	var none := Tooltip.make(long)
	check(not none.visible and none.get_child_count() == 0, "disabled: an invisible tip (no tooltip)")
	none.free()
	Tooltip.enabled = was


func _check_wrap() -> void:
	print("=== plain tooltip_text wrap ===")
	var text := "Colors the stem words to look up in the NEC Index and names the entry before you answer. Off in the Full Exam, like the real test."
	var wrapped := Tooltip.wrap(text)
	var lines := wrapped.split("\n")
	check(lines.size() >= 2, "long plain tip broken into %d lines" % lines.size())
	check(wrapped.replace("\n", " ") == text, "wrapping only swaps spaces for line breaks")
	var font := AppTheme.ui_font(AppTheme.WEIGHT_MEDIUM)
	for line in lines:
		check(font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 100).x <= Tooltip.MAX_EM * 100 + 1.0, "line within %d em: %s" % [Tooltip.MAX_EM, line])
	check(Tooltip.wrap("Click to enlarge") == "Click to enlarge", "short tip unchanged")


func _check_desktop() -> void:
	check(Tooltip.enabled, "desktop: tooltips on")
	check(main.theme == Tooltip.theme(), "Main carries the tooltip theme")
	var tile := MenuTile.new("Wiring Methods and Materials", AppTheme.SKY_400, 72, AppTheme.TYPE_BODY, AppTheme.TYPE_CAPTION)
	check(main.get_theme_stylebox("panel", "TooltipPanel") == Tooltip.theme().get_stylebox("panel", "TooltipPanel"), "the app's tooltip panel is the Tooltip style")
	# Tiles repeat their own text in a tip only when it is cut off.
	main.menu_show_tab(main.menu.tab_index("drills"))
	await _wait(0.3)
	var repeats := 0
	for t: MenuTile in main.menu.area_tiles.values():
		if t.get_tooltip(Vector2.ZERO) != "":
			repeats += 1
	check(repeats == 0, "area tiles whose text shows in full have no tip (%d do)" % repeats)
	var drill := _find_drill(main.menu_panel)
	check(drill != null and drill.get_tooltip(Vector2.ZERO).contains(" • ") and not drill.get_tooltip(Vector2.ZERO).begins_with(drill.title_label.text),
		"drill tile's tip adds its purpose as a title")
	var tip := drill.call("_make_custom_tooltip", drill.get_tooltip(Vector2.ZERO)) as Control if drill != null else null
	check(tip != null and tip.visible and tip.get_node_or_null("Title") != null, "drill tile builds the custom tip")
	if tip != null:
		tip.free()
	# A tile too narrow for its text offers the full text.
	var box := Control.new()
	main.add_child(box)
	box.add_child(tile)
	tile.size = Vector2(90, 72)
	tile.set_status("15 of 80 on the exam", "New", AppTheme.SKY_300, 0.0)
	await _wait(0.1)
	check(MenuTile.is_clipped(tile.title_label), "a cut-off title is detected")
	check(tile.get_tooltip(Vector2.ZERO).begins_with("Wiring Methods and Materials • "), "a cut-off tile shows its full text on hover")
	box.queue_free()
	var view := DiagramView.new()
	var dtip := view.call("_make_custom_tooltip", view.tooltip_text) as Control
	check(dtip.visible and (dtip.get_node("Body") as Label).text == "Click to enlarge", "figure tip uses the custom tip")
	dtip.free()
	view.free()
	main.menu_show_tab(main.menu.tab_index("settings"))
	await _wait(0.2)
	check(main.hunt_keywords_toggle.tooltip_text.contains("\n"), "keyword toggle's long tip is wrapped")


func _check_mobile() -> void:
	check(not Tooltip.enabled, "phone layout: tooltips off")
	var drill := _find_drill(main.menu_panel)
	if drill != null:
		var tip := drill.call("_make_custom_tooltip", "Quick warm-up drill • 10 questions") as Control
		check(not tip.visible, "phone: a tile's tip is invisible")
		tip.free()
	check(main.hunt_keywords_toggle.tooltip_text == "", "phone: keyword toggle has no tip")


func _find_drill(n: Node) -> MenuTile:
	if n is MenuTile and (n as MenuTile).tip != "":
		return n
	for c in n.get_children():
		var f := _find_drill(c)
		if f != null:
			return f
	return null


static func _contrast(a: Color, b: Color) -> float:
	var la := a.srgb_to_linear().get_luminance() + 0.05
	var lb := b.srgb_to_linear().get_luminance() + 0.05
	return maxf(la, lb) / minf(la, lb)


func _run_mobile_child() -> bool:
	var out: Array = []
	var code := OS.execute(OS.get_executable_path(),
			["--headless", "--path", ".", "--script", "tools/tests/test_tooltips.gd", "--", "--mobile-ui"], out, true)
	var text := ""
	for chunk in out:
		text += str(chunk)
	for line in text.split("\n"):
		if line.contains("FAIL:") or line.contains("==="):
			print("  [mobile] " + line.strip_edges())
		elif line.begins_with("checks: "):
			checks += int(line.trim_prefix("checks: ").get_slice(" ", 0))
	return code == 0
