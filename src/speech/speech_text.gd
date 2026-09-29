extends RefCounted
## Single source of truth for every word the voice speaks.
## Used by SpeechController at runtime and by tools/speech/dump_speech.gd for batch pre-generation.
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

static func find_answer_match(text: String, answer: String, prompt: String = "") -> Dictionary:
	return AudioExplanationGenerator.find_match_in(text, answer, prompt)

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
	var bare_choice: RegEx = null
	if _asks_for_reference(str(record.get("prompt", ""))) and Rules.is_bare_reference(choice):
		var escaped := choice.strip_edges().replace(".", "\\.").replace("(", "\\(").replace(")", "\\)")
		bare_choice = Rules._re("(?<![\\d.])" + escaped + "(?![\\d(])")
	# Indexed from the shared lesson_lines so spoken index N == displayed line N.
	for line in AudioExplanationGenerator.lesson_lines(record, choice):
		var spoken := speakable(line)
		# "Answer: 220.56." ends a sentence, so the reference rule leaves it a decimal.
		if bare_choice != null:
			spoken = bare_choice.sub(spoken, Rules.bare_reference(choice), true)
		spoken = _terminated(spoken)
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
	var asks_for_reference := _asks_for_reference(prompt)
	for i in answers.size():
		var raw := str(answers[i])
		var spoken := Rules.bare_reference(raw) if asks_for_reference and Rules.is_bare_reference(raw) else speakable(raw)
		# The letter is its own clip so the recorded choices can be played in
		# any shuffled order (display_order). "Option A", not "A": Edge reads a
		# bare "A" as the article "uh".
		segments.append(_segment(letter_line(i), i, false))
		var text := _terminated(spoken)
		if text != "":
			segments.append(_segment(text, i, false))
	return segments

## A stem asking for a Section, Article or Table reads bare-number choices as references.
static func _asks_for_reference(prompt: String) -> bool:
	return Rules._re("(?i)\\b(section|article|table)\\b").search(prompt) != null

## The spoken letter of a choice slot.
static func letter_line(slot: int) -> String:
	return "Option %s." % (ANSWER_LETTERS[slot] if slot >= 0 and slot < ANSWER_LETTERS.size() else str(slot + 1))

## Rearranges a speech plan or play queue from bank order (stem, "Option A.",
## choice 0, "Option B.", choice 1, ..., answer part) into the order the
## choices are shown: slot d gets the letter line of d and the text of choice
## perm[d]. Choice fields become display slots. When the answer part is
## there, it opens with the letter line of the correct slot, marked teach
## (it gives the answer away) and aux (it is not a lesson line).
## Entries need "text", "choice" and "teach".
static func display_order(entries: Array, perm: Array) -> Array:
	var head: Array = []
	var letters := {}
	var texts := {}
	var teach: Array = []
	var count := 0
	for e in entries:
		var c := int(e.get("choice", -1))
		if bool(e.get("teach", false)):
			teach.append(e)
		elif c < 0:
			head.append(e)
		elif str(e.get("text", "")) == letter_line(c):
			letters[c] = e
		else:
			texts[c] = e
		if not bool(e.get("teach", false)):
			count = maxi(count, c + 1)
	var slots: Array = perm
	if count > 0 and slots.size() != count:
		slots = range(count)
	var out := head.duplicate()
	for d in slots.size():
		if letters.has(d):
			out.append(letters[d])
		if texts.has(slots[d]):
			out.append(_in_slot(texts[slots[d]], d))
	if not teach.is_empty():
		var correct_slot := _slot_of(slots, int(teach[0].get("choice", -1)))
		if letters.has(correct_slot):
			var cue: Dictionary = letters[correct_slot].duplicate()
			cue["teach"] = true
			cue["aux"] = true
			out.append(cue)
		for e in teach:
			out.append(_in_slot(e, _slot_of(slots, int(e.get("choice", -1)))))
	return out

static func _slot_of(slots: Array, choice: int) -> int:
	return slots.find(choice) if not slots.is_empty() else choice

static func _in_slot(entry: Dictionary, slot: int) -> Dictionary:
	var moved := entry.duplicate()
	moved["choice"] = slot
	return moved

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
