extends SceneTree
## Release builds never start a process for speech: Edge voices stream
## through the built-in EdgeTtsClient on every platform, so a shared Windows
## build works on a PC with no Python. Guards, statically:
##   - no shipped script (src/, scenes/) calls OS.execute, execute_with_pipe,
##     create_process or create_instance;
##   - no shipped script refers to the old Python helper;
##   - no export preset ships a .py file.

const BANNED := ["OS.execute", "execute_with_pipe", "create_process", "create_instance"]
const HELPER := ["SpeechHelper", "speech_helper.gd", "--serve"]

var failures: Array[String] = []
var checks := 0


func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func _initialize() -> void:
	var files: Array[String] = []
	for dir in ["res://src", "res://scenes"]:
		_collect(dir, files)
	check(files.size() > 20, "found the shipped scripts (%d)" % files.size())
	check(files.has("res://src/speech/edge_tts_client.gd"), "the scan covers the Edge client")
	var calls: Array[String] = []
	var helper_refs: Array[String] = []
	for path in files:
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for i in lines.size():
			var code := _code_part(lines[i])
			for word in BANNED:
				if code.contains(word):
					calls.append("%s:%d %s" % [path, i + 1, word])
			for word in HELPER:
				if code.contains(word):
					helper_refs.append("%s:%d %s" % [path, i + 1, word])
	check(calls.is_empty(), "no shipped script starts a process: %s" % str(calls))
	check(helper_refs.is_empty(), "no shipped script uses the Python speech helper: %s" % str(helper_refs))
	check(not FileAccess.file_exists("res://src/speech/speech_helper.gd"), "the Python helper node is gone")

	var presets := ConfigFile.new()
	check(presets.load("res://export_presets.cfg") == OK, "export_presets.cfg loads")
	var seen := 0
	for section in presets.get_sections():
		if not presets.has_section_key(section, "platform"):
			continue
		seen += 1
		var include := str(presets.get_value(section, "include_filter", ""))
		check(not include.contains(".py"), "%s ships no Python (include_filter '%s')" % [presets.get_value(section, "name", section), include])
	check(seen >= 2, "checked every export preset (%d)" % seen)

	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


## The line without its # comment (strings in these scripts never hold '#'
## next to a banned word, so a plain cut is enough).
func _code_part(line: String) -> String:
	var hash := line.find("#")
	return line if hash < 0 else line.substr(0, hash)


func _collect(dir: String, out: Array[String]) -> void:
	for sub in DirAccess.get_directories_at(dir):
		_collect(dir.path_join(sub), out)
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd") or f.ends_with(".tscn"):
			out.append(dir.path_join(f))
