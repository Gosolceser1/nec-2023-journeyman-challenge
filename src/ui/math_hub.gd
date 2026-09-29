class_name MathHub
extends Control
## The math study screens (Math Trainer, Formula Cards, Table Drills and the
## step-by-step solutions of exam calculation questions) in one full-screen
## overlay above the menu and the quiz. Main only calls the static entry
## points: attach, on_question, on_answered, handle_back and open; the menu
## lists the tools from data/math/tools.json (make_tool_button is optional).
##
## Screens are pushed on a stack as builder Callables; Back pops and rebuilds
## the previous screen, so lists always show fresh accuracy. A screen with its
## own inner state (the trainer's problem, a running drill) answers Back
## itself through handle_back().

const SpeechText = preload("res://src/speech/speech_text.gd")
const NODE_NAME := "MathHub"
const STEPS_BUTTON := "MathStepsButton"
## Desktop: the column is as wide as the menu card.
const DESKTOP_WIDTH := 860.0
## Tests point this at a scratch file.
static var stats_path := MathStats.DEFAULT_PATH

var host: Main
var mobile := false
var stats: MathStats
var rng := RandomNumberGenerator.new()
## Trainer difficulty, a MathData level id.
var level := 1

var _stack: Array = []  # [title, subtitle, builder]
var _margin: MarginContainer
var _title: Label
var _subtitle: Label
var _back: Button
var _content: VBoxContainer
var _screen: Control


# --- entry points for Main ------------------------------------------------------

static func hub(main: Main) -> MathHub:
	var h := main.get_node_or_null(NODE_NAME) as MathHub
	if h == null:
		h = MathHub.new()
		h.name = NODE_NAME
		h.host = main
		h.mobile = main.ui_mobile
		main.add_child(h)
	return h


## Opens a tool by its data/math/tools.json id: trainer, cards, drills or
## weak_spots. Unknown ids open the trainer.
static func open(main: Main, tool_id: String) -> void:
	var h := hub(main)
	h._stack.clear()
	var title := str(MathData.tool(tool_id).get("title", "Math trainer"))
	match tool_id:
		"cards":
			h.push(title, "EVERY FORMULA WITH A PICTURE AND AN EXAMPLE", MathCardsView.list.bind(h))
		"drills":
			h.push(title, "TIMED NEC TABLE LOOKUPS", MathDrillView.list.bind(h))
		"weak_spots":
			h.push(title, "ACCURACY OVER YOUR LAST %d ANSWERS PER TOPIC" % MathStats.RECENT, MathTrainerView.weak_spots.bind(h))
		_:
			h.push(title, "ENDLESS PRACTICE · STEP-BY-STEP HELP", MathTrainerView.pick.bind(h))
	h._show()


## The quiz's "Show steps" button, added once beside the verdict heading.
static func attach(main: Main) -> void:
	if not is_instance_valid(main.feedback_title) or main.feedback_title.get_parent().has_node(STEPS_BUTTON):
		return
	var row := main.feedback_title.get_parent()
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)
	var button := Widgets.make_dock_button("Show steps", 0, MathUi.px(MathUi.BUTTON_H, main.ui_mobile) - 6.0, MathUi.px(MathUi.BUTTON, main.ui_mobile), func() -> void:
		main._sfx("click")
		open_solution(main, main.session.current_record()), "tip")
	button.name = STEPS_BUTTON
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.add_theme_color_override("font_color", AppTheme.AMBER_200)
	button.add_theme_color_override("icon_normal_color", AppTheme.AMBER_400)
	button.visible = false
	row.add_child(button)


static func _steps_button(main: Main) -> Button:
	if not is_instance_valid(main.feedback_title):
		return null
	return main.feedback_title.get_parent().get_node_or_null(STEPS_BUTTON) as Button


## A new question: the steps stay hidden until it is answered.
static func on_question(main: Main) -> void:
	var button := _steps_button(main)
	if button != null:
		button.visible = false


