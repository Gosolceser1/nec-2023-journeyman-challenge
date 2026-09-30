class_name HuntKeywords
extends RefCounted
## Code-book hunt keywords: the stem words to look up in the printed NEC's
## Index, from data/<edition dir>/hunt_keywords.json (written by
## tools/pipeline/hunt_keywords.py, which also keeps them from naming the
## correct choice). Pre-answer the stem colors them and the lookup box names
## the Index heading and article; the spoken question never changes.

const FILE_NAME := "hunt_keywords.json"
## The timed Full Exam is the real open-book exam: no hints there.
const EXAM_NOTE := "Off in the Full Exam, like the real test."

static var _records: Dictionary = {}
static var _loaded := false


static func records() -> Dictionary:
	if not _loaded:
		_loaded = true
		var path := Edition.data_path(FILE_NAME)
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
		_records = parsed.get("records", {}) if parsed is Dictionary else {}
	return _records


## {"keywords": [{"text", "index", "article"}], "show_article": bool}, or {}
## for records with nothing to look up (state law, math, trade knowledge).
static func for_record(record: Dictionary) -> Dictionary:
	var entry = records().get(str(record.get("id", "")), {})
	return entry if entry is Dictionary else {}


static func keywords(record: Dictionary) -> Array:
	var list = for_record(record).get("keywords", [])
	return list if list is Array else []


static func enabled(setting_on: bool, is_exam: bool) -> bool:
	return setting_on and not is_exam


## "Art. 680", "Chapter 9"; "" when the stem asks for the reference itself.
static func article_label(record: Dictionary, keyword: Dictionary) -> String:
	if not bool(for_record(record).get("show_article", false)):
		return ""
	var article := str(keyword.get("article", ""))
	if article == "" or article.begins_with("Chapter"):
		return article
	return "Art. " + article


## One Index entry: "Swimming pools → Art. 680" (heading only when hidden).
static func entry_text(record: Dictionary, keyword: Dictionary) -> String:
	var where := article_label(record, keyword)
	var heading := str(keyword.get("index", ""))
	return heading + ("  →  " + where if where != "" else "")


## The lookup-box line: "INDEX  Swimming pools → Art. 680  ·  Receptacles → Art. 406".
static func index_line(record: Dictionary, only: int = -1) -> String:
	var parts: Array[String] = []
	var list := keywords(record)
	for i in list.size():
		if only < 0 or i == only:
			parts.append(entry_text(record, list[i]))
	return "INDEX  " + "  ·  ".join(parts) if not parts.is_empty() else ""


## One keyword's [hint] in the stem (KeywordStemLabel never shows it).
static func tooltip(record: Dictionary, keyword: Dictionary) -> String:
	var where := article_label(record, keyword)
	var tip := "Look up \"%s\" in the Index" % str(keyword.get("index", ""))
	return tip + (", then go to " + where if where != "" else "")


## The [hint] a keyword carries in the stem; RichTextLabel.get_tooltip() at a
## point returns it, which is how a finger finds its keyword (HuntView).
static func hint_text(record: Dictionary, keyword: Dictionary) -> String:
	return tooltip(record, keyword).replace("]", ")").replace("[", "(").replace("\"", "'")


static func escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]")


static func _is_word_char(c: String) -> bool:
	return c != "" and (c.to_lower() != c.to_upper() or c.is_valid_int())


## Where `text` sits in `prompt` as a whole word ("wire" not inside "wireless")
## and clear of `taken` spans; else its first free occurrence; -1 when none.
static func find_span(prompt: String, text: String, taken: Array = []) -> int:
	if text == "":
		return -1
	var loose := -1
	var at := prompt.find(text)
	while at >= 0:
		var free := true
		for span in taken:
			if at < int(span["end"]) and at + text.length() > int(span["start"]):
				free = false
		if free:
			var before := prompt.substr(at - 1, 1) if at > 0 else ""
			var after := prompt.substr(at + text.length(), 1)
			var whole := not (_is_word_char(text.left(1)) and _is_word_char(before)) \
					and not (_is_word_char(text.right(1)) and _is_word_char(after))
			if whole:
				return at
			if loose < 0:
				loose = at
		at = prompt.find(text, at + 1)
	return loose


## The stem as BBCode with each keyword colored once, as a whole word where the
## stem allows (a [url] and [hint] let hover and tap single it out); parsed
## text equals `prompt` exactly. Keywords are `color` on a `tint` background;
## `looks` maps a keyword index to its own [text color, background].
static func stem_bbcode(record: Dictionary, prompt: String, color: Color, show: bool,
		tint := Color.TRANSPARENT, looks := {}) -> String:
	var spans: Array = []
	var list := keywords(record) if show else []
	for i in list.size():
		var text := str(list[i].get("text", ""))
		var at := find_span(prompt, text, spans)
		if at >= 0:
			spans.append({"start": at, "end": at + text.length(), "i": i})
	spans.sort_custom(func(a, b): return a["start"] < b["start"])
	var out := ""
	var pos := 0
	for span in spans:
		out += escape_bbcode(prompt.substr(pos, span["start"] - pos))
		var i: int = span["i"]
		var look: Array = looks.get(i, [color, tint])
		var word := "[color=#%s]%s[/color]" % [(look[0] as Color).to_html(false), escape_bbcode(prompt.substr(span["start"], span["end"] - span["start"]))]
		if (look[1] as Color).a > 0.0:
			word = "[bgcolor=#%s]%s[/bgcolor]" % [(look[1] as Color).to_html(true), word]
		out += "[url=%d][hint=%s]%s[/hint][/url]" % [i, hint_text(record, list[i]), word]
		pos = span["end"]
	return out + escape_bbcode(prompt.substr(pos))
