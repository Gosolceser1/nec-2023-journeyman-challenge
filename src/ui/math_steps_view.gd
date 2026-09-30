class_name MathStepsView
extends VBoxContainer
## A solution from MathEngine shown one step at a time: the step's title, its
## sentence, the worked lines in big figures, a note, and the calculator keys
## as key caps, with a calculator (CalcPad) that walks those keys on request.
## Back / Next walk the steps; the last step's button says Done.

signal done
signal step_changed(index: int)

const MathStepSpeech = preload("res://src/speech/math_step_speech.gd")

## Title colour per step kind; unknown kinds use the sky accent.
const KIND_COLORS := {
	"formula": AppTheme.AMBER_400,
	"given": AppTheme.SKY_400,
	"lookup": AppTheme.VIOLET_400,
	"calc": AppTheme.SKY_300,
	"round": AppTheme.AMBER_200,
	"rule": AppTheme.ROSE_300,
	"answer": AppTheme.EMERALD_400,
}
## Kinds whose text is the working line itself ("I = 120 ÷ 15 = 8"): shown in
## big figures. Other kinds' text is a sentence.
const WORKING_KINDS := ["formula", "calc", "round"]
## Key cap colours: operators, memory keys, equals, everything else.
const OPERATOR_KEYS := ["+", "−", "-", "×", "÷", "x²", "√", "1/x", "%", "(", ")", "^", "yˣ"]
const MEMORY_KEYS := ["M+", "M-", "M−", "MR", "MC"]

var mobile := false
var steps: Array = []
var index := 0
## The exam question the steps solve ("" for a generated problem): names the
## step's recorded clips.
var record_id := ""
## Plays an interface sound by Sfx id (the hub passes Main._sfx).
var sfx: Callable
## speak.call(folder_id, plan, on_state) reads a step; on_state(playing, note)
## comes back. Empty: no Read button (voice off).
var speak: Callable
var stop: Callable
## Read each step as it is shown (the Auto-read and Listen voice modes).
var auto_read := false
var reading := false
## "Try it on the calculator" stays open from step to step once opened.
var pad_open := false
var pad: CalcPad
var _voice_note: Label

var _counter: Label
var _title: Label
var _dots: HBoxContainer
var _scroll: ScrollContainer
var _body: VBoxContainer
var _back: Button
var _next: Button
var _read: Button


