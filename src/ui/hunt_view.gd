class_name HuntView
extends RefCounted
## The question stem with its code-book hunt keywords (HuntKeywords): marked
## words in the stem and the "INDEX ..." line above the lookup path. At rest
## the INDEX line is a dim prompt, never the list of entries. Hovering a
## keyword (desktop) puts just its entry there until the pointer leaves; a tap
## or click pins it until a second tap or the next question. Entries name what
## to look up, never where. After answering the keywords stay marked, the
## reference line is the usual section breadcrumb and no INDEX text shows.

## Keyword looks: amber text on a faint amber tint (a highlighter mark, not a
## link; fainter still on the non-primary keywords, HuntKeywords.secondary_tint),
## a stronger tint under the pointer, and the singled-out keyword as a
## solid amber chip with dark text.
const KEYWORD_COLOR := AppTheme.AMBER_200
const KEYWORD_TINT := Color(AppTheme.AMBER_400, 0.14)
const HOVER_COLOR := AppTheme.AMBER_100
const HOVER_TINT := Color(AppTheme.AMBER_400, 0.32)
const FOCUS_COLOR := AppTheme.SLATE_900
const FOCUS_TINT := Color(AppTheme.AMBER_400, 0.92)
const INDEX_COLOR := AppTheme.AMBER_400
const PROMPT_COLOR := AppTheme.SLATE_400
const PROMPT_DESKTOP := "INDEX  Hover a colored word to see what to look up"
const PROMPT_PHONE := "INDEX  Tap a colored word to see what to look up"
## A tap and the emulated click of the same finger (when a device emulates the
## mouse) arrive this close together; only the first counts.
const DOUBLE_FIRE_MSEC := 400
## Picking a keyword lights the lookup box: an amber border and tint that
## settle back to its own style while the INDEX text fades up. Hovering onto
## a different entry fades the text only. Colors and alpha only, so nothing
## moves. Reduce motion: the box stays tinted while a keyword is picked.
const PULSE_SEC := 0.3
const PULSE_BORDER := AppTheme.AMBER_400
const PULSE_TINT := Color(AppTheme.AMBER_400, 0.12)
const PULSE_TEXT_FROM := 0.35

var host: Main
var _record: Dictionary = {}
var _correct := ""
## Keyword singled out by a tap/click, and the one under the pointer.
var _focus := -1
var _hover := -1
## The fit hid the INDEX line altogether.
var _hidden_by_fit := false
## Finger on the stem: its index and where it went down.
var _touch := -1
var _touch_at := Vector2.ZERO
var _pick_msec := -DOUBLE_FIRE_MSEC
var _pick_by_touch := false
var _pulse: Tween
## The lookup box's own style, put back when a pulse ends.
var _box: PanelContainer
var _box_style: StyleBoxFlat


static func make_stem_label(font_size: int) -> RichTextLabel:
	var label := KeywordStemLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.shortcut_keys_enabled = false
	label.hint_underlined = false
	label.meta_underlined = false
	label.add_theme_font_override("normal_font", AppTheme.ui_font(AppTheme.WEIGHT_SEMIBOLD))
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.add_theme_color_override("default_color", AppTheme.WHITE)
	label.add_theme_constant_override("line_separation", 2)
	# The keyword tint reaches a little past the glyphs, inside the line gap; any
	# wider and it runs under the punctuation after the word.
	label.add_theme_constant_override("text_highlight_h_padding", 1)
	label.add_theme_constant_override("text_highlight_v_padding", 1)
	# Main._touch_filter_walk keeps it PASS: hover and tap reach the keywords,
	# drags still reach the page scroller.
	label.set_meta("keeps_input", true)
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	return label


## Hover, click and finger taps on the stem's keywords. project.godot keeps
## emulate_mouse_from_touch off and RichTextLabel emits meta_clicked only for
## the mouse, so a finger is read here from ScreenTouch. Hover is read from
## each motion event's own position (meta_hover_started follows the OS cursor
## instead, so it never sees injected events).
func attach(label: RichTextLabel) -> void:
	label.meta_clicked.connect(on_keyword_clicked)
	label.gui_input.connect(_on_stem_input)
	label.mouse_exited.connect(hover_keyword.bind(-1))


static func make_index_label(font_size: int) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", AppTheme.ui_font(AppTheme.WEIGHT_SEMIBOLD))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", INDEX_COLOR)
	label.visible = false
	return label


static func set_font_size(label: RichTextLabel, font_size: int) -> void:
	label.add_theme_font_size_override("normal_font_size", font_size)


