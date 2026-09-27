extends SceneTree
## speech_text.gd -- speakable() (the TTS normaliser) plus the segment planners
## and the delegation shims.
##
##   ./Godot_v4.7.2-stable_win64_console.exe --headless --path . \
##       --script tools/tests/test_speech_text.gd

const ST = preload("res://src/speech/speech_text.gd")
const R = preload("res://tools/tests/t_report.gd")

var t: R = R.new()


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
	speakable_inches()
	speakable_units()
	speakable_terms_and_sections()
	speakable_blanks_and_punct()
	spoken_fraction()
	normalize_spoken()
	segment_planners()
	teach_gate_ordering()
	delegation_shims()
	bank_speakable_sweep()
	known_defects()
	report()


# --------------------------------------------------------------------------
# speakable(): inches, feet, fractions
# --------------------------------------------------------------------------
func speakable_inches() -> void:
	print("=== speakable: inches and fractions ===")
	var rows := [
		# [input, expected, why]
		['5"', "5 inches", "bare inch mark"],
		['3/8"', "Three eighths of an inch", "fraction + inch mark"],
		['1/8"', "One eighth of an inch", "singular fraction stays singular"],
		['1 1/8"', "1 and one eighth inches", "mixed number with inch mark"],
		['1 1/4"', "1 and one quarter inches", "mixed quarter"],
		['3 5/16"', "3 and five sixteenths inches", "mixed sixteenth"],
		['10 3/4"', "10 and three quarters inches", "mixed three-quarters"],
		['1/2 inch', "Half inch", "spelled inch, no mark; trade size 'half inch' (one half is heard as 1.5)"],
		['1 1/2 inches', "1 and one half inches", "spelled plural inches"],
		['15 3/16 in.', "15 and three sixteenths inches", "'in.' abbreviation"],
		['1/2-inch RNC', "Half inch R N C", "hyphenated adjective read as a trade size; RNC is spelled"],
		['1-1/4" knockout', "1 and one quarter inches knockout", "hyphenated mixed number reads exactly like the spaced form"],
		['1 1/16"', "1 and one sixteenth inches", "sixteenths"],
		['5 5/8"', "5 and five eighths inches", "eighths"],
		['3 5/8"', "3 and five eighths inches", "eighths with whole"],
		['1 1/4" knockout', "1 and one quarter inches knockout", "spaced form (the correct one)"],
		['240/120 V', "240 slash 120 volts", "slash-voltage reads as 'slash', not a fraction"],
		['3 1/2', "3 and one half", "mixed number with no unit"],
	]
	for row in rows:
		t.eq(ST.speakable(row[0]), row[1], "speakable(%s) [%s]" % [row[0], row[2]])


# --------------------------------------------------------------------------
# speakable(): electrical units
# --------------------------------------------------------------------------
func speakable_units() -> void:
	print("=== speakable: units ===")
	var rows := [
		["240V", "240 volts", "V"],
		["20 A", "20 amps", "A"],
		["10 kVA", "10 kilovolt amperes", "kVA"],
		["2400 VA", "2400 volt amperes", "VA"],
		["1.5 kW", "1.5 kilowatts", "kW"],
		["3.5 V", "3.5 volts", "decimal volts"],
		["8000 mA", "8000 milliamps", "mA is distinct from A"],
		["300 mA", "300 milliamps", "mA (the A rule must not win)"],
		["20A receptacle", "20 amp receptacle", "no space before A; singular as an adjective"],
		["60 Hz", "60 hertz", "Hz"],
		["10 mm", "10 millimeters", "mm"],
		["40°C", "40 degrees Celsius", "deg C"],
		["75°F", "75 degrees Fahrenheit", "deg F"],
		["8 AWG 75°C", "8 A W G 75 degrees Celsius", "combined"],
		["0.5 mA", "0.5 milliamps", "decimal mA"],
		["1,200 volts", "1,200 volts", "thousands separator is left for the voice"],
		["2 x 30A", "2 times 30 amps", "' x ' multiplication"],
		["kcmil", "Thousand circular mil", "kcmil"],
		["Kcmil", "Thousand circular mil", "capitalised kcmil"],
		["12 AWG", "12 A W G", "AWG is spelled, the way electricians say it"],
		["16 AWG", "16 A W G", "AWG with a double-digit size"],
		["#6 AWG", "Number 6 A W G", "hash becomes 'number'"],
		["No. 6", "Number 6", "'No.' abbreviation"],
		["12/3 and 10/2", "12 slash 3 and 10 slash 2", "cable designations are read as conductor counts, not fractions"],
	]
	for row in rows:
		t.eq(ST.speakable(row[0]), row[1], "speakable(%s) [%s]" % [row[0], row[2]])


