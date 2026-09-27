class_name Main
extends Control

const ANSWER_LETTERS := QuizSession.ANSWER_LETTERS
const SESSION_LENGTH := QuizSession.SESSION_LENGTH
const EXAM_NAME := "NE JOURNEYMAN ELECTRICIAN"
const EXAM_SCORED_ITEMS := QuizSession.EXAM_SCORED_ITEMS
const EXAM_MINUTES := QuizSession.EXAM_MINUTES
const PASS_PERCENT := QuizSession.PASS_PERCENT
const SECONDS_PER_SCORED_ITEM := QuizSession.SECONDS_PER_SCORED_ITEM
const SESSION_TIME_SECONDS := QuizSession.SESSION_TIME_SECONDS
const SpeechText = preload("res://src/speech/speech_text.gd")
const BUNDLED_VOICE_ID := VoiceCatalog.BUNDLED_VOICE_ID
const BUNDLED_VOICE_LABEL := VoiceCatalog.BUNDLED_VOICE_LABEL
const PREVIEW_TEXT := SpeechController.PREVIEW_TEXT
const PREVIEW_ID := SpeechController.PREVIEW_ID

var session := QuizSession.new()
# The session's fields under their old names: the harness, tests and snapshot
# tools read and assign these on main.
var records: Array:
	get: return session.records
	set(v): session.records = v
var order: Array[int]:
	get: return session.order
	set(v): session.order = v
var current_index: int:
	get: return session.current_index
	set(v): session.current_index = v
var score: int:
	get: return session.score
	set(v): session.score = v
var streak: int:
	get: return session.streak
	set(v): session.streak = v
var answered_count: int:
	get: return session.answered_count
	set(v): session.answered_count = v
var current_answered: bool:
	get: return session.current_answered
	set(v): session.current_answered = v
var missed_questions: Array[Dictionary]:
	get: return session.missed_questions
	set(v): session.missed_questions = v
var chapter_stats: Dictionary:
	get: return session.chapter_stats
	set(v): session.chapter_stats = v
var time_left: int:
	get: return session.time_left
	set(v): session.time_left = v
var session_length: int:
	get: return session.session_length
	set(v): session.session_length = v
var session_time_limit: int:
	get: return session.session_time_limit
	set(v): session.session_time_limit = v
var timed_session: bool:
	get: return session.timed_session
	set(v): session.timed_session = v
var session_name: String:
	get: return session.session_name
	set(v): session.session_name = v
var question_time_left: int:
	get: return session.question_time_left
	set(v): session.question_time_left = v
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
var speech := SpeechController.new()
# Speech state under its old names, for the harness and tests.
var reader: AudioStreamPlayer:
	get: return speech.reader
	set(v): speech.reader = v
var speak_thread: Thread:
	get: return speech.speak_thread
	set(v): speech.speak_thread = v
var speak_generation: int:
	get: return speech.speak_generation
	set(v): speech.speak_generation = v
var speak_busy: bool:
	get: return speech.speak_busy
	set(v): speech.speak_busy = v
var speech_helper: SpeechHelper:
	get: return speech.speech_helper
	set(v): speech.speech_helper = v
var speech_cache_root: String:
	get: return speech.speech_cache_root
	set(v): speech.speech_cache_root = v
var _live_request: int:
	get: return speech._live_request
	set(v): speech._live_request = v
var _voice_fallback: String:
	get: return speech._voice_fallback
	set(v): speech._voice_fallback = v
var speech_queue: Array:
	get: return speech.speech_queue
	set(v): speech.speech_queue = v
var speech_queue_index: int:
	get: return speech.speech_queue_index
	set(v): speech.speech_queue_index = v
var teach_from_index: int:
	get: return speech.teach_from_index
	set(v): speech.teach_from_index = v
var want_teach: bool:
	get: return speech.want_teach
	set(v): speech.want_teach = v
var voice_ids: Dictionary:
	get: return speech.voice_ids
	set(v): speech.voice_ids = v
var voice_cfg_path: String:
	get: return speech.voice_cfg_path
	set(v): speech.voice_cfg_path = v
var prompt_voice_badge: PanelContainer
var main_margin: MarginContainer
var menu_center_box: MarginContainer
var menu_overlay: Control
var menu_panel: PanelContainer
var menu_mode_buttons: Array[Button] = []

