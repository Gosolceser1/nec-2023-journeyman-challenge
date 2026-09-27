class_name AppTheme
extends RefCounted
## The one palette and the style/font factories every screen builds from.
## Palette colours keep their Tailwind names (hue + lightness, SKY_400 is the
## cyan accent); the custom dark surfaces are named for the widget they paint.
## Screenshots are compared pixel-for-pixel, so a value here is never "tidied"
## to a neighbouring shade.

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


static func panel_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style


## Thin cyan outline: visible for keyboard users, but unlike reusing the hover
## box it doesn't look like the last-clicked button is stuck highlighted.
static func focus_ring(radius: int = 10) -> StyleBoxFlat:
	var ring := StyleBoxFlat.new()
	ring.draw_center = false
	ring.border_color = Color(0.22, 0.74, 0.97, 0.55)
	ring.set_border_width_all(1)
	ring.set_corner_radius_all(radius)
	ring.set_expand_margin_all(2)
	return ring


static func ui_font(weight: int = 500) -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Segoe UI", "SF Pro Display", "Inter", "Roboto", "Helvetica Neue", "Arial", "sans-serif"])
	font.font_weight = weight
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	return font


static func monospace_font() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])
	return font
