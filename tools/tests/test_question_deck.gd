extends SceneTree
## ExamBlueprint and QuestionDeck: subject-area classification, blueprint
## drills from per-area decks, reviews of missed questions, the simulator's
## blueprint, interleaving, fixed seeds, and the saved state.

const FILE := "user://test_question_deck.cfg"

var failures: Array[String] = []
var checks := 0
var bank: Array = []
var by_area: Dictionary = {}
var area_of: Array[String] = []
var nec_count := 0

func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func _session(seed_value: int, file := "") -> QuizSession:
	var s := QuizSession.new()
	s.records = bank
	s.rng.seed = seed_value
	s.bag_path = file
	return s


func _capacity() -> Dictionary:
	var c := {}
	for k in by_area:
		c[k] = (by_area[k] as Array).size()
	return c


## Answers every question of the session: right, wrong, or per a callable(index) -> bool.
func _answer(s: QuizSession, right) -> void:
	for j in s.order.size():
		s.current_index = j
		s.start_question()
		var rec := s.current_record()
		var ci := int(rec["correct_index"])
		var want: bool = right.call(s.order[j]) if right is Callable else bool(right)
		s.submit(ci if want else (ci + 1) % (rec["answers"] as Array).size(), true)


## Questions from areas big enough that their own deck will not bring them
## back within a few runs (the review queue is what is being tested).
func _roomy(order: Array) -> Array:
	var out: Array = []
	for i in order:
		if (by_area[area_of[i]] as Array).size() >= 17:
			out.append(i)
	return out


## A deck pass shows every question of its area once, so after any run the
## times shown within an area differ by at most one. Returns the areas that
## break that (ignoring the given questions).
func _unbalanced(shown: Dictionary, ignore: Array) -> int:
	var bad := 0
	for k in by_area:
		var lo := 1 << 30
		var hi := 0
		for i in by_area[k]:
			if ignore.has(i):
				continue
			lo = mini(lo, int(shown.get(i, 0)))
			hi = maxi(hi, int(shown.get(i, 0)))
		if hi - lo > 1:
			bad += 1
	return bad


func _initialize() -> void:
	bank = BankLoader.load_records()
	by_area = ExamBlueprint.indices_by_area(bank)
	for r in bank:
		area_of.append(ExamBlueprint.area_of(r))
	nec_count = BankLoader.count_in_section(bank, BankLoader.SECTION_NEC)
	var snapshot: Array = bank.duplicate(true)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE))
	_blueprint()
	_apportion()
	_drills()
	_clumping()
	_reviews()
	_simulator()
	_area_drill()
	_seeded()
	_saved_state()
	_mastery()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE))
	check(bank == snapshot, "no record was changed")
	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)


