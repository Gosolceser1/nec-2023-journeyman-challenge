class_name Main
extends Control

const ANSWER_LETTERS := QuizSession.ANSWER_LETTERS
const SESSION_LENGTH := QuizSession.SESSION_LENGTH
## Session name of the full timed exam; the results report keys off
## session.session_simulation, not this text.
const SIMULATION_NAME := "Full Journeyman Exam"
const SpeechText = preload("res://src/speech/speech_text.gd")
static var BUNDLED_VOICE_ID: String = VoiceCatalog.BUNDLED_VOICE_ID
static var BUNDLED_VOICE_LABEL: String = VoiceCatalog.BUNDLED_VOICE_LABEL
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
var question_label: RichTextLabel
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
var index_hint_label: Label
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
var feedback_icon: TextureRect
var feedback_body: Label
var feedback_reference: Label
var feedback_table_scroll: ScrollContainer
var feedback_table_grid: GridContainer
var feedback_table_note: Label
var info_label: RichTextLabel
var next_button: Button
var read_button: Button
var voice_picker: OptionButton
## Mobile: shows the picked voice and opens voice_sheet (Widgets.make_voice_button).
var voice_button: Button
var voice_sheet: VoiceSheet
## Finger drag-to-scroll for every ScrollContainer (see TouchScroll).
var touch_scroll: TouchScroll
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
var edge_client: EdgeTtsClient:
	get: return speech.edge_client
	set(v): speech.edge_client = v
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
## The menu's button column; _fit_menu_spacing tightens its separation.
var menu_column: VBoxContainer
var _menu_separation := -1
var menu_mode_buttons: Array[Button] = []
## The weakest-area drill; its subtitle shows the area and the readiness.
var study_button: Button
## Menu hero (Widgets.add_menu_hero): readiness dial.
var readiness_ring: ReadinessRing
## The tabbed launch menu (tabs, pages, exam and area tiles), from data/menu.json.
var menu := MainMenu.new()
## Practice-exam best scores and the run to continue (user://study_progress.cfg).
var progress: StudyProgress

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
var reduce_motion_toggle: CheckButton
var hunt_keywords_toggle: CheckButton
var audio_exam_note: Label
var preview_button: Button
var mute_button: Button
var dock_panel: PanelContainer
var key_hint_label: Label  # desktop only
var _results_seq := 0
var audio_body: VBoxContainer
var quiz_scroll_box: ScrollContainer
var answers_row: BoxContainer  # desktop only: choices | lookup material
var ref_column: VBoxContainer  # desktop only
var feedback_scroll: ScrollContainer
var fit := FitController.new()
var hunt := HuntView.new()
var _verdict_scroll_tween: Tween
var _start_tween: Tween
var _leave_armed_until := 0
## The last input was a key or controller (not a pointer or touch); see _input.
var _nav_input := false
## The launch menu gets no transition sound; later returns to it do.
var _menu_shown := false
## The 860 px menu card and ~823 px quiz header clip below this; narrower
## windows scale the desktop canvas down instead.
const DESKTOP_MIN_CANVAS_WIDTH := 900
## Below this the scaled-down desktop canvas gets too small to read. At or
## under the smallest window measure_fit checks (360x640, 1024x600).
const DESKTOP_MIN_WINDOW := Vector2i(360, 600)

var pause_button: Button
var skip_button: Button

# Reading highlight state
var info_panel := InfoPanelRenderer.new()
var _question_stem_glow_style: StyleBoxFlat = null  # cached glow style for question panel
var fx_layer: Control
var progress_segments: ProgressSegments
var exam_gauge: TimeGauge
var pace_gauge: TimeGauge
var results_visual: BoxContainer
var result_gauge: ResultGauge
var chapter_bars: ChapterBars
var sfx: Sfx
var sfx_level_buttons: Array[Button] = []  # Off, then one per AudioSettings.SFX_LEVEL_TITLES

## "v" + application/config/version, the one place the version is set
## (tools/release/bump_version.py copies it into the export presets).
static func version_label() -> String:
	var version := str(ProjectSettings.get_setting("application/config/version", ""))
	return "v" + version if version != "" else ""

func _init() -> void:
	speech.host = self
	fit.host = self
	hunt.host = self
	menu.host = self
	session.bag_path = QuizSession.BAG_PATH

func _exit_tree() -> void:
	# The TTS worker runs on speak_thread. Destroying the node while that thread is
	# still running leaves Godot printing "Thread object is being
	# destroyed without its completion having been realized" and can tear the
	# thread down mid-write. Join it before the node goes away.
	speech._join_speak_thread()

