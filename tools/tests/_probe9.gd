extends SceneTree
# Scratch probe #9: settle the two candidate real bugs + the plain_words plural gap.

const AEG = preload("res://audio_explanation_generator.gd")
const ST = preload("res://speech_text.gd")
const TV = preload("res://table_viewer.gd")

func _init() -> void:
	print("--- BUG 1 candidate: is_note_row vs its own docstring ---")
	print("  docstring promises: NOTE:, NOTE 1:, NOTE 2:, NOTE No. 1:")
	for h in ["NOTE: text", "NOTE 1: text", "NOTE 2: text", "NOTE No. 1: text", "NOTE 3:(A) text", "NOTE 1. text"]:
		print("    is_note_row([%s]) = %s   (strip-> %s)" % [h, TV.is_note_row([h]), TV._strip_note_prefix(h)])

	print("--- BUG 1 reachability: the one real numbered-note record ---")
	var bank = JSON.parse_string(FileAccess.get_file_as_string("res://question_bank.json"))
	var recs: Array = bank.get("records", [])
	for rec_v in recs:
		var rec: Dictionary = rec_v
		if rec.get("id", "") != "final-exam-#1-021":
			continue
		var tbl: Array = rec.get("reference_table", [])
		print("  id=final-exam-#1-021  answer=%s" % str(rec.get("answers", [])[int(rec.get("correct_index"))]))
		var counted := 0
		for row_v in tbl:
			if TV.is_note_row(row_v):
				continue
			counted += 1
		print("  rows counted as DATA rows: %d (of %d raw rows)" % [counted, tbl.size()])
		print("  preview_layout: ", TV.preview_layout(tbl))
		# The note is NOT in the note strip, so it is rendered as a normal cell:
		# it inflates the table AND its text prints in the grid.
		for row_v in tbl:
			print("    data-row? %-5s  %s" % [str(not TV.is_note_row(row_v)), str(row_v).substr(0, 100)])

	print("--- BUG 2 candidate: foot marks and cable designations in speakable ---")
	for s in ["5'", "6'", "10'", "25'", "4'", "3 1/2'", "1-1/4\"", "12/3", "10/2", "8/3", "15/20 A", "1/60 s"]:
		print("    speakable(%-10s) = %s" % [s, ST.speakable(s)])
	var foot := 0
	var cable := 0
	for rec_v in recs:
		var rec: Dictionary = rec_v
		for a_v in (rec.get("answers", []) as Array):
			if str(a_v).strip_edges().ends_with("'"):
				foot += 1
	print("  narrated answer choices that are bare foot marks: %d" % foot)
	var cable_re := RegEx.new()
	cable_re.compile("\\b\\d{1,2}/\\d{1,2}\\b")
	for rec_v in recs:
		var rec: Dictionary = rec_v
		for f in ["prompt", "reference_text", "worked", "formula"]:
			var t: String = str(rec.get(f, "") or "")
			for m_v in cable_re.search_all(t):
				cable += 1
				if cable <= 6:
					print("    cable-ish token in %s/%s: %r" % [rec.get("id",""), f, m_v.get_string()])
	print("  slash tokens in spoken-source fields: %d" % cable)

	print("--- BUG 3 candidate: plain_words plural gap (measured in GDScript) ---")
	var plural := ["receptacles", "branch circuits", "overcurrent devices", "luminaires",
		"ungrounded conductors", "dwelling units", "demand factors", "full-load currents",
		"grounded conductors", "grounding conductors", "waste disposers", "service equipment"]
	var missed := {}
	var affected := 0
	for rec_v in recs:
		var rec: Dictionary = rec_v
		var src := str(rec.get("reference_text", "") or "")
		src += "\n" + str(rec.get("formula", "") or "")
		src += "\n" + str(rec.get("worked", "") or "")
		if src.strip_edges() == "":
			continue
		var conv: String = AEG.plain_words(src)
		var hit_here := false
		for p in plural:
			var pat := RegEx.create_from_string("(?i)\\b" + p.replace(" ", "\\s+") + "\\b")
			var n_in: int = pat.search_all(src).size()
			var n_out: int = pat.search_all(conv).size()
			if n_in > n_out:
				missed[p] = int(missed.get(p, 0)) + (n_in - n_out)
				hit_here = true
		if hit_here:
			affected += 1
	var keys := missed.keys()
	keys.sort_custom(func(a, b): return int(missed[a]) > int(missed[b]))
	for k in keys:
		print("    %-24s %d occurrence(s) survive" % [k, missed[k]])
	print("    records affected: %d / %d" % [affected, recs.size()])
	print("    example: ", AEG.plain_words("Luminaires in dwelling units shall be protected by branch circuits."))
	quit(0)
