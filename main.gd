extends Control

const BANK_PATH := "res://question_bank.json"
const ANSWER_LETTERS := ["A", "B", "C", "D"]
const SESSION_LENGTH := 10
const EXAM_NAME := "NE JOURNEYMAN ELECTRICIAN"
const EXAM_SCORED_ITEMS := 80
const EXAM_MINUTES := 240
const EXAM_NON_SCORED_ITEMS := 8
const EXAM_NON_SCORED_MINUTES := 30
const PASS_PERCENT := 75
const SECONDS_PER_SCORED_ITEM: int = (EXAM_MINUTES * 60) / EXAM_SCORED_ITEMS
const SESSION_TIME_SECONDS: int = SECONDS_PER_SCORED_ITEM * SESSION_LENGTH
const SpeechText = preload("res://speech_text.gd")

var records: Array = []
var order: Array[int] = []
var current_index := 0
var score := 0
var streak := 0
var answered_count := 0
var current_answered := false
var missed_questions: Array[Dictionary] = []
var time_left := SESSION_TIME_SECONDS
var session_length := SESSION_LENGTH
var session_time_limit := SESSION_TIME_SECONDS
var timed_session := true
var session_name := "Practice Test"
var question_time_left := SECONDS_PER_SCORED_ITEM
var timer: Timer

var progress_label: Label
var pass_badge: PanelContainer
var score_label: Label
var streak_label: Label
var question_label: Label
var question_table_panel: PanelContainer
var question_table_heading: Label
var question_table_grid: GridContainer
var question_table_note: Label
var question_table_scroll: ScrollContainer
var question_diagram_panel: PanelContainer
var question_diagram_label: Label
var question_formula_label: Label
var formula_box: PanelContainer
var chapter_hint_label: Label
var question_hint_row: HBoxContainer
var lookup_box: PanelContainer
var question_panel: PanelContainer
var article_label: Label
var exam_pills_row: HBoxContainer
var exam_label: Label
var exam_mode_pill: Label
var exam_license_pill: Label
var exam_pace_pill: Label
var timer_label: Label
var question_timer_label: Label
var timer_bar: ProgressBar
var answers_box: VBoxContainer
var feedback_panel: PanelContainer
var feedback_title: Label
var feedback_body: Label
var feedback_reference: Label
var feedback_table_scroll: ScrollContainer
var feedback_table_grid: GridContainer
var feedback_table_note: Label
var feedback_table_match_row := -1
var feedback_table_row_count := 0
var info_label: RichTextLabel
var next_button: Button
var read_button: Button
var voice_picker: OptionButton
var restart_button: Button
var dock_visualizer: VoiceVisualizer
var prompt_visualizer: VoiceVisualizer
# Platform UI: false = Windows/desktop layout (pixel-identical legacy UI),
# true = Android/mobile layout (touch-first). Preview on desktop with -- --mobile-ui.
var ui_mobile := false
var _last_go_back_msec := 0
var read_status_label: Label
var _native_segments: Array = []
var _native_seg: int = -1
var _native_generation: int = 0
var _native_voice_id: String = ""
var _native_tts_callbacks_registered: bool = false
var _native_watch_id: int = 0
var prompt_voice_badge: PanelContainer
var main_margin: MarginContainer
var menu_center_box: MarginContainer
var menu_overlay: Control
var menu_panel: PanelContainer
var menu_mode_buttons: Array[Button] = []
var reader: AudioStreamPlayer
var speak_thread: Thread
var speak_generation := 0
var speak_busy := false
var speech_queue: Array = []
var speech_queue_index := 0
var teach_from_index := -1
var want_teach := false
var voice_ids: Dictionary = {}

# Reading highlight state
var _current_record: Dictionary = {}
var _current_correct_answer: String = ""
var _info_table_highlighted: bool = false
var _active_teach_line: int = -1  # index into teach lines being highlighted
var _question_stem_glow_style: StyleBoxFlat = null  # cached glow style for question panel

func _exit_tree() -> void:
	# The TTS worker runs on speak_thread. Destroying the node while that thread is
	# still inside OS.execute() leaves Godot printing "Thread object is being
	# destroyed without its completion having been realized" and can tear the
	# thread down mid-write. Join it before the node goes away.
	_join_speak_thread()

func _join_speak_thread() -> void:
	if speak_thread != null and speak_thread.is_started():
		speak_thread.wait_to_finish()

func _ready() -> void:
	_load_voice_catalog()
	ui_mobile = "--mobile-ui" in OS.get_cmdline_args() or "--mobile-ui" in OS.get_cmdline_user_args() or OS.get_name() in ["Android", "iOS"]
	_build_ui()
	_apply_touch_filters()
	_apply_safe_area()
	# OS voices can arrive late on mobile: silently refresh the picker a few
	# seconds after launch so the first Read already offers real voices.
	if ui_mobile or not OS.has_feature("pc"):
		get_tree().create_timer(4.0).timeout.connect(_refresh_native_voices)
	get_viewport().size_changed.connect(_apply_safe_area)
	timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_tick_timer)
	add_child(timer)
	reader = AudioStreamPlayer.new()
	reader.finished.connect(_on_reader_finished)
	add_child(reader)
	_load_bank()
	if records.is_empty():
		_show_error("Question bank could not be loaded.")
	else:
		_show_menu()

func _apply_safe_area() -> void:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var win := get_window()
	var win_size: Vector2i = win.size if win != null else Vector2i.ZERO
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var cutouts: Array[Rect2] = DisplayServer.get_display_cutouts()
	var m := safe_area_margins(vp_size, win_size, safe_area, cutouts, ui_mobile)
	if is_instance_valid(main_margin):
		main_margin.add_theme_constant_override("margin_left", m["side"])
		main_margin.add_theme_constant_override("margin_right", m["side"])
		main_margin.add_theme_constant_override("margin_top", m["top"])
		main_margin.add_theme_constant_override("margin_bottom", m["bottom"])

	if is_instance_valid(menu_center_box):
		menu_center_box.add_theme_constant_override("margin_left", m["side"])
		menu_center_box.add_theme_constant_override("margin_right", m["side"])
		menu_center_box.add_theme_constant_override("margin_top", m["top"])
		menu_center_box.add_theme_constant_override("margin_bottom", m["bottom"])
	if ui_mobile and is_instance_valid(menu_panel):
		# Fit the INSIDE of the side margins, not the raw viewport: using
		# vp_size.x - 32 ignored side_margin and overflowed on any device with
		# a cutout, because the enclosing scroll clips instead of scrolling.
		var mms := menu_panel.custom_minimum_size
		mms.x = clampf(vp_size.x - float(m["side"]) * 2.0 - 16.0, 288.0, vp_size.x)
		menu_panel.custom_minimum_size = mms

## PURE margin math, split out so tools/tests/test_safe_area.gd can exercise the
## real function instead of a copy that can silently drift out of sync.
##
## vp_size / safe_area are in different spaces: get_display_safe_area() and
## get_display_cutouts() return PHYSICAL-SCREEN pixels, while the UI lays out in
## stretched canvas units, so every inset is scaled by vp_size.x / win_size.x.
##
## safe_area is a RECT, not a set of edge distances: the bottom inset is the gap
## from the rect's BOTTOM EDGE to the screen bottom, i.e.
## (screen_height - (pos.y + size.y)). Using (size.y - pos.y) instead measures
## the rect's own height and produced ~1100px margins that collapsed the content
## box to a blank strip - the app drew its header and dock and showed no
## question at all.
static func safe_area_margins(vp_size: Vector2, win_size: Vector2i, safe_area: Rect2i,
		cutouts: Array, is_mobile: bool) -> Dictionary:
	var top_margin: int = 16 if is_mobile else 24
	var bottom_margin: int = 16 if is_mobile else 24
	var side_margin: int = 16 if is_mobile else 20

	var scale: float = 1.0
	if win_size.x > 0:
		scale = vp_size.x / float(win_size.x)
	if scale <= 0.0:
		scale = 1.0

	var top_inset := 0.0
	var bottom_inset := 0.0
	var left_inset := 0.0
	var right_inset := 0.0
	if safe_area.size.y > 0 and vp_size.y > 0:
		top_inset = float(safe_area.position.y) * scale
		bottom_inset = maxf(0.0, (float(win_size.y) - float(safe_area.position.y + safe_area.size.y)) * scale)
	if safe_area.size.x > 0 and vp_size.x > 0:
		left_inset = float(safe_area.position.x) * scale
		right_inset = maxf(0.0, (float(win_size.x) - float(safe_area.position.x + safe_area.size.x)) * scale)
	# A cutout is a LOCALISED hole, not an edge-to-edge inset, so it must not be
	# max()'d against the full screen width/height. Only count a cutout towards
	# an edge when it actually touches that edge, and clamp the result so a
	# malformed rect can never eat the whole screen.
	for rect_v in cutouts:
		var rect := rect_v as Rect2
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		var touches_top: bool = rect.position.y <= 1.0
		var touches_left: bool = rect.position.x <= 1.0
		var touches_right: bool = (rect.position.x + rect.size.x) >= float(win_size.x) - 1.0
		# A cutout on the top edge, or a notch that spans the full width, does
		# need top padding. Side notches only inset their own side.
		if touches_top:
			top_inset = maxf(top_inset, float(rect.position.y + rect.size.y) * scale)
		if touches_left:
			left_inset = maxf(left_inset, float(rect.position.x + rect.size.x) * scale)
		if touches_right:
			right_inset = maxf(right_inset, (float(win_size.x) - float(rect.position.x)) * scale)
	# An inset may never exceed the viewport it insets; clamp before use.
	top_inset = clampf(top_inset, 0.0, vp_size.y * 0.25)
	bottom_inset = clampf(bottom_inset, 0.0, vp_size.y * 0.25)
	left_inset = clampf(left_inset, 0.0, vp_size.x * 0.25)
	right_inset = clampf(right_inset, 0.0, vp_size.x * 0.25)

	# Padding beyond the raw inset keeps content clear of the bar edge and of
	# the mandatory system gesture zones along the bottom.
	if top_inset > 0.0:
		top_margin = maxi(top_margin, int(round(top_inset)) + 8)
	if bottom_inset > 0.0:
		bottom_margin = maxi(bottom_margin, int(round(bottom_inset)) + 12)
	if left_inset > 0.0 or right_inset > 0.0:
		side_margin = maxi(side_margin, int(round(maxf(left_inset, right_inset))) + 8)
	return {"top": top_margin, "bottom": bottom_margin, "side": side_margin}

