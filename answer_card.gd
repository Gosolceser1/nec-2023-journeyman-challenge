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

static func _card_font(weight: int = 500) -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Segoe UI", "SF Pro Display", "Inter", "Roboto", "Helvetica Neue", "Arial", "sans-serif"])
	font.font_weight = weight
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	return font

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
	_margin.add_theme_constant_override("margin_left", 14)
	_margin.add_theme_constant_override("margin_right", 14)
	add_child(_margin)

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 14)
	_margin.add_child(hbox)

	# Left Accent Indicator Strip (4px)
	accent_bar = ColorRect.new()
	accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	accent_bar.custom_minimum_size = Vector2(4, 28)
	accent_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	accent_bar.color = Color("38bdf8")
	hbox.add_child(accent_bar)

	# Letter Pill (A, B, C, D)
	letter_panel = PanelContainer.new()
	letter_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	letter_panel.custom_minimum_size = Vector2(34, 34)
	letter_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pill_style := StyleBoxFlat.new()
	pill_style.bg_color = Color("142035")
	pill_style.border_color = Color("223659")
	pill_style.set_border_width_all(1)
	pill_style.set_corner_radius_all(10)
	letter_panel.add_theme_stylebox_override("panel", pill_style)
	hbox.add_child(letter_panel)

	letter_label = Label.new()
	letter_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	letter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	letter_label.add_theme_font_override("font", _card_font(700))
	letter_label.add_theme_font_size_override("font_size", 16)
	letter_label.add_theme_color_override("font_color", Color("ffffff"))
	letter_panel.add_child(letter_label)

	# Answer Text Label
	answer_label = Label.new()
	answer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	answer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	answer_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	answer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	answer_label.add_theme_font_override("font", _card_font(600))
	answer_label.add_theme_font_size_override("font_size", 17)
	answer_label.add_theme_color_override("font_color", Color("ffffff"))
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

	set_density(0)
	_apply_styling()

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

func set_state(state: State) -> void:
	current_state = state
	if state == State.CORRECT or state == State.WRONG or state == State.ELIMINATED:
		_touch_press_index = -1
	_apply_styling()
	vector_state_icon.queue_redraw()
	if state == State.CORRECT:
		pivot_offset = size / 2.0
		var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "scale", Vector2(1.035, 1.035), 0.14)
		tw.tween_property(self, "scale", Vector2.ONE, 0.18)
		# Pop icon with scale and rotation
		vector_state_icon.pivot_offset = vector_state_icon.size / 2.0
		vector_state_icon.scale = Vector2(0.3, 0.3)
		vector_state_icon.rotation_degrees = -20.0
		var ic_tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		ic_tw.parallel().tween_property(vector_state_icon, "scale", Vector2.ONE, 0.22)
		ic_tw.parallel().tween_property(vector_state_icon, "rotation_degrees", 0.0, 0.22)
	elif state == State.WRONG:
		pivot_offset = size / 2.0
		var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(self, "position:x", -8.0, 0.04).as_relative()
		tw.tween_property(self, "position:x", 16.0, 0.06).as_relative()
		tw.tween_property(self, "position:x", -12.0, 0.05).as_relative()
		tw.tween_property(self, "position:x", 4.0, 0.05).as_relative()
		# Pop icon
		vector_state_icon.pivot_offset = vector_state_icon.size / 2.0
		vector_state_icon.scale = Vector2(0.5, 0.5)
		var ic_tw := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		ic_tw.tween_property(vector_state_icon, "scale", Vector2.ONE, 0.26)

