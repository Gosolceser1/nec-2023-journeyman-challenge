extends SceneTree
## Study feedback: per-area results, pace, readiness, and the weakest-area
## drill on the menu, in both layouts (the mobile one in a child process with
## --mobile-ui, since main picks its layout from the command line).

var failures: Array[String] = []
var checks := 0
var bank: Array = []
var fake_ms := 0

func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func _now() -> int:
	return fake_ms


func _initialize() -> void:
	bank = BankLoader.load_records()
	var mobile := "--mobile-ui" in OS.get_cmdline_user_args()
	if not mobile:
		_session_tallies()
		_bars()
	await _scene(mobile)
	var child_ok := mobile or _run_mobile_child()
	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	print("RESULT: ", "PASS" if failures.is_empty() and child_ok else "FAIL")
	quit(0 if failures.is_empty() and child_ok else 1)


func _run_mobile_child() -> bool:
	var out: Array = []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ".", "--script", "tools/tests/test_study_feedback.gd", "--", "--mobile-ui"], out, true)
	for line in "".join(PackedStringArray(out)).split("\n"):
		if line.contains("FAIL:") or line.contains("===") or line.begins_with("checks:"):
			print("  [mobile] " + line.strip_edges())
	return code == 0


func _session_tallies() -> void:
	print("=== session: areas and pace ===")
	var s := QuizSession.new()
	s.records = bank
	s.rng.seed = 3
	s.clock = _now
	s.begin(10, 1800, true, "Pace")
	var want := {}
	var seconds := [30, 200, 400, 90, 60, 45, 380, 120, 100, 75]
	for j in s.order.size():
		s.current_index = j
		fake_ms = j * 1_000_000
		s.start_question()
		fake_ms += seconds[j] * 1000
		var rec := s.current_record()
		var right := j % 2 == 0
		s.submit(int(rec["correct_index"]) if right else (int(rec["correct_index"]) + 1) % 4, true)
		var k := ExamBlueprint.area_of(bank[s.order[j]])
		var t: Array = want.get(k, [0, 0])
		want[k] = [t[0] + (1 if right else 0), t[1] + 1]
	check(s.area_stats == want, "area tallies match the answers")
	var pace := QuizSession.pace(s.answer_seconds)
	check(is_equal_approx(float(pace["mean"]), 150.0), "mean pace 150 s (%.1f)" % float(pace["mean"]))
	check(pace["slow"] == [3, 7], "answers over 6:00 flagged: items 3 and 7 (%s)" % str(pace["slow"]))
	check(QuizSession.SLOW_SECONDS == 360, "slow means over twice the exam's 3:00 per item")
	check(ResultsView.clock_text(150.0) == "2:30" and ResultsView.clock_text(59.6) == "1:00", "clock text")
	var l := QuizSession.new()
	l.records = bank
	l.begin(5, 60, false, "Listen")
	for j in l.order.size():
		l.current_index = j
		l.start_question()
		l.submit(0, false)
	check(l.area_stats.is_empty() and l.answer_seconds.is_empty(), "listen (ungraded) answers stay out of the areas and the pace")
	var ne := QuizSession.new()
	ne.records = bank
	ne.bag_path = ""
	ne.begin(9999, 600, true, "Nebraska State Law", false, "", BankLoader.SECTION_NE_STATE_LAW)
	for j in ne.order.size():
		ne.current_index = j
		ne.start_question()
		ne.submit(0, true)
	check(ne.order.size() > 0 and ne.area_stats.is_empty() and ne.answer_seconds.size() == ne.order.size(), "Nebraska State Law answers count for pace but no subject area")
	check(ne.deck.stats.is_empty(), "Nebraska State Law answers stay out of the NEC deck")
	s.begin(10, 1800, true, "Again")
	check(s.area_stats.is_empty() and s.answer_seconds.is_empty(), "a new session starts with empty tallies")


