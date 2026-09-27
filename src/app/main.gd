class_name Main
extends Control

const ANSWER_LETTERS := ["A", "B", "C", "D"]
const SESSION_LENGTH := 10
const EXAM_NAME := "NE JOURNEYMAN ELECTRICIAN"
const EXAM_SCORED_ITEMS := 80
const EXAM_MINUTES := 240
const PASS_PERCENT := 75
const SECONDS_PER_SCORED_ITEM: int = (EXAM_MINUTES * 60) / EXAM_SCORED_ITEMS
const SESSION_TIME_SECONDS: int = SECONDS_PER_SCORED_ITEM * SESSION_LENGTH
const SpeechText = preload("res://src/speech/speech_text.gd")
const SpeechChain = preload("res://src/fx/speech_chain.gd")
## Microsoft's conversational "Copilot" persona: the most human-sounding US voice
## on the free Edge endpoint. Also the voice of the bundled offline clips.
const DEFAULT_VOICE_ID := "en-US-AndrewNeural"
const VOICE_TIER_HEADINGS := {
	"natural": "MOST NATURAL",
	"general": "ASSISTANT",
	"classic": "CLASSIC NARRATORS",
}

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
var question_diagram_view: DiagramView
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
var _retired_threads: Array[Thread] = []
var speak_generation := 0
var speak_busy := false
var speech_helper: SpeechHelper
## Desktop Edge clips cache. Tests point it elsewhere.
var speech_cache_root := "user://speech"
## Helper request the playing queue is waiting on (-1 when none).
var _live_request := -1
## Set when the picked voice could not be used, so the status line names the
## voice actually speaking instead of the one in the picker.
var _voice_fallback := ""
var speech_queue: Array = []
var speech_queue_index := 0
var teach_from_index := -1
var want_teach := false
var voice_ids: Dictionary = {}
var voice_tiers: Dictionary = {}  # picker label -> "natural" / "general" / "classic"

# Study audio (menu "Audio & Voice" section + compact quiz dock controls)
const PREVIEW_TEXT := "Hi. This is the voice that will read your National Electrical Code questions and answer choices."
## Speech folder id of the preview line; tools/speech/dump_speech.gd bundles it too.
const PREVIEW_ID := "voice-preview"
const SPEECH_BUS := "Speech"
var audio := AudioSettings.new()
var audio_cfg_path := AudioSettings.PATH
var voice_cfg_path := "user://voice.cfg"
var session_audio_mode: int = AudioSettings.Mode.SILENT
var session_muted := true
var listen_phase: int = AudioSettings.ListenPhase.IDLE
var listen_paused := false
var _listen_countdown := 0
var _listen_timer: Timer
var _auto_token := 0  # bumps invalidate pending auto-read / listen timers
var _previewing := false
var audio_mode_buttons: Array[Button] = []
var audio_mode_blurb: Label
var audio_details_box: BoxContainer
var audio_speed_buttons: Array[Button] = []
var audio_pause_buttons: Array[Button] = []
var audio_pause_row: HBoxContainer
var auto_teach_toggle: CheckButton
var audio_exam_note: Label
var preview_button: Button
var mute_button: Button
var dock_panel: PanelContainer
var key_hint_label: Label  # desktop only
var _results_seq := 0
var audio_summary_label: Label
var audio_toggle_button: Button
var audio_body: VBoxContainer
var audio_expanded := false
var quiz_scroll_box: ScrollContainer
var answers_row: BoxContainer  # desktop only: choices | lookup material
var ref_column: VBoxContainer  # desktop only
var feedback_scroll: ScrollContainer
var _fit_gen := 0
var _fit_level := 0
var _table_natural_h := 0.0

## Auto-fit steps for the unanswered screen, roomy -> dense. Answer text never
## goes below 15 px, the readable floor on a phone.
const FIT_QUESTION_MOBILE := [23, 21, 19, 18]
const FIT_QUESTION_DESKTOP := [21, 19, 18, 17]
const FIT_ANSWER := [17, 16, 15, 15]
const FIT_HINT_MOBILE := [15, 14, 14, 13]
const FIT_HINT_DESKTOP := [14, 13, 13, 12]
const FIT_TABLE_MIN_H := 64.0
const DIAGRAM_MAX_H_DESKTOP := 320.0
const DIAGRAM_MAX_H_MOBILE := 250.0
const FIT_DIAGRAM_MIN_H := 96.0
const SIDE_BY_SIDE_MIN_WIDTH := 1100.0
var pause_button: Button
var skip_button: Button

# Reading highlight state
var _current_record: Dictionary = {}
var _current_correct_answer: String = ""
var _info_table_highlighted: bool = false
var _active_teach_line: int = -1  # index into teach lines being highlighted
var _question_stem_glow_style: StyleBoxFlat = null  # cached glow style for question panel
var fx_layer: Control
var streak_meter: StreakMeter
var exam_gauge: TimeGauge
var pace_gauge: TimeGauge
var results_visual: BoxContainer
var result_gauge: ResultGauge
var chapter_bars: ChapterBars
var chapter_stats: Dictionary = {}  # chapter:int -> [correct, total] for the results breakdown
var sfx: Sfx
var sfx_level_buttons: Array[Button] = []  # Off, then one per AudioSettings.SFX_LEVEL_TITLES

func _exit_tree() -> void:
	# The TTS worker runs on speak_thread. Destroying the node while that thread is
	# still inside OS.execute() leaves Godot printing "Thread object is being
	# destroyed without its completion having been realized" and can tear the
	# thread down mid-write. Join it before the node goes away.
	_join_speak_thread()

func _join_speak_thread() -> void:
	if speak_thread != null and speak_thread.is_started():
		speak_thread.wait_to_finish()
	for t in _retired_threads:
		if t.is_started():
			t.wait_to_finish()
	_retired_threads.clear()

func _ready() -> void:
	_load_voice_catalog()
	audio.load_from(audio_cfg_path)
	ui_mobile = "--mobile-ui" in OS.get_cmdline_args() or "--mobile-ui" in OS.get_cmdline_user_args() or OS.get_name() in ["Android", "iOS"]
	speech_helper = SpeechHelper.new()
	speech_helper.name = "SpeechHelper"
	add_child(speech_helper)
	speech_helper.clip_ready.connect(_on_helper_clip)
	speech_helper.request_failed.connect(_on_helper_failed)
	_build_ui()
	_warm_speech_helper()
	_attach_fx()
	_polish_controls()
	_apply_touch_filters()
	_apply_safe_area()
	# OS voices can arrive late on mobile: silently refresh the picker a few
	# seconds after launch so the first Read already offers real voices.
	if ui_mobile or not OS.has_feature("pc"):
		get_tree().create_timer(4.0).timeout.connect(_refresh_native_voices)
	get_viewport().size_changed.connect(_apply_safe_area)
	get_viewport().size_changed.connect(_on_viewport_resized)
	_apply_answers_row_layout()
	timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_tick_timer)
	add_child(timer)
	reader = AudioStreamPlayer.new()
	reader.finished.connect(_on_reader_finished)
	add_child(reader)
	_setup_speech_bus()
	_setup_sfx()
	_listen_timer = Timer.new()
	_listen_timer.wait_time = 1.0
	_listen_timer.timeout.connect(_on_listen_tick)
	add_child(_listen_timer)
	_refresh_audio_section()
	_refresh_dock_audio()
	records = BankLoader.load_records()
	if records.is_empty():
		_show_error("Question bank could not be loaded.")
	else:
		_show_menu()

## Decoration shared by both layouts, attached after the builder ran so the two
## builders stay separate: the fx layer for particles/flashes, the streak meter
## beside the progress line, and the countdown gauges on the time badges.
func _attach_fx() -> void:
	fx_layer = UiFx.make_fx_layer()
	add_child(fx_layer)

	streak_meter = StreakMeter.new()
	streak_meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 12)
	var progress_parent := progress_label.get_parent()
	progress_parent.add_child(progress_row)
	progress_parent.move_child(progress_row, progress_label.get_index())
	progress_label.reparent(progress_row)
	progress_row.add_child(streak_meter)

	exam_gauge = _attach_time_gauge(timer_label)
	pace_gauge = _attach_time_gauge(question_timer_label)

## Shared state styling for both layouts, applied after the builder ran:
## several buttons only had normal/hover boxes and flashed the stock grey
## theme when pressed or focused.
func _polish_controls() -> void:
	var ring := AppTheme.focus_ring(9)
	for b in [read_button, restart_button]:
		if is_instance_valid(b):
			b.add_theme_stylebox_override("pressed", AppTheme.panel_style(AppTheme.BUTTON_PRESSED_BG, AppTheme.SKY_600, 1, 9))
			b.add_theme_stylebox_override("focus", ring)
			b.add_theme_color_override("font_hover_color", AppTheme.WHITE)
			b.add_theme_color_override("font_pressed_color", AppTheme.SKY_300)
	for b in [mute_button, pause_button, skip_button, preview_button]:
		if is_instance_valid(b):
			b.add_theme_stylebox_override("focus", ring)
	if is_instance_valid(next_button):
		next_button.add_theme_stylebox_override("focus", AppTheme.focus_ring(10))
		next_button.add_theme_stylebox_override("disabled", AppTheme.panel_style(AppTheme.SLATE_800, AppTheme.SLATE_700, 1, 10))
		next_button.add_theme_color_override("font_hover_color", AppTheme.WHITE)
		next_button.add_theme_color_override("font_pressed_color", AppTheme.SKY_100)
	if not ui_mobile and is_instance_valid(restart_button):
		key_hint_label = Label.new()
		key_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		key_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		key_hint_label.size_flags_stretch_ratio = 0.7
		key_hint_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		key_hint_label.clip_text = true
		key_hint_label.add_theme_font_override("font", AppTheme.ui_font(600))
		key_hint_label.add_theme_font_size_override("font_size", 11)
		key_hint_label.add_theme_color_override("font_color", AppTheme.SLATE_500)
		var dock_row := restart_button.get_parent()
		dock_row.add_child(key_hint_label)
		dock_row.move_child(key_hint_label, restart_button.get_index())
	_update_key_hint()

## Desktop dock hint that matches what the keyboard does right now.
func _update_key_hint() -> void:
	if not is_instance_valid(key_hint_label):
		return
	if order.is_empty() or (is_instance_valid(menu_overlay) and menu_overlay.visible):
		key_hint_label.text = ""
	elif next_button.visible and next_button.text == "Return to Main Menu":
		key_hint_label.text = "ENTER  menu"
	elif session_audio_mode == AudioSettings.Mode.LISTEN:
		key_hint_label.text = "SPACE  pause / resume   •   ENTER / →  skip"
	elif current_answered:
		key_hint_label.text = "ENTER / SPACE / →  next question"
	else:
		key_hint_label.text = "KEYS  A–D  or  1–4  to answer"

