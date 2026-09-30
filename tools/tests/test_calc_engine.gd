extends SceneTree
## The in-app calculator (CalcEngine): basic-calculator rules, and every key
## row Show steps prints (70 exam solutions, every trainer problem type at each
## level) pressed on it lands on the number the step's working line shows.
##
##   Godot --headless --path . --script tools/tests/test_calc_engine.gd

const R = preload("res://tools/tests/t_report.gd")

var t: R = R.new()


func _initialize() -> void:
	print("=== calculator ===")
	_rules()
	_exam_keys()
	_trainer_keys()
	_pad()
	t.report()
	quit(0 if t.failures.is_empty() else 1)


func _run(keys: String) -> CalcEngine:
	var c := CalcEngine.new()
	c.press_sequence(keys)
	return c


func _rules() -> void:
	t.eq(_run("2 + 3 × 4 =").display(), "20", "left to right, like a basic calculator")
	t.eq(_run("5000 × 1.3 =").display(), "6500", "5000 × 1.3")
	t.eq(_run("40 × 0.87 × 1 =").display(), "34.8", "chained ×")
	t.eq(_run("10 ÷ 4 =").display(), "2.5", "÷")
	t.eq(_run("10 − 4 =").display(), "6", "−")
	t.eq(_run("12000 − 3000 = × 35 %").display(), "3150", "× then % finishes the operation")
	t.eq(_run("200 + 10 %").display(), "220", "+ then % adds the percent")
	t.eq(_run("50 %").display(), "0.5", "% alone")
	t.eq(_run("9 √").display(), "3", "square root")
	t.eq(_run("12 x²").display(), "144", "square")
	t.eq(_run("8 1/x").display(), "0.125", "reciprocal")
	t.eq(_run("1 ÷ 3 =").display(), "0.333333333", "ten digits, no trailing zeros")
	t.eq(_run("5 ÷ 0 =").display(), "Error", "divide by zero")
	var c := _run("5 ÷ 0 =")
	c.press("7")
	t.eq(c.display(), "Error", "keys wait for C after an error")
	c.press("C")
	t.eq(c.display(), "0", "C clears the error")
	t.eq(_run("277 × 1.732 = M+ C MR").display(), "479.764", "memory survives C")
	t.eq(_run("3 + × 4 =").display(), "12", "a second operator replaces the first")
	t.eq(_run("6 × 7 = + 8 =").display(), "50", "an operator after = continues from the result")
	t.eq(_run("6 × 7 = 5 + 1 =").display(), "6", "a number after = starts over")
	c = CalcEngine.new()
	for k in ["1", "2", "3", "⌫"]:
		c.press(k)
	t.eq(c.display(), "12", "backspace")
	c.press("±")
	t.eq(c.display(), "-12", "change sign")
	c = CalcEngine.new()
	for k in ["1", ".", ".", "5"]:
		c.press(k)
	t.eq(c.display(), "1.5", "one decimal point")
	c = CalcEngine.new()
	for i in 14:
		c.press("9")
	t.eq(c.display(), "9999999999", "ten digits at most")
	t.eq(_run("9999999999 × 10 =").display(), "Error", "overflow")
	t.eq(_run("1,000 × 2 =").display(), "2000", "a thousands comma in a key row is ignored")
	t.eq(_run("12 × 5 = 1/x").display(), "0.016666667", "rounded to ten digits")
	t.eq(_run("2 × 3 × 35 %").display(), "2.1", "chained × then %")
	t.eq(CalcEngine.tokens_to_keys("1.25"), ["1", ".", "2", "5"], "a number is typed digit by digit")
	t.eq(CalcEngine.tokens_to_keys("M-"), ["M−"], "ASCII minus in memory keys")
	for key in CalcEngine.KEYS:
		var fresh := CalcEngine.new()
		fresh.press(key)
		t.check(fresh.display() != "", "key %s does something sane" % key)



## Presses each step's pad row (the basic-calculator keys when the step has
## them, as the in-app pad does) on one calculator, memory carried along.
func _walk(label: String, steps: Array) -> int:
	var c := CalcEngine.new()
	var checked := 0
	for i in steps.size():
		var step: Dictionary = steps[i]
		var keys := CalcEngine.pad_keys(step)
		if keys == "":
			continue
		c.press_row(keys)
		var want := CalcEngine.expected_values(step, steps[i + 1] if i + 1 < steps.size() else {})
		if want.is_empty():
			continue
		checked += 1
		if not want.any(func(w: String) -> bool: return CalcEngine.agrees(c.display(), w)):
			t.check(false, "%s step %d: keys '%s' show %s, the step says %s" % [label, i + 1, keys, c.display(), want[0]])
	return checked

