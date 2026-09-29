extends SceneTree
## UserDirMigration: the one-time copy from %APPDATA%\Godot\app_userdata\<name>
## into the custom user folder. Every case runs in throwaway folders under the
## OS temp dir; the real user folders are never read or written.

var failures: Array[String] = []
var checks := 0
var tmp_root := ""


func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func _init() -> void:
	print("=== user dir migration ===")
	tmp_root = OS.get_temp_dir().path_join("nec_migration_test_%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(tmp_root)

	_settings()
	_copies_known_files()
	_runs_once()
	_new_folder_in_use()
	_no_old_folder()
	_partial_old_folder()
	_same_folder()
	_find_legacy_dir()
	_legacy_names()

	_remove_tree(tmp_root)
	check(not DirAccess.dir_exists_absolute(tmp_root), "temp folders cleaned up")
	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	for f in failures:
		print("  - %s" % f)
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)


func _settings() -> void:
	check(ProjectSettings.get_setting("application/config/use_custom_user_dir") == true,
		"use_custom_user_dir is on")
	var frozen := AppIdentity.user_dir()
	check(frozen != "" and ProjectSettings.get_setting("application/config/custom_user_dir_name") == frozen,
		"custom user folder is data/app.json's frozen user_dir (%s)" % frozen)
	var user_dir := OS.get_user_data_dir()
	check(user_dir.ends_with(frozen) and not user_dir.contains("app_userdata"),
		"user:// resolves to the custom folder (got %s)" % user_dir)
	check(UserDirMigration.FILES == PackedStringArray(["audio.cfg", "voice.cfg", "question_bag.cfg"]),
		"migrates the settings and the study progress")
	check(UserDirMigration.FILES.has(QuizSession.BAG_PATH.get_file())
			and UserDirMigration.FILES.has(AudioSettings.PATH.get_file())
			and UserDirMigration.FILES.has(VoiceCatalog.CONFIG_PATH.get_file()),
		"FILES matches the paths the app writes")


func _copies_known_files() -> void:
	var old := _case_dir("copy/old")
	var new := tmp_root.path_join("copy/new")
	_write(old, "audio.cfg", "[audio]\nmode=2\n")
	_write(old, "voice.cfg", "[voice]\nid=\"x\"\n")
	_write(old, "question_bag.cfg", "[deck]\nseen=42\n")
	_write(old, "snap_audio.cfg", "tool leftover")
	var copied := UserDirMigration.migrate(old, new)
	check(copied == PackedStringArray(["audio.cfg", "voice.cfg", "question_bag.cfg"]),
		"copies the three files (got %s)" % str(copied))
	check(_read(new, "question_bag.cfg") == "[deck]\nseen=42\n", "progress copied byte for byte")
	check(_read(new, "audio.cfg") == "[audio]\nmode=2\n", "audio settings copied")
	check(not FileAccess.file_exists(new.path_join("snap_audio.cfg")), "tool leftovers are not copied")
	for f in ["audio.cfg", "voice.cfg", "question_bag.cfg", "snap_audio.cfg"]:
		check(FileAccess.file_exists(old.path_join(f)), "old %s is kept" % f)
	check(FileAccess.file_exists(new.path_join(UserDirMigration.MARKER)), "marker written")


func _runs_once() -> void:
	var old := tmp_root.path_join("copy/old")
	var new := tmp_root.path_join("copy/new")
	# The user resets progress; the next launch must not bring it back.
	DirAccess.remove_absolute(new.path_join("question_bag.cfg"))
	_write(old, "question_bag.cfg", "[deck]\nseen=99\n")
	check(UserDirMigration.migrate(old, new).is_empty(), "second run copies nothing")
	check(not FileAccess.file_exists(new.path_join("question_bag.cfg")), "a reset stays reset")


func _new_folder_in_use() -> void:
	var old := _case_dir("inuse/old")
	var new := _case_dir("inuse/new")
	_write(old, "question_bag.cfg", "old progress")
	_write(old, "audio.cfg", "old audio")
	_write(new, "question_bag.cfg", "new progress")
	check(UserDirMigration.migrate(old, new).is_empty(), "a folder already in use gets nothing")
	check(_read(new, "question_bag.cfg") == "new progress", "newer progress is never overwritten")
	check(not FileAccess.file_exists(new.path_join("audio.cfg")), "no mixing of old and new files")
	check(FileAccess.file_exists(new.path_join(UserDirMigration.MARKER)), "marker written when skipped")