# Study audio (menu "Audio & Voice" section + compact quiz dock controls)
var audio := AudioSettings.new()
var audio_cfg_path := AudioSettings.PATH
var session_audio_mode: int = AudioSettings.Mode.SILENT
var session_muted := true
var listen_phase: int = AudioSettings.ListenPhase.IDLE
var listen_paused := false
var _listen_countdown := 0
var _listen_timer: Timer
var _auto_token := 0  # bumps invalidate pending auto-read / listen timers
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
var fit := FitController.new()

var pause_button: Button
var skip_button: Button

# Reading highlight state
var info_panel := InfoPanelRenderer.new()
var _question_stem_glow_style: StyleBoxFlat = null  # cached glow style for question panel
var fx_layer: Control
var streak_meter: StreakMeter
var exam_gauge: TimeGauge
var pace_gauge: TimeGauge
var results_visual: BoxContainer
var result_gauge: ResultGauge
var chapter_bars: ChapterBars
var sfx: Sfx
var sfx_level_buttons: Array[Button] = []  # Off, then one per AudioSettings.SFX_LEVEL_TITLES

func _init() -> void:
	speech.host = self
	fit.host = self

func _exit_tree() -> void:
	# The TTS worker runs on speak_thread. Destroying the node while that thread is
	# still inside OS.execute() leaves Godot printing "Thread object is being
	# destroyed without its completion having been realized" and can tear the
	# thread down mid-write. Join it before the node goes away.
	speech._join_speak_thread()

func _ready() -> void:
	speech._load_voice_catalog()
	audio.load_from(audio_cfg_path)
	ui_mobile = "--mobile-ui" in OS.get_cmdline_args() or "--mobile-ui" in OS.get_cmdline_user_args() or OS.get_name() in ["Android", "iOS"]
	speech.speech_helper = SpeechHelper.new()
	speech.speech_helper.name = "SpeechHelper"
	add_child(speech.speech_helper)
	speech.speech_helper.clip_ready.connect(speech._on_helper_clip)
	speech.speech_helper.request_failed.connect(speech._on_helper_failed)
	_build_ui()
	info_panel.label = info_label
	speech._warm_speech_helper()
	QuizFx.attach(self)
	_polish_controls()
	_apply_touch_filters()
	_apply_safe_area()
	# OS voices can arrive late on mobile: silently refresh the picker a few
	# seconds after launch so the first Read already offers real voices.
	if ui_mobile or not OS.has_feature("pc"):
		get_tree().create_timer(4.0).timeout.connect(speech._refresh_native_voices)
	get_viewport().size_changed.connect(_apply_safe_area)
	get_viewport().size_changed.connect(fit.on_viewport_resized)
	fit.apply_answers_row_layout()
	timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_tick_timer)
	add_child(timer)
	speech.reader = AudioStreamPlayer.new()
	speech.reader.finished.connect(speech._on_reader_finished)
	add_child(speech.reader)
	speech._setup_speech_bus()
	_setup_sfx()
	_listen_timer = Timer.new()
	_listen_timer.wait_time = 1.0
	_listen_timer.timeout.connect(_on_listen_tick)
	add_child(_listen_timer)
	AudioSection.refresh(self)
	_refresh_dock_audio()
	records = BankLoader.load_records()
	if records.is_empty():
		_show_error("Question bank could not be loaded.")
	else:
		_show_menu()

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
	feedback_scroll.custom_minimum_size = Vector2(0, fit.feedback_min_h())
	column.add_child(feedback_scroll)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 10 if ui_mobile else 8)
	feedback_scroll.add_child(detail)
	return detail

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
	session_audio_mode = AudioSettings.session_mode(audio.mode, mode_name == "Full Journeyman Exam")
	session_muted = AudioSettings.starts_muted(session_audio_mode)
	listen_phase = AudioSettings.ListenPhase.IDLE
	listen_paused = false
	var listening := session_audio_mode == AudioSettings.Mode.LISTEN
	session.begin(question_count, time_limit, timed and not listening, mode_name + (" · Listen" if listening else ""))
	_refresh_dock_audio()
	if timed_session:
		timer.start()
	else:
		timer.stop()
	speech._stop_reading()
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

func _toggle_audio_section() -> void:
	audio_expanded = not audio_expanded
	AudioSection.refresh(self)

func _on_audio_mode_picked(m: int) -> void:
	audio.mode = AudioSettings.sanitize_mode(m)
	if speech._previewing and audio.mode == AudioSettings.Mode.SILENT:
		speech._stop_reading()
	audio.save_to(audio_cfg_path)
	AudioSection.refresh(self)

