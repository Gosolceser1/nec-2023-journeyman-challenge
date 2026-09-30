class_name HuntView
extends RefCounted
## The question stem with its code-book hunt keywords (HuntKeywords): colored
## words in the stem and the "INDEX ..." line above the lookup path. Hover
## shows a keyword's entry (desktop); a tap puts just that entry in the INDEX
## line. After answering the keywords stay colored and the reference line is
## the usual section breadcrumb.

const KEYWORD_COLOR := AppTheme.AMBER_200
const INDEX_COLOR := AppTheme.AMBER_400

var host: Main
var _record: Dictionary = {}
var _correct := ""
var _focus := -1
## The fit gave up room: the INDEX line names only the first entry.
var _short := false


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
	_short = false
	var on := showing()
	var prompt := str(record.get("prompt", "Question unavailable"))
	host.question_label.text = HuntKeywords.stem_bbcode(record, prompt, KEYWORD_COLOR, on)
	_fill_index_line()


func showing() -> bool:
	return HuntKeywords.enabled(host.audio.hunt_keywords, host.session.session_simulation) \
			and not HuntKeywords.keywords(_record).is_empty()


func _fill_index_line() -> void:
	var only := _focus if _focus >= 0 else (0 if _short else -1)
	var line := HuntKeywords.index_line(_record, only) if showing() else ""
	if _correct != "":
		line = AudioExplanationGenerator.redact_answer_spans(line, _correct)
	host.index_hint_label.text = line
	host.index_hint_label.visible = line != ""
	sync_lookup_box()


## Unanswered-screen fit (FitController): the full INDEX line again.
func refill() -> void:
	if host.current_answered:
		return
	_short = false
	_fill_index_line()


## One step of giving up room, for the fit: first only the first entry, then
## no INDEX line. False when there is nothing left to give.
func shrink_index() -> bool:
	if not host.index_hint_label.visible:
		return false
	if not _short and _focus < 0 and HuntKeywords.keywords(_record).size() > 1:
		_short = true
		_fill_index_line()
		return true
	host.index_hint_label.visible = false
	sync_lookup_box()
	return true


func sync_lookup_box() -> void:
	host.lookup_box.visible = host.chapter_hint_label.visible or host.index_hint_label.visible


## A tap on a keyword: the INDEX line names just its entry; a second tap on the
## same keyword brings back the full line.
func on_keyword_clicked(meta) -> void:
	if host.current_answered or not showing() or not host.index_hint_label.visible:
		return
	var i := int(str(meta)) if str(meta).is_valid_int() else -1
	_focus = -1 if i == _focus else i
	_fill_index_line()
