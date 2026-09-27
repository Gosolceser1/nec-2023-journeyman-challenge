class_name QuizSession
extends RefCounted
## Quiz state and rules with no nodes: question order, score, streak, the
## missed list, per-chapter tallies and both clocks. Main renders it and
## exposes the same fields under the old names for the harness.

const ANSWER_LETTERS := ["A", "B", "C", "D"]
const SESSION_LENGTH := 10
const EXAM_SCORED_ITEMS := 80
const EXAM_MINUTES := 240
const PASS_PERCENT := 75
const SECONDS_PER_SCORED_ITEM: int = (EXAM_MINUTES * 60) / EXAM_SCORED_ITEMS
const SESSION_TIME_SECONDS: int = SECONDS_PER_SCORED_ITEM * SESSION_LENGTH

enum Verdict { REVIEWED, TIMED_OUT, CORRECT, WRONG }
## What the clock asks the screen to do after a tick.
enum Tick { NONE, TIME_OUT, STOP_CLOCK }

var records: Array = []
var order: Array[int] = []
var current_index := 0
var score := 0
var streak := 0
var answered_count := 0
var current_answered := false
var missed_questions: Array[Dictionary] = []
var chapter_stats: Dictionary = {}  # chapter:int -> [correct, total] for the results breakdown
var time_left := SESSION_TIME_SECONDS
var session_length := SESSION_LENGTH
var session_time_limit := SESSION_TIME_SECONDS
var timed_session := true
var session_name := "Practice Test"
var question_time_left := SECONDS_PER_SCORED_ITEM


## A fresh shuffled session of up to question_count records.
func begin(question_count: int, time_limit: int, timed: bool, name: String) -> void:
	order.clear()
	for i in records.size():
		order.append(i)
	order.shuffle()
	session_length = mini(question_count, records.size())
	if order.size() > session_length:
		order.resize(session_length)
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
	time_left = session_time_limit
	question_time_left = SECONDS_PER_SCORED_ITEM


func current_record() -> Dictionary:
	return records[order[current_index]]


## The current question goes up: unanswered, full item time.
func start_question() -> void:
	current_answered = false
	question_time_left = SECONDS_PER_SCORED_ITEM


## Grades the pick (-1 = time ran out). Returns {} if the question was already
## answered, else verdict, record, record_index, correct, correct_text and
## selected_text. Ungraded (listen) answers count as reviewed and nothing else.
func submit(selected: int, graded: bool) -> Dictionary:
	if current_answered:
		return {}
	current_answered = true
	var record_index: int = order[current_index]
	var record: Dictionary = records[record_index]
	answered_count += 1
	var correct := int(record.get("correct_index", -1))
	var answers: Array = record.get("answers", [])
	var correct_text: String = str(answers[correct]) if correct >= 0 and correct < answers.size() else ANSWER_LETTERS[correct]
	var selected_text: String = str(answers[selected]) if selected >= 0 and selected < answers.size() else "No answer"
	if graded:
		var chapter := ChapterBars.chapter_of(str(record.get("article", "")))
		var tally: Array = chapter_stats.get(chapter, [0, 0])
		chapter_stats[chapter] = [int(tally[0]) + (1 if selected == correct else 0), int(tally[1]) + 1]

	var verdict: Verdict
	if not graded:
		verdict = Verdict.REVIEWED
	elif selected == -1:
		streak = 0
		verdict = Verdict.TIMED_OUT
		missed_questions.append(_missed(record, record_index, "Time expired", correct, correct_text))
	elif selected == correct:
		score += 1
		streak += 1
		verdict = Verdict.CORRECT
	else:
		streak = 0
		verdict = Verdict.WRONG
		missed_questions.append(_missed(record, record_index, "%s — %s" % [ANSWER_LETTERS[selected], selected_text], correct, correct_text))
	return {
		"verdict": verdict,
		"record": record,
		"record_index": record_index,
		"correct": correct,
		"correct_text": correct_text,
		"selected_text": selected_text,
	}


func _missed(record: Dictionary, record_index: int, selected_label: String, correct: int, correct_text: String) -> Dictionary:
	return {
		"index": current_index + 1,
		"prompt": str(record.get("prompt", "")),
		"selected": selected_label,
		"correct": "%s — %s" % [ANSWER_LETTERS[correct], correct_text],
		"article": str(record.get("article", "General")),
		"article_title": str(record.get("article_title", "")),
		"tip_short": str(record.get("tip_short", record.get("gist", ""))),
		"record_index": record_index,
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
