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
	# The menu fade ends in its own _show_question, which would close a zoom
	# the sweep just opened.
	while main._start_tween != null and main._start_tween.is_running():
		await process_frame
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
	_mask_data_checks(m)


static func _inside_unit(r) -> bool:
	return r is Array and r.size() == 4 and float(r[2]) > 0.0 and float(r[3]) > 0.0 \
			and float(r[0]) >= 0.0 and float(r[1]) >= 0.0 \
			and float(r[0]) + float(r[2]) <= 1.0001 and float(r[1]) + float(r[3]) <= 1.0001


static func _contains(outer: Array, inner: Array) -> bool:
	return float(inner[0]) >= float(outer[0]) - 0.0001 and float(inner[1]) >= float(outer[1]) - 0.0001 \
			and float(inner[0]) + float(inner[2]) <= float(outer[0]) + float(outer[2]) + 0.0001 \
			and float(inner[1]) + float(inner[3]) <= float(outer[1]) + float(outer[3]) + 0.0001


## The leak guard: every region flagged as giving the answer away must sit
## inside a mask, or the figure would show it before answering.
static func leak_problems(file: String, entry: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var masks: Array = entry.get("masks", [])
	for mk in masks:
		if not (mk is Dictionary and _inside_unit(mk.get("rect"))):
			out.append("%s: mask rect %s is not a box inside the image" % [file, mk])
	for leak in entry.get("leaks", []):
		var region = leak.get("region") if leak is Dictionary else null
		if not _inside_unit(region):
			out.append("%s: leak %s has no valid region" % [file, leak])
			continue
		var covered := false
		for mk in masks:
			if mk is Dictionary and _inside_unit(mk.get("rect")) and _contains(mk["rect"], region):
				covered = true
		if not covered:
			out.append("%s: leak '%s' at %s has no mask" % [file, leak.get("what", ""), region])
	return out


func _mask_data_checks(m: Dictionary) -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(DiagramView.MASKS_PATH))
	t.check(parsed is Dictionary and parsed.get("diagrams") is Dictionary, "diagram_masks.json parses")
	var entries: Dictionary = parsed.get("diagrams", {}) if parsed is Dictionary else {}
	var files := {}
	for qid in m:
		files[str(m[qid].get("file", "")).get_file()] = qid
	for file in entries:
		t.check(files.has(file), "%s: mask entry maps to a figure in diagrams.json" % file)
		t.check(ResourceLoader.exists("res://assets/diagrams/" + file), "%s: mask entry's figure exists in assets/diagrams" % file)
		var e: Dictionary = entries[file]
		t.check(str(e.get("reviewed", "")) != "", "%s: pixel review is dated" % file)
		for p in leak_problems(file, e):
			t.check(false, p)
	for file in files:
		t.check(entries.has(file), "%s: figure has a leak review in diagram_masks.json (every figure must)" % file)
	# The guard itself must catch an unmasked leak and accept a covered one.
	var leak := {"region": [0.2, 0.2, 0.1, 0.1], "what": "dimension"}
	t.check(not leak_problems("x.png", {"leaks": [leak], "masks": []}).is_empty(), "guard fails a leak with no mask")
	t.check(not leak_problems("x.png", {"leaks": [leak], "masks": [{"rect": [0.25, 0.2, 0.1, 0.1]}]}).is_empty(), "guard fails a mask that only partly covers the leak")
	t.check(leak_problems("x.png", {"leaks": [leak], "masks": [{"rect": [0.15, 0.15, 0.2, 0.2]}]}).is_empty(), "guard accepts a covered leak")


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
		var file_masks := DiagramView.masks_for_file(str(m.get(qid, {}).get("file", "")))
		t.eq(view.masks.size(), file_masks.size(), "%s: the figure carries its masks from diagram_masks.json" % qid)
		if not file_masks.is_empty():
			t.check(view.is_masked(), "%s: answer regions masked before answering" % qid)
			view.open_zoom()
			await _frames(2)
			var sheet = view._zoom.get_child(0)
			t.eq(view.mask_rects(sheet._card_rect().grow(-16)).size(), file_masks.size(), "%s: zoom view is masked too" % qid)
			view.close_zoom()
			await _frames(2)
		var ci := int(rec.get("correct_index", 0))
		main._answer_selected(ci)
		main._auto_token += 1
		main._stop_reading()
		await _wait(DiagramView.MASK_FADE + 0.15)
		t.check(panel.is_visible_in_tree(), "%s: figure stays up after answering" % qid)
		t.eq(view.is_revealed(), m.get(qid, {}).has("highlight"), "%s: answer part highlighted only after answering" % qid)
		t.check(not view.is_masked(), "%s: no mask left after answering" % qid)
		main._show_question()
		t.check(not view.is_revealed(), "%s: highlight cleared when the question is shown again" % qid)
		t.eq(view.is_masked(), not file_masks.is_empty(), "%s: masks come back when the question is shown again" % qid)
	t.eq(shown, _map().size(), "every mapped figure was shown by the 283-record sweep")
	print("  swept %d records, %d with figures" % [main.records.size(), shown])
	await _masked_figure_checks()


