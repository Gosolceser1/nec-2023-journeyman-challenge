extends SceneTree
## Math engine: hand-verified answers for every problem type, every exam
## calculation question solved to its keyed answer, and generated trainer
## problems at every level solved by the same steps that are shown.

const CALC_CLASSES := ["calc", "formula", "table+calc"]

var t := TReport.new()


func _init() -> void:
	if not t.run_suite_body():
		return
	_format()
	_hand_verified()
	_steps_shape()
	_exam_questions()
	_generated()
	_speech()
	_cards()
	_drills()
	_stats()
	t.report()
	quit(0 if t.failures.is_empty() else 1)


func _solve(type_id: String, inputs: Dictionary, level: int = 1) -> Dictionary:
	var sol := MathEngine.solve(type_id, inputs, level)
	t.check(sol.get("ok", false), "%s %s solves (%s)" % [type_id, str(inputs), sol.get("error", "")])
	return sol


func _near(type_id: String, inputs: Dictionary, want: float, level: int = 1) -> void:
	var sol := _solve(type_id, inputs, level)
	if not sol.get("ok", false):
		return
	var got = sol["answer"]["value"]
	t.check(absf(float(got) - want) < 1e-6, "%s %s -- got %s, want %s" % [type_id, str(inputs), str(got), str(want)])


func _text(type_id: String, inputs: Dictionary, want: String) -> void:
	var sol := _solve(type_id, inputs)
	if sol.get("ok", false):
		t.eq(str(sol["answer"]["value"]), want, "%s %s" % [type_id, str(inputs)])


func _format() -> void:
	print("=== formatting and parsing ===")
	t.eq(MathFormat.number(6500.0), "6,500", "thousands")
	t.eq(MathFormat.number(6500.0, -1, false), "6500", "keys have no commas")
	t.eq(MathFormat.number(0.0133), "0.0133", "small area")
	t.eq(MathFormat.number(27.757484, 2), "27.76", "two places")
	t.eq(MathFormat.number(20.0, 2), "20", "trailing zeros dropped")
	t.eq(MathFormat.render("{a} x {b:1} = {c}", {"a": 1500.0, "b": 2.25, "c": "x"}), "1,500 x 2.3 = x", "render")
	t.eq(MathFormat.render("{a} ÷ {missing}", {"a": 1.0}), "1 ÷ {missing}", "unknown token kept")
	t.eq(MathFormat.parse("20a"), 20.0, "20a")
	t.eq(MathFormat.parse("6,500"), 6500.0, "6,500")
	t.eq(MathFormat.parse("0.10 A"), 0.1, "0.10 A")
	t.eq(MathFormat.parse("1 1/2"), 1.5, "mixed number")
	t.eq(MathFormat.parse("two"), 2.0, "number word")
	t.check(absf(MathFormat.parse("1/240") - 1.0 / 240.0) < 1e-12, "1/240")
	t.check(is_nan(MathFormat.parse("none of these")) == false, "'none' is zero")
	t.check(is_nan(MathFormat.parse("abc")), "no number")
	t.check(MathFormat.same_value("2/5", "2/5"), "same fraction")
	t.check(not MathFormat.same_value("1/24", "1/240"), "different fractions")


