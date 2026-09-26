extends SceneTree
# Scratch probe #13: GDScript `or` is a BOOLEAN operator, so `x or ""` yields
# str(true)="true". The earlier bank sweeps were therefore measuring the literal
# strings "true"/"false". Re-measure correctly.

const AEG = preload("res://audio_explanation_generator.gd")
const ST = preload("res://speech_text.gd")

func field(rec: Dictionary, key: String) -> String:
	var v = rec.get(key, "")
	if v == null:
		return ""
	return str(v)

func _init() -> void:
	var raw := FileAccess.get_file_as_string("res://question_bank.json")
	var recs: Array = (JSON.parse_string(raw) as Dictionary).get("records", [])

	print("--- sanity: the two idioms side by side ---")
	var r0: Dictionary = recs[0]
	print("  field(r0,'reference_text').substr(0,40) = %s" % field(r0, "reference_text").substr(0, 40))
	print("  str(r0.get('reference_text','') or '').substr(0,40) = %s" % str(r0.get("reference_text", "") or "").substr(0, 40))

	print("--- real plural counts in plain_words() inputs ---")
	var terms := ["branch circuits", "receptacles", "luminaires", "overcurrent devices",
		"ungrounded conductors", "dwelling units", "grounded conductors",
		"grounding conductors", "full-load currents", "waste disposers",
		"demand factors", "service equipment", "feeder taps", "ampacities"]
	var n_in := {}
	var n_out := {}
	var affected := 0
	for rec_v in recs:
		var rec: Dictionary = rec_v
		var src := field(rec, "reference_text") + "\n" + field(rec, "formula") + "\n" + field(rec, "worked")
		if src.strip_edges() == "":
			continue
		var conv: String = AEG.plain_words(src)
		var hit := false
		for term in terms:
			var pat := RegEx.create_from_string("(?i)\\b" + term.replace(" ", "\\s+") + "\\b")
			var a: int = pat.search_all(src).size()
			var b: int = pat.search_all(conv).size()
			if a > 0:
				n_in[term] = int(n_in.get(term, 0)) + a
				n_out[term] = int(n_out.get(term, 0)) + b
			if b < a:
				hit = true
		if hit:
			affected += 1
	var keys := n_in.keys()
	keys.sort_custom(func(a, b): return int(n_in[a]) > int(n_in[b]))
	print("  %-24s %6s %6s %9s" % ["plural term", "in", "out", "SURVIVED"])
	for k in keys:
		var survived: int = int(n_in[k]) - int(n_out.get(k, 0))
		print("  %-24s %6d %6d %9d" % [k, int(n_in[k]), int(n_out.get(k, 0)), survived])
	print("  records affected: %d / %d" % [affected, recs.size()])

	print("--- real leak sweep, correct field reads ---")
	var leaks := 0
	var log: Array[String] = []
	var fields := ["reference_text", "formula", "worked", "gist", "tip_short", "info_tip",
		"lookup_summary", "article", "article_title", "prompt"]
	for rec_v in recs:
		var rec: Dictionary = rec_v
		var ci: int = int(rec.get("correct_index", -1))
		var answers: Array = rec.get("answers", [])
		if ci < 0 or ci >= answers.size():
			continue
		var ans: String = str(answers[ci])
		if ans.strip_edges() == "":
			continue
		for f in fields:
			var src: String = field(rec, f)
			if src.strip_edges() == "":
				continue
			var red: String = AEG.redact_answer_spans(src, ans)
			if not AEG.find_match_in(red, ans).is_empty():
				leaks += 1
				if log.size() < 12:
					log.append("%s/%s ans=%s" % [field(rec, "id"), f, ans])
	print("  leaks: %d" % leaks)
	for l in log:
		print("   * ", l)

	print("--- foot marks really in the bank ---")
	var foot := 0
	for rec_v in recs:
		var rec: Dictionary = rec_v
		for a_v in (rec.get("answers", []) as Array):
			var a: String = str(a_v).strip_edges()
			if a.ends_with("'") and a.length() <= 4:
				foot += 1
	print("  bare foot-mark choices: %d" % foot)
	quit(0)
