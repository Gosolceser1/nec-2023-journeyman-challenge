extends RefCounted
## Single source of truth for every word the voice speaks.
## Used by main.gd at runtime and by tools/dump_speech.gd for batch pre-generation.
## Reading order and pronunciation rules: docs/VOICE_READING_RULES.md.

const Rules = preload("res://src/speech/speech_rules.gd")

const ANSWER_LETTERS := ["A", "B", "C", "D"]

## Stamped on every segment and copied into clip manifests, so a clip rendered
## under older rules never matches a current plan.
const RULES_VERSION := Rules.VERSION

static func format_answer_number(value: float) -> String:
	return UnitMatcher.format_answer_number(value)

static func answer_match_candidates(answer: String) -> Array[String]:
	return UnitMatcher.answer_match_candidates(answer)

static func find_answer_match(text: String, answer: String) -> Dictionary:
	return AudioExplanationGenerator.find_match_in(text, answer)

static func _normalize_spoken(text: String) -> String:
	var lower := text.to_lower().strip_edges()
	var cleaned := ""
	for i in lower.length():
		var ch := lower.substr(i, 1)
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") or ch == " ":
			cleaned += ch
		else:
			cleaned += " "
	while cleaned.contains("  "):
		cleaned = cleaned.replace("  ", " ")
	return cleaned.strip_edges()

static func speech_plan(record: Dictionary) -> Array:
	# Full plan = question stem + choices (pre-answer) followed by teach lines.
	# Teach lines are NOT deduped against the Q/A here on purpose: the answer words
	# are expected to repeat, and the two groups never play back-to-back (the player
	# stops before the first teach line until the learner answers, then jumps to teach).
	var segments := spoken_segments(record)
	for teach_seg in teach_segments(record):
		segments.append(teach_seg)
	return segments

static func teach_segments(record: Dictionary) -> Array:
	# LEARN PART ONLY: short answer callout + distinct code rule (+ math when new).
	# Split from speech_plan so answering can synthesize ONLY these clips instead of
	# re-generating the question stem + 4 choices (which burned Edge quota for audio
	# the learner had already heard and then skipped).
	var out: Array = []
	var answers: Array = record.get("answers", [])
	var correct := int(record.get("correct_index", -1))
	var choice := str(answers[correct]) if correct >= 0 and correct < answers.size() else ""
	var seen: Array[String] = []
	# Indexed from the shared lesson_lines so spoken index N == displayed line N.
	for line in AudioExplanationGenerator.lesson_lines(record, choice):
		var spoken := speakable(line)
		if spoken == "":
			continue
		var norm := _normalize_spoken(spoken)
		var dupe := false
		for prev in seen:
			if norm == prev or norm.contains(prev) or prev.contains(norm):
				dupe = true
				break
		if dupe:
			continue
		seen.append(norm)
		out.append(_segment(spoken, correct, true))
	return out

static func spoken_segments(record: Dictionary) -> Array:
	var segments: Array = []
	var prompt := str(record.get("prompt", ""))
	var stem := speakable(Rules.restore_lost_blank(prompt))
	segments.append(_segment(_terminated(stem), -1, false))
	var answers: Array = record.get("answers", [])
	var asks_for_reference := Rules._re("(?i)\\b(section|article|table)\\b").search(prompt) != null
	for i in answers.size():
		var letter: String = ANSWER_LETTERS[i] if i < ANSWER_LETTERS.size() else str(i + 1)
		var raw := str(answers[i])
		var spoken := Rules.bare_reference(raw) if asks_for_reference and Rules.is_bare_reference(raw) else speakable(raw)
		# "Option A," not "A,": Edge reads a leading "A," as the article "uh" and
		# runs it into the choice text with no pause. B, C and D were fine.
		segments.append(_segment(_terminated("Option %s, %s" % [letter, spoken]), i, false))
	return segments

static func _segment(text: String, choice: int, teach: bool) -> Dictionary:
	return {"text": text, "choice": choice, "teach": teach, "rules": RULES_VERSION}

## Ends a spoken line with exactly one terminator. A choice that already ended
## in "." used to be spoken with "..", and a stem ending in ":" got none.
static func _terminated(text: String) -> String:
	var body := text.strip_edges()
	while body != "" and body.substr(body.length() - 1) in [":", ",", ";"]:
		body = body.substr(0, body.length() - 1).strip_edges()
	if body == "":
		return body
	var last := body.substr(body.length() - 1)
	if last == "." or last == "?" or last == "!":
		return body
	return body + "."

static func prompt_intent(prompt: String) -> String:
	return AudioExplanationGenerator.prompt_intent(prompt)

static func plain_words(text: String) -> String:
	return AudioExplanationGenerator.plain_words(text)

static func lesson_point(prompt: String, body: String, worked: String, answer: String) -> String:
	return AudioExplanationGenerator.lesson_point(prompt, body, worked, answer)

static func prompt_with_answer(prompt: String, answer: String) -> String:
	return AudioExplanationGenerator.prompt_with_answer(prompt, answer)

static func answer_sentence(body: String, answer: String) -> String:
	return AudioExplanationGenerator.answer_sentence(body, answer)

static func speakable(text: String) -> String:
	return Rules.normalize(text)

static func spoken_fraction(top: String, bottom: String) -> String:
	return Rules.spoken_fraction(top, bottom)
