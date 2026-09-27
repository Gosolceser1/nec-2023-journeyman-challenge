class_name AnswerCard
extends PanelContainer

signal card_clicked(index: int)

enum State { NORMAL, HOVER, PRESSED, CORRECT, WRONG, ELIMINATED }

var option_index: int = 0
var current_state: State = State.NORMAL
var is_disabled: bool = false

# Internal visual nodes
var letter_panel: PanelContainer
var letter_label: Label
var answer_label: Label
var state_overlay: ColorRect
var vector_state_icon: Control
var accent_bar: ColorRect
var voice_visualizer: VoiceVisualizer
var _margin: MarginContainer
## The learner's pick, set by main before grading: after grading its accent
## bar becomes the thicker energized bus bar (right or wrong).
var chosen := false

const LUG_SIZE := 34
## Recessed look of the letter lug: the chip's fill darkens toward its top.
const LUG_GRADIENT := [AppTheme.SURFACE_BOTTOM, AppTheme.LUG_BG]

func _init() -> void:
	custom_minimum_size = Vector2(0, 56)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# PASS (not STOP): the card still receives its own input, but drags propagate
	# up to the ScrollContainer — STOP grabs the whole touch gesture and kills
	# scroll-from-card on touch screens.
	mouse_filter = Control.MOUSE_FILTER_PASS
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# State Overlay (for background tint / glow flash)
	state_overlay = ColorRect.new()
	state_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	state_overlay.color = Color.TRANSPARENT
	add_child(state_overlay)

	_margin = MarginContainer.new()
	_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_margin.add_theme_constant_override("margin_left", AppTheme.SPACE_MD)
	_margin.add_theme_constant_override("margin_right", AppTheme.SPACE_MD)
	add_child(_margin)

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", AppTheme.SPACE_MD)
	_margin.add_child(hbox)

	# Accent bar: always BUS_BAR_W wide in the layout, drawn at ACCENT_BAR_W
	# (scale.x) until it becomes the chosen card's bus bar.
	accent_bar = ColorRect.new()
	accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	accent_bar.custom_minimum_size = Vector2(AppTheme.BUS_BAR_W, 28)
	accent_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	accent_bar.color = AppTheme.SKY_400
	accent_bar.resized.connect(func(): accent_bar.pivot_offset = Vector2(0.0, accent_bar.size.y * 0.5))
	hbox.add_child(accent_bar)

	# Letter lug (A, B, C, D): a recessed terminal chip.
	letter_panel = PanelContainer.new()
	letter_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	letter_panel.custom_minimum_size = Vector2(LUG_SIZE, LUG_SIZE)
	letter_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	letter_panel.resized.connect(func(): letter_panel.pivot_offset = letter_panel.size * 0.5)
	var pill_style := AppTheme.panel_style(AppTheme.LUG_BG, AppTheme.LUG_RIM, AppTheme.BORDER_HAIRLINE, AppTheme.RADIUS_INNER)
	letter_panel.add_theme_stylebox_override("panel", pill_style)
	UiFx.add_glass(letter_panel, LUG_GRADIENT, AppTheme.RADIUS_INNER, 0.0)
	hbox.add_child(letter_panel)

	letter_label = Label.new()
	letter_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	letter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	letter_label.add_theme_font_override("font", AppTheme.ui_font(AppTheme.WEIGHT_BOLD))
	letter_label.add_theme_font_size_override("font_size", AppTheme.TYPE_BODY_LG - 1)
	letter_label.add_theme_color_override("font_color", AppTheme.WHITE)
	letter_panel.add_child(letter_label)

	# Answer Text Label
	answer_label = Label.new()
	answer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	answer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	answer_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	answer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	answer_label.add_theme_font_override("font", AppTheme.ui_font(AppTheme.WEIGHT_MEDIUM))
	answer_label.add_theme_font_size_override("font_size", AppTheme.TYPE_BODY_LG)
	answer_label.add_theme_color_override("font_color", AppTheme.WHITE)
	hbox.add_child(answer_label)

	# Audio voice visualizer bars (shown when card is being read)
	voice_visualizer = VoiceVisualizer.new()
	voice_visualizer.bar_count = 4
	voice_visualizer.bar_width = 3.0
	voice_visualizer.bar_gap = 2.5
	voice_visualizer.custom_minimum_size = Vector2(24, 20)
	voice_visualizer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	voice_visualizer.visible = false
	hbox.add_child(voice_visualizer)

	# Vector State Icon (Drawn dynamically, NO EMOJI)
	vector_state_icon = Control.new()
	vector_state_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vector_state_icon.custom_minimum_size = Vector2(24, 24)
	vector_state_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vector_state_icon.draw.connect(_draw_state_icon)
	hbox.add_child(vector_state_icon)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	gui_input.connect(_on_gui_input)

	UiFx.add_glass(self)
	set_density(0)
	_apply_styling()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PARENTED:
		var box := get_parent() as Container
		if box != null and not box.sort_children.is_connected(_reapply_lift):
			box.sort_children.connect(_reapply_lift)

