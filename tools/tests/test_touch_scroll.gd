extends SceneTree
## Finger drag-to-scroll (TouchScroll) versus taps.
##
## WHY THIS EXISTS: 1.0.0 set emulate_mouse_from_touch=false so a scroll could
## not answer a card, but Godot 4.7's ScrollContainer drags only on mouse
## events, so on Android no page, menu or list moved under a finger. TouchScroll
## scrolls from ScreenTouch/ScreenDrag itself. A swipe must scroll and must
## never press a button or answer a card (grading is irreversible); a tap must
## still press. Events go through the viewport (push_input), as on a device.
##
##   Godot --headless --path . --script tools/tests/test_touch_scroll.gd

var failures: Array[String] = []
var checks := 0

var box: Control
var scroll: ScrollContainer
var scroller: TouchScroll
var buttons: Array[Button] = []
var cards: Array[AnswerCard] = []
var presses := [0]
var answers := [0]


func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func _wait(sec: float) -> void:
	await create_timer(sec).timeout
	await process_frame


func _touch(pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.pressed = pressed
	ev.position = pos
	root.push_input(ev, true)


## A finger from `from` moving by `by` in `steps` events, `gap` seconds apart.
func _swipe(from: Vector2, by: Vector2, steps: int = 20, gap: float = 0.0, release := true) -> void:
	_touch(from, true)
	await process_frame
	var last := from
	for i in steps:
		var pos := from + by * float(i + 1) / float(steps)
		var ev := InputEventScreenDrag.new()
		ev.index = 0
		ev.position = pos
		ev.relative = pos - last
		last = pos
		root.push_input(ev, true)
		if gap > 0.0:
			await create_timer(gap).timeout
		else:
			await process_frame
	if release:
		_touch(from + by, false)
	await process_frame


func _tap(pos: Vector2) -> void:
	await _swipe(pos, Vector2.ZERO, 0)


func _center(c: Control) -> Vector2:
	return c.get_global_rect().get_center()


func _initialize() -> void:
	if "--mobile-ui" in OS.get_cmdline_user_args():
		await _app_cases()
	else:
		print("=== TOUCH DRAG-TO-SCROLL ===")
		check(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch") == false,
			"the test covers the shipped setting: no mouse emulation from touch")
		await _build_list()
		await _list_cases()
		# ui_mobile comes from the command line, so the app half runs as a child.
		var out: Array = []
		var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ".", "--script",
			"tools/tests/test_touch_scroll.gd", "--", "--mobile-ui"], out, true)
		for line in "".join(out).split("\n"):
			if line.begins_with("  ") or line.begins_with("==="):
				print(line)
		check(code == 0, "the mobile app touch checks pass (exit %d)" % code)
	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	for f in failures:
		print("  - %s" % f)
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)


func _build_list() -> void:
	box = Control.new()
	box.size = Vector2(420, 600)
	root.add_child(box)
	scroll = ScrollContainer.new()
	scroll.position = Vector2.ZERO
	scroll.size = Vector2(420, 600)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(400, 0)
	scroll.add_child(col)
	for i in 12:
		var b := Button.new()
		b.text = "Menu card %d" % i
		b.custom_minimum_size = Vector2(400, 80)
		b.pressed.connect(func() -> void: presses[0] += 1)
		col.add_child(b)
		buttons.append(b)
		var panel := PanelContainer.new()  # decoration left at MOUSE_FILTER_STOP
		panel.custom_minimum_size = Vector2(400, 30)
		col.add_child(panel)
		var card := AnswerCard.new()
		card.set_card_data(i % 4, "Answer %d" % i)
		card.custom_minimum_size = Vector2(400, 80)
		card.card_clicked.connect(func(_i: int) -> void: answers[0] += 1)
		col.add_child(card)
		cards.append(card)
	scroller = TouchScroll.new()
	scroller.root = box
	root.add_child(scroller)
	await _wait(0.2)
	var bar := scroll.get_v_scroll_bar()
	print("  list: content %.0f px, page %.0f px" % [bar.max_value, bar.page])
	check(TouchScroll.can_scroll(scroll, true), "the test list is scrollable (max %.0f, page %.0f)" % [bar.max_value, bar.page])


