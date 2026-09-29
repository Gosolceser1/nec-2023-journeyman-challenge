class_name MathEngine
extends RefCounted
## Generates and solves math problems from data/math/problem_types.json. The
## same solve() builds the trainer's answer and every step shown to the user,
## so the steps always reach the checked answer. Exam solutions reuse it with
## the inputs from data/math/exam_steps.json (or the question's requirement
## check, see data/question_requirements.json).
##
## A solution is a Dictionary:
##   ok, error, type, level, vars, prompt, hint,
##   steps: [{kind, title, text, lines, note, keys, basic}],
##   answer: {value, kind ("number"/"choice"), text, unit, tol, rel, options}

const REQUIREMENTS_PATH := "res://data/question_requirements.json"
const MAX_TRIES := 80

static var _fn: MathFunctions
static var _requirements: Dictionary = {}


static func _functions() -> MathFunctions:
	if _fn == null:
		_fn = MathFunctions.new()
	return _fn


## Evaluates expr with vars. Returns [ok, value].
static func evaluate(expr: String, vars: Dictionary) -> Array:
	var e := Expression.new()
	var names := PackedStringArray()
	var values: Array = []
	for key in vars:
		names.append(str(key))
		values.append(vars[key])
	if e.parse(expr, names) != OK:
		return [false, "parse error in '%s': %s" % [expr, e.get_error_text()]]
	var out = e.execute(values, _functions(), false)
	if e.has_execute_failed():
		return [false, "cannot evaluate '%s': %s" % [expr, e.get_error_text()]]
	return [true, out]


static func level_ids() -> Array[int]:
	var out: Array[int] = []
	for l in MathData.levels():
		out.append(int(l.get("id", 1)))
	return out


## The level spec for level, falling back to the nearest lower level defined.
static func _level_spec(def: Dictionary, level: int) -> Dictionary:
	var levels: Dictionary = def.get("levels", {})
	for l in range(level, 0, -1):
		if levels.has(str(l)):
			return levels[str(l)]
	return levels.values()[0] if not levels.is_empty() else {}


static func _normalize(value) -> Variant:
	return float(value) if value is int else value


## One generated value for a var spec, or null when the spec is invalid.
static func _gen_value(spec: Dictionary, vars: Dictionary, rng: RandomNumberGenerator) -> Variant:
	if spec.has("pick"):
		var options: Array = spec["pick"]
		return _normalize(options[rng.randi_range(0, options.size() - 1)]) if not options.is_empty() else null
	if spec.has("range"):
		var lo := float(spec["range"][0])
		var hi := float(spec["range"][1])
		var step := float(spec.get("step", 1))
		var count := int(floor((hi - lo) / step + 1e-9))
		return snappedf(lo + step * rng.randi_range(0, count), 0.000001)
	if spec.has("key"):
		var keys := _table_keys(str(spec["key"]))
		var from := keys.find(str(spec.get("from", keys[0] if not keys.is_empty() else "")))
		var to := keys.find(str(spec.get("to", keys[-1] if not keys.is_empty() else "")))
		if from < 0 or to < from:
			return null
		return keys[rng.randi_range(from, to)]
	if spec.has("expr"):
		var res := evaluate(str(spec["expr"]), vars)
		return _normalize(res[1]) if res[0] else null
	return null


static func _table_keys(table_id: String) -> PackedStringArray:
	var out := PackedStringArray()
	for row in MathData.table(table_id).get("rows", []):
		out.append(str(row.get("key", "")))
	return out


## Distinct values of a column in row order.
static func _column_values(table_id: String, col: String) -> PackedStringArray:
	var out := PackedStringArray()
	for row in MathData.table(table_id).get("rows", []):
		var val = row.get(col)
		if val != null and not out.has(str(val)):
			out.append(str(val))
	return out


## Applies [[name, spec], ...] var definitions in order.
static func _apply_vars(defs: Array, vars: Dictionary, rng: RandomNumberGenerator, skip_given: bool) -> bool:
	for pair in defs:
		var key := str(pair[0])
		if skip_given and vars.has(key):
			continue
		var val = _gen_value(pair[1], vars, rng)
		if val == null:
			return false
		vars[key] = val
	return true


## A new problem of type_id at level, solved. Returns {} when no valid problem
## could be generated.
static func generate(type_id: String, level: int, rng: RandomNumberGenerator = null) -> Dictionary:
	var def := MathData.type_def(type_id)
	if def.is_empty():
		return {}
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	for _try in MAX_TRIES:
		var vars := {}
		if not _apply_vars(_level_spec(def, level).get("vars", []), vars, rng, false):
			continue
		var sol := solve(type_id, vars, level)
		if not sol.get("ok", false):
			continue
		if _requirements_met(def, sol["vars"]):
			_add_options(sol, def, rng)
			return sol
	return {}