# Hover/focus lift: a y offset on top of wherever the answers box placed the
# card, so the fitted layout never moves. The box resets positions whenever
# it sorts, so the offset is put back after every sort.
var _lift := 0.0
var _lift_tween: Tween

func _set_lift(v: float) -> void:
	position.y += v - _lift
	_lift = v

func _reapply_lift() -> void:
	if _lift != 0.0:
		position.y += _lift

func _lift_to(target: float) -> void:
	if _lift_tween != null and _lift_tween.is_valid():
		_lift_tween.kill()
	if UiFx.reduce_motion or not is_inside_tree():
		_set_lift(target)
		return
	_lift_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_lift_tween.tween_method(_set_lift, _lift, target, AppTheme.MOTION_FAST)

## Press pulse on the letter lug.
func _pulse_lug() -> void:
	if UiFx.reduce_motion:
		return
	var tw := letter_panel.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	letter_panel.scale = Vector2(0.86, 0.86)
	tw.tween_property(letter_panel, "scale", Vector2.ONE, 0.22)

## 0 = roomy, 1 = tight: vertical padding only; the tap target stays >= 48 px.
func set_density(level: int) -> void:
	var pad := 7 if level <= 0 else 3
	_margin.add_theme_constant_override("margin_top", pad)
	_margin.add_theme_constant_override("margin_bottom", pad)

func set_text_size(px: int) -> void:
	answer_label.add_theme_font_size_override("font_size", px)

func set_card_data(idx: int, option_text: String) -> void:
	option_index = idx
	letter_label.text = char(65 + idx)
	answer_label.text = option_text
	set_state(State.NORMAL)

## Style only: the verdict motion is celebrate() / reject() / reveal_right(),
## started by QuizFx after grading, so a synchronous caller sees the final look.
func set_state(state: State) -> void:
	current_state = state
	if state == State.CORRECT or state == State.WRONG or state == State.ELIMINATED:
		_touch_press_index = -1
		if _lift_tween != null and _lift_tween.is_valid():
			_lift_tween.kill()
		_set_lift(0.0)
	_apply_styling()
	vector_state_icon.queue_redraw()

# Verdict animation, electrical theme (docs/SFX_PLAN.md has the timings):
#   right: the check draws itself as a hot cyan trace with an electron at its
#          head, a solder pad pulses at the tip, then current runs once around
#          the card's border and the card settles in its normal CORRECT look.
#   wrong: the two strokes of the X cross like a short circuit with a spark at
#          the crossing, the X flickers once like a failing tube, and the card
#          glitches sideways; then the right card gets the same current, softer.
# Everything is scale, a stylebox tween, the card shader or the icon's own
# drawing, never size, so the fitted layout cannot change. The glitch moves
# position.x absolutely: cards sit at x = 0 in the answers VBox, so a mid-shake
# re-sort cannot leave an offset. All of it settles within ~0.6 s.
var icon_progress := 1.0:
	set(v):
		icon_progress = v
		vector_state_icon.queue_redraw()
