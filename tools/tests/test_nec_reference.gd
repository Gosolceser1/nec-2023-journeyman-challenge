extends SceneTree
## NecReference: article titles, the post-answer reference line, and the
## pre-answer "where to look" path.

var failures: Array[String] = []
var checks := 0
var book := Edition.short_label()

func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)

func eq(got, want, label: String) -> void:
	check(got == want, "%s: got '%s', want '%s'" % [label, str(got), str(want)])


func _init() -> void:
	print("=== edition (data/edition.json) ===")
	var year := str(Edition.year())
	check(Edition.year() >= 2023, "edition year is set (%s)" % year)
	check(book.contains(year) and Edition.long_label().contains(year), "short and long labels name the year")
	eq(NecReference.code_book(), book, "breadcrumbs start with the edition label")
	eq(NecReference.articles_path(), Edition.data_path("articles.json"), "article table is the edition's")
	check(Edition.data_path("articles.json").contains("/%s/" % year), "edition data folder names the year")
	check(FileAccess.file_exists(NecReference.articles_path()), "edition article table exists")

	print("=== article_title ===")
	eq(NecReference.article_title("NEC 210.8(A)"), "Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal", "known article")
	eq(NecReference.article_title("314.23(E)"),
		"Outlet, Device, Pull, and Junction Boxes; Conduit Bodies; Fittings; and Handhole Enclosures", "reported 314 record")

	print("=== canonical table ===")
	eq(NecReference.chapter_of_article(314), 3, "314 is in chapter 3")
	eq(NecReference.chapter_of_article(430), 4, "430 is in chapter 4")
	eq(NecReference.chapter_of_article(90), 0, "Article 90 has no chapter")
	eq(NecReference.chapter_title(3), "Wiring Methods and Materials", "chapter 3 title")
	eq(NecReference.primary_article("314.23(E)"), 314, "section")
	eq(NecReference.primary_article("Table 310.16"), 310, "table")
	eq(NecReference.primary_article("NEC 250.66 and 250.102(C)"), 250, "first of several")
	eq(NecReference.primary_article("Neb. Rev. Stat. 81-2108"), -1, "state law")
	eq(NecReference.primary_article("311.10"), -1, "article not in the edition")
	eq(NecReference.expected_breadcrumb({"article": "314.23(E)", "article_title": "stale"}),
		book + "  ►  Chapter 3: Wiring Methods and Materials  ►  Article 314 (Outlet, Device, Pull, and Junction Boxes; Conduit Bodies; Fittings; and Handhole Enclosures)",
		"expected breadcrumb ignores a stale title")
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
		book + "  ►  Chapter 2: Wiring and Protection  ►  Article 210 (Branch Circuits)", "section")
	eq(NecReference.lookup_path({"article": "NEC 310.16"}),
		book + "  ►  Chapter 3: Wiring Methods and Materials  ►  Article 310", "no title")
	eq(NecReference.lookup_path({"article": "Chapter 9, Table 8"}), book + "  ►  Chapter 9: Tables", "chapter only")
	eq(NecReference.lookup_path({"article": "NFPA 70E"}),
		"NFPA 70E  ►  Standard for Electrical Safety in the Workplace", "NFPA 70E")
	eq(NecReference.lookup_path({"article": "General math"}), "CALCULATION  ►  General Math", "math")
	eq(NecReference.lookup_path({"article": "Trade practice", "formula": "P = I x E"}),
		"CALCULATION  ►  Ohm's Law & Power", "formula record")
	print("=== calculation topics ===")
	var calc := func(formula: String, prompt: String) -> String:
		return NecReference.lookup_path({"article": "General knowledge", "formula": formula, "prompt": prompt})
	eq(calc.call("Percent / 100 = Fraction", "60% is equivalent to ___."), "CALCULATION  ►  Percentages & Fractions", "percent is not Ohm's law")
	eq(calc.call("% Drop = ((V_panel - V_load) / V_panel) × 100", "You have 125 volts at the panel and 115 volts at the load."),
		"CALCULATION  ►  Voltage Drop", "percent voltage drop")
	eq(calc.call("Actual Feet = Drawing Inches × 4", "If the plans drawing has a scale of 1/4 inch = 1 foot"),
		"CALCULATION  ►  Plan Scale & Measurement", "plan scale")
	eq(calc.call("t = (Angle / 360) × (1 / Frequency)", "60 cycle frequency travels 90 degrees in how many seconds?"),
		"CALCULATION  ►  AC Waveform & Frequency", "AC timing")
	eq(calc.call("R_total = R_branch / Number of identical branches", "Two 2,000 ohm resistors connected in parallel."),
		"CALCULATION  ►  Series & Parallel Circuits", "parallel resistors")
	eq(calc.call("Divide the numerator by the denominator.", "The decimal equivalent for 11/16\" is ___."),
		"CALCULATION  ►  Fractions & Decimals", "fraction to decimal")
	eq(calc.call("R = K × L ÷ A", "A wire has a resistance of 5 ohms."), "CALCULATION  ►  Conductor Resistance", "wire resistance")
	eq(calc.call("Ohm's power law: amps = watts ÷ volts.", "The power is 2 W and the voltage is 20 VDC."),
		"CALCULATION  ►  Ohm's Law & Power", "Ohm's law")
	eq(NecReference.lookup_path({"article": "General calculation", "prompt": "How many are left?"}), "CALCULATION  ►  General Math", "no topic words")
	var vague := []
	for r in BankLoader.load_records():
		if NecReference.lookup_path(r) == "CALCULATION  ►  General Math":
			vague.append(r.get("id", ""))
	check(vague.is_empty(), "every bank calculation gets a specific topic (vague: %s)" % str(vague))
	eq(NecReference.lookup_path({"article": "General knowledge"}),
		"GENERAL TRADE KNOWLEDGE  ►  Standard Electrical Practice", "general knowledge")
	eq(NecReference.lookup_path({"article": "Something else"}), "", "unknown")

	print("=== reference-seeking prompts ===")
	check(NecReference.is_reference_seeking("Table ___ lists ampacities."), "table blank")
	check(NecReference.is_reference_seeking("Which ARTICLE ___ covers services?"), "article blank, any case")
	check(not NecReference.is_reference_seeking("Which table lists ampacities?"), "no blank")
	check(not NecReference.is_reference_seeking("The minimum is ___ inches."), "blank but not a reference")
	check(NecReference.is_reference_seeking("What section of the NEC covers this?", ["230.60", "545.7", "240.6", "250.66"]),
			"no blank, section numbers as choices")
	check(NecReference.is_reference_seeking("___ lists conductor dimensions.", ["300.1(C)", "300.19(A)", "Table 2, Chapter 9", "Table 5, Chapter 9"]),
			"table choices")
	check(not NecReference.is_reference_seeking("The ampacity is ___ amps.", ["31.6", "34.8", "35", "37.2"]),
			"decimal values are not citations")
	eq(NecReference.chapter_only_path(book + "  ►  Chapter 2: Wiring and Protection  ►  Article 210 (Branch Circuits)"),
		book + "  ►  Chapter 2: Wiring and Protection", "drops the article")
	eq(NecReference.chapter_only_path(book + "  ►  Chapter 9: Tables"), book + "  ►  Chapter 9: Tables", "already chapter only")

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
