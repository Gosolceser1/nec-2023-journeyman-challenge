extends SceneTree
## Headless exporter: builds the exact speech segments the game would speak
## for every question and writes them as JSON for tools/pregenerate_speech.py.
## Run: Godot --headless --path . --script tools/dump_speech.gd

func _init() -> void:
	var speech_text = load("res://src/speech/speech_text.gd")
	var bank_path := "res://question_bank.json"
	if not FileAccess.file_exists(bank_path):
		push_error("question bank not found: " + bank_path)
		quit(1)
		return
	var raw := FileAccess.get_file_as_string(bank_path)
	var bank = JSON.parse_string(raw)
	if bank == null or not bank is Dictionary or not bank.has("records"):
		push_error("question bank is not the expected shape")
		quit(1)
		return
	var out_dir := OS.get_user_data_dir().path_join("speech_src")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var count := 0
	for record in bank["records"]:
		if not record is Dictionary:
			continue
		var plan: Array = speech_text.speech_plan(record)
		var safe_id := str(record.get("id", "item_%d" % count)).replace("/", "_").replace("\\", "_")
		var file := FileAccess.open(out_dir.path_join(safe_id + ".json"), FileAccess.WRITE)
		if file == null:
			push_error("cannot write speech plan for " + safe_id)
			continue
		file.store_string(JSON.stringify({"id": str(record.get("id", "")), "segments": plan}))
		file.close()
		count += 1
	# The voice picker's preview line, so the recorded voice previews offline.
	var main_script = load("res://src/app/main.gd")
	var preview := FileAccess.open(out_dir.path_join(main_script.PREVIEW_ID + ".json"), FileAccess.WRITE)
	preview.store_string(JSON.stringify({"id": main_script.PREVIEW_ID,
		"segments": [{"text": main_script.PREVIEW_TEXT, "choice": -1, "teach": false}]}))
	preview.close()
	print("SPEECH_SRC_DIR=" + out_dir)
	print("SPEECH_PLANS=" + str(count))
	quit(0)