## 1 = drawn hot (cyan trace / white-hot X), 0 = the settled state colour.
var icon_heat := 0.0:
	set(v):
		icon_heat = v
		vector_state_icon.queue_redraw()
## Solder-pad pulse at the tip of the check, 0..1 (0 = not drawn).
var icon_pad := 0.0:
	set(v):
		icon_pad = v
		vector_state_icon.queue_redraw()
## Spark pop where the strokes of the X cross, 0..1 (0 = not drawn).
var icon_pop := 0.0:
	set(v):
		icon_pop = v
		vector_state_icon.queue_redraw()
## Opacity of the X while it flickers; 1 when settled.
var icon_flicker := 1.0:
	set(v):
		icon_flicker = v
		vector_state_icon.queue_redraw()
var _verdict_tweens: Array[Tween] = []

const TRACE_CYAN := AppTheme.SKY_300
const GLITCH_PX: Array[float] = [5.0, -4.0, 3.0, -3.0, 1.5, 0.0]

## The pick was right. strength 1.0 = first correct, up to ~1.4 on a streak.
## pitch is the correct cue's streak pitch_scale: the timing follows the sound
## (correct.wav: G5 tine at 30 ms, C6 + sparkle at ~95 ms, scaled by 1/pitch),
## so the electron passes the check's corner on the first note and reaches the
## tip on the second. calm (reduce motion): only the final state.
func celebrate(strength: float = 1.0, calm: bool = false, pitch: float = 1.0) -> void:
	_stop_verdict()
	if calm:
		return
	_energize_bus()
	var land := 0.1 / maxf(pitch, 0.5)
	_flash_style(Color(AppTheme.EMERALD_400, 0.35), AppTheme.SKY_300, int(14 + 6 * strength), Color(AppTheme.SKY_400, 0.45), 0.45)
	pivot_offset = size / 2.0
	var peak := 1.0 + 0.03 * strength
	var punch := _verdict_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	punch.tween_interval(land)
	punch.tween_property(self, "scale", Vector2(peak, peak), 0.06)
	punch.tween_property(self, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK)
	icon_progress = 0.0
	icon_heat = 1.0
	var icon := _verdict_tween()
	icon.tween_property(self, "icon_progress", 1.0, land)
	icon.tween_property(self, "icon_pad", 1.0, 0.24).from(0.001).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	icon.parallel().tween_property(self, "icon_heat", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	icon.tween_callback(func(): icon_pad = 0.0)
	# Spark positions are read inside callbacks: the icon only turns visible in
	# the grading frame and has no settled position until the container sorts.
	var sparks := _verdict_tween()
	sparks.tween_callback(func(): UiFx.trail_sparks(self, _icon_path(), land, TRACE_CYAN, roundi(8 * strength)))
	sparks.tween_interval(land)
	sparks.tween_callback(func(): UiFx.card_burst(self, _icon_path()[-1], TRACE_CYAN, roundi(8 * strength), 0.55))
	_run_current(land, 0.36, 0.9 + 0.25 * (strength - 1.0) / 0.4)

## The pick was wrong: the X shorts out on the breaker thunk at the start of
## wrong.wav (spark pop where the strokes cross), flickers, the card glitches.
func reject(calm: bool = false) -> void:
	_stop_verdict()
	if calm:
		return
	_energize_bus()
	var muted_red := AppTheme.ROSE_400.lerp(AppTheme.SLATE_500, 0.35)
	_flash_style(Color(muted_red, 0.4), AppTheme.RED_300, 16, Color(AppTheme.RED_400, 0.4), 0.4)
	icon_progress = 0.0
	icon_heat = 1.0
	var icon := _verdict_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	icon.tween_property(self, "icon_progress", 1.0, 0.06)
	icon.parallel().tween_property(self, "icon_pop", 1.0, 0.22).from(0.001).set_delay(0.015)
	icon.parallel().tween_property(self, "icon_heat", 0.0, 0.26).set_delay(0.06)
	icon.tween_callback(func(): icon_pop = 0.0)
	# Two dips 0.33 s apart (under 3 Hz) on a small, low-contrast glyph, so it
	# stays well inside photosensitivity limits.
	var flicker := _verdict_tween()
	flicker.tween_interval(0.16)
	flicker.tween_property(self, "icon_flicker", 0.55, 0.04)
	flicker.tween_property(self, "icon_flicker", 1.0, 0.05)
	flicker.tween_interval(0.24)
	flicker.tween_property(self, "icon_flicker", 0.75, 0.04)
	flicker.tween_property(self, "icon_flicker", 1.0, 0.04)
	var pop := _verdict_tween()
	pop.tween_interval(0.015)
	pop.tween_callback(func(): UiFx.card_burst(self, _to_card(PackedVector2Array([vector_state_icon.size / 2.0]))[0], AppTheme.AMBER_200, 10, 0.6))
	var glitch := _verdict_tween()
	glitch.tween_interval(0.01)
	glitch.tween_method(_glitch_at, 0.0, 1.0, 0.2)

## The right answer after a miss or a timeout, never before: after `delay` the
## check draws in as a trace and a softer current runs around the border.
func reveal_right(delay: float = 0.2, calm: bool = false) -> void:
	_stop_verdict()
	if calm:
		return
	icon_progress = 0.0
	icon_heat = 1.0
	var icon := _verdict_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	icon.tween_interval(delay)
	icon.tween_property(self, "icon_progress", 1.0, 0.12)
	icon.tween_property(self, "icon_heat", 0.0, 0.2)
	_run_current(delay, 0.36, 0.55)

## The chosen card's bus bar charges up: an over-bright flash that settles.
func _energize_bus() -> void:
	if not chosen:
		return
	accent_bar.modulate = Color(2.2, 2.2, 2.2)
	var tw := _verdict_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(accent_bar, "modulate", Color.WHITE, 0.5)

## Current runs once around the border via the surface shader (UiFx.add_glass).
func _run_current(delay: float, duration: float, power: float) -> void:
	_verdict_tweens.append(UiFx.run_current(self, delay, duration, power))

func _verdict_tween() -> Tween:
	var tw := create_tween()
	_verdict_tweens.append(tw)
	return tw

## Snaps any running verdict animation to its settled look.
func _stop_verdict() -> void:
	for tw in _verdict_tweens:
		if tw.is_valid():
			tw.kill()
	_verdict_tweens.clear()
	scale = Vector2.ONE
	modulate.a = 1.0
	UiFx.slide_x(self, 0.0, 0.0)
	accent_bar.modulate = Color.WHITE
	icon_progress = 1.0
	icon_heat = 0.0
	icon_pad = 0.0
	icon_pop = 0.0
	icon_flicker = 1.0
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter("current_pos", -1.0)
	_apply_styling()

## Flashes the card's stylebox from the given colours back to its state style,
## then puts the state style itself back so the settled frame is unchanged.
func _flash_style(bg: Color, border: Color, shadow_size_peak: int, shadow: Color, duration: float) -> void:
	var base := get_theme_stylebox("panel") as StyleBoxFlat
	if base == null:
		return
	var fx := base.duplicate() as StyleBoxFlat
	fx.bg_color = base.bg_color.blend(bg)
	fx.border_color = border
	fx.shadow_size = shadow_size_peak
	fx.shadow_color = shadow
	add_theme_stylebox_override("panel", fx)
	var tw := _verdict_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(fx, "bg_color", base.bg_color, duration * 0.7)
	tw.tween_property(fx, "border_color", base.border_color, duration * 0.7)
	tw.tween_property(fx, "shadow_size", base.shadow_size, duration)
	tw.tween_property(fx, "shadow_color", base.shadow_color, duration)
	tw.chain().tween_callback(_restore_style.bind(fx, base))

func _restore_style(fx: StyleBoxFlat, base: StyleBoxFlat) -> void:
	if get_theme_stylebox("panel") == fx:
		add_theme_stylebox_override("panel", base)

## The check's stroke in this card's local space.
func _icon_path() -> PackedVector2Array:
	return _to_card(_check_points(vector_state_icon.size))

## Icon-local points -> this card's local space (for sparks parented to the card).
func _to_card(pts: PackedVector2Array) -> PackedVector2Array:
	var xf := get_global_transform().affine_inverse() * vector_state_icon.get_global_transform()
	return xf * pts

## Stepped sideways jumps, like a glitching signal (t runs 0 -> 1).
func _glitch_at(t: float) -> void:
	position.x = GLITCH_PX[mini(int(t * GLITCH_PX.size()), GLITCH_PX.size() - 1)]

func animate_entrance(delay: float = 0.0) -> void:
	modulate.a = 0.0
	pivot_offset = size / 2.0
	scale = Vector2(0.95, 0.95)
	var tw := _verdict_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(self, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(self, "scale", Vector2.ONE, 0.28)

var is_speaking := false

# Direct touch tracking (touch screens): finger index + press position + slop.
# Cards fire on mouse release (desktop) but touch releases are routinely stolen
# by the scroll container — so touch gets its own press/slop/release handling
# instead of relying on emulated mouse events.
var _touch_press_index: int = -1
var _touch_press_pos: Vector2 = Vector2.ZERO
var _mouse_press_pos: Vector2 = Vector2.ZERO
const TOUCH_SLOP_PX := 20.0

func cancel_press() -> void:
	# Called when a scroll starts under the finger: silently leave PRESSED.
	# The state must be reset too. This only cleared _touch_press_index and then
	# called _apply_styling(), which re-applies the PRESSED style and leaves
	# current_state == PRESSED - so a card whose release landed elsewhere kept
	# the pressed fill forever, looking stuck.
	if current_state == State.PRESSED:
		_touch_press_index = -1
		set_state(State.NORMAL)
		pivot_offset = size / 2.0
		var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "scale", Vector2.ONE, 0.15)
		UiFx.slide_x(self, 0.0, 0.15)

func set_speaking(on: bool) -> void:
	if is_disabled:
		return
	is_speaking = on
	if is_instance_valid(voice_visualizer):
		voice_visualizer.visible = on
		voice_visualizer.set_active(on)
	if on:
		# Dynamic speaking visual feedback: glowing cyan border, elevated card, and smooth bounce
		var style: StyleBoxFlat = get_theme_stylebox("panel")
		if style:
			style = style.duplicate()
			style.bg_color = AppTheme.CARD_SPEAKING_BG
			style.border_color = AppTheme.SKY_400
			style.set_border_width_all(AppTheme.BORDER_STRONG)
			AppTheme.elevate(style, AppTheme.ELEVATION_CARD + 2, AppTheme.GLOW_CYAN)
			add_theme_stylebox_override("panel", style)
		
		# Pill badge glows electric cyan
		var pill_style: StyleBoxFlat = letter_panel.get_theme_stylebox("panel")
		if pill_style:
			pill_style = pill_style.duplicate()
			pill_style.bg_color = AppTheme.SKY_600
			pill_style.border_color = AppTheme.SKY_400
			letter_panel.add_theme_stylebox_override("panel", pill_style)
		letter_label.add_theme_color_override("font_color", AppTheme.WHITE)

		# Animated gentle bounce
		pivot_offset = size / 2.0
		var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "scale", Vector2(1.025, 1.025), 0.12)
		UiFx.slide_x(self, 8.0)
	else:
		_apply_styling()
		pivot_offset = size / 2.0
		var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "scale", Vector2.ONE, 0.15)
		UiFx.slide_x(self, 0.0, 0.15)

