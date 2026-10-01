extends RefCounted
## The voice normaliser: written question-bank text -> text a TTS voice reads
## correctly. One ruleset feeds BOTH voices (Edge neural clips on desktop and
## DisplayServer.tts_* on mobile), because both consume speech_text.gd's plans.
##
## Spec: docs/VOICE_READING_RULES.md. Every rule id in PIPELINE has a golden
## case in tools/tests/test_speech_rules.gd, and that suite fails if one is
## added without a case.
##
## VERSION is stamped into every speech segment and clip manifest, so cached or
## bundled audio rendered under older rules is never replayed. Bump it whenever
## a change here can alter spoken output.

const VERSION := 4

## Ordered pipeline. [id, pattern, replacement] is a regex substitution;
## [id, ""] is a function stage (see _apply_function). Order matters: e.g. the
## unspaced mixed number must run before the inch mark and cable rules, and
## units run before acronym spelling so "20 A" becomes "20 amps", not "20 A".
const PIPELINE := [
	# Code-Making Panel tags and NFPA extract sources close Article 100
	# definitions; read aloud they are "(C M P, 18)" and "[499 colon 3.3.4.2]".
	["panel_tag", "\\s*\\(CMP[\\s\\-—–]*\\d+\\)", ""],
	["extract_tag", "\\s*\\[\\d+[A-Z]?:[\\w.()\\-]+\\]", ""],
	["table_block", ""],
	["typography", ""],
	# A table row flattened into prose ("15 | 20 | 12"): a pause, not "vertical bar".
	["table_pipes", "\\s*\\|\\s*", ", "],
	# A footnote mark on a word ("*In addition", "(FMC)*"); a spaced * is multiplication.
	["footnote_star", "(?<![\\w)*])\\*(?=[A-Za-z])|(?<=[A-Za-z)])\\*(?![\\w*])", ""],
	["footnote_dagger", "[†‡]", ""],
	# "1ø 115-volt motor": the phase sign is silent on every voice.
	["phase_single", "(?<!\\()\\b1\\s*[øØφΦ](?!\\w)", "single-phase"],
	["phase_three", "(?<!\\()\\b3\\s*[øØφΦ](?!\\w)", "three-phase"],
	["sigma_sum", "Σ\\s*", "the sum of "],
	# "125%/115%" (430.32(A)(1)): two alternatives, not a division.
	["percent_or", "(\\d)\\s*%\\s*/\\s*(\\d)", "$1% or $2"],
	# The welder's rated primary current, one symbol: not "I-one-max" run together.
	["welder_i1max", "\\bI1max\\b", "I 1 max"],
	# "#12-2 with ground" is said "twelve two", never "12 to 2" (number_range).
	["cable_dash", "#\\s*(\\d{1,2})-([234])\\b(?=\\s+(?:with|w/|NM|cable|conductors?)\\b)", "number $1 $2"],
	# "33 VA/m2 (3 VA/ft2)": a unit load per area.
	["per_square_meter", "/\\s*m2\\b", " per square meter"],
	["per_square_foot", "/\\s*ft2\\b", " per square foot"],
	# Before number_range turns the Nebraska section 81-2113 into "81 to 2113".
	["state_citations", ""],
	["abbreviations", ""],
	# ".6875" is 0.6875; the tidy stage would drop a bare leading point.
	["leading_decimal_point", "(?<![\\w.])\\.(\\d)", "0.$1"],
	["plural_suffix", "(?<=[A-Za-z])\\(s\\)", "s"],
	# "11/2" typed for 1 1/2. Numerator pinned to 1 so the live 15/16 stays a fraction.
	["mixed_number_unspaced", "(?<![\\d/])([1-9])(1)/([248]|16)(?![\\d/])", "$1 $2/$3"],
	["mixed_number_hyphen", "\\b(\\d+)-(\\d+)/(\\d+)\\b", "$1 $2/$3"],
	# Box and room sizes are said "3 by 2 by 2-inch": before the inch marks.
	["dimensions", ""],
	["inch_mark_mixed", "(\\d+)\\s+(\\d+)/(\\d+)\\s*\"", "$1 and $2/$3 inches"],
	["inch_mark_fraction", "(\\d+)/(\\d+)\\s*\"", "$1/$2 inch"],
	["inch_mark_one", "(?<![\\d.])1\\s*\"", "1 inch"],
	["inch_mark", "(\\d+(?:\\.\\d+)?)\\s*\"", "$1 inches"],
	["quote_strip", "\"", ""],
	# Must follow a digit and not precede a letter, so "the Code's" survives.
	["foot_mark", "(\\d+)\\s*'(?![A-Za-z])", "$1 feet"],
	["foot_inch_seam", "\\b(feet|foot)(\\d)", "$1 $2"],
	["typo_srating", "srating", "stating"],
	["blank_named", "(?i)\\b(article|table|section)\\s*_+", "which $1"],
	["blank_run", "_{2,}", " blank "],
	# A lone underscore between word chars is a formula subscript (R_total).
	["subscript", "(?<=[A-Za-z0-9])_(?=[A-Za-z])", " "],
	["trailing_junk", "\\s+\\.\\s+[a-zA-Z]\\s*$", "."],
	["roman_list_marker", ""],
	["roman_choice_before", "\\bI\\b(?=(?:,|,? and|,? or)\\s+(?:II|III|IV)\\b)", "1"],
	["roman_choice_after", "\\b(II|III|IV)(,?) (and|or) I\\b", "$1$2 $3 1"],
	["roman_choice_only", "^I(?= only\\b)", "1"],
	["area_units", ""],
	# Before symbols turns µ into "micro" and leaves the A a letter ("microA").
	["unit_microamps", "(\\d+(?:\\.\\d+)?)\\s*µA\\b", "$1 microamps"],
	# "6.24 x 10^18 electrons"; read as "10 caret 18" otherwise.
	["power_of_ten", "\\b10\\s*\\^\\s*(\\d+)\\b", "10 to the power of $1"],
	# "a ratio of 20:1" is read as a clock time.
	["ratio_colon", "(?i)\\b(ratios?(?:\\s+of)?\\s+)(\\d+):(\\d+)\\b", "$1$2 to $3"],
	# "What does the -2 represent?" (THWN-2): a suffix, not minus 2.
	["suffix_dash", "\\b(the) -(\\d)\\b", "$1 dash $2"],
	["symbols", ""],
	["degrees_c", "(?i)\\b(\\d+(?:\\.\\d+)?)\\s*(?:°|degrees?\\s*)C\\b", "$1 degrees Celsius"],
	["degrees_f", "(?i)\\b(\\d+(?:\\.\\d+)?)\\s*(?:°|degrees?\\s*)F\\b", "$1 degrees Fahrenheit"],
	["degree_sign", "°", " degrees "],
	["vulgar_fractions", ""],
	["slash_words", ""],
	["wye_voltage", "\\b(\\d+)\\s*Y\\s*/\\s*(\\d+)", "$1 wye $2"],
	["slash_voltage", "(?i)\\b(\\d+)\\s*/\\s*(\\d+)(?=\\s*-?\\s*(?:v|volts?)\\b)", "$1 slash $2"],
	["kcmil", "(?i)kcmil", " thousand circular mil "],
	["expand_acronyms", ""],
	["compound_slash", ""],
	# "Rt = 1 ÷ (1/R1 + 1/R2)": a number over a symbol, read "slash" otherwise.
	["reciprocal_slash", "(?<![\\w./])(\\d+(?:\\.\\d+)?)/([A-Za-z]\\w*)", "$1 over $2"],
	["number_abbrev", "(?i)\\bNo\\.\\s*(\\d+)\\b", "number $1"],
	["references", ""],
	["designator_pair", "(?<![\\w)])\\(([A-Z])\\)\\((\\d{1,2})\\)", "paragraph $1, item $2"],
	["wire_aught", ""],
	# 12/3, 10/2 cable: a conductor count, not a fraction ("twelve thirds").
	["cable_designation", "(?<![\\d/])([89]|[1-9]\\d)/([23])(?![\\d/])", "$1 slash $2"],
	["mixed_number", ""],
	["fraction", ""],
	# "1/240 second": "one two-hundred-fortieth of a second".
	["fraction_of_a_second", "\\b(one (?:[a-z]+-)*[a-z]+th) seconds?\\b", "$1 of a second"],
	# How it is said: "one and a half inch", "two and a quarter".
	["mixed_a_half", "\\b(\\d+) and one (half|quarter)\\b", "$1 and a $2"],
	# Before the units: "2x30A" has no word boundary before 30 until x is a word.
	["times_digits", "(\\d)\\s*[xX]\\s*(\\d)", "$1 times $2"],
	["unit_sq_ft", "(?i)\\bsq\\.?\\s*ft\\.?(?!\\w)", "square feet"],
	["unit_sq_in", "(?i)\\bsq\\.?\\s*in(?:ches)?\\.?(?!\\w)", "square inches"],
	["unit_cu_in", "(?i)\\bcu\\.?\\s*in(?:ches)?\\.?(?!\\w)", "cubic inches"],
	["unit_ft_adjective", "\\b(\\d+(?:\\.\\d+)?)-ft\\b\\.?", "$1-foot"],
	["unit_ft_dot_end", "\\b[Ff][Tt]\\.(?=\\s+[A-Z](?:[a-z]|\\s)|\\s*$)", "feet."],
	["unit_ft_dot", "(?i)\\bft\\.", "feet"],
	["unit_ft", "(\\d|half|quarters?|thirds?|eighths?|sixteenths?)\\s*ft\\b", "$1 feet"],
	["unit_in_dot_end", "(?<=\\d )[Ii][Nn]\\.(?=\\s+[A-Z](?:[a-z]|\\s)|\\s*$)", "inches."],
	["unit_in_dot", "(?i)\\bin\\.", "inches"],
	# Bare "in" only where it cannot be the preposition.
	["unit_in", "(\\d|half|quarters?|thirds?|eighths?|sixteenths?)\\s+in\\b(?=\\s*(?:[),;:=]|$|per\\b|divided\\b|times\\b))", "$1 inches"],
	# After every inch rule: "15/16 in." is less than one inch, so "inch".
	["fraction_inch_singular", "(?<!\\d and )\\b((?:one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen) (?:half|halves|thirds?|quarters?|fifths?|sixths?|eighths?|tenths?|sixteenths?|thirty-seconds?|sixty-fourths?))\\s+inches\\b", "$1 inch"],
	["fraction_inch_hyphen", "\\b(half|halves|thirds?|quarters?|fifths?|sixths?|eighths?|tenths?|sixteenths?|thirty-seconds?|sixty-fourths?)-inch\\b", "$1 inch"],
	# Trade sizes. Every voice is heard as "1.5 inch" for "one half inch".
	["half_quarter_inch", "(?<!\\d and )\\bone (half|quarter) inch\\b", "$1 inch"],
	["three_quarter_inch", "(?<!\\d and )\\bthree quarters inch\\b", "three quarter inch"],
	# "three eighths inch" is heard as "3.8 inch"; "of an inch" keeps the fraction.
	["fraction_of_an_inch", "(?<!\\d and )\\b((?:one|two|three|four|five|seven|nine|eleven|thirteen|fifteen) (?:thirds?|fifths?|sixths?|eighths?|tenths?|sixteenths?|thirty-seconds?|sixty-fourths?)) inch\\b", "$1 of an inch"],
	["unit_lb_in", "(?i)\\blbs?[- ]in(?:ch(?:es)?)?\\b\\.?", "pound-inches"],
	["unit_lb_ft", "(?i)\\blbs?[- ]f(?:ee)?t\\b\\.?", "pound-feet"],
	["unit_lb", "(?i)(\\d)\\s*lbs?\\b\\.?", "$1 pounds"],
	["unit_mm", "(?i)\\b(\\d+(?:\\.\\d+)?)\\s*mm\\b", "$1 millimeters"],
	["unit_m", "\\b(\\d+(?:\\.\\d+)?)\\s?m\\b(?![-'])", "$1 meters"],
	["unit_s", "\\b(\\d*\\.\\d+|\\d+)\\s+s\\b(?=\\s*(?:[.,;)]|$))", "$1 seconds"],
	["unit_kva", "(?i)\\b(\\d+(?:\\.\\d+)?)\\s*kva\\b", "$1 kilovolt amperes"],
	["unit_kw", "(?i)\\b(\\d+(?:\\.\\d+)?)\\s*kw\\b", "$1 kilowatts"],
	["unit_va", "(?i)\\b(\\d+(?:\\.\\d+)?)\\s*va\\b", "$1 volt amperes"],
	["unit_vdc", "(?i)\\b(\\d+(?:\\.\\d+)?)\\s*vdc\\b", "$1 volts D C"],
	["unit_vac", "(?i)\\b(\\d+(?:\\.\\d+)?)\\s*vac\\b", "$1 volts A C"],
	["unit_kv", "\\b(\\d+(?:\\.\\d+)?)\\s*kV\\b", "$1 kilovolts"],
	["unit_ka", "\\b(\\d+(?:\\.\\d+)?)\\s*kA\\b", "$1 kiloamps"],
	["unit_volts", "(?i)\\b(\\d+(?:\\.\\d+)?)\\s*v\\b", "$1 volts"],
	["unit_ma", "\\b(\\d+(?:\\.\\d+)?)\\s*mA\\b", "$1 milliamps"],
	["unit_amps", "\\b(\\d+(?:\\.\\d+)?)\\s*A\\b", "$1 amps"],
	# Choices typed "17.5a", "400a": read as the letter A otherwise.
	["unit_amps_glued", "\\b(\\d+(?:\\.\\d+)?)a\\b", "$1 amps"],
	["unit_watts", "\\b(\\d+(?:\\.\\d+)?)\\s*W\\b", "$1 watts"],
	["unit_hz", "(?i)\\b(\\d+)\\s*hz\\b", "$1 hertz"],
	["percent", "\\s*%", " percent"],
	["singular_one", ""],
	["unit_attributive", ""],
	# A spelled type ending in N runs into the next word ("T H H N wire" is
	# heard as "T H H and wire"); the pause keeps the N a letter on every voice.
	["wire_type_pause", "\\b(THHN|THWN|XHHN|XHWN|TFN|TFFN)(?=\\s+[A-Za-z0-9])", "$1,"],
	# "THWN-2": without the pause and "dash", "N 2" is heard as "and 2".
	["type_suffix_digit", "\\b([A-Z]{2,6})-([0-9])\\b", "$1, dash $2"],
	["type_suffix", "\\b([A-Z]{2,6})-([A-Z])\\b", "$1 $2"],
	["roman_numerals", ""],
	["class_one", "\\b([Cc])lass I\\b", "$1lass 1"],
	["spell_acronyms", ""],
	["unshout", ""],
	["spell_unknown_caps", ""],
	["hash", "#\\s*", "number "],
	["formula_operators", ""],
	["times_spaced", "(?<=\\s)x(?=\\s)", "times"],
	["number_range", "(?<![\\d.])(\\d+(?:\\.\\d+)?)\\s?-\\s?(\\d+(?:\\.\\d+)?)(?![\\d/.])", "$1 to $2"],
	["comparison", ""],
	["line_breaks", ""],
	["tidy", ""],
]

