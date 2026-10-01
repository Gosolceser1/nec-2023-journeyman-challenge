class_name DiagramView
extends Control

## A question's figure. Either an original study figure
## (assets/diagrams/nec/figures.json, from tools/diagrams/build.py), dark slate
## art shown on a dark card, or a crop of a scanned exam page
## (assets/diagrams/diagrams.json, from tools/pipeline/extract_diagrams.py;
## none ship now), shown on a paper-white card. Records with
## neither fall back to their ASCII "diagram" text in a monospace font. The
## drawing scales to the width it is given (no minimum width, no wrapping) and
## a tap opens it fullscreen.
##
## Pre-answer nothing is marked, and any region of the picture that would give
## the answer away (data/diagram_masks.json) is covered by an opaque "?" badge.
## reveal(correct_index) fades the badges out (instantly with Reduce motion),
## rings the regions flagged "ring" and outlines the part of the figure the
## answer key points at (the mapping's "highlight" box). The badges are drawn
## in image space, so they scale with the figure inline and in the zoom.
## A figure mapped "when": "after" teaches rather than sets up: it has nothing
## to draw until the question is answered.

const MAP_PATH := "res://assets/diagrams/diagrams.json"
const NEC_MAP_PATH := "res://assets/diagrams/nec/figures.json"
const MASKS_PATH := "res://data/diagram_masks.json"
const MASK_FADE := 0.22
const PAD := 4.0
const TAP_SLOP := 14.0
const HINT_GUTTER := 36.0
const INK := AppTheme.SLATE_900
const HIGHLIGHT := AppTheme.EMERALD_500

static var _map: Dictionary = {}
static var _loaded := false
static var _mask_map: Dictionary = {}
static var _record_masks: Dictionary = {}
static var _masks_loaded := false
static var _textures: Dictionary = {}
static var _mono_font: SystemFont

var figure: Dictionary = {}
var texture: Texture2D
var ascii_lines: PackedStringArray = PackedStringArray()
var revealed := false
## Mask entries for the current figure: {"rect": [x, y, w, h], "label", "ring"}.
var masks: Array = []
var answered := false
## 1 = badges fully drawn (pre-answer), 0 = gone.
var mask_alpha := 1.0
var _mask_tween: Tween
## Tallest the figure may grow while following the width's aspect ratio.
var max_height := 220.0:
	set(v):
		max_height = v
		_update_height()
var min_height := MIN_H
const MIN_H := 64.0
## A thin tappable strip: a small thumbnail and "tap to enlarge", for a phone
## screen where even the smallest figure would scroll. The zoom is unchanged.
const STRIP_H := 40.0
var compact := false:
	set(v):
		compact = v
		min_height = STRIP_H if v else MIN_H
		_update_height()
		queue_redraw()
const HEIGHT_PASSES := 4
var _height_frame := -1
var _height_passes := 0
var _press_pos := Vector2.INF
var _zoom: CanvasLayer


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tooltip_text = "Click to enlarge"
	resized.connect(_update_height)


func _make_custom_tooltip(for_text: String) -> Object:
	return Tooltip.make(for_text)


static func _read_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}


## A scanned crop, if one is mapped, wins over an original figure for the same record.
static func _load_map() -> void:
	if _loaded:
		return
	_loaded = true
	_map = _read_json(NEC_MAP_PATH)
	_map.merge(_read_json(MAP_PATH), true)


static func figure_for(record_id: String) -> Dictionary:
	_load_map()
	return _map.get(record_id, {})


static func all_figures() -> Dictionary:
	_load_map()
	return _map


static func mask_map() -> Dictionary:
	if not _masks_loaded:
		_masks_loaded = true
		var parsed := _read_json(MASKS_PATH)
		if parsed.get("diagrams") is Dictionary:
			_mask_map = parsed["diagrams"]
		if parsed.get("records") is Dictionary:
			_record_masks = parsed["records"]
	return _mask_map


static func record_mask_map() -> Dictionary:
	mask_map()
	return _record_masks


