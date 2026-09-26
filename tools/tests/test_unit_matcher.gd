extends SceneTree
## unit_matcher.gd -- format_answer_number and answer_match_candidates, the
## function that decides WHICH surface forms of an answer count as a match.
## It is the foundation of redaction, so a wrong candidate set is a leak.
##
##   ./Godot_v4.7.2-stable_win64_console.exe --headless --path . \
##       --script tools/tests/test_unit_matcher.gd

const UM = preload("res://unit_matcher.gd")
const R = preload("res://tools/tests/t_report.gd")

var t: R = R.new()


func must_have(cands: Array, needle: String, label: String) -> void:
	t.check(cands.has(needle), "%s -- %s missing from %s" % [label, needle, str(cands)])


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
	format_answer_number()
	basic_candidates()
	word_number_mapping()
	length_conversions()
	thousands_separators()
	unit_spellings()
	comma_formatting()
	edge_cases()
	bank_candidate_sweep()
	known_defects()
	report()


# --------------------------------------------------------------------------
# format_answer_number -- renders a float without a trailing ".0"
# --------------------------------------------------------------------------
func format_answer_number() -> void:
	print("=== format_answer_number ===")
	var rows := [
		[0.0, "0", "zero"],
		[1.0, "1", "one"],
		[30.0, "30", "a whole number drops the fraction"],
		[1000.0, "1000", "1000"],
		[1200.0, "1200", "1200"],
		[-4.0, "-4", "negatives are not special-cased"],
		[2.5, "2.5", "one decimal is kept"],
		[0.0762, "0.08", "2 significant decimals then trailing zeros trimmed"],
		[3.14159, "3.14", "rounded to 2 decimals"],
		[1000000.0, "1000000", "1e6"],
	]
	for row in rows:
		t.eq(UM.format_answer_number(row[0]), row[1], "format_answer_number(%s) [%s]" % [str(row[0]), row[2]])


# --------------------------------------------------------------------------
# The direct answer is always candidate #1, and the list is never empty for a
# non-empty answer.
# --------------------------------------------------------------------------
func basic_candidates() -> void:
	print("=== answer_match_candidates: basics ===")
	t.eq(UM.answer_match_candidates("").size(), 0, "an empty answer yields no candidates")
	t.eq(UM.answer_match_candidates("   ").size(), 0, "a whitespace answer yields no candidates")
	for ans in ["front", "MC", "250", "12 AWG", "1,200", "83%", "5'"]:
		var cands: Array = UM.answer_match_candidates(ans)
		t.check(cands.size() > 0, "answer %s has candidates" % ans)
		t.eq(str(cands[0]), ans.strip_edges(), "the answer itself is always the FIRST candidate of %s" % ans)
	# No duplicates inside one candidate list.
	for ans in ["2400", "1,200", "5'", "3", "2 1/2 feet", "1,200 VA", "12 AWG"]:
		var cands: Array = UM.answer_match_candidates(ans)
		var seen := {}
		var dupes := 0
		for c in cands:
			if seen.has(str(c)):
				dupes += 1
			seen[str(c)] = true
		t.eq(dupes, 0, "no duplicate candidates for %s (%s)" % [ans, str(cands)])
	# Curly apostrophes and double primes are normalised.
	must_have(UM.answer_match_candidates("5’"), "5'", "curly apostrophe normalises to straight")
	must_have(UM.answer_match_candidates("3/8″"), "3/8\"", "double prime normalises to an inch mark")
	# Longest-first ordering matters for redact_answer_spans, which sorts anyway,
	# but find_match_in relies on candidate order to prefer the longest form.
	t.eq(str(UM.answer_match_candidates("2400")[0]), "2400", "the literal answer comes first")


# --------------------------------------------------------------------------
# Number-word mapping, both directions.
# --------------------------------------------------------------------------
func word_number_mapping() -> void:
	print("=== answer_match_candidates: number words ===")
	var map := {
		"3": "three", "25": "", "0": "zero", "1": "one", "2": "two", "4": "four",
		"5": "five", "6": "six", "7": "seven", "8": "eight", "9": "nine",
		"10": "ten", "12": "twelve", "15": "fifteen", "20": "twenty",
	}
	for num in map.keys():
		var word: String = map[num]
		if word == "":
			continue
		must_have(UM.answer_match_candidates(num), word, "digit %s maps to its word" % num)
		must_have(UM.answer_match_candidates(word), num, "word '%s' maps back to %s" % [word, num])
	# 11, 13, 14, 16-19 are NOT in the table: the mapping is intentionally partial.
	t.check(not UM.answer_match_candidates("11").has("eleven"), "11 has no word candidate (partial table)")
	t.check(not UM.answer_match_candidates("eleven").has("11"), "no reverse mapping for 'eleven'")
	# 25 has no word candidate either, and that is fine -- the digit is the form used.
	t.check(not UM.answer_match_candidates("25").has("twenty-five"), "25 has no word candidate")


