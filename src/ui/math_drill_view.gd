class_name MathDrillView
extends VBoxContainer
## Table Drills. list(): every drill with its accuracy and best run. An
## instance is a timed run: MathDrills.count() lookups, four choices each, the
## table cell explained after every answer. The clock only runs while a
## question waits for an answer, so reading the explanation costs nothing.

var hub: MathHub
var drill: Dictionary = {}
var count := 8
var seconds := 120
var index := 0
var right := 0
var used := 0.0
var question: Dictionary = {}
var answered := false

var _progress: Label
var _clock: Label
var _bar: ProgressBar
var _prompt: Label
var _choices: GridContainer
var _where: Label
var _next: Button


static func list(hub: MathHub) -> Control:
	var scroll := MathUi.scroll()
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	scroll.add_child(col)
	for d in MathData.drills():
		var id := str(d.get("id", ""))
		var best := hub.stats.best(id)
		var sub := "%s · %d lookups in %d s" % [d.get("ref", ""), MathDrills.count(d), MathDrills.seconds(d)]
		if not best.is_empty():
			sub += " · best %d/%d in %d s" % [int(best["right"]), int(best["total"]), roundi(float(best["seconds"]))]
		col.add_child(MathTrainerView._stat_tile(hub, str(d.get("title", id)), sub, AppTheme.VIOLET_400,
			hub.stats.accuracy("drill", id), MathUi.px(MathUi.TILE_H, hub.mobile),
			func() -> void:
				hub.sfx(Sfx.START)
				hub.push(str(d.get("title", id)), str(d.get("ref", "")).to_upper(), MathDrillView.run.bind(hub, id))))
	return scroll


static func run(hub: MathHub, drill_id: String) -> Control:
	return MathDrillView.new(hub, drill_id)


func _init(h: MathHub, drill_id: String) -> void:
	hub = h
	drill = MathData.drill(drill_id)
	count = MathDrills.count(drill)
	seconds = MathDrills.seconds(drill)
	add_theme_constant_override("separation", AppTheme.SPACE_SM)
	var top := HBoxContainer.new()
	add_child(top)
	_progress = MathUi.meta_label("", AppTheme.VIOLET_400)
	_progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_progress)
	_clock = MathUi.label("", MathUi.px(MathUi.TEXT, hub.mobile), AppTheme.SLATE_100, AppTheme.WEIGHT_BOLD)
	_clock.add_theme_font_override("font", AppTheme.numeric_font())
	top.add_child(_clock)
	_bar = MathUi.accuracy_bar(1.0, 6.0)
	_bar.add_theme_stylebox_override("fill", AppTheme.panel_style(AppTheme.VIOLET_400, Color.TRANSPARENT, 0, 3))
	add_child(_bar)
	var scroll := MathUi.scroll()
	add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", AppTheme.SPACE_MD)
	scroll.add_child(body)
	_prompt = MathUi.label("", MathUi.px(MathUi.BIG, hub.mobile) - 4, AppTheme.SLATE_50, AppTheme.WEIGHT_BOLD, true)
	body.add_child(_prompt)
	_where = MathUi.label("", MathUi.px(MathUi.NOTE, hub.mobile), AppTheme.SLATE_300, AppTheme.WEIGHT_REGULAR, true)
	body.add_child(_where)
	_choices = GridContainer.new()
	_choices.columns = 1 if hub.mobile else 2
	_choices.add_theme_constant_override("h_separation", AppTheme.SPACE_SM)
	_choices.add_theme_constant_override("v_separation", AppTheme.SPACE_SM)
	add_child(_choices)
	_next = Widgets.make_primary_button("Next", MathUi.px(MathUi.BUTTON_H, hub.mobile), MathUi.px(MathUi.BUTTON, hub.mobile), _advance)
	_next.name = "Next"
	add_child(_next)
	_show_question()


func _process(delta: float) -> void:
	if answered or not is_visible_in_tree():
		return
	used += delta
	_render_clock()
	if used >= seconds:
		_finish()


func _render_clock() -> void:
	var left := maxf(0.0, seconds - used)
	_clock.text = "%d:%02d" % [int(left) / 60, int(left) % 60]
	_clock.add_theme_color_override("font_color", AppTheme.ROSE_400 if left <= 15.0 else AppTheme.SLATE_100)
	_bar.value = left / float(seconds)


