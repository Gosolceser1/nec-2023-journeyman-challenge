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
