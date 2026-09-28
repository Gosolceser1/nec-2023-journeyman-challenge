extends SceneTree
## The desktop streaming read: Edge voices come from the built-in
## EdgeTtsClient, exactly like the phone, against a local fake of the
## read-aloud service (tools/tests/fake_edge_server.gd), so no network is
## needed. PATH is emptied first: nothing here may depend on Python.
##
## The promises: no Python helper node exists and no process is started; the
## desktop picker keeps its full list (Ryan included); prefetch fills the cache
## for the current and next question, a cached read starts at once, a streamed
## read waits ("PREPARING") and then plays from the stem, Stop while waiting
## plays nothing, the rule never plays before answering, "Hear the rule" reuses
## the full-question cache, and with no internet the read falls back to the
## recorded Andrew (else the system voice) and says so.

const SpeechText = preload("res://src/speech/speech_text.gd")
const FakeEdge = preload("res://tools/tests/fake_edge_server.gd")
const AVA := "en-US-AvaNeural"
const RYAN := "en-GB-RyanNeural"
const ROOT := "user://desktop_edge_test"
const BUDGET_MSEC := 100

var failures: Array[String] = []
var checks := 0
var fake := FakeEdge.new()
var worst := 0


func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func _initialize() -> void:
	_run()


func _run() -> void:
	fake.audio = _fixture_audio()
	if fake.audio.is_empty():
		# assets/speech is gitignored, so a fresh clone or CI has no clip to serve.
		print("SKIPPED: no bundled clip under res://assets/speech (gitignored; build it with")
		print("  python tools/speech/pregenerate_speech.py --bundle). Desktop Edge checks not run.")
		_finish()
		return
	OS.set_environment("PATH", "")
	check(fake.listen() > 0, "the fake Edge service listens")
	_wipe(ProjectSettings.globalize_path(ROOT))
	await _game_flow()
	fake.stop()
	_wipe(ProjectSettings.globalize_path(ROOT))
	_finish()


