extends SceneTree
## table_viewer.gd -- the PURE helpers only.
##
##   _folded_lines, max_blocks, _column_floors, _column_widths   folding and widths
##   extract_target_keyword   the scroll target, no nodes
##   is_note_row              note-row classification, no nodes
##   _strip_note_prefix       note text cleanup, no nodes
##
## populate_table and the fit (predict_height, pick_layout) are NOT here: they
## need live labels; test_table_fit.gd and tools/harness.gd drive them.
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
	folding_layout()
	column_widths()
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
# Folding and column widths -- the table never scrolls, so a long narrow one
# folds into side-by-side blocks and the columns share the box's width.
# --------------------------------------------------------------------------
func folding_layout() -> void:
	print("=== folding ===")
	var header := ["Size", "Amps"]
	var rows := [header, ["a", "1"], ["b", "2"], ["c", "3"], ["d", "4"], ["e", "5"]]
	var one: Array = TV._folded_lines(rows, 1)
	t.eq(one.size(), 6, "one block: header + 5 lines")
	t.eq(one[0], header, "one block: the header comes first")
	var two: Array = TV._folded_lines(rows, 2)
	t.eq(two.size(), 4, "two blocks: header + ceil(5/2) = 3 lines")
	t.eq(two[0], ["Size", "Amps", "Size", "Amps"], "each block has its own header")
	t.eq(two[1], ["a", "1", "d", "4"], "rows run down the first block, then the next")
	t.eq(two[3], ["c", "3", "", ""], "the last block is padded with empty cells")
	t.eq((TV._folded_lines(rows, 9)[0] as Array).size(), 10, "never more blocks than body rows (5 blocks of 2 columns)")

	var grid := GridContainer.new()
	var long_rows: Array = [header]
	for i in 30:
		long_rows.append(["row %d" % i, str(i)])
	long_rows.append(["NOTE: a note"])
	grid.set_meta("populate_args", [null, long_rows, "", true, ""])
	t.eq(TV.max_blocks(grid), 3, "30 short rows may fold into 3 blocks")
	grid.set_meta("populate_args", [null, [header, ["a", "1"], ["b", "2"], ["c", "3"]], "", true, ""])
	t.eq(TV.max_blocks(grid), 1, "3 body rows never fold")
	grid.set_meta("populate_args", [null, [["h1", "h2", "h3", "h4"]] + long_rows.slice(1, 20).map(func(r): return r + ["x", "y"]), "", true, ""])
	t.eq(TV.max_blocks(grid), 1, "a table of 4+ columns never folds")
	grid.free()


func column_widths() -> void:
	print("=== column widths ===")
	var font: Font = ThemeDB.fallback_font
	var floors: Array[float] = TV._column_floors([["TF/XHHW/TW", "Out"]], font, 12, 0)
	var whole: float = font.get_string_size("TF/XHHW/TW", HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	t.check(floors[0] < whole, "text breaks after '/', so the floor is under the whole word")
	t.check(TV._keeps_words(floors, 1000.0) and not TV._keeps_words(floors, 20.0), "_keeps_words compares the floors with the width")

	var lines := [["Type of occupancy", "Unit load (VA/ft2)"], ["Office", "1.3"], ["Hospital", "1.6"],
			["Hotel or motel, or apartment house without provision for cooking by tenant", "1.7"]]
	for width in [200.0, 320.0, 600.0]:
		var widths: Array[float] = TV._column_widths(lines, width, font, 12, 0)
		t.check(widths[0] + widths[1] <= width + 0.01, "columns never exceed the box (%d px)" % width)
	var w: Array[float] = TV._column_widths(lines, 320.0, font, 12, 0)
	var number_floor: float = TV._column_floors(lines, font, 12, 0)[1]
	t.check(w[1] <= number_floor + 0.01, "a long header wraps instead of widening a column of numbers")
	var roomy: Array[float] = TV._column_widths([["A", "B"], ["x", "y"]], 600.0, font, 12, 0)
	t.check(roomy[0] + roomy[1] < 600.0, "short text leaves the rest of the width to the grid")
	var squeezed: Array[float] = TV._column_widths([["Transportation", "Warehouse"], ["a", "b"]], 40.0, font, 12, 0)
	t.check(absf(squeezed[0] + squeezed[1] - 40.0) < 0.01, "too narrow: the floors scale down to the width")

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
		# Folding keeps every data cell exactly once, in every block count.
		var body: Array = []
		for row_v in (tbl as Array):
			if row_v is Array and not (row_v as Array).is_empty() and not TV.is_note_row(row_v):
				body.append(row_v)
		for blocks in [1, 2, 3]:
			var cells := 0
			for line in TV._folded_lines(body, blocks).slice(1):
				for cell in line:
					cells += 1 if str(cell) != "" else 0
			var want := 0
			for row in body.slice(1):
				for cell in row:
					want += 1 if str(cell) != "" else 0
			if cells != want or data_rows != body.size():
				mismatch += 1
	t.check(tables > 0, "the bank contains reference tables (got %d)" % tables)
	t.eq(mismatch, 0, "folding into 1-3 blocks keeps every data cell of every bank table once")
	# Every numbered NEC note in the bank is now classified as a note. This was
	# a defect pin expecting final-exam-#1-021 to slip through; the is_note_row
	# fix closed it, so there is nothing left to list.
	t.eq(note_ids, [], "no numbered NEC note in the bank is left unclassified")


func report() -> void:
	t.report()