func _ready() -> void:
	# Before anything reads user://: the settings and progress may still be in
	# the pre-1.0 folder.
	UserDirMigration.run()
	speech._load_voice_catalog()
	audio.load_from(audio_cfg_path)
	ui_mobile = "--mobile-ui" in OS.get_cmdline_args() or "--mobile-ui" in OS.get_cmdline_user_args() or OS.get_name() in ["Android", "iOS"]
	if not ui_mobile:
		get_window().content_scale_size = Vector2i(DESKTOP_MIN_CANVAS_WIDTH, 960)
		# Headless, a min size grows the fake 960x960 window the tests measure.
		if DisplayServer.get_name() != "headless":
			get_window().min_size = DESKTOP_MIN_WINDOW
	Tooltip.attach(self, not ui_mobile)
	speech.edge_client = EdgeTtsClient.new()
	speech.edge_client.name = "EdgeTtsClient"
	add_child(speech.edge_client)
	speech.edge_client.clip_ready.connect(speech._on_edge_clip)
	speech.edge_client.request_failed.connect(speech._on_edge_failed)
	# Before the build: the menu lists the bank's practice exams.
	records = BankLoader.load_records()
	# A memory-only deck (tests) gets memory-only progress too.
	progress = StudyProgress.new(StudyProgress.PATH if session.bag_path != "" else "")
	_build_ui()
	info_panel.label = info_label
	QuizFx.attach(self)
	UiFx.apply_reduce_motion(get_tree(), audio.reduce_motion)
	_polish_controls()
	_apply_touch_filters()
	touch_scroll = TouchScroll.new()
	touch_scroll.name = "TouchScroll"
	touch_scroll.root = self
	add_child(touch_scroll)
	_apply_safe_area()
	# OS voices can arrive late on mobile: silently refresh the picker a few
	# seconds after launch so the first Read already offers real voices.
	if ui_mobile or not OS.has_feature("pc"):
		get_tree().create_timer(4.0).timeout.connect(speech._refresh_native_voices)
	get_viewport().size_changed.connect(_apply_safe_area)
	get_viewport().size_changed.connect(fit.on_viewport_resized)
	get_viewport().size_changed.connect(_fit_menu_spacing, CONNECT_DEFERRED)
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
	menu.study_hook("attach", [self])
	_listen_timer = Timer.new()
	_listen_timer.wait_time = 1.0
	_listen_timer.timeout.connect(_on_listen_tick)
	add_child(_listen_timer)
	AudioSection.refresh(self)
	_refresh_dock_audio()
	if records.is_empty():
		_show_error("Question bank could not be loaded.")
	else:
		_show_menu()

## Shared behaviour for both layouts, applied after the builder ran. The dock
## buttons are ghost buttons and Next the primary one (AppTheme), so every
## state already has a style; this adds the focus handling and the key hint.
func _polish_controls() -> void:
	if is_instance_valid(preview_button):
		preview_button.add_theme_stylebox_override("focus", AppTheme.focus_ring(AppTheme.RADIUS_INNER))
	# A mouse click must not leave a dock button holding keyboard focus, or the
	# next Enter/Space presses it instead of running the quiz shortcut.
	# Keyboard activation keeps focus so Tab navigation still works; releasing on
	# button_down would cancel the press, so it happens after pressed.
	for b in [read_button, mute_button, pause_button, skip_button, restart_button]:
		if is_instance_valid(b):
			b.button_down.connect(func() -> void:
				b.set_meta("pointer_press", Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)))
			b.pressed.connect(func() -> void:
				if b.get_meta("pointer_press", false):
					b.release_focus.call_deferred())
	if not ui_mobile and is_instance_valid(restart_button):
		key_hint_label = Label.new()
		key_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		key_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		key_hint_label.size_flags_stretch_ratio = 0.7
		key_hint_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		key_hint_label.clip_text = true
		key_hint_label.add_theme_font_override("font", AppTheme.meta_font(AppTheme.WEIGHT_SEMIBOLD))
		key_hint_label.add_theme_font_size_override("font_size", AppTheme.TYPE_MICRO)
		key_hint_label.add_theme_color_override("font_color", AppTheme.SLATE_400)
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
	return AppTheme.surface(AppTheme.SURFACE_BOTTOM, AppTheme.HAIRLINE_BRIGHT, AppTheme.ELEVATION_CARD)

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

func _start_quiz(question_count: int = SESSION_LENGTH, time_limit: int = QuizSession.session_seconds(), timed: bool = true, mode_name: String = "Practice Test", area: String = "", section: String = BankLoader.SECTION_NEC) -> void:
	if BankLoader.count_in_section(records, section) == 0:
		return
	var simulation := mode_name == SIMULATION_NAME
	_begin_session(simulation, func(listening: bool) -> bool:
		session.begin(question_count, time_limit, timed and not listening, mode_name + (" · Listen" if listening else ""), simulation, area, section)
		return true)

