class_name BankLoader
extends RefCounted
## Reads the question bank into normalized record dictionaries.

const BANK_PATH := "res://data/question_bank.json"
## Question pools. NEC records carry no "section" field; others name their pool
## so the NEC drills and the simulator never draw them.
const SECTION_NEC := "nec"
const SECTION_NE_STATE_LAW := "ne_state_law"

static func section_of(record: Dictionary) -> String:
	return str(record.get("section", SECTION_NEC))

static func count_in_section(records: Array, section: String) -> int:
	var count := 0
	for record in records:
		if section_of(record) == section:
			count += 1
	return count

## The record count the bank file declares ("playable"); -1 when unreadable.
## Suites compare load_records() against it instead of pinning a bank size.
static func declared_count(path: String = BANK_PATH) -> int:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	return int(parsed.get("playable", -1)) if parsed is Dictionary else -1

static func load_records(path: String = BANK_PATH) -> Array:
	var records: Array = []
	if not FileAccess.file_exists(path):
		return records
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return records
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		# ONLY "records" is authoritative. The old fallback chain also accepted a
		# top-level "questions" key, which holds the RAW pre-curation rows:
		# un-redacted stems and answers in their original units (36" instead of
		# "36 inches"). If "records" were ever missing, that fallback would have
		# silently loaded stale, partly-unredacted data - a latent answer leak.
		var source = parsed.get("records", [])
		if source is Array:
			for raw in source:
				var record := normalize_record(raw)
				if not record.is_empty():
					records.append(record)
	return records

## Schema v2 records (the validator guarantees their shape); the article
## defaults cover hand-made records in tests and tools.
static func normalize_record(raw) -> Dictionary:
	if not raw is Dictionary:
		return {}
	var record: Dictionary = raw.duplicate(true)
	if not record.has("article"):
		record["article"] = "General knowledge"
	if not record.has("article_title") or str(record.article_title).strip_edges() == "":
		record["article_title"] = NecReference.article_title(str(record.article))
	return record