func set_eliminated() -> void:
	is_disabled = true
	current_state = State.ELIMINATED
	_touch_press_index = -1
	_lift_to(0.0)
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	var tween: Tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.38, 0.22)
	_apply_styling()
	vector_state_icon.queue_redraw()

func _draw_state_icon() -> void:
	var s: Vector2 = vector_state_icon.size
	var ci := vector_state_icon
	match current_state:
		State.CORRECT:
			# Vector checkmark with a soft outer glow line; drawn hot cyan while
			# the trace animates, cooling to emerald (heat 0 is the settled look).
			var full := _check_points(s)
			var pts: PackedVector2Array = _partial_stroke(full, icon_progress)
			if pts.size() >= 2:
				var glow := Color(0.06, 0.72, 0.5, 0.35).lerp(Color(AppTheme.SKY_400, 0.5), icon_heat)
				ci.draw_polyline(pts, glow, 4.6 + 2.0 * icon_heat, true)
				ci.draw_polyline(pts, AppTheme.EMERALD_500.lerp(TRACE_CYAN, icon_heat), 2.6, true)
			if icon_heat > 0.0 and icon_progress > 0.0 and icon_progress < 1.0:
				var head: Vector2 = pts[-1]
				ci.draw_circle(head, 5.5, Color(AppTheme.SKY_300, 0.25))
				ci.draw_circle(head, 3.2, Color(AppTheme.SKY_100, 0.7))
				ci.draw_circle(head, 1.6, Color.WHITE)
			if icon_pad > 0.0 and icon_pad < 1.0:
				var tip: Vector2 = full[-1]
				var fade := 1.0 - icon_pad
				ci.draw_arc(tip, lerpf(2.5, 8.0, icon_pad), 0.0, TAU, 20, Color(AppTheme.SKY_300, 0.8 * fade), 1.5, true)
				ci.draw_circle(tip, 2.6, Color(AppTheme.SKY_100, fade))
		State.WRONG:
			# Vector cross with a soft outer glow line; both strokes draw at once
			# and cross like a short, flickering white-hot to red.
			var pad: float = 4.0
			var strokes := [
				_partial_stroke(PackedVector2Array([Vector2(pad, pad), Vector2(s.x - pad, s.y - pad)]), icon_progress),
				_partial_stroke(PackedVector2Array([Vector2(s.x - pad, pad), Vector2(pad, s.y - pad)]), icon_progress),
			]
			var glow := Color(0.93, 0.26, 0.26, 0.35)
			var core := AppTheme.RED_500.lerp(AppTheme.RED_300, icon_heat)
			glow.a *= icon_flicker
			core.a *= icon_flicker
			for stroke in strokes:
				if stroke.size() >= 2:
					ci.draw_line(stroke[0], stroke[1], glow, 4.6, true)
			for stroke in strokes:
				if stroke.size() >= 2:
					ci.draw_line(stroke[0], stroke[1], core, 2.6, true)
			if icon_pop > 0.0 and icon_pop < 1.0:
				var fade := 1.0 - icon_pop
				ci.draw_circle(s / 2.0, lerpf(3.0, 7.0, icon_pop), Color(AppTheme.AMBER_200, 0.55 * fade))
				ci.draw_circle(s / 2.0, lerpf(2.0, 0.5, icon_pop), Color(1, 1, 1, fade))
		_:
			pass

