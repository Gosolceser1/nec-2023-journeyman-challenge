extends SceneTree
## The tabbed main menu (MainMenu, MenuModel, data/menu.json):
##   - MenuModel: exam labels -> families and exams, question order, progress,
##     missed questions, paging, templates
##   - a new exam or a new family in the bank gets its tile with no code change,
##     and a family longer than one page gets a pager
##   - every tab opens from its button, Android Back returns to Home
##   - every entry starts the session it names: quick drill, weakest area, full
##     exam, each practice exam (its own questions in order), each drill size,
##     each subject area, review missed, continue where you left off
##   - a finished practice exam keeps its best score; a resumed run is graded
##   - the study tools open through data/menu.json's entry script and hooks
##   - every tab fits without scrolling at the phone and desktop window sizes
##
##   Godot --headless --path . --script tools/tests/test_menu.gd [-- --mobile-ui]
##
## Without --mobile-ui the suite also runs itself once with it.

const SIZES := [Vector2i(360, 640), Vector2i(540, 960), Vector2i(540, 1170), Vector2i(1024, 600), Vector2i(1024, 768), Vector2i(1280, 720)]

var failures: Array[String] = []
var checks := 0
var main: Main
var tag := "desktop"


func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: [%s] %s" % [tag, label])


func _wait(sec: float) -> void:
	var until := Time.get_ticks_msec() + int(sec * 1000.0)
	while Time.get_ticks_msec() < until:
		await process_frame
	await process_frame


func _initialize() -> void:
	var mobile := "--mobile-ui" in OS.get_cmdline_user_args()
	tag = "mobile" if mobile else "desktop"
	print("=== main menu (%s) ===" % tag)
	if not mobile:
		_model()
	main = load("res://scenes/main.tscn").instantiate()
	main.audio_cfg_path = "user://test_menu_audio.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.audio_cfg_path))
	main.session.bag_path = ""
	root.add_child(main)
	await _wait(0.6)
	main._on_audio_mode_picked(AudioSettings.Mode.SILENT)
	await _tabs()
	await _entries()
	await _progress_flow()
	await _discovery()
	await _study_tools()
	await _fit()
	var child_ok := true
	if not mobile:
		child_ok = _run_mobile_child()
	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	print("RESULT: ", "PASS" if failures.is_empty() and child_ok else "FAIL")
	quit(0 if failures.is_empty() and child_ok else 1)


func _rec(id: String, exam: String, n: int, area_article := "210.8") -> Dictionary:
	return {"id": id, "exam": exam, "question_number": n, "article": area_article, "prompt": "Q " + id,
		"answers": ["a", "b", "c", "d"], "correct_index": 0}


func _model() -> void:
	print("=== MenuModel ===")
	check(MenuModel.parse_label("Open Book Exam #12") == {"family": "Open Book Exam", "number": 12}, "a label splits into family and number")
	check(MenuModel.parse_label("Final Exam#3") == {"family": "Final Exam", "number": 3}, "no space before # still parses")
	check(MenuModel.parse_label("Code Quiz") == {"family": "Code Quiz", "number": 0}, "a label without a number is its own family")
	check(MenuModel.fill("{a} and {b} {c}", {"a": 1, "b": "two"}) == "1 and two {c}", "fill leaves unknown placeholders")
	check(MenuModel.page_count(0, 12) == 1 and MenuModel.page_count(12, 12) == 1 and MenuModel.page_count(13, 12) == 2, "page counts")
	var recs := [
		_rec("q1", "Final Exam #2", 2), _rec("q2", "Open Book Exam #10", 1), _rec("q3", "Final Exam #2", 1),
		_rec("q4", "Brand New Test #1", 1), _rec("q5", "Open Book Exam #2", 1), _rec("q6", "", 1),
		_rec("q7", "NE State Act #3", 1), _rec("q8", "Open Book Exam #10", 3), _rec("q9", "Open Book Exam #10", 2)]
	var fams := MenuModel.families(recs)
	var names := fams.map(func(f): return f["family"])
	check(names == ["Open Book Exam", "Final Exam", "NE State Act", "Brand New Test"], "families follow family_order, a new one goes last: %s" % str(names))
	check(fams[3]["title"] == "Brand New Test", "a family without a short title shows its own name")
	var ob: Array = fams[0]["exams"]
	check(ob.map(func(e): return e["label"]) == ["Open Book Exam #2", "Open Book Exam #10"], "exams go by number, not text (#2 before #10)")
	check(ob[1]["indices"] == [1, 8, 7], "an exam's questions go by question_number: %s" % str(ob[1]["indices"]))
	check(fams[1]["exams"][0]["indices"] == [2, 0], "Final Exam #2 in question order")
	check(fams[0]["count"] == 4 and fams[1]["count"] == 2, "family question counts")
	check(fams.all(func(f): return (f["exams"] as Array).all(func(e): return e["label"] != "")), "records without an exam label are not an exam")
	var history := {"q2": {"right": 1, "answers": 2, "last_right": false}, "q9": {"right": 1, "answers": 1, "last_right": true},
		"q5": {"right": 0, "answers": 1, "last_right": false}}
	var p := MenuModel.progress(recs, ob[1]["indices"], history)
	check(p == {"questions": 3, "seen": 2, "right": 2, "answers": 3}, "progress over an exam: %s" % str(p))
	check(MenuModel.missed_indices(recs, history, 10) == [1, 4], "missed = last answer wrong, in bank order")
	check(MenuModel.missed_indices(recs, history, 1) == [1], "missed stops at the limit")


