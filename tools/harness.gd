extends SceneTree

# Tight feedback loop: drives the real quiz flow end-to-end headlessly and
# asserts exact symptoms. Run:
#   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/harness.gd

const SpeechText = preload("res://src/speech/speech_text.gd")

var failures: Array[String] = []
var checks := 0

func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: ", label)

func _init() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	# Pin the default (Silent, no autoplay) whatever this machine saved in the
	# menu, and never write the developer's real audio.cfg.
	main.audio = AudioSettings.new()
	main.audio_cfg_path = "user://harness_audio.cfg"
	# Same questions and choice orders every run, and the saved question bag
	# is never read or written.
	main.session.bag_path = ""
	main.session.rng.seed = 2023
	await process_frame

	print("=== bank load ===")
	check(main.records.size() == 283, "records count == 283, got %d" % main.records.size())
	check(BankLoader.count_in_section(main.records, BankLoader.SECTION_NEC) == 279, "NEC pool == 279")
	check(BankLoader.count_in_section(main.records, BankLoader.SECTION_NE_STATE_LAW) == 4, "Nebraska state-law pool == 4")
	check(main.voice_ids.size() > 0, "voice catalog (data/voices.json) loaded: %d voices" % main.voice_ids.size())

	print("=== sessions ===")
	await _run_session(main, 10, false)
	await _run_session(main, 25, true)
	await _run_session(main, 9999, false)
	await _run_session(main, 1, false)
	await _run_session(main, 9999, true, BankLoader.SECTION_NE_STATE_LAW)
	await _full_exam_excludes_state_law(main)

	print("=== answer every record (all render branches) ===")
	await _answer_every_record(main)

	print("=== speech plan sanity (all records, both modes) ===")
	await _speech_sanity(main)

	print("=== teach-gate: pre-answer playback must never reach a teach clip ===")
	await _teach_gate(main)

	print("=== teach-gate with a missing/corrupt clip file ===")
	await _teach_gate(main, true)

	print("=== thread is joined on quit ===")
	await _thread_join(main)

	print("=== stale speech callback must not clear the busy flag ===")
	await _stale_callback(main)

	print("=== audio modes: silent default, listen is ungraded + untimed, exam never autoplays ===")
	await _audio_modes(main)

	print("=== recorded voice: bundled clips load as resources; mobile picks them first ===")
	_voice_routing(main)

	print("=== timer expiry ===")
	main._start_quiz(5, 3, true, "TimerTest")
	await process_frame
	await process_frame
	for i in 6:
		main._tick_timer()
		await process_frame
	check(main.time_left <= 0 or main.order.size() == 0, "timer did not go negative past zero: %d" % main.time_left)

	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	for f in failures:
		print("  - ", f)
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)

func _run_session(main: Node, count: int, timed: bool, section := BankLoader.SECTION_NEC) -> void:
	main._start_quiz(count, main.SESSION_TIME_SECONDS, timed, "Harness", "", section)
	await process_frame
	await process_frame
	var total: int = mini(count, BankLoader.count_in_section(main.records, section))
	check(main.order.size() == total, "order size count=%d %s -> %d (want %d)" % [count, section, main.order.size(), total])
	var foreign := 0
	for idx in main.order:
		if BankLoader.section_of(main.records[idx]) != section:
			foreign += 1
	check(foreign == 0, "%s session drew %d records from another section" % [section, foreign])
	# The tween in _start_quiz only reaches _show_question once frames run, so
	# render q0 explicitly before the walk.
	main._show_question()
	# Own counter: current_index stops advancing once results are shown.
	var i := 0
	while i < total:
		var cards = main.answers_box.get_children()
		check(cards.size() >= 2, "cards for q%d: %d" % [i, cards.size()])
		main._answer_selected(i % 2)
		i += 1
		if i < total:
			main._next_question()
		if i % 25 == 0:
			await process_frame
	check(main.answered_count == total, "answered_count count=%d -> %d (want %d)" % [count, main.answered_count, total])
	main._show_results()
	await process_frame

func _full_exam_excludes_state_law(main: Node) -> void:
	for attempt in 5:
		main._start_quiz(80, main.EXAM_MINUTES * 60, true, "Full Journeyman Exam")
		await process_frame
		var drawn := 0
		for idx in main.order:
			if BankLoader.section_of(main.records[idx]) != BankLoader.SECTION_NEC:
				drawn += 1
		check(main.order.size() == 80 and drawn == 0, "simulator #%d: 80 NEC items, %d state-law drawn" % [attempt, drawn])
	main._show_results()
	await process_frame

