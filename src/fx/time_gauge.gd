class_name TimeGauge
extends Control

## Remaining-time indicator. RING draws a circular countdown (desktop header,
## sits beside the time text); EDGE draws a thin bar along the bottom of the
## badge it fills (mobile header, where badges are too narrow for a ring).

enum Mode { RING, EDGE }

var mode: Mode = Mode.RING
var fraction := 1.0
var color := Color("38bdf8")
var track_color := Color(1, 1, 1, 0.09)
var _pulse := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func set_value(value: float, tint: Color, urgent: bool = false) -> void:
	fraction = clampf(value, 0.0, 1.0)
	color = tint
	if urgent:
		_pulse = 1.0
		set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_pulse = maxf(0.0, _pulse - delta * 2.2)
	queue_redraw()
	if _pulse <= 0.0:
		set_process(false)


func _draw() -> void:
	if mode == Mode.RING:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 2.0
		if r <= 1.0:
			return
		draw_arc(c, r, 0.0, TAU, 48, track_color, 2.5, true)
		if fraction > 0.0:
			var start := -PI * 0.5
			var end := start + TAU * fraction
			draw_arc(c, r, start, end, 48, color, 2.5, true)
			draw_circle(c + Vector2(cos(end), sin(end)) * r, 2.2, color.lightened(0.35))
		if _pulse > 0.0:
			draw_arc(c, r + 3.0 * _pulse, 0.0, TAU, 48, Color(color, 0.5 * _pulse), 1.5, true)
	else:
		var y := size.y - 2.0
		var x0 := 6.0
		var x1 := size.x - 6.0
		if x1 <= x0:
			return
		draw_line(Vector2(x0, y), Vector2(x1, y), track_color, 2.0, true)
		if fraction > 0.0:
			var tip := x0 + (x1 - x0) * fraction
			draw_line(Vector2(x0, y), Vector2(tip, y), Color(color, 0.85 + 0.15 * _pulse), 2.0 + _pulse, true)