func _load_bank() -> void:
	if not FileAccess.file_exists(BANK_PATH):
		return
	var file := FileAccess.open(BANK_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		# ONLY "records" is authoritative. The old fallback chain also accepted a
		# top-level "questions" key, which holds the RAW pre-curation rows:
		# un-redacted stems and answers in their original units (36" instead of
		# "36 inches"). If "records" were ever missing, that fallback would have
		# silently loaded stale, partly-unredacted data - a latent answer leak.
		var source = parsed.get("records", [])
		if source is Array:
			for raw in source:
				var record := _normalize_record(raw)
				if not record.is_empty():
					records.append(record)
	elif parsed is Array:
		for raw in parsed:
			var record := _normalize_record(raw)
			if not record.is_empty():
				records.append(record)

func _normalize_record(raw) -> Dictionary:
	if raw is Dictionary:
		var record: Dictionary = raw.duplicate(true)
		if not record.has("answers") and record.has("choices"):
			record["answers"] = record["choices"]
		if not record.has("correct_index") and record.has("answer"):
			record["correct_index"] = record["answer"]
		if not record.has("article"):
			record["article"] = "General knowledge"
		if not record.has("article_title") or str(record.article_title).strip_edges() == "":
			record["article_title"] = _article_title(str(record.article))
		return record
	if raw is Array and raw.size() >= 4:
		var answers = raw[2] if raw[2] is Array else []
		var article := str(raw[4]) if raw.size() > 4 else "General knowledge"
		return {
			"exam": str(raw[0]),
			"prompt": str(raw[1]),
			"answers": answers,
			"correct_index": int(raw[3]),
			"article": article,
			"article_title": _article_title(article),
			"difficulty": str(raw[7]) if raw.size() > 7 else "medium"
		}
	return {}

func _article_title(reference: String) -> String:
	var match := RegEx.create_from_string("\\b(\\d{3})\\b").search(reference)
	if match == null:
		return reference if reference != "" else "General knowledge"
	var titles := {
		100: "Definitions", 110: "Requirements for Electrical Installations",
		200: "Use and Identification of Grounded Conductors", 210: "Branch Circuits",
		215: "Feeders", 220: "Load Calculations", 225: "Outside Branch Circuits and Feeders",
		230: "Services", 240: "Overcurrent Protection", 250: "Grounding and Bonding",
		300: "Wiring Methods and Materials", 310: "Conductors for General Wiring",
		314: "Outlet, Device, Pull, and Junction Boxes", 334: "Nonmetallic-Sheathed Cable",
		344: "Rigid Metal Conduit", 358: "Electrical Metallic Tubing",
		400: "Flexible Cords and Flexible Cables", 404: "Switches",
		406: "Wiring Devices", 408: "Switchboards, Switchgear, and Panelboards",
		410: "Luminaires, Lampholders, and Lamps", 422: "Appliances",
		430: "Motors, Motor Circuits, and Controllers", 440: "Air-Conditioning Equipment",
		450: "Transformers", 500: "Hazardous Locations", 550: "Mobile Homes",
		551: "Recreational Vehicles", 590: "Temporary Installations",
		625: "Electric Vehicle Power Transfer Systems", 630: "Electric Welders",
		680: "Swimming Pools, Fountains, and Similar Installations"
	}
	return str(titles.get(int(match.get_string(1)), "NEC Article " + match.get_string(1)))

func _format_nec_reference(record: Dictionary) -> String:
	var reference := str(record.get("article", "General knowledge"))
	var title := str(record.get("article_title", _article_title(reference)))
	var match := RegEx.create_from_string("\\b(\\d{3})\\b").search(reference)
	if match == null:
		return reference
	var article_number := match.get_string(1)
	return "Article %s %s — %s" % [article_number, title, reference]

func _lookup_navigation_path(record: Dictionary) -> String:
	var reference := str(record.get("article", "")).strip_edges()
	var code := reference.replace("NEC ", "").strip_edges()
	var chapter_names := {
		1: "General",
		2: "Wiring and Protection",
		3: "Wiring Methods and Materials",
		4: "Equipment for General Use",
		5: "Special Occupancies",
		6: "Special Equipment",
		7: "Special Conditions",
		8: "Communications Systems",
		9: "Tables",
	}
	var chapter_match := RegEx.create_from_string("(?i)\\bChapter\\s+(\\d+)\\b").search(code)
	var chapter := 0
	if chapter_match != null:
		chapter = int(chapter_match.get_string(1))
	var section_match := RegEx.create_from_string("\\b(\\d{3}(?:\\.\\d+)?(?:\\([A-Za-z0-9]+\\))*)").search(code)
	var article_number := ""
	if section_match != null:
		var section_number := section_match.get_string(1)
		article_number = section_number.substr(0, 3)
		if chapter == 0:
			var article_value := int(article_number)
			if article_value >= 100 and article_value < 900:
				chapter = int(article_value / 100)
	if chapter_names.has(chapter):
		if article_number != "":
			var article_title := str(record.get("article_title", "")).strip_edges()
			var article_path := "Article " + article_number
			if article_title != "":
				article_path += " (" + article_title + ")"
			return "NEC 2023  ►  Chapter %d: %s  ►  %s" % [chapter, chapter_names[chapter], article_path]
		return "NEC 2023  ►  Chapter %d: %s" % [chapter, chapter_names[chapter]]
	if code.to_lower().contains("nfpa 70e"):
		return "NFPA 70E  ►  Standard for Electrical Safety in the Workplace"
	var article_lower := code.to_lower()
	if article_lower in ["general calculation", "general math"] or str(record.get("formula", "")) != "":
		return "CALCULATION  ►  Basic Ohm's Law / General Math"
	if article_lower == "general knowledge":
		return "GENERAL TRADE KNOWLEDGE  ►  Standard Electrical Practice"
	return ""

func _start_quiz(question_count: int = SESSION_LENGTH, time_limit: int = SESSION_TIME_SECONDS, timed: bool = true, mode_name: String = "Practice Test") -> void:
	order.clear()
	for i in records.size():
		order.append(i)
	order.shuffle()
	session_length = mini(question_count, records.size())
	if order.size() > session_length:
		order.resize(session_length)
	session_time_limit = time_limit
	timed_session = timed
	session_name = mode_name
	current_index = 0
	score = 0
	streak = 0
	answered_count = 0
	current_answered = false
	missed_questions.clear()
	time_left = session_time_limit
	question_time_left = SECONDS_PER_SCORED_ITEM
	if timed_session:
		timer.start()
	else:
		timer.stop()
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(menu_overlay, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func():
		menu_overlay.visible = false
		_show_question()
	)

func _build_ui() -> void:
	if ui_mobile:
		_build_mobile_ui()
		return
	# 2026 Illustrated NEC Edition Backdrop (Windows/desktop layout — do not restyle):
	# Deep obsidian-black into electric slate-blue gradient
	var bg_gradient := Gradient.new()
	bg_gradient.set_color(0, Color("020408"))
	bg_gradient.set_color(1, Color("08101e"))
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
	add_child(bg_rect)

	main_margin = MarginContainer.new()
	main_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_margin.add_theme_constant_override("margin_left", 20)
	main_margin.add_theme_constant_override("margin_right", 20)
	main_margin.add_theme_constant_override("margin_top", 24)
	main_margin.add_theme_constant_override("margin_bottom", 24)
	add_child(main_margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	main_margin.add_child(root)

	var quiz_scroll := ScrollContainer.new()
	quiz_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	quiz_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quiz_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	quiz_scroll.scroll_started.connect(_reset_pressed_cards)
	root.add_child(quiz_scroll)
	var quiz_column := VBoxContainer.new()
	quiz_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quiz_column.add_theme_constant_override("separation", 12)
	quiz_scroll.add_child(quiz_column)

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
	title.add_theme_font_override("font", _ui_font(700))
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color("f8fafc"))
	title_box.add_child(title)

	progress_label = Label.new()
	progress_label.add_theme_font_override("font", _ui_font(600))
	progress_label.add_theme_font_size_override("font_size", 12)
	progress_label.add_theme_color_override("font_color", Color("38bdf8"))
	title_box.add_child(progress_label)

	# Target Pass Pill Badge (75% Pass Standard per PSI CIB)
	pass_badge = PanelContainer.new()
	var pass_badge_style := _panel_style("0f291e", "059669", 1, 8)
	pass_badge.add_theme_stylebox_override("panel", pass_badge_style)
	var pass_margin := MarginContainer.new()
	pass_margin.add_theme_constant_override("margin_left", 12)
	pass_margin.add_theme_constant_override("margin_right", 12)
	pass_margin.add_theme_constant_override("margin_top", 6)
	pass_margin.add_theme_constant_override("margin_bottom", 6)
	pass_badge.add_child(pass_margin)
	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_override("font", _ui_font(700))
	score_label.add_theme_font_size_override("font_size", 12)
	score_label.add_theme_color_override("font_color", Color("6ee7b7"))
	pass_margin.add_child(score_label)
	header.add_child(pass_badge)

	# Session Type Badge (PSI Test Specification)
	var streak_badge := PanelContainer.new()
	var streak_badge_style := _panel_style("132035", "1e3a5f", 1, 8)
	streak_badge.add_theme_stylebox_override("panel", streak_badge_style)
	var streak_margin := MarginContainer.new()
	streak_margin.add_theme_constant_override("margin_left", 12)
	streak_margin.add_theme_constant_override("margin_right", 12)
	streak_margin.add_theme_constant_override("margin_top", 6)
	streak_margin.add_theme_constant_override("margin_bottom", 6)
	streak_badge.add_child(streak_margin)
	streak_label = Label.new()
	streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	streak_label.add_theme_font_override("font", _ui_font(600))
	streak_label.add_theme_font_size_override("font_size", 12)
	streak_label.add_theme_color_override("font_color", Color("7dd3fc"))
	streak_margin.add_child(streak_label)
	header.add_child(streak_badge)

	# Overall Exam Timer Badge
	var timer_badge := PanelContainer.new()
	timer_badge.add_theme_stylebox_override("panel", _panel_style("141c2a", "334155", 1, 8))
	var timer_m := MarginContainer.new()
	timer_m.add_theme_constant_override("margin_left", 12)
	timer_m.add_theme_constant_override("margin_right", 12)
	timer_m.add_theme_constant_override("margin_top", 6)
	timer_m.add_theme_constant_override("margin_bottom", 6)
	timer_badge.add_child(timer_m)
	timer_label = Label.new()
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_override("font", _ui_font(700))
	timer_label.add_theme_font_size_override("font_size", 13)
	timer_label.add_theme_color_override("font_color", Color("f8fafc"))
	timer_m.add_child(timer_label)
	header.add_child(timer_badge)

	# Pace Item Timer Badge
	var pace_badge := PanelContainer.new()
	pace_badge.add_theme_stylebox_override("panel", _panel_style("0f2334", "0284c7", 1, 8))
	var pace_m := MarginContainer.new()
	pace_m.add_theme_constant_override("margin_left", 12)
	pace_m.add_theme_constant_override("margin_right", 12)
	pace_m.add_theme_constant_override("margin_top", 6)
	pace_m.add_theme_constant_override("margin_bottom", 6)
	pace_badge.add_child(pace_m)
	question_timer_label = Label.new()
	question_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_timer_label.add_theme_font_override("font", _ui_font(700))
	question_timer_label.add_theme_font_size_override("font_size", 13)
	question_timer_label.add_theme_color_override("font_color", Color("38bdf8"))
	pace_m.add_child(question_timer_label)
	header.add_child(pace_badge)

	question_panel = PanelContainer.new()
	var qp_style := _panel_style("0a0f1d", "1e293b", 1, 14)
	qp_style.shadow_color = Color(0, 0, 0, 0.4)
	qp_style.shadow_size = 10
	question_panel.add_theme_stylebox_override("panel", qp_style)
	quiz_column.add_child(question_panel)
	var question_margin := MarginContainer.new()
	question_margin.add_theme_constant_override("margin_left", 20)
	question_margin.add_theme_constant_override("margin_right", 20)
	question_margin.add_theme_constant_override("margin_top", 18)
	question_margin.add_theme_constant_override("margin_bottom", 18)
	question_panel.add_child(question_margin)
	var question_column := VBoxContainer.new()
	question_column.add_theme_constant_override("separation", 12)
	question_margin.add_child(question_column)

	# Exam Header Pills Row
	exam_pills_row = HBoxContainer.new()
	exam_pills_row.add_theme_constant_override("separation", 8)
	question_column.add_child(exam_pills_row)

	exam_label = Label.new()
	exam_label.visible = false
	exam_pills_row.add_child(exam_label)

	var mode_pill_panel := PanelContainer.new()
	mode_pill_panel.add_theme_stylebox_override("panel", _panel_style("132035", "1e3a5f", 1, 6))
	var mode_pill_m := MarginContainer.new()
	mode_pill_m.add_theme_constant_override("margin_left", 8)
	mode_pill_m.add_theme_constant_override("margin_right", 8)
	mode_pill_m.add_theme_constant_override("margin_top", 3)
	mode_pill_m.add_theme_constant_override("margin_bottom", 3)
	mode_pill_panel.add_child(mode_pill_m)
	exam_mode_pill = Label.new()
	exam_mode_pill.add_theme_font_override("font", _ui_font(700))
	exam_mode_pill.add_theme_font_size_override("font_size", 11)
	exam_mode_pill.add_theme_color_override("font_color", Color("38bdf8"))
	mode_pill_m.add_child(exam_mode_pill)
	exam_pills_row.add_child(mode_pill_panel)

	var lic_pill_panel := PanelContainer.new()
	lic_pill_panel.add_theme_stylebox_override("panel", _panel_style("141c2a", "334155", 1, 6))
	var lic_pill_m := MarginContainer.new()
	lic_pill_m.add_theme_constant_override("margin_left", 8)
	lic_pill_m.add_theme_constant_override("margin_right", 8)
	lic_pill_m.add_theme_constant_override("margin_top", 3)
	lic_pill_m.add_theme_constant_override("margin_bottom", 3)
	lic_pill_panel.add_child(lic_pill_m)
	exam_license_pill = Label.new()
	exam_license_pill.add_theme_font_override("font", _ui_font(600))
	exam_license_pill.add_theme_font_size_override("font_size", 11)
	exam_license_pill.add_theme_color_override("font_color", Color("cbd5e1"))
	lic_pill_m.add_child(exam_license_pill)
	exam_pills_row.add_child(lic_pill_panel)

	var pace_pill_panel := PanelContainer.new()
	pace_pill_panel.add_theme_stylebox_override("panel", _panel_style("1e2213", "854d0e", 1, 6))
	var pace_pill_m := MarginContainer.new()
	pace_pill_m.add_theme_constant_override("margin_left", 8)
	pace_pill_m.add_theme_constant_override("margin_right", 8)
	pace_pill_m.add_theme_constant_override("margin_top", 3)
	pace_pill_m.add_theme_constant_override("margin_bottom", 3)
	pace_pill_panel.add_child(pace_pill_m)
	exam_pace_pill = Label.new()
	exam_pace_pill.add_theme_font_override("font", _ui_font(600))
	exam_pace_pill.add_theme_font_size_override("font_size", 11)
	exam_pace_pill.add_theme_color_override("font_color", Color("fef08a"))
	pace_pill_m.add_child(exam_pace_pill)
	exam_pills_row.add_child(pace_pill_panel)

	# Question Stem Voice Visualizer Badge
	prompt_voice_badge = PanelContainer.new()
	prompt_voice_badge.add_theme_stylebox_override("panel", _panel_style("06263b", "0284c7", 1, 6))
	var pvb_margin := MarginContainer.new()
	pvb_margin.add_theme_constant_override("margin_left", 8)
	pvb_margin.add_theme_constant_override("margin_right", 8)
	pvb_margin.add_theme_constant_override("margin_top", 3)
	pvb_margin.add_theme_constant_override("margin_bottom", 3)
	prompt_voice_badge.add_child(pvb_margin)
	var pvb_hbox := HBoxContainer.new()
	pvb_hbox.add_theme_constant_override("separation", 6)
	pvb_margin.add_child(pvb_hbox)
	prompt_visualizer = VoiceVisualizer.new()
	prompt_visualizer.bar_count = 4
	prompt_visualizer.bar_width = 2.5
	prompt_visualizer.bar_gap = 2.0
	prompt_visualizer.custom_minimum_size = Vector2(18, 14)
	prompt_visualizer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pvb_hbox.add_child(prompt_visualizer)
	var pvb_text := Label.new()
	pvb_text.text = "READING AUDIO"
	pvb_text.add_theme_font_override("font", _ui_font(700))
	pvb_text.add_theme_font_size_override("font_size", 10)
	pvb_text.add_theme_color_override("font_color", Color("38bdf8"))
	pvb_hbox.add_child(pvb_text)
	prompt_voice_badge.visible = false
	exam_pills_row.add_child(prompt_voice_badge)

	question_label = Label.new()
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.add_theme_font_override("font", _ui_font(700))
	question_label.add_theme_font_size_override("font_size", 21)
	question_label.add_theme_color_override("font_color", Color("ffffff"))
	question_column.add_child(question_label)

	# Subtitle / Gist Hint with Left Accent Bar
	var hint_hbox := HBoxContainer.new()
	question_hint_row = hint_hbox
	hint_hbox.add_theme_constant_override("separation", 10)
	question_column.add_child(hint_hbox)

	var hint_bar := ColorRect.new()
	hint_bar.custom_minimum_size = Vector2(3, 18)
	hint_bar.size_flags_vertical = Control.SIZE_FILL
	hint_bar.color = Color("38bdf8")
	hint_hbox.add_child(hint_bar)

	article_label = Label.new()
	article_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	article_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	article_label.add_theme_font_override("font", _ui_font(500))
	article_label.add_theme_font_size_override("font_size", 14)
	article_label.add_theme_color_override("font_color", Color("e2e8f0"))
	hint_hbox.add_child(article_label)

	# Lookup Path Callout Box
	lookup_box = PanelContainer.new()
	var lookup_style := _panel_style("0d192c", "1e3a5f", 1, 8)
	lookup_box.add_theme_stylebox_override("panel", lookup_style)
	question_column.add_child(lookup_box)
	var lookup_margin := MarginContainer.new()
	lookup_margin.add_theme_constant_override("margin_left", 12)
	lookup_margin.add_theme_constant_override("margin_right", 12)
	lookup_margin.add_theme_constant_override("margin_top", 6)
	lookup_margin.add_theme_constant_override("margin_bottom", 6)
	lookup_box.add_child(lookup_margin)

	chapter_hint_label = Label.new()
	chapter_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chapter_hint_label.add_theme_font_override("font", _ui_font(500))
	chapter_hint_label.add_theme_font_size_override("font_size", 12)
	chapter_hint_label.add_theme_color_override("font_color", Color("38bdf8"))
	lookup_margin.add_child(chapter_hint_label)
	lookup_box.visible = false

	# Connect lookup box visibility to chapter hint
	chapter_hint_label.item_rect_changed.connect(func():
		if is_instance_valid(lookup_box) and is_instance_valid(chapter_hint_label):
			lookup_box.visible = chapter_hint_label.visible
	)

	question_table_panel = PanelContainer.new()
	question_table_panel.add_theme_stylebox_override("panel", _panel_style("091322", "1e3a5f", 1, 9))
	question_table_panel.custom_minimum_size = Vector2(0, 120)
	question_table_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	question_table_panel.visible = false
	question_column.add_child(question_table_panel)
	var question_table_margin := MarginContainer.new()
	question_table_margin.add_theme_constant_override("margin_left", 10)
	question_table_margin.add_theme_constant_override("margin_right", 10)
	question_table_margin.add_theme_constant_override("margin_top", 7)
	question_table_margin.add_theme_constant_override("margin_bottom", 7)
	question_table_panel.add_child(question_table_margin)
	var question_table_column := VBoxContainer.new()
	question_table_column.add_theme_constant_override("separation", 5)
	question_table_margin.add_child(question_table_column)
	question_table_heading = Label.new()
	question_table_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_table_heading.add_theme_font_size_override("font_size", 12)
	question_table_heading.add_theme_color_override("font_color", Color("7dd3fc"))
	question_table_column.add_child(question_table_heading)
	question_table_scroll = ScrollContainer.new()
	question_table_scroll.custom_minimum_size = Vector2(0, 42)
	question_table_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	question_table_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	question_table_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	question_table_column.add_child(question_table_scroll)
	question_table_grid = GridContainer.new()
	question_table_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	question_table_grid.add_theme_constant_override("h_separation", 0)
	question_table_grid.add_theme_constant_override("v_separation", 0)
	question_table_scroll.add_child(question_table_grid)
	question_table_note = Label.new()
	question_table_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_table_note.add_theme_font_size_override("font_size", 11)
	question_table_note.add_theme_color_override("font_color", Color("cbd5e1"))
	question_table_column.add_child(question_table_note)

	question_diagram_panel = PanelContainer.new()
	question_diagram_panel.add_theme_stylebox_override("panel", _panel_style("0a1322", "1e3a5f", 1, 8))
	question_diagram_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	question_diagram_panel.visible = false
	question_column.add_child(question_diagram_panel)
	var diagram_margin := MarginContainer.new()
	diagram_margin.add_theme_constant_override("margin_left", 14)
	diagram_margin.add_theme_constant_override("margin_right", 14)
	diagram_margin.add_theme_constant_override("margin_top", 10)
	diagram_margin.add_theme_constant_override("margin_bottom", 10)
	question_diagram_panel.add_child(diagram_margin)
	question_diagram_label = Label.new()
	question_diagram_label.add_theme_font_override("font", _monospace_font())
	question_diagram_label.add_theme_font_size_override("font_size", 12)
	question_diagram_label.add_theme_color_override("font_color", Color("7dd3fc"))
	question_diagram_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	diagram_margin.add_child(question_diagram_label)

	# Calculation Reference Box
	formula_box = PanelContainer.new()
	var formula_style := _panel_style("141c2a", "2563eb", 1, 8)
	formula_box.add_theme_stylebox_override("panel", formula_style)
	question_column.add_child(formula_box)
	var formula_margin := MarginContainer.new()
	formula_margin.add_theme_constant_override("margin_left", 12)
	formula_margin.add_theme_constant_override("margin_right", 12)
	formula_margin.add_theme_constant_override("margin_top", 6)
	formula_margin.add_theme_constant_override("margin_bottom", 6)
	formula_box.add_child(formula_margin)

	question_formula_label = Label.new()
	question_formula_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_formula_label.add_theme_font_override("font", _ui_font(500))
	question_formula_label.add_theme_font_size_override("font_size", 13)
	question_formula_label.add_theme_color_override("font_color", Color("93c5fd"))
	formula_margin.add_child(question_formula_label)
	formula_box.visible = false

	# Connect formula box visibility to question_formula_label
	question_formula_label.item_rect_changed.connect(func():
		if is_instance_valid(formula_box) and is_instance_valid(question_formula_label):
			formula_box.visible = question_formula_label.visible
	)

	timer_bar = ProgressBar.new()
	timer_bar.min_value = 0
	timer_bar.max_value = SESSION_TIME_SECONDS
	timer_bar.show_percentage = false
	timer_bar.custom_minimum_size = Vector2(0, 6)
	var bar_bg := _panel_style("0f172a", "1e293b", 1, 3)
	var bar_fill := _panel_style("0284c7", "38bdf8", 0, 3)
	timer_bar.add_theme_stylebox_override("background", bar_bg)
	timer_bar.add_theme_stylebox_override("fill", bar_fill)
	question_column.add_child(timer_bar)

	answers_box = VBoxContainer.new()
	answers_box.add_theme_constant_override("separation", 10)
	quiz_column.add_child(answers_box)

	feedback_panel = PanelContainer.new()
	feedback_panel.add_theme_stylebox_override("panel", _panel_style("13213a", "29476f", 1, 14))
	quiz_column.add_child(feedback_panel)
	var feedback_margin := MarginContainer.new()
	feedback_margin.add_theme_constant_override("margin_left", 16)
	feedback_margin.add_theme_constant_override("margin_right", 16)
	feedback_margin.add_theme_constant_override("margin_top", 12)
	feedback_margin.add_theme_constant_override("margin_bottom", 12)
	feedback_panel.add_child(feedback_margin)
	var feedback_column := VBoxContainer.new()
	feedback_column.add_theme_constant_override("separation", 8)
	feedback_margin.add_child(feedback_column)
	feedback_title = Label.new()
	feedback_title.add_theme_font_override("font", _ui_font(700))
	feedback_title.add_theme_font_size_override("font_size", 18)
	feedback_column.add_child(feedback_title)
	feedback_body = Label.new()
	feedback_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_body.add_theme_font_override("font", _ui_font(500))
	feedback_body.add_theme_font_size_override("font_size", 14)
	feedback_body.add_theme_color_override("font_color", Color("f1f5f9"))
	feedback_column.add_child(feedback_body)
	feedback_reference = Label.new()
	feedback_reference.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_reference.add_theme_font_override("font", _ui_font(600))
	feedback_reference.add_theme_font_size_override("font_size", 13)
	feedback_reference.add_theme_color_override("font_color", Color("7dd3fc"))
	feedback_reference.visible = false
	feedback_column.add_child(feedback_reference)
	feedback_table_scroll = ScrollContainer.new()
	feedback_table_scroll.custom_minimum_size = Vector2(0, 42)
	feedback_table_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feedback_table_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	feedback_table_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	feedback_table_scroll.visible = false
	feedback_column.add_child(feedback_table_scroll)
	feedback_table_grid = GridContainer.new()
	feedback_table_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feedback_table_grid.add_theme_constant_override("h_separation", 0)
	feedback_table_grid.add_theme_constant_override("v_separation", 0)
	feedback_table_scroll.add_child(feedback_table_grid)
	feedback_table_note = Label.new()
	feedback_table_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_table_note.add_theme_font_size_override("font_size", 11)
	feedback_table_note.add_theme_color_override("font_color", Color("cbd5e1"))
	feedback_table_note.visible = false
	feedback_column.add_child(feedback_table_note)
	info_label = RichTextLabel.new()
	info_label.fit_content = true
	info_label.scroll_active = false
	info_label.custom_minimum_size = Vector2(0, 0)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.add_theme_font_override("normal_font", _ui_font(400))
	info_label.add_theme_font_override("bold_font", _ui_font(700))
	info_label.add_theme_color_override("default_color", Color("f1f5f9"))
	info_label.add_theme_font_size_override("normal_font_size", 14)
	info_label.add_theme_font_size_override("bold_font_size", 14)
	info_label.add_theme_constant_override("line_separation", 4)
	info_label.visible = false
	feedback_column.add_child(info_label)
	next_button = Button.new()
	next_button.text = "Next question"
	next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_button.custom_minimum_size = Vector2(0, 48)
	next_button.pressed.connect(_on_next_button_pressed)
	next_button.visible = false
	var btn_normal := _panel_style("0284c7", "38bdf8", 1, 10)
	var btn_hover := _panel_style("0369a1", "7dd3fc", 2, 10)
	var btn_pressed := _panel_style("075985", "38bdf8", 1, 10)
	next_button.add_theme_stylebox_override("normal", btn_normal)
	next_button.add_theme_stylebox_override("hover", btn_hover)
	next_button.add_theme_stylebox_override("pressed", btn_pressed)
	next_button.add_theme_font_size_override("font_size", 16)
	next_button.add_theme_color_override("font_color", Color("ffffff"))
	root.add_child(next_button)

	var dock_panel := PanelContainer.new()
	var dock_style := _panel_style("0a0f1d", "1e293b", 1, 12)
	dock_panel.add_theme_stylebox_override("panel", dock_style)
	root.add_child(dock_panel)

	var dock_margin := MarginContainer.new()
	dock_margin.add_theme_constant_override("margin_left", 12)
	dock_margin.add_theme_constant_override("margin_right", 12)
	dock_margin.add_theme_constant_override("margin_top", 8)
	dock_margin.add_theme_constant_override("margin_bottom", 8)
	dock_panel.add_child(dock_margin)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 12)
	dock_margin.add_child(controls)

	voice_picker = OptionButton.new()
	voice_picker.custom_minimum_size = Vector2(210, 42)
	var vp_norm := _panel_style("0f1a2e", "1e3a5f", 1, 9)
	var vp_hov := _panel_style("162640", "38bdf8", 2, 9)
	var vp_pressed := _panel_style("0c1526", "0284c7", 1, 9)
	voice_picker.add_theme_stylebox_override("normal", vp_norm)
	voice_picker.add_theme_stylebox_override("hover", vp_hov)
	voice_picker.add_theme_stylebox_override("pressed", vp_pressed)
	voice_picker.add_theme_stylebox_override("focus", vp_hov)
	voice_picker.add_theme_font_override("font", _ui_font(500))
	voice_picker.add_theme_font_size_override("font_size", 13)
	voice_picker.add_theme_color_override("font_color", Color("e2e8f0"))
	voice_picker.add_theme_color_override("font_hover_color", Color("ffffff"))
	voice_picker.add_theme_color_override("font_pressed_color", Color("38bdf8"))

	# Style the dropdown PopupMenu so it matches the UI theme
	var popup: PopupMenu = voice_picker.get_popup()
	if popup:
		var pop_panel := _panel_style("0a1220", "1e3a5f", 1, 10)
		pop_panel.shadow_color = Color(0, 0, 0, 0.7)
		pop_panel.shadow_size = 14
		pop_panel.content_margin_left = 8
		pop_panel.content_margin_right = 8
		pop_panel.content_margin_top = 8
		pop_panel.content_margin_bottom = 8
		popup.add_theme_stylebox_override("panel", pop_panel)
		
		var item_hover := _panel_style("14253d", "38bdf8", 1, 6)
		popup.add_theme_stylebox_override("hover", item_hover)
		popup.add_theme_font_override("font", _ui_font(500))
		popup.add_theme_font_size_override("font_size", 13)
		popup.add_theme_color_override("font_color", Color("cbd5e1"))
		popup.add_theme_color_override("font_hover_color", Color("ffffff"))
		popup.add_theme_color_override("font_separator_color", Color("1e293b"))
		popup.add_theme_constant_override("v_separation", 8)
		popup.add_theme_constant_override("item_start_padding", 10)
		popup.add_theme_constant_override("item_end_padding", 10)

	_populate_voice_picker()
	controls.add_child(voice_picker)

	read_button = Button.new()
	read_button.text = "Read question"
	read_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	read_button.custom_minimum_size = Vector2(0, 42)
	read_button.pressed.connect(_toggle_read)
	var rb_norm := _panel_style("142238", "2d4a77", 1, 9)
	var rb_hov := _panel_style("1e3458", "38bdf8", 2, 9)
	read_button.add_theme_stylebox_override("normal", rb_norm)
	read_button.add_theme_stylebox_override("hover", rb_hov)
	read_button.add_theme_font_override("font", _ui_font(600))
	read_button.add_theme_font_size_override("font_size", 14)
	read_button.add_theme_color_override("font_color", Color("f1f5f9"))
	controls.add_child(read_button)

	# Bottom Dock Voice Visualizer Pod
	dock_visualizer = VoiceVisualizer.new()
	dock_visualizer.bar_count = 6
	dock_visualizer.bar_width = 3.5
	dock_visualizer.bar_gap = 3.0
	dock_visualizer.custom_minimum_size = Vector2(40, 24)
	dock_visualizer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dock_visualizer.visible = false
	controls.add_child(dock_visualizer)

	# NOW READING indicator: unmissable text showing exactly which part is spoken.
	read_status_label = Label.new()
	read_status_label.text = ""
	read_status_label.visible = false
	read_status_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	read_status_label.add_theme_font_override("font", _ui_font(700))
	read_status_label.add_theme_font_size_override("font_size", 12)
	read_status_label.add_theme_color_override("font_color", Color("38bdf8"))
	read_status_label.clip_text = true
	controls.add_child(read_status_label)

	restart_button = Button.new()
	restart_button.text = "Main menu"
	restart_button.custom_minimum_size = Vector2(110, 42)
	restart_button.pressed.connect(_show_menu)
	var rst_norm := _panel_style("111d31", "223659", 1, 9)
	var rst_hov := _panel_style("1a2c4b", "475569", 1, 9)
	restart_button.add_theme_stylebox_override("normal", rst_norm)
	restart_button.add_theme_stylebox_override("hover", rst_hov)
	restart_button.add_theme_font_override("font", _ui_font(500))
	restart_button.add_theme_font_size_override("font_size", 14)
	restart_button.add_theme_color_override("font_color", Color("94a3b8"))
	controls.add_child(restart_button)

	feedback_panel.visible = false

	menu_overlay = Control.new()
	menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_overlay.z_index = 20
	add_child(menu_overlay)
	var menu_background := ColorRect.new()
	menu_background.color = Color("020408")
	menu_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_overlay.add_child(menu_background)
	var menu_scroll := ScrollContainer.new()
	menu_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_overlay.add_child(menu_scroll)
	menu_center_box = MarginContainer.new()
	menu_center_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_center_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_center_box.add_theme_constant_override("margin_left", 20)
	menu_center_box.add_theme_constant_override("margin_right", 20)
	menu_center_box.add_theme_constant_override("margin_top", 24)
	menu_center_box.add_theme_constant_override("margin_bottom", 24)
	menu_scroll.add_child(menu_center_box)

	var menu_outer_center := CenterContainer.new()
	menu_outer_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_outer_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_center_box.add_child(menu_outer_center)

	menu_panel = PanelContainer.new()
	menu_panel.custom_minimum_size = Vector2(860, 0)
	var panel_sb := _panel_style("0c1322", "1e293b", 1, 16)
	panel_sb.border_width_top = 3
	panel_sb.border_color = Color("38bdf8")
	panel_sb.shadow_color = Color(0, 0, 0, 0.5)
	panel_sb.shadow_size = 14
	menu_panel.add_theme_stylebox_override("panel", panel_sb)
	menu_outer_center.add_child(menu_panel)

	var menu_margin := MarginContainer.new()
	menu_margin.add_theme_constant_override("margin_left", 32)
	menu_margin.add_theme_constant_override("margin_right", 32)
	menu_margin.add_theme_constant_override("margin_top", 28)
	menu_margin.add_theme_constant_override("margin_bottom", 28)
	menu_panel.add_child(menu_margin)

	var menu_column := VBoxContainer.new()
	menu_column.add_theme_constant_override("separation", 14)
	menu_margin.add_child(menu_column)

	# Official Standards Top Badge
	var badge_box := HBoxContainer.new()
	badge_box.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_column.add_child(badge_box)

	var year_badge := Label.new()
	year_badge.text = " NFPA 70 • NEC 2023 EDITION • PSI EXAM STANDARDS "
	year_badge.add_theme_font_override("font", _ui_font(700))
	year_badge.add_theme_font_size_override("font_size", 11)
	year_badge.add_theme_color_override("font_color", Color("38bdf8"))
	var yb_style := _panel_style("0f2338", "0284c7", 1, 6)
	yb_style.content_margin_left = 12
	yb_style.content_margin_right = 12
	yb_style.content_margin_top = 4
	yb_style.content_margin_bottom = 4
	year_badge.add_theme_stylebox_override("normal", yb_style)
	badge_box.add_child(year_badge)

	var menu_title := Label.new()
	menu_title.text = "NEC 2023 // JOURNEYMAN CHALLENGE"
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_title.add_theme_font_override("font", _ui_font(700))
	menu_title.add_theme_font_size_override("font_size", 22)
	menu_title.add_theme_color_override("font_color", Color("f8fafc"))
	menu_column.add_child(menu_title)

	var menu_subtitle := Label.new()
	menu_subtitle.text = "Master the National Electrical Code • Comprehensive Exam Prep"
	menu_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_subtitle.add_theme_font_size_override("font_size", 13)
	menu_subtitle.add_theme_color_override("font_color", Color("94a3b8"))
	menu_column.add_child(menu_subtitle)

	var menu_rule := HSeparator.new()
	menu_column.add_child(menu_rule)

	# Practice Drills Section
	var practice_hdr_box := HBoxContainer.new()
	practice_hdr_box.add_theme_constant_override("separation", 8)
	menu_column.add_child(practice_hdr_box)

	var practice_bar := ColorRect.new()
	practice_bar.custom_minimum_size = Vector2(4, 16)
	practice_bar.color = Color("38bdf8")
	practice_hdr_box.add_child(practice_bar)

	var practice_heading := Label.new()
	practice_heading.text = "RAPID PRACTICE DRILLS"
	practice_heading.add_theme_font_size_override("font_size", 12)
	practice_heading.add_theme_color_override("font_color", Color("38bdf8"))
	practice_hdr_box.add_child(practice_heading)

	menu_mode_buttons.clear()
	_add_mode_button(menu_column, "10 QUESTIONS", "Quick warm-up drill • 30 minutes timed", _start_quiz.bind(10, _practice_time(10), true, "10-Question Practice"), "38bdf8", "111928")
	_add_mode_button(menu_column, "20 QUESTIONS", "Standard focused session • 60 minutes timed", _start_quiz.bind(20, _practice_time(20), true, "20-Question Practice"), "38bdf8", "111928")
	_add_mode_button(menu_column, "30 QUESTIONS", "Extended study block • 90 minutes timed", _start_quiz.bind(30, _practice_time(30), true, "30-Question Practice"), "38bdf8", "111928")
	_add_mode_button(menu_column, "40 QUESTIONS", "Half-length diagnostic test • 120 minutes timed", _start_quiz.bind(40, _practice_time(40), true, "40-Question Practice"), "38bdf8", "111928")
	_add_mode_button(menu_column, "50 QUESTIONS", "Intensive endurance drill • 150 minutes timed", _start_quiz.bind(50, _practice_time(50), true, "50-Question Practice"), "38bdf8", "111928")

	# Full Simulation Section
	var exam_hdr_box := HBoxContainer.new()
	exam_hdr_box.add_theme_constant_override("separation", 8)
	menu_column.add_child(exam_hdr_box)

	var exam_bar := ColorRect.new()
	exam_bar.custom_minimum_size = Vector2(4, 16)
	exam_bar.color = Color("f43f5e")
	exam_hdr_box.add_child(exam_bar)

	var exam_heading := Label.new()
	exam_heading.text = "OFFICIAL LICENSING SIMULATION"
	exam_heading.add_theme_font_override("font", _ui_font(700))
	exam_heading.add_theme_font_size_override("font_size", 12)
	exam_heading.add_theme_color_override("font_color", Color("f43f5e"))
	exam_hdr_box.add_child(exam_heading)

	_add_mode_button(menu_column, "FULL JOURNEYMAN SIMULATOR", "80 scored questions • 240 minutes • 75% required to pass", _start_quiz.bind(80, EXAM_MINUTES * 60, true, "Full Journeyman Exam"), "f43f5e", "1e141d", true)


	var menu_note := Label.new()
	menu_note.text = "Aligned with NFPA 70 (NEC 2023) & Nebraska State Electrical Division / PSI Standards\nPacing standard: 3:00 per scored item • 80 questions timed"
	menu_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_note.add_theme_font_override("font", _ui_font(400))
	menu_note.add_theme_font_size_override("font_size", 11)
	menu_note.add_theme_color_override("font_color", Color("64748b"))
	menu_column.add_child(menu_note)

