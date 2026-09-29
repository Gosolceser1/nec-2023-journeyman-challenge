extends SceneTree
## Question and choice shuffling, statistically: every new run is reshuffled,
## the first question is a fair pick, answer choices move but grading, letters
## on screen and the spoken letters all follow them. The deck itself (areas,
## coverage, reviews, saving) is covered by test_question_deck.gd.
## Seeds are fixed so the suite is repeatable; the chi-square bounds are at
## p = 0.001.

const SpeechText = preload("res://src/speech/speech_text.gd")
const LETTERS := ["A", "B", "C", "D"]

var failures: Array[String] = []
var checks := 0
var bank: Array = []
## Size of the NEC pool, read from the bank.
var nec := 0

func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func _session(seed_value: int) -> QuizSession:
	var s := QuizSession.new()
	s.records = bank
	s.rng.seed = seed_value
	return s


## Upper chi-square bound at p = 0.001 (Wilson-Hilferty).
func _chi_bound(df: int) -> float:
	var z := 3.090
	var k := 2.0 / (9.0 * df)
	return df * pow(1.0 - k + z * sqrt(k), 3)


func _chi(counts: Array, expected: float) -> float:
	var x := 0.0
	for c in counts:
		x += pow(float(c) - expected, 2) / expected
	return x


func _initialize() -> void:
	bank = BankLoader.load_records()
	check(bank.size() == BankLoader.declared_count(), "every declared record loads (%d)" % bank.size())
	nec = BankLoader.count_in_section(bank, BankLoader.SECTION_NEC)
	check(nec > 0 and nec == bank.size() - BankLoader.count_in_section(bank, BankLoader.SECTION_NE_STATE_LAW), "%d of them are NEC questions" % nec)
	var snapshot: Array = bank.duplicate(true)
	_rng_isolation()
	_modes()
	_first_question_uniform()
	_choice_rules()
	_choice_uniform()
	_grading_every_record()
	_speech_follows_display()
	await _scene()
	check(bank == snapshot, "no record was changed by shuffling or grading")
	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)


func _rng_isolation() -> void:
	print("=== session RNG: its own, randomized, seedable ===")
	seed(123)
	var a := QuizSession.new()
	a.records = bank
	a.begin(10, 60, true, "A")
	seed(123)
	var b := QuizSession.new()
	b.records = bank
	b.begin(10, 60, true, "B")
	check(a.order != b.order, "the global seed() does not fix the question order")
	var c := _session(7)
	var d := _session(7)
	c.begin(80, 60, true, "C")
	d.begin(80, 60, true, "D")
	check(c.order == d.order and c.choice_orders == d.choice_orders, "an injected seed repeats questions and choice orders")
	var e := _session(8)
	e.begin(80, 60, true, "E")
	check(e.order != c.order, "another seed gives another order")


## Session sizes the menu offers (data/menu.json drill sizes, the simulator);
## listen mode uses the same draw untimed.
func _mode_sizes() -> Array[int]:
	var out: Array[int] = []
	for s in MenuModel.block("drill_sizes").get("sizes", []):
		out.append(int(s["n"]))
	out.append(ExamBlueprint.scored_items())
	return out


func _modes() -> void:
	print("=== every mode: size, no duplicates, new order each run ===")
	for size in _mode_sizes():
		var s := _session(1000 + size)
		var bad_size := 0
		var dupes := 0
		var same_order := 0
		var prev: Array[int] = []
		for r in 12:
			s.begin(size, size * ExamBlueprint.seconds_per_item(), true, "Mode", size == ExamBlueprint.scored_items())
			if s.order.size() != size or s.session_length != size:
				bad_size += 1
			var run := {}
			for i in s.order:
				if run.has(i) or i < 0 or i >= bank.size():
					dupes += 1
				run[i] = true
			if s.order == prev:
				same_order += 1
			prev = s.order.duplicate()
		check(bad_size == 0, "%d-question runs have %d questions" % [size, size])
		check(dupes == 0, "%d-question runs: no duplicate or invalid index within a run (%d)" % [size, dupes])
		check(same_order == 0, "%d-question runs: every run has a new order" % size)
	var listen := _session(55)
	listen.begin(10, 9999, false, "Listen")
	check(listen.order.size() == 10 and not listen.timed_session, "listen draws the same way, untimed")
	var all := _session(56)
	all.begin(9999, 60, false, "All")
	var uniq := {}
	for i in all.order:
		uniq[i] = true
	check(all.order.size() == nec and uniq.size() == nec, "a whole-bank run holds each question once")
	for first in [100, 250, nec]:
		all.begin(first, 60, false, "Part")
		all.begin(9999, 60, false, "All again")
		uniq.clear()
		for i in all.order:
			uniq[i] = true
		check(uniq.size() == nec, "a whole-bank run after a %d-question run still holds each question once" % first)


