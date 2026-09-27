extends SceneTree
## QuizSession without a scene: order, grading, the missed list, chapter
## tallies and both clocks.

var failures: Array[String] = []
var checks := 0

func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func _rec(article: String, correct: int) -> Dictionary:
	return {"prompt": "Q " + article, "answers": ["a", "b", "c", "d"], "correct_index": correct, "article": article,
		"article_title": "T", "tip_short": "tip"}


func _session(records: Array) -> QuizSession:
	var s := QuizSession.new()
	s.records = records
	return s


func _init() -> void:
	var recs := [_rec("NEC 210.8", 0), _rec("NEC 310.16", 1), _rec("NEC 250.66", 2), _rec("NEC 430.52", 3), _rec("General math", 0)]

	print("=== begin ===")
	var s := _session(recs)
	s.score = 7
	s.missed_questions.append({})
	s.chapter_stats[2] = [1, 1]
	s.begin(3, 540, true, "Practice")
	check(s.order.size() == 3 and s.session_length == 3, "order trimmed to the requested count")
	var uniq := {}
	for i in s.order:
		uniq[i] = true
		check(i >= 0 and i < recs.size(), "order index %d in range" % i)
	check(uniq.size() == 3, "no question repeats")
	check(s.score == 0 and s.streak == 0 and s.answered_count == 0 and s.current_index == 0, "counters reset")
	check(s.missed_questions.is_empty() and s.chapter_stats.is_empty(), "missed list and tallies reset")
	check(s.time_left == 540 and s.session_time_limit == 540 and s.timed_session and s.session_name == "Practice", "limit, timing and name")
	check(s.question_time_left == QuizSession.SECONDS_PER_SCORED_ITEM, "full item time")
	s.begin(50, 60, false, "Big")
	check(s.order.size() == recs.size() and s.session_length == recs.size(), "count capped at the bank size")
	check(QuizSession.SECONDS_PER_SCORED_ITEM == 180, "exam pace: 240 min / 80 items = 180 s")

	print("=== submit ===")
	s = _session(recs)
	s.begin(5, 900, true, "P")
	s.order = [0, 1, 2, 3, 4] as Array[int]
	var r := s.submit(0, true)
	check(r["verdict"] == QuizSession.Verdict.CORRECT and s.score == 1 and s.streak == 1 and s.answered_count == 1, "correct pick")
	check(r["correct_text"] == "a" and r["record_index"] == 0, "verdict carries the answer")
	check(s.chapter_stats.get(2) == [1, 1], "chapter 2 tally after a right answer")
	check(s.submit(1, true).is_empty() and s.answered_count == 1 and s.score == 1, "second submit on the same question is ignored")
	check(s.advance() and s.current_index == 1, "advance")
	s.start_question()
	r = s.submit(3, true)
	check(r["verdict"] == QuizSession.Verdict.WRONG and s.streak == 0 and s.score == 1, "wrong pick resets the streak")
	check(s.missed_questions.size() == 1, "wrong pick is listed")
	var miss: Dictionary = s.missed_questions[0]
	check(miss["index"] == 2 and miss["selected"] == "D — d" and miss["correct"] == "B — b", "missed entry: position, pick, answer")
	check(miss["record_index"] == 1 and miss["article"] == "NEC 310.16" and miss["tip_short"] == "tip", "missed entry: record and study key")
	check(s.chapter_stats.get(3) == [0, 1], "chapter 3 tally after a wrong answer")
	s.advance()
	s.start_question()
	r = s.submit(-1, true)
	check(r["verdict"] == QuizSession.Verdict.TIMED_OUT and s.missed_questions[-1]["selected"] == "Time expired", "time out is a miss")
	check(r["selected_text"] == "No answer", "time out has no pick")
	s.advance()
	s.start_question()
	var before := s.streak
	r = s.submit(0, false)
	check(r["verdict"] == QuizSession.Verdict.REVIEWED and s.answered_count == 4, "listen answer is reviewed and counted")
	check(s.score == 1 and s.streak == before and s.missed_questions.size() == 2 and not s.chapter_stats.has(4), "listen answer is not graded")
	s.advance()
	check(not s.advance() and s.current_index == 4, "advance stops at the last question")

	print("=== whole bank, random picks ===")
	var bank := BankLoader.load_records()
	s = _session(bank)
	s.begin(bank.size(), 99999, true, "All")
	var rng := RandomNumberGenerator.new()
	rng.seed = 2023
	var more := true
	while more:
		s.start_question()
		s.submit(rng.randi_range(-1, 3), true)
		more = s.advance()
	check(s.answered_count == bank.size(), "every question answered (%d)" % s.answered_count)
	check(s.score + s.missed_questions.size() == s.answered_count, "score + missed == answered: %d + %d vs %d" % [s.score, s.missed_questions.size(), s.answered_count])
	var tallied := 0
	for ch in s.chapter_stats:
		tallied += int(s.chapter_stats[ch][1])
	check(tallied == s.answered_count, "chapter tallies cover every graded answer")

	print("=== clocks ===")
	s = _session(recs)
	s.begin(3, 600, false, "Untimed")
	var t := s.tick(true)
	check(t["action"] == QuizSession.Tick.NONE and not t["item_ticked"] and s.time_left == 600, "untimed: clocks stand still")
	s.begin(3, 600, true, "Timed")
	t = s.tick(true)
	check(s.time_left == 599 and s.question_time_left == 179 and t["item_ticked"], "idle second: both clocks run")
	t = s.tick(false)
	check(s.time_left == 598 and s.question_time_left == 179 and not t["item_ticked"], "clock does not tick while speech busy")
	s.question_time_left = 0
	t = s.tick(false)
	check(t["action"] == QuizSession.Tick.NONE, "an item cannot time out while it is being read")
	t = s.tick(true)
	check(t["action"] == QuizSession.Tick.TIME_OUT, "item time out once reading stops")
	s.submit(-1, true)
	s.time_left = 1
	t = s.tick(true)
	check(t["action"] == QuizSession.Tick.STOP_CLOCK and s.question_time_left == -1, "answered and out of session time: stop, item clock frozen")
	s.advance()
	s.start_question()
	s.time_left = 1
	t = s.tick(false)
	check(t["action"] == QuizSession.Tick.TIME_OUT, "session time out applies even while reading")

	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