## Spoken in place of a tab-separated table block. Tables are never read cell
## by cell: the grid is on screen, and a voice reading "200, 8, 250, 10" teaches
## nothing.
const TABLE_ON_SCREEN := "The table is shown on screen."

## Stem-only rule (speech_text.spoken_segments): a prompt whose blank was lost
## in the source ("the current's .") is spoken with the blank restored.
const LOST_BLANK_RE := "(?<=[A-Za-z'])\\s+\\.\\s*$"

const TYPOGRAPHY := {
	"“": "\"", "”": "\"", "″": "\"", "‘": "'", "’": "'", "′": "'",
	"«": "", "»": "", "…": "...", "•": ", ", "\u00a0": " ",
	"[": "(", "]": ")",
}

## Case-insensitive, matched only at a word start.
const ABBREVIATIONS := {
	"e.g.": "for example", "i.e.": "that is", "etc.": "et cetera",
	"approx.": "approximately", "min.": "minimum", "max.": "maximum",
	"vs.": "versus", "incl.": "including", "fig.": "figure", "ex.": "Exception",
}

const ROMAN_LIST := {"I": "1", "II": "2", "III": "3", "IV": "4"}

const SYMBOLS := {
	"—": ", ", "–": " to ", "→": ", so ", "÷": " divided by ", "×": " times ",
	"√": " square root of ", "≈": " is about ", "Ω": " ohms ", "¢": " cents ",
	"−": " minus ", "≤": " less than or equal to ", "≥": " greater than or equal to ",
	"±": " plus or minus ", "µ": " micro", "²": " squared", "³": " cubed",
	"@": " at ",
}