func _build_mobile_ui() -> void:
	# ANDROID layout: touch-first, phone-safe. Same member set as desktop so all
	# game logic runs untouched; roomier targets, two-row header, narrow-safe menu.
	# prompt_voice_badge / prompt_visualizer stay null by design (all uses guarded) —
	# the dock status line is the mobile "now reading" indicator.
	var bg_gradient := Gradient.new()
	bg_gradient.set_color(0, Color("020408"))
	bg_gradient.set_color(1, Color("08101e"))
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
	add_child(bg_rect)

	main_margin = MarginContainer.new()
	main_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_margin.add_theme_constant_override("margin_left", 16)
	main_margin.add_theme_constant_override("margin_right", 16)
	main_margin.add_theme_constant_override("margin_top", 16)
	main_margin.add_theme_constant_override("margin_bottom", 16)
	add_child(main_margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	main_margin.add_child(root)

	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	root.add_child(header)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	header.add_child(title_row)
	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 2)
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_box)
	var title := Label.new()
	title.text = "NEC 2023 // JOURNEYMAN CHALLENGE"
	title.add_theme_font_override("font", _ui_font(700))
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color("f8fafc"))
	title_box.add_child(title)
	progress_label = Label.new()
	progress_label.add_theme_font_override("font", _ui_font(600))
	progress_label.add_theme_font_size_override("font_size", 13)
	progress_label.add_theme_color_override("font_color", Color("38bdf8"))
	title_box.add_child(progress_label)

	var badge_row := HBoxContainer.new()
	badge_row.add_theme_constant_override("separation", 8)
	header.add_child(badge_row)
	pass_badge = PanelContainer.new()
	pass_badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pass_badge.add_theme_stylebox_override("panel", _panel_style("0f291e", "059669", 1, 8))
	badge_row.add_child(pass_badge)
	var pass_m := MarginContainer.new()
	pass_m.add_theme_constant_override("margin_left", 6)
	pass_m.add_theme_constant_override("margin_right", 6)
	pass_m.add_theme_constant_override("margin_top", 8)
	pass_m.add_theme_constant_override("margin_bottom", 8)
	pass_badge.add_child(pass_m)
	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_override("font", _ui_font(700))
	score_label.add_theme_font_size_override("font_size", 12)
	score_label.add_theme_color_override("font_color", Color("6ee7b7"))
	pass_m.add_child(score_label)
	var streak_badge := PanelContainer.new()
	streak_badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	streak_badge.add_theme_stylebox_override("panel", _panel_style("132035", "1e3a5f", 1, 8))
	badge_row.add_child(streak_badge)
	var streak_m := MarginContainer.new()
	streak_m.add_theme_constant_override("margin_left", 6)
	streak_m.add_theme_constant_override("margin_right", 6)
	streak_m.add_theme_constant_override("margin_top", 8)
	streak_m.add_theme_constant_override("margin_bottom", 8)
	streak_badge.add_child(streak_m)
	streak_label = Label.new()
	streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	streak_label.add_theme_font_override("font", _ui_font(600))
	streak_label.add_theme_font_size_override("font_size", 12)
	streak_label.add_theme_color_override("font_color", Color("7dd3fc"))
	streak_m.add_child(streak_label)
	var timer_badge := PanelContainer.new()
	timer_badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timer_badge.add_theme_stylebox_override("panel", _panel_style("141c2a", "334155", 1, 8))
	badge_row.add_child(timer_badge)
	var timer_m := MarginContainer.new()
	timer_m.add_theme_constant_override("margin_left", 6)
	timer_m.add_theme_constant_override("margin_right", 6)
	timer_m.add_theme_constant_override("margin_top", 8)
	timer_m.add_theme_constant_override("margin_bottom", 8)
	timer_badge.add_child(timer_m)
	timer_label = Label.new()
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_override("font", _ui_font(700))
	timer_label.add_theme_font_size_override("font_size", 12)
	timer_label.add_theme_color_override("font_color", Color("f8fafc"))
	timer_m.add_child(timer_label)
	var pace_badge := PanelContainer.new()
	pace_badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pace_badge.add_theme_stylebox_override("panel", _panel_style("0f2334", "0284c7", 1, 8))
	badge_row.add_child(pace_badge)
	var pace_m := MarginContainer.new()
	pace_m.add_theme_constant_override("margin_left", 6)
	pace_m.add_theme_constant_override("margin_right", 6)
	pace_m.add_theme_constant_override("margin_top", 8)
	pace_m.add_theme_constant_override("margin_bottom", 8)
	pace_badge.add_child(pace_m)
	question_timer_label = Label.new()
	question_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_timer_label.add_theme_font_override("font", _ui_font(700))
	question_timer_label.add_theme_font_size_override("font_size", 12)
	question_timer_label.add_theme_color_override("font_color", Color("38bdf8"))
	pace_m.add_child(question_timer_label)

	var quiz_scroll := ScrollContainer.new()
	quiz_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	quiz_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quiz_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	quiz_scroll.scroll_started.connect(_reset_pressed_cards)
	root.add_child(quiz_scroll)
	var quiz_column := VBoxContainer.new()
	quiz_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quiz_column.add_theme_constant_override("separation", 12)
	quiz_scroll.add_child(quiz_column)

	question_panel = PanelContainer.new()
	var qp_style := _panel_style("0a0f1d", "1e293b", 1, 14)
	qp_style.shadow_color = Color(0, 0, 0, 0.4)
	qp_style.shadow_size = 10
	question_panel.add_theme_stylebox_override("panel", qp_style)
	quiz_column.add_child(question_panel)
	var question_margin := MarginContainer.new()
	question_margin.add_theme_constant_override("margin_left", 16)
	question_margin.add_theme_constant_override("margin_right", 16)
	question_margin.add_theme_constant_override("margin_top", 14)
	question_margin.add_theme_constant_override("margin_bottom", 14)
	question_panel.add_child(question_margin)
	var question_column := VBoxContainer.new()
	question_column.add_theme_constant_override("separation", 12)
	question_margin.add_child(question_column)

	exam_pills_row = HBoxContainer.new()
	exam_pills_row.add_theme_constant_override("separation", 8)
	question_column.add_child(exam_pills_row)
	exam_label = Label.new()
	exam_label.visible = false
	exam_pills_row.add_child(exam_label)
	var mode_pill_panel := PanelContainer.new()
	mode_pill_panel.add_theme_stylebox_override("panel", _panel_style("132035", "1e3a5f", 1, 6))
	var mode_pill_m := MarginContainer.new()
	mode_pill_m.add_theme_constant_override("margin_left", 8)
	mode_pill_m.add_theme_constant_override("margin_right", 8)
	mode_pill_m.add_theme_constant_override("margin_top", 4)
	mode_pill_m.add_theme_constant_override("margin_bottom", 4)
	mode_pill_panel.add_child(mode_pill_m)
	exam_mode_pill = Label.new()
	exam_mode_pill.add_theme_font_override("font", _ui_font(700))
	exam_mode_pill.add_theme_font_size_override("font_size", 12)
	exam_mode_pill.add_theme_color_override("font_color", Color("38bdf8"))
	mode_pill_m.add_child(exam_mode_pill)
	exam_pills_row.add_child(mode_pill_panel)
	var lic_pill_panel := PanelContainer.new()
	lic_pill_panel.add_theme_stylebox_override("panel", _panel_style("141c2a", "334155", 1, 6))
	var lic_pill_m := MarginContainer.new()
	lic_pill_m.add_theme_constant_override("margin_left", 8)
	lic_pill_m.add_theme_constant_override("margin_right", 8)
	lic_pill_m.add_theme_constant_override("margin_top", 4)
	lic_pill_m.add_theme_constant_override("margin_bottom", 4)
	lic_pill_panel.add_child(lic_pill_m)
	exam_license_pill = Label.new()
	exam_license_pill.add_theme_font_override("font", _ui_font(600))
	exam_license_pill.add_theme_font_size_override("font_size", 12)
	exam_license_pill.add_theme_color_override("font_color", Color("cbd5e1"))
	lic_pill_m.add_child(exam_license_pill)
	exam_pills_row.add_child(lic_pill_panel)
	var pace_pill_panel := PanelContainer.new()
	pace_pill_panel.add_theme_stylebox_override("panel", _panel_style("1e2213", "854d0e", 1, 6))
	var pace_pill_m := MarginContainer.new()
	pace_pill_m.add_theme_constant_override("margin_left", 8)
	pace_pill_m.add_theme_constant_override("margin_right", 8)
	pace_pill_m.add_theme_constant_override("margin_top", 4)
	pace_pill_m.add_theme_constant_override("margin_bottom", 4)
	pace_pill_panel.add_child(pace_pill_m)
	exam_pace_pill = Label.new()
	exam_pace_pill.add_theme_font_override("font", _ui_font(600))
	exam_pace_pill.add_theme_font_size_override("font_size", 12)
	exam_pace_pill.add_theme_color_override("font_color", Color("fef08a"))
	pace_pill_m.add_child(exam_pace_pill)
	exam_pills_row.add_child(pace_pill_panel)

	question_label = Label.new()
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.add_theme_font_override("font", _ui_font(700))
	question_label.add_theme_font_size_override("font_size", 23)
	question_label.add_theme_color_override("font_color", Color("ffffff"))
	question_column.add_child(question_label)

	var hint_hbox := HBoxContainer.new()
	hint_hbox.add_theme_constant_override("separation", 10)
	question_column.add_child(hint_hbox)
	question_hint_row = hint_hbox
	var hint_bar := ColorRect.new()
	hint_bar.custom_minimum_size = Vector2(3, 18)
	hint_bar.size_flags_vertical = Control.SIZE_FILL
	hint_bar.color = Color("38bdf8")
	hint_hbox.add_child(hint_bar)
	article_label = Label.new()
	article_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	article_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	article_label.add_theme_font_override("font", _ui_font(500))
	article_label.add_theme_font_size_override("font_size", 15)
	article_label.add_theme_color_override("font_color", Color("e2e8f0"))
	hint_hbox.add_child(article_label)

	lookup_box = PanelContainer.new()
	lookup_box.add_theme_stylebox_override("panel", _panel_style("0d192c", "1e3a5f", 1, 8))
	question_column.add_child(lookup_box)
	var lookup_margin := MarginContainer.new()
	lookup_margin.add_theme_constant_override("margin_left", 12)
	lookup_margin.add_theme_constant_override("margin_right", 12)
	lookup_margin.add_theme_constant_override("margin_top", 8)
	lookup_margin.add_theme_constant_override("margin_bottom", 8)
	lookup_box.add_child(lookup_margin)
	chapter_hint_label = Label.new()
	chapter_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chapter_hint_label.add_theme_font_override("font", _ui_font(500))
	chapter_hint_label.add_theme_font_size_override("font_size", 13)
	chapter_hint_label.add_theme_color_override("font_color", Color("38bdf8"))
	lookup_margin.add_child(chapter_hint_label)
	lookup_box.visible = false
	chapter_hint_label.item_rect_changed.connect(func():
		if is_instance_valid(lookup_box) and is_instance_valid(chapter_hint_label):
			lookup_box.visible = chapter_hint_label.visible
	)

	question_table_panel = PanelContainer.new()
	question_table_panel.add_theme_stylebox_override("panel", _panel_style("091322", "1e3a5f", 1, 9))
	question_table_panel.custom_minimum_size = Vector2(0, 120)
	question_table_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	question_table_panel.visible = false
	question_column.add_child(question_table_panel)
	var question_table_margin := MarginContainer.new()
	question_table_margin.add_theme_constant_override("margin_left", 10)
	question_table_margin.add_theme_constant_override("margin_right", 10)
	question_table_margin.add_theme_constant_override("margin_top", 7)
	question_table_margin.add_theme_constant_override("margin_bottom", 7)
	question_table_panel.add_child(question_table_margin)
	var question_table_column := VBoxContainer.new()
	question_table_column.add_theme_constant_override("separation", 5)
	question_table_margin.add_child(question_table_column)
	question_table_heading = Label.new()
	question_table_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_table_heading.add_theme_font_size_override("font_size", 13)
	question_table_heading.add_theme_color_override("font_color", Color("7dd3fc"))
	question_table_column.add_child(question_table_heading)
	question_table_scroll = ScrollContainer.new()
	question_table_scroll.custom_minimum_size = Vector2(0, 42)
	question_table_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	question_table_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	question_table_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	question_table_column.add_child(question_table_scroll)
	question_table_grid = GridContainer.new()
	question_table_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	question_table_grid.add_theme_constant_override("h_separation", 0)
	question_table_grid.add_theme_constant_override("v_separation", 0)
	question_table_scroll.add_child(question_table_grid)
	question_table_note = Label.new()
	question_table_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_table_note.add_theme_font_size_override("font_size", 12)
	question_table_note.add_theme_color_override("font_color", Color("cbd5e1"))
	question_table_column.add_child(question_table_note)

	question_diagram_panel = PanelContainer.new()
	question_diagram_panel.add_theme_stylebox_override("panel", _panel_style("0a1322", "1e3a5f", 1, 8))
	question_diagram_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	question_diagram_panel.visible = false
	question_column.add_child(question_diagram_panel)
	var diagram_margin := MarginContainer.new()
	diagram_margin.add_theme_constant_override("margin_left", 14)
	diagram_margin.add_theme_constant_override("margin_right", 14)
	diagram_margin.add_theme_constant_override("margin_top", 10)
	diagram_margin.add_theme_constant_override("margin_bottom", 10)
	question_diagram_panel.add_child(diagram_margin)
	question_diagram_label = Label.new()
	question_diagram_label.add_theme_font_override("font", _monospace_font())
	question_diagram_label.add_theme_font_size_override("font_size", 12)
	question_diagram_label.add_theme_color_override("font_color", Color("7dd3fc"))
	question_diagram_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	diagram_margin.add_child(question_diagram_label)

	formula_box = PanelContainer.new()
	formula_box.add_theme_stylebox_override("panel", _panel_style("141c2a", "2563eb", 1, 8))
	question_column.add_child(formula_box)
	var formula_margin := MarginContainer.new()
	formula_margin.add_theme_constant_override("margin_left", 12)
	formula_margin.add_theme_constant_override("margin_right", 12)
	formula_margin.add_theme_constant_override("margin_top", 8)
	formula_margin.add_theme_constant_override("margin_bottom", 8)
	formula_box.add_child(formula_margin)
	question_formula_label = Label.new()
	question_formula_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_formula_label.add_theme_font_override("font", _ui_font(500))
	question_formula_label.add_theme_font_size_override("font_size", 14)
	question_formula_label.add_theme_color_override("font_color", Color("93c5fd"))
	formula_margin.add_child(question_formula_label)
	formula_box.visible = false
	question_formula_label.item_rect_changed.connect(func():
		if is_instance_valid(formula_box) and is_instance_valid(question_formula_label):
			formula_box.visible = question_formula_label.visible
	)

	timer_bar = ProgressBar.new()
	timer_bar.min_value = 0
	timer_bar.max_value = SESSION_TIME_SECONDS
	timer_bar.show_percentage = false
	timer_bar.custom_minimum_size = Vector2(0, 8)
	var bar_bg := _panel_style("0f172a", "1e293b", 1, 3)
	var bar_fill := _panel_style("0284c7", "38bdf8", 0, 3)
	timer_bar.add_theme_stylebox_override("background", bar_bg)
	timer_bar.add_theme_stylebox_override("fill", bar_fill)
	question_column.add_child(timer_bar)

	answers_box = VBoxContainer.new()
	answers_box.add_theme_constant_override("separation", 12)
	quiz_column.add_child(answers_box)

	feedback_panel = PanelContainer.new()
	feedback_panel.add_theme_stylebox_override("panel", _panel_style("13213a", "29476f", 1, 14))
	quiz_column.add_child(feedback_panel)
	var feedback_margin := MarginContainer.new()
	feedback_margin.add_theme_constant_override("margin_left", 16)
	feedback_margin.add_theme_constant_override("margin_right", 16)
	feedback_margin.add_theme_constant_override("margin_top", 14)
	feedback_margin.add_theme_constant_override("margin_bottom", 14)
	feedback_panel.add_child(feedback_margin)
	var feedback_column := VBoxContainer.new()
	feedback_column.add_theme_constant_override("separation", 10)
	feedback_margin.add_child(feedback_column)
	feedback_title = Label.new()
	feedback_title.add_theme_font_override("font", _ui_font(700))
	feedback_title.add_theme_font_size_override("font_size", 19)
	feedback_column.add_child(feedback_title)
	feedback_body = Label.new()
	feedback_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_body.add_theme_font_override("font", _ui_font(500))
	feedback_body.add_theme_font_size_override("font_size", 15)
	feedback_body.add_theme_color_override("font_color", Color("f1f5f9"))
	feedback_column.add_child(feedback_body)
	feedback_reference = Label.new()
	feedback_reference.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_reference.add_theme_font_override("font", _ui_font(600))
	feedback_reference.add_theme_font_size_override("font_size", 14)
	feedback_reference.add_theme_color_override("font_color", Color("7dd3fc"))
	feedback_reference.visible = false
	feedback_column.add_child(feedback_reference)
	feedback_table_scroll = ScrollContainer.new()
	feedback_table_scroll.custom_minimum_size = Vector2(0, 42)
	feedback_table_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feedback_table_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	feedback_table_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	feedback_table_scroll.visible = false
	feedback_column.add_child(feedback_table_scroll)
	feedback_table_grid = GridContainer.new()
	feedback_table_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feedback_table_grid.add_theme_constant_override("h_separation", 0)
	feedback_table_grid.add_theme_constant_override("v_separation", 0)
	feedback_table_scroll.add_child(feedback_table_grid)
	feedback_table_note = Label.new()
	feedback_table_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_table_note.add_theme_font_size_override("font_size", 12)
	feedback_table_note.add_theme_color_override("font_color", Color("cbd5e1"))
	feedback_table_note.visible = false
	feedback_column.add_child(feedback_table_note)
	info_label = RichTextLabel.new()
	info_label.fit_content = true
	info_label.scroll_active = false
	info_label.custom_minimum_size = Vector2(0, 0)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.add_theme_font_override("normal_font", _ui_font(400))
	info_label.add_theme_font_override("bold_font", _ui_font(700))
	info_label.add_theme_color_override("default_color", Color("f1f5f9"))
	info_label.add_theme_font_size_override("normal_font_size", 15)
	info_label.add_theme_font_size_override("bold_font_size", 15)
	info_label.add_theme_constant_override("line_separation", 4)
	info_label.visible = false
	feedback_column.add_child(info_label)
	next_button = Button.new()
	next_button.text = "Next question"
	next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_button.custom_minimum_size = Vector2(0, 56)
	next_button.pressed.connect(_on_next_button_pressed)
	next_button.visible = false
	var btn_normal := _panel_style("0284c7", "38bdf8", 1, 10)
	var btn_hover := _panel_style("0369a1", "7dd3fc", 2, 10)
	var btn_pressed := _panel_style("075985", "38bdf8", 1, 10)
	next_button.add_theme_stylebox_override("normal", btn_normal)
	next_button.add_theme_stylebox_override("hover", btn_hover)
	next_button.add_theme_stylebox_override("pressed", btn_pressed)
	next_button.add_theme_font_size_override("font_size", 18)
	next_button.add_theme_color_override("font_color", Color("ffffff"))
	root.add_child(next_button)

	var dock_panel := PanelContainer.new()
	dock_panel.add_theme_stylebox_override("panel", _panel_style("0a0f1d", "1e293b", 1, 12))
	root.add_child(dock_panel)
	var dock_margin := MarginContainer.new()
	dock_margin.add_theme_constant_override("margin_left", 12)
	dock_margin.add_theme_constant_override("margin_right", 12)
	dock_margin.add_theme_constant_override("margin_top", 10)
	dock_margin.add_theme_constant_override("margin_bottom", 10)
	dock_panel.add_child(dock_margin)
	var dock_column := VBoxContainer.new()
	dock_column.add_theme_constant_override("separation", 8)
	dock_margin.add_child(dock_column)
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 10)
	dock_column.add_child(controls)
	voice_picker = OptionButton.new()
	voice_picker.custom_minimum_size = Vector2(150, 56)
	var vp_norm := _panel_style("0f1a2e", "1e3a5f", 1, 9)
	var vp_hov := _panel_style("162640", "38bdf8", 2, 9)
	voice_picker.add_theme_stylebox_override("normal", vp_norm)
	voice_picker.add_theme_stylebox_override("hover", vp_hov)
	voice_picker.add_theme_font_override("font", _ui_font(500))
	voice_picker.add_theme_font_size_override("font_size", 13)
	voice_picker.add_theme_color_override("font_color", Color("e2e8f0"))
	voice_picker.add_theme_color_override("font_hover_color", Color("ffffff"))
	var popup: PopupMenu = voice_picker.get_popup()
	if popup:
		popup.add_theme_stylebox_override("panel", _panel_style("0a1220", "1e3a5f", 1, 10))
		popup.add_theme_font_override("font", _ui_font(500))
		popup.add_theme_font_size_override("font_size", 14)
		popup.add_theme_color_override("font_color", Color("cbd5e1"))
		popup.add_theme_color_override("font_hover_color", Color("ffffff"))
	_populate_voice_picker()
	controls.add_child(voice_picker)
	read_button = Button.new()
	read_button.text = "Read question"
	read_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	read_button.custom_minimum_size = Vector2(0, 56)
	read_button.pressed.connect(_toggle_read)
	var rb_norm := _panel_style("142238", "2d4a77", 1, 9)
	var rb_hov := _panel_style("1e3458", "38bdf8", 2, 9)
	read_button.add_theme_stylebox_override("normal", rb_norm)
	read_button.add_theme_stylebox_override("hover", rb_hov)
	read_button.add_theme_font_override("font", _ui_font(600))
	read_button.add_theme_font_size_override("font_size", 16)
	read_button.add_theme_color_override("font_color", Color("f1f5f9"))
	controls.add_child(read_button)
	restart_button = Button.new()
	restart_button.text = "Menu"
	restart_button.custom_minimum_size = Vector2(96, 56)
	restart_button.pressed.connect(_show_menu)
	var rst_norm := _panel_style("111d31", "223659", 1, 9)
	var rst_hov := _panel_style("1a2c4b", "475569", 1, 9)
	restart_button.add_theme_stylebox_override("normal", rst_norm)
	restart_button.add_theme_stylebox_override("hover", rst_hov)
	restart_button.add_theme_font_override("font", _ui_font(500))
	restart_button.add_theme_font_size_override("font_size", 14)
	restart_button.add_theme_color_override("font_color", Color("94a3b8"))
	controls.add_child(restart_button)
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 8)
	dock_column.add_child(status_row)
	dock_visualizer = VoiceVisualizer.new()
	dock_visualizer.bar_count = 6
	dock_visualizer.bar_width = 3.5
	dock_visualizer.bar_gap = 3.0
	dock_visualizer.custom_minimum_size = Vector2(40, 24)
	dock_visualizer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dock_visualizer.visible = false
	status_row.add_child(dock_visualizer)
	read_status_label = Label.new()
	read_status_label.text = ""
	read_status_label.visible = false
	read_status_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	read_status_label.add_theme_font_override("font", _ui_font(700))
	read_status_label.add_theme_font_size_override("font_size", 13)
	read_status_label.add_theme_color_override("font_color", Color("38bdf8"))
	read_status_label.clip_text = true
	status_row.add_child(read_status_label)
	feedback_panel.visible = false

	menu_overlay = Control.new()
	menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_overlay.z_index = 20
	add_child(menu_overlay)
	var menu_background := ColorRect.new()
	menu_background.color = Color("020408")
	menu_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_overlay.add_child(menu_background)
	var menu_scroll := ScrollContainer.new()
	menu_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_overlay.add_child(menu_scroll)
	menu_center_box = MarginContainer.new()
	menu_center_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_center_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_center_box.add_theme_constant_override("margin_left", 16)
	menu_center_box.add_theme_constant_override("margin_right", 16)
	menu_center_box.add_theme_constant_override("margin_top", 16)
	menu_center_box.add_theme_constant_override("margin_bottom", 16)
	menu_scroll.add_child(menu_center_box)
	var menu_outer_center := CenterContainer.new()
	menu_outer_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_outer_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_center_box.add_child(menu_outer_center)
	menu_panel = PanelContainer.new()
	menu_panel.custom_minimum_size = Vector2(320, 0)
	var panel_sb := _panel_style("0c1322", "1e293b", 1, 16)
	panel_sb.border_width_top = 3
	panel_sb.border_color = Color("38bdf8")
	panel_sb.shadow_color = Color(0, 0, 0, 0.5)
	panel_sb.shadow_size = 14
	menu_panel.add_theme_stylebox_override("panel", panel_sb)
	menu_outer_center.add_child(menu_panel)
	var menu_margin := MarginContainer.new()
	menu_margin.add_theme_constant_override("margin_left", 24)
	menu_margin.add_theme_constant_override("margin_right", 24)
	menu_margin.add_theme_constant_override("margin_top", 24)
	menu_margin.add_theme_constant_override("margin_bottom", 24)
	menu_panel.add_child(menu_margin)
	var menu_column := VBoxContainer.new()
	menu_column.add_theme_constant_override("separation", 14)
	menu_margin.add_child(menu_column)
	var badge_box := HBoxContainer.new()
	badge_box.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_column.add_child(badge_box)
	var year_badge := Label.new()
	year_badge.text = " NFPA 70 • NEC 2023 • PSI STANDARDS "
	year_badge.add_theme_font_override("font", _ui_font(700))
	year_badge.add_theme_font_size_override("font_size", 11)
	year_badge.add_theme_color_override("font_color", Color("38bdf8"))
	var yb_style := _panel_style("0f2338", "0284c7", 1, 6)
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
	menu_title.add_theme_font_override("font", _ui_font(700))
	menu_title.add_theme_font_size_override("font_size", 24)
	menu_title.add_theme_color_override("font_color", Color("f8fafc"))
	menu_column.add_child(menu_title)
	var menu_subtitle := Label.new()
	menu_subtitle.text = "Master the National Electrical Code • Comprehensive Exam Prep"
	menu_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_subtitle.add_theme_font_size_override("font_size", 13)
	menu_subtitle.add_theme_color_override("font_color", Color("94a3b8"))
	menu_column.add_child(menu_subtitle)
	var menu_rule := HSeparator.new()
	menu_column.add_child(menu_rule)
	var practice_hdr_box := HBoxContainer.new()
	practice_hdr_box.add_theme_constant_override("separation", 8)
	menu_column.add_child(practice_hdr_box)
	var practice_bar := ColorRect.new()
	practice_bar.custom_minimum_size = Vector2(4, 16)
	practice_bar.color = Color("38bdf8")
	practice_hdr_box.add_child(practice_bar)
	var practice_heading := Label.new()
	practice_heading.text = "RAPID PRACTICE DRILLS"
	practice_heading.add_theme_font_size_override("font_size", 12)
	practice_heading.add_theme_color_override("font_color", Color("38bdf8"))
	practice_hdr_box.add_child(practice_heading)
	menu_mode_buttons.clear()
	_add_mode_button(menu_column, "10 QUESTIONS", "Quick warm-up drill • 30 minutes timed", _start_quiz.bind(10, _practice_time(10), true, "10-Question Practice"), "38bdf8", "111928", false, 76.0, 15)
	_add_mode_button(menu_column, "20 QUESTIONS", "Standard focused session • 60 minutes timed", _start_quiz.bind(20, _practice_time(20), true, "20-Question Practice"), "38bdf8", "111928", false, 76.0, 15)
	_add_mode_button(menu_column, "30 QUESTIONS", "Extended study block • 90 minutes timed", _start_quiz.bind(30, _practice_time(30), true, "30-Question Practice"), "38bdf8", "111928", false, 76.0, 15)
	_add_mode_button(menu_column, "40 QUESTIONS", "Half-length diagnostic test • 120 minutes timed", _start_quiz.bind(40, _practice_time(40), true, "40-Question Practice"), "38bdf8", "111928", false, 76.0, 15)
	_add_mode_button(menu_column, "50 QUESTIONS", "Intensive endurance drill • 150 minutes timed", _start_quiz.bind(50, _practice_time(50), true, "50-Question Practice"), "38bdf8", "111928", false, 76.0, 15)
	var exam_hdr_box := HBoxContainer.new()
	exam_hdr_box.add_theme_constant_override("separation", 8)
	menu_column.add_child(exam_hdr_box)
	var exam_bar := ColorRect.new()
	exam_bar.custom_minimum_size = Vector2(4, 16)
	exam_bar.color = Color("f43f5e")
	exam_hdr_box.add_child(exam_bar)
	var exam_heading := Label.new()
	exam_heading.text = "OFFICIAL LICENSING SIMULATION"
	exam_heading.add_theme_font_override("font", _ui_font(700))
	exam_heading.add_theme_font_size_override("font_size", 12)
	exam_heading.add_theme_color_override("font_color", Color("f43f5e"))
	exam_hdr_box.add_child(exam_heading)
	_add_mode_button(menu_column, "FULL JOURNEYMAN SIMULATOR", "80 scored questions • 240 minutes • 75% required to pass", _start_quiz.bind(80, EXAM_MINUTES * 60, true, "Full Journeyman Exam"), "f43f5e", "1e141d", true, 84.0, 15)

	var menu_note := Label.new()
	menu_note.text = "Aligned with NFPA 70 (NEC 2023) & Nebraska State Electrical Division / PSI Standards\nPacing standard: 3:00 per scored item • 80 questions timed"
	menu_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_note.add_theme_font_override("font", _ui_font(400))
	menu_note.add_theme_font_size_override("font_size", 11)
	menu_note.add_theme_color_override("font_color", Color("64748b"))
	menu_column.add_child(menu_note)

