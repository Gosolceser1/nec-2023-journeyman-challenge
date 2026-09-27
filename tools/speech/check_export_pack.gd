extends SceneTree
## Runs against an exported pack, not the project: the bank, every bundled
## speech clip and the sound effects must load from inside the .pck, and the
## desktop speech helper script must be copied out to a real file for Python.
## tools/ is excluded from exports, so pass this script by absolute path:
##
##   cd build
##   ..\Godot_v4.7.2-stable_win64_console.exe --headless --main-pack NEC2023JourneymanChallenge.pck \
##       --script "<repo>/tools/speech/check_export_pack.gd"

var failures: Array[String] = []

func check(cond: bool, label: String) -> void:
	if not cond:
		failures.append(label)
		print("  FAIL: ", label)

func _init() -> void:
	check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://tools")),
		"running from the project folder, not a pack (use --main-pack)")
	var bank = JSON.parse_string(FileAccess.get_file_as_string("res://data/question_bank.json"))
	var records: Array = bank.get("records", []) if bank is Dictionary else []
	check(records.size() == 283, "bank loads from the pack: %d records" % records.size())
	var voices = JSON.parse_string(FileAccess.get_file_as_string("res://data/voices.json"))
	check(voices is Array and not (voices as Array).is_empty(), "voice catalog loads from the pack")

	var host = load("res://src/app/main.gd").new()
	var speech_text = load("res://src/speech/speech_text.gd")
	var folders := 0
	var clips := 0
	var bad_clips := 0
	for rec in records:
		var qid := str(rec.get("id", "")).replace("/", "_").replace("\\", "_")
		var folder: String = host._bundled_speech_folder(qid, host.BUNDLED_VOICE_ID, speech_text.speech_plan(rec))
		if folder == "":
			continue
		folders += 1
		for i in speech_text.speech_plan(rec).size():
			var clip = host._load_clip(folder.path_join("%d.mp3" % i))
			if clip is AudioStream and clip.get_length() > 0.2:
				clips += 1
			else:
				bad_clips += 1
	host.free()
	print("PACK_BUNDLE_FOLDERS=%d/%d  CLIPS_LOADED=%d  CLIPS_FAILED=%d" % [folders, records.size(), clips, bad_clips])
	check(folders == records.size(), "every record has its bundled clip folder in the pack")
	check(bad_clips == 0 and clips > 0, "every bundled clip loads as an imported AudioStream")

	for cue in ["correct", "wrong", "pass", "fail", "warning"]:
		check(load("res://assets/sfx/%s.wav" % cue) is AudioStream, "sfx %s loads from the pack" % cue)

	var script := SpeechHelper.resolve_script()
	print("SPEECH_HELPER_SCRIPT=", script)
	check(script.is_absolute_path() and FileAccess.file_exists(script),
		"speech helper script copied out of the pack to a real file: '%s'" % script)
	check(FileAccess.get_file_as_string(script) == FileAccess.get_file_as_string(SpeechHelper.SCRIPT_RES),
		"copied helper script matches the packed one")

	print("PACK CHECK: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
