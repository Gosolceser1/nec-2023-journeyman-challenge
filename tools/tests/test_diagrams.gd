extends SceneTree
## Question figures: every figure the source PDFs print for a question must be
## on screen BEFORE the learner answers (redrawn as an original figure, with
## the keyed part outlined after answering) and give nothing away until the
## answer is in. All figures (assets/diagrams/nec/) are masked per question
## before answering (inline and zoomed), revealed after, show no label with
## the answer outside a mask, and "after" figures only once answered.
##
##   Godot --headless --path . --script tools/tests/test_diagrams.gd [-- --mobile-ui]
##
## Without --mobile-ui the suite also runs itself once with it, so run_all.gd
## covers both layouts (ui_mobile is read from the command line in _ready and
## cannot be flipped in-process).

const R = preload("res://tools/tests/t_report.gd")
const MAP_PATH := "res://assets/diagrams/diagrams.json"
const LABELS_PATH := "res://docs/diagrams/labels.json"
const BANK_PATH := "res://data/question_bank.json"
## Prompt/choice wording that only makes sense with a picture next to it.
const NEEDS_FIGURE := "(?i)(refer to the figure|figure below|shown below|diagram [a-d]\\b|which of the following is an? (ammeter|voltmeter|wattmeter|ohmmeter)\\b)"
## Questions the printed exam answers only with its figure; each is redrawn.
const REQUIRED := ["final-exam-#1-005", "final-exam-#1-013", "final-exam-#1-047"]

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


## Every mapped figure: the PDF crops and the original study figures.
func _map() -> Dictionary:
	return DiagramView.all_figures()


func _pdf_map() -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH))
	return parsed if parsed is Dictionary else {}


func _bank_by_id() -> Dictionary:
	var bank = JSON.parse_string(FileAccess.get_file_as_string(BANK_PATH))
	var by_id := {}
	for r in (bank.get("records", []) if bank is Dictionary else []):
		by_id[str(r.get("id", ""))] = r
	return by_id


func _data_checks() -> void:
	var m := _map()
	t.check(JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH)) is Dictionary, "diagrams.json parses")
	for qid in REQUIRED:
		var e: Dictionary = m.get(qid, {})
		t.check(str(e.get("source", "")) == "original" and not e.has("pdf"), "%s: required exam figure is a redrawn original, not a PDF crop" % qid)
		t.check(e.has("highlight") and DiagramView.shows_before_answer(e), "%s: required figure shows before answering and outlines the keyed part after" % qid)
	var by_id := _bank_by_id()
	var recs: Array = by_id.values()
	for qid in m:
		var e: Dictionary = m[qid]
		t.check(by_id.has(qid), "%s: mapped figure belongs to a bank record" % qid)
		t.check(ResourceLoader.exists(str(e.get("file", ""))), "%s: figure PNG %s exists" % [qid, e.get("file", "")])
		var tex := load(str(e.get("file", ""))) as Texture2D
		if e.has("pdf"):
			t.check(int(e.get("page", 0)) > 0 and str(e.get("pdf", "")).ends_with(".pdf"), "%s: records its source PDF and page" % qid)
			t.check(tex != null and tex.get_width() >= 400, "%s: crop is high-resolution (width %d)" % [qid, tex.get_width() if tex else 0])
		else:
			t.check(str(e.get("source", "")) == "original" and DiagramView.is_dark_figure(e), "%s: original figure is marked source=original, style=dark" % qid)
			t.check(str(e.get("when", "")) in ["before", "after"], "%s: figure says when it shows (before/after answering)" % qid)
			var sz: Array = e.get("size", [0, 0])
			t.check(tex != null and tex.get_width() == int(sz[0]) and tex.get_height() == int(sz[1]) and tex.get_width() >= 800,
					"%s: figure PNG is the built size %s (got %s)" % [qid, sz, Vector2i(tex.get_width(), tex.get_height()) if tex else Vector2i.ZERO])
			t.check(str(e.get("file", "")).begins_with("res://assets/diagrams/nec/"), "%s: original figure lives in assets/diagrams/nec/" % qid)
		if e.has("highlight"):
			var h: Array = e["highlight"]
			t.check(h.size() == 4 and float(h[2]) > 0.0 and float(h[3]) > 0.0 and float(h[0]) >= -0.01 and float(h[1]) >= -0.01 \
					and float(h[0]) + float(h[2]) <= 1.01 and float(h[1]) + float(h[3]) <= 1.01, "%s: highlight box lies inside the figure" % qid)
	var re := RegEx.create_from_string(NEEDS_FIGURE)
	for r in recs:
		var text := str(r.get("prompt", "")) + " | " + " | ".join(PackedStringArray(r.get("answers", [])))
		if re.search(text) != null:
			t.check(DiagramView.has_figure(r), "%s: stem/choices refer to a picture, so it must have a figure" % r.get("id", ""))
	# Figures replace the old ASCII drafts: nothing may still carry one.
	for r in recs:
		if m.has(str(r.get("id", ""))):
			t.check(str(r.get("diagram", "")) == "", "%s: no stale ASCII diagram next to the figure" % r.get("id", ""))
	_mask_data_checks(_pdf_map())
	_record_mask_checks(m, by_id)


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


