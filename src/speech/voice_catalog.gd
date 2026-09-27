class_name VoiceCatalog
extends RefCounted
## Voice data with no scene state: the desktop cloud catalog in data/voices.json,
## the saved choice in voice.cfg, and how device voices are ranked and labelled.

## Microsoft's conversational "Copilot" persona: the most human-sounding US voice
## on the free Edge endpoint. Also the voice of the bundled offline clips.
const DEFAULT_VOICE_ID := "en-US-AndrewNeural"
const VOICE_TIER_HEADINGS := {
	"natural": "MOST NATURAL",
	"general": "ASSISTANT",
	"classic": "CLASSIC NARRATORS",
}
const BUNDLED_VOICE_ID := DEFAULT_VOICE_ID
const BUNDLED_VOICE_LABEL := "Andrew · Recorded (offline)"
const VOICE_CONFIG_VERSION := 2
const CATALOG_PATH := "res://data/voices.json"
const CONFIG_PATH := "user://voice.cfg"

## Fills ids (picker label -> voice id) and tiers (label -> "natural" /
## "general" / "classic") from the cloud catalog.
static func load_catalog(ids: Dictionary, tiers: Dictionary, path: String = CATALOG_PATH) -> void:
	ids.clear()
	tiers.clear()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		ids["Andrew · Male · Warm"] = DEFAULT_VOICE_ID
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Array:
		for row in parsed:
			if row is Dictionary:
				var label := str(row.get("label", ""))
				ids[label] = str(row.get("id", ""))
				tiers[label] = str(row.get("tier", "classic"))

static func native_tier(info: Dictionary) -> int:
	# 0 = US English (the only tier we list), 1 = other English, 2 = rest.
	var vlang := str(info.get("language", "")).strip_edges().to_lower().replace("_", "-")
	var vname := str(info.get("name", "")).strip_edges().to_lower()
	if vlang.begins_with("en-us"):
		return 0
	if vlang == "" and ("en-us" in vname or "en_us" in vname or "english (united states)" in vname):
		return 0
	if vlang.begins_with("en"):
		return 1
	if vlang == "" and "english" in vname:
		return 1
	return 2

static func pretty_lang(vlang: String, vname: String) -> String:
	# Human-readable language tag so every entry says WHO it is ("Voice 3" tells
	# nothing; "Voice 3 · English (US)" does).
	var t := vlang.strip_edges().replace("_", "-")
	if t == "":
		var ln := vname.to_lower()
		if "en-us" in ln or "en_us" in ln or "united states" in ln:
			return "English (US)"
		return ""
	var low := t.to_lower()
	var names := {"en": "English", "es": "Spanish", "fr": "French", "de": "German",
		"it": "Italian", "pt": "Portuguese", "hi": "Hindi", "ru": "Russian",
		"ar": "Arabic", "zh": "Chinese", "ja": "Japanese", "ko": "Korean",
		"nl": "Dutch", "pl": "Polish", "tr": "Turkish", "uk": "Ukrainian"}
	var parts := low.split("-")
	var base: String = names.get(parts[0], parts[0].to_upper() if parts[0].length() <= 3 else parts[0])
	if parts.size() > 1 and parts[1] != "":
		return "%s (%s)" % [base, parts[1].to_upper()]
	return base

static func display_label(vname: String, vlang: String, vid: String) -> String:
	var label := vname.strip_edges()
	if label == "":
		label = vid
	var tag := pretty_lang(vlang, vname)
	if tag != "" and not label.to_lower().contains(tag.to_lower()):
		label = "%s · %s" % [label, tag]
	return label

## Compact speaker name for the status line ("who is speaking").
static func short_name(label: String) -> String:
	var cut := label.find(" (")
	if cut < 0:
		cut = label.find(" [")
	if cut < 0:
		cut = label.find(" · ")
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