## These questions in this order: a practice exam as written (exam = its
## label, so the results keep its best score) or the missed-question review.
func _start_fixed(indices: Array[int], time_limit: int, mode_name: String, exam: String = "") -> void:
	if indices.is_empty():
		return
	_begin_session(false, func(listening: bool) -> bool:
		session.begin_fixed(indices, time_limit, not listening, mode_name + (" · Listen" if listening else ""), exam if not listening else "")
		return true)

## Up to the review_missed block's max of the questions whose latest answer
## was wrong.
func _start_review() -> void:
	var cap := int(MenuModel.block("review_missed").get("max", 20))
	var missed := MenuModel.missed_indices(records, session.deck.history(records), cap)
	_start_fixed(missed, _practice_time(missed.size()), "Review Missed")

## The unfinished run saved after its last graded answer. Always graded: a
## listen-mode setting resumes as Tap to hear.
func _resume_session() -> void:
	var snap := progress.resume_snapshot
	if snap.is_empty():
		return
	_begin_session(bool(snap.get("simulation", false)), func(_listening: bool) -> bool: return session.restore(snap), true)

## Shared start of every session: the audio mode for it, then begin (given
## whether this is a listen session; false = nothing to start), then the
## clock and the fade into the first question.
func _begin_session(simulation: bool, begin: Callable, graded: bool = false) -> void:
	session_audio_mode = AudioSettings.session_mode(audio.mode, simulation)
	if graded and not AudioSettings.grades_answers(session_audio_mode):
		session_audio_mode = AudioSettings.Mode.TAP
	session_muted = AudioSettings.starts_muted(session_audio_mode)
	listen_phase = AudioSettings.ListenPhase.IDLE
	listen_paused = false
	if not begin.call(session_audio_mode == AudioSettings.Mode.LISTEN):
		progress.clear_resume()
		session_audio_mode = AudioSettings.Mode.SILENT
		menu.refresh()
		return
	_refresh_dock_audio()
	if timed_session:
		timer.start()
	else:
		timer.stop()
	speech._stop_reading()
	# A start press already played the start cue, which silences this.
	_sfx("transition")
	# A second tap during the fade restarts it instead of queueing a second
	# _show_question for the same session.
	if _start_tween != null and _start_tween.is_valid():
		_start_tween.kill()
	_start_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_start_tween.tween_property(menu_overlay, "modulate:a", 0.0, AppTheme.MOTION_SCREEN)
	_start_tween.tween_callback(func():
		menu_overlay.visible = false
		_show_question()
	)

func _build_ui() -> void:
	if ui_mobile:
		MobileLayout.build(self)
	else:
		DesktopLayout.build(self)

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

func _on_reduce_motion_toggled(on: bool) -> void:
	audio.reduce_motion = on
	audio.reduce_motion_picked = true
	audio.save_to(audio_cfg_path)
	UiFx.apply_reduce_motion(get_tree(), on)
	AudioSection.refresh(self)

func _on_hunt_keywords_toggled(on: bool) -> void:
	audio.hunt_keywords = on
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
	# Recorded clips are on the Speech bus, which the duck bus already listens to.
	sfx.voice_active = func() -> bool:
		return DisplayServer.tts_is_speaking()
	sfx.voice_reading = func() -> bool:
		return (speech.reader != null and speech.reader.playing) or DisplayServer.tts_is_speaking()
	_apply_sfx_settings()
	_wire_ui_sounds(self)

## Interface sounds for every button the builders made (docs/SFX_PLAN.md):
## toggle for switches, check boxes, segmented chips and the voice mute; click
## for other presses; hover for the pointer entering a menu mode card (desktop
## only; plain buttons stay quiet on hover). Session-start controls play the
## start cue themselves, so they get no click.
## Answer cards are not buttons: _show_question gives them select.
func _wire_ui_sounds(node: Node) -> void:
	for child in node.get_children():
		_wire_ui_sounds(child)
	if not node is BaseButton:
		return
	var button := node as BaseButton
	var toggles := button.toggle_mode or button == mute_button
	if not button.has_meta("starts_session"):
		button.pressed.connect(_sfx.bind("toggle" if toggles else "click"))
	if not ui_mobile and (menu_mode_buttons.has(button) or menu.tiles.has(button)):
		button.mouse_entered.connect(func() -> void:
			if not button.disabled:
				_sfx("hover"))

