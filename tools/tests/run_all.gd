extends SceneTree
## Combined runner for the pure-logic test suites.
##
##   ./Godot_v4.7.2-stable_win64_console.exe --headless --path . \
##       --script tools/tests/run_all.gd
##
## Exit code 0 = every suite passed. Non-zero = the number of failing SUITES.
##
## Each suite `extends SceneTree` (so it can be run standalone with --script),
## which means it cannot be instantiated in-process. So this runner invokes
## each one as a child Godot process and reads its exit code. Slower than an
## in-process runner, but correct: no shared state, no way for one suite's
## failure to abort the rest, and it exercises the same path a developer runs
## by hand.

const SUITES := [
	{"name": "no-leak (product guarantee)", "path": "res://tools/tests/test_no_leak.gd"},
	{"name": "audio_explanation_generator", "path": "res://tools/tests/test_audio_explanation_generator.gd"},
	{"name": "speech_text", "path": "res://tools/tests/test_speech_text.gd"},
	{"name": "unit_matcher", "path": "res://tools/tests/test_unit_matcher.gd"},
	{"name": "table_viewer (pure)", "path": "res://tools/tests/test_table_viewer.gd"},
	# Layout regression guard. The scene harness asserts quiz LOGIC and never
	# inspects a margin, so a broken safe-area calculation shipped green and left
	# the app rendering a blank strip where the question should be.
	{"name": "safe_area margins (layout)", "path": "res://tools/tests/test_safe_area.gd"},
]

const NOISE := "Unreferenced static string|string_name\\.cpp:|NavMeshGeometryParser|PagedAllocator"


func _init() -> void:
	var exe := OS.get_executable_path()
	var failed: Array[String] = []
	var total_checks := 0
	var total_failures := 0
	var total_defects := 0

	print("==========================================================")
	print("  pure-logic test suite -- combined run")
	print("==========================================================")

	for suite_v in SUITES:
		var suite: Dictionary = suite_v
		var path: String = str(suite["path"])
		var rel := path.replace("res://", "")
		print("")
		print("----------------------------------------------------------")
		print("  %s" % str(suite["name"]))
		print("----------------------------------------------------------")
		var out: Array = []
		var code := OS.execute(exe, ["--headless", "--path", ".", "--script", rel], out, true)
		var text := ""
		for chunk in out:
			text += str(chunk)
		for line in text.split("\n"):
			if RegEx.new().search(line) == null:
				continue
			if line.strip_edges() != "" and not _is_noise(line):
				print("  %s" % line)
		# Pull the counters the suite printed.
		total_checks += _grab(text, "checks: ")
		total_failures += _grab_fail(text)
		total_defects += _grab_defects(text)
		if code != 0:
			failed.append(str(suite["name"]))
		print("  --> %s (exit %d)" % ["PASS" if code == 0 else "FAIL", code])

	print("")
	print("==========================================================")
	print("  TOTALS: %d checks across %d suites" % [total_checks, SUITES.size()])
	print("  failures: %d   known product defects pinned: %d" % [total_failures, total_defects])
	if failed.is_empty():
		print("  RESULT: PASS")
	else:
		print("  RESULT: FAIL -- failing suites: %s" % str(failed))
	print("==========================================================")
	quit(0 if failed.is_empty() else failed.size())


func _is_noise(line: String) -> bool:
	for pat in ["Unreferenced static string", "string_name.cpp:", "NavMeshGeometryParser", "PagedAllocator"]:
		if line.contains(pat):
			return true
	return false


func _grab(text: String, marker: String) -> int:
	for line in text.split("\n"):
		if line.contains(marker):
			var parts := line.strip_edges().trim_prefix(marker).split(" ")
			if parts.size() > 0 and parts[0].is_valid_int():
				return int(parts[0])
	return 0


func _grab_fail(text: String) -> int:
	var n := 0
	for line in text.split("\n"):
		if line.contains("FAIL:") and not line.contains("known defect appears FIXED"):
			n += 1
	return n


func _grab_defects(text: String) -> int:
	var n := 0
	for line in text.split("\n"):
		if line.contains("KNOWN DEFECT:"):
			n += 1
	return n
