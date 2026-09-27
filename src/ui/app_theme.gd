class_name AppTheme
extends RefCounted
## The one palette, the design tokens and the style/font factories every
## screen builds from. Palette colours keep their Tailwind names (hue +
## lightness, SKY_400 is the cyan accent); the custom dark surfaces are named
## for the widget they paint. Screenshots are compared pixel-for-pixel, so a
## value here is never "tidied" to a neighbouring shade.
##
## Tokens (docs/ARCHITECTURE.md, "Visual system"): layout code takes every
## margin, separation, radius, border width, shadow, font size and motion
## timing from the constants below, never a bare number.

# --- Spacing scale ----------------------------------------------------------
const SPACE_XS := 4
const SPACE_SM := 8
const SPACE_MD := 12
const SPACE_LG := 16
const SPACE_XL := 24

# --- Shape -----------------------------------------------------------------
## The one surface radius. Chips and badges nested inside a surface use
## RADIUS_INNER so their curve stays concentric with the surface's.
const RADIUS := 12
const RADIUS_INNER := 8
const BORDER_HAIRLINE := 1
const BORDER_STRONG := 2
## Left accent bar of an answer card, and the thicker energized "bus bar" the
## chosen card gets after grading.
const ACCENT_BAR_W := 4
const BUS_BAR_W := 6

# --- Elevation: shadow size per level (colours: SHADOW_*) --------------------
const ELEVATION_FLAT := 0
const ELEVATION_REST := 4
const ELEVATION_CARD := 10
const ELEVATION_FLOAT := 18
const SHADOW_OFFSET_Y := 2

# --- Type scale (px) ------------------------------------------------------------
const TYPE_DISPLAY := 40
const TYPE_TITLE := 22
const TYPE_HEADING := 18
const TYPE_BODY_LG := 17
const TYPE_BODY := 15
const TYPE_BODY_SM := 14
const TYPE_CAPTION := 13
const TYPE_META := 12
const TYPE_MICRO := 11
## Extra advance per glyph on uppercase meta labels ("QUESTION 05 OF 10").
const TRACKING_META := 1
const WEIGHT_REGULAR := 400
const WEIGHT_MEDIUM := 500
const WEIGHT_SEMIBOLD := 600
const WEIGHT_BOLD := 700

# --- Motion (seconds / px) ------------------------------------------------------
const MOTION_FAST := 0.12
const MOTION_SCREEN := 0.18
const MOTION_SLIDE_PX := 8.0
## Hover/focus lift of cards, drawn as an offset so the layout never moves.
const LIFT_PX := 2.0
## Gap between the light sweeps on the timer rings.
const SWEEP_PERIOD := 4.5
const SWEEP_SECONDS := 0.9

const WHITE := Color("ffffff")

const SLATE_50 := Color("f8fafc")
const SLATE_100 := Color("f1f5f9")
const SLATE_200 := Color("e2e8f0")
const SLATE_300 := Color("cbd5e1")
const SLATE_400 := Color("94a3b8")
const SLATE_500 := Color("64748b")
const SLATE_600 := Color("475569")
const SLATE_700 := Color("334155")
const SLATE_800 := Color("1e293b")
const SLATE_900 := Color("0f172a")
const GRAY_900 := Color("111827")

const SKY_100 := Color("e0f2fe")
const SKY_300 := Color("7dd3fc")
const SKY_400 := Color("38bdf8")
const SKY_500 := Color("0ea5e9")
const SKY_600 := Color("0284c7")
const SKY_700 := Color("0369a1")
const SKY_800 := Color("075985")
const BLUE_300 := Color("93c5fd")
const BLUE_600 := Color("2563eb")
const BLUE_800 := Color("1e40af")

const EMERALD_50 := Color("ecfdf5")
const EMERALD_200 := Color("a7f3d0")
const EMERALD_300 := Color("6ee7b7")
const EMERALD_400 := Color("34d399")
const EMERALD_500 := Color("10b981")
const EMERALD_600 := Color("059669")
const EMERALD_700 := Color("047857")
const EMERALD_900 := Color("064e3b")
const GREEN_50 := Color("f0fdf4")
const GREEN_300 := Color("86efac")

const ROSE_50 := Color("fff1f2")
const ROSE_200 := Color("fecdd3")
const ROSE_300 := Color("fda4af")
const ROSE_400 := Color("fb7185")
const ROSE_500 := Color("f43f5e")
const ROSE_800 := Color("9f1239")
const RED_300 := Color("fca5a5")
const RED_400 := Color("f87171")
const RED_500 := Color("ef4444")