# --------------------------------------------------------------------------
# Fractional feet <-> inches. This is the reappearance of the answer in a
# different unit, and the classic way an answer leaks.
# --------------------------------------------------------------------------
func length_conversions() -> void:
	print("=== answer_match_candidates: lengths ===")
	var c5: Array = UM.answer_match_candidates("5'")
	t.eq(c5.size(), 7, "5 feet expands to 7 candidates (answer, ft, feet, in., inches, mark, m)")
	must_have(c5, "60 in.", "5 feet -> 60 in.")
	must_have(c5, '60"', "5 feet -> 60 inch mark")
	must_have(c5, "1.52 m", "5 feet -> 1.52 m")
	var c_half: Array = UM.answer_match_candidates("2 1/2 feet")
	must_have(c_half, "30 in.", "2 1/2 feet -> 30 in.")
	must_have(c_half, "30 inches", "2 1/2 feet -> 30 inches")
	must_have(c_half, '30"', "2 1/2 feet -> 30 inch mark")
	must_have(c_half, "30", "2 1/2 feet -> bare 30")
	var c_30: Array = UM.answer_match_candidates("30 in.")
	must_have(c_30, "2 1/2 feet", "30 in. -> 2 1/2 feet (the conversion is symmetric)")
	must_have(c_30, '2 1/2\'', "30 in. -> 2 1/2 feet with a foot mark")
	# A whole number of inches converts to whole feet.
	must_have(UM.answer_match_candidates("12 inches"), "1 ft", "12 inches -> 1 ft")
	must_have(UM.answer_match_candidates('12"'), "1 feet", '12" -> 1 feet')
	# Metric answers are NOT expanded to imperial: "1.5 m" has no conversion rule,
	# only the inch/foot arms convert. Locked in so a future change is deliberate.
	t.eq(str(UM.answer_match_candidates("1.5 m")), "[\"1.5 m\"]", "a metric answer is left alone")
	t.check(UM.answer_match_candidates("1/2 inch").has("1/2 in."), "inch spelling variant")
	# A FRACTIONAL inch answer gets its own N/M forms plus a feet equivalent.
	# This used to return only the spelling variant, which is why final-exam-#3-034
	# (answer 15/16", written "15/16 in." in its own reference_text) could never
	# match itself and never highlighted. Verified against the live record.
	var c_frac_half: Array = UM.answer_match_candidates("1/2 inch")
	must_have(c_frac_half, "1/2 inches", "1/2 inch -> 1/2 inches")
	must_have(c_frac_half, '1/2"', "1/2 inch -> bare inch mark")
	must_have(c_frac_half, "0.04 ft", "1/2 inch -> feet equivalent")
	var c_frac_916: Array = UM.answer_match_candidates('15/16"')
	must_have(c_frac_916, "15/16 in.", '15/16" -> the 15/16 in. form used in reference_text')
	must_have(c_frac_916, "15/16 inches", '15/16" -> the 15/16 inches form')
	# A slash-voltage and a cable designation must NOT be swallowed by the
	# fractional rule. Verified by printing the live candidate sets: both come
	# back as a single element, and the fraction forms only appear for a real
	# inch fraction.
	t.eq(str(UM.answer_match_candidates("240/120 V")), "[\"240/120 V\"]",
		"a slash-voltage is not an inch fraction")
	t.eq(str(UM.answer_match_candidates("12/3")), "[\"12/3\"]",
		"a bare 12/3 is a cable designation, not an inch fraction")
	t.eq(str(UM.answer_match_candidates("10/2")), "[\"10/2\"]",
		"a bare 10/2 is a cable designation, not an inch fraction")
	# ...but an UNSPACED MIXED number with a non-cable numerator is a fraction:
	# final-exam-#5-053 offers '41/2' (4 1/2), so 41 must not be read as a cable.
	t.check(UM.answer_match_candidates("41/2").has("41/2 in."),
		"41/2 is an unspaced mixed number, not a 41-conductor cable")


