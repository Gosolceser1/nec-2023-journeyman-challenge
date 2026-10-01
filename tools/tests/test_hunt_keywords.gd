extends SceneTree
## Code-book hunt keywords on the question screen, every record:
## - the stem reads exactly as the bank has it (the colors are markup only),
##   each keyword is colored, the INDEX line at rest is the hover/tap prompt
##   and a pick names that keyword's entry;
## - neither names the correct choice, and no keyword or its Index heading holds
##   any choice (distractors included); the answers box holds answer cards only;
## - after answering the INDEX line goes and the reference line is unchanged;
## - the spoken question is the same with the setting on or off;
## - the setting off, or the Full Exam, shows no keywords at all;
## - with the keywords on, the page does not scroll before answering at any
##   standard window size.
##
##   Godot --headless --path . --script tools/tests/test_hunt_keywords.gd [-- --mobile-ui]
##
## Without --mobile-ui the suite also runs itself once with it.

const R = preload("res://tools/tests/t_report.gd")
const SpeechText = preload("res://src/speech/speech_text.gd")
const TOL := 0.5
const DESKTOP_SIZES := [Vector2i(1280, 720), Vector2i(1024, 600), Vector2i(1920, 1080)]
const PHONE_SIZES := [Vector2i(360, 640), Vector2i(412, 915), Vector2i(540, 960), Vector2i(800, 1280)]

var t: R = R.new()
var main: Node
var mobile := false
var base := Vector2.ZERO


func _initialize() -> void:
	mobile = "--mobile-ui" in OS.get_cmdline_user_args()
	print("=== hunt keywords (%s) ===" % ("mobile" if mobile else "desktop"))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _frames(6)
	main.audio_cfg_path = "user://test_hunt_keywords_audio.cfg"
	main.session.bag_path = ""
	main._on_audio_mode_picked(AudioSettings.Mode.SILENT)
	_data_rules()
	_setting_round_trip()
	main._start_quiz(10, 1800, true, "Practice Test")
	main.timer.stop()
	while main._start_tween != null and main._start_tween.is_running():
		await process_frame
	await _frames(2)
	base = Vector2(root.content_scale_size)
	await _screen_rules()
	for s in (PHONE_SIZES if mobile else DESKTOP_SIZES):
		await _fit_sweep(s)
	await _full_exam_is_clean()
	var child_ok := true
	if not mobile:
		child_ok = _run_mobile_child()
	t.report()
	quit(0 if t.failures.is_empty() and child_ok else 1)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _correct(rec: Dictionary) -> String:
	var answers: Array = rec.get("answers", [])
	var idx := int(rec.get("correct_index", -1))
	return str(answers[idx]) if idx >= 0 and idx < answers.size() else ""


func _names_answer(text: String, answer: String) -> bool:
	var a := answer.strip_edges().to_lower()
	return a.length() > 1 and text.to_lower().contains(a)


## Lowercase words joined by single spaces, for whole-word containment.
func _words(text: String) -> String:
	var out := ""
	for c in text.to_lower():
		out += c if (c >= "a" and c <= "z") or (c >= "0" and c <= "9") else " "
	return " ".join(out.split(" ", false))


func _holds(haystack: String, needle: String) -> bool:
	var n := _words(needle)
	return n != "" and (" %s " % _words(haystack)).contains(" %s " % n)


## Neither a keyword nor its Index heading may hold any choice, distractors
## included (unless every choice holds it): a marked choice points at itself.
func _points_at_choice(rec: Dictionary, kw: Dictionary) -> String:
	var choices: Array = (rec.get("answers", []) as Array).filter(func(a): return _words(str(a)) != "")
	for choice in choices:
		if choices.all(func(c): return _holds(str(c), str(choice))):
			continue
		if _words(str(kw.get("text", ""))) == _words(str(choice)) or _holds(str(kw.get("text", "")), str(choice)) \
				or _holds(str(kw.get("index", "")), str(choice)):
			return str(choice)
	return ""


