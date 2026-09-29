class_name ResultGauge
extends Control

## Results-screen score dial: sweeps from 0 to the final percentage with the
## number counting up, and marks the passing line on the arc. `landed` fires
## when the needle arrives, which is when the result sound and flourish play.

signal landed

const START_DEG := 150.0
const SWEEP_DEG := 240.0
const LAND_SECONDS := 1.15

var target_pct := 0.0
var pass_pct := float(ExamBlueprint.pass_percent())
var _shown := 0.0
var _tween: Tween


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(220, 190)


## instant: reduce motion, the dial shows the score at once and lands now.
func play(pct: float, pass_line: float, instant: bool = false) -> void:
	target_pct = clampf(pct, 0.0, 100.0)
	pass_pct = pass_line
	if _tween != null and _tween.is_valid():
		_tween.kill()
	scale = Vector2.ONE
	if instant or not is_inside_tree():
		_set_shown(target_pct)
		landed.emit()
		return
	_shown = 0.0
	queue_redraw()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(0.15)
	_tween.tween_method(_set_shown, 0.0, target_pct, LAND_SECONDS - 0.15)
	_tween.tween_callback(landed.emit)


## The needle's little bounce on a pass.
func punch() -> void:
	pivot_offset = size / 2.0
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(1.06, 1.06), 0.08)
	tw.tween_property(self, "scale", Vector2.ONE, 0.2)


func _set_shown(v: float) -> void:
	_shown = v
	queue_redraw()


static func tint_for(pct: float, pass_line: float) -> Color:
	if pct >= pass_line:
		return AppTheme.EMERALD_400
	if pct >= pass_line - 15.0:
		return AppTheme.AMBER_400
	return AppTheme.RED_400


func _angle(pct: float) -> float:
	return deg_to_rad(START_DEG + SWEEP_DEG * pct / 100.0)


func _draw() -> void:
	var c := Vector2(size.x * 0.5, size.y * 0.55)
	var r := minf(size.x * 0.5, size.y * 0.55) - 24.0
	if r <= 4.0:
		return
	var a0 := _angle(0.0)
	draw_arc(c, r, a0, _angle(100.0), 64, Color(AppTheme.WHITE, 0.08), 12.0, true)
	var col := tint_for(_shown, pass_pct)
	if _shown > 0.0:
		draw_arc(c, r, a0, _angle(_shown), 64, Color(col, 0.12), 28.0, true)
		draw_arc(c, r, a0, _angle(_shown), 64, Color(col, 0.25), 20.0, true)
		draw_arc(c, r, a0, _angle(_shown), 64, col, 12.0, true)

	var pa := _angle(pass_pct)
	var dir := Vector2(cos(pa), sin(pa))
	draw_line(c + dir * (r - 12.0), c + dir * (r + 12.0), AppTheme.SLATE_50, 2.0, true)

	var digits := AppTheme.numeric_font()
	var meta := AppTheme.meta_font()
	draw_string(digits, Vector2(0, c.y + 10.0), "%d%%" % roundi(_shown), HORIZONTAL_ALIGNMENT_CENTER, size.x, AppTheme.TYPE_DISPLAY, AppTheme.SLATE_50)
	var verdict := "PASS" if target_pct >= pass_pct else "BELOW %d%%" % roundi(pass_pct)
	var verdict_col := tint_for(target_pct, pass_pct) if is_equal_approx(_shown, target_pct) else AppTheme.SLATE_400
	draw_string(meta, Vector2(0, c.y + 32.0), verdict, HORIZONTAL_ALIGNMENT_CENTER, size.x, AppTheme.TYPE_CAPTION, verdict_col)
	var label_at := c + dir * (r + 22.0)
	draw_string(digits, label_at + Vector2(-20, 4), "%d%%" % roundi(pass_pct), HORIZONTAL_ALIGNMENT_CENTER, 40, AppTheme.TYPE_MICRO, AppTheme.SLATE_400)
