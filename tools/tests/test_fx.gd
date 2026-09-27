extends SceneTree
## Pure helpers behind the visual layer: NEC chapter mapping for the results
## breakdown, the stats -> rows conversion, gauge tinting, and a bank sweep that
## every record's article maps to a real chapter bucket.

var failures: Array[String] = []
var checks := 0

func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func _init() -> void:
	print("=== ChapterBars.chapter_of ===")
	var cases := {
		"310.16": 3, "Table 250.66": 2, "NEC 110.26(E)(1)": 1, "Chapter 9, Table 4": 9,
		"Chapter 9 Table 8": 9, "Table 310.15(B)(1)(1)": 3, "680.21(C) and 680.5(B)": 6,
		"NFPA 70E 130.2": 0, "General knowledge": 0, "General math": 0, "": 0,
		"Article 100 definition": 1, "220.14(H)": 2, "547.30": 5,
	}
	for article in cases:
		var got := ChapterBars.chapter_of(article)
		check(got == int(cases[article]), "chapter_of(%s) = %d, want %d" % [article, got, int(cases[article])])

	print("=== ChapterBars.rows_from_stats ===")
	var rows := ChapterBars.rows_from_stats({3: [2, 3], 0: [1, 1], 1: [0, 2]})
	check(rows.size() == 3, "three rows")
	check(str(rows[0]["label"]).begins_with("Trade"), "chapter 0 sorts first")
	check(str(rows[1]["label"]).begins_with("Ch 1"), "chapter 1 second")
	check(int(rows[2]["correct"]) == 2 and int(rows[2]["total"]) == 3, "counts carried")
	check(ChapterBars.rows_from_stats({}).is_empty(), "empty stats -> no rows")

	print("=== ResultGauge.tint_for ===")
	check(ResultGauge.tint_for(75.0, 75.0) == Color("34d399"), "exactly passing is green")
	check(ResultGauge.tint_for(74.9, 75.0) == Color("fbbf24"), "just below is amber")
	check(ResultGauge.tint_for(59.0, 75.0) == Color("f87171"), "well below is red")

	print("=== StreakMeter.segment_color ===")
	check(StreakMeter.segment_color(0).is_equal_approx(Color("38bdf8")), "first segment cyan")
	check(StreakMeter.segment_color(StreakMeter.SEGMENTS - 1).is_equal_approx(Color("fbbf24")), "last segment amber")

	print("=== bank sweep: article -> chapter bucket ===")
	var bank = JSON.parse_string(FileAccess.get_file_as_string("res://data/question_bank.json"))
	var bad: Array[String] = []
	var n := 0
	if bank is Dictionary:
		for rec in bank.get("records", []):
			n += 1
			var ch := ChapterBars.chapter_of(str(rec.get("article", "")))
			if not ChapterBars.CHAPTER_NAMES.has(ch):
				bad.append(str(rec.get("id", "?")))
	check(n > 0, "bank loaded")
	check(bad.is_empty(), "records without a chapter bucket: %s" % str(bad))
	print("    swept %d records" % n)

	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	for f in failures:
		print("  - %s" % f)
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
