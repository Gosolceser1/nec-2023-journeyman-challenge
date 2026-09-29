class_name MathUi
extends RefCounted
## Small control factories the math screens share, built from AppTheme tokens.

## Type sizes of the math screens, [desktop, phone]. The learner reads best
## with big figures, so these sit above the quiz's sizes; both canvases are
## scaled to the window (about 0.75 on a 1280x720 desktop or a 412 px phone).
const BIG := [AppTheme.TYPE_DISPLAY - 6, AppTheme.TYPE_DISPLAY - 6]
const ENTRY := [AppTheme.TYPE_DISPLAY - 2, AppTheme.TYPE_DISPLAY - 2]
const TEXT := [AppTheme.TYPE_TITLE, AppTheme.TYPE_TITLE + 2]
const KEY := [AppTheme.TYPE_TITLE, AppTheme.TYPE_TITLE + 2]
const NOTE := [AppTheme.TYPE_BODY_LG, AppTheme.TYPE_HEADING + 1]
const TILE := [AppTheme.TYPE_BODY_LG, AppTheme.TYPE_HEADING]
const BUTTON := [AppTheme.TYPE_BODY_LG, AppTheme.TYPE_HEADING]
## Control heights, [desktop, phone]: phones get finger-sized targets.
const BUTTON_H := [46.0, 58.0]
const KEY_H := [44.0, 56.0]
const CHOICE_H := [52.0, 60.0]
const TILE_H := [58.0, 68.0]


## The [desktop, phone] entry of a size token.
static func px(token: Array, mobile: bool):
	return token[1] if mobile else token[0]


static func label(text: String, font_size: int = AppTheme.TYPE_BODY, color: Color = AppTheme.SLATE_100, weight: int = AppTheme.WEIGHT_MEDIUM, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", AppTheme.ui_font(weight))
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.custom_minimum_size = Vector2(40, 0)
	return l


## Tracked uppercase caption ("STEP 2 OF 5").
static func meta_label(text: String, color: Color = AppTheme.SLATE_400) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", AppTheme.meta_font())
	l.add_theme_font_size_override("font_size", AppTheme.TYPE_META)
	l.add_theme_color_override("font_color", color)
	return l


static func panel(fill: Color = AppTheme.SURFACE_BOTTOM, border: Color = AppTheme.HAIRLINE_BRIGHT, pad_h: float = AppTheme.SPACE_MD, pad_v: float = AppTheme.SPACE_SM + 2) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := AppTheme.panel_style(fill, border, AppTheme.BORDER_HAIRLINE, AppTheme.RADIUS)
	AppTheme.pad(style, pad_h, pad_v)
	p.add_theme_stylebox_override("panel", style)
	return p


## A vertical inner scroller that takes the height left over; the screen
## itself never scrolls.
static func scroll() -> ScrollContainer:
	var s := ScrollContainer.new()
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.scroll_deadzone = 16
	return s


static func ghost_button(text: String, h: float, callback: Callable, icon_name: String = "", font_size: int = AppTheme.TYPE_BODY_LG) -> Button:
	var b := Widgets.make_dock_button(text, 0, h, font_size, callback, icon_name)
	return b


## A tappable list row: title, a second line, and an accent bar on the left.
static func tile(title: String, subtitle: String, accent: Color, h: float, font_size: int, callback: Callable) -> Button:
	var b := Button.new()
	b.text = title + ("\n" + subtitle if subtitle != "" else "")
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(0, h)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_override("font", AppTheme.ui_font(AppTheme.WEIGHT_SEMIBOLD))
	b.add_theme_font_size_override("font_size", font_size)
	var normal := AppTheme.panel_style(AppTheme.SURFACE_BOTTOM, Color(accent, 0.4), AppTheme.BORDER_HAIRLINE, AppTheme.RADIUS_INNER)
	var hover := AppTheme.panel_style(AppTheme.SURFACE_TOP, accent, AppTheme.BORDER_HAIRLINE, AppTheme.RADIUS_INNER)
	var pressed := AppTheme.panel_style(AppTheme.BUTTON_PRESSED_BG, accent, AppTheme.BORDER_HAIRLINE, AppTheme.RADIUS_INNER)
	for style in [normal, hover, pressed]:
		style.border_width_left = AppTheme.ACCENT_BAR_W
		AppTheme.pad(style, AppTheme.SPACE_MD, AppTheme.SPACE_XS + 2)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("hover_pressed", pressed)
	b.add_theme_stylebox_override("focus", AppTheme.focus_ring(AppTheme.RADIUS_INNER))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, AppTheme.SLATE_100)
	b.pressed.connect(callback)
	return b