# --------------------------------------------------------------------------
# speakable(): jargon expansions, NEC section references, Roman numerals
# --------------------------------------------------------------------------
func speakable_terms_and_sections() -> void:
	print("=== speakable: terms, sections, Roman numerals ===")
	var rows := [
		["GFCI receptacle", "G F C I receptacle", "GFCI is spelled"],
		["AFCI", "A F C I", "AFCI is spelled"],
		["EMT", "E M T", "EMT is spelled"],
		["PVC", "P V C", "PVC is letter-spaced"],
		["NEC", "N E C", "NEC is letter-spaced"],
		["OCPD", "Overcurrent protective device", "OCPD"],
		["EGC", "Equipment grounding conductor", "EGC"],
		["GEC", "Grounding electrode conductor", "GEC"],
		["AHJ", "Authority having jurisdiction", "AHJ"],
		["1 HP", "1 horsepower", "HP"],
		["408.18(C) Connections", "Section 408 point 18, paragraph C Connections", "section reference"],
		["240.4(D)(5)", "Section 240 point 4, paragraph D, item 5", "nested section reference"],
		["Table 210.8", "Table 210 point 8", "a table number reads its decimal as point N"],
		["Article 210.8", "Article 210 point 8", "an article-prefixed decimal is a reference too"],
		["THHN wire", "T H H N, wire", "conductor type spelled out, with a pause so the N stays a letter"],
		["12 AWG THHN", "12 A W G T H H N", "gauge + type"],
		["12/3 cable", "12 slash 3 cable", "cable designation in context"],
		["1/3 the ampere rating", "One third the ampere rating", "a REAL fraction with a small numerator is still a fraction"],
		["15/16 in.", "Fifteen sixteenths of an inch", "a real fraction with a large numerator is still a fraction"],
		["1/0 and 2/0", "One aught and two aught", "aught sizes"],
		["3/0 and 4/0", "Three aught and four aught", "aught sizes"],
		["CO/ALR", "C O A L R", "CO/ALR is spelled"],
		["VIII", "8", "multi-character Roman numerals resolve, longest form first"],
		["XII", "12", "twelve is not 'X2'"],
		["XIII", "13", "thirteen is not 'X3'"],
		["W = E x I", "W equals E times I", "a bare 'I' in Ohm's law is the current, not a Roman numeral"],
		["Class III locations", "Class 3 locations", "Roman III (the common case, correct)"],
		["Diagram III", "Diagram 3", "Roman III in a diagram label"],
		["Class I and Class II", "Class 1 and Class 2", "Roman I and II"],
		["5'", "5 feet", "a bare foot mark becomes 'feet' (no more literal apostrophe)"],
		["4'", "4 feet", "foot mark with a single digit"],
		["12'", "12 feet", "foot mark with a double digit"],
		["5'9\"", "5 feet 9 inches", "a height reads as feet AND inches"],
		["the 5's worth of current", "The 5's worth of current", "a possessive keeps its apostrophe and is not a foot mark"],
		["R_total = R / n", "R total equals R divided by n", "a formula subscript is spoken as a word, not an underscore"],
		["sq. ft.", "Square feet", "square feet"],
		["sq. in.", "Square inches", "square inches"],
		["cu. in.", "Cubic inches", "cubic inches"],
		["CU/AL", "Copper or aluminum", "conductor material"],
		["cu/al", "Copper or aluminum", "lowercase material, capitalised at the end"],
		["a/an", "A or an", "a/an"],
		["and/or", "And or", "and/or"],
		["under/over", "Under or over", "generic word slash reads as 'or'"],
	]
	for row in rows:
		t.eq(ST.speakable(row[0]), row[1], "speakable(%s) [%s]" % [row[0], row[2]])


