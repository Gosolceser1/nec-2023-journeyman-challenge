class_name QuestionDeck
extends RefCounted
## Which questions a run gets, and the study memory behind it. Node-free;
## QuizSession owns one and passes its records and RNG in. The subject areas
## and their weights come from ExamBlueprint (the licensing exam's outline).
##
## Drills (every practice size, and listen mode) share one deck per subject
## area: a shuffled pass over that area's questions, taken from the top, so no
## question repeats before its whole area has been asked. A drill's slots are
## split over the areas in blueprint proportion; the leftover fractions carry
## to the next drill so the 5-item areas still get their share. A new pass
## keeps the last drill's questions away from its top, and at most
## ARTICLE_SHARE of a run comes from one NEC article.
## A question answered wrong comes back REVIEW_GAP runs later, oldest first,
## at most REVIEW_SHARE of a drill; a right answer retires it.
## The simulator takes exactly the blueprint's count per area, least recently
## drawn first. It ignores the review queue and leaves the drill decks alone,
## so it stays an honest exam.
## Every run is interleaved: neighbours differ in article, and in area where
## the mix allows.
##
## Saved by question id, so a rebuilt bank does not scramble it. Version 1
## files (one deck, no stats) are split into the area decks. No answers or
## choices are stored.

const VERSION := 2
const REVIEW_GAP := 2
const REVIEW_SHARE := 0.25
const ARTICLE_SHARE := 0.2
## Answers per question that count toward mastery.
const HISTORY := 4

## "" keeps everything in memory only.
var path := ""
## area key -> record indices left in this pass; draws take from the end.
var decks: Dictionary = {}
## The last drill's questions, kept out of the top of the next pass.
var recent: Array[int] = []
## area key -> blueprint remainder carried to the next drill.
var credits: Dictionary = {}
## Runs drawn so far, any mode.
var run := 0
## question id -> [times drawn, times wrong, run last drawn, run due for
## review (0 = none), last HISTORY answers (bit 0 = latest, 1 = right), answers kept]
var stats: Dictionary = {}

static var _regex_cache := {}


static func _re(pattern: String) -> RegEx:
	if not _regex_cache.has(pattern):
		_regex_cache[pattern] = RegEx.create_from_string(pattern)
	return _regex_cache[pattern]


## The topic runs are spread over: the NEC article number, else the source
## label ("General knowledge", "NFPA 70E").
static func topic_of(record: Dictionary) -> String:
	var article := str(record.get("article", ""))
	if article.to_lower().contains("70e"):
		return "nfpa 70e"
	var m := _re("\\b([1-9]\\d\\d)\\b").search(article)
	return m.get_string(1) if m != null else article.strip_edges().to_lower()


## A drill of count questions; with area, from that subject area only.
func draw_drill(records: Array, count: int, rng: RandomNumberGenerator, area := "") -> Array[int]:
	load_state(records)
	run += 1
	var by_area := ExamBlueprint.indices_by_area(records)
	var pool_size := _pool_size(by_area) if area == "" else (by_area.get(area, []) as Array).size()
	count = mini(count, pool_size)
	var picked: Array[int] = []
	var taken := {}
	var per_topic := {}
	# A review counts as this pass's showing of the question.
	for i in _due(records, int(count * REVIEW_SHARE), rng, area):
		_take(records, i, picked, taken, per_topic)
		for k in decks:
			(decks[k] as Array[int]).erase(i)
	var capacity := {}
	for k in by_area:
		capacity[k] = 0 if area != "" and k != area else _count_untaken(by_area[k], taken)
	var quotas := {area: count - picked.size()} if area != "" else ExamBlueprint.apportion(count - picked.size(), capacity, credits)
	var cap := maxi(2, ceili(count * ARTICLE_SHARE))
	for k in ExamBlueprint.keys():
		for n in int(quotas.get(k, 0)):
			var i := _draw_from(records, k, by_area[k], taken, per_topic, cap, rng)
			if i < 0:
				break
			_take(records, i, picked, taken, per_topic)
	recent = picked.duplicate()
	_mark_drawn(records, picked)
	save_state(records)
	return interleave(records, picked, rng)


