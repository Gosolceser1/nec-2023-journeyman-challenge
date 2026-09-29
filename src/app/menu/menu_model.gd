class_name MenuModel
extends RefCounted
## What the main menu shows, worked out from the question bank, the deck's
## study stats and StudyProgress. Node-free. Nothing here names an exam: the
## practice exams are the bank's "exam" labels, a family is a label without
## its trailing "#N" ("Open Book Exam #3" -> "Open Book Exam"), and a newly
## imported exam or family shows up by itself. data/menu.json may order the
## families and give them short titles; unknown ones follow in bank order.

const SPEC_PATH := "res://data/menu.json"

static var _spec: Dictionary = {}
static var _label_re := RegEx.create_from_string("^(.*?)\\s*#\\s*(\\d+)\\s*$")


static func spec() -> Dictionary:
	if _spec.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(SPEC_PATH)) if FileAccess.file_exists(SPEC_PATH) else null
		_spec = parsed if parsed is Dictionary else {"tabs": [], "blocks": {}}
	return _spec


static func block(kind: String) -> Dictionary:
	var b = spec().get("blocks", {}).get(kind, {})
	return b if b is Dictionary else {}


## "{name}" placeholders filled from vars; unknown ones stay as written.
static func fill(template: String, vars: Dictionary) -> String:
	var out := template
	for k in vars:
		out = out.replace("{%s}" % k, str(vars[k]))
	return out


## {"family": "Open Book Exam", "number": 3} for "Open Book Exam #3"; a label
## without a number is a family of its own, number 0.
static func parse_label(label: String) -> Dictionary:
	var m := _label_re.search(label.strip_edges())
	if m == null:
		return {"family": label.strip_edges(), "number": 0}
	return {"family": m.get_string(1), "number": int(m.get_string(2))}


## Practice exams grouped by family:
##   [{"family", "title", "exams": [{"label", "number", "indices"}], "count"}]
## Families follow data/menu.json's family_order, then bank order; exams go by
## number; each exam's indices by question_number (bank order on ties).
static func families(records: Array) -> Array:
	var by_family := {}
	var family_seen: Array[String] = []
	var exam_of := {}
	for i in records.size():
		var label := str(records[i].get("exam", "")).strip_edges()
		if label == "":
			continue
		if not exam_of.has(label):
			var parsed := parse_label(label)
			var fam := str(parsed["family"])
			if not by_family.has(fam):
				by_family[fam] = []
				family_seen.append(fam)
			var exam := {"label": label, "number": int(parsed["number"]), "indices": [] as Array[int]}
			exam_of[label] = exam
			(by_family[fam] as Array).append(exam)
		(exam_of[label]["indices"] as Array[int]).append(i)
	var cfg := block("exam_groups")
	var order: Array = cfg.get("family_order", [])
	var titles: Dictionary = cfg.get("family_titles", {})
	var sorted_names: Array[String] = []
	for f in order:
		if by_family.has(str(f)):
			sorted_names.append(str(f))
	for f in family_seen:
		if not sorted_names.has(f):
			sorted_names.append(f)
	var out: Array = []
	for fam in sorted_names:
		var exams: Array = by_family[fam]
		exams.sort_custom(func(a, b): return int(a["number"]) < int(b["number"]) or (int(a["number"]) == int(b["number"]) and str(a["label"]) < str(b["label"])))
		var count := 0
		for e in exams:
			var idx: Array[int] = e["indices"]
			idx.sort_custom(func(a, b): return _question_number(records[a], a) < _question_number(records[b], b))
			count += idx.size()
		out.append({"family": fam, "title": str(titles.get(fam, fam)), "exams": exams, "count": count})
	return out


static func _question_number(record: Dictionary, fallback: int) -> float:
	var n = record.get("question_number", null)
	return float(n) if n is float or n is int else 1e6 + fallback


## Seen and accuracy over a set of records from QuestionDeck.history():
## {"questions", "seen", "right", "answers"}.
static func progress(records: Array, indices: Array, history: Dictionary) -> Dictionary:
	var out := {"questions": indices.size(), "seen": 0, "right": 0, "answers": 0}
	for i in indices:
		var h = history.get(str(records[i].get("id", "")))
		if h == null:
			continue
		out["seen"] += 1
		out["right"] += int(h["right"])
		out["answers"] += int(h["answers"])
	return out


## Records whose latest answer was wrong, in bank order, at most limit.
static func missed_indices(records: Array, history: Dictionary, limit: int) -> Array[int]:
	var out: Array[int] = []
	for i in records.size():
		var h = history.get(str(records[i].get("id", "")))
		if h != null and not bool(h["last_right"]):
			out.append(i)
			if out.size() >= limit:
				break
	return out


## How many tiles a page of a grid holds, and how many pages n tiles need.
static func page_count(n: int, per_page: int) -> int:
	return maxi(1, ceili(float(n) / float(maxi(per_page, 1))))