## Answered state: the verdict, correct answer and reference stay put; the
## table and explanation live in this inner scroll that takes whatever height
## is left, so the page itself does not scroll and Next stays pinned below.
func _make_feedback_detail(column: VBoxContainer) -> VBoxContainer:
	feedback_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	feedback_scroll = ScrollContainer.new()
	feedback_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	feedback_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feedback_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	feedback_scroll.custom_minimum_size = Vector2(0, _feedback_min_h())
	column.add_child(feedback_scroll)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 10 if ui_mobile else 8)
	feedback_scroll.add_child(detail)
	return detail

func _quiz_overflow() -> float:
	if not is_instance_valid(quiz_scroll_box) or quiz_scroll_box.get_child_count() == 0:
		return 0.0
	var content := quiz_scroll_box.get_child(0) as Control
	return content.get_combined_minimum_size().y - quiz_scroll_box.size.y

func _live_cards() -> Array:
	var out: Array = []
	for c in answers_box.get_children():
		if c is AnswerCard and not c.is_queued_for_deletion():
			out.append(c)
	return out

func _fit_apply(level: int) -> void:
	_fit_level = clampi(level, 0, FIT_ANSWER.size() - 1)
	var q_steps: Array = FIT_QUESTION_MOBILE if ui_mobile else FIT_QUESTION_DESKTOP
	var h_steps: Array = FIT_HINT_MOBILE if ui_mobile else FIT_HINT_DESKTOP
	question_label.add_theme_font_size_override("font_size", int(q_steps[_fit_level]))
	article_label.add_theme_font_size_override("font_size", int(h_steps[_fit_level]))
	for card in _live_cards():
		card.set_text_size(int(FIT_ANSWER[_fit_level]))
		card.set_density(1 if _fit_level >= 2 else 0)

## Restart the unanswered-screen fit: roomy first, then step down once the
## new cards have been laid out (they need a frame to get their width).
func _fit_begin() -> void:
	_fit_gen += 1
	_fit_apply(0)
	if question_table_panel.visible and _table_natural_h > 0.0:
		question_table_scroll.custom_minimum_size.y = _table_natural_h
	if is_instance_valid(question_diagram_view):
		question_diagram_view.max_height = DIAGRAM_MAX_H_MOBILE if ui_mobile else DIAGRAM_MAX_H_DESKTOP
	_fit_after_frames(_fit_gen, 2)

func _fit_after_frames(gen: int, frames: int) -> void:
	if gen != _fit_gen or not is_inside_tree():
		return
	if frames <= 0:
		_fit_run(gen)
		return
	var next := _fit_after_frames.bind(gen, frames - 1)
	if not get_tree().process_frame.is_connected(next):
		get_tree().process_frame.connect(next, CONNECT_ONE_SHOT)

func _fit_run(gen: int) -> void:
	if gen != _fit_gen or order.is_empty():
		return
	if current_answered:
		_fit_answered()
		return
	# Font and min-size changes re-measure synchronously at a fixed width, so
	# the whole step-down happens in this one call.
	var over := _quiz_overflow()
	while over > 0.5 and _fit_level < FIT_ANSWER.size() - 1:
		_fit_apply(_fit_level + 1)
		over = _quiz_overflow()
	if over > 0.5 and question_table_panel.visible:
		question_table_panel.custom_minimum_size.y = 0.0
		question_table_scroll.custom_minimum_size.y = maxf(FIT_TABLE_MIN_H, question_table_scroll.custom_minimum_size.y - over)
		over = _quiz_overflow()
	# The table heading already says where to look; the chapter path is the
	# expendable duplicate (kept when the heading had to be redacted).
	if over > 0.5 and question_table_panel.visible and lookup_box.visible \
			and not question_table_heading.text.ends_with("REFERENCE TABLE"):
		chapter_hint_label.visible = false
		lookup_box.visible = false
		over = _quiz_overflow()
	if over > 0.5 and question_diagram_panel.visible:
		_shrink_diagram(over)

func _shrink_diagram(over: float) -> void:
	var cur := question_diagram_view.custom_minimum_size.y
	question_diagram_view.max_height = maxf(FIT_DIAGRAM_MIN_H, cur - over)

func _refresh_ref_column() -> void:
	if not is_instance_valid(ref_column):
		return
	ref_column.visible = question_table_panel.visible or question_diagram_panel.visible or formula_box.visible

func _side_by_side() -> bool:
	return is_instance_valid(answers_row) and get_viewport().get_visible_rect().size.x >= SIDE_BY_SIDE_MIN_WIDTH

func _apply_answers_row_layout() -> void:
	if not is_instance_valid(answers_row):
		return
	var wide := _side_by_side()
	answers_row.vertical = not wide
	# Stacked, the lookup material reads first, like the book open above the sheet.
	answers_row.move_child(ref_column, 1 if wide else 0)

func _on_viewport_resized() -> void:
	_apply_answers_row_layout()
	if not current_answered and not order.is_empty():
		_fit_begin()

## After answering, drop what only mattered while choosing: the eliminated
## cards (their notes are in the explanation), session pills, gist, lookup
## path and item bar. What remains is the question, the verdict cards and the
## explanation sheet.
func _compact_answered(correct: int, selected: int) -> void:
	var cards := answers_box.get_children()
	for i in cards.size():
		if i != correct and i != selected:
			(cards[i] as Control).visible = false
	exam_pills_row.visible = false
	if is_instance_valid(question_hint_row):
		question_hint_row.visible = false
	chapter_hint_label.visible = false
	lookup_box.visible = false
	timer_bar.visible = false
	_refresh_ref_column()
	feedback_scroll.visible = true
	feedback_scroll.scroll_vertical = 0
	feedback_scroll.custom_minimum_size.y = _feedback_min_h()
	_fit_gen += 1
	_fit_after_frames(_fit_gen, 2)

func _feedback_min_h() -> float:
	return 150.0 if ui_mobile else 170.0

## Answered-state fit: a long stem can leave less than the sheet's preferred
## height; let the sheet give way (it scrolls inside) before the page does.
func _fit_answered() -> void:
	var over := _quiz_overflow()
	if over > 0.5:
		feedback_scroll.custom_minimum_size.y = maxf(84.0, feedback_scroll.custom_minimum_size.y - over)
		over = _quiz_overflow()
	if over > 0.5 and question_diagram_panel.visible:
		_shrink_diagram(over)

func _attach_time_gauge(label: Label) -> TimeGauge:
	var gauge := TimeGauge.new()
	var margin := label.get_parent()
	if ui_mobile:
		gauge.mode = TimeGauge.Mode.EDGE
		var badge := margin.get_parent()
		badge.add_child(gauge)
		badge.move_child(gauge, 0)
		return gauge
	gauge.custom_minimum_size = Vector2(18, 18)
	gauge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	label.reparent(row)
	row.add_child(gauge)
	row.move_child(gauge, 0)
	return gauge

func _update_time_gauges() -> void:
	if is_instance_valid(exam_gauge):
		exam_gauge.visible = timed_session
		var exam_col := UiFx.CYAN
		if time_left <= 300:
			exam_col = UiFx.RED
		elif time_left <= 900:
			exam_col = UiFx.AMBER
		exam_gauge.set_value(float(maxi(time_left, 0)) / float(maxi(session_time_limit, 1)), exam_col,
			not timer.is_stopped() and time_left > 0 and time_left <= 60)
	if is_instance_valid(question_timer_label):
		var pace_badge: Node = question_timer_label.get_parent()
		while pace_badge != null and not pace_badge is PanelContainer:
			pace_badge = pace_badge.get_parent()
		if pace_badge != null:
			pace_badge.visible = timed_session
	if is_instance_valid(pace_gauge):
		pace_gauge.visible = timed_session
		var pace_col := UiFx.CYAN
		if current_answered:
			pace_col = UiFx.EMERALD
		elif question_time_left <= 30:
			pace_col = UiFx.RED
		elif question_time_left <= 60:
			pace_col = UiFx.AMBER
		pace_gauge.set_value(float(maxi(question_time_left, 0)) / float(SECONDS_PER_SCORED_ITEM), pace_col,
			not current_answered and question_time_left > 0 and question_time_left <= 30)

func _play_answer_fx(cards: Array, correct: int, selected: int) -> void:
	var is_right := selected == correct and selected >= 0
	_sfx(Sfx.answer_sound(AudioSettings.grades_answers(session_audio_mode), is_right))
	if ui_mobile:
		Input.vibrate_handheld(25 if is_right else 90)
	if correct >= 0 and correct < cards.size():
		var right_card: AnswerCard = cards[correct]
		UiFx.glow_pulse(right_card, UiFx.EMERALD, 30 if is_right else 18)
		if is_right:
			var spark_at := right_card.vector_state_icon.get_global_rect().get_center()
			if _quiz_view_rect().has_point(spark_at):
				UiFx.spark_burst(fx_layer, spark_at, UiFx.EMERALD)
			UiFx.screen_flash(fx_layer, UiFx.EMERALD, 0.07)
	if not is_right:
		UiFx.screen_flash(fx_layer, UiFx.RED, 0.11)
		if selected >= 0 and selected < cards.size():
			UiFx.glow_pulse(cards[selected], UiFx.RED, 24)
	UiFx.pop(pass_badge, 1.06)
	UiFx.pop(feedback_title, 1.12, 0.3)
	UiFx.glow_pulse(feedback_panel, UiFx.EMERALD if is_right else UiFx.RED, 22, 0.8)

## On-screen rect of the scrolling quiz column (sparks outside it would land on
## the Next button or dock).
func _quiz_view_rect() -> Rect2:
	var n: Node = answers_box
	while n != null and not n is ScrollContainer:
		n = n.get_parent()
	return (n as Control).get_global_rect() if n != null else get_global_rect()

func _question_panel_style() -> StyleBoxFlat:
	var style := AppTheme.panel_style(AppTheme.SURFACE_DEEP, AppTheme.SLATE_800, 1, 14)
	style.shadow_color = Color(0.22, 0.74, 0.97, 0.09)
	style.shadow_size = 16
	return style

func _apply_safe_area() -> void:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var win := get_window()
	var win_size: Vector2i = win.size if win != null else Vector2i.ZERO
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var cutouts: Array[Rect2] = DisplayServer.get_display_cutouts()
	var m := SafeArea.margins(vp_size, win_size, safe_area, cutouts, ui_mobile)
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