## Keyboard / controller focus moves on the answer cards get select; a focus
## that comes with a click or tap does not (the answer tone covers that).
func _on_answer_card_focused() -> void:
	if _nav_input and not current_answered:
		_sfx("select")

func _apply_sfx_settings() -> void:
	if sfx != null:
		sfx.apply_settings(audio.sfx_enabled, AudioSettings.sfx_bus_db(audio.sfx_level))

func _sfx(id: String, pitch: float = 1.0) -> void:
	if sfx != null and id != "":
		sfx.play(id, pitch)

func _refresh_dock_audio() -> void:
	if not is_instance_valid(mute_button):
		return
	var listening := session_audio_mode == AudioSettings.Mode.LISTEN and listen_phase != AudioSettings.ListenPhase.IDLE
	mute_button.visible = not listening
	mute_button.text = "Voice off · Turn on" if session_muted else "Mute"
	mute_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL if session_muted and ui_mobile else Control.SIZE_FILL
	mute_button.add_theme_color_override("font_color", AppTheme.SLATE_400 if session_muted else AppTheme.SLATE_300)
	if mute_button.icon != null:
		mute_button.icon = Icons.texture("speaker_off" if session_muted else "speaker", mute_button.icon.get_width())
	read_button.visible = not listening and not session_muted
	pause_button.visible = listening
	skip_button.visible = listening
	pause_button.text = "Resume" if listen_paused else "Pause"
	if pause_button.icon != null:
		pause_button.icon = Icons.texture("play" if listen_paused else "pause", pause_button.icon.get_width())
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
			_answer_selected(int(session.current_record().get("correct_index", 0)))
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
	return question_count * ExamBlueprint.seconds_per_item()

## A drill of `size` questions from one subject area; by default the one with
## the lowest recent accuracy (or the heaviest one not practised yet).
func _start_area_drill(size: int = 10, area: String = "") -> void:
	if area == "":
		area = QuestionDeck.weakest_area(session.deck.mastery(records), records)
	_start_quiz(size, _practice_time(size), true, "Area Drill · " + ExamBlueprint.title(area), area)

## Every menu card and tile, and the readiness dial, from the current progress.
func _refresh_study_button() -> void:
	menu.refresh()
	if records.is_empty():
		return
	if is_instance_valid(readiness_ring):
		readiness_ring.set_value(QuestionDeck.readiness(session.deck.mastery(records)))

## The menu's tabs, for tests and the snapshot tools.
func menu_tab_count() -> int:
	return menu.pages.size()

func menu_show_tab(i: int) -> void:
	menu.show_tab(i)

## Tightens the menu's row spacing (the column and the open page) just enough
## that the whole menu fits the screen without scrolling, down to 4 px; a
## roomy screen keeps the layout's own spacing.
func _fit_menu_spacing() -> void:
	if not is_instance_valid(menu_column) or not is_instance_valid(menu_center_box):
		return
	var scroll := menu_center_box.get_parent() as ScrollContainer
	if scroll == null or scroll.size.y <= 0.0:
		return
	if _menu_separation < 0:
		_menu_separation = menu_column.get_theme_constant("separation")
	var boxes: Array[BoxContainer] = [menu_column]
	if not menu.pages.is_empty():
		boxes.append(menu.pages[menu.current])
	var gaps := 0
	# Overflow at the full spacing: undo what each box is tightened by now.
	var overflow := menu_center_box.get_combined_minimum_size().y - scroll.size.y
	for box in boxes:
		var n := maxi(0, box.get_children().filter(func(c): return c is Control and c.visible).size() - 1)
		gaps += n
		overflow += (_menu_separation - box.get_theme_constant("separation")) * n
	gaps = maxi(gaps, 1)
	var fitted := clampi(_menu_separation - ceili(maxf(overflow, 0.0) / gaps), 4, _menu_separation)
	for box in boxes:
		if box.get_theme_constant("separation") != fitted:
			box.add_theme_constant_override("separation", fitted)
	menu.hold_height()

