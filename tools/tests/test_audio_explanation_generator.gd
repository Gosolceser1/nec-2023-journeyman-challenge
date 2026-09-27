extends SceneTree
## audio_explanation_generator.gd -- everything except the leak guard, which
## lives in test_no_leak.gd.
##
##   ./Godot_v4.7.2-stable_win64_console.exe --headless --path . \
##       --script tools/tests/test_audio_explanation_generator.gd

const AEG = preload("res://src/speech/audio_explanation_generator.gd")
const R = preload("res://tools/tests/t_report.gd")

var t: R = R.new()


func field(rec: Dictionary, key: String) -> String:
	var v = rec.get(key, "")
	if v == null:
		return ""
	return str(v)


## SceneTree entry point. When the file is run on its own this calls run();
## when run_all.gd drives it, the runner calls run() directly so a failing
## assertion in one suite cannot abort the others.
func _init() -> void:
	# Standalone execution: run and set the exit code. The combined runner sets
	# t_report.autostart_disabled so this becomes a no-op there (it calls run()).
	if not t.run_suite_body():
		return
	run()
	quit(0 if t.failures.is_empty() else 1)


func run() -> void:
	normalize_for_compare()
	is_duplicate_text()
	rule_adds_value()
	prompt_intent()
	prompt_with_answer()
	answer_sentence()
	lesson_point()
	plain_words()
	lesson_lines_and_format()
	generate_explanation_shape()
	known_defects()
	report()


# --------------------------------------------------------------------------
# _normalize_for_compare -- lowercases, strips a citation prefix, drops
# punctuation, collapses whitespace.
# --------------------------------------------------------------------------
func normalize_for_compare() -> void:
	print("=== _normalize_for_compare ===")
	var rows := [
		["408.18(C): the front of it", "the front of it", "strips a short citation prefix"],
		["  The FRONT, please.  ", "the front please", "lowercase, strip, punctuation to space"],
		["A outlet", "a outlet", "keeps single letters"],
		["Receptacle outlets shall be", "receptacle outlets shall be", "no substitutions happen here"],
		["See section 210.19 for this", "see section 210 19 for this", "digits kept, '.' becomes a space"],
		["no colon here", "no colon here", "text without a colon is untouched"],
		["a: b: c", "b c", "only the FIRST ': ' prefix is stripped"],
		["", "", "empty stays empty"],
		["!!! ???", "", "punctuation-only collapses to empty"],
	]
	for row in rows:
		t.eq(AEG._normalize_for_compare(row[0]), row[1], "normalize(%s) [%s]" % [row[0], row[3 - 1]])

	# The ': ' strip is bounded (< 24 chars), so a long prefix is NOT removed.
	# That bound stops a sentence containing a colon from being truncated.
	t.eq(AEG._normalize_for_compare("0123456789012345abcdefghij: text"),
		"0123456789012345abcdefghij text", "a >24-char prefix is not stripped")
	t.eq(AEG._normalize_for_compare("012345678901234567890123: text"),
		"012345678901234567890123 text", "a 24+ char prefix is not stripped")


# --------------------------------------------------------------------------
# _is_duplicate_text -- powers math/intent suppression in lesson_lines
# --------------------------------------------------------------------------
func is_duplicate_text() -> void:
	print("=== _is_duplicate_text ===")
	t.eq(AEG._is_duplicate_text("Calculation: 30 amps", "30 amps"), true, "contains -> duplicate")
	t.eq(AEG._is_duplicate_text("30 amps", "Calculation: 30 amps"), true, "contains (reversed) -> duplicate")
	t.eq(AEG._is_duplicate_text("Answer: 30 amps.", "Calculation: 30 amps."), true,
		"token overlap of stopwords -> duplicate")
	t.eq(AEG._is_duplicate_text("conductor ampacity shall be sized", "conductor ampacity shall be sized"),
		true, "identical -> duplicate")
	t.eq(AEG._is_duplicate_text("The answer is 30 amps.", "Answer 30 amps."), false,
		"'the answer is' vs 'answer' -- only 1 meaningful short word, not >= 3")
	t.eq(AEG._is_duplicate_text("totally different words here", "nothing alike at all"), false,
		"unrelated text is not a duplicate")
	t.eq(AEG._is_duplicate_text("210.19 sized to the load", "Answer D, 12 kW"), false,
		"code rule vs a different answer is NOT a duplicate")
	t.eq(AEG._is_duplicate_text("", "x"), false, "empty side is never a duplicate")
	t.eq(AEG._is_duplicate_text("x", ""), false, "empty side (reversed) is never a duplicate")


