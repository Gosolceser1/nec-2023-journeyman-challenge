class_name DesktopLayout
extends RefCounted
## The Windows/desktop layout builder, moved verbatim out of main.gd: it
## creates every node and assigns the same members on the host, so the
## quiz logic in main.gd runs unchanged. tools/tests/test_layout_tree.gd
## pins the resulting tree.

static func build(host: Main) -> void:
	# 2026 Illustrated NEC Edition Backdrop (Windows/desktop layout — do not restyle):
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
	title.add_theme_font_override("font", AppTheme.ui_font(700))
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", AppTheme.SLATE_50)
	title_box.add_child(title)

	host.progress_label = Label.new()
	host.progress_label.add_theme_font_override("font", AppTheme.ui_font(600))
	host.progress_label.add_theme_font_size_override("font_size", 12)
	host.progress_label.add_theme_color_override("font_color", AppTheme.SKY_400)
	title_box.add_child(host.progress_label)

	# Target Pass Pill Badge (75% Pass Standard per PSI CIB)
	host.pass_badge = PanelContainer.new()
	var pass_badge_style := AppTheme.panel_style(AppTheme.BADGE_GREEN_BG, AppTheme.EMERALD_600, 1, 8)
	host.pass_badge.add_theme_stylebox_override("panel", pass_badge_style)
	var pass_margin := MarginContainer.new()
	pass_margin.add_theme_constant_override("margin_left", 12)
	pass_margin.add_theme_constant_override("margin_right", 12)
	pass_margin.add_theme_constant_override("margin_top", 6)
	pass_margin.add_theme_constant_override("margin_bottom", 6)
	host.pass_badge.add_child(pass_margin)
	host.score_label = Label.new()
	host.score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	host.score_label.add_theme_font_override("font", AppTheme.ui_font(700))
	host.score_label.add_theme_font_size_override("font_size", 12)
	host.score_label.add_theme_color_override("font_color", AppTheme.EMERALD_300)
	pass_margin.add_child(host.score_label)
	header.add_child(host.pass_badge)

	# Session Type Badge (PSI Test Specification)
	var streak_badge := PanelContainer.new()
	var streak_badge_style := AppTheme.panel_style(AppTheme.PILL_BLUE_BG, AppTheme.BORDER_BLUE, 1, 8)
	streak_badge.add_theme_stylebox_override("panel", streak_badge_style)
	var streak_margin := MarginContainer.new()
	streak_margin.add_theme_constant_override("margin_left", 12)
	streak_margin.add_theme_constant_override("margin_right", 12)
	streak_margin.add_theme_constant_override("margin_top", 6)
	streak_margin.add_theme_constant_override("margin_bottom", 6)
	streak_badge.add_child(streak_margin)
	host.streak_label = Label.new()
	host.streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	host.streak_label.add_theme_font_override("font", AppTheme.ui_font(600))
	host.streak_label.add_theme_font_size_override("font_size", 12)
	host.streak_label.add_theme_color_override("font_color", AppTheme.SKY_300)
	streak_margin.add_child(host.streak_label)
	header.add_child(streak_badge)

	# Overall Exam Timer Badge
	var timer_badge := PanelContainer.new()
	timer_badge.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.PILL_SLATE_BG, AppTheme.SLATE_700, 1, 8))
	var timer_m := MarginContainer.new()
	timer_m.add_theme_constant_override("margin_left", 12)
	timer_m.add_theme_constant_override("margin_right", 12)
	timer_m.add_theme_constant_override("margin_top", 6)
	timer_m.add_theme_constant_override("margin_bottom", 6)
	timer_badge.add_child(timer_m)
	host.timer_label = Label.new()
	host.timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	host.timer_label.add_theme_font_override("font", AppTheme.ui_font(700))
	host.timer_label.add_theme_font_size_override("font_size", 13)
	host.timer_label.add_theme_color_override("font_color", AppTheme.SLATE_50)
	timer_m.add_child(host.timer_label)
	header.add_child(timer_badge)

	# Pace Item Timer Badge
	var pace_badge := PanelContainer.new()
	pace_badge.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.PACE_BADGE_BG, AppTheme.SKY_600, 1, 8))
	var pace_m := MarginContainer.new()
	pace_m.add_theme_constant_override("margin_left", 12)
	pace_m.add_theme_constant_override("margin_right", 12)
	pace_m.add_theme_constant_override("margin_top", 6)
	pace_m.add_theme_constant_override("margin_bottom", 6)
	pace_badge.add_child(pace_m)
	host.question_timer_label = Label.new()
	host.question_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	host.question_timer_label.add_theme_font_override("font", AppTheme.ui_font(700))
	host.question_timer_label.add_theme_font_size_override("font_size", 13)
	host.question_timer_label.add_theme_color_override("font_color", AppTheme.SKY_400)
	pace_m.add_child(host.question_timer_label)
	header.add_child(pace_badge)

	host.question_panel = PanelContainer.new()
	host.question_panel.add_theme_stylebox_override("panel", host._question_panel_style())
	quiz_column.add_child(host.question_panel)
	var question_margin := MarginContainer.new()
	question_margin.add_theme_constant_override("margin_left", 20)
	question_margin.add_theme_constant_override("margin_right", 20)
	question_margin.add_theme_constant_override("margin_top", 14)
	question_margin.add_theme_constant_override("margin_bottom", 14)
	host.question_panel.add_child(question_margin)
	var question_column := VBoxContainer.new()
	question_column.add_theme_constant_override("separation", 9)
	question_margin.add_child(question_column)

	# Exam Header Pills Row
	host.exam_pills_row = HBoxContainer.new()
	host.exam_pills_row.add_theme_constant_override("separation", 8)
	question_column.add_child(host.exam_pills_row)

	host.exam_label = Label.new()
	host.exam_label.visible = false
	host.exam_pills_row.add_child(host.exam_label)

	var mode_pill_panel := PanelContainer.new()
	mode_pill_panel.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.PILL_BLUE_BG, AppTheme.BORDER_BLUE, 1, 6))
	var mode_pill_m := MarginContainer.new()
	mode_pill_m.add_theme_constant_override("margin_left", 8)
	mode_pill_m.add_theme_constant_override("margin_right", 8)
	mode_pill_m.add_theme_constant_override("margin_top", 3)
	mode_pill_m.add_theme_constant_override("margin_bottom", 3)
	mode_pill_panel.add_child(mode_pill_m)
	host.exam_mode_pill = Label.new()
	host.exam_mode_pill.add_theme_font_override("font", AppTheme.ui_font(700))
	host.exam_mode_pill.add_theme_font_size_override("font_size", 11)
	host.exam_mode_pill.add_theme_color_override("font_color", AppTheme.SKY_400)
	mode_pill_m.add_child(host.exam_mode_pill)
	host.exam_pills_row.add_child(mode_pill_panel)

	var lic_pill_panel := PanelContainer.new()
	lic_pill_panel.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.PILL_SLATE_BG, AppTheme.SLATE_700, 1, 6))
	var lic_pill_m := MarginContainer.new()
	lic_pill_m.add_theme_constant_override("margin_left", 8)
	lic_pill_m.add_theme_constant_override("margin_right", 8)
	lic_pill_m.add_theme_constant_override("margin_top", 3)
	lic_pill_m.add_theme_constant_override("margin_bottom", 3)
	lic_pill_panel.add_child(lic_pill_m)
	host.exam_license_pill = Label.new()
	host.exam_license_pill.add_theme_font_override("font", AppTheme.ui_font(600))
	host.exam_license_pill.add_theme_font_size_override("font_size", 11)
	host.exam_license_pill.add_theme_color_override("font_color", AppTheme.SLATE_300)
	lic_pill_m.add_child(host.exam_license_pill)
	host.exam_pills_row.add_child(lic_pill_panel)

	# Question Stem Voice Visualizer Badge
	host.prompt_voice_badge = PanelContainer.new()
	host.prompt_voice_badge.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.VOICE_BADGE_BG, AppTheme.SKY_600, 1, 6))
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
	pvb_text.add_theme_font_override("font", AppTheme.ui_font(700))
	pvb_text.add_theme_font_size_override("font_size", 10)
	pvb_text.add_theme_color_override("font_color", AppTheme.SKY_400)
	pvb_hbox.add_child(pvb_text)
	host.prompt_voice_badge.visible = false
	host.exam_pills_row.add_child(host.prompt_voice_badge)

	host.question_label = Label.new()
	host.question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.question_label.add_theme_font_override("font", AppTheme.ui_font(700))
	host.question_label.add_theme_font_size_override("font_size", 21)
	host.question_label.add_theme_color_override("font_color", AppTheme.WHITE)
	question_column.add_child(host.question_label)

	# Subtitle / Gist Hint with Left Accent Bar
	var hint_hbox := HBoxContainer.new()
	host.question_hint_row = hint_hbox
	hint_hbox.add_theme_constant_override("separation", 10)
	question_column.add_child(hint_hbox)

	var hint_bar := ColorRect.new()
	hint_bar.custom_minimum_size = Vector2(3, 18)
	hint_bar.size_flags_vertical = Control.SIZE_FILL
	hint_bar.color = AppTheme.SKY_400
	hint_hbox.add_child(hint_bar)

	host.article_label = Label.new()
	host.article_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.article_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.article_label.add_theme_font_override("font", AppTheme.ui_font(500))
	host.article_label.add_theme_font_size_override("font_size", 14)
	host.article_label.add_theme_color_override("font_color", AppTheme.SLATE_200)
	hint_hbox.add_child(host.article_label)

	# Lookup Path Callout Box
	host.lookup_box = PanelContainer.new()
	var lookup_style := AppTheme.panel_style(AppTheme.LOOKUP_BG, AppTheme.BORDER_BLUE, 1, 8)
	host.lookup_box.add_theme_stylebox_override("panel", lookup_style)
	question_column.add_child(host.lookup_box)
	var lookup_margin := MarginContainer.new()
	lookup_margin.add_theme_constant_override("margin_left", 12)
	lookup_margin.add_theme_constant_override("margin_right", 12)
	lookup_margin.add_theme_constant_override("margin_top", 6)
	lookup_margin.add_theme_constant_override("margin_bottom", 6)
	host.lookup_box.add_child(lookup_margin)

	host.chapter_hint_label = Label.new()
	host.chapter_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.chapter_hint_label.add_theme_font_override("font", AppTheme.ui_font(500))
	host.chapter_hint_label.add_theme_font_size_override("font_size", 12)
	host.chapter_hint_label.add_theme_color_override("font_color", AppTheme.SKY_400)
	lookup_margin.add_child(host.chapter_hint_label)
	host.lookup_box.visible = false

	# Connect lookup box visibility to chapter hint
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
	host.question_table_heading.add_theme_font_size_override("font_size", 12)
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
	host.question_table_note.add_theme_font_size_override("font_size", 11)
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
	host.question_diagram_view.max_height = Main.DIAGRAM_MAX_H_DESKTOP
	diagram_margin.add_child(host.question_diagram_view)

	# Calculation Reference Box
	host.formula_box = PanelContainer.new()
	var formula_style := AppTheme.panel_style(AppTheme.PILL_SLATE_BG, AppTheme.BLUE_600, 1, 8)
	host.formula_box.add_theme_stylebox_override("panel", formula_style)
	question_column.add_child(host.formula_box)
	var formula_margin := MarginContainer.new()
	formula_margin.add_theme_constant_override("margin_left", 12)
	formula_margin.add_theme_constant_override("margin_right", 12)
	formula_margin.add_theme_constant_override("margin_top", 6)
	formula_margin.add_theme_constant_override("margin_bottom", 6)
	host.formula_box.add_child(formula_margin)

	host.question_formula_label = Label.new()
	host.question_formula_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.question_formula_label.add_theme_font_override("font", AppTheme.ui_font(500))
	host.question_formula_label.add_theme_font_size_override("font_size", 13)
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
	host.timer_bar.custom_minimum_size = Vector2(0, 6)
	var bar_bg := AppTheme.panel_style(AppTheme.SLATE_900, AppTheme.SLATE_800, 1, 3)
	var bar_fill := AppTheme.panel_style(AppTheme.SKY_600, AppTheme.SKY_400, 0, 3)
	host.timer_bar.add_theme_stylebox_override("background", bar_bg)
	host.timer_bar.add_theme_stylebox_override("fill", bar_fill)
	question_column.add_child(host.timer_bar)

	host.answers_box = VBoxContainer.new()
	host.answers_box.add_theme_constant_override("separation", 8)
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
	host.feedback_panel.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.FEEDBACK_BG, AppTheme.FEEDBACK_BORDER, 1, 14))
	quiz_column.add_child(host.feedback_panel)
	var feedback_margin := MarginContainer.new()
	feedback_margin.add_theme_constant_override("margin_left", 16)
	feedback_margin.add_theme_constant_override("margin_right", 16)
	feedback_margin.add_theme_constant_override("margin_top", 12)
	feedback_margin.add_theme_constant_override("margin_bottom", 12)
	host.feedback_panel.add_child(feedback_margin)
	var feedback_column := VBoxContainer.new()
	feedback_column.add_theme_constant_override("separation", 8)
	feedback_margin.add_child(feedback_column)
	host.feedback_title = Label.new()
	host.feedback_title.add_theme_font_override("font", AppTheme.ui_font(700))
	host.feedback_title.add_theme_font_size_override("font_size", 18)
	feedback_column.add_child(host.feedback_title)
	host.feedback_body = Label.new()
	host.feedback_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.feedback_body.add_theme_font_override("font", AppTheme.ui_font(500))
	host.feedback_body.add_theme_font_size_override("font_size", 14)
	host.feedback_body.add_theme_color_override("font_color", AppTheme.SLATE_100)
	feedback_column.add_child(host.feedback_body)
	host.feedback_reference = Label.new()
	host.feedback_reference.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.feedback_reference.add_theme_font_override("font", AppTheme.ui_font(600))
	host.feedback_reference.add_theme_font_size_override("font_size", 13)
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
	host.feedback_table_note.add_theme_font_size_override("font_size", 11)
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
	host.info_label.add_theme_font_size_override("normal_font_size", 14)
	host.info_label.add_theme_font_size_override("bold_font_size", 14)
	host.info_label.add_theme_constant_override("line_separation", 4)
	host.info_label.visible = false
	feedback_detail.add_child(host.info_label)
	host.next_button = Button.new()
	host.next_button.text = "Next question"
	host.next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.next_button.custom_minimum_size = Vector2(0, 48)
	host.next_button.pressed.connect(host._on_next_button_pressed)
	host.next_button.visible = false
	var btn_normal := AppTheme.panel_style(AppTheme.SKY_600, AppTheme.SKY_400, 1, 10)
	var btn_hover := AppTheme.panel_style(AppTheme.SKY_700, AppTheme.SKY_300, 2, 10)
	var btn_pressed := AppTheme.panel_style(AppTheme.SKY_800, AppTheme.SKY_400, 1, 10)
	host.next_button.add_theme_stylebox_override("normal", btn_normal)
	host.next_button.add_theme_stylebox_override("hover", btn_hover)
	host.next_button.add_theme_stylebox_override("pressed", btn_pressed)
	host.next_button.add_theme_font_size_override("font_size", 16)
	host.next_button.add_theme_color_override("font_color", AppTheme.WHITE)
	root.add_child(host.next_button)

	host.dock_panel = PanelContainer.new()
	var dock_style := AppTheme.panel_style(AppTheme.SURFACE_DEEP, AppTheme.SLATE_800, 1, 12)
	host.dock_panel.add_theme_stylebox_override("panel", dock_style)
	root.add_child(host.dock_panel)

	var dock_margin := MarginContainer.new()
	dock_margin.add_theme_constant_override("margin_left", 12)
	dock_margin.add_theme_constant_override("margin_right", 12)
	dock_margin.add_theme_constant_override("margin_top", 8)
	dock_margin.add_theme_constant_override("margin_bottom", 8)
	host.dock_panel.add_child(dock_margin)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 12)
	dock_margin.add_child(controls)

	host.mute_button = Widgets.make_dock_button("Sound off", 118, 42, 13, host._toggle_session_mute)
	controls.add_child(host.mute_button)

	host.read_button = Button.new()
	host.read_button.text = host._idle_read_label()
	host.read_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.read_button.custom_minimum_size = Vector2(0, 42)
	host.read_button.pressed.connect(host._toggle_read)
	var rb_norm := AppTheme.panel_style(AppTheme.READ_BUTTON_BG, AppTheme.READ_BUTTON_BORDER, 1, 9)
	var rb_hov := AppTheme.panel_style(AppTheme.READ_BUTTON_HOVER_BG, AppTheme.SKY_400, 2, 9)
	host.read_button.add_theme_stylebox_override("normal", rb_norm)
	host.read_button.add_theme_stylebox_override("hover", rb_hov)
	host.read_button.add_theme_font_override("font", AppTheme.ui_font(600))
	host.read_button.add_theme_font_size_override("font_size", 14)
	host.read_button.add_theme_color_override("font_color", AppTheme.SLATE_100)
	controls.add_child(host.read_button)

	host.pause_button = Widgets.make_dock_button("Pause", 130, 42, 14, host._toggle_listen_pause)
	controls.add_child(host.pause_button)
	host.skip_button = Widgets.make_dock_button("Skip  ›", 110, 42, 14, host._listen_skip)
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
	host.read_status_label.add_theme_font_override("font", AppTheme.ui_font(700))
	host.read_status_label.add_theme_font_size_override("font_size", 12)
	host.read_status_label.add_theme_color_override("font_color", AppTheme.SKY_400)
	host.read_status_label.clip_text = true
	# clip_text drops the min width to zero, so beside an expanding button the
	# label would get no room at all; reserve space while it is visible.
	host.read_status_label.custom_minimum_size = Vector2(250, 0)
	controls.add_child(host.read_status_label)

	host.restart_button = Button.new()
	host.restart_button.text = "Main menu"
	host.restart_button.custom_minimum_size = Vector2(110, 42)
	host.restart_button.pressed.connect(host._show_menu)
	var rst_norm := AppTheme.panel_style(AppTheme.DOCK_BUTTON_BG, AppTheme.DOCK_BUTTON_BORDER, 1, 9)
	var rst_hov := AppTheme.panel_style(AppTheme.DOCK_BUTTON_HOVER_BG, AppTheme.SLATE_600, 1, 9)
	host.restart_button.add_theme_stylebox_override("normal", rst_norm)
	host.restart_button.add_theme_stylebox_override("hover", rst_hov)
	host.restart_button.add_theme_font_override("font", AppTheme.ui_font(500))
	host.restart_button.add_theme_font_size_override("font_size", 14)
	host.restart_button.add_theme_color_override("font_color", AppTheme.SLATE_400)
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
	host.menu_overlay.add_child(UiFx.make_circuit_backdrop())
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
	var panel_sb := AppTheme.panel_style(AppTheme.MENU_PANEL_BG, AppTheme.SLATE_800, 1, 16)
	panel_sb.border_width_top = 3
	panel_sb.border_color = AppTheme.SKY_400
	panel_sb.shadow_color = Color(0, 0, 0, 0.5)
	panel_sb.shadow_size = 14
	host.menu_panel.add_theme_stylebox_override("panel", panel_sb)
	menu_outer_center.add_child(host.menu_panel)

	var menu_margin := MarginContainer.new()
	menu_margin.add_theme_constant_override("margin_left", 32)
	menu_margin.add_theme_constant_override("margin_right", 32)
	menu_margin.add_theme_constant_override("margin_top", 28)
	menu_margin.add_theme_constant_override("margin_bottom", 28)
	host.menu_panel.add_child(menu_margin)

	var menu_column := VBoxContainer.new()
	menu_column.add_theme_constant_override("separation", 14)
	menu_margin.add_child(menu_column)

	# Official Standards Top Badge
	var badge_box := HBoxContainer.new()
	badge_box.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_column.add_child(badge_box)

	var year_badge := Label.new()
	year_badge.text = " NFPA 70 • NEC 2023 EDITION • PSI EXAM STANDARDS "
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
	menu_title.add_theme_font_override("font", AppTheme.ui_font(700))
	menu_title.add_theme_font_size_override("font_size", 22)
	menu_title.add_theme_color_override("font_color", AppTheme.SLATE_50)
	menu_column.add_child(menu_title)
	UiFx.electrify_title(menu_title)

	var menu_subtitle := Label.new()
	menu_subtitle.text = "Master the National Electrical Code • Comprehensive Exam Prep"
	menu_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_subtitle.add_theme_font_size_override("font_size", 13)
	menu_subtitle.add_theme_color_override("font_color", AppTheme.SLATE_400)
	menu_column.add_child(menu_subtitle)

	var menu_rule := HSeparator.new()
	menu_column.add_child(menu_rule)

	# Practice Drills Section
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
	Widgets.add_mode_button(host, menu_column, "10 QUESTIONS", "Quick warm-up drill • 30 minutes timed", host._start_quiz.bind(10, host._practice_time(10), true, "10-Question Practice"), AppTheme.SKY_400, AppTheme.BUTTON_BG)
	Widgets.add_mode_button(host, menu_column, "20 QUESTIONS", "Standard focused session • 60 minutes timed", host._start_quiz.bind(20, host._practice_time(20), true, "20-Question Practice"), AppTheme.SKY_400, AppTheme.BUTTON_BG)
	Widgets.add_mode_button(host, menu_column, "30 QUESTIONS", "Extended study block • 90 minutes timed", host._start_quiz.bind(30, host._practice_time(30), true, "30-Question Practice"), AppTheme.SKY_400, AppTheme.BUTTON_BG)
	Widgets.add_mode_button(host, menu_column, "40 QUESTIONS", "Half-length diagnostic test • 120 minutes timed", host._start_quiz.bind(40, host._practice_time(40), true, "40-Question Practice"), AppTheme.SKY_400, AppTheme.BUTTON_BG)
	Widgets.add_mode_button(host, menu_column, "50 QUESTIONS", "Intensive endurance drill • 150 minutes timed", host._start_quiz.bind(50, host._practice_time(50), true, "50-Question Practice"), AppTheme.SKY_400, AppTheme.BUTTON_BG)

	# Full Simulation Section
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

	Widgets.add_mode_button(host, menu_column, "FULL JOURNEYMAN SIMULATOR", "80 scored questions • 240 minutes • 75% required to pass", host._start_quiz.bind(80, Main.EXAM_MINUTES * 60, true, "Full Journeyman Exam"), AppTheme.ROSE_500, AppTheme.EXAM_BUTTON_BG, true)


	var menu_note := Label.new()
	menu_note.text = "Aligned with NFPA 70 (NEC 2023) & Nebraska State Electrical Division / PSI Standards\nPacing standard: 3:00 per scored item • 80 questions timed"
	menu_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_note.add_theme_font_override("font", AppTheme.ui_font(400))
	menu_note.add_theme_font_size_override("font_size", 11)
	menu_note.add_theme_color_override("font_color", AppTheme.SLATE_500)
	menu_column.add_child(menu_note)
