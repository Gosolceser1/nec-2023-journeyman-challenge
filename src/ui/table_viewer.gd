class_name TableViewer
extends RefCounted
## NEC table rendering: cells, answer highlight or blank, and a column fit that
## lets the table show whole without scrolling.

## Cell padding per text level; the font is the base size minus the level.
const CELL_PAD_X := [7, 6, 5, 4]
const CELL_PAD_Y := [4, 3, 2, 1]
const TEXT_LEVELS := 4

## The characters that may follow the word NOTE in a real note row: a colon,
## a number separator, or plain whitespace. Shared by is_note_row() and
## _strip_note_prefix() so the classifier and the strip can never disagree --
## that disagreement is what let a "NOTE 1:" row render as data while
## "NOTED:" had its first four characters eaten.
static func _is_note_separator(ch: String) -> bool:
	return ch == ":" or ch == " " or ch == "." or ch == ","

static func _strip_note_prefix(text: String) -> String:
	# "NOTE: x" / "NOTE 1: x" / "NOTE No. 1: x" -> "x"
	var out := text.strip_edges()
	var upper := out.to_upper()
	if not upper.begins_with("NOTE"):
		return out
	# "NOTE" must be the whole word. Without this test a cell beginning with a
	# word that merely STARTS with "note" had 4 characters cut off it: "NOTED: x"
	# became "D: x". is_note_row() already draws this line; the two must agree,
	# because is_note_row decides whether the text is a note at all and this
	# function decides what the note says.
	var after_word := out.substr(4)
	if after_word != "" and not _is_note_separator(after_word.substr(0, 1)):
		return out
	out = after_word.strip_edges()
	# Drop a leading note number / label ("1:", "No. 1:").
	while out != "":
		if out.begins_with(":"):
			out = out.substr(1).strip_edges()
			break
		if out.substr(0, 1) == "." or out.substr(0, 1) == ",":
			out = out.substr(1).strip_edges()
			continue
		if out.substr(0, 1).is_valid_int() or out.substr(0, 1) == "(":
			break
		break
	if out.to_upper().begins_with("NO."):
		out = out.substr(3).strip_edges()
		if out.begins_with(":"):
			out = out.substr(1).strip_edges()
	# A bare number followed by a colon ("1: text").
	var colon := out.find(":")
	if colon > 0 and out.substr(0, colon).strip_edges().is_valid_int():
		out = out.substr(colon + 1).strip_edges()
	return out.strip_edges()

static func is_note_row(row: Array) -> bool:
	# NEC tables number their notes ("NOTE:", "NOTE 1:", "NOTE 2:", "NOTE No. 1:").
	# Only matching the bare "NOTE:" prefix left numbered notes to be rendered as
	# data rows, inflating the row count and hiding the note from the note strip.
	#
	# Do NOT strip_edges() before the prefix test: the separator IS the evidence.
	# "NOTE 1:" -> " 1:" and "NOTE No. 1:" -> " NO. 1:". Testing the stripped form
	# for a leading space is dead code (nothing follows strip_edges() with one),
	# so every numbered note fell through as a data row - the exact bug the
	# function was written to fix. Verified against final-exam-#1-021.
	if row.size() != 1:
		return false
	var head := str(row[0]).strip_edges().to_upper()
	if not head.begins_with("NOTE"):
		return false
	# A data cell that merely starts with the letters NOTE (e.g. "NOTES ON
	# SUPPLIES") is not a note row; a real note is "NOTE" then a separator.
	var tail := head.substr(4)
	if tail == "":
		return true
	return _is_note_separator(tail.substr(0, 1))

static func extract_target_keyword(record: Dictionary, table: Array) -> String:
	if table.is_empty():
		return ""
	var prompt := str(record.get("prompt", "")).to_lower()
	var best_kw := ""
	var best_len := 0
	for row_index in range(1, table.size()):
		var row = table[row_index]
		if not row is Array or row.is_empty():
			continue
		var candidate := str(row[0]).strip_edges()
		if candidate.length() < 3 or candidate.begins_with("NOTE:"):
			continue
		var cand_lower := candidate.to_lower()
		if prompt.contains(cand_lower):
			if cand_lower.length() > best_len:
				best_len = cand_lower.length()
				best_kw = cand_lower
	return best_kw

