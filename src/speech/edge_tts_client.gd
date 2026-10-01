class_name EdgeTtsClient
extends Node
## Edge neural voices in pure GDScript, on Windows and Android alike: no Python,
## no child process. Speaks the same read-aloud WebSocket protocol as edge-tts
## (src/speech/speak_question.py, the dev/pregeneration tool) and writes the
## same cache layout: I.mp3 per segment, manifest.json last.
##
## Everything is polled from _process: DNS, TLS and the socket never block the
## main thread. A failed request marks the network down for OFFLINE_HOLD_MSEC,
## so the next reads fall back at once instead of waiting on a timeout again.

signal clip_ready(request_id: int, index: int)
signal request_done(request_id: int)
signal request_failed(request_id: int, reason: String)

const PRIO_LIVE := 0
const PRIO_PREFETCH := 1
const TRUSTED_CLIENT_TOKEN := "6A5AA1D4EAFF4E9FB37E23D68491D6F4"
const WSS_URL := "wss://speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1"
const CHROMIUM_FULL_VERSION := "143.0.3650.75"
const ORIGIN := "chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold"
## Keep in sync with SpeechController.SPEECH_FORMAT and speak_question.py OUTPUT_FORMAT.
const OUTPUT_FORMAT := "audio-24khz-96kbitrate-mono-mp3"
const WIN_EPOCH := 11644473600
## Live reads get this many sockets; prefetch gets fewer beside them.
const LIVE_PARALLEL := 4
const PREFETCH_PARALLEL := 2
const RETRIES := 1
const OFFLINE_HOLD_MSEC := 30000
## The service refuses SSML text over 4096 bytes.
const MAX_CHUNK_BYTES := 3000

## Tests point these at a local fake server and shorten the waits.
var url := WSS_URL
var connect_timeout_msec := 6000
var clip_timeout_msec := 20000
var fail_reason := ""
var offline_until_msec := 0
var _next_id := 0
## id -> {folder, voice, prio, rows: [[index, row]], queue: [index], clips: {}, status, reason}
var _requests := {}
## One per open socket: {rid, index, chunks, chunk, ws, t0, sent, audio, attempt, opened}
var _jobs: Array = []


func _ready() -> void:
	set_process(busy_count() > 0)


## Nothing to launch; false while the network is presumed down.
func start() -> bool:
	return not is_offline()


func is_offline() -> bool:
	return Time.get_ticks_msec() < offline_until_msec


## Asks for every clip of `segments` in `folder` (absolute). A request already
## in flight for the same folder is reused; a live request raises its priority
## and cancels older live ones. -1 while the network is presumed down.
func request(folder: String, voice: String, segments: Array, prio: int) -> int:
	if is_offline():
		return -1
	var existing := busy_request_for(folder)
	if prio == PRIO_LIVE:
		for id in _requests.keys():
			var other: Dictionary = _requests[id]
			if id != existing and other["status"] == "busy" and int(other["prio"]) == PRIO_LIVE:
				cancel(id)
	if existing >= 0:
		var req: Dictionary = _requests[existing]
		req["prio"] = mini(int(req["prio"]), prio)
		return existing
	_next_id += 1
	var rows := plan_rows(segments)
	DirAccess.make_dir_recursive_absolute(folder)
	DirAccess.remove_absolute(folder.path_join("manifest.json"))
	var queue: Array = []
	for r in rows:
		queue.append(int(r[0]))
	_requests[_next_id] = {"folder": folder, "voice": english_voice(voice), "prio": prio, "rows": rows,
		"queue": queue, "clips": {}, "status": "busy", "reason": ""}
	if rows.is_empty():
		_fail(_next_id, "empty speech text")
		return _next_id
	set_process(true)
	return _next_id


func busy_request_for(folder: String) -> int:
	for id in _requests:
		var req: Dictionary = _requests[id]
		if req["status"] == "busy" and req["folder"] == folder:
			return id
	return -1


func cancel(id: int) -> void:
	var req: Dictionary = _requests.get(id, {})
	if req.is_empty() or req["status"] != "busy":
		return
	req["status"] = "cancelled"
	_close_jobs(id)
	_discard(req)


