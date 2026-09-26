extends RefCounted
## Single source of truth for every word the voice speaks.
## Used by main.gd at runtime and by tools/dump_speech.gd for batch pre-generation.

const ANSWER_LETTERS := ["A", "B", "C", "D"]

static func format_answer_number(value: float) -> String:
	return UnitMatcher.format_answer_number(value)

static func answer_match_candidates(answer: String) -> Array[String]:
	return UnitMatcher.answer_match_candidates(answer)

static func find_answer_match(text: String, answer: String) -> Dictionary:
	return AudioExplanationGenerator.find_match_in(text, answer)

static func _normalize_spoken(text: String) -> String:
	var lower := text.to_lower().strip_edges()
	var cleaned := ""
	for i in lower.length():
		var ch := lower.substr(i, 1)
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") or ch == " ":
			cleaned += ch
		else:
			cleaned += " "
	while cleaned.contains("  "):
		cleaned = cleaned.replace("  ", " ")
	return cleaned.strip_edges()

static func speech_plan(record: Dictionary) -> Array:
	# Full plan = question stem + choices (pre-answer) followed by teach lines.
	# Teach lines are NOT deduped against the Q/A here on purpose: the answer words
	# are expected to repeat, and the two groups never play back-to-back (the player
	# stops before the first teach line until the learner answers, then jumps to teach).
	var segments := spoken_segments(record)
	for teach_seg in teach_segments(record):
		segments.append(teach_seg)
	return segments

static func teach_segments(record: Dictionary) -> Array:
	# LEARN PART ONLY: short answer callout + distinct code rule (+ math when new).
	# Split from speech_plan so answering can synthesize ONLY these clips instead of
	# re-generating the question stem + 4 choices (which burned Edge quota for audio
	# the learner had already heard and then skipped).
	var out: Array = []
	var answers: Array = record.get("answers", [])
	var correct := int(record.get("correct_index", -1))
	var choice := str(answers[correct]) if correct >= 0 and correct < answers.size() else ""
	var seen: Array[String] = []
	# Indexed from the shared lesson_lines so spoken index N == displayed line N.
	for line in AudioExplanationGenerator.lesson_lines(record, choice):
		var spoken := speakable(line)
		if spoken == "":
			continue
		var norm := _normalize_spoken(spoken)
		var dupe := false
		for prev in seen:
			if norm == prev or norm.contains(prev) or prev.contains(norm):
				dupe = true
				break
		if dupe:
			continue
		seen.append(norm)
		out.append({"text": spoken, "choice": correct, "teach": true})
	return out

static func spoken_segments(record: Dictionary) -> Array:
	var segments: Array = []
	var stem := speakable(str(record.get("prompt", "")))
	if stem != "" and not stem.ends_with(".") and not stem.ends_with("?"):
		stem += "."
	segments.append({"text": stem, "choice": -1, "teach": false})
	var answers: Array = record.get("answers", [])
	for i in answers.size():
		var letter: String = ANSWER_LETTERS[i] if i < ANSWER_LETTERS.size() else str(i + 1)
		segments.append({"text": "%s, %s." % [letter, speakable(str(answers[i]))], "choice": i, "teach": false})
	return segments

static func prompt_intent(prompt: String) -> String:
	return AudioExplanationGenerator.prompt_intent(prompt)

static func plain_words(text: String) -> String:
	return AudioExplanationGenerator.plain_words(text)

static func lesson_point(prompt: String, body: String, worked: String, answer: String) -> String:
	return AudioExplanationGenerator.lesson_point(prompt, body, worked, answer)

static func prompt_with_answer(prompt: String, answer: String) -> String:
	return AudioExplanationGenerator.prompt_with_answer(prompt, answer)

static func answer_sentence(body: String, answer: String) -> String:
	return AudioExplanationGenerator.answer_sentence(body, answer)