func _reset() -> void:
	scroller._stop_fling()
	scroll.scroll_vertical = 400
	presses[0] = 0
	answers[0] = 0
	for c in cards:
		c.cancel_press()
		c.set_state(AnswerCard.State.NORMAL)


## The first card/button fully on screen.
func _visible(list: Array) -> Control:
	var view := scroll.get_global_rect()
	for c in list:
		if view.encloses(c.get_global_rect()):
			return c
	return null


func _list_cases() -> void:
	# Swipe up over an answer card: scrolls, never answers.
	_reset()
	await process_frame
	var card := _visible(cards)
	var start := scroll.scroll_vertical
	await _swipe(_center(card), Vector2(0, -200))
	print("  swipe 200 px on an answer card: scroll %d -> %d, answers %d" % [start, scroll.scroll_vertical, answers[0]])
	check(scroll.scroll_vertical - start >= 150, "a finger swipe on an answer card scrolls the list (%d -> %d)" % [start, scroll.scroll_vertical])
	check(answers[0] == 0, "a swipe over an answer card must not answer it (answered %d)" % answers[0])
	check(card.current_state != AnswerCard.State.PRESSED, "the swiped card is not left pressed")

	# Swipe down over a menu button: scrolls, never presses.
	_reset()
	await process_frame
	var button := _visible(buttons)
	start = scroll.scroll_vertical
	await _swipe(_center(button), Vector2(0, 150))
	print("  swipe 150 px on a button: scroll %d -> %d, presses %d" % [start, scroll.scroll_vertical, presses[0]])
	check(start - scroll.scroll_vertical >= 100, "a finger swipe on a button scrolls the list")
	check(presses[0] == 0, "a swipe over a button must not press it (pressed %d)" % presses[0])

	# Swipe starting on a MOUSE_FILTER_STOP panel between them still scrolls.
	_reset()
	await process_frame
	var panel: Control = card.get_parent().get_child(card.get_index() - 1)
	start = scroll.scroll_vertical
	await _swipe(_center(panel), Vector2(0, -120))
	check(scroll.scroll_vertical - start >= 80, "a swipe that starts on a STOP panel scrolls too")

	# Between the scroll threshold (14 px) and the card's own slop (20 px): the
	# scroller wins and the card must not answer.
	_reset()
	await process_frame
	card = _visible(cards)
	await _swipe(_center(card), Vector2(0, -17), 3)
	check(answers[0] == 0, "a 17 px drag on a card scrolls and does not answer (answered %d)" % answers[0])

	# Taps still work.
	_reset()
	await process_frame
	card = _visible(cards)
	start = scroll.scroll_vertical
	await _tap(_center(card))
	check(answers[0] == 1, "a tap on an answer card answers once (got %d)" % answers[0])
	check(scroll.scroll_vertical == start, "a tap does not scroll")
	_reset()
	await process_frame
	button = _visible(buttons)
	await _tap(_center(button))
	check(presses[0] == 1, "a tap on a button presses it once (got %d)" % presses[0])
	_reset()
	await process_frame
	card = _visible(cards)
	await _swipe(_center(card), Vector2(3, 6), 3)
	check(answers[0] == 1, "a tap with a few px of finger jitter still answers (got %d)" % answers[0])

	# Sideways on a vertical-only list: not a scroll, and the card's slop still
	# refuses the release.
	_reset()
	await process_frame
	card = _visible(cards)
	start = scroll.scroll_vertical
	await _swipe(_center(card), Vector2(60, 0))
	check(scroll.scroll_vertical == start and answers[0] == 0, "a sideways drag neither scrolls nor answers")

	# Fling: a quick swipe keeps gliding after release; a tap on the moving list
	# only stops it.
	_reset()
	scroll.scroll_vertical = 0
	await process_frame
	button = _visible(buttons)
	await _swipe(_center(button), Vector2(0, -160), 8, 0.008)
	var released_at := scroll.scroll_vertical
	await _wait(0.1)
	print("  fling: %d at release, %d 0.1 s later" % [released_at, scroll.scroll_vertical])
	check(scroll.scroll_vertical > released_at, "a quick swipe keeps scrolling after release (fling)")
	button = _visible(buttons)
	presses[0] = 0
	answers[0] = 0
	await _tap(_center(button))
	var stopped_at := scroll.scroll_vertical
	await _wait(0.1)
	check(scroll.scroll_vertical == stopped_at, "a tap during a fling stops it")
	check(presses[0] == 0 and answers[0] == 0, "the tap that stops a fling presses nothing")
	box.queue_free()
	scroller.queue_free()
	await process_frame