func _show_question() -> void:
	question = MathDrills.question(drill, hub.rng)
	answered = false
	_progress.text = "LOOKUP %d OF %d · %d RIGHT" % [index + 1, count, right]
	_prompt.text = str(question.get("prompt", ""))
	_where.text = "Find it in %s." % drill.get("ref", "the table")
	_where.add_theme_color_override("font_color", AppTheme.SLATE_400)
	for c in _choices.get_children():
		_choices.remove_child(c)
		c.queue_free()
	var options: Array = question.get("options", [])
	for i in options.size():
		_choices.add_child(MathUi.choice(str(options[i]), MathUi.px(MathUi.CHOICE_H, hub.mobile), MathUi.px(MathUi.KEY, hub.mobile), _pick.bind(i)))
	_next.visible = false
	_render_clock()


func _pick(i: int) -> void:
	if answered:
		return
	answered = true
	var ok := i == int(question.get("answer_index", -1))
	if ok:
		right += 1
	hub.stats.record("drill", str(drill.get("id", "")), ok)
	hub.sfx("correct" if ok else "wrong")
	var buttons := _choices.get_children()
	for j in buttons.size():
		MathUi.set_choice_state(buttons[j], "right" if j == int(question["answer_index"]) else ("wrong" if j == i else "faded"))
	_where.text = str(question.get("where", ""))
	_where.add_theme_color_override("font_color", AppTheme.EMERALD_200 if ok else AppTheme.AMBER_200)
	_progress.text = "LOOKUP %d OF %d · %d RIGHT" % [index + 1, count, right]
	_next.text = "See results" if index >= count - 1 else "Next"
	_next.visible = true


func _advance() -> void:
	hub.sfx("click")
	index += 1
	if index >= count:
		_finish()
	else:
		_show_question()


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k := event as InputEventKey
	if answered and k.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_RIGHT]:
		_advance()
	elif not answered and k.keycode >= KEY_1 and k.keycode <= KEY_4 and k.keycode - KEY_1 < _choices.get_child_count():
		_pick(k.keycode - KEY_1)
	else:
		return
	get_viewport().set_input_as_handled()


func _finish() -> void:
	set_process(false)
	answered = true
	var id := str(drill.get("id", ""))
	var new_best := hub.stats.record_best(id, right, count, used)
	hub.sfx("pass" if right * 100 >= count * QuizSession.PASS_PERCENT else "fail")
	hub.replace(str(drill.get("title", "")), "RESULT", MathDrillView.result.bind(hub, id, right, count, used, new_best))


static func result(hub: MathHub, drill_id: String, got: int, total: int, time_used: float, new_best: bool) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", AppTheme.SPACE_MD)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var pass_mark := got * 100 >= total * QuizSession.PASS_PERCENT
	var big := MathUi.label("%d / %d" % [got, total], AppTheme.TYPE_DISPLAY, AppTheme.EMERALD_400 if pass_mark else AppTheme.AMBER_400, AppTheme.WEIGHT_BOLD)
	big.add_theme_font_override("font", AppTheme.numeric_font())
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(big)
	var line := "right in %d seconds" % roundi(time_used)
	if new_best:
		line += " · new best!"
	var sub := MathUi.label(line, MathUi.px(MathUi.TEXT, hub.mobile), AppTheme.SLATE_200, AppTheme.WEIGHT_MEDIUM, true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	var h: float = MathUi.px(MathUi.BUTTON_H, hub.mobile)
	var again := Widgets.make_primary_button("Try again", h, MathUi.px(MathUi.BUTTON, hub.mobile), func() -> void:
		hub.sfx(Sfx.START)
		var d := MathData.drill(drill_id)
		hub.replace(str(d.get("title", "")), str(d.get("ref", "")).to_upper(), MathDrillView.run.bind(hub, drill_id)))
	again.name = "TryAgain"
	again.size_flags_horizontal = Control.SIZE_FILL
	col.add_child(again)
	var back := MathUi.ghost_button("All table drills", h, func() -> void:
		hub.sfx("click")
		hub.go_back())
	col.add_child(back)
	return col