func _hand_verified() -> void:
	print("=== hand-verified answers ===")
	_near("ohm_current", {"E": 120, "R": 15}, 8)
	_near("ohm_voltage", {"I": 4, "R": 12}, 48)
	_near("ohm_resistance", {"E": 240, "I": 8}, 30)
	_near("power_current", {"P": 2, "E": 20}, 0.1)
	_near("power_watts", {"E": 240, "I": 12.5}, 3000)
	_near("power_i2r", {"I": 10, "R": 0.5}, 50)
	# 10,000 ÷ (208 × 1.732) = 10,000 ÷ 360.256 = 27.7580
	_near("power_three_phase", {"kw": 10, "E": 208}, 27.76)
	_near("series_resistance", {"R1": 10, "R2": 20, "R3": 30, "R4": 0}, 60)
	_near("parallel_equal", {"R": 2000, "n": 2}, 1000)
	_near("parallel_two", {"R1": 6, "R2": 12}, 4)
	# 1 ÷ (0.1 + 0.05 + 0.0333) = 5.4545
	_near("parallel_reciprocal", {"R1": 10, "R2": 20, "R3": 30}, 5.45)
	_near("wire_resistance_scale", {"R1": 5, "lf": 3, "ad": 2}, 30)
	# 6 conductors + 1 clamps + 2 one yoke + 1 two EGCs = 10 × 2.25 in³
	_near("box_fill_volume", {"awg": "12", "n": 6, "clamps": 1, "yokes": 1, "egc": 2}, 22.5)
	# six EGCs: 1 + 2 × 1/4 = 1.5 -> 10.5 × 2.25 = 23.625
	_near("box_fill_volume", {"awg": "12", "n": 6, "clamps": 1, "yokes": 1, "egc": 6}, 23.63)
	_near("box_fill_volume", {"awg": "14", "n": 4, "clamps": 0, "yokes": 0, "egc": 0}, 8)
	# 30.3 ÷ 2.25 = 13.47 -> 13 (Table 314.16(A) lists 13), minus 2 (yoke) + 1 (clamps)
	_near("box_max_conductors", {"box": "4 × 2-1/8 in. square", "awg": "12", "yokes": 0, "clamps": 0}, 13)
	_near("box_max_conductors", {"box": "4 × 2-1/8 in. square", "awg": "12", "yokes": 1, "clamps": 1}, 10)
	# Annex C, Table C.1: 3/4 EMT holds 16 #12 THHN, 1/2 EMT holds 12 #14 THHN
	_near("conduit_fill_count", {"rw": "emt", "ins": "thhn", "ts": "3/4", "awg": "12"}, 16)
	_near("conduit_fill_count", {"rw": "emt", "ins": "thhn", "ts": "1/2", "awg": "14"}, 12)
	_near("conduit_fill_count", {"rw": "emt", "ins": "thhn", "ts": "1/2", "awg": "12"}, 9)
	_text("conduit_size", {"rw": "emt", "ins": "thhn", "n": 9, "awg": "12"}, "1/2")
	_text("conduit_size", {"rw": "emt", "ins": "thhn", "n": 10, "awg": "12"}, "3/4")
	_near("ampacity_adjusted", {"metal": "cu", "size": "12", "temp": 75, "ambient": 86, "ccc": 4}, 20)
	_near("ampacity_adjusted", {"metal": "cu", "size": "10", "temp": 90, "ambient": 112, "ccc": 3}, 34.8)
	# 55 A × 0.91 (96–104 °F, 90 °C) × 0.80 (4–6) = 40.04
	_near("ampacity_adjusted", {"metal": "cu", "size": "8", "temp": 90, "ambient": 100, "ccc": 6}, 40.04)
	# 2 × 12.9 × 16 × 100 ÷ 6,530 = 6.3216
	_near("vd_single", {"metal": "cu", "E": 120, "size": "12", "I": 16, "L": 100}, 6.32)
	# 1.732 × 12.9 × 100 × 200 ÷ 105,600 = 4.2316
	_near("vd_three", {"metal": "cu", "E": 480, "size": "1/0", "I": 100, "L": 200}, 4.23)
	_near("vd_percent", {"Vs": 125, "Vl": 115, "drop": 10}, 8)
	# 2,000 × 3 + 3,000 + 1,500 = 10,500 -> 3,000 + 7,500 × 35% = 5,625
	_near("dwelling_lighting", {"units": 1, "area": 2000, "sa": 2}, 5625)
	# 20 × 7,500 = 150,000 -> 3,000 + 117,000 × 35% + 30,000 × 25% = 51,450
	_near("dwelling_lighting", {"units": 20, "area": 1000, "sa": 2}, 51450)
	# 5,625 + 8,800 + 5,500 + 8,100 × 75% + 10,000 = 36,000 VA ÷ 240 = 150 A
	_near("dwelling_service", {"area": 2000, "rkw": 14, "dry": 5500, "wh": 4500, "dw": 1200, "disp": 900, "extra": 1500, "heat": 10, "ac": 4800}, 150)
	# three appliances stay at 100%, heat 5 kW < A/C 6 kW
	# 5,625 + 8,000 + 5,000 + 6,600 + 6,000 = 31,225 ÷ 240 = 130.1
	_near("dwelling_service", {"area": 2000, "rkw": 12, "dry": 4500, "wh": 4500, "dw": 1200, "disp": 900, "extra": 0, "heat": 5, "ac": 6000}, 130.1)
	_near("range_demand", {"n": 1, "kw": 14}, 8.8)
	_near("range_demand", {"n": 1, "kw": 11}, 8)
	_near("range_demand", {"n": 1, "kw": 12.8}, 8.4)
	_near("range_demand", {"n": 1, "kw": 12.5}, 8)
	# Column C, 3 ranges = 14 kW; 1.7 kW over -> 2 -> 10% -> 15.4
	_near("range_demand", {"n": 3, "kw": 13.7}, 15.4)
	_near("dryer_demand", {"n": 5, "w": 5500}, 23.375)
	# 13 dryers: 47% − 2% = 45% of 65,000
	_near("dryer_demand", {"n": 13, "w": 4500}, 29.25)
	# 30 dryers: 35% − 7 × 0.5% = 31.5% of 150,000
	_near("dryer_demand", {"n": 30, "w": 5000}, 47.25)
	_near("motor_flc", {"ph": 3, "V": 460, "hp": "50"}, 65)
	_near("motor_flc", {"ph": 1, "V": 230, "hp": "5"}, 28)
	_near("motor_conductor", {"V": 460, "hp": "25"}, 42.5)
	_near("motor_overload", {"fla": 20, "mk": 1}, 25)
	_near("motor_overload", {"fla": 20, "mk": 3}, 23)
	# 34 A × 250% = 85 A -> next standard 90 A; 28 A × 175% = 49 A -> 50 A
	_near("motor_ocpd", {"dev": "inverse_breaker", "V": 460, "hp": "25"}, 90)
	_near("motor_ocpd", {"dev": "dual_fuse", "V": 230, "hp": "10"}, 50)
	_near("transformer_1ph", {"kva": 25, "E": 240}, 104.17)
	# 75,000 ÷ (208 × 1.732) = 75,000 ÷ 360.256 = 208.185
	_near("transformer_3ph", {"kva": 75, "E": 208, "side": "secondary"}, 208.19)
	_near("percent_of", {"p": 80, "x": 20}, 16)
	# round(5 × 746 ÷ 0.85) = 4,388 W input; 3,730 ÷ 4,388 = 85.0%
	_near("efficiency", {"hp": 5, "eff_t": 85}, 85)
	_text("percent_to_fraction", {"p": 40}, "2/5")
	_text("percent_to_fraction", {"p": 12.5}, "1/8")
	_text("phase_time", {"deg": 90, "hz": 60}, "1/240")
	_near("scale_drawing", {"sc": 0.25, "inch": 3.5}, 14)
	_near("unit_load", {"occ": "office", "area": 5000}, 6500)
	_near("multioutlet", {"L": 12}, 540)
	_near("multioutlet", {"L": 15}, 540)
	_near("multioutlet", {"L": 15.5}, 720)
	_near("busbar_area", {"metal": "cu", "area": 1.5}, 1500)
	_near("busbar_dims", {"metal": "al", "wd": 4, "th": 0.5}, 1400)
	_near("welder_ocpd", {"i1": 43}, 90)
	_near("welder_duty", {"ip": 21, "duty": "15"}, 8.19)
	_near("tap_10ft", {"tap": 40}, 400)
	_near("garage_receptacles", {"bays": 2}, 2)
	_near("apprentice_ratio", {"lic": 3}, 9)
	# Column C, 28 ranges: 15 kW + 1 kW × 28; 45 ranges: 25 kW + 0.75 kW × 45
	_near("range_demand", {"n": 28, "kw": 8}, 43)
	_near("range_demand", {"n": 45, "kw": 10}, 58.75)
	_near("range_col_b", {"n": 8, "kw": 4}, 11.52)
	_near("range_col_b", {"n": 3, "total": 13, "sum_text": "4 + 4 + 5 kW"}, 7.15)
	# 6 × 5,000 × 75% = 22,500 W; × 70% neutral = 15,750 W
	_near("dryer_neutral", {"n": 6, "w": 4500}, 15.75)
	_near("dryer_demand", {"n": 6, "w": 4500}, 22.5)
	_near("motor_conductor", {"ph": 1, "V": 115, "hp": "3/4"}, 17.25)
	_near("motor_ocpd", {"ph": 1, "dev": "dual_fuse", "V": 115, "hp": "3"}, 60)
	_near("motor_ocpd", {"ph": 1, "dev": "inverse_breaker", "V": 230, "hp": "3"}, 45)
	_near("motor_overload_max", {"fla": 24, "mk": 1}, 33.6)
	_near("motor_overload_max", {"src": "table", "ph": 1, "V": 230, "hp": "3", "mk": 3}, 22.1)
	# 10 A × 125% + 10 A; 28 A × 125% + 15.2 A (10 and 5 hp, 230 V three-phase)
	_near("motor_feeder", {"ph": 1, "V": 230, "hp1": "1-1/2", "hp2": "1-1/2"}, 22.5)
	_near("motor_feeder", {"ph": 3, "V": 230, "hp1": "10", "hp2": "5"}, 50.2)
	# 46.2 A × 208 V × 1.732 = 16,644 VA
	_near("motor_va", {"V": 208, "hp": "15"}, 16644)
	_near("motor_va", {"V": 208, "hp": "15", "nearest": 1000}, 17000)
	_near("box_fill_mixed", {"awg1": "12", "n1": 3, "awg2": "10", "n2": 3}, 14.25)
	_near("wire_area_sum", {"ins": "xhhw", "awg1": "8", "n1": 6, "awg2": "6", "n2": 2}, 0.3802)
	_near("conduit_space_left", {"rw": "rmc", "ins": "xhhw", "ts": "1", "awg": "12", "n": 9}, 0.1921)
	# nipples: 60% column; 0.575 ÷ 0.0437 = 13.16 -> 13
	_near("conduit_fill_count", {"rw": "imc", "ins": "tw", "ts": "1", "awg": "8", "nipple": 1, "nip_len": 18}, 13)
	_near("conduit_fill_count", {"rw": "pvc80", "ins": "xhhw", "ts": "2", "awg": "6"}, 19)
	_near("dwelling_gl", {"area": 1800}, 5400)
	_near("sa_laundry", {"sa": 2, "lau": 1}, 4500)
	_near("lighting_circuits", {"area": 2500, "amps": 15}, 5)
	_near("appliance_demand", {"n": 10, "kw": 4.5}, 33.75)
	_near("appliance_demand", {"n": 3, "kw": 4.5}, 13.5)
	# 40 A × 0.91 = 36.4 A, but 240.4(D) caps 10 AWG copper at 30 A
	_near("ocpd_small_conductor", {"metal": "cu", "temp": 90, "size": "10", "ambient": 104, "ccc": 3}, 30)
	# 14 AWG 90 °C: 25 × 0.76 (123–131 °F) = 19 A -> next standard 20 A, but 240.4(D) caps it at 15 A
	_near("ocpd_small_conductor", {"metal": "cu", "temp": 90, "size": "14", "ambient": 125, "ccc": 3}, 15)
	_text("egc_size", {"metal": "cu", "rating": 80}, "8")
	_text("egc_size", {"metal": "al", "rating": 200}, "4")
	_near("fraction_to_decimal", {"num": 11, "den": 16}, 0.6875)
	_near("neutral_current", {"p1": 9000, "p2": 9500}, 79.17)
	_near("neutral_current", {"p1": 9000, "p2": 9500, "nearest": 1}, 79)
	var missing := []
	var tested := ["ohm_current", "ohm_voltage", "ohm_resistance", "power_current", "power_watts",
		"power_i2r", "power_three_phase", "series_resistance", "parallel_equal", "parallel_two",
		"parallel_reciprocal", "wire_resistance_scale", "box_fill_volume", "box_max_conductors",
		"conduit_fill_count", "conduit_size", "ampacity_adjusted", "vd_single", "vd_three", "vd_percent",
		"dwelling_lighting", "dwelling_service", "range_demand", "dryer_demand", "motor_flc",
		"motor_conductor", "motor_overload", "motor_ocpd", "transformer_1ph", "transformer_3ph",
		"percent_of", "efficiency", "percent_to_fraction", "phase_time", "scale_drawing", "unit_load",
		"multioutlet", "busbar_area", "busbar_dims", "welder_ocpd", "welder_duty", "tap_10ft",
		"garage_receptacles", "apprentice_ratio", "range_col_b", "dryer_neutral", "motor_overload_max",
		"motor_feeder", "motor_va", "box_fill_mixed", "wire_area_sum", "conduit_space_left", "dwelling_gl",
		"sa_laundry", "lighting_circuits", "appliance_demand", "ocpd_small_conductor", "egc_size",
		"fraction_to_decimal", "neutral_current"]
	for def in MathData.types():
		if not tested.has(str(def["id"])):
			missing.append(def["id"])
	t.check(missing.is_empty(), "every problem type has a hand-verified case -- missing %s" % str(missing))


