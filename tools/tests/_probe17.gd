extends SceneTree
# Scratch probe #17: the third underscore case in final-exam-#3-030.

const ST = preload("res://speech_text.gd")

func _init() -> void:
	var recs: Array = (JSON.parse_string(FileAccess.get_file_as_string("res://question_bank.json")) as Dictionary).get("records", [])
	for rec_v in recs:
		var rec: Dictionary = rec_v
		if str(rec.get("id", "")) != "final-exam-#3-030":
			continue
		var prompt := str(rec.get("prompt", ""))
		print("  id      : final-exam-#3-030")
		print("  answers : ", rec.get("answers", []), " correct=", rec.get("correct_index", -1))
		print("  prompt  : '", prompt, "'")
		print("  ends with lone '_': ", prompt.ends_with(" "))
		print("  prompt has ___: ", prompt.contains("___"))
		print("  prompt has __ : ", prompt.contains("__"))
		print("  prompt has lone _: ", prompt.replace("___", "").replace("__", "").contains("_"))
		print("  speakable(prompt) = '", ST.speakable(prompt), "'")
		print("  answer callout speakable = '", ST.speakable(str((rec.get("answers") as Array)[int(rec.get("correct_index"))])), "'")
		for seg_v in ST.spoken_segments(rec):
			var txt := str((seg_v as Dictionary).get("text", ""))
			if txt.contains("_"):
				print("  SEGMENT with '_': '", txt, "'")
		# The blank is never filled: the record has no ___ marker at all, so the
		# learner sees a literal underscore instead of a blank.
		print("  => the prompt renders its blank as a bare '_', which speakable() does not speak as 'blank'")
	quit(0)
