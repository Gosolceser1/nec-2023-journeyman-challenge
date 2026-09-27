extends SceneTree
## Safe-area regression guard.
##
## WHY THIS EXISTS: a rewrite of _apply_safe_area() computed the bottom inset as
## `safe_area.size.y - safe_area.position.y` — the safe rect's own HEIGHT, not
## the gap below it. On a 1080x2400 phone that produced a ~1100px bottom margin
## and collapsed the content box: the app booted, drew its header and dock, and
## showed NO question and NO answer cards. The 342-check scene harness stayed
## GREEN throughout, because it asserts quiz LOGIC and never inspects a margin.
##
## This calls the REAL main.gd:static safe_area_margins() with synthetic
## insets, so it cannot drift away from the shipped arithmetic. A first version
## of this test re-implemented the math locally and passed against the broken
## code — which proved nothing.

var failures: Array[String] = []
var checks := 0

func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func _init() -> void:
	var main_script = load("res://src/app/main.gd")
	if main_script == null:
		print("  FAIL: could not load main.gd")
		quit(1)
		return
	print("=== SAFE AREA MARGIN MATH (against the real safe_area_margins) ===")

	# screen_w/h: physical pixels.  vp_w/h: stretched canvas units.
	_geom(main_script, 1080, 2400, 540, 1200, Rect2i(0, 63, 1080, 2274), [], "Pixel 7, status + gesture")
	_geom(main_script, 1080, 2400, 540, 1200, Rect2i(0, 0, 1080, 2400), [], "no insets at all")
	_geom(main_script, 1536, 2048, 720, 960, Rect2i(0, 0, 1536, 2048), [], "tablet, no insets")
	_geom(main_script, 1080, 2400, 540, 1200, Rect2i(0, 63, 1080, 2400 - 63), [], "gesture nav only")
	_geom(main_script, 1080, 2400, 540, 1200, Rect2i(0, 0, 1080, 2400), [Rect2(440, 0, 200, 120)], "punch-hole, symmetric")
	_geom(main_script, 2400, 1080, 1200, 540, Rect2i(63, 0, 2400 - 63, 1080), [], "landscape, cutout on a side")
	_geom(main_script, 1080, 2400, 540, 1200, Rect2i(0, 63, 1080, 2274), [Rect2(0, 0, 200, 120)], "notch + cutout union")

	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	for f in failures:
		print("  - %s" % f)
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)


func _geom(main_script, sw: int, sh: int, vw: float, vh: float,
		safe: Rect2i, cutouts: Array, label: String) -> void:
	var m: Dictionary = main_script.safe_area_margins(
		Vector2(vw, vh), Vector2i(sw, sh), safe, cutouts, true)
	var top: int = int(m["top"])
	var bottom: int = int(m["bottom"])
	var side: int = int(m["side"])
	print("  %-28s -> T%-4d B%-4d S%-4d (usable H %0.f of %0.f)" % [
		label, top, bottom, side, vh - float(top) - float(bottom), vh])

	# The regression guard: a bottom margin anywhere near the viewport height
	# means the content box has collapsed to a blank strip.
	check(bottom < vh * 0.25,
		"%s: bottom_margin %d >= 25%% of the %0.fpx viewport — content collapsed" % [label, bottom, vh])
	check(vh - float(top) - float(bottom) > vh * 0.5,
		"%s: usable height %0.f of %0.f is too small to show a question" % [label, vh - float(top) - float(bottom), vh])
	# Insets must never exceed the screen they inset, nor go negative.
	check(bottom <= vh, "%s: bottom_margin %d exceeds the %0.fpx viewport" % [label, bottom, vh])
	check(top <= vh, "%s: top_margin %d exceeds the %0.fpx viewport" % [label, top, vh])
	check(side * 2.0 < vw, "%s: side margins %d each do not fit in %0.fpx" % [label, side, vw])
	# The menu panel must fit inside the side margins (it clips, not scrolls).
	var panel: float = clampf(vw - float(side) * 2.0 - 16.0, 288.0, vw)
	check(panel + float(side) * 2.0 <= vw,
		"%s: menu panel %0.f plus %d margins overflows %0.fpx" % [label, panel, side, vw])
