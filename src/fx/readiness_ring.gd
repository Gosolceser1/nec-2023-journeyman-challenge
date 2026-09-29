class_name ReadinessRing
extends Control

## Menu hero dial: exam readiness (QuestionDeck.readiness) as a glowing ring
## with the percentage in tabular figures and a caption under it. Tinted by
## the pass line like the results gauge.

var fraction := 0.0
var caption := "READY"


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


func set_value(value: float) -> void:
	fraction = clampf(value, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var width := maxf(4.0, minf(size.x, size.y) * 0.08)
	var r := minf(size.x, size.y) * 0.5 - width
	if r <= 6.0:
		return
	draw_circle(c, r - width * 0.5, Color(AppTheme.SURFACE_BOTTOM, 0.9))
	draw_arc(c, r, 0.0, TAU, 64, Color(AppTheme.WHITE, 0.08), width, true)
	var col := ResultGauge.tint_for(fraction * 100.0, float(ExamBlueprint.pass_percent())) if fraction > 0.0 else AppTheme.SKY_400
	if fraction > 0.0:
		var a0 := -PI * 0.5
		var a1 := a0 + TAU * fraction
		draw_arc(c, r, a0, a1, 64, Color(col, 0.22), width * 2.2, true)
		draw_arc(c, r, a0, a1, 64, col, width, true)
	var big := int(r * 0.62)
	draw_string(AppTheme.numeric_font(), Vector2(0, c.y + big * 0.28), "%d%%" % roundi(fraction * 100.0),
		HORIZONTAL_ALIGNMENT_CENTER, size.x, big, AppTheme.SLATE_50)
	draw_string(AppTheme.meta_font(), Vector2(0, c.y + big * 0.28 + AppTheme.TYPE_MICRO + 2.0), caption,
		HORIZONTAL_ALIGNMENT_CENTER, size.x, AppTheme.TYPE_MICRO - 2, AppTheme.SLATE_400)
