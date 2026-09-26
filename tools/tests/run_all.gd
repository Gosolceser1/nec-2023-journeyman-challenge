extends SceneTree
## Combined runner: executes every pure-logic test file in one Godot process and
## prints one pass/fail line per suite plus a grand total.
##
##   ./Godot_v4.7.2-stable_win64_console.exe --headless --path . \
##       --script tools/tests/run_all.gd
##
## Exit code 0 = every suite passed. Non-zero = the number of failing SUITES.
##
## WHY THIS WORKS: each suite is a SceneTree script whose logic lives in a
## plain method that this runner calls directly, so a failing assertion does not
## abort the whole run. The suites are still runnable standalone (see README.md)
## for a focused loop.

const SUITES := [
	{"name": "no-leak (the product guarantee)", "path": "res://tools/tests/test_no_leak.gd", "run": "run"},
	{"name": "audio_explanation_generator", "path": "res://tools/tests/test_audio_explanation_generator.gd", "run": "run"},
	{"name": "speech_text", "path": "res://tools/tests/test_speech_text.gd", "run": "run"},
	{"name": "unit_matcher", "path": "res://tools/tests/test_unit_matcher.gd", "run": "run"},
	{"name": "table_viewer (pure)", "path": "res://tools/tests/test_table_viewer.gd", "run": "run"},
]


func _init() -> void:
	var total_checks := 0
	var total_failures := 0
	var total_defects := 0
	var failed_suites: Array[String] = []

	print("==========================================================")
	print("  pure-logic test suite -- combined run")
	print("==========================================================")

	# SceneTree.new() fires each suite's _init(); tell them to stand down so the
	# runner can drive run() itself and keep every suite running after a failure.
	var reporter_script = load("res://tools/tests/t_report.gd")
	reporter_script.autostart_disabled = true

	for suite_v in SUITES:
		var suite: Dictionary = suite_v
		var path: String = str(suite["path"])
		print("")
		print("----------------------------------------------------------")
		print("  %s" % str(suite["name"]))
		print("----------------------------------------------------------")
		var script = load(path)
		if script == null:
			print("  COULD NOT LOAD ", path)
			failed_suites.append(str(suite["name"]))
			continue
		# Each suite is a SceneTree subclass; instantiate it WITHOUT letting it
		# attach to this tree, then drive its run method and read its counters.
		var instance = script.new()
		if not instance.has_method(str(suite["run"])):
			print("  SUITE HAS NO run() METHOD")
			failed_suites.append(str(suite["name"]))
			instance.free()
			continue
		instance.call(str(suite["run"]))
		var reporter = instance.get("t")
		var checks: int = int(reporter.get("checks"))
		var failures: Array = reporter.get("failures")
		var defects: Array = reporter.get("defects")
		total_checks += checks
		total_failures += failures.size()
		total_defects += defects.size()
		var ok: bool = failures.is_empty()
		print("  --> %s: %d checks, %d failures, %d known defects" % [
			"PASS" if ok else "FAIL", checks, failures.size(), defects.size()])
		if not ok:
			failed_suites.append(str(suite["name"]))
		instance.free()

	print("")
	print("==========================================================")
	print("  TOTALS: %d checks across %d suites" % [total_checks, SUITES.size()])
	print("  failures: %d   known product defects documented: %d" % [total_failures, total_defects])
	if failed_suites.is_empty():
		print("  RESULT: PASS")
	else:
		print("  RESULT: FAIL -- failing suites: %s" % str(failed_suites))
	print("==========================================================")
	quit(0 if failed_suites.is_empty() else failed_suites.size())
