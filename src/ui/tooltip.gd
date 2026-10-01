class_name Tooltip
extends RefCounted
## Hover tips (desktop only). Main carries theme() so every tooltip, built in or
## custom, gets a solid slate panel and the UI font; make() builds the custom
## content: a bold title over a wrapped description for "Title • description"
## text. The desktop canvas is scaled to fit the window (900x960 at least), so
## the font size is set from that scale to stay readable on screen.

## Smallest on-screen text height, in window pixels, at any window size.
const MIN_SCREEN_PX := 14.0
## Wrap width in multiples of the font size (about 55 characters a line).
const MAX_EM := 24.0
const SEPARATOR := " • "
const PANEL_ALPHA := 0.97
const BORDER_ALPHA := 0.45
const SHADOW_PX := 8

## False on phones (and the --mobile-ui preview): make() returns an invisible
## control, which shows no tooltip.
static var enabled := true
static var _theme: Theme
static var _viewport: Viewport


static func theme() -> Theme:
	if _theme != null:
		return _theme
	_theme = Theme.new()
	_theme.set_stylebox("panel", "TooltipPanel", panel_style())
	_theme.set_font("font", "TooltipLabel", AppTheme.ui_font(AppTheme.WEIGHT_MEDIUM))
	_theme.set_font_size("font_size", "TooltipLabel", AppTheme.TYPE_BODY)
	_theme.set_color("font_color", "TooltipLabel", AppTheme.SLATE_200)
	_theme.set_color("font_shadow_color", "TooltipLabel", Color.TRANSPARENT)
	_theme.set_constant("line_spacing", "TooltipLabel", 2)
	return _theme


## The popup is transparent and clips at its edges, so the shadow is drawn
## inside it: the panel is inset by SHADOW_PX on every side.
static func panel_style() -> StyleBoxFlat:
	var style := AppTheme.panel_style(Color(AppTheme.SLATE_900, PANEL_ALPHA), Color(AppTheme.SKY_400, BORDER_ALPHA),
		AppTheme.BORDER_HAIRLINE, AppTheme.RADIUS_INNER)
	style.shadow_color = AppTheme.SHADOW_FLOAT
	style.shadow_size = SHADOW_PX
	style.shadow_offset = Vector2(0, AppTheme.SHADOW_OFFSET_Y)
	style.set_expand_margin_all(-SHADOW_PX)
	AppTheme.pad(style, AppTheme.SPACE_MD + SHADOW_PX, AppTheme.SPACE_SM + SHADOW_PX)
	return style


## Gives `host` (Main) the tooltip theme and keeps its font size readable as
## the window is resized.
static func attach(host: Control, on: bool) -> void:
	enabled = on
	host.theme = theme()
	_viewport = host.get_viewport()
	fit(_viewport)
	var refit := Callable(Tooltip, "_refit")
	if not _viewport.size_changed.is_connected(refit):
		_viewport.size_changed.connect(refit)


static func _refit() -> void:
	if is_instance_valid(_viewport):
		fit(_viewport)


## Canvas px that come out at least MIN_SCREEN_PX on screen, between body and
## title size.
static func font_size_for(scale: float) -> int:
	return clampi(ceili(MIN_SCREEN_PX / maxf(scale, 0.01)), AppTheme.TYPE_BODY, AppTheme.TYPE_TITLE)


static func fit(vp: Viewport) -> void:
	theme().set_font_size("font_size", "TooltipLabel", font_size_for(vp.get_final_transform().get_scale().y))


static func font_size() -> int:
	if is_instance_valid(_viewport):
		fit(_viewport)
	return theme().get_font_size("font_size", "TooltipLabel")


## The content for a control's _make_custom_tooltip.
static func make(text: String) -> Control:
	if not enabled or text.strip_edges() == "":
		var none := Control.new()
		none.visible = false
		return none
	var px := font_size()
	var max_w := MAX_EM * px
	var box := VBoxContainer.new()
	box.name = "Tooltip"
	box.add_theme_constant_override("separation", AppTheme.SPACE_XS)
	var parts := text.split(SEPARATOR, true, 1)
	var body := text
	if parts.size() == 2 and parts[0].strip_edges() != "" and parts[1].strip_edges() != "":
		var title := _label(parts[0].strip_edges(), px, max_w)
		title.name = "Title"
		title.add_theme_font_override("font", AppTheme.ui_font(AppTheme.WEIGHT_BOLD))
		title.add_theme_color_override("font_color", AppTheme.SLATE_50)
		box.add_child(title)
		body = parts[1].strip_edges()
	var desc := _label(body, px, max_w)
	desc.name = "Body"
	box.add_child(desc)
	return box


## A Label that wraps at max_w: as wide as its longest line up to max_w, so
## short tips stay compact.
static func _label(text: String, px: int, max_w: float) -> Label:
	var l := Label.new()
	l.theme_type_variation = "TooltipLabel"
	l.add_theme_font_override("font", AppTheme.ui_font(AppTheme.WEIGHT_MEDIUM))
	l.add_theme_font_size_override("font_size", px)
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var natural := 0.0
	for line in text.split("\n"):
		natural = maxf(natural, AppTheme.ui_font(AppTheme.WEIGHT_BOLD).get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x)
	l.custom_minimum_size.x = ceilf(minf(natural + 1.0, max_w))
	return l


## Line breaks for a plain tooltip_text, whose built-in label never wraps;
## measured in font-size units, so the breaks hold at every font size.
static func wrap(text: String) -> String:
	const REF_PX := 100
	var font := AppTheme.ui_font(AppTheme.WEIGHT_MEDIUM)
	var space := font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, REF_PX).x
	var out: PackedStringArray = []
	for para in text.split("\n"):
		var line := ""
		var w := 0.0
		for word in para.split(" ", false):
			var ww := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, REF_PX).x
			if line != "" and w + space + ww > MAX_EM * REF_PX:
				out.append(line)
				line = word
				w = ww
			else:
				w += (space if line != "" else 0.0) + ww
				line = word if line == "" else line + " " + word
		out.append(line)
	return "\n".join(out)