## A question's chance to open a run is its area's share of the run spread
## evenly over the area: the first drill's fixed split for fresh sessions,
## the blueprint weight on average for consecutive drills.
func _first_question_uniform() -> void:
	print("=== first question of a new run: a fair pick within the blueprint ===")
	var by_area := ExamBlueprint.indices_by_area(bank)
	var capacity := {}
	for k in by_area:
		capacity[k] = (by_area[k] as Array).size()
	var first_split := ExamBlueprint.apportion(10, capacity)
	var n := nec * 25
	var counts: Array = []
	counts.resize(bank.size())
	counts.fill(0)
	var firsts_long: Array = []
	firsts_long.resize(bank.size())
	firsts_long.fill(0)
	var long_run := _session(99)
	for k in n:
		var s := _session(50000 + k)
		s.begin(10, 60, true, "First")
		counts[s.order[0]] += 1
		long_run.begin(10, 60, true, "Next")
		firsts_long[long_run.order[0]] += 1
	var bound := _chi_bound(nec - 1)
	var x := 0.0
	var y := 0.0
	for k in by_area:
		var size: int = (by_area[k] as Array).size()
		var fresh := float(n) * int(first_split[k]) / 10.0 / size
		var steady := float(n) * ExamBlueprint.items(k) / float(ExamBlueprint.scored_items()) / size
		for i in by_area[k]:
			x += pow(counts[i] - fresh, 2) / fresh
			y += pow(firsts_long[i] - steady, 2) / steady
	print("  fresh sessions: chi-square %.1f (df %d, bound %.1f)" % [x, nec - 1, bound])
	check(x < bound, "first question of fresh sessions: chi2 %.1f < %.1f" % [x, bound])
	print("  consecutive runs of one session: chi-square %.1f" % y)
	check(y < bound, "first question across consecutive runs: chi2 %.1f < %.1f" % [y, bound])


func _choice_rules() -> void:
	print("=== choices that stay put ===")
	var locked: Array[String] = []
	var pinned: Array[String] = []
	for rec in bank:
		if ChoiceOrder.is_locked(rec):
			locked.append(str(rec["id"]))
			continue
		var answers: Array = rec["answers"]
		for i in answers.size():
			if ChoiceOrder.is_pinned_choice(str(answers[i])):
				pinned.append("%s %s '%s'" % [rec["id"], LETTERS[i], answers[i]])
	print("  not shuffled (%d): %s" % [locked.size(), ", ".join(locked)])
	print("  pinned choices (%d):" % pinned.size())
	for p in pinned:
		print("    ", p)
	for id in ["final-exam-#3-041", "final-exam-#1-069", "final-exam-#5-033", "final-exam-#1-047", "final-exam-#1-013"]:
		check(locked.has(id), "%s keeps bank order (its choices or notes point at letters/labels)" % id)
	check(locked.size() < 20, "only a handful of questions are left unshuffled (%d)" % locked.size())
	for text in ["all of these", "None of these", "any of the above", "both AFCI and GFCI", "neither X nor Y"]:
		check(ChoiceOrder.is_pinned_choice(text), "'%s' is pinned" % text)
	for text in ["none required", "all grounded conductors", "wood is not permitted at all", "Both"]:
		check(not ChoiceOrder.is_pinned_choice(text), "'%s' moves" % text)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var moved_pin := 0
	var moved_locked := 0
	for r in 50:
		for rec in bank:
			var perm := ChoiceOrder.shuffled(rec, rng)
			if ChoiceOrder.is_locked(rec):
				if perm != ChoiceOrder.identity(rec):
					moved_locked += 1
				continue
			var answers: Array = rec["answers"]
			for i in answers.size():
				if ChoiceOrder.is_pinned_choice(str(answers[i])) and perm[i] != i:
					moved_pin += 1
	check(moved_locked == 0, "unshuffled questions never move (%d)" % moved_locked)
	check(moved_pin == 0, "pinned choices never leave their slot (%d)" % moved_pin)


