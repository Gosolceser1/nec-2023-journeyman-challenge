class_name VoiceCatalog
extends RefCounted
## Voice data with no scene state: the desktop cloud catalog in data/voices.json,
## the saved choice in voice.cfg, and how device voices are ranked and labelled.

const VOICE_TIER_HEADINGS := {
	"natural": "MOST NATURAL",
	"general": "ASSISTANT",
	"classic": "CLASSIC NARRATORS",
}
const VOICE_CONFIG_VERSION := 2
const CATALOG_PATH := "res://data/voices.json"
const CONFIG_PATH := "user://voice.cfg"
## The catalog row marked "default": true (en-US-AndrewNeural, Microsoft's
## conversational "Copilot" persona: the most human-sounding US voice on the
## free Edge endpoint). Also the voice of the bundled offline clips.
static var DEFAULT_VOICE_ID: String = str(default_row().get("id", ""))
static var BUNDLED_VOICE_ID: String = DEFAULT_VOICE_ID
## "Andrew · Recorded (offline)".
static var BUNDLED_VOICE_LABEL: String = "%s · Recorded (offline)" % str(default_row().get("label", "")).get_slice(" · ", 0)


## The catalog row marked "default": true, else the first row, else {}.
static func default_row(path: String = CATALOG_PATH) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if not parsed is Array or (parsed as Array).is_empty():
		return {}
	for row in parsed:
		if row is Dictionary and row.get("default", false) == true:
			return row
	return parsed[0] if parsed[0] is Dictionary else {}

## Fills ids (picker label -> voice id) and tiers (label -> "natural" /
## "general" / "classic") from the cloud catalog.
static func load_catalog(ids: Dictionary, tiers: Dictionary, path: String = CATALOG_PATH) -> void:
	ids.clear()
	tiers.clear()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Array:
		for row in parsed:
			if row is Dictionary:
				var label := str(row.get("label", ""))
				ids[label] = str(row.get("id", ""))
				tiers[label] = str(row.get("tier", "classic"))

const EDGE_TAG := "Online (natural)"

## Edge neural ids (en-US-AvaNeural); device voice ids never end this way.
static func is_edge_voice(voice_id: String) -> bool:
	return voice_id.ends_with("Neural")

## The Edge voices the mobile list shows, as [label, id] rows in catalog order:
## en-US only, named "Ava · Female · Online (natural)" from the catalog's name
## and Edge gender. Andrew is left out: the recorded row already is Andrew, and
## reads anything it has no clip for with the online Andrew voice.
static func edge_voice_rows(path: String = CATALOG_PATH) -> Array:
	var rows: Array = []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return rows
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Array:
		return rows
	for row in parsed:
		if not row is Dictionary:
			continue
		var vid := str(row.get("id", ""))
		if vid == BUNDLED_VOICE_ID or not is_edge_voice(vid) or str(row.get("locale", "")) != "en-US":
			continue
		var voice_name := str(row.get("label", "")).get_slice(" · ", 0).strip_edges()
		var gender := str(row.get("gender", "")).strip_edges().capitalize()
		if voice_name == "":
			continue
		var parts := [voice_name] + ([gender] if gender in ["Male", "Female"] else []) + [EDGE_TAG]
		rows.append([" · ".join(parts), vid])
	return rows

## Every en-US voice code in docs/ANDROID_VOICES.md, with its gender confirmed
## by two independent sources: Google Speech Services codes (the "sfg" in
## en-us-x-sfg-local) and Samsung TTS packs ("smtf00" for en-US-SMTf00). The
## numbers are fixed per code so "Female 2" is the same voice on every phone.
## A code not listed here gets a neutral "Voice A" label, never a guess.
const US_VOICE_NAMES := {
	"tpc": "Female 1", "iob": "Female 2", "iog": "Female 3", "tpf": "Female 4", "sfg": "Female 5",
	"iom": "Male 1", "iol": "Male 2", "tpd": "Male 3",
	"smtf00": "Female 1", "smtl03": "Female 2", "smtl04": "Female 3", "smtg02": "Male 1",
}
const SYSTEM_DEFAULT_LABEL := "System default"
const US_TAG := "US English"

static func is_us_voice(info: Dictionary) -> bool:
	var vid := str(info.get("id", "")).strip_edges().to_lower()
	var vlang := str(info.get("language", "")).strip_edges().to_lower().replace("_", "-")
	return vlang == "en-us" or vlang.begins_with("en-us-") or vid.begins_with("en-us-") \
		or vid.begins_with("en_us") or (vlang == "" and vid == "en-us")

