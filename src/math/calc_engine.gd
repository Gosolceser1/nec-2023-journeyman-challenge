class_name CalcEngine
extends RefCounted
## A basic calculator, the kind allowed in the exam room: left to right with no
## operator precedence ("2 + 3 × 4 =" is 20), a pending operator, one memory,
## percent, square, square root and reciprocal. Keys are the labels the Show
## steps key rows use ("×", "÷", "−", "M+", "1/x", "x²", "√"), so a step's key
## sequence can be pressed here as written. Pure logic: no nodes.

## Every key the pad shows, in the row order the pad builds them.
const KEYS := ["MC", "MR", "M+", "M−", "C",
		"√", "x²", "1/x", "%", "÷",
		"7", "8", "9", "⌫", "×",
		"4", "5", "6", "±", "−",
		"1", "2", "3", ".", "+",
		"0", "="]
const OPERATORS := ["+", "−", "×", "÷"]
## Keys that work on the number already showing, so a key row starting with
## one continues from the previous step instead of starting over.
const CONTINUES := ["+", "−", "×", "÷", "=", "%", "√", "x²", "1/x", "M+", "M−", "±"]
## Digits on the display, like a 10-digit pocket calculator.
const MAX_DIGITS := 10

var memory := 0.0
var error := false
var _acc := 0.0
var _op := ""
## The number showing: _entry is its text, _val its full value (a result keeps
## every digit, like a real calculator, even though ten are shown).
var _entry := "0"
var _val := 0.0
## True while digits typed start a new number (after an operator, =, or a
## function key), false while the current number is being typed.
var _fresh := true
## True once a number was typed or recalled since the last operator, so a
## second operator in a row replaces the first instead of applying it.
var _operand := false


func clear() -> void:
	_acc = 0.0
	_op = ""
	_entry = "0"
	_val = 0.0
	_fresh = true
	_operand = false
	error = false


## What the display shows.
func display() -> String:
	return "Error" if error else _entry


## The pending operation, for a small line above the number ("27 ×").
func pending() -> String:
	if _op == "" or error:
		return ""
	return "%s %s" % [format(_acc), _op]


func value() -> float:
	return 0.0 if error else _val


## One key press; aliases from the step key rows are accepted ("-", "M-").
func press(key: String) -> void:
	key = {"-": "−", "M-": "M−", "*": "×", "/": "÷", "AC": "C", "CE": "C", "+/-": "±"}.get(key, key)
	if error and key != "C":
		return
	if key.length() == 1 and key >= "0" and key <= "9":
		_digit(key)
		return
	match key:
		".":
			if _fresh:
				_type("0.")
			elif not _entry.contains("."):
				_type(_entry + ".")
		"C":
			clear()
		"⌫":
			if not _fresh:
				var left := _entry.left(-1)
				if left in ["", "-", "-0"]:
					_show(0.0)
				else:
					_type(left)
		"±":
			if _val != 0.0:
				if _fresh:
					_show(-_val)
				else:
					_type(_entry.trim_prefix("-") if _entry.begins_with("-") else "-" + _entry)
				_operand = true
		"+", "−", "×", "÷":
			if _op != "" and _operand:
				_apply()
			elif _op == "":
				_acc = _val
			_op = key
			_fresh = true
			_operand = false
		"=":
			if _op != "":
				_apply()
				_op = ""
			_fresh = true
		"%":
			# Finishes the operation like a pocket calculator: "a × b %" is
			# a × b/100, "a + b %" adds b percent of a; alone it is b/100.
			var v := _acc * _val / 100.0 if _op in ["+", "−"] else _val / 100.0
			_show(v)
			if _op != "":
				_apply()
				_op = ""
		"√":
			if _val < 0.0:
				error = true
			else:
				_show(sqrt(_val))
		"x²":
			_show(_val * _val)
		"1/x":
			if _val == 0.0:
				error = true
			else:
				_show(1.0 / _val)
		"M+":
			memory += _val
			_fresh = true
		"M−":
			memory -= _val
			_fresh = true
		"MR":
			_show(memory)
		"MC":
			memory = 0.0


## Presses a whole key row from Show steps: "277 × 1.732 = M+" (numbers are
## typed digit by digit, a thousands comma is ignored).
func press_sequence(keys: String) -> void:
	for token in keys.split(" ", false):
		for k in tokens_to_keys(token):
			press(k)


## Presses one step's row: a row starting with a number starts over (C, memory
## kept); one starting with an operator or function key continues.
func press_row(keys: String) -> void:
	var first := sequence_keys(keys)
	if first.is_empty():
		return
	if not first[0] in CONTINUES:
		press("C")
	press_sequence(keys)


