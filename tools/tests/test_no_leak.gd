extends SceneTree
## LEAK GUARD -- the app's core product promise is that the answer must not
## appear anywhere above the question until the learner answers. This file owns
## that guarantee for the pure helpers.
##
## Run:
##   ./Godot_v4.7.2-stable_win64_console.exe --headless --path . \
##       --script tools/tests/test_no_leak.gd
##
## The assertions below pin the FIXED regressions (single-digit needles,
## digit-inside-larger-number, "two"<->"2", multi-word answers, 125-volt) AND
## sweep every real bank record for surviving matches.

const AEG = preload("res://src/speech/audio_explanation_generator.gd")
const UM = preload("res://src/speech/unit_matcher.gd")
const R = preload("res://tools/tests/t_report.gd")

var t: R = R.new()

## Coincidental answer tokens that appear inside a QUESTION PROMPT because the
## NEC code itself puts them there. The prompt is the question and is never
## redacted; blanking these would destroy the question, and they do not hand
## over the answer. Keyed "<record id>|<token that matched>".
##
##   final-exam-#1-024|20     "All 15 or 20 amp, ... 125 volt through 250 volt" is
##                             the cited circuit rating; the answer is the DISTANCE.
##   final-exam-#3-052|three  "a three-phase motor" is the motor type; the answer
##                             is the NUMBER of overload units.
##   open-book-exam-#4-019|6  "weighing not more than 6 pounds" is the luminaire
##                             weight; the answer is the SCREW size (#6).
##   final-exam-#5-070|36 inches
##                             "secured within 36 inches of each termination" is the
##                             termination rule; the answer is the SUPPORT SPACING.
##   final-exam-#3-042|an accessible
##                             the PDF stem quotes 422.33(A), which says "an accessible"
##                             twice and blanks only the second; mirrors
##                             PROMPT_LEAK_EXCEPTIONS in tools/pipeline/validate_question_bank.py.
var prompt_allowlist := {
	"final-exam-#3-042|an accessible": true,
	"final-exam-#1-024|20": true,
	"final-exam-#3-052|three": true,
	"open-book-exam-#4-019|6": true,
	"final-exam-#5-070|3 ft": true,
	"final-exam-#1-022|two": true,
	# The stem's own values: no demand factor on one oven (220.55), 20 A vs 20 ft,
	# two bays -> two outlets, 30 V within 30 seconds, EGC not larger than the #12 circuit.
	"final-exam-#4-036|6": true,
	"open-book-exam-#3-015|20": true,
	"open-book-exam-#3-017|two": true,
	"open-book-exam-#12-017|30": true,
	"open-book-exam-#12-023|#12": true,
}


## GDScript's `or` is a BOOLEAN operator, so `dict.get(k, "") or ""` yields
## str(true) == "true", not a fallback. Use this for safe field reads.
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
	redact_table()
	redact_boundaries()
	redact_word_answers()
	redact_numeric_answers()
	redact_variants_covered()
	redact_idempotence()
	match_in_semantics()
	bank_wide_sweep()
	figure_text_sweep()
	known_defects()
	report()


