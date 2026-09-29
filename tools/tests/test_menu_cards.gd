extends SceneTree
## Menu mode cards, menu tiles and answer cards stay in their slot. Mode cards
## and tiles: one content box for every state (normal, hover, pressed,
## hover_pressed, focus); hover is glow and shine only, so a hovered card never
## leaves its slot; the Home cards rest at the same left x and width as their
## siblings and the page, scale 1, once the menu settles, after quick hover
## passes, a hover spanning a container re-sort, a focus walk, the
## session-start press animation and a quiz round-trip; the tiles of a grid
## share one width and rest at scale 1 after hover passes. Answer cards return
## to their slot after hover and speaking. Every menu tab fits the screen
## without scrolling, desktop and mobile.
##
##   Godot --headless --path . --script tools/tests/test_menu_cards.gd [-- --mobile-ui]
##
## Without --mobile-ui the suite also runs itself once with it. Waits are real
## time: headless frames are unthrottled, so a frame count is no tween time.

const TOL := 0.5
const STATES := ["hover", "pressed", "hover_pressed", "focus"]

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
	print("=== menu cards (%s) ===" % ("mobile" if mobile else "desktop"))
	main = load("res://scenes/main.tscn").instantiate()
	main.audio_cfg_path = "user://test_menu_cards_audio.cfg"
	main.session.bag_path = ""
	root.add_child(main)
	await _wait(0.8)
	var cards: Array = main.menu_mode_buttons.filter(func(b): return b.is_visible_in_tree())
	check(cards.size() == 4, "4 mode cards on Home without a run to continue (got %d)" % cards.size())

	_check_styles(cards)
	_check_styles(main.menu.tiles)
	await _check_tiles()
	_check_toggles()
	_check_rest(cards, "menu settled")

	for k in [0, 1, 2, 3, 2, 1, 0, 3, 1, 2, 3, 2, 3]:
		cards[k].mouse_entered.emit()
		await _wait(0.01 + 0.015 * float(k % 4))
		cards[k].mouse_exited.emit()
	await _wait(0.4)
	_check_rest(cards, "after quick hover passes")

	for card in [cards[1], cards[2]]:
		card.mouse_entered.emit()
		await _wait(0.3)
		_check_rest(cards, "while %s is hovered (glow only, no slide)" % _title(card))
		(card.get_parent() as Container).queue_sort()
		await process_frame
		await process_frame
		card.mouse_exited.emit()
		await _wait(0.4)
		_check_rest(cards, "after a %s hover spanning a re-sort" % _title(card))

	for b in cards:
		b.grab_focus()
		await _wait(0.03)
	await _wait(0.3)
	_check_rest(cards, "after a focus walk")

	for b in cards:
		Widgets._start_press_motion(b)
	await _wait(0.5)
	_check_rest(cards, "after the start press animation")

	main._on_audio_mode_picked(AudioSettings.Mode.SILENT)
	main._start_quiz(10, 1800, true, "Menu cards")
	main.timer.stop()
	await _wait(0.8)
	var answers: Array = main.answers_box.get_children()
	_check_slots(answers, "answer cards settled")
	for c in answers:
		c.mouse_entered.emit()
		await _wait(0.03)
		c.mouse_exited.emit()
	for c in answers:
		c.set_speaking(true)
		await _wait(0.05)
		c.set_speaking(true)
		await _wait(0.05)
		c.set_speaking(false)
	await _wait(0.4)
	_check_slots(answers, "answer cards after hover and speaking")

	main._show_menu()
	await _wait(0.1)
	main._show_menu()
	await _wait(0.8)
	_check_rest(cards, "after a quiz round-trip and a doubled _show_menu")

	_check_menu_fits("Home after a quiz round-trip")

	var child_ok := true
	if not mobile:
		child_ok = _run_mobile_child()
	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	print("RESULT: ", "PASS" if failures.is_empty() and child_ok else "FAIL")
	quit(0 if failures.is_empty() and child_ok else 1)


func _title(b: Button) -> String:
	return str(b.get_meta("base_text")).get_slice("\n", 0)


