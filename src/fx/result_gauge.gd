class_name ResultGauge
extends Control

## Results-screen score dial: sweeps from 0 to the final percentage with the
## number counting up, and marks the passing line on the arc.

const START_DEG := 150.0
const SWEEP_DEG := 240.0

var target_pct := 0.0
var pass_pct := 75.0
var _shown := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(220, 190)


func play(pct: float, pass_line: float) -> void:
	target_pct = clampf(pct, 0.0, 100.0)
	pass_pct = pass_line
	_shown = 0.0
	queue_redraw()
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.15)
	tw.tween_method(_set_shown, 0.0, target_pct, 1.3)


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
	draw_arc(c, r, a0, _angle(100.0), 64, Color(1, 1, 1, 0.08), 12.0, true)
	var col := tint_for(_shown, pass_pct)
	if _shown > 0.0:
		draw_arc(c, r, a0, _angle(_shown), 64, Color(col, 0.25), 20.0, true)
		draw_arc(c, r, a0, _angle(_shown), 64, col, 12.0, true)

	var pa := _angle(pass_pct)
	var dir := Vector2(cos(pa), sin(pa))
	draw_line(c + dir * (r - 12.0), c + dir * (r + 12.0), AppTheme.SLATE_50, 2.0, true)

	var font := get_theme_default_font()
	draw_string(font, Vector2(0, c.y + 8.0), "%d%%" % roundi(_shown), HORIZONTAL_ALIGNMENT_CENTER, size.x, 38, AppTheme.SLATE_50)
	var verdict := "PASS" if target_pct >= pass_pct else "BELOW %d%%" % roundi(pass_pct)
	var verdict_col := tint_for(target_pct, pass_pct) if is_equal_approx(_shown, target_pct) else AppTheme.SLATE_500
	draw_string(font, Vector2(0, c.y + 30.0), verdict, HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, verdict_col)
	var label_at := c + dir * (r + 22.0)
	draw_string(font, label_at + Vector2(-20, 4), "%d%%" % roundi(pass_pct), HORIZONTAL_ALIGNMENT_CENTER, 40, 10, AppTheme.SLATE_400)