# --------------------------------------------------------------------------
# speakable(): blanks, symbols, em-dashes
# --------------------------------------------------------------------------
func speakable_blanks_and_punct() -> void:
	print("=== speakable: blanks and symbols ===")
	var rows := [
		["a____at the wall", "A blank at the wall", "a 4-underscore run collapses to one 'blank'"],
		["Article__", "Which Article", "'Article__'"],
		["Table ___", "Which Table", "'Table ___'"],
		["Table __", "Which Table", "'Table __'"],
		["Article __", "Which Article", "'Article __' (spaced form)"],
		["Section ___", "Which Section", "'Section ___'"],
		["— dash", "Dash", "em dash becomes a comma"],
		["– dash", "To dash", "en dash becomes 'to'"],
		["→ arrow", "So arrow", "arrow becomes 'so'"],
		["÷ × √ ≈", "Divided by times square root of is about", "math symbols"],
		["Ω 5", "Ohms 5", "ohm sign"],
		["¢ 5", "Cents 5", "cent sign"],
		["½ ½", "One half one half", "a standalone vulgar half has no leading and"],
		["¼", "One quarter", "vulgar fraction quarters"],
		["¾", "Three quarters", "vulgar fraction three-quarters"],
		["srating", "Stating", "typo guard"],
		["...end", "End", "a leading ellipsis is dropped"],
		["a....b", "A.b", "repeated periods collapse"],
		["", "", "empty stays empty"],
		["   ", "", "whitespace becomes empty"],
	]
	for row in rows:
		t.eq(ST.speakable(row[0]), row[1], "speakable(%s) [%s]" % [row[0], row[2]])

	# The first character is always upper-cased.
	t.eq(ST.speakable("front of the box"), "Front of the box", "leading lowercase is capitalised")
	t.eq(ST.speakable("12 AWG"), "12 A W G", "a leading digit is left alone")
	# Whitespace is collapsed and edges trimmed.
	t.check(ST.speakable("  a   b  ") == "A b", "surrounding and doubled spaces collapse")
	# smart quotes become plain quotes, which are then stripped entirely.
	t.eq(ST.speakable("the “front”"), "The front", "curly double quotes normalise then drop")
	t.check(not ST.speakable("“x”").contains("“"), "no curly quotes survive")


# --------------------------------------------------------------------------
# spoken_fraction
# --------------------------------------------------------------------------
func spoken_fraction() -> void:
	print("=== spoken_fraction ===")
	var rows := [
		["1", "2", "one half", "singular half"],
		["3", "8", "three eighths", "eighths"],
		["5", "16", "five sixteenths", "sixteenths"],
		["1", "1", "1 over 1", "denominator 1 falls back to 'over'"],
		["7", "9", "7 over 9", "unlisted denominator falls back to 'over'"],
		["3", "32", "three thirty-seconds", "thirty-seconds"],
		["1", "64", "one sixty-fourth", "sixty-fourth"],
		["1", "3", "one third", "third"],
		["1", "4", "one quarter", "quarter"],
		["1", "8", "one eighth", "eighth"],
		["1", "16", "one sixteenth", "sixteenth"],
		["2", "2", "two halves", "plural half (word form via num_words)"],
		["2", "3", "two thirds", "plural third"],
		["2", "4", "two quarters", "plural quarter (word form)"],
		["2", "8", "two eighths", "plural eighth (word form)"],
		["2", "16", "two sixteenths", "plural sixteenth (word form)"],
		["2", "32", "two thirty-seconds", "plural thirty-second"],
		["2", "64", "two sixty-fourths", "plural sixty-fourth (word form)"],
	]
	for row in rows:
		t.eq(ST.spoken_fraction(row[0], row[1]), row[2], "spoken_fraction(%s/%s) [%s]" % [row[0], row[1], row[3]])