func _init(is_mobile: bool = false) -> void:
	mobile = is_mobile
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", AppTheme.SPACE_SM)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	add_child(head)
	_counter = MathUi.meta_label("", AppTheme.SLATE_400)
	head.add_child(_counter)
	_dots = HBoxContainer.new()
	_dots.add_theme_constant_override("separation", AppTheme.SPACE_XS)
	_dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dots.alignment = BoxContainer.ALIGNMENT_END
	head.add_child(_dots)
	_title = MathUi.label("", MathUi.px(MathUi.TEXT, mobile) + 4, AppTheme.SKY_400, AppTheme.WEIGHT_BOLD)
	add_child(_title)
	_scroll = MathUi.scroll()
	add_child(_scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", AppTheme.SPACE_MD)
	_scroll.add_child(_body)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	add_child(foot)
	var h: float = MathUi.px(MathUi.BUTTON_H, mobile)
	var fs: int = MathUi.px(MathUi.BUTTON, mobile)
	_back = MathUi.ghost_button("Back", h, _go.bind(-1), "", fs)
	foot.add_child(_back)
	_read = MathUi.ghost_button("Read", h, _read_step, "speaker", fs)
	foot.add_child(_read)
	_next = Widgets.make_primary_button("Next step", h, fs, _go.bind(1))
	foot.add_child(_next)
	_voice_note = MathUi.meta_label("", AppTheme.AMBER_200)
	_voice_note.visible = false
	add_child(_voice_note)


func show_solution(solution: Dictionary, start: int = 0) -> void:
	stop_reading()
	steps = solution.get("steps", [])
	record_id = str(solution.get("record_id", ""))
	index = clampi(start, 0, maxi(0, steps.size() - 1))
	_render()


func is_last() -> bool:
	return index >= steps.size() - 1


func _go(delta: int) -> void:
	if delta > 0 and is_last():
		stop_reading()
		if sfx.is_valid():
			sfx.call("click")
		done.emit()
		return
	var to := clampi(index + delta, 0, maxi(0, steps.size() - 1))
	if to == index:
		return
	stop_reading()
	index = to
	if sfx.is_valid():
		sfx.call("select")
	_render()


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match (event as InputEventKey).keycode:
		KEY_RIGHT, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_go(1)
		KEY_LEFT, KEY_BACKSPACE:
			_go(-1)
		_:
			return
	get_viewport().set_input_as_handled()


## The words of the current step, as read aloud.
func step_text(i: int = -1) -> String:
	var step: Dictionary = steps[index if i < 0 else i]
	var parts: Array = [str(step.get("title", "")) + "."]
	for field in ["text"]:
		if str(step.get(field, "")) != "":
			parts.append(str(step[field]))
	for line in step.get("lines", []):
		parts.append(str(line) + ".")
	if str(step.get("note", "")) != "":
		parts.append(str(step["note"]))
	if str(step.get("keys", "")) != "":
		parts.append("On the calculator: " + str(step["keys"]) + ".")
	return " ".join(parts)


## What the voice says for a step (MathStepSpeech: every part a sentence, the
## calculator keys named one by one).
func spoken_text(i: int = -1) -> String:
	return MathStepSpeech.spoken(steps[index if i < 0 else i])


## The recorded / cached clip folder for a step.
func step_folder_id(i: int = -1) -> String:
	var at := index if i < 0 else i
	if record_id != "":
		return MathStepSpeech.folder_id(record_id, at)
	return MathStepSpeech.live_id(steps[at])


## Read toggles: Stop while this step is being read.
func _read_step() -> void:
	if reading:
		stop_reading()
		return
	read_current()


func read_current() -> void:
	if not speak.is_valid() or steps.is_empty():
		return
	speak.call(step_folder_id(), MathStepSpeech.plan(steps[index]), set_reading)


func stop_reading() -> void:
	if reading and stop.is_valid():
		stop.call()
	set_reading(false, "")


## The voice's state: the button says Stop while it reads; a fallback voice
## ("System voice (no internet)") or "Preparing…" shows under the buttons.
func set_reading(playing: bool, note: String = "") -> void:
	reading = playing
	if not is_instance_valid(_read):
		return
	_read.text = "Stop" if playing else "Read"
	_voice_note.text = note
	_voice_note.visible = playing and note != ""


## fresh: false when only the calculator opened or closed on the same step
## (no entrance, no scroll to top, no re-read).
func _render(fresh: bool = true) -> void:
	for c in _body.get_children():
		_body.remove_child(c)
		c.queue_free()
	for c in _dots.get_children():
		_dots.remove_child(c)
		c.queue_free()
	if steps.is_empty():
		return
	var step: Dictionary = steps[index]
	var kind := str(step.get("kind", "calc"))
	var accent: Color = KIND_COLORS.get(kind, AppTheme.SKY_400)
	_counter.text = "STEP %d OF %d" % [index + 1, steps.size()]
	_title.text = str(step.get("title", ""))
	_title.add_theme_color_override("font_color", accent)
	for i in steps.size():
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(18 if i == index else 8, 8)
		dot.color = accent if i == index else (AppTheme.SLATE_500 if i < index else AppTheme.SLATE_700)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dots.add_child(dot)
	var working: Array = []
	if str(step.get("text", "")) != "":
		if kind in WORKING_KINDS:
			working.append(str(step["text"]))
		elif kind != "answer":
			_body.add_child(MathUi.label(str(step["text"]), MathUi.px(MathUi.TEXT, mobile), AppTheme.SLATE_100, AppTheme.WEIGHT_MEDIUM, true))
	working.append_array(step.get("lines", []))
	if not working.is_empty():
		var box := MathUi.panel(AppTheme.TABLE_PANEL_BG, Color(accent, 0.45), AppTheme.SPACE_LG, AppTheme.SPACE_MD)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", AppTheme.SPACE_SM)
		box.add_child(col)
		for line in working:
			var big := MathUi.label(str(line), MathUi.px(MathUi.BIG, mobile), AppTheme.SLATE_50, AppTheme.WEIGHT_SEMIBOLD, true)
			big.add_theme_font_override("font", AppTheme.numeric_font(AppTheme.WEIGHT_SEMIBOLD))
			col.add_child(big)
		_body.add_child(box)
	if kind == "answer":
		var answer_box := MathUi.panel(AppTheme.CARD_CORRECT_BG, AppTheme.EMERALD_400, AppTheme.SPACE_LG, AppTheme.SPACE_LG)
		var big := MathUi.label(str(step.get("text", "")), MathUi.px(MathUi.BIG, mobile) + 6, AppTheme.EMERALD_300, AppTheme.WEIGHT_BOLD, true)
		big.add_theme_font_override("font", AppTheme.numeric_font())
		big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		answer_box.add_child(big)
		_body.add_child(answer_box)
	if str(step.get("note", "")) != "":
		_body.add_child(MathUi.label(str(step["note"]), MathUi.px(MathUi.NOTE, mobile), AppTheme.SLATE_300, AppTheme.WEIGHT_REGULAR, true))
	if str(step.get("keys", "")) != "":
		_body.add_child(key_row("ON YOUR CALCULATOR", str(step["keys"]), mobile))
	if str(step.get("basic", "")) != "":
		_body.add_child(key_row("BASIC CALCULATOR (NO SPECIAL KEY)", str(step["basic"]), mobile))
	_add_pad(step)
	_back.disabled = index == 0
	_next.text = "Done" if is_last() else "Next step"
	_read.visible = speak.is_valid()
	if not fresh:
		return
	_scroll.scroll_vertical = 0
	if not UiFx.reduce_motion:
		UiFx.screen_enter(_body, false)
	step_changed.emit(index)
	if auto_read and speak.is_valid():
		read_current.call_deferred()


func _exit_tree() -> void:
	stop_reading()


## The toggle and, when open, a calculator that walks this step's keys (the
## basic-calculator row when the step has one: the pad has no precedence).
func _add_pad(step: Dictionary) -> void:
	pad = null
	var row := CalcEngine.pad_keys(step)
	if row == "":
		return
	var toggle := MathUi.ghost_button("Hide calculator" if pad_open else "Try it on the calculator",
		MathUi.px(MathUi.KEY_H, mobile), toggle_pad, "calculator", MathUi.px(MathUi.BUTTON, mobile))
	toggle.name = "PadToggle"
	toggle.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	toggle.add_theme_color_override("icon_normal_color", AppTheme.SKY_300)
	_body.add_child(toggle)
	if not pad_open:
		return
	var earlier: Array = []
	for j in index:
		var r := CalcEngine.pad_keys(steps[j])
		if r != "":
			earlier.append(r)
	pad = CalcPad.new(mobile, true)
	pad.sfx = sfx
	_body.add_child(pad)
	pad.guide(row, earlier, CalcEngine.expected_values(step, steps[index + 1] if index + 1 < steps.size() else {}))


func toggle_pad() -> void:
	pad_open = not pad_open
	if sfx.is_valid():
		sfx.call("click")
	_render(false)
	if pad_open:
		_scroll_to_pad.call_deferred()


func _scroll_to_pad() -> void:
	await get_tree().process_frame
	if is_instance_valid(pad):
		_scroll.ensure_control_visible(pad)


## A caption and the key sequence as caps, wrapping onto more rows as needed.
static func key_row(caption: String, keys: String, is_mobile: bool) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", AppTheme.SPACE_XS)
	box.add_child(MathUi.meta_label(caption, AppTheme.SLATE_400))
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", AppTheme.SPACE_XS + 2)
	flow.add_theme_constant_override("v_separation", AppTheme.SPACE_XS + 2)
	box.add_child(flow)
	for key in keys.split(" ", false):
		flow.add_child(key_cap(key, is_mobile))
	return box


static func key_cap(key: String, is_mobile: bool) -> PanelContainer:
	var tint := AppTheme.SLATE_300
	if key == "=":
		tint = AppTheme.EMERALD_400
	elif MEMORY_KEYS.has(key):
		tint = AppTheme.VIOLET_400
	elif OPERATOR_KEYS.has(key):
		tint = AppTheme.AMBER_400
	var cap := PanelContainer.new()
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := AppTheme.panel_style(AppTheme.LUG_BG, Color(tint, 0.6), AppTheme.BORDER_HAIRLINE, AppTheme.RADIUS_INNER)
	style.border_width_bottom = AppTheme.BORDER_STRONG + 1
	AppTheme.pad(style, AppTheme.SPACE_SM + 2, AppTheme.SPACE_XS)
	cap.add_theme_stylebox_override("panel", style)
	var label := MathUi.label(key, MathUi.px(MathUi.KEY, is_mobile), tint, AppTheme.WEIGHT_BOLD)
	label.add_theme_font_override("font", AppTheme.numeric_font())
	label.custom_minimum_size = Vector2(28, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_child(label)
	return cap