func _start_quiz(question_count: int = SESSION_LENGTH, time_limit: int = SESSION_TIME_SECONDS, timed: bool = true, mode_name: String = "Practice Test") -> void:
	order.clear()
	for i in records.size():
		order.append(i)
	order.shuffle()
	session_length = mini(question_count, records.size())
	if order.size() > session_length:
		order.resize(session_length)
	session_time_limit = time_limit
	session_audio_mode = AudioSettings.session_mode(audio.mode, mode_name == "Full Journeyman Exam")
	session_muted = AudioSettings.starts_muted(session_audio_mode)
	listen_phase = AudioSettings.ListenPhase.IDLE
	listen_paused = false
	var listening := session_audio_mode == AudioSettings.Mode.LISTEN
	timed_session = timed and not listening
	session_name = mode_name + (" · Listen" if listening else "")
	_refresh_dock_audio()
	current_index = 0
	score = 0
	streak = 0
	answered_count = 0
	current_answered = false
	missed_questions.clear()
	chapter_stats.clear()
	time_left = session_time_limit
	question_time_left = SECONDS_PER_SCORED_ITEM
	if timed_session:
		timer.start()
	else:
		timer.stop()
	_stop_reading()
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(menu_overlay, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func():
		menu_overlay.visible = false
		_show_question()
	)

func _build_ui() -> void:
	if ui_mobile:
		MobileLayout.build(self)
	else:
		DesktopLayout.build(self)

## "Audio & Voice" menu section, shared by both layouts (sizes follow ui_mobile).
## Returns the section so the caller can position it.
func _build_audio_section(parent: VBoxContainer) -> Control:
	var h: float = 56.0 if ui_mobile else 40.0
	var fs: int = 14 if ui_mobile else 13
	var label_w: float = 62.0 if ui_mobile else 48.0
	var section := PanelContainer.new()
	var section_style := AppTheme.panel_style(AppTheme.SECTION_BG, AppTheme.SLATE_800, 1, 12)
	section_style.set_content_margin_all(14.0 if ui_mobile else 16.0)
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
	audio_summary_label = Label.new()
	audio_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	audio_summary_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	audio_summary_label.clip_text = true
	audio_summary_label.add_theme_font_override("font", AppTheme.ui_font(600))
	audio_summary_label.add_theme_font_size_override("font_size", fs)
	audio_summary_label.add_theme_color_override("font_color", AppTheme.SLATE_300)
	hdr.add_child(audio_summary_label)
	audio_toggle_button = Widgets.make_dock_button("Change", 92.0 if ui_mobile else 84.0, 44.0 if ui_mobile else 32.0, fs, _toggle_audio_section)
	audio_toggle_button.add_theme_stylebox_override("focus", AppTheme.focus_ring(9))
	hdr.add_child(audio_toggle_button)
	audio_body = VBoxContainer.new()
	audio_body.add_theme_constant_override("separation", 10)
	audio_body.visible = false
	col.add_child(audio_body)

	var modes := GridContainer.new()
	modes.columns = 2 if ui_mobile else 4
	modes.add_theme_constant_override("h_separation", 8)
	modes.add_theme_constant_override("v_separation", 8)
	audio_body.add_child(modes)
	var mode_group := ButtonGroup.new()
	audio_mode_buttons.clear()
	for m in [AudioSettings.Mode.SILENT, AudioSettings.Mode.TAP, AudioSettings.Mode.AUTO, AudioSettings.Mode.LISTEN]:
		var chip := Widgets.make_chip(AudioSettings.MODE_TITLES[m], h, fs + 1, mode_group)
		chip.pressed.connect(_on_audio_mode_picked.bind(m))
		modes.add_child(chip)
		audio_mode_buttons.append(chip)

	audio_mode_blurb = Label.new()
	audio_mode_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	audio_mode_blurb.add_theme_font_override("font", AppTheme.ui_font(400))
	audio_mode_blurb.add_theme_font_size_override("font_size", 13 if ui_mobile else 12)
	audio_mode_blurb.add_theme_color_override("font_color", AppTheme.SLATE_400)
	audio_body.add_child(audio_mode_blurb)

	audio_details_box = VBoxContainer.new()
	audio_details_box.add_theme_constant_override("separation", 10)
	audio_body.add_child(audio_details_box)
	var opts: BoxContainer = VBoxContainer.new() if ui_mobile else HBoxContainer.new()
	opts.add_theme_constant_override("separation", 10 if ui_mobile else 20)
	audio_details_box.add_child(opts)

	var voice_row := HBoxContainer.new()
	voice_row.add_theme_constant_override("separation", 8)
	voice_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opts.add_child(voice_row)
	voice_row.add_child(Widgets.audio_row_label("VOICE", label_w))
	voice_row.add_child(Widgets.make_voice_picker(self, h, fs))
	preview_button = Widgets.make_dock_button("Preview", 96.0 if ui_mobile else 84.0, h, fs, _preview_voice)
	voice_row.add_child(preview_button)

	var speed_row := HBoxContainer.new()
	speed_row.add_theme_constant_override("separation", 6)
	opts.add_child(speed_row)
	speed_row.add_child(Widgets.audio_row_label("SPEED", label_w))
	var speed_group := ButtonGroup.new()
	audio_speed_buttons.clear()
	for s in AudioSettings.SPEEDS:
		var chip := Widgets.make_chip(AudioSettings.speed_label(s), h, fs, speed_group)
		chip.custom_minimum_size.x = 0.0 if ui_mobile else 56.0
		chip.pressed.connect(_on_audio_speed_picked.bind(s))
		speed_row.add_child(chip)
		audio_speed_buttons.append(chip)

	auto_teach_toggle = CheckButton.new()
	auto_teach_toggle.text = "Also read the rule after I answer"
	auto_teach_toggle.custom_minimum_size = Vector2(0, 44.0 if ui_mobile else 32.0)
	auto_teach_toggle.add_theme_font_override("font", AppTheme.ui_font(500))
	auto_teach_toggle.add_theme_font_size_override("font_size", fs)
	auto_teach_toggle.add_theme_color_override("font_color", AppTheme.SLATE_300)
	auto_teach_toggle.add_theme_color_override("font_hover_color", AppTheme.WHITE)
	auto_teach_toggle.add_theme_color_override("font_pressed_color", AppTheme.EMERALD_300)
	auto_teach_toggle.add_theme_color_override("font_hover_pressed_color", AppTheme.EMERALD_200)
	auto_teach_toggle.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	auto_teach_toggle.toggled.connect(_on_auto_teach_toggled)
	audio_details_box.add_child(auto_teach_toggle)

	audio_pause_row = HBoxContainer.new()
	audio_pause_row.add_theme_constant_override("separation", 6)
	audio_details_box.add_child(audio_pause_row)
	audio_pause_row.add_child(Widgets.audio_row_label("THINK", label_w))
	var pause_group := ButtonGroup.new()
	audio_pause_buttons.clear()
	for p in AudioSettings.THINK_PAUSES:
		var chip := Widgets.make_chip("%d s" % p, h, fs, pause_group)
		chip.custom_minimum_size.x = 0.0 if ui_mobile else 56.0
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL if ui_mobile else Control.SIZE_FILL
		chip.pressed.connect(_on_audio_pause_picked.bind(p))
		audio_pause_row.add_child(chip)
		audio_pause_buttons.append(chip)
	if not ui_mobile:
		var pause_hint := Widgets.audio_row_label("pause before the answer is revealed", 0)
		pause_hint.add_theme_font_override("font", AppTheme.ui_font(500))
		pause_hint.add_theme_font_size_override("font_size", 12)
		audio_pause_row.add_child(pause_hint)

	audio_exam_note = Label.new()
	audio_exam_note.text = "The Full Journeyman Simulator stays exam-quiet: nothing plays by itself, like the real exam. The Read button still works there."
	audio_exam_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	audio_exam_note.add_theme_font_override("font", AppTheme.ui_font(400))
	audio_exam_note.add_theme_font_size_override("font_size", 12 if ui_mobile else 11)
	audio_exam_note.add_theme_color_override("font_color", AppTheme.ROSE_300)
	audio_details_box.add_child(audio_exam_note)

	# Sound effects sit outside the voice details: Silent mutes the voice only.
	var sfx_row := HBoxContainer.new()
	sfx_row.add_theme_constant_override("separation", 6)
	audio_body.add_child(sfx_row)
	sfx_row.add_child(Widgets.audio_row_label("SOUNDS", label_w))
	var sfx_group := ButtonGroup.new()
	sfx_level_buttons.clear()
	var sfx_titles: Array[String] = ["Off"]
	sfx_titles.append_array(AudioSettings.SFX_LEVEL_TITLES)
	for i in sfx_titles.size():
		var chip := Widgets.make_chip(sfx_titles[i], h, fs, sfx_group)
		chip.custom_minimum_size.x = 0.0 if ui_mobile else 72.0
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL if ui_mobile else Control.SIZE_FILL
		chip.pressed.connect(_on_sfx_level_picked.bind(i - 1))
		sfx_row.add_child(chip)
		sfx_level_buttons.append(chip)
	if not ui_mobile:
		var sfx_hint := Widgets.audio_row_label("answer tones, results and clock warnings", 0)
		sfx_hint.add_theme_font_override("font", AppTheme.ui_font(500))
		sfx_hint.add_theme_font_size_override("font_size", 12)
		sfx_row.add_child(sfx_hint)
	return section

