extends SceneTree
## Math study screens inside the real app: every screen of the trainer,
## formula cards, table drills, weak spots and exam step-by-step opens, works
## and fits the window without the page scrolling (inner lists may scroll),
## at the standard desktop and phone sizes. The exam "Show steps" button stays
## hidden until the question is answered.
##
##   Godot --headless --path . --script tools/tests/test_math_ui.gd [-- --mobile-ui]
##
## Without --mobile-ui the suite also runs itself once with it.

const DESKTOP_SIZES := [Vector2i(1280, 720), Vector2i(1024, 600), Vector2i(1920, 1080)]
const MOBILE_SIZES := [Vector2i(360, 640), Vector2i(412, 915), Vector2i(540, 960), Vector2i(800, 1280)]
const TOL := 0.5

var failures: Array[String] = []
var checks := 0
var main: Main
var hub: MathHub
var size_label := ""


func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func _frames(n: int = 3) -> void:
	for i in n:
		await process_frame


func _initialize() -> void:
	var mobile := "--mobile-ui" in OS.get_cmdline_user_args()
	print("=== math screens (%s) ===" % ("mobile" if mobile else "desktop"))
	MathHub.stats_path = "user://test_math_ui_stats.cfg"
	MathStats.new(MathHub.stats_path).reset()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	main = load("res://scenes/main.tscn").instantiate()
	main.audio_cfg_path = "user://test_math_ui_audio.cfg"
	main.session.bag_path = ""
	root.add_child(main)
	await _frames(10)
	for size in (MOBILE_SIZES if mobile else DESKTOP_SIZES):
		_emulate(size, mobile)
		await _frames(4)
		print("  window %s -> viewport %s" % [size_label, str(root.get_viewport().get_visible_rect().size)])
		await _screens()
	await _all_types_fit(MOBILE_SIZES[0] if mobile else DESKTOP_SIZES[1])
	await _exam_steps()
	_tools_data()
	MathStats.new(MathHub.stats_path).reset()
	var child_ok := true
	if not mobile:
		child_ok = _run_mobile_child()
	print("checks: %d  failures: %d" % [checks, failures.size()])
	print("RESULT: ", "PASS" if failures.is_empty() and child_ok else "FAIL")
	quit(0 if failures.is_empty() and child_ok else 1)


## Headless keeps one fixed window, so each window size is emulated by its
## logical canvas: the "expand" stretch of the layout's base size (project
## 540x960 on phones, Main's 900x960 on desktop), as a real window shows it.
func _emulate(win: Vector2i, mobile: bool) -> void:
	var base := Vector2(540, 960) if mobile else Vector2(Main.DESKTOP_MIN_CANVAS_WIDTH, 960)
	var k := minf(win.x / base.x, win.y / base.y)
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = Vector2i(roundi(win.x / k), roundi(win.y / k))
	size_label = "%dx%d" % [win.x, win.y]


## The hub's column fits its margins: nothing on the page is cut off.
func _fits(what: String) -> void:
	await _frames(3)
	var margin := hub._margin
	var col := margin.get_child(0) as Control
	var need := col.get_combined_minimum_size()
	var vp := root.get_viewport().get_visible_rect().size
	check(hub.visible, "%s %s: hub visible" % [size_label, what])
	check(need.y <= col.size.y + TOL and col.size.y <= vp.y + TOL, "%s %s: fits height (needs %.0f, has %.0f)" % [size_label, what, need.y, col.size.y])
	check(need.x <= col.size.x + TOL and col.size.x <= vp.x + TOL, "%s %s: fits width (needs %.0f, has %.0f)" % [size_label, what, need.x, col.size.x])


func _find(node: Node, name_part: String) -> Node:
	if node.name.contains(name_part):
		return node
	for c in node.get_children():
		var hit := _find(c, name_part)
		if hit != null:
			return hit
	return null


func _find_type(node: Node, cls: String) -> Node:
	if node.get_script() != null and node.get_script().get_global_name() == cls:
		return node
	for c in node.get_children():
		var hit := _find_type(c, cls)
		if hit != null:
			return hit
	return null