## A calculator with the earlier steps' rows already pressed, so a step that
## continues ("× 14 =") or recalls memory ("1 ÷ MR =") starts where it should.
static func primed(rows: Array) -> CalcEngine:
	var c := CalcEngine.new()
	for row in rows:
		c.press_row(str(row))
	return c


## What a step's row should land on: the last number after "=" in its working
## line ("5,000 × 1.3 = 6,500 VA" -> "6500"), then, for a row that runs ahead
## ("20 1/x + 30 1/x =" under the single reciprocals), the numbers in the next
## step's line ("Add them: 0.0833"). Empty when the step's answer is a
## fraction and the row only gives the decimal to compare.
static func expected_values(step: Dictionary, next: Dictionary = {}) -> Array:
	if str(step.get("note", "")).contains("decimal"):
		return []
	var texts: Array = [str(step.get("text", ""))]
	texts.append_array(step.get("lines", []))
	var out: Array = []
	var after_equals := RegEx.create_from_string("=\\s*(-?[\\d,]*\\.?\\d+)(?![\\d/])")
	for line in texts:
		for m in after_equals.search_all(str(line)):
			out = [m.get_string(1).replace(",", "")]
	if not next.is_empty():
		var number := RegEx.create_from_string("-?[\\d,]*\\.?\\d+")
		for m in number.search_all(str(next.get("text", ""))):
			out.append(m.get_string().replace(",", ""))
	return out


## True when the display agrees with a figure the working line prints, to the
## figure's decimals (the line rounds) or within 0.5 %.
static func agrees(shown: String, want: String) -> bool:
	if not shown.is_valid_float() or not want.is_valid_float():
		return false
	var a := float(shown)
	var b := float(want)
	var decimals := want.get_slice(".", 1).length() if want.contains(".") else 0
	return absf(a - b) <= 0.5 * pow(10.0, -decimals) + 1e-9 or absf(a - b) <= absf(b) * 0.005


## The row a Show steps step is pressed with on this calculator: its
## basic-calculator keys when it has them ("1 ÷ 20 = M+" for "20 1/x"),
## otherwise its keys.
static func pad_keys(step: Dictionary) -> String:
	var basic := str(step.get("basic", "")).strip_edges()
	return basic if basic != "" else str(step.get("keys", "")).strip_edges()


## The single keys a whole key row stands for, in order.
static func sequence_keys(keys: String) -> Array:
	var out: Array = []
	for token in keys.split(" ", false):
		out.append_array(tokens_to_keys(token))
	return out


## The single keys one Show steps token stands for: "1.25" -> 1 . 2 5.
static func tokens_to_keys(token: String) -> Array:
	var clean := token.replace(",", "")
	if clean.is_valid_float() and not clean.begins_with("+"):
		var out: Array = []
		var negative := clean.begins_with("-")
		for ch in clean.trim_prefix("-"):
			out.append(ch)
		if negative:
			out.append("±")
		return out
	return [{"-": "−", "M-": "M−", "*": "×", "/": "÷", "+/-": "±"}.get(token, token)]


func _digit(d: String) -> void:
	if _fresh:
		_type(d)
		return
	if _entry.replace("-", "").replace(".", "").length() >= MAX_DIGITS:
		return
	_type(d if _entry == "0" else ("-" + d if _entry == "-0" else _entry + d))


## The number being typed.
func _type(text: String) -> void:
	_entry = text
	_val = float(text)
	_fresh = false
	_operand = true


func _apply() -> void:
	var b := _val
	var r := _acc
	match _op:
		"+":
			r = _acc + b
		"−":
			r = _acc - b
		"×":
			r = _acc * b
		"÷":
			if b == 0.0:
				error = true
				return
			r = _acc / b
	_acc = r
	_show(r)


## A result or recalled number.
func _show(v: float) -> void:
	_val = v
	_entry = format(v)
	if _entry == "Error":
		error = true
	_fresh = true
	_operand = true


## A number as a pocket calculator shows it: at most MAX_DIGITS digits, no
## trailing zeros, no exponent for everyday sizes.
static func format(v: float) -> String:
	if is_nan(v) or is_inf(v) or absf(v) >= pow(10.0, MAX_DIGITS):
		return "Error"
	if absf(v) < 1e-9:
		return "0"
	var int_digits := maxi(1, int(floor(log(absf(v)) / log(10.0))) + 1)
	var decimals := clampi(MAX_DIGITS - int_digits, 0, 9)
	var s := String.num(v, decimals)
	if s.contains("."):
		s = s.rstrip("0").rstrip(".")
	return "0" if s in ["-0", ""] else s
