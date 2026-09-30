extends SceneTree
## Show steps' Read: what the voice says for every step, and how Read behaves.
##
## Text: every step of every exam calculation solution and generated trainer
## problems of every type and level read as whole sentences (title, text,
## worked lines, note, calculator keys), with no raw math symbol, no quantity
## read as a Code section and every calculator key named.
## Screen: Read turns into Stop while reading; Stop, Next, Back, Done and Close
## stop it; Voice off hides Read; Auto-read reads each step; a step read never
## drives the quiz's Read button or its hands-free loop; the offline fallback
## says which voice it used.
##
##   Godot --headless --path . --script tools/tests/test_math_voice.gd

const MathStepSpeech = preload("res://src/speech/math_step_speech.gd")
const SpeechText = preload("res://src/speech/speech_text.gd")
const SEEDS_PER_LEVEL := 5

var failures: Array[String] = []
var checks := 0
var main: Main


func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func _frames(n: int = 3) -> void:
	for i in n:
		await process_frame


func _initialize() -> void:
	print("=== math steps voice ===")
	_spoken_text()
	MathHub.stats_path = "user://test_math_voice_stats.cfg"
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	main = load("res://scenes/main.tscn").instantiate()
	main.audio_cfg_path = "user://test_math_voice_audio.cfg"
	main.speech.voice_cfg_path = "user://test_math_voice_voice.cfg"
	main.speech.speech_cache_root = "user://test_math_voice_speech"
	main.session.bag_path = ""
	root.add_child(main)
	await _frames(10)
	await _view_read_stop()
	await _hub_voice_rules()
	await _controller_external()
	MathStats.new(MathHub.stats_path).reset()
	print("checks: %d  failures: %d" % [checks, failures.size()])
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)


# --- spoken text ----------------------------------------------------------------

func _spoken_text() -> void:
	var bank = JSON.parse_string(FileAccess.get_file_as_string("res://data/question_bank.json"))
	var sols: Array = []
	for rec in bank.get("records", []):
		var sol := MathEngine.exam_solution(rec)
		if sol.get("ok", false):
			sols.append([str(rec.get("id", "")), sol["steps"]])
	check(sols.size() >= 70, "exam step solutions (%d)" % sols.size())
	var exam_steps := 0
	for s in sols:
		exam_steps += (s[1] as Array).size()
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var types := 0
	for def in MathData.types():
		types += 1
		for level in MathEngine.level_ids():
			for n in SEEDS_PER_LEVEL:
				var gen := MathEngine.generate(str(def["id"]), level, rng)
				if not gen.is_empty():
					sols.append(["%s L%d #%d" % [def["id"], level, n], gen["steps"]])
	check(types >= 58, "every trainer type sampled (%d)" % types)
	var raw := ["×", "÷", "√", "²", "³", "φ", "Ω", "{", "}", "≈", "≤", "≥", "=", "%", "^", "[", "]", "*"]
	var arith := RegEx.create_from_string("(?:divided by|times|equals|plus|minus|over) section\\b")
	var hack := RegEx.create_from_string("(?<!section |Section |Table |table |article |Article )\\b\\d+ point \\d")
	var number := RegEx.create_from_string("^[\\d.,]+$")
	var last_word := RegEx.create_from_string("([A-Za-z0-9]+)[^A-Za-z0-9]*$")
	var unknown_keys := {}
	var spoken := 0
	for s in sols:
		var id: String = s[0]
		var steps: Array = s[1]
		for i in steps.size():
			var step: Dictionary = steps[i]
			var said := MathStepSpeech.spoken(step)
			var where := "%s step %d" % [id, i + 1]
			spoken += 1
			if said.strip_edges() == "":
				check(false, "%s: says something" % where)
				continue
			check(said.ends_with(".") or said.ends_with("?") or said.ends_with("!"), "%s ends a sentence: %s" % [where, said])
			for sym in raw:
				if said.contains(sym):
					check(false, "%s spoken without '%s': %s" % [where, sym, said])
			check(arith.search(said) == null, "%s: no quantity read as a section: %s" % [where, said])
			check(hack.search(said) == null, "%s: a decimal is read as a number, not 'N point M': %s" % [where, said])
			check(not said.contains("per square feet"), "%s: 'per square foot': %s" % [where, said])
			check(not said.contains(".."), "%s: no doubled stop: %s" % [where, said])
			# Every part is there to its end: no part is cut off.
			for part in [str(step.get("title", "")), str(step.get("text", "")), str(step.get("note", ""))] + Array(step.get("lines", [])):
				var m := last_word.search(SpeechText.speakable(str(part)))
				if m != null and not said.contains(m.get_string(1)):
					check(false, "%s reads '%s' to its end: %s" % [where, part, said])
			for field in ["keys", "basic"]:
				var keys := str(step.get(field, "")).strip_edges()
				if keys == "":
					continue
				check(said.contains("On the calculator, press" if field == "keys" else "On a basic calculator, press"),
					"%s reads its %s: %s" % [where, field, said])
				for key in keys.split(" ", false):
					if not MathStepSpeech.KEY_WORDS.has(key) and number.search(key) == null:
						unknown_keys[key] = where
	check(unknown_keys.is_empty(), "every calculator key has a spoken name: %s" % str(unknown_keys))
	check(spoken > exam_steps, "steps spoken: %d (%d exam)" % [spoken, exam_steps])
	print("  spoken steps: %d (exam %d)" % [spoken, exam_steps])
	# The keys read as a sequence of named presses.
	check(MathStepSpeech.key_words("277 × 1.732 = M+") == "277, times, 1.732, equals, memory plus", "key sequence named")
	var sample := MathStepSpeech.spoken({"title": "Multiply by 1.25", "text": "40 A × 1.25 = 50 A",
		"keys": "40 × 1.25 =", "note": "Table 310.16 (see 240.4(D))"})
	check(sample.begins_with("Multiply by 1.25. 40 amps times 1.25 equals 50 amps."), "title, then working: %s" % sample)
	check(sample.contains("section 240 point 4, paragraph D") and sample.contains("Table 310 point 16"), "Code references still read as sections: %s" % sample)
	check(sample.ends_with("On the calculator, press 40, times, 1.25, equals."), "keys last: %s" % sample)
	check(MathStepSpeech.spoken({"text": "199,526 VA ÷ 831.36 = 240 A"}).contains("divided by 831.36"), "÷ 831.36 is a number")
	check(MathStepSpeech.folder_id("final-exam-#1/014", 2) == "math_final-exam-#1_014_s2", "step folder id")