func _refresh_audio_section() -> void:
	if audio_mode_buttons.is_empty():
		return
	for i in audio_mode_buttons.size():
		audio_mode_buttons[i].set_pressed_no_signal(i == audio.mode)
	for i in audio_speed_buttons.size():
		audio_speed_buttons[i].set_pressed_no_signal(is_equal_approx(AudioSettings.SPEEDS[i], audio.speed))
	for i in audio_pause_buttons.size():
		audio_pause_buttons[i].set_pressed_no_signal(AudioSettings.THINK_PAUSES[i] == audio.think_pause)
	audio_mode_blurb.text = AudioSettings.MODE_BLURBS[audio.mode]
	if is_instance_valid(audio_summary_label):
		var summary: String = AudioSettings.MODE_TITLES[audio.mode]
		if audio.mode != AudioSettings.Mode.SILENT:
			summary += "  ·  %s  ·  %s" % [_voice_short(), AudioSettings.speed_label(audio.speed)]
			if audio.mode == AudioSettings.Mode.LISTEN:
				summary += "  ·  %d s think" % audio.think_pause
		summary += "  ·  " + AudioSettings.sfx_label(audio.sfx_enabled, audio.sfx_level)
		audio_summary_label.text = summary
		# Open, the chips below say the same thing in full.
		audio_summary_label.modulate.a = 0.0 if audio_expanded else 1.0
		audio_body.visible = audio_expanded
		audio_toggle_button.text = "Done" if audio_expanded else "Change"
	audio_details_box.visible = audio.mode != AudioSettings.Mode.SILENT
	auto_teach_toggle.set_pressed_no_signal(audio.auto_teach)
	auto_teach_toggle.visible = audio.mode == AudioSettings.Mode.AUTO
	audio_pause_row.visible = audio.mode == AudioSettings.Mode.LISTEN
	audio_exam_note.visible = AudioSettings.autoplays_question(audio.mode)
	for i in sfx_level_buttons.size():
		sfx_level_buttons[i].set_pressed_no_signal(i == (audio.sfx_level + 1 if audio.sfx_enabled else 0))
	# Listen sessions run untimed, so "30 minutes timed" on the drills would lie.
	for b in menu_mode_buttons:
		if not is_instance_valid(b) or not b.has_meta("base_text") or bool(b.get_meta("full_exam")):
			continue
		var base := str(b.get_meta("base_text"))
		if audio.mode == AudioSettings.Mode.LISTEN:
			var cut := base.rfind(" • ")
			b.text = (base.substr(0, cut) if cut > 0 else base) + " • hands-free, untimed"
		else:
			b.text = base

func _toggle_audio_section() -> void:
	audio_expanded = not audio_expanded
	_refresh_audio_section()

func _on_audio_mode_picked(m: int) -> void:
	audio.mode = AudioSettings.sanitize_mode(m)
	if _previewing and audio.mode == AudioSettings.Mode.SILENT:
		_stop_reading()
	audio.save_to(audio_cfg_path)
	_refresh_audio_section()

func _on_audio_speed_picked(s: float) -> void:
	audio.speed = AudioSettings.sanitize_speed(s)
	audio.save_to(audio_cfg_path)
	_apply_speed()
	_refresh_audio_section()

func _on_audio_pause_picked(p: int) -> void:
	audio.think_pause = AudioSettings.sanitize_pause(p)
	audio.save_to(audio_cfg_path)
	_refresh_audio_section()

func _on_auto_teach_toggled(on: bool) -> void:
	audio.auto_teach = on
	audio.save_to(audio_cfg_path)

## level -1 = Off; otherwise an index into AudioSettings.SFX_LEVEL_TITLES.
func _on_sfx_level_picked(level: int) -> void:
	audio.sfx_enabled = level >= 0
	if level >= 0:
		audio.sfx_level = AudioSettings.sanitize_sfx_level(level)
	audio.save_to(audio_cfg_path)
	_apply_sfx_settings()
	_refresh_audio_section()
	# Let the learner hear the new level on the sound they'll hear most.
	_sfx("correct")

func _setup_sfx() -> void:
	sfx = Sfx.new()
	sfx.name = "Sfx"
	add_child(sfx)
	sfx.setup()
	sfx.voice_active = func() -> bool:
		return (reader != null and reader.playing) or speak_busy or DisplayServer.tts_is_speaking()
	_apply_sfx_settings()

func _apply_sfx_settings() -> void:
	if sfx != null:
		sfx.apply_settings(audio.sfx_enabled, AudioSettings.sfx_bus_db(audio.sfx_level))

func _sfx(id: String) -> void:
	if sfx != null and id != "":
		sfx.play(id)

## Speed is applied at playback so the cached per-voice Edge clips stay valid:
## pitch_scale speeds the player up, and a pitch shift on a dedicated bus pulls
## the voice back to its natural pitch. See fx/speech_chain.gd for the rest.
func _setup_speech_bus() -> void:
	var idx := AudioServer.get_bus_index(SPEECH_BUS)
	if idx < 0:
		idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, SPEECH_BUS)
		AudioServer.set_bus_send(idx, "Master")
		SpeechChain.build(idx)
	reader.bus = SPEECH_BUS
	_apply_speed()

func _apply_speed() -> void:
	if reader != null:
		reader.pitch_scale = audio.speed
	SpeechChain.apply_speed(AudioServer.get_bus_index(SPEECH_BUS), audio.speed)

func _preview_voice() -> void:
	if _previewing:
		_stop_reading()
		return
	_stop_reading()
	var segments: Array = [{"text": PREVIEW_TEXT, "choice": -1, "teach": false}]
	_previewing = true
	preview_button.text = "Stop"
	_voice_fallback = ""
	_save_voice_choice()
	var bundle := _bundled_speech_folder(PREVIEW_ID, _selected_voice_id(), segments)
	if bundle != "":
		speak_generation += 1
		_on_speech_ready(speak_generation, bundle, 0, "bundle")
		return
	if _speech_mobile():
		_begin_native_tts(segments)
		return
	_read_with_helper(PREVIEW_ID, segments)

func _refresh_dock_audio() -> void:
	if not is_instance_valid(mute_button):
		return
	var listening := session_audio_mode == AudioSettings.Mode.LISTEN and listen_phase != AudioSettings.ListenPhase.IDLE
	mute_button.visible = not listening
	mute_button.text = "Audio off · Turn on" if session_muted else "Mute"
	mute_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL if session_muted and ui_mobile else Control.SIZE_FILL
	mute_button.add_theme_color_override("font_color", AppTheme.SLATE_400 if session_muted else AppTheme.SLATE_300)
	read_button.visible = not listening and not session_muted
	pause_button.visible = listening
	skip_button.visible = listening
	pause_button.text = "Resume" if listen_paused else "Pause"
	pause_button.add_theme_color_override("font_color", AppTheme.EMERALD_300 if listen_paused else AppTheme.SLATE_300)

func _toggle_session_mute() -> void:
	session_muted = not session_muted
	if session_muted:
		_auto_token += 1
		_stop_reading()
	else:
		_prefetch_speech()
	_refresh_dock_audio()

## Runs `callback` after `seconds` unless anything bumped _auto_token meanwhile
## (next question, menu, mute, pause), so stale autoplay can never fire.
func _after_delay(seconds: float, callback: Callable) -> void:
	var token := _auto_token
	get_tree().create_timer(seconds).timeout.connect(func() -> void:
		if token == _auto_token and is_inside_tree():
			callback.call()
	)

func _schedule_auto_read() -> void:
	_auto_token += 1
	if is_instance_valid(_listen_timer):
		_listen_timer.stop()
	listen_phase = AudioSettings.ListenPhase.IDLE
	if session_muted or order.is_empty() or not AudioSettings.autoplays_question(session_audio_mode):
		_refresh_dock_audio()
		return
	if session_audio_mode == AudioSettings.Mode.LISTEN:
		_listen_enter(AudioSettings.ListenPhase.QUESTION)
		return
	_after_delay(0.45, _auto_read_question)

func _auto_read_question() -> void:
	if current_answered or menu_overlay.visible or order.is_empty() or listen_paused:
		return
	if reader.playing or speak_busy or DisplayServer.tts_is_speaking():
		return
	_begin_reading(SpeechText.speech_plan(records[order[current_index]]))

func _auto_read_teach() -> void:
	if not current_answered or menu_overlay.visible or order.is_empty() or listen_paused:
		return
	if reader.playing or speak_busy or DisplayServer.tts_is_speaking():
		return
	want_teach = true
	_begin_reading(SpeechText.teach_segments(records[order[current_index]]))

func _listen_enter(phase: int) -> void:
	listen_phase = phase
	match phase:
		AudioSettings.ListenPhase.QUESTION:
			_listen_timer.stop()
			_set_read_status("LISTEN MODE · QUESTION %d OF %d" % [current_index + 1, order.size()])
			_after_delay(0.45, _auto_read_question)
		AudioSettings.ListenPhase.THINK:
			_listen_countdown = audio.think_pause
			_listen_timer.start()
			_show_listen_countdown()
		AudioSettings.ListenPhase.TEACH:
			_listen_timer.stop()
			if order.is_empty() or SpeechText.teach_segments(records[order[current_index]]).is_empty():
				_listen_enter(AudioSettings.ListenPhase.GAP)
				return
			_after_delay(0.6, _auto_read_teach)
		AudioSettings.ListenPhase.GAP:
			_listen_countdown = AudioSettings.LISTEN_GAP_SECONDS
			_listen_timer.start()
			_show_listen_countdown()
	_refresh_dock_audio()

func _show_listen_countdown() -> void:
	if listen_phase == AudioSettings.ListenPhase.THINK:
		_set_read_status("THINK IT OVER · ANSWER IN %d s" % _listen_countdown)
	elif listen_phase == AudioSettings.ListenPhase.GAP:
		var last := current_index >= order.size() - 1
		_set_read_status(("RESULTS IN %d s" if last else "NEXT QUESTION IN %d s") % _listen_countdown)

func _on_listen_tick() -> void:
	if listen_paused or session_audio_mode != AudioSettings.Mode.LISTEN or order.is_empty():
		return
	_listen_countdown -= 1
	if _listen_countdown > 0:
		_show_listen_countdown()
		return
	_listen_timer.stop()
	if listen_phase == AudioSettings.ListenPhase.THINK:
		if current_answered:
			_listen_enter(AudioSettings.ListenPhase.TEACH)
		else:
			_answer_selected(int(records[order[current_index]].get("correct_index", 0)))
	elif listen_phase == AudioSettings.ListenPhase.GAP:
		_next_question()

## Pausing stops the audio outright; Resume restarts the current step (re-reads
## the question or rule, or continues the countdown). Restarting a line is more
## robust than engine pause across Edge clips and Android TTS, and it helps a
## listener who lost track while busy.
func _toggle_listen_pause() -> void:
	if session_audio_mode != AudioSettings.Mode.LISTEN:
		return
	listen_paused = not listen_paused
	if listen_paused:
		_auto_token += 1
		_stop_reading()
		_set_read_status("PAUSED · TAP RESUME TO CONTINUE")
	else:
		match listen_phase:
			AudioSettings.ListenPhase.QUESTION, AudioSettings.ListenPhase.TEACH:
				_listen_enter(listen_phase)
			_:
				_show_listen_countdown()
	_refresh_dock_audio()

func _listen_skip() -> void:
	listen_paused = false
	_auto_token += 1
	_listen_timer.stop()
	_stop_reading()
	_next_question()

## Natural end of a readout (queue done or stopped at the teach gate), as
## opposed to the user pressing Stop. Drives the hands-free loop.
func _notify_playback_complete() -> void:
	call_deferred("_on_playback_complete", speak_generation)