func _steps_shape() -> void:
	print("=== steps ===")
	var sol := _solve("ampacity_adjusted", {"metal": "cu", "size": "12", "temp": 75, "ambient": 86, "ccc": 4})
	if not sol.get("ok", false):
		return
	var steps: Array = sol["steps"]
	t.eq(steps[0]["kind"], "formula", "starts with the formula")
	t.eq(steps[-1]["kind"], "answer", "ends with the answer")
	t.has(steps[1]["text"], "Table 310.16", "base ampacity names its table")
	t.has(steps[1]["text"], "25 A", "base ampacity value")
	t.has(steps[3]["text"], "80%", "adjustment step")
	t.eq(steps[-1]["text"], "20 A", "answer text")
	var keys := ""
	for s in steps:
		keys += str(s["keys"]) + " "
	t.has(keys, "25 × 1 × 0.8 =", "calculator keys")
	var three := _solve("power_three_phase", {"kw": 10, "E": 208})
	if three.get("ok", false):
		t.has(str(three["steps"][2]["keys"]), "M+", "memory key coaching")
	var box := _solve("box_fill_volume", {"awg": "12", "n": 6, "clamps": 0, "yokes": 0, "egc": 0})
	if box.get("ok", false):
		for s in box["steps"]:
			t.lacks(str(s["text"]), "clamps", "no clamp step without clamps")
	for def in MathData.types():
		t.check(MathData.card(str(def.get("card", ""))).size() > 0, "%s has a formula card '%s'" % [def["id"], def.get("card", "")])
		t.check(MathData.skill_def(str(def.get("skill", ""))).size() > 0, "%s has a skill" % def["id"])


