class_name MathTrainerView
extends VBoxContainer
## Math Trainer. pick(): difficulty, "Practice my weak spots" and every skill
## with its accuracy. types(): one skill's problem types. An instance is the
## problem screen: a generated problem, a keypad (or choices), Hint, the
## formula card, Check, and the solution's steps shown in place.

const KEYPAD_ROWS := [["7", "8", "9", "⌫"], ["4", "5", "6", "C"], ["1", "2", "3", "/"], ["0", "."]]
const MAX_ENTRY := 12

var hub: MathHub
var skill := ""
var type_id := ""
var problem: Dictionary = {}
var entry := ""
var answered := false
var right := 0
var total := 0

var _problem_box: VBoxContainer
var _steps_box: VBoxContainer
var _steps: MathStepsView
var _meta: Label
var _score: Label
var _prompt: Label
var _hint: Label
var _entry_row: PanelContainer
var _entry_label: Label
var _unit_label: Label
var _pad: VBoxContainer
var _choices: GridContainer
var _result: PanelContainer
var _verdict: Label
var _answer_line: Label
var _hint_button: Button
var _card_button: Button
var _steps_button: Button
var _check_button: Button


# --- skill and type pickers -----------------------------------------------------

## Skills that have trainer problem types, in data order.
static func trainer_skills() -> Array:
	var out: Array = []
	for s in MathData.skills():
		if not MathData.trainer_types(str(s.get("id", ""))).is_empty():
			out.append(str(s["id"]))
	return out


static func pick(hub: MathHub) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	var h: float = MathUi.px(MathUi.BUTTON_H, hub.mobile)
	var fs: int = MathUi.px(MathUi.BUTTON, hub.mobile)
	var levels_row := HBoxContainer.new()
	levels_row.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	col.add_child(levels_row)
	var group := ButtonGroup.new()
	for lv in MathData.levels():
		var id := int(lv.get("id", 1))
		var chip := Widgets.make_chip(str(lv.get("label", id)), h, fs, group)
		chip.button_pressed = id == hub.level
		chip.pressed.connect(func() -> void:
			hub.level = id
			hub.sfx("toggle"))
		levels_row.add_child(chip)
	var skills := trainer_skills()
	var weakest: Array = hub.stats.weakest("skill", skills)
	var mix := Widgets.make_primary_button("Practice my weak spots", MathUi.px(MathUi.BUTTON_H, hub.mobile), MathUi.px(MathUi.BUTTON, hub.mobile), func() -> void:
		hub.sfx("click")
		hub.push("Weak-spot mix", "MORE PRACTICE WHERE YOU MISS MOST", MathTrainerView.solve.bind(hub, "", "")))
	mix.name = "WeakSpotMix"
	col.add_child(mix)
	var answered: Array = weakest.filter(func(id): return hub.stats.accuracy("skill", str(id)) >= 0.0)
	var note := "Answer a few problems in each topic and the mix leans toward the ones you miss."
	if not answered.is_empty():
		var names: Array = []
		for id in answered.slice(0, 3):
			names.append(str(MathData.skill_def(str(id)).get("short", id)))
		note = "Weakest so far: " + ", ".join(names) + ". The mix gives them more problems."
	col.add_child(MathUi.label(note, MathUi.px(MathUi.NOTE, hub.mobile) - 2, AppTheme.SLATE_400, AppTheme.WEIGHT_REGULAR, true))
	col.add_child(MathUi.meta_label("OR PICK A TOPIC", AppTheme.SLATE_400))
	var scroll := MathUi.scroll()
	col.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", AppTheme.SPACE_SM)
	grid.add_theme_constant_override("v_separation", AppTheme.SPACE_SM)
	scroll.add_child(grid)
	for id in skills:
		var def := MathData.skill_def(id)
		var title := str(def.get("short" if hub.mobile else "title", id))
		grid.add_child(_stat_tile(hub, title, MathUi.accuracy_text(hub.stats, "skill", id), MathUi.skill_color(id),
			hub.stats.accuracy("skill", id), MathUi.px(MathUi.TILE_H, hub.mobile),
			func() -> void:
				hub.sfx("click")
				hub.push(str(def.get("title", id)), "PICK A PROBLEM TYPE", MathTrainerView.types.bind(hub, id))))
	col.add_child(_reset_button(hub))
	return col