func _on_playback_complete(generation: int) -> void:
	if generation != speak_generation:
		return
	if _previewing:
		_previewing = false
		if is_instance_valid(preview_button):
			preview_button.text = "Preview"
		return
	if session_audio_mode != AudioSettings.Mode.LISTEN or listen_paused or menu_overlay.visible:
		return
	if listen_phase == AudioSettings.ListenPhase.QUESTION and not current_answered:
		_listen_enter(AudioSettings.ListenPhase.THINK)
	elif listen_phase == AudioSettings.ListenPhase.TEACH:
		_listen_enter(AudioSettings.ListenPhase.GAP)

func _practice_time(question_count: int) -> int:
	return question_count * SECONDS_PER_SCORED_ITEM

func _show_menu() -> void:
	timer.stop()
	_auto_token += 1
	_clear_confetti()
	if is_instance_valid(_listen_timer):
		_listen_timer.stop()
	listen_phase = AudioSettings.ListenPhase.IDLE
	listen_paused = false
	session_audio_mode = AudioSettings.Mode.SILENT
	_stop_reading()
	_refresh_audio_section()
	_update_key_hint()
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
				b_tw.tween_property(btn, "modulate:a", 1.0, 0.18)
				b_tw.parallel().tween_property(btn, "scale", Vector2.ONE, 0.22)
				b_tw.tween_callback(UiFx.shine_sweep.bind(btn))

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
	_prefetch_speech()
	question_time_left = SECONDS_PER_SCORED_ITEM
	question_label.text = str(record.get("prompt", "Question unavailable"))
	question_panel.modulate.a = 0.0
	question_panel.position.x = 28.0
	var q_tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	q_tw.parallel().tween_property(question_panel, "modulate:a", 1.0, 0.28)
	q_tw.parallel().tween_property(question_panel, "position:x", 0.0, 0.32)
	var correct_idx := int(record.get("correct_index", -1))
	var answers: Array = record.get("answers", [])
	var current_correct_text: String = str(answers[correct_idx]) if correct_idx >= 0 and correct_idx < answers.size() else ""
	var question_table = record.get("reference_table", [])
	question_table_panel.visible = question_table is Array and not question_table.is_empty()
	if question_table_panel.visible:
		var table_layout := _table_preview_layout(question_table, 340.0 if _side_by_side() else 220.0)
		_table_natural_h = float(table_layout["scroll_height"])
		question_table_scroll.custom_minimum_size.y = _table_natural_h
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
	question_diagram_panel.visible = question_diagram_view.show_record(record)
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
	if NecReference.is_reference_seeking(str(record.get("prompt", ""))):
		# The stem asks WHICH table/article holds the rule — printing the article
		# hands over the answer, so pre-answer navigation stops at chapter level.
		chapter_hint_label.text = NecReference.chapter_only_path(NecReference.lookup_path(record))
	else:
		chapter_hint_label.text = AudioExplanationGenerator.redact_answer_spans(NecReference.lookup_path(record), current_correct_text)
	chapter_hint_label.visible = chapter_hint_label.text != ""
	lookup_box.visible = chapter_hint_label.visible
	formula_box.visible = question_formula_label.visible
	progress_label.text = "QUESTION %02d OF %02d" % [current_index + 1, order.size()]
	_update_score_badges()
	timer_label.text = "TOTAL " + _format_time(time_left) if timed_session else "UNTIMED"
	question_timer_label.text = "ITEM " + _format_time(question_time_left) if timed_session else ""
	question_timer_label.add_theme_color_override("font_color", AppTheme.SKY_400)
	timer_bar.visible = timed_session
	if timed_session:
		timer_bar.max_value = session_time_limit
		timer_bar.value = time_left
	_apply_exam_time_tint()

	for child in answers_box.get_children():
		child.queue_free()
	for i in answers.size():
		var card := AnswerCard.new()
		card.set_card_data(i, str(answers[i]))
		card.card_clicked.connect(_answer_selected)
		answers_box.add_child(card)
		UiFx.add_shine(card)
		card.animate_entrance(0.08 + float(i) * 0.07)
	_update_time_gauges()
	if is_instance_valid(results_visual):
		results_visual.visible = false

	feedback_panel.visible = false
	feedback_reference.visible = false
	feedback_table_scroll.visible = false
	feedback_table_note.visible = false
	next_button.visible = false
	info_label.visible = false
	next_button.text = "Next question" if current_index < order.size() - 1 else "Finish quiz"
	if is_instance_valid(dock_panel):
		dock_panel.visible = true
	exam_pills_row.visible = not ui_mobile
	feedback_scroll.visible = false
	_refresh_ref_column()
	_fit_begin()
	_schedule_auto_read()
	_update_key_hint()

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
	var graded := AudioSettings.grades_answers(session_audio_mode)
	if graded:
		var chapter := ChapterBars.chapter_of(str(record.get("article", "")))
		var tally: Array = chapter_stats.get(chapter, [0, 0])
		chapter_stats[chapter] = [int(tally[0]) + (1 if selected == correct else 0), int(tally[1]) + 1]

	if not graded:
		# Listen mode reviews, it does not test: no score, streak or missed list.
		feedback_title.text = "Answer"
		feedback_title.add_theme_color_override("font_color", AppTheme.SKY_400)
		feedback_body.text = "Correct answer: %s — %s" % [ANSWER_LETTERS[correct], correct_text]
		feedback_body.visible = true
	elif selected == -1:
		streak = 0
		feedback_title.text = "Time expired"
		feedback_title.add_theme_color_override("font_color", AppTheme.RED_400)
		feedback_body.text = "Correct answer: %s — %s" % [ANSWER_LETTERS[correct], correct_text]
		feedback_body.visible = true
		missed_questions.append({
			"index": current_index + 1,
			"prompt": str(record.get("prompt", "")),
			"selected": "Time expired",
			"correct": "%s — %s" % [ANSWER_LETTERS[correct], correct_text],
			"article": str(record.get("article", "General")),
			"article_title": str(record.get("article_title", "")),
			"tip_short": str(record.get("tip_short", record.get("gist", ""))),
			"record_index": record_index,
		})
	elif selected == correct:
		score += 1
		streak += 1
		feedback_title.text = "Correct"
		# The green card already shows the pick — a text echo of it is clutter.
		feedback_body.text = ""
		feedback_body.visible = false
		feedback_title.add_theme_color_override("font_color", AppTheme.EMERALD_400)
	else:
		streak = 0
		feedback_title.text = "Not quite"
		feedback_title.add_theme_color_override("font_color", AppTheme.RED_400)
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
			"tip_short": str(record.get("tip_short", record.get("gist", ""))),
			"record_index": record_index,
		})
	feedback_panel.visible = true
	feedback_panel.modulate.a = 0.0
	feedback_panel.pivot_offset = feedback_panel.size / 2.0
	feedback_panel.scale = Vector2(0.98, 0.98)
	var fb_tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	fb_tw.parallel().tween_property(feedback_panel, "modulate:a", 1.0, 0.16)
	fb_tw.parallel().tween_property(feedback_panel, "scale", Vector2.ONE, 0.2)

	question_table_panel.visible = false
	# The figure stays up: the explanation talks about it by its labels.
	question_diagram_view.reveal(correct)
	question_formula_label.visible = false
	# The box only follows the label on a resize, so hide it explicitly or an
	# empty frame is left behind on formula questions.
	formula_box.visible = false
	feedback_table_scroll.visible = false
	feedback_table_note.visible = false
	next_button.visible = true
	next_button.modulate.a = 0.0
	next_button.scale = Vector2(0.96, 0.96)
	next_button.pivot_offset = next_button.size / 2.0
	var nb_tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	nb_tw.parallel().tween_property(next_button, "modulate:a", 1.0, 0.18)
	nb_tw.parallel().tween_property(next_button, "scale", Vector2.ONE, 0.22)
	feedback_reference.text = NecReference.format_reference(record)
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
	_compact_answered(correct, selected)
	# Answering always stops the readout in progress. The rule then plays by
	# itself in Auto-read (unless "Also read the rule" is off) and in Listen;
	# Tap to hear keeps it behind the "Hear the rule" button.
	_stop_reading()
	want_teach = true
	if session_audio_mode == AudioSettings.Mode.LISTEN and not session_muted:
		# The loop advances by itself and the dock has Skip; a second
		# "Next question" button would just compete with it.
		next_button.visible = false
		_listen_enter(AudioSettings.ListenPhase.TEACH)
	elif not session_muted and AudioSettings.autoplays_teach(session_audio_mode, audio.auto_teach):
		_after_delay(0.6, _auto_read_teach)
	if ui_mobile:
		call_deferred("_scroll_to_verdict", correct)
	_update_key_hint()
	question_timer_label.text = "ITEM COMPLETED"
	_update_score_badges()
	_update_time_gauges()
	_play_answer_fx(cards, correct, selected)


## Phone: after answering, the green card and the feedback usually sit below
## the fold (a wrong pick near the top leaves only the red card in view).
## Glide so the correct card sits at the top of the viewport.
func _scroll_to_verdict(correct: int) -> void:
	var cards := answers_box.get_children()
	if correct < 0 or correct >= cards.size():
		return
	var scroll: ScrollContainer = null
	var n: Node = answers_box
	while n != null and not n is ScrollContainer:
		n = n.get_parent()
	scroll = n as ScrollContainer
	if scroll == null or scroll.get_child_count() == 0:
		return
	var content := scroll.get_child(0) as Control
	var card := cards[correct] as Control
	var target := int(card.global_position.y - content.global_position.y) - 8
	target = clampi(target, 0, maxi(0, int(content.size.y - scroll.size.y)))
	if target <= scroll.scroll_vertical:
		return
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(scroll, "scroll_vertical", target, 0.35)

