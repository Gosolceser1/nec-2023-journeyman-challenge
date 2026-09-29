class_name MobileLayout
extends RefCounted
## The Android/mobile layout builder: same member set as DesktopLayout,
## touch-first sizes, and the same AppTheme tokens and surfaces. The two
## builders stay separate on purpose; tools/tests/test_layout_tree.gd pins
## both trees.

static func build(host: Main) -> void:
	# ANDROID layout: touch-first, phone-safe. Same member set as desktop so all
	# game logic runs untouched; roomier targets, two-row header, narrow-safe menu.
	# prompt_voice_badge / prompt_visualizer stay null by design (all uses guarded) —
	# the dock status line is the mobile "now reading" indicator.
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
	host.main_margin.add_theme_constant_override("margin_left", AppTheme.SPACE_LG)
	host.main_margin.add_theme_constant_override("margin_right", AppTheme.SPACE_LG)
	host.main_margin.add_theme_constant_override("margin_top", AppTheme.SPACE_LG)
	host.main_margin.add_theme_constant_override("margin_bottom", AppTheme.SPACE_LG)
	host.add_child(host.main_margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", AppTheme.SPACE_SM + 2)
	host.main_margin.add_child(root)

	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", AppTheme.SPACE_XS + 2)
	root.add_child(header)
	# One line for title + progress: every pixel of header is a pixel of question.
	var title_box := HBoxContainer.new()
	title_box.add_theme_constant_override("separation", AppTheme.SPACE_SM + 2)
	header.add_child(title_box)
	var title := Label.new()
	title.text = MenuModel.fill(str(MenuModel.spec().get("title_short", "")), {"edition": Edition.short_label()})
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	title.add_theme_font_override("font", AppTheme.ui_font(AppTheme.WEIGHT_BOLD))
	title.add_theme_font_size_override("font_size", AppTheme.TYPE_BODY_LG - 1)
	title.add_theme_color_override("font_color", AppTheme.SLATE_50)
	title_box.add_child(title)
	host.progress_label = Label.new()
	host.progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	host.progress_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	host.progress_label.add_theme_font_override("font", AppTheme.meta_font())
	host.progress_label.add_theme_font_size_override("font_size", AppTheme.TYPE_META)
	host.progress_label.add_theme_color_override("font_color", AppTheme.SKY_400)
	title_box.add_child(host.progress_label)

	# Status strip, four equal cells: pass target, score, exam clock, item clock.
	var hud := Widgets.make_hud_strip(header, true)
	host.score_label = Label.new()
	host.pass_badge = Widgets.hud_segment(hud, host.score_label, AppTheme.TYPE_META, AppTheme.EMERALD_300, true)
	host.streak_label = Label.new()
	Widgets.hud_segment(hud, host.streak_label, AppTheme.TYPE_META, AppTheme.SKY_300, true)
	host.timer_label = Label.new()
	Widgets.hud_segment(hud, host.timer_label, AppTheme.TYPE_META, AppTheme.SLATE_50, true)
	host.question_timer_label = Label.new()
	Widgets.hud_segment(hud, host.question_timer_label, AppTheme.TYPE_META, AppTheme.SKY_400, true)

	var quiz_scroll := ScrollContainer.new()
	quiz_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	quiz_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quiz_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	quiz_scroll.scroll_started.connect(host._reset_pressed_cards)
	root.add_child(quiz_scroll)
	var quiz_column := VBoxContainer.new()
	quiz_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quiz_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	quiz_column.add_theme_constant_override("separation", AppTheme.SPACE_SM + 2)
	quiz_scroll.add_child(quiz_column)
	host.quiz_scroll_box = quiz_scroll

	host.question_panel = PanelContainer.new()
	host.question_panel.add_theme_stylebox_override("panel", host._question_panel_style())
	UiFx.add_glass(host.question_panel)
	quiz_column.add_child(host.question_panel)
	var question_margin := MarginContainer.new()
	question_margin.add_theme_constant_override("margin_left", AppTheme.SPACE_MD + 2)
	question_margin.add_theme_constant_override("margin_right", AppTheme.SPACE_MD + 2)
	question_margin.add_theme_constant_override("margin_top", AppTheme.SPACE_MD)
	question_margin.add_theme_constant_override("margin_bottom", AppTheme.SPACE_MD)
	host.question_panel.add_child(question_margin)
	var question_column := VBoxContainer.new()
	question_column.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	question_margin.add_child(question_column)

	# Session pills restate what the player just picked on the menu; on a
	# phone that row costs a card's worth of height, so it stays built but hidden.
	host.exam_pills_row = HBoxContainer.new()
	host.exam_pills_row.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	host.exam_pills_row.visible = false
	question_column.add_child(host.exam_pills_row)
	host.exam_label = Label.new()
	host.exam_label.visible = false
	host.exam_pills_row.add_child(host.exam_label)
	var mode_pill_panel := PanelContainer.new()
	mode_pill_panel.add_theme_stylebox_override("panel", AppTheme.pad(AppTheme.panel_style(AppTheme.PILL_BLUE_BG, AppTheme.BORDER_BLUE, AppTheme.BORDER_HAIRLINE, AppTheme.RADIUS_INNER), AppTheme.SPACE_SM, AppTheme.SPACE_XS))
	host.exam_mode_pill = Label.new()
	host.exam_mode_pill.add_theme_font_override("font", AppTheme.meta_font())
	host.exam_mode_pill.add_theme_font_size_override("font_size", AppTheme.TYPE_META)
	host.exam_mode_pill.add_theme_color_override("font_color", AppTheme.SKY_400)
	mode_pill_panel.add_child(host.exam_mode_pill)
	host.exam_pills_row.add_child(mode_pill_panel)
	var lic_pill_panel := PanelContainer.new()
	lic_pill_panel.add_theme_stylebox_override("panel", AppTheme.pad(AppTheme.panel_style(AppTheme.PILL_SLATE_BG, AppTheme.HAIRLINE_BRIGHT, AppTheme.BORDER_HAIRLINE, AppTheme.RADIUS_INNER), AppTheme.SPACE_SM, AppTheme.SPACE_XS))
	host.exam_license_pill = Label.new()
	host.exam_license_pill.add_theme_font_override("font", AppTheme.meta_font(AppTheme.WEIGHT_SEMIBOLD))
	host.exam_license_pill.add_theme_font_size_override("font_size", AppTheme.TYPE_META)
	host.exam_license_pill.add_theme_color_override("font_color", AppTheme.SLATE_300)
	lic_pill_panel.add_child(host.exam_license_pill)
	host.exam_pills_row.add_child(lic_pill_panel)
	host.question_label = Label.new()
	host.question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.question_label.add_theme_font_override("font", AppTheme.ui_font(AppTheme.WEIGHT_SEMIBOLD))
	host.question_label.add_theme_font_size_override("font_size", AppTheme.TYPE_TITLE + 1)
	host.question_label.add_theme_color_override("font_color", AppTheme.WHITE)
	question_column.add_child(host.question_label)

	var hint_hbox := HBoxContainer.new()
	hint_hbox.add_theme_constant_override("separation", AppTheme.SPACE_SM + 2)
	question_column.add_child(hint_hbox)
	host.question_hint_row = hint_hbox
	var hint_bar := ColorRect.new()
	hint_bar.custom_minimum_size = Vector2(AppTheme.ACCENT_BAR_W - 1, 18)
	hint_bar.size_flags_vertical = Control.SIZE_FILL
	hint_bar.color = AppTheme.SKY_400
	hint_hbox.add_child(hint_bar)
	host.article_label = Label.new()
	host.article_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.article_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.article_label.add_theme_font_override("font", AppTheme.ui_font(AppTheme.WEIGHT_MEDIUM))
	host.article_label.add_theme_font_size_override("font_size", AppTheme.TYPE_BODY)
	host.article_label.add_theme_color_override("font_color", AppTheme.SLATE_200)
	hint_hbox.add_child(host.article_label)

	host.lookup_box = PanelContainer.new()
	host.lookup_box.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.LOOKUP_BG, AppTheme.HAIRLINE_BRIGHT, AppTheme.BORDER_HAIRLINE, AppTheme.RADIUS_INNER))
	question_column.add_child(host.lookup_box)
	var lookup_margin := MarginContainer.new()
	lookup_margin.add_theme_constant_override("margin_left", AppTheme.SPACE_MD)
	lookup_margin.add_theme_constant_override("margin_right", AppTheme.SPACE_MD)
	lookup_margin.add_theme_constant_override("margin_top", AppTheme.SPACE_SM)
	lookup_margin.add_theme_constant_override("margin_bottom", AppTheme.SPACE_SM)
	host.lookup_box.add_child(lookup_margin)
	host.chapter_hint_label = Label.new()
	host.chapter_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.chapter_hint_label.add_theme_font_override("font", AppTheme.ui_font(AppTheme.WEIGHT_MEDIUM))
	host.chapter_hint_label.add_theme_font_size_override("font_size", AppTheme.TYPE_CAPTION)
	host.chapter_hint_label.add_theme_color_override("font_color", AppTheme.SKY_400)
	lookup_margin.add_child(host.chapter_hint_label)
	host.lookup_box.visible = false
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
	host.question_table_note.add_theme_font_size_override("font_size", AppTheme.TYPE_META)
	host.question_table_note.add_theme_color_override("font_color", AppTheme.SLATE_300)
	question_table_column.add_child(host.question_table_note)

	host.question_diagram_panel = PanelContainer.new()
	# Paper card: the figures are black-on-white scans of the exam page.
	host.question_diagram_panel.add_theme_stylebox_override("panel", AppTheme.surface(AppTheme.SLATE_50, AppTheme.SKY_400, AppTheme.ELEVATION_REST, AppTheme.RADIUS_INNER))
	host.question_diagram_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.question_diagram_panel.visible = false
	question_column.add_child(host.question_diagram_panel)
	var diagram_margin := MarginContainer.new()
	diagram_margin.add_theme_constant_override("margin_left", AppTheme.SPACE_SM)
	diagram_margin.add_theme_constant_override("margin_right", AppTheme.SPACE_SM)
	diagram_margin.add_theme_constant_override("margin_top", AppTheme.SPACE_XS + 2)
	diagram_margin.add_theme_constant_override("margin_bottom", AppTheme.SPACE_XS + 2)
	host.question_diagram_panel.add_child(diagram_margin)
	host.question_diagram_view = DiagramView.new()
	host.question_diagram_view.max_height = FitController.DIAGRAM_MAX_H_MOBILE
	diagram_margin.add_child(host.question_diagram_view)

	host.formula_box = PanelContainer.new()
	var formula_style := AppTheme.surface(AppTheme.PAPER_BOTTOM, AppTheme.PAPER_BORDER, AppTheme.ELEVATION_REST, AppTheme.RADIUS_INNER)
	formula_style.border_width_left = AppTheme.ACCENT_BAR_W - 1
	formula_style.border_color = AppTheme.BLUE_600
	host.formula_box.add_theme_stylebox_override("panel", formula_style)
	question_column.add_child(host.formula_box)
	var formula_margin := MarginContainer.new()
	formula_margin.add_theme_constant_override("margin_left", AppTheme.SPACE_MD)
	formula_margin.add_theme_constant_override("margin_right", AppTheme.SPACE_MD)
	formula_margin.add_theme_constant_override("margin_top", AppTheme.SPACE_SM)
	formula_margin.add_theme_constant_override("margin_bottom", AppTheme.SPACE_SM)
	host.formula_box.add_child(formula_margin)
	host.question_formula_label = Label.new()
	host.question_formula_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.question_formula_label.add_theme_font_override("font", AppTheme.numeric_font(AppTheme.WEIGHT_MEDIUM))
	host.question_formula_label.add_theme_font_size_override("font_size", AppTheme.TYPE_BODY_SM)
	host.question_formula_label.add_theme_color_override("font_color", AppTheme.BLUE_300)
	formula_margin.add_child(host.question_formula_label)
	host.formula_box.visible = false
	host.question_formula_label.item_rect_changed.connect(func():
		if is_instance_valid(host.formula_box) and is_instance_valid(host.question_formula_label):
			host.formula_box.visible = host.question_formula_label.visible
	)

	host.timer_bar = ProgressBar.new()
	host.timer_bar.min_value = 0
	host.timer_bar.max_value = QuizSession.session_seconds()
	host.timer_bar.show_percentage = false
	host.timer_bar.custom_minimum_size = Vector2(0, ProgressSegments.BAR_H + 2)
	var bar_bg := AppTheme.panel_style(AppTheme.PANEL_BOTTOM, AppTheme.HAIRLINE, 0, 3)
	var bar_fill := AppTheme.panel_style(AppTheme.SKY_500, AppTheme.SKY_400, 0, 3)
	host.timer_bar.add_theme_stylebox_override("background", bar_bg)
	host.timer_bar.add_theme_stylebox_override("fill", bar_fill)
	question_column.add_child(host.timer_bar)

	host.answers_box = VBoxContainer.new()
	host.answers_box.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	quiz_column.add_child(host.answers_box)

	host.feedback_panel = PanelContainer.new()
	host.feedback_panel.add_theme_stylebox_override("panel", AppTheme.surface(AppTheme.PANEL_BOTTOM, AppTheme.HAIRLINE_BRIGHT, AppTheme.ELEVATION_CARD))
	UiFx.add_glass(host.feedback_panel, AppTheme.GRAD_PANEL)
	quiz_column.add_child(host.feedback_panel)
	var feedback_margin := MarginContainer.new()
	feedback_margin.add_theme_constant_override("margin_left", AppTheme.SPACE_LG)
	feedback_margin.add_theme_constant_override("margin_right", AppTheme.SPACE_LG)
	feedback_margin.add_theme_constant_override("margin_top", AppTheme.SPACE_MD + 2)
	feedback_margin.add_theme_constant_override("margin_bottom", AppTheme.SPACE_MD + 2)
	host.feedback_panel.add_child(feedback_margin)
	var feedback_column := VBoxContainer.new()
	feedback_column.add_theme_constant_override("separation", AppTheme.SPACE_SM + 2)
	feedback_margin.add_child(feedback_column)
	Widgets.add_feedback_title(host, feedback_column, AppTheme.TYPE_HEADING + 1)
	host.feedback_body = Label.new()
	host.feedback_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.feedback_body.add_theme_font_override("font", AppTheme.ui_font(AppTheme.WEIGHT_MEDIUM))
	host.feedback_body.add_theme_font_size_override("font_size", AppTheme.TYPE_BODY)
	host.feedback_body.add_theme_color_override("font_color", AppTheme.SLATE_100)
	feedback_column.add_child(host.feedback_body)
	host.feedback_reference = Label.new()
	host.feedback_reference.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.feedback_reference.add_theme_font_override("font", AppTheme.ui_font(AppTheme.WEIGHT_SEMIBOLD))
	host.feedback_reference.add_theme_font_size_override("font_size", AppTheme.TYPE_BODY_SM)
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
	host.feedback_table_note.add_theme_font_size_override("font_size", AppTheme.TYPE_META)
	host.feedback_table_note.add_theme_color_override("font_color", AppTheme.SLATE_300)
	host.feedback_table_note.visible = false
	feedback_detail.add_child(host.feedback_table_note)
	host.info_label = RichTextLabel.new()
	host.info_label.fit_content = true
	host.info_label.scroll_active = false
	host.info_label.custom_minimum_size = Vector2(0, 0)
	host.info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Widgets.style_info_label(host.info_label, AppTheme.TYPE_BODY)
	host.info_label.visible = false
	feedback_detail.add_child(host.info_label)
	host.next_button = Widgets.make_primary_button("Next question", 52, AppTheme.TYPE_BODY_LG + 1, host._on_next_button_pressed)
	host.next_button.visible = false
	root.add_child(host.next_button)

	host.dock_panel = PanelContainer.new()
	host.dock_panel.add_theme_stylebox_override("panel", AppTheme.surface(AppTheme.PANEL_BOTTOM, AppTheme.HAIRLINE, AppTheme.ELEVATION_REST))
	UiFx.add_glass(host.dock_panel, AppTheme.GRAD_PANEL)
	root.add_child(host.dock_panel)
	var dock_margin := MarginContainer.new()
	dock_margin.add_theme_constant_override("margin_left", AppTheme.SPACE_MD)
	dock_margin.add_theme_constant_override("margin_right", AppTheme.SPACE_MD)
	dock_margin.add_theme_constant_override("margin_top", AppTheme.SPACE_XS + 2)
	dock_margin.add_theme_constant_override("margin_bottom", AppTheme.SPACE_XS + 2)
	host.dock_panel.add_child(dock_margin)
	var dock_column := VBoxContainer.new()
	# 0: an empty status row would otherwise still cost a separation gap.
	dock_column.add_theme_constant_override("separation", 0)
	dock_margin.add_child(dock_column)
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", AppTheme.SPACE_SM + 2)
	dock_column.add_child(controls)
	host.mute_button = Widgets.make_dock_button("Sound off", 112, 48, AppTheme.TYPE_BODY_SM, host._toggle_session_mute, "speaker")
	controls.add_child(host.mute_button)
	host.read_button = Widgets.make_dock_button(host.speech._idle_read_label(), 0, 48, AppTheme.TYPE_BODY_LG - 1, host._toggle_read, "replay")
	host.read_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.read_button.add_theme_color_override("font_color", AppTheme.SLATE_100)
	host.read_button.add_theme_color_override("icon_normal_color", AppTheme.SKY_400)
	controls.add_child(host.read_button)
	host.pause_button = Widgets.make_dock_button("Pause", 0, 48, AppTheme.TYPE_BODY_LG - 1, host._toggle_listen_pause, "pause")
	host.pause_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(host.pause_button)
	host.skip_button = Widgets.make_dock_button("Skip", 96, 48, AppTheme.TYPE_BODY_LG - 1, host._listen_skip, "skip")
	controls.add_child(host.skip_button)
	host.restart_button = Widgets.make_dock_button("Menu", 96, 48, AppTheme.TYPE_BODY_SM, host._request_menu, "menu")
	controls.add_child(host.restart_button)
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	dock_column.add_child(status_row)
	host.dock_visualizer = VoiceVisualizer.new()
	host.dock_visualizer.bar_count = 6
	host.dock_visualizer.bar_width = 3.5
	host.dock_visualizer.bar_gap = 3.0
	host.dock_visualizer.custom_minimum_size = Vector2(40, 24)
	host.dock_visualizer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	host.dock_visualizer.visible = false
	status_row.add_child(host.dock_visualizer)
	host.read_status_label = Label.new()
	host.read_status_label.text = ""
	host.read_status_label.visible = false
	host.read_status_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	host.read_status_label.add_theme_font_override("font", AppTheme.meta_font())
	host.read_status_label.add_theme_font_size_override("font_size", AppTheme.TYPE_CAPTION)
	host.read_status_label.add_theme_color_override("font_color", AppTheme.SKY_400)
	host.read_status_label.clip_text = true
	host.read_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(host.read_status_label)
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
	# The panel is sized to the full viewport width; a visible scrollbar would
	# steal its width and clip the right edge. Touch-drag scrolling still works.
	menu_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	host.menu_overlay.add_child(menu_scroll)
	host.menu_center_box = MarginContainer.new()
	host.menu_center_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.menu_center_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host.menu_center_box.add_theme_constant_override("margin_left", AppTheme.SPACE_LG)
	host.menu_center_box.add_theme_constant_override("margin_right", AppTheme.SPACE_LG)
	host.menu_center_box.add_theme_constant_override("margin_top", AppTheme.SPACE_LG)
	host.menu_center_box.add_theme_constant_override("margin_bottom", AppTheme.SPACE_LG)
	menu_scroll.add_child(host.menu_center_box)
	var menu_outer_center := CenterContainer.new()
	menu_outer_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_outer_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host.menu_center_box.add_child(menu_outer_center)
	host.menu_panel = PanelContainer.new()
	host.menu_panel.custom_minimum_size = Vector2(320, 0)
	var panel_sb := AppTheme.surface(AppTheme.SURFACE_BOTTOM, AppTheme.HAIRLINE_BRIGHT, AppTheme.ELEVATION_FLOAT, AppTheme.RADIUS + 4)
	panel_sb.border_width_top = AppTheme.BORDER_STRONG + 1
	panel_sb.border_color = AppTheme.SKY_400
	host.menu_panel.add_theme_stylebox_override("panel", panel_sb)
	UiFx.add_glass(host.menu_panel, AppTheme.GRAD_SURFACE, AppTheme.RADIUS + 4)
	menu_outer_center.add_child(host.menu_panel)
	var menu_margin := MarginContainer.new()
	menu_margin.add_theme_constant_override("margin_left", AppTheme.SPACE_LG + 4)
	menu_margin.add_theme_constant_override("margin_right", AppTheme.SPACE_LG + 4)
	menu_margin.add_theme_constant_override("margin_top", AppTheme.SPACE_LG + 2)
	menu_margin.add_theme_constant_override("margin_bottom", AppTheme.SPACE_LG + 2)
	host.menu_panel.add_child(menu_margin)
	var menu_column := VBoxContainer.new()
	menu_column.add_theme_constant_override("separation", AppTheme.SPACE_SM + 2)
	menu_margin.add_child(menu_column)
	host.menu_column = menu_column
	host.menu_mode_buttons.clear()
	host.menu.build(menu_column)