func has_clip(id: int, index: int) -> bool:
	var req: Dictionary = _requests.get(id, {})
	return not req.is_empty() and (req["clips"] as Dictionary).has(index)


func status(id: int) -> String:
	var req: Dictionary = _requests.get(id, {})
	return "" if req.is_empty() else str(req["status"])


func reason(id: int) -> String:
	var req: Dictionary = _requests.get(id, {})
	return "" if req.is_empty() else str(req["reason"])


func stop() -> void:
	for id in _requests.keys():
		cancel(id)
	set_process(false)


func _exit_tree() -> void:
	stop()


## (index, manifest row) for every non-empty segment, as speak_question.py _plan.
static func plan_rows(segments: Array) -> Array:
	var rows: Array = []
	for i in segments.size():
		var seg = segments[i]
		if not seg is Dictionary:
			continue
		var text := str(seg.get("text", "")).strip_edges()
		if text == "":
			continue
		rows.append([i, {"file": "%d.mp3" % i, "choice": int(seg.get("choice", -1)),
			"teach": bool(seg.get("teach", false)), "rules": int(seg.get("rules", 0)),
			"format": OUTPUT_FORMAT, "text": text}])
	return rows


## Multilingual voices switch to French on an inch mark or curly quote.
static func english_voice(voice: String) -> String:
	var v := voice.replace("Multilingual", "")
	return v if v != "" else VoiceCatalog.DEFAULT_VOICE_ID


## The Sec-MS-GEC token: SHA-256 of the Windows file time (rounded down to
## 5 minutes, in 100 ns ticks) followed by the client token, upper-case hex.
static func sec_ms_gec(unix_seconds: float) -> String:
	var secs := int(unix_seconds) + WIN_EPOCH
	secs -= secs % 300
	return ("%d%s" % [secs * 10000000, TRUSTED_CLIENT_TOKEN]).sha256_text().to_upper()


static func xml_escape(text: String) -> String:
	var out := ""
	for ch in text:
		var c := ch.unicode_at(0)
		if (c >= 0 and c <= 8) or c == 11 or c == 12 or (c >= 14 and c <= 31):
			out += " "
		else:
			out += ch
	return out.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


## Escaped text split into pieces the service accepts: at a sentence end when
## one is in the back half of the piece, else at a space; never inside an
## entity or a number ("310.16" has no space after its point).
static func chunks_of(text: String) -> PackedStringArray:
	var out := PackedStringArray()
	var rest := xml_escape(text).strip_edges()
	while rest.to_utf8_buffer().size() > MAX_CHUNK_BYTES:
		var cut := rest.length()
		while cut > 0 and rest.left(cut).to_utf8_buffer().size() > MAX_CHUNK_BYTES:
			cut = rest.rfind(" ", cut - 1)
			if cut < 0:
				cut = MAX_CHUNK_BYTES / 4
				break
		var stop := maxi(rest.rfind(". ", cut - 1), maxi(rest.rfind("? ", cut - 1), rest.rfind("! ", cut - 1)))
		if stop > cut / 2:
			cut = stop + 1
		var amp := rest.rfind("&", cut - 1)
		if amp >= 0 and rest.find(";", amp) >= cut:
			cut = amp
		cut = maxi(cut, 1)
		var piece := rest.left(cut).strip_edges()
		if piece != "":
			out.append(piece)
		rest = rest.substr(cut).strip_edges()
	if rest != "":
		out.append(rest)
	return out


static func _connect_id() -> String:
	var bytes := Crypto.new().generate_random_bytes(16)
	return bytes.hex_encode()


static func _timestamp() -> String:
	var d := Time.get_datetime_dict_from_system(true)
	var days := ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
	var months := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	return "%s %s %02d %d %02d:%02d:%02d GMT+0000 (Coordinated Universal Time)" % [
		days[int(d["weekday"])], months[int(d["month"]) - 1], int(d["day"]), int(d["year"]),
		int(d["hour"]), int(d["minute"]), int(d["second"])]


