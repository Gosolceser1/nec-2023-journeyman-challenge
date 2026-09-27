extends SceneTree
## Every screen, fixed records, both layouts:
##   Godot --path . --script tools/visual/snap_all.gd -- [--mobile-ui] --out=before
## Before/after comparisons (tools/visual/compare_shots.py) need repeatable
## frames: run with the engine at a fixed step and pass --det, which seeds the
## global RNG and hides particle bursts (their emission is not reproducible):
##   Godot --fixed-fps 60 --disable-vsync --path . --script tools/visual/snap_all.gd -- --det --out=before

const REC_PLAIN := 0
const REC_TABLE := 9
const REC_DIAGRAM := 135
const REC_FORMULA := 6

var tag := "desk"
var out := "after"
var main: Node

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

func _scroll_menu(px: int) -> void:
	for c in main.menu_overlay.get_children():
		if c is ScrollContainer:
			(c as ScrollContainer).scroll_vertical = px

func _show(rec_index: int) -> void:
	main.order = [rec_index, 1, 2, 3, 4, 5, 7, 8, 10, 11] as Array[int]
	main.current_index = 0
	main._show_question()
	main._auto_token += 1

func _answer(correct: bool) -> void:
	var rec: Dictionary = main.records[main.order[main.current_index]]
	var ci := int(rec.correct_index)
	main._answer_selected(ci if correct else (ci + 1) % (rec.answers as Array).size())
	main._auto_token += 1

func _hide_particles(n: Node) -> void:
	if n is CPUParticles2D:
		(n as CPUParticles2D).visible = false

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	if "--det" in OS.get_cmdline_user_args():
		seed(20260927)
		node_added.connect(_hide_particles)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.audit_tmp/shots/" + out))
	if "--mobile-ui" in OS.get_cmdline_user_args():
		tag = "mob"
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(540, 960))
	main = load("res://Main.tscn").instantiate()
	root.add_child(main)
	await _wait(10)
	main.audio_cfg_path = "user://snap_audio.cfg"
	main._on_audio_mode_picked(AudioSettings.Mode.SILENT)
	await _wait(60)
	_snap("01_menu")
	main._on_audio_mode_picked(AudioSettings.Mode.LISTEN)
	if "audio_expanded" in main and not main.audio_expanded:
		main._toggle_audio_section()
	await _wait(10)
	_snap("02_menu_listen")
	_scroll_menu(2000)
	await _wait(10)
	_snap("03_menu_bottom")
	_scroll_menu(0)
	if "audio_expanded" in main and main.audio_expanded:
		main._toggle_audio_section()
	main._on_audio_mode_picked(AudioSettings.Mode.SILENT)

	main._start_quiz(10, 1800, true, "10-Question Practice")
	await _wait(20)
	_show(REC_PLAIN)
	await _wait(50)
	_snap("04_question")
	_answer(true)
	await _wait(70)
	_snap("05_correct")
	_scroll(400)
	await _wait(5)
	_snap("05b_correct_scrolled")
	_scroll(0)
	main.current_index = 1
	main._show_question()
	main._auto_token += 1
	await _wait(50)
	_answer(false)
	await _wait(70)
	_snap("06_wrong")

	_show(REC_TABLE)
	await _wait(50)
	_snap("07_table_question")
	_answer(true)
	await _wait(70)
	_snap("08_table_answered")
	_scroll(500)
	await _wait(5)
	_snap("08b_table_answered_scrolled")
	_scroll(0)
	_show(REC_DIAGRAM)
	await _wait(50)
	_snap("09_diagram_question")
	_show(REC_FORMULA)
	await _wait(50)
	_snap("10_formula_question")

	# Listen dock + ungraded reveal, without starting real audio.
	main.session_audio_mode = AudioSettings.Mode.LISTEN
	main.session_muted = false
	_show(REC_PLAIN)
	main.listen_phase = AudioSettings.ListenPhase.THINK
	main._listen_countdown = 7
	main._refresh_dock_audio()
	main._show_listen_countdown()
	await _wait(50)
	_snap("11_listen_think")
	_answer(false)
	main._auto_token += 1
	await _wait(70)
	_snap("12_listen_answer")
	main._listen_timer.stop()
	main.answered_count = 10
	main._show_results()
	await _wait(60)
	_snap("13_listen_results")

	main.session_audio_mode = AudioSettings.Mode.SILENT
	main.session_muted = true
	main._refresh_dock_audio()
	main.score = 9
	main.answered_count = 10
	main.streak = 5
	main.chapter_stats = {1: [2, 2], 2: [3, 3], 3: [2, 3], 4: [1, 1], 0: [1, 1]}
	main.missed_questions.clear()
	main.missed_questions.append({"index": 3, "prompt": main.records[2].prompt, "selected": "B — 10,000", "correct": "C — 17,500", "article": "220.12", "article_title": "Lighting Load", "tip_short": str(main.records[2].get("tip_short", "")), "record_index": 2})
	main._show_results()
	_scroll(0)
	await _wait(90)
	_snap("14_results_pass")
	main.score = 5
	main.chapter_stats = {1: [0, 2], 2: [2, 3], 3: [1, 3], 4: [1, 1], 0: [1, 1]}
	main._show_results()
	_scroll(0)
	await _wait(90)
	_snap("15_results_fail")
	_scroll(600)
	await _wait(5)
	_snap("15b_results_fail_scrolled")
	quit()
