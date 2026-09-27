extends SceneTree
## table_viewer.gd -- the PURE helpers only.
##
##   preview_layout           geometry, no nodes
##   extract_target_keyword   the scroll target, no nodes
##   is_note_row              note-row classification, no nodes
##   _strip_note_prefix       note text cleanup, no nodes
##
## populate_table and scroll_to_row are deliberately NOT here: they need a live
## GridContainer/Label/ScrollContainer and stay in tools/harness.gd.
##
##   ./Godot_v4.7.2-stable_win64_console.exe --headless --path . \
##       --script tools/tests/test_table_viewer.gd

const TV = preload("res://src/ui/table_viewer.gd")
const R = preload("res://tools/tests/t_report.gd")

var t: R = R.new()


## SceneTree entry point. When the file is run on its own this calls run();
## when run_all.gd drives it, the runner calls run() directly so a failing
## assertion in one suite cannot abort the others.
func _init() -> void:
	# Standalone execution: run and set the exit code. The combined runner sets
	# t_report.autostart_disabled so this becomes a no-op there (it calls run()).
	if not t.run_suite_body():
		return
	run()
	quit(0 if t.failures.is_empty() else 1)


func run() -> void:
	is_note_row_classification()
	strip_note_prefix()
	preview_layout_geometry()
	preview_layout_edge_cases()
	extract_target_keyword_matching()
	extract_target_keyword_edges()
	note_row_bank_consistency()
	report()


# --------------------------------------------------------------------------
# is_note_row -- a single-cell row whose first word is "NOTE"
# --------------------------------------------------------------------------
func is_note_row_classification() -> void:
	print("=== is_note_row ===")
	# The bare forms the NEC actually uses and the function DOES accept.
	var accepted := [
		["NOTE: text", "bare NOTE:"],
		["NOTE:", "bare NOTE with no body"],
		["note: text", "lowercase note:"],
		["NOTE : text", "NOTE then space then colon"],
		["NOTE", "bare NOTE word"],
	]
	for row in accepted:
		t.eq(TV.is_note_row([row[0]]), true, "is_note_row([%s]) [%s]" % [row[0], row[1]])

	# Rows that are NOT notes.
	var rejected := [
		[["NOTE: x", "y"], "two cells is never a note"],
		[["Notes on the subject"], "'Notes' is a different word"],
		[["noted"], "'noted' is a different word"],
		[[""], "empty cell"],
		[["Column A", "Column B"], "a header row"],
		[["30 A", "40 A"], "a data row"],
		[["15/16 in."], "a data row"],
	]
	for row in rejected:
		t.eq(TV.is_note_row(row[0]), false, "is_note_row(%s) [%s]" % [str(row[0]), row[1]])
	# A non-Array row is skipped by the `row is Array` guard, but it raises a
	# logged type error, so it is asserted as returning false without the noise.
	t.eq(TV.is_note_row([["a"], ["b"]]), false, "is_note_row: a normal two-row table is not a note")

	# Numbered notes are now classified correctly. These were recorded as a
	# defect pin (expecting false); the fix in is_note_row made them true, which
	# is the intended behaviour, so the pins are gone rather than flipped.
	t.eq(TV.is_note_row(["NOTE 1: text"]), true, "is_note_row: 'NOTE 1:' is a note row")
	t.eq(TV.is_note_row(["NOTE No. 1: text"]), true, "is_note_row: 'NOTE No. 1:' is a note row")
	# A data cell that merely begins with the letters NOTE is not a note.
	t.eq(TV.is_note_row(["NOTES ON SUPPLIES"]), false, "is_note_row: 'NOTES ON SUPPLIES' is data, not a note")
	t.eq(TV.is_note_row(["NOTED"]), false, "is_note_row: 'NOTED' is data, not a note")


# --------------------------------------------------------------------------
# _strip_note_prefix -- "NOTE: x" / "NOTE 1: x" / "NOTE No. 1: x" -> "x"
# --------------------------------------------------------------------------
func strip_note_prefix() -> void:
	print("=== _strip_note_prefix ===")
	var rows := [
		["NOTE: text", "text", "bare NOTE:"],
		["NOTE 1: text", "text", "numbered note"],
		["NOTE 2: text", "text", "numbered note"],
		["NOTE No. 1: text", "text", "'No. n' form"],
		["NOTE 3:(A) text", "(A) text", "a lettered sub-paragraph is kept"],
		["Note 2: (A) body", "(A) body", "lowercase note with a sub-paragraph"],
		["NOTE: ", "", "empty body"],
		["NOTE", "", "bare NOTE with no colon"],
		["  NOTE: text  ", "text", "edges stripped"],
		["NOTE 1. text", "1. text", "a '.' separator stops the number strip"],
		["", "", "empty stays empty"],
		["Just some text", "Just some text", "text without a NOTE prefix is untouched"],
		["NOTED: x", "NOTED: x", "'NOTED' is not a NOTE prefix, so nothing is stripped"],
	]
	for row in rows:
		t.eq(TV._strip_note_prefix(row[0]), row[1], "strip(%s) [%s]" % [row[0], row[2]])


