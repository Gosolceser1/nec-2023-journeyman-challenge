class_name RefTabs
extends HBoxContainer
## One reference block before answering: a question with both a reference
## table and a figure shows one of them at a time, picked here. The table is
## what the code book is opened to, so it comes first; the figure is a tap away.
## Hidden for every other question and after answering.

signal picked(figure: bool)

var table_tab: Button
var figure_tab: Button
var showing_figure := false


func _init(height: float, font_size: int) -> void:
	add_theme_constant_override("separation", AppTheme.SPACE_XS)
	visible = false
	var group := ButtonGroup.new()
	table_tab = _tab("Table", height, font_size, group)
	figure_tab = _tab("Figure", height, font_size, group)
	table_tab.button_pressed = true
	table_tab.pressed.connect(_pick.bind(false))
	figure_tab.pressed.connect(_pick.bind(true))


func _tab(text: String, height: float, font_size: int, group: ButtonGroup) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.button_group = group
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, height)
	b.add_theme_font_override("font", AppTheme.meta_font(AppTheme.WEIGHT_SEMIBOLD))
	b.add_theme_font_size_override("font_size", font_size)
	var idle := AppTheme.panel_style(Color(0, 0, 0, 0), AppTheme.HAIRLINE, AppTheme.BORDER_HAIRLINE, AppTheme.RADIUS_INNER)
	var on := AppTheme.panel_style(AppTheme.PILL_BLUE_BG, AppTheme.SKY_600, AppTheme.BORDER_HAIRLINE, AppTheme.RADIUS_INNER)
	for s in [idle, on]:
		s.content_margin_left = AppTheme.SPACE_SM + 4
		s.content_margin_right = AppTheme.SPACE_SM + 4
	b.add_theme_stylebox_override("normal", idle)
	b.add_theme_stylebox_override("hover", idle)
	b.add_theme_stylebox_override("pressed", on)
	b.add_theme_stylebox_override("hover_pressed", on)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", AppTheme.SLATE_400)
	b.add_theme_color_override("font_hover_color", AppTheme.SLATE_200)
	b.add_theme_color_override("font_pressed_color", AppTheme.SKY_300)
	b.add_theme_color_override("font_hover_pressed_color", AppTheme.SKY_300)
	add_child(b)
	return b


## both: the question has a table and a figure.
func show_for(both: bool) -> void:
	visible = both
	showing_figure = false
	table_tab.button_pressed = true


func _pick(figure: bool) -> void:
	if figure == showing_figure:
		return
	showing_figure = figure
	picked.emit(figure)