# --- the steps view ---------------------------------------------------------------

func _view_read_stop() -> void:
	var calls: Array = []
	var view := MathStepsView.new(false)
	root.add_child(view)
	var sol := {}
	for rec in main.records:
		sol = MathEngine.exam_solution(rec)
		if sol.get("ok", false) and (sol["steps"] as Array).size() >= 3:
			break
	view.speak = func(folder: String, plan: Array, on_state: Callable) -> void:
		calls.append(["speak", folder, plan])
		on_state.call(true, "")
	view.stop = func() -> void:
		calls.append(["stop"])
	view.show_solution(sol)
	await _frames(2)
	var read_button := view._read
	check(read_button.visible and read_button.text == "Read", "Read shown while voice is on")
	read_button.pressed.emit()
	check(calls.size() == 1 and calls[0][0] == "speak", "Read speaks the step")
	check(calls[0][1] == MathStepSpeech.folder_id(str(sol["record_id"]), 0), "exam step reads its recorded folder: %s" % str(calls[0][1]))
	check((calls[0][2] as Array)[0]["text"] == MathStepSpeech.spoken(sol["steps"][0]), "the plan is the step's spoken text")
	check(view.reading and read_button.text == "Stop", "button says Stop while reading")
	read_button.pressed.emit()
	check(calls.back()[0] == "stop" and not view.reading and read_button.text == "Read", "Stop stops it")
	read_button.pressed.emit()
	calls.clear()
	view._go(1)
	check(not calls.is_empty() and calls[0][0] == "stop" and not view.reading and read_button.text == "Read", "Next step stops the voice")
	read_button.pressed.emit()
	calls.clear()
	view._go(-1)
	check(not calls.is_empty() and calls[0][0] == "stop" and not view.reading, "Previous step stops the voice")
	view.set_reading(true, "System voice (no internet)")
	check(view._voice_note.visible and view._voice_note.text == "System voice (no internet)", "fallback voice named under the buttons")
	view.set_reading(false, "")
	check(not view._voice_note.visible, "note hidden when idle")
	view.index = (view.steps as Array).size() - 1
	read_button.pressed.emit()
	calls.clear()
	view._go(1)
	check(not calls.is_empty() and calls[0][0] == "stop", "Done stops the voice")
	# Generated problems have no record: the step's text names its cache folder.
	var gen := MathEngine.generate(str(MathData.types()[0]["id"]), 1, RandomNumberGenerator.new())
	view.show_solution(gen)
	calls.clear()
	read_button.pressed.emit()
	check(str(calls[0][1]).begins_with("math_live_"), "trainer step reads live: %s" % str(calls[0][1]))
	# Auto-read: each step reads itself when shown.
	view.auto_read = true
	calls.clear()
	view.show_solution(sol)
	await _frames(2)
	check(calls.any(func(c): return c[0] == "speak" and c[1] == MathStepSpeech.folder_id(str(sol["record_id"]), 0)), "Auto-read reads the first step")
	calls.clear()
	view._go(1)
	await _frames(2)
	check(calls.size() >= 2 and calls[0][0] == "stop" and calls.back()[0] == "speak" \
		and calls.back()[1] == MathStepSpeech.folder_id(str(sol["record_id"]), 1), "Auto-read: Next stops, then reads the next step")
	# Voice off: no speak Callable, no Read.
	var quiet := MathStepsView.new(false)
	root.add_child(quiet)
	quiet.show_solution(sol)
	check(not quiet._read.visible, "no Read without a voice")
	quiet.queue_free()
	calls.clear()
	view.set_reading(true, "")
	view.queue_free()
	await _frames(2)
	check(calls.any(func(c): return c[0] == "stop"), "leaving the screen stops the voice")


