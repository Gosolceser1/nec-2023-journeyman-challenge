class_name StreakMeter
extends Control

## "Voltage meter" for consecutive correct answers: a bolt plus rising bars
## that charge one step per correct answer and drain on a miss.

const SEGMENTS := 8

var streak := 0
var _shown := 0.0
var _flash := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(118, 16)
	set_process(false)


func set_streak(value: int) -> void:
	if value > streak:
		_flash = 1.0
	streak = maxi(value, 0)
	set_process(true)


func _process(delta: float) -> void:
	_shown = move_toward(_shown, float(mini(streak, SEGMENTS)), delta * 14.0)
	_flash = maxf(0.0, _flash - delta * 2.0)
	queue_redraw()
	if is_equal_approx(_shown, float(mini(streak, SEGMENTS))) and _flash <= 0.0:
		set_process(false)


static func segment_color(i: int) -> Color:
	var t := float(i) / float(SEGMENTS - 1)
	if t < 0.5:
		return AppTheme.SKY_400.lerp(AppTheme.EMERALD_400, t * 2.0)
	return AppTheme.EMERALD_400.lerp(AppTheme.AMBER_400, (t - 0.5) * 2.0)


func _draw() -> void:
	var h := size.y
	var charged := streak > 0
	var bolt_col := AppTheme.AMBER_400 if charged else AppTheme.SLATE_700
	if _flash > 0.0:
		bolt_col = bolt_col.lerp(Color.WHITE, _flash * 0.7)
	draw_colored_polygon(UiFx.bolt_points(Vector2(6, h * 0.5), h * 0.95), bolt_col)

	var x := 16.0
	var bar_w := 5.0
	var gap := 3.0
	for i in SEGMENTS:
		var bar_h := lerpf(h * 0.35, h, float(i) / float(SEGMENTS - 1))
		var rect := Rect2(x, h - bar_h, bar_w, bar_h)
		var lit := clampf(_shown - float(i), 0.0, 1.0)
		draw_rect(rect, Color(1, 1, 1, 0.07))
		if lit > 0.0:
			var col := segment_color(i)
			if streak >= SEGMENTS:
				col = col.lerp(Color.WHITE, 0.25 + 0.25 * _flash)
			draw_rect(Rect2(x, h - bar_h * lit, bar_w, bar_h * lit), col)
		x += bar_w + gap

	if streak >= 2:
		var font := get_theme_default_font()
		var label := "x%d" % streak
		draw_string(font, Vector2(x + 3.0, h - 3.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
			AppTheme.AMBER_200.lerp(Color.WHITE, _flash))