static func _check_points(s: Vector2) -> PackedVector2Array:
	return PackedVector2Array([Vector2(3, s.y * 0.52), Vector2(8, s.y * 0.78), Vector2(21, s.y * 0.22)])

## The first `t` (0..1) of a polyline, by length; all of it at t >= 1.
static func _partial_stroke(pts: PackedVector2Array, t: float) -> PackedVector2Array:
	if t >= 1.0:
		return pts
	var out := PackedVector2Array()
	if t <= 0.0:
		return out
	var total := 0.0
	for i in range(1, pts.size()):
		total += pts[i - 1].distance_to(pts[i])
	var left := total * t
	out.append(pts[0])
	for i in range(1, pts.size()):
		var seg := pts[i - 1].distance_to(pts[i])
		if left >= seg:
			out.append(pts[i])
			left -= seg
		else:
			out.append(pts[i - 1].lerp(pts[i], left / maxf(seg, 0.001)))
			break
	return out

## One StyleBox per state. Every state keeps the same content margins, so a
## state change (thicker border, glow) never changes the card's size.
func _apply_styling() -> void:
	pivot_offset = size / 2.0
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(AppTheme.RADIUS)
	AppTheme.pad(style, AppTheme.SPACE_MD, AppTheme.SPACE_XS + 2)

	var pill_style: StyleBoxFlat = letter_panel.get_theme_stylebox("panel")
	var bus := chosen and current_state in [State.CORRECT, State.WRONG]
	accent_bar.scale.x = 1.0 if bus else float(AppTheme.ACCENT_BAR_W) / float(AppTheme.BUS_BAR_W)
	accent_bar.size_flags_vertical = Control.SIZE_FILL if bus else Control.SIZE_SHRINK_CENTER

	# Unanswered cards all share one neutral look, so no choice looks
	# pre-answered green or red.
	match current_state:
		State.CORRECT:
			_state_style(style, AppTheme.CARD_CORRECT_BG, AppTheme.EMERALD_500, AppTheme.BORDER_STRONG, AppTheme.ELEVATION_CARD, AppTheme.GLOW_EMERALD)
			accent_bar.color = AppTheme.EMERALD_300 if bus else AppTheme.EMERALD_400
			pill_style.bg_color = AppTheme.EMERALD_500
			pill_style.border_color = AppTheme.EMERALD_300
			letter_label.add_theme_color_override("font_color", AppTheme.CARD_CORRECT_INK)
			answer_label.add_theme_color_override("font_color", AppTheme.GREEN_50)
		State.WRONG:
			_state_style(style, AppTheme.CARD_WRONG_BG, AppTheme.RED_500, AppTheme.BORDER_STRONG, AppTheme.ELEVATION_CARD, AppTheme.GLOW_RED)
			accent_bar.color = AppTheme.ROSE_400
			pill_style.bg_color = AppTheme.RED_500
			pill_style.border_color = AppTheme.RED_300
			letter_label.add_theme_color_override("font_color", AppTheme.CARD_WRONG_INK)
			answer_label.add_theme_color_override("font_color", AppTheme.ROSE_50)
		State.ELIMINATED:
			_state_style(style, AppTheme.CARD_ELIMINATED_BG, AppTheme.CARD_ELIMINATED_BORDER, AppTheme.BORDER_HAIRLINE, AppTheme.ELEVATION_FLAT)
			accent_bar.color = Color(AppTheme.SLATE_500, 0.2)
			pill_style.bg_color = AppTheme.GRAY_900
			pill_style.border_color = AppTheme.CARD_ELIMINATED_PILL_BORDER
			letter_label.add_theme_color_override("font_color", AppTheme.SLATE_600)
			answer_label.add_theme_color_override("font_color", AppTheme.SLATE_500)
		State.HOVER:
			_state_style(style, AppTheme.CARD_HOVER_BG, AppTheme.SKY_300, AppTheme.BORDER_STRONG, AppTheme.ELEVATION_CARD, AppTheme.GLOW_CYAN)
			accent_bar.color = AppTheme.SKY_300
			pill_style.bg_color = AppTheme.SKY_700
			pill_style.border_color = AppTheme.SKY_300
			letter_label.add_theme_color_override("font_color", AppTheme.WHITE)
			answer_label.add_theme_color_override("font_color", AppTheme.WHITE)
		State.PRESSED:
			_state_style(style, AppTheme.CARD_PRESSED_BG, AppTheme.SKY_500, AppTheme.BORDER_STRONG, AppTheme.ELEVATION_REST, AppTheme.GLOW_CYAN_SOFT)
			accent_bar.color = AppTheme.SKY_500
			pill_style.bg_color = AppTheme.SKY_800
			pill_style.border_color = AppTheme.SKY_400
			letter_label.add_theme_color_override("font_color", AppTheme.WHITE)
			answer_label.add_theme_color_override("font_color", AppTheme.WHITE)
		_: # NORMAL
			_state_style(style, AppTheme.SURFACE_BOTTOM, AppTheme.BUTTON_BORDER, AppTheme.BORDER_HAIRLINE, AppTheme.ELEVATION_REST)
			accent_bar.color = AppTheme.SKY_400
			pill_style.bg_color = AppTheme.LUG_BG
			pill_style.border_color = AppTheme.LUG_RIM
			letter_label.add_theme_color_override("font_color", AppTheme.WHITE)
			answer_label.add_theme_color_override("font_color", AppTheme.WHITE)

	add_theme_stylebox_override("panel", style)