func _wait(sec: float) -> void:
	await create_timer(sec).timeout
	await process_frame


## The shipped figures need no masks today (docs/DIAGRAMS_AUDIT.md), so the
## mask path is exercised with one injected on a real figure record.
func _masked_figure_checks() -> void:
	var m := _map()
	var qid: String = m.keys()[0]
	var i := -1
	for k in main.records.size():
		if str(main.records[k].get("id", "")) == qid:
			i = k
	var view: DiagramView = main.question_diagram_view
	for reduce in [false, true]:
		main.audio.reduce_motion = reduce
		main.order = [i, (i + 1) % main.records.size()] as Array[int]
		main.current_index = 0
		main._show_question()
		main._auto_token += 1
		await _frames(3)
		var h0 := view.custom_minimum_size
		view.masks = [{"rect": [0.1, 0.2, 0.3, 0.1], "ring": true}, {"rect": [0.6, 0.6, 0.2, 0.2], "label": "? ft"}]
		view.queue_redraw()
		await _frames(2)
		var tag := "injected mask (%s)" % ("Reduce motion" if reduce else "animated")
		t.check(view.is_masked(), tag + ": masked before answering")
		t.eq(view.custom_minimum_size, h0, tag + ": masks never change the figure's size")
		var a := Rect2(10, 20, 400, 300)
		var r1 := view.mask_rects(a)
		var r2 := view.mask_rects(Rect2(20, 40, 800, 600))
		var img := view.image_rect(a)
		t.check(r1.size() == 2 and img.encloses(r1[0]) and img.encloses(r1[1]), tag + ": badges lie on the picture")
		t.check(r1.size() == 2 and r2[0].size.is_equal_approx(r1[0].size * 2.0), tag + ": badges scale with the figure")
		view.open_zoom()
		await _frames(2)
		var sheet = view._zoom.get_child(0)
		var zr: Array[Rect2] = view.mask_rects(sheet._card_rect().grow(-16))
		t.check(zr.size() == 2 and view.image_rect(sheet._card_rect().grow(-16)).encloses(zr[0]), tag + ": zoom view is masked, badges on the enlarged picture")
		view.close_zoom()
		await _frames(2)
		main._answer_selected(int(main.records[i].get("correct_index", 0)))
		main._auto_token += 1
		main._stop_reading()
		if reduce:
			t.check(not view.is_masked(), tag + ": badges gone at once with Reduce motion")
		else:
			t.check(view.is_masked(), tag + ": badges fade rather than vanish")
			await _wait(DiagramView.MASK_FADE + 0.15)
			t.check(not view.is_masked(), tag + ": badges gone after the fade")
		t.eq(view.mask_rects(a).size(), 0, tag + ": nothing masked after answering")
	main.audio.reduce_motion = false


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
