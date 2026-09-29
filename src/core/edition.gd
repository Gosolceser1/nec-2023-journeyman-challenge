class_name Edition
extends RefCounted
## The NEC edition the app teaches, from data/edition.json: the one place the
## year is written. UI strings format it in ("{edition}" in data/menu.json).
## Edition-specific data (article titles, ...) lives under data/<dir>/.

const PATH := "res://data/edition.json"

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else null
		_data = parsed if parsed is Dictionary else {}
	return _data


## 2023.
static func year() -> int:
	return int(data().get("year", 0))


## "NEC 2023".
static func short_label() -> String:
	return str(data().get("short", ""))


## "NFPA 70, National Electrical Code, 2023 Edition".
static func long_label() -> String:
	return str(data().get("long", ""))


## res:// path of an edition data file: data_path("articles.json") ->
## "res://data/nec/2023/articles.json".
static func data_path(file_name: String) -> String:
	return "res://data/%s/%s" % [str(data().get("dir", "")), file_name]