# --------------------------------------------------------------------------
# 1. Table-driven: [text, answer, expected, why]
# --------------------------------------------------------------------------
func redact_table() -> void:
	print("=== redact_answer_spans: table ===")
	var rows := [
		# -- the named regressions, now locked in --------------------------------
		# Single-digit needle: digits ARE redacted even at length 1.
		["Chapter 3: Wiring and Protection", "3", "Chapter ___: Wiring and Protection",
			"single-digit needle blanks the chapter number"],
		["Use 2 in. of slack", "2", "Use ___ in. of slack", "single-digit needle"],
		["three-phase motor", "3", "___-phase motor", "digit answer redacts via the 'three' candidate"],
		# Digit-inside-larger-number: "25" must NOT eat the "25" inside "125".
		["A 125-volt circuit requires 25 amps.", "25",
			"A 125-volt circuit requires ___ amps.", "125-volt false positive (headline regression)"],
		["A 20-ampere circuit", "20", "A ___-ampere circuit", "'-' is a boundary, so 20 still blanks"],
		["Rated 5-15A duplex receptacle", "5", "Rated ___-15A duplex receptacle", "digit after '-' blanks"],
		# "two" <-> "2" word mapping, both directions.
		["two-wire circuit", "two", "___-wire circuit", "word answer redacts its own word form"],
		["A two-wire circuit needs two hot conductors", "2",
			"A ___-wire circuit needs ___ hot conductors", "digit answer 2 redacts digit AND 'two'"],
		# Multi-word answers: every occurrence, not just the first.
		["Strain relief devices are required", "strain relief devices", "___ are required", "multi-word answer"],
		["Motor and controller are required by Motor and controller rules.", "motor and controller",
			"___ are required by ___ rules.", "multi-word answer blanks EVERY occurrence"],
		["both (b) and (c)", "Both (b) and (c)", "___", "answer with parens"],
		# Spans with punctuation and units.
		["See 240.4(D) for the breaker", "240.4(D)", "See ___ for the breaker", "parenthesised section span"],
		["The maximum is 1,200 volts-ampere", "1200", "The maximum is ___ volts-ampere", "comma-formatted twin"],
		["1/2 inch knockout", "1/2 inch", "___ knockout", "fractional-inch answer"],
		["MC cable is permitted", "MC", "___ cable is permitted", "two-letter needle is safe"],
		# No-ops.
		["Nothing relevant here at all.", "12", "Nothing relevant here at all.", "no occurrence -> no-op"],
		["Table ___ lists 30 amps.", "30", "Table ___ lists ___ amps.", "an existing blank is left alone"],
	]
	for row in rows:
		var text: String = row[0]
		var ans: String = row[1]
		var want: String = row[2]
		var why: String = row[3]
		t.eq(AEG.redact_answer_spans(text, ans), want, "redact(%s) [%s]" % [text, why])
		t.no_leak(AEG.redact_answer_spans(text, ans), ans, "table row: %s" % why)


# --------------------------------------------------------------------------
# 2. Boundary rules -- the mechanism every regression above rides on
# --------------------------------------------------------------------------
func redact_boundaries() -> void:
	print("=== redact_answer_spans: boundaries ===")
	# A digit is a word char, so a digit glued to a LETTER is NOT a match.
	# (Over-blanking a section number is safe; under-blanking leaks.)
	var cases := [
		["Model 125 and 125 volts", "125", "Model ___ and ___ volts", "two standalone hits both blank"],
		["125", "125", "___", "whole string is the answer"],
		["25,000 feet", "25", "___,000 feet", "',' is not a word char -> boundary ok"],
		["125.4", "125", "___.4", "'.' is not a word char -> boundary ok"],
		["(25)", "25", "(___)", "parentheses are boundaries"],
		["#25", "25", "#___", "hash is a boundary"],
		["125V", "125", "125V", "'V' is a word char on the right -> NO match"],
		["V125", "125", "V125", "'V' is a word char on the left -> NO match"],
		["A125B", "125", "A125B", "word chars on both sides -> NO match"],
		["x25", "25", "x25", "word char on the left -> NO match"],
		["25x", "25", "25x", "word char on the right -> NO match"],
	]
	for row in cases:
		var text: String = row[0]
		var ans: String = row[1]
		var want: String = row[2]
		var why: String = row[3]
		t.eq(AEG.redact_answer_spans(text, ans), want, "boundary(%s) [%s]" % [text, why])

	# A "." inside a needle is matched literally, not as a wildcard.
	t.eq(AEG.redact_answer_spans("See 408.18(C) here.", "408.18(C)"), "See ___ here.", "literal needle with dots+paren")
	t.eq(AEG.redact_answer_spans("Table 220.55 exists.", "220.55"), "Table ___ exists.", "dotted needle")

	# Degenerate inputs must be inert.
	t.eq(AEG.redact_answer_spans("Unrelated text.", ""), "Unrelated text.", "empty answer is inert")
	t.eq(AEG.redact_answer_spans("Unrelated text.", "   "), "Unrelated text.", "whitespace answer is inert")
	t.eq(AEG.redact_answer_spans("", "25"), "", "empty text stays empty")

	# Over-redaction of a dotted section number is CONSERVATIVE and intended:
	# answer "4" blanks the "4" in "240.4" because '.' is a boundary.
	t.eq(AEG.redact_answer_spans("Rated 240.4(D) here.", "4"), "Rated 240.___(D) here.",
		"a digit inside a dotted section is still blanked (over-blank, never leaks)")


