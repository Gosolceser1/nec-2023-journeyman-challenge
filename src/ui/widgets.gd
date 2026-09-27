class_name Widgets
extends RefCounted
## Controls both layout builders (and the audio section) make the same way.
## The mode button and voice picker register on the host (menu_mode_buttons,
## voice_picker), hence their host argument.

## Right margin of a mode card, reserved for its ModeBadge.
const MODE_BADGE_ROOM := 66
const MODE_BADGE_PX := 44

## A menu mode card that starts a session. is_major: the Full Journeyman
## Simulator's official red -> amber card with a slow light on its border.
## Every card goes through connect_session_start, so a new mode (the
## Nebraska State Law section, say) gets the start cue and press animation
## without extra wiring.
static func add_mode_button(host: Main, parent: VBoxContainer, title_text: String, subtitle_text: String, callback: Callable, accent: Color = AppTheme.SKY_400, bg: Color = AppTheme.SURFACE_BOTTOM, is_major: bool = false, min_height: float = -1.0, font_size: int = -1, icon_name: String = "stopwatch") -> void:
	var button := Button.new()
	button.text = title_text + "\n" + subtitle_text
	button.custom_minimum_size = Vector2(0, min_height if min_height > 0.0 else (60.0 if is_major else 54.0))
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if host.ui_mobile:
		# An unwrapped subtitle sets the button's min width, which pushed the
		# phone menu panel past the right screen edge.
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_override("font", AppTheme.ui_font(AppTheme.WEIGHT_SEMIBOLD))
	button.add_theme_font_size_override("font_size", font_size if font_size > 0 else AppTheme.TYPE_BODY_SM)
	button.icon = Icons.texture(icon_name, 20)
	button.add_theme_constant_override("h_separation", AppTheme.SPACE_MD)
	button.add_theme_constant_override("icon_max_width", 20)

	# Same border widths and margins in every state: hover changes colour and
	# glow only, so the card never shifts.
	var fill := AppTheme.OFFICIAL_FROM if is_major else bg
	var normal := _mode_style(fill, Color(accent, 0.45), AppTheme.ELEVATION_REST, Color.TRANSPARENT)
	var hover := _mode_style(fill.lightened(0.05), accent, AppTheme.ELEVATION_CARD, Color(accent, 0.28))
	var pressed := _mode_style(fill.darkened(0.15), accent, AppTheme.ELEVATION_FLAT, Color.TRANSPARENT)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("hover_pressed", pressed)
	var focus := AppTheme.focus_ring(AppTheme.RADIUS)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		focus.set_content_margin(side, normal.get_content_margin(side))
	button.add_theme_stylebox_override("focus", focus)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, AppTheme.WHITE)
	for state in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		button.add_theme_color_override(state, accent)

	button.set_meta("base_text", button.text)
	button.set_meta("full_exam", is_major)
	var badge := ModeBadge.new()
	badge.name = "ModeBadge"
	badge.question_count = int(title_text.get_slice(" ", 0))
	badge.full_exam = is_major
	badge.accent = AppTheme.AMBER_400 if is_major else accent
	badge.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	badge.offset_left = -MODE_BADGE_PX - AppTheme.SPACE_LG
	badge.offset_right = -AppTheme.SPACE_LG
	badge.offset_top = -MODE_BADGE_PX * 0.5
	badge.offset_bottom = MODE_BADGE_PX * 0.5
	button.add_child(badge)
	button.mouse_entered.connect(badge.set_hover.bind(true))
	button.mouse_exited.connect(badge.set_hover.bind(false))
	button.focus_entered.connect(badge.set_hover.bind(true))
	button.focus_exited.connect(badge.set_hover.bind(false))

	if is_major:
		UiFx.add_glass(button, [fill.lightened(0.06), fill])
		UiFx.add_tint(button, AppTheme.GRAD_OFFICIAL, 0.9)
		UiFx.add_border_flow(button, AppTheme.AMBER_400, 0.55)
	else:
		UiFx.add_glass(button)
	UiFx.add_shine(button)

	connect_session_start(host, button, callback)
	parent.add_child(button)
	host.menu_mode_buttons.append(button)