## The simulator: the blueprint's count per area (scaled if count is not the
## blueprint total), least recently drawn first, random among equals.
func draw_exam(records: Array, count: int, rng: RandomNumberGenerator) -> Array[int]:
	load_state(records)
	run += 1
	var by_area := ExamBlueprint.indices_by_area(records)
	count = mini(count, _pool_size(by_area))
	var capacity := {}
	for k in by_area:
		capacity[k] = (by_area[k] as Array).size()
	var quotas := ExamBlueprint.apportion(count, capacity)
	var ids := _ids_by_index(records)
	var picked: Array[int] = []
	for k in ExamBlueprint.keys():
		var key := {}
		for i in by_area[k]:
			key[i] = Vector2(float(stats.get(ids[i], [0, 0, 0])[2]), rng.randf())
		var members: Array = (by_area[k] as Array).duplicate()
		members.sort_custom(func(a, b): return key[a] < key[b])
		for i in members.slice(0, int(quotas.get(k, 0))):
			picked.append(i)
	_mark_drawn(records, picked)
	save_state(records)
	return interleave(records, picked, rng)


## Grading feedback: wrong queues the question REVIEW_GAP runs ahead, right
## retires it; both go into its answer history.
func record_result(records: Array, index: int, right: bool) -> void:
	if index < 0 or index >= records.size():
		return
	load_state(records)
	var id := str(records[index].get("id", ""))
	var st: Array = _stat(id)
	if right:
		st[3] = 0
	else:
		st[1] += 1
		st[3] = run + REVIEW_GAP
	st[4] = ((int(st[4]) << 1) | (1 if right else 0)) & ((1 << HISTORY) - 1)
	st[5] = mini(int(st[5]) + 1, HISTORY)
	stats[id] = st
	save_state(records)


## area key -> {"right", "answers", "questions"} over each question's last
## HISTORY answers.
func mastery(records: Array) -> Dictionary:
	load_state(records)
	var out := {}
	for k in ExamBlueprint.keys():
		out[k] = {"right": 0, "answers": 0, "questions": 0}
	for i in records.size():
		var st = stats.get(str(records[i].get("id", "")))
		var k := ExamBlueprint.area_of(records[i])
		if st == null or int(st[5]) == 0 or k == "":
			continue
		var m: Dictionary = out[k]
		var bits := int(st[4])
		for b in int(st[5]):
			m["right"] += (bits >> b) & 1
		m["answers"] += int(st[5])
		m["questions"] += 1
	return out


## question id -> {"right", "answers", "last_right"} over its last HISTORY
## answers, for every question answered at least once.
func history(records: Array) -> Dictionary:
	load_state(records)
	var out := {}
	for id in stats:
		var st: Array = stats[id]
		var kept := int(st[5])
		if kept == 0:
			continue
		var right := 0
		for b in kept:
			right += (int(st[4]) >> b) & 1
		out[id] = {"right": right, "answers": kept, "last_right": (int(st[4]) & 1) == 1}
	return out


## 0..1: rolling accuracy per area weighted by the blueprint; an area not yet
## practised counts as 0, so the estimate only rises with coverage.
static func readiness(mastery_by_area: Dictionary) -> float:
	var sum := 0.0
	for k in ExamBlueprint.keys():
		var m: Dictionary = mastery_by_area.get(k, {})
		if int(m.get("answers", 0)) > 0:
			sum += ExamBlueprint.items(k) * float(m["right"]) / float(m["answers"])
	return sum / maxf(1.0, float(ExamBlueprint.scored_items()))


## The area to drill next: one never practised (heaviest first), else the
## lowest rolling accuracy (heavier area on ties). Areas without questions
## are skipped.
static func weakest_area(mastery_by_area: Dictionary, records: Array) -> String:
	var by_area := ExamBlueprint.indices_by_area(records)
	var best := ""
	var best_score := 0.0
	for k in ExamBlueprint.keys():
		if (by_area[k] as Array).is_empty():
			continue
		var m: Dictionary = mastery_by_area.get(k, {})
		var acc := -1.0 if int(m.get("answers", 0)) == 0 else float(m["right"]) / float(m["answers"])
		var score := acc - ExamBlueprint.items(k) * 1e-6
		if best == "" or score < best_score:
			best = k
			best_score = score
	return best


## Forget the decks, the stats and the review queue.
func reset() -> void:
	decks.clear()
	recent.clear()
	credits.clear()
	stats.clear()
	run = 0
	if path != "" and FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Spreads a run out: never the same article twice in a row while another