# --------------------------------------------------------------------------
# _rule_adds_value -- is the code rule worth showing after the answer callout?
# --------------------------------------------------------------------------
func rule_adds_value() -> void:
	print("=== _rule_adds_value ===")
	t.eq(AEG._rule_adds_value("210.19(A) conductors shall be sized to the load.", "Answer A, 30 amperes."),
		true, "a real code rule adds value")
	t.eq(AEG._rule_adds_value("The answer is 30 amps per the table below.", "Answer: 30 amps."),
		true, "a long rule that merely repeats the answer still adds length/value")
	t.eq(AEG._rule_adds_value("Front.", "Answer A, front."), false,
		"a rule that is ONLY the answer is dropped")
	t.eq(AEG._rule_adds_value("Answer A, front.", "Answer A, front."), false,
		"identical rule and callout -> dropped")
	# A rule is EXPECTED to contain the answer words; that alone is not a dupe.
	t.eq(AEG._rule_adds_value("Marked on the front by the manufacturer on the front.", "Answer A, front."),
		true, "a rule that contains the answer is still shown when it says more")


# --------------------------------------------------------------------------
# prompt_intent / prompt_with_answer
# --------------------------------------------------------------------------
func prompt_intent() -> void:
	print("=== prompt_intent ===")
	t.eq(AEG.prompt_intent("Value is ___ volts."), "Value is [value] volts.", "___ becomes [value]")
	t.eq(AEG.prompt_intent("Value is __ volts."), "Value is [value] volts.", "__ becomes [value]")
	t.eq(AEG.prompt_intent("Which article ___?"), "Which article [value]?", "___ in a question")
	t.eq(AEG.prompt_intent("  Spaced ___  "), "Spaced [value]", "edges are stripped")
	t.eq(AEG.prompt_intent("No blank here."), "No blank here.", "no blank is a no-op")
	# NOTE: a 4-underscore run degrades to "[value]_"; see the recorded defect below.


func prompt_with_answer() -> void:
	print("=== prompt_with_answer ===")
	t.eq(AEG.prompt_with_answer("Value is ___ volts.", "250"), "Value is 250 volts.", "___ filled")
	t.eq(AEG.prompt_with_answer("Value is __ volts.", "250"), "Value is 250 volts.", "__ filled")
	t.eq(AEG.prompt_with_answer("The device is...", "front"), "The device is front.", "ellipsis form")
	t.eq(AEG.prompt_with_answer("The device is ...", "front"), "The device is front.", "spaced ellipsis form")
	t.eq(AEG.prompt_with_answer("Plain text", "front"), "", "no blank and no ellipsis -> empty")
	# Every ___ is replaced, not just the first.
	t.eq(AEG.prompt_with_answer("___ and ___", "X"), "X and X", "all blanks filled")
	# Degenerate answers must not vanish into the prompt.
	t.eq(AEG.prompt_with_answer("Value is ___ volts.", ""), "Value is  volts.", "empty answer yields a gap, not a crash")


# --------------------------------------------------------------------------
# answer_sentence -- picks the sentence that carries the answer
# --------------------------------------------------------------------------
func answer_sentence() -> void:
	print("=== answer_sentence ===")
	t.eq(AEG.answer_sentence("Each section shall be marked on the front. Other rules follow here.", "front"),
		"Each section shall be marked on the front.", "picks the answer-bearing sentence")
	t.eq(AEG.answer_sentence("Marked on the front.", "front"), "Marked on the front.",
		"a single matching sentence with its period")
	t.eq(AEG.answer_sentence("A rule with 25 amps. Another rule.", "25"), "A rule with 25 amps.",
		"numeric answer in the first sentence")
	t.eq(AEG.answer_sentence("No matching content at all here.", "zzz"), "No matching content at all here.",
		"falls back to the whole body")
	t.eq(AEG.answer_sentence("", "front"), "", "empty body -> empty")

	# A long body with NO match is truncated near a sentence boundary.
	var long_body := ""
	for i in 60:
		long_body += "This is filler sentence number %d in the body. " % i
	var out: String = AEG.answer_sentence(long_body, "zzz-not-present")
	t.check(long_body.length() > 420, "the truncation fixture really is > 420 chars (%d)" % long_body.length())
	t.check(out.length() <= 421, "long body is truncated to <= 421 chars (got %d)" % out.length())
	t.check(out.ends_with("."), "truncated body still ends on a sentence boundary")
	t.check(out.length() > 200, "truncation keeps a useful amount of text (got %d)" % out.length())


