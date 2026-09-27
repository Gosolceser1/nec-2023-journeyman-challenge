extends SceneTree
## Menu mode cards and answer cards stay in their column slot: same left x and
## width as the VBoxContainer that holds them, once the menu settles, after
## mouse passes (including one spanning a container re-sort), after focus moves
## and after a quiz round-trip. The Nebraska State Law card is held to the
## same column x and width as the NEC cards. Hover slides used to tween position:x
## as_relative, so a re-sort or a quick enter/exit left each card a different
## few px off its slot and the menu looked staggered.
##
##   Godot --headless --path . --script tools/tests/test_menu_alignment.gd [-- --mobile-ui]
##
## Without --mobile-ui the suite also runs itself once with it. Waits are real
## time: headless frames are unthrottled, so a frame count is no tween time.

const TOL := 0.5

var failures: Array[String] = []
var checks := 0
var main: Node


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
	print("=== menu alignment (%s) ===" % ("mobile" if mobile else "desktop"))
	main = load("res://scenes/main.tscn").instantiate()
	main.audio_cfg_path = "user://test_menu_alignment_audio.cfg"
	main.session.bag_path = ""
	root.add_child(main)
	await _wait(0.8)
	check(main.menu_mode_buttons.size() == 8, "8 mode cards (got %d)" % main.menu_mode_buttons.size())

	_check_styles()
	_check_slots(main.menu_mode_buttons, "menu settled")
	var state_card := _state_law_card()
	_check_state_law_card(state_card, "menu settled")

	var btns: Array = main.menu_mode_buttons
	for k in [0, 1, 2, 3, 4, 5, 6, 7, 6, 5, 4, 3, 2, 1, 0, 1, 2, 3, 2, 1, 7, 6, 7]:
		btns[k].mouse_entered.emit()
		await _wait(0.01 + 0.015 * float(k % 4))
		btns[k].mouse_exited.emit()
	await _wait(0.4)
	_check_slots(btns, "after quick mouse passes")
	_check_state_law_card(state_card, "after quick mouse passes")

	if state_card != null:
		state_card.mouse_entered.emit()
		await _wait(0.3)
		var dx := state_card.get_global_rect().position.x - (state_card.get_parent() as Control).get_global_rect().position.x
		check(absf(dx - 5.0) <= TOL, "hovered State Law card rests 5 px right of its slot (off by %.2f)" % dx)
		state_card.mouse_exited.emit()
		await _wait(0.4)
		_check_state_law_card(state_card, "after a State Law hover")

	btns[2].mouse_entered.emit()
	await _wait(0.3)
	var col := btns[2].get_parent() as Control
	check(absf(btns[2].get_global_rect().position.x - col.get_global_rect().position.x - 5.0) <= TOL,
			"hovered card rests 5 px right of its slot (off by %.2f)" % (btns[2].get_global_rect().position.x - col.get_global_rect().position.x))
	(col as Container).queue_sort()
	await process_frame
	await process_frame
	btns[2].mouse_exited.emit()
	await _wait(0.4)
	_check_slots(btns, "after a hover spanning a re-sort")

	for b in btns:
		b.grab_focus()
		await _wait(0.03)
	await _wait(0.2)
	_check_slots(btns, "after focus walk")

	main._on_audio_mode_picked(AudioSettings.Mode.SILENT)
	main._start_quiz(10, 1800, true, "Alignment")
	main.timer.stop()
	await _wait(0.8)
	var cards: Array = main.answers_box.get_children()
	_check_slots(cards, "answer cards settled")
	for c in cards:
		c.mouse_entered.emit()
		await _wait(0.03)
		c.mouse_exited.emit()
	for c in cards:
		c.set_speaking(true)
		await _wait(0.05)
		c.set_speaking(true)
		await _wait(0.05)
		c.set_speaking(false)
	await _wait(0.4)
	_check_slots(cards, "answer cards after hover and speaking")

	main._show_menu()
	await _wait(0.8)
	_check_slots(main.menu_mode_buttons, "menu after returning from a quiz")
	_check_state_law_card(state_card, "menu after returning from a quiz")

	var child_ok := true
	if not mobile:
		child_ok = _run_mobile_child()
	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	print("RESULT: ", "PASS" if failures.is_empty() and child_ok else "FAIL")
	quit(0 if failures.is_empty() and child_ok else 1)