func _choice_uniform() -> void:
	print("=== choice positions: uniform over the free slots ===")
	var s := _session(4242)
	var runs := 300
	var correct_slot := [0, 0, 0, 0]
	var per_choice := {}  # "rec:orig" -> [slot counts]
	var free_recs := 0
	var identical_consecutive := 0
	var shuffled_total := 0
	var prev := {}
	for r in runs:
		s.begin(nec, 60, false, "All")
		for ri in s.order:
			var rec: Dictionary = bank[ri]
			var perm: Array = s.choice_orders[ri]
			if ChoiceOrder.is_locked(rec):
				continue
			var free := true
			for a in rec["answers"]:
				if ChoiceOrder.is_pinned_choice(str(a)):
					free = false
			if not free:
				continue
			shuffled_total += 1
			if prev.get(ri, []) == perm:
				identical_consecutive += 1
			prev[ri] = perm
			correct_slot[perm.find(int(rec["correct_index"]))] += 1
			if ri < 40:
				for d in 4:
					var key := "%d:%d" % [ri, perm[d]]
					if not per_choice.has(key):
						per_choice[key] = [0, 0, 0, 0]
					per_choice[key][d] += 1
	var x := _chi(correct_slot, float(shuffled_total) / 4.0)
	print("  correct answer slot A..D: %s  chi-square %.2f (df 3, bound %.2f)" % [str(correct_slot), x, _chi_bound(3)])
	check(x < _chi_bound(3), "the correct answer lands on A, B, C, D equally often: chi2 %.2f" % x)
	var worst := 0.0
	for key in per_choice:
		worst = maxf(worst, _chi(per_choice[key], float(runs) / 4.0))
	# 160 choices tested at once: Bonferroni-style bound at p = 0.001 / 160.
	var z := 4.36
	var k := 2.0 / 27.0
	var bound := 3.0 * pow(1.0 - k + z * sqrt(k), 3)
	print("  worst single choice over %d choices: chi-square %.2f (bound %.2f)" % [per_choice.size(), worst, bound])
	check(worst < bound, "every choice visits every slot equally often (worst chi2 %.2f < %.2f)" % [worst, bound])
	var rate := float(identical_consecutive) / float(shuffled_total)
	print("  same choice order as the previous run: %.3f (1/24 = 0.042 expected)" % rate)
	check(rate < 0.06, "a new run reshuffles the choices (same order %.3f of the time)" % rate)


func _grading_every_record() -> void:
	print("=== every record, random choice orders: grading, texts, notes, tip letters ===")
	var s := _session(77)
	var bad_grade := 0
	var bad_text := 0
	var bad_notes := 0
	var bad_tip := 0
	var bad_stable := 0
	var marker := RegEx.create_from_string("(Correct: |Not )([A-D])(?= —|:)")
	for r in 6:
		s.begin(9999, 99999, true, "All")
		var more := true
		while more:
			var ri: int = s.order[s.current_index]
			var rec: Dictionary = bank[ri]
			var perm: Array = s.choice_order(ri)
			var shown := s.current_record()
			if s.current_record()["answers"] != shown["answers"]:
				bad_stable += 1
			var ci: int = shown["correct_index"]
			if str(shown["answers"][ci]) != str(rec["answers"][rec["correct_index"]]):
				bad_text += 1
			var notes = rec.get("choice_notes", [])
			if notes is Array and notes.size() == 4:
				for d in 4:
					if shown["choice_notes"][d] != notes[perm[d]]:
						bad_notes += 1
			var tip := str(shown.get("tip_short", ""))
			var not_letters := []
			for m in marker.search_all(tip):
				if m.get_string(1) == "Correct: " and m.get_string(2) != LETTERS[ci]:
					bad_tip += 1
				elif m.get_string(1) == "Not ":
					not_letters.append(m.get_string(2))
			for l in not_letters:
				if l == LETTERS[ci] or not_letters.count(l) > 1:
					bad_tip += 1
			s.start_question()
			var pick := ci if (ri + r) % 2 == 0 else (ci + 1 + (ri % 3)) % 4
			var res := s.submit(pick, true)
			var want_right := pick == ci
			var got_right: bool = res["verdict"] == QuizSession.Verdict.CORRECT
			if got_right != want_right or res["correct"] != ci or res["correct_original"] != int(rec["correct_index"]) \
					or res["selected_original"] != perm[pick] or res["correct_text"] != str(rec["answers"][rec["correct_index"]]):
				bad_grade += 1
			if not want_right:
				var miss: Dictionary = s.missed_questions[-1]
				if not str(miss["correct"]).begins_with(LETTERS[ci] + " — ") or not str(miss["selected"]).begins_with(LETTERS[pick] + " — ") \
						or miss["correct_index"] != int(rec["correct_index"]) or miss["selected_index"] != perm[pick]:
					bad_grade += 1
			more = s.advance()
		check(s.score + s.missed_questions.size() == nec, "run %d: score + missed == %d" % [r, nec])
	check(bad_grade == 0, "grading by original index is right for every record and pick (%d wrong)" % bad_grade)
	check(bad_text == 0, "correct_index on the display copy points at the right text (%d)" % bad_text)
	check(bad_notes == 0, "choice notes follow their choices (%d)" % bad_notes)
	check(bad_tip == 0, "the tip's Correct/Not letters are the display letters (%d)" % bad_tip)
	check(bad_stable == 0, "the choice order stays put for the whole session (%d)" % bad_stable)
	var label := RichTextLabel.new()
	var panel := InfoPanelRenderer.new()
	panel.label = label
	var wrong_rows := 0
	for ri in bank.size():
		var shown := s.display_record(ri)
		label.clear()
		if not panel.append_tip_rows(shown, str(shown.get("tip_short", ""))):
			continue
		var text := label.get_parsed_text()
		if not text.contains(" ✓ %s " % LETTERS[shown["correct_index"]]):
			wrong_rows += 1
		for d in 4:
			if d != shown["correct_index"] and not text.contains(" ✗ %s   %s" % [LETTERS[d], shown["answers"][d]]):
				wrong_rows += 1
	label.free()
	check(wrong_rows == 0, "explanation rows show display letters next to the right choices (%d)" % wrong_rows)