func _add_mode_button(parent: VBoxContainer, title_text: String, subtitle_text: String, callback: Callable, accent_hex: String = "38bdf8", bg_hex: String = "111928", is_major: bool = false, min_height: float = -1.0, font_size: int = -1) -> void:
	var button := Button.new()
	button.text = title_text + "\n" + subtitle_text
	button.custom_minimum_size = Vector2(0, min_height if min_height > 0.0 else (68.0 if is_major else 62.0))
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_override("font", _ui_font(600))
	button.add_theme_font_size_override("font_size", font_size if font_size > 0 else 14)

	var btn_norm := _panel_style(bg_hex, "2e3d57", 1, 10)
	btn_norm.border_width_left = 6
	btn_norm.border_color = Color(accent_hex)
	btn_norm.content_margin_left = 20
	btn_norm.content_margin_right = 16
	btn_norm.content_margin_top = 10
	btn_norm.content_margin_bottom = 10

	var btn_hov := _panel_style("182438" if not is_major else "2e151e", accent_hex, 2, 10)
	btn_hov.border_width_left = 8
	btn_hov.content_margin_left = 22
	btn_hov.content_margin_right = 16
	btn_hov.content_margin_top = 10
	btn_hov.content_margin_bottom = 10

	var btn_pressed := _panel_style(bg_hex, accent_hex, 2, 10)
	btn_pressed.border_width_left = 6
	btn_pressed.content_margin_left = 20
	btn_pressed.content_margin_right = 16

	button.add_theme_stylebox_override("normal", btn_norm)
	button.add_theme_stylebox_override("hover", btn_hov)
	button.add_theme_stylebox_override("pressed", btn_pressed)
	button.add_theme_stylebox_override("focus", btn_hov)
	button.add_theme_color_override("font_color", Color("ffffff"))
	button.add_theme_color_override("font_hover_color", Color("ffffff"))

	# Tactile hover animation: gentle slide on X
	button.mouse_entered.connect(func():
		var tw := button.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(button, "position:x", 5.0, 0.12).as_relative()
	)
	button.mouse_exited.connect(func():
		var tw := button.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(button, "position:x", -5.0, 0.12).as_relative()
	)

	button.pressed.connect(callback)
	parent.add_child(button)
	menu_mode_buttons.append(button)


