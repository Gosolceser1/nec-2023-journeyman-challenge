extends SceneTree
## project.godot parser guard.
##
## WHY THIS EXISTS: project.godot is parsed by ConfigFile, whose ONLY comment
## character is ";" (not "#"). A block of "#" comments above
## pointing/emulate_mouse_from_touch was glued onto that setting's NAME,
## producing a junk key and leaving the setting at Godot's default of TRUE.
## The app's whole touch model depends on it being false: answer_card.gd's
## mouse-branch release handler has no drag-slop check, so a tap that was
## meant to scroll the page instead selected the answer card. Nothing in the
## build failed - the file parsed fine and simply meant something else.
##
## This asserts (a) the settings the app depends on have their intended values
## and (b) no key looks like it swallowed a comment.

var failures: Array[String] = []
var checks := 0

func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func _init() -> void:
	print("=== project.godot EFFECTIVE SETTINGS ===")

	# The two the touch model depends on.
	check(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch") == false,
		"emulate_mouse_from_touch must be false: with it true, answer_card.gd's mouse "
		+ "branch (no drag-slop check) selects a card when the user only meant to scroll")
	check(ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse") == false,
		"emulate_touch_from_mouse must be false")

	# Structural settings the layout depends on.
	check(ProjectSettings.get_setting("display/window/stretch/mode") == "canvas_items",
		"stretch mode must be canvas_items")
	check(ProjectSettings.get_setting("display/window/stretch/aspect") == "expand",
		"stretch aspect must be expand")
	check(ProjectSettings.get_setting("application/config/quit_on_go_back") == false,
		"quit_on_go_back must be false: main.gd handles Back itself via _on_go_back()")
	check(ProjectSettings.get_setting("audio/general/text_to_speech") == true,
		"audio/general/text_to_speech must be true: the Read button is silently dead without it")

	# Branding: with show_image on and no image, Godot draws its own logo.
	var icon := str(ProjectSettings.get_setting("application/config/icon"))
	check(icon.begins_with("res://assets/branding/") and ResourceLoader.exists(icon),
		"application/config/icon must be the app icon (got '%s')" % icon)
	var ico := str(ProjectSettings.get_setting("application/config/windows_native_icon"))
	check(ico.ends_with(".ico") and FileAccess.file_exists(ico), "windows_native_icon must be an existing .ico")
	var splash := str(ProjectSettings.get_setting("application/boot_splash/image"))
	check(ProjectSettings.get_setting("application/boot_splash/show_image") == false
			or (splash != "" and ResourceLoader.exists(splash)),
		"boot splash must show the app's image or none, never Godot's default logo")
	check(not FileAccess.file_exists("res://icon.svg"), "Godot's default icon.svg must not be in the project")
	var version := str(ProjectSettings.get_setting("application/config/version"))
	check(RegEx.create_from_string("^\\d+\\.\\d+\\.\\d+$").search(version) != null, "config/version is x.y.z (%s)" % version)

	# Name and identifiers: data/app.json + data/edition.json (sync_identity.py
	# writes them; the save folder and Android package id are frozen).
	check(str(ProjectSettings.get_setting("application/config/name")) == AppIdentity.display_name(),
		"config/name is data/app.json's display_name (%s)" % AppIdentity.display_name())
	check(str(ProjectSettings.get_setting("application/config/description")) == AppIdentity.fill(str(AppIdentity.data().get("description", ""))),
		"config/description is data/app.json's description")
	check(str(ProjectSettings.get_setting("application/config/custom_user_dir_name")) == AppIdentity.user_dir(),
		"custom_user_dir_name is the frozen user_dir (%s)" % AppIdentity.user_dir())

	# Export presets: the Edge voices need the network on Android, and every
	# build carries the same version and name.
	var presets := ConfigFile.new()
	check(presets.load("res://export_presets.cfg") == OK, "export_presets.cfg parses")
	var androids := 0
	var macs := 0
	var android_code := -1
	var windows_exclude := ""
	var mac_exclude := ""
	for sec in presets.get_sections():
		if sec.ends_with(".options") or not presets.has_section(sec + ".options"):
			continue
		var opts := sec + ".options"
		var platform := str(presets.get_value(sec, "platform", ""))
		if platform == "Android":
			androids += 1
			check(presets.get_value(opts, "permissions/internet", false) == true,
				"%s asks for INTERNET (the Edge voices stream over the network)" % presets.get_value(sec, "name"))
			check(str(presets.get_value(opts, "version/name", "")) == version, "%s version/name is %s" % [presets.get_value(sec, "name"), version])
			check(str(presets.get_value(opts, "package/unique_name", "")) == AppIdentity.android_package(),
				"%s package id is the frozen android_package" % presets.get_value(sec, "name"))
			check(str(presets.get_value(opts, "package/name", "")) == AppIdentity.display_name(), "%s app name" % presets.get_value(sec, "name"))
			android_code = int(presets.get_value(opts, "version/code", -1))
		elif platform == "macOS":
			macs += 1
			mac_exclude = str(presets.get_value(sec, "exclude_filter", ""))
			check(str(presets.get_value(opts, "application/short_version", "")) == version, "macOS short_version is %s" % version)
			check(str(presets.get_value(opts, "application/bundle_identifier", "")) == AppIdentity.macos_bundle_id(),
				"macOS bundle id is the frozen macos_bundle_id")
			check(str(presets.get_value(opts, "binary_format/architecture", "")) == "universal", "macOS build is universal (Apple Silicon + Intel)")
			check(int(presets.get_value(opts, "codesign/codesign", 0)) == 1, "macOS is ad-hoc signed (built-in): Apple Silicon runs nothing unsigned")
			check(bool(presets.get_value(opts, "display/high_res", false)), "macOS renders at Retina resolution")
			var mac_icon := str(presets.get_value(opts, "application/icon", ""))
			check(mac_icon.ends_with("icon_1024.png") and FileAccess.file_exists(mac_icon), "macOS icon is the 1024 px branding render (%s)" % mac_icon)
			check(str(presets.get_value(sec, "export_path", "")).get_file() == "%s_v%s_macOS.zip" % [AppIdentity.file_stem(), version],
				"macOS exports a .zip (a bare .app from Windows loses the executable bit)")
		elif platform == "Windows Desktop":
			windows_exclude = str(presets.get_value(sec, "exclude_filter", ""))
			check(str(presets.get_value(opts, "application/file_version", "")) == version
				and str(presets.get_value(opts, "application/product_version", "")) == version, "Windows file/product version is %s" % version)
			check(str(presets.get_value(opts, "application/product_name", "")) == AppIdentity.display_name(), "Windows product name")
			check(str(presets.get_value(sec, "export_path", "")).get_file() == AppIdentity.display_name() + ".exe", "Windows exe is named after the app")
	check(androids == 2, "both Android presets checked (%d)" % androids)
	check(macs == 1, "the macOS preset checked (%d)" % macs)
	check(mac_exclude != "" and mac_exclude == windows_exclude, "macOS packs exactly what Windows packs (same exclude_filter)")
	for sec in presets.get_sections():
		if str(presets.get_value(sec, "platform", "")) == "macOS":
			check(str(presets.get_value(sec + ".options", "application/version", "")) == str(android_code),
				"macOS build number is the Android version/code (%d)" % android_code)

	# No setting name may contain a comment character or a space: that is the
	# signature of a "#" comment line fused onto the next key.
	var junk: Array[String] = []
	for p in ProjectSettings.get_property_list():
		var n := str(p.get("name", ""))
		if n == "" or n.begins_with("_"):
			continue
		if n.contains("#") or n.contains(";") or n.contains(" ") or n.contains("\"") \
				or n.contains("(") or n.contains("."):
			# Dotted names are legitimate (section/key); anything else is a fused comment.
			if not _is_legit_dotted(n):
				junk.append(n)
	check(junk.is_empty(), "settings with fused comment text in their name: %s" % str(junk))

	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	for f in failures:
		print("  - %s" % f)
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)


func _is_legit_dotted(n: String) -> bool:
	# Godot setting names are section/key with at most one dot.
	var parts := n.split(".")
	return parts.size() == 2
