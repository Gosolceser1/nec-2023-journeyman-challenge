class_name AppIdentity
extends RefCounted
## The app's name and frozen identifiers, from data/app.json. Names are
## templates filled from the edition ("NEC {year} Journeyman Challenge");
## tools/release/sync_identity.py writes the same values into project.godot
## and export_presets.cfg.

const PATH := "res://data/app.json"

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else null
		_data = parsed if parsed is Dictionary else {}
	return _data


## "{year}" and "{short}" filled from data/edition.json.
static func fill(template: String) -> String:
	return template.replace("{year}", str(Edition.year())).replace("{short}", Edition.short_label())


## "NEC 2023 Journeyman Challenge".
static func display_name() -> String:
	return fill(str(data().get("display_name", "")))


## "NEC2023JourneymanChallenge", the stem of the release file names.
static func file_stem() -> String:
	return fill(str(data().get("file_stem", "")))


## The save folder name. Frozen: it never follows the edition.
static func user_dir() -> String:
	return str(data().get("user_dir", ""))


## The Android application id. Frozen: it never follows the edition.
static func android_package() -> String:
	return str(data().get("android_package", ""))


## Names the project had while saves went to Godot's default folder.
static func legacy_project_names() -> PackedStringArray:
	return PackedStringArray(data().get("legacy_project_names", []))
