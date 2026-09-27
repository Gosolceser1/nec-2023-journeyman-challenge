class_name FitController
extends RefCounted
## Keeps the question screen free of scrolling: steps fonts and card density
## down, trims the table, lookup path and figure, and after answering lets the
## explanation sheet give way first. Also switches the desktop answers row
## between side by side and stacked.

## Auto-fit steps for the unanswered screen, roomy -> dense. Answer text never
## goes below 15 px, the readable floor on a phone.
const FIT_QUESTION_MOBILE := [23, 21, 19, 18]
const FIT_QUESTION_DESKTOP := [22, 20, 18, 17]
const FIT_ANSWER := [17, 16, 15, 15]
const FIT_HINT_MOBILE := [15, 14, 14, 13]
const FIT_HINT_DESKTOP := [14, 13, 13, 12]
const FIT_TABLE_MIN_H := 64.0
const DIAGRAM_MAX_H_DESKTOP := 320.0
const DIAGRAM_MAX_H_MOBILE := 250.0
const FIT_DIAGRAM_MIN_H := 96.0
const SIDE_BY_SIDE_MIN_WIDTH := 1100.0

var host: Main
var _fit_gen := 0
var _fit_level := 0
var table_natural_h := 0.0

func _quiz_overflow() -> float:
	if not is_instance_valid(host.quiz_scroll_box) or host.quiz_scroll_box.get_child_count() == 0:
		return 0.0
	var content := host.quiz_scroll_box.get_child(0) as Control
	return content.get_combined_minimum_size().y - host.quiz_scroll_box.size.y

func _live_cards() -> Array:
	var out: Array = []
	for c in host.answers_box.get_children():
		if c is AnswerCard and not c.is_queued_for_deletion():
			out.append(c)
	return out

func apply_level(level: int) -> void:
	_fit_level = clampi(level, 0, FIT_ANSWER.size() - 1)
	var q_steps: Array = FIT_QUESTION_MOBILE if host.ui_mobile else FIT_QUESTION_DESKTOP
	var h_steps: Array = FIT_HINT_MOBILE if host.ui_mobile else FIT_HINT_DESKTOP
	host.question_label.add_theme_font_size_override("font_size", int(q_steps[_fit_level]))
	host.article_label.add_theme_font_size_override("font_size", int(h_steps[_fit_level]))
	for card in _live_cards():
		card.set_text_size(int(FIT_ANSWER[_fit_level]))
		card.set_density(1 if _fit_level >= 2 else 0)

## Restart the unanswered-screen fit: roomy first, then step down once the
## new cards have been laid out (they need a frame to get their width).
func begin() -> void:
	_fit_gen += 1
	apply_level(0)
	if host.question_table_panel.visible and table_natural_h > 0.0:
		host.question_table_scroll.custom_minimum_size.y = table_natural_h
	if is_instance_valid(host.question_diagram_view):
		host.question_diagram_view.max_height = DIAGRAM_MAX_H_MOBILE if host.ui_mobile else DIAGRAM_MAX_H_DESKTOP
	_fit_after_frames(_fit_gen, 2)

func _fit_after_frames(gen: int, frames: int) -> void:
	if gen != _fit_gen or not host.is_inside_tree():
		return
	if frames <= 0:
		_fit_run(gen)
		return
	var next := _fit_after_frames.bind(gen, frames - 1)
	if not host.get_tree().process_frame.is_connected(next):
		host.get_tree().process_frame.connect(next, CONNECT_ONE_SHOT)