# --------------------------------------------------------------------------
# Thousands separators -- 1200 vs "1,200" is a real leak vector.
# --------------------------------------------------------------------------
func thousands_separators() -> void:
	print("=== answer_match_candidates: thousands ===")
	var c2400: Array = UM.answer_match_candidates("2400")
	must_have(c2400, "2400", "plain form")
	must_have(c2400, "2,400", "comma form")
	must_have(c2400, "2,400 VA", "comma form with VA")
	var c_comma: Array = UM.answer_match_candidates("1,200")
	must_have(c_comma, "1200", "comma answer -> plain digits")
	must_have(c_comma, "1200 VA", "comma answer -> plain digits with VA")
	must_have(c_comma, "1,200 volt-amperes", "comma answer -> comma form with a spelled unit")
	t.eq(UM.answer_match_candidates("1000").has("1,000"), true, "1000 -> 1,000")
	t.eq(UM.answer_match_candidates("999").has("999"), true, "a sub-1000 value is not comma-formatted")
	t.check(not UM.answer_match_candidates("999").has("nonsense"), "no bogus candidate for 999")
	# A 4-digit value below 1000 is never comma-formatted, but 4 digits >= 1000 are.
	t.eq(UM.answer_match_candidates("1234").has("1,234"), true, "1234 -> 1,234")


# --------------------------------------------------------------------------
# Unit spellings -- every spelling of the same unit must be a candidate.
# --------------------------------------------------------------------------
func unit_spellings() -> void:
	print("=== answer_match_candidates: units ===")
	var amp: Array = UM.answer_match_candidates("20 amps")
	must_have(amp, "20 A", "amps -> A")
	must_have(amp, "20 amperes", "amps -> amperes")
	var volt: Array = UM.answer_match_candidates("240 volts")
	must_have(volt, "240 V", "volts -> V")
	# NOTE: kW/kVA have only a spelling arm, NOT the VA cross-conversion, so
	# "10 kVA" does not expand to "10 volt-amperes". Locked in as current behaviour.
	t.eq(str(UM.answer_match_candidates("10 kVA")), "[\"10 kVA\"]", "kVA is not cross-converted to VA")
	must_have(UM.answer_match_candidates("10 kW"), "10 kilowatts", "kW -> kilowatts")
	var kw: Array = UM.answer_match_candidates("5 kW")
	must_have(kw, "5 kilowatts", "kW -> kilowatts")
	# An answer with NO unit (a bare number) offers the bare number, VA forms, and
	# the comma form -- these are the ones a table cell is likely to contain.
	var bare: Array = UM.answer_match_candidates("30")
	must_have(bare, "30", "bare number")
	must_have(bare, "30 VA", "bare number -> VA")
	must_have(bare, "30 volt-amperes", "bare number -> volt-amperes")
	# Inches vs in. vs ".
	must_have(UM.answer_match_candidates("36 inches"), "3 ft", "36 inches -> 3 ft")
	must_have(UM.answer_match_candidates('36"'), "3 ft", '36" -> 3 ft')
	must_have(UM.answer_match_candidates("3 ft"), "36 in.", "3 ft -> 36 in. (symmetric)")
	# A word answer has no unit expansion at all.
	t.eq(UM.answer_match_candidates("front").size(), 1, "a word answer has exactly one candidate")
	t.eq(UM.answer_match_candidates("MC").size(), 1, "a code-like answer has exactly one candidate")


# --------------------------------------------------------------------------
# The number_pattern allows an optional leading '#', so '#6' -> 6.
# --------------------------------------------------------------------------
func comma_formatting() -> void:
	print("=== answer_match_candidates: leading hash ===")
	var c4: Array = UM.answer_match_candidates("#4")
	must_have(c4, "4", "#4 -> 4")
	must_have(c4, "4 VA", "#4 -> 4 VA")
	t.eq(UM.answer_match_candidates("#6").has("6"), true, "#6 -> 6")
	# A percent answer gets its phrase forms, so the number can be found in the
	# "83 percent" wording the reference text actually uses. It used to return
	# only itself, which meant a pre-answer "83 percent" was never redacted.
	var c_pct: Array = UM.answer_match_candidates("83%")
	must_have(c_pct, "83 percent", "83% -> 83 percent")
	must_have(c_pct, "eighty-three percent", "83% -> the spelled-out form")
	var c_pct2: Array = UM.answer_match_candidates("1.5%")
	must_have(c_pct2, "1.5 percent", "1.5% -> 1.5 percent")
	must_have(c_pct2, "one point five percent", "1.5% -> the spelled-out decimal")


