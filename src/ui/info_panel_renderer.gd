class_name InfoPanelRenderer
extends RefCounted
## The post-answer explanation panel (memory tip, code provision, lesson lines,
## worked solution) and the rich-text helpers the results report shares.

const SpeechText = preload("res://src/speech/speech_text.gd")

var label: RichTextLabel
## Index into the lesson lines being spoken; -1 when none is highlighted.
var active_teach_line := -1
var _record: Dictionary = {}
var _correct_answer := ""
var _table_highlighted := false


func has_record() -> bool:
	return not _record.is_empty()

func append_answer_highlight(text: String, answer: String) -> bool:
	var match_info := SpeechText.find_answer_match(text, answer, str(_record.get("prompt", "")))
	if match_info.is_empty():
		label.add_text(text)
		return false
	var start := int(match_info["start"])
	var match_length := int(match_info["length"])
	label.add_text(text.substr(0, start))
	label.push_bgcolor(AppTheme.EMERALD_700)
	label.push_color(AppTheme.WHITE)
	label.push_bold()
	label.add_text(" " + text.substr(start, match_length) + " ")
	label.pop()
	label.pop()
	label.pop()
	label.add_text(text.substr(start + match_length))
	return true

## Provisions quote NEC tables as tab-separated lines; plain add_text() leaves the
## columns misaligned. Each run of tab lines becomes a RichTextLabel table. The
## answer is highlighted once, in the first prose block or cell that contains it.
func append_provision_with_tables(body: String, answer: String) -> bool:
	var highlighted := false
	var prose := PackedStringArray()
	var rows: Array = []
	for line in body.split("\n"):
		if line.contains("\t"):
			if not prose.is_empty():
				highlighted = _append_once("\n".join(prose) + "\n", answer, highlighted)
				prose.clear()
			rows.append(line.split("\t"))
		else:
			if not rows.is_empty():
				highlighted = _append_rows(rows, answer, highlighted)
				rows.clear()
			prose.append(line)
	if not rows.is_empty():
		highlighted = _append_rows(rows, answer, highlighted)
	if not prose.is_empty():
		highlighted = _append_once("\n".join(prose), answer, highlighted)
	return highlighted

func _append_once(text: String, answer: String, already: bool) -> bool:
	if already:
		label.add_text(text)
		return true
	return append_answer_highlight(text, answer)

## NEC sub-header rows ("Copper / Aluminum", "Condition 1 / 2 / 3") leave out the
## row-label column, so a short row after the first is aligned to the right edge.
## The header band runs until the first full-width row.
func _append_rows(rows: Array, answer: String, already: bool) -> bool:
	var columns := 1
	for row in rows:
		columns = maxi(columns, (row as PackedStringArray).size())
	var header_rows := 1
	while header_rows < rows.size() and (rows[header_rows] as PackedStringArray).size() < columns:
		header_rows += 1
	if header_rows == rows.size():
		header_rows = 1
	label.push_table(columns)
	label.set_table_column_expand(0, true, 2)
	var highlighted := already
	for ri in rows.size():
		var row: PackedStringArray = rows[ri]
		var offset := 0 if ri == 0 else columns - row.size()
		for ci in columns:
			label.push_cell()
			label.set_cell_padding(Rect2(4, 1, 4, 1))
			label.set_cell_row_background_color(AppTheme.TABLE_ROW_ODD, AppTheme.TABLE_ROW_EVEN)
			var si := ci - offset
			var cell := row[si].strip_edges() if si >= 0 and si < row.size() else ""
			if ri < header_rows:
				label.push_color(AppTheme.SKY_400)
				label.add_text(cell)
				label.pop()
			else:
				highlighted = _append_once(cell, answer, highlighted)
			label.pop()
	label.pop()
	label.add_text("\n")
	return highlighted

## tip_short reads "<tip> Correct: B — <answer>. <note> Not A: <note> ...". When
## choice_notes lines up with the answers, render the tip sentence followed by one
## row per choice (correct first) instead of that single run-on paragraph.
## Returns true when the correct answer was shown.
func append_tip_rows(record: Dictionary, tip: String) -> bool:
	var notes = record.get("choice_notes", [])
	var answers: Array = record.get("answers", [])
	var ci := int(record.get("correct_index", -1))
	var cut := tip.find(" Correct: ")
	if not (notes is Array) or notes.size() != answers.size() or ci < 0 or ci >= answers.size() or cut <= 0:
		label.add_text(tip)
		return false
	label.add_text(tip.substr(0, cut))
	var row_order: Array[int] = [ci]
	for i in answers.size():
		if i != ci:
			row_order.append(i)
	for i in row_order:
		var is_correct := i == ci
		label.add_text("\n")
		label.push_bgcolor(AppTheme.EMERALD_700 if is_correct else AppTheme.WRONG_HIGHLIGHT_BG)
		label.push_color(AppTheme.WHITE if is_correct else AppTheme.ROSE_200)
		label.push_bold()
		label.add_text(" %s %s " % ["✓" if is_correct else "✗", QuizSession.ANSWER_LETTERS[i]])
		label.pop()
		label.pop()
		label.pop()
		label.push_color(AppTheme.GREEN_50 if is_correct else AppTheme.SLATE_300)
		if is_correct:
			label.push_bold()
		label.add_text("  " + str(answers[i]))
		if is_correct:
			label.pop()
		label.pop()
		var note := str(notes[i]).strip_edges()
		if note != "":
			label.push_color(AppTheme.EMERALD_200 if is_correct else AppTheme.SLATE_400)
			label.add_text("  —  " + note)
			label.pop()
	return true

static func echoes_any(line: String, others: Array) -> bool:
	# True when line adds nothing over already-displayed text (declutter filter).
	for other in others:
		var o := str(other).strip_edges()
		if o != "" and AudioExplanationGenerator._is_duplicate_text(line, o):
			return true
	return false