func _exam_questions() -> void:
	print("=== exam calculation questions reach the keyed answer ===")
	var records := BankLoader.load_records()
	var solved := 0
	var calc := 0
	for rec in records:
		var id := str(rec.get("id", ""))
		var req := MathEngine._requirement(id)
		var cls := str(req.get("class", ""))
		var planned := not MathEngine.exam_plan(rec).is_empty()
		if not CALC_CLASSES.has(cls) and not planned:
			continue
		if CALC_CLASSES.has(cls):
			calc += 1
		if MathData.exam_skips().has(id):
			t.check(not MathData.exam_steps().has(id), "%s is either skipped or planned, not both" % id)
			continue
		var sol := MathEngine.exam_solution(rec)
		if sol.is_empty():
			t.check(not CALC_CLASSES.has(cls) or not req.has("check"), "%s (%s) has a step-by-step solution" % [id, cls])
			continue
		t.check(sol.get("ok", false), "%s solves (%s)" % [id, sol.get("error", "")])
		if not sol.get("ok", false):
			continue
		var ok := MathEngine.matches_key(sol, rec)
		var answers: Array = rec.get("answers", [])
		t.check(ok, "%s: steps give %s, key is '%s'" % [id, sol["answer"]["text"], answers[int(rec.get("correct_index", 0))] if not answers.is_empty() else "?"])
		if ok:
			solved += 1
	print("  exam questions with step-by-step solutions: %d (calc-class records: %d)" % [solved, calc])
	t.check(solved >= 20, "at least the 20 audited calc questions are solved -- %d" % solved)
	for id in MathData.exam_steps():
		var found := false
		for rec in records:
			if str(rec.get("id", "")) == id:
				found = true
				break
		t.check(found, "exam_steps.json entry %s is a bank record" % id)


