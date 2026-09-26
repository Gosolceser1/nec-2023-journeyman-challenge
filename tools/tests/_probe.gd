extends SceneTree
# Scratch probe: prints real outputs for the tricky pure helpers so the real
# test files can assert on exact strings. Not part of the suite.

const AEG = preload("res://audio_explanation_generator.gd")
const ST = preload("res://speech_text.gd")
const UM = preload("res://unit_matcher.gd")
const TV = preload("res://table_viewer.gd")

func _init() -> void:
	print("=== answer_match_candidates ===")
	for a in ["3", "25", "125", "5'", "MC", "0", "20", "12", "240", "2400", "two", "front",
			"1/2 inch", "2 1/2 feet", "1,200", "8%", "#4", "3/8 inch", "1 1/8\"", "10 AWG", ""]:
		print("  %-14s -> %s" % [a, str(UM.answer_match_candidates(a))])

	print("=== redact_answer_spans ===")
	var red = [
		["A 125-volt circuit requires 25 amps.", "25"],
		["Chapter 3: Wiring and Protection", "3"],
		["Navigate to Article 210 and then Table 210.8", "210"],
		["The front of the equipment", "front"],
		["Use 2 in. of slack", "2"],
		["Strain relief devices are required", "strain relief devices"],
		["See 240.4(D) for the breaker", "240.4(D)"],
		["Class III hazardous location", "3"],
		["Rated 5-15A duplex receptacle", "5"],
		["A 20-ampere circuit", "20"],
		["Use 12 AWG copper", "12"],
		["The maximum is 1,200 volts-ampere", "1200"],
		["two-wire circuit", "two"],
		["1/2 inch knockout", "1/2 inch"],
		["a____at the wall", "front"],
		["Table ___ lists the ampacities", "___"],
		["three-phase motor", "3"],
		["Section 210.19(A)", "210"],
	]
	for pair in red:
		var text: String = pair[0]
		var ans: String = pair[1]
		print("  [%s] ans=%s\n     -> %s" % [text, ans, AEG.redact_answer_spans(text, ans)])

	print("=== redact invariant sweep over bank ===")
	var bank = JSON.parse_string(FileAccess.get_file_as_string("res://question_bank.json"))
	var recs: Array = bank.get("records", [])
	var leaks := 0
	var leak_samples: Array[String] = []
	for rec_v in recs:
		var rec: Dictionary = rec_v
		var ci: int = int(rec.get("correct_index", -1))
		var answers: Array = rec.get("answers", [])
		if ci < 0 or ci >= answers.size():
			continue
		var ans: String = str(answers[ci])
		for f in ["reference_text", "formula", "worked", "gist", "tip_short", "info_tip", "lookup_summary"]:
			var src: String = str(rec.get(f, "") or "")
			if src.strip_edges() == "":
				continue
			var out: String = AEG.redact_answer_spans(src, ans)
			if not AEG.find_match_in(out, ans).is_empty():
				leaks += 1
				if leak_samples.size() < 15:
					var m: Dictionary = AEG.find_match_in(out, ans)
					leak_samples.append("%s %s ans=%s match=%s :: %s" % [rec.get("id",""), f, ans, str(m), out.substr(0, 90)])
	print("  leaks: %d / records" % leaks)
	for s in leak_samples:
		print("   * ", s)

	print("=== find_match_in ===")
	var fm = [
		["The 25 ampere circuit", "25"],
		["A 125-volt system", "25"],
		["3-wire circuit", "3"],
		["Chapter 3 of the NEC", "3"],
		["answer 2 here", "2"],
		["nothing here", "5"],
		["Class III", "3"],
		["The front door", "front"],
		["strain relief devices are used", "strain relief devices"],
	]
	for pair in fm:
		print("  [%s] ans=%s -> %s" % [pair[0], pair[1], str(AEG.find_match_in(pair[0], pair[1]))])

	print("=== answer_sentence ===")
	for pair in [["Each section shall be marked on the front. Other rules follow here.", "front"],
			["Marked on the front.", "front"],
			["A rule with 25 amps. Another rule.", "25"],
			["No matching content at all here.", "zzz"],
			["", "front"]]:
		print("  [%s] ans=%s\n     -> %s" % [pair[0], pair[1], AEG.answer_sentence(pair[0], pair[1])])

	print("=== speakable ===")
	var sp = ["240V", "20 A", "12 AWG", "1/2 inch", "1 1/2 inches", "3/8\"", "10 kVA", "2400 VA",
		"1 1/8\"", "Class III locations", "Diagram II", "Table 210.8", "Article 210.8",
		"1,200 volts", "2 x 30A", "5' 11\"", "12/3 cable", "THHN wire", "GFCI receptacle",
		"#6 AWG", "60 Hz", "10 mm", "8000 mA", "8 AWG 75°C", "VIII", "XII", "XIII",
		"15 3/16 in.", "a____at the wall", "Article__", "2 1/2 ft", "3.5 V", "1-1/4\"",
		"40°C", "75°F", "— dash", "→ arrow", "÷ × √ ≈", "Ω 5", "½ ½", "sq. ft.", "cu. in.",
		"1/60 hp", "3/16\" hole", "16 AWG", "3 5/16\"", "No. 6", "kcmil", "300 mA"]
	for s in sp:
		print("  %-22s -> %s" % [s, ST.speakable(s)])

	print("=== spoken_fraction ===")
	for pair in [["1", "2"], ["3", "8"], ["5", "16"], ["1", "1"], ["7", "9"], ["3", "32"], ["1", "64"]]:
		print("  %s/%s -> %s" % [pair[0], pair[1], ST.spoken_fraction(pair[0], pair[1])])

	print("=== format_answer_number ===")
	for v in [0.0, 1.0, 2.5, 30.0, 1000.0, 1200.0, 0.0762, 3.14159, -4.0, 1e6]:
		print("  %s -> %s" % [v, UM.format_answer_number(v)])

	print("=== table pure ===")
	var rows = [["Header A", "Header B"], ["NOTE: some note", ], ["Row 1", "x"], [], "notarray", ["NOTE 2: another"]]
	print("  layout: ", TV.preview_layout(rows))
	print("  layout cap: ", TV.preview_layout(rows, 100.0))
	for r in [["NOTE: x"], ["NOTE 1: x"], ["NOTE No. 1: x"], ["NOTE 2:(A) x"], ["NOTE: x", "y"], ["Notes on things"], ["noted"], [""]]:
		print("  is_note_row %s -> %s" % [str(r), TV.is_note_row(r)])
	for t in ["NOTE: text", "NOTE 1: text", "NOTE No. 1: text", "NOTE: ", "Note 2: (A) body", "NOTED: x", "NOTE"]:
		print("  strip_note_prefix [%s] -> [%s]" % [t, TV._strip_note_prefix(t)])
	var table = [["Size", "Ampacity"], ["14 AWG", "15 A"], ["12 AWG", "20 A"], ["10 AWG", "30 A"], ["NOTE: not copper"]]
	for p in ["What size is 12 AWG rated?", "Ampacity of 14 AWG", "nothing matches here", "10 awg size"]:
		print("  extract_target_keyword [%s] -> [%s]" % [p, TV.extract_target_keyword({"prompt": p}, table)])

	print("=== normalize / duplicate ===")
	for s in ["408.18(C): the front of it", "  The FRONT, please.  ", "A outlet", "Receptacle outlets shall be"]:
		print("  normalize [%s] -> [%s]" % [s, AEG._normalize_for_compare(s)])
	print("  dup(a,b):", AEG._is_duplicate_text("The answer is 30 amps.", "Answer 30 amps."))
	print("  dup(empty):", AEG._is_duplicate_text("", "x"))
	print("  rule_adds_value:", AEG._rule_adds_value("210.19(A) conductors shall be sized to the load.", "Answer A, 30 amperes."))
	print("  rule_adds_value(short):", AEG._rule_adds_value("Front.", "Answer A, front."))

	print("=== lesson_lines on a real record ===")
	var rec2: Dictionary = recs[0]
	var lines: PackedStringArray = AEG.lesson_lines(rec2)
	print("  ", lines)
	print("  prompt_intent: ", AEG.prompt_intent(str(rec2["prompt"])))
	quit(0)