func _blueprint() -> void:
	print("=== blueprint: outline, classification, overrides ===")
	check(ExamBlueprint.scored_items() == int(ExamBlueprint.data()["scored_items"]), "the areas add up to the bulletin's scored items (%d)" % ExamBlueprint.scored_items())
	var want := {"general": 10, "wiring_protection": 20, "wiring_methods": 15, "equipment": 15, "special_occupancies": 10, "special_equipment": 5, "special_conditions": 5}
	for k in want:
		check(ExamBlueprint.items(k) == want[k], "%s has %d items" % [k, want[k]])
	var total := 0
	for k in by_area:
		total += (by_area[k] as Array).size()
		print("  %-30s %3d records" % [ExamBlueprint.title(k), (by_area[k] as Array).size()])
		check(not (by_area[k] as Array).is_empty(), "%s has records" % k)
	check(total == nec_count, "every NEC record is in exactly one area")
	var no_area := 0
	for i in bank.size():
		if (area_of[i] == "") != (BankLoader.section_of(bank[i]) != BankLoader.SECTION_NEC):
			no_area += 1
	check(no_area == 0 and nec_count < bank.size(), "Nebraska State Law records (%d) have no subject area" % (bank.size() - nec_count))
	var chapter_area := {0: "general", 1: "general", 2: "wiring_protection", 3: "wiring_methods", 4: "equipment", 5: "special_occupancies", 6: "special_equipment", 7: "special_conditions", 8: "general", 9: "general"}
	var overrides: Dictionary = ExamBlueprint.data().get("overrides", {})
	var mismatched := 0
	for i in bank.size():
		if area_of[i] == "":
			continue
		var id := str(bank[i]["id"])
		var expect: String = overrides[id]["area"] if overrides.has(id) else chapter_area[ChapterBars.chapter_of(str(bank[i].get("article", "")))]
		if area_of[i] != expect:
			mismatched += 1
	check(mismatched == 0, "areas follow the chapter map and the overrides (%d off)" % mismatched)
	for id in overrides:
		var found := false
		for r in bank:
			found = found or str(r["id"]) == id
		check(found and ExamBlueprint.items(str(overrides[id]["area"])) > 0, "override %s names a real question and area" % id)
	check(ExamBlueprint.area_of({"id": "x", "article": "NFPA 70E"}) == "general" and ExamBlueprint.area_of({"id": "x", "article": "Table 310.16"}) == "wiring_methods"
		and ExamBlueprint.area_of({"id": "x", "article": "700.12"}) == "special_conditions" and ExamBlueprint.area_of({"id": "x", "article": "Chapter 9, Table 8"}) == "general",
		"classifier: 70E, a Ch. 3 table, a Ch. 7 section and a Ch. 9 table")


func _apportion() -> void:
	print("=== apportionment ===")
	var cap := _capacity()
	var bad := 0
	for n in range(0, nec_count + 1):
		var q := ExamBlueprint.apportion(n, cap)
		var sum := 0
		for k in q:
			sum += q[k]
			if q[k] > cap[k] or q[k] < 0:
				bad += 1
		if sum != n:
			bad += 1
	check(bad == 0, "every size up to the pool is split exactly, within each area's records (%d bad)" % bad)
	var exam := ExamBlueprint.apportion(80, cap)
	print("  simulator: %s" % str(exam))
	for k in exam:
		var expected := mini(ExamBlueprint.items(k), cap[k])
		check(exam[k] >= expected and (exam[k] == expected or cap[k] >= ExamBlueprint.items(k)), "simulator %s: %d (blueprint %d, pool %d)" % [k, exam[k], ExamBlueprint.items(k), cap[k]])
	for k in exam:
		if cap[k] < ExamBlueprint.items(k):
			check(exam[k] == cap[k], "%s short of records: all of them are used" % k)
	for size in [10, 20, 30, 40, 50]:
		var credits := {}
		var sum := {}
		var gaps := 0
		var last_seen := {}
		var runs := 160
		for r in runs:
			var q := ExamBlueprint.apportion(size, cap, credits)
			for k in q:
				sum[k] = int(sum.get(k, 0)) + q[k]
				if q[k] > 0:
					if r - int(last_seen.get(k, -1)) > int(ceil(80.0 / (size * ExamBlueprint.items(k)))) + 1:
						gaps += 1
					last_seen[k] = r
		var worst := 0.0
		for k in sum:
			var share := mini(size * ExamBlueprint.items(k), 80 * cap[k]) / 80.0
			worst = maxf(worst, absf(float(sum[k]) / runs - share))
		check(worst <= 1.0 / runs + 0.0001 or (size == 50 and worst < 0.2), "%d-question drills: long-run share per area matches the blueprint (worst gap %.4f per run)" % [size, worst])
		check(gaps == 0, "%d-question drills: the remainder rotates, no area skipped longer than its share allows (%d)" % [size, gaps])