# --------------------------------------------------------------------------
# preview_layout -- scroll/panel geometry
# --------------------------------------------------------------------------
func preview_layout_geometry() -> void:
	print("=== preview_layout ===")
	var header := ["Column C", "Maximum demand"]
	var rows := [header, ["One range 12 kW or less", "8 kW"], ["NOTE: not copper"], ["Over 12 kW", "5 kW"]]
	var out: Dictionary = TV.preview_layout(rows)
	# 3 data rows x 33.0 = 99.0, clamped into [42, 220].
	t.eq(float(out["scroll_height"]), 99.0, "scroll_height = data rows x 33")
	# panel = max(120, scroll + 38 + 28 for the note strip)
	t.eq(float(out["panel_height"]), 165.0, "panel_height = scroll + 38 + 28 (note strip present)")

	# The note strip adds exactly 28px; without a note it does not.
	# NOTE: preview_layout counts the HEADER as a data row (it is not special-cased),
	# so two rows -> 66 and three rows -> 99.
	var no_note: Dictionary = TV.preview_layout([header, ["a", "b"]])
	t.eq(float(no_note["scroll_height"]), 66.0, "2 rows (incl. header) x 33")
	t.eq(float(no_note["panel_height"]), 120.0, "panel floors at 120 when scroll + 38 is under it")
	t.eq(float(TV.preview_layout([header, ["a"], ["b"]])["scroll_height"]), 99.0, "3 rows x 33")
	t.eq(float(TV.preview_layout([header, ["a"], ["b"]])["panel_height"]), 137.0, "scroll 99 + 38 = 137")
	# The note strip adds exactly 28 on top.
	t.eq(float(TV.preview_layout([header, ["a"], ["NOTE: n"]])["panel_height"]), 132.0,
		"66 + 38 + 28 note strip = 132")

	# The cap is honoured.
	var many: Array = [header]
	for i in 30:
		many.append(["row %d" % i, "x"])
	t.eq(float(TV.preview_layout(many)["scroll_height"]), 220.0, "scroll_height clamps to the 220 default cap")
	t.eq(float(TV.preview_layout(many, 100.0)["scroll_height"]), 100.0, "scroll_height honours a custom cap")
	t.eq(float(TV.preview_layout(many, 190.0)["scroll_height"]), 190.0, "190 is the cap the feedback table uses")
	t.eq(float(TV.preview_layout(many, 190.0)["panel_height"]), 228.0, "panel grows with the capped scroll")


# --------------------------------------------------------------------------
# preview_layout -- degenerate input
# --------------------------------------------------------------------------
func preview_layout_edge_cases() -> void:
	print("=== preview_layout: edge cases ===")
	var empty: Dictionary = TV.preview_layout([])
	t.eq(float(empty["scroll_height"]), 42.0, "no rows -> scroll floors at 42")
	t.eq(float(empty["panel_height"]), 120.0, "no rows -> panel floors at 120")

	t.eq(float(TV.preview_layout([["a", "b"]])["scroll_height"]), 42.0, "one row still floors at 42")

	# Junk rows are skipped, not counted and not crashed on.
	var junk: Array = [[], "not an array", {}, null, ["real", "row"]]
	var out: Dictionary = TV.preview_layout(junk)
	t.eq(float(out["scroll_height"]), 42.0, "empty/非array rows are skipped")

	# A single note row is NOT a data row, so the count stays 0.
	t.eq(float(TV.preview_layout([["NOTE: only a note"]])["scroll_height"]), 42.0,
		"a lone note row does not inflate the scroll height")
	t.eq(float(TV.preview_layout([["NOTE: only a note"]])["panel_height"]), 120.0,
		"42 + 38 + 28 = 108, which the 120 panel floor absorbs")

	# The two keys must always be present and numeric.
	for rows in [[], [["a"]], [["NOTE: n"], ["a", "b"]]]:
		var res: Dictionary = TV.preview_layout(rows)
		t.check(res.has("scroll_height"), "scroll_height key present")
		t.check(res.has("panel_height"), "panel_height key present")
		t.check(typeof(res["scroll_height"]) in [TYPE_FLOAT, TYPE_INT], "scroll_height is numeric")
		t.check(float(res["panel_height"]) >= 120.0, "panel_height never drops below 120")