func _practice_time(question_count: int) -> int:
	return question_count * SECONDS_PER_SCORED_ITEM

func _show_menu() -> void:
	timer.stop()
	_stop_reading()
	if menu_overlay:
		menu_overlay.visible = true
		menu_overlay.modulate.a = 0.0
		var ov_tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		ov_tw.tween_property(menu_overlay, "modulate:a", 1.0, 0.2)

		if menu_panel:
			menu_panel.pivot_offset = menu_panel.size / 2.0
			menu_panel.scale = Vector2(0.96, 0.96)
			var p_tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			p_tw.tween_property(menu_panel, "scale", Vector2.ONE, 0.24)

		# Staggered entrance for mode buttons
		for i in menu_mode_buttons.size():
			var btn := menu_mode_buttons[i]
			if is_instance_valid(btn):
				btn.modulate.a = 0.0
				btn.scale = Vector2(0.97, 0.97)
				var b_tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				b_tw.tween_interval(0.04 * float(i))
				b_tw.parallel().tween_property(btn, "modulate:a", 1.0, 0.18)
				b_tw.parallel().tween_property(btn, "scale", Vector2.ONE, 0.22)

func _panel_style(fill: String, border: String, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(fill)
	style.border_color = Color(border)
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style

func _ui_font(weight: int = 500) -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Segoe UI", "SF Pro Display", "Inter", "Roboto", "Helvetica Neue", "Arial", "sans-serif"])
	font.font_weight = weight
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	return font

func _monospace_font() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])
	return font

func _populate_reference_table(grid: GridContainer, note_label: Label, rows: Array, highlight_answer: String = "", is_feedback: bool = true, target_keyword: String = "") -> bool:
	var res := TableViewer.populate_table(grid, note_label, rows, highlight_answer, is_feedback, target_keyword)
	# Only the FEEDBACK table scrolls to a match; the pre-answer table is opened
	# at the top instead, so its match state was written but never read.
	if is_feedback:
		feedback_table_match_row = int(res.get("matched_row", -1))
		feedback_table_row_count = int(res.get("row_count", 0))
	return bool(res.get("highlighted", false))

func _scroll_feedback_table_to_match() -> void:
	TableViewer.scroll_to_row(feedback_table_scroll, feedback_table_grid, feedback_table_match_row, feedback_table_row_count)

func _scroll_question_table_to_top() -> void:
	if not is_instance_valid(question_table_scroll):
		return
	var bar := question_table_scroll.get_v_scroll_bar()
	if bar != null:
		bar.value = 0.0

func _is_reference_seeking(prompt: String) -> bool:
	# True when the question asks for the reference itself ("Table ___ lists...",
	# "which article..."). Those prompts get redacted lookup aids pre-answer.
	var lowered := prompt.to_lower()
	if not lowered.contains("___"):
		return false
	return lowered.contains("table") or lowered.contains("article") or lowered.contains("section")

func _chapter_only_path(full_path: String) -> String:
	# "NEC 2023  ►  Chapter 3: ...  ►  Article 300 (...)" -> drops the article segment.
	var parts := full_path.split("►", false)
	if parts.size() >= 3:
		return parts[0].strip_edges() + "  ►  " + parts[1].strip_edges()
	return full_path

func _extract_table_target_keyword(record: Dictionary, table: Array) -> String:
	return TableViewer.extract_target_keyword(record, table)

func _table_preview_layout(rows: Array, max_scroll_height: float = 220.0) -> Dictionary:
	return TableViewer.preview_layout(rows, max_scroll_height)


func _show_question() -> void:
	if order.is_empty():
		return
	var record: Dictionary = records[order[current_index]]
	current_answered = false
	_stop_reading()
	question_time_left = SECONDS_PER_SCORED_ITEM
	question_label.text = str(record.get("prompt", "Question unavailable"))
	question_panel.modulate.a = 0.0
	question_panel.position.x = 10.0
	var q_tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	q_tw.parallel().tween_property(question_panel, "modulate:a", 1.0, 0.22)
	q_tw.parallel().tween_property(question_panel, "position:x", 0.0, 0.22)
	var correct_idx := int(record.get("correct_index", -1))
	var answers: Array = record.get("answers", [])
	var current_correct_text: String = str(answers[correct_idx]) if correct_idx >= 0 and correct_idx < answers.size() else ""
	var question_table = record.get("reference_table", [])
	question_table_panel.visible = question_table is Array and not question_table.is_empty()
	if question_table_panel.visible:
		var table_layout := _table_preview_layout(question_table)
		question_table_scroll.custom_minimum_size.y = float(table_layout["scroll_height"])
		question_table_panel.custom_minimum_size.y = float(table_layout["panel_height"])
		var reference_lines := str(record.get("reference_text", "")).split("\n", false)
		var table_title := reference_lines[0] if not reference_lines.is_empty() else str(record.get("article", "Reference table"))
		# The title often IS the answer ("Table ___ lists..." + title "Table 300.5(A)...").
		# Redact it pre-answer; blanked cells already hide in-table answers.
		table_title = AudioExplanationGenerator.redact_answer_spans(table_title, current_correct_text)
		if table_title.strip_edges() == "" or table_title.strip_edges() == "___":
			table_title = "REFERENCE TABLE"
		question_table_heading.text = "LOOK UP BEFORE ANSWERING  •  " + table_title
		_populate_reference_table(question_table_grid, question_table_note, question_table, current_correct_text, false, "")
		# Open the "book" at the top like a real lookup — never auto-scroll to the
		# blanked answer cell pre-answer. (Post-answer feedback still jumps to the match.)
		call_deferred("_scroll_question_table_to_top")
	var diagram := str(record.get("diagram", "")).strip_edges()
	question_diagram_panel.visible = diagram != ""
	if question_diagram_panel.visible:
		question_diagram_label.text = diagram
	var formula_str := str(record.get("formula", "")).strip_edges()
	if formula_str != "":
		# The formula box shows pre-answer: keep the method, blank a computed answer value.
		question_formula_label.text = "FORMULA / METHOD:  " + AudioExplanationGenerator.redact_answer_spans(formula_str, current_correct_text)
		question_formula_label.visible = true
	else:
		question_formula_label.visible = false
	exam_label.text = "%s  |  %s  |  AVG %s / ITEM" % [session_name.to_upper(), EXAM_NAME, _format_time(SECONDS_PER_SCORED_ITEM)]
	if is_instance_valid(exam_mode_pill):
		exam_mode_pill.text = session_name.to_upper()
	if is_instance_valid(exam_license_pill):
		exam_license_pill.text = EXAM_NAME
	if is_instance_valid(exam_pace_pill):
		exam_pace_pill.text = "PACE " + _format_time(SECONDS_PER_SCORED_ITEM)
	# Pre-answer subtitle: the gist first; when empty, the info_tip's task-framing
	# paragraph ("This asks...", never answer-bearing). Tips must NEVER stand in
	# here — they name the answer ("Correct: B — ...") and blanking can hide the
	# value but not the letter. Truly nothing to show means no subtitle row at all.
	var gist := str(record.get("gist", "")).strip_edges()
	if gist == "":
		gist = _gist_task_sentence(record)
	if gist != "" and current_correct_text != "":
		# Blank EVERY mention: tips now name the answer (possibly twice), and the gist
		# fallback would otherwise leak the second occurrence pre-answer.
		var blank_guard := 0
		while blank_guard < 8:
			var match_info := AudioExplanationGenerator.find_match_in(gist, current_correct_text)
			if match_info.is_empty():
				break
			var m_start := int(match_info["start"])
			var m_len := int(match_info["length"])
			gist = gist.substr(0, m_start) + "[ ___ ]" + gist.substr(m_start + m_len)
			blank_guard += 1
	article_label.text = gist
	article_label.visible = gist != ""
	if is_instance_valid(question_hint_row):
		question_hint_row.visible = gist != ""
	if _is_reference_seeking(str(record.get("prompt", ""))):
		# The stem asks WHICH table/article holds the rule — printing the article
		# hands over the answer, so pre-answer navigation stops at chapter level.
		chapter_hint_label.text = _chapter_only_path(_lookup_navigation_path(record))
	else:
		chapter_hint_label.text = AudioExplanationGenerator.redact_answer_spans(_lookup_navigation_path(record), current_correct_text)
	chapter_hint_label.visible = chapter_hint_label.text != ""
	progress_label.text = "QUESTION %02d OF %02d" % [current_index + 1, order.size()]
	_update_score_badges()
	timer_label.text = "EXAM TIME: " + _format_time(time_left) if timed_session else "UNTIMED"
	question_timer_label.text = "PACE: " + _format_time(question_time_left) if timed_session else ""
	timer_label.add_theme_color_override("font_color", Color("f8fafc"))
	timer_bar.visible = timed_session
	if timed_session:
		timer_bar.max_value = session_time_limit
		timer_bar.value = time_left
	timer_bar.modulate = Color("38bdf8")

	for child in answers_box.get_children():
		child.queue_free()
	for i in answers.size():
		var card := AnswerCard.new()
		card.set_card_data(i, str(answers[i]))
		card.card_clicked.connect(_answer_selected)
		answers_box.add_child(card)
		card.animate_entrance(float(i) * 0.04)

	feedback_panel.visible = false
	feedback_reference.visible = false
	feedback_table_scroll.visible = false
	feedback_table_note.visible = false
	next_button.visible = false
	info_label.visible = false
	next_button.text = "Next question" if current_index < order.size() - 1 else "Finish quiz"

