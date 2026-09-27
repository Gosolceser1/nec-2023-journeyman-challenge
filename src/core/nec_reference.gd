class_name NecReference
extends RefCounted
## NEC article titles and the reference/lookup strings shown with a question.
## Pure string work: no nodes, no bank access.

const STATE_ACT_TITLE := "Nebraska State Electrical Act"
const BOARD_RULES_TITLE := "Nebraska State Electrical Board Rules"

## Nebraska law rather than the NEC: "Neb. Rev. Stat. 81-2113(2)" or
## "Title 100 NAC Rule 13". Their numbers are not NEC articles.
static func is_state_law(reference: String) -> bool:
	return RegEx.create_from_string("^(?:Neb\\. Rev\\. Stat\\.|Title \\d+ NAC\\b)").search(reference.strip_edges()) != null

## The code a citation belongs to, for labels such as "NEC 210.8" or
## "Nebraska law Neb. Rev. Stat. 81-2113(2)" in the results review.
static func code_label(reference: String) -> String:
	return "Nebraska law" if is_state_law(reference) else "NEC"

static func article_title(reference: String) -> String:
	if is_state_law(reference):
		return BOARD_RULES_TITLE if reference.contains("NAC") else STATE_ACT_TITLE
	var match := RegEx.create_from_string("\\b(\\d{3})\\b").search(reference)
	if match == null:
		return reference if reference != "" else "General knowledge"
	var titles := {
		100: "Definitions", 110: "Requirements for Electrical Installations",
		200: "Use and Identification of Grounded Conductors", 210: "Branch Circuits",
		215: "Feeders", 220: "Load Calculations", 225: "Outside Branch Circuits and Feeders",
		230: "Services", 240: "Overcurrent Protection", 250: "Grounding and Bonding",
		300: "Wiring Methods and Materials", 310: "Conductors for General Wiring",
		314: "Outlet, Device, Pull, and Junction Boxes", 334: "Nonmetallic-Sheathed Cable",
		344: "Rigid Metal Conduit", 358: "Electrical Metallic Tubing",
		400: "Flexible Cords and Flexible Cables", 404: "Switches",
		406: "Wiring Devices", 408: "Switchboards, Switchgear, and Panelboards",
		410: "Luminaires, Lampholders, and Lamps", 422: "Appliances",
		430: "Motors, Motor Circuits, and Controllers", 440: "Air-Conditioning Equipment",
		450: "Transformers", 500: "Hazardous Locations", 550: "Mobile Homes",
		551: "Recreational Vehicles", 590: "Temporary Installations",
		625: "Electric Vehicle Power Transfer Systems", 630: "Electric Welders",
		680: "Swimming Pools, Fountains, and Similar Installations"
	}
	return str(titles.get(int(match.get_string(1)), "NEC Article " + match.get_string(1)))

## The post-answer reference line: "Article 210 Branch Circuits — NEC 210.8(A)".
static func format_reference(record: Dictionary) -> String:
	var reference := str(record.get("article", "General knowledge"))
	var title := str(record.get("article_title", article_title(reference)))
	if is_state_law(reference):
		return "%s — %s" % [title, reference]
	var match := RegEx.create_from_string("\\b(\\d{3})\\b").search(reference)
	if match == null:
		return reference
	var article_number := match.get_string(1)
	return "Article %s %s — %s" % [article_number, title, reference]

## Where to look the answer up in the code book, chapter then article.
static func lookup_path(record: Dictionary) -> String:
	var reference := str(record.get("article", "")).strip_edges()
	if is_state_law(reference):
		var source := BOARD_RULES_TITLE if reference.contains("NAC") else STATE_ACT_TITLE
		return "%s  ►  %s" % [source.to_upper(), reference]
	var code := reference.replace("NEC ", "").strip_edges()
	var chapter_names := {
		1: "General",
		2: "Wiring and Protection",
		3: "Wiring Methods and Materials",
		4: "Equipment for General Use",
		5: "Special Occupancies",
		6: "Special Equipment",
		7: "Special Conditions",
		8: "Communications Systems",
		9: "Tables",
	}
	var chapter_match := RegEx.create_from_string("(?i)\\bChapter\\s+(\\d+)\\b").search(code)
	var chapter := 0
	if chapter_match != null:
		chapter = int(chapter_match.get_string(1))
	var section_match := RegEx.create_from_string("\\b(\\d{3}(?:\\.\\d+)?(?:\\([A-Za-z0-9]+\\))*)").search(code)
	var article_number := ""
	if section_match != null:
		var section_number := section_match.get_string(1)
		article_number = section_number.substr(0, 3)
		if chapter == 0:
			var article_value := int(article_number)
			if article_value >= 100 and article_value < 900:
				chapter = int(article_value / 100)
	if chapter_names.has(chapter):
		if article_number != "":
			var title := str(record.get("article_title", "")).strip_edges()
			var article_path := "Article " + article_number
			if title != "":
				article_path += " (" + title + ")"
			return "NEC 2023  ►  Chapter %d: %s  ►  %s" % [chapter, chapter_names[chapter], article_path]
		return "NEC 2023  ►  Chapter %d: %s" % [chapter, chapter_names[chapter]]
	if code.to_lower().contains("nfpa 70e"):
		return "NFPA 70E  ►  Standard for Electrical Safety in the Workplace"
	var article_lower := code.to_lower()
	if article_lower in ["general calculation", "general math"] or str(record.get("formula", "")) != "":
		return "CALCULATION  ►  Basic Ohm's Law / General Math"
	if article_lower == "general knowledge":
		return "GENERAL TRADE KNOWLEDGE  ►  Standard Electrical Practice"
	return ""

static func is_reference_seeking(prompt: String) -> bool:
	# True when the question asks for the reference itself ("Table ___ lists...",
	# "which article..."). Those prompts get redacted lookup aids pre-answer.
	var lowered := prompt.to_lower()
	if not lowered.contains("___"):
		return false
	return lowered.contains("table") or lowered.contains("article") or lowered.contains("section")

static func chapter_only_path(full_path: String) -> String:
	# "NEC 2023  ►  Chapter 3: ...  ►  Article 300 (...)" -> drops the article segment.
	var parts := full_path.split("►", false)
	if parts.size() >= 3:
		return parts[0].strip_edges() + "  ►  " + parts[1].strip_edges()
	return full_path
