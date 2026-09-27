class_name ProgressSegments
extends Control

## Question progress as one thin segment per question: green = right, red =
## missed, cyan = reviewed (Listen) or the current question, dim = ahead.
## The right end carries the streak (a bolt and "x3" from two in a row up).
## Drawing only; the height is fixed, so it never moves the layout.

enum Outcome { AHEAD, CURRENT, RIGHT, WRONG, REVIEWED }

const BAR_H := 4.0
const STREAK_W := 40.0

var outcomes: Array[int] = []
var streak := 0
var _flash := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(120, 16)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	set_process(false)


## One Outcome per question; `new_streak` > the old one flashes the bolt.
func set_progress(new_outcomes: Array[int], new_streak: int) -> void:
	if new_streak > streak and not UiFx.reduce_motion:
		_flash = 1.0
		set_process(true)
	outcomes = new_outcomes
	streak = maxi(new_streak, 0)
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


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * 2.0)
	queue_redraw()
	if _flash <= 0.0:
		set_process(false)


func _draw() -> void:
	var n := outcomes.size()
	var bar_w := size.x - STREAK_W
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

	var charged := streak >= 2
	var bolt_col := AppTheme.AMBER_400 if charged else AppTheme.SLATE_700
	if _flash > 0.0:
		bolt_col = bolt_col.lerp(Color.WHITE, _flash * 0.7)
	var bx := bar_w + 12.0
	draw_colored_polygon(UiFx.bolt_points(Vector2(bx, size.y * 0.5), size.y * 0.9), bolt_col)
	if charged:
		draw_string(AppTheme.numeric_font(), Vector2(bx + 7.0, size.y * 0.5 + 4.0), "x%d" % streak,
			HORIZONTAL_ALIGNMENT_LEFT, STREAK_W - 18.0, AppTheme.TYPE_MICRO, AppTheme.AMBER_200.lerp(Color.WHITE, _flash))
