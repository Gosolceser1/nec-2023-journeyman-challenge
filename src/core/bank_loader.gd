class_name BankLoader
extends RefCounted
## Reads the question bank into normalized record dictionaries.

const BANK_PATH := "res://data/question_bank.json"

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
	elif parsed is Array:
		for raw in parsed:
			var record := normalize_record(raw)
			if not record.is_empty():
				records.append(record)
	return records

static func normalize_record(raw) -> Dictionary:
	if raw is Dictionary:
		var record: Dictionary = raw.duplicate(true)
		if not record.has("answers") and record.has("choices"):
			record["answers"] = record["choices"]
		if not record.has("correct_index") and record.has("answer"):
			record["correct_index"] = record["answer"]
		if not record.has("article"):
			record["article"] = "General knowledge"
		if not record.has("article_title") or str(record.article_title).strip_edges() == "":
			record["article_title"] = NecReference.article_title(str(record.article))
		return record
	if raw is Array and raw.size() >= 4:
		var answers = raw[2] if raw[2] is Array else []
		var article := str(raw[4]) if raw.size() > 4 else "General knowledge"
		return {
			"exam": str(raw[0]),
			"prompt": str(raw[1]),
			"answers": answers,
			"correct_index": int(raw[3]),
			"article": article,
			"article_title": NecReference.article_title(article),
			"difficulty": str(raw[7]) if raw.size() > 7 else "medium"
		}
	return {}