const AMBER_100 := Color("fef3c7")
const AMBER_200 := Color("fde68a")
const AMBER_400 := Color("fbbf24")
const AMBER_500 := Color("f59e0b")
const YELLOW_300 := Color("fde047")
const YELLOW_700 := Color("a16207")
const YELLOW_800 := Color("854d0e")
const ORANGE_400 := Color("fb923c")
const PINK_400 := Color("f472b6")
const VIOLET_400 := Color("a78bfa")
const PURPLE_400 := Color("c084fc")

# Screen background gradient (also the menu backdrop).
const BG_TOP := Color("020408")
const BG_BOTTOM := Color("08101e")

# Shared surfaces and borders.
const SURFACE_DEEP := Color("0a0f1d")
const BORDER_BLUE := Color("1e3a5f")
const BUTTON_BG := Color("111928")
const BUTTON_HOVER_BG := Color("182438")
const BUTTON_PRESSED_BG := Color("0c1526")
const BUTTON_BORDER := Color("2e3d57")
const EXAM_BUTTON_BG := Color("1e141d")
const EXAM_BUTTON_HOVER_BG := Color("2e151e")
const DOCK_BUTTON_BG := Color("111d31")
const DOCK_BUTTON_HOVER_BG := Color("1a2c4b")
const DOCK_BUTTON_BORDER := Color("223659")
const READ_BUTTON_BG := Color("142238")
const READ_BUTTON_HOVER_BG := Color("1e3458")
const READ_BUTTON_BORDER := Color("2d4a77")
const MENU_PANEL_BG := Color("0c1322")
const SECTION_BG := Color("0a1120")
const CHIP_ON_BG := Color("0c2a24")
const PICKER_BG := Color("0f1a2e")
const PICKER_HOVER_BG := Color("162640")
const POPUP_BG := Color("0a1220")
const POPUP_HOVER_BG := Color("14253d")

# Header badges and pills.
const PILL_BLUE_BG := Color("132035")
const PILL_SLATE_BG := Color("141c2a")
const PACE_BADGE_BG := Color("0f2334")
const VOICE_BADGE_BG := Color("06263b")
const BADGE_BLUE_BG := Color("0f2338")
const BADGE_GREEN_BG := Color("0f291e")
const BADGE_AMBER_BG := Color("241d08")
const BADGE_RED_BG := Color("260c14")

# Question and feedback panels.
const STEM_GLOW_BG := Color("10233f")
const LOOKUP_BG := Color("0d192c")
const TABLE_PANEL_BG := Color("091322")
const FEEDBACK_BG := Color("13213a")
const FEEDBACK_BORDER := Color("29476f")
const WRONG_HIGHLIGHT_BG := Color("4c1d24")

# Reference table cells.
const TABLE_HEADER_BG := Color("152844")
const TABLE_HEADER_BORDER := Color("334d72")
const TABLE_ROW_EVEN := Color("0c1524")
const TABLE_ROW_ODD := Color("121d30")
const TABLE_CELL_BORDER := Color("1e2f47")

# Answer card states.
const CARD_PILL_BG := Color("142035")
const CARD_SPEAKING_BG := Color("1a2942")
const CARD_HOVER_BG := Color("1a2538")
const CARD_PRESSED_BG := Color("141e30")
const CARD_CORRECT_BG := Color("0d281e")
const CARD_CORRECT_INK := Color("022c1b")
const CARD_WRONG_BG := Color("2e1216")
const CARD_WRONG_INK := Color("1f0408")
const CARD_ELIMINATED_BG := Color("0d131f")
const CARD_ELIMINATED_BORDER := Color("172030")
const CARD_ELIMINATED_PILL_BORDER := Color("1f293d")

# Glass surfaces: the StyleBox fill is the bottom colour; the surface shader
# (UiFx.add_glass) lifts the top edge to the top colour.
const SURFACE_TOP := Color("141e33")
const SURFACE_BOTTOM := Color("0b1221")
const PANEL_TOP := Color("0f1729")
const PANEL_BOTTOM := Color("080d19")
const PAPER_TOP := Color("1a2842")
const PAPER_BOTTOM := Color("131e33")
const PAPER_BORDER := Color("2c4163")
const OFFICIAL_FROM := Color("2c0f1b")
const OFFICIAL_TO := Color("2b1d08")
const HAIRLINE := Color("1c2940")
const HAIRLINE_BRIGHT := Color("2a3b57")
const LUG_BG := Color("18233a")
const LUG_RIM := Color("3a4d6d")