# --------------------------------------------------------------------------
# _normalize_spoken -- drives teach-segment dedup
# --------------------------------------------------------------------------
func normalize_spoken() -> void:
	print("=== _normalize_spoken ===")
	var rows := [
		["Answer B, 5'.", "answer b 5", "punctuation and apostrophe become spaces"],
		["  12 AWG  ", "12 awg", "trim + lowercase"],
		["A & B", "a b", "ampersand becomes a space"],
		["Front!  ", "front", "exclamation stripped"],
		["", "", "empty stays empty"],
		["!!!", "", "punctuation-only collapses to empty"],
	]
	for row in rows:
		t.eq(ST._normalize_spoken(row[0]), row[1], "normalize_spoken(%s) [%s]" % [row[0], row[2]])


# --------------------------------------------------------------------------
# spoken_segments -- the PRE-ANSWER half of the plan
# --------------------------------------------------------------------------
func segment_planners() -> void:
	print("=== spoken_segments / speech_plan ===")
	var rec := {
		"prompt": "The demand load is ___ kW.",
		"answers": ["8 kW", "8.4 kW", "8.8 kW", "12 kW"], "correct_index": 3,
		"reference_text": "220.53 Demand Load\nFor a range over 12 kW use column c of table 220.55.",
		"formula": "", "worked": "",
	}
	var segs: Array = ST.spoken_segments(rec)
	t.eq(segs.size(), 9, "one stem + four choices, each a letter line then its text")
	t.has(str(segs[0].get("text", "")), "The demand load is", "the stem is first")
	t.has(str(segs[0].get("text", "")), "blank", "a prompt blank is spoken as 'blank'")
	t.has(str(segs[0].get("text", "")), ".", "a stem without terminal punctuation gets a period")
	t.eq(int(segs[0].get("choice", -1)), -1, "the stem is not tied to a choice")
	for i in 4:
		for k in [1 + 2 * i, 2 + 2 * i]:
			t.eq(int(segs[k].get("choice", -99)), i, "segment %d is tied to choice %d" % [k, i])
			t.check(bool(segs[k].get("teach", true)) == false, "segment %d is NOT a teach clip" % k)
	t.eq(str(segs[7].get("text", "")), "Option D.", "the fourth choice is lettered D, in its own clip")
	t.eq(str(segs[8].get("text", "")), "12 kilowatts.", "the choice text carries no letter")

	# A stem that already ends in ? or . is not given a second terminator.
	t.eq(str(ST.spoken_segments({"prompt": "What is it?", "answers": ["a"], "correct_index": 0})[0].get("text", "")),
		"What is it?", "a stem ending in '?' is left alone")
	# More than four answers fall back to a numeric label.
	var five: Array = ST.spoken_segments({"prompt": "P", "answers": ["a", "b", "c", "d", "e"], "correct_index": 0})
	t.eq(str(five[9].get("text", "")), "Option 5.", "a fifth choice is labelled '5'")
	t.eq(str(five[10].get("text", "")), "E.", "the answer text is capitalised")

	# speech_plan = pre-answer segments followed by teach segments.
	var plan: Array = ST.speech_plan(rec)
	t.eq(plan.size(), segs.size() + ST.teach_segments(rec).size(), "plan = pre-answer + teach")
	t.check(bool(plan[plan.size() - 1].get("teach", false)), "the plan ENDS on a teach segment")
	var first_teach := -1
	var last_non_teach := -1
	for i in plan.size():
		if bool(plan[i].get("teach", false)):
			if first_teach < 0:
				first_teach = i
		else:
			last_non_teach = i
	t.check(first_teach >= 0, "the plan has teach segments")
	t.check(last_non_teach < first_teach, "teach clips are a contiguous TAIL (the playback gate depends on this)")


