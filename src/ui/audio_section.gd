class_name AudioSection
extends RefCounted
## The menu's "Audio & Voice" panel for both layouts: build it, and refresh it
## from the host's AudioSettings. The pick handlers stay on main because they
## also stop or re-time speech.

## "Audio & Voice" menu section, shared by both layouts (sizes follow ui_mobile).
## Returns the section so the caller can position it.
static func build(host: Main, parent: VBoxContainer) -> Control:
	var h: float = 56.0 if host.ui_mobile else 40.0
	var fs: int = 14 if host.ui_mobile else 13
	var label_w: float = 62.0 if host.ui_mobile else 48.0
	var section := PanelContainer.new()
	var section_style := AppTheme.panel_style(AppTheme.SECTION_BG, AppTheme.SLATE_800, 1, 12)
	section_style.set_content_margin_all(14.0 if host.ui_mobile else 16.0)
	section.add_theme_stylebox_override("panel", section_style)
	parent.add_child(section)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	section.add_child(col)

	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 8)
	col.add_child(hdr)
	var bar := ColorRect.new()
	bar.custom_minimum_size = Vector2(4, 16)
	bar.color = AppTheme.EMERALD_400
	hdr.add_child(bar)
	var heading := Label.new()
	heading.text = "AUDIO & VOICE"
	heading.add_theme_font_override("font", AppTheme.ui_font(700))
	heading.add_theme_font_size_override("font_size", 12)
	heading.add_theme_color_override("font_color", AppTheme.EMERALD_400)
	heading.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hdr.add_child(heading)
	# Collapsed by default: one line says what is set, the full panel is a tap
	# away, and the session buttons move up above the fold.
	host.audio_summary_label = Label.new()
	host.audio_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.audio_summary_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	host.audio_summary_label.clip_text = true
	host.audio_summary_label.add_theme_font_override("font", AppTheme.ui_font(600))
	host.audio_summary_label.add_theme_font_size_override("font_size", fs)
	host.audio_summary_label.add_theme_color_override("font_color", AppTheme.SLATE_300)
	hdr.add_child(host.audio_summary_label)
	host.audio_toggle_button = Widgets.make_dock_button("Change", 92.0 if host.ui_mobile else 84.0, 44.0 if host.ui_mobile else 32.0, fs, host._toggle_audio_section)
	host.audio_toggle_button.add_theme_stylebox_override("focus", AppTheme.focus_ring(9))
	hdr.add_child(host.audio_toggle_button)
	host.audio_body = VBoxContainer.new()
	host.audio_body.add_theme_constant_override("separation", 10)
	host.audio_body.visible = false
	col.add_child(host.audio_body)

	var modes := GridContainer.new()
	modes.columns = 2 if host.ui_mobile else 4
	modes.add_theme_constant_override("h_separation", 8)
	modes.add_theme_constant_override("v_separation", 8)
	host.audio_body.add_child(modes)
	var mode_group := ButtonGroup.new()
	host.audio_mode_buttons.clear()
	for m in [AudioSettings.Mode.SILENT, AudioSettings.Mode.TAP, AudioSettings.Mode.AUTO, AudioSettings.Mode.LISTEN]:
		var chip := Widgets.make_chip(AudioSettings.MODE_TITLES[m], h, fs + 1, mode_group)
		chip.pressed.connect(host._on_audio_mode_picked.bind(m))
		modes.add_child(chip)
		host.audio_mode_buttons.append(chip)

	host.audio_mode_blurb = Label.new()
	host.audio_mode_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.audio_mode_blurb.add_theme_font_override("font", AppTheme.ui_font(400))
	host.audio_mode_blurb.add_theme_font_size_override("font_size", 13 if host.ui_mobile else 12)
	host.audio_mode_blurb.add_theme_color_override("font_color", AppTheme.SLATE_400)
	host.audio_body.add_child(host.audio_mode_blurb)

	host.audio_details_box = VBoxContainer.new()
	host.audio_details_box.add_theme_constant_override("separation", 10)
	host.audio_body.add_child(host.audio_details_box)
	var opts: BoxContainer = VBoxContainer.new() if host.ui_mobile else HBoxContainer.new()
	opts.add_theme_constant_override("separation", 10 if host.ui_mobile else 20)
	host.audio_details_box.add_child(opts)

	var voice_row := HBoxContainer.new()
	voice_row.add_theme_constant_override("separation", 8)
	voice_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opts.add_child(voice_row)
	voice_row.add_child(Widgets.audio_row_label("VOICE", label_w))
	voice_row.add_child(Widgets.make_voice_picker(host, h, fs))
	if host.ui_mobile:
		voice_row.add_child(Widgets.make_voice_button(host, h, fs))
	host.preview_button = Widgets.make_dock_button("Preview", 96.0 if host.ui_mobile else 84.0, h, fs, host.speech._preview_voice)
	voice_row.add_child(host.preview_button)

	var speed_row := HBoxContainer.new()
	speed_row.add_theme_constant_override("separation", 6)
	opts.add_child(speed_row)
	speed_row.add_child(Widgets.audio_row_label("SPEED", label_w))
	var speed_group := ButtonGroup.new()
	host.audio_speed_buttons.clear()
	for s in AudioSettings.SPEEDS:
		var chip := Widgets.make_chip(AudioSettings.speed_label(s), h, fs, speed_group)
		chip.custom_minimum_size.x = 0.0 if host.ui_mobile else 56.0
		chip.pressed.connect(host._on_audio_speed_picked.bind(s))
		speed_row.add_child(chip)
		host.audio_speed_buttons.append(chip)

	host.auto_teach_toggle = _make_toggle(host, "Also read the rule after I answer", fs)
	host.auto_teach_toggle.toggled.connect(host._on_auto_teach_toggled)
	host.audio_details_box.add_child(host.auto_teach_toggle)

	host.audio_pause_row = HBoxContainer.new()
	host.audio_pause_row.add_theme_constant_override("separation", 6)
	host.audio_details_box.add_child(host.audio_pause_row)
	host.audio_pause_row.add_child(Widgets.audio_row_label("THINK", label_w))
	var pause_group := ButtonGroup.new()
	host.audio_pause_buttons.clear()
	for p in AudioSettings.THINK_PAUSES:
		var chip := Widgets.make_chip("%d s" % p, h, fs, pause_group)
		chip.custom_minimum_size.x = 0.0 if host.ui_mobile else 56.0
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL if host.ui_mobile else Control.SIZE_FILL
		chip.pressed.connect(host._on_audio_pause_picked.bind(p))
		host.audio_pause_row.add_child(chip)
		host.audio_pause_buttons.append(chip)
	if not host.ui_mobile:
		var pause_hint := Widgets.audio_row_label("pause before the answer is revealed", 0)
		pause_hint.add_theme_font_override("font", AppTheme.ui_font(500))
		pause_hint.add_theme_font_size_override("font_size", 12)
		host.audio_pause_row.add_child(pause_hint)

	host.audio_exam_note = Label.new()
	host.audio_exam_note.text = "The Full Journeyman Exam stays exam-quiet: nothing plays by itself, like the real exam. The Read button still works there."
	host.audio_exam_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.audio_exam_note.add_theme_font_override("font", AppTheme.ui_font(400))
	host.audio_exam_note.add_theme_font_size_override("font_size", 12 if host.ui_mobile else 11)
	host.audio_exam_note.add_theme_color_override("font_color", AppTheme.ROSE_300)
	host.audio_details_box.add_child(host.audio_exam_note)

	# Sound effects sit outside the voice details: Silent mutes the voice only.
	var sfx_row := HBoxContainer.new()
	sfx_row.add_theme_constant_override("separation", 6)
	host.audio_body.add_child(sfx_row)
	sfx_row.add_child(Widgets.audio_row_label("SOUNDS", label_w))
	var sfx_group := ButtonGroup.new()
	host.sfx_level_buttons.clear()
	var sfx_titles: Array[String] = ["Off"]
	sfx_titles.append_array(AudioSettings.SFX_LEVEL_TITLES)
	for i in sfx_titles.size():
		var chip := Widgets.make_chip(sfx_titles[i], h, fs, sfx_group)
		chip.custom_minimum_size.x = 0.0 if host.ui_mobile else 72.0
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL if host.ui_mobile else Control.SIZE_FILL
		chip.pressed.connect(host._on_sfx_level_picked.bind(i - 1))
		sfx_row.add_child(chip)
		host.sfx_level_buttons.append(chip)
	if not host.ui_mobile:
		var sfx_hint := Widgets.audio_row_label("answers, results, clock warnings and taps", 0)
		sfx_hint.add_theme_font_override("font", AppTheme.ui_font(500))
		sfx_hint.add_theme_font_size_override("font_size", 12)
		sfx_row.add_child(sfx_hint)

	host.reduce_motion_toggle = _make_toggle(host, "Reduce motion (no shake, pop or sparks on answers)" if not host.ui_mobile else "Reduce motion", fs)
	host.reduce_motion_toggle.toggled.connect(host._on_reduce_motion_toggled)
	host.audio_body.add_child(host.reduce_motion_toggle)
	host.hunt_keywords_toggle = _make_toggle(host, "Highlight code-book keywords (Index hints; off in the Full Exam)" if not host.ui_mobile else "Keyword hints (off in Full Exam)", fs)
	if not host.ui_mobile:
		host.hunt_keywords_toggle.tooltip_text = Tooltip.wrap("Colors the stem words to look up in the NEC Index and names the entry before you answer. " + HuntKeywords.EXAM_NOTE)
	host.hunt_keywords_toggle.toggled.connect(host._on_hunt_keywords_toggled)
	host.audio_body.add_child(host.hunt_keywords_toggle)
	return section


