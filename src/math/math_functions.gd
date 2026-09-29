class_name MathFunctions
extends RefCounted
## The functions a problem-type expression may call (it is the Expression base
## instance). Table access is generic: tables are looked up by id in the
## edition's tables.json, so the data files decide every NEC value.
##   t(table, key, col)       exact row by key ("12", "1/0", 3 -> "3")
##   trange(table, x, col)    row whose lo..hi range holds x (row "expr" in n)
##   trange_key(table, x)     that row's key label, e.g. "105–113"
##   tmin(table, col, x)      key of the first row whose col is at least x
##   tnext(table, col, x)     smallest col value at least x (240.6(A) sizes)
##   tier(table, x, i)        part of x inside tier i; tierpct(table, i)
##   v(name)  NEC scalar value       k(name)  non-NEC constant


func t(table_id, key, col) -> Variant:
	var row := _row(str(table_id), key_text(key))
	return row.get(str(col)) if not row.is_empty() else null


func tlabel(table_id, key) -> String:
	var row := _row(str(table_id), key_text(key))
	return str(row.get("label", row.get("key", ""))) if not row.is_empty() else ""


func trange(table_id, x, col) -> Variant:
	var row := _range_row(str(table_id), float(x))
	if row.is_empty():
		return null
	var expr_key := "%s_expr" % col if row.has("%s_expr" % col) else "expr"
	if row.has(expr_key):
		var e := Expression.new()
		if e.parse(str(row[expr_key]), PackedStringArray(["n"])) != OK:
			return null
		var out = e.execute([float(x)])
		return null if e.has_execute_failed() else out
	return row.get(str(col))


func trange_key(table_id, x) -> String:
	return str(_range_row(str(table_id), float(x)).get("key", ""))


## A text field of the range row holding x, "" when it has none.
func trange_text(table_id, x, field) -> String:
	var val = _range_row(str(table_id), float(x)).get(str(field))
	return str(val) if val != null else ""


func tmin(table_id, col, x) -> Variant:
	for row in _rows(str(table_id)):
		var val = row.get(str(col))
		if val != null and float(val) >= float(x) - 1e-9:
			return str(row["key"])
	return null


func tnext(table_id, col, x) -> Variant:
	var best = null
	for row in _rows(str(table_id)):
		var val = row.get(str(col))
		if val != null and float(val) >= float(x) - 1e-9 and (best == null or float(val) < best):
			best = float(val)
	return best


func tier(table_id, x, index) -> float:
	var rows := _rows(str(table_id))
	var i := int(index)
	if i < 0 or i >= rows.size():
		return 0.0
	var lo := float(rows[i].get("lo", 0))
	var hi := float(rows[i].get("hi", 0))
	return clampf(float(x) - lo, 0.0, hi - lo)


func tierpct(table_id, index) -> float:
	var rows := _rows(str(table_id))
	var i := int(index)
	return float(rows[i].get("percent", 0)) if i >= 0 and i < rows.size() else 0.0


func v(key) -> Variant:
	var val = MathData.value(str(key))
	return float(val) if val is int or val is float else val


func k(key) -> Variant:
	var val = MathData.constant(str(key))
	return float(val) if val is int or val is float else val


## Display label for a short id (data/math/problem_types.json "labels").
func label(key) -> String:
	return str(MathData.problems().get("labels", {}).get(str(key), str(key)))


## Rounds to places decimals.
func r(x, places) -> float:
	var m := pow(10.0, int(places))
	return round(float(x) * m) / m


## floor(x), plus one when the decimal part is at least threshold
## (Chapter 9, Note 7 uses 0.8).
func upfrac(x, threshold) -> float:
	var whole := floorf(float(x) + 1e-9)
	return whole + (1.0 if float(x) - whole >= float(threshold) - 1e-9 else 0.0)


## floor(x), plus one for a major fraction (more than one half).
func major(x) -> float:
	var whole := floorf(float(x) + 1e-9)
	return whole + (1.0 if float(x) - whole > 0.5 + 1e-9 else 0.0)


func frac(x) -> float:
	return float(x) - floorf(float(x) + 1e-9)


func pick(condition, a, b) -> Variant:
	return a if condition else b


func nz(x) -> float:
	return 1.0 if float(x) != 0.0 else 0.0


func gcd(a, b) -> float:
	var x := absi(int(round(float(a))))
	var y := absi(int(round(float(b))))
	while y != 0:
		var tmp := y
		y = x % y
		x = tmp
	return float(x)


## "a/b" reduced to lowest terms.
func fraction(a, b) -> String:
	var g := gcd(a, b)
	if g == 0.0:
		return "0"
	return "%d/%d" % [int(round(float(a) / g)), int(round(float(b) / g))]


## prefix + n, with whole numbers written without a decimal point.
func name(prefix, n) -> String:
	return str(prefix) + key_text(n)


func fmt(x) -> String:
	return MathFormat.number(x)


func upper(s) -> String:
	return str(s).to_upper()


func lower(s) -> String:
	return str(s).to_lower()


## "1 device yoke" / "2 device yokes".
func plural(n, one, many) -> String:
	return "%s %s" % [MathFormat.number(n), str(one) if float(n) == 1.0 else str(many)]


func join_nonzero(values, sep) -> String:
	var parts := PackedStringArray()
	for x in values:
		if float(x) != 0.0:
			parts.append(MathFormat.number(x, -1, false))
	return str(sep).join(parts)


func join_nonempty(values, sep) -> String:
	var parts := PackedStringArray()
	for x in values:
		if str(x) != "":
			parts.append(str(x))
	return str(sep).join(parts)


## The key form used by the tables: 3.0 -> "3", 7.5 -> "7.5", "1/0" unchanged.
static func key_text(key) -> String:
	if key is float or key is int:
		var f := float(key)
		return str(int(f)) if f == floor(f) else str(f)
	return str(key)


static func _rows(table_id: String) -> Array:
	return MathData.table(table_id).get("rows", [])


static func _row(table_id: String, key: String) -> Dictionary:
	for row in _rows(table_id):
		if str(row.get("key", "")) == key:
			return row
	return {}


static func _range_row(table_id: String, x: float) -> Dictionary:
	for row in _rows(table_id):
		if row.has("lo") and x >= float(row["lo"]) - 1e-9 and x <= float(row["hi"]) + 1e-9:
			return row
	return {}