func _show_menu() -> void:
	timer.stop()
	if _start_tween != null and _start_tween.is_valid():
		_start_tween.kill()
	_auto_token += 1
	ResultsView.clear_confetti(self)
	if is_instance_valid(_listen_timer):
		_listen_timer.stop()
	listen_phase = AudioSettings.ListenPhase.IDLE
	listen_paused = false
	session_audio_mode = AudioSettings.Mode.SILENT
	speech._stop_reading()
	if _menu_shown:
		_sfx("transition")
	_menu_shown = true
	_refresh_study_button()
	AudioSection.refresh(self)
	_update_key_hint()
	if menu_overlay:
		menu_overlay.visible = true
		if is_instance_valid(main_margin):
			main_margin.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
		var first := menu.first_focus()
		if not ui_mobile and first != null:
			first.grab_focus.call_deferred()
		UiFx.screen_enter(menu_overlay, audio.reduce_motion)

		# Staggered entrance for mode buttons
		for i in menu_mode_buttons.size():
			var btn := menu_mode_buttons[i]
			if is_instance_valid(btn):
				var badge := btn.get_node_or_null("ModeBadge") as ModeBadge
				if badge != null:
					badge.charge = 0.0
				# A second _show_menu restarts the entrance rather than racing it,
				# and the scale grows from the centre: every card ends at rest in
				# its column slot.
				if btn.has_meta("entrance_tween"):
					var prev := btn.get_meta("entrance_tween") as Tween
					if prev != null and prev.is_valid():
						prev.kill()
				if audio.reduce_motion:
					btn.modulate.a = 1.0
					btn.scale = Vector2.ONE
					continue
				btn.pivot_offset = btn.size * 0.5
				btn.modulate.a = 0.0
				btn.scale = Vector2(0.97, 0.97)
				var b_tw := btn.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				btn.set_meta("entrance_tween", b_tw)
				b_tw.tween_interval(0.04 * float(i))
				b_tw.tween_property(btn, "modulate:a", 1.0, 0.18)
				b_tw.parallel().tween_property(btn, "scale", Vector2.ONE, 0.22)
				b_tw.tween_callback(UiFx.shine_sweep.bind(btn))
		_fit_menu_spacing.call_deferred()

func _populate_reference_table(grid: GridContainer, note_label: Label, rows: Array, highlight_answer: String = "", is_feedback: bool = true, target_keyword: String = "") -> bool:
	var res := TableViewer.populate_table(grid, note_label, rows, highlight_answer, is_feedback, target_keyword)
	return bool(res.get("highlighted", false))

func _extract_table_target_keyword(record: Dictionary, table: Array) -> String:
	return TableViewer.extract_target_keyword(record, table)