## ["tpc", "local"] from "en-us-x-tpc-local" / "en-us-x-sfg#female_2-network";
## gender is "female"/"male" when the name itself carries it (older engines).
static func parse_voice_id(vid: String) -> Dictionary:
	var low := vid.strip_edges().to_lower()
	var out := {"code": "", "network": low.ends_with("-network") or low.contains("network"), "gender": "", "variant": ""}
	var hash := low.find("#")
	if hash >= 0:
		var tail := low.substr(hash + 1)
		for g in ["female", "male"]:
			if tail.begins_with(g):
				out["gender"] = g
				out["variant"] = tail.get_slice("-", 0).trim_prefix(g).trim_prefix("_")
				break
		low = low.substr(0, hash) + ("-" + tail.get_slice("-", 1) if tail.contains("-") else "")
	for suffix in ["-local", "-network", "-embedded"]:
		low = low.trim_suffix(suffix)
	var marker := low.find("-x-")
	var samsung := low.find("-smt")
	if marker >= 0:
		out["code"] = low.substr(marker + 3)
	elif samsung >= 0:
		out["code"] = low.substr(samsung + 1)
	elif low.ends_with("-language") or low.ends_with("_language") or low.ends_with("-default"):
		out["code"] = "language"
	return out

## The device voices the mobile list shows, as [label, id] rows in display
## order: US English only (Android can report hundreds of voices in every
## locale), one entry per voice code with the offline copy preferred, named
## voices (Female 1..5, Male 1..3) then unconfirmed codes, all offline voices
## before online ones, "System default" last. Never empty.
static func device_voice_rows(voices: Array) -> Array:
	var by_key := {}  # one entry per voice, the offline copy preferred
	var default_id := ""
	for info in voices:
		if not info is Dictionary or not is_us_voice(info):
			continue
		var vid := str(info.get("id", "")).strip_edges()
		if vid == "":
			continue
		var parsed := parse_voice_id(vid)
		var code: String = parsed["code"]
		if code == "language":
			default_id = vid
			continue
		if code == "":
			code = vid.to_lower()
		var key: String = code + "#" + parsed["gender"] + parsed["variant"]
		var entry := {"id": vid, "code": code, "network": parsed["network"],
			"gender": parsed["gender"], "variant": parsed["variant"]}
		if not by_key.has(key) or (by_key[key]["network"] and not entry["network"]):
			by_key[key] = entry
	var unknown: Array = []
	var all: Array = []
	for key in by_key:
		var e: Dictionary = by_key[key]
		if e["gender"] != "":
			e["name"] = ("%s %s" % [e["gender"].capitalize(), e["variant"]]).strip_edges()
		elif US_VOICE_NAMES.has(e["code"]):
			e["name"] = US_VOICE_NAMES[e["code"]]
		else:
			unknown.append(e)
		all.append(e)
	unknown.sort_custom(func(a, b): return a["code"] < b["code"])
	for i in unknown.size():
		unknown[i]["name"] = "Voice %s" % char(65 + i % 26)
	for e in all:
		var n := str(e["name"])
		e["rank"] = (1000 if e["network"] else 0) \
			+ (0 if n.begins_with("Female") else (100 if n.begins_with("Male") else 200))
	all.sort_custom(func(a, b):
		if a["rank"] != b["rank"]:
			return a["rank"] < b["rank"]
		return str(a["name"]).naturalnocasecmp_to(str(b["name"])) < 0)
	var rows: Array = []
	for e in all:
		var where := "Online (needs internet)" if e["network"] else "Offline"
		rows.append(["%s · %s · %s" % [e["name"], US_TAG, where], e["id"]])
	rows.append([SYSTEM_DEFAULT_LABEL, default_id])
	return rows

## The id a saved choice maps to among the listed rows: itself when listed, the
## listed copy of the same voice when the other copy was deduplicated away,
## otherwise the recorded voice (also for non-US voices hidden since 1.0.1).
static func migrate_voice_id(saved: String, rows: Array) -> String:
	var ids := rows.map(func(r): return str(r[1]))
	if saved == DEFAULT_VOICE_ID or ids.has(saved):
		return saved
	if not is_us_voice({"id": saved}):
		return DEFAULT_VOICE_ID
	var want := parse_voice_id(saved)
	for id in ids:
		var got := parse_voice_id(id)
		if id != "" and got["code"] == want["code"] and got["gender"] == want["gender"] and got["variant"] == want["variant"]:
			return id
	return DEFAULT_VOICE_ID

## Compact speaker name for the status line ("who is speaking").
static func short_name(label: String) -> String:
	var cut := -1
	for mark in [" (", " [", " · "]:
		var at := label.find(mark)
		if at > 0 and (cut < 0 or at < cut):
			cut = at
	if cut > 0:
		label = label.substr(0, cut)
	label = label.strip_edges()
	if label.length() > 22:
		label = label.substr(0, 22).strip_edges()
	return label

## Saved voice id, or null when there is no readable config. "" is a real id
## (the device's system default voice).
static func load_choice(path: String, mobile_picker: bool) -> Variant:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return null
	var saved := str(config.get_value("speech", "voice", DEFAULT_VOICE_ID))
	# Before version 2 the mobile picker held only device voices, so a saved
	# device voice was never a choice against the recorded one.
	if mobile_picker and int(config.get_value("speech", "version", 1)) < VOICE_CONFIG_VERSION:
		saved = DEFAULT_VOICE_ID
	return saved

static func save_choice(path: String, voice_id: String) -> void:
	var config := ConfigFile.new()
	config.set_value("speech", "voice", voice_id)
	config.set_value("speech", "version", VOICE_CONFIG_VERSION)
	config.save(path)
