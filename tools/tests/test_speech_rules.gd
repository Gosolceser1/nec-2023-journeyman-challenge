extends SceneTree
## speech_rules.gd -- the voice normaliser, rule by rule, plus the reading
## order contract from docs/VOICE_READING_RULES.md.
##
##   ./Godot_v4.7.2-stable_win64_console.exe --headless --path . \
##       --script tools/tests/test_speech_rules.gd

const Rules = preload("res://src/speech/speech_rules.gd")
const ST = preload("res://src/speech/speech_text.gd")
const AEG = preload("res://src/speech/audio_explanation_generator.gd")
const R = preload("res://tools/tests/t_report.gd")

var t: R = R.new()

## [rule id, written input, spoken output after the FULL pipeline]. Every id in
## Rules.PIPELINE must appear at least once (checked in rule_coverage()).
const GOLDEN := [
	["panel_tag", "Busbar. A bare conductor. (393) (CMP—18)", "Busbar. A bare conductor. (393)"],
	["panel_tag", "Labeled. Equipment with a label. (CMP-1)", "Labeled. Equipment with a label."],
	["extract_tag", "an ignitible layer fire hazard. [499:3.3.4.2] (CMP-14)", "An ignitible layer fire hazard."],
	["table_pipes", "Circuit Rating | Maximum Load. 15 or 20 | 12", "Circuit Rating, Maximum Load. 15 or 20, 12"],
	["footnote_star", "Table 348.22 (FMC)*. *In addition, one bare wire.", "Table 348 point 22 (F M C). In addition, one bare wire."],
	["footnote_star", "V drop = (10 V / 125 V) * 100", "V drop equals (10 volts divided by 125 volts) times 100"],
	["unit_microamps", "trips at 5 µA", "Trips at 5 microamps"],
	["table_block", "Table 408.5 Clearance\nConductor\tMinimum\nInsulated\t200\t8", "Table 408 point 5 is shown on screen."],
	["table_block", "Rule text.\nA\tB\n1\t2", "Rule text. The table is shown on screen."],
	["table_block", "Table 310.16 Ampacities\nAWG\t60\n12\t20\nCopper\n10\t30\nTable 310.15(C)(1) Adjustment Factors\n4—6\t80",
		"Table 310 point 16 is shown on screen. Copper. Table 310 point 15, C, 1 is shown on screen."],
	["typography", "the “front” and 5′", "The front and 5 feet"],
	["typography", "shall be…", "Shall be."],
	["typography", "the feeder [based on the rating], plus", "The feeder (based on the rating), plus"],
	["state_citations", "Neb. Rev. Stat. 81-2108", "Nebraska Revised Statute eighty-one twenty-one oh-eight"],
	["state_citations", "Neb. Rev. Stat. 81-2108(2) and 81-2113(2): text", "Nebraska Revised Statute eighty-one twenty-one oh-eight, subsection 2 and section eighty-one twenty-one thirteen, subsection 2: text"],
	["state_citations", "as provided in section 81-2106, 81-2112, or 81-2144", "As provided in section eighty-one twenty-one oh-six, section eighty-one twenty-one twelve, or section eighty-one twenty-one forty-four"],
	["state_citations", "Title 100 NAC Rule 13: notify", "Title 100 of the Nebraska Administrative Code, Rule 13: notify"],
	["state_citations", "rated 100-400 A", "Rated 100 to 400 amps"],
	["abbreviations", "e.g. a box, i.e. metal", "For example a box, that is metal"],
	["abbreviations", "min. depth, max. load, approx. 5", "Minimum depth, maximum load, approximately 5"],
	["abbreviations", "708.54 Ex.: text", "Section 708 point 54 Exception: text"],
	["leading_decimal_point", ".6875", "0.6875"],
	["leading_decimal_point", "Answer: .6875 or 2.5 A.", "Answer: 0.6875 or 2.5 amps."],
	["plural_suffix", "the door(s) and connector(s)", "The doors and connectors"],
	["mixed_number_unspaced", "11/2\"", "1 and one half inches"],
	["mixed_number_unspaced", "41/2", "4 and one half"],
	["mixed_number_unspaced", "15/16\"", "Fifteen sixteenths of an inch"],
	["mixed_number_hyphen", "1-1/4 in.", "1 and one quarter inches"],
	["inch_mark_mixed", "3 5/16\"", "3 and five sixteenths inches"],
	["inch_mark_fraction", "3/8\"", "Three eighths of an inch"],
	["inch_mark_one", "1\"", "1 inch"],
	["inch_mark", "12\" and 1.5\"", "12 inches and 1.5 inches"],
	["quote_strip", "marked \"Caution\"", "Marked Caution"],
	["foot_mark", "8' high", "8 feet high"],
	["foot_mark", "the Code's rule", "The Code's rule"],
	["foot_inch_seam", "5'9\"", "5 feet 9 inches"],
	["typo_srating", "srating the rule", "Stating the rule"],
	["blank_named", "see Article ___", "See which Article"],
	["blank_run", "a____at the wall", "A blank at the wall"],
	["blank_run", "a 4-wire, ___-connected system", "A 4-wire, blank-connected system"],
	["subscript", "V_load", "V load"],
	["trailing_junk", "the end . x", "The end."],
	["roman_list_marker", "include ___. I. one EGC II. one neutral III. three hots", "Include blank. Item 1, one equipment grounding conductor. Item 2, one neutral. Item 3, three hots"],
	["roman_choice_before", "I and II only", "1 and 2 only"],
	["roman_choice_before", "I, II and III", "1, 2 and 3"],
	["roman_choice_after", "II or I", "2 or 1"],
	["roman_choice_only", "I only", "1 only"],
	["area_units", "4 mm² and 2 in²", "4 square millimeters and 2 square inches"],
	["symbols", "a — b", "A, b"],
	["symbols", "14 kW − 12 kW", "14 kilowatts minus 12 kilowatts"],
	["symbols", "V ≤ 50, I ≥ 5, ± 5%", "V less than or equal to 50, I greater than or equal to 5, plus or minus 5 percent"],
	["symbols", "√3 ≈ 1.73", "Square root of 3 is about 1.73"],
	["symbols", "600 × 1.25 ÷ 2", "600 times 1.25 divided by 2"],
	["symbols", "10 Ω, 5¢, 3 µF", "10 ohms, 5 cents, 3 microF"],
	["symbols", "blank @ 250 volts", "Blank at 250 volts"],
	["symbols", "I² and 2³", "I squared and 2 cubed"],
	["degrees_c", "rated 90°C", "Rated 90 degrees Celsius"],
	["degrees_f", "112°F ambient", "112 degrees Fahrenheit ambient"],
	["degree_sign", "a 90° bend", "A 90 degrees bend"],
	["vulgar_fractions", "3½ turns and ¼", "3 and one half turns and one quarter"],
	["slash_words", "a/an CU/AL and/or CO/ALR lockout/tagout", "A or an copper or aluminum and or C O A L R lockout tagout"],
	["wye_voltage", "208Y/120 volt", "208 wye 120 volt"],
	["wye_voltage", "480Y/277V", "480 wye 277 volts"],
	["slash_voltage", "120/240-volt and 240/120 V", "120 slash 240-volt and 240 slash 120 volts"],
	["kcmil", "250 kcmil", "250 thousand circular mil"],
	["expand_acronyms", "the OCPD and EGC", "The overcurrent protective device and equipment grounding conductor"],
	["expand_acronyms", "OCPDs are replaced", "Overcurrent protective devices are replaced"],
	["expand_acronyms", "a 5 HP motor per the AHJ", "A 5 horsepower motor per the authority having jurisdiction"],
	["compound_slash", "under/over", "Under or over"],
	["compound_slash", "I = P/E", "I equals P divided by E"],
	["number_abbrev", "No. 12 wire", "Number 12 wire"],
	["references", "210.8(A)(1) requires", "Section 210 point 8, paragraph A, item 1 requires"],
	["references", "per Section 250.52(A)(2)", "Per Section 250 point 52, paragraph A, item 2"],
	["references", "Table 310.15(B)(1)(1)", "Table 310 point 15, B, 1, 1"],
	["references", "Table 310.16", "Table 310 point 16"],
	["references", "680.58: All outlets", "Section 680 point 58: All outlets"],
	["references", "§ 90.2 scope", "Section 90 point 2 scope"],
	["references", "Article 250 and Chapter 9", "Article 250 and Chapter 9"],
	["references", "31.6 amps", "31.6 amps"],
	["references", "422.16(B)(1)(a)", "Section 422 point 16, paragraph B, item 1, sub-item A"],
	["references", "sized under 250.122 based on", "Sized under section 250 point 122 based on"],
	["references", "as covered by 240.21.", "As covered by section 240 point 21."],
	["references", "352.100, 352.12(B), and 352.60: text", "Section 352 point 100, section 352 point 12, paragraph B, and section 352 point 60: text"],
	["references", "332.104, 332.108, and 332.116: 332.104 Conductors", "Section 332 point 104, section 332 point 108, and section 332 point 116: section 332 point 104 Conductors"],
	["references", "rules\n352.100 Construction", "Rules. section 352 point 100 Construction"],
	["references", "Tables 310.15(B)(1) and 310.16", "Tables 310 point 15, B, 1 and Table 310 point 16"],
	["references", "21 x 0.39 = 8.19 A", "21 times 0.39 equals 8.19 amps"],
	["references", "a value of 888.8 ohms", "A value of 888.8 ohms"],
	["references", "within 1.5 seconds, a 1.5% drop", "Within 1.5 seconds, a 1.5 percent drop"],
	["references", "in 120.5 V and 42.4, 34.8", "In 120.5 volts and 42.4, 34.8"],
	# Arithmetic makes a decimal a quantity, even after "by" or with a real article.
	["references", "199,526 VA ÷ 831.36 = 240 A", "199,526 volt amperes divided by 831.36 equals 240 amps"],
	["references", "divided by 240.21", "Divided by 240.21"],
	["references", "Multiply 240.21 by 2.", "Multiply 240.21 by 2."],
	["references", "240.21 × 2 = 480.42", "240.21 times 2 equals 480.42"],
	["references", "The result equals 310.16", "The result equals 310.16"],
	["references", "Result is 250.66, round up.", "Result is 250.66, round up."],
	["references", "Multiply 50 A times 1.25, then by 0.8", "Multiply 50 amps times 1.25, then by 0.8"],
	# Not an NEC 2023 article, or a leading-zero part: never a section.
	["references", "covered by 831.36", "Covered by 831.36"],
	["references", "covered by 240.05", "Covered by 240.05"],
	# Citations written without a Section word.
	["references", "FLC × 125% (430.22).", "F L C times 125 percent (section 430 point 22)."],
	["references", "× the 220.41 dwelling unit load", "Times the section 220 point 41 dwelling unit load"],
	["references", "= 5,000 W 220.54.", "Equals 5,000 watts section 220 point 54."],
	["references", "other FLC 430.24, using", "Other F L C section 430 point 24, using"],
	["references", "310.15(A) through (F) and 310.12.", "Section 310 point 15, paragraph A through (F) and section 310 point 12."],
	["references", "conforming to 551.81.", "Conforming to section 551 point 81."],
	["references", "Under NEC 626.11, services", "Under N E C section 626 point 11, services"],
	["references", "430.24 gives 22.5 amperes.", "Section 430 point 24 gives 22.5 amperes."],
	["references", "Table 430.248 (1φ) or 430.250 (3φ)", "Table 430 point 248 (1φ) or Table 430 point 250 (3φ)"],
	["area_units", "3 VA per ft², 12 in² and 4 mm²", "3 volt amperes per square foot, 12 square inches and 4 square millimeters"],
	["power_of_ten", "about 6.24 x 10^18 electrons", "About 6.24 times 10 to the power of 18 electrons"],
	["ratio_colon", "a transformer ratio of 20:1", "A transformer ratio of 20 to 1"],
	["suffix_dash", "What does the -2 represent?", "What does the dash 2 represent?"],
	["unit_amps_glued", "17.5a", "17.5 amps"],
	["unit_amps_glued", "Answer: 400a.", "Answer: 400 amps."],
	["designator_pair", "item 1 through (B)(5)", "Item 1 through paragraph B, item 5"],
	["wire_aught", "1/0 and 4/0", "One aught and four aught"],
	["cable_designation", "12/3 and 10/2 NM", "12 slash 3 and 10 slash 2 N M"],
	["mixed_number", "3 1/2", "3 and one half"],
	["fraction", "1/3 of 3/5", "One third of three fifths"],
	["fraction", "1/60", "1 over 60"],
	["fraction_inch_singular", "23.8 mm (15/16 in.)", "23.8 millimeters (fifteen sixteenths of an inch)"],
	["unit_sq_ft", "3 VA per sq. ft. of area", "3 volt amperes per square feet of area"],
	["unit_sq_in", "0.0133 sq in", "0.0133 square inches"],
	["unit_cu_in", "18 cu. in. box", "18 cubic inches box"],
	["unit_cu_in", "Answer: 18 cu.in.", "Answer: 18 cubic inches"],
	["unit_ft_adjective", "three 5-ft sections", "Three 5-foot sections"],
	["unit_ft_dot", "within 6 ft. of", "Within 6 feet of"],
	["unit_ft", "2.0 m (6 and one half ft) above", "2.0 meters (6 and one half feet) above"],
	["unit_ft", "12 ft, so", "12 feet, so"],
	["unit_in_dot", "12 in. deep", "12 inches deep"],
	["unit_in", "3 1/2 in divided by 1/4 in per foot", "3 and one half inches divided by quarter inch per foot"],
	["unit_in", "3 in a raceway", "3 in a raceway"],
	["unit_lb_in", "7 lb-in.", "7 pound-inches"],
	["unit_lb_in", "___ lbs-inch", "Blank pound-inches"],
	["unit_lb_ft", "20 lb-ft", "20 pound-feet"],
	["unit_lb", "50 lbs load", "50 pounds load"],
	["unit_mm", "23.8 mm deep", "23.8 millimeters deep"],
	["unit_m", "6 m (20 ft)", "6 meters (20 feet)"],
	["unit_m", "1 m apart", "1 meter apart"],
	["unit_s", "= 0.01667 s.", "Equals 0.01667 seconds."],
	["unit_kva", "10kVA", "10 kilovolt amperes"],
	["unit_kw", "1.5kW", "1.5 kilowatts"],
	["unit_va", "180VA", "180 volt amperes"],
	["unit_vdc", "48 VDC", "48 volts D C"],
	["unit_vac", "24 VAC", "24 volts A C"],
	["unit_kv", "15 kV", "15 kilovolts"],
	["unit_ka", "10 kA", "10 kiloamps"],
	["unit_volts", "240V", "240 volts"],
	["unit_ma", "5 mA", "5 milliamps"],
	["unit_amps", "20 A at 240 V", "20 amps at 240 volts"],
	["unit_watts", "100 W each", "100 watts each"],
	["unit_hz", "60 Hz", "60 hertz"],
	["percent", "125% of load", "125 percent of load"],
	["percent", "at least ___ % of sites", "At least blank percent of sites"],
	["singular_one", "1 A and 0.1 A and 11 A", "1 amp and 0.1 amps and 11 amps"],
	["singular_one", "1 ft", "1 foot"],
	["type_suffix", "NM-B and SE-R", "N M B and S E R"],
	["type_suffix_digit", "THWN-2 and XHHW-2 and SPT-2", "T H W N, dash 2 and X H H W, dash 2 and S P T, dash 2"],
	["wire_type_pause", "copper THHN wire and THWN conductors, or THHN.", "Copper T H H N, wire and T H W N, conductors, or T H H N."],
	["wire_type_pause", "XHHW insulation", "X H H W insulation"],
	["unit_attributive", "a 200 A service and 20 A breakers, 120/240 V single-phase", "A 200 amp service and 20 amp breakers, 120 slash 240 volt single-phase"],
	["unit_attributive", "the load is 30 A total", "The load is 30 amps total"],
	["fraction_inch_hyphen", "a 3/8-inch FMC", "A three eighths of an inch F M C"],
	["fraction_of_an_inch", "1/16\", 3/32 in. and 1 5/8 in.", "One sixteenth of an inch, three thirty-seconds of an inch and 1 and five eighths inches"],
	["half_quarter_inch", "a 1/2-inch EMT raceway and 1/4 in. plate", "A half inch E M T raceway and quarter inch plate"],
	["half_quarter_inch", "1 1/2 in. and 2 1/4 in.", "1 and one half inches and 2 and one quarter inches"],
	["three_quarter_inch", "3/4\" knockouts and 3/4 in. deep", "Three quarter inch knockouts and three quarter inch deep"],
	["three_quarter_inch", "1 3/4 in.", "1 and three quarters inches"],
	["roman_numerals", "Class III and VIII", "Class 3 and 8"],
	["class_one", "Class I, Division 1", "Class 1, Division 1"],
	["spell_acronyms", "STOOW cord, MI cable, HARC", "S T O O W cord, M I cable, H A R C"],
	["spell_acronyms", "GFCI, AFCI, AWG, EMT, PVC, NEC, UL", "G F C I, A F C I, A W G, E M T, P V C, N E C, U L"],
	["spell_acronyms", "two ACs", "Two A C's"],
	["spell_acronyms", "an IBEW apprentice", "An I B E W apprentice"],
	["spell_acronyms", "IEEE and NEMA and OSHA", "I triple E and NEMA and OSHA"],
	["unshout", "CABLES SHALL BE LOW VOLTAGE", "Cables shall be low voltage"],
	["unshout", "Switch in the ON position, NOT off", "Switch in the ON position, NOT off"],
	["spell_unknown_caps", "a QRZ device", "A Q R Z device"],
	["hash", "#10 and # 12", "Number 10 and number 12"],
	["formula_operators", "VD = V source - V load", "V D equals V source minus V load"],
	["formula_operators", "a = 125-115 + 2 * 3", "A equals 125 minus 115 plus 2 times 3"],
	["formula_operators", "Grounding - general rules", "Grounding - general rules"],
	["times_digits", "2x30A", "2 times 30 amps"],
	["times_spaced", "W = E x I", "W equals E times I"],
	["number_range", "100-400 A", "100 to 400 amps"],
	["comparison", "if I < 5 and V > 3", "If I less than 5 and V greater than 3"],
	["line_breaks", "Rule one\nException: two", "Rule one. Exception: two"],
	["tidy", "a  ,  b ..  c ( d )", "A, b. c (d)"],
	["tidy", "... leading", "Leading"],
]


