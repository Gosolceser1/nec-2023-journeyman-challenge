extends SceneTree
## Records with both a figure and a reference table, at every standard window
## size: before answering the page does not scroll, and neither table scrolls
## before or after answering. Each record runs in its bank order and two seeded
## choice shuffles, as sessions show them.
##
##   Godot --headless --path . --script tools/tests/test_figure_table_fit.gd [-- --mobile-ui]
##
## Without --mobile-ui the suite also runs itself once with it.

const R = preload("res://tools/tests/t_report.gd")
const TOL := 0.5
const DESKTOP_SIZES := [Vector2i(1280, 720), Vector2i(1024, 600), Vector2i(1920, 1080)]
const PHONE_SIZES := [Vector2i(360, 640), Vector2i(412, 915), Vector2i(540, 960), Vector2i(800, 1280)]
const SEEDS := [0, 2023, 70]

var t: R = R.new()
var main: Node
var mobile := false
## The project's stretch base (main widens it on desktop).
var base := Vector2.ZERO


func _initialize() -> void:
	mobile = "--mobile-ui" in OS.get_cmdline_user_args()
	print("=== figure + reference table fit (%s) ===" % ("mobile" if mobile else "desktop"))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _frames(6)
	main.audio_cfg_path = "user://test_figure_table_fit_audio.cfg"
	main.session.bag_path = ""
	main._on_audio_mode_picked(AudioSettings.Mode.SILENT)
	main._start_quiz(10, 1800, true, "Practice Test")
	main.timer.stop()
	while main._start_tween != null and main._start_tween.is_running():
		await process_frame
	await _frames(2)
	base = Vector2(root.content_scale_size)
	var picked := _records()
	t.check(picked.size() > 0, "the bank has records with a figure and a table")
	print("  %d records with a figure and a table" % picked.size())
	for s in (PHONE_SIZES if mobile else DESKTOP_SIZES):
		await _sweep(s, picked)
	var child_ok := true
	if not mobile:
		child_ok = _run_mobile_child()
	t.report()
	quit(0 if t.failures.is_empty() and child_ok else 1)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _records() -> Array[int]:
	var out: Array[int] = []
	for i in main.records.size():
		var rec: Dictionary = main.records[i]
		var table = rec.get("reference_table", [])
		if table is Array and not (table as Array).is_empty() and DiagramView.has_figure(rec):
			out.append(i)
	return out


func _page_scroll() -> ScrollContainer:
	var n: Node = main.answers_box
	while n != null and not n is ScrollContainer:
		n = n.get_parent()
	return n as ScrollContainer


func _overflow(scroll: ScrollContainer) -> float:
	return (scroll.get_child(0) as Control).get_combined_minimum_size().y - scroll.size.y


func _table_whole(box: ScrollContainer, what: String) -> void:
	if not box.is_visible_in_tree():
		return
	var need := (box.get_child(0) as Control).get_combined_minimum_size()
	t.check(not box.get_v_scroll_bar().visible and not box.get_h_scroll_bar().visible
			and need.y <= box.size.y + TOL and need.x <= box.size.x + TOL,
			"%s: table shows whole (%.0fx%.0f in %.0fx%.0f)" % [what, need.x, need.y, box.size.x, box.size.y])


## The canvas a real window of this size gets under the "canvas_items" /
## "expand" stretch. Headless runs have one fake 960x960 window, so the test
## pins the root viewport to that canvas instead of resizing the window.
func _canvas_for(win: Vector2i) -> Vector2i:
	var s := minf(win.x / base.x, win.y / base.y)
	return Vector2i(roundi(win.x / s), roundi(win.y / s))


func _sweep(win: Vector2i, picked: Array[int]) -> void:
	var canvas := _canvas_for(win)
	root.content_scale_size = canvas
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	await _frames(8)
	t.check(Vector2i(root.get_visible_rect().size) == canvas, "%dx%d: canvas is %s" % [win.x, win.y, str(canvas)])
	var scroll := _page_scroll()
	var n: int = main.records.size()
	var worst := -INF
	var worst_at := ""
	for i in picked:
		var rec: Dictionary = main.records[i]
		var qid := str(rec.get("id", i))
		for seed in SEEDS:
			if seed == 0:
				main.session.choice_orders.erase(i)
			else:
				var rng := RandomNumberGenerator.new()
				rng.seed = seed
				main.session.choice_orders[i] = ChoiceOrder.shuffled(rec, rng)
			var what := "%dx%d %s order %d" % [win.x, win.y, qid, seed]
			main.order = [i, (i + 1) % n] as Array[int]
			main.current_index = 0
			main._show_question()
			main._auto_token += 1
			# The table fit steps once per frame.
			await _frames(12)
			var pre := _overflow(scroll)
			if pre > worst:
				worst = pre
				worst_at = what
			t.check(pre <= TOL, "%s: no page scroll before answering (%.0f px over)" % [what, pre])
			_table_whole(main.question_table_scroll, what + " before answering")
			var shown: Dictionary = main.session.display_record(i)
			main._answer_selected((int(shown.get("correct_index", 0)) + 1) % (shown.get("answers", []) as Array).size())
			main._auto_token += 1
			main._stop_reading()
			await _frames(4)
			_table_whole(main.feedback_table_scroll, what + " after answering")
		main.session.choice_orders.erase(i)
	var vp := root.get_viewport().get_visible_rect().size
	print("  %dx%d (canvas %dx%d): tightest %s (%.0f px)" % [win.x, win.y, int(vp.x), int(vp.y), worst_at, worst])


func _run_mobile_child() -> bool:
	var out: Array = []
	var code := OS.execute(OS.get_executable_path(),
			["--headless", "--path", ".", "--script", "tools/tests/test_figure_table_fit.gd", "--", "--mobile-ui"], out, true)
	var text := ""
	for chunk in out:
		text += str(chunk)
	for line in text.split("\n"):
		if line.contains("FAIL:") or line.begins_with("checks:") or line.contains("===") or line.contains("tightest") or line.contains("records with"):
			print("  [mobile] " + line.strip_edges())
	return code == 0
