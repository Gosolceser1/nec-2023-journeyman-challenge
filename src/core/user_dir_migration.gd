class_name UserDirMigration
extends RefCounted
## One-time copy of the settings and study progress from Godot's default user
## folder (%APPDATA%\Godot\app_userdata\<project name>) into the custom one
## (application/config/use_custom_user_dir). The old files are never deleted.

## What the app itself writes to user://; the speech cache is rebuilt on demand.
const FILES: PackedStringArray = ["audio.cfg", "voice.cfg", "question_bag.cfg"]
## Written to the new folder once the check has run, so a later reset of
## progress is not undone by copying the old files again.
const MARKER := "user_dir_migration.cfg"


## Runs the migration for this build. Returns the names of the files copied.
static func run() -> PackedStringArray:
	if not ProjectSettings.get_setting("application/config/use_custom_user_dir", false):
		return PackedStringArray()
	var project_name := str(ProjectSettings.get_setting("application/config/name", ""))
	return migrate(find_legacy_dir(OS.get_data_dir(), project_name), OS.get_user_data_dir())


## Godot's default user folder for this project, or "" if there is none.
## Windows and macOS use "Godot", Linux "godot".
static func find_legacy_dir(data_dir: String, project_name: String) -> String:
	if data_dir.is_empty() or project_name.is_empty():
		return ""
	for vendor in ["Godot", "godot"]:
		var dir := data_dir.path_join(vendor).path_join("app_userdata").path_join(project_name)
		if DirAccess.dir_exists_absolute(dir):
			return dir
	return ""


## Copies FILES from old_dir to new_dir when new_dir has never been checked
## and holds none of them yet. Returns the names copied.
static func migrate(old_dir: String, new_dir: String) -> PackedStringArray:
	var copied := PackedStringArray()
	if new_dir.is_empty() or FileAccess.file_exists(new_dir.path_join(MARKER)):
		return copied
	if DirAccess.make_dir_recursive_absolute(new_dir) != OK:
		return copied
	var fresh := true
	for f in FILES:
		if FileAccess.file_exists(new_dir.path_join(f)):
			fresh = false
	var same_dir := not old_dir.is_empty() and old_dir.simplify_path() == new_dir.simplify_path()
	if fresh and not same_dir and not old_dir.is_empty() and DirAccess.dir_exists_absolute(old_dir):
		for f in FILES:
			var src := old_dir.path_join(f)
			if FileAccess.file_exists(src) and DirAccess.copy_absolute(src, new_dir.path_join(f)) == OK:
				copied.append(f)
	var marker := ConfigFile.new()
	marker.set_value("migration", "from", old_dir)
	marker.set_value("migration", "copied", copied)
	marker.save(new_dir.path_join(MARKER))
	if not copied.is_empty():
		print_verbose("UserDirMigration: copied %s from %s" % [", ".join(copied), old_dir])
	return copied