func _generated() -> void:
	print("=== generated problems, every type and level ===")
	var rng := RandomNumberGenerator.new()
	rng.seed = 20230929
	for def in MathData.types():
		var id := str(def["id"])
		for level in MathEngine.level_ids():
			for i in 12:
				var sol := MathEngine.generate(id, level, rng)
				if sol.is_empty():
					t.check(false, "%s level %d generates a problem" % [id, level])
					break
				var answer: Dictionary = sol["answer"]
				t.check(not str(sol["prompt"]).contains("{"), "%s prompt fully rendered: %s" % [id, sol["prompt"]])
				var again := MathEngine.solve(id, _inputs_of(sol, def, level), level)
				t.check(again.get("ok", false) and str(again["answer"]["value"]) == str(answer["value"]), "%s re-solves to the same answer" % id)
				if answer["kind"] == "choice":
					t.check((answer["options"] as Array).has(str(answer["value"])), "%s options hold the answer" % id)
					t.check((answer["options"] as Array).size() >= 2, "%s has choices" % id)
					t.check(MathEngine.check(sol, str(answer["value"])), "%s accepts its own answer" % id)
				else:
					t.check(MathEngine.check(sol, MathFormat.number(answer["value"], -1, false)), "%s accepts its own answer %s" % [id, answer["value"]])
					t.check(not MathEngine.check(sol, MathFormat.number(float(answer["value"]) * 1.5 + 1.0, -1, false)), "%s rejects a wrong answer" % id)
				for s in sol["steps"]:
					for field in ["text", "note", "keys", "basic", "title"]:
						t.check(not str(s[field]).contains("{"), "%s step %s rendered: %s" % [id, field, s[field]])
					for line in s["lines"]:
						t.check(not str(line).contains("{"), "%s line rendered: %s" % [id, line])