## Pre-answer: color the keywords and fill the INDEX line (both off when the
## setting is off or in the Full Exam). The stem text itself never changes.
func show_question(record: Dictionary, correct_text: String) -> void:
	_record = record
	_correct = correct_text
	_focus = -1
	_hover = -1
	_touch = -1
	_hidden_by_fit = false
	stop_pulse()
	var label := host.index_hint_label
	if not label.resized.is_connected(_reserve_height):
		label.resized.connect(_reserve_height)
	_render_stem()
	_fill_index_line()


## After answering: nothing singled out, every keyword back to its plain mark.
func answered() -> void:
	_focus = -1
	_hover = -1
	_touch = -1
	stop_pulse()
	_render_stem()


func _render_stem() -> void:
	var looks := {}
	if _hover >= 0:
		looks[_hover] = [HOVER_COLOR, HOVER_TINT]
	if _focus >= 0:
		looks[_focus] = [FOCUS_COLOR, FOCUS_TINT]
	var prompt := str(_record.get("prompt", "Question unavailable"))
	host.question_label.text = HuntKeywords.stem_bbcode(_record, prompt, KEYWORD_COLOR, showing(), KEYWORD_TINT, looks)


func showing() -> bool:
	return HuntKeywords.enabled(host.audio.hunt_keywords, host.session.session_simulation) \
			and not HuntKeywords.keywords(_record).is_empty()


## The keyword whose entry alone the INDEX line names, or -1.
func singled_out() -> int:
	return _hover if _hover >= 0 else _focus


## The rest line: what to do with the colored words, no entries.
func prompt_text() -> String:
	return PROMPT_PHONE if host.ui_mobile else PROMPT_DESKTOP


func _entry_line(i: int) -> String:
	var line := HuntKeywords.index_line(_record, i)
	return AudioExplanationGenerator.redact_answer_spans(line, _correct) if _correct != "" else line


## The singled-out entry, else the prompt. When the fit had no room for the
## line, a singled-out entry still shows and the line goes again once nothing
## is singled out.
func _fill_index_line() -> void:
	var one := singled_out()
	var label := host.index_hint_label
	var line := ""
	if showing():
		line = _entry_line(one) if one >= 0 else prompt_text()
	label.text = line
	label.add_theme_color_override("font_color", INDEX_COLOR if one >= 0 else PROMPT_COLOR)
	label.visible = line != "" and (one >= 0 or not _hidden_by_fit)
	_reserve_height()
	sync_lookup_box()


## The line keeps the height of its tallest text (the prompt or any one entry)
## at its width, so hovering or tapping never grows the box or scrolls.
func _reserve_height() -> void:
	var label := host.index_hint_label
	var tall := 0.0
	var font := label.get_theme_font("font")
	var width := label.size.x
	if showing() and font != null and width > 0.0:
		var font_size := label.get_theme_font_size("font_size")
		var font_h := font.get_height(font_size)
		var spacing := label.get_theme_constant("line_spacing")
		var texts: Array[String] = [prompt_text()]
		for i in HuntKeywords.keywords(_record).size():
			texts.append(_entry_line(i))
		for text in texts:
			var h := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size).y
			var lines := maxf(1.0, ceilf(h / font_h - 0.01))
			tall = maxf(tall, lines * font_h + (lines - 1.0) * spacing)
	if not is_equal_approx(label.custom_minimum_size.y, tall):
		label.custom_minimum_size.y = tall


## Unanswered-screen fit (FitController): the INDEX line again.
func refill() -> void:
	if host.current_answered:
		return
	_hidden_by_fit = false
	_fill_index_line()


## Giving up room, for the fit: no INDEX line. False when there is nothing
## left to give.
func shrink_index() -> bool:
	if not host.index_hint_label.visible:
		return false
	_hidden_by_fit = true
	host.index_hint_label.visible = false
	sync_lookup_box()
	return true


func sync_lookup_box() -> void:
	host.lookup_box.visible = host.chapter_hint_label.visible or host.index_hint_label.visible


func _live() -> bool:
	return not host.current_answered and showing()


func _meta_index(meta) -> int:
	var i := int(str(meta)) if str(meta).is_valid_int() else -1
	return i if i >= 0 and i < HuntKeywords.keywords(_record).size() else -1


## A live INDEX line with nothing singled out is hidden only by a fit step,
## including the table fit, which hides it without shrink_index().
func _note_fit_hide() -> void:
	if singled_out() < 0 and not host.index_hint_label.visible:
		_hidden_by_fit = true


