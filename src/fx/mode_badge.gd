class_name ModeBadge
extends Control

## Right-edge badge on a menu mode button: a ring filled to question_count/80
## with the count in the middle, or a bolt for the full simulator. Hovering
## the button charges the ring to full (set_hover).

var question_count := 10
var full_exam := false
var accent := AppTheme.SKY_400
## 0 = resting fill, 1 = fully charged (hover).
var charge := 0.0:
	set(v):
		charge = v
		queue_redraw()
var _tween: Tween


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## charge_seconds: how long the ring takes to fill (the session-start press
## fills it faster, in step with the start cue).
func set_hover(on: bool, charge_seconds: float = 0.35) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if UiFx.reduce_motion:
		charge = 1.0 if on else 0.0
		return
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "charge", 1.0 if on else 0.0, charge_seconds if on else AppTheme.MOTION_FAST)


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 3.0
	if r <= 4.0:
		return
	draw_circle(c, r, Color(accent, 0.08 + 0.06 * charge))
	draw_arc(c, r, 0.0, TAU, 40, Color(1, 1, 1, 0.08), 3.0, true)
	var rest := 1.0 if full_exam else clampf(float(question_count) / 80.0, 0.0, 1.0)
	var frac := lerpf(rest, 1.0, charge)
	if charge > 0.0:
		draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * frac, 40, Color(accent, 0.25 * charge), 7.0, true)
	draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * frac, 40, accent, 3.0, true)
	if full_exam:
		draw_colored_polygon(UiFx.bolt_points(c, r * 1.1), accent)
	else:
		draw_string(AppTheme.numeric_font(), Vector2(0, c.y + 5.0), str(question_count), HORIZONTAL_ALIGNMENT_CENTER, size.x, AppTheme.TYPE_BODY_SM, AppTheme.SLATE_50)
