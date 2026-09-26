extends SceneTree
# Scratch probe #10: settle the plain_words plural gap definitively.

const AEG = preload("res://audio_explanation_generator.gd")

func _init() -> void:
	print("--- controlled sample ---")
	var s1 := "Branch circuits and luminaires shall be protected."
	print("  in : ", s1)
	print("  out: ", AEG.plain_words(s1))

	print("--- does the bank actually contain bare plurals in plain_words inputs? ---")
	var bank = JSON.parse_string(FileAccess.get_file_as_string("res://question_bank.json"))
	var recs: Array = bank.get("records", [])
	var probes := {
		"branch circuits": RegEx.create_from_string("(?i)\\bbranch circuits\\b"),
		"receptacles": RegEx.create_from_string("(?i)\\breceptacles\\b"),
		"luminaires": RegEx.create_from_string("(?i)\\bluminaires\\b"),
		"overcurrent devices": RegEx.create_from_string("(?i)\\bovercurrent devices\\b"),
		"ungrounded conductors": RegEx.create_from_string("(?i)\\bungrounded conductors\\b"),
		"dwelling units": RegEx.create_from_string("(?i)\\bdwelling units\\b"),
		"grounded conductors": RegEx.create_from_string("(?i)\\bgrounded conductors\\b"),
		"full-load currents": RegEx.create_from_string("(?i)\\bfull-load currents\\b"),
		"waste disposers": RegEx.create_from_string("(?i)\\bwaste disposers\\b"),
		"service equipment": RegEx.create_from_string("(?i)\\bservice equipment\\b"),
		"demand factors": RegEx.create_from_string("(?i)\\bdemand factors\\b"),
	}
	var total_in := {}
	var total_out := {}
	for rec_v in recs:
		var rec: Dictionary = rec_v
		var src := str(rec.get("reference_text", "") or "")
		src += "\n" + str(rec.get("formula", "") or "")
		src += "\n" + str(rec.get("worked", "") or "")
		if src.strip_edges() == "":
			continue
		var conv: String = AEG.plain_words(src)
		for key in probes.keys():
			var pat: RegEx = probes[key]
			var n_in: int = pat.search_all(src).size()
			var n_out: int = pat.search_all(conv).size()
			if n_in > 0:
				total_in[key] = int(total_in.get(key, 0)) + n_in
				total_out[key] = int(total_out.get(key, 0)) + n_out
	var keys := total_in.keys()
	keys.sort_custom(func(a, b): return int(total_in[a]) > int(total_in[b]))
	print("  %-26s %8s %8s %8s" % ["plural term", "in", "out", "SURVIVED"])
	for k in keys:
		print("  %-26s %8d %8d %8d" % [k, int(total_in[k]), int(total_out.get(k, 0)),
			int(total_in[k]) - int(total_out.get(k, 0))])
	quit(0)