## Original figures: masks are per question ("records"), since one drawing
## can serve several questions with different answers.
func _record_mask_checks(m: Dictionary, by_id: Dictionary) -> void:
	var entries := DiagramView.record_mask_map()
	var labels = JSON.parse_string(FileAccess.get_file_as_string(LABELS_PATH))
	t.check(labels is Dictionary, "docs/diagrams/labels.json parses (the leak scan's input)")
	if not labels is Dictionary:
		labels = {}
	var originals := 0
	for qid in m:
		var e: Dictionary = m[qid]
		if e.has("pdf"):
			t.check(not entries.has(qid), "%s: a PDF crop keeps its masks per file, not per record" % qid)
			continue
		originals += 1
		var file := str(e.get("file", "")).get_file()
		t.check(entries.has(qid), "%s: original figure has a mask entry (every one must)" % qid)
		var me: Dictionary = entries.get(qid, {})
		t.eq(str(me.get("file", "")), file, "%s: mask entry names the figure it covers" % qid)
		t.eq(str(me.get("when", "")), str(e.get("when", "")), "%s: mask entry and figure agree on when it shows" % qid)
		t.check(str(me.get("reviewed", "")) != "", "%s: masks are dated" % qid)
		for p in leak_problems(qid, me):
			t.check(false, p)
		if str(e.get("when", "")) != "before":
			continue
		t.check(labels.has(file), "%s: labels recorded for %s" % [qid, file])
		for hit in label_leaks(by_id.get(qid, {}), labels.get(file, []), me.get("masks", []), me.get("terms", [])):
			t.check(false, "%s: label '%s' shows the answer before answering, outside every mask" % [qid, hit])
	for qid in entries:
		t.check(m.has(qid) and not m[qid].has("pdf"), "%s: record mask entry maps to an original figure" % qid)
	print("  %d original figure records checked for label leaks" % originals)
	# The label scan must catch a visible answer and accept a masked one.
	var rec := {"prompt": "Rods shall be not less than ___ apart.", "answers": ["36 inches", "48 inches", "60 inches", "72 inches"], "correct_index": 3}
	var lab := [["6 ft min", 0.4, 0.4, 0.1, 0.05]]
	t.check(not label_leaks(rec, lab, [], []).is_empty(), "label scan catches '6 ft' for a 72 in answer")
	t.check(label_leaks(rec, lab, [{"rect": [0.35, 0.35, 0.2, 0.15]}], []).is_empty(), "label scan accepts the value under a mask")
	t.check(label_leaks(rec, [["8 ft rod", 0.4, 0.4, 0.1, 0.05]], [], []).is_empty(), "label scan ignores other values")
	var word := {"prompt": "The link is the ___.", "answers": ["neutral", "equipment bonding jumper", "main bonding jumper", "GEC"], "correct_index": 2}
	t.check(not label_leaks(word, [["MAIN BONDING JUMPER", 0.4, 0.4, 0.2, 0.05]], [], []).is_empty(), "label scan catches a word answer")


const _NUM := "(\\d+\\s+\\d+/\\d+|\\d+-\\d+/\\d+|\\d+/\\d+|\\d+(?:,\\d{3})*(?:\\.\\d+)?|\\.\\d+)"
const _UNIT := "(inches|inch|in\\.?|\"|feet|foot|ft\\.?|'|mm|percent|%|volts?|v\\b|kv\\b|amperes?|amps?|a\\b|awg)"
const _STOP := ["a", "an", "the", "of", "to", "and", "or", "in", "on", "at", "for", "is", "be", "by", "with",
		"shall", "not", "all", "above", "none", "both", "only", "any", "each", "from", "than",
		"these", "those", "this", "that", "below", "following"]


