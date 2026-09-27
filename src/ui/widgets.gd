class_name Widgets
extends RefCounted
## Controls both layout builders (and the audio section) make the same way.
## The mode button and voice picker register on the host (menu_mode_buttons,
## voice_picker), hence their host argument.

static func add_mode_button(host: Main, parent: VBoxContainer, title_text: String, subtitle_text: String, callback: Callable, accent: Color = AppTheme.SKY_400, bg: Color = AppTheme.BUTTON_BG, is_major: bool = false, min_height: float = -1.0, font_size: int = -1) -> void:
	var button := Button.new()
	button.text = title_text + "\n" + subtitle_text
	button.custom_minimum_size = Vector2(0, min_height if min_height > 0.0 else (68.0 if is_major else 62.0))
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if host.ui_mobile:
		# An unwrapped subtitle sets the button's min width, which pushed the
		# phone menu panel past the right screen edge.
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_override("font", AppTheme.ui_font(600))
	button.add_theme_font_size_override("font_size", font_size if font_size > 0 else 14)

	var btn_norm := AppTheme.panel_style(bg, AppTheme.BUTTON_BORDER, 1, 10)
	btn_norm.border_width_left = 6
	btn_norm.border_color = accent

	var btn_hov := AppTheme.panel_style(AppTheme.BUTTON_HOVER_BG if not is_major else AppTheme.EXAM_BUTTON_HOVER_BG, accent, 2, 10)
	btn_hov.border_width_left = 8

	var btn_pressed := AppTheme.panel_style(bg, accent, 2, 10)
	btn_pressed.border_width_left = 6

	# Every state shares one content box, so the title never shifts between
	# states. The right margin clears the badge.
	var ring := AppTheme.focus_ring(10)
	for sb in [btn_norm, btn_hov, btn_pressed, ring]:
		sb.content_margin_left = 20
		sb.content_margin_right = 66
		sb.content_margin_top = 10
		sb.content_margin_bottom = 10

	button.add_theme_stylebox_override("normal", btn_norm)
	button.add_theme_stylebox_override("hover", btn_hov)
	button.add_theme_stylebox_override("pressed", btn_pressed)
	button.add_theme_stylebox_override("focus", ring)
	button.add_theme_color_override("font_color", AppTheme.WHITE)
	button.add_theme_color_override("font_hover_color", AppTheme.WHITE)

	button.mouse_entered.connect(func(): UiFx.slide_x(button, 5.0))
	button.mouse_exited.connect(func(): UiFx.slide_x(button, 0.0))

	button.set_meta("base_text", button.text)
	button.set_meta("full_exam", is_major)
	var badge := ModeBadge.new()
	badge.question_count = int(title_text.get_slice(" ", 0))
	badge.full_exam = is_major
	badge.accent = accent
	badge.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	badge.offset_left = -58
	badge.offset_right = -14
	badge.offset_top = -22
	badge.offset_bottom = 22
	button.add_child(badge)
	UiFx.add_shine(button)

	button.pressed.connect(callback)
	parent.add_child(button)
	host.menu_mode_buttons.append(button)


## "NEBRASKA STATE LAW" heading plus one drill of every state-law question,
## shuffled. Adds nothing when the bank has none.
static func add_state_law_section(host: Main, parent: VBoxContainer, min_height: float = -1.0, font_size: int = -1) -> void:
	var count := BankLoader.count_in_section(host.records, BankLoader.SECTION_NE_STATE_LAW)
	if count == 0:
		return
	var hdr_box := HBoxContainer.new()
	hdr_box.add_theme_constant_override("separation", 8)
	parent.add_child(hdr_box)
	var bar := ColorRect.new()
	bar.custom_minimum_size = Vector2(4, 16)
	bar.color = AppTheme.SKY_300
	hdr_box.add_child(bar)
	var heading := Label.new()
	heading.text = "NEBRASKA STATE LAW"
	heading.add_theme_font_size_override("font_size", 12)
	heading.add_theme_color_override("font_color", AppTheme.SKY_300)
	hdr_box.add_child(heading)
	var seconds: int = host._practice_time(count)
	add_mode_button(host, parent, "%d QUESTIONS" % count,
		"State Electrical Act & Board Rules • %d minutes timed" % (seconds / 60),
		host._start_quiz.bind(count, seconds, true, "Nebraska State Law", "", BankLoader.SECTION_NE_STATE_LAW),
		AppTheme.SKY_300, AppTheme.BUTTON_BG, false, min_height, font_size)


static func make_dock_button(text: String, min_w: float, h: float, font_size: int, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(min_w, h)
	button.add_theme_stylebox_override("normal", AppTheme.panel_style(AppTheme.DOCK_BUTTON_BG, AppTheme.DOCK_BUTTON_BORDER, 1, 9))
	button.add_theme_stylebox_override("hover", AppTheme.panel_style(AppTheme.DOCK_BUTTON_HOVER_BG, AppTheme.SKY_400, 1, 9))
	button.add_theme_stylebox_override("pressed", AppTheme.panel_style(AppTheme.BUTTON_PRESSED_BG, AppTheme.SKY_600, 1, 9))
	button.add_theme_stylebox_override("focus", AppTheme.focus_ring(9))
	button.add_theme_font_override("font", AppTheme.ui_font(600))
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", AppTheme.SLATE_300)
	button.add_theme_color_override("font_hover_color", AppTheme.WHITE)
	button.pressed.connect(callback)
	return button


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