## "NEBRASKA STATE LAW" heading plus one drill of every state-law question,
## shuffled. Adds nothing when the bank has none.
static func add_state_law_section(host: Main, parent: VBoxContainer, min_height: float = -1.0, font_size: int = -1) -> void:
	var count := BankLoader.count_in_section(host.records, BankLoader.SECTION_NE_STATE_LAW)
	if count == 0:
		return
	parent.add_child(make_section_header("NEBRASKA STATE LAW", AppTheme.SKY_300))
	var seconds: int = host._practice_time(count)
	add_mode_button(host, parent, "%d QUESTIONS" % count,
		"State Electrical Act & Board Rules • %d minutes timed" % (seconds / 60),
		host._start_quiz.bind(count, seconds, true, "Nebraska State Law", "", BankLoader.SECTION_NE_STATE_LAW),
		AppTheme.SKY_300, AppTheme.SURFACE_BOTTOM, false, min_height, font_size, "code")


static func _mode_style(fill: Color, border: Color, elevation: int, glow: Color) -> StyleBoxFlat:
	var style := AppTheme.panel_style(fill, border, AppTheme.BORDER_HAIRLINE, AppTheme.RADIUS)
	style.border_width_left = AppTheme.ACCENT_BAR_W
	AppTheme.elevate(style, elevation, glow)
	style.content_margin_left = AppTheme.SPACE_LG + AppTheme.ACCENT_BAR_W
	style.content_margin_right = MODE_BADGE_ROOM
	style.content_margin_top = AppTheme.SPACE_SM
	style.content_margin_bottom = AppTheme.SPACE_SM
	return style


## Anything on the menu that starts a session: the power-on cue (Sfx.START,
## assets/sfx/start.wav) and a press animation on its beats, then the session
## itself. The menu fades out over MOTION_SCREEN (180 ms), so the motion is
## keyed to the cue's first 180 ms; the charge-up keeps playing under the fade.
##   0 ms   pre-click      the card dips 1.5 %
##   50 ms  charge onset   current runs once around the card's border and
##                         the badge ring charges to full
## Reduce motion keeps the sound and skips the motion.
static func connect_session_start(host: Main, button: Button, callback: Callable) -> void:
	button.set_meta("starts_session", true)
	button.pressed.connect(func() -> void:
		host._sfx(Sfx.START)
		if not UiFx.reduce_motion:
			_start_press_motion(button)
		callback.call()
	)


const START_CUE_ONSET := 0.05
const START_MOTION_SECONDS := 0.13

static func _start_press_motion(button: Button) -> void:
	button.pivot_offset = button.size * 0.5
	var dip := button.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	dip.tween_property(button, "scale", Vector2(0.985, 0.985), START_CUE_ONSET)
	dip.tween_property(button, "scale", Vector2.ONE, START_MOTION_SECONDS).set_trans(Tween.TRANS_BACK)
	if button.material is ShaderMaterial:
		UiFx.run_current(button, START_CUE_ONSET, START_MOTION_SECONDS, 1.1)
	var badge := button.get_node_or_null("ModeBadge") as ModeBadge
	if badge != null:
		button.get_tree().create_timer(START_CUE_ONSET).timeout.connect(badge.set_hover.bind(true, START_MOTION_SECONDS))


## Secondary dock action in the ghost style, with an optional Icons glyph.
static func make_dock_button(text: String, min_w: float, h: float, font_size: int, callback: Callable, icon_name: String = "") -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(min_w, h)
	AppTheme.style_ghost_button(button)
	if icon_name != "":
		button.icon = Icons.texture(icon_name, 16)
		button.add_theme_constant_override("icon_max_width", 16)
	button.add_theme_font_override("font", AppTheme.ui_font(AppTheme.WEIGHT_SEMIBOLD))
	button.add_theme_font_size_override("font_size", font_size)
	button.pressed.connect(callback)
	return button


