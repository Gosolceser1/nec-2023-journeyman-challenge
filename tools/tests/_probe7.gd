extends SceneTree
# Scratch probe #7: accurate count of plain_words() misses on its real inputs.

const AEG = preload("res://audio_explanation_generator.gd")

func _init() -> void:
	var bank = JSON.parse_string(FileAccess.get_file_as_string("res://question_bank.json"))
	var recs: Array = bank.get("records", [])
	var terms := ["receptacle", "branch circuit", "overcurrent device", "luminaire",
		"ungrounded conductor", "dwelling unit", "demand factor", "waste disposer",
		"grounded conductor", "grounding conductor", "full-load current", "feeder tap",
		"disconnecting means", "premises wiring", "service equipment",
		"utilization equipment", "walking surface", "ampacity", "overcurrent protection"]
	var missed := {}
	var affected_records := 0
	for rec_v in recs:
		var rec: Dictionary = rec_v
		var src := str(rec.get("reference_text", "") or "")
		src += "\n" + str(rec.get("formula", "") or "")
		src += "\n" + str(rec.get("worked", "") or "")
		if src.strip_edges() == "":
			continue
		var converted: String = AEG.plain_words(src)
		var hit_here := false
		for t in terms:
			var pattern := RegEx.create_from_string("(?i)\\b" + t.replace(" ", "\\s+") + "s\\b")
			# Only the PLURAL survives -> the singular mapping ran, the plural did not.
			var plural_in := pattern.search_all(src).size()
			if plural_in == 0:
				continue
			var plural_out := pattern.search_all(converted).size()
			if plural_out < plural_in:
				missed[t] = int(missed.get(t, 0)) + (plural_in - plural_out)
				hit_here = true
		if hit_here:
			affected_records += 1
	var keys := missed.keys()
	keys.sort_custom(func(a, b): return int(missed[a]) > int(missed[b]))
	print("=== plural forms left unconverted by plain_words(), on real input ===")
	for k in keys:
		print("   %-26s %d" % [k, missed[k]])
	print("   records affected: %d / %d" % [affected_records, recs.size()])
	quit(0)
