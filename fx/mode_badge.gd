class_name ModeBadge
extends Control

## Right-edge badge on a menu mode button: a ring filled to question_count/80
## with the count in the middle, or a bolt for the full simulator.

var question_count := 10
var full_exam := false
var accent := Color("38bdf8")


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 3.0
	if r <= 4.0:
		return
	draw_circle(c, r, Color(accent, 0.08))
	draw_arc(c, r, 0.0, TAU, 40, Color(1, 1, 1, 0.08), 3.0, true)
	var frac := 1.0 if full_exam else clampf(float(question_count) / 80.0, 0.0, 1.0)
	draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * frac, 40, accent, 3.0, true)
	if full_exam:
		draw_colored_polygon(UiFx.bolt_points(c, r * 1.1), accent)
	else:
		var font := get_theme_default_font()
		draw_string(font, Vector2(0, c.y + 5.0), str(question_count), HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, Color("f8fafc"))