static func speakable(text: String) -> String:
	var spoken := text.strip_edges()
	if spoken == "":
		return ""
	spoken = spoken.replace("“", "\"")
	spoken = spoken.replace("”", "\"")
	spoken = spoken.replace("″", "\"")
	spoken = spoken.replace("«", "")
	spoken = spoken.replace("»", "")
	var mixed_in := RegEx.new()
	mixed_in.compile("(\\d+)\\s+(\\d+)/(\\d+)\\s*\"")
	spoken = mixed_in.sub(spoken, "$1 and $2/$3 inches", true)
	var frac_in := RegEx.new()
	frac_in.compile("(\\d+)/(\\d+)\\s*\"")
	spoken = frac_in.sub(spoken, "$1/$2 inch", true)
	var single_inch := RegEx.new()
	single_inch.compile("(\\b1)\\s*\"")
	spoken = single_inch.sub(spoken, "1 inch", true)
	var inches := RegEx.new()
	inches.compile("(\\d+)\\s*\"")
	spoken = inches.sub(spoken, "$1 inches", true)
	spoken = spoken.replace("\"", "")
	# Foot mark: "5'" -> "5 feet", mirroring the inch-mark path above. Without
	# this the TTS read a literal apostrophe in 9 records' worth of narrated
	# choices. Two guards keep it from mangling anything else: the mark must
	# follow a digit, and must NOT be followed by a letter (that would be a
	# possessive like "5's"). A feet-and-inches height "5'9\"" therefore becomes
	# "5 feet 9 inches" -- the inch-mark rules above already converted the 9".
	var feet_mark2 := RegEx.new()
	feet_mark2.compile("(\\d+)\\s*'(?![A-Za-z])")
	spoken = feet_mark2.sub(spoken, "$1 feet", true)
	# A height reaches this point as "5 feet9 inches", because the inch-mark
	# rules above already consumed the 9" and the mark between the two numbers
	# was the apostrophe. Re-open the seam so the two units do not run together.
	var feet_seam := RegEx.new()
	feet_seam.compile("\\b(feet|foot)(\\d)")
	spoken = feet_seam.sub(spoken, "$1 $2", true)
	spoken = spoken.replace("srating", "stating")
	spoken = spoken.replace("Article__", "which article")
	spoken = spoken.replace("Article ___", "which article")
	spoken = spoken.replace("Table ___", "which table")
	spoken = spoken.replace("Table __", "which table")
	var blank_words := RegEx.new()
	blank_words.compile("(?i)\\b(article|table|section)\\s*_+")
	spoken = blank_words.sub(spoken, "which $1", true)
	# Collapse a WHOLE run of underscores in one pass. Replacing "___" and then
	# "__" left a trailing "_" on longer runs, so a 4-underscore blank in the
	# bank was spoken as "blank _at the wall" ("a____at" -> "a blank _at").
	var blank_run := RegEx.new()
	blank_run.compile("_{2,}")
	spoken = blank_run.sub(spoken, " blank ", true)
	# A LONE underscore is a variable subscript, not a blank: "R_total" and
	# "V_load" are formula symbols, and the TTS read them as the word
	# "underscore" in 2 records. Only an underscore with a letter/digit on both
	# sides is a subscript -- a lone "_" with a space or punctuation after it is
	# a malformed bank blank (final-exam-#3-030) and must stay loud, because it
	# is a DATA bug, not a notation one. Spoken as "R total" / "V load": the
	# subscript's own name carries the meaning and the value is already in the
	# formula around it.
	var subscript := RegEx.new()
	subscript.compile("(?<=[A-Za-z0-9])_(?=[A-Za-z])")
	spoken = subscript.sub(spoken, " ", true)
	var junk := RegEx.new()
	junk.compile("\\s+\\.\\s+[a-zA-Z]\\s*$")
	spoken = junk.sub(spoken, ".", true)
	spoken = spoken.replace("—", ", ")
	spoken = spoken.replace("–", " to ")
	spoken = spoken.replace("→", ", so ")
	spoken = spoken.replace("÷", " divided by ")
	spoken = spoken.replace("×", " times ")
	spoken = spoken.replace("√", " square root of ")
	spoken = spoken.replace("≈", " about ")
	spoken = spoken.replace("Ω", " ohms ")
	spoken = spoken.replace("¢", " cents ")
	var deg_c := RegEx.new()
	deg_c.compile("(?i)\\b(\\d+)\\s*(?:°|degrees?\\s*)C\\b")
	spoken = deg_c.sub(spoken, "$1 degrees Celsius", true)
	var deg_f := RegEx.new()
	deg_f.compile("(?i)\\b(\\d+)\\s*(?:°|degrees?\\s*)F\\b")
	spoken = deg_f.sub(spoken, "$1 degrees Fahrenheit", true)
	spoken = spoken.replace("°", " degrees ")
	spoken = spoken.replace("½", " and one half ")
	spoken = spoken.replace("¼", " and one quarter ")
	spoken = spoken.replace("¾", " and three quarters ")
	spoken = spoken.replace("a/an", "a or an")
	spoken = spoken.replace("and/or", "and or")
	spoken = spoken.replace("cu/al", "copper or aluminum")
	spoken = spoken.replace("CU/AL", "copper or aluminum")
	spoken = spoken.replace("CO/ALR", "C O A L R")
	spoken = spoken.replace("ockout/tagout", "lockout tagout")
	spoken = spoken.replace("kcmil", " thousand circular mil ")
	spoken = spoken.replace("Kcmil", " thousand circular mil ")
	var terms := {
		"GFCI": "ground fault circuit interrupter",
		"AFCI": "arc fault circuit interrupter",
		"AWG": "American wire gauge",
		"EMT": "electrical metallic tubing",
		"PVC": "P V C",
		"NEC": "N E C",
		"VA": "volt amperes",
		"kVA": "kilovolt amperes",
		"kW": "kilowatts",
		"HP": "horsepower",
		"OCPD": "overcurrent protective device",
		"EGC": "equipment grounding conductor",
		"GEC": "grounding electrode conductor",
		"AHJ": "authority having jurisdiction",
	}
	for term in terms:
		var pattern := RegEx.new()
		pattern.compile("(?i)\\b" + term + "\\b")
		spoken = pattern.sub(spoken, terms[term], true)

	var compound_slash := RegEx.new()
	compound_slash.compile("(?i)\\b([a-z]+)/([a-z]+)\\b")
	spoken = compound_slash.sub(spoken, "$1 or $2", true)

	var no_wire := RegEx.new()
	no_wire.compile("(?i)\\bNo\\.\\s*(\\d+)\\b")
	spoken = no_wire.sub(spoken, "number $1", true)

	var section := RegEx.new()
	section.compile("(\\d{3}\\.\\d+)\\(([A-Z])\\)(?:\\((\\d+)\\))?")
	var search_from := 0
	var rebuilt := ""
	while true:
		var found := section.search(spoken, search_from)
		if found == null:
			rebuilt += spoken.substr(search_from)
			break
		rebuilt += spoken.substr(search_from, found.get_start() - search_from)
		var paragraph := found.get_string(2)
		var extra := found.get_string(3)
		var phrase := "section %s, paragraph %s" % [found.get_string(1), paragraph]
		if extra != "":
			phrase += ", item %s" % extra
		rebuilt += phrase
		search_from = found.get_end()
	spoken = rebuilt

	var wire := RegEx.new()
	wire.compile("\\b([1-4])/0\\b")
	var wire_names := {"1": "one aught", "2": "two aught", "3": "three aught", "4": "four aught"}
	search_from = 0
	rebuilt = ""
	while true:
		var wire_hit := wire.search(spoken, search_from)
		if wire_hit == null:
			rebuilt += spoken.substr(search_from)
			break
		rebuilt += spoken.substr(search_from, wire_hit.get_start() - search_from)
		rebuilt += str(wire_names.get(wire_hit.get_string(1), wire_hit.get_string(0)))
		search_from = wire_hit.get_end()
	spoken = rebuilt

	var volts := RegEx.new()
	volts.compile("(?i)\\b(\\d+)\\s*/\\s*(\\d+)\\s*v(?:olts)?\\b")
	spoken = volts.sub(spoken, "$1 slash $2 volts", true)

	# N/M cable designations (12/3, 10/2) are a conductor count over a
	# live count, NOT a fraction -- the fraction rule below would have read
	# them as "twelve thirds". Only a 2- or 3-conductor cable with a single- or
	# double-digit count qualifies, which keeps every real fraction in the bank
	# safe: the fractions there are 1/2, 1/3, 2/5, 15/16, 15/20, 40/100, 60/100
	# and 120/240 (denominator outside 2-3, or numerator below 8). Verified: no
	# live fraction has a numerator >= 8 with a denominator in {2, 3}.
	#
	# Replaced by "slash N/M" rather than a spoken digit-word, because the number
	# of conductors is what the learner must hear ("12 slash 3 cable" is how
	# electricians say it) and a digit word here would be indistinguishable from
	# the fraction reading. The later fraction rule cannot match it: the token is
	# now "slash"-prefixed, so no bare N/M remains.
	var cable := RegEx.new()
	cable.compile("(?<![\\d/])([89]|[1-9]\\d)/([23])(?![\\d/])")
	spoken = cable.sub(spoken, "$1 slash $2", true)

	# An unspaced mixed number ("11/2" typed for 1 1/2) needs a space before the
	# mixed-number rule below can see it. The fraction numerator is pinned to "1"
	# deliberately: an unspaced N 1/M is almost always a whole number plus one
	# half/third/quarter, but "15/16" is a real inch fraction, not "1 5/16".
	# Allowing any numerator here silently rewrote the live 15/16 in
	# final-exam-#3-034 as "1 and five sixteenths". The spaced form ("3 5/16")
	# never needed this rule.
	var unspaced_mixed := RegEx.new()
	unspaced_mixed.compile("(?<![\\d/])([1-9])(1)/([248]|16)(?!\\d)")
	spoken = unspaced_mixed.sub(spoken, "$1 $2/$3", true)

	# A HYPHENATED mixed number (1-1/4") is the drafting form of 1 1/4". The
	# mixed-number rule below needs whitespace, so normalise the hyphen to a
	# space first. Only a FRACTION after the hyphen qualifies, so a numeric
	# range ("100-400 A") is untouched.
	var hyphen_mixed := RegEx.new()
	hyphen_mixed.compile("\\b(\\d+)-(\\d+)/(\\d+)\\b")
	spoken = hyphen_mixed.sub(spoken, "$1 $2/$3", true)

	# 1. Mixed numbers: e.g. "1 1/8", "2 1/2", "3 5/16"
	var mixed_num := RegEx.new()
	mixed_num.compile("\\b(\\d+)\\s+(\\d+)/(\\d+)\\b")
	search_from = 0
	rebuilt = ""
	while true:
		var mixed_hit := mixed_num.search(spoken, search_from)
		if mixed_hit == null:
			rebuilt += spoken.substr(search_from)
			break
		rebuilt += spoken.substr(search_from, mixed_hit.get_start() - search_from)
		rebuilt += mixed_hit.get_string(1) + " and " + spoken_fraction(mixed_hit.get_string(2), mixed_hit.get_string(3))
		search_from = mixed_hit.get_end()
	spoken = rebuilt

	# 2. Standalone fractions: e.g. "1/16", "3/32", "3/16", "1/2"
	var fraction := RegEx.new()
	fraction.compile("\\b(\\d+)/(\\d+)\\b")
	search_from = 0
	rebuilt = ""
	while true:
		var hit := fraction.search(spoken, search_from)
		if hit == null:
			rebuilt += spoken.substr(search_from)
			break
		rebuilt += spoken.substr(search_from, hit.get_start() - search_from)
		rebuilt += spoken_fraction(hit.get_string(1), hit.get_string(2))
		search_from = hit.get_end()
	spoken = rebuilt

	var sq_ft := RegEx.new()
	sq_ft.compile("(?i)\\bsq\\.?\\s*ft\\.?\\b")
	spoken = sq_ft.sub(spoken, "square feet", true)

	var sq_in := RegEx.new()
	sq_in.compile("(?i)\\bsq\\.?\\s*in(?:ches)?\\.?\\b")
	spoken = sq_in.sub(spoken, "square inches", true)

	var cu_in := RegEx.new()
	cu_in.compile("(?i)\\bcu\\.?\\s*in(?:ches)?\\.?\\b")
	spoken = cu_in.sub(spoken, "cubic inches", true)

	var feet_mark := RegEx.new()
	feet_mark.compile("(?i)\\bft\\.")
	spoken = feet_mark.sub(spoken, "feet", true)

	var inch_mark := RegEx.new()
	inch_mark.compile("(?i)\\bin\\.")
	spoken = inch_mark.sub(spoken, "inches", true)

	var unit_kva := RegEx.new()
	unit_kva.compile("(?i)\\b(\\d+(?:\\.\\d+)?)\\s*kva\\b")
	spoken = unit_kva.sub(spoken, "$1 kilovolt amperes", true)

	var unit_kw := RegEx.new()
	unit_kw.compile("(?i)\\b(\\d+(?:\\.\\d+)?)\\s*kw\\b")
	spoken = unit_kw.sub(spoken, "$1 kilowatts", true)

	var unit_va := RegEx.new()
	unit_va.compile("(?i)\\b(\\d+(?:\\.\\d+)?)\\s*va\\b")
	spoken = unit_va.sub(spoken, "$1 volt amperes", true)

	var unit_vdc := RegEx.new()
	unit_vdc.compile("(?i)\\b(\\d+(?:\\.\\d+)?)\\s*vdc\\b")
	spoken = unit_vdc.sub(spoken, "$1 volts D C", true)

	var unit_vac := RegEx.new()
	unit_vac.compile("(?i)\\b(\\d+(?:\\.\\d+)?)\\s*vac\\b")
	spoken = unit_vac.sub(spoken, "$1 volts A C", true)

	var unit_volts := RegEx.new()
	unit_volts.compile("(?i)\\b(\\d+(?:\\.\\d+)?)\\s*v\\b")
	spoken = unit_volts.sub(spoken, "$1 volts", true)

	var unit_ma := RegEx.new()
	unit_ma.compile("\\b(\\d+(?:\\.\\d+)?)\\s*mA\\b")
	spoken = unit_ma.sub(spoken, "$1 milliamps", true)

	var unit_amps := RegEx.new()
	unit_amps.compile("\\b(\\d+(?:\\.\\d+)?)\\s*A\\b")
	spoken = unit_amps.sub(spoken, "$1 amps", true)

	var unit_watts := RegEx.new()
	unit_watts.compile("\\b(\\d+(?:\\.\\d+)?)\\s*W\\b")
	spoken = unit_watts.sub(spoken, "$1 watts", true)

	var unit_hz := RegEx.new()
	unit_hz.compile("(?i)\\b(\\d+)\\s*hz\\b")
	spoken = unit_hz.sub(spoken, "$1 hertz", true)

	var unit_mm := RegEx.new()
	unit_mm.compile("(?i)\\b(\\d+)\\s*mm\\b")
	spoken = unit_mm.sub(spoken, "$1 millimeters", true)

	var letters := RegEx.new()
	letters.compile("\\b(THHN|THWN|THW|RHW|XHHW|NM|UF|MC|SE|USE|IMC|RMC|FMC|LFMC|ENT|AC)\\b")
	search_from = 0
	rebuilt = ""
	while true:
		var letter_hit := letters.search(spoken, search_from)
		if letter_hit == null:
			rebuilt += spoken.substr(search_from)
			break
		rebuilt += spoken.substr(search_from, letter_hit.get_start() - search_from)
		var spelled := ""
		var token := letter_hit.get_string(1)
		for i in token.length():
			spelled += token.substr(i, 1) + " "
		rebuilt += spelled.strip_edges()
		search_from = letter_hit.get_end()
	spoken = rebuilt

	# Roman numerals. A plain ordered string replace degrades "VIII" to "V3"
	# (I -> nothing, then III -> 3), so the forms are matched longest-first
	# behind a word boundary. Only the MULTI-character numerals are listed: a
	# single "I"/"V"/"X" is real content in this bank (final-exam-#1-019 asks
	# what the LETTER I represents in W = E x I, and "240 V" / "X-ray" are
	# everywhere), so substituting those would corrupt live text. I, II and III
	# are the only ones the bank actually uses today.
	var roman := {
		"VIII": "8", "XIII": "13", "XIV": "14", "XII": "12", "VII": "7",
		"VI": "6", "XI": "11", "IX": "9", "IV": "4", "III": "3", "II": "2",
	}
	var roman_re := RegEx.new()
	roman_re.compile("\\b(?:" + "|".join(PackedStringArray(roman.keys())) + ")\\b")
	var roman_out := ""
	var roman_from := 0
	while true:
		var roman_hit := roman_re.search(spoken, roman_from)
		if roman_hit == null:
			roman_out += spoken.substr(roman_from)
			break
		roman_out += spoken.substr(roman_from, roman_hit.get_start() - roman_from)
		roman_out += str(roman.get(roman_hit.get_string(0), roman_hit.get_string(0)))
		roman_from = roman_hit.get_end()
	spoken = roman_out
	spoken = spoken.replace("Class I", "class 1")
	spoken = spoken.replace("class I", "class 1")
	spoken = spoken.replace("#", "number ")
	spoken = spoken.replace(" x ", " times ")
	spoken = spoken.replace("...", ".")
	while spoken.contains(".."):
		spoken = spoken.replace("..", ".")
	while spoken.contains("  "):
		spoken = spoken.replace("  ", " ")
	if spoken.length() > 0 and spoken.substr(0, 1) == spoken.substr(0, 1).to_lower():
		spoken = spoken.substr(0, 1).to_upper() + spoken.substr(1)
	return spoken.strip_edges()

