extends SceneTree
## Frame sequences of the interactive motion, driven by real pointer input:
##   Godot --fixed-fps 60 --disable-vsync --path . --script tools/visual/snap_motion.gd -- [--mobile-ui] --out=after
## Writes res://.audit_tmp/motion/<out>/<desk|mob>_<sequence>/f_0000.png ... at
## 60 fps game time, plus timeline.json with each sequence's frame count and
## the frame on which the start cue fired (the Pressed frame of a mode card).
## With --answers it records only answer_correct and answer_wrong (one click
## each on fixed questions), for the README animations; --win=WxH sets the window.

var tag := "desk"
var out := "after"
var main: Node
var _seq := ""
var _frame := 0
var _timeline := {}
var _mouse := Vector2.ZERO


func _dir() -> String:
	return ProjectSettings.globalize_path("res://.audit_tmp/motion/%s/%s_%s" % [out, tag, _seq])


func _begin(seq: String) -> void:
	_seq = seq
	_frame = 0
	DirAccess.make_dir_recursive_absolute(_dir())
	_timeline[tag + "_" + seq] = {"frames": 0, "fps": 60, "cue_frame": -1}


func _capture(frames: int) -> void:
	for i in frames:
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("%s/f_%04d.png" % [_dir(), _frame])
		_frame += 1
	_timeline[tag + "_" + _seq]["frames"] = _frame


func _idle(frames: int) -> void:
	for i in frames:
		await process_frame


func _move(to: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = to
	ev.global_position = to
	ev.relative = to - _mouse
	_mouse = to
	root.push_input(ev, true)


func _button(pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = _mouse
	ev.global_position = _mouse
	root.push_input(ev, true)


## Hover, press for about 70 ms like a real click, release; the release is the
## Pressed signal. Captures through the release, then `after` more frames.
func _click(target: Control, hover_frames: int, after: int, mark_cue := false) -> void:
	_move(target.get_global_rect().get_center())
	await _capture(hover_frames)
	_button(true)
	await _capture(4)
	if mark_cue:
		_timeline[tag + "_" + _seq]["cue_frame"] = _frame
	_button(false)
	await _capture(after)


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	seed(20260927)
	AudioServer.set_bus_mute(0, true)
	# A fixed window: the project starts maximized, and on a 4K screen each
	# captured frame is an 8-megapixel readback + PNG (~4 fps on screen).
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	if "--mobile-ui" in OS.get_cmdline_user_args():
		tag = "mob"
		DisplayServer.window_set_size(Vector2i(540, 960))
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--win="):
			var p := a.trim_prefix("--win=").split("x")
			DisplayServer.window_set_size(Vector2i(int(p[0]), int(p[1])))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _idle(10)
	main.audio_cfg_path = "user://motion_audio.cfg"
	main.session.bag_path = ""
	main._refresh_study_button()
	main._on_audio_mode_picked(AudioSettings.Mode.SILENT)
	_move(Vector2(4, 4))
	await _idle(70)
	if "--answers" in OS.get_cmdline_user_args():
		await _answers()
		_finish()
		return

	var cards: Array[Button] = []
	for b in main.menu_overlay.find_children("*", "Button", true, false):
		if (b as Button).has_meta("starts_session") and (b as Button).is_visible_in_tree():
			cards.append(b)

	_begin("menu_hover")
	await _capture(6)
	for i in mini(3, cards.size()):
		_move(cards[i].get_global_rect().get_center())
		await _capture(18)
	_move(Vector2(4, 4))
	await _capture(18)

	_begin("start_press")
	await _capture(4)
	await _click(cards[0], 16, 56, true)

	main.timer.stop()
	main.order = [0, 1, 2, 3, 4, 5, 7, 8, 10, 11] as Array[int]
	main.current_index = 0
	main._show_question()
	main._auto_token += 1
	_move(Vector2(4, 4))
	await _idle(50)

	var answer_cards: Array = main.answers_box.get_children()
	_begin("answer_hover")
	await _capture(4)
	for i in mini(3, answer_cards.size()):
		_move((answer_cards[i] as Control).get_global_rect().get_center())
		await _capture(16)
	_move(Vector2(4, 4))
	await _capture(16)

	_begin("answer_and_next")
	var rec: Dictionary = main.session.current_record()
	await _click(answer_cards[int(rec.correct_index)], 10, 50)
	await _click(main.next_button, 14, 40)

	_begin("results")
	main.timer.stop()
	main.score = 9
	main.answered_count = 10
	main.session.area_stats = {"general": [3, 3], "wiring_protection": [3, 3], "wiring_methods": [2, 3], "equipment": [1, 1]}
	main.session.answer_seconds = [[1, 95.0], [2, 120.0], [3, 150.0], [4, 80.0], [5, 110.0], [6, 130.0], [7, 100.0], [8, 90.0], [9, 140.0], [10, 105.0]]
	main.missed_questions.clear()
	main._show_results()
	await _capture(96)
	await _click(main.next_button, 10, 36)
	_finish()


func _answers() -> void:
	main._start_quiz(10, 1800, true, "10-Question Practice")
	await _idle(40)
	main.timer.stop()
	for step in [["answer_correct", 0, true], ["answer_wrong", 2, false]]:
		main.order = [int(step[1]), 1, 3, 4, 5, 7, 8, 10, 11, 12] as Array[int]
		main.current_index = 0
		main._show_question()
		main._auto_token += 1
		_move(Vector2(4, 4))
		await _idle(60)
		_begin(step[0])
		var rec: Dictionary = main.session.current_record()
		var slot := int(rec.correct_index)
		if not step[2]:
			slot = (slot + 1) % main.answers_box.get_child_count()
		await _click(main.answers_box.get_child(slot) as Control, 12, 84)


func _finish() -> void:
	var f := FileAccess.open("res://.audit_tmp/motion/%s/timeline_%s.json" % [out, tag], FileAccess.WRITE)
	f.store_string(JSON.stringify(_timeline, "  "))
	f.close()
	print("MOTION=", ProjectSettings.globalize_path("res://.audit_tmp/motion/" + out))
	quit()