## A click on a keyword: the INDEX line names just its entry; a second click on
## the same keyword brings back the full line.
func on_keyword_clicked(meta) -> void:
	_pick(_meta_index(meta), false)


func _pick(i: int, by_touch: bool) -> void:
	if not _live() or i < 0:
		return
	var now := Time.get_ticks_msec()
	if by_touch != _pick_by_touch and now - _pick_msec < DOUBLE_FIRE_MSEC:
		return
	_pick_msec = now
	_pick_by_touch = by_touch
	_note_fit_hide()
	_focus = -1 if i == _focus else i
	_render_stem()
	_fill_index_line()
	if _focus >= 0:
		_light_index(true)
	else:
		stop_pulse()


## The pointer is over keyword `i` (-1: over none). Leaving brings back what
## was there before: the tapped entry, or the full (or fit-shortened, or
## fit-hidden) line.
func hover_keyword(i: int) -> void:
	if not _live():
		_hover = -1
		return
	if i == _hover:
		return
	if _hover < 0:
		_note_fit_hide()
	var before := singled_out()
	_hover = i
	_render_stem()
	_fill_index_line()
	if i >= 0 and i != before and not UiFx.reduce_motion:
		_light_index(false)


## True while the lookup box or the INDEX text is easing back.
func pulsing() -> bool:
	return _pulse != null and _pulse.is_valid() and _pulse.is_running()


## The lookup box style showing now differs from its own (a pulse or the
## Reduce-motion tint).
func box_lit() -> bool:
	return _box != null and _box.get_theme_stylebox("panel") != _box_style


## with_box: the box border and tint too (a pick), else the text fade only.
func _light_index(with_box: bool) -> void:
	stop_pulse()
	var box := host.lookup_box
	if not host.index_hint_label.visible or not box.visible:
		return
	if _box != box:
		_box = box
		_box_style = box.get_theme_stylebox("panel") as StyleBoxFlat
	if _box_style == null:
		return
	var lit: StyleBoxFlat = null
	if with_box:
		lit = _box_style.duplicate() as StyleBoxFlat
		lit.border_color = PULSE_BORDER
		lit.bg_color = _box_style.bg_color.blend(PULSE_TINT)
		box.add_theme_stylebox_override("panel", lit)
	if UiFx.reduce_motion or not box.is_inside_tree():
		return
	host.index_hint_label.modulate.a = PULSE_TEXT_FROM
	_pulse = box.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_parallel()
	_pulse.tween_property(host.index_hint_label, "modulate:a", 1.0, PULSE_SEC)
	if lit != null:
		_pulse.tween_property(lit, "border_color", _box_style.border_color, PULSE_SEC)
		_pulse.tween_property(lit, "bg_color", _box_style.bg_color, PULSE_SEC)
		_pulse.chain().tween_callback(_restore_box)


## Ends a pulse at once: the box in its own style, the INDEX text opaque.
func stop_pulse() -> void:
	if _pulse != null and _pulse.is_valid():
		_pulse.kill()
	_pulse = null
	_restore_box()
	host.index_hint_label.modulate.a = 1.0


func _restore_box() -> void:
	if _box != null and is_instance_valid(_box) and _box_style != null:
		_box.add_theme_stylebox_override("panel", _box_style)


## The keyword under a point of the stem label (its [hint]), or -1.
func keyword_at(pos: Vector2) -> int:
	var hint := host.question_label.get_tooltip(pos)
	var list := HuntKeywords.keywords(_record)
	for i in list.size():
		if hint == HuntKeywords.hint_text(_record, list[i]):
			return i
	return -1


## A finger tap on a keyword works like a click. A drag belongs to TouchScroll,
## which swallows its release, so each press starts over.
func _on_stem_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hover_keyword(keyword_at((event as InputEventMouseMotion).position))
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touch = touch.index
			_touch_at = touch.position
		elif touch.index == _touch:
			_touch = -1
			if touch.position.distance_to(_touch_at) <= TouchScroll.DRAG_THRESHOLD:
				var i := keyword_at(touch.position)
				if i >= 0 and _live():
					_pick(i, true)
					host.question_label.accept_event()
	elif event is InputEventScreenDrag and (event as InputEventScreenDrag).index == _touch:
		if (event as InputEventScreenDrag).position.distance_to(_touch_at) > TouchScroll.DRAG_THRESHOLD:
			_touch = -1
