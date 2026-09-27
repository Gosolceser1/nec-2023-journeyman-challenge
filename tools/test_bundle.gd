extends SceneTree
## Headless check: every record's live speech plan must resolve to its bundled
## default-voice folder (after tools/fix step copies pregenerated clips to res://speech).
## Run: Godot --headless --path . --script tools/test_bundle.gd

func _init() -> void:
	var main_script = load("res://main.gd")
	var holder = main_script.new()
	var speech_text = load("res://speech_text.gd")
	var bank = JSON.parse_string(FileAccess.get_file_as_string("res://question_bank.json"))
	if bank == null or not bank is Dictionary or not bank.has("records"):
		push_error("question bank unreadable")
		quit(1)
		return
	var hits := 0
	var total := 0
	var missing: Array = []
	for record in bank["records"]:
		if not record is Dictionary:
			continue
		var segs: Array = speech_text.speech_plan(record)
		var qid := str(record.get("id", "")).replace("/", "_").replace("\\", "_")
		var folder: String = holder._bundled_speech_folder(qid, holder.BUNDLED_VOICE_ID, segs)
		total += 1
		if folder != "":
			hits += 1
		elif missing.size() < 8:
			missing.append(str(record.get("id", "?")))
	print("BUNDLE_HITS=%d/%d" % [hits, total])
	if not missing.is_empty():
		print("BUNDLE_MISSING=" + ", ".join(missing))
	quit(0 if hits == total and total > 0 else 1)
