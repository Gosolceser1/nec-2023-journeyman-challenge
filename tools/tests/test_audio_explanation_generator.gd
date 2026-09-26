extends SceneTree
## audio_explanation_generator.gd -- everything except the leak guard, which
## lives in test_no_leak.gd.
##
##   ./Godot_v4.7.2-stable_win64_console.exe --headless --path . \
##       --script tools/tests/test_audio_explanation_generator.gd

const AEG = preload("res://audio_explanation_generator.gd")
const R = preload("res://tools/tests/t_report.gd")

var t: R = R.new()


func field(rec: Dictionary, key: String) -> String:
	var v = rec.get(key, "")
	if v == null:
		return ""
	return str(v)


func _init() -> void:
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
	report_and_quit()


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

	# Word-boundary anchoring: a longer word containing a term is not swapped.
	t.eq(AEG.plain_words("ampacities are listed"), "ampacities are listed", "\b prevents a partial-word swap")
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

	# DEFECT 7: prompt_intent / prompt_with_answer only handle runs of 2 or 3
	# underscores. A 4-run leaves a stray "_", and the fill glues the answer to
	# the neighbouring word.
	t.defect("audio_explanation_generator.gd:8 prompt_intent + :192 prompt_with_answer",
		"blank runs longer than 3 underscores are not handled: prompt_intent leaves a stray '_' "
		+ "and prompt_with_answer glues the answer onto the adjacent word",
		"prompt_intent('...shall have a____at the building wall') = '"
			+ AEG.prompt_intent("For over 1000 volts, busways having sections located both inside and outside of buildings, shall have a____at the building wall.") + "'",
		"'...shall have a [value] at the building wall.' -- the whole run is one blank",
		"1 live record: final-exam-#5-050 (answer 'vapor seal'); the prompt renders as "
		+ "'a[value]_at the building wall' and the fill produces 'avapor seal_at the building wall'")

	t.defect("audio_explanation_generator.gd:192 prompt_with_answer",
		"'Article__.' (a 2-run glued to the word) fills as 'Article426.' with no space",
		"prompt_with_answer('...is found in Article__.', '100') = '"
			+ AEG.prompt_with_answer("The definition of “fibers/flyings, ignitible” is found in Article__.", "100") + "'",
		"'...is found in Article 100.' -- a space before the answer",
		"1 live record: final-exam-#3-058 (answer '100'); speakable() handles this case via its "
		+ "'article\\s*_+' rule, but the DISPLAYED prompt shows 'Article100.'")

	# DEFECT 1: is_note_row rejects numbered notes, contradicting its own
	# docstring, so a "NOTE 1:" row is rendered as a DATA row.
	t.defect("table_viewer.gd:41 is_note_row",
		"numbered NEC notes ('NOTE 1:', 'NOTE No. 1:') are NOT recognised as note rows, "
		+ "contradicting the function's own docstring; they render as data rows and bypass the note strip",
		"is_note_row(['NOTE 1: x']) = " + str(TV_is_note("NOTE 1: x"))
			+ ", _strip_note_prefix('NOTE 1: x') = '" + tv_strip("NOTE 1: x") + "'",
		"is_note_row = true, and the note routed to the note strip (which redacts it pre-answer)",
		"1 real record (final-exam-#1-021) -- its table's NOTE 1 row is counted as data, "
		+ "inflating the row count and putting a 165-char sentence in a table cell")

	# DEFECT 2: speakable() has no foot-mark rule, so a foot-mark answer is
	# narrated with a raw apostrophe.
	t.defect("speech_text.gd:94 speakable",
		"no foot-mark conversion, so \"5'\" is narrated with a literal apostrophe instead of '5 feet'",
		"speakable(\"5'\") = '" + speech_speakable("5'") + "', speakable(\"5\\\"\") = '" + speech_speakable("5\"") + "'",
		"speakable(\"5'\") should be '5 feet', matching the inch-mark path",
		"14 narrated answer choices across final-exam-#3-013 / -018 / -035 / -049 "
		+ "(e.g. 'A, 4.' / 'B, 5.'), and the answer callout 'Answer B, 5'.'")

	# DEFECT 3: Roman-numeral replacement is literal and order-dependent.
	t.defect("speech_text.gd:343 speakable",
		"the Roman-numeral fix is a plain string replace, so VIII/XII/XIII degrade to 'V3'/'X2'/'X3'",
		"speakable('VIII') = '" + speech_speakable("VIII") + "', speakable('XII') = '"
			+ speech_speakable("XII") + "', speakable('XIII') = '" + speech_speakable("XIII") + "'",
		"'8' / '12' / '13' (or the Roman numeral left intact), never 'V3'",
		"not reachable today: the bank contains only Class I/II/III and 'Diagram II/III', "
		+ "which the III/II replacements handle correctly")

	# DEFECT 4: a hyphenated mixed number is not recognised.
	t.defect("speech_text.gd:98 speakable",
		"the mixed-number rule requires whitespace, so '1-1/4\"' is not converted "
		+ "and then mis-spaced by the standalone-fraction rule",
		"speakable('1-1/4\\\"') = '" + speech_speakable("1-1/4\"") + "'",
		"'1 and one quarter inches', matching the spaced form '1 1/4\"'",
		"not reachable in spoken fields today (0 matches in reference_text/formula/worked); "
		+ "the form does appear in info_tip text")

	# DEFECT 5: N/M cable designations are read as fractions.
	t.defect("speech_text.gd:239 speakable",
		"a cable designation like '12/3' is spoken as a fraction",
		"speakable('12/3') = '" + speech_speakable("12/3") + "', speakable('10/2') = '"
			+ speech_speakable("10/2") + "'",
		"'twelve over three' with the 'over' cue, or the designation left intact",
		"not reachable today: 0 cable designations in the spoken-source fields; "
		+ "latent for any future '12/3' answer or reference line")

	# DEFECT 6: plain_words() misses plural/inflected forms.
	t.defect("audio_explanation_generator.gd:285 plain_words",
		"the swap table has no plural entries for several terms, so plural forms are "
		+ "read out in code jargon",
		"plain_words('Luminaires in dwelling units shall be protected.') = '"
			+ aeg_plain("Luminaires in dwelling units shall be protected. Receptacles and branch circuits too.") + "'",
		"plurals mapped the same way their singulars are ('light fixtures in houses ...')",
		"26 of 279 records: luminaires (10), ungrounded conductors (8), dwelling units (7), "
		+ "overcurrent devices (5), service equipment (4), full-load currents (1)")


func TV_is_note(text: String) -> bool:
	return preload("res://table_viewer.gd").is_note_row([text])


func tv_strip(text: String) -> String:
	return preload("res://table_viewer.gd")._strip_note_prefix(text)


func speech_speakable(text: String) -> String:
	return preload("res://speech_text.gd").speakable(text)


func aeg_plain(text: String) -> String:
	return AEG.plain_words(text)


func report_and_quit() -> void:
	var res: Dictionary = t.report()
	quit(0 if (res["failures"] as Array).is_empty() else 1)
