extends SceneTree
## Dev check, needs the internet: synthesizes lines through the app's own
## EdgeTtsClient (same request format, chunking and cache writes as the game)
## so tools/speech/audit_bundle.py --root can check the audio is whole.
##
##   SAMPLE_IN=lines.json SAMPLE_OUT=<abs folder> Godot --headless --path . --script tools/speech/live_edge_sample.gd
##
## lines.json is a JSON array of strings, spoken as-is; SAMPLE_NORMALIZE=1
## runs them through the reading rules first (written bank text in).
## SAMPLE_VOICE picks the voice (default: the recorded Andrew's Edge voice).
## The spoken text of each clip is in manifest.json.

const Rules = preload("res://src/speech/speech_rules.gd")
const TIMEOUT_MSEC := 240000


func _initialize() -> void:
	var lines = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("SAMPLE_IN")))
	var out := OS.get_environment("SAMPLE_OUT")
	if not lines is Array or lines.is_empty() or out == "":
		push_error("set SAMPLE_IN (JSON array of lines) and SAMPLE_OUT (absolute folder)")
		quit(2)
		return
	var voice := OS.get_environment("SAMPLE_VOICE")
	var segments: Array = []
	var normalize := OS.get_environment("SAMPLE_NORMALIZE") == "1"
	for line in lines:
		var text := Rules.normalize(str(line)) if normalize else str(line)
		segments.append({"text": text, "choice": -1, "teach": false, "rules": Rules.VERSION})
	var client := EdgeTtsClient.new()
	client.clip_timeout_msec = 60000
	root.add_child(client)
	var id := client.request(out, voice if voice != "" else VoiceCatalog.DEFAULT_VOICE_ID, segments, EdgeTtsClient.PRIO_LIVE)
	var t0 := Time.get_ticks_msec()
	while client.status(id) == "busy" and Time.get_ticks_msec() - t0 < TIMEOUT_MSEC:
		await process_frame
	print("LIVE_SAMPLE=%s clips=%d reason=%s ms=%d" % [client.status(id), segments.size(), client.reason(id), Time.get_ticks_msec() - t0])
	quit(0 if client.status(id) == "done" else 1)