## Read aloud, a step says its symbols as words (speech rules), never "{x}".
func _speech() -> void:
	print("=== steps read aloud ===")
	var speech_text = load("res://src/speech/speech_text.gd")
	var bank = JSON.parse_string(FileAccess.get_file_as_string("res://data/question_bank.json"))
	var records: Array = bank.get("records", []) if bank is Dictionary else []
	var view := MathStepsView.new()
	var cite_re := RegEx.create_from_string("(?:divided by|times|equals|plus|minus) section")
	var spoken := 0
	var sols: Array = []
	for rec in records:
		var sol := MathEngine.exam_solution(rec)
		if sol.get("ok", false):
			sol["id"] = rec.get("id", "")
			sols.append(sol)
	var rng := RandomNumberGenerator.new()
	rng.seed = 314
	for def in MathData.types():
		for level in MathEngine.level_ids():
			var gen := MathEngine.generate(str(def["id"]), level, rng)
			if not gen.is_empty():
				gen["id"] = "%s L%d" % [def["id"], level]
				sols.append(gen)
	for rec in sols:
		view.steps = rec["steps"]
		for i in view.steps.size():
			var said: String = speech_text.speakable(view.spoken_text(i))
			spoken += 1
			t.check(cite_re.search(said) == null,
				"%s step %d: a quantity is not read as a Code section: %s" % [rec.get("id", ""), i + 1, said])
			for sym in ["{", "}", "÷", "×", "√", "²", "Ω"]:
				t.lacks(said, sym, "%s step %d spoken without '%s': %s" % [rec.get("id", ""), i + 1, sym, said])
	view.free()
	t.check(spoken > 100, "exam steps spoken (%d)" % spoken)