# --- the hub: voice settings ------------------------------------------------------

func _find_type(node: Node, cls: String) -> Node:
	if node.get_class() == cls or (node.get_script() != null and node.get_script().get_global_name() == cls):
		return node
	for c in node.get_children():
		var f := _find_type(c, cls)
		if f != null:
			return f
	return null


func _hub_voice_rules() -> void:
	var hub := MathHub.hub(main)
	var record := {}
	for rec in main.records:
		if MathEngine.exam_solution(rec).get("ok", false):
			record = rec
			break
	# From the menu: the menu's voice mode decides.
	main.menu_overlay.visible = true
	main.audio.mode = AudioSettings.Mode.SILENT
	check(not hub.can_speak(), "menu: Silent mode hides Read")
	main.audio.mode = AudioSettings.Mode.TAP
	check(hub.can_speak() and not hub.auto_reads(), "menu: Tap to read shows Read, no auto-read")
	main.audio.mode = AudioSettings.Mode.AUTO
	check(hub.auto_reads(), "menu: Auto-read reads each step")
	# Over the quiz: the session's mute and mode decide.
	main._start_quiz(10, 1800, true, "10-Question Practice")
	main.timer.stop()
	while main._start_tween != null and main._start_tween.is_running():
		await process_frame
	main.menu_overlay.visible = false
	main.session_audio_mode = AudioSettings.Mode.TAP
	main.session_muted = true
	check(not hub.can_speak(), "quiz: Voice off hides Read")
	MathHub.open_solution(main, record)
	await _frames(2)
	var view := _find_type(hub.current_screen(), "MathStepsView") as MathStepsView
	check(view != null and not view._read.visible, "quiz muted: steps have no Read")
	hub.close()
	main.session_muted = false
	check(hub.can_speak() and not hub.auto_reads(), "quiz: voice on, Tap mode: Read, no auto-read")
	main.session_audio_mode = AudioSettings.Mode.AUTO
	check(hub.auto_reads(), "quiz: Auto-read mode reads each step")
	main.session_audio_mode = AudioSettings.Mode.TAP
	MathHub.open_solution(main, record)
	await _frames(2)
	view = _find_type(hub.current_screen(), "MathStepsView") as MathStepsView
	check(view != null and view._read.visible and view.speak.is_valid() and view.stop.is_valid(), "quiz voice on: Read wired to the app voice")
	hub.close()


# --- the speech controller: a step read beside the quiz ---------------------------