## The real mobile app: the menu scrolls under a finger without starting a
## session, and the voice sheet scrolls without picking a voice.
func _app_cases() -> void:
	print("=== TOUCH SCROLL IN THE APP (mobile layout) ===")
	var main: Main = load("res://scenes/main.tscn").instantiate()
	main.audio_cfg_path = "user://test_touch_scroll_audio.cfg"
	main.voice_cfg_path = "user://test_touch_scroll_voice.cfg"
	for path in [main.audio_cfg_path, main.voice_cfg_path]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	main.session.bag_path = ""
	var fake: Array = []
	for i in 60:
		fake.append({"id": "en-us-x-t%02d-local" % i, "name": "en-us-x-t%02d-local" % i, "language": "en_US"})
	main.speech.voice_source = func() -> Array: return fake
	root.add_child(main)
	await _wait(0.8)
	check(main.ui_mobile and is_instance_valid(main.touch_scroll), "mobile layout with a TouchScroll")

	# Menu: every tab fits the screen, so it never scrolls, and a swipe over a
	# mode card starts nothing.
	var menu_scroll: ScrollContainer = main.menu_center_box.get_parent()
	for i in main.menu_tab_count():
		main.menu_show_tab(i)
		await _wait(0.2)
		check(not TouchScroll.can_scroll(menu_scroll, true), "mobile menu tab %s fits without scrolling" % main.menu.tab_ids[i])
	main.menu_show_tab(0)
	await _wait(0.2)
	var mode_card: Button = main.menu.first_focus()
	var start := menu_scroll.scroll_vertical
	await _swipe(_center(mode_card), Vector2(0, -200))
	await _wait(0.2)
	check(menu_scroll.scroll_vertical == start, "a swipe on the menu leaves it in place (%d -> %d)" % [start, menu_scroll.scroll_vertical])
	check(main.menu_overlay.visible and main.order.is_empty(), "swiping over a mode card does not start a session")
	main.menu_show_tab(main.menu.tab_index("settings"))
	await _wait(0.2)

	# Voice sheet: 62 rows, taller than the sheet.
	main.voice_button.pressed.emit()
	await _wait(0.3)
	var sheet := main.voice_sheet
	check(is_instance_valid(sheet) and sheet.is_complete(), "the voice button opens the voice sheet")
	if not is_instance_valid(sheet):
		return
	var picked := [0]
	main.voice_picker.item_selected.connect(func(_i: int) -> void: picked[0] += 1)
	var row: Button = null
	for r in sheet.rows:
		if sheet.scroll.get_global_rect().encloses(r.get_global_rect()):
			row = r
	start = sheet.scroll.scroll_vertical
	var menu_before := menu_scroll.scroll_vertical
	await _swipe(_center(row), Vector2(0, -150))
	await _wait(0.2)
	print("  voice sheet swipe 150 px on a row: scroll %d -> %d, picks %d" % [start, sheet.scroll.scroll_vertical, picked[0]])
	check(sheet.scroll.scroll_vertical - start >= 100, "a finger swipe scrolls the voice list")
	check(picked[0] == 0 and is_instance_valid(main.voice_sheet), "swiping the voice list picks nothing and keeps it open")
	check(menu_scroll.scroll_vertical == menu_before, "the menu under the sheet stays put")
	for i in 60:
		if main.touch_scroll._fling_speed == 0.0:
			break
		await _wait(0.05)
	var target: Button = null
	for r in sheet.rows:
		if sheet.scroll.get_global_rect().encloses(r.get_global_rect()):
			target = r
			break
	var idx := sheet.rows.find(target)
	await _tap(_center(target))
	await _wait(0.1)
	check(picked[0] == 1 and main.voice_picker.selected == idx, "a tap on a voice row picks that voice (picks %d, selected %d, row %d)" % [picked[0], main.voice_picker.selected, idx])
	check(not is_instance_valid(main.voice_sheet), "picking a voice closes the sheet")
	main.queue_free()
	await process_frame
