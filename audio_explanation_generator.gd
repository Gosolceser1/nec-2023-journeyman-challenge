class_name AudioExplanationGenerator
extends RefCounted
## Generates structured explanation scripts (intent, code breakdown, math, answer callout)
## and handles plain-language terminology transformations.

const ANSWER_LETTERS := ["A", "B", "C", "D"]

static func prompt_intent(prompt: String) -> String:
	var clean := prompt.strip_edges()
	if clean.contains("___"):
		return clean.replace("___", "[value]")
	if clean.contains("__"):
		return clean.replace("__", "[value]")
	return clean

static func generate_explanation(record: Dictionary, answer: String = "") -> Dictionary:
	var prompt := str(record.get("prompt", "")).strip_edges()
	var source := str(record.get("reference_text", "")).strip_edges()
	var formula := str(record.get("formula", "")).strip_edges()
	var worked := str(record.get("worked", "")).strip_edges()
	var cite := str(record.get("article", "")).strip_edges()
	var answers: Array = record.get("answers", [])
	var correct := int(record.get("correct_index", -1))
	var correct_letter: String = ANSWER_LETTERS[correct] if correct >= 0 and correct < ANSWER_LETTERS.size() else ""
	var choice_text: String = answer if answer != "" else (str(answers[correct]) if correct >= 0 and correct < answers.size() else "")

	var cite_header := ""
	var body := source
	var split_at := source.find("\n")
	if split_at >= 0:
		cite_header = source.substr(0, split_at).strip_edges()
		body = source.substr(split_at + 1).strip_edges()
	if cite == "" and cite_header != "":
		cite = cite_header

	var tested := lesson_point(prompt, body, worked, choice_text)
	var code_breakdown := ""
	if cite != "":
		code_breakdown = "%s: %s" % [cite, plain_words(tested)]
	else:
		code_breakdown = plain_words(tested)

	var math_explanation := ""
	var math_raw := ""
	if worked != "":
		math_raw = plain_words(worked)
	elif formula != "":
		math_raw = plain_words(formula)
	if math_raw != "" and not _is_duplicate_text(math_raw, code_breakdown):
		if worked != "":
			math_explanation = "Calculation: " + math_raw
		else:
			math_explanation = "Formula: " + math_raw

	var answer_callout := ""
	if correct_letter != "" and choice_text != "":
		answer_callout = "Answer %s, %s." % [correct_letter, choice_text]
	elif choice_text != "":
		answer_callout = "Answer: " + choice_text + "."

	return {
		"question_id": str(record.get("id", "")),
		"raw_question_text": prompt,
		"tts_script": {
			"intent": "",
			"code_breakdown": code_breakdown,
			"math_explanation": math_explanation,
			"answer_callout": answer_callout
		}
	}

static func _normalize_for_compare(text: String) -> String:
	var lower := text.to_lower().strip_edges()
	# Strip citation prefix like "408.18(C): " for comparison purposes.
	var colon := lower.find(": ")
	if colon >= 0 and colon < 24:
		lower = lower.substr(colon + 2)
	var cleaned := ""
	for i in lower.length():
		var ch := lower.substr(i, 1)
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") or ch == " ":
			cleaned += ch
		elif ch == "." or ch == "," or ch == ";" or ch == ":":
			cleaned += " "
	while cleaned.contains("  "):
		cleaned = cleaned.replace("  ", " ")
	return cleaned.strip_edges()

static func _is_duplicate_text(a: String, b: String) -> bool:
	var na := _normalize_for_compare(a)
	var nb := _normalize_for_compare(b)
	if na == "" or nb == "":
		return false
	if na == nb:
		return true
	if na.contains(nb) or nb.contains(na):
		return true
	# Token-overlap check: if the shorter line shares >= 85% of its meaningful words
	# (stopwords excluded) with the longer, drop it.
	var wa := na.split(" ", false)
	var wb := nb.split(" ", false)
	if wa.is_empty() or wb.is_empty():
		return false
	var stopwords := ["the", "and", "for", "with", "that", "this", "from", "answer", "correct", "shall", "within", "have", "has", "are", "was", "were", "will", "must", "than", "then"]
	var short_words: PackedStringArray = wa if wa.size() <= wb.size() else wb
	var long_text := nb if wa.size() <= wb.size() else na
	var hits := 0
	var meaningful := 0
	for w in short_words:
		if w.length() <= 2 or w in stopwords:
			continue
		meaningful += 1
		if long_text.contains(w):
			hits += 1
	if meaningful >= 3 and float(hits) / float(maxi(meaningful, 1)) >= 0.85:
		return true
	return false