static func _make_toggle(host: Main, text: String, fs: int) -> CheckButton:
	var toggle := CheckButton.new()
	toggle.text = text
	toggle.custom_minimum_size = Vector2(0, 44.0 if host.ui_mobile else 32.0)
	toggle.add_theme_font_override("font", AppTheme.ui_font(500))
	toggle.add_theme_font_size_override("font_size", fs)
	toggle.add_theme_color_override("font_color", AppTheme.SLATE_300)
	toggle.add_theme_color_override("font_hover_color", AppTheme.WHITE)
	toggle.add_theme_color_override("font_pressed_color", AppTheme.EMERALD_300)
	toggle.add_theme_color_override("font_hover_pressed_color", AppTheme.EMERALD_200)
	# The engine theme pads the label a few px in from the row labels above it.
	var flush := StyleBoxEmpty.new()
	flush.content_margin_left = 0
	flush.content_margin_right = 0
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		toggle.add_theme_stylebox_override(state, flush)
	toggle.add_theme_stylebox_override("focus", AppTheme.focus_ring(8))
	return toggle


static func refresh(host: Main) -> void:
	if host.audio_mode_buttons.is_empty():
		return
	for i in host.audio_mode_buttons.size():
		host.audio_mode_buttons[i].set_pressed_no_signal(i == host.audio.mode)
	for i in host.audio_speed_buttons.size():
		host.audio_speed_buttons[i].set_pressed_no_signal(is_equal_approx(AudioSettings.SPEEDS[i], host.audio.speed))
	for i in host.audio_pause_buttons.size():
		host.audio_pause_buttons[i].set_pressed_no_signal(AudioSettings.THINK_PAUSES[i] == host.audio.think_pause)
	host.audio_mode_blurb.text = AudioSettings.MODE_BLURBS[host.audio.mode]
	if is_instance_valid(host.audio_summary_label):
		var summary: String = AudioSettings.MODE_TITLES[host.audio.mode]
		if host.audio.mode != AudioSettings.Mode.SILENT:
			summary += "  ·  %s  ·  %s" % [host.speech._voice_short(), AudioSettings.speed_label(host.audio.speed)]
			if host.audio.mode == AudioSettings.Mode.LISTEN:
				summary += "  ·  %d s think" % host.audio.think_pause
		summary += "  ·  " + AudioSettings.sfx_label(host.audio.sfx_enabled, host.audio.sfx_level)
		host.audio_summary_label.text = summary
		# Open, the chips below say the same thing in full.
		host.audio_summary_label.modulate.a = 0.0 if host.audio_expanded else 1.0
		host.audio_body.visible = host.audio_expanded
		host.audio_toggle_button.text = "Done" if host.audio_expanded else "Change"
	host.audio_details_box.visible = host.audio.mode != AudioSettings.Mode.SILENT
	host.auto_teach_toggle.set_pressed_no_signal(host.audio.auto_teach)
	if is_instance_valid(host.reduce_motion_toggle):
		host.reduce_motion_toggle.set_pressed_no_signal(host.audio.reduce_motion)
	if is_instance_valid(host.hunt_keywords_toggle):
		host.hunt_keywords_toggle.set_pressed_no_signal(host.audio.hunt_keywords)
	host.auto_teach_toggle.visible = host.audio.mode == AudioSettings.Mode.AUTO
	host.audio_pause_row.visible = host.audio.mode == AudioSettings.Mode.LISTEN
	host.audio_exam_note.visible = AudioSettings.autoplays_question(host.audio.mode)
	for i in host.sfx_level_buttons.size():
		host.sfx_level_buttons[i].set_pressed_no_signal(i == (host.audio.sfx_level + 1 if host.audio.sfx_enabled else 0))
	# Listen sessions run untimed, so "30 minutes timed" on the drills would lie.
	for b in host.menu_mode_buttons:
		if not is_instance_valid(b) or not b.has_meta("base_text") or bool(b.get_meta("full_exam")) or b.get_meta("keeps_detail", false):
			continue
		var base := str(b.get_meta("base_text"))
		if host.audio.mode == AudioSettings.Mode.LISTEN:
			var cut := base.rfind(" • ")
			b.text = (base.substr(0, cut) if cut > 0 else base) + " • hands-free, untimed"
		else:
			b.text = base
