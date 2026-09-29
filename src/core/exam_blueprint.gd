class_name ExamBlueprint
extends RefCounted
## The licensing exam's content outline (data/exam_blueprint.json): subject
## areas, scored items per area, and which NEC chapters feed each area. Every
## record belongs to exactly one area: an explicit override by question id,
## else the chapter of its article (ChapterBars.chapter_of; 0 = no NEC
## article), else the first area. Records outside the NEC pool (a "section"
## such as ne_state_law, see BankLoader.section_of) have no area: "".

const PATH := "res://data/exam_blueprint.json"

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = parsed if parsed is Dictionary else {"areas": [], "overrides": {}}
	return _data


static func areas() -> Array:
	return data().get("areas", [])


## Area keys in outline order.
static func keys() -> PackedStringArray:
	var out := PackedStringArray()
	for a in areas():
		out.append(str(a["key"]))
	return out


static func items(key: String) -> int:
	for a in areas():
		if str(a["key"]) == key:
			return int(a["items"])
	return 0


static func title(key: String) -> String:
	for a in areas():
		if str(a["key"]) == key:
			return str(a["title"])
	return key


## Exam time in minutes and the pass mark in percent, from the bulletin.
static func minutes() -> int:
	return int(data().get("minutes", 0))


static func pass_percent() -> int:
	return int(data().get("pass_percent", 0))


static func scored_items() -> int:
	var total := 0
	for a in areas():
		total += int(a["items"])
	return total


static func area_of(record: Dictionary) -> String:
	if BankLoader.section_of(record) != BankLoader.SECTION_NEC:
		return ""
	var override = data().get("overrides", {}).get(str(record.get("id", "")))
	if override is Dictionary and items(str(override.get("area", ""))) > 0:
		return str(override["area"])
	var chapter := ChapterBars.chapter_of(str(record.get("article", "")))
	for a in areas():
		if (a["chapters"] as Array).has(float(chapter)) or (a["chapters"] as Array).has(chapter):
			return str(a["key"])
	return keys()[0] if not keys().is_empty() else ""


## area key -> record indices, every area present (possibly empty). Records
## with no area are left out.
static func indices_by_area(records: Array) -> Dictionary:
	var out := {}
	for k in keys():
		out[k] = [] as Array[int]
	for i in records.size():
		var k := area_of(records[i])
		if out.has(k):
			(out[k] as Array[int]).append(i)
	return out


## Splits count questions over the areas in blueprint proportion, never more
## than capacity[area]. Largest remainder; ties go to the heavier area, then
## outline order. With credits (area -> carried remainder, updated in place)
## the fractions carry over to the next call, so over many drills every area,
## the 5-item ones included, gets its blueprint share. An area short of
## records passes its share on to the others the same way.
static func apportion(count: int, capacity: Dictionary, credits = null) -> Dictionary:
	var ks := keys()
	var weight_sum := float(scored_items())
	var target := {}
	var alloc := {}
	var total := 0
	for k in ks:
		var carry := float(credits.get(k, 0.0)) if credits is Dictionary else 0.0
		target[k] = carry + count * items(k) / weight_sum
		alloc[k] = clampi(int(floor(target[k])), 0, int(capacity.get(k, 0)))
		total += alloc[k]
	while total > count:
		var k := _pick(ks, target, alloc, capacity, false)
		alloc[k] -= 1
		total -= 1
	while total < count:
		var k := _pick(ks, target, alloc, capacity, true)
		if k == "":
			break
		alloc[k] += 1
		total += 1
	if credits is Dictionary:
		for k in ks:
			credits[k] = clampf(target[k] - alloc[k], -1.0, 1.0)
	return alloc


## The area to give one more (grow) or take one back from: largest (grow) or
## smallest remaining fraction, heavier area first on ties.
static func _pick(ks: PackedStringArray, target: Dictionary, alloc: Dictionary, capacity: Dictionary, grow: bool) -> String:
	var best := ""
	var best_score := 0.0
	for k in ks:
		if grow and alloc[k] >= int(capacity.get(k, 0)):
			continue
		if not grow and alloc[k] <= 0:
			continue
		var score: float = (target[k] - alloc[k]) if grow else (alloc[k] - target[k])
		score += items(k) * 1e-6
		if best == "" or score > best_score:
			best = k
			best_score = score
	return best
