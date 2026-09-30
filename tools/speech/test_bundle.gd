extends SceneTree
## Headless check: every record's live speech plan must resolve to its bundled
## default-voice folder (after `pregenerate_speech.py --bundle` writes them to res://assets/speech).
## Run: Godot --headless --path . --script tools/speech/test_bundle.gd

func _init() -> void:
	var main_script = load("res://src/app/main.gd")
	var holder = main_script.new()
	var speech_text = load("res://src/speech/speech_text.gd")
	var bank = JSON.parse_string(FileAccess.get_file_as_string("res://data/question_bank.json"))
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
	# Show steps: every step of every calculation question's solution.
	var step_speech = load("res://src/speech/math_step_speech.gd")
	var step_hits := 0
	var step_total := 0
	var step_missing: Array = []
	for record in bank["records"]:
		if not record is Dictionary:
			continue
		var sol: Dictionary = MathEngine.exam_solution(record)
		if not sol.get("ok", false):
			continue
		var steps: Array = sol.get("steps", [])
		for i in steps.size():
			var sid: String = step_speech.folder_id(str(record.get("id", "")), i)
			step_total += 1
			if holder._bundled_speech_folder(sid, holder.BUNDLED_VOICE_ID, step_speech.plan(steps[i])) != "":
				step_hits += 1
			elif step_missing.size() < 8:
				step_missing.append(sid)
	print("BUNDLE_STEP_HITS=%d/%d" % [step_hits, step_total])
	if not step_missing.is_empty():
		print("BUNDLE_STEP_MISSING=" + ", ".join(step_missing))
	quit(0 if hits == total and total > 0 and step_hits == step_total and step_total > 0 else 1)
