class_name MenuTile
extends Button
## A menu grid tile (one practice exam, one subject area, one study tool):
## the title, a detail line with a status badge at its end, and a MeterBar.
## Same content box in every state, so hover and focus never move it (like
## the mode cards, see Widgets.add_mode_button).

var title_row: HBoxContainer
var title_label: Label
var badge_label: Label
var detail_label: Label
var meter: MeterBar
var accent := AppTheme.SKY_400
## Hover text that adds to what the tile shows ("Title • description"); with
## none, the tile's own text shows on hover only when it is cut off.
var tip := ""


func _init(title_text: String, accent_color: Color, h: float, title_px: int, detail_px: int, with_meter: bool = true) -> void:
	accent = accent_color
	custom_minimum_size = Vector2(0, h)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip_contents = true
	var normal := _style(AppTheme.SURFACE_BOTTOM, Color(accent, 0.4), AppTheme.ELEVATION_REST, Color.TRANSPARENT)
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", _style(AppTheme.SURFACE_BOTTOM.lightened(0.05), accent, AppTheme.ELEVATION_CARD, Color(accent, 0.28)))
	var pressed := _style(AppTheme.SURFACE_BOTTOM.darkened(0.15), accent, AppTheme.ELEVATION_FLAT, Color.TRANSPARENT)
	add_theme_stylebox_override("pressed", pressed)
	add_theme_stylebox_override("hover_pressed", pressed)
	add_theme_stylebox_override("disabled", _style(AppTheme.SURFACE_BOTTOM, AppTheme.HAIRLINE, AppTheme.ELEVATION_FLAT, Color.TRANSPARENT))
	var focus := AppTheme.focus_ring(AppTheme.RADIUS)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		focus.set_content_margin(side, normal.get_content_margin(side))
	add_theme_stylebox_override("focus", focus)

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = normal.content_margin_left
	column.offset_top = normal.content_margin_top
	column.offset_right = -normal.content_margin_right
	column.offset_bottom = -normal.content_margin_bottom
	column.add_theme_constant_override("separation", AppTheme.SPACE_XS)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	title_row = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", AppTheme.SPACE_XS)
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(title_row)
	title_label = _label(title_text, title_px, AppTheme.SLATE_50, AppTheme.WEIGHT_BOLD)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_row.add_child(title_label)
	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", AppTheme.SPACE_XS)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(status)
	detail_label = _label("", detail_px, AppTheme.SLATE_300, AppTheme.WEIGHT_MEDIUM)
	detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status.add_child(detail_label)
	badge_label = _label("", detail_px, AppTheme.SLATE_400, AppTheme.WEIGHT_SEMIBOLD)
	badge_label.add_theme_font_override("font", AppTheme.numeric_font(AppTheme.WEIGHT_SEMIBOLD))
	status.add_child(badge_label)
	if with_meter:
		meter = MeterBar.new()
		meter.color = accent
		column.add_child(meter)
	UiFx.add_glass(self)
	UiFx.add_shine(self)


func set_status(detail: String, badge: String, badge_color: Color, fraction: float, tick: float = -1.0) -> void:
	detail_label.text = detail
	badge_label.text = badge
	badge_label.add_theme_color_override("font_color", badge_color)
	tooltip_text = title_label.text + " • " + detail + ("  •  " + badge if badge != "" else "")
	set_meta("base_text", title_label.text + "\n" + detail)
	if meter != null:
		meter.fraction = fraction
		meter.tick = tick


func _get_tooltip(_at_position: Vector2) -> String:
	if tip != "":
		return tip
	return tooltip_text if is_clipped(title_label) or is_clipped(detail_label) else ""


func _make_custom_tooltip(for_text: String) -> Object:
	return Tooltip.make(for_text)


## True when the label's text is cut off (ellipsis or lines past
## max_lines_visible).
static func is_clipped(l: Label) -> bool:
	if l.text == "" or not l.is_visible_in_tree():
		return false
	if l.autowrap_mode != TextServer.AUTOWRAP_OFF:
		return l.get_line_count() > l.get_visible_line_count()
	var width := l.get_theme_font("font").get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size("font_size")).x
	return width > l.size.x + 0.5


func _label(text_value: String, px: int, color: Color, weight: int) -> Label:
	var l := Label.new()
	l.text = text_value
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", AppTheme.ui_font(weight))
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", color)
	return l


func _style(fill: Color, border: Color, elevation: int, glow: Color) -> StyleBoxFlat:
	var style := AppTheme.panel_style(fill, border, AppTheme.BORDER_HAIRLINE, AppTheme.RADIUS)
	style.border_width_top = AppTheme.ACCENT_BAR_W - 1
	AppTheme.elevate(style, elevation, glow)
	style.content_margin_left = AppTheme.SPACE_MD
	style.content_margin_right = AppTheme.SPACE_MD
	style.content_margin_top = AppTheme.SPACE_SM
	style.content_margin_bottom = AppTheme.SPACE_SM
	return style