func _screens() -> void:
	MathHub.open(main, "trainer")
	hub = main.get_node("MathHub") as MathHub
	await _fits("trainer topics")
	check(hub.current_title() == str(MathData.tool("trainer")["title"]), "%s trainer title from tools.json" % size_label)
	hub.push("Motors", "PICK", MathTrainerView.types.bind(hub, "motors"))
	await _fits("trainer types")
	hub.push("Find current", "OHMS", MathTrainerView.solve.bind(hub, "ohms", "ohm_current"))
	await _fits("trainer problem")
	var view := hub.current_screen() as MathTrainerView
	check(view != null and view._pad.visible and not view._result.visible, "%s calculator shown before answering" % size_label)
	check(CalcEngine.KEYS.all(func(k: String) -> bool: return view._pad.key_button(k) != null and view._pad.key_button(k).is_visible_in_tree()),
		"%s the answer calculator has every key" % size_label)
	check(view._pad.display_text() == "?" and view._pad._unit.text == "A", "%s blank entry with the unit (%s %s)" % [size_label, view._pad.display_text(), view._pad._unit.text])
	var want := str(view.problem["answer"]["value"])
	view.press_keys(MathFormat.number(float(want), -1, false))
	view._on_check()
	check(view.answered and view._verdict.text == "Correct!", "%s typed answer %s graded correct" % [size_label, want])
	await _fits("trainer answered")
	view._show_steps()
	var steps := view._steps
	check(steps.steps.size() >= 2 and steps.index == 0, "%s steps start at step 1" % size_label)
	await _fits("trainer steps")
	for i in steps.steps.size() + 1:
		steps._go(1)
	check(not view._steps_box.visible, "%s Done returns to the problem" % size_label)
	check(hub.stats.attempts("type", "ohm_current") >= 1, "%s trainer answer recorded" % size_label)
	view._on_check()
	check(not view.answered and view._pad.display_text() == "?" and view.entry() == "" and not view._pad.locked, "%s Next problem clears the entry" % size_label)
	view.press_keys("99")
	view._on_check()
	check(view._verdict.text == "Not quite" or view.problem["answer"]["value"] == 99.0, "%s wrong answer graded" % size_label)
	await _work_on_pad(view)
	# A choice-answer type shows choices, not the keypad.
	hub.replace("EGC", "CODE", MathTrainerView.solve.bind(hub, "code_calcs", "egc_size"))
	await _fits("trainer choices")
	view = hub.current_screen() as MathTrainerView
	check(view._choices.visible and not view._pad.visible and view._choices.get_child_count() >= 2, "%s choice problem shows choices" % size_label)
	view._pick_choice(str(view.problem["answer"]["value"]))
	check(view._verdict.text == "Correct!", "%s right choice graded correct" % size_label)
	hub.go_back()
	hub.go_back()
	check(hub.current_title() == str(MathData.tool("trainer")["title"]), "%s Back walks the stack" % size_label)
	hub.go_back()
	check(not hub.visible, "%s Back from the first screen closes" % size_label)

	MathHub.open(main, "cards")
	await _fits("card list")
	for i in MathData.cards().size():
		hub.push("card", "CARD", MathCardsView.card_screen.bind(hub, i, true))
		await _fits("card %s" % MathData.cards()[i]["id"])
		var example := _find(hub.current_screen(), "WorkedExample") as Button
		check(example != null and not example.disabled, "%s card %s has a worked example" % [size_label, MathData.cards()[i]["id"]])
		hub.go_back()
	hub.push("card", "CARD", MathCardsView.card_screen.bind(hub, 0, true))
	(_find(hub.current_screen(), "WorkedExample") as Button).pressed.emit()
	await _fits("worked example")
	check(_find_type(hub.current_screen(), "MathStepsView") != null, "%s worked example shows steps" % size_label)
	hub.close()

	MathHub.open(main, "drills")
	await _fits("drill list")
	for d in MathData.drills():
		hub.push("drill", "DRILL", MathDrillView.run.bind(hub, str(d["id"])))
		await _fits("drill %s" % d["id"])
		var run := hub.current_screen() as MathDrillView
		for q in run.count:
			run._pick(int(run.question["answer_index"]))
			if q == 0:
				await _fits("drill %s answered" % d["id"])
			run._advance()
		await _frames(2)
		check(hub.current_screen() is VBoxContainer and not (hub.current_screen() is MathDrillView), "%s drill %s ends on its result" % [size_label, d["id"]])
		await _fits("drill %s result" % d["id"])
		check(int(hub.stats.best(str(d["id"])).get("right", -1)) == MathDrills.count(d), "%s drill %s best run saved" % [size_label, d["id"]])
		hub.go_back()
	hub.close()

	MathHub.open(main, "weak_spots")
	await _fits("weak spots")
	check(_find(hub.current_screen(), "WeakSpotMix") != null, "%s weak spots offer the mix" % size_label)
	(_find(hub.current_screen(), "WeakSpotMix") as Button).pressed.emit()
	await _fits("weak-spot mix")
	check(hub.current_screen() is MathTrainerView, "%s mix opens a problem" % size_label)
	hub.close()

	await _steps_pad()


