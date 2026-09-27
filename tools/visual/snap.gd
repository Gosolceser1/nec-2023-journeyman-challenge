extends SceneTree

var tag := "desk"

func _snap(name: String) -> void:
	var out := ProjectSettings.globalize_path("res://.audit_tmp/shots/%s_%s.png" % [tag, name])
	root.get_viewport().get_texture().get_image().save_png(out)
	print("SNAP=", out)

func _scroll_down(main: Node, px: int) -> void:
	var n: Node = main.feedback_panel
	while n != null and not n is ScrollContainer:
		n = n.get_parent()
	if n != null:
		(n as ScrollContainer).scroll_vertical = px

func _wait(frames: int) -> void:
	await create_timer(frames / 60.0).timeout
	await process_frame

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.audit_tmp/shots"))
	if "--mobile-ui" in OS.get_cmdline_user_args():
		tag = "mob"
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(540, 960))
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.audio_cfg_path = "user://snap_audio.cfg"
	main._on_audio_mode_picked(AudioSettings.Mode.SILENT)
	await _wait(70)
	_snap("1_menu")
	main._on_audio_mode_picked(AudioSettings.Mode.AUTO)
	await _wait(10)
	_snap("1b_menu_auto")
	main._on_audio_mode_picked(AudioSettings.Mode.LISTEN)
	await _wait(10)
	_snap("1c_menu_listen")
	main.voice_picker.show_popup()
	await _wait(20)
	_snap("1d_voice_menu")
	main.voice_picker.get_popup().hide()
	main._on_audio_mode_picked(AudioSettings.Mode.SILENT)
	main._on_sfx_level_picked(AudioSettings.SFX_DEFAULT_LEVEL)
	main._toggle_audio_section()
	await _wait(10)
	_snap("1e_audio_open_silent")
	main._on_audio_mode_picked(AudioSettings.Mode.AUTO)
	await _wait(10)
	_snap("1f_audio_open_auto")
	main._toggle_audio_section()
	main._on_audio_mode_picked(AudioSettings.Mode.SILENT)
	await _wait(5)
	main._start_quiz(10, 1800, true, "Practice Test")
	await _wait(12)
	_snap("2_question_enter")
	await _wait(50)
	_snap("3_question")
	main._toggle_session_mute()
	await _wait(5)
	_snap("3b_dock_sound_on")
	# Listen dock look, without actually starting audio.
	main.session_audio_mode = AudioSettings.Mode.LISTEN
	main.listen_phase = AudioSettings.ListenPhase.THINK
	main._listen_countdown = 7
	main._refresh_dock_audio()
	main._show_listen_countdown()
	await _wait(5)
	_snap("3c_dock_listen")
	main._auto_token += 1
	main.listen_phase = AudioSettings.ListenPhase.IDLE
	main.session_audio_mode = AudioSettings.Mode.SILENT
	main.session_muted = true
	main._refresh_dock_audio()
	await _wait(5)
	var rec: Dictionary = main.records[main.order[main.current_index]]
	main._answer_selected(int(rec.correct_index))
	await _wait(8)
	_snap("4_correct_fx")
	await _wait(60)
	_scroll_down(main, 330)
	await _wait(3)
	_snap("5_correct")
	main._next_question()
	await _wait(60)
	rec = main.records[main.order[main.current_index]]
	main._answer_selected((int(rec.correct_index) + 1) % 4)
	await _wait(5)
	_snap("6_wrong_fx")
	await _wait(60)
	_scroll_down(main, 330)
	await _wait(3)
	_snap("7_wrong")
	# Force a passing, streaky session for the results screen.
	main.score = 9
	main.answered_count = 10
	main.streak = 5
	main.chapter_stats = {1: [2, 2], 2: [3, 3], 3: [2, 3], 4: [1, 1], 0: [1, 1]}
	main._show_results()
	_scroll_down(main, 0)
	await _wait(100)
	_snap("8_results")
	await _wait(60)
	_snap("9_results_confetti")
	quit()