func _show_question() -> void:
	if order.is_empty():
		return
	var record := session.current_record()
	session.start_question()
	if is_instance_valid(main_margin):
		main_margin.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED
	speech._stop_reading()
	speech._prefetch_speech()
	UiFx.screen_enter(question_panel, audio.reduce_motion)
	# A new question always opens at the top: the verdict glide on a phone may
	# still be running, and the page may have been scrolled on the last one.
	if _verdict_scroll_tween != null and _verdict_scroll_tween.is_valid():
		_verdict_scroll_tween.kill()
	if is_instance_valid(quiz_scroll_box):
		quiz_scroll_box.scroll_vertical = 0
	var correct_idx := int(record.get("correct_index", -1))
	var answers: Array = record.get("answers", [])
	var current_correct_text: String = str(answers[correct_idx]) if correct_idx >= 0 and correct_idx < answers.size() else ""
	var question_table = record.get("reference_table", [])
	question_table_panel.visible = question_table is Array and not question_table.is_empty() \
			and not bool(record.get("table_after_answer", false))
	if question_table_panel.visible:
		var reference_lines := str(record.get("reference_text", "")).split("\n", false)
		var table_title := reference_lines[0] if not reference_lines.is_empty() else str(record.get("article", "Reference table"))
		# The title often IS the answer ("Table ___ lists..." + title "Table 300.5(A)...").
		# Redact it pre-answer; blanked cells already hide in-table answers.
		table_title = AudioExplanationGenerator.redact_answer_spans(table_title, current_correct_text)
		if table_title.strip_edges() == "" or table_title.strip_edges() == "___":
			table_title = "REFERENCE TABLE"
		question_table_heading.text = "LOOK UP BEFORE ANSWERING  •  " + table_title
		_populate_reference_table(question_table_grid, question_table_note, question_table, current_correct_text, false, "")
	question_diagram_panel.visible = question_diagram_view.show_record(record)
	question_diagram_panel.add_theme_stylebox_override("panel", DiagramView.card_style(question_diagram_view.is_dark()))
	var formula_str := str(record.get("formula", "")).strip_edges()
	if formula_str != "":
		# The formula box shows pre-answer: keep the method, blank a computed answer value.
		question_formula_label.text = "FORMULA / METHOD:  " + AudioExplanationGenerator.redact_answer_spans(formula_str, current_correct_text)
		question_formula_label.visible = true
	else:
		question_formula_label.visible = false
	exam_label.text = "%s  |  %s  |  AVG %s / ITEM" % [session_name.to_upper(), ExamBlueprint.exam_name(), _format_time(ExamBlueprint.seconds_per_item())]
	if is_instance_valid(exam_mode_pill):
		exam_mode_pill.text = session_name.to_upper()
	if is_instance_valid(exam_license_pill):
		exam_license_pill.text = ExamBlueprint.exam_name()
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
	if NecReference.is_reference_seeking(str(record.get("prompt", "")), record.get("answers", [])):
		# The stem asks WHICH table/article holds the rule — printing the article
		# hands over the answer, so pre-answer navigation stops at chapter level.
		chapter_hint_label.text = NecReference.chapter_only_path(NecReference.lookup_path(record))
	else:
		chapter_hint_label.text = AudioExplanationGenerator.redact_answer_spans(NecReference.lookup_path(record), current_correct_text)
	chapter_hint_label.visible = chapter_hint_label.text != ""
	hunt.show_question(record, current_correct_text)
	formula_box.visible = question_formula_label.visible
	progress_label.text = "QUESTION %02d OF %02d" % [current_index + 1, order.size()]
	_update_score_badges()
	timer_label.text = "TOTAL " + _format_time(maxi(time_left, 0)) if timed_session else "UNTIMED"
	question_timer_label.text = "ITEM " + _format_time(question_time_left) if timed_session else ""
	question_timer_label.add_theme_color_override("font_color", AppTheme.SKY_400)
	timer_bar.visible = timed_session
	if timed_session:
		timer_bar.max_value = session_time_limit
		timer_bar.value = time_left
	_apply_exam_time_tint()

	for child in answers_box.get_children():
		answers_box.remove_child(child)
		child.queue_free()
	for i in answers.size():
		var card := AnswerCard.new()
		card.set_card_data(i, str(answers[i]))
		card.card_clicked.connect(_answer_selected)
		card.focus_entered.connect(_on_answer_card_focused)
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
	feedback_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	fit.refresh_ref_column()
	fit.begin()
	menu.study_hook("question", [self])
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
	if result["verdict"] != QuizSession.Verdict.REVIEWED:
		progress.set_resume(session.snapshot())
	var cards := answers_box.get_children()
	for i in cards.size():
		var card = cards[i]
		card.chosen = i == selected
		if i == correct:
			card.set_state(AnswerCard.State.CORRECT)
		elif i == selected:
			card.set_state(AnswerCard.State.WRONG)
		else:
			card.set_eliminated()

	match result["verdict"]:
		QuizSession.Verdict.REVIEWED:
			# Listen mode reviews, it does not test: no score, streak or missed list.
			_set_feedback_verdict("Answer", AppTheme.SKY_400, "tip")
			feedback_body.text = "Correct answer: %s — %s" % [ANSWER_LETTERS[correct], correct_text]
			feedback_body.visible = true
		QuizSession.Verdict.TIMED_OUT:
			_set_feedback_verdict("Time expired", AppTheme.RED_400, "clock")
			feedback_body.text = "Correct answer: %s — %s" % [ANSWER_LETTERS[correct], correct_text]
			feedback_body.visible = true
		QuizSession.Verdict.CORRECT:
			_set_feedback_verdict("Correct", AppTheme.EMERALD_400, "check")
			# The green card already shows the pick — a text echo of it is clutter.
			feedback_body.text = ""
			feedback_body.visible = false
		QuizSession.Verdict.WRONG:
			_set_feedback_verdict("Not quite", AppTheme.RED_400, "cross")
			# One verdict line: your pick is already red on its card, no need to restate it.
			feedback_body.text = "Correct answer: %s — %s" % [ANSWER_LETTERS[correct], correct_text]
			feedback_body.visible = true
	feedback_panel.visible = true
	UiFx.reveal(feedback_panel, audio.reduce_motion)

	question_table_panel.visible = false
	# The figure stays up: the explanation talks about it by its labels. A
	# teaching figure ("when": "after") appears now.
	question_diagram_panel.visible = question_diagram_view.reveal(correct, audio.reduce_motion)
	question_formula_label.visible = false
	# The box only follows the label on a resize, so hide it explicitly or an
	# empty frame is left behind on formula questions.
	formula_box.visible = false
	feedback_table_scroll.visible = false
	feedback_table_note.visible = false
	next_button.visible = true
	UiFx.reveal(next_button, audio.reduce_motion, 0.96)
	feedback_reference.text = NecReference.format_reference(record)
	feedback_reference.visible = true
	var table = record.get("reference_table", [])
	feedback_table_note.visible = false
	feedback_table_scroll.visible = table is Array and not table.is_empty()
	var table_highlighted := false
	if feedback_table_scroll.visible:
		var target_kw := _extract_table_target_keyword(record, table)
		table_highlighted = _populate_reference_table(feedback_table_grid, feedback_table_note, table, correct_text, true, target_kw)
	info_panel.show(record, correct_text, table_highlighted)
	menu.study_hook("answered", [self, record, result["verdict"] == QuizSession.Verdict.CORRECT, result["verdict"] != QuizSession.Verdict.REVIEWED])
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
	if timed_session and time_left <= 0:
		next_button.text = "See results"
	if ui_mobile:
		call_deferred("_scroll_to_verdict", correct)
	_update_key_hint()
	question_timer_label.text = "ITEM COMPLETED"
	_update_score_badges()
	QuizFx.update_time_gauges(self)
	QuizFx.play_answer(self, cards, correct, selected)


