class_name VoiceVisualizer
extends Control

## VoiceVisualizer
## Draws real-time pulsing equalizer audio bars or wave lines.
## Responds dynamically to speech activity with smooth organic animation.

@export var bar_count: int = 5
@export var bar_width: float = 3.5
@export var bar_gap: float = 3.0
@export var active_color: Color = AppTheme.SKY_400       # Electric Sky Cyan
@export var secondary_color: Color = AppTheme.EMERALD_400    # Emerald highlight
@export var idle_color: Color = AppTheme.SLATE_700         # Subdued slate

var is_active: bool = false
var _anim_time: float = 0.0
var _current_levels: Array[float] = []
var _target_levels: Array[float] = []
var _noise_offsets: Array[float] = []

func _init() -> void:
	custom_minimum_size = Vector2(bar_count * bar_width + (bar_count - 1) * bar_gap + 4.0, 20.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_current_levels.resize(bar_count)
	_target_levels.resize(bar_count)
	_noise_offsets.resize(bar_count)
	for i in bar_count:
		_current_levels[i] = 0.15
		_target_levels[i] = 0.15
		_noise_offsets[i] = float(i) * 1.37

func _resync_bars() -> void:
	# bar_count is assigned AFTER _init() by callers (dock uses 6, cards/prompt use 4),
	# so lazily resize the level arrays. Without this the dock visualizer (bar_count=6
	# over arrays sized for 5) indexes out of bounds every frame and never animates.
	var old_size := _current_levels.size()
	if old_size == bar_count:
		return
	_current_levels.resize(bar_count)
	_target_levels.resize(bar_count)
	_noise_offsets.resize(bar_count)
	for i in range(old_size, bar_count):
		_current_levels[i] = 0.15
		_target_levels[i] = 0.15
		_noise_offsets[i] = float(i) * 1.37

func _process(delta: float) -> void:
	_resync_bars()
	_anim_time += delta * 6.5
	var needs_redraw := false

	for i in bar_count:
		if is_active:
			# Multi-sine synthesized audio waveform simulation:
			# Creates natural speech-cadence fluctuations across frequency bands
			var wave1 := sin(_anim_time * 1.8 + _noise_offsets[i])
			var wave2 := sin(_anim_time * 3.4 + _noise_offsets[i] * 2.1) * 0.4
			var wave3 := cos(_anim_time * 0.9 + float(i)) * 0.3
			var combined := (wave1 + wave2 + wave3 + 1.7) / 3.4
			_target_levels[i] = clampf(combined, 0.18, 1.0)
		else:
			# Gentle resting minimum line
			_target_levels[i] = 0.12

		var prev := _current_levels[i]
		_current_levels[i] = lerpf(_current_levels[i], _target_levels[i], clampf(delta * 14.0, 0.0, 1.0))
		if absf(_current_levels[i] - prev) > 0.005:
			needs_redraw = true

	if needs_redraw or is_active:
		queue_redraw()

func set_active(active: bool) -> void:
	if is_active != active:
		is_active = active
		queue_redraw()

func _draw() -> void:
	var total_w := float(bar_count) * bar_width + float(bar_count - 1) * bar_gap
	var start_x := (size.x - total_w) * 0.5
	var center_y := size.y * 0.5
	var max_half_h := (size.y * 0.5) - 1.5

	for i in bar_count:
		var lvl: float = _current_levels[i] if i < _current_levels.size() else 0.15
		var half_h := maxf(2.0, max_half_h * lvl)
		var bx := start_x + float(i) * (bar_width + bar_gap)
		var rect := Rect2(bx, center_y - half_h, bar_width, half_h * 2.0)
		
		# Dynamic gradient / color interpolation: Cyan to Emerald when active
		var col: Color
		if is_active:
			var t := float(i) / maxf(1.0, float(bar_count - 1))
			col = active_color.lerp(secondary_color, t * lvl)
		else:
			col = idle_color

		# Draw rounded bar
		draw_rect(rect, col, true, -1.0)