func _update_score_badges() -> void:
	if is_instance_valid(streak_meter):
		streak_meter.set_streak(streak)
	if session_audio_mode == AudioSettings.Mode.LISTEN:
		score_label.text = "LISTEN MODE"
		score_label.add_theme_color_override("font_color", AppTheme.SKY_300)
		if is_instance_valid(pass_badge):
			pass_badge.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.BADGE_BLUE_BG, AppTheme.SKY_600, 1, 8))
		streak_label.text = "%d / %d REVIEWED" % [answered_count, session_length]
		streak_label.add_theme_color_override("font_color", AppTheme.SKY_300)
		return
	if answered_count == 0:
		score_label.text = "TARGET: 75%"
		score_label.add_theme_color_override("font_color", AppTheme.EMERALD_300)
		if is_instance_valid(pass_badge):
			pass_badge.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.BADGE_GREEN_BG, AppTheme.EMERALD_600, 1, 8))
		streak_label.text = "0 / %d ITEMS" % session_length
		streak_label.add_theme_color_override("font_color", AppTheme.SKY_300)
		return

	var pct: float = (float(score) / float(answered_count)) * 100.0
	var pct_int: int = roundi(pct)
	streak_label.text = "%d/%d (%d%%)" % [score, answered_count, pct_int]

	if pct >= 75.0:
		score_label.text = "PASSING: " + str(pct_int) + "%"
		score_label.add_theme_color_override("font_color", AppTheme.EMERALD_300)
		if is_instance_valid(pass_badge):
			pass_badge.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.BADGE_GREEN_BG, AppTheme.EMERALD_600, 1, 8))
		streak_label.add_theme_color_override("font_color", AppTheme.EMERALD_400)
	elif pct >= 60.0:
		score_label.text = "AT RISK: " + str(pct_int) + "%"
		score_label.add_theme_color_override("font_color", AppTheme.YELLOW_300)
		if is_instance_valid(pass_badge):
			pass_badge.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.BADGE_AMBER_BG, AppTheme.YELLOW_700, 1, 8))
		streak_label.add_theme_color_override("font_color", AppTheme.YELLOW_300)
	else:
		score_label.text = "BELOW 75%: " + str(pct_int) + "%"
		score_label.add_theme_color_override("font_color", AppTheme.ROSE_300)
		if is_instance_valid(pass_badge):
			pass_badge.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.BADGE_RED_BG, AppTheme.ROSE_800, 1, 8))
		streak_label.add_theme_color_override("font_color", AppTheme.ROSE_300)


func _append_answer_highlight(text: String, answer: String) -> bool:
	var match_info := SpeechText.find_answer_match(text, answer)
	if match_info.is_empty():
		info_label.add_text(text)
		return false
	var start := int(match_info["start"])
	var match_length := int(match_info["length"])
	info_label.add_text(text.substr(0, start))
	info_label.push_bgcolor(AppTheme.EMERALD_700)
	info_label.push_color(AppTheme.WHITE)
	info_label.push_bold()
	info_label.add_text(" " + text.substr(start, match_length) + " ")
	info_label.pop()
	info_label.pop()
	info_label.pop()
	info_label.add_text(text.substr(start + match_length))
	return true

## tip_short reads "<tip> Correct: B — <answer>. <note> Not A: <note> ...". When
## choice_notes lines up with the answers, render the tip sentence followed by one
## row per choice (correct first) instead of that single run-on paragraph.
## Returns true when the correct answer was shown.
func _append_tip_rows(record: Dictionary, tip: String) -> bool:
	var notes = record.get("choice_notes", [])
	var answers: Array = record.get("answers", [])
	var ci := int(record.get("correct_index", -1))
	var cut := tip.find(" Correct: ")
	if not (notes is Array) or notes.size() != answers.size() or ci < 0 or ci >= answers.size() or cut <= 0:
		info_label.add_text(tip)
		return false
	info_label.add_text(tip.substr(0, cut))
	var row_order: Array[int] = [ci]
	for i in answers.size():
		if i != ci:
			row_order.append(i)
	for i in row_order:
		var is_correct := i == ci
		info_label.add_text("\n")
		info_label.push_bgcolor(AppTheme.EMERALD_700 if is_correct else AppTheme.WRONG_HIGHLIGHT_BG)
		info_label.push_color(AppTheme.WHITE if is_correct else AppTheme.ROSE_200)
		info_label.push_bold()
		info_label.add_text(" %s %s " % ["✓" if is_correct else "✗", ANSWER_LETTERS[i]])
		info_label.pop()
		info_label.pop()
		info_label.pop()
		info_label.push_color(AppTheme.GREEN_50 if is_correct else AppTheme.SLATE_300)
		if is_correct:
			info_label.push_bold()
		info_label.add_text("  " + str(answers[i]))
		if is_correct:
			info_label.pop()
		info_label.pop()
		var note := str(notes[i]).strip_edges()
		if note != "":
			info_label.push_color(AppTheme.EMERALD_200 if is_correct else AppTheme.SLATE_400)
			info_label.add_text("  —  " + note)
			info_label.pop()
	return true

func _echoes_any(line: String, others: Array) -> bool:
	# True when line adds nothing over already-displayed text (declutter filter).
	for other in others:
		var o := str(other).strip_edges()
		if o != "" and AudioExplanationGenerator._is_duplicate_text(line, o):
			return true
	return false

func _append_provision_heading(text: String, heading_color: Color = AppTheme.SKY_300) -> void:
	info_label.push_color(heading_color)
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
			_append_provision_heading("MEMORY TIP — " + tip_title + "\n", AppTheme.AMBER_500)
		else:
			_append_provision_heading("MEMORY TIP\n", AppTheme.AMBER_500)
		highlighted = _append_tip_rows(record, tip) or highlighted
		info_label.add_text("\n\n")

	# --- CODE PROVISION section (NEC statutory text) ---
	_append_provision_heading("CODE PROVISION\n", AppTheme.EMERALD_400)
	if source_text != "":
		var heading_end := source_text.find("\n")
		if heading_end >= 0:
			info_label.push_color(AppTheme.BLUE_300)
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
		_append_provision_heading("WHAT THE CODE SAYS\n", AppTheme.SKY_400)
		var first_row := true
		for pair in render_lesson:
			var li: int = pair[0]
			var ln: String = pair[1]
			if li == _active_teach_line:
				# Amber highlight on the currently-spoken line
				if not first_row:
					info_label.add_text("\n")
				info_label.push_bgcolor(AppTheme.YELLOW_800)
				info_label.push_color(AppTheme.AMBER_100)
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
		_append_provision_heading("WORKED SOLUTION\n", AppTheme.YELLOW_300)
		highlighted = _append_answer_highlight(worked, correct_answer) or highlighted
	elif formula != "":
		info_label.add_text("\n\n")
		_append_provision_heading("METHOD & FORMULA\n", AppTheme.PURPLE_400)
		highlighted = _append_answer_highlight(formula, correct_answer) or highlighted
	if not highlighted and correct_answer != "":
		info_label.add_text("\n\n")
		_append_provision_heading("ANSWER DETAIL\n", AppTheme.EMERALD_400)
		_append_answer_highlight(correct_answer, correct_answer)
func _load_voice_catalog() -> void:
	voice_ids.clear()
	voice_tiers.clear()
	var file := FileAccess.open("res://data/voices.json", FileAccess.READ)
	if file == null:
		voice_ids["Andrew · Male · Warm"] = DEFAULT_VOICE_ID
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Array:
		for row in parsed:
			if row is Dictionary:
				var label := str(row.get("label", ""))
				voice_ids[label] = str(row.get("id", ""))
				voice_tiers[label] = str(row.get("tier", "classic"))

func _populate_voice_picker() -> void:
	# Desktop: cloud voices from voices.json. Mobile: REAL on-device voices —
	# the old code showed cloud voices on Android while silently speaking OS
	# voice #1 no matter what was picked.
	voice_picker.clear()
	if ui_mobile or not OS.has_feature("pc"):
		_populate_voice_picker_native()
	else:
		var default_idx := 0
		var last_tier := ""
		for voice_name in voice_ids:
			var tier := str(voice_tiers.get(voice_name, ""))
			if tier != last_tier and VOICE_TIER_HEADINGS.has(tier):
				voice_picker.add_separator(VOICE_TIER_HEADINGS[tier])
				last_tier = tier
			if str(voice_ids[voice_name]) == DEFAULT_VOICE_ID:
				default_idx = voice_picker.item_count
			voice_picker.add_item(voice_name)
		voice_picker.selected = default_idx
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
	_refresh_audio_section()
	_warm_speech_helper()
	_prefetch_speech()

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
	var who := _voice_fallback if _voice_fallback != "" else _voice_short()
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
	# The recorded voice ships with the app (every question, offline); device
	# voices are the fallback for anything it has no clip for.
	voice_ids[BUNDLED_VOICE_LABEL] = BUNDLED_VOICE_ID
	var seen := {}
	for pair in chosen:
		var label := "Device voice · " + _voice_display_label(str(pair[0]), str(pair[1]), str(pair[2]))
		if seen.has(label):
			label = "%s [%s]" % [label, str(pair[2])]
		seen[label] = true
		voice_ids[label] = str(pair[2])
	if chosen.is_empty():
		voice_ids["Device voice · System default"] = ""
	for label in voice_ids:
		voice_picker.add_item(label)
	voice_picker.selected = 0

func _selected_voice_id() -> String:
	var label := voice_picker.get_item_text(voice_picker.selected)
	var voice_id := str(voice_ids.get(label, ""))
	return voice_id.replace("Multilingual", "")

func _load_voice_choice() -> void:
	var config := ConfigFile.new()
	if config.load(voice_cfg_path) != OK:
		return
	var saved := str(config.get_value("speech", "voice", DEFAULT_VOICE_ID))
	# Before version 2 the mobile picker held only device voices, so a saved
	# device voice was never a choice against the recorded one.
	var mobile_picker := ui_mobile or not OS.has_feature("pc")
	if mobile_picker and int(config.get_value("speech", "version", 1)) < VOICE_CONFIG_VERSION:
		saved = DEFAULT_VOICE_ID
	for i in voice_picker.item_count:
		if str(voice_ids.get(voice_picker.get_item_text(i), "")) == saved:
			voice_picker.selected = i
			return

func _save_voice_choice() -> void:
	var config := ConfigFile.new()
	config.set_value("speech", "voice", _selected_voice_id())
	config.set_value("speech", "version", VOICE_CONFIG_VERSION)
	config.save(voice_cfg_path)

func _stop_reading() -> void:
	speak_generation += 1
	speak_busy = false
	# The helper keeps synthesizing into the cache; only playback detaches.
	_live_request = -1
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
		read_button.text = _idle_read_label()
		read_button.disabled = false
	_previewing = false
	if is_instance_valid(preview_button):
		preview_button.text = "Preview"

## Read-button text while nothing is playing. After answering in a mode that
## reads the rule by itself, the rule has just played (or is about to), so the
## button offers a replay rather than asking the learner to push for it.
func _idle_read_label() -> String:
	if not current_answered:
		return "Read question"
	if not session_muted and AudioSettings.autoplays_teach(session_audio_mode, audio.auto_teach):
		return "Replay rule"
	return "Hear the rule"

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

const BUNDLED_VOICE_ID := DEFAULT_VOICE_ID
const BUNDLED_VOICE_LABEL := "Andrew · Recorded (offline)"
const VOICE_CONFIG_VERSION := 2
## Edge output format every clip must be recorded in (src/speech/speak_question.py
## OUTPUT_FORMAT). A manifest row in any other format is stale.
const SPEECH_FORMAT := "audio-24khz-96kbitrate-mono-mp3"