func _cards() -> void:
	print("=== formula cards ===")
	var ids := []
	for card in MathData.cards():
		var id := str(card.get("id", ""))
		t.check(not ids.has(id), "card id %s unique" % id)
		ids.append(id)
		t.check(str(card.get("formula", "")) != "", "%s has a formula" % id)
		t.check(MathData.skill_def(str(card.get("skill", ""))).size() > 0, "%s has a skill" % id)
		t.check((card.get("picture", {}).get("items", []) as Array).size() > 0, "%s has a picture" % id)
		var size: Array = card.get("picture", {}).get("size", [])
		t.check(size.size() == 2 and float(size[0]) > 0 and float(size[1]) > 0, "%s picture size" % id)
		for item in card.get("picture", {}).get("items", []):
			t.check(["circle", "line", "rect", "poly", "text", "zigzag", "arc"].has(str(item.get("t", ""))), "%s known primitive %s" % [id, item.get("t", "")])
		var ex: Dictionary = card.get("example", {})
		var sol := MathEngine.solve(str(ex.get("type", "")), ex.get("inputs", {}))
		t.check(sol.get("ok", false), "%s example solves (%s)" % [id, sol.get("error", "")])
	t.eq(MathFormat.conductor_size("250"), "250 kcmil", "kcmil sizes")
	t.eq(MathFormat.conductor_size("4/0"), "4/0 AWG", "AWG sizes")
	t.eq(MathFormat.render("{s:awg}", {"s": 12.0}), "12 AWG", "awg format")