static func _rule_adds_value(rule: String, callout: String) -> bool:
	# The code rule is EXPECTED to contain the answer words — that is not a duplicate.
	# Only treat it as a duplicate when the rule says nothing beyond the answer itself.
	var nr := _normalize_for_compare(rule)
	var nc := _normalize_for_compare(callout)
	for filler in ["answer", "correct"]:
		nc = nc.replace(filler, " ").strip_edges()
	while nc.contains("  "):
		nc = nc.replace("  ", " ")
	var stripped := nr.replace(nc, " ").strip_edges()
	while stripped.contains("  "):
		stripped = stripped.replace("  ", " ")
	if stripped.length() < 30:
		return false
	return true

static func lesson_lines(record: Dictionary, answer: String = "") -> PackedStringArray:
	# SINGLE SOURCE for the learn content: speech (teach_segments) and the info panel
	# (WHAT THE CODE SAYS highlight) both index into THIS list, so spoken line N is
	# always displayed line N. Never build a parallel list elsewhere.
	var expl := generate_explanation(record, answer)
	var script: Dictionary = expl.get("tts_script", {})
	var lines := PackedStringArray()
	# TEACH ORDER: answer callout FIRST (short confirmation), then the code rule,
	# then the calculation only when it adds new information.
	# Old order (rule, math, answer-last) plus prompt restatement made the learn
	# segment feel like the same sentence twice.
	var callout := str(script.get("answer_callout", ""))
	var rule := str(script.get("code_breakdown", ""))
	var math := str(script.get("math_explanation", ""))
	if callout != "":
		lines.append(callout)
	if rule != "" and (lines.is_empty() or _rule_adds_value(rule, callout)):
		lines.append(rule)
	if math != "":
		var dupe := false
		for existing in lines:
			if _is_duplicate_text(math, existing):
				dupe = true
				break
		if not dupe:
			lines.append(math)
	var intent := str(script.get("intent", ""))
	if intent != "":
		var dupe_intent := false
		for existing in lines:
			if _is_duplicate_text(intent, existing):
				dupe_intent = true
				break
		if not dupe_intent:
			lines.append(intent)
	return lines

static func format_lesson_text(record: Dictionary, answer: String = "") -> String:
	return "\n".join(lesson_lines(record, answer))

static func lesson_point(prompt: String, body: String, worked: String, answer: String) -> String:
	# TEACH RULE: the lesson must teach the CODE REASON, not restate the question.
	# Old behavior returned prompt_with_answer FIRST, which for fill-in-blank
	# questions is nearly word-identical to the code sentence -> the "2 duplicates"
	# feeling (hear Q+answer, then hear same sentence again, then hear answer callout).
	# New order: code sentence containing the answer -> worked/formula -> prompt fill LAST resort.
	if body != "":
		var sentence := answer_sentence(body, answer)
		if sentence != "":
			return sentence
	if worked != "":
		return worked
	var filled := prompt_with_answer(prompt, answer)
	if filled != "":
		return filled
	return answer

static func prompt_with_answer(prompt: String, answer: String) -> String:
	if prompt.contains("___"):
		return prompt.replace("___", answer)
	if prompt.contains("__"):
		return prompt.replace("__", answer)
	var trimmed := prompt.strip_edges()
	if trimmed.ends_with("..."):
		return trimmed.trim_suffix("...").strip_edges() + " " + answer + "."
	return ""

static func answer_sentence(body: String, answer: String) -> String:
	var parts := body.split(". ")
	for part in parts:
		var sentence := str(part).strip_edges()
		if sentence != "" and not UnitMatcher.answer_match_candidates(answer).is_empty():
			if not find_match_in(sentence, answer).is_empty():
				if not sentence.ends_with("."):
					sentence += "."
				return sentence
	if body.length() > 420:
		var truncated := body.substr(0, 420).strip_edges()
		var last_period := truncated.rfind(".")
		if last_period > 200:
			return truncated.substr(0, last_period + 1)
		return truncated + "."
	return body

static func find_match_in(text: String, answer: String) -> Dictionary:
	for candidate in UnitMatcher.answer_match_candidates(answer):
		if candidate == "":
			continue
		var start := 0
		while start < text.length():
			var index := text.to_lower().find(candidate.to_lower(), start)
			if index < 0:
				break
			var before := text.substr(index - 1, 1) if index > 0 else ""
			var after_index := index + candidate.length()
			var after := text.substr(after_index, 1) if after_index < text.length() else ""
			var has_left_boundary := candidate.length() == 0 or not _is_word_char(candidate.substr(0, 1)) or not _is_word_char(before)
			var has_right_boundary := candidate.length() == 0 or not _is_word_char(candidate.substr(candidate.length() - 1, 1)) or not _is_word_char(after)
			if has_left_boundary and has_right_boundary:
				return {"start": index, "length": candidate.length()}
			start = index + 1
	return {}

