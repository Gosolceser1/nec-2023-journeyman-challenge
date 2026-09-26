extends SceneTree
# Scratch probe #6: quantify the plain_words plural gap over the FIELDS IT ACTUALLY RUNS ON.

const AEG = preload("res://audio_explanation_generator.gd")

func _init() -> void:
	var bank = JSON.parse_string(FileAccess.get_file_as_string("res://question_bank.json"))
	var recs: Array = bank.get("records", [])
	# plain_words() runs on lesson_point() output, which is built from reference_text /
	# formula / worked ONLY (generate_explanation lines 36-48).
	var terms := ["receptacle", "branch circuit", "overcurrent device", "luminaire",
		"ungrounded conductor", "dwelling unit", "demand factor", "waste disposer",
		"grounded conductor", "grounding conductor", "full-load current", "feeder tap",
		"disconnecting means", "premises wiring", "service equipment", "utilization equipment",
		"walking surface", "ampacity", "overcurrent protection"]
	var unswapped := {}
	var swapped := {}
	for rec_v in recs:
		var rec: Dictionary = rec_v
		var src := str(rec.get("reference_text", "") or "")
		src += "\n" + str(rec.get("formula", "") or "")
		src += "\n" + str(rec.get("worked", "") or "")
		if src.strip_edges() == "":
			continue
		var converted: String = AEG.plain_words(src)
		for t in terms:
			var pattern := RegEx.create_from_string("(?i)\\b" + t.replace(" ", "\\s+") + "s?\\b")
			var before := pattern.search_all(src).size()
			if before == 0:
				continue
			var after := pattern.search_all(converted).size()
			if after == 0:
				swapped[t] = int(swapped.get(t, 0)) + before
			elif after == before:
				var pass_count := 0
				for m_v in pattern.search_all(src):
					pass_count += 1
				if pass_count > after:
					unswapped[t] = int(unswapped.get(t, 0)) + (pass_count - after)
	var keys := unswapped.keys()
	keys.sort_custom(func(a, b): return int(unswapped[a]) > int(unswapped[b]))
	print("=== plural/inflection forms left UNCONVERTED in plain_words() output ===")
	for k in keys:
		print("   %-26s %d occurrence(s) left" % [k, unswapped[k]])

	print("=== worked example ===")
	var sample := "Receptacles in dwelling units shall be listed. Branch circuits and luminaires shall be protected."
	print("   in : ", sample)
	print("   out: ", AEG.plain_words(sample))
	quit(0)