func _drills() -> void:
	print("=== table drills ===")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	t.check(MathData.drills().size() >= 10, "drills defined")
	for drill in MathData.drills():
		var id := str(drill.get("id", ""))
		t.check(MathData.table(str(drill.get("table", ""))).size() > 0, "%s table exists" % id)
		for i in 30:
			var q := MathDrills.question(drill, rng)
			if q.is_empty():
				t.check(false, "%s makes a question" % id)
				break
			var options: Array = q["options"]
			t.check(options.size() >= 2, "%s has choices" % id)
			t.check(int(q["answer_index"]) >= 0 and options[int(q["answer_index"])] == q["answer"], "%s answer in options" % id)
			var unique := {}
			for o in options:
				unique[o] = true
			t.eq(unique.size(), options.size(), "%s choices unique" % id)
			t.check(not str(q["prompt"]).contains("{"), "%s prompt rendered: %s" % [id, q["prompt"]])
	# Known cells: 12 AWG Cu 75 °C = 25 A; 80 A OCPD -> 8 AWG Cu EGC; 3/0 Cu -> 4 AWG GEC.
	var fixed := RandomNumberGenerator.new()
	var cu := MathData.drill("t310_16_cu").duplicate(true)
	cu["rows"] = {"from": "12", "to": "12"}
	cu["cols"] = ["cu75"]
	t.eq(MathDrills.question(cu, fixed)["answer"], "25 A", "Table 310.16 cell")
	var egc := MathData.drill("t250_122").duplicate(true)
	egc["values"] = {"table": "t240_6a", "col": "amps", "from": "80", "to": "80"}
	egc["cols"] = ["cu"]
	t.eq(MathDrills.question(egc, fixed)["answer"], "8 AWG", "Table 250.122 at-most row")
	var gec := MathData.drill("t250_66").duplicate(true)
	gec["sizes"] = {"table": "t310_16", "from": "3/0", "to": "3/0"}
	t.eq(MathDrills.question(gec, fixed)["answer"], "4 AWG", "Table 250.66 size row")
	gec["sizes"] = {"table": "t310_16", "from": "1000", "to": "1000"}
	t.eq(MathDrills.question(gec, fixed)["answer"], "2/0 AWG", "Table 250.66 kcmil limit row (over 600 through 1100)")
	egc["values"] = {"table": "t240_6a", "col": "amps", "from": "1000", "to": "1000"}
	egc["cols"] = ["al"]
	t.eq(MathDrills.question(egc, fixed)["answer"], "4/0 AWG", "Table 250.122 aluminum at 1000 A")
	egc["values"] = {"table": "t240_6a", "col": "amps", "from": "5000", "to": "5000"}
	t.eq(MathDrills.question(egc, fixed)["answer"], "1250 kcmil", "Table 250.122 kcmil answer")
	t.check(MathFormat.conductor_rank("14") < MathFormat.conductor_rank("1") and MathFormat.conductor_rank("1") < MathFormat.conductor_rank("1/0") and MathFormat.conductor_rank("4/0") < MathFormat.conductor_rank("250"), "conductor size order")
	var dry := MathData.drill("t220_54").duplicate(true)
	dry["x"] = {"from": 30, "to": 30}
	t.eq(MathDrills.question(dry, fixed)["answer"], "31.5%", "Table 220.54 formula row")


func _stats() -> void:
	print("=== weak-spot stats ===")
	var path := "user://math_stats_test.cfg"
	var s := MathStats.new(path)
	s.reset()
	t.eq(s.accuracy("skill", "ohms"), -1.0, "unanswered")
	for i in 4:
		s.record("skill", "ohms", true)
	for i in 4:
		s.record("skill", "motors", i == 0)
	t.eq(s.accuracy("skill", "ohms"), 1.0, "all right")
	t.eq(s.accuracy("skill", "motors"), 0.25, "one of four")
	var again := MathStats.new(path)
	t.eq(again.attempts("skill", "motors"), 4, "saved and reloaded")
	t.check(again.weight("skill", "motors") > again.weight("skill", "ohms"), "weak skill weighs more")
	t.eq(again.weight("skill", "box_fill"), MathStats.UNSEEN_WEIGHT, "unseen weight")
	t.eq(again.weakest("skill", ["ohms", "box_fill", "motors"]), ["motors", "ohms", "box_fill"], "weakest first, unseen last")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var hits := {"ohms": 0, "motors": 0}
	for i in 2000:
		hits[again.pick_weighted("skill", ["ohms", "motors"], rng)] += 1
	t.check(hits["motors"] > hits["ohms"] * 2, "weighted pick favors the weak skill %s" % str(hits))
	var rec := {"id": "final-exam-#1-014"}
	again.record_exam(rec, false)
	t.eq(again.attempts("skill", "ampacity"), 1, "exam calc answer counts for its skill")
	again.record_exam({"id": "final-exam-#1-002"}, true)
	t.eq(again.attempts("skill", ""), 0, "non-calc exam question is not recorded")
	again.reset()
	t.check(not FileAccess.file_exists(path), "reset removes the file")


## The generated inputs of a solution (its level's var names).
func _inputs_of(sol: Dictionary, def: Dictionary, level: int) -> Dictionary:
	var out := {}
	var spec: Dictionary = MathEngine._level_spec(def, level)
	for pair in spec.get("vars", []):
		out[pair[0]] = sol["vars"][pair[0]]
	return out
