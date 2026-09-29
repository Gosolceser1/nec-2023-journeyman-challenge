class_name MathFormat
extends RefCounted
## Number formatting and {var} templates for math steps, plus reading a number
## out of an answer ("20a", "6,500", "2/5", "two") to compare values.

const DEFAULT_PLACES := 4
const WORDS := {
	"none": 0, "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
	"six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10, "eleven": 11, "twelve": 12,
}

static var _token_re: RegEx
static var _number_re: RegEx


## x rounded to places decimals (DEFAULT_PLACES when places < 0), trailing
## zeros dropped; thousands separated by commas when commas is true.
static func number(x, places: int = -1, commas: bool = true) -> String:
	if not (x is float or x is int):
		return str(x)
	var p := DEFAULT_PLACES if places < 0 else places
	var text := String.num(float(x), p)
	if text.contains("."):
		text = text.rstrip("0").trim_suffix(".")
	if text == "-0":
		text = "0"
	return _group(text) if commas else text


static func _group(text: String) -> String:
	var sign := ""
	if text.begins_with("-"):
		sign = "-"
		text = text.substr(1)
	var dot := text.find(".")
	var whole := text if dot < 0 else text.substr(0, dot)
	var rest := "" if dot < 0 else text.substr(dot)
	if whole.length() <= 3:
		return sign + whole + rest
	var out := ""
	while whole.length() > 3:
		out = "," + whole.substr(whole.length() - 3) + out
		whole = whole.substr(0, whole.length() - 3)
	return sign + whole + out + rest


## A conductor size key with its unit: "12 AWG", "1/0 AWG", "250 kcmil".
static func conductor_size(key) -> String:
	var text := MathFunctions.key_text(key)
	return "%s kcmil" % text if text.is_valid_int() and int(text) >= 250 else "%s AWG" % text


## Orders conductor sizes smallest first: 14 AWG … 1 AWG, 1/0 … 4/0, then kcmil.
static func conductor_rank(key) -> float:
	var text := MathFunctions.key_text(key)
	if text.ends_with("/0"):
		return float(text.get_slice("/", 0))
	var n := float(text)
	return n if n >= 250.0 else -n


## Replaces {name}, {name:places} and {name:awg} (a conductor size) with
## values from vars. Calculator key sequences (for_keys) are written without
## thousands separators.
static func render(template: String, vars: Dictionary, for_keys: bool = false) -> String:
	if template.is_empty() or not template.contains("{"):
		return template
	if _token_re == null:
		_token_re = RegEx.create_from_string("\\{([A-Za-z_][A-Za-z0-9_]*)(?::(\\d|awg))?\\}")
	var out := ""
	var last := 0
	for m in _token_re.search_all(template):
		out += template.substr(last, m.get_start() - last)
		var key := m.get_string(1)
		var fmt := m.get_string(2)
		if not vars.has(key):
			out += m.get_string()
		elif fmt == "awg":
			out += conductor_size(vars[key])
		else:
			out += number(vars[key], int(fmt) if fmt != "" else -1, not for_keys)
		last = m.get_end()
	return out + template.substr(last)


## The numeric value of an answer or typed entry, or NAN if there is none.
## Understands "6,500", "20a", "0.10 A", "2/5", "1 1/2", "-3" and number words.
static func parse(text: String) -> float:
	var s := text.strip_edges().to_lower().replace(",", "")
	if WORDS.has(s.split(" ")[0] if s != "" else ""):
		return float(WORDS[s.split(" ")[0]])
	if _number_re == null:
		_number_re = RegEx.create_from_string("^[^0-9.\\-]*(-?\\d*\\.?\\d+)(?:\\s+(\\d+)\\s*/\\s*(\\d+)|\\s*/\\s*(\\d+))?")
	var m := _number_re.search(s)
	if m == null:
		return NAN
	var first := float(m.get_string(1))
	if m.get_string(2) != "" and float(m.get_string(3)) != 0.0:
		return first + float(m.get_string(2)) / float(m.get_string(3))
	if m.get_string(4) != "":
		var den := float(m.get_string(4))
		return first / den if den != 0.0 else NAN
	return first


## True when two answers name the same number (within a relative 1e-6).
static func same_value(a, b) -> bool:
	var x := parse(str(a)) if not (a is float or a is int) else float(a)
	var y := parse(str(b)) if not (b is float or b is int) else float(b)
	if is_nan(x) or is_nan(y):
		return false
	return absf(x - y) <= maxf(1e-9, 1e-6 * maxf(absf(x), absf(y)))
