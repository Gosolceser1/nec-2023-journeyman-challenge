extends RefCounted
## A local stand-in for the Edge read-aloud WebSocket, so the tests exercise
## EdgeTtsClient's real protocol without the internet. Answers each SSML turn
## the way the service does: turn.start, one binary audio message (2-byte
## header length, headers, MP3 bytes), turn.end. Call poll() every frame.
##
## mode "ok" answers, "silent" accepts and never answers.

var mode := "ok"
var audio := PackedByteArray()
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
				if mode == "ok":
					_answer(ws)


func _answer(ws: WebSocketPeer) -> void:
	ws.send_text("X-RequestId:0\r\nContent-Type:application/json; charset=utf-8\r\nPath:turn.start\r\n\r\n{}")
	var head := "X-RequestId:0\r\nContent-Type:audio/mpeg\r\nX-StreamId:0\r\nPath:audio\r\n".to_utf8_buffer()
	var msg := PackedByteArray([head.size() >> 8, head.size() & 255])
	msg.append_array(head)
	msg.append_array(audio)
	ws.send(msg, WebSocketPeer.WRITE_MODE_BINARY)
	ws.send_text("X-RequestId:0\r\nContent-Type:application/json; charset=utf-8\r\nPath:turn.end\r\n\r\n{}")