static func types(hub: MathHub, skill_id: String) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	var accent := MathUi.skill_color(skill_id)
	var title := str(MathData.skill_def(skill_id).get("title", skill_id))
	var all := Widgets.make_primary_button("All %s problems" % str(MathData.skill_def(skill_id).get("short", "")).to_lower(), MathUi.px(MathUi.BUTTON_H, hub.mobile), MathUi.px(MathUi.BUTTON, hub.mobile), func() -> void:
		hub.sfx("click")
		hub.push(title, "MIXED PROBLEM TYPES", MathTrainerView.solve.bind(hub, skill_id, "")))
	col.add_child(all)
	var scroll := MathUi.scroll()
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	scroll.add_child(list)
	for def in MathData.trainer_types(skill_id):
		var id := str(def.get("id", ""))
		list.add_child(_stat_tile(hub, str(def.get("title", id)), MathUi.accuracy_text(hub.stats, "type", id), accent,
			hub.stats.accuracy("type", id), MathUi.px(MathUi.TILE_H, hub.mobile),
			func() -> void:
				hub.sfx("click")
				hub.push(str(def.get("title", id)), title.to_upper(), MathTrainerView.solve.bind(hub, skill_id, id))))
	return col


## Accuracy per math topic (trainer and exam calculation answers) and per
## table drill, weakest first, with the weak-spot mix one press away.
static func weak_spots(hub: MathHub) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	var mix := Widgets.make_primary_button("Practice my weak spots", MathUi.px(MathUi.BUTTON_H, hub.mobile), MathUi.px(MathUi.BUTTON, hub.mobile), func() -> void:
		hub.sfx("click")
		hub.push("Weak-spot mix", "MORE PRACTICE WHERE YOU MISS MOST", MathTrainerView.solve.bind(hub, "", "")))
	mix.name = "WeakSpotMix"
	col.add_child(mix)
	var scroll := MathUi.scroll()
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", AppTheme.SPACE_XS + 2)
	scroll.add_child(list)
	list.add_child(MathUi.meta_label("MATH TOPICS · WEAKEST FIRST", AppTheme.SLATE_400))
	for id in hub.stats.weakest("skill", trainer_skills()):
		var def := MathData.skill_def(str(id))
		list.add_child(_stat_row(hub, str(def.get("title", id)), "skill", str(id), MathUi.skill_color(str(id)), func() -> void:
			hub.sfx("click")
			hub.push(str(def.get("title", id)), "PICK A PROBLEM TYPE", MathTrainerView.types.bind(hub, str(id)))))
	list.add_child(MathUi.meta_label("TABLE DRILLS", AppTheme.SLATE_400))
	var drill_ids: Array = []
	for d in MathData.drills():
		drill_ids.append(str(d.get("id", "")))
	for id in hub.stats.weakest("drill", drill_ids):
		var d := MathData.drill(str(id))
		list.add_child(_stat_row(hub, "%s · %s" % [d.get("ref", ""), d.get("title", "")], "drill", str(id), AppTheme.VIOLET_400, func() -> void:
			hub.sfx("click")
			hub.push(str(d.get("title", "")), str(d.get("ref", "")).to_upper(), MathDrillView.run.bind(hub, str(id)))))
	return col


## One weak-spot line: name, accuracy text and bar; pressing it practises.
static func _stat_row(hub: MathHub, title: String, group: String, id: String, accent: Color, callback: Callable) -> Button:
	return _stat_tile(hub, title, MathUi.accuracy_text(hub.stats, group, id), accent, hub.stats.accuracy(group, id), MathUi.px(MathUi.TILE_H, hub.mobile), callback)


## A list tile with an accuracy bar along its bottom edge.
static func _stat_tile(hub: MathHub, title: String, subtitle: String, accent: Color, accuracy: float, h: float, callback: Callable) -> Button:
	var b := MathUi.tile(title, subtitle, accent, h, MathUi.px(MathUi.TILE, hub.mobile), callback)
	var bar := MathUi.accuracy_bar(accuracy, 3.0)
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_left = AppTheme.ACCENT_BAR_W + AppTheme.SPACE_SM
	bar.offset_right = -AppTheme.SPACE_SM
	bar.offset_top = -AppTheme.SPACE_XS - 3
	bar.offset_bottom = -AppTheme.SPACE_XS
	b.add_child(bar)
	return b


