extends SceneTree
# Scratch probe #8: exact values for assertions not yet confirmed.

const AEG = preload("res://audio_explanation_generator.gd")
const ST = preload("res://speech_text.gd")
const UM = preload("res://unit_matcher.gd")
const TV = preload("res://table_viewer.gd")

func _init() -> void:
	print("--- _is_duplicate_text ---")
	print("  A ", AEG._is_duplicate_text("The answer is 30 amps.", "Answer 30 amps."))
	print("  B ", AEG._is_duplicate_text("Calculation: 30 amps", "30 amps"))
	print("  C ", AEG._is_duplicate_text("totally different words here", "nothing alike at all"))
	print("  D ", AEG._is_duplicate_text("conductor ampacity shall be sized", "conductor ampacity shall be sized"))
	print("  E ", AEG._is_duplicate_text("Answer: 30 amps.", "Calculation: 30 amps."))
	print("  F ", AEG._is_duplicate_text("210.19 sized to the load", "Answer D, 12 kW"))
	print("  G ", AEG._is_duplicate_text("x", ""))

	print("--- _rule_adds_value ---")
	print("  A ", AEG._rule_adds_value("210.19(A) conductors shall be sized to the load.", "Answer A, 30 amperes."))
	print("  B ", AEG._rule_adds_value("Front.", "Answer A, front."))
	print("  C ", AEG._rule_adds_value("The answer is 30 amps per the table below.", "Answer: 30 amps."))
	print("  D ", AEG._rule_adds_value("Answer A, front.", "Answer A, front."))

	print("--- plain_words extras ---")
	for s in ["Overcurrent protective device", "Overcurrent device", "overcurrent protection devices",
			"supplementary overcurrent protection", "utilization equipment shall be",
			"fixed electric space-heating equipment", "shall not be used as a substitute for grounding",
			"full-load currents", "not more than 6 ft", "not exceeding 30 in.", "located in the wall",
			"grounding-type attachment plug", "grounded conductor", "ungrounded conductors",
			"feeder tap conductors", "Article 210.8 shall be used"]:
		print("  [%s] -> [%s]" % [s, AEG.plain_words(s)])

	print("--- format_lesson_text / generate_explanation ---")
	var rec := {"prompt": "P ___?", "answers": ["12 kW", "8 kW"], "correct_index": 0,
		"reference_text": "220.53 Demand Load\nFor a range over 12 kW use column c.",
		"formula": "I = V / R", "worked": "12 kW is the demand", "article": "220.53"}
	var expl: Dictionary = AEG.generate_explanation(rec)
	print("  script: ", expl.get("tts_script", {}))
	print("  qid: ", expl.get("question_id", ""))
	print("  lesson_lines: ", AEG.lesson_lines(rec))
	var rec_no_art := {"prompt": "P", "answers": ["x"], "correct_index": -1,
		"reference_text": "NoCite here\nBody text."}
	print("  no correct: ", AEG.generate_explanation(rec_no_art).get("tts_script", {}))
	var rec_dup := {"prompt": "P", "answers": ["12 kW"], "correct_index": 0,
		"reference_text": "X\nFor a range over 12 kW use column c.", "worked": "For a range over 12 kW use column c."}
	print("  dupe math: ", AEG.generate_explanation(rec_dup).get("tts_script", {}))
	print("  cite from header: ", AEG.generate_explanation({"prompt": "p", "answers": ["a"], "correct_index": 0,
		"reference_text": "210.8 Name\nbody"}).get("tts_script", {}))

	print("--- UM candidates extras ---")
	for a in ["1/2 inch", "30 in.", "240 volts", "20 amps", "3/8\"", "1,200 VA", "ten", "0.5 inch", "MC", "5'"]:
		print("  %-12s -> %s" % [a, str(UM.answer_match_candidates(a))])

	print("--- speakable extras ---")
	for s in ["12 AWG THHN", "no. 6 cu", "3 1/2'", "1 1/4\" knockout", "240/120 V", "1 5/8 in.",
			"20A receptacle", "8 AWG 90°C", "1,000,000", "5 5/8\"", "12/3 and 10/2",
			"Table 1 and 2", "under/over", "1.5 kW", "0.5 mA", "1 1/16\"", "II III IV"]:
		print("  %-22s -> [%s]" % [s, ST.speakable(s)])

	print("--- table extras ---")
	print("  is_note_row([\"NOTE:\"]) ", TV.is_note_row(["NOTE:"]))
	print("  is_note_row([\"NOTE 1: x\"]) ", TV.is_note_row(["NOTE 1: x"]))
	print("  strip [NOTE: x] ", TV._strip_note_prefix("NOTE: x"))
	print("  strip [NOTE 1: x] ", TV._strip_note_prefix("NOTE 1: x"))
	print("  strip [NOTE No. 1: x] ", TV._strip_note_prefix("NOTE No. 1: x"))
	print("  strip [NOTED: x] ", TV._strip_note_prefix("NOTED: x"))
	print("  extract [ampacity of 14 AWG or 10 AWG] ", TV.extract_target_keyword(
		{"prompt": "ampacity of 14 awg or 10 awg"}, [["14 AWG", "15"], ["10 AWG", "30"]]))
	quit(0)
