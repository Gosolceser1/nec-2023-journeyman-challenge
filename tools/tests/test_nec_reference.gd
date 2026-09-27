extends SceneTree
## NecReference: article titles, the post-answer reference line, and the
## pre-answer "where to look" path.

var failures: Array[String] = []
var checks := 0

func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)

func eq(got, want, label: String) -> void:
	check(got == want, "%s: got '%s', want '%s'" % [label, str(got), str(want)])


func _init() -> void:
	print("=== article_title ===")
	eq(NecReference.article_title("NEC 210.8(A)"), "Branch Circuits", "known article")
	eq(NecReference.article_title("Table 310.16"), "Conductors for General Wiring", "table number")
	eq(NecReference.article_title("NEC 999.1"), "NEC Article 999", "unknown article")
	eq(NecReference.article_title(""), "General knowledge", "empty")
	eq(NecReference.article_title("Ohm's law"), "Ohm's law", "no article number")

	print("=== format_reference ===")
	eq(NecReference.format_reference({"article": "NEC 250.66", "article_title": "Grounding and Bonding"}),
		"Article 250 Grounding and Bonding — NEC 250.66", "with title")
	eq(NecReference.format_reference({"article": "NEC 230.79"}), "Article 230 Services — NEC 230.79", "title looked up")
	eq(NecReference.format_reference({"article": "General math"}), "General math", "no article number")
	eq(NecReference.format_reference({}), "General knowledge", "no article")

	print("=== lookup_path ===")
	eq(NecReference.lookup_path({"article": "NEC 210.8(A)", "article_title": "Branch Circuits"}),
		"NEC 2023  ►  Chapter 2: Wiring and Protection  ►  Article 210 (Branch Circuits)", "section")
	eq(NecReference.lookup_path({"article": "NEC 310.16"}),
		"NEC 2023  ►  Chapter 3: Wiring Methods and Materials  ►  Article 310", "no title")
	eq(NecReference.lookup_path({"article": "Chapter 9, Table 8"}), "NEC 2023  ►  Chapter 9: Tables", "chapter only")
	eq(NecReference.lookup_path({"article": "NFPA 70E"}),
		"NFPA 70E  ►  Standard for Electrical Safety in the Workplace", "NFPA 70E")
	eq(NecReference.lookup_path({"article": "General math"}), "CALCULATION  ►  Basic Ohm's Law / General Math", "math")
	eq(NecReference.lookup_path({"article": "Trade practice", "formula": "P = I x E"}),
		"CALCULATION  ►  Basic Ohm's Law / General Math", "formula record")
	eq(NecReference.lookup_path({"article": "General knowledge"}),
		"GENERAL TRADE KNOWLEDGE  ►  Standard Electrical Practice", "general knowledge")
	eq(NecReference.lookup_path({"article": "Something else"}), "", "unknown")

	print("=== reference-seeking prompts ===")
	check(NecReference.is_reference_seeking("Table ___ lists ampacities."), "table blank")
	check(NecReference.is_reference_seeking("Which ARTICLE ___ covers services?"), "article blank, any case")
	check(not NecReference.is_reference_seeking("Which table lists ampacities?"), "no blank")
	check(not NecReference.is_reference_seeking("The minimum is ___ inches."), "blank but not a reference")
	eq(NecReference.chapter_only_path("NEC 2023  ►  Chapter 2: Wiring and Protection  ►  Article 210 (Branch Circuits)"),
		"NEC 2023  ►  Chapter 2: Wiring and Protection", "drops the article")
	eq(NecReference.chapter_only_path("NEC 2023  ►  Chapter 9: Tables"), "NEC 2023  ►  Chapter 9: Tables", "already chapter only")

	print("=== bank sweep ===")
	var records := BankLoader.load_records()
	var no_path := 0
	for rec in records:
		check(NecReference.format_reference(rec) != "", "%s has a reference line" % rec.get("id", "?"))
		if NecReference.lookup_path(rec) == "":
			no_path += 1
	print("  %d records, %d without a lookup path" % [records.size(), no_path])
	check(no_path == 0, "every record has a lookup path (%d missing)" % no_path)

	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