const AREA_UNITS := {"mm": "square millimeters", "in": "square inches", "ft": "square feet"}

const VULGAR_FRACTIONS := {"½": "one half", "¼": "one quarter", "¾": "three quarters"}

## Exact, case-sensitive substrings.
const SLASH_WORDS := {
	"a/an": "a or an", "and/or": "and or", "cu/al": "copper or aluminum",
	"CU/AL": "copper or aluminum", "CO/ALR": "C O A L R", "ockout/tagout": "ockout tagout",
}

## Acronyms read as their words. Everything electricians say letter by letter
## is in SPELL instead.
const EXPAND := {
	"OCPD": "overcurrent protective device", "EGC": "equipment grounding conductor",
	"GEC": "grounding electrode conductor", "AHJ": "authority having jurisdiction",
	"HP": "horsepower", "kVA": "kilovolt amperes", "kW": "kilowatts", "VA": "volt amperes",
}

const AUGHT := {"1": "one aught", "2": "two aught", "3": "three aught", "4": "four aught"}

const SINGULAR := {
	"amps": "amp", "volts": "volt", "watts": "watt", "feet": "foot", "inches": "inch",
	"meters": "meter", "millimeters": "millimeter", "pounds": "pound", "seconds": "second",
	"ohms": "ohm", "kilowatts": "kilowatt", "kilovolts": "kilovolt", "milliamps": "milliamp",
}

## A unit used as an adjective is singular and hyphenated: "a 200-amp service",
## "a 12-foot assembly", "a 1-inch E M T conduit". It is an adjective when a
## lowercase word (or a spelled-out raceway like "E M T") follows, unless that
## word is one of these, which follow a quantity: "10 feet long", "20 feet or
## more", "150 volts to ground", "180 volt amperes".
const ATTRIBUTIVE_STOP := [
	"or", "and", "but", "nor", "x", "times", "equals", "minus", "plus", "divided", "multiplied",
	"over", "through", "thru", "to", "in", "of", "on", "at", "for", "from", "per", "by",
	"with", "without", "as", "than", "into", "onto", "between", "above", "below", "under",
	"within", "beyond", "past", "before", "after", "apart", "away", "off", "up", "down",
	"is", "are", "was", "were", "be", "been", "being", "does", "do", "did", "shall", "must",
	"may", "can", "will", "would", "should", "could", "has", "have", "had",
	"long", "wide", "high", "deep", "thick", "tall", "square", "cubed", "squared",
	"horizontally", "vertically", "diagonally", "continuously", "nominal", "total",
	"peak", "maximum", "minimum", "max", "min", "actual", "each", "less", "more", "about",
	"approximately", "versus", "vs", "rms", "ac", "dc", "line-to-line", "line-to-neutral",
	"phase-to-phase", "phase-to-ground", "to-ground", "measured", "appearing", "installed",
	"located", "pass", "passes", "counts", "falls", "fall", "gives", "give", "needed",
	"required", "allowed", "permitted", "left", "remaining", "if", "when", "where", "which",
	"that", "so", "then", "while", "unless", "because", "whichever", "respectively",
	"amperes", "ampere", "amps", "hours", "hour", "feet", "foot", "inches", "inch",
	"a", "an", "the", "not", "no", "section", "sections", "paragraph", "item",
]