# --------------------------------------------------------------------------
# 3. Word answers (multi-word, stop words, case, adjacency)
# --------------------------------------------------------------------------
func redact_word_answers() -> void:
	print("=== redact_answer_spans: word answers ===")
	var cases := [
		["The front of the equipment", "front", "The ___ of the equipment", "single word"],
		["FRONT and front and Front", "front", "___ and ___ and ___", "case-insensitive, all occurrences"],
		["all of these are correct", "all of these", "___ are correct", "answer containing stop words"],
		["strain relief devices required", "Strain Relief Devices", "___ required", "case-insensitive answer"],
		["only to Article 393", "only to Article 393", "___", "answer with an article reference"],
		["the front right side", "front", "the ___ right side", "neighbouring word survives"],
		["(front)", "front", "(___)", "punctuation preserved around a blank"],
	]
	for row in cases:
		var text: String = row[0]
		var ans: String = row[1]
		var want: String = row[2]
		t.eq(AEG.redact_answer_spans(text, ans), want, "word(%s) ans=%s" % [text, ans])
		t.no_leak(AEG.redact_answer_spans(text, ans), ans, "word answer %s" % ans)


# --------------------------------------------------------------------------
# 4. Numeric answers, unit variants, and their formatted twins
# --------------------------------------------------------------------------
func redact_numeric_answers() -> void:
	print("=== redact_answer_spans: numeric answers ===")
	var cases := [
		["A 25 ampere circuit", "25", "A ___ ampere circuit", "bare int"],
		["25 A or 25 amps here", "25", "___ A or ___ amps here", "both unit spellings share the digit"],
		["240 volts is the service", "240 V", "___ is the service", "twin candidate '240 volts' blanks both words"],
		["Rated 240 V here", "240 volts", "Rated ___ here", "twin candidate '240 V' blanks the abbreviation"],
		["12 AWG copper", "12 AWG", "___ copper", "answer carries its own unit"],
		["The size is 12 awg", "12 AWG", "The size is ___", "unit matching is case-insensitive"],
		["20 kVA required", "20", "___ kVA required", "kVA is not confused with the answer"],
		["1,200 volts max", "1,200", "___ volts max", "comma form"],
		["1200 volts max", "1,200", "___ volts max", "comma-form answer blanks the plain digits"],
		["Conductor #6 cu", "#6", "Conductor ___ cu", "leading hash form"],
		["Conductor 6 cu", "#6", "Conductor ___ cu", "'#6' answer blanks the bare number"],
		["3/8 inch hole", "3/8 inch", "___ hole", "fraction answer"],
		["5 feet of run", "5'", "___ of run", "foot answer's '5 feet' twin is blanked too"],
		["A 5' run is 60 inches", "5'", "A ___ run is ___", "both the foot mark and its inch twin are blanked"],
	]
	for row in cases:
		var text: String = row[0]
		var ans: String = row[1]
		var want: String = row[2]
		var why: String = row[3]
		t.eq(AEG.redact_answer_spans(text, ans), want, "numeric(%s) ans=%s [%s]" % [text, ans, why])
		t.no_leak(AEG.redact_answer_spans(text, ans), ans, "numeric answer %s" % ans)

	# A ONE-LETTER answer is deliberately never redacted: blanking every "a"
	# would shred the text. All 1-char answers in the bank are DIGITS, which
	# take the length<2 digit path instead, so this stays safe in practice.
	t.eq(AEG.redact_answer_spans("Class A wiring methods", "A"), "Class A wiring methods",
		"a bare letter answer is never redacted (documented trade-off)")
	t.eq(AEG.redact_answer_spans("Chapter 3 wiring", "3"), "Chapter ___ wiring", "a bare digit answer IS redacted")


# --------------------------------------------------------------------------
# 5. Every known variant of an answer must be redacted when it appears
# --------------------------------------------------------------------------
func redact_variants_covered() -> void:
	print("=== redact_answer_spans: variant coverage ===")
	for ans in ["25", "12 AWG", "240 V", "5'", "1,200", "2 1/2 feet", "30 in.", "MC", "three", "20 amps"]:
		var cands: Array = UM.answer_match_candidates(ans)
		t.check(not cands.is_empty(), "answer_match_candidates(%s) is non-empty" % ans)
		for c in cands:
			var needle := str(c)
			if needle.strip_edges().length() < 2:
				continue
			var probe := "pre %s post" % needle
			var out: String = AEG.redact_answer_spans(probe, ans)
			t.check(out.contains("___"), "variant %s of answer %s is redacted (got %s)" % [needle, ans, out])
			t.check(not out.contains(needle), "variant %s of answer %s is gone (got %s)" % [needle, ans, out])


