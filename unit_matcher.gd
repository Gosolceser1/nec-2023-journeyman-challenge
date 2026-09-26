class_name UnitMatcher
extends RefCounted
## Specialized unit converter and candidate generator for NEC calculations and choices.

static func format_answer_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return String.num(value, 2).trim_suffix("0").trim_suffix(".")

static func answer_match_candidates(answer: String) -> Array[String]:
	var candidates: Array[String] = []
	var direct := answer.strip_edges().replace("’", "'").replace("″", "\"")
	if direct != "":
		candidates.append(direct)
	var common_spelling := direct.to_lower().replace("inches", "in.").replace("inch", "in.").replace("feet", "ft").replace("foot", "ft")
	if common_spelling != direct.to_lower() and not candidates.has(common_spelling):
		candidates.append(common_spelling)
	
	# Number word mappings (e.g., 3 <-> three)
	var word_numbers := {
		"0": "zero", "1": "one", "2": "two", "3": "three", "4": "four",
		"5": "five", "6": "six", "7": "seven", "8": "eight", "9": "nine",
		"10": "ten", "12": "twelve", "15": "fifteen", "20": "twenty"
	}
	var direct_num_only := direct.strip_edges().to_lower().replace(",", "")
	if word_numbers.has(direct_num_only):
		var w: String = word_numbers[direct_num_only]
		if not candidates.has(w):
			candidates.append(w)
	for num_key in word_numbers:
		if direct_num_only == word_numbers[num_key] and not candidates.has(num_key):
			candidates.append(num_key)

	# Fractional feet / inches handling (e.g. 2 1/2 feet <-> 30 in. / 30")
	var fraction_feet := RegEx.create_from_string("^([0-9]+)\\s+1/2\\s*(?:feet|foot|ft|ft\\.|')?$")
	var ff_match := fraction_feet.search(direct.to_lower())
	if ff_match:
		var whole := float(ff_match.get_string(1))
		var total_inches := (whole + 0.5) * 12.0
		var in_text := format_answer_number(total_inches)
		candidates.append(in_text + " in.")
		candidates.append(in_text + " inches")
		candidates.append(in_text + "\"")
		candidates.append(in_text)

	var direct_clean := direct.replace(",", "")
	var number_pattern := RegEx.create_from_string("^\\s*#?([0-9]+(?:\\.[0-9]+)?)\\s*(.*?)\\s*$")
	var number_match := number_pattern.search(direct_clean)
	if number_match == null:
		return candidates
	var amount := float(number_match.get_string(1))
	var amount_text := format_answer_number(amount)
	var comma_amount := amount_text
	if amount >= 1000.0 and not amount_text.contains("."):
		var s := str(int(amount))
		var parts: Array[String] = []
		while s.length() > 3:
			parts.insert(0, s.substr(s.length() - 3, 3))
			s = s.substr(0, s.length() - 3)
		parts.insert(0, s)
		comma_amount = ",".join(parts)
	if comma_amount != amount_text and not candidates.has(comma_amount):
		candidates.append(comma_amount)

	var unit := number_match.get_string(2).strip_edges().to_lower()
	var extras: Array[String] = []
	if unit in ["\"", "in", "in.", "inch", "inches"]:
		var total_ft := amount / 12.0
		if is_equal_approx(total_ft, roundf(total_ft)):
			var feet_text := format_answer_number(total_ft)
			extras.append(feet_text + " ft")
			extras.append(feet_text + " feet")
		elif is_equal_approx(total_ft - floorf(total_ft), 0.5):
			var whole_ft := str(int(floorf(total_ft)))
			extras.append(whole_ft + " 1/2 feet")
			extras.append(whole_ft + " 1/2 ft")
			extras.append(whole_ft + " 1/2'")
		var meters_text := format_answer_number(amount * 0.0254)
		extras.append(meters_text + " m")
	elif unit in ["'", "ft", "ft.", "foot", "feet"]:
		extras.append(amount_text + " ft")
		extras.append(amount_text + " feet")
		extras.append(amount_text + "'")
		var inch_text := format_answer_number(amount * 12.0)
		extras.append(inch_text + " in.")
		extras.append(inch_text + " inches")
		extras.append(inch_text + "\"")
		var meter_text := format_answer_number(amount * 0.3048)
		extras.append(meter_text + " m")
	elif unit in ["a", "amp", "amps", "ampere", "amperes"]:
		extras.append(amount_text + " A")
		extras.append(amount_text + " amperes")
	elif unit in ["v", "volt", "volts"]:
		extras.append(amount_text + " V")
		extras.append(amount_text + " volts")
	elif unit in ["va", "volt-amperes", "volt amperes", "volt-ampere", "volt ampere"]:
		extras.append(amount_text + " VA")
		extras.append(amount_text + " volt-amperes")
		extras.append(amount_text)
		if comma_amount != amount_text:
			extras.append(comma_amount + " VA")
			extras.append(comma_amount + " volt-amperes")
			extras.append(comma_amount)
	elif unit in ["kw", "kilowatt", "kilowatts"]:
		extras.append(amount_text + " kW")
		extras.append(amount_text + " kilowatts")
	elif unit == "":
		extras.append(amount_text)
		if comma_amount != amount_text:
			extras.append(comma_amount)
		extras.append(amount_text + " VA")
		extras.append(amount_text + " volt-amperes")
		if comma_amount != amount_text:
			extras.append(comma_amount + " VA")
			extras.append(comma_amount + " volt-amperes")
	for extra in extras:
		if not candidates.has(extra):
			candidates.append(extra)
	return candidates
