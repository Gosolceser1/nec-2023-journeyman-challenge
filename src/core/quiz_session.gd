class_name QuizSession
extends RefCounted
## Quiz state and rules with no nodes: question order, choice order, score,
## streak, the missed list, per-chapter tallies and both clocks. Main renders
## it and exposes the same fields under the old names for the harness.
##
## Questions come from the whole pool through a QuestionDeck (blueprint
## drills from per-area decks, review queue, blueprint simulator). Choices are shuffled per
## question per session (ChoiceOrder). Everything shown uses display slots;
## grading compares original indices, so the bank is never touched.

const ANSWER_LETTERS := ["A", "B", "C", "D"]
## Where main keeps the deck and study stats between launches. Question ids
## only, no answers.
const BAG_PATH := "user://question_bag.cfg"
const SESSION_LENGTH := 10
const EXAM_SCORED_ITEMS := 80
const EXAM_MINUTES := 240
const PASS_PERCENT := 75
const SECONDS_PER_SCORED_ITEM: int = (EXAM_MINUTES * 60) / EXAM_SCORED_ITEMS
const SESSION_TIME_SECONDS: int = SECONDS_PER_SCORED_ITEM * SESSION_LENGTH
## Twice the exam's pace: answers slower than this are flagged on the report.
const SLOW_SECONDS := SECONDS_PER_SCORED_ITEM * 2

enum Verdict { REVIEWED, TIMED_OUT, CORRECT, WRONG }
## What the clock asks the screen to do after a tick.
enum Tick { NONE, TIME_OUT, STOP_CLOCK }

var records: Array = []
## record index -> display slot -> original choice index, for this session.
var choice_orders: Dictionary = {}
## Record indices in play order. Assigning it directly (tools do) shows every
## choice in bank order.
var order: Array[int] = []:
	set(v):
		order = v
		choice_orders.clear()
## Randomized per session object; tests and the harness set rng.seed for a
## repeatable run.
var rng := RandomNumberGenerator.new()
var deck := QuestionDeck.new()
## "" keeps the deck and stats in memory only.
var bag_path: String:
	get: return deck.path
	set(v): deck.path = v
var current_index := 0
var score := 0
var streak := 0
var answered_count := 0
var current_answered := false
var missed_questions: Array[Dictionary] = []
var chapter_stats: Dictionary = {}  # chapter:int -> [correct, total] for the results breakdown
var area_stats: Dictionary = {}  # exam subject area -> [correct, total], graded answers
## [item number, seconds from showing to answering] per answered question.
var answer_seconds: Array = []
## Milliseconds now; tests swap it for a fake clock.
var clock := Callable(Time, "get_ticks_msec")
var _shown_msec := 0
var time_left := SESSION_TIME_SECONDS
var session_length := SESSION_LENGTH
var session_time_limit := SESSION_TIME_SECONDS
var timed_session := true
var session_name := "Practice Test"
var question_time_left := SECONDS_PER_SCORED_ITEM


func _init() -> void:
	rng.randomize()


## A fresh session of up to question_count records, each with a new choice
## order: the next drill from the decks (from one subject area if area is
## set), or with simulation a blueprint exam.
func begin(question_count: int, time_limit: int, timed: bool, name: String, simulation := false, area := "") -> void:
	if simulation:
		order = deck.draw_exam(records, question_count, rng)
	else:
		order = deck.draw_drill(records, question_count, rng, area)
	for i in order:
		choice_orders[i] = ChoiceOrder.shuffled(records[i], rng)
	session_length = order.size()
	session_time_limit = time_limit
	timed_session = timed
	session_name = name
	current_index = 0
	score = 0
	streak = 0
	answered_count = 0
	current_answered = false
	missed_questions.clear()
	chapter_stats.clear()
	area_stats.clear()
	answer_seconds.clear()
	time_left = session_time_limit
	question_time_left = SECONDS_PER_SCORED_ITEM


## {"mean": seconds per answered question, "slow": item numbers over
## SLOW_SECONDS}; mean is 0 with no answers.
static func pace(seconds: Array) -> Dictionary:
	var sum := 0.0
	var slow: Array[int] = []
	for e in seconds:
		sum += float(e[1])
		if float(e[1]) > SLOW_SECONDS:
			slow.append(int(e[0]))
	return {"mean": sum / seconds.size() if not seconds.is_empty() else 0.0, "slow": slow}


## Clears the deck, the review queue and the per-question stats.
func reset_progress() -> void:
	deck.reset()


## Display slot -> original choice index for a record; bank order when the
## session did not shuffle it.
func choice_order(record_index: int) -> Array[int]:
	if choice_orders.has(record_index):
		return choice_orders[record_index]
	return ChoiceOrder.identity(records[record_index])


