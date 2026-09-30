extends SceneTree
## The "where to look" breadcrumb on screen belongs to the question on screen.
## Every record in turn, in a shuffled order with shuffled choices, through the
## real Next flow: before answering the breadcrumb names the record's own
## chapter and article (canonical NEC 2023 titles), after answering it is gone
## and never shows another record's article.
##
##   Godot --headless --path . --script tools/tests/test_breadcrumb.gd [-- --mobile-ui]
##
## Without --mobile-ui the suite also runs itself once with it.

const R = preload("res://tools/tests/t_report.gd")

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
		var shown_rec: Dictionary = main.session.current_record()
		var wrong := (int(shown_rec["correct_index"]) + 1 + q % 3) % (shown_rec["answers"] as Array).size()
		main._answer_selected(wrong if q % 2 == 0 else int(shown_rec["correct_index"]))
		main._auto_token += 1
		main._stop_reading()
		t.check(not main.chapter_hint_label.visible and not main.lookup_box.visible,
				"%s: breadcrumb hidden after answering" % qid)
		t.check(main.chapter_hint_label.text == shown, "%s: breadcrumb unchanged by answering" % qid)
		var reference := str(rec.get("article", ""))
		var article := NecReference.primary_article(reference)
		if article >= 100:
			t.eq(main.feedback_reference.text, "Article %d %s — %s" % [article, NecReference.canonical_article_title(article), reference],
					"%s: reference line after answering" % qid)
		seen += 1
		if q < n - 1:
			main._next_question()
	t.eq(seen, n, "every record swept")
	print("  %d records swept" % seen)


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
