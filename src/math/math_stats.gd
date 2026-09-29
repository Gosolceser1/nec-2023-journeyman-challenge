class_name MathStats
extends RefCounted
## Math accuracy per skill (trainer answers plus exam calculation questions)
## and per table drill, saved in user://math_stats.cfg. The trainer's mixed
## mode picks skills with weights that favor weak and unseen ones.

const DEFAULT_PATH := "user://math_stats.cfg"
## Answers kept per id for the recent accuracy.
const RECENT := 12
## Attempts before recent accuracy counts; fewer means "still new".
const MIN_ATTEMPTS := 3
const UNSEEN_WEIGHT := 2.5

var path := DEFAULT_PATH
var _data := {}


func _init(save_path: String = DEFAULT_PATH) -> void:
	path = save_path
	load_file()


func load_file() -> void:
	_data = {}
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	for section in cfg.get_sections():
		_data[section] = {}
		for key in cfg.get_section_keys(section):
			var val = cfg.get_value(section, key)
			if val is Dictionary:
				_data[section][key] = val


func save() -> void:
	var cfg := ConfigFile.new()
	for section in _data:
		for key in _data[section]:
			cfg.set_value(section, key, _data[section][key])
	cfg.save(path)


func reset() -> void:
	_data = {}
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path) if path.begins_with("user://") else path)


## Records one answer. group: "skill" or "drill".
func record(group: String, id: String, correct: bool) -> void:
	if id.is_empty():
		return
	if not _data.has(group):
		_data[group] = {}
	var entry: Dictionary = _data[group].get(id, {"attempts": 0, "correct": 0, "recent": ""})
	entry["attempts"] = int(entry.get("attempts", 0)) + 1
	entry["correct"] = int(entry.get("correct", 0)) + (1 if correct else 0)
	var recent := str(entry.get("recent", "")) + ("1" if correct else "0")
	entry["recent"] = recent.substr(maxi(0, recent.length() - RECENT))
	_data[group][id] = entry
	save()


## Records an exam calculation question answered in a quiz under its skill.
func record_exam(record: Dictionary, correct: bool) -> void:
	var plan := MathEngine.exam_plan(record)
	if plan.is_empty():
		return
	var type_id := str(plan.get("type", ""))
	record("skill", str(MathData.type_def(type_id).get("skill", "")), correct)
	record("type", type_id, correct)


## Keeps a drill run if it beats the best one: more right, or as many in less time.
func record_best(id: String, right: int, total: int, seconds: float) -> bool:
	var prev := best(id)
	var better := prev.is_empty() or right > int(prev["right"]) \
			or (right == int(prev["right"]) and seconds < float(prev["seconds"]))
	if better:
		if not _data.has("best"):
			_data["best"] = {}
		_data["best"][id] = {"right": right, "total": total, "seconds": snappedf(seconds, 0.1)}
		save()
	return better


## {right, total, seconds} of the best run, or {}.
func best(id: String) -> Dictionary:
	return _data.get("best", {}).get(id, {})


func attempts(group: String, id: String) -> int:
	return int(_data.get(group, {}).get(id, {}).get("attempts", 0))


func correct(group: String, id: String) -> int:
	return int(_data.get(group, {}).get(id, {}).get("correct", 0))


## Accuracy over the recent answers, 0..1, or -1 when never answered.
func accuracy(group: String, id: String) -> float:
	var recent := str(_data.get(group, {}).get(id, {}).get("recent", ""))
	if recent.is_empty():
		return -1.0
	return float(recent.count("1")) / recent.length()


func weight(group: String, id: String) -> float:
	if attempts(group, id) < MIN_ATTEMPTS:
		return UNSEEN_WEIGHT
	return 1.0 + 3.0 * (1.0 - accuracy(group, id))


## A skill id picked at random, weighted toward weak and new skills.
func pick_weighted(group: String, ids: Array, rng: RandomNumberGenerator) -> String:
	if ids.is_empty():
		return ""
	var total := 0.0
	for id in ids:
		total += weight(group, str(id))
	var roll := rng.randf() * total
	for id in ids:
		roll -= weight(group, str(id))
		if roll <= 0.0:
			return str(id)
	return str(ids[-1])


## ids sorted weakest first (answered ones by accuracy, then unanswered).
func weakest(group: String, ids: Array) -> Array:
	var out := ids.duplicate()
	out.sort_custom(func(a, b):
		var aa := accuracy(group, str(a))
		var bb := accuracy(group, str(b))
		if aa < 0.0 or bb < 0.0:
			return bb < 0.0 and aa >= 0.0
		return aa < bb)
	return out
