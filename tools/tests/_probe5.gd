extends SceneTree
# Scratch probe #5: is each speakable/table defect REACHABLE from real bank content?

const ST = preload("res://speech_text.gd")
const TV = preload("res://table_viewer.gd")
const AEG = preload("res://audio_explanation_generator.gd")

func _init() -> void:
	var bank = JSON.parse_string(FileAccess.get_file_as_string("res://question_bank.json"))
	var recs: Array = bank.get("records", [])

	# The SPOKEN text is: lesson_lines (built from reference_text/formula/worked) + speakable().
	var spoken_defects := {
		"hyphen_mixed": RegEx.new(),
		"dual_rating": RegEx.new(),
		"foot_mark": RegEx.new(),
	}
	spoken_defects["hyphen_mixed"].compile("\\b\\d+\\s*-\\s*\\d+/\\d+\\b")
	spoken_defects["dual_rating"].compile("\\b\\d{1,2}/\\d{1,2}\\s*A\\b")
	spoken_defects["foot_mark"].compile("\\b\\d+\\s*'")

	var found := {"hyphen_mixed": [], "dual_rating": [], "foot_mark": []}
	for rec_v in recs:
		var rec: Dictionary = rec_v
		var src := ""
		src += str(rec.get("reference_text", "") or "")
		src += "\n" + str(rec.get("formula", "") or "")
		src += "\n" + str(rec.get("worked", "") or "")
		for key in found.keys():
			for m_v in spoken_defects[key].search_all(src):
				var m: RegExMatch = m_v
				if found[key].size() < 6:
					found[key].append("%s :: %s  ==>  %s" % [rec.get("id", ""),
						m.get_string(), ST.speakable(m.get_string())])
	for key in found.keys():
		print("=== SPOKEN-SOURCE %s ===" % key)
		for s in found[key]:
			print("   ", s)

	# Same for the NARRATED choices: every answer string is spoken pre-answer.
	var foot_answers := 0
	for rec_v in recs:
		var rec: Dictionary = rec_v
		for a_v in (rec.get("answers", []) as Array):
			var a := str(a_v).strip_edges()
			if a.ends_with("'") and a.length() <= 4:
				foot_answers += 1
				if foot_answers <= 8:
					print("=== NARRATED CHOICE %s : %s ==> %s" % [rec.get("id",""), a, ST.speakable(a)])
	print("  narrated foot-mark choices total: ", foot_answers)

	# NUMBERED note rows that bypass is_note_row -> and whether the answer hides in one.
	print("=== numbered note rows: redaction bypass ===")
	for rec_v in recs:
		var rec: Dictionary = rec_v
		var t = rec.get("reference_table") or []
		if not (t is Array):
			continue
		var ci: int = int(rec.get("correct_index", -1))
		var answers: Array = rec.get("answers", [])
		if ci < 0 or ci >= answers.size():
			continue
		var ans: String = str(answers[ci])
		for row_v in t:
			if not (row_v is Array):
				continue
			var is_note: bool = TV.is_note_row(row_v)
			var cell := str(row_v[0])
			var head := cell.strip_edges().to_upper()
			if head.begins_with("NOTE") and not is_note:
				var leaks: bool = not AEG.find_match_in(cell, ans).is_empty()
				print("   %s  note_row_rejected=%s  answer_in_note=%s  ans=%s" % [rec.get("id",""), str(not is_note), str(leaks), ans])
	quit(0)