func _answer_every_record(main: Node) -> void:
	var orig_order: Array = main.order.duplicate()
	main.order.clear()
	for i in main.records.size():
		main.order.append(i)
	main.session_length = main.records.size()
	main.timed_session = false
	main.time_left = 99999
	main.timer.stop()
	main.current_index = 0
	main.score = 0
	main.streak = 0
	main.answered_count = 0
	main.missed_questions.clear()
	var idx := 0
	while idx < main.records.size():
		main.current_index = idx
		main._show_question()
		var rec: Dictionary = main.records[idx]
		var n: int = (rec.get("answers", []) as Array).size()
		var ci := int(rec.get("correct_index", 0))
		var pick := ci if idx % 3 == 0 else ((ci + 1) % maxi(n, 1) if idx % 3 == 1 else maxi(n - 1, 0))
		main._answer_selected(pick)
		idx += 1
		if idx % 40 == 0:
			await process_frame
	check(main.answered_count == main.records.size(),
		"answered all: %d/%d" % [main.answered_count, main.records.size()])
	check(main.score + main.missed_questions.size() == main.answered_count,
		"score+missed==answered: %d+%d vs %d" % [main.score, main.missed_questions.size(), main.answered_count])
	main._show_results()
	await process_frame
	main.order = orig_order

func _speech_sanity(main: Node) -> void:
	var bad := 0
	for rec in main.records:
		for seg in SpeechText.speech_plan(rec):
			if not seg is Dictionary:
				bad += 1
	check(bad == 0, "malformed speech segments: %d" % bad)
	# A pre-answer speech plan must not reach a teach segment at all: the player
	# stops before it, and the queue index must sit in the pre-teach region.
	var misplaced := 0
	for rec in main.records:
		var plan: Array = SpeechText.speech_plan(rec)
		var first_teach := -1
		var last_non_teach := -1
		for i in plan.size():
			if bool(plan[i].get("teach", false)):
				if first_teach < 0:
					first_teach = i
			else:
				last_non_teach = i
		if first_teach >= 0 and last_non_teach > first_teach:
			misplaced += 1  # teach lines must be a contiguous tail
	check(misplaced == 0, "teach segments not a contiguous tail in %d plans" % misplaced)

func _teach_gate(main: Node, corrupt: bool = false) -> void:
	# Drive the real playback path against a synthetic queue: pre-answer, the
	# player must never advance INTO a teach clip. Simulates the mp3 loading
	# failure branch too, which recurses through the same gate.
	var rec: Dictionary = main.records[0]
	var plan: Array = SpeechText.speech_plan(rec)
	if plan.is_empty():
		return
	main.current_answered = false
	main.want_teach = false
	main.speak_generation += 1
	main.speech_queue.clear()
	for seg in plan:
		# Point every clip at a missing file so _play_speech_clip takes its
		# skip-and-recurse branch, which recurses through the same teach gate.
		main.speech_queue.append({
			"path": "res://does_not_exist.mp3", "choice": int(seg.get("choice", -1)),
			"teach": bool(seg.get("teach", false)),
		})
	main.teach_from_index = -1
	for i in main.speech_queue.size():
		if bool(main.speech_queue[i].get("teach", false)):
			main.teach_from_index = i
			break
	main.speech_queue_index = 0
	# _play_speech_clip OWNS the skip-and-recurse loop for unplayable clips, so
	# one call walks the whole remaining queue exactly as the real player does.
	# (The harness must not advance the index itself - that would race the
	# function's own increment and overshoot the gate.)
	main._play_speech_clip()
	await process_frame
	# Invariant: pre-answer, playback must STOP at the teach boundary. The index
	# may rest ON the first teach clip (that is the gate), but it must never be
	# advanced past it, and no teach clip may ever be handed to the player.
	check(main.teach_from_index < 0 or main.speech_queue_index <= main.teach_from_index,
		"pre-answer playback advanced PAST the teach gate: index %d, gate %d (corrupt=%s)" %
			[main.speech_queue_index, main.teach_from_index, corrupt])
	var played_teach := false
	for ci in mini(main.speech_queue_index, main.speech_queue.size()):
		if bool(main.speech_queue[ci].get("teach", false)):
			played_teach = true
	check(not played_teach,
		"pre-answer playback narrated a teach clip (the answer) (corrupt=%s)" % corrupt)
	# The gate must also leave the UI in a sane state, not stuck on "Stop".
	if main.teach_from_index >= 0:
		check(main.read_button.text != "Stop",
			"teach gate left the Read button stuck on 'Stop' (corrupt=%s)" % corrupt)

