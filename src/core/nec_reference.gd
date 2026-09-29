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

## The one table of the edition's chapter and article titles
## (data/<edition dir>/articles.json). The bank builder and validator read the
## same file.
static func articles_path() -> String:
	return Edition.data_path("articles.json")

static var _table: Dictionary = {}

static func _articles() -> Dictionary:
	if _table.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(articles_path()))
		_table = parsed if parsed is Dictionary else {"chapters": {}, "articles": {}}
	return _table

## The code book segment that starts every NEC breadcrumb: "NEC 2023".
static func code_book() -> String:
	return Edition.short_label()

## Official title of an article number in the edition, "" if the number is not an article.
static func canonical_article_title(article_number: int) -> String:
	return str((_articles()["articles"] as Dictionary).get(str(article_number), ""))

static func chapter_title(chapter: int) -> String:
	return str((_articles()["chapters"] as Dictionary).get(str(chapter), ""))

## Chapter of an NEC article number: 100-199 is Chapter 1, ..., 800-899 Chapter 8.
## Article 90 (the Introduction) is in no chapter: 0.
static func chapter_of_article(article_number: int) -> int:
	return article_number / 100 if article_number >= 100 and article_number < 900 else 0

## The article of the primary (first) citation: "314.23(E)" -> 314,
## "Table 220.42(A)" -> 220, "Article 100" -> 100; -1 when there is none.
static func primary_article(reference: String) -> int:
	if is_state_law(reference):
		return -1
	var match := RegEx.create_from_string("^(?:NEC\\s+)?(?:Table\\s+|Article\\s+)?(\\d{2,3})(?:\\.\\d|\\b)").search(reference.strip_edges())
	if match == null:
		return -1
	var number := int(match.get_string(1))
	return number if canonical_article_title(number) != "" else -1

static func article_title(reference: String) -> String:
	if is_state_law(reference):
		return BOARD_RULES_TITLE if reference.contains("NAC") else STATE_ACT_TITLE
	var match := RegEx.create_from_string("\\b(\\d{3})\\b").search(reference)
	if match == null:
		return reference if reference != "" else "General knowledge"
	var title := canonical_article_title(int(match.get_string(1)))
	return title if title != "" else "NEC Article " + match.get_string(1)

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

## The breadcrumb a record must show, built only from its primary citation and
## the canonical table (no stored title): what the validator and tests compare
## the screen against.
static func expected_breadcrumb(record: Dictionary) -> String:
	var reference := str(record.get("article", "")).strip_edges()
	var article := primary_article(reference)
	if article < 100:
		return lookup_path(record)
	var chapter := chapter_of_article(article)
	return "%s  ►  Chapter %d: %s  ►  Article %d (%s)" % [code_book(), chapter, chapter_title(chapter), article, canonical_article_title(article)]

## Where to look the answer up in the code book, chapter then article.
static func lookup_path(record: Dictionary) -> String:
	var reference := str(record.get("article", "")).strip_edges()
	if is_state_law(reference):
		var source := BOARD_RULES_TITLE if reference.contains("NAC") else STATE_ACT_TITLE
		return "%s  ►  %s" % [source.to_upper(), reference]
	var code := reference.replace("NEC ", "").strip_edges()
	var chapter_names := {}
	for key in (_articles()["chapters"] as Dictionary):
		chapter_names[int(key)] = str(_articles()["chapters"][key])
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
			return "%s  ►  Chapter %d: %s  ►  %s" % [code_book(), chapter, chapter_names[chapter], article_path]
		return "%s  ►  Chapter %d: %s" % [code_book(), chapter, chapter_names[chapter]]
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
	# "<code book>  ►  Chapter 3: ...  ►  Article 300 (...)" -> drops the article segment.
	var parts := full_path.split("►", false)
	if parts.size() >= 3:
		return parts[0].strip_edges() + "  ►  " + parts[1].strip_edges()
	return full_path
