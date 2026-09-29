class_name OutlineBars
extends Control
## The licensing exam's content outline as a picture: one row per subject
## area, bar length = its share of the scored items, bar colour = your recent
## accuracy there (grey until practised). Rows come from ExamBlueprint.

const ROW_H := 20.0

## [{"title", "items", "accuracy" (-1 = not practised)}]
var rows: Array = []
var _pill := StyleBoxFlat.new()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL


func set_rows(new_rows: Array) -> void:
	rows = new_rows
	custom_minimum_size.y = ROW_H * rows.size()
	queue_redraw()


## Rows from the blueprint and QuestionDeck.mastery().
static func rows_from(mastery: Dictionary) -> Array:
	var out: Array = []
	for k in ExamBlueprint.keys():
		var m: Dictionary = mastery.get(k, {})
		var answers := int(m.get("answers", 0))
		out.append({"title": ExamBlueprint.title(k), "items": ExamBlueprint.items(k),
			"accuracy": float(m["right"]) / answers if answers > 0 else -1.0})
	return out


func _draw() -> void:
	var most := 1
	for row in rows:
		most = maxi(most, int(row["items"]))
	var font := AppTheme.ui_font(AppTheme.WEIGHT_MEDIUM)
	var digits := AppTheme.numeric_font(AppTheme.WEIGHT_SEMIBOLD)
	var label_w := minf(230.0, size.x * 0.5)
	var count_w := 88.0
	var bar_x := label_w + AppTheme.SPACE_SM
	var bar_w := maxf(20.0, size.x - bar_x - count_w)
	var pass_mark := float(ExamBlueprint.pass_percent())
	for i in rows.size():
		var row: Dictionary = rows[i]
		var y := float(i) * ROW_H
		var acc := float(row["accuracy"])
		var col := ResultGauge.tint_for(acc * 100.0, pass_mark) if acc >= 0.0 else AppTheme.SLATE_500
		draw_string(font, Vector2(0, y + 14.0), str(row["title"]), HORIZONTAL_ALIGNMENT_LEFT, label_w, AppTheme.TYPE_META, AppTheme.SLATE_300)
		var w := bar_w * float(row["items"]) / float(most)
		_pill.bg_color = Color(col, 0.9)
		_pill.set_corner_radius_all(4)
		draw_style_box(_pill, Rect2(bar_x, y + 6.0, maxf(w, 8.0), 8.0))
		var tail := "%d" % int(row["items"])
		if acc >= 0.0:
			tail += "  •  %d%%" % roundi(acc * 100.0)
		draw_string(digits, Vector2(bar_x + bar_w + 6.0, y + 14.0), tail, HORIZONTAL_ALIGNMENT_LEFT, count_w, AppTheme.TYPE_META, AppTheme.SLATE_400)