func _audio_modes(main: Node) -> void:
	# Every autoplay goes through a token-guarded delay, and _show_menu bumps the
	# token, so nothing scheduled here can start real synthesis after the check.
	main._start_quiz(3, 9999, true, "SilentTest")
	check(main.session_audio_mode == AudioSettings.Mode.SILENT, "default session audio is Silent")
	check(main.session_muted, "Silent sessions start muted")
	check(not main.read_button.visible, "muted dock hides the Read button")
	main._toggle_session_mute()
	check(not main.session_muted and main.read_button.visible, "unmuting shows the Read button")
	main._show_menu()

	main.audio.mode = AudioSettings.Mode.AUTO
	main._start_quiz(80, 9999, true, "Full Journeyman Exam")
	check(main.session_audio_mode == AudioSettings.Mode.TAP, "simulator downgrades Auto-read to Tap")
	main._show_menu()

	# Auto-read: the rule is read by itself after answering, so the dock offers
	# a replay instead of asking the learner to push "Hear the rule".
	main.audio.mode = AudioSettings.Mode.AUTO
	main._start_quiz(3, 9999, true, "AutoTest")
	main.menu_overlay.visible = false
	main._show_question()
	main._auto_token += 1
	check(main.audio.auto_teach, "Auto-read reads the rule after answering by default")
	var auto_rec: Dictionary = main.records[main.order[main.current_index]]
	var token_before: int = main._auto_token
	main._answer_selected(int(auto_rec.get("correct_index", 0)))
	check(main.want_teach, "answering in Auto-read arms the teach read")
	check(AudioSettings.autoplays_teach(main.session_audio_mode, main.audio.auto_teach), "Auto-read session autoplays the rule")
	check(main._auto_token == token_before, "nothing cancels the scheduled rule read at answer time")
	check(main.read_button.text == "Replay rule", "Auto-read dock offers 'Replay rule', got '%s'" % main.read_button.text)
	main._auto_token += 1
	main.audio.auto_teach = false
	check(main._idle_read_label() == "Hear the rule", "with the rule read switched off the dock asks for it")
	main.audio.auto_teach = true
	main._show_menu()

	main.audio.mode = AudioSettings.Mode.TAP
	main._start_quiz(3, 9999, true, "TapTest")
	main.menu_overlay.visible = false
	main._show_question()
	var tap_rec: Dictionary = main.records[main.order[main.current_index]]
	main._answer_selected(int(tap_rec.get("correct_index", 0)))
	check(main.read_button.text == "Hear the rule", "Tap to hear keeps the manual 'Hear the rule' button, got '%s'" % main.read_button.text)
	main._auto_token += 1
	main._show_menu()

	main.audio.mode = AudioSettings.Mode.LISTEN
	main._start_quiz(3, 9999, true, "ListenTest")
	check(main.session_audio_mode == AudioSettings.Mode.LISTEN, "listen session mode")
	check(not main.timed_session, "listen sessions are untimed")
	main.menu_overlay.visible = false
	main._show_question()
	check(main.listen_phase == AudioSettings.ListenPhase.QUESTION, "listen starts in QUESTION phase")
	check(main.pause_button.visible and main.skip_button.visible, "listen dock shows Pause + Skip")
	check(not main.read_button.visible, "listen dock hides the Read button")
	var rec: Dictionary = main.records[main.order[main.current_index]]
	var wrong := (int(rec.get("correct_index", 0)) + 1) % (rec.get("answers", []) as Array).size()
	main._answer_selected(wrong)
	check(main.score == 0 and main.streak == 0 and main.missed_questions.is_empty(), "listen answers are not graded")
	check(main.chapter_stats.is_empty(), "listen answers stay out of the chapter breakdown")
	check(main.answered_count == 1, "listen still counts the item as reviewed")
	check(main.listen_phase == AudioSettings.ListenPhase.TEACH, "answering in listen moves to TEACH")
	main._toggle_listen_pause()
	check(main.listen_paused and main.pause_button.text == "Resume", "pause toggles to Resume")
	main._toggle_listen_pause()
	main._listen_skip()
	check(main.current_index == 1 and main.listen_phase == AudioSettings.ListenPhase.QUESTION, "skip advances to the next question")
	main._show_menu()
	check(main.listen_phase == AudioSettings.ListenPhase.IDLE, "menu ends the listen loop")
	main.audio = AudioSettings.new()
	await process_frame

