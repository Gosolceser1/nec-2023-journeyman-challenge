extends SceneTree
## EdgeTtsClient: the Edge voices in pure GDScript, so Android (which cannot
## run the desktop Python helper) gets the same natural voices. Runs against a
## local fake of the read-aloud WebSocket; no internet needed.
##
## WHY THIS EXISTS: the desktop Edge voices were synthesized by a Python
## process (OS.execute_with_pipe), which Android cannot start, so the phone
## only ever listed device voices. A network client must also never block the
## main thread and must fail fast with no connection.
##
##   Godot --headless --path . --script tools/tests/test_edge_client.gd

const FakeEdge = preload("res://tools/tests/fake_edge_server.gd")
const ROOT := "user://edge_client_test"
const BUDGET_MSEC := 150

var failures: Array[String] = []
var checks := 0
var fake: FakeEdge
var worst_frame := 0


func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func _initialize() -> void:
	print("=== EDGE CLIENT (pure) ===")
	_pure_cases()
	print("=== EDGE CLIENT (fake service) ===")
	fake = FakeEdge.new()
	check(fake.listen() > 0, "the fake Edge service listens on localhost")
	fake.audio = _fixture_audio()
	await _roundtrip()
	await _cancel_and_supersede()
	await _silent_service()
	await _no_network()
	fake.stop()
	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	for f in failures:
		print("  - %s" % f)
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)


func _pure_cases() -> void:
	check(EdgeTtsClient.sec_ms_gec(1790000000.0) == "CA99F0B37F2EAC6F5D719AE4BA7C98978842B3F335D9F42979070A8DB149F0A5",
		"Sec-MS-GEC matches edge-tts for the same time")
	check(EdgeTtsClient.sec_ms_gec(1790000000.0) == EdgeTtsClient.sec_ms_gec(1790000099.0)
		and EdgeTtsClient.sec_ms_gec(1790000100.0) != EdgeTtsClient.sec_ms_gec(1790000099.0),
		"the token holds for its 5-minute window and changes after it")
	check(EdgeTtsClient.xml_escape("12 AWG & <75 °C>\u000bok") == "12 AWG &amp; &lt;75 °C&gt; ok",
		"text is XML-escaped and control characters become spaces")
	check(EdgeTtsClient.english_voice("en-US-AvaMultilingualNeural") == "en-US-AvaNeural",
		"multilingual voices are read in their English form")
	var long := ""
	for i in 900:
		long += "conductor & ampacity "
	var chunks := EdgeTtsClient.chunks_of(long)
	check(chunks.size() > 1, "a long text is split (%d chunks)" % chunks.size())
	var ok := true
	for c in chunks:
		ok = ok and c.to_utf8_buffer().size() <= EdgeTtsClient.MAX_CHUNK_BYTES and not c.ends_with("&amp") and not c.ends_with("&")
	check(ok, "every chunk fits the service limit and no entity is cut")
	check(" ".join(chunks).replace(" ", "") == EdgeTtsClient.xml_escape(long).replace(" ", ""), "chunks keep every word")
	var rows := EdgeTtsClient.plan_rows([{"text": "Stem", "choice": -1, "rules": 3}, {"text": "  "}, {"text": "A", "choice": 0, "teach": false}])
	check(rows.size() == 2 and int(rows[1][0]) == 2 and rows[1][1]["file"] == "2.mp3", "empty segments are skipped, files keep their segment index")
	check(rows[0][1]["format"] == SpeechController.SPEECH_FORMAT and int(rows[0][1]["rules"]) == 3,
		"manifest rows carry the format and rules the game's cache check expects")


func _roundtrip() -> void:
	var client := _client()
	var folder := _folder("ok")
	var clips: Array = []
	var done: Array = []
	client.clip_ready.connect(func(_id: int, i: int) -> void: clips.append(i))
	client.request_done.connect(func(id: int) -> void: done.append(id))
	var segs := [{"text": "What size & type <copper>?", "choice": -1}, {"text": ""}, {"text": "12 AWG", "choice": 0}]
	var t0 := Time.get_ticks_msec()
	var id := client.request(folder, "en-US-AvaMultilingualNeural", segs, EdgeTtsClient.PRIO_LIVE)
	check(Time.get_ticks_msec() - t0 < BUDGET_MSEC, "a request returns at once")
	check(await _until(func() -> bool: return done.has(id), 5.0), "the fake service's audio arrives")
	check(clips.size() == 2 and clips.has(0) and clips.has(2), "one clip per spoken segment (%s)" % [clips])
	check(client.status(id) == "done" and client.has_clip(id, 0) and client.has_clip(id, 2), "the request reports done with both clips")
	check(FileAccess.get_file_as_bytes(folder.path_join("0.mp3")) == fake.audio, "the clip is exactly the audio sent")
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("manifest.json")))
	check(manifest is Array and manifest.size() == 2 and manifest[1]["file"] == "2.mp3", "manifest.json is written last, like the Python helper")
	check(not Array(DirAccess.get_files_at(folder)).any(func(f: String) -> bool: return f.ends_with(".part")), "no .part file is left")
	check(fake.configs.size() >= 2 and fake.configs[0].contains(EdgeTtsClient.OUTPUT_FORMAT), "speech.config asks for the 96 kbps format")
	var s := "\n".join(fake.ssml)
	check(s.contains("<voice name='en-US-AvaNeural'>") and s.contains("What size &amp; type &lt;copper&gt;?"),
		"SSML names the English voice and carries escaped text")
	check(worst_frame < BUDGET_MSEC, "no frame over %d ms while synthesizing (worst %d)" % [BUDGET_MSEC, worst_frame])
	client.queue_free()