func _page(id: String) -> VBoxContainer:
	return main.menu.pages[main.menu.tab_index(id)]


func _tabs() -> void:
	var spec_tabs: Array = MenuModel.spec().get("tabs", [])
	check(main.menu_tab_count() == spec_tabs.size() and spec_tabs.size() >= 5, "one tab per data/menu.json tab (%d)" % main.menu_tab_count())
	for i in main.menu_tab_count():
		main.menu.tab_buttons[i].pressed.emit()
		await process_frame
		var shown := range(main.menu_tab_count()).filter(func(j): return main.menu.pages[j].visible)
		check(shown == [i] and main.menu.tab_buttons[i].button_pressed, "tab %s opens its page alone" % main.menu.tab_ids[i])
	main._last_go_back_msec = 0
	main._on_go_back()
	check(main.menu.current == 0 and main.menu_overlay.visible, "Android Back on another tab returns to Home, the app stays open")
	check(main.menu.current == 0 and main.menu.pages[0].visible, "Home is the first tab")


## Presses a menu control and waits for the session to be up.
func _press(b: BaseButton) -> void:
	b.pressed.emit()
	while main._start_tween != null and main._start_tween.is_running():
		await process_frame
	await process_frame


func _back_to_menu() -> void:
	main._show_menu()
	await _wait(0.1)


func _entries() -> void:
	var menu := main.menu
	# Home
	var quick_n := int(MenuModel.block("quick_drill").get("size", 0))
	await _press(menu.quick_button)
	check(main.session_length == quick_n and not main.menu_overlay.visible and not main.session.session_simulation,
		"quick drill: %d mixed questions (got %d)" % [quick_n, main.session_length])
	await _back_to_menu()
	await _press(main.study_button)
	check(main.session_name.begins_with("Area Drill") and main.session_length == int(MenuModel.block("weakest_area").get("size", 0)), "weakest area: an area drill (%s)" % main.session_name)
	await _back_to_menu()
	var sim: Array = main.menu_mode_buttons.filter(func(b): return bool(b.get_meta("full_exam", false)))
	check(sim.size() == 1, "one full-exam card")
	await _press(sim[0])
	check(main.session.session_simulation and main.session_length == ExamBlueprint.scored_items()
		and main.session_time_limit == ExamBlueprint.minutes() * 60, "full exam: %d items, %d minutes, from the blueprint" % [main.session_length, main.session_time_limit / 60])
	await _back_to_menu()
	check(menu.review_button.disabled, "review missed is off before anything was missed")
	check(not menu.continue_button.visible, "no continue card before any answer")
	# Exams: every tile runs its exam's own questions in order.
	var fams := MenuModel.families(main.records)
	var labels := []
	for f in fams:
		for e in f["exams"]:
			labels.append(e["label"])
	check(menu.exam_tiles.size() == labels.size() and labels.all(func(l): return menu.exam_tiles.has(l)), "a tile for every exam in the bank (%d)" % labels.size())
	var bad := []
	for f in fams:
		for e in f["exams"]:
			await _press(menu.exam_tiles[e["label"]])
			if main.order != e["indices"] or main.session.session_exam != e["label"] or main.session_time_limit != main._practice_time((e["indices"] as Array).size()):
				bad.append(e["label"])
			await _back_to_menu()
	check(bad.is_empty(), "every exam tile runs that exam in question order, timed (off: %s)" % str(bad))
	# Drills
	var sizes: Array = MenuModel.block("drill_sizes").get("sizes", [])
	var size_tiles := menu.tiles.filter(func(t): return _page("drills").is_ancestor_of(t) and not menu.area_tiles.values().has(t))
	check(size_tiles.size() == sizes.size(), "a tile per drill size (%d)" % size_tiles.size())
	for i in size_tiles.size():
		await _press(size_tiles[i])
		check(main.session_length == int(sizes[i]["n"]), "drill tile %d: %d questions" % [i, main.session_length])
		await _back_to_menu()
	check(menu.area_tiles.size() == ExamBlueprint.keys().size(), "a tile per subject area")
	for k in MenuModel.block("area_drills").get("short_titles", {}):
		check(ExamBlueprint.keys().has(k), "short title for a real area: %s" % k)
	for k in menu.area_tiles:
		await _press(menu.area_tiles[k])
		var off := main.order.filter(func(i): return ExamBlueprint.area_of(main.records[i]) != k)
		check(main.session_name.contains(ExamBlueprint.title(k)) and off.is_empty() and not main.order.is_empty(), "area tile %s: only that area" % k)
		await _back_to_menu()


