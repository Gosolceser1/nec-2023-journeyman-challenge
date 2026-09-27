extends SceneTree
## SpeechHelper + the desktop streaming read, against the real
## speak_question.py --serve in fake mode (SPEECH_FAKE_CLIP: copies a fixture
## clip instead of calling Edge), so no network is needed.
##
## The promises: clips stream back and the manifest lands last; requests for
## one folder are shared; cancel leaves no clips; a failure or a missing Python
## is reported with a reason. In the game: prefetch fills the cache for the
## current and next question, a cached read starts at once, a streamed read
## waits ("PREPARING") and then plays from the stem, Stop while waiting plays
## nothing, the rule never plays before answering, "Hear the rule" reuses the
## full-question cache, and a failed Edge voice is labelled as the system voice.

const SpeechText = preload("res://speech_text.gd")
const BRIAN := "en-US-BrianNeural"
const ROOT := "user://speech_helper_test"

var failures: Array[String] = []
var checks := 0
var events: Array = []


func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func _initialize() -> void:
	_run()


func _run() -> void:
	var fixture := _fixture_clip()
	check(fixture != "", "a fixture MP3 exists under res://speech")
	if fixture == "":
		_finish()
		return
	OS.set_environment("SPEECH_FAKE_CLIP", fixture)
	OS.set_environment("SPEECH_FAKE_DELAY", "0.15")
	_wipe(ProjectSettings.globalize_path(ROOT))

	await _helper_protocol()
	await _helper_failures()
	await _game_flow()
	_wipe(ProjectSettings.globalize_path(ROOT))
	_finish()


func _finish() -> void:
	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _helper_protocol() -> void:
	print("=== helper protocol ===")
	var helper := SpeechHelper.new()
	root.add_child(helper)
	helper.clip_ready.connect(func(id: int, index: int) -> void: events.append(["clip", id, index]))
	helper.request_done.connect(func(id: int) -> void: events.append(["done", id]))
	check(helper.start(), "helper starts")
	check(await _until(func() -> bool: return helper.state == SpeechHelper.State.READY, 10.0), "helper reports ready")

	var folder := ProjectSettings.globalize_path(ROOT).path_join("proto")
	var segs := [{"text": "one", "choice": -1}, {"text": "  ", "choice": 0}, {"text": "three", "choice": 1, "teach": true}]
	var id := helper.request(folder, BRIAN, segs, SpeechHelper.PRIO_PREFETCH)
	check(id > 0, "request gets an id")
	check(helper.request(folder, BRIAN, segs, SpeechHelper.PRIO_LIVE) == id, "a second request for the same folder is shared")
	check(await _until(func() -> bool: return helper.status(id) == "done", 5.0), "request completes")
	var clips := events.filter(func(e: Array) -> bool: return e[0] == "clip" and e[1] == id).map(func(e: Array) -> int: return e[2])
	clips.sort()
	check(clips == [0, 2], "a clip event per non-empty segment, by segment index (got %s)" % str(clips))
	var done_at := events.find(["done", id])
	check(done_at > 0 and events.slice(0, done_at).filter(func(e: Array) -> bool: return e[0] == "clip").size() == 2, "done comes after every clip")
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("manifest.json")))
	check(manifest is Array and manifest.size() == 2, "manifest lists the two spoken clips")
	check(manifest is Array and str(manifest[1].get("file", "")) == "2.mp3" and bool(manifest[1].get("teach", false)), "manifest rows keep file index and teach flag")
	check(not _has_part(folder), "no .part files left")

	var cancel_folder := ProjectSettings.globalize_path(ROOT).path_join("cancel")
	var cid := helper.request(cancel_folder, BRIAN, segs, SpeechHelper.PRIO_PREFETCH)
	helper.cancel(cid)
	check(helper.status(cid) == "cancelled", "cancel marks the request")
	await _sleep(0.8)
	check(not FileAccess.file_exists(cancel_folder.path_join("manifest.json")), "a cancelled request writes no manifest")
	check(_mp3_count(cancel_folder) == 0 and not _has_part(cancel_folder), "a cancelled request leaves no clips")
	check(helper.busy_request_for(cancel_folder) < 0, "a cancelled request is not reused")

	var live_a := helper.request(ProjectSettings.globalize_path(ROOT).path_join("a"), BRIAN, segs, SpeechHelper.PRIO_LIVE)
	var live_b := helper.request(ProjectSettings.globalize_path(ROOT).path_join("b"), BRIAN, segs, SpeechHelper.PRIO_LIVE)
	check(helper.status(live_a) == "cancelled", "a new live read cancels the previous live read")
	check(await _until(func() -> bool: return helper.status(live_b) == "done", 5.0), "the new live read completes")

	helper.stop()
	helper.queue_free()