## Clears the math accuracy after a second press within three seconds.
static func _reset_button(hub: MathHub) -> Button:
	var b := MathUi.ghost_button("Reset math progress", MathUi.px(MathUi.BUTTON_H, hub.mobile) - 8.0, func() -> void: pass, "", MathUi.px(MathUi.BUTTON, hub.mobile) - 2)
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	b.pressed.connect(func() -> void:
		hub.sfx("click")
		if b.has_meta("armed_until") and Time.get_ticks_msec() < int(b.get_meta("armed_until")):
			hub.stats.reset()
			hub.replace(hub.current_title(), "PROGRESS CLEARED", MathTrainerView.pick.bind(hub))
			return
		b.set_meta("armed_until", Time.get_ticks_msec() + 3000)
		b.text = "Press again to reset")
	return b


static func solve(hub: MathHub, skill_id: String, type: String) -> Control:
	return MathTrainerView.new(hub, skill_id, type)


# --- the problem screen ---------------------------------------------------------

func _init(h: MathHub, skill_id: String, type: String) -> void:
	hub = h
	skill = skill_id
	type_id = type
	add_theme_constant_override("separation", AppTheme.SPACE_SM)
	_problem_box = VBoxContainer.new()
	_problem_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_problem_box.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	add_child(_problem_box)
	_steps_box = VBoxContainer.new()
	_steps_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_steps_box.visible = false
	add_child(_steps_box)
	_steps = hub.make_steps_view()
	_steps.done.connect(_hide_steps)
	_steps_box.add_child(_steps)
	_build_problem_box()
	next_problem()


func _build_problem_box() -> void:
	var mobile := hub.mobile
	var top := HBoxContainer.new()
	_problem_box.add_child(top)
	_meta = MathUi.meta_label("", AppTheme.SKY_400)
	_meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_meta.clip_text = true
	top.add_child(_meta)
	_score = MathUi.meta_label("", AppTheme.SLATE_400)
	top.add_child(_score)
	var scroll := MathUi.scroll()
	_problem_box.add_child(scroll)
	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	scroll.add_child(text_col)
	_prompt = MathUi.label("", MathUi.px(MathUi.TEXT, mobile), AppTheme.SLATE_50, AppTheme.WEIGHT_MEDIUM, true)
	text_col.add_child(_prompt)
	_hint = MathUi.label("", MathUi.px(MathUi.NOTE, mobile), AppTheme.AMBER_200, AppTheme.WEIGHT_REGULAR, true)
	_hint.visible = false
	text_col.add_child(_hint)
	_result = MathUi.panel(AppTheme.FEEDBACK_BG, AppTheme.FEEDBACK_BORDER)
	_result.visible = false
	var result_col := VBoxContainer.new()
	_result.add_child(result_col)
	_verdict = MathUi.label("", MathUi.px(MathUi.TEXT, mobile) + 4, AppTheme.EMERALD_400, AppTheme.WEIGHT_BOLD)
	result_col.add_child(_verdict)
	_answer_line = MathUi.label("", MathUi.px(MathUi.BIG, mobile) - 4, AppTheme.SLATE_50, AppTheme.WEIGHT_SEMIBOLD, true)
	_answer_line.add_theme_font_override("font", AppTheme.numeric_font(AppTheme.WEIGHT_SEMIBOLD))
	result_col.add_child(_answer_line)
	_problem_box.add_child(_result)
	_entry_row = MathUi.panel(AppTheme.TABLE_PANEL_BG, AppTheme.SKY_700, AppTheme.SPACE_LG, AppTheme.SPACE_XS)
	var entry_h := HBoxContainer.new()
	entry_h.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	_entry_row.add_child(entry_h)
	_entry_label = MathUi.label("", MathUi.px(MathUi.ENTRY, mobile), AppTheme.SLATE_50, AppTheme.WEIGHT_BOLD)
	_entry_label.add_theme_font_override("font", AppTheme.numeric_font())
	_entry_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_entry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_entry_label.clip_text = true
	entry_h.add_child(_entry_label)
	_unit_label = MathUi.label("", MathUi.px(MathUi.TEXT, mobile), AppTheme.SLATE_400, AppTheme.WEIGHT_SEMIBOLD)
	_unit_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	entry_h.add_child(_unit_label)
	_problem_box.add_child(_entry_row)
	_pad = VBoxContainer.new()
	_pad.add_theme_constant_override("separation", AppTheme.SPACE_XS + 2)
	_problem_box.add_child(_pad)
	var key_h: float = MathUi.px(MathUi.KEY_H, mobile)
	for row_keys in KEYPAD_ROWS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", AppTheme.SPACE_XS + 2)
		_pad.add_child(row)
		for key in row_keys:
			var b := MathUi.choice(key, key_h, MathUi.px(MathUi.KEY, mobile), _press_key.bind(key))
			b.name = "Key_" + {"⌫": "back", "C": "clear", "/": "slash", ".": "dot"}.get(key, key)
			if key == "0":
				b.size_flags_stretch_ratio = 2.0
			if key in ["⌫", "C", "/", "."]:
				b.add_theme_color_override("font_color", AppTheme.AMBER_200)
			row.add_child(b)
	_choices = GridContainer.new()
	_choices.columns = 1 if mobile else 2
	_choices.add_theme_constant_override("h_separation", AppTheme.SPACE_SM)
	_choices.add_theme_constant_override("v_separation", AppTheme.SPACE_SM)
	_problem_box.add_child(_choices)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	_problem_box.add_child(actions)
	var h: float = MathUi.px(MathUi.BUTTON_H, mobile)
	_hint_button = MathUi.ghost_button("Hint", h, _show_hint, "tip")
	actions.add_child(_hint_button)
	_card_button = MathUi.ghost_button("Card", h, _open_card, "code")
	actions.add_child(_card_button)
	_steps_button = MathUi.ghost_button("Steps", h, _show_steps)
	actions.add_child(_steps_button)
	_check_button = Widgets.make_primary_button("Check", h, MathUi.px(MathUi.BUTTON, mobile), _on_check)
	_check_button.name = "Check"
	actions.add_child(_check_button)