func _init() -> void:
	if not t.run_suite_body():
		return
	run()
	quit(0 if t.failures.is_empty() else 1)


func run() -> void:
	golden_cases()
	rule_coverage()
	idempotent_and_safe()
	reading_order()
	lost_blank_and_references()
	rules_version_stamp()
	no_answer_before_answering()
	bank_sweep()
	t.report()


func golden_cases() -> void:
	print("=== golden cases (full pipeline) ===")
	for row in GOLDEN:
		t.eq(Rules.normalize(str(row[1])), str(row[2]), "[%s] %s" % [row[0], row[1]])


func rule_coverage() -> void:
	print("=== every rule has a golden case ===")
	var covered := {}
	for row in GOLDEN:
		covered[str(row[0])] = true
	for id in Rules.rule_ids():
		t.check(covered.has(id), "rule '%s' has no golden case in GOLDEN" % id)
	for id in covered:
		t.check(id in Rules.rule_ids(), "golden case names unknown rule '%s'" % id)
	# Each rule must actually CHANGE its first golden input by the time it has
	# run (proves the case exercises that rule, not a neighbour). Rules pinned
	# as "must not touch this" are listed so they are exempt.
	var guards := ["Article 250 and Chapter 9", "31.6 amps", "3 in a raceway", "the Code's rule",
		"Switch in the ON position, NOT off", "Grounding - general rules", "1/60", "15/16\""]
	var checked := {}
	for row in GOLDEN:
		var id := str(row[0])
		if checked.has(id) or str(row[1]) in guards:
			continue
		checked[id] = true
		var before := _through_previous(str(row[1]), id)
		var after := Rules.normalize_through(str(row[1]), id)
		t.check(before != after, "rule '%s' changes nothing in its golden input '%s'" % [id, row[1]])


