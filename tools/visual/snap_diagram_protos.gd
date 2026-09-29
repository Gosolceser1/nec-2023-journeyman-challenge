extends SceneTree
## Screenshots of the prototype study figures (tools/diagrams/protos.py) in the
## real question screen: masked before answering, the zoom view before
## answering, and revealed after. Nothing is wired into the bank: the PNG and
## its masks (docs/diagrams_proto/masks.json) are pushed into the DiagramView.
##   Godot --path . --script tools/visual/snap_diagram_protos.gd -- [--mobile-ui] --win=540x960 \
##       --png-dir=<abs dir with <name>.png> --out-dir=<abs dir>
## Shots: <out-dir>/<desk|mob>_<WxH>_<name>_<pre|zoom|post>.png

const MASKS := "res://docs/diagrams_proto/masks.json"

var main: Node
var win := Vector2i(1280, 720)
var png_dir := ""
var out_dir := ""


func _wait(sec: float) -> void:
	await create_timer(sec).timeout
	await process_frame


func _snap(tag: String) -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	var path := "%s/%s_%dx%d_%s.png" % [out_dir, "mob" if main.ui_mobile else "desk", win.x, win.y, tag]
	root.get_viewport().get_texture().get_image().save_png(path)
	print("SNAP=", path)


func _show_figure(file: String, masks: Array) -> void:
	var view: DiagramView = main.question_diagram_view
	var img := Image.load_from_file(file)
	img.generate_mipmaps()
	view.figure = {}
	view.ascii_lines = PackedStringArray()
	view.texture = ImageTexture.create_from_image(img)
	view.masks = masks.duplicate(true)
	view.answered = false
	view.revealed = false
	view._set_mask_alpha(1.0)
	main.question_diagram_panel.visible = true
	main.question_diagram_panel.add_theme_stylebox_override("panel",
			AppTheme.surface(AppTheme.SLATE_900, AppTheme.SKY_400, AppTheme.ELEVATION_REST, AppTheme.RADIUS_INNER))
	view._update_height()
	view.queue_redraw()


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--win="):
			var p := a.trim_prefix("--win=").split("x")
			win = Vector2i(int(p[0]), int(p[1]))
		elif a.begins_with("--png-dir="):
			png_dir = a.trim_prefix("--png-dir=")
		elif a.begins_with("--out-dir="):
			out_dir = a.trim_prefix("--out-dir=")
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(win)
	var protos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MASKS))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 10:
		await process_frame
	main.audio_cfg_path = "user://snap_protos_audio.cfg"
	main.session.bag_path = ""
	main._on_audio_mode_picked(AudioSettings.Mode.SILENT)
	main._start_quiz(10, 1800, true, "10-Question Practice")
	main.timer.stop()
	while main._start_tween != null and main._start_tween.is_running():
		await process_frame
	var n: int = main.records.size()
	for file in protos:
		var name: String = file.get_basename()
		var qid: String = protos[file]["records"][0]
		var i := -1
		for k in n:
			if str(main.records[k].get("id", "")) == qid:
				i = k
		if i < 0:
			print("no record ", qid)
			continue
		main.order = [i, (i + 1) % n] as Array[int]
		main.current_index = 0
		main._show_question()
		main._auto_token += 1
		_show_figure("%s/%s" % [png_dir, file], protos[file]["masks"])
		main.fit.refresh_ref_column()
		await _wait(0.2)
		main.question_diagram_view._update_height()
		main.fit.begin()
		await _wait(1.2)
		_snap(name + "_pre")
		main.question_diagram_view.open_zoom()
		await _wait(0.4)
		_snap(name + "_zoom")
		main.question_diagram_view.close_zoom()
		await _wait(0.1)
		var rec: Dictionary = main.session.display_record(i)
		main._answer_selected((int(rec.get("correct_index", 0)) + 1) % (rec.get("answers", []) as Array).size())
		main._auto_token += 1
		main._stop_reading()
		await _wait(1.2)
		_snap(name + "_post")
	quit()