func _no_old_folder() -> void:
	var new := tmp_root.path_join("fresh/new")
	check(UserDirMigration.migrate(tmp_root.path_join("fresh/missing"), new).is_empty(), "no old folder: nothing copied")
	check(UserDirMigration.migrate("", tmp_root.path_join("fresh/new2")).is_empty(), "empty old path: nothing copied")
	check(FileAccess.file_exists(new.path_join(UserDirMigration.MARKER)), "new folder created with its marker")


func _partial_old_folder() -> void:
	var old := _case_dir("partial/old")
	var new := tmp_root.path_join("partial/new")
	_write(old, "question_bag.cfg", "only progress")
	check(UserDirMigration.migrate(old, new) == PackedStringArray(["question_bag.cfg"]),
		"copies whatever of the three exists")


func _same_folder() -> void:
	var dir := _case_dir("same")
	_write(dir, "audio.cfg", "keep")
	check(UserDirMigration.migrate(dir, dir + "/").is_empty(), "same folder: nothing copied")
	check(_read(dir, "audio.cfg") == "keep", "same folder: file untouched")


func _find_legacy_dir() -> void:
	var data := _case_dir("appdata")
	var name := AppIdentity.legacy_project_names()[0]
	check(UserDirMigration.find_legacy_dir(data, name) == "", "no legacy folder: empty path")
	var legacy := data.path_join("Godot/app_userdata").path_join(name)
	DirAccess.make_dir_recursive_absolute(legacy)
	var found := UserDirMigration.find_legacy_dir(data, name)
	check(found.to_lower() == legacy.to_lower(), "finds Godot/app_userdata/<name> (got %s)" % found)
	check(UserDirMigration.find_legacy_dir(data, "") == "", "no project name: empty path")
	check(UserDirMigration.find_legacy_dir("", name) == "", "no data dir: empty path")
	# The whole path as main.gd runs it, against a fake APPDATA layout.
	_write(legacy, "question_bag.cfg", "legacy progress")
	var new := data.path_join(AppIdentity.user_dir())
	check(UserDirMigration.migrate(found, new) == PackedStringArray(["question_bag.cfg"]),
		"fake APPDATA: legacy progress lands in the new folder")
	check(_read(legacy, "question_bag.cfg") == "legacy progress", "fake APPDATA: legacy file kept")


## The pre-1.0 folder is found by the legacy names, not by config/name, so an
## app renamed for a new edition still migrates the old progress.
func _legacy_names() -> void:
	var names := AppIdentity.legacy_project_names()
	check(names.has("NEC 2023 Journeyman Challenge"), "legacy names hold the pre-1.0 project name (%s)" % str(names))
	var data := _case_dir("renamed")
	var legacy := data.path_join("Godot/app_userdata").path_join(names[0])
	DirAccess.make_dir_recursive_absolute(legacy)
	_write(legacy, "question_bag.cfg", "pre-1.0 progress")
	check(UserDirMigration.find_legacy_dir(data, "NEC 2032 Journeyman Challenge") == "", "a renamed app has no default folder of its own")
	var found := UserDirMigration.find_first_legacy_dir(data, PackedStringArray(["NEC 2032 Journeyman Challenge"]) + names)
	check(found.to_lower() == legacy.to_lower(), "the first legacy name with a folder wins (got %s)" % found)
	check(UserDirMigration.find_first_legacy_dir(data, PackedStringArray()) == "", "no names: empty path")
	var new := data.path_join(AppIdentity.user_dir())
	check(UserDirMigration.migrate(found, new) == PackedStringArray(["question_bag.cfg"]), "renamed app: pre-1.0 progress still lands in the frozen folder")


func _case_dir(rel: String) -> String:
	var dir := tmp_root.path_join(rel)
	DirAccess.make_dir_recursive_absolute(dir)
	return dir


func _write(dir: String, file: String, text: String) -> void:
	var f := FileAccess.open(dir.path_join(file), FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _read(dir: String, file: String) -> String:
	return FileAccess.get_file_as_string(dir.path_join(file))


func _remove_tree(dir: String) -> void:
	for sub in DirAccess.get_directories_at(dir):
		_remove_tree(dir.path_join(sub))
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	DirAccess.remove_absolute(dir)