func _through_previous(text: String, id: String) -> String:
	var ids := Rules.rule_ids()
	var at := ids.find(id)
	if at <= 0:
		return text.strip_edges()
	return Rules.normalize_through(text, ids[at - 1])


func idempotent_and_safe() -> void:
	print("=== edge cases ===")
	t.eq(Rules.normalize(""), "", "empty stays empty")
	t.eq(Rules.normalize("   "), "", "whitespace stays empty")
	for row in GOLDEN:
		var once := Rules.normalize(str(row[1]))
		t.eq(Rules.normalize(once), once, "normalising twice changes nothing: '%s'" % row[1])
	t.eq(Rules.spoken_fraction("2", "5"), "two fifths", "fifths")
	t.eq(Rules.spoken_fraction("1", "10"), "one tenth", "tenths")
	t.eq(Rules.spoken_fraction("7", "9"), "7 over 9", "unlisted denominator falls back to 'over'")


func reading_order() -> void:
	print("=== reading order: stem, then Option A..D ===")
	var rec := {
		"prompt": "The conductor is marked RHW-2 on the insulation, what does the -2 represent",
		"answers": ["The cable has two conductors.", "Double insulated", "20 A", "I only"],
		"correct_index": 1, "reference_text": "310.4\nRHW-2 is rated 90°C.",
	}
	var segs: Array = ST.spoken_segments(rec)
	t.eq(segs.size(), 9, "stem + 4 choices, each a letter line then its text")
	t.eq(str(segs[0]["text"]), "The conductor is marked R H W, dash 2 on the insulation, what does the dash 2 represent.",
		"stem first, terminated once")
	t.eq(str(segs[2]["text"]), "The cable has two conductors.", "a choice already ending in '.' is not doubled")
	t.eq(str(segs[4]["text"]), "Double insulated.", "choice B")
	t.eq(str(segs[6]["text"]), "20 amps.", "choice C with a unit")
	t.eq(str(segs[8]["text"]), "1 only.", "a Roman choice is read as a number")
	for i in 4:
		t.eq(str(segs[1 + 2 * i]["text"]), "Option %s." % ["A", "B", "C", "D"][i],
			"choice %d is lettered 'Option X' in its own clip (a bare 'A' is voiced as the article 'uh')" % i)
	t.eq(ST._terminated("Which one:"), "Which one.", "a trailing colon becomes one period")
	t.eq(ST._terminated("Why?"), "Why?", "a question mark is kept")
	t.eq(ST._terminated("only for work.;"), "only for work.", "stray punctuation after a period is dropped, not doubled")