## After an answer: count a calculation question toward its math skill and
## offer its steps. graded: false in Listen mode, which reviews, not tests.
static func on_answered(main: Main, record: Dictionary, correct: bool, graded: bool = true) -> void:
	if MathEngine.exam_plan(record).is_empty():
		return
	if graded:
		MathStats.new(stats_path).record_exam(record, correct)
	var button := _steps_button(main)
	if button != null:
		button.visible = MathEngine.exam_solution(record).get("ok", false)


## Android Back / Escape: true when the hub used it.
static func handle_back(main: Main) -> bool:
	var h := main.get_node_or_null(NODE_NAME) as MathHub
	if h == null or not h.visible:
		return false
	h.go_back()
	return true


## The exam question's solution, one step at a time, over the answered quiz.
static func open_solution(main: Main, record: Dictionary) -> void:
	var sol := MathEngine.exam_solution(record)
	if not sol.get("ok", false):
		return
	var h := hub(main)
	h._stack.clear()
	h.push("Step-by-step", str(MathData.skill_def(str(sol.get("skill", ""))).get("title", "")).to_upper(),
		h.steps_screen.bind(sol, str(record.get("prompt", ""))))
	h._show()


## Optional ready-made menu button for one tool (the menu may build its own
## from MathData.tool()). Pressing it calls MathHub.open(main, tool_id).
static func make_tool_button(main: Main, tool_id: String, h: float = MathUi.TILE_H[0], font_size: int = MathUi.TILE[0]) -> Button:
	var t := MathData.tool(tool_id)
	var accent := MathPicture.color_of(str(t.get("accent", "sky")))
	var b := MathUi.tile(str(t.get("title", tool_id)), MathData.tool_detail(tool_id), accent, h, font_size, open.bind(main, tool_id))
	b.icon = Icons.texture(str(t.get("icon", "bolt")), 18)
	b.add_theme_constant_override("icon_max_width", 18)
	for state in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		b.add_theme_color_override(state, accent)
	b.tooltip_text = str(t.get("description", ""))
	b.name = "Math_" + tool_id
	return b


# --- frame and navigation -------------------------------------------------------

func _ready() -> void:
	stats = MathStats.new(stats_path)
	rng.randomize()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 30
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var bg := ColorRect.new()
	bg.color = AppTheme.BG_TOP
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	add_child(UiFx.make_circuit_backdrop(UiFx.BACKDROP_DRIFT_MENU))
	_margin = MarginContainer.new()
	_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", AppTheme.SPACE_MD)
	_margin.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", AppTheme.SPACE_MD)
	col.add_child(head)
	_back = MathUi.ghost_button("Back", MathUi.px(MathUi.BUTTON_H, mobile), go_back, "menu", MathUi.px(MathUi.BUTTON, mobile))
	_back.pressed.connect(_click)
	head.add_child(_back)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 0)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(titles)
	_subtitle = MathUi.meta_label("", AppTheme.AMBER_400)
	_subtitle.clip_text = true
	titles.add_child(_subtitle)
	_title = MathUi.label("", AppTheme.TYPE_TITLE + 4, AppTheme.SLATE_50, AppTheme.WEIGHT_BOLD)
	_title.clip_text = true
	titles.add_child(_title)
	_content = VBoxContainer.new()
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_content)
	get_viewport().size_changed.connect(_apply_margins)
	_apply_margins()


func _apply_margins() -> void:
	var vp := get_viewport().get_visible_rect().size
	var win := get_window()
	var m := SafeArea.margins(vp, win.size if win != null else Vector2i.ZERO,
		DisplayServer.get_display_safe_area(), DisplayServer.get_display_cutouts(), mobile)
	var side: float = float(m["side"]) + (0.0 if mobile else AppTheme.SPACE_LG)
	if not mobile:
		side = maxf(side, (vp.x - DESKTOP_WIDTH) * 0.5)
	_margin.add_theme_constant_override("margin_left", int(side))
	_margin.add_theme_constant_override("margin_right", int(side))
	_margin.add_theme_constant_override("margin_top", int(m["top"]) + AppTheme.SPACE_MD)
	_margin.add_theme_constant_override("margin_bottom", int(m["bottom"]) + AppTheme.SPACE_MD)


