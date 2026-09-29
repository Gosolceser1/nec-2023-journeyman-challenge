class_name MeterBar
extends Control
## A thin progress capsule for the menu tiles: fill (0..1) in its colour, and
## an optional tick (0..1, the pass mark).

var fraction := 0.0:
	set(v):
		fraction = clampf(v, 0.0, 1.0)
		queue_redraw()
var tick := -1.0:
	set(v):
		tick = v
		queue_redraw()
var color := AppTheme.SKY_400:
	set(v):
		color = v
		queue_redraw()
var _pill := StyleBoxFlat.new()


func _init(h: float = 6.0) -> void:
	custom_minimum_size = Vector2(0, h)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var h := size.y
	_capsule(0.0, size.x, h, Color(AppTheme.WHITE, 0.08))
	if fraction > 0.0:
		_capsule(0.0, maxf(size.x * fraction, h), h, color)
	if tick >= 0.0:
		var x := size.x * tick
		draw_line(Vector2(x, -2.0), Vector2(x, h + 2.0), Color(AppTheme.WHITE, 0.5), 1.0)


func _capsule(x0: float, x1: float, h: float, col: Color) -> void:
	_pill.bg_color = col
	_pill.set_corner_radius_all(int(h * 0.5))
	draw_style_box(_pill, Rect2(x0, 0.0, x1 - x0, h))
