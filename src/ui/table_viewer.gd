class_name TableViewer
extends RefCounted
## Encapsulates NEC Table rendering, style generation, and row centering / auto-scroll logic.

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

static func preview_layout(rows: Array, max_scroll_height: float = 220.0) -> Dictionary:
	var row_count := 0
	var has_note := false
	for row in rows:
		if not row is Array or row.is_empty():
			continue
		if is_note_row(row):
			has_note = true
		else:
			row_count += 1
	var scroll_height := clampf(float(row_count) * 33.0, 42.0, max_scroll_height)
	var panel_height := maxf(120.0, scroll_height + 38.0 + (28.0 if has_note else 0.0))
	return {"scroll_height": scroll_height, "panel_height": panel_height}

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
	target_keyword: String = ""
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
			var note_text := _strip_note_prefix(str(row[0]))
			if not is_feedback and highlight_answer != "":
				note_text = AudioExplanationGenerator.redact_answer_spans(note_text, highlight_answer)
			note_label.text = note_text
			note_label.visible = note_label.text != ""
		else:
			visible_rows.append(row)

	if visible_rows.is_empty():
		grid.columns = 1
		return {"highlighted": false, "matched_row": -1, "row_count": 0}

	var column_count := 1
	for row in visible_rows:
		column_count = maxi(column_count, row.size())
	grid.columns = column_count

	var target_kw := target_keyword.strip_edges().to_lower()
	for row_index in visible_rows.size():
		var row: Array = visible_rows[row_index]
		var row_matches_target := false
		if target_kw != "" and row_index > 0:
			for col_val in row:
				if str(col_val).to_lower().contains(target_kw):
					row_matches_target = true
					break
		for column_index in column_count:
			var raw_value := str(row[column_index]) if column_index < row.size() else ""
			var is_header := row_index == 0
			var cell_matches_answer := not is_header and highlight_answer != "" and not AudioExplanationGenerator.find_match_in(raw_value, highlight_answer).is_empty()
			
			var display_text := raw_value
			var cell_is_blanked := false
			if not is_feedback and cell_matches_answer:
				display_text = "[ ___ ]"
				cell_is_blanked = true

			var cell_highlighted := is_feedback and cell_matches_answer
			var cell := PanelContainer.new()
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var cell_width := 118.0
			if column_count == 2:
				cell_width = 300.0 if column_index == 0 else 105.0
			elif column_count >= 8:
				cell_width = 84.0 if column_index == 0 else 112.0
			cell.custom_minimum_size = Vector2(cell_width, 30.0)
			var header_cell := row_index == 0
			var background := AppTheme.TABLE_HEADER_BG if header_cell else (AppTheme.EMERALD_900 if cell_highlighted else (AppTheme.SLATE_900 if cell_is_blanked else (AppTheme.TABLE_ROW_EVEN if row_index % 2 == 0 else AppTheme.TABLE_ROW_ODD)))
			var border := AppTheme.TABLE_HEADER_BORDER if header_cell else (AppTheme.EMERALD_400 if cell_highlighted else (AppTheme.SKY_400 if cell_is_blanked else AppTheme.TABLE_CELL_BORDER))
			cell.add_theme_stylebox_override("panel", AppTheme.panel_style(background, border, 1, 0))
			grid.add_child(cell)
			var margin := MarginContainer.new()
			margin.add_theme_constant_override("margin_left", 7)
			margin.add_theme_constant_override("margin_right", 7)
			margin.add_theme_constant_override("margin_top", 4)
			margin.add_theme_constant_override("margin_bottom", 4)
			cell.add_child(margin)
			var label := Label.new()
			label.text = display_text
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if column_index == 0 else HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 12 if column_count < 8 else 11)
			var text_color: Color = AppTheme.SKY_400 if header_cell else (AppTheme.EMERALD_50 if cell_highlighted else (AppTheme.SKY_400 if cell_is_blanked else AppTheme.SLATE_100))
			label.add_theme_color_override("font_color", text_color)
			margin.add_child(label)
			if cell_matches_answer and matched_row < 0:
				matched_row = row_index
			# "highlighted" must mean "an answer cell is actually coloured", so the
			# ANSWER DETAIL fallback in main.gd is not suppressed when nothing was
			# highlighted. A keyword-only row match drives matched_row (the scroll
			# target) but is not a visual highlight, so it must not set this flag.
			answer_highlighted = answer_highlighted or cell_matches_answer

	return {
		"highlighted": answer_highlighted,
		"matched_row": matched_row,
		"row_count": visible_rows.size()
	}

static func scroll_to_row(scroll_container: ScrollContainer, grid: GridContainer, match_row: int, row_count: int) -> void:
	if row_count <= 0 or match_row <= 0:
		return
	if not is_instance_valid(scroll_container) or not is_instance_valid(grid):
		return
	var total_h := grid.get_combined_minimum_size().y
	if total_h <= 0.0:
		return
	var row_h := total_h / float(row_count)
	var bar := scroll_container.get_v_scroll_bar()
	if bar == null:
		return
	bar.value = clampf(float(match_row - 1) * row_h, 0.0, bar.max_value)