# --------------------------------------------------------------------------
# 6. Redaction must be safe to re-run (main.gd re-renders, and the gist loop
#    loops up to 8 times over the same string)
# --------------------------------------------------------------------------
func redact_idempotence() -> void:
	print("=== redact_answer_spans: idempotence / stability ===")
	var pairs := [
		["A 125-volt circuit requires 25 amps.", "25"],
		["Chapter 3: Wiring and Protection", "3"],
		["Motor and controller are required by Motor and controller rules.", "motor and controller"],
		["Table 220.55 Column C, note 1 applies to 12 kW.", "12 kW"],
	]
	for pair in pairs:
		var text: String = pair[0]
		var ans: String = pair[1]
		var once: String = AEG.redact_answer_spans(text, ans)
		t.eq(AEG.redact_answer_spans(once, ans), once, "redaction is idempotent for %s" % text)
		t.no_leak(once, ans, "idempotence %s" % ans)
		# A blanked marker must never be mistaken for an answer on the 2nd pass.
		t.eq(AEG.redact_answer_spans(once, ans).count("___"), once.count("___"), "blank count is stable for %s" % text)
	# The "___ ___" collapse must not eat a legitimate adjacent pair of blanks.
	t.eq(AEG.redact_answer_spans("20 amps and 30 amps", "30"), "20 amps and ___ amps", "no over-eager ___ collapse")


# --------------------------------------------------------------------------
# 7. find_match_in -- the shared leak/match primitive
# --------------------------------------------------------------------------
func match_in_semantics() -> void:
	print("=== find_match_in ===")
	var rows := [
		["The 25 ampere circuit", "25", true, "plain numeric"],
		["A 125-volt system", "25", false, "REGRESSION: digit inside a larger number must not match"],
		["3-wire circuit", "3", true, "single digit"],
		["Chapter 3 of the NEC", "3", true, "single digit mid-text"],
		["Class III hazardous", "3", false, "REGRESSION: Roman numeral III is not the digit 3"],
		["Nothing here", "5", false, "no occurrence"],
		["The front door", "front", true, "word"],
		["", "5", false, "empty text"],
		["A 125-volt system", "", false, "empty answer"],
	]
	for row in rows:
		var text: String = row[0]
		var ans: String = row[1]
		var want: bool = row[2]
		var why: String = row[3]
		t.eq(not AEG.find_match_in(text, ans).is_empty(), want, "find_match_in(%s, %s) [%s]" % [text, ans, why])
		var hit: Dictionary = AEG.find_match_in(text, ans)
		if want and not hit.is_empty():
			var start: int = int(hit["start"])
			var length: int = int(hit["length"])
			var slice: String = text.substr(start, length)
			t.eq(slice.to_lower(), ans.strip_edges().to_lower(), "span points at the answer (%s in %s)" % [ans, text])
			var before: String = text.substr(start - 1, 1) if start > 0 else ""
			var after: String = text.substr(start + length, 1) if start + length < text.length() else ""
			t.check(not AEG._is_word_char(before), "left boundary clean for %s in %s" % [ans, text])
			t.check(not AEG._is_word_char(after), "right boundary clean for %s in %s" % [ans, text])

	# A digit glued to another number by "/", "." or "," is part of that number.
	t.eq(AEG.find_match_in("not more than 1.7 m (5 1/2 ft) above the floor", "two").is_empty(), true,
		"'two' does not match the 2 of 5 1/2 (final-exam-#1-022)")
	t.eq(AEG.find_match_in("rated 3.7 m", "7").is_empty(), true, "7 does not match the tail of 3.7")
	t.eq(AEG.find_match_in("up to 1,200 VA", "200").is_empty(), true, "200 does not match the tail of 1,200")
	# With a prompt, the occurrence next to the blank's words wins; without one,
	# the first occurrence still does.
	var two_tens := "Solid aluminum conductors 8, 10, and 12 AWG. The copper shall form a minimum 10 percent of the cross-sectional area."
	var tens_prompt := "Copper-clad aluminum: the copper shall form a minimum of ___ percent of the cross-sectional area."
	t.eq(int(AEG.find_match_in(two_tens, "10", tens_prompt).get("start", -1)), two_tens.rfind("10"),
		"the prompt's blank context picks 'minimum 10 percent' (open-book-exam-#10-015)")
	t.eq(int(AEG.find_match_in(two_tens, "10").get("start", -1)), two_tens.find("10"),
		"without a prompt the first occurrence wins, as before")
	var negated := "Boxes shall be required at splices. Boxes shall not be required for splices in raceways."
	t.eq(int(AEG.find_match_in(negated, "be required", "Boxes shall ___ at splices.").get("start", -1)),
		negated.find("be required"), "an occurrence after 'not' loses when the stem is not negated")

	# find_match_in and redact_answer_spans must agree.
	for pair in [["A 125-volt circuit requires 25 amps.", "25"], ["Chapter 3: Wiring", "3"],
			["strain relief devices", "strain relief devices"], ["Class III", "3"], ["front", "front"]]:
		var text2: String = pair[0]
		var ans2: String = pair[1]
		t.check(AEG.find_match_in(AEG.redact_answer_spans(text2, ans2), ans2).is_empty(),
			"redact then match agree for %s/%s" % [text2, ans2])

	# answer_sentence must return the sentence that CONTAINS the answer.
	t.eq(AEG.answer_sentence("Marked on the front. Unrelated trailing text.", "front"),
		"Marked on the front.", "answer_sentence returns the answer-bearing sentence")
	t.eq(AEG.answer_sentence("No match here at all.", "zzz"), "No match here at all.",
		"answer_sentence falls back to the body when nothing matches")
	t.eq(AEG.answer_sentence("", "front"), "", "answer_sentence of an empty body is empty")


