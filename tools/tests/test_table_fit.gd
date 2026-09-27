extends SceneTree
## Reference tables never scroll: every table question, before answering (the
## lookup table) and after (the feedback table), shows its whole table with no
## scrollbar of its own and nothing left to scroll either way.
##
##   Godot --headless --path . --script tools/tests/test_table_fit.gd [-- --mobile-ui]
##
## Without --mobile-ui the suite also runs itself once with it. The page-level
## 0% scroll at real window sizes is tools/visual/measure_fit.gd's job.

const R = preload("res://tools/tests/t_report.gd")
const TOL := 0.5

var t: R = R.new()
var main: Node
var mobile := false


func _initialize() -> void:
	mobile = "--mobile-ui" in OS.get_cmdline_user_args()
	print("=== reference tables (%s) ===" % ("mobile" if mobile else "desktop"))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _frames(6)
	main.audio_cfg_path = "user://test_table_fit_audio.cfg"
	main.session.bag_path = ""
	main._on_audio_mode_picked(AudioSettings.Mode.SILENT)
	main._start_quiz(10, 1800, true, "Practice Test")
	main.timer.stop()
	while main._start_tween != null and main._start_tween.is_running():
		await process_frame
	await _frames(2)
	for s in [main.question_table_scroll, main.feedback_table_scroll]:
		var box := s as ScrollContainer
		t.eq(box.vertical_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED, "%s: vertical scrolling is off" % box.name)
		t.eq(box.horizontal_scroll_mode, ScrollContainer.SCROLL_MODE_SHOW_NEVER, "%s: no horizontal scrollbar" % box.name)
	await _sweep()
	var child_ok := true
	if not mobile:
		child_ok = _run_mobile_child()
	t.report()
	quit(0 if t.failures.is_empty() and child_ok else 1)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _check_whole(box: ScrollContainer, what: String) -> void:
	t.check(box.is_visible_in_tree(), "%s: table on screen" % what)
	var grid := box.get_child(0) as GridContainer
	var need := grid.get_combined_minimum_size()
	t.check(not box.get_v_scroll_bar().visible and not box.get_h_scroll_bar().visible, "%s: no scrollbar shown" % what)
	t.check(need.y <= box.size.y + TOL, "%s: whole height shown (%.0f of %.0f px)" % [what, need.y, box.size.y])
	t.check(need.x <= box.size.x + TOL, "%s: whole width shown (%.0f of %.0f px)" % [what, need.x, box.size.x])
	t.check(grid.size.x <= box.size.x + TOL, "%s: columns fit the box (%.0f of %.0f px)" % [what, grid.size.x, box.size.x])


func _sweep() -> void:
	var n: int = main.records.size()
	var pre := 0
	var post := 0
	for i in n:
		var rec: Dictionary = main.records[i]
		var table = rec.get("reference_table", [])
		if not table is Array or (table as Array).is_empty():
			continue
		var qid := str(rec.get("id", i))
		main.order = [i, (i + 1) % n] as Array[int]
		main.current_index = 0
		main._show_question()
		main._auto_token += 1
		# The table fit steps once per frame.
		await _frames(12)
		if not bool(rec.get("table_after_answer", false)):
			_check_whole(main.question_table_scroll, "%s before answering" % qid)
			pre += 1
		main._answer_selected(int(rec.get("correct_index", 0)))
		main._auto_token += 1
		main._stop_reading()
		await _frames(4)
		_check_whole(main.feedback_table_scroll, "%s after answering" % qid)
		post += 1
	t.check(pre > 0 and post > 0, "the sweep met tables before and after answering")
	print("  %d lookup tables, %d feedback tables" % [pre, post])


func _run_mobile_child() -> bool:
	var out: Array = []
	var code := OS.execute(OS.get_executable_path(),
			["--headless", "--path", ".", "--script", "tools/tests/test_table_fit.gd", "--", "--mobile-ui"], out, true)
	var text := ""
	for chunk in out:
		text += str(chunk)
	for line in text.split("\n"):
		if line.contains("FAIL:") or line.begins_with("checks:") or line.contains("==="):
			print("  [mobile] " + line.strip_edges())
	return code == 0