## Longest first behind a word boundary: a plain replace turned VIII into V3.
## A bare I/V/X is real content (W = E x I, 240 V), so it is never listed.
const ROMAN := {
	"VIII": "8", "XIII": "13", "XIV": "14", "XII": "12", "VII": "7",
	"VI": "6", "XI": "11", "IX": "9", "IV": "4", "III": "3", "II": "2",
}

## Spoken letter by letter. Edge reads vowel-bearing caps as words ("STOOW" ->
## "stow", "MI" -> "my", "HARC" -> "hark"); spaced letters are the only form it
## reliably spells. Hyphens and dots between letters do not help.
const SPELL := [
	"GFCI", "AFCI", "SPGFCI", "LCDI", "AWG", "EMT", "PVC", "NEC", "NFPA", "UL", "NRTL",
	"THHN", "THWN", "THHW", "THW", "RHW", "RHH", "XHHW", "XHWN", "XHH", "TW", "SIS",
	"NM", "NMC", "NMS", "UF", "MC", "MI", "SE", "SER", "SEU", "USE", "TC", "FC", "FCC",
	"IMC", "RMC", "FMC", "LFMC", "LFNC", "ENT", "RNC", "NUCC", "HDPE", "AC", "DC",
	"STOOW", "SJOOW", "SOOW", "SO", "SJ", "SPT", "CATV", "CMP", "CMR", "PLTC", "ITC",
	"SPDT", "SPST", "DPDT", "DPST", "PWR", "MCM", "ASTM", "IEC", "HARC", "PV", "EV",
	"RV", "TV", "VD", "MV", "PF", "PB", "AA", "PSI", "UPS", "SWD", "HID", "LED",
	"CT", "GFPE", "FPN", "ANSI", "UV", "SPD", "HACR", "FAA", "USB", "CSA", "XHHN", "TFN", "TFFN",
	"IBEW", "EVSE", "OL",
]

## Read as a word or a fixed phrase, never spelled or lower-cased. Emphasis
## words (NOT, ON, GIVEN) are listed because Edge already reads them as words.
const SAY_AS := {
	"IEEE": "I triple E", "NEMA": "NEMA", "OSHA": "OSHA", "HVAC": "HVAC", "PAR": "par",
	"NOT": "NOT", "ON": "ON", "OFF": "OFF", "GIVEN": "GIVEN", "ONLY": "ONLY", "ALL": "ALL",
	"COPPER": "copper", "ALUMINUM": "aluminum", "ELI": "Eli", "ICE": "ice",
}

static var _cache := {}


static func normalize(text: String) -> String:
	var spoken := text.strip_edges()
	if spoken == "":
		return ""
	for rule in PIPELINE:
		if str(rule[1]) == "":
			spoken = _apply_function(str(rule[0]), spoken)
		else:
			spoken = _re(str(rule[1])).sub(spoken, str(rule[2]), true)
	return spoken


## Rule ids in pipeline order (the test suite's coverage contract).
static func rule_ids() -> Array[String]:
	var ids: Array[String] = []
	for rule in PIPELINE:
		ids.append(str(rule[0]))
	return ids


## Runs the pipeline only up to and including `last_id`. Lets the test suite
## pin one rule's effect without the later stages rewriting it.
static func normalize_through(text: String, last_id: String) -> String:
	var spoken := text.strip_edges()
	for rule in PIPELINE:
		if str(rule[1]) == "":
			spoken = _apply_function(str(rule[0]), spoken)
		else:
			spoken = _re(str(rule[1])).sub(spoken, str(rule[2]), true)
		if str(rule[0]) == last_id:
			break
	return spoken


static func restore_lost_blank(prompt: String) -> String:
	if prompt.contains("_"):
		return prompt
	return _re(LOST_BLANK_RE).sub(prompt, " ___.", false)


## A bare section number offered as an answer choice ("210.12") is read the
## way the stem's "Section ___" asks for it: "210 point 12".
static func is_bare_reference(choice: String) -> bool:
	return _re("^\\d{2,3}\\.\\d{1,3}(?:\\((?:[A-Za-z]|\\d{1,2})\\))*$").search(choice.strip_edges()) != null


static func bare_reference(choice: String) -> String:
	var m := _re("^(\\d{2,3})\\.(\\d{1,3})((?:\\((?:[A-Za-z]|\\d{1,2})\\))*)$").search(choice.strip_edges())
	if m == null:
		return normalize(choice)
	return _speak_reference("", m.get_string(1), m.get_string(2), m.get_string(3))


static func spoken_fraction(top: String, bottom: String) -> String:
	var n := int(top)
	var num_words := {
		1: "one", 2: "two", 3: "three", 4: "four", 5: "five",
		6: "six", 7: "seven", 8: "eight", 9: "nine", 10: "ten",
		11: "eleven", 12: "twelve", 13: "thirteen", 14: "fourteen", 15: "fifteen",
		16: "sixteen", 17: "seventeen", 18: "eighteen", 19: "nineteen",
		21: "twenty-one", 23: "twenty-three", 25: "twenty-five", 27: "twenty-seven",
		29: "twenty-nine", 31: "thirty-one"
	}
	var num_str: String = num_words.get(n, str(n))
	var one := n == 1
	match int(bottom):
		2:
			return "one half" if one else "%s halves" % num_str
		3:
			return "one third" if one else "%s thirds" % num_str
		4:
			return "one quarter" if one else "%s quarters" % num_str
		5:
			return "one fifth" if one else "%s fifths" % num_str
		6:
			return "one sixth" if one else "%s sixths" % num_str
		8:
			return "one eighth" if one else "%s eighths" % num_str
		10:
			return "one tenth" if one else "%s tenths" % num_str
		16:
			return "one sixteenth" if one else "%s sixteenths" % num_str
		32:
			return "one thirty-second" if one else "%s thirty-seconds" % num_str
		64:
			return "one sixty-fourth" if one else "%s sixty-fourths" % num_str
		_:
			# "1/60 second", "1/20 of the primary": a unit fraction is said as one.
			if one and int(bottom) > 1 and int(bottom) < 1000:
				return "one " + _ordinal_words(int(bottom))
			return "%s over %s" % [top, bottom]


const CARDINAL_UNITS := ["", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
	"eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
const ORDINAL_UNITS := ["", "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth",
	"eleventh", "twelfth", "thirteenth", "fourteenth", "fifteenth", "sixteenth", "seventeenth", "eighteenth", "nineteenth"]
const CARDINAL_TENS := ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]
const ORDINAL_TENS := ["", "", "twentieth", "thirtieth", "fortieth", "fiftieth", "sixtieth", "seventieth", "eightieth", "ninetieth"]


