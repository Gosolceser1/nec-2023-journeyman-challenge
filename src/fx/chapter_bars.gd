class_name ChapterBars
extends Control

## Results-screen breakdown: one horizontal bar per exam subject area (or per
## NEC chapter) showing the share answered correctly, with the 75% line on
## area rows. Bars grow in when shown.

const ROW_H := 24.0
## Chart key for Nebraska State Electrical Act / Board Rules citations.
const STATE_LAW := 10
const CHAPTER_NAMES := {
	0: "Trade knowledge / math",
	1: "Ch 1  General",
	2: "Ch 2  Wiring & protection",
	3: "Ch 3  Wiring methods",
	4: "Ch 4  General equipment",
	5: "Ch 5  Special occupancies",
	6: "Ch 6  Special equipment",
	7: "Ch 7  Special conditions",
	8: "Ch 8  Communications",
	9: "Ch 9  Tables",
	STATE_LAW: "NE State Act & Rules",
}

var rows: Array = []
var _grow := 0.0
var _pill := StyleBoxFlat.new()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL


## NEC chapter for an article/section string ("310.16", "Table 250.66",
## "Chapter 9, Table 4"); 0 for NFPA 70E, math and general knowledge;
## STATE_LAW for Nebraska statutes and board rules.
static func chapter_of(article: String) -> int:
	if NecReference.is_state_law(article):
		return STATE_LAW
	var ch := RegEx.create_from_string("(?i)\\bchapter\\s+(\\d)\\b").search(article)
	if ch != null:
		return int(ch.get_string(1))
	if article.to_lower().contains("70e"):
		return 0
	var m := RegEx.create_from_string("\\b([1-9])\\d\\d\\b").search(article)
	return int(m.get_string(1)) if m != null else 0


## stats: {chapter:int -> [correct:int, total:int]} -> sorted display rows.
static func rows_from_stats(stats: Dictionary) -> Array:
	var keys := stats.keys()
	keys.sort()
	var out: Array = []
	for k in keys:
		var v: Array = stats[k]
		out.append({"label": str(CHAPTER_NAMES.get(int(k), "Other")), "correct": int(v[0]), "total": int(v[1])})
	return out


## stats: {area key -> [correct, total]} -> rows in exam outline order. Rows
## below the pass line are marked weak; the lowest of them is the weakest.
static func rows_from_areas(stats: Dictionary, pass_percent: float) -> Array:
	var out: Array = []
	var lowest := 2.0
	for k in ExamBlueprint.keys():
		if not stats.has(k):
			continue
		var v: Array = stats[k]
		var ratio := float(v[0]) / maxf(1.0, float(v[1]))
		out.append({"label": ExamBlueprint.title(k), "correct": int(v[0]), "total": int(v[1]), "weak": ratio * 100.0 < pass_percent, "weakest": false})
		if ratio * 100.0 < pass_percent:
			lowest = minf(lowest, ratio)
	for row in out:
		row["weakest"] = row["weak"] and is_equal_approx(float(row["correct"]) / maxf(1.0, float(row["total"])), lowest)
	return out


func set_rows(new_rows: Array) -> void:
	rows = new_rows
	custom_minimum_size.y = ROW_H * rows.size() + 4.0
	_grow = 0.0
	queue_redraw()
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.3)
	tw.tween_method(_set_grow, 0.0, 1.0, 1.0)


func _set_grow(v: float) -> void:
	_grow = v
	queue_redraw()


func _draw() -> void:
	var font := AppTheme.ui_font(AppTheme.WEIGHT_MEDIUM)
	var digits := AppTheme.numeric_font(AppTheme.WEIGHT_MEDIUM)
	var label_w := minf(190.0, size.x * 0.46)
	var pass_pct := float(ExamBlueprint.pass_percent())
	var count_w := 76.0
	var bar_x := label_w + AppTheme.SPACE_SM
	var bar_w := maxf(20.0, size.x - bar_x - count_w)
	var bar_h := 8.0
	for i in rows.size():
		var row: Dictionary = rows[i]
		var y := float(i) * ROW_H
		var total: int = maxi(int(row["total"]), 1)
		var ratio := float(row["correct"]) / float(total)
		var col := ResultGauge.tint_for(ratio * 100.0, pass_pct)
		var label := ("▸ " if row.get("weakest", false) else "") + str(row["label"])
		draw_string(font, Vector2(0, y + 16.0), label, HORIZONTAL_ALIGNMENT_LEFT, label_w, AppTheme.TYPE_META, AppTheme.AMBER_400 if row.get("weak", false) else AppTheme.SLATE_300)
		var mid := y + 12.0
		_capsule(bar_x, bar_x + bar_w, mid, bar_h, Color(AppTheme.WHITE, 0.07))
		var fill := bar_w * ratio * _grow
		if fill > 0.5:
			_capsule(bar_x, bar_x + fill, mid, bar_h + 6.0, Color(col, 0.18))
			_capsule(bar_x, bar_x + fill, mid, bar_h, col)
		if row.has("weak"):
			var tick_x := bar_x + bar_w * pass_pct / 100.0
			draw_line(Vector2(tick_x, y + 3.0), Vector2(tick_x, y + 21.0), Color(AppTheme.WHITE, 0.45), 1.0)
		draw_string(digits, Vector2(bar_x + bar_w + 6.0, y + 16.0), "%d/%d  %d%%" % [int(row["correct"]), int(row["total"]), roundi(ratio * 100.0)],
			HORIZONTAL_ALIGNMENT_LEFT, count_w, AppTheme.TYPE_META, AppTheme.SLATE_400)


## A round-ended bar from x0 to x1 centred on y.
func _capsule(x0: float, x1: float, y: float, h: float, col: Color) -> void:
	_pill.bg_color = col
	_pill.set_corner_radius_all(int(h * 0.5))
	draw_style_box(_pill, Rect2(x0, y - h * 0.5, maxf(x1 - x0, 1.0), h))
