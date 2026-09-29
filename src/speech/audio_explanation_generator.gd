class_name AudioExplanationGenerator
extends RefCounted
## Generates structured explanation scripts (intent, code breakdown, math, answer callout)
## and handles plain-language terminology transformations.

const ANSWER_LETTERS := ["A", "B", "C", "D"]

static func prompt_intent(prompt: String) -> String:
	var clean := prompt.strip_edges()
	# ANY run of 2+ underscores is one blank. Matching the literal "___" and then
	# "__" left a stray "_" on longer runs: a 4-underscore blank in the bank
	# rendered as "a[value]_at the building wall" (final-exam-#5-050), and the
	# stray underscore then reached the voice as the word "underscore".
	var blank := RegEx.new()
	blank.compile("_{2,}")
	return blank.sub(clean, "[value]", true)

static func generate_explanation(record: Dictionary, answer: String = "") -> Dictionary:
	var prompt := str(record.get("prompt", "")).strip_edges()
	var source := str(record.get("reference_text", "")).strip_edges()
	var formula := str(record.get("formula", "")).strip_edges()
	var worked := str(record.get("worked", "")).strip_edges()
	var cite := str(record.get("article", "")).strip_edges()
	var answers: Array = record.get("answers", [])
	var correct := int(record.get("correct_index", -1))
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

	# No letter: choices are shuffled per session, and the letter the learner
	# saw is spoken as its own clip in front (SpeechText.display_order).
	var answer_callout := ""
	if choice_text != "":
		answer_callout = "Answer: " + _sentence_end(choice_text)

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
		# A calculation that reaches the answer is never a repeat of a rule line
		# that does not state it (a long provision can share every word of
		# "Table 630.31(A)(2): ... = 8.19 A." except the numbers).
		var answers: Array = record.get("answers", [])
		var ci := int(record.get("correct_index", -1))
		var answer_text := answer if answer != "" else (str(answers[ci]) if ci >= 0 and ci < answers.size() else "")
		var math_has_answer := answer_text != "" and not find_match_in(math, answer_text).is_empty()
		for existing in lines:
			if math_has_answer and find_match_in(existing, answer_text).is_empty():
				continue
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
	# Any run of 2+ underscores is one blank, and the answer must be SPACED away
	# from whatever word the run was glued to. Two live records needed this:
	# "a____at" (final-exam-#5-050) filled as "avapor seal_at" because the run
	# was a 4-underscore the old "__" branch never matched, and "Article__."
	# (final-exam-#3-058) filled as "Article100." with no space.
	#
	# The run's own surrounding whitespace is consumed with it, so a blank that
	# already had a space on one side ("___ volts") does not gain a second one.
	# The whitespace class is written as a literal tab inside the class -- GDScript
	# has no 	 escape in a double-quoted string, so "[ 	]" is a syntax error.
	var blank_run := RegEx.new()
	blank_run.compile("[ 	]*_{2,}[ 	]*")
	var filled := blank_run.sub(prompt, " " + answer + " ", true)
	if filled != prompt:
		# A blank at the very start or end would leave a leading/trailing space,
		# and one sitting in front of punctuation ("on the ___." -> "on the front.")
		# would put a space before the full stop. Tidy both.
		filled = filled.strip_edges()
		for punct in [".", ",", ";", ":", "?", "!"]:
			filled = filled.replace(" " + punct, punct)
		# An EMPTY answer deliberately leaves a double space, so the gap where the
		# blank was stays visible on screen instead of the words closing up into
		# "Value is volts." Collapsing runs would hide the missing answer, so the
		# tidy-up is skipped in that one case.
		if answer.strip_edges() == "":
			return filled
		return filled.replace("  ", " ").strip_edges()
	var trimmed := prompt.strip_edges()
	if trimmed.ends_with("..."):
		return trimmed.trim_suffix("...").strip_edges() + " " + answer + "."
	return ""

## Longest quote read when no sentence carries the answer.
const QUOTE_CAP := 420
## A sentence ends at ". " before a capital, quote or bracket; never before a
## digit or a lowercase word, so "Exception No. 1:", "two No. 6 or larger
## screws" and "6 ft. above" stay whole. A line break ends one only before an
## Exception or Informational Note: a list stays with the sentence that
## introduces it.
const SENTENCE_BREAK := "([.?!])(?:[ \\t]+(?=[A-Z\"“'(\\[])|[ \\t]*\\n\\s*(?=Exception|Informational Note))"
## Words whose period is not a sentence end even before a capital.
const NO_BREAK_AFTER := ["no", "nos", "fig", "sec", "art", "ex", "e.g", "i.e", "approx", "vs"]