## 7 -> "seventh", 60 -> "sixtieth", 240 -> "two-hundred-fortieth" (1-999).
static func _ordinal_words(n: int) -> String:
	var head := ""
	if n >= 100:
		head = CARDINAL_UNITS[n / 100] + "-hundred"
		n %= 100
		if n == 0:
			return head + "th"
		head += "-"
	if n < 20:
		return head + ORDINAL_UNITS[n]
	if n % 10 == 0:
		return head + ORDINAL_TENS[n / 10]
	return head + CARDINAL_TENS[n / 10] + "-" + ORDINAL_UNITS[n % 10]


static func _re(pattern: String) -> RegEx:
	if not _cache.has(pattern):
		var compiled := RegEx.new()
		compiled.compile(pattern)
		_cache[pattern] = compiled
	return _cache[pattern]


## Replaces every match of `pattern` with fn.call(match, text).
static func _each(text: String, pattern: String, fn: Callable) -> String:
	var out := ""
	var from := 0
	for m in _re(pattern).search_all(text):
		out += text.substr(from, m.get_start() - from)
		out += str(fn.call(m, text))
		from = m.get_end()
	return out + text.substr(from)


static func _replace_table(text: String, table: Dictionary) -> String:
	for key in table:
		text = text.replace(str(key), str(table[key]))
	return text


static func _words_alternation(words: Array) -> String:
	var escaped: PackedStringArray = []
	for w in words:
		escaped.append(str(w).replace(".", "\\."))
	return "|".join(escaped)


## "3" x 2" x 2" device box", "4 x 2-1/8 in. octagon box", "10 ft x 12 ft":
## sizes are "3 by 2 by 2" with the unit once, at the end. A chain is a size
## when a term has an inch or foot mark, a term is a mixed number, or a box
## follows; never next to = + − ÷ (arithmetic: "5000 x 1.3 = 6,500").
const DIM_TERM := "\\d+(?:\\.\\d+)?(?: \\d+/\\d+)?(?:\\s*(?:\"|''|in\\.|inch(?:es)?\\b|ft\\.?|feet\\b|'))?"
const DIM_TERM_PARTS := "(\\d+(?:\\.\\d+)?(?: \\d+/\\d+)?)(?:\\s*(\"|''|in\\.|inch(?:es)?\\b|ft\\.?|feet\\b|'))?"
const DIM_ARITH_BEFORE := "[=+−÷*/×xX-]\\s*$"
const DIM_ARITH_AFTER := "^\\s*(?:[=+−÷*/%]|-\\s*\\d)"
const DIM_BOX_AFTER := "^\\s*(?:in\\.|inch(?:es)?|\")?\\s*(?:[a-z-]+\\s+){0,2}box(?:es)?\\b"


static func _dimensions(text: String) -> String:
	var chain := "(?<![\\w.])" + DIM_TERM + "(?:\\s*[x×]\\s*" + DIM_TERM + "){1,2}(?![\\w/])"
	return _each(text, chain, func(m: RegExMatch, src: String) -> String:
		var before := src.substr(maxi(0, m.get_start() - 12), mini(12, m.get_start()))
		var after := src.substr(m.get_end(), 40)
		if _re(DIM_ARITH_BEFORE).search(before) != null or _re(DIM_ARITH_AFTER).search(after) != null:
			return m.get_string(0)
		var numbers: PackedStringArray = []
		var unit := ""
		var mixed := false
		for t in _re(DIM_TERM_PARTS).search_all(m.get_string(0)):
			numbers.append(t.get_string(1))
			mixed = mixed or t.get_string(1).contains("/")
			if t.get_string(2) != "":
				unit = t.get_string(2)
		if unit == "" and not mixed and _re(DIM_BOX_AFTER).search(after) == null:
			return m.get_string(0)
		if unit == "":
			return " by ".join(numbers)
		return " by ".join(numbers) + (unit if unit in ["\"", "''", "'"] else " " + unit))