func lost_blank_and_references() -> void:
	print("=== stem blank restore + reference choices ===")
	var lost := ST.spoken_segments({"prompt": "The total number of AC cycles in one second is the current's .", "answers": ["frequency"], "correct_index": 0})
	t.eq(str(lost[0]["text"]), "The total number of A C cycles in one second is the current's blank.", "a lost blank is spoken")
	var kept := ST.spoken_segments({"prompt": "The value is ___.", "answers": ["x"], "correct_index": 0})
	t.eq(str(kept[0]["text"]), "The value is blank.", "a real blank is spoken once")
	var ref := ST.spoken_segments({"prompt": "Which section covers AFCI protection?", "answers": ["210.12", "210.8(A)", "31.6", "Article 406"], "correct_index": 0})
	t.eq(str(ref[2]["text"]), "210 point 12.", "a bare section-number choice reads 'point 12', not 'point one two'")
	t.eq(str(ref[4]["text"]), "210 point 8, paragraph A.", "with its designator")
	var numeric := ST.spoken_segments({"prompt": "The ampacity is ___ amps.", "answers": ["31.6"], "correct_index": 0})
	t.eq(str(numeric[2]["text"]), "31.6.", "a decimal answer to a non-reference question stays a number")
	var cited := ST.spoken_segments({"prompt": "Supply conductors are feeders or ___ as covered by 240.21.", "answers": ["taps", "0.5"], "correct_index": 0})
	t.eq(str(cited[0]["text"]), "Supply conductors are feeders or blank as covered by section 240 point 21.", "a section cited in the stem is read as a section")
	t.eq(str(cited[3]["text"]), "Option B.", "choice B's letter is its own clip")
	t.eq(str(cited[4]["text"]), "0.5.", "a decimal choice stays a number")
	var rule := ST.teach_segments({"prompt": "Conductors shall have an ampacity ___ the rating.", "answers": ["of not less than", "equal to"],
		"correct_index": 0, "article": "210.19(B)",
		"reference_text": "210.19(B) Branch Circuits\nConductors shall have an ampacity of not less than the rating of the branch circuit."})
	var rule_text := ""
	for seg in rule:
		rule_text += str(seg["text"]) + "\n"
	t.check(rule_text.contains("must have a current rating of at least"), "the article before 'current rating' stays lower case: " + rule_text)
	t.check(not rule_text.contains(" A current"), "no mid-sentence capital 'A' for the article 'a'")


