extends SceneTree
## Question figures: every figure the source PDFs print for a question must be
## on screen BEFORE the learner answers, look like the PDF (it is a crop of the
## page, not a redraw), and give nothing away until the answer is in.
##
##   Godot --headless --path . --script tools/tests/test_diagrams.gd [-- --mobile-ui]
##
## Without --mobile-ui the suite also runs itself once with it, so run_all.gd
## covers both layouts (ui_mobile is read from the command line in _ready and
## cannot be flipped in-process).

const R = preload("res://tools/tests/t_report.gd")
const MAP_PATH := "res://assets/diagrams/diagrams.json"
## Prompt/choice wording that only makes sense with a picture next to it.
const NEEDS_FIGURE := "(?i)(refer to the figure|figure below|shown below|diagram [a-d]\\b|which of the following is an? (ammeter|voltmeter|wattmeter|ohmmeter)\\b)"

var t: R = R.new()
var main: Node
var mobile := false


func _initialize() -> void:
	mobile = "--mobile-ui" in OS.get_cmdline_user_args()
	print("=== question figures (%s) ===" % ("mobile" if mobile else "desktop"))
	_data_checks()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _frames(6)
	main.audio_cfg_path = "user://test_diagrams_audio.cfg"
	main.session.bag_path = ""
	main._on_audio_mode_picked(AudioSettings.Mode.SILENT)
	main._start_quiz(10, 1800, true, "Practice Test")
	main.timer.stop()
	await _frames(2)
	await _sweep()
	var child_ok := true
	if not mobile:
		child_ok = _run_mobile_child()
	t.report()
	quit(0 if t.failures.is_empty() and child_ok else 1)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _map() -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH))
	return parsed if parsed is Dictionary else {}


func _data_checks() -> void:
	var m := _map()
	t.check(not m.is_empty(), "diagrams.json parses and is not empty")
	var bank = JSON.parse_string(FileAccess.get_file_as_string("res://data/question_bank.json"))
	var recs: Array = bank.get("records", []) if bank is Dictionary else []
	var by_id := {}
	for r in recs:
		by_id[str(r.get("id", ""))] = r
	for qid in m:
		var e: Dictionary = m[qid]
		t.check(by_id.has(qid), "%s: mapped figure belongs to a bank record" % qid)
		t.check(ResourceLoader.exists(str(e.get("file", ""))), "%s: figure PNG %s exists" % [qid, e.get("file", "")])
		t.check(int(e.get("page", 0)) > 0 and str(e.get("pdf", "")).ends_with(".pdf"), "%s: records its source PDF and page" % qid)
		var tex := load(str(e.get("file", ""))) as Texture2D
		t.check(tex != null and tex.get_width() >= 400, "%s: crop is high-resolution (width %d)" % [qid, tex.get_width() if tex else 0])
		if e.has("highlight"):
			var h: Array = e["highlight"]
			t.check(h.size() == 4 and float(h[2]) > 0.0 and float(h[3]) > 0.0 and float(h[0]) >= -0.01 and float(h[1]) >= -0.01 \
					and float(h[0]) + float(h[2]) <= 1.01 and float(h[1]) + float(h[3]) <= 1.01, "%s: highlight box lies inside the crop" % qid)
	var re := RegEx.create_from_string(NEEDS_FIGURE)
	for r in recs:
		var text := str(r.get("prompt", "")) + " | " + " | ".join(PackedStringArray(r.get("answers", [])))
		if re.search(text) != null:
			t.check(DiagramView.has_figure(r), "%s: stem/choices refer to a picture, so it must have a figure" % r.get("id", ""))
	# PDF figures replace the old ASCII drafts: nothing may still carry one.
	for r in recs:
		if m.has(str(r.get("id", ""))):
			t.check(str(r.get("diagram", "")) == "", "%s: no stale ASCII diagram next to the PDF figure" % r.get("id", ""))


func _sweep() -> void:
	var m := _map()
	var shown := 0
	for i in main.records.size():
		var rec: Dictionary = main.records[i]
		var qid := str(rec.get("id", ""))
		var has_fig := DiagramView.has_figure(rec)
		main.order = [i, (i + 1) % main.records.size()] as Array[int]
		main.current_index = 0
		main._show_question()
		main._auto_token += 1
		var view: DiagramView = main.question_diagram_view
		var panel: Control = main.question_diagram_panel
		t.eq(panel.visible, has_fig, "%s: figure panel shown pre-answer iff the record has a figure" % qid)
		for c in main.answers_box.get_children():
			if not c.is_queued_for_deletion():
				t.check(c is AnswerCard, "%s: answers_box holds only answer cards (found %s)" % [qid, c.get_class()])
		if not has_fig:
			continue
		shown += 1
		await _frames(3)
		t.check(panel.is_visible_in_tree(), "%s: figure is actually visible in the tree pre-answer" % qid)
		t.check(view.has_content(), "%s: figure view has something to draw" % qid)
		t.check(not view.is_revealed(), "%s: no answer highlight before answering" % qid)
		t.eq(DiagramView.added_text(rec), PackedStringArray(), "%s: the app adds no caption/label text to a PDF figure" % qid)
		if m.has(qid):
			t.check(view.texture != null, "%s: draws the PDF crop, not a fallback" % qid)
		t.check(view.custom_minimum_size.x == 0.0, "%s: figure never forces a minimum width" % qid)
		if not mobile:
			t.check(main.ref_column.visible, "%s: desktop reference column is shown for the figure" % qid)
		view.open_zoom()
		await _frames(2)
		t.check(view.is_zoomed(), "%s: tapping opens the fullscreen zoom" % qid)
		view.close_zoom()
		await _frames(2)
		t.check(not view.is_zoomed(), "%s: zoom closes" % qid)
		# Android Back on a zoomed figure closes the zoom and stays on the
		# question. One press can arrive as KEY_BACK and a go-back notification
		# ~1 ms apart; together they must still count as one Back.
		view.open_zoom()
		await _frames(2)
		main._last_go_back_msec = -100000
		var back := InputEventKey.new()
		back.keycode = KEY_BACK
		back.pressed = true
		root.push_input(back)
		main._notification(Control.NOTIFICATION_WM_GO_BACK_REQUEST)
		await _frames(2)
		t.check(not view.is_zoomed(), "%s: Android Back closes the zoom" % qid)
		t.check(not main.menu_overlay.visible, "%s: Android Back on a zoomed figure stays on the question" % qid)
		main._last_go_back_msec = -100000
		var ci := int(rec.get("correct_index", 0))
		main._answer_selected(ci)
		main._auto_token += 1
		main._stop_reading()
		await _frames(2)
		t.check(panel.is_visible_in_tree(), "%s: figure stays up after answering" % qid)
		t.eq(view.is_revealed(), m.get(qid, {}).has("highlight"), "%s: answer part highlighted only after answering" % qid)
		main._show_question()
		t.check(not view.is_revealed(), "%s: highlight cleared when the question is shown again" % qid)
	t.eq(shown, _map().size(), "every mapped figure was shown by the 283-record sweep")
	print("  swept %d records, %d with figures" % [main.records.size(), shown])


func _run_mobile_child() -> bool:
	var out: Array = []
	var code := OS.execute(OS.get_executable_path(),
			["--headless", "--path", ".", "--script", "tools/tests/test_diagrams.gd", "--", "--mobile-ui"], out, true)
	var text := ""
	for chunk in out:
		text += str(chunk)
	for line in text.split("\n"):
		if line.contains("FAIL:") or line.begins_with("checks:") or line.contains("==="):
			print("  [mobile] " + line.strip_edges())
	return code == 0