# --------------------------------------------------------------------------
# 8. Bank-wide sweep: the real guarantee over every record
# --------------------------------------------------------------------------
func bank_wide_sweep() -> void:
	print("=== bank-wide leak sweep (every real record) ===")
	var prompt_hits: Array[String] = []
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/question_bank.json"))
	if not (parsed is Dictionary):
		t.check(false, "question_bank.json parses to a Dictionary")
		return
	var recs: Array = (parsed as Dictionary).get("records", [])
	t.eq(recs.size(), int((parsed as Dictionary).get("playable", -1)), "bank has every declared record (%d)" % recs.size())
	t.check(RegEx.create_from_string("^[a-z0-9#-]+-\\d{3}$").search(field(recs[0], "id")) != null,
		"bank read is NOT vacuous (first record has a record id: %s)" % field(recs[0], "id"))
	t.check(field(recs[0], "reference_text").length() > 20, "reference_text read is not a stub")

	# Exactly the fields main.gd renders BEFORE the learner answers.
	var pre_answer_fields := ["reference_text", "formula", "worked", "gist", "tip_short",
		"info_tip", "lookup_summary", "article", "article_title"]
	var leaks := 0
	var leak_log: Array[String] = []
	var with_answer := 0
	var one_char_letters := 0

	for rec_v in recs:
		var rec: Dictionary = rec_v
		var ci: int = int(rec.get("correct_index", -1))
		var answers: Array = rec.get("answers", [])
		if ci < 0 or ci >= answers.size():
			continue
		with_answer += 1
		var ans: String = str(answers[ci])
		if ans.strip_edges() == "":
			continue
		# Track the 1-char case: letters are not redacted, digits are.
		if ans.strip_edges().length() == 1 and not ans.strip_edges().is_valid_int():
			one_char_letters += 1
		for f in pre_answer_fields:
			var src: String = field(rec, f)
			if src.strip_edges() == "":
				continue
			var out: String = AEG.redact_answer_spans(src, ans)
			if not AEG.find_match_in(out, ans).is_empty():
				leaks += 1
				if leak_log.size() < 20:
					leak_log.append("%s/%s ans=%s" % [field(rec, "id"), f, ans])
		# The PROMPT is deliberately NOT redacted by main.gd (it is the question
		# itself and must read verbatim), so it is checked against an allowlist of
		# COINCIDENTAL tokens instead of being redacted-then-scanned. Each entry is
		# a token the NEC code itself puts in the question while the real answer is
		# something else; blanking these would break the question. Any NEW prompt
		# hit still fails, so this catches a genuine new leak.
	for rec_v in recs:
		var rec3: Dictionary = rec_v
		var ci3: int = int(rec3.get("correct_index", -1))
		var answers3: Array = rec3.get("answers", [])
		if ci3 < 0 or ci3 >= answers3.size():
			continue
		var ans3: String = str(answers3[ci3])
		var hit3: Dictionary = AEG.find_match_in(field(rec3, "prompt"), ans3)
		if hit3.is_empty():
			continue
		var s3: int = int(hit3["start"])
		var key3 := "%s|%s" % [field(rec3, "id"), field(rec3, "prompt").substr(s3, int(hit3["length"]))]
		if not prompt_allowlist.has(key3):
			prompt_hits.append(key3)

	t.eq(with_answer, recs.size(), "every bank record has a resolvable correct answer")
	t.eq(one_char_letters, 0, "no unredactable single-LETTER answers exist in the bank")
	t.eq(leaks, 0, "no answer survives redaction in any pre-answer field (leaks: %s)" % str(leak_log))
	t.eq(prompt_hits, [], "no UNEXPECTED answer token in any prompt (new: %s)" % str(prompt_hits))
	print("  swept %d records x %d pre-answer fields + %d prompts" % [with_answer, pre_answer_fields.size(), with_answer])

	# Every teardown (post-answer) line must state the answer.
	var no_teach := 0
	for rec_v in recs:
		var rec2: Dictionary = rec_v
		var ci2: int = int(rec2.get("correct_index", -1))
		var answers2: Array = rec2.get("answers", [])
		if ci2 < 0 or ci2 >= answers2.size():
			continue
		var ans2: String = str(answers2[ci2])
		if ans2.strip_edges() == "":
			continue
		var lines: PackedStringArray = AEG.lesson_lines(rec2)
		if lines.is_empty():
			no_teach += 1
			continue
		var found := false
		for l in lines:
			if not AEG.find_match_in(l, ans2).is_empty():
				found = true
				break
		if not found:
			no_teach += 1
			if no_teach <= 10:
				print("  no-teach: %s ans=%s lines=%s" % [field(rec2, "id"), ans2, str(lines)])
	t.eq(no_teach, 0, "every record's lesson_lines state the answer")


