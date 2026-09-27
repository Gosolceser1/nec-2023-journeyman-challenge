class_name SafeArea
extends RefCounted
## Pure margin math for notches, cutouts and gesture bars, kept node-free so
## tools/tests/test_safe_area.gd can exercise the real function instead of a
## copy that can silently drift out of sync.
##
## vp_size / safe_area are in different spaces: get_display_safe_area() and
## get_display_cutouts() return PHYSICAL-SCREEN pixels, while the UI lays out in
## stretched canvas units, so every inset is scaled by vp_size.x / win_size.x.
##
## safe_area is a RECT, not a set of edge distances: the bottom inset is the gap
## from the rect's BOTTOM EDGE to the screen bottom, i.e.
## (screen_height - (pos.y + size.y)). Using (size.y - pos.y) instead measures
## the rect's own height and produced ~1100px margins that collapsed the content
## box to a blank strip - the app drew its header and dock and showed no
## question at all.

## Returns {"top", "bottom", "side"} margins in canvas units.
static func margins(vp_size: Vector2, win_size: Vector2i, safe_area: Rect2i,
		cutouts: Array, is_mobile: bool) -> Dictionary:
	var top_margin: int = 16 if is_mobile else 24
	var bottom_margin: int = 16 if is_mobile else 24
	var side_margin: int = 16 if is_mobile else 20

	var scale: float = 1.0
	if win_size.x > 0:
		scale = vp_size.x / float(win_size.x)
	if scale <= 0.0:
		scale = 1.0

	var top_inset := 0.0
	var bottom_inset := 0.0
	var left_inset := 0.0
	var right_inset := 0.0
	if safe_area.size.y > 0 and vp_size.y > 0:
		top_inset = float(safe_area.position.y) * scale
		bottom_inset = maxf(0.0, (float(win_size.y) - float(safe_area.position.y + safe_area.size.y)) * scale)
	if safe_area.size.x > 0 and vp_size.x > 0:
		left_inset = float(safe_area.position.x) * scale
		right_inset = maxf(0.0, (float(win_size.x) - float(safe_area.position.x + safe_area.size.x)) * scale)
	# A cutout is a LOCALISED hole, not an edge-to-edge inset, so it must not be
	# max()'d against the full screen width/height. Only count a cutout towards
	# an edge when it actually touches that edge, and clamp the result so a
	# malformed rect can never eat the whole screen.
	for rect_v in cutouts:
		var rect := rect_v as Rect2
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		var touches_top: bool = rect.position.y <= 1.0
		var touches_left: bool = rect.position.x <= 1.0
		var touches_right: bool = (rect.position.x + rect.size.x) >= float(win_size.x) - 1.0
		# A cutout on the top edge, or a notch that spans the full width, does
		# need top padding. Side notches only inset their own side.
		if touches_top:
			top_inset = maxf(top_inset, float(rect.position.y + rect.size.y) * scale)
		if touches_left:
			left_inset = maxf(left_inset, float(rect.position.x + rect.size.x) * scale)
		if touches_right:
			right_inset = maxf(right_inset, (float(win_size.x) - float(rect.position.x)) * scale)
	# An inset may never exceed the viewport it insets; clamp before use.
	top_inset = clampf(top_inset, 0.0, vp_size.y * 0.25)
	bottom_inset = clampf(bottom_inset, 0.0, vp_size.y * 0.25)
	left_inset = clampf(left_inset, 0.0, vp_size.x * 0.25)
	right_inset = clampf(right_inset, 0.0, vp_size.x * 0.25)

	# Padding beyond the raw inset keeps content clear of the bar edge and of
	# the mandatory system gesture zones along the bottom.
	if top_inset > 0.0:
		top_margin = maxi(top_margin, int(round(top_inset)) + 8)
	if bottom_inset > 0.0:
		bottom_margin = maxi(bottom_margin, int(round(bottom_inset)) + 12)
	if left_inset > 0.0 or right_inset > 0.0:
		side_margin = maxi(side_margin, int(round(maxf(left_inset, right_inset))) + 8)
	return {"top": top_margin, "bottom": bottom_margin, "side": side_margin}
