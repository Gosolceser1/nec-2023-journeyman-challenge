class_name CalcPad
extends VBoxContainer
## A basic calculator on screen (CalcEngine): the display (pending operation,
## the number, M while memory holds something) over the keys in CalcEngine.KEYS
## order, five to a row, the last row a wide 0 and =.
##
## Guided (guide()): the pad follows one Show steps key row. The next key of
## the row is lit and named under the display; when the row is done it says
## whether the number agrees with the step's working line. Any other key still
## works, the guide just steps aside until Restart.
##
## Standalone (the Calculator tool) takes the keyboard too; inline under the
## steps it does not, so Enter and Backspace still walk the steps there.

signal guide_finished(matched: bool)

## Keys to a row; the last row is 0 (three keys wide) and = (two).
const ROW_SIZE := 5
const WIDE_KEYS := {"0": 3.0, "=": 2.0}
## Keyboard characters -> keys (standalone only).
const TYPED := {"+": "+", "-": "−", "*": "×", "x": "×", "/": "÷", "%": "%", "=": "=", ".": ".", ",": "."}

var mobile := false
var keyboard := false
var engine := CalcEngine.new()
## Plays an interface sound by Sfx id (the hub passes its sfx).
var sfx: Callable

var _pending: Label
var _number: Label
var _memory: Label
var _hint: Label
var _restart: Button
var _buttons: Dictionary = {}
var _styles: Dictionary = {}

var _prime_rows: Array = []
var _row := ""
var _want: Array = []
## The row as single keys, and how many of them were pressed as shown; -1
## once the learner went their own way (Restart follows the row again).
var _guide: Array = []
var _guide_at := -1


func _init(is_mobile: bool = false, inline: bool = false) -> void:
	mobile = is_mobile
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", AppTheme.SPACE_SM)
	var screen := MathUi.panel(AppTheme.TABLE_PANEL_BG, AppTheme.HAIRLINE_BRIGHT, AppTheme.SPACE_LG, AppTheme.SPACE_SM)
	add_child(screen)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	screen.add_child(col)
	var top := HBoxContainer.new()
	col.add_child(top)
	_memory = MathUi.meta_label("M", AppTheme.VIOLET_400)
	top.add_child(_memory)
	_pending = MathUi.meta_label("", AppTheme.SLATE_400)
	_pending.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pending.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(_pending)
	_number = MathUi.label("0", MathUi.px(MathUi.ENTRY if not inline else MathUi.BIG, mobile), AppTheme.SLATE_50, AppTheme.WEIGHT_SEMIBOLD)
	_number.add_theme_font_override("font", AppTheme.numeric_font(AppTheme.WEIGHT_SEMIBOLD))
	_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_number.clip_text = true
	col.add_child(_number)
	var hint_row := HBoxContainer.new()
	hint_row.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	add_child(hint_row)
	_hint = MathUi.label("", MathUi.px(MathUi.NOTE, mobile), AppTheme.AMBER_200, AppTheme.WEIGHT_MEDIUM, true)
	hint_row.add_child(_hint)
	_restart = MathUi.ghost_button("Restart", MathUi.px(MathUi.KEY_H, mobile) - 8.0, restart, "replay", MathUi.px(MathUi.BUTTON, mobile) - 2)
	_restart.focus_mode = Control.FOCUS_NONE
	_restart.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hint_row.add_child(_restart)
	hint_row.visible = false
	var key_h: float = MathUi.px(MathUi.KEY_H, mobile) * (1.0 if inline else 1.2)
	var font: int = MathUi.px(MathUi.KEY, mobile)
	var row: HBoxContainer = null
	for i in CalcEngine.KEYS.size():
		if i % ROW_SIZE == 0:
			row = HBoxContainer.new()
			row.add_theme_constant_override("separation", AppTheme.SPACE_XS + 2)
			add_child(row)
		var key: String = CalcEngine.KEYS[i]
		var b := _key_button(key, key_h, font)
		b.size_flags_stretch_ratio = WIDE_KEYS.get(key, 1.0)
		row.add_child(b)
	_refresh()


func _key_button(key: String, h: float, font: int) -> Button:
	var tint := _tint(key)
	var b := Button.new()
	b.name = "Key_" + str(CalcEngine.KEYS.find(key))
	b.text = key
	b.custom_minimum_size = Vector2(0, h)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", AppTheme.numeric_font(AppTheme.WEIGHT_BOLD))
	# The numeric face draws + − × ÷ = small next to its digits.
	b.add_theme_font_size_override("font_size", font + (8 if key in ["+", "−", "×", "÷", "="] else 0))
	var normal := AppTheme.panel_style(AppTheme.LUG_BG, Color(tint, 0.5), AppTheme.BORDER_HAIRLINE, AppTheme.RADIUS_INNER)
	normal.border_width_bottom = AppTheme.BORDER_STRONG + 1
	var hover := AppTheme.panel_style(AppTheme.BUTTON_HOVER_BG, tint, AppTheme.BORDER_HAIRLINE, AppTheme.RADIUS_INNER)
	hover.border_width_bottom = AppTheme.BORDER_STRONG + 1
	var pressed := AppTheme.panel_style(AppTheme.BUTTON_PRESSED_BG, tint, AppTheme.BORDER_HAIRLINE, AppTheme.RADIUS_INNER)
	var lit := AppTheme.panel_style(Color(AppTheme.SKY_400, 0.3), AppTheme.SKY_300, AppTheme.BORDER_STRONG, AppTheme.RADIUS_INNER)
	lit.border_width_bottom = AppTheme.BORDER_STRONG + 2
	for s in [normal, hover, pressed, lit]:
		AppTheme.pad(s, AppTheme.SPACE_XS, AppTheme.SPACE_XS)
	_styles[key] = {"normal": normal, "hover": hover, "lit": lit}
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("hover_pressed", pressed)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(state, tint)
	b.pressed.connect(press.bind(key))
	_buttons[key] = b
	return b