func _on_audio_speed_picked(s: float) -> void:
	audio.speed = AudioSettings.sanitize_speed(s)
	audio.save_to(audio_cfg_path)
	speech._apply_speed()
	AudioSection.refresh(self)

func _on_audio_pause_picked(p: int) -> void:
	audio.think_pause = AudioSettings.sanitize_pause(p)
	audio.save_to(audio_cfg_path)
	AudioSection.refresh(self)

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
	AudioSection.refresh(self)
	# Let the learner hear the new level on the sound they'll hear most.
	_sfx("correct")

func _setup_sfx() -> void:
	sfx = Sfx.new()
	sfx.name = "Sfx"
	add_child(sfx)
	sfx.setup()
	sfx.voice_active = func() -> bool:
		return (speech.reader != null and speech.reader.playing) or speech.speak_busy or DisplayServer.tts_is_speaking()
	_apply_sfx_settings()

func _apply_sfx_settings() -> void:
	if sfx != null:
		sfx.apply_settings(audio.sfx_enabled, AudioSettings.sfx_bus_db(audio.sfx_level))

func _sfx(id: String) -> void:
	if sfx != null and id != "":
		sfx.play(id)

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
		speech._stop_reading()
	else:
		speech._prefetch_speech()
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
	if speech.reader.playing or speech.speak_busy or DisplayServer.tts_is_speaking():
		return
	speech._begin_reading(SpeechText.speech_plan(records[order[current_index]]))

func _auto_read_teach() -> void:
	if not current_answered or menu_overlay.visible or order.is_empty() or listen_paused:
		return
	if speech.reader.playing or speech.speak_busy or DisplayServer.tts_is_speaking():
		return
	speech.want_teach = true
	speech._begin_reading(SpeechText.teach_segments(records[order[current_index]]))

func _listen_enter(phase: int) -> void:
	listen_phase = phase
	match phase:
		AudioSettings.ListenPhase.QUESTION:
			_listen_timer.stop()
			speech._set_read_status("LISTEN MODE · QUESTION %d OF %d" % [current_index + 1, order.size()])
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
		speech._set_read_status("THINK IT OVER · ANSWER IN %d s" % _listen_countdown)
	elif listen_phase == AudioSettings.ListenPhase.GAP:
		var last := current_index >= order.size() - 1
		speech._set_read_status(("RESULTS IN %d s" if last else "NEXT QUESTION IN %d s") % _listen_countdown)

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
		speech._stop_reading()
		speech._set_read_status("PAUSED · TAP RESUME TO CONTINUE")
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
	speech._stop_reading()
	_next_question()

## Natural end of a readout (queue done or stopped at the teach gate), as
## opposed to the user pressing Stop. Drives the hands-free loop.
func _notify_playback_complete() -> void:
	call_deferred("_on_playback_complete", speech.speak_generation)

func _on_playback_complete(generation: int) -> void:
	if generation != speech.speak_generation:
		return
	if speech._previewing:
		speech._previewing = false
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
	ResultsView.clear_confetti(self)
	if is_instance_valid(_listen_timer):
		_listen_timer.stop()
	listen_phase = AudioSettings.ListenPhase.IDLE
	listen_paused = false
	session_audio_mode = AudioSettings.Mode.SILENT
	speech._stop_reading()
	AudioSection.refresh(self)
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
	var record := session.current_record()
	session.start_question()
	speech._stop_reading()
	speech._prefetch_speech()
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
		var table_layout := _table_preview_layout(question_table, 340.0 if fit.side_by_side() else 220.0)
		fit.table_natural_h = float(table_layout["scroll_height"])
		question_table_scroll.custom_minimum_size.y = fit.table_natural_h
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
	QuizFx.update_time_gauges(self)
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
	fit.refresh_ref_column()
	fit.begin()
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
	var result := session.submit(selected, AudioSettings.grades_answers(session_audio_mode))
	if result.is_empty():
		return
	var record: Dictionary = result["record"]
	var correct: int = result["correct"]
	var correct_text: String = result["correct_text"]
	var cards := answers_box.get_children()
	for i in cards.size():
		var card = cards[i]
		if i == correct:
			card.set_state(AnswerCard.State.CORRECT)
		elif i == selected:
			card.set_state(AnswerCard.State.WRONG)
		else:
			card.set_eliminated()

	match result["verdict"]:
		QuizSession.Verdict.REVIEWED:
			# Listen mode reviews, it does not test: no score, streak or missed list.
			feedback_title.text = "Answer"
			feedback_title.add_theme_color_override("font_color", AppTheme.SKY_400)
			feedback_body.text = "Correct answer: %s — %s" % [ANSWER_LETTERS[correct], correct_text]
			feedback_body.visible = true
		QuizSession.Verdict.TIMED_OUT:
			feedback_title.text = "Time expired"
			feedback_title.add_theme_color_override("font_color", AppTheme.RED_400)
			feedback_body.text = "Correct answer: %s — %s" % [ANSWER_LETTERS[correct], correct_text]
			feedback_body.visible = true
		QuizSession.Verdict.CORRECT:
			feedback_title.text = "Correct"
			# The green card already shows the pick — a text echo of it is clutter.
			feedback_body.text = ""
			feedback_body.visible = false
			feedback_title.add_theme_color_override("font_color", AppTheme.EMERALD_400)
		QuizSession.Verdict.WRONG:
			feedback_title.text = "Not quite"
			feedback_title.add_theme_color_override("font_color", AppTheme.RED_400)
			# One verdict line: your pick is already red on its card, no need to restate it.
			feedback_body.text = "Correct answer: %s — %s" % [ANSWER_LETTERS[correct], correct_text]
			feedback_body.visible = true
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
	info_panel.show(record, correct_text, table_highlighted)
	info_label.visible = true
	fit.compact_answered(correct, selected)
	# Answering always stops the readout in progress. The rule then plays by
	# itself in Auto-read (unless "Also read the rule" is off) and in Listen;
	# Tap to hear keeps it behind the "Hear the rule" button.
	speech._stop_reading()
	speech.want_teach = true
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
	QuizFx.update_time_gauges(self)
	QuizFx.play_answer(self, cards, correct, selected)


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