## Every card fills its VBoxContainer's slot: same x and width as the column,
## scale 1.
func _check_slots(nodes: Array, when: String) -> void:
	var bad := PackedStringArray()
	for n in nodes:
		var c := n as Control
		var r := c.get_global_rect()
		var slot := (c.get_parent() as Control).get_global_rect()
		if absf(r.position.x - slot.position.x) > TOL or absf(r.size.x - slot.size.x) > TOL or not c.scale.is_equal_approx(Vector2.ONE):
			bad.append("%s x%+.2f w%+.2f s%.3f" % [c.name, r.position.x - slot.position.x, r.size.x - slot.size.x, c.scale.x])
	check(bad.is_empty(), "%s: %d cards in their slot (off: %s)" % [when, nodes.size() - bad.size(), ", ".join(bad)])


func _state_law_card() -> Button:
	var found: Array = main.menu_mode_buttons.filter(func(b): return str(b.get_meta("base_text")).contains("State Electrical Act"))
	check(found.size() == 1, "one State Law mode card (got %d)" % found.size())
	return found[0] if found.size() == 1 else null


## The State Law card sits in the same column as the NEC mode cards, with the
## same left x and width as each of them.
func _check_state_law_card(card: Button, when: String) -> void:
	if card == null:
		return
	var r := card.get_global_rect()
	var bad := PackedStringArray()
	for b in main.menu_mode_buttons:
		if b == card:
			continue
		var o := (b as Control).get_global_rect()
		if b.get_parent() != card.get_parent() or absf(r.position.x - o.position.x) > TOL or absf(r.size.x - o.size.x) > TOL:
			bad.append("%s x%+.2f w%+.2f" % [b.name, r.position.x - o.position.x, r.size.x - o.size.x])
	check(bad.is_empty(), "%s: State Law card lines up with the %d other cards (off: %s)" % [when, main.menu_mode_buttons.size() - 1, ", ".join(bad)])


## One content box for every state of a card, and the toggles line up with
## the row labels above them.
func _check_styles() -> void:
	for b in main.menu_mode_buttons:
		var base := (b as Button).get_theme_stylebox("normal")
		for state in ["hover", "pressed", "focus"]:
			var sb := (b as Button).get_theme_stylebox(state)
			var same := true
			for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
				same = same and is_equal_approx(sb.get_margin(side), base.get_margin(side))
			check(same, "%s: %s content margins match normal" % [str(b.get_meta("base_text")).get_slice("\n", 0), state])
	for toggle in [main.reduce_motion_toggle, main.auto_teach_toggle]:
		for state in ["normal", "hover", "pressed", "hover_pressed"]:
			check(is_zero_approx((toggle as Button).get_theme_stylebox(state).get_margin(SIDE_LEFT)),
					"%s: %s label flush with the row labels" % [toggle.text.get_slice(" (", 0), state])


func _run_mobile_child() -> bool:
	var out: Array = []
	var code := OS.execute(OS.get_executable_path(),
			["--headless", "--path", ".", "--script", "tools/tests/test_menu_alignment.gd", "--", "--mobile-ui"], out, true)
	var text := ""
	for chunk in out:
		text += str(chunk)
	for line in text.split("\n"):
		if line.contains("FAIL:") or line.contains("==="):
			print("  [mobile] " + line.strip_edges())
		elif line.begins_with("checks: "):
			checks += int(line.trim_prefix("checks: ").get_slice(" ", 0))
	return code == 0