static func _requirements_met(def: Dictionary, vars: Dictionary) -> bool:
	for expr in def.get("require", []):
		var res := evaluate(str(expr), vars)
		if not res[0] or not res[1]:
			return false
	return true


static func _render_pairs(step: Dictionary, field: String, vars: Dictionary) -> String:
	var out := []
	for pair in step.get(field, []):
		var res := evaluate(str(pair[1]), vars)
		if not res[0]:
			return str(res[1])
		vars[str(pair[0])] = _normalize(res[1])
		if vars[str(pair[0])] == null:
			return "'%s' has no value" % pair[0]
	return ""


## Solves type_id with the given inputs; derived vars not in inputs are added.
static func solve(type_id: String, inputs: Dictionary, level: int = 1) -> Dictionary:
	var def := MathData.type_def(type_id)
	var sol := {"ok": false, "error": "", "type": type_id, "level": level, "steps": []}
	if def.is_empty():
		sol["error"] = "unknown problem type '%s'" % type_id
		return sol
	var vars := {}
	for key in inputs:
		vars[key] = _normalize(inputs[key])
	vars["level"] = float(level)
	var rng := RandomNumberGenerator.new()
	if not _apply_vars(def.get("vars", []), vars, rng, true):
		sol["error"] = "cannot derive the type's vars"
		return sol
	var steps: Array = []
	for step in def.get("steps", []):
		if step.has("when"):
			var cond := evaluate(str(step["when"]), vars)
			if not cond[0]:
				sol["error"] = str(cond[1])
				return sol
			if not cond[1]:
				continue
		for field in ["set", "show"]:
			var err := _render_pairs(step, field, vars)
			if err != "":
				sol["error"] = err
				return sol
		steps.append(_render_step(step, vars))
	var spec: Dictionary = def.get("answer", {})
	var value = vars.get(str(spec.get("var", "")))
	if value == null or ((value is float) and (is_nan(value) or is_inf(value))):
		sol["error"] = "answer '%s' has no value" % spec.get("var", "")
		return sol
	var answer := {
		"value": value,
		"kind": str(spec.get("kind", "number")),
		"unit": str(spec.get("unit", "")),
		"tol": float(spec.get("tol", 0.0)),
		"rel": bool(spec.get("rel", false)),
		"text": MathFormat.render(str(spec.get("text", "{%s}" % spec.get("var", ""))), vars),
		"options": [],
	}
	steps.append({
		"kind": "answer", "title": MathData.step_title("answer"), "text": answer["text"],
		"lines": [], "note": "", "keys": "", "basic": "",
	})
	sol["ok"] = true
	sol["vars"] = vars
	sol["steps"] = steps
	sol["answer"] = answer
	sol["prompt"] = MathFormat.render(str(_level_spec(def, level).get("prompt", def.get("prompt", ""))), vars)
	sol["hint"] = MathFormat.render(str(def.get("hint", "")), vars)
	sol["title"] = str(def.get("title", type_id))
	sol["skill"] = str(def.get("skill", ""))
	sol["card"] = str(def.get("card", ""))
	return sol


static func _render_step(step: Dictionary, vars: Dictionary) -> Dictionary:
	var kind := str(step.get("kind", "calc"))
	var lines: Array = []
	for line in step.get("lines", []):
		lines.append(MathFormat.render(str(line), vars))
	var keys := MathFormat.render(str(step.get("keys", "")), vars, true)
	var basic := MathFormat.render(str(step.get("basic", "")), vars, true)
	return {
		"kind": kind,
		"title": MathFormat.render(str(step.get("title", MathData.step_title(kind))), vars),
		"text": MathFormat.render(str(step.get("text", "")), vars),
		"lines": lines,
		"note": MathFormat.render(str(step.get("note", "")), vars),
		"keys": keys,
		"basic": basic if basic != keys else "",
	}