## Node-free rules on every record: markup parses back to the stem, colors
## one span per keyword, never names the answer.
func _data_rules() -> void:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	root.add_child(label)
	var with_keywords := 0
	for rec in main.records:
		var qid := str(rec.get("id", ""))
		var prompt := str(rec.get("prompt", ""))
		var list := HuntKeywords.keywords(rec)
		var code := HuntKeywords.stem_bbcode(rec, prompt, HuntView.KEYWORD_COLOR, true)
		label.text = code
		t.eq(label.get_parsed_text(), prompt, "%s: marked-up stem reads as the bank stem" % qid)
		t.eq(code.count("[color="), list.size(), "%s: one colored span per keyword" % qid)
		t.eq(HuntKeywords.stem_bbcode(rec, prompt, HuntView.KEYWORD_COLOR, false), HuntKeywords.escape_bbcode(prompt), "%s: off means plain" % qid)
		if list.is_empty():
			t.eq(HuntKeywords.index_line(rec), "", "%s: no keywords, no INDEX line" % qid)
			continue
		with_keywords += 1
		var answer := _correct(rec)
		for kw in list:
			t.check(prompt.contains(str(kw.get("text", ""))), "%s: keyword '%s' is in the stem" % [qid, kw.get("text")])
			t.check(not _names_answer(str(kw.get("text", "")), answer), "%s: keyword '%s' holds the answer" % [qid, kw.get("text")])
			var choice := _points_at_choice(rec, kw)
			t.check(choice == "", "%s: keyword '%s' (%s) points at the choice '%s'" % [qid, kw.get("text"), kw.get("index"), choice])
		var line := HuntKeywords.index_line(rec)
		t.check(line.begins_with("INDEX  "), "%s: INDEX line '%s'" % [qid, line])
		if answer.strip_edges().length() > 3 and not answer.strip_edges().is_valid_float():
			t.check(not _names_answer(line, answer), "%s: INDEX line '%s' names the answer '%s'" % [qid, line, answer])
		if not bool(HuntKeywords.for_record(rec).get("show_article", false)):
			t.check(not line.contains("Art. "), "%s: article hidden when the stem asks for it ('%s')" % [qid, line])
	label.queue_free()
	t.check(with_keywords >= 500, "most records have hunt keywords (%d)" % with_keywords)
	print("  %d records with hunt keywords" % with_keywords)


func _setting_round_trip() -> void:
	var cfg := "user://test_hunt_keywords_setting.cfg"
	var a := AudioSettings.new()
	t.check(a.hunt_keywords, "hunt keywords are on by default")
	a.hunt_keywords = false
	a.save_to(cfg)
	var b := AudioSettings.new()
	b.load_from(cfg)
	t.check(not b.hunt_keywords, "the setting survives a restart")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(cfg))
	t.check(not HuntKeywords.enabled(true, true), "never in the Full Exam")
	t.check(HuntKeywords.enabled(true, false) and not HuntKeywords.enabled(false, false), "follows the setting in practice")
	t.check(is_instance_valid(main.hunt_keywords_toggle) and main.hunt_keywords_toggle.button_pressed, "settings toggle shows the setting")


func _show(i: int) -> void:
	var n: int = main.records.size()
	main.order = [i, (i + 1) % n] as Array[int]
	main.current_index = 0
	main._show_question()
	main._auto_token += 1