static func masks_for_file(file: String) -> Array:
	var entry = mask_map().get(file.get_file(), {})
	return (entry.get("masks", []) as Array).duplicate(true) if entry is Dictionary else []


## A record's own masks (shared original figures mask per question), else the
## figure file's.
static func masks_for(record_id: String, file: String) -> Array:
	var entry = record_mask_map().get(record_id)
	if entry is Dictionary:
		return (entry.get("masks", []) as Array).duplicate(true)
	return masks_for_file(file)


static func is_dark_figure(fig: Dictionary) -> bool:
	return str(fig.get("style", "")) == "dark"


static func shows_before_answer(fig: Dictionary) -> bool:
	return str(fig.get("when", "before")) != "after"


## The figure card: paper white for the black-on-white scans, slate for the
## dark original figures.
static func card_style(dark: bool) -> StyleBox:
	return AppTheme.surface(AppTheme.SLATE_900 if dark else AppTheme.SLATE_50, AppTheme.SKY_400 if not dark else AppTheme.SKY_700, AppTheme.ELEVATION_REST, AppTheme.RADIUS_INNER)


static func has_figure(record: Dictionary) -> bool:
	return not figure_for(str(record.get("id", ""))).is_empty() \
			or str(record.get("diagram", "")).strip_edges() != ""


