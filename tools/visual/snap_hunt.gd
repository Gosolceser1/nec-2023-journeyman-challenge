extends SceneTree
## Screenshots of chosen questions in the real question screen, before and after
## answering (wrong pick), for the hunt-keyword highlights.
##   Godot --path . --script tools/visual/snap_hunt.gd -- [--mobile-ui] --win=540x960 \
##       --out-dir=<abs dir> --ids=id1,id2 [--tag=before]
## Shots: <out-dir>/<tag>_<desk|mob>_<WxH>_<id>_<pre|post>.png (id with '#' dropped)

var main: Node
var win := Vector2i(1280, 720)
var out_dir := ""
var tag := "shot"
var ids: PackedStringArray = []


func _wait(sec: float) -> void:
	await create_timer(sec).timeout
	await process_frame


func _snap(qid: String, when: String) -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	var path := "%s/%s_%s_%dx%d_%s_%s.png" % [out_dir, tag, "mob" if main.ui_mobile else "desk", win.x, win.y, qid.replace("#", ""), when]
	root.get_viewport().get_texture().get_image().save_png(path)
	print("SNAP=", path)


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--win="):
			var p := a.trim_prefix("--win=").split("x")
			win = Vector2i(int(p[0]), int(p[1]))
		elif a.begins_with("--out-dir="):
			out_dir = a.trim_prefix("--out-dir=")
		elif a.begins_with("--ids="):
			ids = a.trim_prefix("--ids=").split(",", false)
		elif a.begins_with("--tag="):
			tag = a.trim_prefix("--tag=")
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(win)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 10:
		await process_frame
	main.audio_cfg_path = "user://snap_hunt_audio.cfg"
	main.session.bag_path = ""
	main._on_audio_mode_picked(AudioSettings.Mode.SILENT)
	main._start_quiz(10, 1800, true, "10-Question Practice")
	main.timer.stop()
	while main._start_tween != null and main._start_tween.is_running():
		await process_frame
	var n: int = main.records.size()
	for qid in ids:
		var i := -1
		for j in n:
			if str(main.records[j].get("id", "")) == qid:
				i = j
				break
		if i < 0:
			push_error("snap_hunt: unknown id " + qid)
			continue
		main.order = [i, (i + 1) % n] as Array[int]
		main.current_index = 0
		main._show_question()
		main._auto_token += 1
		await _wait(0.9)
		_snap(qid, "pre")
		var rec: Dictionary = main.session.display_record(i)
		main._answer_selected((int(rec.get("correct_index", 0)) + 1) % (rec.get("answers", []) as Array).size())
		main._auto_token += 1
		main._stop_reading()
		await _wait(1.0)
		_snap(qid, "post")
	quit()