# --------------------------------------------------------------------------
# teach_segments -- the POST-ANSWER half
# --------------------------------------------------------------------------
func teach_gate_ordering() -> void:
	print("=== teach_segments ===")
	var rec := {
		"prompt": "The demand load is ___ kW.",
		"answers": ["8 kW", "8.4 kW", "8.8 kW", "12 kW"], "correct_index": 3,
		"reference_text": "220.53 Demand Load\nFor a range over 12 kW use column c of table 220.55.",
	}
	var teach: Array = ST.teach_segments(rec)
	t.check(teach.size() >= 1, "at least one teach segment is produced")
	t.has(str(teach[0].get("text", "")), "Answer: 12 kilowatts.",
		"the FIRST teach clip states the answer (short confirmation first)")
	for seg_v in teach:
		t.check(bool(seg_v.get("teach", false)), "every teach segment is flagged teach=true")
		t.eq(int(seg_v.get("choice", -99)), 3, "teach segments carry the correct choice index")

	# The spoken index N must match the DISPLAYED lesson line N: both are built
	# from the same lesson_lines list, so they can never drift apart.
	var lines: PackedStringArray = preload("res://src/speech/audio_explanation_generator.gd").lesson_lines(rec, "12 kW")
	t.check(teach.size() <= lines.size(), "teach segments never outnumber the display lines")
	t.has(str(teach[0].get("text", "")), ST.speakable(lines[0]), "teach[0] is the spoken form of lesson_lines[0]")

	# Near-duplicate lines are suppressed so the learner does not hear the same
	# sentence twice.
	var rec_dupes := {
		"prompt": "P ___", "answers": ["30 A", "40 A"], "correct_index": 0,
		"reference_text": "X\nA 30 ampere circuit is a 30 ampere circuit.",
		"worked": "A 30 ampere circuit is a 30 ampere circuit.",
	}
	var teach_dupes: Array = ST.teach_segments(rec_dupes)
	var texts: Array[String] = []
	for seg_v in teach_dupes:
		texts.append(str(seg_v.get("text", "")))
	for i in texts.size():
		for j in range(i + 1, texts.size()):
			t.ne(ST._normalize_spoken(texts[i]), ST._normalize_spoken(texts[j]),
				"teach segments %d and %d are not identical after normalisation" % [i, j])

	# A record with no answer must not crash.
	t.eq(ST.teach_segments({"prompt": "P", "answers": [], "correct_index": -1}).size(), 0,
		"a record with no answer yields no teach segments")


# --------------------------------------------------------------------------
# The shims must stay thin pass-throughs, or callers drift.
# --------------------------------------------------------------------------
func delegation_shims() -> void:
	print("=== delegation shims ===")
	const AEG = preload("res://src/speech/audio_explanation_generator.gd")
	t.eq(ST.format_answer_number(2.5), preload("res://src/speech/unit_matcher.gd").format_answer_number(2.5),
		"format_answer_number mirrors UnitMatcher")
	t.eq(str(ST.answer_match_candidates("25")), str(preload("res://src/speech/unit_matcher.gd").answer_match_candidates("25")),
		"answer_match_candidates mirrors UnitMatcher")
	t.eq(str(ST.find_answer_match("a 25A b", "25")), str(AEG.find_match_in("a 25A b", "25")),
		"find_answer_match mirrors AudioExplanationGenerator.find_match_in")
	t.eq(ST.prompt_intent("a ___"), AEG.prompt_intent("a ___"), "prompt_intent mirrors the generator")
	t.eq(ST.plain_words("ampacity"), AEG.plain_words("ampacity"), "plain_words mirrors the generator")
	t.eq(ST.lesson_point("P ___", "B", "W", "a"), AEG.lesson_point("P ___", "B", "W", "a"),
		"lesson_point mirrors the generator")
	t.eq(ST.prompt_with_answer("P ___", "a"), AEG.prompt_with_answer("P ___", "a"),
		"prompt_with_answer mirrors the generator")
	t.eq(ST.answer_sentence("On the front.", "front"), AEG.answer_sentence("On the front.", "front"),
		"answer_sentence mirrors the generator")
	# The constants must agree too, or the letter labels could disagree.
	t.eq(str(ST.ANSWER_LETTERS), str(AEG.ANSWER_LETTERS), "ANSWER_LETTERS matches the generator")