static func populate_table(
	grid: GridContainer,
	note_label: Label,
	rows: Array,
	highlight_answer: String = "",
	is_feedback: bool = true,
	target_keyword: String = "",
	blocks: int = 1
) -> Dictionary:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	note_label.text = ""
	note_label.visible = false

	var matched_row := -1
	var answer_highlighted := false
	var visible_rows: Array = []
	for row in rows:
		if not row is Array or row.is_empty():
			continue
		if is_note_row(row):
			# A note states the factors and the method, so it waits for the answer.
			note_label.text = _strip_note_prefix(str(row[0])) if is_feedback else ""
			note_label.visible = note_label.text != ""
		else:
			visible_rows.append(row)

	if visible_rows.is_empty():
		grid.columns = 1
		return {"highlighted": false, "matched_row": -1, "row_count": 0}

	var column_count := 1
	for row in visible_rows:
		column_count = maxi(column_count, row.size())
	var body_count := visible_rows.size() - 1
	blocks = clampi(blocks, 1, maxi(1, body_count))
	var per_block := ceili(float(body_count) / float(blocks)) if body_count > 0 else 0
	grid.columns = column_count * blocks
	var base_size := 12 if column_count < 8 else 11
	grid.set_meta("base_text_size", base_size)
	grid.set_meta("text_level", 0)
	grid.set_meta("blocks", blocks)
	grid.set_meta("populate_args", [note_label, rows, highlight_answer, is_feedback, target_keyword])

	# Folded, the rows run down the first block, then the next, each block under
	# its own copy of the header, like a long table printed in columns.
	for line in per_block + 1:
		for block in blocks:
			var row_index := 0 if line == 0 else 1 + block * per_block + line - 1
			var row: Array = visible_rows[row_index] if row_index < visible_rows.size() else []
			var filler := row.is_empty()
			for column_index in column_count:
				var raw_value := str(row[column_index]) if column_index < row.size() else ""
				var header_cell := line == 0
				var cell_matches_answer := not header_cell and not filler and highlight_answer != "" and not AudioExplanationGenerator.find_match_in(raw_value, highlight_answer).is_empty()
				var display_text := raw_value
				var cell_is_blanked := false
				if not is_feedback and cell_matches_answer:
					display_text = "[ ___ ]"
					cell_is_blanked = true
				var cell_highlighted := is_feedback and cell_matches_answer
				var cell := PanelContainer.new()
				cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var background := AppTheme.TABLE_HEADER_BG if header_cell else (AppTheme.EMERALD_900 if cell_highlighted else (AppTheme.SLATE_900 if cell_is_blanked else (AppTheme.TABLE_ROW_EVEN if line % 2 == 0 else AppTheme.TABLE_ROW_ODD)))
				var border := AppTheme.TABLE_HEADER_BORDER if header_cell else (AppTheme.EMERALD_400 if cell_highlighted else (AppTheme.SKY_400 if cell_is_blanked else AppTheme.TABLE_CELL_BORDER))
				var style := AppTheme.panel_style(background, border, 1, 0)
				if block > 0 and column_index == 0:
					style.border_width_left = 3
				cell.add_theme_stylebox_override("panel", style)
				grid.add_child(cell)
				var margin := MarginContainer.new()
				margin.add_theme_constant_override("margin_left", CELL_PAD_X[0])
				margin.add_theme_constant_override("margin_right", CELL_PAD_X[0])
				margin.add_theme_constant_override("margin_top", CELL_PAD_Y[0])
				margin.add_theme_constant_override("margin_bottom", CELL_PAD_Y[0])
				cell.add_child(margin)
				var label := Label.new()
				label.text = display_text
				label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if column_index == 0 else HORIZONTAL_ALIGNMENT_CENTER
				label.add_theme_font_size_override("font_size", base_size)
				var text_color: Color = AppTheme.SKY_400 if header_cell else (AppTheme.EMERALD_50 if cell_highlighted else (AppTheme.SKY_400 if cell_is_blanked else AppTheme.SLATE_100))
				label.add_theme_color_override("font_color", text_color)
				margin.add_child(label)
				if cell_matches_answer and matched_row < 0:
					matched_row = row_index
				# "highlighted" must mean "an answer cell is actually coloured", so the
				# ANSWER DETAIL fallback in main.gd is not suppressed when nothing was
				# highlighted.
				answer_highlighted = answer_highlighted or cell_matches_answer

	fit_columns(grid)
	return {
		"highlighted": answer_highlighted,
		"matched_row": matched_row,
		"row_count": visible_rows.size()
	}

## How many side-by-side blocks the table may fold into: only narrow tables
## (up to 3 columns) with at least 4 body rows per block.
static func max_blocks(grid: GridContainer) -> int:
	var body_rows := _table_rows(grid)
	if body_rows.is_empty():
		return 1
	var cols := 1
	for row in body_rows:
		cols = maxi(cols, row.size())
	if cols > 3:
		return 1
	return clampi(floori((body_rows.size() - 1) / 4.0), 1, 3)

static func block_count(grid: GridContainer) -> int:
	return int(grid.get_meta("blocks", 1))

## Rebuild the table folded into `count` blocks, keeping its text level.
static func set_blocks(grid: GridContainer, count: int) -> void:
	var args: Array = grid.get_meta("populate_args", [])
	if args.is_empty() or count == block_count(grid):
		return
	var level := text_level(grid)
	populate_table(grid, args[0], args[1], args[2], args[3], args[4], count)
	if level > 0:
		set_text_level(grid, level)

