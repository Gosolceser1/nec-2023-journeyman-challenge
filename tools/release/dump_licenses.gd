extends SceneTree
## Writes the engine's own license notices (Godot is MIT and bundles MIT/BSD/
## zlib/... components, whose notices must travel with the binary).
##   Godot --headless --path . --script tools/release/dump_licenses.gd -- <out.txt>


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		push_error("usage: -- <out.txt>")
		quit(2)
		return
	var lines := PackedStringArray()
	lines.append("THIRD-PARTY SOFTWARE LICENSES")
	lines.append("=============================")
	lines.append("")
	lines.append("%s is built with the Godot Engine" % AppIdentity.display_name())
	lines.append("(https://godotengine.org), used under the MIT license below, together")
	lines.append("with the third-party components the engine includes.")
	lines.append("")
	lines.append("-------------------------------------------------------------------------")
	lines.append("Godot Engine")
	lines.append("-------------------------------------------------------------------------")
	lines.append(Engine.get_license_text())
	lines.append("")
	lines.append("-------------------------------------------------------------------------")
	lines.append("Components included in the engine")
	lines.append("-------------------------------------------------------------------------")
	for component in Engine.get_copyright_info():
		lines.append("")
		lines.append(str(component["name"]))
		for part in component["parts"]:
			for holder in part["copyright"]:
				lines.append("  Copyright " + str(holder))
			lines.append("  License: " + str(part["license"]))
	var info := Engine.get_license_info()
	var names := info.keys()
	names.sort()
	for license_name in names:
		lines.append("")
		lines.append("-------------------------------------------------------------------------")
		lines.append("License: " + str(license_name))
		lines.append("-------------------------------------------------------------------------")
		lines.append(str(info[license_name]))
	var f := FileAccess.open(args[0], FileAccess.WRITE)
	if f == null:
		push_error("cannot write " + args[0])
		quit(1)
		return
	f.store_string("\r\n".join("\n".join(lines).split("\n")) + "\r\n")
	f.close()
	quit(0)
