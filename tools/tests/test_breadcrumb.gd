extends SceneTree
## The "where to look" breadcrumb on screen belongs to the question on screen.
## Every record in turn, in a shuffled order with shuffled choices, through the
## real Next flow: before answering the breadcrumb names the record's own
## chapter and article (canonical NEC 2023 titles), after answering it is gone
## and never shows another record's article. Before answering no gist, table
## note or formula strip shows and no visible text holds the answer; after
## answering the explanation carries the method.
##
##   Godot --headless --path . --script tools/tests/test_breadcrumb.gd [-- --mobile-ui]
##
## Without --mobile-ui the suite also runs itself once with it.

const R = preload("res://tools/tests/t_report.gd")

## Visible texts that hold the answer's digits by coincidence: the chapter of a
## section-number-choice question ("4 feet" in Chapter 4). Blanking the
## chapter would point at the answer instead.
const COINCIDENCES := {
	"open-book-exam-#3-018": "NEC 2023  ►  Chapter 4: Equipment for General Use",
}

static var LOCATION := RegEx.create_from_string("(?<![\\w.])(?:90|\\d{3})\\.\\d+(?:\\([A-Za-z0-9]+\\))*|\\bTables?\\s+\\d+[A-Z]?(?:\\.\\d+)?(?:\\([A-Za-z0-9]+\\))*|\\bPart\\s+[IVX]+\\b")

var t: R = R.new()
var main: Node
var mobile := false