## [start, end) of every sentence of `body`, in order, covering all of it.
static func sentence_spans(body: String) -> Array[Vector2i]:
	var spans: Array[Vector2i] = []
	var last_word := RegEx.create_from_string("(\\S+)$")
	# "b." opening a list line starts the next item; it never ends this one,
	# and it splits off a new sentence only after one that already ended.
	var list_marker := RegEx.create_from_string("\\n[ \\t]*\\(?[A-Za-z0-9]{1,3}\\)?$")
	var from := 0
	for m in RegEx.create_from_string(SENTENCE_BREAK).search_all(body):
		var head := body.substr(from, m.get_start() - from)
		var word := last_word.search(head)
		if word != null and word.get_string(1).to_lower().lstrip("(") in NO_BREAK_AFTER:
			continue
		var marker := list_marker.search(head)
		if marker != null:
			var before := head.substr(0, marker.get_start()).strip_edges()
			if before != "" and before.substr(before.length() - 1) in [".", "?", "!"]:
				spans.append(Vector2i(from, from + marker.get_start()))
				from += marker.get_start() + 1
			continue
		if head.strip_edges() != "":
			spans.append(Vector2i(from, m.get_end(1)))
		from = m.get_end()
	if body.substr(from).strip_edges() != "":
		spans.append(Vector2i(from, body.length()))
	return spans

static func sentences_of(body: String) -> PackedStringArray:
	var out := PackedStringArray()
	for s in sentence_spans(body):
		out.append(body.substr(s.x, s.y - s.x).strip_edges())
	return out

## Ends a quoted line on a full stop: "conditions are met:" and a last list
## item with no period are both read (and shown) as a finished sentence.
static func _sentence_end(text: String) -> String:
	var body := text.strip_edges()
	while body != "" and body.substr(body.length() - 1) in [":", ";", ","]:
		body = body.substr(0, body.length() - 1).strip_edges()
	if body == "" or body.substr(body.length() - 1) in [".", "?", "!"]:
		return body
	return body + "."

## Drops trailing lines that only open the NEXT provision ("Exception No. 1:",
## "2.", "Combustible Fibers/Flyings.") after a line that already ended a
## sentence. A line carrying `answer` is never dropped.
static func _drop_dangling_lines(text: String, answer: String) -> String:
	var lines := text.strip_edges().split("\n")
	while lines.size() > 1:
		var last := lines[lines.size() - 1].strip_edges()
		var before := lines[lines.size() - 2].strip_edges()
		if before == "" or not before.substr(before.length() - 1) in [".", "?", "!"]:
			break
		if last.split(" ", false).size() > 4 or (answer != "" and not find_match_in(last, answer).is_empty()):
			break
		lines.remove_at(lines.size() - 1)
	return "\n".join(lines)

static func answer_sentence(body: String, answer: String) -> String:
	var spans := sentence_spans(body)
	if not UnitMatcher.answer_match_candidates(answer).is_empty():
		for i in spans.size():
			var s: Vector2i = spans[i]
			if find_match_in(body.substr(s.x, s.y - s.x), answer).is_empty():
				continue
			# A bare definition heading ("Labeled.") teaches nothing: read the definition with it.
			if body.substr(s.x, s.y - s.x).split(" ", false).size() <= 3 and i + 1 < spans.size():
				s.y = spans[i + 1].y
			return _sentence_end(_drop_dangling_lines(body.substr(s.x, s.y - s.x), answer))
	if body.length() <= QUOTE_CAP:
		return _sentence_end(body) if body != "" else body
	# Whole sentences only, as many as fit: a raw cut once stopped mid-word
	# ("overcurrent devic.") or on "Exception No.".
	var end := 0
	for s in spans:
		if s.y > QUOTE_CAP:
			break
		end = s.y
	if end == 0 and not spans.is_empty():
		end = spans[0].y
		# One sentence longer than the cap: stop at its last line end that fits.
		var head := body.substr(0, mini(end, QUOTE_CAP))
		var cut := maxi(head.rfind(".\n"), maxi(head.rfind("?\n"), head.rfind("!\n")))
		if end > QUOTE_CAP and cut > 200:
			end = cut + 1
		elif end > QUOTE_CAP and head.rfind("\n") > 200:
			end = head.rfind("\n")
	return _sentence_end(_drop_dangling_lines(body.substr(0, end), ""))