## A new problem of the chosen type, skill, or weak-spot pick.
func next_problem() -> void:
	var t := _pick_type()
	problem = MathEngine.generate(t, hub.level, hub.rng)
	if problem.is_empty():
		problem = MathEngine.generate(t, 1, hub.rng)
	entry = ""
	answered = false
	_hint.visible = false
	_hint.text = str(problem.get("hint", ""))
	_hint_button.visible = _hint.text != ""
	_prompt.text = str(problem.get("prompt", ""))
	var skill_title := str(MathData.skill_def(str(problem.get("skill", ""))).get("short", ""))
	var level_label := ""
	for lv in MathData.levels():
		if int(lv.get("id", 0)) == int(problem.get("level", 1)):
			level_label = str(lv.get("label", ""))
	_meta.text = "%s · %s" % [skill_title.to_upper(), level_label.to_upper()]
	_score.text = "%d / %d RIGHT" % [right, total] if total > 0 else ""
	_card_button.visible = MathData.card(str(problem.get("card", ""))).size() > 0
	var answer: Dictionary = problem.get("answer", {})
	var is_choice := str(answer.get("kind", "")) == "choice"
	_unit_label.text = str(answer.get("unit", ""))
	_entry_row.visible = not is_choice
	_pad.visible = not is_choice
	_choices.visible = is_choice
	for c in _choices.get_children():
		_choices.remove_child(c)
		c.queue_free()
	if is_choice:
		for option in answer.get("options", []):
			var b := MathUi.choice(str(option), MathUi.px(MathUi.CHOICE_H, hub.mobile), MathUi.px(MathUi.KEY, hub.mobile), _pick_choice.bind(str(option)))
			_choices.add_child(b)
	_result.visible = false
	_check_button.text = "Check"
	_check_button.visible = not is_choice
	_steps_button.text = "Steps"
	_render_entry()
	_hide_steps()
	if not UiFx.reduce_motion and is_inside_tree():
		UiFx.screen_enter(_problem_box, false)