func _drills() -> void:
	print("=== drills: blueprint per run, no repeat within an area's pass, coverage ===")
	for size in [10, 20, 30, 40, 50]:
		var s := _session(700 + size)
		var mean := {}
		var need := 0
		for k in by_area:
			mean[k] = minf(size * ExamBlueprint.items(k) / 80.0, (by_area[k] as Array).size())
			need = maxi(need, int(ceil((by_area[k] as Array).size() / mean[k])))
		var shown := {}
		var repeats := 0
		var seen := {}
		var covered_at := -1
		var overlaps := 0
		var dupes := 0
		var prev := {}
		var per_area_total := {}
		var runs := need + 4
		for r in runs:
			s.begin(size, 60, true, "Drill")
			var run := {}
			var run_area := {}
			for i in s.order:
				if run.has(i):
					dupes += 1
				run[i] = true
				var k := area_of[i]
				run_area[k] = int(run_area.get(k, 0)) + 1
				per_area_total[k] = int(per_area_total.get(k, 0)) + 1
				shown[i] = int(shown.get(i, 0)) + 1
				seen[i] = true
				if prev.has(i) and (by_area[k] as Array).size() >= 2 * size * ExamBlueprint.items(k) / 80.0 + 2:
					overlaps += 1
			prev = run
			repeats += _unbalanced(shown, [])
			if covered_at < 0 and seen.size() == nec_count:
				covered_at = r + 1
		check(dupes == 0, "%d-question drills: no duplicate within a run" % size)
		check(repeats == 0, "%d-question drills: no question repeats before its whole area was asked (%d)" % [size, repeats])
		check(overlaps == 0, "%d-question drills: consecutive drills share no question outside areas too small to avoid it (%d)" % [size, overlaps])
		check(covered_at > 0 and covered_at <= need + 2, "%d-question drills: whole pool seen in %d runs (bound %d: slowest area + 2)" % [size, covered_at, need + 2])
		var worst := 0.0
		for k in by_area:
			worst = maxf(worst, absf(float(per_area_total.get(k, 0)) / runs - mean[k]))
		check(worst <= 1.0, "%d-question drills: per-run area counts follow the blueprint (worst mean gap %.2f)" % [size, worst])


func _clumping() -> void:
	print("=== topic spread within a run ===")
	for size in [10, 20, 50]:
		var s := _session(900 + size)
		var runs := 300
		var cap := maxi(2, ceili(size * QuestionDeck.ARTICLE_SHARE))
		var over_cap := 0
		var adjacent_article := 0
		var adjacent_area := 0
		var pairs := 0
		for r in runs:
			s.begin(size, 60, true, "Spread")
			var per := {}
			for j in s.order.size():
				var t := QuestionDeck.topic_of(bank[s.order[j]])
				per[t] = int(per.get(t, 0)) + 1
				if j > 0:
					pairs += 1
					if t == QuestionDeck.topic_of(bank[s.order[j - 1]]):
						adjacent_article += 1
					if area_of[s.order[j]] == area_of[s.order[j - 1]]:
						adjacent_area += 1
			for t in per:
				if per[t] > cap:
					over_cap += 1
		var area_rate := float(adjacent_area) / pairs
		print("  %d questions: runs over the article cap %d/%d, same article back to back %d, same area back to back %.3f" % [size, over_cap, runs, adjacent_article, area_rate])
		check(over_cap <= runs / 100, "%d-question drills: at most %d from one article in 99%% of runs (%d over)" % [size, cap, over_cap])
		check(adjacent_article == 0, "%d-question drills: never the same article twice in a row (%d)" % [size, adjacent_article])
		check(area_rate < 0.08, "%d-question drills: same subject area back to back %.3f of the time (random order: about 0.18)" % [size, area_rate])