func _cancel_and_supersede() -> void:
	var client := _client()
	fake.mode = "silent"
	var a := client.request(_folder("a"), "en-US-BrianNeural", [{"text": "one"}], EdgeTtsClient.PRIO_LIVE)
	var pre := client.request(_folder("pre"), "en-US-BrianNeural", [{"text": "two"}], EdgeTtsClient.PRIO_PREFETCH)
	check(client.request(_folder("pre"), "en-US-BrianNeural", [{"text": "two"}], EdgeTtsClient.PRIO_LIVE) == pre,
		"a second request for the same folder is shared")
	check(client.status(a) == "cancelled", "a new live read cancels the older one")
	client.cancel(pre)
	await _until(func() -> bool: return false, 0.2)
	check(client.status(pre) == "cancelled" and client._jobs.is_empty(), "cancel closes every socket")
	fake.mode = "ok"
	client.queue_free()


func _silent_service() -> void:
	var client := _client()
	client.clip_timeout_msec = 400
	fake.mode = "silent"
	var failed: Array = []
	client.request_failed.connect(func(id: int, why: String) -> void: failed.append(why))
	var t0 := Time.get_ticks_msec()
	client.request(_folder("silent"), "en-US-BrianNeural", [{"text": "hello"}], EdgeTtsClient.PRIO_LIVE)
	check(await _until(func() -> bool: return not failed.is_empty(), 5.0), "a service that never answers times out")
	print("  silent service: failed after %d ms (%s)" % [Time.get_ticks_msec() - t0, failed[0] if failed else ""])
	check(not client.is_offline(), "a reachable but silent service does not mark the network down")
	fake.mode = "ok"
	client.queue_free()


func _no_network() -> void:
	var hung := _client()
	hung.url = "ws://127.0.0.1:%d/edge/v1" % (fake.port + 50)
	hung.connect_timeout_msec = 500
	var hung_failed: Array = []
	hung.request_failed.connect(func(id: int, why: String) -> void: hung_failed.append(why))
	hung.request(_folder("hung"), "en-US-BrianNeural", [{"text": "hello"}], EdgeTtsClient.PRIO_LIVE)
	check(await _until(func() -> bool: return not hung_failed.is_empty(), 3.0) and hung.is_offline(),
		"a connection that never opens gives up after the connect timeout and marks the network down")
	hung.queue_free()

	# No internet: the host name does not resolve.
	var client := _client()
	client.url = "wss://no-such-host.invalid/edge/v1"
	var failed: Array = []
	client.request_failed.connect(func(id: int, why: String) -> void: failed.append(id))
	worst_frame = 0
	var t0 := Time.get_ticks_msec()
	var live := client.request(_folder("down"), "en-US-BrianNeural", [{"text": "hello"}, {"text": "again"}], EdgeTtsClient.PRIO_LIVE)
	var pre := client.request(_folder("down2"), "en-US-BrianNeural", [{"text": "next"}], EdgeTtsClient.PRIO_PREFETCH)
	check(await _until(func() -> bool: return failed.has(live), 5.0), "no connection: the read fails instead of waiting")
	var took := Time.get_ticks_msec() - t0
	print("  no network: failed after %d ms, worst frame %d ms" % [took, worst_frame])
	check(took < 3000 and worst_frame < BUDGET_MSEC, "it fails within 3 s without blocking a frame (%d ms, worst frame %d)" % [took, worst_frame])
	check(failed.has(pre), "queued requests fail with it")
	check(client.is_offline() and client.fail_reason != "", "the network is marked down (%s)" % client.fail_reason)
	var t1 := Time.get_ticks_msec()
	check(client.request(_folder("down3"), "en-US-BrianNeural", [{"text": "x"}], EdgeTtsClient.PRIO_LIVE) == -1 and Time.get_ticks_msec() - t1 < 20,
		"while it is down, the next request is refused at once")
	check(not FileAccess.file_exists(_folder("down").path_join("manifest.json")), "a failed request leaves no manifest")
	client.offline_until_msec = 0
	client.url = fake.url()
	var id := client.request(_folder("back"), "en-US-BrianNeural", [{"text": "back"}], EdgeTtsClient.PRIO_LIVE)
	check(await _until(func() -> bool: return client.status(id) == "done", 5.0), "reads work again once the network is back")
	client.queue_free()


func _client() -> EdgeTtsClient:
	var client := EdgeTtsClient.new()
	client.url = fake.url()
	root.add_child(client)
	return client


func _folder(leaf: String) -> String:
	var f := ProjectSettings.globalize_path(ROOT).path_join(leaf)
	if DirAccess.dir_exists_absolute(f):
		for file in DirAccess.get_files_at(f):
			DirAccess.remove_absolute(f.path_join(file))
	return f


## A real MP3 frame run when the bundle exists; any bytes otherwise.
func _fixture_audio() -> PackedByteArray:
	var speech := ProjectSettings.globalize_path("res://assets/speech")
	if DirAccess.dir_exists_absolute(speech):
		for dir in DirAccess.get_directories_at(speech):
			var clip := speech.path_join(dir).path_join("0.mp3")
			if FileAccess.file_exists(clip):
				return FileAccess.get_file_as_bytes(clip)
	var out := PackedByteArray()
	out.resize(4096)
	out.fill(0x55)
	return out


func _until(pred: Callable, limit_s: float) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < limit_s * 1000.0:
		if pred.call():
			return true
		var tf := Time.get_ticks_msec()
		fake.poll()
		await process_frame
		worst_frame = maxi(worst_frame, Time.get_ticks_msec() - tf)
	return pred.call()
