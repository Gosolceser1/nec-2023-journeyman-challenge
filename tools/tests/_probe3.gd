extends SceneTree
# Scratch probe #3: reachability of the foot-mark / cable-designation defects.

const ST = preload("res://speech_text.gd")
const TV = preload("res://table_viewer.gd")

func _init() -> void:
	var bank = JSON.parse_string(FileAccess.get_file_as_string("res://question_bank.json"))
	var recs: Array = bank.get("records", [])

	print("=== records whose CORRECT answer is a foot mark ===")
	for rec_v in recs:
		var rec: Dictionary = rec_v
		var ci: int = int(rec.get("correct_index", -1))
		var ans: Array = rec.get("answers", [])
		if ci < 0 or ci >= ans.size():
			continue
		var a: String = str(ans[ci])
		if a.ends_with("'") and a.length() <= 3:
			print("  id=%s ans=%s  spoken=%s" % [rec.get("id",""), a, ST.speakable(a)])

	print("=== records whose text contains an N/M cable designation (spoken as a fraction?) ===")
	var cable := RegEx.new()
	cable.compile("\\b\\d{1,2}/\\d{1,2}\\b")
	var hit := 0
	for rec_v in recs:
		var rec: Dictionary = rec_v
		for f in ["prompt", "gist", "reference_text", "worked", "tip_short"]:
			var t: String = str(rec.get(f, "") or "")
			for m_v in cable.search_all(t):
				var m: RegExMatch = m_v
				var ctx := t.substr(maxi(0, m.get_start() - 18), 40)
				if hit < 22:
					print("  %-9s %-14s %-10s -> %s" % [rec.get("id",""), f, m.get_string(), ST.speakable(ctx.strip_edges())])
				hit += 1
	print("  total slash tokens: ", hit)

	print("=== teach segment text for a foot-mark answer record ===")
	for rec_v in recs:
		var rec: Dictionary = rec_v
		var ci: int = int(rec.get("correct_index", -1))
		var ans: Array = rec.get("answers", [])
		if ci < 0 or ci >= ans.size():
			continue
		if str(ans[ci]) != "5'":
			continue
		print("  id=", rec.get("id", ""), " ans=", str(ans[ci]))
		print("  prompt=", rec.get("prompt", ""))
		for line in AudioExplanationGenerator.lesson_lines(rec, str(ans[ci])):
			print("   line raw : ", line)
			print("   line spoken: ", ST.speakable(line))
		for seg in ST.spoken_segments(rec):
			print("   seg: ", ST.speakable(str(seg.get("text", ""))))
		break
	quit(0)
