class_name ProgressSegments
extends Control

## Question progress as one thin segment per question: green = right, red =
## missed, cyan = reviewed (Listen) or the current question, dim = ahead.
## Drawing only; the height is fixed, so it never moves the layout.

enum Outcome { AHEAD, CURRENT, RIGHT, WRONG, REVIEWED }

const BAR_H := 4.0

var outcomes: Array[int] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(120, 16)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


## One Outcome per question.
func set_progress(new_outcomes: Array[int]) -> void:
	outcomes = new_outcomes
	queue_redraw()


## Outcomes from the session: missed items are 1-based "index" entries of
## missed_questions; everything answered before the current item and not
## missed was right. Listen mode grades nothing, so answered = reviewed.
static func outcomes_for(total: int, current: int, answered_current: bool, missed: Array, graded: bool) -> Array[int]:
	var wrong := {}
	for item in missed:
		wrong[int(item.get("index", 0)) - 1] = true
	var out: Array[int] = []
	for i in total:
		var done := i < current or (i == current and answered_current)
		if not done:
			out.append(Outcome.CURRENT if i == current else Outcome.AHEAD)
		elif not graded:
			out.append(Outcome.REVIEWED)
		else:
			out.append(Outcome.WRONG if wrong.has(i) else Outcome.RIGHT)
	return out


static func outcome_color(outcome: int) -> Color:
	match outcome:
		Outcome.RIGHT:
			return AppTheme.EMERALD_400
		Outcome.WRONG:
			return AppTheme.RED_400
		Outcome.CURRENT:
			return AppTheme.SKY_400
		Outcome.REVIEWED:
			return AppTheme.SKY_600
	return Color(AppTheme.WHITE, 0.10)


func _draw() -> void:
	var n := outcomes.size()
	var bar_w := size.x
	if n == 0 or bar_w <= 8.0:
		return
	var gap := 3.0 if n <= 20 else (2.0 if n <= 50 else 1.0)
	var seg := (bar_w - gap * float(n - 1)) / float(n)
	var y := (size.y - BAR_H) * 0.5
	for i in n:
		var col := outcome_color(outcomes[i])
		var rect := Rect2(float(i) * (seg + gap), y, maxf(seg, 1.0), BAR_H)
		if outcomes[i] == Outcome.CURRENT:
			draw_rect(rect.grow(1.5), Color(col, 0.25))
		draw_rect(rect, col)