# --------------------------------------------------------------------------
# 8b. Study figures before answering: no text left visible outside the
#     question's masks (labels, titles, section chips, notes) may say where
#     the answer is in the book (section, table or Part number; an Article
#     number alone may show) or carry one of the question's choices.
# --------------------------------------------------------------------------
const FIG_LOCATION := "(?<![\\w.])(?:90|\\d{3})\\.\\d+(?![\\d.]*\\s*(?i:%|\"|'|in\\b|inch|ft\\b|feet|foot|mm\\b|m\\b|v\\b|volt|a\\b|amp|kva|va\\b|kw\\b|w\\b|hz|ohm|deg))|\\b[Tt]ables?\\s+\\d|\\b[Pp]art\\s+[IVX]+\\b"
const FIG_BLAND := ["yes", "no", "true", "false", "never", "always", "same", "other", "none", "nec",
		"all of the above", "none of the above", "both", "either"]


static func _fig_words(s: String) -> String:
	var out := PackedStringArray()
	for m in RegEx.create_from_string("[a-z0-9]+").search_all(s.to_lower()):
		out.append(m.get_string())
	return " ".join(out)


static func _fig_covered(box: Rect2, masks: Array) -> bool:
	for mk in masks:
		var r: Array = mk.get("rect", [0, 0, 0, 0])
		var mr := Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
		if mr.grow(0.0001).has_point(box.get_center()) and box.intersection(mr).get_area() >= 0.6 * box.get_area():
			return true
	return false


## Labels of `labels` ([text, x, y, w, h]) the record would see before answering
## that name a section/table/Part or contain one of its (non-numeric) choices.
static func figure_text_leaks(rec: Dictionary, labels: Array, masks: Array) -> PackedStringArray:
	var out := PackedStringArray()
	var loc := RegEx.create_from_string(FIG_LOCATION)
	var digits := RegEx.create_from_string("\\d")
	var stem := " " + _fig_words(str(rec.get("prompt", ""))) + " "
	var choices := PackedStringArray()
	for a in rec.get("answers", []):
		var p := _fig_words(str(a))
		if p.length() >= 3 and digits.search(p) == null and not p in FIG_BLAND and not stem.contains(" " + p + " "):
			choices.append(p)
	for lab in labels:
		var box := Rect2(float(lab[1]), float(lab[2]), float(lab[3]), float(lab[4]))
		if _fig_covered(box, masks):
			continue
		var text := str(lab[0])
		var low := " " + _fig_words(text) + " "
		var m := loc.search(text)
		if m != null:
			out.append("'%s' names %s" % [text, m.get_string()])
		for p in choices:
			if low.contains(" " + p + " "):
				out.append("'%s' shows the choice '%s'" % [text, p])
	return out