func _show() -> void:
	if not visible:
		visible = true
		sfx("transition")
		UiFx.screen_enter(_content, UiFx.reduce_motion)


func close() -> void:
	stop_speaking()
	visible = false
	_stack.clear()
	if is_instance_valid(_screen):
		_screen.queue_free()
	_screen = null
	if is_instance_valid(host) and host.menu_overlay.visible:
		sfx("transition")


## Shows a new screen on top of the stack.
func push(title: String, subtitle: String, builder: Callable) -> void:
	_stack.append([title, subtitle, builder])
	_render_top()


## Replaces the top screen (a drill's result, say) without growing the stack.
func replace(title: String, subtitle: String, builder: Callable) -> void:
	if not _stack.is_empty():
		_stack.pop_back()
	push(title, subtitle, builder)


func go_back() -> void:
	stop_speaking()
	if is_instance_valid(_screen) and _screen.has_method("handle_back") and _screen.handle_back():
		return
	_stack.pop_back()
	if _stack.is_empty():
		close()
	else:
		_render_top()


## Id of the screen on top, for tests: the title.
func current_title() -> String:
	return _title.text if is_instance_valid(_title) else ""


func current_screen() -> Control:
	return _screen


func _render_top() -> void:
	stop_speaking()
	if is_instance_valid(_screen):
		_content.remove_child(_screen)
		_screen.queue_free()
	var top: Array = _stack.back()
	_title.text = str(top[0])
	_subtitle.text = str(top[1])
	_back.text = "Back" if _stack.size() > 1 else ("Close" if not host.menu_overlay.visible else "Menu")
	_screen = (top[2] as Callable).call()
	_screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(_screen)
	if visible and not UiFx.reduce_motion:
		UiFx.screen_enter(_screen, false)


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo \
			and (event as InputEventKey).keycode == KEY_ESCAPE:
		go_back()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	# The quiz below must not act on keys meant for these screens. Android
	# Back still reaches Main, which asks handle_back (debounced there).
	if visible and event is InputEventKey and (event as InputEventKey).keycode != KEY_BACK:
		get_viewport().set_input_as_handled()


# --- shared services for the screens ------------------------------------------

func sfx(id: String) -> void:
	if is_instance_valid(host):
		host._sfx(id)


func _click() -> void:
	sfx("click")


## A button that clicks like the rest of the app.
func with_click(b: BaseButton) -> BaseButton:
	b.pressed.connect(_click)
	return b


func can_speak() -> bool:
	return DisplayServer.tts_get_voices().size() > 0


## Reads text through the device voice, worded by the app's speech rules.
func speak(text: String) -> void:
	if not can_speak():
		return
	if is_instance_valid(host):
		host.speech._stop_reading()
	DisplayServer.tts_stop()
	var voice := host.speech._pick_native_voice() if is_instance_valid(host) else ""
	var rate := clampf(float(host.audio.speed), 0.5, 2.0) if is_instance_valid(host) else 1.0
	DisplayServer.tts_speak(SpeechText.speakable(text), voice, 80, 1.0, rate)


func stop_speaking() -> void:
	if can_speak():
		DisplayServer.tts_stop()


## A step viewer wired to the hub's sounds and voice.
func make_steps_view() -> MathStepsView:
	var view := MathStepsView.new(mobile)
	view.sfx = sfx
	if can_speak():
		view.speak = speak
	return view


## The steps of a solution as a whole screen; Done goes back.
func steps_screen(sol: Dictionary, question: String = "") -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	if question != "":
		var q := MathUi.label(question, MathUi.px(MathUi.NOTE, mobile), AppTheme.SLATE_400, AppTheme.WEIGHT_REGULAR, true)
		q.max_lines_visible = 3
		q.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		col.add_child(q)
	var view := make_steps_view()
	view.done.connect(go_back)
	col.add_child(view)
	view.show_solution(sol)
	return col