## prompt is optional: when it has a "___" blank, the occurrence whose surrounding
## words best match the words around the blank wins; otherwise the first one does.
static func find_match_in(text: String, answer: String, prompt: String = "") -> Dictionary:
	var lower := text.to_lower()
	var hits: Array = []
	var order := 0
	for candidate in UnitMatcher.answer_match_candidates(answer):
		order += 1
		if candidate == "":
			continue
		var start := 0
		while start < text.length():
			var index := lower.find(candidate.to_lower(), start)
			if index < 0:
				break
			var before := text.substr(index - 1, 1) if index > 0 else ""
			var after_index := index + candidate.length()
			var after := text.substr(after_index, 1) if after_index < text.length() else ""
			var has_left_boundary := not _is_word_char(candidate.substr(0, 1)) or not _is_word_char(before)
			var has_right_boundary := not _is_word_char(candidate.substr(candidate.length() - 1, 1)) or not _is_word_char(after)
			# "2" must not match the tail of "1/2", "7" the tail of "3.7", "200" the tail of "1,200".
			if candidate.substr(0, 1).is_valid_int() and _is_number_glue(text, index - 1, -1):
				has_left_boundary = false
			if candidate.substr(candidate.length() - 1, 1).is_valid_int() and _is_number_glue(text, after_index, 1):
				has_right_boundary = false
			if has_left_boundary and has_right_boundary:
				hits.append([order, index, candidate.length()])
			start = index + 1
	if hits.is_empty():
		return {}
	var best: Array = hits[0]
	var best_score := -999
	var blank_words := _blank_context_words(prompt)
	var prompt_negated := _blank_is_negated(prompt)
	for hit in hits:
		var score := 0
		if not blank_words.is_empty():
			var window := (text.substr(maxi(0, hit[1] - 40), mini(40, hit[1])) + " " + text.substr(hit[1] + hit[2], 40)).to_lower()
			for w in blank_words:
				if RegEx.create_from_string("\\b" + w + "\\b").search(window) != null:
					score += 1
			if not prompt_negated and RegEx.create_from_string("\\bnot\\s*$").search(text.substr(maxi(0, hit[1] - 8), mini(8, hit[1])).to_lower()) != null:
				score -= 2
		if score > best_score or (score == best_score and (hit[0] < best[0] or (hit[0] == best[0] and hit[1] < best[1]))):
			best = hit
			best_score = score
	return {"start": best[1], "length": best[2]}

static func _is_number_glue(text: String, index: int, step: int) -> bool:
	if index < 0 or index >= text.length() or not (text.substr(index, 1) in [".", ",", "/"]):
		return false
	var next := index + step
	return next >= 0 and next < text.length() and text.substr(next, 1).is_valid_int()

const _BLANK_STOPWORDS := ["the", "a", "an", "of", "to", "and", "or", "in", "on", "for", "be", "is", "shall", "not", "than", "that", "with", "by", "at", "as", "are"]

static func _blank_context_words(prompt: String) -> Array[String]:
	var out: Array[String] = []
	var blank := RegEx.create_from_string("_{2,}").search(prompt)
	if blank == null:
		return out
	var word := RegEx.create_from_string("[a-z0-9]+")
	var left: Array[String] = []
	for m in word.search_all(prompt.substr(0, blank.get_start()).to_lower()):
		left.append(m.get_string())
	var right: Array[String] = []
	for m in word.search_all(prompt.substr(blank.get_end()).to_lower()):
		right.append(m.get_string())
	for w in left.slice(maxi(0, left.size() - 4)) + right.slice(0, 4):
		if not (w in _BLANK_STOPWORDS) and not out.has(w):
			out.append(w)
	return out