func _key(view: MathTrainerView, keycode: Key, ch: String = "") -> void:
	var e := InputEventKey.new()
	e.keycode = keycode
	e.unicode = ch.unicode_at(0) if ch != "" else 0
	e.pressed = true
	view._unhandled_key_input(e)


## A fresh problem graded against a fixed answer.
func _fixed(view: MathTrainerView, value: float, text: String, tol: float = 0.0) -> void:
	view.next_problem()
	view.problem = MathEngine.solve("ohm_voltage", {"I": 12, "R": 24}, 1)
	view.problem["answer"].merge({"value": value, "text": text, "tol": tol, "rel": false}, true)


## The problem is worked on the answer calculator: Check finishes a pending
## operation and submits the number shown; Enter does = then Check; a
## fraction answer goes in as a division; keys stop once checked.
func _work_on_pad(view: MathTrainerView) -> void:
	_fixed(view, 288.0, "288 V")
	view.press_keys("12 × 24")
	check(view._pad.display_text() == "24" and view._pad.engine.pending() == "12 ×" and not view._result.visible,
		"%s 12 × 24 is pending, nothing revealed" % size_label)
	view._on_check()
	check(view.answered and view._verdict.text == "Correct!" and view._pad.display_text() == "288", "%s 12 × 24 then Check: 288 correct" % size_label)
	view._pad.press("5")
	check(view._pad.display_text() == "288", "%s the pad is locked once checked" % size_label)
	_fixed(view, 288.0, "288 V")
	for ch in "12*24":
		_key(view, KEY_NONE, ch)
	_key(view, KEY_ENTER)
	check(not view.answered and view._pad.display_text() == "288", "%s keyboard 12*24 Enter shows 288 (%s)" % [size_label, view._pad.display_text()])
	_key(view, KEY_ENTER)
	check(view.answered and view._verdict.text == "Correct!", "%s a second Enter checks" % size_label)
	_fixed(view, 288.0, "288 V")
	for ch in "123":
		_key(view, KEY_NONE, ch)
	_key(view, KEY_BACKSPACE)
	check(view._pad.display_text() == "12", "%s Backspace deletes a digit" % size_label)
	view.press_keys("×")
	view._on_check()
	check(not view.answered, "%s Check waits while an operator has no number" % size_label)
	_fixed(view, 0.95, "19/20")
	view.press_keys("19 ÷ 20 =")
	view._on_check()
	check(view._verdict.text == "Correct!", "%s fraction answer 19/20 entered as 19 ÷ 20" % size_label)
	_fixed(view, 1.0 / 300.0, "1/300")
	view.press_keys("1 ÷ 300")
	view._on_check()
	check(view._verdict.text == "Correct!", "%s fraction answer 1/300 entered as 1 ÷ 300 (%s)" % [size_label, view._pad.display_text()])
	_fixed(view, 288.0, "288 V")
	await _fits("trainer pad working")


## "Try it on the calculator" under a step with keys: the pad follows the row,
## lights the next key, stays open on the next step, and fits.
func _steps_pad() -> void:
	var sol := MathEngine.solve("dwelling_lighting", {"units": 14, "area": 1250, "sa": 2}, 3)
	check(sol.get("ok", false), "%s dwelling solution for the pad" % size_label)
	MathHub.open(main, "trainer")
	hub.push("Step-by-step", "PAD", hub.steps_screen.bind(sol, ""))
	var view := _find_type(hub.current_screen(), "MathStepsView") as MathStepsView
	var at := -1
	for i in view.steps.size():
		if str(view.steps[i].get("keys", "")).begins_with("×"):
			at = i
			break
	check(at > 0, "%s a step continues from the last result" % size_label)
	view.index = at
	view._render()
	check(view.pad == null and _find(view, "PadToggle") != null, "%s pad closed until asked" % size_label)
	view.toggle_pad()
	await _fits("steps with calculator")
	var pad := view.pad
	check(pad != null and pad.is_guiding(), "%s toggle opens a guided pad" % size_label)
	var row := CalcEngine.pad_keys(view.steps[at])
	check(pad.next_key() == CalcEngine.sequence_keys(row)[0], "%s the first key of the row is lit" % size_label)
	for key in CalcEngine.sequence_keys(row):
		pad.key_button(key).pressed.emit()
	check(pad.next_key() == "" and pad.matches() and pad.hint_text().begins_with("Done"),
		"%s the primed pad lands on the step's figure (%s: %s)" % [size_label, pad.display_text(), pad.hint_text()])
	view._go(1)
	check(view.pad_open, "%s the calculator stays open on the next step" % size_label)
	hub.close()