## An answer choice for the trainer and the drills.
static func choice(text: String, h: float, font_size: int, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, h)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_override("font", AppTheme.numeric_font(AppTheme.WEIGHT_SEMIBOLD))
	b.add_theme_font_size_override("font_size", font_size)
	set_choice_state(b, "idle")
	b.add_theme_stylebox_override("focus", AppTheme.focus_ring(AppTheme.RADIUS_INNER))
	b.pressed.connect(callback)
	return b


## state: idle, right, wrong, faded.
static func set_choice_state(b: Button, state: String) -> void:
	var fill := AppTheme.BUTTON_BG
	var border := AppTheme.BUTTON_BORDER
	var ink := AppTheme.SLATE_100
	match state:
		"right":
			fill = AppTheme.CARD_CORRECT_BG
			border = AppTheme.EMERALD_400
			ink = AppTheme.EMERALD_200
		"wrong":
			fill = AppTheme.CARD_WRONG_BG
			border = AppTheme.ROSE_400
			ink = AppTheme.ROSE_200
		"faded":
			fill = AppTheme.CARD_ELIMINATED_BG
			border = AppTheme.CARD_ELIMINATED_BORDER
			ink = AppTheme.SLATE_500
	var normal := AppTheme.panel_style(fill, border, AppTheme.BORDER_STRONG if state in ["right", "wrong"] else AppTheme.BORDER_HAIRLINE, AppTheme.RADIUS_INNER)
	AppTheme.pad(normal, AppTheme.SPACE_MD, AppTheme.SPACE_XS)
	var hover := normal
	if state == "idle":
		hover = AppTheme.panel_style(AppTheme.BUTTON_HOVER_BG, AppTheme.SKY_400, AppTheme.BORDER_HAIRLINE, AppTheme.RADIUS_INNER)
		AppTheme.pad(hover, AppTheme.SPACE_MD, AppTheme.SPACE_XS)
	for s in ["normal", "disabled"]:
		b.add_theme_stylebox_override(s, normal)
	for s in ["hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(s, hover)
	for s in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color"]:
		b.add_theme_color_override(s, ink)
	b.disabled = state != "idle"


## Accuracy bar: a slim track filled to the fraction, coloured by level.
static func accuracy_bar(fraction: float, h: float = 6.0) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = maxf(fraction, 0.0)
	bar.custom_minimum_size = Vector2(0, h)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := AppTheme.panel_style(AppTheme.SLATE_800, Color.TRANSPARENT, 0, 3)
	var fill := AppTheme.panel_style(accuracy_color(fraction), Color.TRANSPARENT, 0, 3)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


## Emerald at the 75 % pass mark or better, amber from 50 %, rose below;
## slate when never practised (fraction < 0).
static func accuracy_color(fraction: float) -> Color:
	if fraction < 0.0:
		return AppTheme.SLATE_600
	if fraction >= QuizSession.PASS_PERCENT / 100.0:
		return AppTheme.EMERALD_400
	if fraction >= 0.5:
		return AppTheme.AMBER_400
	return AppTheme.ROSE_400


static func accuracy_text(stats: MathStats, group: String, id: String) -> String:
	var acc := stats.accuracy(group, id)
	if acc < 0.0:
		return "new"
	return "%d%% · %d tried" % [roundi(acc * 100.0), stats.attempts(group, id)]


static func skill_color(skill_id: String) -> Color:
	return MathPicture.color_of(str(MathData.skill_def(skill_id).get("accent", "sky")))