static func _cell_label(cell: Node) -> Label:
	if cell.get_child_count() == 0 or cell.get_child(0).get_child_count() == 0:
		return null
	return cell.get_child(0).get_child(0) as Label

## Table text density, roomy (0) -> dense (TEXT_LEVELS - 1). The table never
## scrolls, so FitController steps it down when the page would.
static func set_text_level(grid: GridContainer, level: int) -> void:
	level = clampi(level, 0, TEXT_LEVELS - 1)
	grid.set_meta("text_level", level)
	var size := int(grid.get_meta("base_text_size", 12)) - level
	for cell in grid.get_children():
		var label := _cell_label(cell)
		if label == null:
			continue
		var margin := cell.get_child(0) as MarginContainer
		margin.add_theme_constant_override("margin_left", CELL_PAD_X[level])
		margin.add_theme_constant_override("margin_right", CELL_PAD_X[level])
		margin.add_theme_constant_override("margin_top", CELL_PAD_Y[level])
		margin.add_theme_constant_override("margin_bottom", CELL_PAD_Y[level])
		label.add_theme_font_size_override("font_size", size)
	fit_columns(grid)

static func text_level(grid: GridContainer) -> int:
	return int(grid.get_meta("text_level", 0))

## Split the table's width between its columns so it never needs to scroll
## sideways. Runs on populate, on a text level change and when the table's box
## is resized.
static func fit_columns(grid: GridContainer) -> void:
	var box := grid.get_parent() as Control
	var cells := grid.get_children()
	if box == null or box.size.x <= 0.0 or cells.is_empty():
		return
	var label := _cell_label(cells[0])
	if label == null:
		return
	var cols := maxi(grid.columns, 1)
	var lines: Array = []
	for i in cells.size():
		if i % cols == 0:
			lines.append([])
		var cell_label := _cell_label(cells[i])
		lines[-1].append(cell_label.text if cell_label != null else "")
	var widths := _column_widths(lines, box.size.x, label.get_theme_font("font"), label.get_theme_font_size("font_size"), text_level(grid))
	for i in cells.size():
		(cells[i] as Control).custom_minimum_size.x = floorf(widths[i]) if i < cols else 0.0