## Choice answers get options: the answer plus up to three others, shuffled.
static func _add_options(sol: Dictionary, def: Dictionary, rng: RandomNumberGenerator) -> void:
	var answer: Dictionary = sol["answer"]
	if answer["kind"] != "choice":
		return
	var spec: Dictionary = def.get("answer", {})
	var correct := str(answer["value"])
	var others: Array = []
	if spec.has("options_table"):
		var table_id := str(sol["vars"].get(str(spec["options_table"]), spec["options_table"]))
		var keys := _table_keys(table_id)
		if spec.has("options_col"):
			keys = _column_values(table_id, str(sol["vars"].get(str(spec["options_col"]), spec["options_col"])))
		var at := keys.find(correct)
		for offset in [1, -1, 2, -2, 3, -3, 4]:
			var i: int = at + offset
			if at >= 0 and i >= 0 and i < keys.size() and others.size() < 3:
				others.append(keys[i])
	for expr in spec.get("distractors", []):
		var res := evaluate(str(expr), sol["vars"])
		var text := str(res[1]) if res[0] else ""
		if text != "" and text != correct and not others.has(text) and others.size() < 3:
			others.append(text)
	var options: Array = [correct]
	options.append_array(others)
	for i in range(options.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = options[i]
		options[i] = options[j]
		options[j] = tmp
	answer["options"] = options


## True when entered matches the solution's answer within its tolerance.
static func check(sol: Dictionary, entered: String) -> bool:
	var answer: Dictionary = sol.get("answer", {})
	if answer.get("kind", "number") == "choice":
		return entered.strip_edges() == str(answer.get("value", ""))
	var got := MathFormat.parse(entered)
	if is_nan(got):
		return false
	var want := float(answer.get("value", 0.0))
	var tol := float(answer.get("tol", 0.0))
	var allowed := tol * absf(want) if answer.get("rel", false) else tol
	return absf(got - want) <= allowed + 1e-6 * maxf(1.0, absf(want))


# --- exam questions -----------------------------------------------------------

static func _requirement(record_id: String) -> Dictionary:
	if _requirements.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(REQUIREMENTS_PATH)) if FileAccess.file_exists(REQUIREMENTS_PATH) else null
		_requirements = parsed.get("records", {}) if parsed is Dictionary else {"": {}}
	var req = _requirements.get(record_id)
	return req if req is Dictionary else {}


## {type, inputs, level, intro} for an exam record, or {} when it has no math
## solution. data/math/exam_steps.json wins; otherwise a requirement check
## whose kind a problem type declares in "from_check".
static func exam_plan(record: Dictionary) -> Dictionary:
	var id := str(record.get("id", ""))
	var entry = MathData.exam_steps().get(id)
	if entry is Dictionary:
		return entry
	var check = _requirement(id).get("check")
	if not (check is Dictionary):
		return {}
	for def in MathData.types():
		var fc = def.get("from_check")
		if not (fc is Dictionary) or str(fc.get("kind", "")) != str(check.get("kind", "")):
			continue
		if fc.has("when") and not _evaluate_check_when(str(fc["when"]), check):
			continue
		var inputs := {}
		for key in fc.get("fixed", {}):
			inputs[key] = fc["fixed"][key]
		var complete := true
		for key in fc.get("map", {}):
			var src := str(fc["map"][key])
			if not check.has(src):
				complete = false
				break
			inputs[key] = check[src]
		if not complete:
			continue
		for pair in fc.get("derive", []):
			var res := evaluate(str(pair[1]), inputs)
			if res[0]:
				inputs[str(pair[0])] = res[1]
		return {"type": str(def["id"]), "inputs": inputs}
	return {}


static func _evaluate_check_when(expr: String, check: Dictionary) -> bool:
	var e := Expression.new()
	var names := PackedStringArray(["check"])
	var values: Array = [check]
	for key in check:
		names.append(str(key))
		values.append(check[key])
	var wrapped := expr.replace("has(", "check.has(")
	if e.parse(wrapped, names) != OK:
		return false
	var out = e.execute(values, null, false)
	return not e.has_execute_failed() and bool(out)


## The worked solution for an exam record, {} when there is none.
static func exam_solution(record: Dictionary) -> Dictionary:
	var plan := exam_plan(record)
	if plan.is_empty():
		return {}
	var sol := solve(str(plan.get("type", "")), plan.get("inputs", {}), int(plan.get("level", 1)))
	if not sol.get("ok", false):
		return sol
	var intro := str(plan.get("intro", ""))
	if intro != "":
		(sol["steps"] as Array).insert(0, {
			"kind": "given", "title": MathData.step_title("given"), "text": intro,
			"lines": [], "note": "", "keys": "", "basic": "",
		})
	sol["record_id"] = str(record.get("id", ""))
	return sol


## True when the exam solution's answer is the record's keyed answer.
static func matches_key(sol: Dictionary, record: Dictionary) -> bool:
	var answers: Array = record.get("answers", [])
	var idx := int(record.get("correct_index", -1))
	if not sol.get("ok", false) or idx < 0 or idx >= answers.size():
		return false
	return MathFormat.same_value(sol["answer"]["value"], str(answers[idx]))
