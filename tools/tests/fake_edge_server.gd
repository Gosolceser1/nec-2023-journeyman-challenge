extends RefCounted
## A local stand-in for the Edge read-aloud WebSocket, so the tests exercise
## EdgeTtsClient's real protocol without the internet. Answers each SSML turn
## the way the service does: turn.start, one binary audio message (2-byte
## header length, headers, MP3 bytes), turn.end. Call poll() every frame.
##
## mode "ok" answers, "silent" accepts and never answers, "torn" answers with
## the audio cut inside its last frame (then turn.end, as if nothing happened).
## With `pad` on, `audio` is lengthened with silent frames to a plausible length
## for the words asked for, since the client refuses audio that stops early.

var mode := "ok"
var audio := PackedByteArray()
var pad := true
var port := 0
var configs: Array[String] = []
var ssml: Array[String] = []
var _tcp := TCPServer.new()
var _peers: Array[WebSocketPeer] = []


func listen() -> int:
	for p in range(47310, 47400):
		if _tcp.listen(p, "127.0.0.1") == OK:
			port = p
			return p
	return 0


func url() -> String:
	return "ws://127.0.0.1:%d/edge/v1" % port


func stop() -> void:
	for ws in _peers:
		ws.close()
	_peers.clear()
	_tcp.stop()


func poll() -> void:
	while _tcp.is_connection_available():
		var ws := WebSocketPeer.new()
		ws.outbound_buffer_size = 4 << 20
		ws.accept_stream(_tcp.take_connection())
		_peers.append(ws)
	for ws: WebSocketPeer in _peers.duplicate():
		ws.poll()
		if ws.get_ready_state() == WebSocketPeer.STATE_CLOSED:
			_peers.erase(ws)
			continue
		while ws.get_available_packet_count() > 0:
			var text := ws.get_packet().get_string_from_utf8()
			if text.contains("Path:speech.config"):
				configs.append(text)
			elif text.contains("Path:ssml"):
				ssml.append(text)
				if mode == "ok" or mode == "torn":
					_answer(ws, text)


func _answer(ws: WebSocketPeer, request: String) -> void:
	ws.send_text("X-RequestId:0\r\nContent-Type:application/json; charset=utf-8\r\nPath:turn.start\r\n\r\n{}")
	var body := audio.duplicate()
	if pad:
		var re := RegEx.create_from_string("<[^>]*>")
		var spoken := re.sub(request.get_slice("\r\n\r\n", 1), " ", true)
		var need := EdgeTtsClient.min_clip_bytes(spoken.split(" ", false).size()) + 2880
		while body.size() < need:
			var frame := PackedByteArray([0xFF, 0xF3, 0xA4, 0xC4])
			frame.resize(288)
			body.append_array(frame)
	if mode == "torn":
		body = body.slice(0, body.size() - 100)
	var head := "X-RequestId:0\r\nContent-Type:audio/mpeg\r\nX-StreamId:0\r\nPath:audio\r\n".to_utf8_buffer()
	for start in range(0, body.size(), 8192):
		var msg := PackedByteArray([head.size() >> 8, head.size() & 255])
		msg.append_array(head)
		msg.append_array(body.slice(start, start + 8192))
		ws.send(msg, WebSocketPeer.WRITE_MODE_BINARY)
	ws.send_text("X-RequestId:0\r\nContent-Type:application/json; charset=utf-8\r\nPath:turn.end\r\n\r\n{}")