func animate_entrance(delay: float = 0.0) -> void:
	modulate.a = 0.0
	pivot_offset = size / 2.0
	scale = Vector2(0.95, 0.95)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
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
		tw.parallel().tween_property(self, "scale", Vector2.ONE, 0.15)
		tw.parallel().tween_property(self, "position:x", 0.0, 0.15)

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
			style.bg_color = Color("1a2942")
			style.border_color = Color("38bdf8")
			style.set_border_width_all(2)
			style.shadow_color = Color(0.22, 0.74, 0.97, 0.35)
			style.shadow_size = 12
			add_theme_stylebox_override("panel", style)
		
		# Pill badge glows electric cyan
		var pill_style: StyleBoxFlat = letter_panel.get_theme_stylebox("panel")
		if pill_style:
			pill_style = pill_style.duplicate()
			pill_style.bg_color = Color("0284c7")
			pill_style.border_color = Color("38bdf8")
			letter_panel.add_theme_stylebox_override("panel", pill_style)
		letter_label.add_theme_color_override("font_color", Color("ffffff"))

		# Animated gentle bounce
		pivot_offset = size / 2.0
		var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "scale", Vector2(1.025, 1.025), 0.12)
		tw.tween_property(self, "position:x", 8.0, 0.12).as_relative()
	else:
		_apply_styling()
		pivot_offset = size / 2.0
		var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(self, "scale", Vector2.ONE, 0.15)
		tw.parallel().tween_property(self, "position:x", 0.0, 0.15)

func set_eliminated() -> void:
	is_disabled = true
	current_state = State.ELIMINATED
	_touch_press_index = -1
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	var tween: Tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.38, 0.22)
	_apply_styling()
	vector_state_icon.queue_redraw()

func _draw_state_icon() -> void:
	var s: Vector2 = vector_state_icon.size
	match current_state:
		State.CORRECT:
			# Draw vector checkmark with soft outer glow line
			var pts: PackedVector2Array = PackedVector2Array([
				Vector2(3, s.y * 0.52),
				Vector2(8, s.y * 0.78),
				Vector2(21, s.y * 0.22)
			])
			vector_state_icon.draw_polyline(pts, Color(0.06, 0.72, 0.5, 0.35), 4.6, true)
			vector_state_icon.draw_polyline(pts, Color("10b981"), 2.6, true)
		State.WRONG:
			# Draw vector cross with soft outer glow line
			var pad: float = 4.0
			vector_state_icon.draw_line(Vector2(pad, pad), Vector2(s.x - pad, s.y - pad), Color(0.93, 0.26, 0.26, 0.35), 4.6, true)
			vector_state_icon.draw_line(Vector2(s.x - pad, pad), Vector2(pad, s.y - pad), Color(0.93, 0.26, 0.26, 0.35), 4.6, true)
			vector_state_icon.draw_line(Vector2(pad, pad), Vector2(s.x - pad, s.y - pad), Color("ef4444"), 2.6, true)
			vector_state_icon.draw_line(Vector2(s.x - pad, pad), Vector2(pad, s.y - pad), Color("ef4444"), 2.6, true)
		_:
			pass