func figure_text_sweep() -> void:
	print("=== study figures: no section number or choice visible before answering ===")
	var rd := func(p: String): return JSON.parse_string(FileAccess.get_file_as_string(p))
	var figs = rd.call("res://assets/diagrams/nec/figures.json")
	var masks = rd.call("res://data/diagram_masks.json")
	var labels = rd.call("res://docs/diagrams/labels.json")
	var bank = rd.call("res://data/question_bank.json")
	t.check(figs is Dictionary and masks is Dictionary and labels is Dictionary and bank is Dictionary,
			"figure map, masks, labels and bank parse")
	if not (figs is Dictionary and masks is Dictionary and labels is Dictionary and bank is Dictionary):
		return
	var by_id := {}
	for r in bank.get("records", []):
		by_id[str(r.get("id", ""))] = r
	var checked := 0
	var bad := PackedStringArray()
	for rid in figs:
		var e: Dictionary = figs[rid]
		if str(e.get("when", "")) != "before" or e.has("pdf"):
			continue
		checked += 1
		var file := str(e.get("file", "")).get_file()
		var ms: Array = masks.get("records", {}).get(rid, {}).get("masks", [])
		for hit in figure_text_leaks(by_id.get(rid, {}), labels.get(file, []), ms):
			bad.append("%s (%s): %s" % [rid, file, hit])
	print("  %d pre-answer figure records swept" % checked)
	t.check(checked > 200, "every pre-answer study figure is swept (%d)" % checked)
	for b in bad.slice(0, 40):
		t.check(false, b)
	t.check(bad.is_empty(), "no pre-answer figure text names a section/table/Part or shows a choice (%d found)" % bad.size())
	# The sweep must catch the 408.36(B) chip and a visible choice, and accept them masked.
	var rec := {"prompt": "Where a panelboard is supplied through a transformer, the OCPD shall be on the ___ side.",
			"answers": ["supply", "secondary", "high leg", "primary"], "correct_index": 1}
	var chip := [["NEC 408.36(B)", 0.78, 0.08, 0.2, 0.05]]
	t.check(not figure_text_leaks(rec, chip, []).is_empty(), "sweep catches a visible 'NEC 408.36(B)' chip")
	t.check(figure_text_leaks(rec, chip, [{"rect": [0.77, 0.07, 0.22, 0.08]}]).is_empty(), "sweep accepts the chip under a mask")
	for s in ["Table 310.16", "Part II", "Ex.: 240.21(C)(1)", "90.2"]:
		t.check(not figure_text_leaks(rec, [[s, 0.1, 0.1, 0.2, 0.05]], []).is_empty(), "sweep catches '%s'" % s)
	for s in ["Article 408", "12.5 ft", "155.5 A", "100 + 37.5 + 10", "480 V", "panelboard", "transformer"]:
		t.check(figure_text_leaks(rec, [[s, 0.1, 0.1, 0.2, 0.05]], []).is_empty(), "sweep lets '%s' show" % s)
	t.check(not figure_text_leaks(rec, [["on the secondary", 0.1, 0.1, 0.2, 0.05]], []).is_empty(), "sweep catches a choice word")


# --------------------------------------------------------------------------
# 9. CONFIRMED product defects, reproduced but not counted as failures.
#    Each is unreachable from today's bank, so they are recorded rather than
#    red. Fix one and promote it to a check() above.
# --------------------------------------------------------------------------
func known_defects() -> void:
	print("=== known defects (documented, not failures) ===")
	# A percent answer has NO word candidate, so the spelled-out form survives.
	# The percent-answer defect that used to be pinned here is FIXED: '83%' now
	# yields the candidates '83 percent' and 'eighty-three percent', so the
	# number is redacted wherever the reference text spells it. Asserted in
	# test_unit_matcher.gd (percent_form_candidates) and swept above.


func report() -> void:
	t.report()