## Every record through the real screen: before and after answering, on and off.
func _screen_rules() -> void:
	for i in main.records.size():
		var rec: Dictionary = main.records[i]
		var qid := str(rec.get("id", i))
		var list := HuntKeywords.keywords(rec)
		main.audio.hunt_keywords = true
		_show(i)
		var plan_on := JSON.stringify(SpeechText.speech_plan(main.session.display_record(i)))
		t.eq(main.question_label.get_parsed_text(), str(rec.get("prompt", "")), "%s: stem on screen" % qid)
		for c in main.answers_box.get_children():
			t.check(c is AnswerCard, "%s: answers box holds answer cards only (%s)" % [qid, c.get_class()])
		if not list.is_empty():
			t.eq(main.question_label.text.count("[color="), list.size(), "%s: keywords colored" % qid)
			t.check(main.index_hint_label.visible and main.lookup_box.visible, "%s: INDEX line shown" % qid)
			t.eq(main.index_hint_label.text, main.hunt.prompt_text(), "%s: at rest the INDEX line is the prompt" % qid)
			for kw in list:
				var heading := str(kw.get("index", ""))
				t.check(heading == "" or not main.index_hint_label.text.contains(heading), "%s: the rest line names no entry ('%s')" % [qid, heading])
			if i % 17 == 0:
				main.hunt.on_keyword_clicked("0")
				t.eq(main.index_hint_label.text, AudioExplanationGenerator.redact_answer_spans(HuntKeywords.index_line(rec, 0), _correct(rec)), "%s: a tap singles out its entry" % qid)
				main.hunt.on_keyword_clicked("0")
		else:
			t.check(not main.index_hint_label.visible, "%s: no INDEX line without keywords" % qid)
		var shown: Dictionary = main.session.display_record(i)
		main._answer_selected((int(shown.get("correct_index", 0)) + 1) % (shown.get("answers", []) as Array).size())
		main._auto_token += 1
		main._stop_reading()
		t.check(not main.index_hint_label.visible and not main.lookup_box.visible, "%s: INDEX line gone after answering" % qid)
		t.eq(main.feedback_reference.text, NecReference.format_reference(rec), "%s: reference line unchanged" % qid)
		main.audio.hunt_keywords = false
		_show(i)
		t.eq(JSON.stringify(SpeechText.speech_plan(main.session.display_record(i))), plan_on, "%s: spoken question unchanged by the setting" % qid)
		t.check(not main.question_label.text.contains("[color=") and not main.index_hint_label.visible, "%s: setting off shows no keywords" % qid)
	main.audio.hunt_keywords = true
	await _frames(1)


func _page_scroll() -> ScrollContainer:
	var n: Node = main.answers_box
	while n != null and not n is ScrollContainer:
		n = n.get_parent()
	return n as ScrollContainer


func _overflow(scroll: ScrollContainer) -> float:
	return (scroll.get_child(0) as Control).get_combined_minimum_size().y - scroll.size.y


func _canvas_for(win: Vector2i) -> Vector2i:
	var s := minf(win.x / base.x, win.y / base.y)
	return Vector2i(roundi(win.x / s), roundi(win.y / s))


func _fit_sweep(win: Vector2i) -> void:
	var canvas := _canvas_for(win)
	root.content_scale_size = canvas
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	await _frames(8)
	var scroll := _page_scroll()
	var worst := -INF
	var worst_at := ""
	var swept := 0
	for i in main.records.size():
		var rec: Dictionary = main.records[i]
		if HuntKeywords.keywords(rec).is_empty():
			continue
		_show(i)
		var table = rec.get("reference_table", [])
		await _frames(12 if table is Array and not (table as Array).is_empty() else 3)
		var pre := _overflow(scroll)
		if pre > worst:
			worst = pre
			worst_at = str(rec.get("id", i))
		t.check(pre <= TOL, "%dx%d %s: no page scroll before answering with keywords (%.0f px over)" % [win.x, win.y, rec.get("id", i), pre])
		swept += 1
	print("  %dx%d: %d records, tightest %s (%.0f px)" % [win.x, win.y, swept, worst_at, worst])


func _full_exam_is_clean() -> void:
	main._start_quiz(10, 1800, true, main.SIMULATION_NAME)
	main.timer.stop()
	while main._start_tween != null and main._start_tween.is_running():
		await process_frame
	t.check(main.session.session_simulation, "Full Exam session started")
	for q in 5:
		var rec: Dictionary = main.session.current_record()
		t.check(not main.question_label.text.contains("[color=") and not main.index_hint_label.visible,
				"Full Exam %s: no keywords" % rec.get("id", q))
		main.current_index = mini(main.current_index + 1, main.order.size() - 1)
		main._show_question()
		main._auto_token += 1


func _run_mobile_child() -> bool:
	var out: Array = []
	var code := OS.execute(OS.get_executable_path(),
			["--headless", "--path", ".", "--script", "tools/tests/test_hunt_keywords.gd", "--", "--mobile-ui"], out, true)
	var text := ""
	for chunk in out:
		text += str(chunk)
	for line in text.split("\n"):
		if line.contains("FAIL:") or line.begins_with("checks:") or line.contains("===") or line.contains("tightest") or line.contains("hunt keywords"):
			print("  [mobile] " + line.strip_edges())
	return code == 0