## Answers the current question right or wrong (display slot of the record).
func _answer(right: bool) -> void:
	var c := int(main.session.current_record().get("correct_index", 0))
	main._answer_selected(c if right else (c + 1) % 4)
	await process_frame


func _progress_flow() -> void:
	var menu := main.menu
	# Three wrong, then leave: continue and review appear.
	await _press(menu.quick_button)
	var ids := main.order.map(func(i): return main.records[i]["id"])
	var wrong := main.order.slice(0, 3)
	for q in 3:
		await _answer(false)
		main._next_question()
		await process_frame
	await _answer(true)
	main._show_menu()
	await _wait(0.1)
	check(menu.continue_button.visible and menu.continue_button.text.contains("question 5 of %d" % ids.size()), "continue card after leaving mid-run: %s" % menu.continue_button.text.get_slice("\n", 1))
	check(not menu.review_button.disabled, "review missed is on after misses")
	# The resume point survives a relaunch: continue from a fresh load of the file.
	var saved_path := "user://test_menu_progress.cfg"
	var on_disk := StudyProgress.new(saved_path)
	on_disk.reset()
	on_disk.set_resume(main.progress.resume_snapshot)
	on_disk.record_exam("Open Book Exam #1", 18, 25)
	var in_memory := main.progress
	main.progress = StudyProgress.new(saved_path)
	check(main.progress.has_resume() and int(main.progress.exam_result("Open Book Exam #1")["best"]) == 72, "study_progress.cfg keeps the resume point and best scores across a relaunch")
	wrong.sort()
	await _press(menu.review_button)
	check(main.order == wrong and main.session.session_exam == "", "review missed replays the three misses in bank order")
	await _back_to_menu()
	# Continue: same questions, same place, same tally; graded even in Listen.
	main._on_audio_mode_picked(AudioSettings.Mode.LISTEN)
	await _press(menu.continue_button)
	check(main.order.map(func(i): return main.records[i]["id"]) == ids and main.current_index == 4 and main.score == 1 and main.answered_count == 4,
		"continue resumes the run at question 5 with its tally (index %d, score %d)" % [main.current_index, main.score])
	check(main.session_audio_mode == AudioSettings.Mode.TAP and main.timed_session, "a resumed run is graded and timed even with Listen picked")
	main._on_audio_mode_picked(AudioSettings.Mode.SILENT)
	await _back_to_menu()
	main.progress.reset()
	main.progress = in_memory
	# A practice exam finished all right keeps 100 % as its best.
	var fams := MenuModel.families(main.records)
	var exam: Dictionary = fams.back()["exams"][0]
	var tile: MenuTile = menu.exam_tiles[exam["label"]]
	await _press(tile)
	for q in main.order.size():
		await _answer(true)
		main._next_question()
		await process_frame
	check(main.next_button.text == "Return to Main Menu", "the exam ends on the report")
	check(int(main.progress.exam_result(exam["label"])["best"]) == 100, "the exam's best score is kept (%s)" % str(main.progress.exam_result(exam["label"])))
	check(not main.progress.has_resume(), "a finished run leaves nothing to continue")
	main._show_menu()
	await _wait(0.1)
	check(tile.badge_label.text.contains("100"), "the tile shows the best score: %s" % tile.badge_label.text)
	check(not menu.continue_button.visible, "no continue card after the report")
	check(tile.meter.fraction > 0.99 and is_equal_approx(tile.meter.tick, ExamBlueprint.pass_percent() / 100.0), "the tile's meter shows the best score against the pass mark")


