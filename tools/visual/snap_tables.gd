extends SceneTree
## Screenshots of chosen questions before and after answering (a wrong pick),
## for checking reference tables by eye.
##   Godot --path . --script tools/visual/snap_tables.gd -- [--mobile-ui] --win=540x960 \
##       --ids=final-exam-#1-004,open-book-exam-#7-014 [--out=table_noscroll]
## Shots land in .audit_tmp/shots/<out>/<desk|mob>_<WxH>_<id>_<pre|post>.png.

var main: Node
var win := Vector2i(1280, 720)
var ids: PackedStringArray = []
var out_dir := "table_noscroll"


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _wait(sec: float) -> void:
	await create_timer(sec).timeout
	await process_frame


func _snap(tag: String) -> void:
	var dir := "res://.audit_tmp/shots/%s" % out_dir
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var path := ProjectSettings.globalize_path("%s/%s_%dx%d_%s.png" % [dir, "mob" if main.ui_mobile else "desk", win.x, win.y, tag.replace("#", "")])
	root.get_viewport().get_texture().get_image().save_png(path)
	print("SNAP=", path)


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--win="):
			var p := a.trim_prefix("--win=").split("x")
			win = Vector2i(int(p[0]), int(p[1]))
		elif a.begins_with("--ids="):
			ids = a.trim_prefix("--ids=").split(",", false)
		elif a.begins_with("--out="):
			out_dir = a.trim_prefix("--out=")
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(win)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _frames(10)
	main.audio_cfg_path = "user://snap_tables_audio.cfg"
	main.session.bag_path = ""
	main._on_audio_mode_picked(AudioSettings.Mode.SILENT)
	main._start_quiz(10, 1800, true, "10-Question Practice")
	main.timer.stop()
	while main._start_tween != null and main._start_tween.is_running():
		await process_frame
	var n: int = main.records.size()
	for qid in ids:
		var i := -1
		for k in n:
			if str(main.records[k].get("id", "")) == qid:
				i = k
				break
		if i < 0:
			print("no record ", qid)
			continue
		main.order = [i, (i + 1) % n] as Array[int]
		main.current_index = 0
		main._show_question()
		main._auto_token += 1
		await _wait(1.2)
		if main.question_table_panel.visible:
			print("%s table: %d block(s), text level %d" % [qid, TableViewer.block_count(main.question_table_grid), TableViewer.text_level(main.question_table_grid)])
		_snap(qid + "_pre")
		var rec: Dictionary = main.session.display_record(i)
		main._answer_selected((int(rec.get("correct_index", 0)) + 1) % (rec.get("answers", []) as Array).size())
		main._auto_token += 1
		main._stop_reading()
		await _wait(1.2)
		_snap(qid + "_post")
	quit()