func _bars() -> void:
	print("=== results bars by subject area ===")
	var rows := ChapterBars.rows_from_areas({"special_conditions": [1, 1], "general": [1, 4], "wiring_protection": [3, 4], "equipment": [1, 2]}, 75.0)
	var labels := []
	for r in rows:
		labels.append(r["label"])
	check(labels == ["General Electrical Knowledge", "Wiring and Protection", "Equipment for General Use", "Special Conditions"], "rows follow the exam outline: %s" % str(labels))
	check(not rows[1]["weak"] and rows[0]["weak"] and rows[2]["weak"] and not rows[3]["weak"], "rows under 75% are weak, 75% is not")
	check(rows[0]["weakest"] and not rows[2]["weakest"], "the lowest is the weakest")


func _scene(mobile: bool) -> void:
	var tag := "mobile" if mobile else "desktop"
	print("=== on screen (%s) ===" % tag)
	var main = load("res://scenes/main.tscn").instantiate()
	main.session.bag_path = ""
	main.session.rng.seed = 11
	root.add_child(main)
	main.audio = AudioSettings.new()
	main.audio_cfg_path = "user://test_study_feedback_audio.cfg"
	await process_frame
	var button: Button = main.study_button
	check(is_instance_valid(button) and main.menu_mode_buttons.has(button), "%s: the weakest-area drill is a menu mode button" % tag)
	check(button.text.contains("Wiring and Protection (new)") and button.text.contains("readiness 0%"), "%s: before any answers it offers the heaviest area: %s" % [tag, button.text.get_slice("\n", 1)])

	main._start_quiz(80, 240 * 60, true, "Full Journeyman Exam")
	await process_frame
	main.menu_overlay.visible = false
	for q in main.order.size():
		main.current_index = q
		main.session.start_question()
		var rec: Dictionary = main.session.current_record()
		var area := ExamBlueprint.area_of(bank[main.order[q]])
		var right: bool = area != "special_occupancies"
		main.session.submit(int(rec["correct_index"]) if right else (int(rec["correct_index"]) + 1) % 4, true)
	main.answered_count = main.order.size()
	main.score = main.session.score
	main._show_results()
	await process_frame
	var text: String = main.info_label.get_parsed_text()
	check(text.contains("STUDY FEEDBACK"), "%s: the report has a study feedback block" % tag)
	check(text.contains("Scored line: %d of 80 correct, 60 needed for 75%%: PASS." % main.session.score), "%s: the simulator states the scored line" % tag)
	check(text.contains("Below 75%: Special Occupancies 0/10 (0%). Weakest: Special Occupancies."), "%s: the weak area is named with its tally" % tag)
	check(text.contains("Pace: ") and text.contains("exam pace 3:00"), "%s: pace against the exam's 3:00" % tag)
	check(text.contains("Exam readiness: 88%") and text.contains("Next: drill Special Occupancies."), "%s: readiness 70/80 and the next area to drill" % tag)
	var labels := []
	for r in main.chapter_bars.rows:
		labels.append(r["label"])
	check(labels.size() == 7 and labels[0] == "General Electrical Knowledge" and labels[6] == "Special Conditions", "%s: the bars are the seven subject areas" % tag)
	check(main.answers_box.get_child_count() == 0 or main.answers_box.get_children().all(func(c): return c is AnswerCard), "%s: answers_box holds answer cards only" % tag)

	main._show_menu()
	await process_frame
	check(button.text.contains("Special Occupancies (0%)") and button.text.contains("readiness 88%"), "%s: back on the menu the button names the weak area: %s" % [tag, button.text.get_slice("\n", 1)])
	button.pressed.emit()
	await process_frame
	var only: bool = main.order.size() == 10
	for i in main.order:
		only = only and ExamBlueprint.area_of(bank[i]) == "special_occupancies"
	check(only, "%s: pressing it starts 10 questions from that area" % tag)
	check(str(main.session_name).begins_with("Area Drill · Special Occupancies"), "%s: the session is named after the area" % tag)
	main.queue_free()
	await process_frame