## Bundled clips are imported resources: an exported build ships only the
## imported stream, not the raw .mp3, so res:// clips go through ResourceLoader.
## Cached clips in user:// are raw files.
func _clip_available(path: String) -> bool:
	if path.begins_with("res://"):
		return ResourceLoader.exists(path, "AudioStream")
	var clip := FileAccess.open(path, FileAccess.READ)
	if clip == null:
		return false
	var ok := clip.get_length() > 0
	clip.close()
	return ok

func _load_clip(path: String) -> AudioStream:
	if path.begins_with("res://"):
		return load(path) as AudioStream if ResourceLoader.exists(path, "AudioStream") else null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var stream := AudioStreamMP3.new()
	stream.data = file.get_buffer(file.get_length())
	file.close()
	return stream

func _bundled_speech_folder(safe_qid: String, voice_id: String, segments: Array) -> String:
	# Pre-generated default-voice clips shipped inside the app (tools/speech/pregenerate_speech.py).
	# Same neural voice as desktop, zero network, zero quota, exact clip sync.
	# The manifest comparison guarantees the bundle matches the CURRENT speech plan;
	# a stale bundle simply misses and falls through to live synthesis.
	if voice_id != BUNDLED_VOICE_ID or safe_qid == "":
		return ""
	var folder := "res://assets/speech".path_join(safe_qid + "__" + voice_id)
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
		if int(row.get("rules", 0)) != int(segments[i].get("rules", 0)):
			return 0
		if str(row.get("format", "")) != SPEECH_FORMAT:
			return 0
		if not _clip_available(folder.path_join(str(row.get("file", "")))):
			return 0
	return start

func _begin_reading(segments: Array) -> void:
	if segments.is_empty() or menu_overlay.visible:
		return

	var question_id := ""
	var record: Dictionary = {}
	if not order.is_empty() and current_index >= 0 and current_index < order.size():
		record = records[order[current_index]]
		question_id = str(record.get("id", ""))
	var safe_qid := _safe_speech_id(question_id)
	_voice_fallback = ""
	# Mobile defaults to the bundled recorded voice too; a device voice is only
	# used when that is picked or when no recorded clip matches.
	var bundle := _bundled_speech_folder(safe_qid, _selected_voice_id(), segments)
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
	if _speech_mobile():
		if _selected_voice_id() == BUNDLED_VOICE_ID:
			_voice_fallback = "Device voice (no recording)"
			push_warning("Speech: no recorded clip for %s, using the device voice." % safe_qid)
		_begin_native_tts(segments)
		return
	_save_voice_choice()
	# Always synthesize the whole question: "Hear the rule" is its tail, so one
	# cached folder serves the read, the rule, and every replay.
	_read_with_helper(safe_qid, SpeechText.speech_plan(record) if not record.is_empty() else segments)

## ui_mobile too: the mobile layout's picker lists OS voices, which edge-tts
## does not know.
func _speech_mobile() -> bool:
	return ui_mobile or OS.get_name() == "Android" or not OS.has_feature("pc")

func _safe_speech_id(question_id: String) -> String:
	var safe := question_id.replace("/", "_").replace("\\", "_")
	return safe if safe != "" else "item"

func _speech_cache_folder(safe_id: String, voice_id: String) -> String:
	return ProjectSettings.globalize_path(speech_cache_root).path_join(safe_id + "__" + voice_id)

## Desktop Edge voice: cached clips play at once; otherwise the warm helper
## synthesizes `plan` and each clip plays as soon as it lands.
func _read_with_helper(safe_id: String, plan: Array) -> void:
	speak_generation += 1
	var voice_id := _selected_voice_id()
	var folder := _speech_cache_folder(safe_id, voice_id)
	if _speech_cache_matches(folder, plan):
		_on_speech_ready(speak_generation, folder, 0, "cache")
		return
	var rid := speech_helper.request(folder, voice_id, plan, SpeechHelper.PRIO_LIVE)
	if rid < 0:
		_fallback_to_native(speech_helper.fail_reason)
		return
	_live_request = rid
	speech_queue.clear()
	for i in plan.size():
		var seg = plan[i]
		if seg is Dictionary and str(seg.get("text", "")).strip_edges() != "":
			speech_queue.append({
				"path": folder.path_join("%d.mp3" % i),
				"choice": int(seg.get("choice", -1)),
				"teach": bool(seg.get("teach", false)),
				"request": rid,
				"segment": i,
			})
	teach_from_index = -1
	for i in speech_queue.size():
		if bool(speech_queue[i]["teach"]):
			teach_from_index = i
			break
	speech_queue_index = teach_from_index if want_teach and teach_from_index >= 0 else 0
	read_button.text = "Stop"
	read_button.disabled = false
	_play_speech_clip()

func _on_helper_clip(request_id: int, index: int) -> void:
	if request_id != _live_request or not speak_busy:
		return
	if speech_queue_index < speech_queue.size() and int(speech_queue[speech_queue_index].get("segment", -1)) == index:
		speak_busy = false
		_play_speech_clip()

func _on_helper_failed(request_id: int, why: String) -> void:
	if request_id == _live_request:
		_fallback_to_native(why)

## The picked Edge voice cannot speak: say so, log why, read with the system voice.
func _fallback_to_native(why: String) -> void:
	var wanted := _voice_short()
	_live_request = -1
	speak_busy = false
	_halt_player()
	push_warning("Speech: %s unavailable, using the system voice. %s" % [wanted, why])
	_voice_fallback = "System voice (Edge unavailable)"
	if _previewing:
		_begin_native_tts([{"text": PREVIEW_TEXT, "choice": -1, "teach": false}])
		return
	if not order.is_empty() and current_index >= 0 and current_index < order.size():
		var fallback_record: Dictionary = records[order[current_index]]
		_begin_native_tts(SpeechText.teach_segments(fallback_record) if want_teach else SpeechText.speech_plan(fallback_record))
		return
	read_button.text = _idle_read_label()
	_set_read_status("")

## Edge voices other than the bundled one need the helper; start it early so
## its ~3 s of imports are done before the first Read.
func _warm_speech_helper() -> void:
	if speech_helper == null or _speech_mobile() or not is_instance_valid(voice_picker):
		return
	if _selected_voice_id() != BUNDLED_VOICE_ID:
		speech_helper.start()

## Synthesizes the current and next question in the background (whole plans,
## rule included; the teach gate in _play_speech_clip still holds the rule
## until the answer is in), so Read and Next start from the cache.
func _prefetch_speech() -> void:
	if speech_helper == null or session_muted or _speech_mobile() or order.is_empty():
		return
	var voice_id := _selected_voice_id()
	for idx in [current_index, current_index + 1]:
		if idx < 0 or idx >= order.size():
			continue
		var record: Dictionary = records[order[idx]]
		var safe_id := _safe_speech_id(str(record.get("id", "")))
		var plan: Array = SpeechText.speech_plan(record)
		if _bundled_speech_folder(safe_id, voice_id, plan) != "":
			continue
		var folder := _speech_cache_folder(safe_id, voice_id)
		if speech_helper.busy_request_for(folder) >= 0 or _speech_cache_matches(folder, plan):
			continue
		if speech_helper.request(folder, voice_id, plan, SpeechHelper.PRIO_PREFETCH) < 0:
			return


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
	# The bundled recorded voice is not an OS voice: fall through to a device one.
	if is_instance_valid(voice_picker) and voice_picker.item_count > 0:
		var label := voice_picker.get_item_text(voice_picker.selected)
		if voice_ids.has(label) and str(voice_ids[label]) != BUNDLED_VOICE_ID:
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
	# An OS-side cancel (audio focus, engine hiccup) must not stall hands-free play.
	_notify_playback_complete()

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
		_notify_playback_complete()
		return

	var seg: Dictionary = segments[seg_idx]
	var text: String = str(seg.get("text", "")).strip_edges()
	var choice: int = int(seg.get("choice", -1))
	var is_teach: bool = bool(seg.get("teach", false))

	if not want_teach and is_teach:
		_stop_reading()
		_notify_playback_complete()
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
	# Volume 100: Godot's default of 50 made the native voice half as loud as the
	# desktop clips (Android maps it to a 0.5 TextToSpeech volume).
	DisplayServer.tts_speak(text, _native_voice_id, 100, 1.0, audio.speed, seg_idx + 1, true)
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
		# A clip rendered under older speech rules is stale even if the text
		# happens to match (the rules can change more than the text).
		if int(row.get("rules", 0)) != int(wanted[i].get("rules", 0)):
			return false
		if str(row.get("format", "")) != SPEECH_FORMAT:
			return false
		if not _clip_available(folder.path_join(str(row.get("file", "")))):
			return false
	return true

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
		_fallback_to_native(output)
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
		read_button.text = _idle_read_label()
		_notify_playback_complete()
		return
	read_button.text = "Stop"
	_play_speech_clip()

func _play_speech_clip() -> void:
	_clear_speech_highlight()
	if speech_queue_index >= speech_queue.size():
		read_button.text = _idle_read_label()
		_notify_playback_complete()
		return
	var clip: Dictionary = speech_queue[speech_queue_index]
	var choice := int(clip.get("choice", -1))
	var is_teach := bool(clip.get("teach", false))
	# The teach gate lives HERE, in the function that plays, so no caller and no
	# skip path can hand it a clip that narrates the answer before answering.
	# It used to be checked only by the callers and in the missing-file branch.
	if is_teach and not want_teach:
		_clear_speech_highlight()
		if read_button:
			read_button.text = _idle_read_label()
			read_button.disabled = false
		_notify_playback_complete()
		return

	if is_instance_valid(dock_visualizer):
		dock_visualizer.visible = true
		dock_visualizer.set_active(true)

	# Streaming from the helper: this clip has not landed yet. Wait for it
	# (_on_helper_clip resumes); Stop, skip and Next clear _live_request.
	var request_id := int(clip.get("request", -1))
	if request_id >= 0 and not speech_helper.has_clip(request_id, int(clip.get("segment", -1))):
		speak_busy = true
		_set_read_status("PREPARING %s…" % _voice_short().to_upper())
		return
	speak_busy = false

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
	var stream := _load_clip(str(clip.get("path", "")))
	if stream == null:
		# Skip an unplayable clip; the recursion re-enters the teach gate above.
		speech_queue_index += 1
		_play_speech_clip()
		return
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
		read_button.text = _idle_read_label()
	_notify_playback_complete()

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
			_question_stem_glow_style.bg_color = AppTheme.STEM_GLOW_BG
			_question_stem_glow_style.border_color = AppTheme.SKY_400
			_question_stem_glow_style.set_border_width_all(3)
			_question_stem_glow_style.set_corner_radius_all(14)
			_question_stem_glow_style.shadow_color = Color(0.22, 0.74, 0.97, 0.65)
			_question_stem_glow_style.shadow_size = 20
		question_panel.add_theme_stylebox_override("panel", _question_stem_glow_style)
	else:
		question_panel.add_theme_stylebox_override("panel", _question_panel_style())


