extends SceneTree
# Scratch probe #4: pin down exact expected strings for the planned assertions.

const AEG = preload("res://audio_explanation_generator.gd")
const ST = preload("res://speech_text.gd")
const UM = preload("res://unit_matcher.gd")
const TV = preload("res://table_viewer.gd")

func _init() -> void:
	print("=== plain_words ===")
	for s in ["Receptacle outlets shall be listed.",
			"equipment grounding conductor", "Equipment grounding conductors",
			"Overcurrent protection shall be provided.",
			"full-load current", "ampacity", "shall not be used as a substitute for grounding",
			"dwelling unit", "walking surface", "not less than 6 in.",
			"A outlet shall", "utilization equipment", "luminaire", "disconnecting means",
			"waste disposer", "branch circuit", "premises wiring", "service equipment",
			"as specified in 310.16", "ensure access", "is accessible", "shall have a disconnect",
			"demand factor", "supplied by a 20 ampere overcurrent protective device"]:
		print("  %-52s -> %s" % [s, AEG.plain_words(s)])

	print("=== prompt_intent / prompt_with_answer ===")
	for p in ["Value is ___ volts.", "Value is __ volts.", "No blank here.",
			"  Spaced ___  ", "Which article ___?"]:
		print("  intent [%s] -> [%s]   with_answer -> [%s]" % [p, AEG.prompt_intent(p), AEG.prompt_with_answer(p, "250")])
	for p in ["The device is...", "The device is ...", "The device is a....", "Plain text"]:
		print("  with_answer [%s] -> [%s]" % [p, AEG.prompt_with_answer(p, "front")])

	print("=== answer_sentence long-body truncation ===")
	var long_body := ""
	for i in 60:
		long_body += "This is filler sentence number %d in the body. " % i
	print("  len=", long_body.length())
	var out: String = AEG.answer_sentence(long_body, "zzz-not-present")
	print("  truncated len=", out.length(), " ends=", out.substr(out.length() - 30))

	print("=== normalize colon-strip boundary ===")
	for s in ["408.18(C): text", "0123456789012345abcdefghij: text", "012345678901234567890123: text",
			"See section 210.19 for this", "no colon here", "a: b: c"]:
		print("  [%s] -> [%s]" % [s, AEG._normalize_for_compare(s)])

	print("=== lesson_point priority ===")
	print("  body wins: ", AEG.lesson_point("Q ___?", "Marked on the front. More.", "WORKED", "front"))
	print("  worked 2nd: ", AEG.lesson_point("Q ___?", "", "WORKED TEXT", "front"))
	print("  prompt 3rd: ", AEG.lesson_point("Marked on the ___.", "", "", "front"))
	print("  answer 4th: ", AEG.lesson_point("", "", "", "front"))

	print("=== teach_segments dedup / ordering ===")
	var rec := {
		"prompt": "The demand load is ___ kW.",
		"answers": ["8 kW", "8.4 kW", "8.8 kW", "12 kW"],
		"correct_index": 3,
		"reference_text": "220.53 Demand Load\nFor a range over 12 kW, use column c of table 220.55.",
		"formula": "",
		"worked": "",
	}
	for seg_v in ST.teach_segments(rec):
		print("  teach: ", seg_v)
	for seg_v in ST.spoken_segments(rec):
		print("  spoken: ", seg_v)
	var plan: Array = ST.speech_plan(rec)
	print("  plan size=", plan.size(), " last is teach=", bool(plan[plan.size()-1].get("teach", false)))
	var pre_teach := 0
	for seg_v in plan:
		if not bool(seg_v.get("teach", false)):
			pre_teach += 1
	print("  pre-teach count=", pre_teach)

	print("=== lesson_lines on numeric record ===")
	var lines: PackedStringArray = AEG.lesson_lines(rec)
	for l in lines:
		print("   line: ", l)
	print("  format_lesson_text has newline: ", AEG.format_lesson_text(rec).contains("\n"))

	print("=== _normalize_spoken ===")
	for s in ["Answer B, 5'.", "  12 AWG  ", "A & B", "Front!  "]:
		print("  [%s] -> [%s]" % [s, ST._normalize_spoken(s)])

	print("=== delegation shims ===")
	print("  ST.format_answer_number(2.5)=", ST.format_answer_number(2.5))
	print("  ST.answer_match_candidates('25')=", ST.answer_match_candidates("25"))
	print("  ST.find_answer_match('a 25A b','25')=", ST.find_answer_match("a 25A b", "25"))
	print("  ST.prompt_intent('a ___')=", ST.prompt_intent("a ___"))
	print("  ST.plain_words('ampacity')=", ST.plain_words("ampacity"))

	print("=== preview_layout edges ===")
	print("  empty: ", TV.preview_layout([]))
	print("  one row: ", TV.preview_layout([["a","b"]]))
	var many: Array = []
	for i in 30:
		many.append(["row %d" % i, "x"])
	print("  30 rows: ", TV.preview_layout(many))
	print("  30 rows cap 100: ", TV.preview_layout(many, 100.0))
	print("  3 rows + note: ", TV.preview_layout([["a"],["b"],["c"],["NOTE: x"]]))

	print("=== extract_target_keyword edges ===")
	print("  empty table: ", TV.extract_target_keyword({"prompt":"x"}, []))
	print("  short cell (<3): ", TV.extract_target_keyword({"prompt":"what about ab here"}, [["ab"], ["ampacity"]]))
	print("  longest wins: ", TV.extract_target_keyword({"prompt":"grounding conductor ampacity"}, [["ampacity"],["grounding conductor"]]))
	print("  NOTE row skipped: ", TV.extract_target_keyword({"prompt":"note: something"}, [["NOTE: ampacity here"]]))
	quit(0)
