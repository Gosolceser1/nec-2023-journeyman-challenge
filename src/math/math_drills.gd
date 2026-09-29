class_name MathDrills
extends RefCounted
## Timed table-lookup drill questions from data/math/drills.json. Every value
## is read from the edition's tables.json; the spec only says which rows and
## columns to ask about and how to word the question.
##
## A question: {prompt, options: [text], answer_index, answer, where}
## "where" is the explanation shown after answering, e.g.
## "Table 310.16, 12 AWG row, Copper 75°C column = 25 A".

const OPTION_COUNT := 4


static func count(drill: Dictionary) -> int:
	return int(drill.get("count", MathData._json(MathData.MATH_DIR + "drills.json").get("defaults", {}).get("count", 8)))


static func seconds(drill: Dictionary) -> int:
	return int(drill.get("seconds", MathData._json(MathData.MATH_DIR + "drills.json").get("defaults", {}).get("seconds", 120)))


static func _rows(table_id: String) -> Array:
	return MathData.table(table_id).get("rows", [])


static func _col_label(table_id: String, col: String) -> String:
	for c in MathData.table(table_id).get("columns", []):
		if str(c.get("id", "")) == col:
			return str(c.get("label", col))
	return col


## Rows between spec "from" and "to" keys (all rows without a spec).
static func _row_slice(rows: Array, spec) -> Array:
	if not (spec is Dictionary):
		return rows
	var from := 0
	var to := rows.size() - 1
	for i in rows.size():
		if str(rows[i].get("key", "")) == str(spec.get("from", "")):
			from = i
		if str(rows[i].get("key", "")) == str(spec.get("to", "")):
			to = i
	return rows.slice(from, to + 1)


static func _value(row: Dictionary, col: String, x: float) -> Variant:
	var expr_key := "%s_expr" % col if row.has("%s_expr" % col) else "expr"
	if row.has(expr_key) and not row.has(col):
		var res := MathEngine.evaluate(str(row[expr_key]), {"n": x})
		return res[1] if res[0] else null
	return row.get(col)


## unit "conductor" formats a size as AWG or kcmil.
static func _text(value, unit: String) -> String:
	if unit == "conductor":
		return MathFormat.conductor_size(value)
	var text := MathFormat.number(value) if (value is float or value is int) else str(value)
	if unit == "" or text == "":
		return text
	if unit == "%":
		return text + "%"
	return "%s %s" % [text, unit]


## One question for the drill, or {} if the spec cannot produce one.
static func question(drill: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var table_id := str(drill.get("table", ""))
	var rows := _rows(table_id)
	var cols: Array = drill.get("cols", [])
	if rows.is_empty() or cols.is_empty():
		return {}
	for _try in 40:
		var col := str(cols[rng.randi_range(0, cols.size() - 1)])
		var picked := _pick(drill, rows, col, rng)
		if picked.is_empty():
			continue
		var row: Dictionary = picked["row"]
		var value = _value(row, col, float(picked.get("x", 0.0)))
		if value == null:
			continue
		var unit := str(drill.get("units", {}).get(col, drill.get("unit", "")))
		var answer := _text(value, unit)
		var options := [answer]
		for other in _neighbors(rows, rows.find(row), col, cols, float(picked.get("x", 0.0))):
			var text := _text(other, unit)
			if not options.has(text) and options.size() < OPTION_COUNT:
				options.append(text)
		if options.size() < 2:
			continue
		for i in range(options.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp = options[i]
			options[i] = options[j]
			options[j] = tmp
		var vars := {
			"key": str(row.get("key", "")),
			"col_label": _col_label(table_id, col),
			"x": picked.get("x", ""),
		}
		var row_label := MathFormat.render(str(drill.get("row", "{key}")), vars)
		var where := "%s, %s row, %s column = %s" % [str(drill.get("ref", table_id)), row_label, vars["col_label"], answer]
		return {
			"prompt": MathFormat.render(str(drill.get("prompt", "{key}")), vars),
			"options": options,
			"answer_index": options.find(answer),
			"answer": answer,
			"where": where,
		}
	return {}


static func _pick(drill: Dictionary, rows: Array, col: String, rng: RandomNumberGenerator) -> Dictionary:
	match str(drill.get("kind", "cell")):
		"cell":
			var pool := _row_slice(rows, drill.get("rows"))
			return {"row": pool[rng.randi_range(0, pool.size() - 1)]} if not pool.is_empty() else {}
		"range":
			var span: Dictionary = drill.get("x", {})
			var x := float(rng.randi_range(int(span.get("from", 0)), int(span.get("to", 0))))
			for row in rows:
				if row.has("lo") and x >= float(row["lo"]) and x <= float(row["hi"]):
					return {"row": row, "x": x}
		"at_most":
			var spec: Dictionary = drill.get("values", {})
			var pool := _row_slice(_rows(str(spec.get("table", ""))), spec)
			if pool.is_empty():
				return {}
			var x := float(pool[rng.randi_range(0, pool.size() - 1)].get(str(spec.get("col", "")), 0))
			for row in rows:
				var limit = row.get(str(drill.get("limit_col", "")))
				if limit != null and float(limit) >= x:
					return {"row": row, "x": x}
		"size_at_most":
			var spec: Dictionary = drill.get("sizes", {})
			var pool := _row_slice(_rows(str(spec.get("table", ""))), spec)
			if pool.is_empty():
				return {}
			var size := str(pool[rng.randi_range(0, pool.size() - 1)].get("key", ""))
			for row in rows:
				var limit = row.get(str(drill.get("limit_col", "")))
				if limit == null or MathFormat.conductor_rank(size) <= MathFormat.conductor_rank(limit):
					return {"row": row, "x": MathFormat.conductor_size(size)}
	return {}


## Values near the answer: the same column in nearby rows, then the same row
## in the other columns.
static func _neighbors(rows: Array, at: int, col: String, cols: Array, x: float) -> Array:
	var out: Array = []
	for offset in [1, -1, 2, -2, 3, -3]:
		var i: int = at + offset
		if i >= 0 and i < rows.size():
			var val = _value(rows[i], col, x)
			if val != null:
				out.append(val)
	for other in cols:
		if str(other) != col and at >= 0:
			var val = _value(rows[at], str(other), x)
			if val != null:
				out.append(val)
	return out