func _apply_exam_time_tint() -> void:
	var label_col := AppTheme.SLATE_50
	var bar_col := AppTheme.SKY_400
	if timed_session and time_left <= 300:
		label_col = AppTheme.RED_400
		bar_col = AppTheme.RED_500
	elif timed_session and time_left <= 900:
		label_col = AppTheme.AMBER_400
		bar_col = AppTheme.AMBER_500
	timer_label.add_theme_color_override("font_color", label_col)
	timer_bar.modulate = bar_col

func _tick_timer() -> void:
	if not timed_session:
		return
	time_left -= 1
	timer_label.text = "TOTAL " + _format_time(max(time_left, 0))
	timer_bar.value = max(time_left, 0)
	_apply_exam_time_tint()
	if not current_answered and not speak_busy and not reader.playing:
		question_time_left -= 1
		question_timer_label.text = "ITEM " + _format_time(max(question_time_left, 0))
		if question_time_left <= 30:
			question_timer_label.add_theme_color_override("font_color", AppTheme.RED_400)
			# Subtle warning pulse
			question_timer_label.pivot_offset = question_timer_label.size / 2.0
			var p_tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			p_tw.tween_property(question_timer_label, "scale", Vector2(1.08, 1.08), 0.1)
			p_tw.tween_property(question_timer_label, "scale", Vector2.ONE, 0.14)
		elif question_time_left <= 60:
			question_timer_label.add_theme_color_override("font_color", AppTheme.AMBER_400)
		else:
			question_timer_label.add_theme_color_override("font_color", AppTheme.SKY_400)
	if Sfx.time_warning(timed_session, time_left):
		_sfx("warning")
	_update_time_gauges()
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
	_clear_confetti()
	question_label.text = "Official Examination Report"
	chapter_hint_label.visible = false
	lookup_box.visible = false
	formula_box.visible = false
	question_table_panel.visible = false
	question_diagram_panel.visible = false
	question_formula_label.visible = false
	exam_label.text = "STATE ELECTRICAL DIVISION  •  NEBRASKA (NSED / PSI)"
	article_label.text = "CANDIDATE PERFORMANCE SUMMARY  •  NEC 2023 STANDARDS"
	if is_instance_valid(question_hint_row):
		question_hint_row.visible = true
	exam_pills_row.visible = not ui_mobile
	timer_bar.visible = false
	_refresh_ref_column()
	feedback_scroll.visible = true
	feedback_scroll.scroll_vertical = 0
	_fit_apply(0)
	_auto_token += 1
	if is_instance_valid(_listen_timer):
		_listen_timer.stop()
	listen_phase = AudioSettings.ListenPhase.IDLE
	listen_paused = false
	_refresh_dock_audio()
	# Quiz-only chrome would contradict the report ("QUESTION 01 OF 10",
	# "Hear the rule" for a question no longer on screen, a second menu button).
	if ui_mobile:
		progress_label.text = "COMPLETE  •  %d / %d" % [answered_count, order.size()]
	else:
		progress_label.text = "SESSION COMPLETE  •  %d OF %d ANSWERED" % [answered_count, order.size()]
	question_timer_label.text = "REVIEW"
	question_timer_label.add_theme_color_override("font_color", AppTheme.SKY_400)
	if is_instance_valid(dock_panel):
		dock_panel.visible = false
	if session_audio_mode == AudioSettings.Mode.LISTEN:
		_show_listen_results()
		_update_key_hint()
		return
	var accuracy := 100.0 * float(score) / maxf(1.0, float(answered_count))
	var passed := accuracy >= PASS_PERCENT
	if passed:
		score_label.text = "RESULT: PASSED"
		score_label.add_theme_color_override("font_color", AppTheme.EMERALD_300)
		if is_instance_valid(pass_badge):
			pass_badge.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.BADGE_GREEN_BG, AppTheme.EMERALD_600, 1, 8))
	else:
		score_label.text = "RESULT: DID NOT PASS"
		score_label.add_theme_color_override("font_color", AppTheme.ROSE_300)
		if is_instance_valid(pass_badge):
			pass_badge.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.BADGE_RED_BG, AppTheme.ROSE_800, 1, 8))
	streak_label.text = "FINAL: %d/%d (%d%%)" % [score, answered_count, roundi(accuracy)]
	for child in answers_box.get_children():
		child.queue_free()
	feedback_panel.visible = true
	feedback_reference.visible = false
	if passed:
		feedback_title.text = "EXAMINATION RESULT: PASS"
		feedback_title.add_theme_color_override("font_color", AppTheme.EMERALD_400)
	else:
		feedback_title.text = "EXAMINATION RESULT: DID NOT PASS"
		feedback_title.add_theme_color_override("font_color", AppTheme.RED_400)
	
	# The gauge and the title already state the percentage and the verdict.
	var summary_text := "%d of %d correct  •  %d%% needed to pass  •  %s" % [
		score, answered_count, PASS_PERCENT,
		"%d missed item%s to review below" % [missed_questions.size(), "" if missed_questions.size() == 1 else "s"] if not missed_questions.is_empty() else "no misses"
	]
	# The results screen reuses this label after it may have been hidden by a "Correct" verdict.
	feedback_body.text = summary_text
	feedback_body.visible = true
	_show_results_visual(accuracy, passed)

	info_label.clear()
	if missed_questions.is_empty():
		_append_provision_heading("PERFECT SCORE ACHIEVED\n", AppTheme.EMERALD_400)
		info_label.add_text("Congratulations! You answered 100% of questions correctly. You have demonstrated full mastery of these NEC 2023 provisions.")
	else:
		_append_provision_heading("AREAS FOR TARGETED CODE STUDY (%d FAILED ITEMS)\n" % missed_questions.size(), AppTheme.RED_400)
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

			_append_provision_heading("ITEM #%d  •  NEC %s%s\n" % [num, article, " — " + art_title if art_title != "" else ""], AppTheme.SKY_300)
			info_label.push_color(AppTheme.SLATE_200)
			info_label.add_text("Question: %s\n" % prompt)
			info_label.pop()
			
			info_label.push_color(AppTheme.RED_300)
			info_label.add_text("Your answer:  %s\n" % selected)
			info_label.pop()
			
			info_label.push_color(AppTheme.GREEN_300)
			info_label.push_bold()
			info_label.add_text("Correct NEC answer:  %s\n" % correct)
			info_label.pop()
			info_label.pop()

			if tip != "":
				var ri := int(item.get("record_index", -1))
				if ri >= 0 and ri < records.size():
					_append_provision_heading("Code key:  ", AppTheme.BLUE_300)
					_append_tip_rows(records[ri], tip)
					info_label.add_text("\n")
				else:
					info_label.push_color(AppTheme.BLUE_300)
					info_label.add_text("Code Key:  %s\n" % tip)
					info_label.pop()

			info_label.add_text("\n")

	info_label.visible = true
	feedback_table_scroll.visible = false
	feedback_table_note.visible = false
	next_button.text = "Return to Main Menu"
	next_button.visible = true
	next_button.disabled = false
	_update_key_hint()

func _show_listen_results() -> void:
	question_label.text = "Listening Session Summary"
	article_label.text = "HANDS-FREE REVIEW  •  NEC 2023 STANDARDS"
	_update_score_badges()
	for child in answers_box.get_children():
		child.queue_free()
	if is_instance_valid(results_visual):
		results_visual.visible = false
	feedback_panel.visible = true
	feedback_reference.visible = false
	feedback_title.text = "LISTENING SESSION COMPLETE"
	feedback_title.add_theme_color_override("font_color", AppTheme.SKY_400)
	feedback_body.text = "Reviewed %d of %d questions hands-free.\nListen mode is not graded — run a drill in Tap or Auto-read mode to test yourself." % [answered_count, order.size()]
	feedback_body.visible = true
	info_label.clear()
	info_label.visible = false
	feedback_table_scroll.visible = false
	feedback_table_note.visible = false
	feedback_scroll.visible = false
	next_button.text = "Return to Main Menu"
	next_button.visible = true
	next_button.disabled = false

func _show_results_visual(accuracy: float, passed: bool) -> void:
	if not is_instance_valid(results_visual):
		results_visual = VBoxContainer.new() if ui_mobile else HBoxContainer.new()
		results_visual.add_theme_constant_override("separation", 18)
		result_gauge = ResultGauge.new()
		result_gauge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		result_gauge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		results_visual.add_child(result_gauge)
		chapter_bars = ChapterBars.new()
		chapter_bars.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		results_visual.add_child(chapter_bars)
		var column := feedback_body.get_parent()
		column.add_child(results_visual)
		column.move_child(results_visual, feedback_body.get_index() + 1)
	results_visual.visible = true
	result_gauge.play(accuracy, float(PASS_PERCENT))
	chapter_bars.set_rows(ChapterBars.rows_from_stats(chapter_stats))
	UiFx.glow_pulse(feedback_panel, UiFx.EMERALD if passed else UiFx.RED, 30, 1.2)
	_sfx(Sfx.result_sound(passed))
	_results_seq += 1
	if passed:
		get_tree().create_timer(1.1).timeout.connect(_launch_confetti.bind(_results_seq))

func _launch_confetti(seq: int) -> void:
	if seq == _results_seq and is_instance_valid(results_visual) and results_visual.visible:
		UiFx.confetti(fx_layer)

func _clear_confetti() -> void:
	_results_seq += 1
	if not is_instance_valid(fx_layer):
		return
	for child in fx_layer.get_children():
		if child is CPUParticles2D:
			child.queue_free()

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
	if is_instance_valid(question_diagram_view) and question_diagram_view.is_zoomed():
		question_diagram_view.close_zoom()
		return
	if session_audio_mode == AudioSettings.Mode.LISTEN and listen_phase != AudioSettings.ListenPhase.IDLE \
			and not listen_paused and not menu_overlay.visible:
		_toggle_listen_pause()
		return
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
		if session_audio_mode == AudioSettings.Mode.LISTEN and next_button.text != "Return to Main Menu":
			if key == KEY_SPACE:
				_toggle_listen_pause()
				get_viewport().set_input_as_handled()
				return
			if key == KEY_RIGHT or key == KEY_ENTER:
				_listen_skip()
				get_viewport().set_input_as_handled()
				return
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