static func _tint(key: String) -> Color:
	if key == "=":
		return AppTheme.EMERALD_400
	if key in ["MC", "MR", "M+", "M−"]:
		return AppTheme.VIOLET_400
	if key in ["C", "⌫"]:
		return AppTheme.ROSE_300
	if key in ["+", "−", "×", "÷", "%", "√", "x²", "1/x", "±"]:
		return AppTheme.AMBER_400
	return AppTheme.SLATE_100


## Follows one step's row: earlier steps' rows are pressed first (silently), so
## a row that continues from the last result or recalls memory works as shown.
## want: the figures the row may land on (CalcEngine.expected_values).
func guide(row: String, prime_rows: Array = [], want: Array = []) -> void:
	_row = row
	_prime_rows = prime_rows
	_want = want
	restart()


func restart() -> void:
	if _row == "":
		engine.clear()
		_refresh()
		return
	engine = CalcEngine.primed(_prime_rows)
	var keys := CalcEngine.sequence_keys(_row)
	if not keys.is_empty() and not keys[0] in CalcEngine.CONTINUES:
		engine.press("C")
	_guide = keys
	_guide_at = 0
	_refresh()


## The key the guide is waiting for, "" when not guiding or done.
func next_key() -> String:
	return str(_guide[_guide_at]) if _guide_at >= 0 and _guide_at < _guide.size() else ""


func is_guiding() -> bool:
	return _row != ""


func press(key: String) -> void:
	engine.press(key)
	if sfx.is_valid():
		sfx.call("select")
	if _guide_at >= 0 and _guide_at < _guide.size():
		if key == str(_guide[_guide_at]):
			_guide_at += 1
			if _guide_at == _guide.size():
				guide_finished.emit(matches())
		else:
			_guide_at = -1
	_refresh()


## True when the display agrees with the step (or the step has no figure).
func matches() -> bool:
	return _want.is_empty() or _want.any(func(w: String) -> bool: return CalcEngine.agrees(engine.display(), w))


func display_text() -> String:
	return _number.text


func hint_text() -> String:
	return _hint.text


func key_button(key: String) -> Button:
	return _buttons.get(key)


func _refresh() -> void:
	_number.text = engine.display()
	_number.add_theme_color_override("font_color", AppTheme.ROSE_300 if engine.error else AppTheme.SLATE_50)
	_pending.text = engine.pending()
	_memory.modulate.a = 1.0 if engine.memory != 0.0 else 0.0
	var lit := next_key()
	for key in _buttons:
		var b: Button = _buttons[key]
		var s: Dictionary = _styles[key]
		b.add_theme_stylebox_override("normal", s["lit"] if key == lit else s["normal"])
		b.add_theme_stylebox_override("hover", s["lit"] if key == lit else s["hover"])
	_hint.get_parent().visible = is_guiding()
	if not is_guiding():
		return
	if _guide_at < 0:
		_hint.text = "Off the step's keys. Keep going, or press Restart to follow them again."
		_hint.add_theme_color_override("font_color", AppTheme.SLATE_300)
	elif _guide_at < _guide.size():
		_hint.text = "Press  %s   (%d of %d)" % [lit, _guide_at + 1, _guide.size()]
		_hint.add_theme_color_override("font_color", AppTheme.AMBER_200)
	elif matches():
		_hint.text = "Done: %s matches the step." % engine.display() if not _want.is_empty() else "Done: the calculator shows %s." % engine.display()
		_hint.add_theme_color_override("font_color", AppTheme.EMERALD_300)
	else:
		_hint.text = "The calculator shows %s; the step says %s." % [engine.display(), _want[0]]
		_hint.add_theme_color_override("font_color", AppTheme.ROSE_300)


func _unhandled_key_input(event: InputEvent) -> void:
	if not keyboard or not is_visible_in_tree() or not (event is InputEventKey) or not event.pressed:
		return
	var e := event as InputEventKey
	var key := ""
	match e.keycode:
		KEY_ENTER, KEY_KP_ENTER:
			key = "="
		KEY_BACKSPACE:
			key = "⌫"
		KEY_DELETE:
			key = "C"
		_:
			var ch := char(e.unicode) if e.unicode > 0 else ""
			if ch.length() == 1 and ch >= "0" and ch <= "9":
				key = ch
			else:
				key = str(TYPED.get(ch.to_lower(), ""))
	if key == "" or (e.echo and key != "⌫"):
		return
	press(key)
	get_viewport().set_input_as_handled()


## The Calculator tool's screen: the pad, keyboard on, and how it adds up.
static func screen(hub: MathHub) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", AppTheme.SPACE_MD)
	var pad := CalcPad.new(hub.mobile)
	pad.keyboard = true
	pad.sfx = hub.sfx
	if hub.mobile:
		col.add_child(pad)
	else:
		var center := CenterContainer.new()
		center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pad.custom_minimum_size = Vector2(480, 0)
		center.add_child(pad)
		col.add_child(center)
	var note := MathUi.label("Works left to right like a basic calculator: 2 + 3 × 4 = shows 20, so multiply first: 3 × 4 + 2 = shows 14." \
		+ ("" if hub.mobile else "  The keyboard works too: digits, + − * /, Enter, Backspace, Delete clears."),
		MathUi.px(MathUi.NOTE, hub.mobile), AppTheme.SLATE_400, AppTheme.WEIGHT_REGULAR, true)
	col.add_child(note)
	return col