func _helper_failures() -> void:
	print("=== helper failures ===")
	var helper := SpeechHelper.new()
	root.add_child(helper)
	var reasons: Array = []
	helper.request_failed.connect(func(_id: int, why: String) -> void: reasons.append(why))
	OS.set_environment("SPEECH_FAKE_FAIL", "1")
	var folder := ProjectSettings.globalize_path(ROOT).path_join("fail")
	var id := helper.request(folder, BRIAN, [{"text": "x", "choice": -1}], SpeechHelper.PRIO_LIVE)
	OS.set_environment("SPEECH_FAKE_FAIL", "")
	check(await _until(func() -> bool: return helper.status(id) == "failed", 10.0), "a failing clip fails the request")
	check(not reasons.is_empty() and str(reasons[0]).contains("fake failure"), "the failure carries the helper's reason (got %s)" % str(reasons))
	check(_mp3_count(folder) == 0 and not FileAccess.file_exists(folder.path_join("manifest.json")), "a failed request leaves no clips or manifest")

	var pid_before := helper._pid
	OS.kill(pid_before)
	reasons.clear()
	var orphan := helper.request(ProjectSettings.globalize_path(ROOT).path_join("orphan"), BRIAN, [{"text": "x", "choice": -1}], SpeechHelper.PRIO_LIVE)
	check(await _until(func() -> bool: return helper.status(orphan) == "failed", 5.0), "a helper that dies fails its requests")
	check(not reasons.is_empty() and str(reasons[0]).begins_with("speech helper exited"), "death is reported as such (got %s)" % str(reasons))
	check(helper.start() and helper._pid != pid_before, "a dead helper restarts on the next request")
	helper.stop()
	helper.queue_free()

	var missing := SpeechHelper.new()
	root.add_child(missing)
	missing.python = "no-such-python-exe"
	check(not missing.start(), "no Python: start fails")
	check(missing.fail_reason == "Python not found", "no Python: reason says so (got %s)" % missing.fail_reason)
	check(missing.request("x", BRIAN, [], 0) == -1, "no Python: requests are refused")
	missing.queue_free()