## Primary action bar (Next question): AppTheme.style_primary_button with the
## cyan -> deep blue gradient drawn by the surface shader.
static func make_primary_button(text: String, h: float, font_size: int, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, h)
	AppTheme.style_primary_button(button)
	button.add_theme_font_size_override("font_size", font_size)
	UiFx.add_glass(button, [AppTheme.SKY_600, AppTheme.SKY_700], AppTheme.RADIUS, AppTheme.BEVEL * 2.0)
	UiFx.add_tint(button, AppTheme.GRAD_PRIMARY)
	button.pressed.connect(callback)
	return button


## Verdict heading of the feedback panel: an Icons glyph (main sets it with
## the verdict, see Main._set_feedback_verdict) beside host.feedback_title.
static func add_feedback_title(host: Main, column: VBoxContainer, font_size: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	column.add_child(row)
	host.feedback_icon = TextureRect.new()
	host.feedback_icon.custom_minimum_size = Vector2(font_size + 2, font_size + 2)
	host.feedback_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	host.feedback_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	host.feedback_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	host.feedback_icon.visible = false
	row.add_child(host.feedback_icon)
	host.feedback_title = Label.new()
	host.feedback_title.add_theme_font_override("font", AppTheme.ui_font(AppTheme.WEIGHT_BOLD))
	host.feedback_title.add_theme_font_size_override("font_size", font_size)
	row.add_child(host.feedback_title)


## The explanation RichTextLabel: body fonts, and the padding the
## InfoPanelRenderer's highlights, answer pill and tables rely on.
static func style_info_label(label: RichTextLabel, font_size: int) -> void:
	label.add_theme_font_override("normal_font", AppTheme.ui_font(AppTheme.WEIGHT_REGULAR))
	label.add_theme_font_override("bold_font", AppTheme.ui_font(AppTheme.WEIGHT_BOLD))
	label.add_theme_color_override("default_color", AppTheme.SLATE_100)
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.add_theme_font_size_override("bold_font_size", font_size)
	label.add_theme_constant_override("line_separation", AppTheme.SPACE_XS)
	label.add_theme_constant_override("text_highlight_h_padding", 3)
	label.add_theme_constant_override("text_highlight_v_padding", 1)
	label.add_theme_constant_override("table_h_separation", AppTheme.SPACE_SM)
	label.add_theme_constant_override("table_v_separation", AppTheme.SPACE_XS)


## Menu section heading: a short accent bar and a tracked uppercase label.
static func make_section_header(text: String, accent: Color = AppTheme.SKY_400) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	var bar := ColorRect.new()
	bar.custom_minimum_size = Vector2(AppTheme.ACCENT_BAR_W, 14)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.color = accent
	row.add_child(bar)
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", AppTheme.meta_font())
	label.add_theme_font_size_override("font_size", AppTheme.TYPE_META)
	label.add_theme_color_override("font_color", accent)
	row.add_child(label)
	return row


## The quiz HUD: one glass strip whose cells (hud_segment) hold the status
## labels. Returns the row the cells go in.
static func make_hud_strip(parent: Container, expand: bool = false) -> HBoxContainer:
	var strip := PanelContainer.new()
	var style := AppTheme.surface(AppTheme.PANEL_BOTTOM, AppTheme.HAIRLINE_BRIGHT, AppTheme.ELEVATION_REST, AppTheme.RADIUS)
	AppTheme.pad(style, AppTheme.SPACE_XS, AppTheme.SPACE_XS)
	strip.add_theme_stylebox_override("panel", style)
	strip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if expand:
		strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiFx.add_glass(strip, AppTheme.GRAD_PANEL)
	parent.add_child(strip)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", AppTheme.SPACE_XS)
	strip.add_child(row)
	return row


## One HUD cell holding `label` (tabular figures, centred). The cell is a
## PanelContainer so QuizFx can hang a time gauge on it and main can tint it.
static func hud_segment(row: HBoxContainer, label: Label, font_size: int, color: Color, expand: bool = false) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.add_theme_stylebox_override("panel", AppTheme.hud_segment(AppTheme.SLATE_400, AppTheme.SPACE_XS if expand else AppTheme.SPACE_MD))
	if expand:
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", AppTheme.numeric_font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	cell.add_child(label)
	row.add_child(cell)
	return cell


## Status colour of a HUD cell (pass / at risk / below). Only the fill
## changes, so the strip never resizes.
static func tint_hud_segment(cell: PanelContainer, tint: Color) -> void:
	var style := cell.get_theme_stylebox("panel") as StyleBoxFlat
	if style != null:
		style.bg_color = AppTheme.hud_tint(tint)


## Menu hero: the readiness ring, the title block and a chip that starts the
## weakest-area drill. Assigns host.readiness_ring and host.weakest_chip.
static func add_menu_hero(host: Main, parent: VBoxContainer, ring_px: float, title_px: int, standards: String) -> void:
	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", AppTheme.SPACE_LG + (0 if host.ui_mobile else AppTheme.SPACE_SM))
	parent.add_child(hero)
	host.readiness_ring = ReadinessRing.new()
	host.readiness_ring.custom_minimum_size = Vector2(ring_px, ring_px)
	hero.add_child(host.readiness_ring)
	var block := VBoxContainer.new()
	block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	block.add_theme_constant_override("separation", AppTheme.SPACE_XS)
	hero.add_child(block)
	var meta := Label.new()
	meta.text = standards
	meta.add_theme_font_override("font", AppTheme.meta_font())
	meta.add_theme_font_size_override("font_size", AppTheme.TYPE_MICRO)
	meta.add_theme_color_override("font_color", AppTheme.SKY_400)
	block.add_child(meta)
	var title := Label.new()
	title.text = "NEC 2023 // JOURNEYMAN CHALLENGE"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_override("font", AppTheme.ui_font(AppTheme.WEIGHT_BOLD))
	title.add_theme_font_size_override("font_size", title_px)
	title.add_theme_color_override("font_color", AppTheme.SLATE_50)
	block.add_child(title)
	UiFx.electrify_title(title)
	var subtitle := Label.new()
	subtitle.text = "Master the National Electrical Code • Comprehensive Exam Prep"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", AppTheme.TYPE_CAPTION)
	subtitle.add_theme_color_override("font_color", AppTheme.SLATE_400)
	block.add_child(subtitle)
	host.weakest_chip = Button.new()
	host.weakest_chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	host.weakest_chip.custom_minimum_size = Vector2(0, 44 if host.ui_mobile else 30)
	host.weakest_chip.clip_text = true
	AppTheme.style_ghost_button(host.weakest_chip, AppTheme.RADIUS_INNER)
	host.weakest_chip.icon = Icons.texture("target", 14)
	host.weakest_chip.add_theme_constant_override("icon_max_width", 14)
	host.weakest_chip.add_theme_color_override("icon_normal_color", AppTheme.AMBER_400)
	host.weakest_chip.add_theme_color_override("font_color", AppTheme.AMBER_200)
	host.weakest_chip.add_theme_font_override("font", AppTheme.ui_font(AppTheme.WEIGHT_SEMIBOLD))
	host.weakest_chip.add_theme_font_size_override("font_size", AppTheme.TYPE_META)
	connect_session_start(host, host.weakest_chip, host._start_area_drill)
	block.add_child(host.weakest_chip)


static func make_voice_picker(host: Main, h: float, font_size: int) -> OptionButton:
	host.voice_picker = OptionButton.new()
	host.voice_picker.custom_minimum_size = Vector2(0, h)
	host.voice_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.voice_picker.clip_text = true
	host.voice_picker.fit_to_longest_item = false
	var vp_hov := AppTheme.panel_style(AppTheme.PICKER_HOVER_BG, AppTheme.SKY_400, 2, 9)
	var vp_norm := AppTheme.panel_style(AppTheme.PICKER_BG, AppTheme.BORDER_BLUE, 1, 9)
	var vp_pressed := AppTheme.panel_style(AppTheme.BUTTON_PRESSED_BG, AppTheme.SKY_600, 1, 9)
	for sb in [vp_hov, vp_norm, vp_pressed]:
		sb.content_margin_left = 10
		sb.content_margin_right = 8
	host.voice_picker.add_theme_stylebox_override("normal", vp_norm)
	host.voice_picker.add_theme_stylebox_override("hover", vp_hov)
	host.voice_picker.add_theme_stylebox_override("pressed", vp_pressed)
	host.voice_picker.add_theme_stylebox_override("focus", vp_hov)
	host.voice_picker.add_theme_font_override("font", AppTheme.ui_font(500))
	host.voice_picker.add_theme_font_size_override("font_size", font_size)
	host.voice_picker.add_theme_color_override("font_color", AppTheme.SLATE_200)
	host.voice_picker.add_theme_color_override("font_hover_color", AppTheme.WHITE)
	host.voice_picker.add_theme_color_override("font_pressed_color", AppTheme.SKY_400)
	var popup: PopupMenu = host.voice_picker.get_popup()
	if popup:
		var pop_panel := AppTheme.panel_style(AppTheme.POPUP_BG, AppTheme.BORDER_BLUE, 1, 10)
		pop_panel.shadow_color = Color(0, 0, 0, 0.7)
		pop_panel.shadow_size = 14
		pop_panel.set_content_margin_all(8)
		popup.add_theme_stylebox_override("panel", pop_panel)
		popup.add_theme_stylebox_override("hover", AppTheme.panel_style(AppTheme.POPUP_HOVER_BG, AppTheme.SKY_400, 1, 6))
		popup.add_theme_font_override("font", AppTheme.ui_font(500))
		popup.add_theme_font_size_override("font_size", font_size + (1 if host.ui_mobile else 0))
		popup.add_theme_color_override("font_color", AppTheme.SLATE_300)
		popup.add_theme_color_override("font_hover_color", AppTheme.WHITE)
		popup.add_theme_color_override("font_separator_color", AppTheme.SKY_400)
		popup.add_theme_font_override("font_separator", AppTheme.ui_font(700))
		popup.add_theme_font_size_override("font_separator_size", 11)
		popup.add_theme_constant_override("v_separation", 14 if host.ui_mobile else 8)
		popup.add_theme_constant_override("item_start_padding", 10)
		popup.add_theme_constant_override("item_end_padding", 10)
	host.speech._populate_voice_picker()
	host.voice_picker.item_selected.connect(func(_i: int) -> void:
		if host.speech._previewing:
			host.speech._stop_reading()
	)
	return host.voice_picker


## Segmented-control chip: a toggle button in a ButtonGroup, emerald when on.
static func make_chip(text: String, h: float, font_size: int, group: ButtonGroup) -> Button:
	var chip := Button.new()
	chip.text = text
	chip.toggle_mode = true
	chip.button_group = group
	chip.custom_minimum_size = Vector2(0, h)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var on := AppTheme.panel_style(AppTheme.CHIP_ON_BG, AppTheme.EMERALD_400, 2, 9)
	chip.add_theme_stylebox_override("normal", AppTheme.panel_style(AppTheme.BUTTON_BG, AppTheme.BUTTON_BORDER, 1, 9))
	chip.add_theme_stylebox_override("hover", AppTheme.panel_style(AppTheme.BUTTON_HOVER_BG, AppTheme.SKY_400, 1, 9))
	chip.add_theme_stylebox_override("pressed", on)
	chip.add_theme_stylebox_override("hover_pressed", on)
	chip.add_theme_stylebox_override("focus", AppTheme.focus_ring(8))
	chip.add_theme_font_override("font", AppTheme.ui_font(600))
	chip.add_theme_font_size_override("font_size", font_size)
	chip.add_theme_color_override("font_color", AppTheme.SLATE_400)
	chip.add_theme_color_override("font_hover_color", AppTheme.SLATE_200)
	chip.add_theme_color_override("font_pressed_color", AppTheme.EMERALD_300)
	chip.add_theme_color_override("font_hover_pressed_color", AppTheme.EMERALD_200)
	return chip


static func audio_row_label(text: String, min_w: float) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(min_w, 0)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.add_theme_font_override("font", AppTheme.ui_font(700))
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", AppTheme.SLATE_400)
	return label