func rules_version_stamp() -> void:
	print("=== rules version travels with every segment ===")
	var rec := {"prompt": "P ___", "answers": ["30 A", "40 A"], "correct_index": 0, "reference_text": "X\nA 30 ampere circuit."}
	for seg in ST.speech_plan(rec):
		t.eq(int(seg.get("rules", -1)), Rules.VERSION, "segment '%s' carries rules version" % str(seg.get("text", "")).left(30))
	t.check(Rules.VERSION >= 2, "rules version was bumped past the pre-ruleset clips")


func no_answer_before_answering() -> void:
	print("=== pre-answer segments never narrate the answer or the rule ===")
	var recs: Array = (JSON.parse_string(FileAccess.get_file_as_string("res://data/question_bank.json")) as Dictionary).get("records", [])
	var leaks := 0
	for rec_v in recs:
		var rec: Dictionary = rec_v
		var pre: Array = ST.spoken_segments(rec)
		var teach: Array = ST.teach_segments(rec)
		for seg in pre:
			var txt := str(seg["text"])
			if bool(seg["teach"]) or txt.begins_with("Answer") or txt.contains("Calculation:") or txt.contains("Formula:"):
				leaks += 1
			for tseg in teach:
				if txt == str(tseg["text"]):
					leaks += 1
		var plan: Array = ST.speech_plan(rec)
		for i in pre.size():
			if plan[i]["text"] != pre[i]["text"] or bool(plan[i]["teach"]):
				leaks += 1
	t.eq(leaks, 0, "no pre-answer segment is a teach line, a callout or a calculation")


