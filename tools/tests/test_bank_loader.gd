extends SceneTree
## BankLoader: the shipped bank loads whole and well-formed, legacy shapes are
## normalized, and only "records" is ever read.

var failures: Array[String] = []
var checks := 0

func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func _init() -> void:
	print("=== shipped bank ===")
	var records := BankLoader.load_records()
	check(records.size() == 283, "283 records load (%d)" % records.size())
	var ids := {}
	for rec in records:
		var id := str(rec.get("id", ""))
		var answers: Array = rec.get("answers", [])
		var ci := int(rec.get("correct_index", -1))
		check(id != "" and not ids.has(id), "%s: unique id" % id)
		ids[id] = true
		check(answers.size() >= 2, "%s: has answer choices" % id)
		check(ci >= 0 and ci < answers.size(), "%s: correct_index in range" % id)
		check(str(rec.get("prompt", "")).strip_edges() != "", "%s: has a prompt" % id)
		check(str(rec.get("article_title", "")).strip_edges() != "", "%s: has an article title" % id)

	print("=== normalize_record ===")
	var legacy := {"prompt": "Q?", "choices": ["a", "b", "c", "d"], "answer": 2}
	var n := BankLoader.normalize_record(legacy)
	check(n.get("answers") == ["a", "b", "c", "d"] and n.get("correct_index") == 2, "choices/answer become answers/correct_index")
	check(n.get("article") == "General knowledge" and n.get("article_title") == "General knowledge", "missing article defaults")
	check(not legacy.has("answers"), "input record is not mutated")
	var titled := BankLoader.normalize_record({"article": "NEC 250.50", "article_title": " "})
	check(titled.get("article_title") == "Grounding and Bonding", "blank title is looked up")
	var row := BankLoader.normalize_record(["X", "Q?", ["a", "b", "c", "d"], 1, "NEC 210.12", "", "", "hard"])
	check(row.get("exam") == "X" and row.get("correct_index") == 1 and row.get("difficulty") == "hard", "array row")
	check(row.get("article_title") == NecReference.canonical_article_title(210), "array row title")
	check(BankLoader.normalize_record(["too", "short"]).is_empty(), "short array rejected")
	check(BankLoader.normalize_record("text").is_empty(), "non-record rejected")

	print("=== file shapes ===")
	check(BankLoader.load_records("res://data/does_not_exist.json").is_empty(), "missing file gives no records")
	var tmp := "user://test_bank_loader.json"
	_write(tmp, JSON.stringify({"questions": [{"prompt": "raw", "answers": ["a", "b"], "correct_index": 0}]}))
	check(BankLoader.load_records(tmp).is_empty(), "raw 'questions' key is never read (answer-leak guard)")
	_write(tmp, JSON.stringify([{"prompt": "Q?", "answers": ["a", "b"], "correct_index": 0}, 42]))
	check(BankLoader.load_records(tmp).size() == 1, "top-level array, invalid entries skipped")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))

	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