func _apply_styling() -> void:
	pivot_offset = size / 2.0
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(14)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6

	var pill_style: StyleBoxFlat = letter_panel.get_theme_stylebox("panel")
	if not pill_style:
		pill_style = StyleBoxFlat.new()
		pill_style.set_corner_radius_all(9)
		letter_panel.add_theme_stylebox_override("panel", pill_style)

	# Clean, professional exam styling for choices:
	# Keep all cards in a uniform, crisp state so choices C & D don't look pre-answered as green/red.
	var card_accent := Color("38bdf8") # Clean cyan highlight on hover/focus

	match current_state:
		State.CORRECT:
			style.bg_color = Color("0d281e")
			style.border_color = Color("10b981")
			style.set_border_width_all(2)
			style.shadow_color = Color(0.06, 0.72, 0.5, 0.25)
			style.shadow_size = 10
			accent_bar.color = Color("34d399")
			pill_style.bg_color = Color("10b981")
			pill_style.border_color = Color("34d399")
			letter_label.add_theme_color_override("font_color", Color("022c1b"))
			answer_label.add_theme_color_override("font_color", Color("f0fdf4"))
		State.WRONG:
			style.bg_color = Color("2e1216")
			style.border_color = Color("ef4444")
			style.set_border_width_all(2)
			style.shadow_color = Color(0.95, 0.24, 0.36, 0.25)
			style.shadow_size = 10
			accent_bar.color = Color("fb7185")
			pill_style.bg_color = Color("ef4444")
			pill_style.border_color = Color("fca5a5")
			letter_label.add_theme_color_override("font_color", Color("1f0408"))
			answer_label.add_theme_color_override("font_color", Color("fff1f2"))
		State.ELIMINATED:
			style.bg_color = Color("0d131f")
			style.border_color = Color("172030")
			style.set_border_width_all(1)
			style.shadow_size = 0
			accent_bar.color = Color(0.3, 0.35, 0.45, 0.2)
			pill_style.bg_color = Color("111827")
			pill_style.border_color = Color("1f293d")
			letter_label.add_theme_color_override("font_color", Color("475569"))
			answer_label.add_theme_color_override("font_color", Color("64748b"))
		State.HOVER:
			style.bg_color = Color("1a2538")
			style.border_color = Color("38bdf8")
			style.set_border_width_all(2)
			style.shadow_color = Color(0, 0, 0, 0.45)
			style.shadow_size = 8
			accent_bar.color = Color("38bdf8")
			pill_style.bg_color = Color("0284c7")
			pill_style.border_color = Color("38bdf8")
			letter_label.add_theme_color_override("font_color", Color("ffffff"))
			answer_label.add_theme_color_override("font_color", Color("ffffff"))
		State.PRESSED:
			style.bg_color = Color("141e30")
			style.border_color = Color("0ea5e9")
			style.set_border_width_all(2)
			style.shadow_color = Color(0, 0, 0, 0.3)
			style.shadow_size = 4
			accent_bar.color = Color("0ea5e9")
			pill_style.bg_color = Color("0369a1")
			pill_style.border_color = Color("0ea5e9")
			letter_label.add_theme_color_override("font_color", Color("ffffff"))
			answer_label.add_theme_color_override("font_color", Color("ffffff"))
		_: # NORMAL
			style.bg_color = Color("111928")
			style.border_color = Color("2e3d57")
			style.set_border_width_all(1)
			style.shadow_color = Color(0, 0, 0, 0.35)
			style.shadow_size = 6
			accent_bar.color = Color("38bdf8")
			pill_style.bg_color = Color("1e293b")
			pill_style.border_color = Color("475569")
			letter_label.add_theme_color_override("font_color", Color("ffffff"))
			answer_label.add_theme_color_override("font_color", Color("ffffff"))

	add_theme_stylebox_override("panel", style)

func _on_mouse_entered() -> void:
	if is_disabled or current_state in [State.CORRECT, State.WRONG, State.ELIMINATED]:
		return
	set_state(State.HOVER)
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2(1.016, 1.016), 0.12)
	tween.parallel().tween_property(self, "position:x", 4.0, 0.12).as_relative()

func _on_mouse_exited() -> void:
	if is_disabled or current_state in [State.CORRECT, State.WRONG, State.ELIMINATED]:
		return
	set_state(State.NORMAL)
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.12)
	tween.parallel().tween_property(self, "position:x", -4.0, 0.12).as_relative()

func _on_focus_entered() -> void:
	if is_disabled or current_state in [State.CORRECT, State.WRONG, State.ELIMINATED]:
		return
	set_state(State.HOVER)

func _on_focus_exited() -> void:
	if is_disabled or current_state in [State.CORRECT, State.WRONG, State.ELIMINATED]:
		return
	set_state(State.NORMAL)

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
				tw2.parallel().tween_property(self, "scale", Vector2.ONE, 0.15)
				tw2.parallel().tween_property(self, "position:x", 0.0, 0.15)
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
		card_clicked.emit(option_index)
