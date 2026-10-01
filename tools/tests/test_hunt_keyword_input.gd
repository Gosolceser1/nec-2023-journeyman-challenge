extends SceneTree
## "Hover a colored word on desktop, or tap it on a phone, to see just its
## entry" through real input events pushed into the viewport (mouse motion,
## mouse clicks, finger touches), not by calling the handlers:
## - at rest the INDEX line is a dim hover/tap prompt naming no entry, and an
##   entry never makes the box taller than the prompt did;
## - every colored word of a record sample is hoverable/tappable and names
##   exactly its own entry; the line comes back when the pointer moves off or
##   leaves the stem;
## - a click/tap keeps the entry, hover over another keyword shows that one
##   until the pointer leaves, a second tap brings back the full line;
## - a finger tap works (RichTextLabel meta_clicked is mouse-only and
##   project.godot keeps mouse emulation off); a drag is not a tap; a tap and
##   its emulated click count once;
## - with the INDEX line hidden by the fit (either fit path) a tap/hover shows
##   just that entry and the line hides again afterwards;
## - a pick lights the lookup box briefly (amber border and tint easing back,
##   the INDEX text fading up) without moving anything; hovering onto another
##   entry fades the text only; no pulse on unselect, after answering or with
##   Reduce motion (which tints the box while a keyword is picked);
## - nothing carries over to the next question; nothing reacts after answering;
## - keywords are colored as whole words, never a fragment inside a word.
##
##   Godot --headless --path . --script tools/tests/test_hunt_keyword_input.gd [-- --mobile-ui]
##
## Without --mobile-ui the suite also runs itself once with it.

const R = preload("res://tools/tests/t_report.gd")
## Every Nth record with keywords gets the per-keyword hover/tap sweep.
const SAMPLE_EVERY := 11

var t: R = R.new()
var main: Node
var mobile := false


func _initialize() -> void:
	mobile = "--mobile-ui" in OS.get_cmdline_user_args()
	print("=== hunt keyword hover/tap (%s) ===" % ("mobile" if mobile else "desktop"))
	_word_boundaries()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _frames(6)
	main.audio_cfg_path = "user://test_hunt_keyword_input_audio.cfg"
	main.session.bag_path = ""
	main._on_audio_mode_picked(AudioSettings.Mode.SILENT)
	main.audio.hunt_keywords = true
	main._start_quiz(10, 1800, true, "Practice Test")
	main.timer.stop()
	while main._start_tween != null and main._start_tween.is_running():
		await process_frame
	await _frames(2)
	await _sweep()
	var multi := _find_multi()
	t.check(multi >= 0, "a record with 3+ keywords exists")
	if multi >= 0:
		if mobile:
			await _tap_rules(multi)
		else:
			await _hover_click_rules(multi)
		await _drag_and_double_fire(multi)
		await _fit_hidden_rules(multi)
		await _pulse_rules(multi)
		await _stale_and_answered(multi)
	var child_ok := true
	if not mobile:
		child_ok = _run_mobile_child()
	t.report()
	quit(0 if t.failures.is_empty() and child_ok else 1)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _msec_gap() -> void:
	await create_timer(HuntView.DOUBLE_FIRE_MSEC / 1000.0 + 0.05).timeout


# --- node-free: whole-word coloring -----------------------------------------