## Gradient pairs, [from, to]: top -> bottom for surfaces, left -> right for
## the primary button and the official simulator card.
const GRAD_SURFACE := [SURFACE_TOP, SURFACE_BOTTOM]
const GRAD_PANEL := [PANEL_TOP, PANEL_BOTTOM]
const GRAD_PAPER := [PAPER_TOP, PAPER_BOTTOM]
const GRAD_PRIMARY := [SKY_700, BLUE_800]
const GRAD_OFFICIAL := [OFFICIAL_FROM, OFFICIAL_TO]

# Glow and shadow colours (alpha is part of the token).
const GLOW_CYAN := Color(0.22, 0.74, 0.97, 0.30)
const GLOW_CYAN_SOFT := Color(0.22, 0.74, 0.97, 0.12)
const GLOW_EMERALD := Color(0.20, 0.83, 0.60, 0.28)
const GLOW_RED := Color(0.94, 0.27, 0.27, 0.28)
const GLOW_AMBER := Color(0.98, 0.75, 0.14, 0.32)
const SHADOW_REST := Color(0.0, 0.0, 0.0, 0.30)
const SHADOW_CARD := Color(0.0, 0.0, 0.0, 0.42)
const SHADOW_FLOAT := Color(0.0, 0.0, 0.0, 0.55)
# Explanation rows: soft answer pill and the per-choice mini-cards.
const ANSWER_PILL_BG := Color("0f4034")
const ROW_RIGHT_BG := Color("0d2b22")
const ROW_WRONG_BG := Color("26111a")
const ROW_NEUTRAL_BG := Color("121b2d")
## Strength of the 1 px glass highlight under a surface's top edge.
const BEVEL := 0.07


static func panel_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style


## A surface at an elevation level: fill, hairline border and a soft drop
## shadow sized and tinted by the level.
static func surface(fill: Color, border: Color, elevation: int = ELEVATION_CARD, radius: int = RADIUS) -> StyleBoxFlat:
	var style := panel_style(fill, border, BORDER_HAIRLINE, radius)
	elevate(style, elevation)
	return style


static func elevate(style: StyleBoxFlat, elevation: int, glow: Color = Color.TRANSPARENT) -> void:
	style.shadow_size = elevation
	style.shadow_offset = Vector2(0, SHADOW_OFFSET_Y) if elevation > ELEVATION_FLAT and glow.a == 0.0 else Vector2.ZERO
	if glow.a > 0.0:
		style.shadow_color = glow
	elif elevation >= ELEVATION_FLOAT:
		style.shadow_color = SHADOW_FLOAT
	elif elevation >= ELEVATION_CARD:
		style.shadow_color = SHADOW_CARD
	else:
		style.shadow_color = SHADOW_REST


static func pad(style: StyleBox, horizontal: float, vertical: float) -> StyleBox:
	style.content_margin_left = horizontal
	style.content_margin_right = horizontal
	style.content_margin_top = vertical
	style.content_margin_bottom = vertical
	return style


## One cell of the HUD status strip: a rounded inner cell over the strip's
## glass, neutral or tinted by a status colour (pass / at risk / below).
static func hud_segment(tint: Color = SLATE_400, horizontal: float = SPACE_MD) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = hud_tint(tint)
	style.set_corner_radius_all(RADIUS_INNER)
	pad(style, horizontal, SPACE_XS + 2)
	return style


static func hud_tint(tint: Color) -> Color:
	return Color(tint, 0.14 if tint != SLATE_400 else 0.05)