func _controller_external() -> void:
	var sp := main.speech
	var states: Array = []
	var on_state := func(playing: bool, note: String) -> void:
		states.append([playing, note])
	var quiz_label := main.read_button.text
	var phase_before := main.listen_phase
	# Offline, the recorded voice selected, a trainer step (no recording):
	# the system voice reads it and says so.
	var client := sp.edge_client
	sp.edge_client = null
	sp._select_voice_id(VoiceCatalog.BUNDLED_VOICE_ID)
	var step := {"title": "Multiply", "text": "40 A × 1.25 = 50 A"}
	sp.read_external(MathStepSpeech.live_id(step), MathStepSpeech.plan(step), on_state)
	check(sp.is_reading_external(), "a step read is running")
	check(not states.is_empty() and states.back()[0] and str(states.back()[1]).contains("no internet"),
		"offline: the fallback voice is named: %s" % str(states))
	check(main.read_button.text == quiz_label, "the quiz's Read button is untouched")
	sp.stop_external()
	check(not sp.is_reading_external() and not states.back()[0], "Stop ends the step read")
	check(main.listen_phase == phase_before, "the quiz's hands-free loop did not move")
	# Offline with an online voice picked: an exam step falls back to its recording.
	var edge_id := ""
	for label in sp.voice_ids:
		var id := str(sp.voice_ids[label])
		if VoiceCatalog.is_edge_voice(id) and id.replace("Multilingual", "") != VoiceCatalog.BUNDLED_VOICE_ID:
			edge_id = id
			break
	var rec := {}
	for r in main.records:
		if MathEngine.exam_solution(r).get("ok", false):
			rec = r
			break
	var sol := MathEngine.exam_solution(rec)
	var sid := MathStepSpeech.folder_id(str(rec["id"]), 0)
	var plan := MathStepSpeech.plan(sol["steps"][0])
	var recorded: bool = sp._bundled_speech_folder(sid, VoiceCatalog.BUNDLED_VOICE_ID, plan) != ""
	# The clips are gitignored: a fresh checkout (CI) has no assets/speech.
	if DirAccess.dir_exists_absolute("res://assets/speech"):
		check(recorded, "exam step 1 of %s is recorded" % sid)
	if edge_id != "" and recorded:
		sp._select_voice_id(edge_id)
		states.clear()
		sp.read_external(sid, plan, on_state)
		check(not states.is_empty() and str(states.back()[1]).begins_with("Andrew (recorded"),
			"offline online-voice: the recorded Andrew reads it: %s" % str(states))
		check(sp.reader.playing or sp.speak_busy or sp.is_reading_external(), "the recording plays")
		sp.stop_external()
	# With the recorded voice, an exam step plays its bundle clip straight away.
	if recorded:
		sp._select_voice_id(VoiceCatalog.BUNDLED_VOICE_ID)
		states.clear()
		sp.read_external(sid, plan, on_state)
		check(not states.is_empty() and states[0][0] and states[0][1] == "", "recorded step: no fallback note")
		check(sp.reader.playing, "recorded step plays")
		# The end of the clip ends the step read, not the quiz's loop.
		var old_complete := main.listen_phase
		sp._on_reader_finished()
		check(not sp.is_reading_external() and not states.back()[0], "the end of the step's clip ends the read")
		check(main.listen_phase == old_complete, "the end of a step read does not drive the quiz loop")
	# A new step read replaces the old one (no overlap).
	states.clear()
	var other: Array = []
	sp.read_external(MathStepSpeech.live_id(step), MathStepSpeech.plan(step), on_state)
	sp.read_external(MathStepSpeech.live_id(step), MathStepSpeech.plan(step), func(p: bool, n: String) -> void: other.append([p, n]))
	check(not states.is_empty() and not states.back()[0], "the first read hears it was stopped")
	check(not other.is_empty() and other.back()[0], "the second read plays")
	sp.stop_external()
	# The quiz cannot start reading under the steps overlay.
	var hub := MathHub.hub(main)
	hub.visible = true
	sp._begin_reading(SpeechText.speech_plan(main.records[0]))
	check(not sp.reader.playing and not sp._native_active, "the quiz does not read under Show steps")
	hub.visible = false
	sp.edge_client = client