func _word_boundaries() -> void:
	t.eq(HuntKeywords.find_span("a network for work", "work"), 14, "whole word 'work', not the 'work' in 'network'")
	t.eq(HuntKeywords.find_span("the wireless wire", "wire"), 13, "whole word 'wire', not inside 'wireless'")
	t.eq(HuntKeywords.find_span("wireless only", "wire"), 0, "no whole word: the first occurrence still colors")
	t.eq(HuntKeywords.find_span("pools and pool", "pools"), 0, "a keyword at the start of the stem")
	t.eq(HuntKeywords.find_span("Art. 680 (pools)", "(pools)"), 9, "keyword edges that are not letters need no boundary")
	t.eq(HuntKeywords.find_span("service equipment and service", "service", [{"start": 0, "end": 17}]), 22, "a keyword skips a span another keyword holds")
	t.eq(HuntKeywords.find_span("abc", ""), -1, "empty keyword colors nothing")
	t.eq(HuntKeywords.find_span("abc", "x"), -1, "absent keyword colors nothing")
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	root.add_child(label)
	var hex := HuntView.KEYWORD_COLOR.to_html(false)
	var bank: Array = []
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/question_bank.json"))
	if parsed is Dictionary:
		bank = parsed.get("records", [])
	var checked := 0
	for rec in bank:
		var list := HuntKeywords.keywords(rec)
		if list.is_empty():
			continue
		var prompt := str(rec.get("prompt", ""))
		var code := HuntKeywords.stem_bbcode(rec, prompt, HuntView.KEYWORD_COLOR, true)
		label.text = code
		t.eq(label.get_parsed_text(), prompt, "%s: marked-up stem reads as the bank stem" % rec.get("id"))
		t.eq(code.count("[color=#%s]" % hex), list.size(), "%s: every keyword colored once" % rec.get("id"))
		var taken: Array = []
		for kw in list:
			var text := str(kw.get("text", ""))
			var at := HuntKeywords.find_span(prompt, text, taken)
			taken.append({"start": at, "end": at + text.length()})
			var before := prompt.substr(at - 1, 1) if at > 0 else " "
			var after := prompt.substr(at + text.length(), 1)
			var mid := (HuntKeywords._is_word_char(before) and HuntKeywords._is_word_char(text.left(1))) \
					or (HuntKeywords._is_word_char(after) and HuntKeywords._is_word_char(text.right(1)))
			t.check(at >= 0 and not mid, "%s: '%s' colored as a whole word (at %d)" % [rec.get("id"), text, at])
		checked += 1
	label.queue_free()
	t.check(checked >= 500, "whole-word check covers the bank (%d records)" % checked)


# --- helpers ----------------------------------------------------------------

func _show(i: int) -> void:
	var n: int = main.records.size()
	main.order = [i, (i + 1) % n] as Array[int]
	main.current_index = 0
	main._show_question()
	main._auto_token += 1


func _correct(rec: Dictionary) -> String:
	var answers: Array = rec.get("answers", [])
	var idx := int(rec.get("correct_index", -1))
	return str(answers[idx]) if idx >= 0 and idx < answers.size() else ""


## Keyword i's markup in the stem label.
func _markup(i: int) -> String:
	var text: String = main.question_label.text
	var start := text.find("[url=%d]" % i)
	return text.substr(start, text.find("[/url]", start) - start) if start >= 0 else ""


## Which look keyword i wears: "focus", "hover" or "rest".
func _look(i: int) -> String:
	var code := _markup(i)
	if code.contains(HuntView.FOCUS_TINT.to_html(true)):
		return "focus"
	if code.contains(HuntView.HOVER_TINT.to_html(true)):
		return "hover"
	return "rest" if code.contains(HuntView.KEYWORD_TINT.to_html(true)) else "none"


func _line(rec: Dictionary, only := -1) -> String:
	return AudioExplanationGenerator.redact_answer_spans(HuntKeywords.index_line(rec, only), _correct(rec))


func _find_multi() -> int:
	for i in main.records.size():
		var rec: Dictionary = main.records[i]
		var table = rec.get("reference_table", [])
		if HuntKeywords.keywords(rec).size() >= 3 and not (table is Array and not (table as Array).is_empty()):
			return i
	return -1


## Middle of keyword i on the stem label (label-local), found by its [hint];
## (-1, -1) when the colored word cannot be pointed at.
func _spot(rec: Dictionary, i: int) -> Vector2:
	var label: RichTextLabel = main.question_label
	var want := HuntKeywords.hint_text(rec, HuntKeywords.keywords(rec)[i])
	var y := 1.0
	while y < label.size.y:
		var x := 1.0
		while x < label.size.x:
			if label.get_tooltip(Vector2(x, y)) == want:
				var y2 := y
				while label.get_tooltip(Vector2(x + 3, y2 + 1)) == want:
					y2 += 1
				return Vector2(x + 3, (y + y2) / 2.0)
			x += 4.0
		y += 4.0
	return Vector2(-1, -1)