static func _state_style(style: StyleBoxFlat, fill: Color, border: Color, width: int, elevation: int, glow: Color = Color.TRANSPARENT) -> void:
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	AppTheme.elevate(style, elevation, glow)

func _on_mouse_entered() -> void:
	if is_disabled or current_state in [State.CORRECT, State.WRONG, State.ELIMINATED]:
		return
	set_state(State.HOVER)
	_lift_to(-AppTheme.LIFT_PX)

func _on_mouse_exited() -> void:
	if is_disabled or current_state in [State.CORRECT, State.WRONG, State.ELIMINATED]:
		return
	set_state(State.NORMAL)
	_lift_to(0.0)

func _on_focus_entered() -> void:
	if is_disabled or current_state in [State.CORRECT, State.WRONG, State.ELIMINATED]:
		return
	set_state(State.HOVER)
	_lift_to(-AppTheme.LIFT_PX)

func _on_focus_exited() -> void:
	if is_disabled or current_state in [State.CORRECT, State.WRONG, State.ELIMINATED]:
		return
	set_state(State.NORMAL)
	_lift_to(0.0)

func _touch_release_counts(release_pos: Vector2) -> bool:
	if _touch_press_pos.distance_to(release_pos) > TOUCH_SLOP_PX:
		return false
	return Rect2(Vector2.ZERO, size).grow(TOUCH_SLOP_PX).has_point(release_pos)