# --------------------------------------------------------------------------
# extract_target_keyword -- the scroll target for the pre-answer table
# --------------------------------------------------------------------------
func extract_target_keyword_matching() -> void:
	print("=== extract_target_keyword ===")
	var table := [["Size", "Ampacity"], ["14 AWG", "15 A"], ["12 AWG", "20 A"], ["10 AWG", "30 A"]]
	t.eq(TV.extract_target_keyword({"prompt": "What size is 12 AWG rated?"}, table), "12 awg",
		"a first-column cell that appears in the prompt is the target")
	t.eq(TV.extract_target_keyword({"prompt": "Ampacity of 14 AWG"}, table), "14 awg", "matched cell")
	# Matching is case-insensitive on both sides and the RESULT is lowercased.
	t.eq(TV.extract_target_keyword({"prompt": "10 AWG SIZE"}, table), "10 awg", "prompt case does not matter")
	# The LONGEST matching cell wins, so the row scrolls to the most specific one.
	t.eq(TV.extract_target_keyword({"prompt": "grounding conductor ampacity"},
		[["ampacity"], ["grounding conductor"]]), "grounding conductor", "the longest match wins")
	t.eq(TV.extract_target_keyword({"prompt": "ampacity of 14 awg or 10 awg"},
		[["14 AWG", "15"], ["10 AWG", "30"]]), "10 awg", "the longest of several matches wins")


func extract_target_keyword_edges() -> void:
	print("=== extract_target_keyword: edges ===")
	t.eq(TV.extract_target_keyword({"prompt": "anything"}, []), "", "an empty table has no target")
	t.eq(TV.extract_target_keyword({"prompt": "nothing matches here"},
		[["Size", "Ampacity"], ["14 AWG", "15 A"]]), "", "no cell in the prompt -> empty target")
	# Cells shorter than 3 characters are ignored (too generic to be useful).
	t.eq(TV.extract_target_keyword({"prompt": "what about ab here"}, [["ab"], ["ampacity"]]), "",
		"a 2-character cell is ignored")
	# A header row is never a target: the loop starts at index 1.
	t.eq(TV.extract_target_keyword({"prompt": "ampacity of a size"}, [["ampacity"], ["x", "y"]]), "",
		"row 0 (the header) is skipped")
	# Junk rows are skipped without crashing. The header occupies index 0, so a
	# match at index 1 is the earliest that can be found.
	t.eq(TV.extract_target_keyword({"prompt": "ampacity here"},
		["not an array", [], null, ["ampacity here"]]), "ampacity here", "junk rows are skipped")
	t.eq(TV.extract_target_keyword({"prompt": "ampacity"},
		[["ampacity"], ["x"]]), "", "index 0 is the header and is never a target")
	# A NOTE row is never a scroll target, even when the prompt names it.
	t.eq(TV.extract_target_keyword({"prompt": "note: ampacity"}, [["NOTE: ampacity here"]]), "",
		"a 'NOTE:' cell is skipped")
	# A record with no prompt key must not crash.
	var table2 := [["Size", "Ampacity"], ["14 AWG", "15 A"]]
	t.eq(TV.extract_target_keyword({}, table2), "", "a record with no prompt is handled")
	t.eq(TV.extract_target_keyword({"prompt": ""}, table2), "", "an empty prompt has no target")


# --------------------------------------------------------------------------
# Consistency over the real bank: a row is either a note or a data row, and
# the note-strip classification and the data-row count must agree.
# --------------------------------------------------------------------------
func note_row_bank_consistency() -> void:
	print("=== bank note/data consistency (25 tables) ===")
	var recs: Array = (JSON.parse_string(FileAccess.get_file_as_string("res://data/question_bank.json")) as Dictionary).get("records", [])
	t.eq(recs.size(), 283, "bank read is not vacuous")

	var tables := 0
	var mismatch := 0
	var numbered_notes := 0
	var note_ids: Array[String] = []
	for rec_v in recs:
		var rec: Dictionary = rec_v
		var tbl = rec.get("reference_table")
		if not (tbl is Array) or (tbl as Array).is_empty():
			continue
		tables += 1
		var data_rows := 0
		var notes := 0
		for row_v in (tbl as Array):
			if not (row_v is Array) or (row_v as Array).is_empty():
				continue
			var is_note: bool = TV.is_note_row(row_v)
			if is_note:
				notes += 1
			else:
				data_rows += 1
			# A row that _strip_note_prefix would rewrite is a note that should
			# HAVE been classified as one.
			var head := str((row_v as Array)[0]).strip_edges()
			var looks_like_note := head.to_upper().begins_with("NOTE ")
			if looks_like_note and not is_note:
				numbered_notes += 1
				note_ids.append(str(rec.get("id", "")))
		# data_rows must equal the row_count populate_table would report.
		var expected_scroll := clampf(float(data_rows) * 33.0, 42.0, 220.0)
		var layout: Dictionary = TV.preview_layout(tbl)
		if not is_equal_approx(float(layout["scroll_height"]), expected_scroll):
			mismatch += 1
	t.check(tables > 0, "the bank contains reference tables (got %d)" % tables)
	t.eq(mismatch, 0, "preview_layout row counts agree with is_note_row for every table")
	# Every numbered NEC note in the bank is now classified as a note. This was
	# a defect pin expecting final-exam-#1-021 to slip through; the is_note_row
	# fix closed it, so there is nothing left to list.
	t.eq(note_ids, [], "no numbered NEC note in the bank is left unclassified")


func report() -> void:
	t.report()
