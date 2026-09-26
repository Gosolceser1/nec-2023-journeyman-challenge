extends SceneTree
# Scratch probe #2: reachability of the speakable/note-row defects on real data.

const ST = preload("res://speech_text.gd")
const TV = preload("res://table_viewer.gd")
const AEG = preload("res://audio_explanation_generator.gd")

func _init() -> void:
	print("=== foot-mark / hyphen / cable forms ===")
	for s in ["5'", "6'", "3 1/2'", "1-1/4\"", "12/3", "10/2", "8/3", "5' 11\"", "a 5 foot run",
			"Answer B, 5'.", "1 1/4\"", "10 3/4\"", "R 6/4", "#12 cu", "3 5/8\""]:
		print("  %-16s -> %s" % [s, ST.speakable(s)])

	print("=== is_note_row / preview on the real numbered-note record ===")
	var bank = JSON.parse_string(FileAccess.get_file_as_string("res://question_bank.json"))
	var recs: Array = bank.get("records", [])
	var numbered := 0
	for rec_v in recs:
		var rec: Dictionary = rec_v
		var t = rec.get("reference_table") or []
		if not (t is Array):
			continue
		for row_v in t:
			if row_v is Array and TV.is_note_row(row_v):
				var head := str(row_v[0]).strip_edges()
				if not head.to_upper().begins_with("NOTE:"):
					numbered += 1
	print("  rows matching is_note_row with a NON bare-NOTE head: %d" % numbered)
	for rec_v in recs:
		var rec: Dictionary = rec_v
		if rec.get("id", "") != "final-exam-#1-021":
			continue
		print("  id: ", rec.get("id"))
		print("  prompt: ", rec.get("prompt"))
		var ci: int = int(rec.get("correct_index", -1))
		var ans: Array = rec.get("answers", [])
		print("  answers: ", ans, "  correct=", str(ans[ci]) if ci < ans.size() else "?")
		for row_v in (rec.get("reference_table") as Array):
			print("   row is_note=%s : %s" % [TV.is_note_row(row_v), str(row_v)])
		print("  layout: ", TV.preview_layout(rec.get("reference_table")))

	print("=== does a bare NOTE row get redacted, numbered one does not? ===")
	var note_text := "For an individual range over 12 kW through 27 kW, increase Column C by 5%."
	print("  redacted(12 kW): ", AEG.redact_answer_spans(note_text, "12 kW"))

	print("=== speech_plan / teach segments for a foot-mark answer ===")
	for rec_v in recs:
		var rec: Dictionary = rec_v
		var ci: int = int(rec.get("correct_index", -1))
		var ans: Array = rec.get("answers", [])
		if ci < 0 or ci >= ans.size():
			continue
		if not str(ans[ci]).contains("'"):
			continue
		print("  id=", rec.get("id"), " ans=", str(ans[ci]))
		for seg in ST.spoken_segments(rec):
			print("     ", ST.speakable(str(seg.get("text", ""))))
		break

	print("=== extract_target_keyword with a numbered-note table ===")
	var tbl = [["Column C", "Demand"], ["NOTE 1: for ranges over 12 kW use column c", ], ["12 kW", "5 kW"]]
	print("  ", TV.extract_target_keyword({"prompt": "for ranges over 12 kW use column c"}, tbl))
	quit(0)