func _gist_task_sentence(record: Dictionary) -> String:
	# info_tip layout: "WHAT THIS QUESTION MEANS / BACKGROUND / {background} //
	# {task framing} // LOOKUP FOCUS / ...". The middle paragraph explains what the
	# question asks without naming answers — safe pre-answer subtitle fallback.
	var info := str(record.get("info_tip", ""))
	if info == "":
		return ""
	var chunks := info.split("\n\n", false)
	if chunks.size() < 3:
		return ""
	var task := chunks[1].strip_edges()
	if task == "" or task.to_upper().begins_with("LOOKUP FOCUS"):
		return ""
	if not chunks[2].strip_edges().to_upper().begins_with("LOOKUP FOCUS"):
		return ""
	return task

func _answer_selected(selected: int) -> void:
	if current_answered:
		return
	current_answered = true
	if ui_mobile:
		Input.vibrate_handheld(30)
	var record_index: int = order[current_index]
	var record: Dictionary = records[record_index]
	answered_count += 1
	var correct := int(record.get("correct_index", -1))
	var answers: Array = record.get("answers", [])
	var correct_text: String = str(answers[correct]) if correct >= 0 and correct < answers.size() else ANSWER_LETTERS[correct]
	var selected_text: String = str(answers[selected]) if selected >= 0 and selected < answers.size() else "No answer"
	var cards := answers_box.get_children()
	for i in cards.size():
		var card = cards[i]
		if i == correct:
			card.set_state(AnswerCard.State.CORRECT)
		elif i == selected:
			card.set_state(AnswerCard.State.WRONG)
		else:
			card.set_eliminated()

	if selected == -1:
		streak = 0
		feedback_title.text = "Time expired"
		feedback_title.add_theme_color_override("font_color", Color("f87171"))
		feedback_body.text = "Correct answer: %s — %s" % [ANSWER_LETTERS[correct], correct_text]
		feedback_body.visible = true
		missed_questions.append({
			"index": current_index + 1,
			"prompt": str(record.get("prompt", "")),
			"selected": "Time expired",
			"correct": "%s — %s" % [ANSWER_LETTERS[correct], correct_text],
			"article": str(record.get("article", "General")),
			"article_title": str(record.get("article_title", "")),
			"tip_short": str(record.get("tip_short", record.get("gist", "")))
		})
	elif selected == correct:
		score += 1
		streak += 1
		feedback_title.text = "Correct"
		# The green card already shows the pick — a text echo of it is clutter.
		feedback_body.text = ""
		feedback_body.visible = false
		feedback_title.add_theme_color_override("font_color", Color("34d399"))
	else:
		streak = 0
		feedback_title.text = "Not quite"
		feedback_title.add_theme_color_override("font_color", Color("f87171"))
		# One verdict line: your pick is already red on its card, no need to restate it.
		feedback_body.text = "Correct answer: %s — %s" % [ANSWER_LETTERS[correct], correct_text]
		feedback_body.visible = true
		missed_questions.append({
			"index": current_index + 1,
			"prompt": str(record.get("prompt", "")),
			"selected": "%s — %s" % [ANSWER_LETTERS[selected], selected_text],
			"correct": "%s — %s" % [ANSWER_LETTERS[correct], correct_text],
			"article": str(record.get("article", "General")),
			"article_title": str(record.get("article_title", "")),
			"tip_short": str(record.get("tip_short", record.get("gist", "")))
		})
	feedback_panel.visible = true
	feedback_panel.modulate.a = 0.0
	feedback_panel.pivot_offset = feedback_panel.size / 2.0
	feedback_panel.scale = Vector2(0.98, 0.98)
	var fb_tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	fb_tw.parallel().tween_property(feedback_panel, "modulate:a", 1.0, 0.16)
	fb_tw.parallel().tween_property(feedback_panel, "scale", Vector2.ONE, 0.2)

	question_table_panel.visible = false
	question_diagram_panel.visible = false
	question_formula_label.visible = false
	feedback_table_scroll.visible = false
	feedback_table_note.visible = false
	next_button.visible = true
	next_button.modulate.a = 0.0
	next_button.scale = Vector2(0.96, 0.96)
	next_button.pivot_offset = next_button.size / 2.0
	var nb_tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	nb_tw.parallel().tween_property(next_button, "modulate:a", 1.0, 0.18)
	nb_tw.parallel().tween_property(next_button, "scale", Vector2.ONE, 0.22)
	feedback_reference.text = _format_nec_reference(record)
	feedback_reference.visible = true
	var table = record.get("reference_table", [])
	feedback_table_note.visible = false
	feedback_table_scroll.visible = table is Array and not table.is_empty()
	var table_highlighted := false
	if feedback_table_scroll.visible:
		var table_layout := _table_preview_layout(table, 190.0)
		feedback_table_scroll.custom_minimum_size.y = float(table_layout["scroll_height"])
		var target_kw := _extract_table_target_keyword(record, table)
		table_highlighted = _populate_reference_table(feedback_table_grid, feedback_table_note, table, correct_text, true, target_kw)
		call_deferred("_scroll_feedback_table_to_match")
	_render_code_provision(record, correct_text, table_highlighted)
	info_label.visible = true
	# Audio is strictly button-initiated: answering stops any readout in progress and
	# never starts new audio by itself (no autoplay on answer, even if Read was never
	# pressed). The learner presses "Hear the rule" to hear the lesson, which also
	# saves Edge-TTS quota for audio nobody asked for.
	_stop_reading()
	want_teach = true
	question_timer_label.text = "ITEM COMPLETED"
	_update_score_badges()


func _update_score_badges() -> void:
	if answered_count == 0:
		score_label.text = "TARGET: 75%"
		score_label.add_theme_color_override("font_color", Color("6ee7b7"))
		if is_instance_valid(pass_badge):
			pass_badge.add_theme_stylebox_override("panel", _panel_style("0f291e", "059669", 1, 8))
		streak_label.text = "0 / %d ITEMS" % session_length
		streak_label.add_theme_color_override("font_color", Color("7dd3fc"))
		return

	var pct: float = (float(score) / float(answered_count)) * 100.0
	var pct_int: int = roundi(pct)
	streak_label.text = "%d/%d (%d%%)" % [score, answered_count, pct_int]

	if pct >= 75.0:
		score_label.text = "PASSING: " + str(pct_int) + "%"
		score_label.add_theme_color_override("font_color", Color("6ee7b7"))
		if is_instance_valid(pass_badge):
			pass_badge.add_theme_stylebox_override("panel", _panel_style("0f291e", "059669", 1, 8))
		streak_label.add_theme_color_override("font_color", Color("34d399"))
	elif pct >= 60.0:
		score_label.text = "AT RISK: " + str(pct_int) + "%"
		score_label.add_theme_color_override("font_color", Color("fde047"))
		if is_instance_valid(pass_badge):
			pass_badge.add_theme_stylebox_override("panel", _panel_style("241d08", "a16207", 1, 8))
		streak_label.add_theme_color_override("font_color", Color("fde047"))
	else:
		score_label.text = "BELOW 75%: " + str(pct_int) + "%"
		score_label.add_theme_color_override("font_color", Color("fda4af"))
		if is_instance_valid(pass_badge):
			pass_badge.add_theme_stylebox_override("panel", _panel_style("260c14", "9f1239", 1, 8))
		streak_label.add_theme_color_override("font_color", Color("fda4af"))


func _append_answer_highlight(text: String, answer: String) -> bool:
	var match_info := SpeechText.find_answer_match(text, answer)
	if match_info.is_empty():
		info_label.add_text(text)
		return false
	var start := int(match_info["start"])
	var match_length := int(match_info["length"])
	info_label.add_text(text.substr(0, start))
	info_label.push_bgcolor(Color("047857"))
	info_label.push_color(Color("ffffff"))
	info_label.push_bold()
	info_label.add_text(" " + text.substr(start, match_length) + " ")
	info_label.pop()
	info_label.pop()
	info_label.pop()
	info_label.add_text(text.substr(start + match_length))
	return true

func _echoes_any(line: String, others: Array) -> bool:
	# True when line adds nothing over already-displayed text (declutter filter).
	for other in others:
		var o := str(other).strip_edges()
		if o != "" and AudioExplanationGenerator._is_duplicate_text(line, o):
			return true
	return false

func _append_provision_heading(text: String, heading_color: String = "7dd3fc") -> void:
	info_label.push_color(Color(heading_color))
	info_label.push_bold()
	info_label.add_text(text)
	info_label.pop()
	info_label.pop()

func _render_code_provision(record: Dictionary, correct_answer: String, table_answer_highlighted: bool) -> void:
	# Store state so we can re-render with teach-line highlights during TTS
	_current_record = record
	_current_correct_answer = correct_answer
	_info_table_highlighted = table_answer_highlighted
	_active_teach_line = -1
	_do_render_info_label()

func _do_render_info_label() -> void:
	var record := _current_record
	var correct_answer := _current_correct_answer
	var table_answer_highlighted := _info_table_highlighted
	info_label.clear()
	var highlighted := table_answer_highlighted

	# Shared texts, read once: display filtering compares lesson lines against all of
	# these so no sentence prints twice on one screen.
	var source_text := str(record.get("reference_text", ""))
	var worked_text := str(record.get("worked", ""))
	var formula_text := str(record.get("formula", "")).strip_edges()
	var gist_text := str(record.get("gist", "")).strip_edges()

	# --- MEMORY TIP section (plain-English mnemonic, folded to two lines) ---
	# Skipped when it merely requotes the gist or the provision — generic echoes stay out.
	var tip := str(record.get("tip_short", "")).strip_edges()
	var tip_title := str(record.get("tip_title", "")).strip_edges()
	if tip == "":
		tip = str(record.get("info_tip", "")).strip_edges()
	if tip != "" and not _echoes_any(tip, [source_text, gist_text]):
		if tip_title != "":
			_append_provision_heading("MEMORY TIP — " + tip_title + "\n", "f59e0b")
		else:
			_append_provision_heading("MEMORY TIP\n", "f59e0b")
		info_label.add_text(tip)
		info_label.add_text("\n\n")

	# --- CODE PROVISION section (NEC statutory text) ---
	_append_provision_heading("CODE PROVISION\n", "34d399")
	if source_text != "":
		var heading_end := source_text.find("\n")
		if heading_end >= 0:
			info_label.push_color(Color("93c5fd"))
			info_label.push_bold()
			info_label.add_text(source_text.substr(0, heading_end + 1))
			info_label.pop()
			info_label.pop()
			var body := source_text.substr(heading_end + 1)
			highlighted = _append_answer_highlight(body, correct_answer) or highlighted
		else:
			highlighted = _append_answer_highlight(source_text, correct_answer) or highlighted
	else:
		info_label.add_text("No source excerpt has been added yet. Use the NEC reference above to review the provision.")

	# --- WHAT THE CODE SAYS (lesson lines with active-line highlight during TTS) ---
	# Same shared list the voice speaks (lesson_lines index == teach index), but the
	# panel skips anything already on screen: the "Answer D, ..." callout restates the
	# verdict line above, and rule/math lines that requote CODE PROVISION / WORKED /
	# FORMULA / TIP would print the same sentence twice. Skipped lines keep their
	# original li so the spoken highlight index still lands on the right line, and an
	# empty section is omitted entirely instead of echoing.
	var shared_lesson := AudioExplanationGenerator.lesson_lines(record, correct_answer)
	var lesson_echo_basis: Array = [correct_answer, source_text, worked_text, formula_text, gist_text]
	if tip != "":
		lesson_echo_basis.append(tip)
	var render_lesson: Array = []
	for li in shared_lesson.size():
		var ln := str(shared_lesson[li]).strip_edges()
		if ln == "" or _echoes_any(ln, lesson_echo_basis):
			continue
		render_lesson.append([li, ln])
	if not render_lesson.is_empty():
		info_label.add_text("\n\n")
		_append_provision_heading("WHAT THE CODE SAYS\n", "38bdf8")
		var first_row := true
		for pair in render_lesson:
			var li: int = pair[0]
			var ln: String = pair[1]
			if li == _active_teach_line:
				# Amber highlight on the currently-spoken line
				if not first_row:
					info_label.add_text("\n")
				info_label.push_bgcolor(Color("854d0e"))
				info_label.push_color(Color("fef3c7"))
				info_label.push_bold()
				info_label.add_text(" ▶  " + ln + " ")
				info_label.pop()
				info_label.pop()
				info_label.pop()
			else:
				if not first_row:
					info_label.add_text("\n")
				if _active_teach_line >= 0:
					info_label.push_color(Color(0.55, 0.60, 0.68, 1.0))
					highlighted = _append_answer_highlight(ln, correct_answer) or highlighted
					info_label.pop()
				else:
					highlighted = _append_answer_highlight(ln, correct_answer) or highlighted
			first_row = false

	# --- Optional extra sections (texts hoisted above for echo filtering) ---
	var worked := worked_text
	var formula := formula_text
	if worked != "":
		info_label.add_text("\n\n")
		_append_provision_heading("WORKED SOLUTION\n", "fde047")
		highlighted = _append_answer_highlight(worked, correct_answer) or highlighted
	elif formula != "":
		info_label.add_text("\n\n")
		_append_provision_heading("METHOD & FORMULA\n", "c084fc")
		highlighted = _append_answer_highlight(formula, correct_answer) or highlighted
	var diagram := str(record.get("diagram", "")).strip_edges()
	if diagram != "":
		info_label.add_text("\n\n")
		_append_provision_heading("DIAGRAM\n", "67e8f9")
		info_label.add_text(diagram)
	if not highlighted and correct_answer != "":
		info_label.add_text("\n\n")
		_append_provision_heading("ANSWER DETAIL\n", "34d399")
		_append_answer_highlight(correct_answer, correct_answer)
func _load_voice_catalog() -> void:
	voice_ids.clear()
	var file := FileAccess.open("res://voices.json", FileAccess.READ)
	if file == null:
		voice_ids["Aria · US · Female"] = "en-US-AriaNeural"
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Array:
		for row in parsed:
			if row is Dictionary:
				voice_ids[str(row.get("label", ""))] = str(row.get("id", ""))

func _populate_voice_picker() -> void:
	# Desktop: cloud voices from voices.json. Mobile: REAL on-device voices —
	# the old code showed cloud voices on Android while silently speaking OS
	# voice #1 no matter what was picked.
	voice_picker.clear()
	if ui_mobile or not OS.has_feature("pc"):
		_populate_voice_picker_native()
	else:
		var aria_idx := 0
		for voice_name in voice_ids:
			if str(voice_ids[voice_name]) == "en-US-AriaNeural":
				aria_idx = voice_picker.item_count
			voice_picker.add_item(voice_name)
		voice_picker.selected = aria_idx
	if not voice_picker.item_selected.is_connected(_on_voice_picked):
		voice_picker.item_selected.connect(_on_voice_picked)
	var popup: PopupMenu = voice_picker.get_popup()
	if popup != null and not popup.about_to_popup.is_connected(_refresh_native_voices):
		popup.about_to_popup.connect(_refresh_native_voices)
	_load_voice_choice()

func _refresh_native_voices() -> void:
	# OS voice lists can load late on Android, so rebuild until real OS voices
	# actually appear. The old guard counted PICKER ITEMS, and the picker was
	# always seeded with the bundled Aria entry plus "System default" - so
	# item_count was already 2 and this returned early forever, leaving a cloud
	# Edge voice id selectable that the Android TTS engine does not know.
	# Gate on the OS list instead, and only rebuild when the list is non-empty.
	if not ui_mobile and OS.has_feature("pc"):
		return
	if voice_picker == null:
		return
	if not DisplayServer.has_method("tts_get_voices"):
		return
	if DisplayServer.tts_get_voices().is_empty():
		return  # still nothing to show; try again on the next tick
	_populate_voice_picker_native()
	_load_voice_choice()

func _on_voice_picked(_index: int) -> void:
	_save_voice_choice()

func _native_voice_tier(info: Dictionary) -> int:
	# 0 = US English (the only tier we list), 1 = other English, 2 = rest.
	var vlang := str(info.get("language", "")).strip_edges().to_lower().replace("_", "-")
	var vname := str(info.get("name", "")).strip_edges().to_lower()
	if vlang.begins_with("en-us"):
		return 0
	if vlang == "" and ("en-us" in vname or "en_us" in vname or "english (united states)" in vname):
		return 0
	if vlang.begins_with("en"):
		return 1
	if vlang == "" and "english" in vname:
		return 1
	return 2

func _pretty_voice_lang(vlang: String, vname: String) -> String:
	# Human-readable language tag so every entry says WHO it is ("Voice 3" tells
	# nothing; "Voice 3 · English (US)" does).
	var t := vlang.strip_edges().replace("_", "-")
	if t == "":
		var ln := vname.to_lower()
		if "en-us" in ln or "en_us" in ln or "united states" in ln:
			return "English (US)"
		return ""
	var low := t.to_lower()
	var names := {"en": "English", "es": "Spanish", "fr": "French", "de": "German",
		"it": "Italian", "pt": "Portuguese", "hi": "Hindi", "ru": "Russian",
		"ar": "Arabic", "zh": "Chinese", "ja": "Japanese", "ko": "Korean",
		"nl": "Dutch", "pl": "Polish", "tr": "Turkish", "uk": "Ukrainian"}
	var parts := low.split("-")
	var base: String = names.get(parts[0], parts[0].to_upper() if parts[0].length() <= 3 else parts[0])
	if parts.size() > 1 and parts[1] != "":
		return "%s (%s)" % [base, parts[1].to_upper()]
	return base

func _voice_display_label(vname: String, vlang: String, _vid: String) -> String:
	var label := vname.strip_edges()
	if label == "":
		label = _vid
	var tag := _pretty_voice_lang(vlang, vname)
	if tag != "" and not label.to_lower().contains(tag.to_lower()):
		label = "%s · %s" % [label, tag]
	return label

func _voice_short() -> String:
	# Compact speaker name for the status line ("who is speaking").
	if not is_instance_valid(voice_picker) or voice_picker.item_count <= 0:
		return ""
	var label := voice_picker.get_item_text(voice_picker.selected)
	var cut := label.find(" (")
	if cut < 0:
		cut = label.find(" [")
	if cut < 0:
		cut = label.find(" · ")
	if cut > 0:
		label = label.substr(0, cut)
	label = label.strip_edges()
	if label.length() > 22:
		label = label.substr(0, 22).strip_edges()
	return label

func _status_with_voice(base: String) -> String:
	var who := _voice_short()
	return base + (" · " + who if who != "" else "")