## Every tab: its tiles share their grid's column width and are back at
## scale 1 after a quick hover pass, and the page fits without scrolling.
func _check_tiles() -> void:
	for i in main.menu_tab_count():
		main.menu_show_tab(i)
		await _wait(0.3)
		var tiles: Array = main.menu.tiles.filter(func(t): return t.is_visible_in_tree())
		for t in tiles:
			t.mouse_entered.emit()
			await _wait(0.01)
			t.mouse_exited.emit()
		await _wait(0.4)
		var bad := PackedStringArray()
		for t in tiles:
			var grid := t.get_parent() as GridContainer
			var first := grid.get_child(0) as Control
			# A grid hands its leftover pixel to some columns: 1 px apart is one width.
			if absf(t.size.x - first.size.x) > 1.0 + TOL or not t.scale.is_equal_approx(Vector2.ONE) or not is_equal_approx(t.modulate.a, 1.0):
				bad.append("%s w%+.2f s%.3f" % [t.title_label.text, t.size.x - first.size.x, t.scale.x])
		check(bad.is_empty(), "tab %s: %d/%d tiles share their grid's width at rest (off: %s)" % [main.menu.tab_ids[i], tiles.size() - bad.size(), tiles.size(), ", ".join(bad)])
		_check_menu_fits("tab " + main.menu.tab_ids[i])
	main.menu_show_tab(0)
	await _wait(0.3)


## Same content margins in every state, so hover, press and keyboard focus
## never resize or shift a card.
func _check_styles(cards: Array) -> void:
	for b in cards:
		var base := (b as Button).get_theme_stylebox("normal")
		for state in STATES:
			var sb := (b as Button).get_theme_stylebox(state)
			var same := true
			for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
				same = same and is_equal_approx(sb.get_margin(side), base.get_margin(side))
			check(same, "%s: %s content margins match normal" % [_title(b), state])


## The audio section's toggles line up with the row labels above them.
func _check_toggles() -> void:
	for toggle in [main.reduce_motion_toggle, main.auto_teach_toggle]:
		for state in ["normal", "hover", "pressed", "hover_pressed"]:
			check(is_zero_approx((toggle as Button).get_theme_stylebox(state).get_margin(SIDE_LEFT)),
					"%s: %s label flush with the row labels" % [toggle.text.get_slice(" (", 0), state])


## Every card shares the first card's left x and width, fills its column and
## is back at scale 1 and full opacity.
func _check_rest(cards: Array, when: String) -> void:
	var bad := PackedStringArray()
	var first := (cards[0] as Control).get_global_rect()
	for n in cards:
		var c := n as Control
		var r := c.get_global_rect()
		var slot := (c.get_parent() as Control).get_global_rect()
		var off := absf(r.position.x - first.position.x) > TOL or absf(r.size.x - first.size.x) > TOL \
				or absf(r.position.x - slot.position.x) > TOL or absf(r.size.x - slot.size.x) > TOL
		if off or not c.scale.is_equal_approx(Vector2.ONE) or not is_equal_approx(c.modulate.a, 1.0):
			bad.append("%s x%+.2f w%+.2f s%.3f" % [_title(c), r.position.x - first.position.x, r.size.x - first.size.x, c.scale.x])
	check(bad.is_empty(), "%s: %d/%d cards share left x and width (off: %s)" % [when, cards.size() - bad.size(), cards.size(), ", ".join(bad)])


## Each node fills its container's slot: same x and width, scale 1.
func _check_slots(nodes: Array, when: String) -> void:
	var bad := PackedStringArray()
	for n in nodes:
		var c := n as Control
		var r := c.get_global_rect()
		var slot := (c.get_parent() as Control).get_global_rect()
		if absf(r.position.x - slot.position.x) > TOL or absf(r.size.x - slot.size.x) > TOL or not c.scale.is_equal_approx(Vector2.ONE):
			bad.append("%s x%+.2f w%+.2f s%.3f" % [c.name, r.position.x - slot.position.x, r.size.x - slot.size.x, c.scale.x])
	check(bad.is_empty(), "%s: %d cards in their slot (off: %s)" % [when, nodes.size() - bad.size(), ", ".join(bad)])


## The open tab fits the 960 px canvas without scrolling.
func _check_menu_fits(when: String) -> void:
	var scroll := main.menu_center_box.get_parent() as ScrollContainer
	var need := main.menu_center_box.get_combined_minimum_size().y
	print("  %s: menu height %.0f of %.0f px (row gap %d)" % [when, need, scroll.size.y, main.menu_column.get_theme_constant("separation")])
	check(need <= scroll.size.y + TOL, "%s: menu fits without scrolling (%.0f of %.0f px)" % [when, need, scroll.size.y])


func _run_mobile_child() -> bool:
	var out: Array = []
	var code := OS.execute(OS.get_executable_path(),
			["--headless", "--path", ".", "--script", "tools/tests/test_menu_cards.gd", "--", "--mobile-ui"], out, true)
	var text := ""
	for chunk in out:
		text += str(chunk)
	for line in text.split("\n"):
		if line.contains("FAIL:") or line.contains("==="):
			print("  [mobile] " + line.strip_edges())
		elif line.begins_with("checks: "):
			checks += int(line.trim_prefix("checks: ").get_slice(" ", 0))
	return code == 0