## can go between, a different subject area next when there is one. The
## first question is a uniform pick from the run.
static func interleave(records: Array, picked: Array[int], rng: RandomNumberGenerator) -> Array[int]:
	var groups := {}
	var area := {}
	for i in picked:
		var t := topic_of(records[i])
		if not groups.has(t):
			groups[t] = []
			area[t] = ExamBlueprint.area_of(records[i])
		groups[t].append(i)
	var out: Array[int] = []
	var prev := ""
	var prev_area := ""
	var left := picked.size()
	while left > 0:
		var pick := ""
		for t in groups:
			if t != prev and (groups[t] as Array).size() * 2 > left:
				pick = t
		if pick == "":
			var pool: Array = []
			var other_area: Array = []
			for t in groups:
				if t != prev:
					pool.append(t)
					if area[t] != prev_area:
						other_area.append(t)
			if not other_area.is_empty():
				pool = other_area
			if pool.is_empty():
				pool = [prev]
			var total := 0
			for t in pool:
				total += (groups[t] as Array).size()
			var r := rng.randi_range(0, total - 1)
			for t in pool:
				r -= (groups[t] as Array).size()
				if r < 0:
					pick = t
					break
		var members: Array = groups[pick]
		out.append(members.pop_at(rng.randi_range(0, members.size() - 1)))
		if members.is_empty():
			groups.erase(pick)
		prev = pick
		prev_area = area[pick]
		left -= 1
	return out


## The next question from an area's deck: the highest one not in the run
## whose article still has room, else the highest one not in the run. An
## empty deck starts a new pass first. -1 if the area has nothing left.
func _draw_from(records: Array, area: String, members: Array, taken: Dictionary, per_topic: Dictionary, cap: int, rng: RandomNumberGenerator) -> int:
	for attempt in 2:
		var deck: Array[int] = decks.get(area, [] as Array[int])
		var fallback := -1
		for at in range(deck.size() - 1, -1, -1):
			var i: int = deck[at]
			if taken.has(i):
				continue
			if int(per_topic.get(topic_of(records[i]), 0)) < cap:
				fallback = at
				break
			if fallback < 0:
				fallback = at
		if fallback >= 0:
			var i: int = deck[fallback]
			deck.remove_at(fallback)
			return i
		_refill(area, members, taken, rng)
	return -1


## A new pass over one area in random order. This run's questions go to the
## bottom and the last drill's just above them, so a drill never repeats a
## question and shares one with the drill before it only when the area is
## too small to avoid it.
func _refill(area: String, members: Array, taken: Dictionary, rng: RandomNumberGenerator) -> void:
	var fresh: Array[int] = []
	var last: Array[int] = []
	var held: Array[int] = []
	for i in members:
		if taken.has(i):
			held.append(i)
		elif recent.has(i):
			last.append(i)
		else:
			fresh.append(i)
	_shuffle(fresh, rng)
	_shuffle(last, rng)
	_shuffle(held, rng)
	held.append_array(last)
	held.append_array(fresh)
	decks[area] = held


## Questions due for review this run (in area, if given), oldest due first,
## at most limit.
func _due(records: Array, limit: int, rng: RandomNumberGenerator, area := "") -> Array[int]:
	var out: Array[int] = []
	if limit <= 0:
		return out
	var index_of := _index_by_id(records)
	var due: Array = []
	for id in stats:
		var d := int(stats[id][3])
		if d > 0 and d <= run and index_of.has(id):
			var i: int = index_of[id]
			var k := ExamBlueprint.area_of(records[i])
			if k != "" and (area == "" or k == area):
				due.append([d, rng.randf(), i])
	due.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	for e in due.slice(0, limit):
		out.append(int(e[2]))
	return out


## Questions with a subject area: the NEC pool.
static func _pool_size(by_area: Dictionary) -> int:
	var n := 0
	for k in by_area:
		n += (by_area[k] as Array).size()
	return n


static func _count_untaken(members: Array, taken: Dictionary) -> int:
	var n := 0
	for i in members:
		if not taken.has(i):
			n += 1
	return n


func _take(records: Array, i: int, picked: Array[int], taken: Dictionary, per_topic: Dictionary) -> void:
	picked.append(i)
	taken[i] = true
	var t := topic_of(records[i])
	per_topic[t] = int(per_topic.get(t, 0)) + 1


