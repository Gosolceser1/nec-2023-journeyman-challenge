extends SceneTree
# Scratch probe #11: why did the plural probe report 0?

const AEG = preload("res://audio_explanation_generator.gd")

func _init() -> void:
	var pat := RegEx.create_from_string("(?i)\\bbranch circuits\\b")
	print("  simple match on a literal: ", pat.search_all("single-phase branch circuits rated").size())

	var bank = JSON.parse_string(FileAccess.get_file_as_string("res://question_bank.json"))
	var recs: Array = (bank as Dictionary).get("records", [])
	print("  records: ", recs.size())

	var hits := 0
	var example := ""
	for rec_v in recs:
		var rec: Dictionary = rec_v
		var src: String = str(rec.get("reference_text", "") or "")
		if src == "":
			continue
		for m_v in pat.search_all(src):
			hits += 1
			if example == "":
				var m: RegExMatch = m_v
				example = "%s :: %r" % [rec.get("id", ""), src.substr(maxi(0, m.get_start() - 45), 90)]
	print("  'branch circuits' in reference_text: ", hits)
	print("  example: ", example)

	# Now the same via a NON-capturing inline literal to rule out the (?i) flag.
	var pat2 := RegEx.create_from_string("\\b[Bb]ranch circuits\\b")
	print("  pat2 hits: ", pat2.search_all("single-phase branch circuits rated").size())

	# And confirm plain_words really leaves the plural.
	print("  plain_words: ", AEG.plain_words("single-phase branch circuits rated 150 volts"))
	print("  plain_words: ", AEG.plain_words("Luminaires generate heat"))
	print("  plain_words: ", AEG.plain_words("The luminaires shall be protected"))
	print("  plain_words: ", AEG.plain_words("receptacles in garages"))
	quit(0)