func _populate_voice_picker_native() -> void:
	# US-English-only list (mirrors the curated desktop picker): collect tiers,
	# show the best non-empty tier so the list is never empty.
	voice_ids.clear()
	# Clear here, not only in the caller: _refresh_native_voices can run more than
	# once (timer + about_to_popup) and a bare add_item loop duplicated every
	# entry on the second pass.
	voice_picker.clear()
	var tiers: Array = [[], [], []]
	if DisplayServer.has_method("tts_get_voices"):
		for info in DisplayServer.tts_get_voices():
			if not info is Dictionary:
				continue
			var vid := str(info.get("id", ""))
			if vid == "":
				continue
			var vname := str(info.get("name", vid))
			var vlang := str(info.get("language", ""))
			if vname == "":
				vname = vid
			tiers[_native_voice_tier(info)].append([vname, vlang, vid])
	var chosen: Array = tiers[0] if not tiers[0].is_empty() else (tiers[1] if not tiers[1].is_empty() else tiers[2])
	var seen := {}
	for pair in chosen:
		var label := _voice_display_label(str(pair[0]), str(pair[1]), str(pair[2]))
		if seen.has(label):
			label = "%s [%s]" % [label, str(pair[2])]
		seen[label] = true
		voice_ids[label] = str(pair[2])
	if chosen.is_empty():
		voice_ids["System default"] = ""
	if voice_ids.is_empty():
		voice_picker.add_item("System default")
		voice_ids["System default"] = ""
	else:
		for label in voice_ids:
			voice_picker.add_item(label)
	voice_picker.selected = 0

func _selected_voice_id() -> String:
	var label := voice_picker.get_item_text(voice_picker.selected)
	var voice_id := str(voice_ids.get(label, ""))
	return voice_id.replace("Multilingual", "")

func _load_voice_choice() -> void:
	var config := ConfigFile.new()
	if config.load("user://voice.cfg") != OK:
		return
	var saved := str(config.get_value("speech", "voice", "en-US-AriaNeural"))
	for i in voice_picker.item_count:
		if str(voice_ids.get(voice_picker.get_item_text(i), "")) == saved:
			voice_picker.selected = i
			return

func _save_voice_choice() -> void:
	var config := ConfigFile.new()
	config.set_value("speech", "voice", _selected_voice_id())
	config.save("user://voice.cfg")

func _stop_reading() -> void:
	speak_generation += 1
	speak_busy = false
	_native_seg = -1
	want_teach = false
	teach_from_index = -1
	speech_queue.clear()
	speech_queue_index = 0
	_halt_player()
	# Unconditional: an utterance queued but not yet started reads is_speaking=false
	# and would otherwise play on as ghost audio after Stop.
	DisplayServer.tts_stop()
	_clear_speech_highlight()
	if is_instance_valid(dock_visualizer):
		dock_visualizer.visible = false
		dock_visualizer.set_active(false)
	if read_button:
		read_button.text = "Hear the rule" if current_answered else "Read question"
		read_button.disabled = false

func _toggle_read() -> void:
	if reader.playing or speak_busy or DisplayServer.tts_is_speaking():
		_stop_reading()
		return
	if order.is_empty() or menu_overlay.visible:
		return
	var record: Dictionary = records[order[current_index]]
	if current_answered:
		# "Hear the rule" must replay ONLY the learn part, never the Q + choices again.
		# Old code fell through to a full speech_plan on the native path
		# (teach_from_index stays -1 there), re-reading the whole question.
		want_teach = true
		if teach_from_index >= 0:
			_jump_to_teach()
			return
		_begin_reading(SpeechText.teach_segments(record))
		return
	var segments: Array = SpeechText.speech_plan(record)
	_begin_reading(segments)

const BUNDLED_VOICE_ID := "en-US-AriaNeural"

func _bundled_speech_folder(safe_qid: String, voice_id: String, segments: Array) -> String:
	# Pre-generated Aria clips shipped inside the app (tools/pregenerate_speech.py).
	# Same neural voice as desktop, zero network, zero quota, exact clip sync.
	# The manifest comparison guarantees the bundle matches the CURRENT speech plan;
	# a stale bundle simply misses and falls through to live synthesis.
	if voice_id != BUNDLED_VOICE_ID or safe_qid == "":
		return ""
	var folder := "res://speech".path_join(safe_qid + "__" + voice_id)
	if _speech_cache_matches(folder, segments):
		return folder
	# A teach-only request ("Hear the rule") is a contiguous TAIL of the bundled
	# full plan, so it must be matched against that tail rather than the whole
	# manifest. Without this, every "Hear the rule" tap missed the bundle and
	# re-synthesised over the network, defeating the offline/zero-quota design.
	var tail_index := _bundled_teach_tail_offset(folder, segments)
	if tail_index > 0:
		return folder
	return ""

func _bundled_teach_tail_offset(folder: String, segments: Array) -> int:
	# Returns the manifest index at which `segments` starts, or 0 when the
	# requested clips are not a suffix of the bundle. Every requested segment
	# must be a teach clip, and each must match the manifest row at that offset
	# on text, choice and teach flag.
	if segments.is_empty():
		return 0
	var manifest_path := folder.path_join("manifest.json")
	if not FileAccess.file_exists(manifest_path):
		return 0
	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		return 0
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Array or parsed.is_empty():
		return 0
	for seg in segments:
		if not seg is Dictionary or not bool(seg.get("teach", false)):
			return 0
	var start: int = parsed.size() - segments.size()
	if start <= 0:
		return 0
	for i in segments.size():
		var row = parsed[start + i]
		if not row is Dictionary:
			return 0
		if str(row.get("text", "")) != str(segments[i].get("text", "")):
			return 0
		if int(row.get("choice", -1)) != int(segments[i].get("choice", -1)):
			return 0
		if bool(row.get("teach", false)) != bool(segments[i].get("teach", false)):
			return 0
		var clip := FileAccess.open(folder.path_join(str(row.get("file", ""))), FileAccess.READ)
		if clip == null or clip.get_length() == 0:
			if clip != null:
				clip.close()
			return 0
		clip.close()
	return start

func _begin_reading(segments: Array) -> void:
	if segments.is_empty() or menu_overlay.visible:
		return

	var question_id := ""
	if not order.is_empty() and current_index >= 0 and current_index < order.size():
		question_id = str(records[order[current_index]].get("id", ""))
	var safe_qid := question_id.replace("/", "_").replace("\\", "_")
	if safe_qid == "":
		safe_qid = "item"
	var mobile := OS.get_name() == "Android" or not OS.has_feature("pc")
	var wanted_voice := _pick_native_voice() if mobile else _selected_voice_id()
	var bundle := _bundled_speech_folder(safe_qid, wanted_voice, segments)
	if bundle != "":
		speak_generation += 1
		read_button.text = "Stop"
		read_button.disabled = false
		# Start where the requested clips actually begin: a teach-only request
		# matched a SUFFIX of the manifest, so index 0 would replay the question
		# stem and all four choices instead of the lesson.
		var start_index := 0
		if want_teach:
			start_index = _bundled_teach_tail_offset(bundle, segments)
		_on_speech_ready(speak_generation, bundle, 0, "bundle", start_index)
		return
	# On Android or mobile platforms without python runtime, use native OS TTS engine!
	if mobile:
		_begin_native_tts(segments)
		return

	speak_generation += 1
	var generation := speak_generation
	var voice_id := _selected_voice_id()
	speak_busy = true
	# INSTANT FEEDBACK: synthesis takes seconds — show activity NOW, not after clips arrive.
	# Old code left the screen static during generation, feeling like "nothing happens".
	read_button.text = "Loading voice…"
	read_button.disabled = false
	_set_read_status(_status_with_voice("LOADING VOICE…"))
	if is_instance_valid(dock_visualizer):
		dock_visualizer.visible = true
		dock_visualizer.set_active(true)
	# If playback opens with the question stem, light it up upfront so the user sees
	# WHAT is about to be read. (Teach-only replays skip this — first seg has teach=true.)
	if not segments.is_empty() and segments[0] is Dictionary:
		var first_choice := int(segments[0].get("choice", -1))
		var first_teach := bool(segments[0].get("teach", false))
		if first_choice < 0 and not first_teach:
			if is_instance_valid(prompt_voice_badge):
				prompt_voice_badge.visible = true
			if is_instance_valid(prompt_visualizer):
				prompt_visualizer.set_active(true)
			_set_question_stem_glow(true)
	if speak_thread != null and speak_thread.is_started():
		speak_thread.wait_to_finish()
	speak_thread = Thread.new()
	_save_voice_choice()
	speak_thread.start(_speak_worker.bind(segments, generation, voice_id, question_id))


func _set_read_status(text: String) -> void:
	if not is_instance_valid(read_status_label):
		return
	if text == "":
		read_status_label.visible = false
	else:
		read_status_label.text = text
		read_status_label.visible = true

func _count_teach(segments: Array) -> int:
	var n := 0
	for seg in segments:
		if seg is Dictionary and bool(seg.get("teach", false)):
			n += 1
	return n

func _teach_index_of(segments: Array, seg_idx: int) -> int:
	var n := 0
	for si in mini(seg_idx, segments.size()):
		var row = segments[si]
		if row is Dictionary and bool(row.get("teach", false)):
			n += 1
	return n

func _update_read_status(choice: int, is_teach: bool, teach_idx: int, teach_total: int) -> void:
	if is_teach:
		_set_read_status(_status_with_voice("TEACHING: RULE %d OF %d" % [teach_idx + 1, maxi(teach_total, teach_idx + 1)]))
	elif choice >= 0:
		var letter: String = str(ANSWER_LETTERS[choice]) if choice >= 0 and choice < ANSWER_LETTERS.size() else str(choice + 1)
		_set_read_status(_status_with_voice("READING: CHOICE " + letter))
	else:
		_set_read_status(_status_with_voice("READING: QUESTION"))

func _register_native_tts_callbacks() -> void:
	# Docs: DisplayServer.tts_set_utterance_callback fires STARTED / ENDED / CANCELED /
	# BOUNDARY per utterance_id. Engine events drive everything: ENDED advances,
	# STARTED syncs the highlight to actual audio start, and a generous watchdog
	# covers drivers that never report back. Tight duration estimates are banned —
	# on Android they fire mid-utterance and pile speech into the OS queue.
	if _native_tts_callbacks_registered:
		return
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_STARTED, Callable(self, "_on_native_utterance_started"))
		DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, Callable(self, "_on_native_utterance_ended"))
		DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_CANCELED, Callable(self, "_on_native_utterance_canceled"))
	_native_tts_callbacks_registered = true

func _pick_native_voice() -> String:
	# Honor the picker (on mobile it holds real OS voices, including an explicit
	# "System default" whose id is ""). Fall back to first English, then default.
	if is_instance_valid(voice_picker) and voice_picker.item_count > 0:
		var label := voice_picker.get_item_text(voice_picker.selected)
		if voice_ids.has(label):
			return str(voice_ids[label])
	if DisplayServer.has_method("tts_get_voices_for_language"):
		var voices := DisplayServer.tts_get_voices_for_language("en")
		if not voices.is_empty():
			return str(voices[0])
	return ""

func _on_native_utterance_ended(utterance_id: int) -> void:
	var seg := utterance_id - 1
	if seg < 0 or seg != _native_seg:
		return
	if _native_generation != speak_generation:
		return
	_play_next_native_tts_segment(_native_segments, seg + 1, speak_generation)

func _on_native_utterance_canceled(utterance_id: int) -> void:
	# A CANCELED for a DIFFERENT utterance is a stale event: Stop() queues one,
	# and Android can deliver it after the next Read() has already started
	# speaking. This handler used to ignore the id and blindly clear _native_seg,
	# which killed the state machine for the utterance actually playing (both
	# ENDED and the watchdog then failed their _native_seg checks, so playback
	# ran out and never advanced - silence with the button stuck on "Stop").
	# Match the id/generation guards the ENDED and STARTED handlers already use.
	var seg := utterance_id - 1
	if seg < 0 or seg != _native_seg:
		return
	if _native_generation != speak_generation:
		return
	_native_seg = -1
	_stop_reading()

func _on_native_utterance_started(utterance_id: int) -> void:
	var seg := utterance_id - 1
	if seg < 0 or seg != _native_seg:
		return
	if _native_generation != speak_generation:
		return
	# Audio really started now (late on network voices): re-affirm the highlight and
	# restart the watchdog from speech start, invalidating the pre-start timer.
	_show_native_highlight(_native_segments, seg)
	_start_native_watchdog(_native_segments, seg, speak_generation)

func _show_native_highlight(segments: Array, seg_idx: int) -> void:
	if seg_idx < 0 or seg_idx >= segments.size():
		return
	var seg: Dictionary = segments[seg_idx]
	var choice := int(seg.get("choice", -1))
	var is_teach := bool(seg.get("teach", false))
	_clear_speech_highlight()
	if is_instance_valid(dock_visualizer):
		dock_visualizer.visible = true
		dock_visualizer.set_active(true)
	if choice >= 0 and choice < answers_box.get_child_count():
		var card = answers_box.get_child(choice)
		if card.has_method("set_speaking"):
			card.set_speaking(true)
	elif is_teach:
		# Count how many teach segments came before this one to find the teach-line index
		var teach_line_idx := 0
		for si in seg_idx:
			if bool(segments[si].get("teach", false)):
				teach_line_idx += 1
		_active_teach_line = teach_line_idx
		if is_instance_valid(info_label) and info_label.visible:
			_do_render_info_label()
	elif choice < 0:
		# Reading question stem
		if is_instance_valid(prompt_voice_badge):
			prompt_voice_badge.visible = true
		if is_instance_valid(prompt_visualizer):
			prompt_visualizer.set_active(true)
		# Glow the question panel
		_set_question_stem_glow(true)
	_update_read_status(choice, is_teach, _teach_index_of(segments, seg_idx), _count_teach(segments))

func _start_native_watchdog(segments: Array, seg_idx: int, generation: int) -> void:
	# Last-resort timer only. Each (re)start bumps the token so a late STARTED event
	# kills the pre-start timer — only the newest timer for the current segment wins.
	_native_watch_id += 1
	var wid := _native_watch_id
	var words := str(segments[seg_idx].get("text", "")).split(" ", false).size()
	var bound: float = maxf(6.0, float(words) / 1.2 + 4.0)
	var tw := create_tween()
	tw.tween_interval(bound)
	tw.tween_callback(func():
		if generation == speak_generation and _native_seg == seg_idx and wid == _native_watch_id:
			_play_next_native_tts_segment(segments, seg_idx + 1, generation)
	)

func _begin_native_tts(segments: Array) -> void:
	speak_generation += 1
	var generation := speak_generation
	_register_native_tts_callbacks()
	_native_voice_id = _pick_native_voice()
	read_button.text = "Stop"
	read_button.disabled = false
	_play_next_native_tts_segment(segments, 0, generation)

func _play_next_native_tts_segment(segments: Array, seg_idx: int, generation: int) -> void:
	if generation != speak_generation:
		return
	if seg_idx >= segments.size():
		_stop_reading()
		return

	var seg: Dictionary = segments[seg_idx]
	var text: String = str(seg.get("text", "")).strip_edges()
	var choice: int = int(seg.get("choice", -1))
	var is_teach: bool = bool(seg.get("teach", false))

	if not want_teach and is_teach:
		_stop_reading()
		return
	if want_teach and not is_teach:
		# Learn mode on native TTS: skip the Q stem + choices the learner already
		# answered and jump straight to the first teach line (no duplicate read).
		_play_next_native_tts_segment(segments, seg_idx + 1, generation)
		return

	_show_native_highlight(segments, seg_idx)
	_native_segments = segments
	_native_seg = seg_idx
	_native_generation = generation
	if text == "":
		_play_next_native_tts_segment(segments, seg_idx + 1, generation)
		return
	# interrupt=true: never queue behind a stray utterance. On the normal path the
	# previous line already ENDED; anything still speaking gets cut instead of piling
	# into the OS queue while the highlight runs ahead (the Android skip bug).
	DisplayServer.tts_speak(text, _native_voice_id, 50, 1.0, 1.0, seg_idx + 1, true)
	_start_native_watchdog(segments, seg_idx, generation)

func _speech_cache_matches(folder: String, segments: Array) -> bool:
	var manifest_path := folder.path_join("manifest.json")
	if not FileAccess.file_exists(manifest_path):
		return false
	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Array:
		return false
	var wanted: Array = []
	for segment in segments:
		if segment is Dictionary and str(segment.get("text", "")).strip_edges() != "":
			wanted.append(segment)
	if wanted.size() != parsed.size():
		return false
	for i in wanted.size():
		var row = parsed[i]
		if not row is Dictionary:
			return false
		if str(row.get("text", "")) != str(wanted[i].get("text", "")):
			return false
		if int(row.get("choice", -1)) != int(wanted[i].get("choice", -1)):
			return false
		if bool(row.get("teach", false)) != bool(wanted[i].get("teach", false)):
			return false
		var clip := FileAccess.open(folder.path_join(str(row.get("file", ""))), FileAccess.READ)
		if clip == null or clip.get_length() == 0:
			if clip != null:
				clip.close()
			return false
		clip.close()
	return true