static func _blank_is_negated(prompt: String) -> bool:
	var blank := RegEx.create_from_string("_{2,}").search(prompt)
	return blank != null and RegEx.create_from_string("\\bnot\\s*$").search(prompt.substr(0, blank.get_start()).to_lower()) != null

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
	# ORDER MATTERS: the longest / most specific phrase must come first, because
	# each entry is applied as a whole-word regex substitution in sequence. A
	# later, shorter entry can still fire on text an earlier one already
	# rewrote, so the singulars that are prefixes of a plural must be harmless.
	# The PLURAL forms are listed explicitly next to their singulars: the swap
	# table is applied with \b...\b, and "receptacle outlets" is two words, so
	# the singular entry alone never matched "receptacles" -- 26 of 279 records
	# were narrating code jargon ("Luminaires", "ungrounded conductors") at the
	# learner. Every plural added here is one that actually occurs in the bank.
	var swaps := [
		["receptacle outlets", "outlets"],
		["receptacle outlet", "outlet"],
		["receptacles", "outlets"],
		["receptacle", "outlet"],
		["equipment grounding conductors", "ground wires"],
		["equipment grounding conductor", "ground wire"],
		["grounding-type attachment plugs", "three-prong grounded plugs"],
		["grounding-type attachment plug", "three-prong grounded plug"],
		["grounding-type plugs", "three-prong plugs"],
		["grounding-type plug", "three-prong plug"],
		["grounding conductors", "ground wires"],
		["grounding conductor", "ground wire"],
		["grounded conductors", "neutral wires"],
		["grounded conductor", "neutral wire"],
		["ungrounded conductors", "hot wires"],
		["ungrounded conductor", "hot wire"],
		["overcurrent protection devices", "breakers or fuses"],
		["supplementary overcurrent protection", "extra equipment protection"],
		["overcurrent protective devices", "breakers or fuses"],
		["overcurrent protective device", "breaker or fuse"],
		["overcurrent devices", "breakers or fuses"],
		["overcurrent device", "breaker or fuse"],
		["overcurrent protection", "breaker or fuse protection"],
		["service equipment", "main service panel"],
		["utilization equipment", "electrical equipment"],
		["premises wiring", "building wiring"],
		["feeder tap", "tap off the feeder"],
		["disconnecting means", "disconnect switch"],
		["luminaires", "light fixtures"],
		["luminaire", "light fixture"],
		["fixed electric space-heating equipment", "fixed electric heaters"],
		["waste disposers", "garbage disposals"],
		["waste disposer", "garbage disposal"],
		["branch-circuit", "circuit"],
		["branch circuit", "circuit"],
		["branch circuits", "circuits"],
		["demand factors", "share of the load you count"],
		["demand factor", "share of the load you count"],
		["full-load currents", "running amps"],
		["full-load current", "running amps"],
		["ampacity", "current rating"],
		["ampacities", "current ratings"],
		["shall not be used as a substitute for", "must never replace"],
		# Modals agree with any subject: "shall be" -> "is" read "garbage disposals
		# is permitted", and ran before "provided with" -> "has" ("is has").
		["shall be provided with", "must have"],
		["are provided with", "have"],
		["is provided with", "has"],
		# After a plural ("Types NM and NMC cables shall not be permitted"); a
		# word ending in ss/us/is ("Cablebus") stays singular.
		["(?<=[^sui]s )shall not be permitted", "are not permitted"],
		["(?<=[^sui]s )shall be permitted(?! to)", "are permitted"],
		["shall not be permitted", "is not permitted"],
		["shall be permitted to be", "may be"],
		["shall be permitted to", "may"],
		["shall be permitted", "is permitted"],
		["shall not", "must not"],
		["shall be", "must be"],
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
		# "rated at not more than" would read "rated at at most".
		["at not less than", "at least"],
		["at not more than", "at most"],
		["not less than", "at least"],
		["not more than", "at most"],
		["not exceeding", "up to"],
		["as specified in", "in"],
	]
	var plain := text
	for pair in swaps:
		var pattern := RegEx.new()
		pattern.compile("(?i)\\b" + pair[0] + "\\b")
		plain = pattern.sub(plain, pair[1], true)
	# Article agreement after the swaps, case-sensitive: a mid-sentence "an
	# current" must become "a current", because a capital "A" is voiced as the
	# letter. After a naming word ("Class A outlet") the A is a letter, not an article.
	var pairs: Array = []
	for w in SWAPPED_CONSONANT_WORDS:
		pairs.append_array([["An " + w, "A " + w], ["an " + w, "a " + w]])
	for w in SWAPPED_VOWEL_WORDS:
		pairs.append_array([["A " + w, "An " + w], ["a " + w, "an " + w]])
	for pair in pairs:
		var article := RegEx.new()
		article.compile("(?<!Class |Type |Option |Answer |paragraph |sub-item )\\b" + pair[0] + "\\b")
		plain = article.sub(plain, pair[1], true)
	return plain

## First words of plain_words replacements, by the sound they start with: the
## swap keeps the source's article, so "an ungrounded conductor" became "an
## hot wire" and "an accessible location" "an reachable location".
const SWAPPED_CONSONANT_WORDS := ["current", "hot", "ground", "neutral", "reachable", "breaker",
	"three-prong", "main", "building", "tap", "disconnect", "light", "fixed", "garbage", "circuit",
	"share", "running", "house", "floor"]
const SWAPPED_VOWEL_WORDS := ["outlet", "extra", "electrical"]