func append_heading(text: String, heading_color: Color = AppTheme.SKY_300) -> void:
	label.push_color(heading_color)
	label.push_bold()
	label.add_text(text)
	label.pop()
	label.pop()

## Shows the explanation for an answered record and keeps it, so the speech
## code can re-render with the spoken lesson line highlighted.
func show(record: Dictionary, correct_answer: String, table_answer_highlighted: bool) -> void:
	_record = record
	_correct_answer = correct_answer
	_table_highlighted = table_answer_highlighted
	active_teach_line = -1
	render()

func render() -> void:
	var record := _record
	var correct_answer := _correct_answer
	var table_answer_highlighted := _table_highlighted
	label.clear()
	var highlighted := table_answer_highlighted

	# Shared texts, read once: display filtering compares lesson lines against all of
	# these so no sentence prints twice on one screen.
	var source_text := str(record.get("reference_text", ""))
	var worked_text := str(record.get("worked", ""))
	var formula_text := str(record.get("formula", "")).strip_edges()
	var gist_text := str(record.get("gist", "")).strip_edges()

	# --- MEMORY TIP section (plain-English mnemonic, folded to two lines) ---
	# A plain tip is skipped when it merely requotes the gist or the provision. A tip
	# with per-choice rows never is: its notes often quote a short provision, which
	# made the echo filter hide every choice explanation.
	var tip := str(record.get("tip_short", "")).strip_edges()
	var tip_title := str(record.get("tip_title", "")).strip_edges()
	if tip == "":
		tip = str(record.get("info_tip", "")).strip_edges()
	var has_choice_rows := tip.find(" Correct: ") > 0
	if tip != "" and (has_choice_rows or not echoes_any(tip, [source_text, gist_text])):
		if tip_title != "":
			append_heading("MEMORY TIP — " + tip_title + "\n", AppTheme.AMBER_500)
		else:
			append_heading("MEMORY TIP\n", AppTheme.AMBER_500)
		highlighted = append_tip_rows(record, tip) or highlighted
		label.add_text("\n\n")

	# --- CODE PROVISION section (NEC statutory text) ---
	append_heading("CODE PROVISION\n", AppTheme.EMERALD_400)
	if source_text != "":
		var heading_end := source_text.find("\n")
		if heading_end >= 0:
			label.push_color(AppTheme.BLUE_300)
			label.push_bold()
			label.add_text(source_text.substr(0, heading_end + 1))
			label.pop()
			label.pop()
			var body := source_text.substr(heading_end + 1)
			if body.contains("\t"):
				highlighted = append_provision_with_tables(body, correct_answer) or highlighted
			else:
				highlighted = append_answer_highlight(body, correct_answer) or highlighted
		else:
			highlighted = append_answer_highlight(source_text, correct_answer) or highlighted
	else:
		label.add_text("No source excerpt has been added yet. Use the NEC reference above to review the provision.")

	# --- WHAT THE CODE SAYS (lesson lines with active-line highlight during TTS) ---
	# Same shared list the voice speaks (lesson_lines index == teach index), but the
	# panel skips anything already on screen: the "Answer D, ..." callout restates the
	# verdict line above, and rule/math lines that requote CODE PROVISION / WORKED /
	# FORMULA / TIP would print the same sentence twice. Skipped lines keep their
	# original li so the spoken highlight index still lands on the right line, and an
	# empty section is omitted entirely instead of echoing.
	var shared_lesson := AudioExplanationGenerator.lesson_lines(record, correct_answer)
	var lesson_echo_basis: Array = [correct_answer, source_text, worked_text, formula_text, gist_text]
	if tip != "":
		lesson_echo_basis.append(tip)
	var render_lesson: Array = []
	for li in shared_lesson.size():
		var ln := str(shared_lesson[li]).strip_edges()
		if ln == "" or echoes_any(ln, lesson_echo_basis):
			continue
		render_lesson.append([li, ln])
	if not render_lesson.is_empty():
		label.add_text("\n\n")
		append_heading("WHAT THE CODE SAYS\n", AppTheme.SKY_400)
		var first_row := true
		for pair in render_lesson:
			var li: int = pair[0]
			var ln: String = pair[1]
			if li == active_teach_line:
				# Amber highlight on the currently-spoken line
				if not first_row:
					label.add_text("\n")
				label.push_bgcolor(AppTheme.YELLOW_800)
				label.push_color(AppTheme.AMBER_100)
				label.push_bold()
				label.add_text(" ▶  " + ln + " ")
				label.pop()
				label.pop()
				label.pop()
			else:
				if not first_row:
					label.add_text("\n")
				if active_teach_line >= 0:
					label.push_color(Color(0.55, 0.60, 0.68, 1.0))
					highlighted = append_answer_highlight(ln, correct_answer) or highlighted
					label.pop()
				else:
					highlighted = append_answer_highlight(ln, correct_answer) or highlighted
			first_row = false

	# --- Optional extra sections (texts hoisted above for echo filtering) ---
	var worked := worked_text
	var formula := formula_text
	if worked != "":
		label.add_text("\n\n")
		append_heading("WORKED SOLUTION\n", AppTheme.YELLOW_300)
		highlighted = append_answer_highlight(worked, correct_answer) or highlighted
	elif formula != "":
		label.add_text("\n\n")
		append_heading("METHOD & FORMULA\n", AppTheme.PURPLE_400)
		highlighted = append_answer_highlight(formula, correct_answer) or highlighted
	if not highlighted and correct_answer != "":
		label.add_text("\n\n")
		append_heading("ANSWER DETAIL\n", AppTheme.EMERALD_400)
		append_answer_highlight(correct_answer, correct_answer)
