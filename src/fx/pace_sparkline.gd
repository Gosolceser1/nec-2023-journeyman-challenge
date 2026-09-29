class_name PaceSparkline
extends Control

## Results-screen pace: seconds per answer as a sparkline against the exam's
## 3:00 per item (dashed line). Points over the line are amber, the rest cyan.

const PAD := 6.0

## [[question number, seconds], ...] (QuizSession.answer_seconds).
var points: Array = []
var limit := float(ExamBlueprint.seconds_per_item())


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(160, 64)


func set_points(answer_seconds: Array) -> void:
	points = answer_seconds
	visible = points.size() >= 2
	queue_redraw()


func _draw() -> void:
	var font := AppTheme.meta_font()
	draw_string(font, Vector2(0, AppTheme.TYPE_MICRO), "PACE PER ANSWER", HORIZONTAL_ALIGNMENT_LEFT, size.x, AppTheme.TYPE_MICRO - 1, AppTheme.SLATE_400)
	var top := AppTheme.TYPE_MICRO + PAD
	var h := size.y - top - PAD
	var w := size.x - 44.0
	if points.size() < 2 or h <= 8.0 or w <= 20.0:
		return
	var peak := limit * 1.5
	for p in points:
		peak = maxf(peak, float(p[1]))
	var line_y := top + h * (1.0 - limit / peak)
	var x := 0.0
	while x < w:
		draw_line(Vector2(x, line_y), Vector2(minf(x + 4.0, w), line_y), Color(AppTheme.WHITE, 0.25), 1.0)
		x += 8.0
	draw_string(AppTheme.numeric_font(), Vector2(w + 6.0, line_y + 4.0), ResultsView.clock_text(limit),
		HORIZONTAL_ALIGNMENT_LEFT, 40.0, AppTheme.TYPE_MICRO, AppTheme.SLATE_400)
	var pts := PackedVector2Array()
	for i in points.size():
		pts.append(Vector2(w * float(i) / float(points.size() - 1), top + h * (1.0 - float(points[i][1]) / peak)))
	draw_polyline(pts, Color(AppTheme.SKY_400, 0.25), 4.0, true)
	draw_polyline(pts, AppTheme.SKY_400, 1.5, true)
	for i in pts.size():
		var slow := float(points[i][1]) > limit
		draw_circle(pts[i], 2.5 if slow else 2.0, AppTheme.AMBER_400 if slow else AppTheme.SKY_300)