static func _apply_function(id: String, text: String) -> String:
	match id:
		"dimensions":
			return _dimensions(text)
		"table_block":
			return _table_block(text)
		"line_breaks":
			text = _re("([^.?!:;,\\s])[ \\t]*\\n\\s*").sub(text, "$1. ", true)
			return _re("\\s*\\n\\s*").sub(text, " ", true)
		"typography":
			return _replace_table(text, TYPOGRAPHY)
		"state_citations":
			return _state_citations(text)
		"abbreviations":
			var pattern := "(?i)(?<![A-Za-z])(" + _words_alternation(ABBREVIATIONS.keys()) + ")"
			return _each(text, pattern, func(m: RegExMatch, _src: String) -> String:
				return str(ABBREVIATIONS.get(m.get_string(1).to_lower(), m.get_string(1))))
		"roman_list_marker":
			return _each(text, "(?<![^\\s])(III|II|IV|I)\\.(?=\\s+[a-z])", func(m: RegExMatch, _src: String) -> String:
				return ". Item %s," % str(ROMAN_LIST[m.get_string(1)]))
		"area_units":
			# "3 VA per ft²" is per square foot, not "per square feet".
			return _each(text, "(\\bper\\s+)?\\b(mm|in|ft)(?:²|\\^2)", func(m: RegExMatch, _src: String) -> String:
				var unit := str(AREA_UNITS[m.get_string(2)])
				if m.get_string(1) != "":
					return m.get_string(1) + unit.replace("feet", "foot").replace("inches", "inch").trim_suffix("s")
				return unit)
		"symbols":
			return _replace_table(text, SYMBOLS)
		"vulgar_fractions":
			return _each(text, "(\\d?)\\s*([½¼¾])", func(m: RegExMatch, _src: String) -> String:
				var words := str(VULGAR_FRACTIONS[m.get_string(2)])
				return (m.get_string(1) + " and " + words) if m.get_string(1) != "" else (" " + words))
		"slash_words":
			return _replace_table(text, SLASH_WORDS)
		"expand_acronyms":
			var pattern := "(?i)\\b(" + _words_alternation(EXPAND.keys()) + ")(s?)\\b"
			return _each(text, pattern, func(m: RegExMatch, _src: String) -> String:
				for key in EXPAND:
					if str(key).to_lower() == m.get_string(1).to_lower():
						return str(EXPAND[key]) + m.get_string(2)
				return m.get_string(0))
		"compound_slash":
			# In a formula "P/E" is division; in prose "under/over" is a choice.
			var joiner := " divided by " if text.contains("=") else " or "
			return _re("(?i)\\b([a-z]+)/([a-z]+)\\b").sub(text, "$1" + joiner + "$2", true)
		"references":
			return _references(text)
		"wire_aught":
			return _each(text, "\\b([1-4])/0\\b", func(m: RegExMatch, _src: String) -> String:
				return str(AUGHT[m.get_string(1)]))
		"mixed_number":
			return _each(text, "\\b(\\d+)\\s+(\\d+)/(\\d+)\\b", func(m: RegExMatch, _src: String) -> String:
				return m.get_string(1) + " and " + spoken_fraction(m.get_string(2), m.get_string(3)))
		"fraction":
			return _each(text, "\\b(\\d+)/(\\d+)\\b", func(m: RegExMatch, _src: String) -> String:
				return spoken_fraction(m.get_string(1), m.get_string(2)))
		"singular_one":
			var pattern := "(?<![\\d.,])\\b1 (" + _words_alternation(SINGULAR.keys()) + ")\\b"
			return _each(text, pattern, func(m: RegExMatch, _src: String) -> String:
				return "1 " + str(SINGULAR[m.get_string(1)]))
		"unit_attributive":
			var units: Array = SINGULAR.keys() + SINGULAR.values()
			var alt := _words_alternation(units)
			var pattern := "(?<![\\d.,-])\\b(\\d[\\d,]*(?:\\.\\d+)?) (" + alt + ") (?=([a-z][a-z-]*|[A-Z][A-Z-]+|[A-Z] [A-Z] [A-Z])\\b)"
			text = _each(text, pattern, func(m: RegExMatch, _src: String) -> String:
				if ATTRIBUTIVE_STOP.has(m.get_string(3).to_lower()) or m.get_string(3) in ["AC", "DC", "RMS"]:
					return m.get_string(0)
				return m.get_string(1) + "-" + str(SINGULAR.get(m.get_string(2), m.get_string(2))) + " ")
			# "a 30 amps, 240-volt circuit" (a rating: any unit) and "12 kilowatts
			# through 27-kilowatt ranges" (a range: the same unit) are adjectives too.
			var list_pattern := "(?<![\\d.,-])\\b(\\d[\\d,]*(?:\\.\\d+)?) (" + alt + ")(,? (?:(?:through|to|or|and) )?)(?=\\d[\\d,]*(?:\\.\\d+)?-(" + alt + ") )"
			text = _each(text, list_pattern, func(m: RegExMatch, _src: String) -> String:
				var one := str(SINGULAR.get(m.get_string(2), m.get_string(2)))
				if one != m.get_string(4) and m.get_string(3) != ", ":
					return m.get_string(0)
				return m.get_string(1) + "-" + one + m.get_string(3))
			# "a 2 and one eighth inch octagon box", "a three quarter inch E M T".
			var fraction_pattern := "\\b(half|halves|quarters?|thirds?|eighths?|sixteenths?) inches (?=([a-z][a-z-]*|[A-Z][A-Z-]+|[A-Z] [A-Z] [A-Z])\\b)"
			return _each(text, fraction_pattern, func(m: RegExMatch, _src: String) -> String:
				if ATTRIBUTIVE_STOP.has(m.get_string(2).to_lower()) or m.get_string(2) in ["AC", "DC", "RMS"]:
					return m.get_string(0)
				var word := m.get_string(1)
				word = "half" if word == "halves" else word.trim_suffix("s")
				return word + " inch ")
		"roman_numerals":
			var pattern := "\\b(?:" + _words_alternation(ROMAN.keys()) + ")\\b"
			return _each(text, pattern, func(m: RegExMatch, _src: String) -> String:
				return str(ROMAN[m.get_string(0)]))
		"spell_acronyms":
			var pattern := "\\b(" + _words_alternation(SPELL + SAY_AS.keys()) + ")(s?)\\b"
			return _each(text, pattern, func(m: RegExMatch, _src: String) -> String:
				var token := m.get_string(1)
				if SAY_AS.has(token):
					return str(SAY_AS[token]) + m.get_string(2)
				return _spell(token) + ("'s" if m.get_string(2) != "" else ""))
		"unshout":
			return _unshout(text)
		"spell_unknown_caps":
			return _each(text, "\\b[B-DF-HJ-NP-TV-XZ]{2,6}\\b", func(m: RegExMatch, _src: String) -> String:
				return m.get_string(0) if SAY_AS.has(m.get_string(0)) else _spell(m.get_string(0)))
		"formula_operators":
			return _formula_operators(text)
		"comparison":
			return text.replace(" < ", " less than ").replace(" > ", " greater than ")
		"tidy":
			return _tidy(text)
	push_error("speech_rules: unknown function stage " + id)
	return text


## Nebraska statute and board-rule citations. A statute section is read the way
## it is said aloud: "Neb. Rev. Stat. 81-2108(2)" -> "Nebraska Revised Statute
## eighty-one twenty-one oh-eight, subsection 2". Only sections after "Neb. Rev.
## Stat." or "section(s)" are converted, so an NEC range such as "100-400" is
## left for number_range.
const STATE_SECTION := "\\b(\\d{2})-(\\d{4})((?:\\(\\w+\\))*)"
## One or more sections joined as a list: "81-2106, 81-2112, or 81-2144".
const STATE_SECTION_RUN := "\\b\\d{2}-\\d{4}(?:\\(\\w+\\))*(?:(?:,? (?:and|or) |, )\\d{2}-\\d{4}(?:\\(\\w+\\))*)*"

static func _state_citations(text: String) -> String:
	text = _each(text, "Neb\\. Rev\\. Stat\\.\\s*(?:§\\s*)?(" + STATE_SECTION_RUN + ")", func(m: RegExMatch, _src: String) -> String:
		return "Nebraska Revised Statute " + _state_section_run(m.get_string(1)))
	text = _each(text, "(?i)\\b(sections?)\\s+(" + STATE_SECTION_RUN + ")", func(m: RegExMatch, _src: String) -> String:
		return m.get_string(1) + " " + _state_section_run(m.get_string(2)))
	text = _re("\\bTitle (\\d+) NAC\\b,?").sub(text, "Title $1 of the Nebraska Administrative Code,", true)
	return _re("\\bNAC\\b").sub(text, "Nebraska Administrative Code", true)


## "81-2108(2) and 81-2113(2)" -> "eighty-one twenty-one oh-eight, subsection 2
## and section eighty-one twenty-one thirteen, subsection 2".
static func _state_section_run(run: String) -> String:
	return _each(run, STATE_SECTION, func(m: RegExMatch, _src: String) -> String:
		var digits := m.get_string(2)
		var words := "%s %s" % [_pair_words(m.get_string(1), true), _pair_words(digits.substr(0, 2), true)]
		words += " hundred" if digits.substr(2) == "00" else " " + _pair_words(digits.substr(2), false)
		for part in _re("\\((\\w+)\\)").search_all(m.get_string(3)):
			var p := part.get_string(1)
			words += (", subsection " if p.is_valid_int() else ", subdivision ") + p
		return words if m.get_start() == 0 else "section " + words)