## Every trainer type at every level fits the smallest window of the layout.
func _all_types_fit(size: Vector2i) -> void:
	_emulate(size, main.ui_mobile)
	await _frames(4)
	MathHub.open(main, "trainer")
	for def in MathData.trainer_types():
		for lv in MathData.levels():
			hub.level = int(lv["id"])
			hub.push("t", "T", MathTrainerView.solve.bind(hub, "", str(def["id"])))
			await _fits("type %s level %s" % [def["id"], lv["id"]])
			var view := hub.current_screen() as MathTrainerView
			check(not view.problem.is_empty(), "type %s level %s generates" % [def["id"], lv["id"]])
			view._show_steps()
			await _fits("type %s level %s steps" % [def["id"], lv["id"]])
			hub.go_back()
			hub.go_back()
	hub.close()


## Show steps: hidden before the answer, offered after, and the steps reach
## the keyed answer.
func _exam_steps() -> void:
	MathHub.attach(main)
	var idx := -1
	for i in main.records.size():
		if MathEngine.exam_solution(main.records[i]).get("ok", false):
			idx = i
			break
	check(idx >= 0, "a calculation record exists")
	main._start_quiz(10, 1800, true, "10-Question Practice")
	main.timer.stop()
	while main._start_tween != null and main._start_tween.is_running():
		await process_frame
	main.order = [idx, (idx + 1) % main.records.size()] as Array[int]
	main.current_index = 0
	main._show_question()
	MathHub.on_question(main)
	var button := MathHub._steps_button(main)
	check(button != null and not button.visible, "Show steps hidden before answering")
	var record: Dictionary = main.session.current_record()
	main._answer_selected(int(record["correct_index"]))
	MathHub.on_answered(main, record, true)
	check(button.visible, "Show steps offered after answering")
	button.pressed.emit()
	await _frames(3)
	check(hub.visible and hub.current_title() == "Step-by-step", "Show steps opens the solution")
	var steps := _find_type(hub.current_screen(), "MathStepsView") as MathStepsView
	check(steps != null and str(steps.steps.back()["kind"]) == "answer", "exam solution ends on the answer")
	await _fits("exam steps")
	check(MathStats.new(MathHub.stats_path).attempts("type", str(MathEngine.exam_plan(record)["type"])) >= 1, "exam calc answer counted for its type")
	check(MathHub.handle_back(main) and not hub.visible, "Back closes the solution")
	main._next_question()
	MathHub.on_question(main)
	check(not button.visible, "next question hides Show steps")


func _tools_data() -> void:
	check(MathData.tools().size() == 4 and MathData.tool("calculator").is_empty(), "Study lists the four tools, no standalone calculator")
	for id in ["trainer", "cards", "drills", "weak_spots"]:
		var t := MathData.tool(id)
		check(str(t.get("title", "")) != "" and str(t.get("description", "")) != "", "tool %s described" % id)
		check(Icons.sdf(str(t.get("icon", "")), Vector2(12, 12)) < 1e5, "tool %s icon exists" % id)
		check(not MathData.tool_detail(id).contains("{"), "tool %s detail filled: %s" % [id, MathData.tool_detail(id)])
		var b := MathHub.make_tool_button(main, id)
		check(b.text.begins_with(str(t["title"])), "tool %s button" % id)
		b.free()


func _run_mobile_child() -> bool:
	var out: Array = []
	var code := OS.execute(OS.get_executable_path(),
			["--headless", "--path", ".", "--script", "tools/tests/test_math_ui.gd", "--", "--mobile-ui"], out, true)
	var text := ""
	for chunk in out:
		text += str(chunk)
	for line in text.split("\n"):
		if line.contains("FAIL") or line.contains("checks:") or line.contains("viewport") or line.begins_with("==="):
			print("  [mobile] " + line.strip_edges())
	return code == 0