## Text the app itself puts on screen for a figure: none for PDF crops (their
## labels are the printed original), the ASCII lines for the fallback.
static func added_text(record: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	if figure_for(str(record.get("id", ""))).is_empty():
		for ln in str(record.get("diagram", "")).split("\n"):
			if ln.strip_edges() != "":
				out.append(ln)
	return out


## Mipmapped copy: the scans are drawn well below their 300 dpi size, and
## without mipmaps thin lines alias away.
static func _texture(path: String) -> Texture2D:
	if _textures.has(path):
		return _textures[path]
	var tex: Texture2D = null
	var src := load(path) as Texture2D
	if src != null:
		var img := src.get_image()
		if img != null:
			if img.is_compressed():
				img.decompress()
			img.generate_mipmaps()
			tex = ImageTexture.create_from_image(img)
		else:
			tex = src
	_textures[path] = tex
	return tex


static func mono_font() -> SystemFont:
	if _mono_font == null:
		_mono_font = SystemFont.new()
		_mono_font.font_names = PackedStringArray(["Cascadia Mono", "Consolas", "DejaVu Sans Mono", "Liberation Mono", "Menlo", "Courier New", "monospace"])
	return _mono_font


## Returns whether the record has anything to draw.
func show_record(record: Dictionary) -> bool:
	close_zoom()
	figure = figure_for(str(record.get("id", "")))
	texture = _texture(str(figure.get("file", ""))) if not figure.is_empty() else null
	ascii_lines = PackedStringArray()
	if texture == null:
		figure = {}
		var text := str(record.get("diagram", "")).strip_edges(false, true)
		while text.begins_with("\n"):
			text = text.substr(1)
		if text != "":
			ascii_lines = text.split("\n")
	masks = masks_for(str(record.get("id", "")), str(figure.get("file", ""))) if texture != null else []
	revealed = false
	answered = false
	_set_mask_alpha(1.0)
	_update_height()
	queue_redraw()
	return has_content()


## Something to draw right now (an "after" figure has nothing until answered).
func has_content() -> bool:
	if texture != null:
		return answered or shows_before_answer(figure)
	return not ascii_lines.is_empty()


func is_dark() -> bool:
	return texture != null and is_dark_figure(figure)


## Returns whether the figure is on screen after answering.
func reveal(_correct_index: int, instant := false) -> bool:
	var was_hidden := not has_content()
	answered = true
	revealed = figure.has("highlight")
	if masks.is_empty() or instant or not is_inside_tree() or was_hidden:
		_set_mask_alpha(0.0)
	else:
		_mask_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_mask_tween.tween_method(_set_mask_alpha, 1.0, 0.0, MASK_FADE)
	if was_hidden:
		_update_height()
	_redraw_all()
	return has_content()


func is_revealed() -> bool:
	return revealed


## True while any "?" badge is still (even partly) drawn.
func is_masked() -> bool:
	return texture != null and not masks.is_empty() and mask_alpha > 0.0


func _set_mask_alpha(a: float) -> void:
	if a >= 1.0 and _mask_tween != null and _mask_tween.is_valid():
		_mask_tween.kill()
	mask_alpha = a
	_redraw_all()


func _redraw_all() -> void:
	queue_redraw()
	if is_instance_valid(_zoom):
		_zoom.get_child(0).queue_redraw()


## Where the picture lands inside `area` (aspect kept, centred).
func image_rect(area: Rect2) -> Rect2:
	var c := _canvas()
	if texture == null or c.x <= 0.0:
		return Rect2()
	var s := minf(area.size.x / c.x, area.size.y / c.y)
	return Rect2(area.position + (area.size - c * s) * 0.5, c * s)


## The mask badges as they would be drawn in `area` right now (empty once gone).
func mask_rects(area: Rect2) -> Array[Rect2]:
	var out: Array[Rect2] = []
	if not is_masked():
		return out
	var rect := image_rect(area)
	for m in masks:
		out.append(_mask_box(rect, m))
	return out


static func _mask_box(rect: Rect2, m: Dictionary) -> Rect2:
	var r: Array = m.get("rect", [0, 0, 0, 0])
	return Rect2(rect.position + Vector2(float(r[0]), float(r[1])) * rect.size,
			Vector2(float(r[2]), float(r[3])) * rect.size)


func is_zoomed() -> bool:
	return is_instance_valid(_zoom)


## Called by main's touch pass (and a scroll start): drop a pending tap.
func cancel_press() -> void:
	_press_pos = Vector2.INF


func _canvas() -> Vector2:
	if texture != null:
		return Vector2(texture.get_width(), texture.get_height())
	if ascii_lines.is_empty():
		return Vector2.ZERO
	var font := mono_font()
	var cols := 0
	for ln in ascii_lines:
		cols = maxi(cols, ln.length())
	var cw := font.get_string_size("M", HORIZONTAL_ALIGNMENT_LEFT, -1, 100).x / 100.0
	return Vector2(maxf(1.0, cols * cw), ascii_lines.size() * font.get_height(100) / 100.0)


func _update_height() -> void:
	if not has_content():
		custom_minimum_size = Vector2.ZERO
		return
	var c := _canvas()
	if c.x <= 0.0 or size.x <= PAD * 2.0:
		custom_minimum_size = Vector2(0, min_height if has_content() else 0.0)
		return
	var h := clampf((size.x - PAD * 2.0 - HINT_GUTTER) * c.y / c.x + PAD * 2.0, min_height, max_height)
	# The height follows the width, and the width can depend on the height (a
	# page scrollbar that appears only while the figure is taller). Within one
	# frame that ping-pongs until the engine's message queue overflows, so
	# after a few passes the figure may only shrink.
	var frame := Engine.get_process_frames()
	if frame != _height_frame:
		_height_frame = frame
		_height_passes = 0
	_height_passes += 1
	if _height_passes > HEIGHT_PASSES and h > custom_minimum_size.y:
		return
	custom_minimum_size = Vector2(0, h)


func _draw() -> void:
	var area := Rect2(Vector2.ZERO, size).grow(-PAD)
	if has_content() and size.x > 60.0:
		# The magnifier gets its own gutter so it never sits on the art.
		area.size.x -= HINT_GUTTER
		area.position.x += HINT_GUTTER * 0.5
		_draw_zoom_hint()
	if compact and texture != null and has_content():
		var c := _canvas()
		var thumb := Rect2(area.position, Vector2(minf(area.size.x * 0.4, area.size.y * c.x / c.y), area.size.y))
		draw_figure(self, thumb, 0.5)
		var font := get_theme_default_font()
		var fs := 14
		var x := thumb.end.x + 10.0
		draw_string(font, Vector2(x, size.y * 0.5 + font.get_ascent(fs) * 0.5 - 1.0), "Figure: tap to enlarge",
				HORIZONTAL_ALIGNMENT_LEFT, maxf(1.0, area.end.x - x), fs, AppTheme.SKY_400 if is_dark() else AppTheme.SKY_700)
		return
	draw_figure(self, area, 1.0)


## Shared by the inline view and the fullscreen zoom.
func draw_figure(ci: CanvasItem, area: Rect2, line_scale: float) -> void:
	var c := _canvas()
	if c.x <= 0.0 or area.size.x <= 1.0 or area.size.y <= 1.0 or not has_content():
		return
	if texture != null:
		var rect := image_rect(area)
		ci.draw_texture_rect(texture, rect, false)
		_draw_masks(ci, rect, line_scale)
		if revealed:
			var h: Array = figure["highlight"]
			var box := Rect2(rect.position + Vector2(float(h[0]), float(h[1])) * rect.size,
					Vector2(float(h[2]), float(h[3])) * rect.size)
			box = box.intersection(rect.grow(2.0))
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(HIGHLIGHT, 0.12)
			sb.border_color = HIGHLIGHT
			sb.set_border_width_all(int(round(2.5 * line_scale)))
			sb.set_corner_radius_all(int(round(6 * line_scale)))
			ci.draw_style_box(sb, box)
		return
	var font := mono_font()
	var fs := maxi(6, int(floor(minf(14.0 * line_scale, minf(area.size.x / c.x, area.size.y / c.y)))))
	var lh := font.get_height(fs)
	var block := Vector2(c.x * fs, ascii_lines.size() * lh)
	var origin := area.position + ((area.size - block) * 0.5).max(Vector2.ZERO)
	for i in ascii_lines.size():
		ci.draw_string(font, origin + Vector2(0, i * lh + font.get_ascent(fs)), ascii_lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)


## Opaque "?" badges over the masked regions; after answering they shrink and
## fade, and regions flagged "ring" get an answer outline.
func _draw_masks(ci: CanvasItem, rect: Rect2, line_scale: float) -> void:
	if masks.is_empty():
		return
	var font := ThemeDB.fallback_font
	for m in masks:
		var box := _mask_box(rect, m)
		if answered and bool(m.get("ring", false)) and mask_alpha < 1.0:
			var ring := StyleBoxFlat.new()
			ring.draw_center = false
			ring.border_color = Color(HIGHLIGHT, 1.0 - mask_alpha)
			ring.set_border_width_all(int(round(2.5 * line_scale)))
			ring.set_corner_radius_all(int(round(6 * line_scale)))
			ci.draw_style_box(ring, box.grow(3.0 * line_scale))
		if mask_alpha <= 0.0:
			continue
		var shrink := (1.0 - mask_alpha) * minf(box.size.x, box.size.y) * 0.25
		var b := box.grow(1.0 - shrink)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(AppTheme.SLATE_900, mask_alpha)
		sb.border_color = Color(AppTheme.SKY_400, mask_alpha)
		sb.set_border_width_all(maxi(1, int(round(2.0 * line_scale))))
		sb.set_corner_radius_all(int(minf(b.size.y * 0.3, 10.0 * line_scale)))
		ci.draw_style_box(sb, b)
		var label := str(m.get("label", "?"))
		var fs := int(clampf(b.size.y * 0.62, 8.0, 44.0 * line_scale))
		var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		while tw > b.size.x * 0.9 and fs > 8:
			fs -= 1
			tw = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var base := b.position + Vector2((b.size.x - tw) * 0.5, (b.size.y + font.get_ascent(fs) - font.get_descent(fs)) * 0.5)
		ci.draw_string(font, base, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(AppTheme.AMBER_400, mask_alpha))


## Small magnifier in the corner: the figure opens bigger.
func _draw_zoom_hint() -> void:
	var r := 7.0
	var c := Vector2(size.x - r - 5.0, size.y - r - 5.0)
	var ink := AppTheme.SKY_400 if is_dark() else AppTheme.SKY_700
	draw_circle(c, r + 4.0, Color(0.06, 0.09, 0.16, 0.10))
	draw_arc(c + Vector2(-1.5, -1.5), 4.0, 0.0, TAU, 20, ink, 1.6, true)
	draw_line(c + Vector2(1.4, 1.4), c + Vector2(4.5, 4.5), ink, 1.8, true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_SCROLL_BEGIN:
		_press_pos = Vector2.INF


func _gui_input(event: InputEvent) -> void:
	if not has_content():
		return
	# project.godot turns mouse emulation off, so a finger only ever arrives as
	# ScreenTouch / ScreenDrag.
	if event is InputEventScreenTouch:
		if event.pressed:
			_press_pos = event.position
		elif _press_pos != Vector2.INF and event.position.distance_to(_press_pos) <= TAP_SLOP:
			_press_pos = Vector2.INF
			open_zoom()
		return
	if event is InputEventScreenDrag:
		if _press_pos != Vector2.INF and event.position.distance_to(_press_pos) > TAP_SLOP:
			_press_pos = Vector2.INF
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_pos = event.position
		elif _press_pos != Vector2.INF and event.position.distance_to(_press_pos) <= TAP_SLOP:
			_press_pos = Vector2.INF
			open_zoom()
	elif event is InputEventMouseMotion and _press_pos != Vector2.INF:
		if event.position.distance_to(_press_pos) > TAP_SLOP:
			_press_pos = Vector2.INF


func open_zoom() -> void:
	if is_instance_valid(_zoom) or not has_content():
		return
	_zoom = CanvasLayer.new()
	_zoom.layer = 90
	var sheet := _ZoomSheet.new()
	sheet.view = self
	_zoom.add_child(sheet)
	add_child(_zoom)


func close_zoom() -> void:
	if is_instance_valid(_zoom):
		_zoom.queue_free()
	_zoom = null


func _exit_tree() -> void:
	close_zoom()


class _ZoomSheet extends Control:
	const HINT_STRIP := 30.0
	var view: DiagramView

	func _init() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	func _ready() -> void:
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 0.14)

	## The figure's card; the close hint sits in a strip under it (HINT_STRIP).
	func _card_rect() -> Rect2:
		var vp := get_viewport_rect().size
		var avail := Rect2(Vector2(vp.x * 0.04, vp.y * 0.08), Vector2(vp.x * 0.92, vp.y * 0.80 - HINT_STRIP))
		var c := view._canvas()
		if c.x <= 0.0:
			return avail
		var inner := avail.size - Vector2(32, 32)
		var s := minf(inner.x / c.x, inner.y / c.y)
		var card := c * s + Vector2(32, 32)
		return Rect2(avail.position + (avail.size - card) * 0.5, card)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.01, 0.03, 0.07, 0.9))
		var card := _card_rect()
		var sb := StyleBoxFlat.new()
		sb.bg_color = AppTheme.SLATE_900 if view.is_dark() else AppTheme.SLATE_50
		sb.border_color = AppTheme.SKY_400
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(14)
		# The hint lives inside the card, so it never lands on the page text
		# (choice A on phones) that shows through the backdrop.
		draw_style_box(sb, Rect2(card.position, card.size + Vector2(0, HINT_STRIP)))
		view.draw_figure(self, card.grow(-16), 1.6)
		var font := get_theme_default_font()
		var hint := "Tap anywhere to close" if OS.has_feature("mobile") else "Click anywhere or press Esc to close"
		var fs := 15
		var w := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var base_y := card.end.y + (HINT_STRIP - font.get_height(fs)) * 0.5 - 6 + font.get_ascent(fs)
		draw_string(font, Vector2(card.get_center().x - w * 0.5, base_y), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
				AppTheme.SLATE_400 if view.is_dark() else AppTheme.SLATE_600)

	func _gui_input(event: InputEvent) -> void:
		if (event is InputEventMouseButton or event is InputEventScreenTouch) and not event.pressed:
			accept_event()
			view.close_zoom()

	func _input(event: InputEvent) -> void:
		# Android Back goes to the host's debounced go-back handler, which closes
		# the zoom; closing it here too would let the paired go-back
		# notification that follows fall through and leave the screen.
		if event is InputEventKey and event.pressed and event.keycode != KEY_BACK:
			get_viewport().set_input_as_handled()
			view.close_zoom()