## The record as the learner sees it: choices in display order, correct_index
## on the display slot.
func display_record(record_index: int) -> Dictionary:
	return ChoiceOrder.apply(records[record_index], choice_order(record_index))


func current_record() -> Dictionary:
	return display_record(order[current_index])


## The current question goes up: unanswered, full item time.
func start_question() -> void:
	current_answered = false
	question_time_left = SECONDS_PER_SCORED_ITEM
	_shown_msec = int(clock.call())


## Grades the pick, a display slot (-1 = time ran out), against the bank's
## original correct_index. Returns {} if the question was already answered,
## else verdict, record (display copy), record_index, correct (display slot),
## correct_text, selected_text, and the original indices correct_original and
## selected_original. Ungraded (listen) answers count as reviewed and nothing else.
func submit(selected: int, graded: bool) -> Dictionary:
	if current_answered:
		return {}
	current_answered = true
	var record_index: int = order[current_index]
	var record: Dictionary = records[record_index]
	var perm := choice_order(record_index)
	answered_count += 1
	var correct_original := int(record.get("correct_index", -1))
	var selected_original: int = perm[selected] if selected >= 0 and selected < perm.size() else -1
	var correct := perm.find(correct_original)
	var answers: Array = record.get("answers", [])
	var correct_text: String = str(answers[correct_original]) if correct >= 0 else ANSWER_LETTERS[correct]
	var selected_text: String = str(answers[selected_original]) if selected_original >= 0 else "No answer"
	var right := selected_original >= 0 and selected_original == correct_original
	if graded:
		var chapter := ChapterBars.chapter_of(str(record.get("article", "")))
		var tally: Array = chapter_stats.get(chapter, [0, 0])
		chapter_stats[chapter] = [int(tally[0]) + (1 if right else 0), int(tally[1]) + 1]
		var area := ExamBlueprint.area_of(record)
		var area_tally: Array = area_stats.get(area, [0, 0])
		area_stats[area] = [int(area_tally[0]) + (1 if right else 0), int(area_tally[1]) + 1]
		answer_seconds.append([current_index + 1, maxf(0.0, (int(clock.call()) - _shown_msec) / 1000.0)])
		deck.record_result(records, record_index, right)

	var verdict: Verdict
	var shown := ChoiceOrder.apply(record, perm)
	if not graded:
		verdict = Verdict.REVIEWED
	elif selected == -1:
		streak = 0
		verdict = Verdict.TIMED_OUT
		missed_questions.append(_missed(shown, record_index, "Time expired", correct, correct_text, -1, correct_original))
	elif right:
		score += 1
		streak += 1
		verdict = Verdict.CORRECT
	else:
		streak = 0
		verdict = Verdict.WRONG
		missed_questions.append(_missed(shown, record_index, "%s — %s" % [ANSWER_LETTERS[selected], selected_text], correct, correct_text, selected_original, correct_original))
	return {
		"verdict": verdict,
		"record": shown,
		"record_index": record_index,
		"correct": correct,
		"correct_text": correct_text,
		"selected_text": selected_text,
		"correct_original": correct_original,
		"selected_original": selected_original,
	}


## Labels use the letters the learner saw; selected_index and correct_index
## are original choice indices.
func _missed(shown: Dictionary, record_index: int, selected_label: String, correct: int, correct_text: String, selected_original: int, correct_original: int) -> Dictionary:
	return {
		"index": current_index + 1,
		"prompt": str(shown.get("prompt", "")),
		"selected": selected_label,
		"correct": "%s — %s" % [ANSWER_LETTERS[correct], correct_text],
		"article": str(shown.get("article", "General")),
		"article_title": str(shown.get("article_title", "")),
		"tip_short": str(shown.get("tip_short", shown.get("gist", ""))),
		"record_index": record_index,
		"selected_index": selected_original,
		"correct_index": correct_original,
	}


## One second of a timed session. The session clock always runs; the item
## clock only while the question is unanswered and nothing is being read
## aloud, so a long readout never eats the learner's answer time.
## Returns {"item_ticked": bool, "action": Tick}.
func tick(speech_idle: bool) -> Dictionary:
	if not timed_session:
		return {"item_ticked": false, "action": Tick.NONE}
	time_left -= 1
	var item_ticked := false
	if not current_answered and speech_idle:
		question_time_left -= 1
		item_ticked = true
	var action := Tick.NONE
	if not current_answered and question_time_left <= 0 and speech_idle:
		action = Tick.TIME_OUT
	elif time_left <= 0:
		action = Tick.STOP_CLOCK if current_answered else Tick.TIME_OUT
	return {"item_ticked": item_ticked, "action": action}


## Moves to the next question; false when the session is over.
func advance() -> bool:
	if current_index < order.size() - 1:
		current_index += 1
		return true
	return false