func _set_feedback_verdict(title: String, color: Color, icon_name: String) -> void:
	feedback_title.text = title
	feedback_title.add_theme_color_override("font_color", color)
	if is_instance_valid(feedback_icon):
		feedback_icon.texture = Icons.texture(icon_name, int(feedback_icon.custom_minimum_size.y))
		feedback_icon.modulate = color
		feedback_icon.visible = true


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
	if audio.reduce_motion:
		scroll.scroll_vertical = target
		return
	_verdict_scroll_tween = UiFx.ease_out(self)
	_verdict_scroll_tween.tween_property(scroll, "scroll_vertical", target, AppTheme.MOTION_SLOW)

func _update_score_badges() -> void:
	if is_instance_valid(progress_segments):
		progress_segments.set_progress(ProgressSegments.outcomes_for(order.size(), current_index, current_answered,
			missed_questions, AudioSettings.grades_answers(session_audio_mode)))
	if session_audio_mode == AudioSettings.Mode.LISTEN:
		score_label.text = "LISTEN MODE"
		score_label.add_theme_color_override("font_color", AppTheme.SKY_300)
		if is_instance_valid(pass_badge):
			Widgets.tint_hud_segment(pass_badge, AppTheme.SKY_400)
		streak_label.text = "%d / %d REVIEWED" % [answered_count, session_length]
		streak_label.add_theme_color_override("font_color", AppTheme.SKY_300)
		return
	if answered_count == 0:
		score_label.text = "TARGET: %d%%" % ExamBlueprint.pass_percent()
		score_label.add_theme_color_override("font_color", AppTheme.EMERALD_300)
		if is_instance_valid(pass_badge):
			Widgets.tint_hud_segment(pass_badge, AppTheme.EMERALD_400)
		streak_label.text = "0 / %d ITEMS" % session_length
		streak_label.add_theme_color_override("font_color", AppTheme.SKY_300)
		return

	var pct: float = (float(score) / float(answered_count)) * 100.0
	var pct_int: int = roundi(pct)
	streak_label.text = "%d/%d (%d%%)" % [score, answered_count, pct_int]

	if pct >= ExamBlueprint.pass_percent():
		score_label.text = "PASSING: " + str(pct_int) + "%"
		score_label.add_theme_color_override("font_color", AppTheme.EMERALD_300)
		if is_instance_valid(pass_badge):
			Widgets.tint_hud_segment(pass_badge, AppTheme.EMERALD_400)
		streak_label.add_theme_color_override("font_color", AppTheme.EMERALD_400)
	elif pct >= ExamBlueprint.at_risk_percent():
		score_label.text = "AT RISK: " + str(pct_int) + "%"
		score_label.add_theme_color_override("font_color", AppTheme.YELLOW_300)
		if is_instance_valid(pass_badge):
			Widgets.tint_hud_segment(pass_badge, AppTheme.AMBER_400)
		streak_label.add_theme_color_override("font_color", AppTheme.YELLOW_300)
	else:
		score_label.text = "BELOW %d%%: %d%%" % [ExamBlueprint.pass_percent(), pct_int]
		score_label.add_theme_color_override("font_color", AppTheme.ROSE_300)
		if is_instance_valid(pass_badge):
			Widgets.tint_hud_segment(pass_badge, AppTheme.RED_400)
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

## Mobile voice list (the picker's popup cannot take a finger).
func open_voice_sheet() -> void:
	speech._refresh_native_voices()
	VoiceSheet.open(self)