static func spoken_fraction(top: String, bottom: String) -> String:
	var n := int(top)
	var d := int(bottom)
	var num_words := {
		1: "one", 2: "two", 3: "three", 4: "four", 5: "five",
		6: "six", 7: "seven", 8: "eight", 9: "nine", 10: "ten",
		11: "eleven", 12: "twelve", 13: "thirteen", 14: "fourteen", 15: "fifteen",
		16: "sixteen", 17: "seventeen", 18: "eighteen", 19: "nineteen",
		21: "twenty-one", 23: "twenty-three", 25: "twenty-five", 27: "twenty-seven",
		29: "twenty-nine", 31: "thirty-one"
	}
	var num_str: String = num_words.get(n, str(n))
	var is_singular := (n == 1)

	match d:
		2:
			return "one half" if is_singular else "%s halves" % num_str
		3:
			return "one third" if is_singular else "%s thirds" % num_str
		4:
			return "one quarter" if is_singular else "%s quarters" % num_str
		8:
			return "one eighth" if is_singular else "%s eighths" % num_str
		16:
			return "one sixteenth" if is_singular else "%s sixteenths" % num_str
		32:
			return "one thirty-second" if is_singular else "%s thirty-seconds" % num_str
		64:
			return "one sixty-fourth" if is_singular else "%s sixty-fourths" % num_str
		_:
			return "%s over %s" % [top, bottom]
