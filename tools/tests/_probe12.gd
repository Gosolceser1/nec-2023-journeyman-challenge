extends SceneTree
# Scratch probe #12: is the GDScript-side bank read actually seeing the data?

func _init() -> void:
	var raw := FileAccess.get_file_as_string("res://question_bank.json")
	print("  file bytes: ", raw.length())
	var parsed = JSON.parse_string(raw)
	print("  parsed type: ", type_string(typeof(parsed)))
	if not (parsed is Dictionary):
		print("  NOT A DICTIONARY")
		quit(1)
		return
	var d: Dictionary = parsed
	print("  top-level keys: ", d.keys())
	var recs: Array = d.get("records", [])
	print("  records: ", recs.size())
	var rec0: Dictionary = recs[0]
	print("  rec0 keys: ", rec0.keys())
	for f in ["id", "prompt", "reference_text", "gist", "answers", "correct_index"]:
		var v = rec0.get(f, "<MISSING>")
		print("   %-16s -> %s" % [f, str(v).substr(0, 70)])

	var with_ref := 0
	var with_prompt := 0
	for rec_v in recs:
		var rec: Dictionary = rec_v
		if str(rec.get("reference_text", "") or "") != "":
			with_ref += 1
		if str(rec.get("prompt", "") or "") != "":
			with_prompt += 1
	print("  records with non-empty reference_text: ", with_ref, " / ", recs.size())
	print("  records with non-empty prompt: ", with_prompt, " / ", recs.size())

	var pat := RegEx.create_from_string("(?i)\\bbranch circuits\\b")
	var hits := 0
	var sample := ""
	for rec_v in recs:
		var rec: Dictionary = rec_v
		var src: String = str(rec.get("reference_text", "") or "")
		for m_v in pat.search_all(src):
			hits += 1
			if sample == "":
				var m: RegExMatch = m_v
				sample = "%s :: %s" % [rec.get("id", ""),
					src.substr(maxi(0, m.get_start() - 40), 80)]
	print("  'branch circuits' hits in reference_text: ", hits)
	print("  sample: ", sample)

	# Does the same pattern work if built from a plain compile?
	var pat2 := RegEx.new()
	pat2.compile("(?i)\\bbranch circuits\\b")
	print("  pat2 on a literal: ", pat2.search_all("a branch circuits b").size())
	var pat3 := RegEx.new()
	pat3.compile("\\bbranch\\s+circuits\\b")
	print("  pat3 on a literal: ", pat3.search_all("a branch circuits b").size())
	var src0: String = str(rec0.get("reference_text", "") or "")
	print("  pat3 on rec0 reference_text: ", pat3.search_all(src0).size())
	print("  rec0 reference_text head: ", src0.substr(0, 120))
	quit(0)