func _speak_worker(segments: Array, generation: int, voice_id: String, question_id: String) -> void:
	var safe_id := question_id.replace("/", "_").replace("\\", "_")
	if safe_id == "":
		safe_id = "item"
	var folder := OS.get_user_data_dir().path_join("speech").path_join(safe_id + "__" + voice_id)
	DirAccess.make_dir_recursive_absolute(folder)
	if _speech_cache_matches(folder, segments):
		call_deferred("_on_speech_ready", generation, folder, 0, "cache")
		return
	var text_path := folder.path_join("line.json")
	var file := FileAccess.open(text_path, FileAccess.WRITE)
	if file == null:
		call_deferred("_on_speech_ready", generation, folder, 1, "Could not write speech text.")
		return
	file.store_string(JSON.stringify(segments))
	file.close()
	var script_path := ProjectSettings.globalize_path("res://tools/speak_question.py")
	if not FileAccess.file_exists(script_path):
		# Look in executable directory / build directory
		var exe_dir := OS.get_executable_path().get_base_dir()
		var candidate := exe_dir.path_join("tools").path_join("speak_question.py")
		if FileAccess.file_exists(candidate):
			script_path = candidate
		else:
			# If still not found, write out speak_question.py into folder so python can always execute it!
			var embedded_script_path := folder.path_join("speak_question.py")
			var sf := FileAccess.open(embedded_script_path, FileAccess.WRITE)
			if sf != null:
				sf.store_string("""import asyncio, json, sys
from pathlib import Path
import edge_tts

DEFAULT_VOICE = "en-US-AriaNeural"
RATE = "+0%"

def _english_voice(voice: str) -> str:
    return voice.replace("Multilingual", "") or DEFAULT_VOICE

async def _speak(text: str, output_path: str, voice: str) -> None:
    await edge_tts.Communicate(text, _english_voice(voice), rate=RATE).save(output_path)

async def _speak_all(jobs: list) -> None:
    await asyncio.gather(*jobs)

def synthesize(segments: list, folder: Path, voice: str) -> list:
    folder.mkdir(parents=True, exist_ok=True)
    jobs = []
    manifest = []
    for index, segment in enumerate(segments):
        text = str(segment.get("text", "")).strip()
        if not text:
            continue
        name = "%d.mp3" % index
        jobs.append(_speak(text, str(folder / name), voice))
        manifest.append({
            "file": name,
            "choice": int(segment.get("choice", -1)),
            "teach": bool(segment.get("teach", False)),
            "text": text,
        })
    asyncio.run(_speak_all(jobs))
    if not manifest:
        raise SystemExit("empty speech text")
    (folder / "manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
    return manifest

def main() -> None:
    text_path, output_path = sys.argv[1], sys.argv[2]
    voice = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] else DEFAULT_VOICE
    payload = json.loads(Path(text_path).read_text(encoding="utf-8"))
    if isinstance(payload, dict) and "segments" in payload:
        segments = payload["segments"]
    elif isinstance(payload, list):
        segments = payload
    else:
        segments = [{"text": str(payload), "choice": -1}]
    synthesize(segments, Path(output_path), voice)

if __name__ == "__main__":
    main()
""")
				sf.close()
				script_path = embedded_script_path

	var output: Array = []
	var code := OS.execute("python", [script_path, text_path, folder, voice_id], output, true)
	call_deferred("_on_speech_ready", generation, folder, code, "\n".join(output))

func _on_speech_ready(generation: int, folder: String, code: int, output: String, start_index: int = 0) -> void:
	# A late callback from a CANCELLED request must not touch shared state: the
	# busy flag and the queue now belong to the newer request that superseded it.
	# Clearing speak_busy here let _toggle_read start a duplicate synthesis, and
	# the duplicate replaced speak_thread while the live one was still running.
	if generation != speak_generation:
		return
	speak_busy = false
	var manifest_path := folder.path_join("manifest.json")
	if code != 0 or not FileAccess.file_exists(manifest_path):
		# Edge-TTS quota / network failure: fall back to the free on-device voice
		# instead of going silent. Reconstruct the same segments we tried to synth.
		push_warning("Speech failed (edge-tts), falling back to native TTS: " + output)
		if not order.is_empty() and current_index >= 0 and current_index < order.size():
			var fallback_record: Dictionary = records[order[current_index]]
			if want_teach:
				_begin_native_tts(SpeechText.teach_segments(fallback_record))
			else:
				_begin_native_tts(SpeechText.speech_plan(fallback_record))
			return
		read_button.text = "Read question"
		_set_read_status("")
		return
	var file := FileAccess.open(manifest_path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text()) if file else null
	if file:
		file.close()
	speech_queue.clear()
	if parsed is Array:
		for row in parsed:
			if row is Dictionary:
				speech_queue.append({
					"path": folder.path_join(str(row.get("file", ""))),
					"choice": int(row.get("choice", -1)),
					"teach": bool(row.get("teach", false)),
				})
	teach_from_index = -1
	for i in speech_queue.size():
		if bool(speech_queue[i].get("teach", false)):
			teach_from_index = i
			break
	speech_queue_index = teach_from_index if want_teach and teach_from_index >= 0 else maxi(0, start_index)
	if speech_queue.is_empty():
		read_button.text = "Read question"
		return
	read_button.text = "Stop"
	_play_speech_clip()

func _play_speech_clip() -> void:
	_clear_speech_highlight()
	if speech_queue_index >= speech_queue.size():
		read_button.text = "Read question"
		return
	var clip: Dictionary = speech_queue[speech_queue_index]
	var choice := int(clip.get("choice", -1))
	var is_teach := bool(clip.get("teach", false))

	if is_instance_valid(dock_visualizer):
		dock_visualizer.visible = true
		dock_visualizer.set_active(true)

	if choice >= 0 and choice < answers_box.get_child_count():
		var card = answers_box.get_child(choice)
		if card.has_method("set_speaking"):
			card.set_speaking(true)
	elif is_teach:
		# Count how many teach clips came before this one in the queue
		var teach_line_idx := 0
		for si in speech_queue_index:
			if bool(speech_queue[si].get("teach", false)):
				teach_line_idx += 1
		_active_teach_line = teach_line_idx
		if is_instance_valid(info_label) and info_label.visible:
			_do_render_info_label()
	elif choice < 0:
		# Reading question stem
		if is_instance_valid(prompt_voice_badge):
			prompt_voice_badge.visible = true
		if is_instance_valid(prompt_visualizer):
			prompt_visualizer.set_active(true)
		# Glow the question panel
		_set_question_stem_glow(true)

	_update_read_status(choice, is_teach, _teach_index_of(speech_queue, speech_queue_index), _count_teach(speech_queue))
	var file := FileAccess.open(str(clip.get("path", "")), FileAccess.READ)
	if file == null:
		# A clip that will not open must be skipped, but the skip must obey the
		# SAME teach gate as normal playback: pre-answer the learner has not
		# chosen yet, so reaching a teach clip would narrate the answer. The gate
		# used to live only in the callers (_on_reader_finished /
		# _play_next_native_tts_segment), so a missing or truncated mp3 in the
		# question/choices region walked straight past it.
		if is_teach and not want_teach:
			_clear_speech_highlight()
			if read_button:
				read_button.text = "Read question"
				read_button.disabled = false
			return
		speech_queue_index += 1
		_play_speech_clip()
		return
	var stream := AudioStreamMP3.new()
	stream.data = file.get_buffer(file.get_length())
	file.close()
	reader.stream = stream
	reader.play()

func _on_reader_finished() -> void:
	if speak_busy:
		return
	speech_queue_index += 1
	if speech_queue_index < speech_queue.size() and (want_teach or not bool(speech_queue[speech_queue_index].get("teach", false))):
		_play_speech_clip()
		return
	_clear_speech_highlight()
	if is_instance_valid(dock_visualizer):
		dock_visualizer.visible = false
		dock_visualizer.set_active(false)
	if read_button:
		read_button.text = "Hear the rule" if current_answered else "Read question"

func _jump_to_teach() -> void:
	if teach_from_index < 0 or teach_from_index >= speech_queue.size():
		return
	speech_queue_index = teach_from_index
	_halt_player()
	read_button.text = "Stop"
	_play_speech_clip()

func _halt_player() -> void:
	if reader == null:
		return
	var was_connected := reader.finished.is_connected(_on_reader_finished)
	if was_connected:
		reader.finished.disconnect(_on_reader_finished)
	if reader.playing:
		reader.stop()
	if was_connected and not reader.finished.is_connected(_on_reader_finished):
		reader.finished.connect(_on_reader_finished)

func _apply_touch_filters() -> void:
	# Touch scrolling dies when decoration swallows drag starts (MOUSE_FILTER_STOP
	# grabs the gesture). Interactive nodes get PASS (own input + drags propagate);
	# everything else inside scrollable areas gets IGNORE. Scrollers get a real
	# touch deadzone so jittery taps aren't eaten by instant scroll-starts.
	#
	# menu_overlay must be walked TOO, not just its menu_center_box child: the
	# overlay's own ScrollContainer sits ABOVE menu_center_box in the tree, so
	# walking only the two original roots left it at deadzone 0 - meaning the
	# mode-button list scrolled on the very first pixel of finger movement and
	# swallowed taps on Android.
	for root in [main_margin, menu_center_box, menu_overlay]:
		if is_instance_valid(root):
			_touch_filter_walk(root)

func _touch_filter_walk(node: Node) -> void:
	for child in node.get_children():
		_touch_filter_walk(child)
	if not node is Control:
		return
	if node is ScrollContainer:
		(node as ScrollContainer).scroll_deadzone = 16
		return
	if node is ScrollBar:
		return
	if node is BaseButton or node.has_method("cancel_press"):
		(node as Control).mouse_filter = Control.MOUSE_FILTER_PASS
		return
	(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

func _reset_pressed_cards() -> void:
	# A finger that starts scrolling on a card leaves it stuck in PRESSED with no
	# release ever arriving — drop such cards back to NORMAL on scroll start.
	if not is_instance_valid(answers_box):
		return
	for child in answers_box.get_children():
		if child.has_method("cancel_press"):
			child.cancel_press()

func _clear_speech_highlight() -> void:
	if answers_box:
		for child in answers_box.get_children():
			if child.has_method("set_speaking"):
				child.set_speaking(false)
	if is_instance_valid(prompt_voice_badge):
		prompt_voice_badge.visible = false
	if is_instance_valid(prompt_visualizer):
		prompt_visualizer.set_active(false)
	# Clear teach line highlight in info_label
	if _active_teach_line >= 0:
		_active_teach_line = -1
		if is_instance_valid(info_label) and info_label.visible and not _current_record.is_empty():
			_do_render_info_label()
	# Remove question stem glow
	_set_question_stem_glow(false)
	_set_read_status("")


func _set_question_stem_glow(on: bool) -> void:
	if not is_instance_valid(question_panel):
		return
	if on:
		# High-visibility "now reading" state: thicker cyan border, lifted blue-tinted
		# background and a strong outer glow. Old values were near-identical to the
		# resting panel, so the stem highlight was effectively invisible.
		if _question_stem_glow_style == null:
			_question_stem_glow_style = StyleBoxFlat.new()
			_question_stem_glow_style.bg_color = Color("10233f")
			_question_stem_glow_style.border_color = Color("38bdf8")
			_question_stem_glow_style.set_border_width_all(3)
			_question_stem_glow_style.set_corner_radius_all(14)
			_question_stem_glow_style.shadow_color = Color(0.22, 0.74, 0.97, 0.65)
			_question_stem_glow_style.shadow_size = 20
		question_panel.add_theme_stylebox_override("panel", _question_stem_glow_style)
	else:
		# Restore normal panel style
		var normal_style := _panel_style("0a0f1d", "1e293b", 1, 14)
		normal_style.shadow_color = Color(0, 0, 0, 0.4)
		normal_style.shadow_size = 10
		question_panel.add_theme_stylebox_override("panel", normal_style)


func _tick_timer() -> void:
	if not timed_session:
		return
	time_left -= 1
	timer_label.text = "TOTAL " + _format_time(max(time_left, 0))
	timer_bar.value = max(time_left, 0)
	if time_left <= 300:
		timer_label.add_theme_color_override("font_color", Color("f87171"))
		timer_bar.modulate = Color("ef4444")
	elif time_left <= 900:
		timer_label.add_theme_color_override("font_color", Color("fbbf24"))
		timer_bar.modulate = Color("f59e0b")
	if not current_answered and not speak_busy and not reader.playing:
		question_time_left -= 1
		question_timer_label.text = "ITEM " + _format_time(max(question_time_left, 0))
		if question_time_left <= 30:
			question_timer_label.add_theme_color_override("font_color", Color("f87171"))
			# Subtle warning pulse
			question_timer_label.pivot_offset = question_timer_label.size / 2.0
			var p_tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			p_tw.tween_property(question_timer_label, "scale", Vector2(1.08, 1.08), 0.1)
			p_tw.tween_property(question_timer_label, "scale", Vector2.ONE, 0.14)
		elif question_time_left <= 60:
			question_timer_label.add_theme_color_override("font_color", Color("fbbf24"))
		else:
			question_timer_label.add_theme_color_override("font_color", Color("38bdf8"))
	if not current_answered and question_time_left <= 0 and not speak_busy and not reader.playing:
		_answer_selected(-1)
	elif time_left <= 0:
		if current_answered:
			timer.stop()
		else:
			_answer_selected(-1)

func _format_time(seconds: int) -> String:
	return "%02d:%02d" % [seconds / 60, seconds % 60]

func _next_question() -> void:
	if current_index < order.size() - 1:
		current_index += 1
		_show_question()
	else:
		_show_results()

func _show_results() -> void:
	timer.stop()
	_stop_reading()
	question_label.text = "Official Examination Report"
	chapter_hint_label.visible = false
	question_table_panel.visible = false
	question_diagram_panel.visible = false
	question_formula_label.visible = false
	exam_label.text = "STATE ELECTRICAL DIVISION  •  NEBRASKA (NSED / PSI)"
	article_label.text = "CANDIDATE PERFORMANCE SUMMARY  •  NEC 2023 STANDARDS"
	if is_instance_valid(question_hint_row):
		question_hint_row.visible = true
	var accuracy := 100.0 * float(score) / maxf(1.0, float(answered_count))
	var passed := accuracy >= PASS_PERCENT
	if passed:
		score_label.text = "RESULT: PASSED"
		score_label.add_theme_color_override("font_color", Color("6ee7b7"))
		if is_instance_valid(pass_badge):
			pass_badge.add_theme_stylebox_override("panel", _panel_style("0f291e", "059669", 1, 8))
	else:
		score_label.text = "RESULT: DID NOT PASS"
		score_label.add_theme_color_override("font_color", Color("fda4af"))
		if is_instance_valid(pass_badge):
			pass_badge.add_theme_stylebox_override("panel", _panel_style("260c14", "9f1239", 1, 8))
	streak_label.text = "FINAL: %d/%d (%d%%)" % [score, answered_count, roundi(accuracy)]
	for child in answers_box.get_children():
		child.queue_free()
	feedback_panel.visible = true
	feedback_reference.visible = false
	if passed:
		feedback_title.text = "EXAMINATION RESULT: PASS"
		feedback_title.add_theme_color_override("font_color", Color("34d399"))
	else:
		feedback_title.text = "EXAMINATION RESULT: DID NOT PASS"
		feedback_title.add_theme_color_override("font_color", Color("f87171"))
	
	var summary_text := "Candidate Score: %d / %d (%.1f%%)\nPassing Requirement: %d%% or higher\nStatus: %s\nAligned with NFPA 70-2023 National Electrical Code" % [
		score, answered_count, accuracy, PASS_PERCENT, "PASSED" if passed else "DID NOT PASS"
	]
	# The results screen reuses this label after it may have been hidden by a "Correct" verdict.
	feedback_body.text = summary_text
	feedback_body.visible = true

	info_label.clear()
	if missed_questions.is_empty():
		_append_provision_heading("PERFECT SCORE ACHIEVED\n", "34d399")
		info_label.add_text("Congratulations! You answered 100% of questions correctly. You have demonstrated full mastery of these NEC 2023 provisions.")
	else:
		_append_provision_heading("AREAS FOR TARGETED CODE STUDY (%d FAILED ITEMS)\n" % missed_questions.size(), "f87171")
		info_label.add_text("The following questions were answered incorrectly or timed out. Review each NEC article reference carefully before retaking the test:\n\n")

		for i in missed_questions.size():
			var item: Dictionary = missed_questions[i]
			var num: int = int(item.get("index", i + 1))
			var prompt: String = str(item.get("prompt", ""))
			var selected: String = str(item.get("selected", ""))
			var correct: String = str(item.get("correct", ""))
			var article: String = str(item.get("article", "General"))
			var art_title: String = str(item.get("article_title", ""))
			var tip: String = str(item.get("tip_short", ""))

			_append_provision_heading("ITEM #%d  •  NEC %s%s\n" % [num, article, " — " + art_title if art_title != "" else ""], "7dd3fc")
			info_label.push_color(Color("e2e8f0"))
			info_label.add_text("Question: %s\n" % prompt)
			info_label.pop()
			
			info_label.push_color(Color("fca5a5"))
			info_label.add_text("Your answer:  %s\n" % selected)
			info_label.pop()
			
			info_label.push_color(Color("86efac"))
			info_label.push_bold()
			info_label.add_text("Correct NEC answer:  %s\n" % correct)
			info_label.pop()
			info_label.pop()

			if tip != "":
				info_label.push_color(Color("93c5fd"))
				info_label.add_text("Code Key:  %s\n" % tip)
				info_label.pop()

			info_label.add_text("\n")

	info_label.visible = true
	feedback_table_scroll.visible = false
	feedback_table_note.visible = false
	next_button.text = "Return to Main Menu"
	next_button.visible = true
	next_button.disabled = false

func _show_error(message: String) -> void:
	question_label.text = "Project error"
	exam_label.text = "NEC 2023 JOURNEYMAN CHALLENGE"
	article_label.text = ""
	progress_label.text = "Unable to start"
	feedback_panel.visible = true
	next_button.visible = false
	feedback_title.text = "Question bank unavailable"
	feedback_body.text = message
	answers_box.queue_free()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_go_back()

func _on_go_back() -> void:
	# Android system back / gesture. Debounced: the OS may deliver both a key
	# event and a go-back notification for one press.
	var now := Time.get_ticks_msec()
	if now - _last_go_back_msec < 600:
		return
	_last_go_back_msec = now
	if reader != null and reader.playing or speak_busy or DisplayServer.tts_is_speaking():
		_stop_reading()
		return
	if menu_overlay != null and menu_overlay.visible:
		get_tree().quit()
		return
	_show_menu()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_BACK:
			_on_go_back()
			get_viewport().set_input_as_handled()
			return
		if menu_overlay and menu_overlay.visible:
			return
		var key: Key = event.keycode
		if not current_answered:
			if key >= KEY_1 and key <= KEY_4:
				_answer_selected(key - KEY_1)
			elif key == KEY_A:
				_answer_selected(0)
			elif key == KEY_B:
				_answer_selected(1)
			elif key == KEY_C:
				_answer_selected(2)
			elif key == KEY_D:
				_answer_selected(3)
		else:
			if key == KEY_RIGHT or key == KEY_SPACE or key == KEY_ENTER:
				_on_next_button_pressed()

func _on_next_button_pressed() -> void:
	if next_button.text == "Return to Main Menu":
		_show_menu()
	else:
		_next_question()