func _game_flow() -> void:
	print("=== game: prefetch, stream, cancel, cache ===")
	var main = load("res://Main.tscn").instantiate()
	main.audio_cfg_path = ROOT + "/audio.cfg"
	main.voice_cfg_path = ROOT + "/voice.cfg"
	main.speech_cache_root = ROOT + "/cache"
	root.add_child(main)
	await process_frame
	if main.ui_mobile:
		check(true, "mobile layout: no desktop helper flow")
		main.queue_free()
		return
	_select_voice(main, BRIAN)
	main._start_quiz(5, 10, false, "Helper test")
	main.session_muted = false
	main._show_question()
	await process_frame

	var q0: Dictionary = main.records[main.order[0]]
	var q1: Dictionary = main.records[main.order[1]]
	var f0: String = main._speech_cache_folder(main._safe_speech_id(str(q0["id"])), BRIAN)
	var f1: String = main._speech_cache_folder(main._safe_speech_id(str(q1["id"])), BRIAN)
	check(main.speech_helper.busy_request_for(f0) >= 0, "showing a question prefetches it")
	check(main.speech_helper.busy_request_for(f1) >= 0, "showing a question prefetches the next one")
	check(await _until(func() -> bool: return main._speech_cache_matches(f0, SpeechText.speech_plan(q0)) and main._speech_cache_matches(f1, SpeechText.speech_plan(q1)), 15.0),
		"prefetch leaves both full plans cached")

	main._begin_reading(SpeechText.speech_plan(q0))
	check(main.reader.playing, "a cached read starts in the same frame")
	check(main.speech_queue_index == 0, "a read starts at the stem")
	var teach_idx: int = main.teach_from_index
	check(teach_idx > 0, "the cached queue carries the rule after the choices")
	main._stop_reading()

	main.current_answered = true
	main.want_teach = true
	var requests_before: int = main.speech_helper._next_id
	main._begin_reading(SpeechText.teach_segments(q0))
	check(main.reader.playing and main.speech_queue_index == teach_idx, "'Hear the rule' plays the cached tail")
	check(main.speech_helper._next_id == requests_before, "'Hear the rule' synthesizes nothing new")
	main._stop_reading()
	main.current_answered = false

	_wipe(f0)
	main._begin_reading(SpeechText.speech_plan(q0))
	check(main.speak_busy and not main.reader.playing, "an uncached read waits for its first clip")
	check(main.read_status_label.text.begins_with("PREPARING "), "the wait says it is preparing the voice (got %s)" % main.read_status_label.text)
	check(await _until(func() -> bool: return main.reader.playing, 5.0), "the stem plays as soon as its clip lands")
	check(main.speech_queue_index == 0 and not main.speak_busy, "streamed playback starts at the stem")
	var first_teach: int = main.teach_from_index
	main.speech_queue_index = first_teach - 1
	main._halt_player()
	main._on_reader_finished()
	check(not main.reader.playing and main.speech_queue_index == first_teach, "the rule does not play before answering")
	main._stop_reading()
	await _until(func() -> bool: return main.speech_helper.busy_request_for(f0) < 0, 5.0)

	_wipe(f0)
	main._begin_reading(SpeechText.speech_plan(q0))
	main._stop_reading()
	await _sleep(1.2)
	check(not main.reader.playing, "Stop while preparing plays nothing later")
	check(main._live_request == -1, "Stop detaches from the helper request")
	check(await _until(func() -> bool: return main._speech_cache_matches(f0, SpeechText.speech_plan(q0)), 5.0),
		"a stopped read still finishes into the cache")
	check(not main.reader.playing, "finishing into the cache after Stop plays nothing")

	await _until(func() -> bool: return main.speech_helper.busy_request_for(f0) < 0, 5.0)
	main.speech_helper.stop()
	main.speech_helper.python = "no-such-python-exe"
	main.speech_helper._starts = 0
	_wipe(f0)
	main._begin_reading(SpeechText.speech_plan(q0))
	check(main._voice_fallback == "System voice (Edge unavailable)", "a failed Edge voice is labelled as the system voice")
	check(main._status_with_voice("READING").contains("System voice (Edge unavailable)"), "the status line names the voice actually speaking")
	check(not main._status_with_voice("READING").contains("Brian"), "the status line never claims Brian after a fallback")
	main._stop_reading()
	main.current_index = 1
	main._begin_reading(SpeechText.speech_plan(q1))
	check(main.reader.playing and main._voice_fallback == "", "a later cached read clears the fallback label")
	main._stop_reading()
	main.queue_free()
	await process_frame


func _select_voice(main: Node, voice_id: String) -> void:
	for i in main.voice_picker.item_count:
		if str(main.voice_ids.get(main.voice_picker.get_item_text(i), "")) == voice_id:
			main.voice_picker.selected = i
			return


func _fixture_clip() -> String:
	var speech := ProjectSettings.globalize_path("res://speech")
	for dir in DirAccess.get_directories_at(speech):
		var clip := speech.path_join(dir).path_join("0.mp3")
		if FileAccess.file_exists(clip):
			return clip
	return ""


func _until(pred: Callable, limit_s: float) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < limit_s * 1000.0:
		if pred.call():
			return true
		await process_frame
	return pred.call()


func _sleep(seconds: float) -> void:
	await create_timer(seconds).timeout


func _mp3_count(folder: String) -> int:
	if not DirAccess.dir_exists_absolute(folder):
		return 0
	return Array(DirAccess.get_files_at(folder)).filter(func(f: String) -> bool: return f.ends_with(".mp3")).size()


func _has_part(folder: String) -> bool:
	if not DirAccess.dir_exists_absolute(folder):
		return false
	return Array(DirAccess.get_files_at(folder)).any(func(f: String) -> bool: return f.ends_with(".part"))


func _wipe(folder: String) -> void:
	if not DirAccess.dir_exists_absolute(folder):
		return
	for sub in DirAccess.get_directories_at(folder):
		_wipe(folder.path_join(sub))
	for f in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(f))
	DirAccess.remove_absolute(folder)
