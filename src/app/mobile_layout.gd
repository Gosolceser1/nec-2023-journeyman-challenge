class_name MobileLayout
extends RefCounted
## The Android/mobile layout builder, moved verbatim out of main.gd: same
## member set as DesktopLayout, touch-first sizes. The two builders stay
## separate on purpose; tools/tests/test_layout_tree.gd pins both trees.

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
	host.main_margin.add_theme_constant_override("margin_left", 16)
	host.main_margin.add_theme_constant_override("margin_right", 16)
	host.main_margin.add_theme_constant_override("margin_top", 16)
	host.main_margin.add_theme_constant_override("margin_bottom", 16)
	host.add_child(host.main_margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	host.main_margin.add_child(root)

	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	root.add_child(header)
	# One line for title + progress: every pixel of header is a pixel of question.
	var title_box := HBoxContainer.new()
	title_box.add_theme_constant_override("separation", 10)
	header.add_child(title_box)
	var title := Label.new()
	title.text = "NEC 2023 // JOURNEYMAN"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	title.add_theme_font_override("font", AppTheme.ui_font(700))
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", AppTheme.SLATE_50)
	title_box.add_child(title)
	host.progress_label = Label.new()
	host.progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	host.progress_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	host.progress_label.add_theme_font_override("font", AppTheme.ui_font(700))
	host.progress_label.add_theme_font_size_override("font_size", 13)
	host.progress_label.add_theme_color_override("font_color", AppTheme.SKY_400)
	title_box.add_child(host.progress_label)

	var badge_row := HBoxContainer.new()
	badge_row.add_theme_constant_override("separation", 8)
	header.add_child(badge_row)
	host.pass_badge = PanelContainer.new()
	host.pass_badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.pass_badge.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.BADGE_GREEN_BG, AppTheme.EMERALD_600, 1, 8))
	badge_row.add_child(host.pass_badge)
	var pass_m := MarginContainer.new()
	pass_m.add_theme_constant_override("margin_left", 6)
	pass_m.add_theme_constant_override("margin_right", 6)
	pass_m.add_theme_constant_override("margin_top", 5)
	pass_m.add_theme_constant_override("margin_bottom", 5)
	host.pass_badge.add_child(pass_m)
	host.score_label = Label.new()
	host.score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	host.score_label.add_theme_font_override("font", AppTheme.ui_font(700))
	host.score_label.add_theme_font_size_override("font_size", 12)
	host.score_label.add_theme_color_override("font_color", AppTheme.EMERALD_300)
	pass_m.add_child(host.score_label)
	var streak_badge := PanelContainer.new()
	streak_badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	streak_badge.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.PILL_BLUE_BG, AppTheme.BORDER_BLUE, 1, 8))
	badge_row.add_child(streak_badge)
	var streak_m := MarginContainer.new()
	streak_m.add_theme_constant_override("margin_left", 6)
	streak_m.add_theme_constant_override("margin_right", 6)
	streak_m.add_theme_constant_override("margin_top", 5)
	streak_m.add_theme_constant_override("margin_bottom", 5)
	streak_badge.add_child(streak_m)
	host.streak_label = Label.new()
	host.streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	host.streak_label.add_theme_font_override("font", AppTheme.ui_font(600))
	host.streak_label.add_theme_font_size_override("font_size", 12)
	host.streak_label.add_theme_color_override("font_color", AppTheme.SKY_300)
	streak_m.add_child(host.streak_label)
	var timer_badge := PanelContainer.new()
	timer_badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timer_badge.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.PILL_SLATE_BG, AppTheme.SLATE_700, 1, 8))
	badge_row.add_child(timer_badge)
	var timer_m := MarginContainer.new()
	timer_m.add_theme_constant_override("margin_left", 6)
	timer_m.add_theme_constant_override("margin_right", 6)
	timer_m.add_theme_constant_override("margin_top", 5)
	timer_m.add_theme_constant_override("margin_bottom", 5)
	timer_badge.add_child(timer_m)
	host.timer_label = Label.new()
	host.timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	host.timer_label.add_theme_font_override("font", AppTheme.ui_font(700))
	host.timer_label.add_theme_font_size_override("font_size", 12)
	host.timer_label.add_theme_color_override("font_color", AppTheme.SLATE_50)
	timer_m.add_child(host.timer_label)
	var pace_badge := PanelContainer.new()
	pace_badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pace_badge.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.PACE_BADGE_BG, AppTheme.SKY_600, 1, 8))
	badge_row.add_child(pace_badge)
	var pace_m := MarginContainer.new()
	pace_m.add_theme_constant_override("margin_left", 6)
	pace_m.add_theme_constant_override("margin_right", 6)
	pace_m.add_theme_constant_override("margin_top", 5)
	pace_m.add_theme_constant_override("margin_bottom", 5)
	pace_badge.add_child(pace_m)
	host.question_timer_label = Label.new()
	host.question_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	host.question_timer_label.add_theme_font_override("font", AppTheme.ui_font(700))
	host.question_timer_label.add_theme_font_size_override("font_size", 12)
	host.question_timer_label.add_theme_color_override("font_color", AppTheme.SKY_400)
	pace_m.add_child(host.question_timer_label)

	var quiz_scroll := ScrollContainer.new()
	quiz_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	quiz_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quiz_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	quiz_scroll.scroll_started.connect(host._reset_pressed_cards)
	root.add_child(quiz_scroll)
	var quiz_column := VBoxContainer.new()
	quiz_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quiz_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	quiz_column.add_theme_constant_override("separation", 10)
	quiz_scroll.add_child(quiz_column)
	host.quiz_scroll_box = quiz_scroll

	host.question_panel = PanelContainer.new()
	host.question_panel.add_theme_stylebox_override("panel", host._question_panel_style())
	quiz_column.add_child(host.question_panel)
	var question_margin := MarginContainer.new()
	question_margin.add_theme_constant_override("margin_left", 14)
	question_margin.add_theme_constant_override("margin_right", 14)
	question_margin.add_theme_constant_override("margin_top", 12)
	question_margin.add_theme_constant_override("margin_bottom", 12)
	host.question_panel.add_child(question_margin)
	var question_column := VBoxContainer.new()
	question_column.add_theme_constant_override("separation", 8)
	question_margin.add_child(question_column)

	# Session pills restate what the player just picked on the menu; on a
	# phone that row costs a card's worth of height, so it stays built but hidden.
	host.exam_pills_row = HBoxContainer.new()
	host.exam_pills_row.add_theme_constant_override("separation", 8)
	host.exam_pills_row.visible = false
	question_column.add_child(host.exam_pills_row)
	host.exam_label = Label.new()
	host.exam_label.visible = false
	host.exam_pills_row.add_child(host.exam_label)
	var mode_pill_panel := PanelContainer.new()
	mode_pill_panel.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.PILL_BLUE_BG, AppTheme.BORDER_BLUE, 1, 6))
	var mode_pill_m := MarginContainer.new()
	mode_pill_m.add_theme_constant_override("margin_left", 8)
	mode_pill_m.add_theme_constant_override("margin_right", 8)
	mode_pill_m.add_theme_constant_override("margin_top", 4)
	mode_pill_m.add_theme_constant_override("margin_bottom", 4)
	mode_pill_panel.add_child(mode_pill_m)
	host.exam_mode_pill = Label.new()
	host.exam_mode_pill.add_theme_font_override("font", AppTheme.ui_font(700))
	host.exam_mode_pill.add_theme_font_size_override("font_size", 12)
	host.exam_mode_pill.add_theme_color_override("font_color", AppTheme.SKY_400)
	mode_pill_m.add_child(host.exam_mode_pill)
	host.exam_pills_row.add_child(mode_pill_panel)
	var lic_pill_panel := PanelContainer.new()
	lic_pill_panel.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.PILL_SLATE_BG, AppTheme.SLATE_700, 1, 6))
	var lic_pill_m := MarginContainer.new()
	lic_pill_m.add_theme_constant_override("margin_left", 8)
	lic_pill_m.add_theme_constant_override("margin_right", 8)
	lic_pill_m.add_theme_constant_override("margin_top", 4)
	lic_pill_m.add_theme_constant_override("margin_bottom", 4)
	lic_pill_panel.add_child(lic_pill_m)
	host.exam_license_pill = Label.new()
	host.exam_license_pill.add_theme_font_override("font", AppTheme.ui_font(600))
	host.exam_license_pill.add_theme_font_size_override("font_size", 12)
	host.exam_license_pill.add_theme_color_override("font_color", AppTheme.SLATE_300)
	lic_pill_m.add_child(host.exam_license_pill)
	host.exam_pills_row.add_child(lic_pill_panel)
	host.question_label = Label.new()
	host.question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.question_label.add_theme_font_override("font", AppTheme.ui_font(700))
	host.question_label.add_theme_font_size_override("font_size", 23)
	host.question_label.add_theme_color_override("font_color", AppTheme.WHITE)
	question_column.add_child(host.question_label)

	var hint_hbox := HBoxContainer.new()
	hint_hbox.add_theme_constant_override("separation", 10)
	question_column.add_child(hint_hbox)
	host.question_hint_row = hint_hbox
	var hint_bar := ColorRect.new()
	hint_bar.custom_minimum_size = Vector2(3, 18)
	hint_bar.size_flags_vertical = Control.SIZE_FILL
	hint_bar.color = AppTheme.SKY_400
	hint_hbox.add_child(hint_bar)
	host.article_label = Label.new()
	host.article_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.article_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.article_label.add_theme_font_override("font", AppTheme.ui_font(500))
	host.article_label.add_theme_font_size_override("font_size", 15)
	host.article_label.add_theme_color_override("font_color", AppTheme.SLATE_200)
	hint_hbox.add_child(host.article_label)

	host.lookup_box = PanelContainer.new()
	host.lookup_box.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.LOOKUP_BG, AppTheme.BORDER_BLUE, 1, 8))
	question_column.add_child(host.lookup_box)
	var lookup_margin := MarginContainer.new()
	lookup_margin.add_theme_constant_override("margin_left", 12)
	lookup_margin.add_theme_constant_override("margin_right", 12)
	lookup_margin.add_theme_constant_override("margin_top", 8)
	lookup_margin.add_theme_constant_override("margin_bottom", 8)
	host.lookup_box.add_child(lookup_margin)
	host.chapter_hint_label = Label.new()
	host.chapter_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.chapter_hint_label.add_theme_font_override("font", AppTheme.ui_font(500))
	host.chapter_hint_label.add_theme_font_size_override("font_size", 13)
	host.chapter_hint_label.add_theme_color_override("font_color", AppTheme.SKY_400)
	lookup_margin.add_child(host.chapter_hint_label)
	host.lookup_box.visible = false
	host.chapter_hint_label.item_rect_changed.connect(func():
		if is_instance_valid(host.lookup_box) and is_instance_valid(host.chapter_hint_label):
			host.lookup_box.visible = host.chapter_hint_label.visible
	)

	host.question_table_panel = PanelContainer.new()
	host.question_table_panel.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.TABLE_PANEL_BG, AppTheme.BORDER_BLUE, 1, 9))
	host.question_table_panel.custom_minimum_size = Vector2(0, 120)
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
	host.question_table_heading.add_theme_font_size_override("font_size", 13)
	host.question_table_heading.add_theme_color_override("font_color", AppTheme.SKY_300)
	question_table_column.add_child(host.question_table_heading)
	host.question_table_scroll = ScrollContainer.new()
	host.question_table_scroll.custom_minimum_size = Vector2(0, 42)
	host.question_table_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.question_table_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	host.question_table_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	question_table_column.add_child(host.question_table_scroll)
	host.question_table_grid = GridContainer.new()
	host.question_table_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.question_table_grid.add_theme_constant_override("h_separation", 0)
	host.question_table_grid.add_theme_constant_override("v_separation", 0)
	host.question_table_scroll.add_child(host.question_table_grid)
	host.question_table_note = Label.new()
	host.question_table_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.question_table_note.add_theme_font_size_override("font_size", 12)
	host.question_table_note.add_theme_color_override("font_color", AppTheme.SLATE_300)
	question_table_column.add_child(host.question_table_note)

	host.question_diagram_panel = PanelContainer.new()
	# Paper card: the figures are black-on-white scans of the exam page.
	host.question_diagram_panel.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.SLATE_50, AppTheme.SKY_400, 1, 10))
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
	host.question_diagram_view.max_height = FitController.DIAGRAM_MAX_H_MOBILE
	diagram_margin.add_child(host.question_diagram_view)

	host.formula_box = PanelContainer.new()
	host.formula_box.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.PILL_SLATE_BG, AppTheme.BLUE_600, 1, 8))
	question_column.add_child(host.formula_box)
	var formula_margin := MarginContainer.new()
	formula_margin.add_theme_constant_override("margin_left", 12)
	formula_margin.add_theme_constant_override("margin_right", 12)
	formula_margin.add_theme_constant_override("margin_top", 8)
	formula_margin.add_theme_constant_override("margin_bottom", 8)
	host.formula_box.add_child(formula_margin)
	host.question_formula_label = Label.new()
	host.question_formula_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.question_formula_label.add_theme_font_override("font", AppTheme.ui_font(500))
	host.question_formula_label.add_theme_font_size_override("font_size", 14)
	host.question_formula_label.add_theme_color_override("font_color", AppTheme.BLUE_300)
	formula_margin.add_child(host.question_formula_label)
	host.formula_box.visible = false
	host.question_formula_label.item_rect_changed.connect(func():
		if is_instance_valid(host.formula_box) and is_instance_valid(host.question_formula_label):
			host.formula_box.visible = host.question_formula_label.visible
	)

	host.timer_bar = ProgressBar.new()
	host.timer_bar.min_value = 0
	host.timer_bar.max_value = Main.SESSION_TIME_SECONDS
	host.timer_bar.show_percentage = false
	host.timer_bar.custom_minimum_size = Vector2(0, 8)
	var bar_bg := AppTheme.panel_style(AppTheme.SLATE_900, AppTheme.SLATE_800, 1, 3)
	var bar_fill := AppTheme.panel_style(AppTheme.SKY_600, AppTheme.SKY_400, 0, 3)
	host.timer_bar.add_theme_stylebox_override("background", bar_bg)
	host.timer_bar.add_theme_stylebox_override("fill", bar_fill)
	question_column.add_child(host.timer_bar)

	host.answers_box = VBoxContainer.new()
	host.answers_box.add_theme_constant_override("separation", 8)
	quiz_column.add_child(host.answers_box)

	host.feedback_panel = PanelContainer.new()
	host.feedback_panel.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.FEEDBACK_BG, AppTheme.FEEDBACK_BORDER, 1, 14))
	quiz_column.add_child(host.feedback_panel)
	var feedback_margin := MarginContainer.new()
	feedback_margin.add_theme_constant_override("margin_left", 16)
	feedback_margin.add_theme_constant_override("margin_right", 16)
	feedback_margin.add_theme_constant_override("margin_top", 14)
	feedback_margin.add_theme_constant_override("margin_bottom", 14)
	host.feedback_panel.add_child(feedback_margin)
	var feedback_column := VBoxContainer.new()
	feedback_column.add_theme_constant_override("separation", 10)
	feedback_margin.add_child(feedback_column)
	host.feedback_title = Label.new()
	host.feedback_title.add_theme_font_override("font", AppTheme.ui_font(700))
	host.feedback_title.add_theme_font_size_override("font_size", 19)
	feedback_column.add_child(host.feedback_title)
	host.feedback_body = Label.new()
	host.feedback_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.feedback_body.add_theme_font_override("font", AppTheme.ui_font(500))
	host.feedback_body.add_theme_font_size_override("font_size", 15)
	host.feedback_body.add_theme_color_override("font_color", AppTheme.SLATE_100)
	feedback_column.add_child(host.feedback_body)
	host.feedback_reference = Label.new()
	host.feedback_reference.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.feedback_reference.add_theme_font_override("font", AppTheme.ui_font(600))
	host.feedback_reference.add_theme_font_size_override("font_size", 14)
	host.feedback_reference.add_theme_color_override("font_color", AppTheme.SKY_300)
	host.feedback_reference.visible = false
	feedback_column.add_child(host.feedback_reference)
	var feedback_detail := host._make_feedback_detail(feedback_column)
	host.feedback_table_scroll = ScrollContainer.new()
	host.feedback_table_scroll.custom_minimum_size = Vector2(0, 42)
	host.feedback_table_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.feedback_table_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	host.feedback_table_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	host.feedback_table_scroll.visible = false
	feedback_detail.add_child(host.feedback_table_scroll)
	host.feedback_table_grid = GridContainer.new()
	host.feedback_table_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.feedback_table_grid.add_theme_constant_override("h_separation", 0)
	host.feedback_table_grid.add_theme_constant_override("v_separation", 0)
	host.feedback_table_scroll.add_child(host.feedback_table_grid)
	host.feedback_table_note = Label.new()
	host.feedback_table_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.feedback_table_note.add_theme_font_size_override("font_size", 12)
	host.feedback_table_note.add_theme_color_override("font_color", AppTheme.SLATE_300)
	host.feedback_table_note.visible = false
	feedback_detail.add_child(host.feedback_table_note)
	host.info_label = RichTextLabel.new()
	host.info_label.fit_content = true
	host.info_label.scroll_active = false
	host.info_label.custom_minimum_size = Vector2(0, 0)
	host.info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.info_label.add_theme_font_override("normal_font", AppTheme.ui_font(400))
	host.info_label.add_theme_font_override("bold_font", AppTheme.ui_font(700))
	host.info_label.add_theme_color_override("default_color", AppTheme.SLATE_100)
	host.info_label.add_theme_font_size_override("normal_font_size", 15)
	host.info_label.add_theme_font_size_override("bold_font_size", 15)
	host.info_label.add_theme_constant_override("line_separation", 4)
	host.info_label.visible = false
	feedback_detail.add_child(host.info_label)
	host.next_button = Button.new()
	host.next_button.text = "Next question"
	host.next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.next_button.custom_minimum_size = Vector2(0, 52)
	host.next_button.pressed.connect(host._on_next_button_pressed)
	host.next_button.visible = false
	var btn_normal := AppTheme.panel_style(AppTheme.SKY_600, AppTheme.SKY_400, 1, 10)
	var btn_hover := AppTheme.panel_style(AppTheme.SKY_700, AppTheme.SKY_300, 2, 10)
	var btn_pressed := AppTheme.panel_style(AppTheme.SKY_800, AppTheme.SKY_400, 1, 10)
	host.next_button.add_theme_stylebox_override("normal", btn_normal)
	host.next_button.add_theme_stylebox_override("hover", btn_hover)
	host.next_button.add_theme_stylebox_override("pressed", btn_pressed)
	host.next_button.add_theme_font_size_override("font_size", 18)
	host.next_button.add_theme_color_override("font_color", AppTheme.WHITE)
	root.add_child(host.next_button)

	host.dock_panel = PanelContainer.new()
	host.dock_panel.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.SURFACE_DEEP, AppTheme.SLATE_800, 1, 12))
	root.add_child(host.dock_panel)
	var dock_margin := MarginContainer.new()
	dock_margin.add_theme_constant_override("margin_left", 12)
	dock_margin.add_theme_constant_override("margin_right", 12)
	dock_margin.add_theme_constant_override("margin_top", 6)
	dock_margin.add_theme_constant_override("margin_bottom", 6)
	host.dock_panel.add_child(dock_margin)
	var dock_column := VBoxContainer.new()
	# 0: an empty status row would otherwise still cost a separation gap.
	dock_column.add_theme_constant_override("separation", 0)
	dock_margin.add_child(dock_column)
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 10)
	dock_column.add_child(controls)
	host.mute_button = Widgets.make_dock_button("Sound off", 112, 48, 14, host._toggle_session_mute)
	controls.add_child(host.mute_button)
	host.read_button = Button.new()
	host.read_button.text = host.speech._idle_read_label()
	host.read_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.read_button.custom_minimum_size = Vector2(0, 48)
	host.read_button.pressed.connect(host._toggle_read)
	var rb_norm := AppTheme.panel_style(AppTheme.READ_BUTTON_BG, AppTheme.READ_BUTTON_BORDER, 1, 9)
	var rb_hov := AppTheme.panel_style(AppTheme.READ_BUTTON_HOVER_BG, AppTheme.SKY_400, 2, 9)
	host.read_button.add_theme_stylebox_override("normal", rb_norm)
	host.read_button.add_theme_stylebox_override("hover", rb_hov)
	host.read_button.add_theme_font_override("font", AppTheme.ui_font(600))
	host.read_button.add_theme_font_size_override("font_size", 16)
	host.read_button.add_theme_color_override("font_color", AppTheme.SLATE_100)
	controls.add_child(host.read_button)
	host.pause_button = Widgets.make_dock_button("Pause", 0, 48, 16, host._toggle_listen_pause)
	host.pause_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(host.pause_button)
	host.skip_button = Widgets.make_dock_button("Skip  ›", 96, 48, 16, host._listen_skip)
	controls.add_child(host.skip_button)
	host.restart_button = Button.new()
	host.restart_button.text = "Menu"
	host.restart_button.custom_minimum_size = Vector2(96, 48)
	host.restart_button.pressed.connect(host._request_menu)
	var rst_norm := AppTheme.panel_style(AppTheme.DOCK_BUTTON_BG, AppTheme.DOCK_BUTTON_BORDER, 1, 9)
	var rst_hov := AppTheme.panel_style(AppTheme.DOCK_BUTTON_HOVER_BG, AppTheme.SLATE_600, 1, 9)
	host.restart_button.add_theme_stylebox_override("normal", rst_norm)
	host.restart_button.add_theme_stylebox_override("hover", rst_hov)
	host.restart_button.add_theme_font_override("font", AppTheme.ui_font(500))
	host.restart_button.add_theme_font_size_override("font_size", 14)
	host.restart_button.add_theme_color_override("font_color", AppTheme.SLATE_400)
	controls.add_child(host.restart_button)
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 8)
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
	host.read_status_label.add_theme_font_override("font", AppTheme.ui_font(700))
	host.read_status_label.add_theme_font_size_override("font_size", 13)
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
	host.menu_overlay.add_child(UiFx.make_circuit_backdrop())
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
	host.menu_center_box.add_theme_constant_override("margin_left", 16)
	host.menu_center_box.add_theme_constant_override("margin_right", 16)
	host.menu_center_box.add_theme_constant_override("margin_top", 16)
	host.menu_center_box.add_theme_constant_override("margin_bottom", 16)
	menu_scroll.add_child(host.menu_center_box)
	var menu_outer_center := CenterContainer.new()
	menu_outer_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_outer_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host.menu_center_box.add_child(menu_outer_center)
	host.menu_panel = PanelContainer.new()
	host.menu_panel.custom_minimum_size = Vector2(320, 0)
	var panel_sb := AppTheme.panel_style(AppTheme.MENU_PANEL_BG, AppTheme.SLATE_800, 1, 16)
	panel_sb.border_width_top = 3
	panel_sb.border_color = AppTheme.SKY_400
	panel_sb.shadow_color = Color(0, 0, 0, 0.5)
	panel_sb.shadow_size = 14
	host.menu_panel.add_theme_stylebox_override("panel", panel_sb)
	menu_outer_center.add_child(host.menu_panel)
	var menu_margin := MarginContainer.new()
	menu_margin.add_theme_constant_override("margin_left", 20)
	menu_margin.add_theme_constant_override("margin_right", 20)
	menu_margin.add_theme_constant_override("margin_top", 18)
	menu_margin.add_theme_constant_override("margin_bottom", 18)
	host.menu_panel.add_child(menu_margin)
	var menu_column := VBoxContainer.new()
	menu_column.add_theme_constant_override("separation", 10)
	menu_margin.add_child(menu_column)
	host.menu_column = menu_column
	var badge_box := HBoxContainer.new()
	badge_box.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_column.add_child(badge_box)
	var year_badge := Label.new()
	year_badge.text = " NFPA 70 • NEC 2023 • PSI STANDARDS "
	year_badge.add_theme_font_override("font", AppTheme.ui_font(700))
	year_badge.add_theme_font_size_override("font_size", 11)
	year_badge.add_theme_color_override("font_color", AppTheme.SKY_400)
	var yb_style := AppTheme.panel_style(AppTheme.BADGE_BLUE_BG, AppTheme.SKY_600, 1, 6)
	yb_style.content_margin_left = 12
	yb_style.content_margin_right = 12
	yb_style.content_margin_top = 4
	yb_style.content_margin_bottom = 4
	year_badge.add_theme_stylebox_override("normal", yb_style)
	badge_box.add_child(year_badge)
	var menu_title := Label.new()
	menu_title.text = "NEC 2023 // JOURNEYMAN CHALLENGE"
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_title.add_theme_font_override("font", AppTheme.ui_font(700))
	menu_title.add_theme_font_size_override("font_size", 24)
	menu_title.add_theme_color_override("font_color", AppTheme.SLATE_50)
	menu_column.add_child(menu_title)
	UiFx.electrify_title(menu_title)
	var menu_subtitle := Label.new()
	menu_subtitle.text = "Master the National Electrical Code • Comprehensive Exam Prep"
	menu_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_subtitle.add_theme_font_size_override("font_size", 13)
	menu_subtitle.add_theme_color_override("font_color", AppTheme.SLATE_400)
	menu_column.add_child(menu_subtitle)
	var menu_rule := HSeparator.new()
	menu_column.add_child(menu_rule)
	var practice_hdr_box := HBoxContainer.new()
	practice_hdr_box.add_theme_constant_override("separation", 8)
	menu_column.add_child(practice_hdr_box)
	var practice_bar := ColorRect.new()
	practice_bar.custom_minimum_size = Vector2(4, 16)
	practice_bar.color = AppTheme.SKY_400
	practice_hdr_box.add_child(practice_bar)
	var practice_heading := Label.new()
	practice_heading.text = "RAPID PRACTICE DRILLS"
	practice_heading.add_theme_font_size_override("font_size", 12)
	practice_heading.add_theme_color_override("font_color", AppTheme.SKY_400)
	practice_hdr_box.add_child(practice_heading)
	menu_column.move_child(AudioSection.build(host, menu_column), practice_hdr_box.get_index())
	host.menu_mode_buttons.clear()
	Widgets.add_mode_button(host, menu_column, "10 QUESTIONS", "Quick warm-up drill • 30 minutes timed", host._start_quiz.bind(10, host._practice_time(10), true, "10-Question Practice"), AppTheme.SKY_400, AppTheme.BUTTON_BG, false, 64.0, 15)
	Widgets.add_mode_button(host, menu_column, "20 QUESTIONS", "Standard focused session • 60 minutes timed", host._start_quiz.bind(20, host._practice_time(20), true, "20-Question Practice"), AppTheme.SKY_400, AppTheme.BUTTON_BG, false, 64.0, 15)
	Widgets.add_mode_button(host, menu_column, "30 QUESTIONS", "Extended study block • 90 minutes timed", host._start_quiz.bind(30, host._practice_time(30), true, "30-Question Practice"), AppTheme.SKY_400, AppTheme.BUTTON_BG, false, 64.0, 15)
	Widgets.add_mode_button(host, menu_column, "40 QUESTIONS", "Half-length diagnostic test • 120 minutes timed", host._start_quiz.bind(40, host._practice_time(40), true, "40-Question Practice"), AppTheme.SKY_400, AppTheme.BUTTON_BG, false, 64.0, 15)
	Widgets.add_mode_button(host, menu_column, "50 QUESTIONS", "Intensive endurance drill • 150 minutes timed", host._start_quiz.bind(50, host._practice_time(50), true, "50-Question Practice"), AppTheme.SKY_400, AppTheme.BUTTON_BG, false, 64.0, 15)
	Widgets.add_mode_button(host, menu_column, "10 QUESTIONS • WEAKEST AREA", host._study_button_subtitle(), host._start_area_drill, AppTheme.SKY_300, AppTheme.BUTTON_BG, false, 64.0, 15)
	host.study_button = host.menu_mode_buttons.back()
	Widgets.add_state_law_section(host, menu_column, 64.0, 15)
	var exam_hdr_box := HBoxContainer.new()
	exam_hdr_box.add_theme_constant_override("separation", 8)
	menu_column.add_child(exam_hdr_box)
	var exam_bar := ColorRect.new()
	exam_bar.custom_minimum_size = Vector2(4, 16)
	exam_bar.color = AppTheme.ROSE_500
	exam_hdr_box.add_child(exam_bar)
	var exam_heading := Label.new()
	exam_heading.text = "OFFICIAL LICENSING SIMULATION"
	exam_heading.add_theme_font_override("font", AppTheme.ui_font(700))
	exam_heading.add_theme_font_size_override("font_size", 12)
	exam_heading.add_theme_color_override("font_color", AppTheme.ROSE_500)
	exam_hdr_box.add_child(exam_heading)
	Widgets.add_mode_button(host, menu_column, "FULL JOURNEYMAN SIMULATOR", "80 scored questions • 240 minutes • 75% required to pass", host._start_quiz.bind(80, Main.EXAM_MINUTES * 60, true, "Full Journeyman Exam"), AppTheme.ROSE_500, AppTheme.EXAM_BUTTON_BG, true, 72.0, 15)

	var menu_note := Label.new()
	menu_note.text = "Aligned with NFPA 70 (NEC 2023) & Nebraska State Electrical Division / PSI Standards\nPacing standard: 3:00 per scored item • 80 questions timed"
	menu_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_note.add_theme_font_override("font", AppTheme.ui_font(400))
	menu_note.add_theme_font_size_override("font_size", 11)
	menu_note.add_theme_color_override("font_color", AppTheme.SLATE_400)
	menu_column.add_child(menu_note)