## A point on the stem away from every keyword.
func _plain_spot(rec: Dictionary) -> Vector2:
	var label: RichTextLabel = main.question_label
	var y := 1.0
	while y < label.size.y:
		var x := 1.0
		while x < label.size.x:
			if main.hunt.keyword_at(Vector2(x, y)) < 0:
				return Vector2(x, y)
			x += 8.0
		y += 4.0
	return Vector2(-1, -1)


func _global(local: Vector2) -> Vector2:
	return main.question_label.get_global_rect().position + local


func _motion(local: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = _global(local)
	ev.global_position = ev.position
	root.push_input(ev, true)


func _leave() -> void:
	var ev := InputEventMouseMotion.new()
	var rect: Rect2 = main.question_label.get_global_rect()
	ev.position = Vector2(rect.position.x + 20, rect.end.y + 400)
	ev.global_position = ev.position
	root.push_input(ev, true)


func _click(local: Vector2) -> void:
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = _global(local)
		ev.global_position = ev.position
		root.push_input(ev, true)


func _touch(local: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.pressed = pressed
	ev.position = _global(local)
	root.push_input(ev, true)


func _tap(local: Vector2) -> void:
	_touch(local, true)
	_touch(local, false)


## Point at keyword i the way the layout's user does: hover on desktop, a
## finger on the phone (the finger's second tap undoes it).
func _point(local: Vector2) -> void:
	if mobile:
		_tap(local)
	else:
		_motion(local)


func _unpoint(local: Vector2) -> void:
	if mobile:
		_tap(local)
	else:
		_motion(local)


# --- the sweep: every keyword of a record sample ----------------------------

func _sweep() -> void:
	var swept := 0
	var seen := 0
	for i in main.records.size():
		var rec: Dictionary = main.records[i]
		var list := HuntKeywords.keywords(rec)
		if list.is_empty():
			continue
		seen += 1
		if seen % SAMPLE_EVERY != 1:
			continue
		_show(i)
		var table = rec.get("reference_table", [])
		await _frames(12 if table is Array and not (table as Array).is_empty() else 3)
		var qid := str(rec.get("id", i))
		var plain := _plain_spot(rec)
		var rest: String = main.index_hint_label.text
		var rest_visible: bool = main.index_hint_label.visible
		var rest_h: float = main.lookup_box.size.y
		t.eq(rest, main.hunt.prompt_text(), "%s: at rest the INDEX line is the prompt, not the entries" % qid)
		for k in list.size():
			var at := _spot(rec, k)
			t.check(at.x >= 0, "%s: colored keyword '%s' can be pointed at" % [qid, list[k].get("text")])
			if at.x < 0:
				continue
			t.eq(main.hunt.keyword_at(at), k, "%s: the word under the pointer is keyword %d" % [qid, k])
			_point(at)
			await _frames(1)
			t.eq(main.index_hint_label.text, _line(rec, k), "%s: pointing at '%s' names just its entry" % [qid, list[k].get("text")])
			t.check(main.index_hint_label.visible and main.lookup_box.visible, "%s: its entry shows" % qid)
			if rest_visible:
				await _frames(1)
				t.eq(main.lookup_box.size.y, rest_h, "%s: '%s' keeps the box height of the prompt" % [qid, list[k].get("text")])
			if mobile:
				await _msec_gap()
				_tap(at)
			else:
				_motion(plain)
			await _frames(1)
			t.eq(main.index_hint_label.text, rest, "%s: back to the line as it was (%s)" % [qid, "second tap" if mobile else "pointer off the word"])
			t.eq(main.index_hint_label.visible, rest_visible, "%s: line visibility as it was" % qid)
			if not mobile:
				_motion(at)
				_leave()
				await _frames(1)
				t.eq(main.index_hint_label.text, rest, "%s: back to the line when the pointer leaves the stem" % qid)
			else:
				await _msec_gap()
		swept += 1
	print("  %d records swept keyword by keyword" % swept)


# --- desktop: hover + click together ----------------------------------------

func _hover_click_rules(i: int) -> void:
	_show(i)
	await _frames(3)
	var rec: Dictionary = main.records[i]
	var p0 := _spot(rec, 0)
	var p1 := _spot(rec, 1)
	var rest: String = main.index_hint_label.text
	var tip = main.question_label._make_custom_tooltip("x")
	t.check(tip is Control and not (tip as Control).visible, "hovering a keyword shows no tooltip over the line beneath")
	if tip is Control:
		(tip as Control).free()
	t.check(not main.question_label.meta_underlined, "keywords are not underlined like links")
	t.eq([_look(0), _look(1), _look(2)], ["rest", "rest", "rest"], "keywords start with the plain mark")
	t.check(rest.begins_with("INDEX  Hover a colored word"), "desktop prompt says hover: '%s'" % rest)
	t.eq(main.index_hint_label.get_theme_color("font_color"), HuntView.PROMPT_COLOR, "the prompt is dim")
	_motion(p0)
	await _frames(1)
	t.eq(main.index_hint_label.get_theme_color("font_color"), HuntView.INDEX_COLOR, "an entry is amber")
	_motion(_plain_spot(rec))
	await _frames(1)
	t.eq(main.index_hint_label.text, rest, "moving off with nothing picked: the prompt again")
	_click(p0)
	await _frames(1)
	t.eq(main.index_hint_label.text, _line(rec, 0), "click keeps keyword 0's entry")
	_motion(p1)
	await _frames(1)
	t.eq(main.index_hint_label.text, _line(rec, 1), "hovering another keyword shows that one")
	t.eq([_look(0), _look(1), _look(2)], ["focus", "hover", "rest"], "clicked keyword is a chip, hovered one a stronger tint")
	_leave()
	await _frames(1)
	t.eq(main.index_hint_label.text, _line(rec, 0), "leaving the stem goes back to the clicked entry")
	t.eq([_look(0), _look(1)], ["focus", "rest"], "leaving drops the hover look only")
	t.eq(main.question_label.get_parsed_text(), str(rec.get("prompt", "")), "the looks never change the stem text")
	_motion(p0)
	_click(p0)
	await _frames(1)
	t.eq(main.index_hint_label.text, _line(rec, 0), "second click while hovering: the hovered entry stays")
	_leave()
	await _frames(1)
	t.eq(main.index_hint_label.text, rest, "second click, pointer gone: the line as it was")


# --- phone: finger taps -----------------------------------------------------

func _tap_rules(i: int) -> void:
	_show(i)
	await _frames(3)
	var rec: Dictionary = main.records[i]
	var p0 := _spot(rec, 0)
	var p1 := _spot(rec, 1)
	var before: String = main.index_hint_label.text
	var before_visible: bool = main.index_hint_label.visible
	t.check(before.begins_with("INDEX  Tap a colored word"), "phone prompt says tap: '%s'" % before)
	_tap(p0)
	await _frames(1)
	t.eq(main.index_hint_label.text, _line(rec, 0), "a finger tap names just keyword 0's entry")
	t.check(main.index_hint_label.visible, "the tapped entry shows")
	t.eq([_look(0), _look(1)], ["focus", "rest"], "the tapped keyword is a chip, the others keep the plain mark")
	await _msec_gap()
	_tap(p1)
	await _frames(1)
	t.eq(main.index_hint_label.text, _line(rec, 1), "a tap on another keyword moves to its entry")
	await _msec_gap()
	_tap(p1)
	await _frames(1)
	t.eq(main.index_hint_label.text, before, "a second tap brings back the line as it was")
	t.eq(main.index_hint_label.visible, before_visible, "...and its visibility")
	await _msec_gap()
	_tap(_plain_spot(rec))
	await _frames(1)
	t.eq(main.index_hint_label.text, before, "a tap on plain stem text changes nothing")


func _drag_and_double_fire(i: int) -> void:
	_show(i)
	await _frames(3)
	var rec: Dictionary = main.records[i]
	var p0 := _spot(rec, 0)
	var before: String = main.index_hint_label.text
	await _msec_gap()
	_touch(p0, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = _global(p0 + Vector2(0, 40))
	root.push_input(drag, true)
	_touch(p0 + Vector2(0, 40), false)
	_touch(p0, false)
	await _frames(1)
	t.eq(main.index_hint_label.text, before, "a drag that starts on a keyword is not a tap")
	await _msec_gap()
	_tap(p0)
	_click(p0)
	await _frames(1)
	t.eq(main.hunt.singled_out(), 0, "a tap and its emulated click count once")
	await _msec_gap()
	_tap(p0)
	await _frames(1)
	t.eq(main.index_hint_label.text, before, "a later tap still undoes it")
	if not mobile:
		_leave()
		await _frames(1)


# --- the fit hid the INDEX line -----------------------------------------------

func _fit_hidden_rules(i: int) -> void:
	for how in ["shrink_index", "table fit"]:
		_show(i)
		await _frames(3)
		main.hunt.refill()
		if how == "shrink_index":
			while main.hunt.shrink_index():
				pass
		else:
			main.index_hint_label.visible = false
			main.hunt.sync_lookup_box()
		var rec: Dictionary = main.records[i]
		var p1 := _spot(rec, 1)
		t.check(not main.index_hint_label.visible, "%s: INDEX line hidden" % how)
		await _msec_gap()
		_point(p1)
		await _frames(1)
		t.eq(main.index_hint_label.text, _line(rec, 1), "%s: pointing still names just that entry" % how)
		t.check(main.index_hint_label.visible and main.lookup_box.visible, "%s: the entry shows although the fit hid the line" % how)
		t.check(main.hunt.pulsing(), "%s: the entry that comes back fades in" % how)
		if mobile:
			t.check(main.hunt.box_lit(), "%s: the tap lights the box that comes back" % how)
		await _msec_gap()
		if mobile:
			_unpoint(p1)
		else:
			_leave()
		await _frames(1)
		t.check(not main.index_hint_label.visible, "%s: the line hides again afterwards" % how)


# --- the lookup box lights up on a pick ----------------------------------------

func _pulse_over() -> void:
	await create_timer(HuntView.PULSE_SEC + 0.1).timeout


## A click (desktop, pointer already resting on the word) or a tap (phone).
func _pick_at(local: Vector2) -> void:
	if mobile:
		_tap(local)
	else:
		_click(local)


func _pulse_rules(i: int) -> void:
	UiFx.reduce_motion = false
	_show(i)
	await _frames(3)
	var rec: Dictionary = main.records[i]
	var p0 := _spot(rec, 0)
	var p1 := _spot(rec, 1)
	var label: Label = main.index_hint_label
	t.check(not main.hunt.pulsing() and not main.hunt.box_lit(), "pulse: nothing lit before a pick")
	await _msec_gap()
	if not mobile:
		_motion(p0)
		await _frames(1)
		t.check(main.hunt.pulsing() and not main.hunt.box_lit(), "pulse: hovering onto an entry fades the text only")
		await _pulse_over()
	var box_size: Vector2 = main.lookup_box.size
	var text_rect: Rect2 = label.get_global_rect()
	_pick_at(p0)
	await _frames(1)
	t.check(main.hunt.pulsing(), "pulse: a pick starts the pulse")
	t.check(main.hunt.box_lit(), "pulse: the box border/tint lights")
	t.check(label.modulate.a < 1.0, "pulse: the INDEX text fades up (alpha %.2f)" % label.modulate.a)
	t.eq(label.text, _line(rec, 0), "pulse: the line names just the picked entry, nothing more")
	await _frames(2)
	t.eq(main.lookup_box.size, box_size, "pulse: the box keeps its size")
	t.eq(label.get_global_rect(), text_rect, "pulse: the INDEX text stays put")
	await _pulse_over()
	t.check(not main.hunt.pulsing() and not main.hunt.box_lit(), "pulse: settles back to the box's own style")
	t.eq(label.modulate.a, 1.0, "pulse: the text ends opaque")
	await _msec_gap()
	_pick_at(p0)
	await _frames(1)
	t.eq(main.hunt.singled_out(), -1 if mobile else 0, "pulse: second pick unselects")
	t.check(not main.hunt.pulsing() and not main.hunt.box_lit(), "pulse: none on unselect")
	if not mobile:
		_motion(p1)
		await _frames(1)
		t.check(main.hunt.pulsing() and not main.hunt.box_lit(), "pulse: hover switch to another entry fades the text only")
		_motion(_plain_spot(rec))
		_leave()
		await _pulse_over()
	UiFx.reduce_motion = true
	await _msec_gap()
	if not mobile:
		_motion(p1)
		await _frames(1)
		t.check(not main.hunt.pulsing(), "reduce motion: no fade on hover")
	_pick_at(p1)
	await _frames(1)
	t.check(not main.hunt.pulsing(), "reduce motion: no tween on a pick")
	t.check(main.hunt.box_lit(), "reduce motion: the box is tinted at once")
	t.eq(label.modulate.a, 1.0, "reduce motion: the text shows at full alpha")
	await _msec_gap()
	_pick_at(p1)
	await _frames(1)
	t.check(not main.hunt.box_lit(), "reduce motion: the tint goes on unselect")
	if not mobile:
		_leave()
		await _frames(1)
	UiFx.reduce_motion = false


# --- nothing carries over; nothing reacts after answering --------------------

func _stale_and_answered(i: int) -> void:
	_show(i)
	await _frames(3)
	var rec: Dictionary = main.records[i]
	var p0 := _spot(rec, 0)
	await _msec_gap()
	_point(p0)
	await _frames(1)
	t.eq(main.hunt.singled_out(), 0, "keyword singled out before moving on")
	main.current_index = 1
	main._show_question()
	main._auto_token += 1
	await _frames(3)
	var next: Dictionary = main.session.current_record()
	t.eq(main.hunt.singled_out(), -1, "the next question starts with nothing singled out")
	t.check(not main.hunt.pulsing() and not main.hunt.box_lit(), "the next question starts with the box unlit")
	if not HuntKeywords.keywords(next).is_empty():
		t.eq(main.index_hint_label.text, main.hunt.prompt_text(), "the next question starts with the prompt")
	_show(i)
	await _frames(3)
	await _msec_gap()
	_click(_spot(rec, 0))
	_tap(_spot(rec, 0))
	await _frames(1)
	t.eq(_look(0), "focus", "keyword singled out just before answering")
	var shown: Dictionary = main.session.display_record(i)
	main._answer_selected((int(shown.get("correct_index", 0)) + 1) % (shown.get("answers", []) as Array).size())
	main._auto_token += 1
	main._stop_reading()
	await _frames(2)
	await _msec_gap()
	_point(_spot(rec, 0))
	_click(_spot(rec, 0))
	await _frames(1)
	t.check(not main.index_hint_label.visible and not main.lookup_box.visible, "after answering, hover/tap shows no INDEX line")
	t.eq(main.hunt.singled_out(), -1, "after answering nothing is singled out")
	t.check(not main.hunt.pulsing() and not main.hunt.box_lit(), "after answering a pick lights nothing")
	t.eq(_look(0), "rest", "after answering the keyword is back to the plain mark")


func _run_mobile_child() -> bool:
	var out: Array = []
	var code := OS.execute(OS.get_executable_path(),
			["--headless", "--path", ".", "--script", "tools/tests/test_hunt_keyword_input.gd", "--", "--mobile-ui"], out, true)
	var text := ""
	for chunk in out:
		text += str(chunk)
	for line in text.split("\n"):
		if line.contains("FAIL:") or line.begins_with("checks:") or line.contains("===") or line.contains("swept") or line.contains("SCRIPT ERROR"):
			print("  [mobile] " + line.strip_edges())
	return code == 0