## A new exam and a new family appear with no code change; a long family pages.
func _discovery() -> void:
	var extra: Array = main.records.duplicate()
	for n in range(20, 40):
		extra.append(_rec("syn-%d" % n, "Open Book Exam #%d" % n, 1))
	extra.append(_rec("syn-new", "Master Exam #1", 1))
	var saved := main.records
	main.records = extra
	var m := MainMenu.new()
	m.host = main
	var column := VBoxContainer.new()
	root.add_child(column)
	m._block_exam_groups(column, MenuModel.block("exam_groups"))
	m.refresh()
	await process_frame
	check(m.exam_tiles.has("Open Book Exam #39") and m.exam_tiles.has("Master Exam #1"), "new exams get tiles without a code change")
	check(m.families.back()["family"] == "Master Exam" and m.family_buttons.size() == m.families.size(), "a new family gets its own chip")
	m.show_family(0)
	await process_frame
	var total: int = (m.families[0]["exams"] as Array).size()
	check(m.page_total() == MenuModel.page_count(total, m.per_page) and m.page_total() > 1 and m.pager.visible, "a family longer than a page gets a pager (%d pages)" % m.page_total())
	var shown := func() -> int: return m.family_grids[0].get_children().filter(func(t): return t.visible).size()
	check(shown.call() == m.per_page and m.prev_button.disabled, "page 1 shows a full grid")
	m.flip_page(1)
	check(shown.call() == mini(m.per_page, total - m.per_page) and m.page == 1, "page 2 shows the rest")
	m.flip_page(99)
	check(m.page == m.page_total() - 1 and m.next_button.disabled, "paging stops at the last page")
	column.queue_free()
	main.records = saved
	await process_frame


func _study_tools() -> void:
	var cfg: Dictionary = MenuModel.spec()["blocks"]["study_tools"]
	var saved := cfg.duplicate(true)
	cfg["entry_script"] = "res://tools/tests/no_such_entry.gd"
	var m := MainMenu.new()
	m.host = main
	var column := VBoxContainer.new()
	root.add_child(column)
	m._block_study_tools(column, cfg)
	check(m.tool_tiles.is_empty(), "no study tiles while the entry script is not in the build")
	column.queue_free()
	cfg["entry_script"] = "res://tools/tests/menu_study_stub.gd"
	cfg["source"] = "res://tools/tests/menu_study_stub.json"
	var stub: Script = load(cfg["entry_script"])
	stub.set("calls", [])
	m = MainMenu.new()
	m.host = main
	column = VBoxContainer.new()
	root.add_child(column)
	m._block_study_tools(column, cfg)
	check(m.tool_tiles.keys() == ["alpha", "beta"], "a tile per tool in the source file")
	check(not m.tool_tiles["alpha"].has_meta("starts_session"), "opening a tool is not a session start")
	m.tool_tiles["alpha"].pressed.emit()
	await process_frame
	check(stub.get("calls") == ["open:alpha"] and main.menu_overlay.visible, "a tool tile calls the entry script's open(main, id)")
	check(main.menu.study_hook("back", [main]) == true, "the back hook reaches the entry script")
	main._last_go_back_msec = 0
	main._on_go_back()
	check(main.menu_overlay.visible and (stub.get("calls") as Array).count("back") == 2, "Android Back asks the study tools first")
	stub.set("calls", [])
	await _press(main.menu.quick_button)
	await _answer(true)
	check(stub.get("calls") == ["question", "answered:true:true"], "question and answer hooks run: %s" % str(stub.get("calls")))
	await _back_to_menu()
	column.queue_free()
	cfg["entry_script"] = "res://tools/tests/no_such_entry.gd"
	check(main.menu.study_hook("back", [main]) == null, "no hook calls without the entry script")
	MenuModel.spec()["blocks"]["study_tools"] = saved


func _fit() -> void:
	var scroll := main.menu_center_box.get_parent() as ScrollContainer
	var worst := ""
	var worst_over := -INF
	for s in SIZES:
		DisplayServer.window_set_size(s)
		await _wait(0.2)
		for i in main.menu_tab_count():
			main.menu_show_tab(i)
			await _wait(0.1)
			var over := main.menu_center_box.get_combined_minimum_size().y - scroll.size.y
			if over > worst_over:
				worst_over = over
				worst = "%dx%d %s" % [s.x, s.y, main.menu.tab_ids[i]]
			check(over <= 0.5, "%dx%d tab %s fits (%.0f px over)" % [s.x, s.y, main.menu.tab_ids[i], over])
	print("  tightest fit: %s (%.0f px)" % [worst, worst_over])
	main.menu_show_tab(0)


func _run_mobile_child() -> bool:
	var out: Array = []
	var code := OS.execute(OS.get_executable_path(),
			["--headless", "--path", ".", "--script", "tools/tests/test_menu.gd", "--", "--mobile-ui"], out, true)
	var text := ""
	for chunk in out:
		text += str(chunk)
	for line in text.split("\n"):
		if line.contains("FAIL:") or line.contains("===") or line.contains("tightest"):
			print("  [mobile] " + line.strip_edges())
		elif line.begins_with("checks: "):
			checks += int(line.trim_prefix("checks: ").get_slice(" ", 0))
	return code == 0