static func _num(s: String) -> float:
	s = s.replace(",", "").strip_edges()
	var m := RegEx.create_from_string("^(\\d+)[\\s-]+(\\d+)/(\\d+)$").search(s)
	if m != null:
		return float(m.get_string(1)) + float(m.get_string(2)) / float(m.get_string(3))
	m = RegEx.create_from_string("^(\\d+)/(\\d+)$").search(s)
	if m != null:
		return float(m.get_string(1)) / float(m.get_string(2))
	return float(s)


static func _key(kind: String, v: float) -> String:
	return "%s:%.3f" % [kind, v]


## Values stated in text, as "kind:value" keys; lengths in inches.
static func label_values(text: String) -> Dictionary:
	var out := {}
	var taken: Array = []
	var ftin := RegEx.create_from_string("(?i)(?<![\\w.])" + _NUM + "\\s*(?:feet|foot|ft\\.?|')\\s*,?\\s*" + _NUM + "\\s*(?:inches|inch|in\\.?|\")")
	for m in ftin.search_all(text):
		out[_key("len", _num(m.get_string(1)) * 12.0 + _num(m.get_string(2)))] = true
		taken.append(Vector2i(m.get_start(), m.get_end()))
	for m in RegEx.create_from_string("(?i)(?:no\\.|#)\\s*(\\d+(?:/0)?)").search_all(text):
		out["awg:" + m.get_string(1)] = true
	for m in RegEx.create_from_string("(?i)(?<![\\w.])" + _NUM + "\\s*" + _UNIT + "?").search_all(text):
		var inside := false
		for span in taken:
			inside = inside or (m.get_start() >= span.x and m.get_start() < span.y)
		if inside:
			continue
		var v := _num(m.get_string(1))
		var u := m.get_string(2).to_lower().trim_suffix(".")
		var kind := "n"
		var k := 1.0
		if u in ["inches", "inch", "in", "\""]:
			kind = "len"
		elif u in ["feet", "foot", "ft", "'"]:
			kind = "len"
			k = 12.0
		elif u == "mm":
			kind = "len"
			k = 1.0 / 25.4
		elif u in ["percent", "%"]:
			kind = "pct"
		elif u in ["v", "volt", "volts"]:
			kind = "V"
		elif u == "kv":
			kind = "V"
			k = 1000.0
		elif u in ["a", "amp", "amps", "ampere", "amperes"]:
			kind = "A"
		elif u == "awg":
			out["awg:" + m.get_string(1)] = true
			continue
		out[_key(kind, v * k)] = true
		if kind != "n":
			out[_key("n", v)] = true
	return out


static func _words(text: String) -> PackedStringArray:
	var out := PackedStringArray()
	for m in RegEx.create_from_string("[a-z0-9]+").search_all(text.to_lower()):
		if not m.get_string() in _STOP:
			out.append(m.get_string())
	return out