static func _is_word_char(c: String) -> bool:
	if c.is_empty():
		return false
	return c.to_lower() != c.to_upper() or "0123456789".contains(c)

static func redact_answer_spans(text: String, answer: String) -> String:
	# Pre-answer redaction: blank every occurrence of the answer (plus its known
	# variants) so lookup aids (table titles, notes, formulas, nav paths) can't print
	# the answer above the question. Boundary-aware: "25" won't eat the "25" in "125-volt".
	var out := text
	var candidates: Array = []
	candidates.append(answer)
	for c in UnitMatcher.answer_match_candidates(answer):
		candidates.append(str(c))
	candidates.sort_custom(func(a, b): return str(a).length() > str(b).length())
	var seen := {}
	for cand_v in candidates:
		var needle := str(cand_v).strip_edges()
		if needle.is_empty() or seen.has(needle.to_lower()):
			continue
		# Single characters are only safe to blank when they are digits: a bare
		# letter would shred unrelated text, but a digit is boundary-anchored and
		# is exactly the form a word answer takes ("two" -> "2"). Dropping these
		# left the digit candidates of word/number answers unredacted, so a nav
		# path could print the chapter number that names the answer.
		if needle.length() < 2 and not needle.is_valid_int():
			continue
		seen[needle.to_lower()] = true
		var start := 0
		while start <= out.length() - needle.length():
			var idx := out.to_lower().find(needle.to_lower(), start)
			if idx < 0:
				break
			var before := out.substr(idx - 1, 1) if idx > 0 else ""
			var after_index := idx + needle.length()
			var after := out.substr(after_index, 1) if after_index < out.length() else ""
			var left_ok := not _is_word_char(needle.substr(0, 1)) or not _is_word_char(before)
			var right_ok := not _is_word_char(needle.substr(needle.length() - 1, 1)) or not _is_word_char(after)
			if left_ok and right_ok:
				out = out.substr(0, idx) + "___" + out.substr(after_index)
				start = idx + 3
			else:
				start = idx + 1
	while out.contains("___ ___"):
		out = out.replace("___ ___", "___")
	return out

static func plain_words(text: String) -> String:
	var swaps := [
		["receptacle outlets", "outlets"],
		["receptacle outlet", "outlet"],
		["receptacle", "outlet"],
		["equipment grounding conductor", "ground wire"],
		["grounding-type attachment plug", "three-prong grounded plug"],
		["grounding-type plug", "three-prong plug"],
		["grounding conductor", "ground wire"],
		["grounded conductor", "neutral wire"],
		["ungrounded conductors", "hot wires"],
		["overcurrent protection devices", "breakers or fuses"],
		["supplementary overcurrent protection", "extra equipment protection"],
		["overcurrent devices", "breakers or fuses"],
		["overcurrent protection", "breaker or fuse protection"],
		["overcurrent protective device", "breaker or fuse"],
		["overcurrent device", "breaker or fuse"],
		["service equipment", "main service panel"],
		["utilization equipment", "electrical equipment"],
		["premises wiring", "building wiring"],
		["feeder tap", "tap off the feeder"],
		["disconnecting means", "disconnect switch"],
		["luminaires", "light fixtures"],
		["luminaire", "light fixture"],
		["fixed electric space-heating equipment", "fixed electric heaters"],
		["waste disposer", "garbage disposal"],
		["branch-circuit", "circuit"],
		["branch circuit", "circuit"],
		["demand factor", "share of the load you count"],
		["full-load current", "running amps"],
		["full-load currents", "running amps"],
		["ampacity", "current rating"],
		["shall not be used as a substitute for", "must never replace"],
		["shall not", "must not"],
		["shall be", "is"],
		["shall have", "must have"],
		["shall", "must"],
		["in accordance with", "under"],
		["provided with", "has"],
		["utilized", "used"],
		["ensure", "make sure"],
		["located", "placed"],
		["is accessible", "can be reached"],
		["dwelling units", "houses"],
		["dwelling unit", "house"],
		["walking surface", "floor"],
		["accessible", "reachable"],
		["not less than", "at least"],
		["not more than", "at most"],
		["not exceeding", "up to"],
		["as specified in", "in"],
		["An current", "A current"],
		["an current", "a current"],
		["A outlet", "An outlet"],
		["a outlet", "an outlet"],
	]
	var plain := text
	for pair in swaps:
		var pattern := RegEx.new()
		pattern.compile("(?i)\\b" + pair[0] + "\\b")
		plain = pattern.sub(plain, pair[1], true)
	return plain
