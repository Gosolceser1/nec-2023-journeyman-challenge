class_name MathPicture
extends Control
## Draws a formula card picture (data/math/formula_cards.json "picture"):
## primitives in the picture's own units, scaled to fit this control and
## centred. Text positions are the centre of the text.

const COLORS := {
	"sky": AppTheme.SKY_400,
	"amber": AppTheme.AMBER_400,
	"emerald": AppTheme.EMERALD_400,
	"rose": AppTheme.ROSE_400,
	"violet": AppTheme.VIOLET_400,
	"slate": AppTheme.SLATE_400,
	"dim": AppTheme.SLATE_600,
	"white": AppTheme.SLATE_50,
}
const DIM_ALPHA := 0.22

var picture: Dictionary = {}:
	set(v):
		picture = v
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


static func color_of(name: String) -> Color:
	if name.ends_with("_dim"):
		return Color(COLORS.get(name.trim_suffix("_dim"), AppTheme.SLATE_400), DIM_ALPHA)
	return COLORS.get(name, AppTheme.SLATE_300)


func _draw() -> void:
	var src: Array = picture.get("size", [])
	if src.size() != 2 or float(src[0]) <= 0.0 or float(src[1]) <= 0.0:
		return
	var k := minf(size.x / float(src[0]), size.y / float(src[1]))
	var off := (size - Vector2(float(src[0]), float(src[1])) * k) * 0.5
	var at := func(p: Array) -> Vector2: return off + Vector2(float(p[0]), float(p[1])) * k
	for item in picture.get("items", []):
		var col := color_of(str(item.get("color", "slate")))
		var w := maxf(1.0, float(item.get("w", 2)) * k)
		var fill := str(item.get("fill", ""))
		match str(item.get("t", "")):
			"circle":
				var r := float(item.get("r", 4)) * k
				if fill != "":
					draw_circle(at.call(item["c"]), r, color_of(fill))
				draw_arc(at.call(item["c"]), r, 0.0, TAU, 48, col, w, true)
			"line":
				draw_line(at.call(item["a"]), at.call(item["b"]), col, w, true)
			"rect":
				var rect := Rect2(at.call(item["p"]), Vector2(float(item["s"][0]), float(item["s"][1])) * k)
				var box := StyleBoxFlat.new()
				box.bg_color = color_of(fill) if fill != "" else Color.TRANSPARENT
				box.border_color = col
				box.set_border_width_all(int(round(w)))
				box.set_corner_radius_all(int(float(item.get("r", 0)) * k))
				box.anti_aliasing = true
				draw_style_box(box, rect)
			"poly":
				var pts := PackedVector2Array()
				for p in item.get("pts", []):
					pts.append(at.call(p))
				if fill != "" and pts.size() >= 3:
					draw_colored_polygon(pts, color_of(fill))
				if bool(item.get("closed", false)) and pts.size() > 0:
					pts.append(pts[0])
				draw_polyline(pts, col, w, true)
			"zigzag":
				_zigzag(at.call(item["a"]), at.call(item["b"]), col, w, k)
			"arc":
				draw_arc(at.call(item["c"]), float(item.get("r", 10)) * k,
					deg_to_rad(float(item.get("from", 0))), deg_to_rad(float(item.get("to", 180))), 32, col, w, true)
			"text":
				_text(at.call(item["p"]), str(item.get("text", "")), maxi(8, int(float(item.get("size", 14)) * k)), col, bool(item.get("bold", false)))


## A resistor symbol: short leads and six peaks between a and b.
func _zigzag(a: Vector2, b: Vector2, col: Color, w: float, k: float) -> void:
	var dir := (b - a).normalized()
	var normal := Vector2(-dir.y, dir.x)
	var length := a.distance_to(b)
	var lead := length * 0.15
	var pts := PackedVector2Array([a, a + dir * lead])
	var peaks := 6
	var step := (length - lead * 2.0) / peaks
	for i in peaks:
		pts.append(a + dir * (lead + step * (i + 0.5)) + normal * (6.0 * k) * (1 if i % 2 == 0 else -1))
	pts.append(b - dir * lead)
	pts.append(b)
	draw_polyline(pts, col, w, true)


func _text(center: Vector2, text: String, font_size: int, col: Color, bold: bool) -> void:
	var font: Font = AppTheme.ui_font(AppTheme.WEIGHT_BOLD if bold else AppTheme.WEIGHT_MEDIUM)
	var dims := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := center + Vector2(-dims.x * 0.5, font.get_ascent(font_size) - dims.y * 0.5)
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