func _stat(id: String) -> Array:
	return (stats.get(id, [0, 0, 0, 0, 0, 0]) as Array).duplicate()


func _mark_drawn(records: Array, picked: Array[int]) -> void:
	var ids := _ids_by_index(records)
	for i in picked:
		var st := _stat(ids[i])
		st[0] += 1
		st[2] = run
		stats[ids[i]] = st


static func _shuffle(a: Array[int], rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t := a[i]
		a[i] = a[j]
		a[j] = t


## Reads the saved state; anything malformed or no longer in the bank is
## dropped. Without a path the in-memory state carries on.
func load_state(records: Array) -> void:
	if path != "":
		var cfg := ConfigFile.new()
		if cfg.load(path) != OK:
			cfg = ConfigFile.new()
		var index_of := _index_by_id(records)
		decks = {}
		if cfg.has_section_key("bag", "ids"):
			# Version 1: one deck over the whole bank, split by area in order.
			for i in _indices_of(index_of, cfg.get_value("bag", "ids")):
				var k := ExamBlueprint.area_of(records[i]) if i >= 0 and i < records.size() else ""
				if k != "":
					if not decks.has(k):
						decks[k] = [] as Array[int]
					(decks[k] as Array[int]).append(i)
		for k in ExamBlueprint.keys():
			if cfg.has_section_key("decks", k):
				decks[k] = _indices_of(index_of, cfg.get_value("decks", k))
		recent = _indices_of(index_of, cfg.get_value("bag", "recent", PackedStringArray()))
		var saved_run = cfg.get_value("meta", "run", 0)
		run = maxi(0, int(saved_run)) if saved_run is int or saved_run is float else 0
		credits = {}
		var saved_credits = cfg.get_value("meta", "credits", {})
		if saved_credits is Dictionary:
			for k in ExamBlueprint.keys():
				var c = saved_credits.get(k, 0.0)
				credits[k] = clampf(float(c), -1.0, 1.0) if c is float or c is int else 0.0
		stats = {}
		var saved = cfg.get_value("stats", "by_id", {})
		if saved is Dictionary:
			for id in saved:
				var v = saved[id]
				if (v is Array or v is PackedInt32Array) and v.size() >= 4 and index_of.has(str(id)):
					var hist := int(v[4]) if v.size() >= 6 else 0
					var kept := clampi(int(v[5]), 0, HISTORY) if v.size() >= 6 else 0
					stats[str(id)] = [maxi(0, int(v[0])), maxi(0, int(v[1])), clampi(int(v[2]), 0, run), clampi(int(v[3]), 0, run + REVIEW_GAP), hist & ((1 << HISTORY) - 1), kept]
	for k in decks.keys():
		decks[k] = _valid(records, decks[k])
	recent = _valid(records, recent)


func save_state(records: Array) -> void:
	if path == "":
		return
	var ids := _ids_by_index(records)
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", VERSION)
	cfg.set_value("meta", "run", run)
	cfg.set_value("meta", "credits", credits)
	for k in decks:
		cfg.set_value("decks", k, _ids_of(ids, decks[k]))
	cfg.set_value("bag", "recent", _ids_of(ids, recent))
	cfg.set_value("stats", "by_id", stats)
	cfg.save(path)


static func _index_by_id(records: Array) -> Dictionary:
	var index_of := {}
	for i in records.size():
		index_of[str(records[i].get("id", ""))] = i
	return index_of


static func _ids_by_index(records: Array) -> PackedStringArray:
	var ids := PackedStringArray()
	for r in records:
		ids.append(str(r.get("id", "")))
	return ids


static func _indices_of(index_of: Dictionary, value) -> Array[int]:
	var out: Array[int] = []
	if value is PackedStringArray or value is Array:
		for id in value:
			out.append(int(index_of.get(str(id), -1)))
	return out


static func _ids_of(ids: PackedStringArray, indices: Array[int]) -> PackedStringArray:
	var out := PackedStringArray()
	for i in indices:
		out.append(ids[i])
	return out


static func _valid(records: Array, indices: Array) -> Array[int]:
	var out: Array[int] = []
	var seen := {}
	for i in indices:
		if i >= 0 and i < records.size() and not seen.has(i):
			seen[i] = true
			out.append(i)
	return out
