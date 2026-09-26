class_name UnitMatcher
extends RefCounted
## Specialized unit converter and candidate generator for NEC calculations and choices.

static func format_answer_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return String.num(value, 2).trim_suffix("0").trim_suffix(".")

## Spells 0-99 the way the NEC reference text writes them, so a percent answer
## can be matched against "eighty-three percent" as well as "83 percent".
## Returns "" above 99, which simply means no spelled candidate is offered --
## a number that large is not written out in a table note.
static func _spell_small(n: int) -> String:
	var ones := ["zero", "one", "two", "three", "four", "five", "six", "seven",
		"eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen",
		"fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
	if n < 0 or n > 99:
		return ""
	if n < 20:
		return str(ones[n])
	var tens := ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy",
		"eighty", "ninety"]
	if n % 10 == 0:
		return str(tens[n / 10])
	return str(tens[n / 10]) + "-" + str(ones[n % 10])

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

	# A PERCENT answer ("83%", "1.5%") is a number the reference text usually
	# spells as a word -- "83 percent", "eighty-five percent". Neither the
	# percent sign nor the spelled-out form is a candidate without this branch,
	# so the number survived redaction whenever it was written as a phrase.
	# 3 records spell it that way (final-exam-#1-036, open-book-exam-#1-006,
	# open-book-exam-#4-022); the field is post-answer today, so this closes a
	# latent leak rather than a live one, but the candidate set is the same set
	# the highlight and the redaction both key off.
	#
	# The BARE number ("83" for "83%") is deliberately NOT a candidate. It was
	# tried and removed: redaction is boundary-anchored, so an "8%" answer blanked
	# the 8 in "8 AWG" and the 8 in "conductors numbered 8, 9 and 10" -- shredding
	# unrelated pre-answer text. Only forms that actually carry the percent
	# meaning are offered.
	var percent := RegEx.create_from_string("^\\s*([0-9]+(?:\\.[0-9]+)?)\\s*%\\s*$")
	var pct_match := percent.search(direct)
	if pct_match:
		var pct_num := pct_match.get_string(1)
		for pct_form in [pct_num + " percent", pct_num + " per cent", pct_num + "%"]:
			if not candidates.has(pct_form):
				candidates.append(pct_form)
		# The spelled-out number, e.g. "1.5%" -> "one point five percent".
		var parts := pct_num.split(".")
		var spelled := ""
		if parts.size() == 2:
			var ones := _spell_small(int(parts[0]))
			var tenths := _spell_small(int(parts[1]))
			if ones != "" and tenths != "":
				spelled = ones + " point " + tenths
		else:
			spelled = _spell_small(int(pct_num))
		if spelled != "":
			for pct_word_form in [spelled + " percent", spelled + " per cent"]:
				if not candidates.has(pct_word_form):
					candidates.append(pct_word_form)

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
	# A FRACTIONAL answer like 15/16" or 1/2 inch must be handled before the
	# plain-number pattern below: that pattern matches the leading "15" and then
	# reads "/16 in." as a unit, so the fraction never got a candidate and the
	# reference wording ("15/16 in.") could not match its own answer -- that is
	# why final-exam-#3-034 never highlighted its own 15/16" answer.
	#
	# The denominator must be a REAL inch fraction (2,3,4,8,16,32,64).
	# Without that guard this rule also swallowed the slash-voltage "240/120 V",
	# verified by printing the candidate sets.
	#
	# A BARE "N/2" or "N/3" with no unit is ambiguous: it is either an unspaced
	# mixed number (the bank has '41/2' in final-exam-#5-053, meaning 4 1/2) or a
	# N-conductor cable designation (12/3, 10/2). The tie is broken on the
	# numerator: NEC cable sizes are 8, 10, 12 and 14, so only those are read as
	# a cable. A numerator outside that set stays a fraction, which keeps
	# '41/2' correct while '12/3' keeps only its own form.
	var frac_answer := RegEx.create_from_string("^\\s*(\\d+)\\s*/\\s*(2|3|4|8|16|32|64)\\s*(\"|''|in\\.?|inch|inches)?\\s*$")
	var frac_match := frac_answer.search(direct.to_lower())
	if frac_match:
		var f_num := frac_match.get_string(1)
		var f_den := frac_match.get_string(2)
		var f_unit := frac_match.get_string(3)
		var looks_like_cable := f_unit == "" and (f_den == "2" or f_den == "3") \
			and ["8", "10", "12", "14"].has(f_num)
		if not int(f_num) == 0 and not int(f_den) == 0 and not looks_like_cable:
			var frac_forms: Array[String] = [f_num + "/" + f_den]
			for spelling in [f_num + "/" + f_den + " in.", f_num + "/" + f_den + " inches",
					f_num + "/" + f_den + " inch", f_num + "/" + f_den + "\"",
					f_num + "/" + f_den]:
				if not frac_forms.has(spelling):
					frac_forms.append(spelling)
			for form in frac_forms:
				if not candidates.has(form):
					candidates.append(form)
			# Feet equivalent, for the times a table states the depth in feet.
			var total_in := float(f_num) / float(f_den)
			var feet_val := total_in / 12.0
			if not is_equal_approx(feet_val, 0.0):
				for ft_form in [format_answer_number(feet_val) + " ft",
						format_answer_number(feet_val) + " feet"]:
					if not candidates.has(ft_form):
						candidates.append(ft_form)
			return candidates

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