func _apply_touch_filters() -> void:
	# Finger drags are scrolled by touch_scroll before the GUI sees them, so these
	# filters no longer decide whether a page scrolls. They keep a mouse drag and a
	# touchscreen laptop's wheel/pan events reaching the scroller: interactive
	# nodes get PASS, everything else inside scrollable areas gets IGNORE, and
	# scrollers a deadzone so jittery presses aren't eaten by instant scroll-starts.
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
	if node is BaseButton or node.has_method("cancel_press") or node.has_meta("keeps_input"):
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
			_question_stem_glow_style.set_border_width_all(AppTheme.BORDER_STRONG + 1)
			# Same content box as the resting hairline style: the glow must not
			# resize the panel mid-question.
			AppTheme.pad(_question_stem_glow_style, AppTheme.BORDER_HAIRLINE, AppTheme.BORDER_HAIRLINE)
			_question_stem_glow_style.set_corner_radius_all(AppTheme.RADIUS)
			_question_stem_glow_style.shadow_color = Color(AppTheme.GLOW_CYAN, 0.65)
			_question_stem_glow_style.shadow_size = AppTheme.ELEVATION_FLOAT + 2
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
	var tick := session.tick(not speech.speak_busy and not speech.reader.playing and not DisplayServer.tts_is_speaking())
	timer_label.text = "TOTAL " + _format_time(max(time_left, 0))
	timer_bar.value = max(time_left, 0)
	_apply_exam_time_tint()
	if tick["item_ticked"]:
		question_timer_label.text = "ITEM " + _format_time(max(question_time_left, 0))
		if question_time_left <= 30:
			question_timer_label.add_theme_color_override("font_color", AppTheme.RED_400)
			if not audio.reduce_motion:
				UiFx.pop(question_timer_label, 1.06, AppTheme.MOTION_NORMAL)
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
			next_button.text = "See results"
			_update_key_hint()

func _format_time(seconds: int) -> String:
	return "%02d:%02d" % [seconds / 60, seconds % 60]

func _next_question() -> void:
	# The session clock ran out: the exam is over, like the real one.
	if timed_session and time_left <= 0:
		_show_results()
		return
	if session.advance():
		_show_question()
	else:
		_show_results()

## The run is over: a graded practice exam keeps its score, nothing is left
## to continue, and the report shows.
func _show_results() -> void:
	if session.session_exam != "" and AudioSettings.grades_answers(session_audio_mode):
		progress.record_exam(session.session_exam, score, session_length)
	if AudioSettings.grades_answers(session_audio_mode):
		progress.clear_resume()
	ResultsView.show(self)

func _show_error(message: String) -> void:
	if is_instance_valid(timer):
		timer.stop()
	if menu_overlay:
		menu_overlay.visible = false
	if is_instance_valid(restart_button):
		restart_button.get_parent().visible = false
	question_label.text = "Project error"
	exam_label.text = MenuModel.fill(str(MenuModel.spec().get("title", "")), menu.vars())
	article_label.text = ""
	progress_label.text = "Unable to start"
	feedback_panel.visible = true
	next_button.visible = false
	feedback_title.text = "Question bank unavailable"
	feedback_body.text = message
	answers_box.visible = false

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
	if is_instance_valid(voice_sheet):
		voice_sheet.close()
		return
	if menu.study_hook("back", [self]) == true:
		return
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
	var starting := _start_tween != null and _start_tween.is_running()
	if menu_overlay != null and menu_overlay.visible and not starting:
		if menu.current != 0:
			menu.show_tab(0)
			return
		get_tree().quit()
		return
	_request_menu()

## Menu button / Back mid-session: the first press arms, a second within 3 s
## leaves. Nothing to lose (no answers yet, or the report) leaves at once.
func _request_menu() -> void:
	var in_progress := answered_count > 0 and not menu_overlay.visible \
			and next_button.text != "Return to Main Menu"
	if not in_progress or Time.get_ticks_msec() < _leave_armed_until:
		_leave_armed_until = 0
		if restart_button.has_meta("idle_text"):
			restart_button.text = restart_button.get_meta("idle_text")
		_show_menu()
		return
	_leave_armed_until = Time.get_ticks_msec() + 3000
	if not restart_button.has_meta("idle_text"):
		restart_button.set_meta("idle_text", restart_button.text)
	restart_button.text = "Leave?"
	read_status_label.text = "Press again to leave. This session's progress will be lost."
	get_tree().create_timer(3.0).timeout.connect(func() -> void:
		if is_instance_valid(restart_button) and Time.get_ticks_msec() >= _leave_armed_until:
			restart_button.text = restart_button.get_meta("idle_text", restart_button.text)
			read_status_label.text = "")

func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventJoypadButton \
			or event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.5:
		_nav_input = true
	elif event is InputEventMouseButton or event is InputEventScreenTouch:
		_nav_input = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_BACK:
			_on_go_back()
			get_viewport().set_input_as_handled()
			return
		if menu_overlay and menu_overlay.visible:
			return
		var key: Key = event.keycode
		# A focused button already acted on Enter/Space (ui_accept); running the
		# quiz shortcut too would fire a second, different action.
		var focus_owner := get_viewport().gui_get_focus_owner()
		if focus_owner is BaseButton and key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			return
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