## Two digits as said in a statute number: "81" eighty-one, "13" thirteen,
## "08" oh-eight ("oh" only inside a number, not leading it).
static func _pair_words(pair: String, leading: bool) -> String:
	var ones := ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
		"ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen",
		"eighteen", "nineteen"]
	var tens := ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]
	var n := int(pair)
	if pair.begins_with("0"):
		return str(ones[n]) if leading else "oh-" + str(ones[n])
	if n < 20:
		return str(ones[n])
	return str(tens[n / 10]) + ("" if n % 10 == 0 else "-" + str(ones[n % 10]))


## Drops every tab-separated line. The line just before a run of dropped ones
## is that table's title when it starts with "Table"; it becomes the pointer to
## the on-screen grid, for every table of a multi-table provision. A first
## table without such a title gets the pointer appended where it was.
static func _table_block(text: String) -> String:
	if not text.contains("\t"):
		return text
	var kept: PackedStringArray = []
	var pointed := false
	var in_table := false
	for line in text.split("\n"):
		if not line.contains("\t"):
			kept.append(line)
			in_table = false
			continue
		if in_table:
			continue
		in_table = true
		var title := kept[kept.size() - 1].strip_edges() if not kept.is_empty() else ""
		var ref := _re("^Table\\s+\\S+").search(title)
		if ref != null:
			kept[kept.size() - 1] = "%s is shown on screen." % ref.get_string(0)
		elif not pointed:
			kept.append(TABLE_ON_SCREEN)
		pointed = true
	return "\n".join(kept)


static func _spell(token: String) -> String:
	var letters: PackedStringArray = []
	for i in token.length():
		letters.append(token.substr(i, 1))
	return " ".join(letters)


## A caps token that is not a known acronym is either an unknown acronym or a
## shouted word ("CABLES SHALL BE LOW VOLTAGE"). Two or more vowel-bearing
## unknowns of 3+ letters in one line means shouting: read the line in lower
## case, which Edge voices as normal words instead of guessing at each token.
static func _unshout(text: String) -> String:
	var shouted := 0
	for m in _re("\\b[A-Z]{3,}\\b").search_all(text):
		var token := m.get_string(0)
		if not SAY_AS.has(token) and _re("[AEIOUY]").search(token) != null:
			shouted += 1
	if shouted < 2:
		return text
	return _each(text, "\\b[A-Z]{2,}\\b", func(m: RegExMatch, _src: String) -> String:
		return m.get_string(0) if SAY_AS.has(m.get_string(0)) else m.get_string(0).to_lower())


const REFERENCE_RE := "(?:\\b(Sections?|sections?|Tables?|tables?|Articles?|articles?)\\s+|(§)\\s*)?\\b(\\d{2,3})\\.(\\d{1,3})\\b((?:\\((?:[A-Za-z]|\\d{1,2})\\))*)"


## A word that cites a bare section in running text: "as covered by 240.21",
## "Under NEC 626.11", "conforming to 551.81".
const CITE_CUE_RE := "(?i)(?:\\b(?:under|in|by|per|see|with|of|NEC|Code)|\\b(?:conforming|refer|according|pursuant|subject|comply|complying|complies)\\s+to)\\s+$"
## Arithmetic around a number makes it a quantity: "÷ 831.36" (already "divided
## by" here), "multiply 240.21 by 2", "= 310.16", "240.21 × 2".
const ARITH_BEFORE_RE := "(?i)(?:[=÷×*/+−]|\\b(?:divided|multiplied)\\s+by|\\b(?:multiply|divide|times|equals|plus|minus|over|is|are|gives?|to get|about|approximately)|\\d\\s*[xX])\\s*$"
const ARITH_AFTER_RE := "(?i)^\\s*(?:[=÷×*/+−]|[xX]\\s*\\d|(?:times|divided|multiplied|plus|minus|equals)\\b|by\\s+[\\d.])"
## Written where only a citation fits: "(430.22)", "the 250.62 wording",
## "(F) and 310.12", "= 5,000 W 220.54." after a formula, "430.24 gives".
const CITE_PAREN_BEFORE_RE := "\\(\\s*$"
const CITE_PAREN_AFTER_RE := "^\\s*[),]"
const CITE_ARTICLE_BEFORE_RE := "(?i)\\b(?:the|a|an)\\s+$"
const CITE_ARTICLE_AFTER_RE := "^ [a-z]"
const CITE_AFTER_PAREN_LIST_RE := "\\)\\s*(?:,\\s*)?(?:and|or)\\s+$"
const CITE_AFTER_UNIT_BEFORE_RE := "(?:[)%]|\\b(?:[A-Z]{1,4}|amps|volts|watts|loads?))\\s+$"
const CITE_AFTER_UNIT_AFTER_RE := "^(?:[.,;]|\\s+(?:load|dwelling)\\b|\\s*$)"
const CITE_VERB_AFTER_RE := "^ (?:requires|says|allows|covers|applies|uses|permits|prohibits|limits|gives|sets|exempts|excuses|treats|rates|addresses|restricts)\\b"
## A unit after the number makes it a measurement: "of 888.8 ohms".
const UNIT_AFTER_RE := "^\\s*(?:%|°|\"|'|(?:percent|amps?|amperes?|A|mA|kA|V|volts?|kV|VA|kVA|W|watts?|kW|ohms?|Ω|m|mm|meters?|millimeters?|ft|feet|foot|in|inch(?:es)?|s|seconds?|Hz|hertz|lbs?|pounds?|kcmil|degrees?|sq|cu)\\b)"
## Joins the members of a reference list: "352.100, 352.12(B), and 352.60".
const LIST_GAP_RE := "^(?:,\\s*|,?\\s+(?:and|or|through)\\s+)$"