func _initialize() -> void:
	mobile = "--mobile-ui" in OS.get_cmdline_user_args()
	print("=== breadcrumb follows the question (%s) ===" % ("mobile" if mobile else "desktop"))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _frames(4)
	main.audio_cfg_path = "user://test_breadcrumb_audio.cfg"
	main.session.bag_path = ""
	main._on_audio_mode_picked(AudioSettings.Mode.SILENT)
	main.session.rng.seed = 23
	main._start_quiz(10, 1800, true, "Practice Test")
	main.timer.stop()
	while main._start_tween != null and main._start_tween.is_running():
		await process_frame
	await _sweep()
	var child_ok := true
	if not mobile:
		child_ok = _run_mobile_child()
	t.report()
	quit(0 if t.failures.is_empty() and child_ok else 1)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _sweep() -> void:
	var n: int = main.records.size()
	var order: Array[int] = []
	for i in n:
		order.append(i)
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	for i in range(n - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := order[i]
		order[i] = order[j]
		order[j] = tmp
	main.session.order = order
	main.session.choice_orders.clear()
	for i in n:
		main.session.choice_orders[i] = ChoiceOrder.shuffled(main.records[i], rng)
	main.session.current_index = 0
	main._show_question()
	var seen := 0
	var previous_text := ""
	for q in n:
		await process_frame
		var ri: int = main.order[q]
		var rec: Dictionary = main.records[ri]
		var qid := str(rec.get("id", ri))
		t.eq(main.question_label.get_parsed_text(), str(rec.get("prompt", "")), "%s: stem on screen" % qid)
		var shown: String = main.chapter_hint_label.text
		var want := NecReference.expected_breadcrumb(rec)
		if NecReference.is_reference_seeking(str(rec.get("prompt", "")), rec.get("answers", [])):
			want = NecReference.chapter_only_path(want)
		if want != "":
			t.check(main.chapter_hint_label.visible, "%s: breadcrumb visible before answering" % qid)
			t.check(shown == want or shown.contains("___"),
					"%s: breadcrumb '%s', want '%s'" % [qid, shown, want])
		var own := NecReference.lookup_path(rec)
		if previous_text != "" and previous_text != own and shown == previous_text:
			t.check(false, "%s: breadcrumb left over from the previous question" % qid)
		previous_text = own
		_pre_answer_text(qid, main.session.current_record())
		var shown_rec: Dictionary = main.session.current_record()
		var wrong := (int(shown_rec["correct_index"]) + 1 + q % 3) % (shown_rec["answers"] as Array).size()
		main._answer_selected(wrong if q % 2 == 0 else int(shown_rec["correct_index"]))
		main._auto_token += 1
		main._stop_reading()
		t.check(not main.chapter_hint_label.visible and not main.lookup_box.visible,
				"%s: breadcrumb hidden after answering" % qid)
		var cards: Array = main.answers_box.get_children()
		var listed := cards.size() == (shown_rec["answers"] as Array).size()
		for card in cards:
			listed = listed and card is AnswerCard and (card as Control).visible \
					and (card as AnswerCard).current_state in [AnswerCard.State.CORRECT, AnswerCard.State.WRONG, AnswerCard.State.ELIMINATED]
		t.check(listed, "%s: every choice stays listed after answering (green, red or dimmed)" % qid)
		t.check((cards[int(shown_rec["correct_index"])] as AnswerCard).current_state == AnswerCard.State.CORRECT, "%s: the correct card is green" % qid)
		var explained: String = main.info_label.get_parsed_text()
		t.check(explained.contains("CODE PROVISION"), "%s: the code provision shows after answering" % qid)
		for word in ["THE IDEA", "INDEX"]:
			t.check(not explained.contains(word), "%s: no %s after answering" % [qid, word])
		if mobile:
			t.check(main.feedback_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED,
					"%s: the explanation grows into the page's one scroll, no box scrolls inside it" % qid)
		t.check(main.chapter_hint_label.text == shown, "%s: breadcrumb unchanged by answering" % qid)
		if str(rec.get("worked", "")).strip_edges() != "":
			t.check(explained.contains("WORKED SOLUTION\n"), "%s: the worked solution shows after answering" % qid)
		elif str(rec.get("formula", "")).strip_edges() != "":
			t.check(explained.contains("METHOD & FORMULA\n"), "%s: the method shows after answering" % qid)
		var reference := str(rec.get("article", ""))
		var article := NecReference.primary_article(reference)
		if article >= 100:
			t.eq(main.feedback_reference.text, "%s — %s" % [reference.trim_prefix("NEC "), NecReference.canonical_article_title(article)],
					"%s: reference line after answering" % qid)
		seen += 1
		if q < n - 1:
			main._next_question()
	t.eq(seen, n, "every record swept")
	print("  %d records swept" % seen)


## Before answering the screen states no method and no answer: the gist, the
## table note and the formula strip are hidden, and no visible text outside the
## stem, the choices and the table cells (which blank the answer themselves)
## holds the correct choice.
func _pre_answer_text(qid: String, rec: Dictionary) -> void:
	t.check(not main.article_label.visible and not main.question_hint_row.visible, "%s: no gist line before answering" % qid)
	t.check(not main.formula_box.visible and not main.question_formula_label.visible, "%s: no formula strip before answering" % qid)
	t.check(not main.question_table_note.is_visible_in_tree(), "%s: no table note before answering" % qid)
	t.check(not (main.question_table_panel.visible and main.question_diagram_panel.visible),
			"%s: one reference at a time before answering" % qid)
	var answers: Array = rec.get("answers", [])
	var correct := str(answers[int(rec.get("correct_index", 0))])
	var roots: Array[Node] = [main.question_panel]
	if is_instance_valid(main.ref_column):
		roots.append(main.ref_column)
	var texts: Array[String] = []
	for r in roots:
		_visible_texts(r, texts)
	var stem := str(rec.get("prompt", ""))
	for text in texts:
		if COINCIDENCES.get(qid, "") == text:
			continue
		if not AudioExplanationGenerator.find_match_in(text, correct).is_empty():
			t.check(false, "%s: '%s' shows the answer '%s' before answering" % [qid, text, correct])
		# Where the rule is (section, table or Part) is what the learner finds;
		# only the stem may name one. The breadcrumb's article may show.
		for m in LOCATION.search_all(text):
			if not stem.contains(m.get_string()):
				t.check(false, "%s: '%s' names %s before answering" % [qid, text, m.get_string()])
	# The surfaces that teach (gist, formula, table note) and the reference's
	# own title name no choice at all, right or wrong.
	var teaching: Array[String] = []
	for node in [main.article_label, main.question_formula_label, main.question_table_note, main.question_table_heading, main.ref_tabs]:
		_visible_texts(node, teaching)
	for text in teaching:
		for choice in answers:
			if not AudioExplanationGenerator.find_match_in(text, str(choice)).is_empty():
				t.check(false, "%s: '%s' names the choice '%s' before answering" % [qid, text, choice])


func _visible_texts(node: Node, out: Array[String]) -> void:
	if node == main.question_label or node == main.answers_box or node == main.question_table_grid:
		return
	if node is CanvasItem and not (node as CanvasItem).is_visible_in_tree():
		return
	if node is Label:
		out.append((node as Label).text)
	elif node is RichTextLabel:
		out.append((node as RichTextLabel).get_parsed_text())
	elif node is Button:
		out.append((node as Button).text)
	for c in node.get_children():
		_visible_texts(c, out)


func _run_mobile_child() -> bool:
	var out: Array = []
	var code := OS.execute(OS.get_executable_path(),
			["--headless", "--path", ".", "--script", "tools/tests/test_breadcrumb.gd", "--", "--mobile-ui"], out, true)
	var text := ""
	for chunk in out:
		text += str(chunk)
	for line in text.split("\n"):
		if line.contains("FAIL:") or line.begins_with("checks:") or line.contains("===") or line.contains("swept"):
			print("  [mobile] " + line.strip_edges())
	return code == 0