func _socket_url() -> String:
	return "%s?TrustedClientToken=%s&ConnectionId=%s&Sec-MS-GEC=%s&Sec-MS-GEC-Version=1-%s" % [
		url, TRUSTED_CLIENT_TOKEN, _connect_id(), sec_ms_gec(Time.get_unix_time_from_system()), CHROMIUM_FULL_VERSION]


func _open(job: Dictionary) -> bool:
	var ws := WebSocketPeer.new()
	var major := CHROMIUM_FULL_VERSION.get_slice(".", 0)
	ws.handshake_headers = PackedStringArray([
		"Pragma: no-cache",
		"Cache-Control: no-cache",
		"Origin: " + ORIGIN,
		"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%s.0.0.0 Safari/537.36 Edg/%s.0.0.0" % [major, major],
		"Accept-Language: en-US,en;q=0.9",
		"Cookie: muid=%s;" % _connect_id().to_upper(),
	])
	ws.inbound_buffer_size = 1 << 20
	job["ws"] = ws
	job["t0"] = Time.get_ticks_msec()
	job["sent"] = false
	job["opened"] = false
	return ws.connect_to_url(_socket_url()) == OK


func _process(_delta: float) -> void:
	_fill_lanes()
	for job in _jobs.duplicate():
		_poll(job)
	if _jobs.is_empty() and busy_count() == 0:
		set_process(false)


func busy_count() -> int:
	var n := 0
	for id in _requests:
		if _requests[id]["status"] == "busy":
			n += 1
	return n


## Starts clips in reading order: live requests first, oldest first.
func _fill_lanes() -> void:
	for lane in [PRIO_LIVE, PRIO_PREFETCH]:
		var cap := LIVE_PARALLEL if lane == PRIO_LIVE else PREFETCH_PARALLEL
		var ids := _requests.keys()
		ids.sort()
		for id in ids:
			var req: Dictionary = _requests[id]
			if req["status"] != "busy" or int(req["prio"]) != lane:
				continue
			while not (req["queue"] as Array).is_empty() and _lane_count(lane) < cap:
				var index: int = req["queue"].pop_front()
				var job := {"rid": id, "index": index, "chunks": chunks_of(_row_text(req, index)),
					"chunk": 0, "audio": PackedByteArray(), "attempt": 0, "lane": lane}
				_jobs.append(job)
				if not _open(job):
					_job_error(job, "could not open the connection")


func _lane_count(lane: int) -> int:
	var n := 0
	for job in _jobs:
		if int(job["lane"]) == lane:
			n += 1
	return n


func _row_text(req: Dictionary, index: int) -> String:
	for r in req["rows"]:
		if int(r[0]) == index:
			return str(r[1]["text"])
	return ""


func _poll(job: Dictionary) -> void:
	var req: Dictionary = _requests.get(job["rid"], {})
	if req.is_empty() or req["status"] != "busy":
		_drop(job)
		return
	var ws: WebSocketPeer = job["ws"]
	ws.poll()
	var state := ws.get_ready_state()
	var now := Time.get_ticks_msec()
	if state == WebSocketPeer.STATE_CONNECTING:
		if now - int(job["t0"]) > connect_timeout_msec:
			_job_error(job, "no connection to the Edge voice service")
		return
	if state == WebSocketPeer.STATE_OPEN:
		job["opened"] = true
		if not job["sent"]:
			job["sent"] = true
			ws.send_text(_config_message())
			ws.send_text(_ssml_message(str(req["voice"]), str(job["chunks"][job["chunk"]])))
		while ws.get_available_packet_count() > 0:
			var packet := ws.get_packet()
			if ws.was_string_packet():
				if _on_text(job, packet.get_string_from_utf8()):
					return
			else:
				_on_binary(job, packet)
		if now - int(job["t0"]) > clip_timeout_msec:
			_job_error(job, "the Edge voice service timed out")
		return
	if state == WebSocketPeer.STATE_CLOSED:
		var why := "the Edge voice service closed the connection (%d)" % ws.get_close_code()
		if not job["opened"]:
			why = "no connection to the Edge voice service"
		_job_error(job, why)