# --------------------------------------------------------------------------
# lesson_point -- the TEACH ORDER: code sentence > worked > prompt fill > answer
# --------------------------------------------------------------------------
func lesson_point() -> void:
	print("=== lesson_point ===")
	t.eq(AEG.lesson_point("Q ___?", "Marked on the front. More.", "WORKED", "front"),
		"Marked on the front.", "the code sentence wins (it teaches the reason)")
	t.eq(AEG.lesson_point("Q ___?", "", "WORKED TEXT", "front"), "WORKED TEXT", "worked is second")
	t.eq(AEG.lesson_point("Marked on the ___.", "", "", "front"), "Marked on the front.",
		"the filled prompt is third")
	t.eq(AEG.lesson_point("", "", "", "front"), "front", "the bare answer is the last resort")
	# The code sentence must take precedence over the filled prompt, because for
	# fill-in-blank questions the two are nearly word-identical.
	t.eq(AEG.lesson_point("The conductor is marked on the ___.", "Marked on the front.", "", "front"),
		"Marked on the front.", "the code sentence wins over the filled prompt (the '2 duplicates' fix)")


# --------------------------------------------------------------------------
# plain_words -- the jargon -> plain-language map
# --------------------------------------------------------------------------
func plain_words() -> void:
	print("=== plain_words ===")
	var swaps := [
		["Receptacle outlets shall be listed.", "outlets is listed.", "receptacle outlets + shall be"],
		["equipment grounding conductor", "ground wire", "singular EGC"],
		["Overcurrent protection shall be provided.", "breaker or fuse protection is provided.", "OCPD"],
		["Overcurrent protective device", "breaker or fuse", "longest OCPD form first"],
		["Overcurrent device", "breaker or fuse", "shorter OCPD form"],
		["supplementary overcurrent protection", "extra equipment protection", "longest first, so it wins"],
		["full-load current", "running amps", "singular FLC"],
		["full-load currents", "running amps", "plural FLC (has its own entry)"],
		["ampacity", "current rating", "ampacity"],
		["shall not be used as a substitute for grounding", "must never replace grounding", "double swap"],
		["shall not", "must not", "shall not"],
		["shall be", "is", "shall be"],
		["shall have a disconnect", "must have a disconnect", "shall have"],
		["shall", "must", "bare shall"],
		["in accordance with", "under", "in accordance with"],
		["utilized", "used", "utilized"],
		["ensure access", "make sure access", "ensure"],
		["located in the wall", "placed in the wall", "located"],
		["is accessible", "can be reached", "is accessible"],
		["dwelling unit", "house", "singular DU"],
		["dwelling units", "houses", "plural DU (has its own entry)"],
		["walking surface", "floor", "walking surface"],
		["accessible", "reachable", "accessible (after the longer forms)"],
		["not less than 6 in.", "at least 6 in.", "not less than"],
		["not more than 6 ft", "at most 6 ft", "not more than"],
		["not exceeding 30 in.", "up to 30 in.", "not exceeding"],
		["as specified in 310.16", "in 310.16", "as specified in"],
		["utilization equipment", "electrical equipment", "utilization equipment"],
		["luminaire", "light fixture", "singular luminaire"],
		["luminaires", "light fixtures", "plural luminaires"],
		["disconnecting means", "disconnect switch", "disconnecting means"],
		["waste disposer", "garbage disposal", "waste disposer"],
		["branch circuit", "circuit", "branch circuit"],
		["premises wiring", "building wiring", "premises wiring"],
		["service equipment", "main service panel", "service equipment"],
		["fixed electric space-heating equipment", "fixed electric heaters", "long compound"],
		["grounding-type attachment plug", "three-prong grounded plug", "grounding-type plug"],
		["grounded conductor", "neutral wire", "singular grounded conductor"],
		["ungrounded conductors", "hot wires", "plural ungrounded conductors"],
		["A outlet shall", "An outlet must", "a -> an article fix"],
		["Article 210.8 shall be used", "Article 210.8 is used", "shall be"],
	]
	for row in swaps:
		t.eq(AEG.plain_words(row[0]), row[1], "plain_words(%s) [%s]" % [row[0], row[2]])

	# Word-boundary anchoring: a longer word CONTAINING a term is not swapped.
	# "ungrounded" contains "grounded", but the grounded-conductor swaps are all
	# two-word phrases, so nothing fires on the bare word.
	t.eq(AEG.plain_words("ampacitied"), "ampacitied", "\\b prevents a partial-word swap")
	t.eq(AEG.plain_words("ungrounded"), "ungrounded", "a term inside a longer word is not swapped")
	t.eq(AEG.plain_words(""), "", "empty stays empty")
	# Case-insensitive.
	t.eq(AEG.plain_words("AMPACITY"), "current rating", "matching is case-insensitive")