func _speech_follows_display() -> void:
	print("=== speech: letters spoken in display order, answer letter after answering only ===")
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var letter_in_text := RegEx.create_from_string("\\b(Option|Answer) [A-D]\\b")
	var bad := 0
	var leaks := 0
	for rec in bank:
		var perm := ChoiceOrder.shuffled(rec, rng)
		var plan: Array = SpeechText.speech_plan(rec)
		var canonical_text := {}
		for seg in plan:
			var c := int(seg["choice"])
			if c >= 0 and not bool(seg["teach"]) and str(seg["text"]) != SpeechText.letter_line(c):
				canonical_text[c] = str(seg["text"])
			if str(seg["text"]) != SpeechText.letter_line(int(seg["choice"])) and letter_in_text.search(str(seg["text"])) != null:
				bad += 1
		var shown: Array = SpeechText.display_order(plan, perm)
		var at := 1
		for d in 4:
			if str(shown[at]["text"]) != SpeechText.letter_line(d) or int(shown[at]["choice"]) != d:
				bad += 1
			at += 1
			if canonical_text.has(perm[d]):
				if str(shown[at]["text"]) != canonical_text[perm[d]] or int(shown[at]["choice"]) != d:
					bad += 1
				at += 1
		var correct_slot := perm.find(int(rec["correct_index"]))
		var first_teach := -1
		var lessons := 0
		for i in shown.size():
			if bool(shown[i]["teach"]):
				if first_teach < 0:
					first_teach = i
				if not bool(shown[i].get("aux", false)):
					lessons += 1
			elif first_teach >= 0:
				leaks += 1
		var teach_count := SpeechText.teach_segments(rec).size()
		if teach_count > 0 and (first_teach < 0 or str(shown[first_teach]["text"]) != SpeechText.letter_line(correct_slot) \
				or not bool(shown[first_teach].get("aux", false))):
			bad += 1
		if lessons != teach_count or shown.size() != plan.size() + (1 if teach_count > 0 else 0):
			bad += 1
	check(bad == 0, "each slot is read as its display letter then its choice, and the rule opens with the correct display letter (%d)" % bad)
	check(leaks == 0, "the answer part stays a contiguous tail behind the teach gate (%d)" % leaks)


func _scene() -> void:
	print("=== on screen: cards, keys, verdict text ===")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.audio = AudioSettings.new()
	main.audio_cfg_path = "user://test_shuffle_audio.cfg"
	main.session.bag_path = ""
	main.session.rng.seed = 5
	await process_frame
	var checked := 0
	for attempt in 5:
		main._start_quiz(10, 9999, true, "Shuffle")
		await process_frame
		main.menu_overlay.visible = false
		for q in main.order.size():
			main.current_index = q
			main._show_question()
			await process_frame
			await process_frame
			var ri: int = main.order[q]
			var perm: Array = main.session.choice_order(ri)
			if perm == ChoiceOrder.identity(bank[ri]):
				continue
			var shown: Dictionary = main.session.current_record()
			var cards: Array = main.answers_box.get_children()
			var texts := []
			for c in cards:
				texts.append((c as AnswerCard).answer_label.text)
			check(texts == shown["answers"], "cards show the display order")
			var ci: int = shown["correct_index"]
			var wrong := (ci + 1) % 4
			var key := InputEventKey.new()
			key.pressed = true
			key.keycode = KEY_A + wrong
			main._unhandled_input(key)
			check(main.current_answered and main.missed_questions.size() > 0, "key %s answers the card in slot %s" % [LETTERS[wrong], LETTERS[wrong]])
			check(main.feedback_body.text == "Correct answer: %s — %s" % [LETTERS[ci], shown["answers"][ci]], "verdict names the display letter: '%s'" % main.feedback_body.text)
			check((cards[ci] as AnswerCard).current_state == AnswerCard.State.CORRECT and (cards[wrong] as AnswerCard).current_state == AnswerCard.State.WRONG, "the right cards turn green and red")
			main.missed_questions.clear()
			checked += 1
			break
		main._show_menu()
		if checked >= 3:
			break
	check(checked >= 3, "checked shuffled questions on screen (%d)" % checked)
	main.queue_free()
	await process_frame