func _reviews() -> void:
	print("=== missed questions come back, capped ===")
	var s := _session(31)
	s.begin(10, 60, true, "R1")
	var missed := _roomy(s.order).slice(0, 2)
	_answer(s, func(i): return not missed.has(i))
	s.begin(10, 60, true, "R2")
	var in_r2 := 0
	for i in missed:
		if s.order.has(i):
			in_r2 += 1
	_answer(s, true)
	s.begin(10, 60, true, "R3")
	var back := true
	for i in missed:
		back = back and s.order.has(i)
	check(in_r2 == 0 and back, "two misses come back exactly %d runs later" % QuestionDeck.REVIEW_GAP)
	_answer(s, true)
	var again := 0
	for r in 6:
		s.begin(10, 60, true, "After")
		for i in missed:
			if s.order.has(i):
				again += 1
		_answer(s, true)
	check(again == 0, "answered right on review, they are retired (%d reappearances)" % again)

	var t := _session(32)
	t.begin(20, 60, true, "All wrong")
	var wrong: Array = _roomy(t.order)
	_answer(t, false)
	var cap := int(20 * QuestionDeck.REVIEW_SHARE)
	var over := 0
	var back_at := {}
	for r in range(2, 12):
		t.begin(20, 60, true, "Next")
		var reviews := 0
		for i in t.order:
			if wrong.has(i):
				reviews += 1
				if not back_at.has(i):
					back_at[i] = r
		if reviews > cap:
			over += 1
		_answer(t, true)
	check(over == 0, "reviews never take more than %d of a 20-question drill" % cap)
	var latest := 0
	for i in back_at:
		latest = maxi(latest, back_at[i])
	var bound := 1 + QuestionDeck.REVIEW_GAP + int(ceil(20.0 / cap)) - 1
	check(back_at.size() == wrong.size() and latest <= bound, "all %d misses back by run %d (bound %d)" % [wrong.size(), latest, bound])

	var u := _session(33)
	u.begin(80, 60, true, "Exam", true)
	var exam_wrong: Array = u.order.duplicate()
	_answer(u, false)
	var v := _session(33)
	v.begin(80, 60, true, "Exam", true)
	u.begin(80, 60, true, "Exam 2", true)
	v.begin(80, 60, true, "Exam 2", true)
	u.begin(80, 60, true, "Exam 3", true)
	v.begin(80, 60, true, "Exam 3", true)
	check(u.order == v.order, "the simulator ignores the review queue: same seed, same exam with or without 80 misses queued")
	u.begin(10, 60, true, "Drill after exam")
	var from_exam := 0
	for i in u.order:
		if exam_wrong.has(i):
			from_exam += 1
	check(from_exam >= 1, "misses in the simulator still come back in later drills (%d)" % from_exam)


func _simulator() -> void:
	print("=== simulator: blueprint, fresh, interleaved ===")
	var s := _session(41)
	var want := ExamBlueprint.apportion(80, _capacity())
	var prev := {}
	var bad := 0
	var dupes := 0
	var overlap := 0
	var adjacent := 0
	var pairs := 0
	for r in 6:
		s.begin(ExamBlueprint.scored_items(), ExamBlueprint.minutes() * 60, true, Main.SIMULATION_NAME, true)
		var counts := {}
		var run := {}
		for j in s.order.size():
			var i := s.order[j]
			if run.has(i):
				dupes += 1
			run[i] = true
			counts[area_of[i]] = int(counts.get(area_of[i], 0)) + 1
			if j > 0:
				pairs += 1
				if area_of[i] == area_of[s.order[j - 1]]:
					adjacent += 1
			if prev.has(i) and 2 * int(want[area_of[i]]) <= (by_area[area_of[i]] as Array).size():
				overlap += 1
		for k in want:
			if int(counts.get(k, 0)) != int(want[k]):
				bad += 1
		prev = run
	check(s.order.size() == 80 and dupes == 0, "80 questions, no duplicates")
	check(bad == 0, "every exam matches the blueprint per area exactly")
	check(overlap == 0, "the next exam takes other questions wherever the area has enough (%d repeats)" % overlap)
	var rate := float(adjacent) / pairs
	print("  same area back to back: %.3f" % rate)
	check(rate < 0.10, "areas are mixed through the exam (%.3f back to back)" % rate)
	var small := _session(42)
	small.records = bank.slice(0, 50)
	small.begin(80, 60, true, "Small pool", true)
	var uniq := {}
	for i in small.order:
		uniq[i] = true
	check(small.order.size() == 50 and uniq.size() == 50, "a 50-question pool gives a 50-question exam, no duplicates")
	var tiny := _session(43)
	tiny.records = bank.slice(0, 5)
	tiny.begin(10, 60, true, "Tiny pool")
	check(tiny.order.size() == 5, "a 10-question drill from a 5-question pool gives 5")


