class_name SpeechHelper
extends Node
## One warm `speak_question.py --serve` process for desktop Edge voices.
##
## Spawning Python per question cost ~3 s of edge_tts + aiohttp imports before
## any audio, and playback waited for every clip. The helper pays the imports
## once and reports each clip as it lands, so the first clip can play while the
## rest are still being synthesized. The pipe is non-blocking and polled from
## _process, so the main thread never waits on Python.

signal clip_ready(request_id: int, index: int)
signal request_done(request_id: int)
signal request_failed(request_id: int, reason: String)

enum State { OFF, STARTING, READY, DEAD }

const SCRIPT_RES := "res://tools/speak_question.py"
const PRIO_LIVE := 0
const PRIO_PREFETCH := 1
## A helper that keeps dying is not restarted forever.
const MAX_STARTS := 3

var state := State.OFF
## Why the helper is unusable, in one line (shown in the log and fallback label).
var fail_reason := ""
var python := "python"
var started_msec := 0
var ready_msec := 0

var _pid := -1
var _io: FileAccess
var _err: FileAccess
var _buf := PackedByteArray()
var _err_text := ""
var _starts := 0
var _next_id := 0
## id -> {folder, prio, clips: {index: true}, status: "busy"/"done"/"failed"/"cancelled", reason}
var _requests := {}
var _alive_check := 0.0


## The script the helper runs. In the editor it is the project file; an export
## carries it inside the pack (export include_filter), copied out on first use.
static func resolve_script() -> String:
	var dev := ProjectSettings.globalize_path(SCRIPT_RES)
	if FileAccess.file_exists(dev):
		return dev
	var beside := OS.get_executable_path().get_base_dir().path_join("tools").path_join("speak_question.py")
	if FileAccess.file_exists(beside):
		return beside
	var source := FileAccess.get_file_as_string(SCRIPT_RES)
	if source == "":
		return ""
	var out := OS.get_user_data_dir().path_join("speech").path_join("speak_question.py")
	if FileAccess.get_file_as_string(out) != source:
		DirAccess.make_dir_recursive_absolute(out.get_base_dir())
		var f := FileAccess.open(out, FileAccess.WRITE)
		if f == null:
			return ""
		f.store_string(source)
		f.close()
	return out


func is_usable() -> bool:
	return state == State.STARTING or state == State.READY


## Starts the process if it is not running. False when it cannot run at all.
func start() -> bool:
	if is_usable():
		return true
	if _starts >= MAX_STARTS:
		return false
	_starts += 1
	var script := resolve_script()
	if script == "":
		return _die("speak_question.py missing from the build")
	var info := OS.execute_with_pipe(python, ["-u", script, "--serve"], false)
	if info.is_empty():
		return _die("Python not found")
	_pid = int(info["pid"])
	_io = info["stdio"]
	_err = info["stderr"]
	_buf.clear()
	_err_text = ""
	state = State.STARTING
	fail_reason = ""
	started_msec = Time.get_ticks_msec()
	set_process(true)
	return true


## Asks for every clip of `segments` in `folder` (absolute). A request already
## in flight for the same folder is reused; a live request raises its priority.
## Live requests cancel older live ones: the learner moved on.
func request(folder: String, voice: String, segments: Array, prio: int) -> int:
	if not start():
		return -1
	var existing := busy_request_for(folder)
	if prio == PRIO_LIVE:
		for id in _requests:
			var other: Dictionary = _requests[id]
			if id != existing and other["status"] == "busy" and int(other["prio"]) == PRIO_LIVE:
				cancel(id)
	if existing >= 0:
		var req: Dictionary = _requests[existing]
		if prio < int(req["prio"]):
			req["prio"] = prio
			_send({"op": "prio", "id": existing, "prio": prio})
		return existing
	_next_id += 1
	_requests[_next_id] = {"folder": folder, "prio": prio, "clips": {}, "status": "busy", "reason": ""}
	_send({"op": "speak", "id": _next_id, "folder": folder, "voice": voice, "segments": segments, "prio": prio})
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
	_send({"op": "cancel", "id": id})


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
	if _io != null:
		# EOF on stdin ends the helper; kill in case it is wedged.
		_io.close()
		_io = null
	if _err != null:
		_err.close()
		_err = null
	if _pid > 0 and OS.is_process_running(_pid):
		OS.kill(_pid)
	_pid = -1
	if is_usable():
		state = State.OFF
	set_process(false)


func _exit_tree() -> void:
	stop()


func _ready() -> void:
	set_process(is_usable())


func _process(delta: float) -> void:
	if _io == null:
		return
	_drain()
	_alive_check += delta
	if _alive_check >= 0.25:
		_alive_check = 0.0
		_drain_stderr()
		if not OS.is_process_running(_pid):
			_drain()
			var last := _last_line(_err_text)
			_die("speech helper exited" + (": " + last if last != "" else ""))


func _send(msg: Dictionary) -> void:
	if _io == null:
		return
	_io.store_string(JSON.stringify(msg) + "\n")
	_io.flush()


func _drain() -> void:
	var chunk := _io.get_buffer(65536)
	if chunk.is_empty():
		return
	_buf.append_array(chunk)
	while true:
		var nl := _buf.find(10)
		if nl < 0:
			break
		var line := _buf.slice(0, nl).get_string_from_utf8().strip_edges()
		_buf = _buf.slice(nl + 1)
		if line != "":
			_on_line(line)


func _drain_stderr() -> void:
	if _err == null:
		return
	var chunk := _err.get_buffer(65536)
	if not chunk.is_empty():
		_err_text = (_err_text + chunk.get_string_from_utf8()).right(4000)


func _on_line(line: String) -> void:
	var msg = JSON.parse_string(line)
	if not msg is Dictionary:
		return
	var event := str(msg.get("event", ""))
	if event == "ready":
		state = State.READY
		ready_msec = Time.get_ticks_msec()
		return
	if event == "error":
		push_warning("Speech helper: " + str(msg.get("reason", "")))
		return
	var id := int(msg.get("id", -1))
	var req: Dictionary = _requests.get(id, {})
	if req.is_empty() or req["status"] == "cancelled":
		return
	match event:
		"clip":
			(req["clips"] as Dictionary)[int(msg.get("index", -1))] = true
			clip_ready.emit(id, int(msg.get("index", -1)))
		"done":
			req["status"] = "done"
			request_done.emit(id)
		"fail":
			req["status"] = "failed"
			req["reason"] = str(msg.get("reason", ""))
			request_failed.emit(id, req["reason"])


func _die(why: String) -> bool:
	fail_reason = why
	state = State.DEAD
	if _io != null:
		_io.close()
		_io = null
	if _err != null:
		_err.close()
		_err = null
	_pid = -1
	set_process(false)
	var failed: Array = []
	for id in _requests:
		var req: Dictionary = _requests[id]
		if req["status"] == "busy":
			req["status"] = "failed"
			req["reason"] = why
			failed.append(id)
	# Emitted after the loop: a handler may start a new request.
	for id in failed:
		request_failed.emit(id, why)
	return false


static func _last_line(text: String) -> String:
	var lines := text.strip_edges().split("\n", false)
	return lines[lines.size() - 1].strip_edges() if not lines.is_empty() else ""
