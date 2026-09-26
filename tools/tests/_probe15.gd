extends SceneTree
# Scratch probe #15: what EXACTLY matched in the 4 flagged prompts?

const AEG = preload("res://audio_explanation_generator.gd")
const UM = preload("res://unit_matcher.gd")

func _init() -> void:
	var cases := [
		["All 15 or 20 amp, single-phase, 125 volt through 250 volt receptacles located within ___ feet of a fountain edge shall be provided with GFCI protection.", "20"],
		["The minimum number of overload units required for a three-phase motor is...", "3"],
		["Utilization equipment weighing not more than 6 pounds shall be permitted to be supported on other boxes or plaster rings that are secured to other boxes, provided the equipment or its supporting yoke is secured to the box with no fewer than two ___ or larger screws.", "#6"],
		["For a 1/2-inch RNC run secured within 36 inches of each termination, what is the maximum permitted spacing between supports along the run?", "3 feet"],
	]
	for pair in cases:
		var text: String = pair[0]
		var ans: String = pair[1]
		var hit: Dictionary = AEG.find_match_in(text, ans)
		var start: int = int(hit.get("start", -1))
		var length: int = int(hit.get("length", 0))
		print("ans=%-8s -> start=%d len=%d slice=%r" % [ans, start, length,
			text.substr(start, length) if start >= 0 else ""])
		var cands: Array = UM.answer_match_candidates(ans)
		for c in cands:
			var needle := str(c)
			if needle.strip_edges().is_empty():
				continue
			var idx := text.to_lower().find(needle.to_lower())
			if idx >= 0:
				print("     candidate %r matches at %d  (neighbours %r / %r)" % [needle, idx,
					text.substr(idx - 1, 1) if idx > 0 else "", text.substr(idx + needle.length(), 1)])
		print("     is that the ANSWER or a coincidental token? -> %r" % text.substr(maxi(0, start - 45), 100))
		print("")

	print("--- does redaction fix the prompt case? (main.gd does NOT redact prompts) ---")
	print("  redact(prompt1, '20') = %s" % AEG.redact_answer_spans(cases[0][0], "20"))
	quit(0)