## Secondary action: transparent over its surface, hairline edge, cyan on
## hover. Used by the dock (Mute, Read, Pause, Skip, Main menu) and the menu.
static func style_ghost_button(button: Button, radius: int = RADIUS_INNER) -> void:
	var normal := panel_style(Color(WHITE, 0.02), HAIRLINE_BRIGHT, BORDER_HAIRLINE, radius)
	var hover := panel_style(Color(SKY_400, 0.08), Color(SKY_400, 0.75), BORDER_HAIRLINE, radius)
	var pressed := panel_style(Color(SKY_400, 0.15), SKY_500, BORDER_HAIRLINE, radius)
	var disabled := panel_style(Color.TRANSPARENT, HAIRLINE, BORDER_HAIRLINE, radius)
	for style in [normal, hover, pressed, disabled]:
		pad(style, SPACE_MD, SPACE_XS)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("hover_pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", focus_ring(radius))
	button.add_theme_color_override("font_color", SLATE_300)
	button.add_theme_color_override("font_hover_color", WHITE)
	button.add_theme_color_override("font_pressed_color", SKY_300)
	button.add_theme_color_override("icon_normal_color", SLATE_400)
	button.add_theme_color_override("icon_hover_color", SKY_300)
	button.add_theme_color_override("icon_pressed_color", SKY_300)
	button.add_theme_color_override("icon_focus_color", SKY_300)
	button.add_theme_constant_override("h_separation", SPACE_SM)


## Primary action (Next question): a cyan -> deep blue bar (the gradient is
## the surface shader's tint, UiFx.add_glass) with an inner glow and a pressed
## state that sinks by a pixel. White on SKY_700 is 5.9:1 (WCAG AA).
static func style_primary_button(button: Button) -> void:
	var normal := panel_style(SKY_700, SKY_500, BORDER_HAIRLINE, RADIUS)
	elevate(normal, ELEVATION_REST * 2, GLOW_CYAN_SOFT)
	var hover := panel_style(SKY_700, SKY_300, BORDER_HAIRLINE, RADIUS)
	elevate(hover, ELEVATION_CARD + 2, GLOW_CYAN)
	var pressed := panel_style(SKY_800, SKY_600, BORDER_HAIRLINE, RADIUS)
	elevate(pressed, 2, GLOW_CYAN_SOFT)
	var disabled := panel_style(SLATE_800, SLATE_700, BORDER_HAIRLINE, RADIUS)
	for style in [normal, hover, disabled]:
		pad(style, SPACE_LG, SPACE_SM)
	pad(pressed, SPACE_LG, SPACE_SM)
	pressed.content_margin_top += 1
	pressed.content_margin_bottom -= 1
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("hover_pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", focus_ring(RADIUS))
	button.add_theme_font_override("font", ui_font(WEIGHT_SEMIBOLD))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, WHITE)
	button.add_theme_color_override("font_disabled_color", SLATE_400)


## Cyan outline for keyboard focus. Pointer clicks don't draw focus
## (gui/common/show_focus_state_on_pointer_event), so it can be strong.
static func focus_ring(radius: int = 10) -> StyleBoxFlat:
	var ring := StyleBoxFlat.new()
	ring.draw_center = false
	ring.border_color = SKY_300
	ring.set_border_width_all(2)
	ring.set_corner_radius_all(radius)
	ring.set_expand_margin_all(3)
	return ring


static var _ui_fonts: Dictionary = {}

## Shared per weight: every SystemFont resolves the OS font and keeps its own
## glyph cache, so building one per label stalled startup and each question.
## Callers must not mutate the returned font (duplicate() it first).
static func ui_font(weight: int = 500) -> SystemFont:
	if _ui_fonts.has(weight):
		return _ui_fonts[weight]
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Segoe UI", "SF Pro Display", "Inter", "Roboto", "Helvetica Neue", "Arial", "sans-serif"])
	font.font_weight = weight
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	_ui_fonts[weight] = font
	return font


static var _variants: Dictionary = {}

## Uppercase meta labels: the UI font with TRACKING_META px of letter spacing.
static func meta_font(weight: int = WEIGHT_BOLD) -> FontVariation:
	return _variant("meta", weight)


## Clocks, scores and counts: tabular figures, so "1:11" and "8:08" line up
## and a ticking clock does not jitter.
static func numeric_font(weight: int = WEIGHT_BOLD) -> FontVariation:
	return _variant("numeric", weight)


static func _variant(kind: String, weight: int) -> FontVariation:
	var key := "%s_%d" % [kind, weight]
	if _variants.has(key):
		return _variants[key]
	var font := FontVariation.new()
	font.base_font = ui_font(weight)
	if kind == "meta":
		font.spacing_glyph = TRACKING_META
	else:
		font.opentype_features = {TextServerManager.get_primary_interface().name_to_tag("tnum"): 1}
	_variants[key] = font
	return font


static func monospace_font() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])
	return font