func _fit_run(gen: int) -> void:
	if gen != _fit_gen or host.order.is_empty():
		return
	if host.current_answered:
		_fit_answered()
		return
	# Font and min-size changes re-measure synchronously at a fixed width, so
	# the whole step-down happens in this one call.
	var over := _quiz_overflow()
	while over > 0.5 and _fit_level < FIT_ANSWER.size() - 1:
		apply_level(_fit_level + 1)
		over = _quiz_overflow()
	if over > 0.5 and host.question_table_panel.visible:
		host.question_table_panel.custom_minimum_size.y = 0.0
		host.question_table_scroll.custom_minimum_size.y = maxf(FIT_TABLE_MIN_H, host.question_table_scroll.custom_minimum_size.y - over)
		over = _quiz_overflow()
	# The table heading already says where to look; the chapter path is the
	# expendable duplicate (kept when the heading had to be redacted).
	if over > 0.5 and host.question_table_panel.visible and host.lookup_box.visible \
			and not host.question_table_heading.text.ends_with("REFERENCE TABLE"):
		host.chapter_hint_label.visible = false
		host.lookup_box.visible = false
		over = _quiz_overflow()
	if over > 0.5 and host.question_diagram_panel.visible:
		_shrink_diagram(over)
func _shrink_diagram(over: float) -> void:
	var cur := host.question_diagram_view.custom_minimum_size.y
	host.question_diagram_view.max_height = maxf(FIT_DIAGRAM_MIN_H, cur - over)

func refresh_ref_column() -> void:
	if not is_instance_valid(host.ref_column):
		return
	host.ref_column.visible = host.question_table_panel.visible or host.question_diagram_panel.visible or host.formula_box.visible

func side_by_side() -> bool:
	return is_instance_valid(host.answers_row) and host.get_viewport().get_visible_rect().size.x >= SIDE_BY_SIDE_MIN_WIDTH

func apply_answers_row_layout() -> void:
	if not is_instance_valid(host.answers_row):
		return
	var wide := side_by_side()
	host.answers_row.vertical = not wide
	# Stacked, the lookup material reads first, like the book open above the sheet.
	host.answers_row.move_child(host.ref_column, 1 if wide else 0)

func on_viewport_resized() -> void:
	apply_answers_row_layout()
	if host.order.is_empty():
		return
	if not host.current_answered:
		begin()
	elif is_instance_valid(host.feedback_scroll) and host.feedback_scroll.visible:
		# Answered: give the sheet its preferred height back, then let
		# _fit_answered shrink it again for the new size.
		host.feedback_scroll.custom_minimum_size.y = feedback_min_h()
		_fit_gen += 1
		_fit_after_frames(_fit_gen, 2)

## After answering, drop what only mattered while choosing: the eliminated
## cards (their notes are in the explanation), session pills, gist, lookup
## path and item bar. What remains is the question, the verdict cards and the
## explanation sheet.
func compact_answered(correct: int, selected: int) -> void:
	var cards := host.answers_box.get_children()
	for i in cards.size():
		if i != correct and i != selected:
			(cards[i] as Control).visible = false
	host.exam_pills_row.visible = false
	if is_instance_valid(host.question_hint_row):
		host.question_hint_row.visible = false
	host.chapter_hint_label.visible = false
	host.lookup_box.visible = false
	host.timer_bar.visible = false
	refresh_ref_column()
	host.feedback_scroll.visible = true
	host.feedback_scroll.scroll_vertical = 0
	host.feedback_scroll.custom_minimum_size.y = feedback_min_h()
	_fit_gen += 1
	_fit_after_frames(_fit_gen, 2)

func feedback_min_h() -> float:
	return 150.0 if host.ui_mobile else 170.0

## Answered-state fit: a long stem can leave less than the sheet's preferred
## height; let the sheet give way (it scrolls inside), then the type steps
## down, before the page scrolls.
func _fit_answered() -> void:
	var over := _quiz_overflow()
	if over > 0.5:
		host.feedback_scroll.custom_minimum_size.y = maxf(84.0, host.feedback_scroll.custom_minimum_size.y - over)
		over = _quiz_overflow()
	while over > 0.5 and _fit_level < FIT_ANSWER.size() - 1:
		apply_level(_fit_level + 1)
		over = _quiz_overflow()
	if over > 0.5 and host.question_diagram_panel.visible:
		_shrink_diagram(over)