## Width of each column's longest unbreakable piece: text wraps at spaces and
## after "/" and "-" ("TF/XHHW/TW"), and a narrower column breaks inside a word.
static func _column_floors(lines: Array, font: Font, size: int, level: int) -> Array[float]:
	var cols: int = (lines[0] as Array).size()
	var pad: float = 2.0 * CELL_PAD_X[level] + 4.0
	var floors: Array[float] = []
	floors.resize(cols)
	floors.fill(0.0)
	for line in lines:
		for c in cols:
			var piece := ""
			for ch in str(line[c]) + " ":
				if ch != " ":
					piece += ch
				if ch == " " or ch == "/" or ch == "-":
					if piece != "":
						floors[c] = maxf(floors[c], font.get_string_size(piece, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + pad)
					piece = ""
	return floors

## True when every column can hold its longest unbreakable piece at `width`.
static func _keeps_words(floors: Array[float], width: float) -> bool:
	var total := 0.0
	for w in floors:
		total += w
	return total <= width

## Every column gets its longest word. The rest of the width brings columns up
## to their typical (85th percentile) body cell on one line, then up to their
## longest, the smallest shortfalls met first and the rest shared equally; an
## outlier cell wraps before it widens its column at the others' cost. Headers
## only claim their longest word, so a long header wraps over a column of short
## numbers.
static func _column_widths(lines: Array, width: float, font: Font, size: int, level: int) -> Array[float]:
	var cols: int = (lines[0] as Array).size()
	# Padding, border and 2 px so a text that just fits is not wrapped by rounding.
	var pad: float = 2.0 * CELL_PAD_X[level] + 4.0
	var floor_w := _column_floors(lines, font, size, level)
	var typical: Array[float] = []
	var longest: Array[float] = []
	for c in cols:
		var word_w := floor_w[c]
		var body_w: Array[float] = []
		for line_index in lines.size():
			var text := str(lines[line_index][c])
			if line_index > 0 and text != "":
				body_w.append(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + pad)
		body_w.sort()
		typical.append(maxf(word_w, body_w[floori(0.85 * (body_w.size() - 1))] if not body_w.is_empty() else 0.0))
		longest.append(maxf(word_w, body_w[-1] if not body_w.is_empty() else 0.0))
	var floor_sum := 0.0
	for w in floor_w:
		floor_sum += w
	var widths: Array[float] = []
	if floor_sum >= width:
		for w in floor_w:
			widths.append(w * width / floor_sum)
		return widths
	widths = floor_w.duplicate()
	var budget := width - floor_sum
	for goal in [typical, longest]:
		var order := range(cols)
		order.sort_custom(func(a, b): return goal[a] - widths[a] < goal[b] - widths[b])
		for k in cols:
			var c: int = order[k]
			var add := clampf(goal[c] - widths[c], 0.0, budget / float(cols - k))
			widths[c] += add
			budget -= add
	return widths

## The table's rows without its notes, as populate_table last drew them.
static func _table_rows(grid: GridContainer) -> Array:
	var args: Array = grid.get_meta("populate_args", [])
	var out: Array = []
	if args.is_empty():
		return out
	for row in args[1]:
		if row is Array and not row.is_empty() and not is_note_row(row):
			out.append(row)
	return out

## Cell texts line by line for the table folded into `blocks`, in the order
## populate_table lays them out ("" pads the last block).
static func _folded_lines(body_rows: Array, blocks: int) -> Array:
	var cols := 1
	for row in body_rows:
		cols = maxi(cols, row.size())
	var body_count := body_rows.size() - 1
	blocks = clampi(blocks, 1, maxi(1, body_count))
	var per_block := ceili(float(body_count) / float(blocks)) if body_count > 0 else 0
	var lines: Array = []
	for line in per_block + 1:
		var texts: Array = []
		for block in blocks:
			var row_index := 0 if line == 0 else 1 + block * per_block + line - 1
			var row: Array = body_rows[row_index] if row_index < body_rows.size() else []
			for c in cols:
				texts.append(str(row[c]) if c < row.size() else "")
		lines.append(texts)
	return lines

## Height the grid would take at `width` folded into `blocks` at text `level`,
## from the font metrics: the real grid only re-measures after a re-sort.
static func predict_height(grid: GridContainer, width: float, blocks: int, level: int) -> float:
	var body_rows := _table_rows(grid)
	var cells := grid.get_children()
	if body_rows.is_empty() or cells.is_empty() or _cell_label(cells[0]) == null:
		return 0.0
	var label := _cell_label(cells[0])
	var font := label.get_theme_font("font")
	var size := int(grid.get_meta("base_text_size", 12)) - level
	var spacing := float(label.get_theme_constant("line_spacing"))
	var line_h := font.get_height(size)
	var lines := _folded_lines(body_rows, blocks)
	var widths := _column_widths(lines, width, font, size, level)
	var pad: float = 2.0 * CELL_PAD_X[level] + 2.0
	var flags := TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	var total := 0.0
	for line in lines:
		var row_h := 0.0
		for c in (line as Array).size():
			var text := str(line[c])
			var n := 1
			if text != "":
				var wrapped := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, maxf(widths[c] - pad, 1.0), size, -1, flags)
				n = maxi(1, roundi(wrapped.y / line_h))
			row_h = maxf(row_h, n * line_h + (n - 1) * spacing)
		total += row_h + 2.0 * CELL_PAD_Y[level] + 2.0
	return total

## Whether the table folded into `blocks` at text `level` keeps every word
## whole at `width`.
static func keeps_words(grid: GridContainer, width: float, blocks: int, level: int) -> bool:
	var body_rows := _table_rows(grid)
	var cells := grid.get_children()
	if body_rows.is_empty() or cells.is_empty() or _cell_label(cells[0]) == null:
		return true
	var font := _cell_label(cells[0]).get_theme_font("font")
	var size := int(grid.get_meta("base_text_size", 12)) - level
	return _keeps_words(_column_floors(_folded_lines(body_rows, blocks), font, size, level), width)

## The most readable layout whose height, scaled by how the prediction compares
## with the grid on screen now, fits `target`: whole words first, then the
## largest type, then the fewest blocks. When none fits, the smallest one, or
## the current one if smallest_if_none is off. Returns [blocks, level].
static func pick_layout(grid: GridContainer, width: float, target: float, smallest_if_none := true) -> Array:
	var now := [block_count(grid), text_level(grid)]
	var predicted_now := predict_height(grid, width, now[0], now[1])
	var scale := grid.get_combined_minimum_size().y / predicted_now if predicted_now > 0.0 else 1.0
	var smallest := now
	var smallest_h := INF
	for whole_words in [true, false]:
		for level in TEXT_LEVELS:
			for blocks in range(1, max_blocks(grid) + 1):
				if whole_words and not keeps_words(grid, width, blocks, level):
					continue
				var h := predict_height(grid, width, blocks, level) * scale
				if h <= target:
					return [blocks, level]
				if h < smallest_h:
					smallest_h = h
					smallest = [blocks, level]
	return smallest if smallest_if_none else now

static func apply_layout(grid: GridContainer, layout: Array) -> void:
	set_blocks(grid, int(layout[0]))
	set_text_level(grid, int(layout[1]))