func _on_gui_input(event: InputEvent) -> void:
	if is_disabled or current_state in [State.CORRECT, State.WRONG, State.ELIMINATED]:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if _touch_press_index < 0:
				_touch_press_index = event.index
				_touch_press_pos = event.position
				set_state(State.PRESSED)
				_pulse_lug()
				var tween: Tween = create_tween()
				tween.tween_property(self, "scale", Vector2(0.985, 0.985), 0.05)
		elif event.index == _touch_press_index:
			var tapped := _touch_release_counts(event.position)
			_touch_press_index = -1
			if tapped:
				set_state(State.HOVER)
				pivot_offset = size / 2.0
				var tw: Tween = create_tween()
				tw.tween_property(self, "scale", Vector2.ONE, 0.08)
				card_clicked.emit(option_index)
				accept_event()
			else:
				_apply_styling()
				pivot_offset = size / 2.0
				var tw2 := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tw2.tween_property(self, "scale", Vector2.ONE, 0.15)
				UiFx.slide_x(self, 0.0, 0.15)
		return
	if event is InputEventScreenDrag and event.index == _touch_press_index:
		if _touch_press_pos.distance_to(event.position) > TOUCH_SLOP_PX:
			cancel_press()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Defence in depth for the mouse/emulated path. project.godot now really
		# sets emulate_mouse_from_touch=false, so a real finger reaches the
		# ScreenTouch branch above (which HAS a slop check). But this branch used
		# to emit card_clicked unconditionally on release, so on a device where
		# emulation was on - which it was, because "#" comments silently broke
		# that project setting - dragging down the page to scroll committed an
		# answer. Track the press position and refuse a release that moved.
		if event.pressed:
			if _touch_press_index < 0:
				_mouse_press_pos = event.position
			set_state(State.PRESSED)
			_pulse_lug()
			var tween: Tween = create_tween()
			tween.tween_property(self, "scale", Vector2(0.985, 0.985), 0.05)
		else:
			var moved: float = _mouse_press_pos.distance_to(event.position)
			set_state(State.HOVER)
			var tween: Tween = create_tween()
			tween.tween_property(self, "scale", Vector2.ONE, 0.08)
			if moved > TOUCH_SLOP_PX:
				# A drag that ends here is a scroll, not a selection.
				accept_event()
				return
			card_clicked.emit(option_index)
	elif event.is_action_pressed("ui_accept"):
		accept_event()
		card_clicked.emit(option_index)