func _exam_keys() -> void:
	var checked := 0
	var solutions := 0
	for rec in BankLoader.load_records():
		var sol := MathEngine.exam_solution(rec)
		if not sol.get("ok", false):
			continue
		solutions += 1
		checked += _walk(str(rec.get("id", "")), sol.get("steps", []))
	t.check(solutions >= 70, "exam solutions found (%d)" % solutions)
	t.check(checked >= 70, "exam key rows checked against the working line (%d)" % checked)
	print("  exam: %d solutions, %d key rows checked" % [solutions, checked])


func _trainer_keys() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var checked := 0
	for def in MathData.types():
		for level in MathEngine.level_ids():
			for n in 3:
				var sol := MathEngine.generate(str(def.get("id", "")), level, rng)
				if sol.get("ok", false):
					checked += _walk("%s L%d" % [def.get("id", ""), level], sol.get("steps", []))
	t.check(checked >= 100, "trainer key rows checked (%d)" % checked)
	print("  trainer: %d key rows checked" % checked)


## The pad's guide: lights each key in turn, steps aside on another key,
## Restart follows the row again, and it tells a mismatch from a match.
func _pad() -> void:
	var pad := CalcPad.new()
	t.check(not pad.is_guiding() and pad.next_key() == "", "a fresh pad is free")
	pad.guide("250 × 1.25 =", [], ["312.5"])
	t.eq(pad.next_key(), "2", "the first key of the row is lit")
	for k in ["2", "5", "0", "×"]:
		pad.press(k)
	t.eq(pad.next_key(), "1", "the guide moves key by key")
	pad.press("7")
	t.eq(pad.next_key(), "", "another key: the guide steps aside")
	t.has(pad.hint_text(), "Restart", "and says how to follow it again")
	pad.restart()
	t.eq(pad.display_text(), "0", "Restart starts the row over")
	for k in CalcEngine.sequence_keys("250 × 1.25 ="):
		pad.press(k)
	t.check(pad.matches(), "the row lands on the step's figure")
	t.has(pad.hint_text(), "matches the step", "and says so")
	pad.guide("× 2 =", ["250 × 1.25 ="], ["625"])
	t.eq(pad.display_text(), "312.5", "a continuing row starts from the earlier steps' result")
	for k in CalcEngine.sequence_keys("× 2 ="):
		pad.press(k)
	t.check(pad.matches(), "continuing row lands on 625")
	pad.guide("1 ÷ MR =", ["1 ÷ 20 = M+ 1 ÷ 20 = M+ 1 ÷ 30 = M+", "MR"], ["7.5"])
	for k in CalcEngine.sequence_keys("1 ÷ MR ="):
		pad.press(k)
	t.check(pad.matches(), "memory from earlier steps is there (%s)" % pad.display_text())
	pad.guide("6 × 7 =", [], ["40"])
	for k in CalcEngine.sequence_keys("6 × 7 ="):
		pad.press(k)
	t.check(not pad.matches(), "a different figure is not a match")
	t.has(pad.hint_text(), "the step says 40", "and the hint shows both")
	pad.free()
	_answer_pad()


## The Math Trainer's answer pad: "?" until a key, the unit beside the number,
## keys stop while locked, and keyboard presses map to pad keys.
func _answer_pad() -> void:
	t.check(_run("12 ×").awaiting_operand(), "12 × waits for a number")
	t.check(not _run("12 × 2").awaiting_operand() and not _run("12 × 2 =").awaiting_operand(), "12 × 2 does not")
	var pad := CalcPad.new()
	pad.reset()
	pad.set_unit("V")
	t.eq(pad.display_text(), "?", "blank until a key")
	t.check(pad._unit.visible and pad._unit.text == "V", "the unit shows")
	for k in CalcEngine.sequence_keys("12 × 24 ="):
		pad.press(k)
	t.eq(pad.display_text(), "288", "12 × 24 = 288")
	pad.locked = true
	pad.press("5")
	t.eq(pad.display_text(), "288", "locked: keys do nothing")
	pad.locked = false
	pad.press("C")
	t.eq(pad.display_text(), "?", "C blanks the entry again")
	var cases := {"7": "7", "*": "×", "x": "×", "/": "÷", "-": "−", "+": "+", "%": "%", ".": ".", "a": ""}
	for ch in cases:
		var e := InputEventKey.new()
		e.pressed = true
		e.unicode = ch.unicode_at(0)
		t.eq(CalcPad.key_for_event(e), cases[ch], "keyboard '%s'" % ch)
	var enter := InputEventKey.new()
	enter.pressed = true
	enter.keycode = KEY_ENTER
	t.eq(CalcPad.key_for_event(enter), "=", "Enter is =")
	enter.echo = true
	t.eq(CalcPad.key_for_event(enter), "", "a held Enter does not repeat")
	pad.free()