func _area_drill() -> void:
	print("=== single-area drill ===")
	var s := _session(51)
	for k in by_area:
		s.begin(10, 60, true, "Area", false, k)
		var only := true
		for i in s.order:
			only = only and area_of[i] == k
		check(only and s.order.size() == mini(10, (by_area[k] as Array).size()), "%s drill: %d questions, all from the area" % [k, s.order.size()])
	var state_drawn := 0
	for step in [[50, false], [80, true], [9999, false], [9999, true]]:
		s.begin(step[0], 60, true, "NEC only", step[1])
		for i in s.order:
			if area_of[i] == "":
				state_drawn += 1
		check(s.order.size() == mini(step[0], nec_count), "%d-question %s: %d questions from the NEC pool" % [step[0], "exam" if step[1] else "drill", s.order.size()])
	check(state_drawn == 0, "drills and the simulator never draw Nebraska State Law records (%d)" % state_drawn)


func _seeded() -> void:
	print("=== fixed seed: repeatable ===")
	var a := _session(61)
	var b := _session(61)
	var same := true
	for step in [[10, false, ""], [80, true, ""], [20, false, ""], [10, false, "special_occupancies"], [50, false, ""]]:
		a.begin(step[0], 60, true, "A", step[1], step[2])
		b.begin(step[0], 60, true, "B", step[1], step[2])
		same = same and a.order == b.order and a.choice_orders == b.choice_orders
		_answer(a, func(i): return i % 3 != 0)
		_answer(b, func(i): return i % 3 != 0)
	check(same, "same seed, same sequence of modes and answers: identical runs and choice orders")


func _saved_state() -> void:
	print("=== saved state: relaunch, migration, damage, reset ===")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE))
	var shown := {}
	var repeats := 0
	var missed := -1
	var back_on := -1
	for launch in 12:
		var s := _session(1000 + launch, FILE)
		s.begin(10, 60, true, "Launch")
		for i in s.order:
			shown[i] = int(shown.get(i, 0)) + 1
			if i == missed and back_on < 0 and launch > 0:
				back_on = launch
		if launch == 0:
			missed = _roomy(s.order)[0]
			_answer(s, func(i): return i != missed)
		else:
			_answer(s, true)
		repeats += _unbalanced(shown, [missed])
	check(repeats == 0, "12 relaunches: no question repeats within its area's pass")
	check(back_on == QuestionDeck.REVIEW_GAP, "a miss from launch 1 comes back on launch %d (got %d)" % [1 + QuestionDeck.REVIEW_GAP, back_on + 1])
	var text := FileAccess.get_file_as_string(FILE)
	check(not text.contains("correct") and not text.contains("answers") and not text.contains("prompt"), "the save holds ids and counters only")
	var cfg := ConfigFile.new()
	cfg.load(FILE)
	check(int(cfg.get_value("meta", "version", 0)) == QuestionDeck.VERSION, "the save is version %d" % QuestionDeck.VERSION)

	var v1 := ConfigFile.new()
	var id5 := str(bank[5]["id"])
	v1.set_value("bag", "ids", PackedStringArray(["no-such-id", id5, id5]))
	v1.set_value("bag", "recent", PackedStringArray(["gone"]))
	v1.save(FILE)
	var m := _session(71, FILE)
	m.begin(10, 60, true, "Migrated")
	var uniq := {}
	for i in m.order:
		uniq[i] = true
	check(m.order.has(5) and m.order.size() == 10 and uniq.size() == 10, "a version 1 save loads: its deck is kept per area, unknown and repeated ids dropped")
	cfg = ConfigFile.new()
	cfg.load(FILE)
	check(not cfg.has_section_key("bag", "ids") and cfg.has_section("decks") and int(cfg.get_value("meta", "version", 0)) == QuestionDeck.VERSION, "it is saved back as version %d" % QuestionDeck.VERSION)

	var old := ConfigFile.new()
	old.set_value("meta", "version", 2)
	old.set_value("meta", "run", 5)
	old.set_value("stats", "by_id", {id5: [3, 1, 4, 6]})
	old.save(FILE)
	var o := _session(72, FILE)
	o.begin(10, 60, true, "Old stats")
	check(o.order.has(5), "stats without answer history load, and a due review comes back")

	var bad := ConfigFile.new()
	bad.set_value("meta", "run", "seven")
	bad.set_value("meta", "credits", "lots")
	bad.set_value("stats", "by_id", "none")
	bad.set_value("decks", "general", 42)
	bad.set_value("bag", "recent", {"a": 1})
	bad.save(FILE)
	var d := _session(73, FILE)
	d.begin(20, 60, true, "Damaged")
	check(d.order.size() == 20, "a damaged save starts fresh instead of failing")
	FileAccess.open(FILE, FileAccess.WRITE).store_string("[meta\nrun=")
	var e := _session(74, FILE)
	e.begin(20, 60, true, "Unreadable")
	check(e.order.size() == 20, "an unreadable save starts fresh")

	var r := _session(75, FILE)
	r.begin(10, 60, true, "Before reset")
	_answer(r, false)
	r.reset_progress()
	check(not FileAccess.file_exists(FILE) and r.deck.stats.is_empty() and r.deck.run == 0, "reset clears the save, the stats and the review queue")
	r.begin(10, 60, true, "After reset")
	check(r.deck.run == 1 and QuestionDeck.readiness(r.deck.mastery(bank)) == 0.0, "after a reset the next run starts from scratch")