func _pick_type() -> String:
	if type_id != "":
		return type_id
	var s := skill
	if s == "":
		s = hub.stats.pick_weighted("skill", trainer_skills(), hub.rng)
	var ids: Array = []
	for def in MathData.trainer_types(s):
		ids.append(str(def.get("id", "")))
	return hub.stats.pick_weighted("type", ids, hub.rng)


func _render_entry() -> void:
	_entry_label.text = entry if entry != "" else "?"
	_entry_label.add_theme_color_override("font_color", AppTheme.SLATE_50 if entry != "" else AppTheme.SLATE_600)


func _press_key(key: String) -> void:
	if answered:
		return
	hub.sfx("click")
	match key:
		"⌫":
			entry = entry.substr(0, maxi(0, entry.length() - 1))
		"C":
			entry = ""
		_:
			if entry.length() < MAX_ENTRY and not (key in [".", "/"] and entry.contains(key)):
				entry += key
	_render_entry()


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or _steps_box.visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k := event as InputEventKey
	var ch := String.chr(k.unicode) if k.unicode > 0 else ""
	if answered:
		if k.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_RIGHT]:
			_on_check()
			get_viewport().set_input_as_handled()
		return
	if ch != "" and "0123456789./".contains(ch):
		_press_key(ch)
	elif k.keycode == KEY_BACKSPACE:
		_press_key("⌫")
	elif k.keycode == KEY_DELETE:
		_press_key("C")
	elif k.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		_on_check()
	else:
		return
	get_viewport().set_input_as_handled()


## Check before answering; Next problem after.
func _on_check() -> void:
	if answered:
		hub.sfx("click")
		next_problem()
		return
	if entry == "" or is_nan(MathFormat.parse(entry)):
		hub.sfx("warning")
		UiFx.screen_enter(_entry_row, false)
		return
	_grade(MathEngine.check(problem, entry), entry)


func _pick_choice(option: String) -> void:
	if answered:
		return
	_grade(MathEngine.check(problem, option), option)
	var want := str(problem.get("answer", {}).get("value", ""))
	for b in _choices.get_children():
		var text := (b as Button).text
		MathUi.set_choice_state(b, "right" if text == want else ("wrong" if text == option else "faded"))


func _grade(ok: bool, given: String) -> void:
	answered = true
	total += 1
	if ok:
		right += 1
	hub.stats.record("skill", str(problem.get("skill", "")), ok)
	hub.stats.record("type", str(problem.get("type", "")), ok)
	hub.sfx("correct" if ok else "wrong")
	var answer: Dictionary = problem.get("answer", {})
	_verdict.text = "Correct!" if ok else "Not quite"
	_verdict.add_theme_color_override("font_color", AppTheme.EMERALD_400 if ok else AppTheme.ROSE_400)
	_answer_line.text = "Answer: " + str(answer.get("text", ""))
	if not ok and given != "" and str(answer.get("kind", "")) != "choice":
		_answer_line.text += "   (you entered %s)" % given
	_result.visible = true
	_entry_row.visible = false
	_pad.visible = false
	_check_button.text = "Next problem"
	_check_button.visible = true
	_steps_button.text = "Show steps"
	_score.text = "%d / %d RIGHT" % [right, total]
	if not UiFx.reduce_motion:
		UiFx.screen_enter(_result, false)


func _show_hint() -> void:
	hub.sfx("click")
	_hint.visible = not _hint.visible


func _open_card() -> void:
	hub.sfx("click")
	var id := str(problem.get("card", ""))
	var index := -1
	var cards := MathData.cards()
	for i in cards.size():
		if str(cards[i].get("id", "")) == id:
			index = i
	if index >= 0:
		hub.push(str(cards[index].get("title", "")), "FORMULA CARD", MathCardsView.card_screen.bind(hub, index, false))


## Steps before answering count as a miss: the solution shows the answer.
func _show_steps() -> void:
	hub.sfx("click")
	if not answered:
		_grade(false, "")
		_verdict.text = "Here's how"
		_verdict.add_theme_color_override("font_color", AppTheme.SKY_400)
	_problem_box.visible = false
	_steps_box.visible = true
	_steps.show_solution(problem)


func _hide_steps() -> void:
	hub.stop_speaking()
	_steps_box.visible = false
	_problem_box.visible = true


func handle_back() -> bool:
	if _steps_box.visible:
		_hide_steps()
		return true
	return false