# Speech entry points under their old names, for the harness and tests.
func _status_with_voice(base: String) -> String: return speech._status_with_voice(base)
func _populate_voice_picker_native() -> void: speech._populate_voice_picker_native()
func _selected_voice_id() -> String: return speech._selected_voice_id()
func _stop_reading() -> void: speech._stop_reading()
func _idle_read_label() -> String: return speech._idle_read_label()
func _toggle_read() -> void: speech._toggle_read()
func _clip_available(path: String) -> bool: return speech._clip_available(path)
func _load_clip(path: String) -> AudioStream: return speech._load_clip(path)
func _bundled_speech_folder(safe_qid: String, voice_id: String, segments: Array) -> String: return speech._bundled_speech_folder(safe_qid, voice_id, segments)
func _begin_reading(segments: Array) -> void: speech._begin_reading(segments)
func _safe_speech_id(question_id: String) -> String: return speech._safe_speech_id(question_id)
func _speech_cache_folder(safe_id: String, voice_id: String) -> String: return speech._speech_cache_folder(safe_id, voice_id)
func _pick_native_voice() -> String: return speech._pick_native_voice()
func _speech_cache_matches(folder: String, segments: Array) -> bool: return speech._speech_cache_matches(folder, segments)
func _on_speech_ready(generation: int, folder: String, code: int, output: String, start_index: int = 0) -> void: speech._on_speech_ready(generation, folder, code, output, start_index)
func _play_speech_clip() -> void: speech._play_speech_clip()
func _on_reader_finished() -> void: speech._on_reader_finished()
func _halt_player() -> void: speech._halt_player()

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
	if info_panel.active_teach_line >= 0:
		info_panel.active_teach_line = -1
		if is_instance_valid(info_label) and info_label.visible and info_panel.has_record():
			info_panel.render()
	# Remove question stem glow
	_set_question_stem_glow(false)
	speech._set_read_status("")


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
	var tick := session.tick(not speech.speak_busy and not speech.reader.playing)
	timer_label.text = "TOTAL " + _format_time(max(time_left, 0))
	timer_bar.value = max(time_left, 0)
	_apply_exam_time_tint()
	if tick["item_ticked"]:
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
	QuizFx.update_time_gauges(self)
	match tick["action"]:
		QuizSession.Tick.TIME_OUT:
			_answer_selected(-1)
		QuizSession.Tick.STOP_CLOCK:
			timer.stop()

func _format_time(seconds: int) -> String:
	return "%02d:%02d" % [seconds / 60, seconds % 60]

func _next_question() -> void:
	if session.advance():
		_show_question()
	else:
		ResultsView.show(self)

func _show_results() -> void:
	ResultsView.show(self)

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
	if speech.reader != null and speech.reader.playing or speech.speak_busy or DisplayServer.tts_is_speaking():
		speech._stop_reading()
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