# --------------------------------------------------------------------------
# Every real record must produce a speakable, non-empty plan.
# --------------------------------------------------------------------------
func bank_speakable_sweep() -> void:
	print("=== bank speakable sweep (283 records) ===")
	var recs: Array = (JSON.parse_string(FileAccess.get_file_as_string("res://data/question_bank.json")) as Dictionary).get("records", [])
	t.eq(recs.size(), 283, "bank read is not vacuous")

	var bad := 0
	var empty := 0
	# A LONE underscore is a DATA defect: speakable() converts a formula subscript
	# (R_total) to a word, and a malformed blank in a prompt is a data bug the
	# validator reports. The bank is now clean of both, so this set is empty --
	# and a record gaining one fails the suite, which is the point of the pin.
	const KNOWN_LONE_UNDERSCORE_RECORDS: Array[String] = []
	var underscore_records: Array[String] = []
	for rec_v in recs:
		var rec: Dictionary = rec_v
		var rid := str(rec.get("id", ""))
		for seg_v in ST.speech_plan(rec):
			if not (seg_v is Dictionary):
				bad += 1
				continue
			var txt := str((seg_v as Dictionary).get("text", ""))
			if txt.strip_edges() == "" and int((seg_v as Dictionary).get("choice", -1)) >= 0:
				empty += 1
			var lone := false
			for bad_char in ["_", "“", "”", "—", "→", "÷", "×", "√", "≈", "Ω", "½", "¼", "¾"]:
				if txt.contains(bad_char):
					if bad_char == "_" and not _has_blank_run(txt) and not underscore_records.has(rid):
						underscore_records.append(rid)
						lone = true
						break
					bad += 1
					print("  raw '%s' survives in %s: %s" % [bad_char, rid, txt.substr(0, 80)])
					break
			if lone:
				continue
	t.eq(bad, 0, "no malformed segment and no TTS-hostile character survives in any of the 283 plans")
	t.eq(empty, 0, "no narrated choice is silent")
	t.eq(underscore_records, KNOWN_LONE_UNDERSCORE_RECORDS,
		"the only records whose speech contains '_' are the known lone-underscore defect set")

	# Every teach clip must be non-empty and mention the answer somewhere in the
	# learn part (checked at the generator level in test_no_leak.gd).
	for rec_v in recs:
		var rec2: Dictionary = rec_v
		for seg_v in ST.teach_segments(rec2):
			t.check(str((seg_v as Dictionary).get("text", "")).strip_edges() != "",
				"no empty teach clip in %s" % str(rec2.get("id", "")))
			break  # one per record is enough for the smoke check


func known_defects() -> void:
	print("=== known defects (documented, not failures) ===")
	# The three defects that used to be pinned here are FIXED and are now
	# asserted as behaviour in the rows above plus the whole-bank sweep:
	#   - a formula subscript ("R_total") is spoken as "R total", not "underscore"
	#     (final-exam-#3-055, final-exam-#1-062).
	#   - final-exam-#3-030's malformed lone-underscore blank was fixed in the
	#     DATA: the prompt now reads "... minimum of ___ lbs-inch", so the blank
	#     renders and is spoken as "blank". The bank has zero lone underscores.
	#   - a foot mark ("5'") is spoken as "5 feet" (9 records, 14 narrated
	#     choices), with a possessive ("the Code's") deliberately left alone.


func report() -> void:
	t.report()


## True when the text still contains a run of 2+ underscores, i.e. a real blank
## that speakable() failed to collapse.
func _has_blank_run(text: String) -> bool:
	var run := false
	var count := 0
	for i in text.length():
		if text.substr(i, 1) == "_":
			count += 1
			run = run or count >= 2
		else:
			count = 0
	return run