## "210.8(A)(1)" -> "section 210 point 8, paragraph A, item 1".
## "Table 310.15(B)(1)" -> "Table 310 point 15, B, 1".
## A decimal is only treated as a reference when something says it is one: a
## Section/Table/Article word, a (designator), a citing word ("under 250.122"),
## a "352.100 Construction" heading (at a line start or after a "label: "), a
## "680.58:" label, or membership of a list
## that holds one ("332.104, 332.108, and 332.116:"). Without a designator the
## number must also look like an NEC section (NNN.N, no unit after it), so
## "31.6", "8.19 amps" and "in 1.5 seconds" stay numbers.
static func _references(text: String) -> String:
	var matches := _re(REFERENCE_RE).search_all(text)
	var prefixes: Array[String] = []
	for i in matches.size():
		var prefix := _reference_prefix(matches[i], text)
		# "Table 430.248 (1φ) or 430.250 (3φ)": the second is a table too.
		if prefix == "section" and i > 0 and prefixes[i - 1].to_lower().begins_with("table") \
				and matches[i].get_string(1) == "" and matches[i].get_string(2) == "" \
				and _re("^(?:\\s*\\([^()]{1,6}\\))?\\s*(?:,\\s*)?(?:and|or)\\s+$").search(
					text.substr(matches[i - 1].get_end(), matches[i].get_start() - matches[i - 1].get_end())) != null:
			prefix = "Table"
		prefixes.append(prefix)
	# A list is spoken as references when any member is one.
	var run_start := 0
	for i in matches.size() + 1:
		var joined := i > 0 and i < matches.size() and _list_member(matches[i], text) \
			and _re(LIST_GAP_RE).search(text.substr(matches[i - 1].get_end(), matches[i].get_start() - matches[i - 1].get_end())) != null
		if joined:
			continue
		var lead := ""
		for j in range(run_start, i):
			if prefixes[j] != "":
				lead = "Table" if prefixes[j].to_lower().begins_with("table") else "section"
				break
		if lead != "":
			for j in range(run_start, i):
				if prefixes[j] == "" and _list_member(matches[j], text):
					prefixes[j] = lead
		run_start = i
	var out := ""
	var from := 0
	for i in matches.size():
		var m := matches[i]
		out += text.substr(from, m.get_start() - from)
		if prefixes[i] == "":
			out += m.get_string(0)
		else:
			out += _speak_reference(prefixes[i], m.get_string(3), m.get_string(4), m.get_string(5))
		from = m.get_end()
	return out + text.substr(from)


static func _reference_prefix(m: RegExMatch, src: String) -> String:
	var prefix := m.get_string(1)
	if m.get_string(2) == "§":
		return "section"
	if prefix != "" or m.get_string(5) != "":
		return prefix if prefix != "" else "section"
	var at_line_start := m.get_start() == 0 or src.substr(m.get_start() - 1, 1) == "\n"
	var after := src.substr(m.get_end(), 11)
	if at_line_start and (after.begins_with(":") or after.begins_with(" Exception")):
		return "section"
	if not _looks_like_section(m, src):
		return ""
	var before := _before(m, src)
	var heading_start := at_line_start or before.ends_with(": ")
	var heading := heading_start and _re("^ [A-Za-z]").search(after) != null
	if after.begins_with(":") or heading or _re(CITE_CUE_RE).search(before) != null \
			or _re(CITE_VERB_AFTER_RE).search(after) != null \
			or _re(CITE_AFTER_PAREN_LIST_RE).search(before) != null \
			or (_re(CITE_PAREN_BEFORE_RE).search(before) != null and _re(CITE_PAREN_AFTER_RE).search(after) != null) \
			or (_re(CITE_ARTICLE_BEFORE_RE).search(before) != null and _re(CITE_ARTICLE_AFTER_RE).search(after) != null) \
			or (_re(CITE_AFTER_UNIT_BEFORE_RE).search(before) != null and _re(CITE_AFTER_UNIT_AFTER_RE).search(after) != null):
		return "section"
	return ""


static func _before(m: RegExMatch, src: String) -> String:
	var from := maxi(0, m.get_start() - 24)
	return src.substr(from, m.get_start() - from)


## A bare NNN.N that could be an NEC section: its article exists in NEC 2023
## (so "831.36" and "31.6" never are), no leading-zero part ("240.05"), no
## unit after it, and no arithmetic around it.
static func _looks_like_section(m: RegExMatch, src: String) -> bool:
	if m.get_string(1) != "" or m.get_string(2) != "":
		return false
	var part := m.get_string(4)
	if part.length() > 1 and part.begins_with("0"):
		return false
	if NecReference.canonical_article_title(int(m.get_string(3))) == "":
		return false
	var after := src.substr(m.get_end(), 16)
	return _re(UNIT_AFTER_RE).search(after) == null \
		and _re(ARITH_AFTER_RE).search(after) == null \
		and _re(ARITH_BEFORE_RE).search(_before(m, src)) == null


## A later list member carries no Section/Table word of its own.
static func _list_member(m: RegExMatch, src: String) -> bool:
	return m.get_string(1) == "" and m.get_string(2) == "" \
		and (m.get_string(5) != "" or _looks_like_section(m, src))


static func _speak_reference(prefix: String, whole: String, part: String, desig: String) -> String:
	var spoken := "%s point %s" % [whole, part]
	if prefix != "":
		spoken = prefix + " " + spoken
	var levels := ["paragraph", "item", "sub-item", "sub-item"]
	var is_table := prefix.to_lower().begins_with("table")
	var i := 0
	for d in _re("\\(([A-Za-z]|\\d{1,2})\\)").search_all(desig):
		var mark := d.get_string(1).to_upper()
		spoken += (", " + mark) if is_table else (", %s %s" % [levels[mini(i, 3)], mark])
		i += 1
	return spoken


## Operators are only words inside a formula (a line with "="): elsewhere a
## spaced hyphen is a prose dash and "/" is "or".
static func _formula_operators(text: String) -> String:
	if not text.contains("="):
		return text
	text = _re("\\s*=\\s*").sub(text, " equals ", true)
	text = _re("(?<=[\\w)])\\s+-\\s+(?=[\\w(])").sub(text, " minus ", true)
	text = _re("(\\d)-(\\d)").sub(text, "$1 minus $2", true)
	text = _re("\\s*\\+\\s*").sub(text, " plus ", true)
	text = _re("\\s+/\\s+").sub(text, " divided by ", true)
	text = _re("\\s*\\*\\s*").sub(text, " times ", true)
	text = _re("\\^2\\b").sub(text, " squared", true)
	return text


static func _tidy(text: String) -> String:
	text = _re("\\s+([,.;:?!])(?!\\d)").sub(text, "$1", true)
	text = _re("\\.(?:\\s*\\.)+").sub(text, ".", true)
	text = _re("([,;:])(?:\\s*[,;:])+").sub(text, "$1", true)
	text = _re("[,;:]\\s*\\.").sub(text, ".", true)
	text = _re("\\.\\s*,").sub(text, ".", true)
	text = _re("\\bblank\\s+-").sub(text, "blank-", true)
	text = _re("\\(\\s+").sub(text, "(", true)
	text = _re("\\s+\\)").sub(text, ")", true)
	text = _re("\\(\\s*\\)").sub(text, "", true)
	text = _re("\\s{2,}").sub(text, " ", true)
	text = _re("^[\\s.,;:]+").sub(text.strip_edges(), "", false)
	if text.length() > 0 and text.substr(0, 1) != text.substr(0, 1).to_upper():
		text = text.substr(0, 1).to_upper() + text.substr(1)
	return text.strip_edges()