func bank_sweep() -> void:
	print("=== bank sweep: every spoken line of every record ===")
	var recs: Array = (JSON.parse_string(FileAccess.get_file_as_string("res://data/question_bank.json")) as Dictionary).get("records", [])
	t.eq(recs.size() > 0 and recs.size() == BankLoader.declared_count(), true, "bank read is not vacuous: %d records" % recs.size())
	var caps := RegEx.create_from_string("\\b[A-Z]{2,}s?\\b")
	var hostile := RegEx.create_from_string("[\\t\\n_\"“”‘’—–→÷×√≈Ω½¼¾≤≥±−²³•…%#=]|\\.\\.|\\s[,.;:](?!\\d)|\\b\\d{2,3}\\.\\d+\\(|\\bft\\b|\\blbs?\\b|\\bkcmil\\b")
	# A bare NNN.N left in a line is voiced as a decimal; the only real one in the bank is a resistance.
	var bare_section := RegEx.create_from_string("\\b(?:90|[1-9]\\d{2})\\.\\d+\\b(?! ohms)")
	# A capital "A" before a lowercase word is voiced as the letter, so only a real letter may be one.
	var letter_a := RegEx.create_from_string("\\b([A-Za-z-]+) A (?=[a-z])")
	var letter_words := ["paragraph", "sub-item", "Class", "phase"]
	var bad_caps := {}
	var bad := 0
	for rec_v in recs:
		var rec: Dictionary = rec_v
		var plan: Array = ST.speech_plan(rec)
		for si in plan.size():
			var seg: Dictionary = plan[si]
			var txt := str(seg["text"])
			var bs := bare_section.search(txt)
			if bs != null:
				bad += 1
				print("  bare section '%s' in %s" % [bs.get_string(0), rec.get("id", "")])
			for la in letter_a.search_all(txt):
				if not la.get_string(1) in letter_words:
					bad += 1
					print("  article read as letter '%s' in %s" % [la.get_string(0), rec.get("id", "")])
			for m in caps.search_all(txt):
				if not Rules.SAY_AS.has(m.get_string(0)):
					bad_caps[m.get_string(0)] = str(rec.get("id", ""))
			var h := hostile.search(txt)
			if h != null:
				bad += 1
				if bad <= 8:
					print("  hostile '%s' in %s: %s" % [h.get_string(0), rec.get("id", ""), txt.left(100)])
			var letter := ST.letter_line(int(seg["choice"]))
			if int(seg["choice"]) >= 0 and not bool(seg["teach"]) and txt != letter \
					and (si == 0 or str(plan[si - 1]["text"]) != letter):
				bad += 1
	t.eq(bad_caps, {}, "every all-caps token is spelled, expanded, lower-cased or a known word")
	t.eq(bad, 0, "no raw symbol, table tab, doubled period, unconverted unit or unlettered choice reaches the voice")
