extends SceneTree
## Does each record fit its viewport without scrolling, before and after answering?
##   Godot --path . --script tools/visual/measure_fit.gd -- [--mobile-ui] --win=1280x720 --label=before

var main: Node
var label := "run"
var win := Vector2i(540, 960)

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _quiz_scroll() -> ScrollContainer:
	var n: Node = main.answers_box
	while n != null and not n is ScrollContainer:
		n = n.get_parent()
	return n as ScrollContainer

func _overflow(scroll: ScrollContainer) -> float:
	var content := scroll.get_child(0) as Control
	return content.get_combined_minimum_size().y - scroll.size.y

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--label="):
			label = a.trim_prefix("--label=")
		elif a.begins_with("--win="):
			var p := a.trim_prefix("--win=").split("x")
			win = Vector2i(int(p[0]), int(p[1]))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(win)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _frames(10)
	main.audio_cfg_path = "user://measure_audio.cfg"
	main._on_audio_mode_picked(AudioSettings.Mode.SILENT)
	main._start_quiz(10, 1800, true, "10-Question Practice")
	main.timer.stop()
	await _frames(4)
	var scroll := _quiz_scroll()
	var vp := root.get_viewport().get_visible_rect().size
	var n: int = main.records.size()
	var pre_bad := 0
	var post_bad := 0
	var kinds := {"table": [0, 0, 0], "diagram": [0, 0, 0], "formula": [0, 0, 0], "plain": [0, 0, 0]}
	var worst_pre: Array = []
	var worst_post: Array = []
	var post_sum := 0.0
	for i in n:
		var rec: Dictionary = main.records[i]
		main.order = [i, (i + 1) % n] as Array[int]
		main.current_index = 0
		main._show_question()
		main._auto_token += 1
		await _frames(4)
		var pre := _overflow(scroll)
		var ci := int(rec.get("correct_index", 0))
		main._answer_selected((ci + 1) % (rec.get("answers", []) as Array).size())
		main._auto_token += 1
		main._stop_reading()
		await _frames(4)
		var post := _overflow(scroll)
		post_sum += maxf(post, 0.0)
		var kind := "plain"
		if rec.get("reference_table", []) is Array and not (rec.get("reference_table", []) as Array).is_empty():
			kind = "table"
		elif DiagramView.has_figure(rec):
			kind = "diagram"
		elif str(rec.get("formula", "")).strip_edges() != "":
			kind = "formula"
		kinds[kind][0] += 1
		if pre > 0.5:
			pre_bad += 1
			kinds[kind][1] += 1
			worst_pre.append([pre, i])
		if post > 0.5:
			post_bad += 1
			kinds[kind][2] += 1
			worst_post.append([post, i])
	worst_pre.sort_custom(func(a, b): return a[0] > b[0])
	worst_post.sort_custom(func(a, b): return a[0] > b[0])
	var report := "FIT %s  layout=%s  window=%dx%d  logical=%dx%d  records=%d\n" % [label, "mobile" if main.ui_mobile else "desktop", win.x, win.y, int(vp.x), int(vp.y), n]
	report += "  pre-answer needs scroll:  %d  (%.1f%%)\n" % [pre_bad, 100.0 * pre_bad / n]
	report += "  post-answer needs scroll: %d  (%.1f%%)   mean overflow %.0f px\n" % [post_bad, 100.0 * post_bad / n, post_sum / n]
	for k in kinds:
		report += "    %-8s n=%-4d pre=%-4d post=%d\n" % [k, kinds[k][0], kinds[k][1], kinds[k][2]]
	report += "  worst pre:  %s\n" % str(worst_pre.slice(0, 6))
	report += "  worst post: %s\n" % str(worst_post.slice(0, 6))
	print(report)
	var f := FileAccess.open("res://.audit_tmp/fit_%s_%s_%dx%d.txt" % [label, "mob" if main.ui_mobile else "desk", win.x, win.y], FileAccess.WRITE)
	f.store_string(report)
	f.close()
	quit()