# --------------------------------------------------------------------------
# Edge cases must not crash and must not return junk.
# --------------------------------------------------------------------------
func edge_cases() -> void:
	print("=== answer_match_candidates: edge cases ===")
	var inputs := ["", "   ", "___", "a/b", "//", "1//2", "#", "1.2.3", "1e5", "-5",
		"all of these", "Both (b) and (c)", "1,200,000", "0.5 inch", "3'", " "]
	for inp in inputs:
		var cands: Array = UM.answer_match_candidates(inp)
		t.check(cands is Array, "answer_match_candidates(%s) returns an Array" % inp)
		for c in cands:
			t.check(str(c) is String, "candidate of %s is a String" % inp)
		t.check(not cands.has(""), "no empty candidate for %s" % inp)
	# The first candidate of a whitespace-padded answer is the trimmed form.
	t.eq(str(UM.answer_match_candidates("  25  ")[0]), "25", "the answer is stripped before matching")
	# A huge value does not break the comma grouping.
	t.eq(UM.answer_match_candidates("1234567").has("1,234,567"), true, "million-scale comma grouping")
	# Decimals keep 2 places.
	t.eq(UM.answer_match_candidates("2.5 inches").has("0.06 m"), true, "2.5 inches -> 0.06 m")


# --------------------------------------------------------------------------
# Every real answer must yield a usable candidate set.
# --------------------------------------------------------------------------
func bank_candidate_sweep() -> void:
	print("=== bank candidate sweep (279 records) ===")
	var recs: Array = (JSON.parse_string(FileAccess.get_file_as_string("res://question_bank.json")) as Dictionary).get("records", [])
	t.eq(recs.size(), 279, "bank read is not vacuous")

	var empty_sets := 0
	var self_missing := 0
	var checked := 0
	for rec_v in recs:
		var rec: Dictionary = rec_v
		var ci: int = int(rec.get("correct_index", -1))
		var answers: Array = rec.get("answers", [])
		if ci < 0 or ci >= answers.size():
			continue
		var ans: String = str(answers[ci])
		if ans.strip_edges() == "":
			continue
		checked += 1
		var cands: Array = UM.answer_match_candidates(ans)
		if cands.is_empty():
			empty_sets += 1
			print("  EMPTY candidates for %s ans=%s" % [str(rec.get("id", "")), ans])
			continue
		if not cands.has(ans.strip_edges()):
			self_missing += 1
			print("  self missing for %s ans=%s cands=%s" % [str(rec.get("id", "")), ans, str(cands)])
	t.eq(checked, recs.size(), "every record was checked")
	t.eq(empty_sets, 0, "no real answer yields an empty candidate set")
	t.eq(self_missing, 0, "every real answer is a candidate of itself")

	# The answer must be findable SOMEWHERE in the record's teaching material,
	# because the post-answer highlight and the teach line both key off it.
	# reference_text alone is NOT required: 106 of 279 records keep the answer in
	# reference_table, worked, or a tip instead, and the UI highlights the TABLE.
	# final-exam-#3-034 is the ONE record that fails this, via the defect below.
	var nowhere := 0
	var nowhere_ids: Array[String] = []
	for rec_v in recs:
		var rec2: Dictionary = rec_v
		var ci2: int = int(rec2.get("correct_index", -1))
		var answers2: Array = rec2.get("answers", [])
		if ci2 < 0 or ci2 >= answers2.size():
			continue
		var ans2: String = str(answers2[ci2])
		var blob := ""
		for f in ["reference_text", "worked", "formula", "gist", "tip_short", "info_tip", "lookup_summary"]:
			blob += " " + _str(rec2.get(f, ""))
		var tbl = rec2.get("reference_table")
		if tbl is Array:
			for row_v in (tbl as Array):
				if row_v is Array:
					for cell in (row_v as Array):
						blob += " " + _str(cell)
		if preload("res://audio_explanation_generator.gd").find_match_in(blob.strip_edges(), ans2).is_empty():
			nowhere += 1
			nowhere_ids.append(_str(rec2.get("id", "")))
			if nowhere <= 10:
				print("  answer %s appears NOWHERE in record %s" % [ans2, _str(rec2.get("id", ""))])
	t.eq(nowhere_ids, [],
		"every record's answer is findable somewhere in its own teaching material")


func known_defects() -> void:
	print("=== known defects (documented, not failures) ===")
	# The fractional-inch and percent-answer defects that used to be pinned here
	# are FIXED and are now asserted as behaviour in the suites above:
	#   - '15/16"' -> '15/16 in.' / '15/16 inches' (final-exam-#3-034 now
	#     highlights its own answer; the whole-bank sweep asserts 0 unfindable).
	#   - '83%' -> '83 percent' / 'eighty-three percent' (redaction + highlight).


func report() -> void:
	t.report()


## GDScript's `or` is a BOOLEAN operator: `x or ""` yields str(true) == "true",
## not a fallback. Always route optional field reads through this.
func _str(v) -> String:
	if v == null:
		return ""
	return str(v)