## True when the job is finished with its socket.
func _on_text(job: Dictionary, text: String) -> bool:
	var head_end := text.find("\r\n\r\n")
	var head := text.substr(0, head_end) if head_end >= 0 else text
	if not head.contains("Path:turn.end"):
		return false
	(job["ws"] as WebSocketPeer).close()
	var bad := mp3_problem(job["audio"])
	if bad != "":
		_job_error(job, bad)
		return true
	job["chunk"] = int(job["chunk"]) + 1
	if int(job["chunk"]) < (job["chunks"] as PackedStringArray).size():
		if not _open(job):
			_job_error(job, "could not open the connection")
		return true
	var words := " ".join(job["chunks"] as PackedStringArray).split(" ", false).size()
	if (job["audio"] as PackedByteArray).size() < min_clip_bytes(words):
		_job_error(job, "the audio stops early (%d bytes for %d words)" % [(job["audio"] as PackedByteArray).size(), words])
		return true
	_finish_clip(job)
	return true


## The service can end a stream early, on a clean frame, and still send
## turn.end. No clip is spoken faster than 4.6 words a second (the bound in
## tools/speech/audit_bundle.py); OUTPUT_FORMAT is 96 kbit/s, 12000 bytes a second.
static func min_clip_bytes(words: int) -> int:
	return int(words / 4.6 * 12000.0)


## Why `audio` must not be cached, or "" for a whole MP3 stream: frames from
## the first byte (after any ID3 tag) to the end of the last one. A clip cut
## inside a frame would play, then stop mid-word.
static func mp3_problem(audio: PackedByteArray) -> String:
	if audio.size() < 4:
		return "no audio received"
	var pos := 0
	if audio[0] == 0x49 and audio[1] == 0x44 and audio[2] == 0x33 and audio.size() >= 10:
		pos = 10 + ((audio[6] << 21) | (audio[7] << 14) | (audio[8] << 7) | audio[9])
	var frames := 0
	while pos < audio.size():
		if audio.size() - pos < 4 or audio[pos] != 0xFF or (audio[pos + 1] & 0xE0) != 0xE0:
			return "the audio is not a clean MP3 stream (byte %d of %d)" % [pos, audio.size()]
		var size := mp3_frame_size(audio[pos + 1], audio[pos + 2])
		if size <= 0:
			return "bad MP3 frame header at byte %d" % pos
		if pos + size > audio.size():
			return "the audio stops inside its last frame"
		pos += size
		frames += 1
	return "" if frames > 0 else "no audio received"


## Bytes in an MPEG Layer III frame from header bytes 1 and 2; 0 when invalid.
static func mp3_frame_size(b1: int, b2: int) -> int:
	var version := (b1 >> 3) & 3
	var layer := (b1 >> 1) & 3
	var bitrate_idx := (b2 >> 4) & 15
	var rate_idx := (b2 >> 2) & 3
	if version == 1 or layer != 1 or bitrate_idx == 0 or bitrate_idx == 15 or rate_idx == 3:
		return 0
	var kbps: Array = [32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320] if version == 3 \
		else [8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160]
	var rates: Array = [[11025, 12000, 8000], [], [22050, 24000, 16000], [44100, 48000, 32000]]
	var rate: int = rates[version][rate_idx]
	return (144 if version == 3 else 72) * int(kbps[bitrate_idx - 1]) * 1000 / rate + ((b2 >> 1) & 1)


func _on_binary(job: Dictionary, packet: PackedByteArray) -> void:
	if packet.size() < 2:
		return
	var head_len := (packet[0] << 8) | packet[1]
	if head_len + 2 > packet.size():
		return
	var head := packet.slice(2, 2 + head_len).get_string_from_utf8()
	if not head.contains("Path:audio"):
		return
	var data := packet.slice(2 + head_len)
	if data.is_empty():
		return
	var audio: PackedByteArray = job["audio"]
	audio.append_array(data)
	job["audio"] = audio