func _voice_routing(main: Node) -> void:
	check(not main._clip_available("res://does_not_exist.mp3"), "a missing bundled clip reports available")
	check(main._load_clip("res://does_not_exist.mp3") == null, "a missing bundled clip loaded")
	# The bundle is gitignored; only check it where it has been generated.
	if DirAccess.dir_exists_absolute("res://assets/speech"):
		var rec: Dictionary = main.records[0]
		var qid := str(rec.get("id", "")).replace("/", "_")
		var folder: String = main._bundled_speech_folder(qid, main.BUNDLED_VOICE_ID, SpeechText.speech_plan(rec))
		check(folder != "", "record 0 has no bundled clips at the current rules/format")
		if folder != "":
			var clip = main._load_clip(folder.path_join("0.mp3"))
			check(clip is AudioStream and clip.get_length() > 0.5,
				"bundled clip does not load through ResourceLoader (what an exported build uses)")
		var preview_segs := [{"text": main.PREVIEW_TEXT, "choice": -1, "teach": false}]
		check(main._bundled_speech_folder(main.PREVIEW_ID, main.BUNDLED_VOICE_ID, preview_segs) != "",
			"the voice preview line is not bundled")
	if main.ui_mobile:
		main._populate_voice_picker_native()
		check(main.voice_picker.get_item_text(0) == main.BUNDLED_VOICE_LABEL,
			"mobile picker does not list the recorded voice first: '%s'" % main.voice_picker.get_item_text(0))
		main.voice_picker.selected = 0
		check(main._selected_voice_id() == main.BUNDLED_VOICE_ID, "recorded voice entry has the wrong id")
		check(main._pick_native_voice() != main.BUNDLED_VOICE_ID,
			"native fallback was handed the recorded voice id instead of a device voice")
		var edge_rows := VoiceCatalog.edge_voice_rows().size()
		check(edge_rows > 0 and main.voice_picker.get_item_text(1).ends_with(" · " + VoiceCatalog.EDGE_TAG),
			"mobile picker does not list the online Edge voices after the recorded one")
		for i in range(1, main.voice_picker.item_count):
			var label: String = main.voice_picker.get_item_text(i)
			if i <= edge_rows:
				check(label.ends_with(" · " + VoiceCatalog.EDGE_TAG), "Edge voice row %d out of place: '%s'" % [i, label])
			else:
				check(label == VoiceCatalog.SYSTEM_DEFAULT_LABEL or label.contains(" · US English · "),
					"device voice without a friendly US English label: '%s'" % label)

func _thread_join(main: Node) -> void:
	# Start a thread on speak_thread, then check the node joins it before the
	# tree tears down.
	main.speak_thread = Thread.new()
	main.speak_thread.start(func() -> void: OS.delay_msec(50))
	check(main.speak_thread.is_started(), "thread started for join test")
	# The app must provide a cleanup hook that joins the thread.
	check(main.has_method("_exit_tree") or main.has_method("_join_speak_thread"),
		"no thread-join hook on the node (thread destroyed unjoined at exit)")
	if main.has_method("_exit_tree"):
		main._exit_tree()
		await process_frame
	check(not main.speak_thread.is_started(), "thread still running after cleanup")

func _stale_callback(main: Node) -> void:
	# Race: user taps Read on question N (thread A starts, speak_busy=true,
	# generation=G1), taps Stop, then taps Read again on the SAME question
	# (thread B starts, speak_busy=true, generation=G2). Thread A now finishes
	# late and calls _on_speech_ready(G1).
	#
	# A stale callback must not clear speak_busy: that flag belongs to thread B.
	# Clearing it lets _toggle_read start a THIRD synthesis and, worse, replaces
	# speak_thread while thread B is still running, destroying it unjoined.
	main._start_quiz(3, 9999, false, "StaleTest")
	await process_frame
	main._show_question()
	main.current_answered = false
	main.menu_overlay.visible = false

	main.speak_generation += 1
	var stale_gen: int = main.speak_generation          # G1: thread A
	main.speak_busy = true

	# Stop, then Read again: this is thread B's generation.
	main._stop_reading()
	main.speak_generation += 1
	var live_gen: int = main.speak_generation           # G2: thread B, in flight
	main.speak_busy = true
	main.speech_queue.clear()
	main.speech_queue.append({"path": "res://does_not_exist.mp3", "choice": 0, "teach": false})
	main.teach_from_index = -1
	main.speech_queue_index = 0
	var before: int = main.speech_queue_index
	var before_size: int = main.speech_queue.size()

	check(stale_gen < live_gen, "test setup: stale generation is older")
	# Thread A's late callback arrives.
	main._on_speech_ready(stale_gen, "res://nope", 0, "stale")
	await process_frame

	check(main.speak_busy,
		"stale speech callback cleared speak_busy for the in-flight request G%d (was G%d); " % [live_gen, stale_gen] +
		"Read button now starts a duplicate synthesis and orphans the running thread")
	check(main.speech_queue_index == before,
		"stale speech callback advanced the live queue: %d -> %d" % [before, main.speech_queue_index])
	check(main.speech_queue.size() == before_size,
		"stale speech callback rebuilt the live queue: %d -> %d clips" % [before_size, main.speech_queue.size()])
	# Clean up the simulated in-flight state.
	main.speak_busy = false
