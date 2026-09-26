extends SceneTree
# Scratch probe #14: confirm the real defects with CORRECT field reads.

const ST = preload("res://speech_text.gd")
const TV = preload("res://table_viewer.gd")
const UM = preload("res://unit_matcher.gd")
const AEG = preload("res://audio_explanation_generator.gd")

func field(rec: Dictionary, key: String) -> String:
	var v = rec.get(key, "")
	if v == null:
		return ""
	return str(v)

func _init() -> void:
	var recs: Array = (JSON.parse_string(FileAccess.get_file_as_string("res://question_bank.json")) as Dictionary).get("records", [])

	print("=== BUG A: numbered NOTE rows in the real bank ===")
	for rec_v in recs:
		var rec: Dictionary = rec_v
		var tbl = rec.get("reference_table")
		if not (tbl is Array) or (tbl as Array).is_empty():
			continue
		for row_v in (tbl as Array):
			if not (row_v is Array):
				continue
			var head := str((row_v as Array)[0]).strip_edges().to_upper()
			if head.begins_with("NOTE") and not TV.is_note_row(row_v):
				print("  id=%s  answer=%s" % [field(rec, "id"), str((rec.get("answers") as Array)[int(rec.get("correct_index"))])])
				print("  row: %s" % str(row_v).substr(0, 120))
				print("  is_note_row=%s  _strip_note_prefix=%s" % [TV.is_note_row(row_v), TV._strip_note_prefix(str((row_v as Array)[0])).substr(0, 60)])

	print("=== BUG B: foot marks in NARRATED answer choices ===")
	var n := 0
	for rec_v in recs:
		var rec: Dictionary = rec_v
		for a_v in (rec.get("answers", []) as Array):
			var a: String = str(a_v).strip_edges()
			if a.ends_with("'") and a.length() <= 4:
				n += 1
				if n <= 6:
					print("  %s : %-5s -> speakable=%-8s inch-mark control: %s" % [field(rec, "id"), a, ST.speakable(a), ST.speakable("5\"")])
	print("  total bare foot-mark choices: %d" % n)

	print("=== BUG C/D: cable designations, hyphenated mixed numbers, Roman numerals ===")
	for s in ["12/3", "10/2", "8/3", "15/20 A", "1-1/4\"", "1-1/2\"", "3 1/2\"", "VIII", "XII", "XIII", "XIV", "Class III", "Diagram III"]:
		print("  %-12s -> %s" % [s, ST.speakable(s)])

	print("=== BUG E: plain_words plural gap, real data ===")
	var src := "125-volt receptacles in garages supplied by single-phase branch circuits rated 150 volts. Luminaires generate heat."
	print("  in : %s" % src)
	print("  out: %s" % AEG.plain_words(src))

	print("=== BUG F: percent answers vs 'N percent' wording ===")
	for a in ["83%", "50%", "8%"]:
		print("  candidates(%s) = %s" % [a, str(UM.answer_match_candidates(a))])
	print("  redact('83 percent of the rating', '83%') = %s" % AEG.redact_answer_spans("83 percent of the rating", "83%"))
	var fcount := 0
	for rec_v in recs:
		var rec: Dictionary = rec_v
		var ci: int = int(rec.get("correct_index", -1))
		var answers: Array = rec.get("answers", [])
		if ci < 0 or ci >= answers.size():
			continue
		var a: String = str(answers[ci])
		if not a.ends_with("%"):
			continue
		var num := a.substr(0, a.length() - 1)
		var body := field(rec, "reference_text") + " " + field(rec, "worked")
		if body.find(num + " percent") >= 0 or body.find(num + " per cent") >= 0:
			fcount += 1
			print("  %s ans=%s has '%s percent' in reference_text" % [field(rec, "id"), a, num])
	print("  records with a %% answer whose reference_text spells the number: %d" % fcount)
	quit(0)
