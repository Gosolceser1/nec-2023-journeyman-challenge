class_name DiagramView
extends Control

## A question's figure, as printed in the source exam: a crop of the scanned
## PDF page (diagrams/diagrams.json, produced by tools/pipeline/extract_diagrams.py),
## shown on a paper-white card so the black line art reads on the dark theme.
## Records with no PDF figure fall back to their ASCII "diagram" text in a
## monospace font. The drawing scales to the width it is given (no minimum
## width, no wrapping) and a tap opens it fullscreen.
##
## Pre-answer nothing is marked. reveal(correct_index) outlines the part of the
## figure the answer key points at (the mapping's "highlight" box).

const MAP_PATH := "res://assets/diagrams/diagrams.json"
const PAD := 4.0
const TAP_SLOP := 14.0
const HINT_GUTTER := 36.0
const INK := AppTheme.SLATE_900
const HIGHLIGHT := AppTheme.EMERALD_500

static var _map: Dictionary = {}
static var _loaded := false
static var _textures: Dictionary = {}
static var _mono_font: SystemFont

var figure: Dictionary = {}
var texture: Texture2D
var ascii_lines: PackedStringArray = PackedStringArray()
var revealed := false
## Tallest the figure may grow while following the width's aspect ratio.
var max_height := 220.0:
	set(v):
		max_height = v
		_update_height()
var min_height := 64.0
var _press_pos := Vector2.INF
var _zoom: CanvasLayer


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tooltip_text = "Click or tap to enlarge"
	resized.connect(_update_height)


static func _load_map() -> void:
	if _loaded:
		return
	_loaded = true
	var f := FileAccess.open(MAP_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		_map = parsed


static func figure_for(record_id: String) -> Dictionary:
	_load_map()
	return _map.get(record_id, {})


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
	revealed = false
	_update_height()
	queue_redraw()
	return has_content()


func has_content() -> bool:
	return texture != null or not ascii_lines.is_empty()


func reveal(_correct_index: int) -> void:
	revealed = figure.has("highlight")
	queue_redraw()
	if is_instance_valid(_zoom):
		_zoom.get_child(0).queue_redraw()


func is_revealed() -> bool:
	return revealed


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
	var c := _canvas()
	if c.x <= 0.0 or size.x <= PAD * 2.0:
		custom_minimum_size = Vector2(0, min_height if has_content() else 0.0)
		return
	var h := (size.x - PAD * 2.0 - HINT_GUTTER) * c.y / c.x + PAD * 2.0
	custom_minimum_size = Vector2(0, clampf(h, min_height, max_height))


func _draw() -> void:
	var area := Rect2(Vector2.ZERO, size).grow(-PAD)
	if has_content() and size.x > 60.0:
		# The magnifier gets its own gutter so it never sits on the art.
		area.size.x -= HINT_GUTTER
		area.position.x += HINT_GUTTER * 0.5
		_draw_zoom_hint()
	draw_figure(self, area, 1.0)


## Shared by the inline view and the fullscreen zoom.
func draw_figure(ci: CanvasItem, area: Rect2, line_scale: float) -> void:
	var c := _canvas()
	if c.x <= 0.0 or area.size.x <= 1.0 or area.size.y <= 1.0:
		return
	if texture != null:
		var s := minf(area.size.x / c.x, area.size.y / c.y)
		var rect := Rect2(area.position + (area.size - c * s) * 0.5, c * s)
		ci.draw_texture_rect(texture, rect, false)
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


## Small magnifier in the corner: the figure opens bigger.
func _draw_zoom_hint() -> void:
	var r := 7.0
	var c := Vector2(size.x - r - 5.0, size.y - r - 5.0)
	draw_circle(c, r + 4.0, Color(0.06, 0.09, 0.16, 0.10))
	draw_arc(c + Vector2(-1.5, -1.5), 4.0, 0.0, TAU, 20, AppTheme.SKY_700, 1.6, true)
	draw_line(c + Vector2(1.4, 1.4), c + Vector2(4.5, 4.5), AppTheme.SKY_700, 1.8, true)


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
	var view: DiagramView

	func _init() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	func _ready() -> void:
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 0.14)

	func _card_rect() -> Rect2:
		var vp := get_viewport_rect().size
		var avail := Rect2(Vector2(vp.x * 0.04, vp.y * 0.08), Vector2(vp.x * 0.92, vp.y * 0.80))
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
		sb.bg_color = AppTheme.SLATE_50
		sb.border_color = AppTheme.SKY_400
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(14)
		draw_style_box(sb, card)
		view.draw_figure(self, card.grow(-16), 1.6)
		var font := get_theme_default_font()
		var hint := "Tap anywhere or press Esc to close"
		var fs := 15
		var w := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2((get_viewport_rect().size.x - w) * 0.5, card.end.y + 30), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, AppTheme.SLATE_400)

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
