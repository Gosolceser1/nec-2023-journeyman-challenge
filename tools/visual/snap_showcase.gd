extends SceneTree
## README / store screenshots with plausible study progress, both layouts:
##   Godot --path . --script tools/visual/snap_showcase.gd -- [--mobile-ui] [--win=1080x1920] [--out=showcase]
## Seeds user://question_bag.cfg (the app's own save format) with a few weeks
## of drills so the readiness ring and the weakest-area drill are not empty.
## It overwrites that file, so ALWAYS run with a temporary APPDATA.
## Shots land in .audit_tmp/shots/<out>/<desk|mob>_<name>.png.

const TABLE_ID := "final-exam-#3-026"
const DIAGRAM_ID := "final-exam-#1-005"
## Rolling accuracy per subject area in the seeded history.
const SEED_ACCURACY := {
	"general": 0.8, "wiring_protection": 0.82, "wiring_methods": 0.76, "equipment": 0.72,
	"special_occupancies": 0.55, "special_equipment": 0.7, "special_conditions": 0.67,
}

var tag := "desk"
var out := "showcase"
var win := Vector2i(1600, 900)
var main: Node
var rng := RandomNumberGenerator.new()


func _snap(name: String) -> void:
	var path := ProjectSettings.globalize_path("res://.audit_tmp/shots/%s/%s_%s.png" % [out, tag, name])
	root.get_viewport().get_texture().get_image().save_png(path)
	print("SNAP=", path)


func _wait(frames: int) -> void:
	await create_timer(frames / 60.0).timeout
	await process_frame


func _scroll(px: int) -> void:
	var n: Node = main.feedback_panel
	while n != null and not n is ScrollContainer:
		n = n.get_parent()
	if n != null:
		(n as ScrollContainer).scroll_vertical = px


func _seed_progress() -> void:
	var records := BankLoader.load_records()
	var deck := QuestionDeck.new()
	deck.path = QuizSession.BAG_PATH
	deck.run = 23
	for i in records.size():
		var area := ExamBlueprint.area_of(records[i])
		if area == "" or rng.randf() > 0.62:
			continue
		var kept := rng.randi_range(1, QuestionDeck.HISTORY)
		var bits := 0
		var wrong := 0
		for b in kept:
			if rng.randf() < float(SEED_ACCURACY.get(area, 0.7)):
				bits |= 1 << b
			else:
				wrong += 1
		var last := rng.randi_range(1, deck.run)
		var due := last + QuestionDeck.REVIEW_GAP if (bits & 1) == 0 and last > deck.run - 2 else 0
		deck.stats[str(records[i].get("id", ""))] = [kept, wrong, last, due, bits, kept]
	deck.save_state(records)


func _index_of(qid: String) -> int:
	for k in main.records.size():
		if str(main.records[k].get("id", "")) == qid:
			return k
	return -1


func _show(rec_index: int) -> void:
	var o: Array[int] = [rec_index]
	for k in 9:
		o.append((rec_index + 1 + k) % main.records.size())
	main.order = o
	main.current_index = 0
	main._show_question()
	main._auto_token += 1


func _answer(correct: bool) -> void:
	var rec: Dictionary = main.session.display_record(main.order[main.current_index])
	var ci := int(rec.correct_index)
	main._answer_selected(ci if correct else (ci + 1) % (rec.answers as Array).size())
	main._auto_token += 1
	main._stop_reading()


func _initialize() -> void:
	rng.seed = 20260927
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a.begins_with("--win="):
			var p := a.trim_prefix("--win=").split("x")
			win = Vector2i(int(p[0]), int(p[1]))
	if "--mobile-ui" in OS.get_cmdline_user_args():
		tag = "mob"
		if not Array(OS.get_cmdline_user_args()).any(func(a: String) -> bool: return a.begins_with("--win=")):
			win = Vector2i(540, 960)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.audit_tmp/shots/" + out))
	_seed_progress()
	AudioServer.set_bus_mute(0, true)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(win)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _wait(10)
	main.audio_cfg_path = "user://snap_showcase_audio.cfg"
	main._on_audio_mode_picked(AudioSettings.Mode.SILENT)
	main._refresh_study_button()
	main.session.bag_path = ""
	await _wait(80)
	_snap("01_menu")

	main._start_quiz(10, 1800, true, "10-Question Practice")
	await _wait(30)
	main.timer.stop()
	_show(_index_of(TABLE_ID))
	await _wait(70)
	_snap("02_table_question")
	_answer(true)
	await _wait(90)
	_snap("03_table_correct")
	_scroll(420)
	await _wait(8)
	_snap("03b_table_correct_scrolled")
	_scroll(0)

	_show(0)
	await _wait(60)
	_snap("04_plain_question")
	_answer(true)
	await _wait(90)
	_snap("05_plain_correct")

	_show(2)
	await _wait(60)
	_answer(false)
	await _wait(90)
	_snap("06_wrong")

	_show(_index_of(DIAGRAM_ID))
	await _wait(70)
	_snap("07_diagram_question")

	main._start_quiz(80, Main.EXAM_MINUTES * 60, true, "Full Journeyman Exam")
	await _wait(40)
	main.timer.stop()
	for i in 37:
		_answer(rng.randf() < 0.84)
		await process_frame
		main._next_question()
		await process_frame
	main.time_left = Main.EXAM_MINUTES * 60 - 37 * 151
	main._tick_timer()
	main.timer.stop()
	await _wait(80)
	_snap("08_simulator")

	for i in range(37, 80):
		_answer(rng.randf() < 0.84)
		await process_frame
		if i < 79:
			main._next_question()
			await process_frame
	var secs: Array = []
	for i in 80:
		secs.append([i + 1, clampf(rng.randfn(150.0, 45.0), 45.0, 400.0)])
	main.session.answer_seconds = secs
	main.streak = 6
	main._show_results()
	_scroll(0)
	await _wait(120)
	_snap("09_results")
	_scroll(600)
	await _wait(8)
	_snap("09b_results_scrolled")
	quit()
