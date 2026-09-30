class_name Icons
extends RefCounted
## Small line icons for buttons and headings, drawn once from signed-distance
## shapes into white textures (tinted by the button's icon_* theme colours).
## No image assets to ship or license, crisp at any size, and cheap: each
## icon is a few hundred pixels rasterised on first use, then cached.
##
## Shapes live on a 24 x 24 grid; strokes are STROKE units wide.

const GRID := 24.0
const STROKE := 1.1
const NAMES: Array[String] = ["speaker", "speaker_off", "replay", "menu", "pause", "skip", "play",
		"stopwatch", "target", "bolt", "tip", "code", "check", "cross", "clock", "calculator"]

static var _cache: Dictionary = {}


static func texture(icon: String, px: int = 18) -> ImageTexture:
	var key := "%s@%d" % [icon, px]
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(_render(icon, px))
	return _cache[key]


static func _render(icon: String, px: int) -> Image:
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	var unit := GRID / float(px)
	for y in px:
		for x in px:
			var p := (Vector2(x, y) + Vector2(0.5, 0.5)) * unit
			var coverage := clampf(0.5 - sdf(icon, p) / unit, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, coverage))
	return img


## Signed distance from p (grid units) to the icon's ink; negative inside.
static func sdf(icon: String, p: Vector2) -> float:
	match icon:
		"speaker":
			return minf(_speaker_body(p), minf(_arc(p, Vector2(12, 12), 4.2, -0.8, 0.8), _arc(p, Vector2(12, 12), 7.6, -0.85, 0.85)) - STROKE)
		"speaker_off":
			return minf(_speaker_body(p), minf(_seg(p, Vector2(15.5, 9), Vector2(21, 15)), _seg(p, Vector2(21, 9), Vector2(15.5, 15))) - STROKE)
		"replay":
			var ring := _arc(p, Vector2(12, 12.5), 7.0, -2.2, 2.9) - STROKE
			return minf(ring, _poly(p, PackedVector2Array([Vector2(1.8, 7.8), Vector2(8.6, 6.4), Vector2(5.0, 12.2)])))
		"menu":
			return minf(_seg(p, Vector2(5, 7), Vector2(19, 7)), minf(_seg(p, Vector2(5, 12), Vector2(19, 12)), _seg(p, Vector2(5, 17), Vector2(19, 17)))) - STROKE
		"pause":
			return minf(_box(p, Vector2(8.5, 12), Vector2(1.6, 6.5)), _box(p, Vector2(15.5, 12), Vector2(1.6, 6.5))) - 0.4
		"skip":
			return minf(_poly(p, PackedVector2Array([Vector2(5.5, 5.5), Vector2(15, 12), Vector2(5.5, 18.5)])), _box(p, Vector2(17.8, 12), Vector2(1.2, 6.5)))
		"play":
			return _poly(p, PackedVector2Array([Vector2(7, 5), Vector2(19, 12), Vector2(7, 19)])) - 0.3
		"stopwatch":
			var face := absf(p.distance_to(Vector2(12, 13.5)) - 7.2)
			var hand := _seg(p, Vector2(12, 13.5), Vector2(14.6, 10.2))
			var crown := minf(_seg(p, Vector2(9.8, 3.4), Vector2(14.2, 3.4)), _seg(p, Vector2(12, 3.4), Vector2(12, 6.3)))
			return minf(face, minf(hand, crown)) - STROKE
		"target":
			var rings := minf(absf(p.distance_to(Vector2(12, 12)) - 8.0), absf(p.distance_to(Vector2(12, 12)) - 4.4)) - STROKE
			return minf(rings, p.distance_to(Vector2(12, 12)) - 1.7)
		"bolt":
			return _poly(p, UiFx.bolt_points(Vector2(12, 12), 20.0))
		"tip":
			var bulb := absf(p.distance_to(Vector2(12, 10)) - 5.6)
			var base := minf(_seg(p, Vector2(9.6, 17.2), Vector2(14.4, 17.2)), _seg(p, Vector2(10.4, 20.2), Vector2(13.6, 20.2)))
			return minf(bulb, base) - STROKE
		"code":
			var page := absf(_box(p, Vector2(12, 12), Vector2(6.5, 8.5)))
			var lines := minf(_seg(p, Vector2(9, 9), Vector2(15, 9)), minf(_seg(p, Vector2(9, 12.5), Vector2(15, 12.5)), _seg(p, Vector2(9, 16), Vector2(13, 16))))
			return minf(page, lines) - STROKE
		"check":
			return minf(_seg(p, Vector2(5, 12.5), Vector2(10, 17.5)), _seg(p, Vector2(10, 17.5), Vector2(19.5, 7))) - STROKE * 1.2
		"cross":
			return minf(_seg(p, Vector2(6.5, 6.5), Vector2(17.5, 17.5)), _seg(p, Vector2(17.5, 6.5), Vector2(6.5, 17.5))) - STROKE * 1.2
		"clock":
			var dial := absf(p.distance_to(Vector2(12, 12)) - 8.0)
			return minf(dial, minf(_seg(p, Vector2(12, 12), Vector2(12, 7)), _seg(p, Vector2(12, 12), Vector2(15.5, 14)))) - STROKE
		"calculator":
			var body := absf(_box(p, Vector2(12, 12), Vector2(6.5, 8.8)) - 0.8) - STROKE
			var screen := _box(p, Vector2(12, 7.2), Vector2(3.8, 1.4))
			var dots := 1e6
			for row in 3:
				for col in 3:
					dots = minf(dots, p.distance_to(Vector2(8.8 + col * 3.2, 11.8 + row * 3.1)) - 1.0)
			return minf(body, minf(screen, dots))
	return 1e6


static func _speaker_body(p: Vector2) -> float:
	return _poly(p, PackedVector2Array([Vector2(3, 9), Vector2(7, 9), Vector2(12, 4.8), Vector2(12, 19.2), Vector2(7, 15), Vector2(3, 15)]))


static func _seg(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	return p.distance_to(a + ab * clampf((p - a).dot(ab) / ab.dot(ab), 0.0, 1.0))


static func _box(p: Vector2, center: Vector2, half: Vector2) -> float:
	var d := (p - center).abs() - half
	return Vector2(maxf(d.x, 0.0), maxf(d.y, 0.0)).length() + minf(maxf(d.x, d.y), 0.0)


## Distance to the arc of radius r around c between angles a0 and a1
## (radians, y down, a0 < a1).
static func _arc(p: Vector2, c: Vector2, r: float, a0: float, a1: float) -> float:
	var v := p - c
	var a := atan2(v.y, v.x)
	if a >= a0 and a <= a1:
		return absf(v.length() - r)
	var e0 := c + Vector2(cos(a0), sin(a0)) * r
	var e1 := c + Vector2(cos(a1), sin(a1)) * r
	return minf(p.distance_to(e0), p.distance_to(e1))


## Signed distance to a simple polygon (negative inside).
static func _poly(p: Vector2, v: PackedVector2Array) -> float:
	var d := (p - v[0]).length_squared()
	var s := 1.0
	var j := v.size() - 1
	for i in v.size():
		var e := v[j] - v[i]
		var w := p - v[i]
		var b := w - e * clampf(w.dot(e) / e.dot(e), 0.0, 1.0)
		d = minf(d, b.length_squared())
		var c1 := p.y >= v[i].y
		var c2 := p.y < v[j].y
		var c3 := e.x * w.y > e.y * w.x
		if (c1 and c2 and c3) or (not c1 and not c2 and not c3):
			s = -s
		j = i
	return s * sqrt(d)