func _finish() -> void:
	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _game_flow() -> void:
	print("=== desktop: built-in Edge client, no Python ===")
	var main = load("res://scenes/main.tscn").instantiate()
	main.audio_cfg_path = ROOT + "/audio.cfg"
	main.voice_cfg_path = ROOT + "/voice.cfg"
	main.speech_cache_root = ROOT + "/cache"
	root.add_child(main)
	await process_frame
	if main.ui_mobile:
		check(true, "mobile layout: covered by test_voice_picker")
		main.queue_free()
		return
	main.edge_client.url = fake.url()
	main.edge_client.offline_until_msec = 0

	var helper_nodes: Array = main.find_children("*", "", true, false).filter(func(n: Node) -> bool:
		var s: Script = n.get_script()
		return s != null and s.resource_path.contains("speech_helper"))
	check(helper_nodes.is_empty(), "no Python speech helper node in the scene")
	check(not ("speech_helper" in main.speech), "the speech controller has no Python backend")
	check(main.edge_client is EdgeTtsClient, "the desktop has the built-in Edge client")
	var ids: Array = main.voice_ids.values()
	check(ids.has(AVA) and ids.has(RYAN) and ids.has(VoiceCatalog.BUNDLED_VOICE_ID), "the desktop picker keeps Andrew, Ava and Ryan (British)")

	_select_voice(main, AVA)
	main._start_quiz(5, 10, false, "Desktop Edge test")
	main.session_muted = false
	main._show_question()
	await process_frame

	var q0: Dictionary = main.records[main.order[0]]
	var q1: Dictionary = main.records[main.order[1]]
	var f0: String = main._speech_cache_folder(main._safe_speech_id(str(q0["id"])), AVA)
	var f1: String = main._speech_cache_folder(main._safe_speech_id(str(q1["id"])), AVA)
	check(main.edge_client.busy_request_for(f0) >= 0, "showing a question prefetches it")
	check(main.edge_client.busy_request_for(f1) >= 0, "showing a question prefetches the next one")
	check(await _until(func() -> bool: return main._speech_cache_matches(f0, SpeechText.speech_plan(q0)) and main._speech_cache_matches(f1, SpeechText.speech_plan(q1)), 15.0),
		"prefetch leaves both full plans cached")
	check(fake.ssml.any(func(s: String) -> bool: return s.contains("AvaNeural")), "the clips were synthesized with Ava")

	main._begin_reading(SpeechText.speech_plan(q0))
	check(main.reader.playing, "a cached read starts in the same frame")
	check(main.speech_queue_index == 0, "a read starts at the stem")
	var teach_idx: int = main.teach_from_index
	check(teach_idx > 0, "the cached queue carries the rule after the choices")
	main._stop_reading()

	main.current_answered = true
	main.want_teach = true
	var requests_before: int = main.edge_client._next_id
	main._begin_reading(SpeechText.teach_segments(q0))
	check(main.reader.playing and main.speech_queue_index == teach_idx, "'Hear the rule' plays the cached tail")
	check(main.edge_client._next_id == requests_before, "'Hear the rule' synthesizes nothing new")
	main._stop_reading()
	main.current_answered = false

	_wipe(f0)
	worst = 0
	var t0 := Time.get_ticks_msec()
	main._begin_reading(SpeechText.speech_plan(q0))
	check(Time.get_ticks_msec() - t0 < BUDGET_MSEC, "Read returns at once while the clips are fetched")
	check(main.speak_busy and not main.reader.playing, "an uncached read waits for its first clip")
	check(main.read_status_label.text.begins_with("PREPARING AVA"), "the wait says it is preparing Ava (got %s)" % main.read_status_label.text)
	check(await _until(func() -> bool: return main.reader.playing, 5.0), "the stem plays as soon as its clip lands")
	check(main._voice_fallback == "" and main._live_request >= 0, "Ava streams through the built-in client, no fallback")
	check(main.speech_queue_index == 0 and not main.speak_busy, "streamed playback starts at the stem")
	var first_teach: int = main.teach_from_index
	main.speech_queue_index = first_teach - 1
	main._halt_player()
	main._on_reader_finished()
	check(not main.reader.playing and main.speech_queue_index == first_teach, "the rule does not play before answering")
	main._stop_reading()
	check(worst < BUDGET_MSEC, "no frame over %d ms while streaming (worst %d)" % [BUDGET_MSEC, worst])
	await _until(func() -> bool: return main.edge_client.busy_request_for(f0) < 0, 5.0)

	_wipe(f0)
	main._begin_reading(SpeechText.speech_plan(q0))
	main._stop_reading()
	check(main._live_request == -1, "Stop detaches from the Edge request")
	check(await _until(func() -> bool: return main._speech_cache_matches(f0, SpeechText.speech_plan(q0)), 5.0),
		"a stopped read still finishes into the cache")
	await _until(func() -> bool: return false, 0.5)
	check(not main.reader.playing, "Stop while preparing plays nothing later")

	_select_voice(main, RYAN)
	main.speech._preview_voice()
	check(await _until(func() -> bool: return main.reader.playing, 5.0), "the Ryan preview streams on the desktop")
	check(fake.ssml.any(func(s: String) -> bool: return s.contains("RyanNeural") and s.contains("en-GB")), "Ryan is asked for as the British voice")
	main.speech._preview_voice()
	main._stop_reading()
	_select_voice(main, AVA)

	# No internet: fall back to the recorded Andrew (or the system voice), never hang.
	main.edge_client.url = "wss://no-such-host.invalid/edge/v1"
	_wipe(f0)
	worst = 0
	t0 = Time.get_ticks_msec()
	main._begin_reading(SpeechText.speech_plan(q0))
	check(Time.get_ticks_msec() - t0 < BUDGET_MSEC, "Read with no internet returns at once")
	check(await _until(func() -> bool: return main._voice_fallback != "", 3.0), "with no internet the read falls back within 3 s")
	var q0_bundled: bool = main._bundled_speech_folder(main._safe_speech_id(str(q0["id"])), VoiceCatalog.BUNDLED_VOICE_ID, SpeechText.speech_plan(q0)) != ""
	var want := "Andrew (recorded, no internet)" if q0_bundled else "System voice (no internet)"
	check(main._voice_fallback == want, "a failed Edge voice falls back to the recorded Andrew, else the system voice (%s)" % main._voice_fallback)
	if q0_bundled:
		check(main.reader.playing and not bool(main.speech_queue[main.speech_queue_index]["teach"]), "the recorded Andrew reads the question, not the rule")
	check(main._status_with_voice("READING").contains(want), "the status line names the voice actually speaking")
	check(not main._status_with_voice("READING").contains("Ava"), "the status line never claims Ava after a fallback")
	check(worst < BUDGET_MSEC, "no frame over %d ms while failing (worst %d)" % [BUDGET_MSEC, worst])
	main._stop_reading()
	main.current_index = 1
	main._begin_reading(SpeechText.speech_plan(q1))
	check(main.reader.playing and main._voice_fallback == "", "a later cached read clears the fallback label")
	main._stop_reading()
	main.edge_client.offline_until_msec = 0
	# The audio thread drops stopped playbacks on a later mix; quitting before
	# that reports the last clips as leaked.
	main.reader.stream = null
	await create_timer(0.5).timeout
	main.queue_free()
	await process_frame


func _select_voice(main: Node, voice_id: String) -> void:
	for i in main.voice_picker.item_count:
		if str(main.voice_ids.get(main.voice_picker.get_item_text(i), "")) == voice_id:
			main.voice_picker.selected = i
			return


func _fixture_audio() -> PackedByteArray:
	var speech := ProjectSettings.globalize_path("res://assets/speech")
	if DirAccess.dir_exists_absolute(speech):
		for dir in DirAccess.get_directories_at(speech):
			var clip := speech.path_join(dir).path_join("0.mp3")
			if FileAccess.file_exists(clip):
				return FileAccess.get_file_as_bytes(clip)
	return PackedByteArray()


## Waits for `pred`, serving the fake Edge service every frame and recording
## the slowest frame in `worst`.
func _until(pred: Callable, limit_s: float) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < limit_s * 1000.0:
		if pred.call():
			return true
		var tf := Time.get_ticks_msec()
		fake.poll()
		await process_frame
		worst = maxi(worst, Time.get_ticks_msec() - tf)
	return pred.call()


func _wipe(folder: String) -> void:
	if not DirAccess.dir_exists_absolute(folder):
		return
	for sub in DirAccess.get_directories_at(folder):
		_wipe(folder.path_join(sub))
	for f in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(f))
	DirAccess.remove_absolute(folder)
