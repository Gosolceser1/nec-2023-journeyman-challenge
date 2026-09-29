class_name MathData
extends RefCounted
## Read-only access to the math study data: the NEC edition (data/edition.json),
## that edition's table values (data/<dir>/tables.json), non-NEC constants and
## the trainer, formula-card, drill and exam-solution files under data/math/.
## Everything is loaded once and cached.

const EDITION_PATH := "res://data/edition.json"
const MATH_DIR := "res://data/math/"

static var _cache: Dictionary = {}


static func _json(path: String) -> Dictionary:
	if _cache.has(path):
		return _cache[path]
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	var out: Dictionary = parsed if parsed is Dictionary else {}
	_cache[path] = out
	return out


static func edition() -> Dictionary:
	return _json(EDITION_PATH)


## Short edition label for the UI, e.g. "NEC 2023".
static func edition_label() -> String:
	return str(edition().get("short", ""))


static func tables_path() -> String:
	return "res://data/%s/tables.json" % str(edition().get("dir", "nec/2023"))


static func tables() -> Dictionary:
	return _json(tables_path()).get("tables", {})


static func table(id: String) -> Dictionary:
	return tables().get(id, {})


## A named NEC scalar value such as "220.41.va_per_ft2".
static func value(key: String) -> Variant:
	return _json(tables_path()).get("values", {}).get(key)


static func constant(key: String) -> Variant:
	var entry = _json(MATH_DIR + "constants.json").get("values", {}).get(key)
	return entry.get("value") if entry is Dictionary else null


static func constant_entry(key: String) -> Dictionary:
	var entry = _json(MATH_DIR + "constants.json").get("values", {}).get(key)
	return entry if entry is Dictionary else {}


static func problems() -> Dictionary:
	return _json(MATH_DIR + "problem_types.json")


static func types() -> Array:
	return problems().get("types", [])


static func type_def(id: String) -> Dictionary:
	for t in types():
		if str(t.get("id", "")) == id:
			return t
	return {}


static func skills() -> Array:
	return problems().get("skills", [])


static func skill_def(id: String) -> Dictionary:
	for s in skills():
		if str(s.get("id", "")) == id:
			return s
	return {}


static func levels() -> Array:
	return problems().get("levels", [])


## Problem types offered by the trainer for a skill ("" = all skills).
static func trainer_types(skill: String = "") -> Array:
	var out: Array = []
	for t in types():
		if not bool(t.get("trainer", true)):
			continue
		if skill == "" or str(t.get("skill", "")) == skill:
			out.append(t)
	return out


static func step_title(kind: String) -> String:
	return str(problems().get("step_titles", {}).get(kind, kind.capitalize()))


static func cards() -> Array:
	return _json(MATH_DIR + "formula_cards.json").get("cards", [])


static func card(id: String) -> Dictionary:
	for c in cards():
		if str(c.get("id", "")) == id:
			return c
	return {}


static func drills() -> Array:
	return _json(MATH_DIR + "drills.json").get("drills", [])


static func drill(id: String) -> Dictionary:
	for d in drills():
		if str(d.get("id", "")) == id:
			return d
	return {}


## Menu entries for the math tools (data/math/tools.json).
static func tools() -> Array:
	return _json(MATH_DIR + "tools.json").get("tools", [])


static func tool(id: String) -> Dictionary:
	for t in tools():
		if str(t.get("id", "")) == id:
			return t
	return {}


## A tool's detail line with its count filled in ("60 problem types · 3 levels").
static func tool_detail(id: String) -> String:
	var t := tool(id)
	var n := 0
	match str(t.get("count_of", "")):
		"trainer_types": n = trainer_types().size()
		"cards": n = cards().size()
		"drills": n = drills().size()
		"skills": n = skills().size()
	return str(t.get("detail", "")).replace("{n}", str(n))


static func exam_steps() -> Dictionary:
	return _json(MATH_DIR + "exam_steps.json").get("records", {})


## Exam calc questions deliberately left without steps: id -> reason.
static func exam_skips() -> Dictionary:
	return _json(MATH_DIR + "exam_steps.json").get("skip", {})


## Drops the cache (tests that swap data files).
static func reset() -> void:
	_cache.clear()
