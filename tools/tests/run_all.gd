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
	# PDF figures: shown before answering in both layouts, crop of the real page,
	# no highlight or added caption until the answer is in.
	{"name": "question figures (pre-answer, no leak, both layouts)", "path": "res://tools/tests/test_diagrams.gd"},
	{"name": "audio_explanation_generator", "path": "res://tools/tests/test_audio_explanation_generator.gd"},
	{"name": "speech_text", "path": "res://tools/tests/test_speech_text.gd"},
	{"name": "speech_rules", "path": "res://tools/tests/test_speech_rules.gd"},
	{"name": "unit_matcher", "path": "res://tools/tests/test_unit_matcher.gd"},
	{"name": "info panel (memory tip, answer chip)", "path": "res://tools/tests/test_info_panel.gd"},
	{"name": "table_viewer (pure)", "path": "res://tools/tests/test_table_viewer.gd"},
	# Tables used to scroll inside a box sized from a 33 px row guess; a wrapped
	# row put a scrollbar on the table. Now every table shows whole.
	{"name": "reference tables (no scrollbar, both layouts)", "path": "res://tools/tests/test_table_fit.gd"},
	# Layout regression guard. The scene harness asserts quiz LOGIC and never
	# inspects a margin, so a broken safe-area calculation shipped green and left
	# the app rendering a blank strip where the question should be.
	{"name": "safe_area margins (layout)", "path": "res://tools/tests/test_safe_area.gd"},
	# Pins the full node tree both builders make, so they can be moved and
	# refactored with proof that nothing on screen changed.
	{"name": "layout tree golden (both layouts)", "path": "res://tools/tests/test_layout_tree.gd"},
	{"name": "quiz session (grading, missed list, clocks)", "path": "res://tools/tests/test_quiz_session.gd"},
	# Every new run reshuffles questions and choices; letters on screen and in
	# the voice follow the shuffled choices, grading uses the bank's index.
	{"name": "shuffle (question order, choice order, statistics)", "path": "res://tools/tests/test_shuffle.gd"},
	# Blueprint drills, per-area decks, missed-question reviews, the simulator's
	# blueprint and the saved study state.
	{"name": "question deck (exam blueprint, reviews, saved state)", "path": "res://tools/tests/test_question_deck.gd"},
	{"name": "study feedback (subject areas, pace, readiness, weakest-area drill)", "path": "res://tools/tests/test_study_feedback.gd"},
	{"name": "app theme (palette, factories)", "path": "res://tools/tests/test_app_theme.gd"},
	{"name": "nec reference (titles, lookup path)", "path": "res://tools/tests/test_nec_reference.gd"},
	{"name": "bank loader (shapes, leak guard)", "path": "res://tools/tests/test_bank_loader.gd"},
	# project.godot is parsed by ConfigFile, whose only comment char is ";".
	# A "#" comment silently fused onto the next setting's NAME and left
	# emulate_mouse_from_touch at its default TRUE, so every tap also drove the
	# mouse branch that selects an answer card when you meant to scroll.
	{"name": "project settings (parsed)", "path": "res://tools/tests/test_project_settings.gd"},
	# 1.0 moved saves out of %APPDATA%\Godot\app_userdata; progress is copied once.
	{"name": "user dir migration (one-time copy, temp dirs)", "path": "res://tools/tests/test_user_dir_migration.gd"},
	# Tap-vs-drag on the answer cards. Grading is irreversible, so a scroll that
	# commits an answer is the worst failure mode in an exam app.
	{"name": "answer card tap-vs-drag", "path": "res://tools/tests/test_answer_card_input.gd"},
	# Android: ScrollContainer only drag-scrolls on mouse events and the app
	# turns touch-to-mouse emulation off, so no list scrolled by finger. A swipe
	# over buttons and cards must scroll without pressing; a tap still presses.
	{"name": "touch scroll (swipe scrolls, never presses; both layouts)", "path": "res://tools/tests/test_touch_scroll.gd"},
	# Android: the OptionButton popup took no touch, so choosing a voice froze
	# the app and Back then quit it. 450 fake voices, time budget, no re-entry,
	# US English only with male/female names from docs/ANDROID_VOICES.md; the
	# Windows Edge voices after the recorded one, with a no-internet fallback.
	{"name": "voice picker (hundreds of voices, names, US only, Edge voices)", "path": "res://tools/tests/test_voice_picker.gd"},
	{"name": "fx helpers (chapter map, gauges)", "path": "res://tools/tests/test_fx.gd"},
	# Hover slides once tweened position:x as_relative, so container re-sorts
	# and quick mouse passes left each menu card a different few px off its
	# slot. Mode and answer cards now line up in every state and after every
	# animation, and the desktop menu (State Law section included) fits.
	{"name": "menu and answer cards (alignment, state margins, fit)", "path": "res://tools/tests/test_menu_cards.gd"},
	{"name": "audio settings (modes, autoplay rules)", "path": "res://tools/tests/test_audio_settings.gd"},
	{"name": "sfx (sound map, voice ducking, bus)", "path": "res://tools/tests/test_sfx.gd"},
	{"name": "speech bus chain (anti-image, pitch bypass)", "path": "res://tools/tests/test_speech_chain.gd"},
	# Desktop Edge voices: warm helper, streamed clips, prefetch, cancel, honest fallback.
	{"name": "speech helper (stream, prefetch, cancel, cache)", "path": "res://tools/tests/test_speech_helper.gd"},
	# Android cannot run the Python helper, so the phone never had the Edge
	# voices. The GDScript client speaks the same protocol (against a local fake
	# here), never blocks a frame and fails fast with no internet.
	{"name": "edge client (Edge voices without Python, offline fallback)", "path": "res://tools/tests/test_edge_client.gd"},
]

const NOISE := "Unreferenced static string|string_name\\.cpp:|NavMeshGeometryParser|PagedAllocator"


func _init() -> void:
	var exe := OS.get_executable_path()
	var failed: Array[String] = []
	var total_checks := 0
	var total_failures := 0
	var total_defects := 0

	if not _should_print_suite_line("checks: 1") or _should_print_suite_line(" ") or _should_print_suite_line("Unreferenced static string"):
		failed.append("runner output filtering")

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
			if not _should_print_suite_line(line):
				continue
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


func _should_print_suite_line(line: String) -> bool:
	return not line.strip_edges().is_empty() and not _is_noise(line)


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