func _config_message() -> String:
	return ("X-Timestamp:%s\r\nContent-Type:application/json; charset=utf-8\r\nPath:speech.config\r\n\r\n"
		+ "{\"context\":{\"synthesis\":{\"audio\":{\"metadataoptions\":{"
		+ "\"sentenceBoundaryEnabled\":\"false\",\"wordBoundaryEnabled\":\"false\"},"
		+ "\"outputFormat\":\"%s\"}}}}\r\n") % [_timestamp(), OUTPUT_FORMAT]


func _ssml_message(voice: String, escaped_text: String) -> String:
	var ssml := ("<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='en-US'>"
		+ "<voice name='%s'><prosody pitch='+0Hz' rate='+0%%' volume='+0%%'>%s</prosody></voice></speak>") % [voice, escaped_text]
	return "X-RequestId:%s\r\nContent-Type:application/ssml+xml\r\nX-Timestamp:%sZ\r\nPath:ssml\r\n\r\n%s" % [
		_connect_id(), _timestamp(), ssml]


func _finish_clip(job: Dictionary) -> void:
	_jobs.erase(job)
	var id: int = job["rid"]
	var req: Dictionary = _requests.get(id, {})
	if req.is_empty() or req["status"] != "busy":
		return
	var path: String = str(req["folder"]).path_join("%d.mp3" % int(job["index"]))
	var part := FileAccess.open(path + ".part", FileAccess.WRITE)
	if part == null:
		_fail(id, "cannot write %s" % path)
		return
	part.store_buffer(job["audio"])
	part.close()
	DirAccess.rename_absolute(path + ".part", path)
	(req["clips"] as Dictionary)[int(job["index"])] = true
	offline_until_msec = 0
	clip_ready.emit(id, int(job["index"]))
	if req["status"] == "busy" and (req["clips"] as Dictionary).size() == (req["rows"] as Array).size():
		_write_manifest(req)
		req["status"] = "done"
		request_done.emit(id)


func _write_manifest(req: Dictionary) -> void:
	var rows: Array = []
	for r in req["rows"]:
		rows.append(r[1])
	var folder: String = req["folder"]
	var part := FileAccess.open(folder.path_join("manifest.json.part"), FileAccess.WRITE)
	if part == null:
		return
	part.store_string(JSON.stringify(rows))
	part.close()
	DirAccess.rename_absolute(folder.path_join("manifest.json.part"), folder.path_join("manifest.json"))


func _job_error(job: Dictionary, why: String) -> void:
	var ws: WebSocketPeer = job.get("ws")
	if ws != null and ws.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		ws.close()
	var never_connected: bool = not job.get("opened", false)
	if int(job["attempt"]) < RETRIES and not never_connected:
		job["attempt"] = int(job["attempt"]) + 1
		job["audio"] = PackedByteArray()
		job["chunk"] = 0
		if _open(job):
			return
	_jobs.erase(job)
	if never_connected:
		offline_until_msec = Time.get_ticks_msec() + OFFLINE_HOLD_MSEC
	fail_reason = why
	_fail(int(job["rid"]), why)


func _fail(id: int, why: String) -> void:
	var req: Dictionary = _requests.get(id, {})
	if req.is_empty() or req["status"] != "busy":
		return
	req["status"] = "failed"
	req["reason"] = why
	_close_jobs(id)
	_discard(req)
	request_failed.emit(id, why)
	if is_offline():
		for other in _requests.keys():
			_fail(other, why)


func _close_jobs(id: int) -> void:
	for job in _jobs.duplicate():
		if int(job["rid"]) == id:
			_drop(job)


func _drop(job: Dictionary) -> void:
	var ws: WebSocketPeer = job.get("ws")
	if ws != null and ws.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		ws.close()
	_jobs.erase(job)


func _discard(req: Dictionary) -> void:
	var folder: String = req["folder"]
	for r in req["rows"]:
		var clip := folder.path_join(str(r[1]["file"]))
		DirAccess.remove_absolute(clip)
		DirAccess.remove_absolute(clip + ".part")