# --------------------------------------------------------------------------
# lesson_lines / format_lesson_text -- the SINGLE SOURCE for learn content
# --------------------------------------------------------------------------
func lesson_lines_and_format() -> void:
	print("=== lesson_lines / format_lesson_text ===")
	var rec := {
		"id": "test-1", "prompt": "The demand load is ___ kW.",
		"answers": ["8 kW", "8.4 kW", "8.8 kW", "12 kW"], "correct_index": 3,
		"reference_text": "220.53 Demand Load\nFor a range over 12 kW use column c of table 220.55.",
		"formula": "", "worked": "", "article": "220.53",
	}
	var lines: PackedStringArray = AEG.lesson_lines(rec)
	t.eq(lines.size(), 2, "callout + code rule, math suppressed when empty")
	t.has(lines[0], "Answer D, 12 kW.", "the answer callout comes FIRST")
	t.has(lines[1], "220.53", "the code rule follows")
	t.check(AEG.format_lesson_text(rec) == "\n".join(lines), "format_lesson_text joins the same lines with newlines")
	t.has(AEG.format_lesson_text(rec), "\n", "the panel text is multi-line when there are 2+ lines")

	# A third line appears when the worked text is NOT a duplicate of the rule.
	var rec2: Dictionary = rec.duplicate(true)
	rec2["worked"] = "Column C demand for a 14 kW range."
	t.eq(AEG.lesson_lines(rec2).size(), 3, "distinct worked text adds a calculation line")
	# ...and is suppressed when it only restates the rule.
	var rec3: Dictionary = rec.duplicate(true)
	rec3["worked"] = "For a range over 12 kW use column c of table 220.55."
	t.eq(AEG.lesson_lines(rec3).size(), 2, "worked text that duplicates the rule is dropped")

	# An explicit answer argument overrides the record's correct choice.
	var lines2: PackedStringArray = AEG.lesson_lines(rec, "8.4 kW")
	t.has(lines2[0], "Answer", "an explicit answer still produces a callout")
	t.has(lines2[0], "8.4", "the explicit answer wins over correct_index")

	# A record with no resolvable answer must not crash.
	t.eq(AEG.lesson_lines({"prompt": "Q", "answers": [], "correct_index": -1, "reference_text": ""}).size(), 0,
		"a record with no answer yields no lines")


