class_name DesktopLayout
extends RefCounted
## The Windows/desktop layout builder: it creates every node and assigns the
## same members on the host, so the quiz logic in main.gd runs unchanged.
## Sizes, colours and surfaces come from AppTheme tokens (docs/ARCHITECTURE.md,
## "Visual system"). tools/tests/test_layout_tree.gd pins the resulting tree.

static func build(host: Main) -> void:
	# Deep obsidian-black into electric slate-blue gradient
	var bg_gradient := Gradient.new()
	bg_gradient.set_color(0, AppTheme.BG_TOP)
	bg_gradient.set_color(1, AppTheme.BG_BOTTOM)
	var bg_texture := GradientTexture2D.new()
	bg_texture.gradient = bg_gradient
	bg_texture.fill_from = Vector2(0.5, 0.0)
	bg_texture.fill_to = Vector2(0.5, 1.0)
	var bg_rect := TextureRect.new()
	bg_rect.texture = bg_texture
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
	bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(bg_rect)
	host.add_child(UiFx.make_circuit_backdrop())

	host.main_margin = MarginContainer.new()
	host.main_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.main_margin.add_theme_constant_override("margin_left", 20)
	host.main_margin.add_theme_constant_override("margin_right", 20)
	host.main_margin.add_theme_constant_override("margin_top", 24)
	host.main_margin.add_theme_constant_override("margin_bottom", 24)
	host.add_child(host.main_margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	host.main_margin.add_child(root)

	var quiz_scroll := ScrollContainer.new()
	quiz_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	quiz_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quiz_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	quiz_scroll.scroll_started.connect(host._reset_pressed_cards)
	root.add_child(quiz_scroll)
	var quiz_column := VBoxContainer.new()
	quiz_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Fill the viewport so the answered-state feedback sheet can take the rest.
	quiz_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	quiz_column.add_theme_constant_override("separation", 10)
	quiz_scroll.add_child(quiz_column)
	host.quiz_scroll_box = quiz_scroll

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	root.add_child(header)
	root.move_child(header, 0)

	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 2)
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)

	var title := Label.new()
	title.text = "NEC 2023 // JOURNEYMAN CHALLENGE"
	title.add_theme_font_override("font", AppTheme.ui_font(AppTheme.WEIGHT_BOLD))
	title.add_theme_font_size_override("font_size", AppTheme.TYPE_BODY_LG)
	title.add_theme_color_override("font_color", AppTheme.SLATE_50)
	title_box.add_child(title)

	host.progress_label = Label.new()
	host.progress_label.add_theme_font_override("font", AppTheme.meta_font(AppTheme.WEIGHT_SEMIBOLD))
	host.progress_label.add_theme_font_size_override("font_size", AppTheme.TYPE_META)
	host.progress_label.add_theme_color_override("font_color", AppTheme.SKY_400)
	title_box.add_child(host.progress_label)

	# Status strip: pass target (75% per PSI), score, exam clock, item clock.
	var hud := Widgets.make_hud_strip(header)
	host.score_label = Label.new()
	host.pass_badge = Widgets.hud_segment(hud, host.score_label, AppTheme.TYPE_META, AppTheme.EMERALD_300)
	host.streak_label = Label.new()
	Widgets.hud_segment(hud, host.streak_label, AppTheme.TYPE_META, AppTheme.SKY_300)
	host.timer_label = Label.new()
	Widgets.hud_segment(hud, host.timer_label, AppTheme.TYPE_CAPTION, AppTheme.SLATE_50)
	host.question_timer_label = Label.new()
	Widgets.hud_segment(hud, host.question_timer_label, AppTheme.TYPE_CAPTION, AppTheme.SKY_400)

	host.question_panel = PanelContainer.new()
	host.question_panel.add_theme_stylebox_override("panel", host._question_panel_style())
	UiFx.add_glass(host.question_panel)
	quiz_column.add_child(host.question_panel)
	var question_margin := MarginContainer.new()
	question_margin.add_theme_constant_override("margin_left", AppTheme.SPACE_XL - 4)
	question_margin.add_theme_constant_override("margin_right", AppTheme.SPACE_XL - 4)
	question_margin.add_theme_constant_override("margin_top", AppTheme.SPACE_LG - 2)
	question_margin.add_theme_constant_override("margin_bottom", AppTheme.SPACE_LG - 2)
	host.question_panel.add_child(question_margin)
	var question_column := VBoxContainer.new()
	question_column.add_theme_constant_override("separation", AppTheme.SPACE_SM + 1)
	question_margin.add_child(question_column)

	# Exam Header Pills Row
	host.exam_pills_row = HBoxContainer.new()
	host.exam_pills_row.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	question_column.add_child(host.exam_pills_row)

	host.exam_label = Label.new()
	host.exam_label.visible = false
	host.exam_pills_row.add_child(host.exam_label)

	var mode_pill_panel := PanelContainer.new()
	mode_pill_panel.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.PILL_BLUE_BG, AppTheme.BORDER_BLUE, AppTheme.BORDER_HAIRLINE, AppTheme.RADIUS_INNER))
	var mode_pill_m := MarginContainer.new()
	mode_pill_m.add_theme_constant_override("margin_left", AppTheme.SPACE_SM + 2)
	mode_pill_m.add_theme_constant_override("margin_right", AppTheme.SPACE_SM + 2)
	mode_pill_m.add_theme_constant_override("margin_top", 3)
	mode_pill_m.add_theme_constant_override("margin_bottom", 3)
	mode_pill_panel.add_child(mode_pill_m)
	host.exam_mode_pill = Label.new()
	host.exam_mode_pill.add_theme_font_override("font", AppTheme.meta_font())
	host.exam_mode_pill.add_theme_font_size_override("font_size", AppTheme.TYPE_MICRO)
	host.exam_mode_pill.add_theme_color_override("font_color", AppTheme.SKY_400)
	mode_pill_m.add_child(host.exam_mode_pill)
	host.exam_pills_row.add_child(mode_pill_panel)

	var lic_pill_panel := PanelContainer.new()
	lic_pill_panel.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.PILL_SLATE_BG, AppTheme.HAIRLINE_BRIGHT, AppTheme.BORDER_HAIRLINE, AppTheme.RADIUS_INNER))
	var lic_pill_m := MarginContainer.new()
	lic_pill_m.add_theme_constant_override("margin_left", AppTheme.SPACE_SM + 2)
	lic_pill_m.add_theme_constant_override("margin_right", AppTheme.SPACE_SM + 2)
	lic_pill_m.add_theme_constant_override("margin_top", 3)
	lic_pill_m.add_theme_constant_override("margin_bottom", 3)
	lic_pill_panel.add_child(lic_pill_m)
	host.exam_license_pill = Label.new()
	host.exam_license_pill.add_theme_font_override("font", AppTheme.meta_font(AppTheme.WEIGHT_SEMIBOLD))
	host.exam_license_pill.add_theme_font_size_override("font_size", AppTheme.TYPE_MICRO)
	host.exam_license_pill.add_theme_color_override("font_color", AppTheme.SLATE_300)
	lic_pill_m.add_child(host.exam_license_pill)
	host.exam_pills_row.add_child(lic_pill_panel)

	# Question Stem Voice Visualizer Badge
	host.prompt_voice_badge = PanelContainer.new()
	host.prompt_voice_badge.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.VOICE_BADGE_BG, AppTheme.SKY_600, AppTheme.BORDER_HAIRLINE, AppTheme.RADIUS_INNER))
	var pvb_margin := MarginContainer.new()
	pvb_margin.add_theme_constant_override("margin_left", 8)
	pvb_margin.add_theme_constant_override("margin_right", 8)
	pvb_margin.add_theme_constant_override("margin_top", 3)
	pvb_margin.add_theme_constant_override("margin_bottom", 3)
	host.prompt_voice_badge.add_child(pvb_margin)
	var pvb_hbox := HBoxContainer.new()
	pvb_hbox.add_theme_constant_override("separation", 6)
	pvb_margin.add_child(pvb_hbox)
	host.prompt_visualizer = VoiceVisualizer.new()
	host.prompt_visualizer.bar_count = 4
	host.prompt_visualizer.bar_width = 2.5
	host.prompt_visualizer.bar_gap = 2.0
	host.prompt_visualizer.custom_minimum_size = Vector2(18, 14)
	host.prompt_visualizer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pvb_hbox.add_child(host.prompt_visualizer)
	var pvb_text := Label.new()
	pvb_text.text = "READING AUDIO"
	pvb_text.add_theme_font_override("font", AppTheme.meta_font())
	pvb_text.add_theme_font_size_override("font_size", AppTheme.TYPE_MICRO - 1)
	pvb_text.add_theme_color_override("font_color", AppTheme.SKY_400)
	pvb_hbox.add_child(pvb_text)
	host.prompt_voice_badge.visible = false
	host.exam_pills_row.add_child(host.prompt_voice_badge)

	host.question_label = Label.new()
	host.question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.question_label.add_theme_font_override("font", AppTheme.ui_font(AppTheme.WEIGHT_SEMIBOLD))
	host.question_label.add_theme_font_size_override("font_size", AppTheme.TYPE_TITLE)
	host.question_label.add_theme_color_override("font_color", AppTheme.WHITE)
	question_column.add_child(host.question_label)

	# Subtitle / Gist Hint with Left Accent Bar
	var hint_hbox := HBoxContainer.new()
	host.question_hint_row = hint_hbox
	hint_hbox.add_theme_constant_override("separation", AppTheme.SPACE_SM + 2)
	question_column.add_child(hint_hbox)

	var hint_bar := ColorRect.new()
	hint_bar.custom_minimum_size = Vector2(AppTheme.ACCENT_BAR_W - 1, 18)
	hint_bar.size_flags_vertical = Control.SIZE_FILL
	hint_bar.color = AppTheme.SKY_400
	hint_hbox.add_child(hint_bar)

	host.article_label = Label.new()
	host.article_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.article_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.article_label.add_theme_font_override("font", AppTheme.ui_font(AppTheme.WEIGHT_MEDIUM))
	host.article_label.add_theme_font_size_override("font_size", AppTheme.TYPE_BODY_SM)
	host.article_label.add_theme_color_override("font_color", AppTheme.SLATE_200)
	hint_hbox.add_child(host.article_label)

	# Lookup Path Callout Box
	host.lookup_box = PanelContainer.new()
	var lookup_style := AppTheme.panel_style(AppTheme.LOOKUP_BG, AppTheme.HAIRLINE_BRIGHT, AppTheme.BORDER_HAIRLINE, AppTheme.RADIUS_INNER)
	host.lookup_box.add_theme_stylebox_override("panel", lookup_style)
	question_column.add_child(host.lookup_box)
	var lookup_margin := MarginContainer.new()
	lookup_margin.add_theme_constant_override("margin_left", AppTheme.SPACE_MD)
	lookup_margin.add_theme_constant_override("margin_right", AppTheme.SPACE_MD)
	lookup_margin.add_theme_constant_override("margin_top", AppTheme.SPACE_XS + 2)
	lookup_margin.add_theme_constant_override("margin_bottom", AppTheme.SPACE_XS + 2)
	host.lookup_box.add_child(lookup_margin)

	host.chapter_hint_label = Label.new()
	host.chapter_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.chapter_hint_label.add_theme_font_override("font", AppTheme.ui_font(AppTheme.WEIGHT_MEDIUM))
	host.chapter_hint_label.add_theme_font_size_override("font_size", AppTheme.TYPE_META)
	host.chapter_hint_label.add_theme_color_override("font_color", AppTheme.SKY_400)
	lookup_margin.add_child(host.chapter_hint_label)
	host.lookup_box.visible = false

	# Connect lookup box visibility to chapter hint
	host.chapter_hint_label.item_rect_changed.connect(func():
		if is_instance_valid(host.lookup_box) and is_instance_valid(host.chapter_hint_label):
			host.lookup_box.visible = host.chapter_hint_label.visible
	)

	host.question_table_panel = PanelContainer.new()
	host.question_table_panel.add_theme_stylebox_override("panel", AppTheme.surface(AppTheme.PAPER_BOTTOM, AppTheme.PAPER_BORDER, AppTheme.ELEVATION_REST, AppTheme.RADIUS_INNER))
	UiFx.add_glass(host.question_table_panel, AppTheme.GRAD_PAPER, AppTheme.RADIUS_INNER)
	host.question_table_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.question_table_panel.visible = false
	question_column.add_child(host.question_table_panel)
	var question_table_margin := MarginContainer.new()
	question_table_margin.add_theme_constant_override("margin_left", 10)
	question_table_margin.add_theme_constant_override("margin_right", 10)
	question_table_margin.add_theme_constant_override("margin_top", 7)
	question_table_margin.add_theme_constant_override("margin_bottom", 7)
	host.question_table_panel.add_child(question_table_margin)
	var question_table_column := VBoxContainer.new()
	question_table_column.add_theme_constant_override("separation", 5)
	question_table_margin.add_child(question_table_column)
	host.question_table_heading = Label.new()
	host.question_table_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.question_table_heading.add_theme_font_override("font", AppTheme.meta_font(AppTheme.WEIGHT_SEMIBOLD))
	host.question_table_heading.add_theme_font_size_override("font_size", AppTheme.TYPE_META)
	host.question_table_heading.add_theme_color_override("font_color", AppTheme.SKY_300)
	question_table_column.add_child(host.question_table_heading)
	host.question_table_scroll = ScrollContainer.new()
	host.question_table_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.question_table_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	host.question_table_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	question_table_column.add_child(host.question_table_scroll)
	host.question_table_grid = GridContainer.new()
	host.question_table_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.question_table_grid.add_theme_constant_override("h_separation", 0)
	host.question_table_grid.add_theme_constant_override("v_separation", 0)
	host.question_table_scroll.add_child(host.question_table_grid)
	host.question_table_scroll.resized.connect(TableViewer.fit_columns.bind(host.question_table_grid))
	host.question_table_note = Label.new()
	host.question_table_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.question_table_note.add_theme_font_size_override("font_size", 11)
	host.question_table_note.add_theme_color_override("font_color", AppTheme.SLATE_300)
	question_table_column.add_child(host.question_table_note)

	host.question_diagram_panel = PanelContainer.new()
	# Paper card: the figures are black-on-white scans of the exam page.
	host.question_diagram_panel.add_theme_stylebox_override("panel", AppTheme.surface(AppTheme.SLATE_50, AppTheme.SKY_400, AppTheme.ELEVATION_REST, AppTheme.RADIUS_INNER))
	host.question_diagram_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.question_diagram_panel.visible = false
	question_column.add_child(host.question_diagram_panel)
	var diagram_margin := MarginContainer.new()
	diagram_margin.add_theme_constant_override("margin_left", 8)
	diagram_margin.add_theme_constant_override("margin_right", 8)
	diagram_margin.add_theme_constant_override("margin_top", 6)
	diagram_margin.add_theme_constant_override("margin_bottom", 6)
	host.question_diagram_panel.add_child(diagram_margin)
	host.question_diagram_view = DiagramView.new()
	host.question_diagram_view.max_height = FitController.DIAGRAM_MAX_H_DESKTOP
	diagram_margin.add_child(host.question_diagram_view)

	# Calculation Reference Box
	host.formula_box = PanelContainer.new()
	var formula_style := AppTheme.surface(AppTheme.PAPER_BOTTOM, AppTheme.PAPER_BORDER, AppTheme.ELEVATION_REST, AppTheme.RADIUS_INNER)
	formula_style.border_width_left = AppTheme.ACCENT_BAR_W - 1
	formula_style.border_color = AppTheme.BLUE_600
	host.formula_box.add_theme_stylebox_override("panel", formula_style)
	question_column.add_child(host.formula_box)
	var formula_margin := MarginContainer.new()
	formula_margin.add_theme_constant_override("margin_left", AppTheme.SPACE_MD)
	formula_margin.add_theme_constant_override("margin_right", AppTheme.SPACE_MD)
	formula_margin.add_theme_constant_override("margin_top", AppTheme.SPACE_XS + 2)
	formula_margin.add_theme_constant_override("margin_bottom", AppTheme.SPACE_XS + 2)
	host.formula_box.add_child(formula_margin)

	host.question_formula_label = Label.new()
	host.question_formula_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.question_formula_label.add_theme_font_override("font", AppTheme.numeric_font(AppTheme.WEIGHT_MEDIUM))
	host.question_formula_label.add_theme_font_size_override("font_size", AppTheme.TYPE_CAPTION)
	host.question_formula_label.add_theme_color_override("font_color", AppTheme.BLUE_300)
	formula_margin.add_child(host.question_formula_label)
	host.formula_box.visible = false

	# Connect formula box visibility to question_formula_label
	host.question_formula_label.item_rect_changed.connect(func():
		if is_instance_valid(host.formula_box) and is_instance_valid(host.question_formula_label):
			host.formula_box.visible = host.question_formula_label.visible
	)

	host.timer_bar = ProgressBar.new()
	host.timer_bar.min_value = 0
	host.timer_bar.max_value = Main.SESSION_TIME_SECONDS
	host.timer_bar.show_percentage = false
	host.timer_bar.custom_minimum_size = Vector2(0, ProgressSegments.BAR_H)
	var bar_bg := AppTheme.panel_style(AppTheme.PANEL_BOTTOM, AppTheme.HAIRLINE, 0, 2)
	var bar_fill := AppTheme.panel_style(AppTheme.SKY_500, AppTheme.SKY_400, 0, 2)
	host.timer_bar.add_theme_stylebox_override("background", bar_bg)
	host.timer_bar.add_theme_stylebox_override("fill", bar_fill)
	question_column.add_child(host.timer_bar)

	host.answers_box = VBoxContainer.new()
	host.answers_box.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	host.answers_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.answers_box.size_flags_stretch_ratio = 1.5
	# Wide windows put the lookup material beside the choices instead of
	# stacking it above them; narrow ones flip the row to a column.
	host.answers_row = BoxContainer.new()
	host.answers_row.add_theme_constant_override("separation", 14)
	quiz_column.add_child(host.answers_row)
	host.answers_row.add_child(host.answers_box)
	host.ref_column = VBoxContainer.new()
	host.ref_column.add_theme_constant_override("separation", 8)
	host.ref_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.ref_column.visible = false
	host.answers_row.add_child(host.ref_column)
	for ref_panel in [host.question_table_panel, host.question_diagram_panel, host.formula_box]:
		ref_panel.reparent(host.ref_column, false)

	host.feedback_panel = PanelContainer.new()
	host.feedback_panel.add_theme_stylebox_override("panel", AppTheme.surface(AppTheme.PANEL_BOTTOM, AppTheme.HAIRLINE_BRIGHT, AppTheme.ELEVATION_CARD))
	UiFx.add_glass(host.feedback_panel, AppTheme.GRAD_PANEL)
	quiz_column.add_child(host.feedback_panel)
	var feedback_margin := MarginContainer.new()
	feedback_margin.add_theme_constant_override("margin_left", AppTheme.SPACE_LG)
	feedback_margin.add_theme_constant_override("margin_right", AppTheme.SPACE_LG)
	feedback_margin.add_theme_constant_override("margin_top", AppTheme.SPACE_MD)
	feedback_margin.add_theme_constant_override("margin_bottom", AppTheme.SPACE_MD)
	host.feedback_panel.add_child(feedback_margin)
	var feedback_column := VBoxContainer.new()
	feedback_column.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	feedback_margin.add_child(feedback_column)
	Widgets.add_feedback_title(host, feedback_column, AppTheme.TYPE_HEADING)
	host.feedback_body = Label.new()
	host.feedback_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.feedback_body.add_theme_font_override("font", AppTheme.ui_font(AppTheme.WEIGHT_MEDIUM))
	host.feedback_body.add_theme_font_size_override("font_size", AppTheme.TYPE_BODY_SM)
	host.feedback_body.add_theme_color_override("font_color", AppTheme.SLATE_100)
	feedback_column.add_child(host.feedback_body)
	host.feedback_reference = Label.new()
	host.feedback_reference.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.feedback_reference.add_theme_font_override("font", AppTheme.ui_font(AppTheme.WEIGHT_SEMIBOLD))
	host.feedback_reference.add_theme_font_size_override("font_size", AppTheme.TYPE_CAPTION)
	host.feedback_reference.add_theme_color_override("font_color", AppTheme.SKY_300)
	host.feedback_reference.visible = false
	feedback_column.add_child(host.feedback_reference)
	var feedback_detail := host._make_feedback_detail(feedback_column)
	host.feedback_table_scroll = ScrollContainer.new()
	host.feedback_table_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.feedback_table_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	host.feedback_table_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.feedback_table_scroll.visible = false
	feedback_detail.add_child(host.feedback_table_scroll)
	host.feedback_table_grid = GridContainer.new()
	host.feedback_table_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.feedback_table_grid.add_theme_constant_override("h_separation", 0)
	host.feedback_table_grid.add_theme_constant_override("v_separation", 0)
	host.feedback_table_scroll.add_child(host.feedback_table_grid)
	host.feedback_table_scroll.resized.connect(TableViewer.fit_columns.bind(host.feedback_table_grid))
	host.feedback_table_note = Label.new()
	host.feedback_table_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.feedback_table_note.add_theme_font_size_override("font_size", 11)
	host.feedback_table_note.add_theme_color_override("font_color", AppTheme.SLATE_300)
	host.feedback_table_note.visible = false
	feedback_detail.add_child(host.feedback_table_note)
	host.info_label = RichTextLabel.new()
	host.info_label.fit_content = true
	host.info_label.scroll_active = false
	host.info_label.custom_minimum_size = Vector2(0, 0)
	host.info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Widgets.style_info_label(host.info_label, AppTheme.TYPE_BODY_SM)
	host.info_label.visible = false
	feedback_detail.add_child(host.info_label)
	host.next_button = Widgets.make_primary_button("Next question", 44, AppTheme.TYPE_BODY, host._on_next_button_pressed)
	host.next_button.visible = false
	root.add_child(host.next_button)

	host.dock_panel = PanelContainer.new()
	host.dock_panel.add_theme_stylebox_override("panel", AppTheme.surface(AppTheme.PANEL_BOTTOM, AppTheme.HAIRLINE, AppTheme.ELEVATION_REST))
	UiFx.add_glass(host.dock_panel, AppTheme.GRAD_PANEL)
	root.add_child(host.dock_panel)

	var dock_margin := MarginContainer.new()
	dock_margin.add_theme_constant_override("margin_left", AppTheme.SPACE_MD)
	dock_margin.add_theme_constant_override("margin_right", AppTheme.SPACE_MD)
	dock_margin.add_theme_constant_override("margin_top", AppTheme.SPACE_SM)
	dock_margin.add_theme_constant_override("margin_bottom", AppTheme.SPACE_SM)
	host.dock_panel.add_child(dock_margin)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", AppTheme.SPACE_MD)
	dock_margin.add_child(controls)

	host.mute_button = Widgets.make_dock_button("Sound off", 118, 42, AppTheme.TYPE_CAPTION, host._toggle_session_mute, "speaker")
	controls.add_child(host.mute_button)

	host.read_button = Widgets.make_dock_button(host.speech._idle_read_label(), 0, 42, AppTheme.TYPE_BODY_SM, host._toggle_read, "replay")
	host.read_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.read_button.add_theme_color_override("font_color", AppTheme.SLATE_100)
	host.read_button.add_theme_color_override("icon_normal_color", AppTheme.SKY_400)
	controls.add_child(host.read_button)

	host.pause_button = Widgets.make_dock_button("Pause", 130, 42, AppTheme.TYPE_BODY_SM, host._toggle_listen_pause, "pause")
	controls.add_child(host.pause_button)
	host.skip_button = Widgets.make_dock_button("Skip", 110, 42, AppTheme.TYPE_BODY_SM, host._listen_skip, "skip")
	controls.add_child(host.skip_button)

	# Bottom Dock Voice Visualizer Pod
	host.dock_visualizer = VoiceVisualizer.new()
	host.dock_visualizer.bar_count = 6
	host.dock_visualizer.bar_width = 3.5
	host.dock_visualizer.bar_gap = 3.0
	host.dock_visualizer.custom_minimum_size = Vector2(40, 24)
	host.dock_visualizer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	host.dock_visualizer.visible = false
	controls.add_child(host.dock_visualizer)

	# NOW READING indicator: unmissable text showing exactly which part is spoken.
	host.read_status_label = Label.new()
	host.read_status_label.text = ""
	host.read_status_label.visible = false
	host.read_status_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	host.read_status_label.add_theme_font_override("font", AppTheme.meta_font())
	host.read_status_label.add_theme_font_size_override("font_size", AppTheme.TYPE_META)
	host.read_status_label.add_theme_color_override("font_color", AppTheme.SKY_400)
	host.read_status_label.clip_text = true
	# clip_text drops the min width to zero, so beside an expanding button the
	# label would get no room at all; reserve space while it is visible.
	host.read_status_label.custom_minimum_size = Vector2(250, 0)
	controls.add_child(host.read_status_label)

	host.restart_button = Widgets.make_dock_button("Main menu", 110, 42, AppTheme.TYPE_BODY_SM, host._request_menu, "menu")
	controls.add_child(host.restart_button)

	host.feedback_panel.visible = false

	host.menu_overlay = Control.new()
	host.menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.menu_overlay.z_index = 20
	host.add_child(host.menu_overlay)
	var menu_background := ColorRect.new()
	menu_background.color = AppTheme.BG_TOP
	menu_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.menu_overlay.add_child(menu_background)
	host.menu_overlay.add_child(UiFx.make_circuit_backdrop(UiFx.BACKDROP_DRIFT_MENU))
	var menu_scroll := ScrollContainer.new()
	menu_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.menu_overlay.add_child(menu_scroll)
	host.menu_center_box = MarginContainer.new()
	host.menu_center_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.menu_center_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host.menu_center_box.add_theme_constant_override("margin_left", 20)
	host.menu_center_box.add_theme_constant_override("margin_right", 20)
	host.menu_center_box.add_theme_constant_override("margin_top", 24)
	host.menu_center_box.add_theme_constant_override("margin_bottom", 24)
	menu_scroll.add_child(host.menu_center_box)

	var menu_outer_center := CenterContainer.new()
	menu_outer_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_outer_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host.menu_center_box.add_child(menu_outer_center)

	host.menu_panel = PanelContainer.new()
	host.menu_panel.custom_minimum_size = Vector2(860, 0)
	var panel_sb := AppTheme.surface(AppTheme.SURFACE_BOTTOM, AppTheme.HAIRLINE_BRIGHT, AppTheme.ELEVATION_FLOAT, AppTheme.RADIUS + 4)
	panel_sb.border_width_top = AppTheme.BORDER_STRONG + 1
	panel_sb.border_color = AppTheme.SKY_400
	host.menu_panel.add_theme_stylebox_override("panel", panel_sb)
	UiFx.add_glass(host.menu_panel, AppTheme.GRAD_SURFACE, AppTheme.RADIUS + 4)
	menu_outer_center.add_child(host.menu_panel)

	var menu_margin := MarginContainer.new()
	menu_margin.add_theme_constant_override("margin_left", AppTheme.SPACE_XL + AppTheme.SPACE_SM)
	menu_margin.add_theme_constant_override("margin_right", AppTheme.SPACE_XL + AppTheme.SPACE_SM)
	menu_margin.add_theme_constant_override("margin_top", AppTheme.SPACE_XL)
	menu_margin.add_theme_constant_override("margin_bottom", AppTheme.SPACE_XL)
	host.menu_panel.add_child(menu_margin)

	var menu_column := VBoxContainer.new()
	menu_column.add_theme_constant_override("separation", AppTheme.SPACE_SM + 2)
	menu_margin.add_child(menu_column)
	host.menu_column = menu_column

	Widgets.add_menu_hero(host, menu_column, 76, AppTheme.TYPE_TITLE, "NFPA 70 • NEC 2023 EDITION • PSI EXAM STANDARDS")

	var practice_header := Widgets.make_section_header("RAPID PRACTICE DRILLS")
	menu_column.add_child(practice_header)
	menu_column.move_child(AudioSection.build(host, menu_column), practice_header.get_index())

	host.menu_mode_buttons.clear()
	Widgets.add_mode_button(host, menu_column, "10 QUESTIONS", "Quick warm-up drill • 30 minutes timed", host._start_quiz.bind(10, host._practice_time(10), true, "10-Question Practice"))
	Widgets.add_mode_button(host, menu_column, "20 QUESTIONS", "Standard focused session • 60 minutes timed", host._start_quiz.bind(20, host._practice_time(20), true, "20-Question Practice"))
	Widgets.add_mode_button(host, menu_column, "30 QUESTIONS", "Extended study block • 90 minutes timed", host._start_quiz.bind(30, host._practice_time(30), true, "30-Question Practice"))
	Widgets.add_mode_button(host, menu_column, "40 QUESTIONS", "Half-length diagnostic test • 120 minutes timed", host._start_quiz.bind(40, host._practice_time(40), true, "40-Question Practice"))
	Widgets.add_mode_button(host, menu_column, "50 QUESTIONS", "Intensive endurance drill • 150 minutes timed", host._start_quiz.bind(50, host._practice_time(50), true, "50-Question Practice"))
	Widgets.add_mode_button(host, menu_column, "10 QUESTIONS • WEAKEST AREA", host._study_button_subtitle(), host._start_area_drill, AppTheme.SKY_300, AppTheme.SURFACE_BOTTOM, false, -1.0, -1, "target")
	host.study_button = host.menu_mode_buttons.back()
	Widgets.add_state_law_section(host, menu_column)

	menu_column.add_child(Widgets.make_section_header("OFFICIAL LICENSING SIMULATION", AppTheme.ROSE_400))
	Widgets.add_mode_button(host, menu_column, "FULL JOURNEYMAN SIMULATOR", "80 scored questions • 240 minutes • 75% required to pass", host._start_quiz.bind(80, Main.EXAM_MINUTES * 60, true, "Full Journeyman Exam"), AppTheme.ROSE_500, AppTheme.EXAM_BUTTON_BG, true, -1.0, -1, "bolt")

	var menu_note := Label.new()
	menu_note.text = "Aligned with NFPA 70 (NEC 2023) & Nebraska State Electrical Division / PSI Standards\nPacing standard: 3:00 per scored item • 80 questions timed"
	menu_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_note.add_theme_font_override("font", AppTheme.ui_font(AppTheme.WEIGHT_REGULAR))
	menu_note.add_theme_font_size_override("font_size", AppTheme.TYPE_MICRO)
	menu_note.add_theme_color_override("font_color", AppTheme.SLATE_400)
	menu_column.add_child(menu_note)