## Labels ([text, x, y, w, h] as image fractions) that state the record's
## answer outside every mask (the rule of tools/diagrams/leakscan.py).
static func label_leaks(rec: Dictionary, labels: Array, masks: Array, terms: Array) -> PackedStringArray:
	var out := PackedStringArray()
	var answers: Array = rec.get("answers", [])
	var ci := int(rec.get("correct_index", -1))
	if ci < 0 or ci >= answers.size():
		return out
	var correct := str(answers[ci])
	var given := label_values(str(rec.get("prompt", "")))
	var others := {}
	var other_words := {}
	for i in answers.size():
		if i != ci:
			others.merge(label_values(str(answers[i])))
			for w in _words(str(answers[i])):
				other_words[w] = true
	var vals := {}
	var has_unit := false
	for k in label_values(correct):
		if not given.has(k) and not others.has(k):
			vals[k] = true
			has_unit = has_unit or not str(k).begins_with("n:")
	if has_unit:
		for k in vals.keys():
			if str(k).begins_with("n:"):
				vals.erase(k)
	var phrases := PackedStringArray()
	var keywords := PackedStringArray()
	var cw := _words(correct)
	if not cw.is_empty() and label_values(correct).is_empty() and " ".join(cw).length() >= 5:
		var stem_words := _words(str(rec.get("prompt", "")))
		var distinct := false
		for w in cw:
			if not other_words.has(w):
				distinct = true
				if w.length() >= 5 and not w in stem_words and not w.is_valid_int():
					keywords.append(w)
		if distinct:
			phrases.append(" ".join(cw))
	for term in terms:
		phrases.append(" ".join(_words(str(term))))
	for lab in labels:
		var box := Rect2(float(lab[1]), float(lab[2]), float(lab[3]), float(lab[4]))
		var hidden := false
		for mk in masks:
			var r: Array = mk.get("rect", [0, 0, 0, 0])
			var mr := Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
			if mr.grow(0.0001).has_point(box.get_center()) and box.intersection(mr).get_area() >= 0.6 * box.get_area():
				hidden = true
		if hidden:
			continue
		var hit := false
		for k in label_values(str(lab[0])):
			hit = hit or vals.has(k)
		var lw := _words(str(lab[0]))
		var low := " " + " ".join(lw) + " "
		for p in phrases:
			hit = hit or (p != "" and low.contains(" " + p + " "))
		for kw in keywords:
			hit = hit or kw in lw
		if hit:
			out.append(str(lab[0]))
	return out


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
		# With a table too, one reference shows at a time: the figure is on its tab.
		if main.ref_tabs.visible:
			main.ref_tabs.figure_tab.button_pressed = true
			main.ref_tabs.figure_tab.pressed.emit()
		var view: DiagramView = main.question_diagram_view
		var panel: Control = main.question_diagram_panel
		var fig: Dictionary = m.get(qid, {})
		var before := has_fig and DiagramView.shows_before_answer(fig)
		t.eq(panel.visible, before, "%s: figure panel shown pre-answer iff the record has a setup figure" % qid)
		for c in main.answers_box.get_children():
			if not c.is_queued_for_deletion():
				t.check(c is AnswerCard, "%s: answers_box holds only answer cards (found %s)" % [qid, c.get_class()])
		if not has_fig:
			continue
		shown += 1
		var card := panel.get_theme_stylebox("panel") as StyleBoxFlat
		t.check(card != null and (card.bg_color.get_luminance() < 0.3) == DiagramView.is_dark_figure(fig),
				"%s: figure card is dark for a dark figure, paper-white for a scan" % qid)
		if not before:
			await _after_figure_checks(qid, rec, view, panel)
			continue
		await _frames(3)
		t.check(panel.is_visible_in_tree(), "%s: figure is actually visible in the tree pre-answer" % qid)
		t.check(view.has_content(), "%s: figure view has something to draw" % qid)
		t.check(not view.is_revealed(), "%s: no answer highlight before answering" % qid)
		t.eq(DiagramView.added_text(rec), PackedStringArray(), "%s: the app adds no caption/label text to a figure image" % qid)
		if m.has(qid):
			t.check(view.texture != null, "%s: draws the figure image, not a fallback" % qid)
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
		var file_masks := DiagramView.masks_for(qid, str(m.get(qid, {}).get("file", "")))
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
	t.eq(shown, _map().size(), "every mapped figure was shown by the whole-bank sweep")
	print("  swept %d records, %d with figures" % [main.records.size(), shown])
	await _masked_figure_checks()


## A teaching figure: nothing on screen (inline or zoom) until answered, then
## shown unmasked.
func _after_figure_checks(qid: String, rec: Dictionary, view: DiagramView, panel: Control) -> void:
	await _frames(3)
	t.check(not panel.is_visible_in_tree() and not view.has_content(), "%s: teaching figure hidden before answering" % qid)
	view.open_zoom()
	await _frames(2)
	t.check(not view.is_zoomed(), "%s: no zoom of a teaching figure before answering" % qid)
	main._answer_selected(int(rec.get("correct_index", 0)))
	main._auto_token += 1
	main._stop_reading()
	await _frames(3)
	t.check(panel.is_visible_in_tree() and view.has_content(), "%s: teaching figure appears after answering" % qid)
	t.check(not view.is_masked(), "%s: teaching figure is unmasked after answering" % qid)
	view.open_zoom()
	await _frames(2)
	t.check(view.is_zoomed(), "%s: teaching figure zooms after answering" % qid)
	view.close_zoom()
	await _frames(2)
	main._show_question()
	await _frames(1)
	t.check(not panel.visible and not view.has_content(), "%s: teaching figure hidden again when the question is shown again" % qid)


func _wait(sec: float) -> void:
	await create_timer(sec).timeout
	await process_frame


## The mask fade and zoom are exercised with masks injected on a real figure
## record that has none of its own.
func _masked_figure_checks() -> void:
	var qid: String = REQUIRED[0]
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
