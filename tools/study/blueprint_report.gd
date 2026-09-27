extends SceneTree
## Pool counts per exam subject area, the overrides in use, and what each mode
## draws per area. Exit code 1 if an override is broken.
##   Godot --headless --path . --script tools/study/blueprint_report.gd

func _initialize() -> void:
	var records := BankLoader.load_records()
	var by_area := ExamBlueprint.indices_by_area(records)
	var ok := true
	print("BLUEPRINT %s: %d scored items" % [str(ExamBlueprint.data().get("source", "")), ExamBlueprint.scored_items()])
	print("  %-30s %6s %6s %s" % ["area", "exam", "pool", "note"])
	var capacity := {}
	for k in ExamBlueprint.keys():
		var n: int = (by_area[k] as Array).size()
		capacity[k] = n
		var need := ExamBlueprint.items(k)
		print("  %-30s %6d %6d %s" % [ExamBlueprint.title(k), need, n, "SHORT by %d: the simulator fills the gap from other areas" % (need - n) if n < need else ""])
	print("  %-30s %6d %6d" % ["total", ExamBlueprint.scored_items(), BankLoader.count_in_section(records, BankLoader.SECTION_NEC)])
	print("  (outside the blueprint: %d Nebraska State Law records)" % BankLoader.count_in_section(records, BankLoader.SECTION_NE_STATE_LAW))
	var index_of := {}
	for i in records.size():
		index_of[str(records[i].get("id", ""))] = i
	var overrides: Dictionary = ExamBlueprint.data().get("overrides", {})
	print("OVERRIDES %d" % overrides.size())
	for id in overrides:
		var area := str(overrides[id].get("area", ""))
		var known := index_of.has(id) and ExamBlueprint.items(area) > 0
		ok = ok and known
		print("  %s -> %s%s  (%s)" % [id, area, "" if known else "  BROKEN", str(overrides[id].get("why", ""))])
	print("SIMULATOR (80): %s" % str(ExamBlueprint.apportion(80, capacity)))
	for size in [10, 20, 30, 40, 50]:
		var credits := {}
		var sum := {}
		for r in 16:
			var q := ExamBlueprint.apportion(size, capacity, credits)
			for k in q:
				sum[k] = int(sum.get(k, 0)) + int(q[k])
		var avg := PackedStringArray()
		for k in ExamBlueprint.keys():
			avg.append("%s %.2f" % [k, float(sum[k]) / 16.0])
		print("DRILL %d first run %s; mean over 16 runs: %s" % [size, str(ExamBlueprint.apportion(size, capacity)), ", ".join(avg)])
	quit(0 if ok else 1)