# --------------------------------------------------------------------------
# generate_explanation -- the shape main.gd and the speech dumper consume
# --------------------------------------------------------------------------
func generate_explanation_shape() -> void:
	print("=== generate_explanation ===")
	var rec := {
		"id": "abc", "prompt": "P ___?", "answers": ["12 kW", "8 kW"], "correct_index": 0,
		"reference_text": "220.53 Demand Load\nFor a range over 12 kW use column c.",
		"formula": "I = V / R", "worked": "12 kW is the demand", "article": "220.53",
	}
	var expl: Dictionary = AEG.generate_explanation(rec)
	t.eq(field(expl, "question_id"), "abc", "question_id is carried through")
	var script: Dictionary = expl.get("tts_script", {})
	for key in ["intent", "code_breakdown", "math_explanation", "answer_callout"]:
		t.check(script.has(key), "tts_script has the '%s' key" % key)
	t.eq(script.get("intent", "x"), "", "intent is always empty in this build")
	t.has(str(script.get("code_breakdown", "")), "220.53", "the citation prefixes the code breakdown")
	t.has(str(script.get("math_explanation", "")), "Calculation:", "worked text becomes a Calculation line")
	t.eq(script.get("answer_callout", ""), "Answer A, 12 kW.", "the callout names the letter and the value")

	# Worked wins over formula, and the label reflects which was used.
	var rec_formula: Dictionary = rec.duplicate(true)
	rec_formula["worked"] = ""
	t.has(str(AEG.generate_explanation(rec_formula).get("tts_script", {}).get("math_explanation", "")),
		"Formula:", "formula-only records get a 'Formula:' line")
	var rec_both: Dictionary = rec.duplicate(true)
	t.has(str(AEG.generate_explanation(rec_both).get("tts_script", {}).get("math_explanation", "")),
		"Calculation:", "worked wins over formula when both exist")

	# Citation is taken from the reference_text header when the field is empty.
	var rec_hdr := {"prompt": "p", "answers": ["a"], "correct_index": 0,
		"reference_text": "210.8 Name\nbody text."}
	t.has(str(AEG.generate_explanation(rec_hdr).get("tts_script", {}).get("code_breakdown", "")),
		"210.8", "the reference_text header supplies the citation")

	# An unresolvable correct_index degrades instead of crashing.
	var rec_bad := {"prompt": "p", "answers": ["a"], "correct_index": -1, "reference_text": "NoCite here\nBody."}
	t.eq(AEG.generate_explanation(rec_bad).get("tts_script", {}).get("answer_callout", ""), "",
		"no valid correct_index -> no callout")
	t.eq(AEG.generate_explanation({"prompt": "p", "answers": [], "correct_index": 9}).get("question_id", ""),
		"", "an out-of-range record still returns a well-formed dictionary")

	# Math that merely repeats the rule is suppressed.
	var rec_dupe := {"prompt": "p", "answers": ["12 kW"], "correct_index": 0,
		"reference_text": "X\nFor a range over 12 kW use column c.",
		"worked": "For a range over 12 kW use column c."}
	t.eq(AEG.generate_explanation(rec_dupe).get("tts_script", {}).get("math_explanation", ""), "",
		"math that duplicates the code rule is dropped")


# --------------------------------------------------------------------------
# CONFIRMED defects, reproduced and reported but not counted as failures.
# --------------------------------------------------------------------------
func known_defects() -> void:
	print("=== known defects (documented, not failures) ===")
	# Every defect that used to be pinned here is FIXED. They are now asserted as
	# behaviour, in the rows above and in the suites named below:
	#   - blank runs of any length (a 4-run in final-exam-#5-050) collapse to one
	#     blank, and the fill is SPACED: "a____at" -> "a vapor seal at",
	#     "Article__." -> "Article 100." (final-exam-#3-058).
	#   - is_note_row() accepts "NOTE 1:" and "NOTE No. 1:" (final-exam-#1-021),
	#     and _strip_note_prefix() no longer eats the first four characters of a
	#     word that merely starts with "note" ("NOTED: x" stays whole).
	#   - a foot mark is spoken as "5 feet", a formula subscript as "R total",
	#     a multi-character Roman numeral as 8/12/13, a cable designation as
	#     "12 slash 3", and a hyphenated mixed number as "1 and one quarter".
	#   - plain_words() has explicit PLURAL entries, so "Luminaires in dwelling
	#     units" is narrated as "light fixtures in houses" (26 records).
	# Asserted in: test_speech_text.gd, test_table_viewer.gd, test_unit_matcher.gd.



func TV_is_note(text: String) -> bool:
	return preload("res://src/ui/table_viewer.gd").is_note_row([text])


func tv_strip(text: String) -> String:
	return preload("res://src/ui/table_viewer.gd")._strip_note_prefix(text)


func speech_speakable(text: String) -> String:
	return preload("res://src/speech/speech_text.gd").speakable(text)


func aeg_plain(text: String) -> String:
	return AEG.plain_words(text)


func report() -> void:
	t.report()
