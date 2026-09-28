class_name VoiceSheet
extends Control
## Mobile voice list: a sheet over the menu with one row per voice in the
## picker. Replaces the OptionButton popup on touch, which neither scrolls nor
## takes a tap without mouse emulation, so it stayed open and swallowed every
## touch. Rows are Buttons in a ScrollContainer (TouchScroll drags it; a swipe
## never picks a row). The first rows are built at once, the rest a batch per
## frame, so even a very long list opens without a hitch.

const ROW_H := 52.0
## Rows built when the sheet opens; it scrolls to the current voice once its row exists.
const FIRST_ROWS := 12
## Rows added per frame after that.
const ROWS_PER_FRAME := 12

var host: Main
var list: VBoxContainer
var scroll: ScrollContainer
var rows: Array[Button] = []
var _labels: PackedStringArray = []
var _selected := -1


## Opens the sheet for host.voice_picker's items, or returns the open one.
static func open(host: Main) -> VoiceSheet:
	if is_instance_valid(host.voice_sheet):
		return host.voice_sheet
	var sheet := VoiceSheet.new()
	sheet.host = host
	host.voice_sheet = sheet
	host.add_child(sheet)
	return sheet


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 30
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.01, 0.03, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(_on_dim_input)
	add_child(dim)

	var frame := MarginContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp := get_viewport_rect().size
	var side := maxf(AppTheme.SPACE_LG, (vp.x - 520.0) * 0.5)
	frame.add_theme_constant_override("margin_left", int(side))
	frame.add_theme_constant_override("margin_right", int(side))
	frame.add_theme_constant_override("margin_top", int(maxf(AppTheme.SPACE_LG, vp.y * 0.08)))
	frame.add_theme_constant_override("margin_bottom", int(maxf(AppTheme.SPACE_LG, vp.y * 0.08)))
	add_child(frame)

	var panel := PanelContainer.new()
	var sb := AppTheme.panel_style(AppTheme.POPUP_BG, AppTheme.BORDER_BLUE, 1, 12)
	sb.shadow_color = Color(0, 0, 0, 0.7)
	sb.shadow_size = 14
	sb.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", sb)
	frame.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	col.add_child(head)
	var title := Label.new()
	title.text = "CHOOSE A VOICE"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title.add_theme_font_override("font", AppTheme.ui_font(700))
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", AppTheme.EMERALD_400)
	head.add_child(title)
	head.add_child(Widgets.make_dock_button("Done", 92.0, 44.0, 14, close))

	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 16
	col.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	var picker := host.voice_picker
	for i in picker.item_count:
		_labels.append(picker.get_item_text(i))
	_selected = picker.selected
	_add_rows(FIRST_ROWS)
	set_process(rows.size() < _labels.size())


func _process(_delta: float) -> void:
	_add_rows(rows.size() + ROWS_PER_FRAME)
	if rows.size() >= _labels.size():
		set_process(false)


## True once every row exists.
func is_complete() -> bool:
	return rows.size() >= _labels.size()


func _add_rows(upto: int) -> void:
	for i in range(rows.size(), mini(upto, _labels.size())):
		var row := Button.new()
		row.text = _labels[i]
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.clip_text = true
		row.custom_minimum_size = Vector2(0, ROW_H)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.focus_mode = Control.FOCUS_ALL
		AppTheme.style_ghost_button(row, AppTheme.RADIUS_INNER)
		row.add_theme_font_override("font", AppTheme.ui_font(600 if i == _selected else 500))
		row.add_theme_font_size_override("font_size", 15)
		row.add_theme_color_override("font_color", AppTheme.SKY_300 if i == _selected else AppTheme.SLATE_200)
		if i == _selected:
			row.add_theme_stylebox_override("normal", AppTheme.panel_style(Color(AppTheme.SKY_400, 0.12), AppTheme.SKY_400, 2, AppTheme.RADIUS_INNER))
		row.pressed.connect(_choose.bind(i))
		list.add_child(row)
		rows.append(row)
		if i == _selected:
			_show_selected.call_deferred()


func _show_selected() -> void:
	if is_instance_valid(scroll) and _selected >= 0 and _selected < rows.size():
		scroll.ensure_control_visible(rows[_selected])


func _choose(index: int) -> void:
	host.speech.pick_voice(index)
	close()


func _on_dim_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and not event.pressed:
		accept_event()
		close()


func close() -> void:
	if host != null and host.voice_sheet == self:
		host.voice_sheet = null
	set_process(false)
	queue_free()
