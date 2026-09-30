class_name HuntView
extends RefCounted
## The question stem with its code-book hunt keywords (HuntKeywords): colored
## words in the stem and the "INDEX ..." line above the lookup path. Hovering a
## keyword (desktop) puts just its entry in the INDEX line until the pointer
## leaves; a tap or click keeps it there until a second tap. After answering
## the keywords stay colored and the reference line is the usual section
## breadcrumb.

const KEYWORD_COLOR := AppTheme.AMBER_200
const INDEX_COLOR := AppTheme.AMBER_400
## A tap and the emulated click of the same finger (when a device emulates the
## mouse) arrive this close together; only the first counts.
const DOUBLE_FIRE_MSEC := 400

var host: Main
var _record: Dictionary = {}
var _correct := ""
## Keyword singled out by a tap/click, and the one under the pointer.
var _focus := -1
var _hover := -1
## The fit gave up room: the INDEX line names only the first entry.
var _short := false
## The fit hid the INDEX line altogether.
var _hidden_by_fit := false
## Finger on the stem: its index and where it went down.
var _touch := -1
var _touch_at := Vector2.ZERO
var _pick_msec := -DOUBLE_FIRE_MSEC
var _pick_by_touch := false


static func make_stem_label(font_size: int) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.shortcut_keys_enabled = false
	label.hint_underlined = false
	label.meta_underlined = true
	label.add_theme_font_override("normal_font", AppTheme.ui_font(AppTheme.WEIGHT_SEMIBOLD))
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.add_theme_color_override("default_color", AppTheme.WHITE)
	label.add_theme_constant_override("line_separation", 2)
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
	_short = false
	_hidden_by_fit = false
	var on := showing()
	var prompt := str(record.get("prompt", "Question unavailable"))
	host.question_label.text = HuntKeywords.stem_bbcode(record, prompt, KEYWORD_COLOR, on)
	_fill_index_line()


func showing() -> bool:
	return HuntKeywords.enabled(host.audio.hunt_keywords, host.session.session_simulation) \
			and not HuntKeywords.keywords(_record).is_empty()


## The keyword whose entry alone the INDEX line names, or -1.
func singled_out() -> int:
	return _hover if _hover >= 0 else _focus


## When the fit had no room for the line, a singled-out entry still shows and
## the line goes again once nothing is singled out.
func _fill_index_line() -> void:
	var one := singled_out()
	var only := one if one >= 0 else (0 if _short else -1)
	var line := HuntKeywords.index_line(_record, only) if showing() else ""
	if _correct != "":
		line = AudioExplanationGenerator.redact_answer_spans(line, _correct)
	host.index_hint_label.text = line
	host.index_hint_label.visible = line != "" and (one >= 0 or not _hidden_by_fit)
	sync_lookup_box()


## Unanswered-screen fit (FitController): the full INDEX line again.
func refill() -> void:
	if host.current_answered:
		return
	_short = false
	_hidden_by_fit = false
	_fill_index_line()


## One step of giving up room, for the fit: first only the first entry, then
## no INDEX line. False when there is nothing left to give.
func shrink_index() -> bool:
	if not host.index_hint_label.visible:
		return false
	if not _short and singled_out() < 0 and HuntKeywords.keywords(_record).size() > 1:
		_short = true
		_fill_index_line()
		return true
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
	_fill_index_line()


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
	_hover = i
	_fill_index_line()


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