func _mastery() -> void:
	print("=== mastery, readiness, weakest area ===")
	var s := _session(81)
	var wp: Array = by_area["wiring_protection"]
	var so: Array = by_area["special_occupancies"]
	s.begin(10, 60, true, "WP", false, "wiring_protection")
	_answer(s, true)
	s.begin(10, 60, true, "SO", false, "special_occupancies")
	_answer(s, false)
	var m := s.deck.mastery(bank)
	check(int(m["wiring_protection"]["right"]) == 10 and int(m["wiring_protection"]["answers"]) == 10, "wiring and protection: 10 of 10")
	check(int(m["special_occupancies"]["right"]) == 0 and int(m["special_occupancies"]["answers"]) == 10, "special occupancies: 0 of 10")
	var ready := QuestionDeck.readiness(m)
	check(absf(ready - 20.0 / 80.0) < 0.0001, "readiness weighs each area by its exam items: %.3f" % ready)
	check(QuestionDeck.weakest_area(m, bank) == "wiring_methods", "weakest: the heaviest area not yet practised (%s)" % QuestionDeck.weakest_area(m, bank))
	for k in by_area:
		if k != "wiring_protection" and k != "special_occupancies":
			s.begin(10, 60, true, "Area", false, k)
			_answer(s, true)
	m = s.deck.mastery(bank)
	check(QuestionDeck.weakest_area(m, bank) == "special_occupancies", "weakest: the lowest rolling accuracy once every area is practised")
	# The no-repeat deck cycles the whole area before a missed question returns.
	for r in ceili(float(so.size() * QuestionDeck.HISTORY) / 20.0):
		s.begin(20, 60, true, "SO again", false, "special_occupancies")
		_answer(s, true)
	m = s.deck.mastery(bank)
	check(int(m["special_occupancies"]["right"]) == int(m["special_occupancies"]["answers"]), "mastery keeps the last %d answers per question, so old misses age out" % QuestionDeck.HISTORY)
	check(absf(QuestionDeck.readiness(m) - 1.0) < 0.0001, "all areas right lately: readiness 100%")
