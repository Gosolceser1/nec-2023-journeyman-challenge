class_name MainMenu
extends RefCounted
## The launch menu for both layouts, built from data/menu.json: a hero, a row
## of tabs and one page per tab; every page fits the screen without scrolling.
## A page lists blocks by kind and each kind has one _block_<kind> builder
## here. Practice exams come from the bank (MenuModel.families), exam format
## numbers from ExamBlueprint, the edition from Edition, the study tools from
## the file the study_tools block names. refresh() re-reads the progress
## whenever the menu opens. Owned by Main (host.menu).

var host: Main
var spec: Dictionary = {}
var tab_ids: PackedStringArray = []
var tab_buttons: Array[Button] = []
## Holds the pages; kept at least as tall as the Home page (hold_height).
var holder: VBoxContainer
var pages: Array[VBoxContainer] = []
var current := 0
## Every grid tile (exams, sizes, areas, tools): hover sound like the cards.
var tiles: Array[Button] = []
var continue_button: Button
var quick_button: Button
var review_button: Button
var outline: OutlineBars
var families: Array = []
var family_buttons: Array[Button] = []
var family_grids: Array[GridContainer] = []
var family := 0
var page := 0
var per_page := 12
var exam_tiles: Dictionary = {}
var exam_summary: Label
var pager: HBoxContainer
var page_label: Label
var prev_button: Button
var next_button: Button
var area_tiles: Dictionary = {}
var tool_tiles: Dictionary = {}
var footer_label: Label


func mobile() -> bool:
	return host.ui_mobile


## Sizes per layout: [desktop, mobile].
func px(desktop: float, phone: float) -> float:
	return phone if mobile() else desktop


func vars() -> Dictionary:
	return {"edition": Edition.short_label(), "version": Main.version_label(),
		"items": ExamBlueprint.scored_items(), "minutes": ExamBlueprint.minutes(), "pass": ExamBlueprint.pass_percent()}


## Hero, tabs and pages into the layout's menu column.
func build(column: VBoxContainer) -> void:
	spec = MenuModel.spec()
	var v := vars()
	Widgets.add_menu_hero(host, column, px(64, 52), AppTheme.TYPE_TITLE,
		MenuModel.fill(str(spec.get("standards", "")), v),
		MenuModel.fill(str(spec.get("title_short" if mobile() else "title", "")), v),
		MenuModel.fill(str(spec.get("tagline", "")), v))
	var bar := HBoxContainer.new()
	bar.name = "MenuTabs"
	bar.add_theme_constant_override("separation", AppTheme.SPACE_XS if mobile() else AppTheme.SPACE_SM)
	column.add_child(bar)
	var group := ButtonGroup.new()
	holder = VBoxContainer.new()
	holder.name = "MenuPages"
	column.add_child(holder)
	for tab in spec.get("tabs", []):
		var i := tab_ids.size()
		tab_ids.append(str(tab.get("id", "")))
		var b := _tab_button(str(tab.get("title", "")), str(tab.get("icon", "")), group)
		b.pressed.connect(show_tab.bind(i))
		bar.add_child(b)
		tab_buttons.append(b)
		var p := VBoxContainer.new()
		p.name = "Page_" + tab_ids[i]
		p.add_theme_constant_override("separation", AppTheme.SPACE_SM + 2)
		p.visible = false
		holder.add_child(p)
		pages.append(p)
		for kind in tab.get("blocks", []):
			var builder := "_block_" + str(kind)
			if has_method(builder):
				call(builder, p, MenuModel.block(str(kind)))
	show_tab(0)


func show_tab(i: int) -> void:
	if pages.is_empty():
		return
	current = clampi(i, 0, pages.size() - 1)
	for j in pages.size():
		pages[j].visible = j == current
		tab_buttons[j].set_pressed_no_signal(j == current)
	if tab_ids[current] == "settings" and not host.audio_expanded:
		host.audio_expanded = true
		AudioSection.refresh(host)
	host._fit_menu_spacing.call_deferred()
	# A page shown for the first time measures its wrapped labels at width 0
	# until it has been laid out once; fit again after that frame.
	var tree := host.get_tree()
	if tree != null and not tree.process_frame.is_connected(host._fit_menu_spacing):
		tree.process_frame.connect(host._fit_menu_spacing, CONNECT_ONE_SHOT | CONNECT_DEFERRED)


## While Home is open, remembers its height as the least height of every
## page, so switching to a shorter tab does not resize or re-centre the menu.
func hold_height() -> void:
	if current == 0 and not pages.is_empty():
		holder.custom_minimum_size.y = pages[0].get_combined_minimum_size().y


func tab_index(id: String) -> int:
	return tab_ids.find(id)


## The page's first visible card or tile, for keyboard focus.
func first_focus() -> Control:
	return _first_button(pages[current]) if not pages.is_empty() else null


func _first_button(node: Node) -> Control:
	for c in node.get_children():
		if not (c is Control and (c as Control).visible):
			continue
		if c is BaseButton and not (c as BaseButton).disabled:
			return c
		var inner := _first_button(c)
		if inner != null:
			return inner
	return null


func _tab_button(title: String, icon: String, group: ButtonGroup) -> Button:
	var b := Widgets.make_chip(title, px(38, 56), AppTheme.TYPE_META if mobile() else AppTheme.TYPE_BODY_SM, group)
	if Icons.NAMES.has(icon):
		b.icon = Icons.texture(icon, 16)
		b.add_theme_constant_override("icon_max_width", 16)
		b.add_theme_color_override("icon_normal_color", AppTheme.SLATE_400)
		b.add_theme_color_override("icon_pressed_color", AppTheme.EMERALD_300)
		b.add_theme_color_override("icon_hover_pressed_color", AppTheme.EMERALD_200)
		if mobile():
			b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.clip_text = true
	return b


func _header(parent: VBoxContainer, text: String, accent: Color = AppTheme.SKY_400) -> void:
	if text != "":
		parent.add_child(Widgets.make_section_header(MenuModel.fill(text, vars()), accent))


func _note(parent: Container, text: String, color: Color = AppTheme.SLATE_400) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", AppTheme.ui_font(AppTheme.WEIGHT_REGULAR))
	l.add_theme_font_size_override("font_size", AppTheme.TYPE_META)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


func _grid(parent: VBoxContainer, columns: int) -> GridContainer:
	var g := GridContainer.new()
	g.columns = maxi(1, columns)
	g.add_theme_constant_override("h_separation", AppTheme.SPACE_SM)
	g.add_theme_constant_override("v_separation", AppTheme.SPACE_SM)
	parent.add_child(g)
	return g


func _layout_value(cfg: Dictionary, key: String, fallback: int) -> int:
	var v = cfg.get(key, {})
	return int(v.get("mobile" if mobile() else "desktop", fallback)) if v is Dictionary else fallback


func _card(parent: VBoxContainer, title: String, detail: String, callback: Callable, accent: Color, icon: String, badge_count: int, major := false) -> Button:
	var b := Widgets.add_mode_button(host, parent, title, detail, callback, accent,
		AppTheme.EXAM_BUTTON_BG if major else AppTheme.SURFACE_BOTTOM, major,
		px(-1.0, 72.0 if major else 64.0), -1 if not mobile() else AppTheme.TYPE_BODY, icon)
	_set_badge(b, badge_count)
	return b


func _set_badge(b: Button, count: int) -> void:
	var badge := b.get_node_or_null("ModeBadge") as ModeBadge
	if badge != null:
		badge.question_count = count
		badge.queue_redraw()


func _tile(parent: GridContainer, title: String, accent: Color, callback: Callable, h: float, starts_session := true) -> MenuTile:
	var t := MenuTile.new(title, accent, h, AppTheme.TYPE_BODY_SM if not mobile() else AppTheme.TYPE_BODY, AppTheme.TYPE_META)
	if starts_session:
		Widgets.connect_session_start(host, t, callback)
	else:
		t.pressed.connect(callback)
	parent.add_child(t)
	tiles.append(t)
	return t


# --- Home ---------------------------------------------------------------

func _block_continue(parent: VBoxContainer, cfg: Dictionary) -> void:
	continue_button = _card(parent, str(cfg.get("title", "")), "", host._resume_session, AppTheme.EMERALD_400, "play", 0)
	continue_button.set_meta("keeps_detail", true)
	continue_button.set_meta("template", str(cfg.get("detail", "")))
	continue_button.visible = false


func _block_quick_drill(parent: VBoxContainer, cfg: Dictionary) -> void:
	var n := int(cfg.get("size", 10))
	var v := vars()
	v["n"] = n
	v["minutes"] = host._practice_time(n) / 60
	quick_button = _card(parent, MenuModel.fill(str(cfg.get("title", "")), v), MenuModel.fill(str(cfg.get("detail", "")), v),
		host._start_quiz.bind(n, host._practice_time(n), true, "%d-Question Practice" % n), AppTheme.SKY_400, "stopwatch", n)


func _block_weakest_area(parent: VBoxContainer, cfg: Dictionary) -> void:
	var n := int(cfg.get("size", 10))
	var v := vars()
	v["n"] = n
	host.study_button = _card(parent, MenuModel.fill(str(cfg.get("title", "")), v), weakest_detail(),
		host._start_area_drill.bind(n), AppTheme.SKY_300, "target", n)


func weakest_detail() -> String:
	var cfg := MenuModel.block("weakest_area")
	var n := int(cfg.get("size", 10))
	var v := vars()
	v["minutes"] = host._practice_time(n) / 60
	if host.records.is_empty():
		return MenuModel.fill(str(cfg.get("empty", "")), v)
	var mastery := host.session.deck.mastery(host.records)
	var area := QuestionDeck.weakest_area(mastery, host.records)
	var m: Dictionary = mastery.get(area, {})
	v["area"] = ExamBlueprint.title(area)
	v["level"] = "new" if int(m.get("answers", 0)) == 0 else "%d%%" % roundi(100.0 * float(m["right"]) / float(m["answers"]))
	v["readiness"] = roundi(100.0 * QuestionDeck.readiness(mastery))
	return MenuModel.fill(str(cfg.get("detail", "")), v)


func _block_review_missed(parent: VBoxContainer, cfg: Dictionary) -> void:
	review_button = _card(parent, str(cfg.get("title", "")), "", host._start_review, AppTheme.AMBER_400, "replay", 0)


func _block_simulator(parent: VBoxContainer, cfg: Dictionary) -> void:
	var v := vars()
	_header(parent, str(cfg.get("header", "")), AppTheme.ROSE_400)
	_card(parent, MenuModel.fill(str(cfg.get("title", "")), v), MenuModel.fill(str(cfg.get("detail", "")), v),
		host._start_quiz.bind(ExamBlueprint.scored_items(), ExamBlueprint.minutes() * 60, true, Main.SIMULATION_NAME),
		AppTheme.ROSE_500, "bolt", ExamBlueprint.scored_items(), true)
	if str(cfg.get("outline", "")) != "":
		_note(parent, MenuModel.fill(str(cfg["outline"]), v), AppTheme.SLATE_300)
		outline = OutlineBars.new()
		parent.add_child(outline)


# --- Exams ----------------------------------------------------------------

func _block_exam_groups(parent: VBoxContainer, cfg: Dictionary) -> void:
	families = MenuModel.families(host.records)
	var g = cfg.get("grid", {})
	var shape = g.get("mobile" if mobile() else "desktop", {}) if g is Dictionary else {}
	if not shape is Dictionary:
		shape = {}
	var columns := maxi(1, int(shape.get("columns", 3)))
	per_page = columns * maxi(1, int(shape.get("rows", 4)))
	_header(parent, str(cfg.get("header", "")))
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	parent.add_child(chips)
	var group := ButtonGroup.new()
	for f in families.size():
		var fam: Dictionary = families[f]
		var chip := Widgets.make_chip("%s  %d" % [fam["title"], (fam["exams"] as Array).size()], px(34, 48), AppTheme.TYPE_BODY_SM, group)
		chip.pressed.connect(show_family.bind(f))
		chips.add_child(chip)
		family_buttons.append(chip)
	exam_summary = _note(parent, "")
	for f in families.size():
		var grid := _grid(parent, columns)
		grid.visible = false
		family_grids.append(grid)
		for exam in families[f]["exams"]:
			var title := MenuModel.fill(str(cfg.get("tile_title", "{label}")),
				{"label": exam["label"], "family": families[f]["title"], "number": exam["number"]}) if int(exam["number"]) > 0 else str(exam["label"])
			var t := _tile(grid, title, AppTheme.SKY_400 if f % 2 == 0 else AppTheme.EMERALD_400,
				_start_exam.bind(exam), px(70, 80))
			exam_tiles[exam["label"]] = t
	pager = HBoxContainer.new()
	pager.alignment = BoxContainer.ALIGNMENT_CENTER
	pager.add_theme_constant_override("separation", AppTheme.SPACE_MD)
	parent.add_child(pager)
	prev_button = Widgets.make_dock_button("Previous", 110, px(32, 44), AppTheme.TYPE_BODY_SM, flip_page.bind(-1))
	page_label = Label.new()
	page_label.add_theme_font_override("font", AppTheme.numeric_font(AppTheme.WEIGHT_SEMIBOLD))
	page_label.add_theme_font_size_override("font_size", AppTheme.TYPE_META)
	page_label.add_theme_color_override("font_color", AppTheme.SLATE_300)
	next_button = Widgets.make_dock_button("Next", 110, px(32, 44), AppTheme.TYPE_BODY_SM, flip_page.bind(1))
	for c in [prev_button, page_label, next_button]:
		pager.add_child(c)
	show_family(0)


func show_family(f: int) -> void:
	if families.is_empty():
		return
	family = clampi(f, 0, families.size() - 1)
	page = 0
	for i in family_buttons.size():
		family_buttons[i].set_pressed_no_signal(i == family)
	_show_page()


func flip_page(step: int) -> void:
	page += step
	_show_page()


func page_total() -> int:
	return MenuModel.page_count((families[family]["exams"] as Array).size(), per_page) if not families.is_empty() else 1


func _show_page() -> void:
	var pages_n := page_total()
	page = clampi(page, 0, pages_n - 1)
	for i in family_grids.size():
		family_grids[i].visible = i == family
	var grid := family_grids[family]
	for i in grid.get_child_count():
		(grid.get_child(i) as Control).visible = i / per_page == page
	pager.visible = pages_n > 1
	page_label.text = MenuModel.fill(str(MenuModel.block("exam_groups").get("page", "")), {"page": page + 1, "pages": pages_n})
	prev_button.disabled = page == 0
	next_button.disabled = page >= pages_n - 1
	_refresh_summary()
	host._fit_menu_spacing.call_deferred()


func _start_exam(exam: Dictionary) -> void:
	var indices: Array[int] = exam["indices"]
	host._start_fixed(indices, host._practice_time(indices.size()), str(exam["label"]), str(exam["label"]))


# --- Drills ---------------------------------------------------------------

func _block_drill_sizes(parent: VBoxContainer, cfg: Dictionary) -> void:
	_header(parent, str(cfg.get("header", "")))
	var sizes: Array = cfg.get("sizes", [])
	var grid := _grid(parent, sizes.size())
	for s in sizes:
		var n := int(s.get("n", 10))
		var v := vars()
		v["n"] = n
		v["minutes"] = host._practice_time(n) / 60
		v["blurb"] = str(s.get("blurb", ""))
		var t := _tile(grid, MenuModel.fill(str(cfg.get("title_compact" if mobile() else "title", cfg.get("title", ""))), v),
			AppTheme.SKY_400, host._start_quiz.bind(n, host._practice_time(n), true, "%d-Question Practice" % n), px(70, 72))
		t.set_status(MenuModel.fill(str(cfg.get("detail_compact" if mobile() else "detail", cfg.get("detail", ""))), v), "", AppTheme.SLATE_400, 0.0)
		t.meter.visible = false
		t.tooltip_text = MenuModel.fill(str(cfg.get("tooltip", "")), v)


func _block_area_drills(parent: VBoxContainer, cfg: Dictionary) -> void:
	var n := int(cfg.get("size", 10))
	var v := vars()
	v["n"] = n
	_header(parent, MenuModel.fill(str(cfg.get("header", "")), v), AppTheme.SKY_300)
	var grid := _grid(parent, _layout_value(cfg, "columns", 2))
	var short: Dictionary = cfg.get("short_titles", {}) if mobile() else {}
	for k in ExamBlueprint.keys():
		var t := _tile(grid, str(short.get(k, ExamBlueprint.title(k))), AppTheme.SKY_300, host._start_area_drill.bind(n, k), px(64, 72))
		area_tiles[k] = t


# --- Study ----------------------------------------------------------------

func _block_study_tools(parent: VBoxContainer, cfg: Dictionary) -> void:
	_header(parent, str(cfg.get("header", "")), AppTheme.EMERALD_400)
	var tools := _study_tools(cfg)
	if tools.is_empty():
		_note(parent, str(cfg.get("missing", "")))
		return
	var grid := _grid(parent, _layout_value(cfg, "columns", 2))
	for tool in tools:
		var id := str(tool.get("id", ""))
		# Opening a tool is not a session: a plain click, not the start cue.
		var t := _tile(grid, str(tool.get("title", id)), AppTheme.EMERALD_400, open_tool.bind(id), px(84, 96), false)
		t.detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.detail_label.max_lines_visible = 2
		t.set_status(str(tool.get("description", "")), "", AppTheme.SLATE_400, 0.0)
		t.meter.visible = false
		if Icons.NAMES.has(str(tool.get("icon", ""))):
			var icon := _tool_icon(str(tool["icon"]))
			t.title_row.add_child(icon)
			t.title_row.move_child(icon, 0)
		tool_tiles[id] = t
	if str(cfg.get("note", "")) != "":
		_note(parent, str(cfg["note"]))


## Exam-day lookup routine (Study tab): a header and numbered steps.
func _block_hunt_tip(parent: VBoxContainer, cfg: Dictionary) -> void:
	_header(parent, str(cfg.get("header", "")), AppTheme.AMBER_400)
	for step in cfg.get("steps", []):
		_note(parent, MenuModel.fill(str(step), vars()), AppTheme.SLATE_300)


func _tool_icon(icon: String) -> TextureRect:
	var r := TextureRect.new()
	r.texture = Icons.texture(icon, 16)
	r.modulate = AppTheme.EMERALD_300
	r.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## The tools the study_tools block lists, when both its source and its entry
## script are in the build.
func _study_tools(cfg: Dictionary) -> Array:
	var source := str(cfg.get("source", ""))
	if source == "" or not ResourceLoader.exists(str(cfg.get("entry_script", ""))) or not FileAccess.file_exists(source):
		return []
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(source))
	var list = parsed.get("tools", []) if parsed is Dictionary else []
	return list if list is Array else []


func open_tool(id: String) -> void:
	var script := study_script()
	if script != null:
		script.call(str(MenuModel.block("study_tools").get("entry_method", "open")), host, id)


## The study tools' entry script, or null when it is not in the build. Loaded
## by path so the menu does not depend on it to compile.
func study_script() -> Script:
	var path := str(MenuModel.block("study_tools").get("entry_script", ""))
	return load(path) as Script if path != "" and ResourceLoader.exists(path) else null


## Calls one of the study tools' quiz hooks (study_tools.hooks in
## data/menu.json) when the entry script has it; null otherwise.
func study_hook(hook: String, args: Array) -> Variant:
	var method := str(MenuModel.block("study_tools").get("hooks", {}).get(hook, ""))
	var script := study_script()
	if method == "" or script == null:
		return null
	for m in script.get_script_method_list():
		if str(m["name"]) == method:
			return script.callv(method, args)
	return null


# --- Settings -------------------------------------------------------------

func _block_audio(parent: VBoxContainer, _cfg: Dictionary) -> void:
	AudioSection.build(host, parent)


func _block_footer(parent: VBoxContainer, _cfg: Dictionary) -> void:
	footer_label = _note(parent, MenuModel.fill(str(spec.get("footer", "")), vars()))
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_label.add_theme_font_size_override("font_size", AppTheme.TYPE_MICRO)


# --- Refresh ----------------------------------------------------------------

## Progress into every card and tile; Main._show_menu calls this.
func refresh() -> void:
	if host.records.is_empty():
		return
	var history := host.session.deck.history(host.records)
	var mastery := host.session.deck.mastery(host.records)
	var pass_line := float(ExamBlueprint.pass_percent()) / 100.0
	if is_instance_valid(continue_button):
		_refresh_continue()
	if is_instance_valid(host.study_button):
		_set_text(host.study_button, weakest_detail())
	if is_instance_valid(review_button):
		var cfg := MenuModel.block("review_missed")
		var missed := MenuModel.missed_indices(host.records, history, int(cfg.get("max", 20)))
		var v := vars()
		v["count"] = missed.size()
		v["minutes"] = host._practice_time(missed.size()) / 60
		_set_text(review_button, MenuModel.fill(str(cfg.get("detail" if not missed.is_empty() else "empty", "")), v))
		review_button.set_meta("keeps_detail", missed.is_empty())
		review_button.disabled = missed.is_empty()
		_set_badge(review_button, missed.size())
	if outline != null:
		outline.set_rows(OutlineBars.rows_from(mastery))
	var eg := MenuModel.block("exam_groups")
	for fam in families:
		for exam in fam["exams"]:
			var t: MenuTile = exam_tiles[exam["label"]]
			var p := MenuModel.progress(host.records, exam["indices"], history)
			var r := host.progress.exam_result(str(exam["label"]))
			var v := {"count": p["questions"], "seen": p["seen"]}
			var ran := int(r["runs"]) > 0
			var badge := MenuModel.fill(str(eg.get("best", "")), {"best": r["best"]}) if ran else (str(eg.get("new", "")) if int(p["seen"]) == 0 else "")
			var col := ResultGauge.tint_for(float(r["best"]), float(ExamBlueprint.pass_percent())) if ran else AppTheme.SKY_300
			t.set_status(MenuModel.fill(str(eg.get("tile_detail_seen" if int(p["seen"]) > 0 else "tile_detail", "")), v), badge, col,
				float(r["best"]) / 100.0 if ran else 0.0, pass_line)
			t.meter.color = col if ran else t.accent
	_refresh_summary()
	var ad := MenuModel.block("area_drills")
	for k in area_tiles:
		var m: Dictionary = mastery.get(k, {})
		var answers := int(m.get("answers", 0))
		var acc := float(m.get("right", 0)) / answers if answers > 0 else 0.0
		var v := {"items": ExamBlueprint.items(k), "total": ExamBlueprint.scored_items(), "accuracy": roundi(acc * 100.0)}
		var tile: MenuTile = area_tiles[k]
		var col := ResultGauge.tint_for(acc * 100.0, float(ExamBlueprint.pass_percent())) if answers > 0 else AppTheme.SKY_300
		tile.set_status(MenuModel.fill(str(ad.get("tile_detail", "")), v),
			MenuModel.fill(str(ad.get("best", "")), v) if answers > 0 else str(ad.get("new", "")), col, acc, pass_line)
		tile.meter.color = col if answers > 0 else tile.accent


func _refresh_summary() -> void:
	if exam_summary == null or families.is_empty():
		return
	var history := host.session.deck.history(host.records)
	var fam: Dictionary = families[family]
	var all: Array = []
	for exam in fam["exams"]:
		all.append_array(exam["indices"])
	var p := MenuModel.progress(host.records, all, history)
	exam_summary.text = MenuModel.fill(str(MenuModel.block("exam_groups").get("summary", "")),
		{"exams": (fam["exams"] as Array).size(), "questions": p["questions"], "seen": roundi(100.0 * p["seen"] / maxf(1.0, p["questions"]))})


func _refresh_continue() -> void:
	var snap := host.progress.resume_snapshot
	continue_button.visible = not snap.is_empty()
	if snap.is_empty():
		return
	var ids = snap.get("ids", [])
	var count: int = ids.size() if ids is Array or ids is PackedStringArray else 0
	var next := int(snap.get("next", 0))
	var v := {"name": str(snap.get("name", "")), "next": next + 1, "count": count, "right": int(snap.get("score", 0))}
	_set_text(continue_button, MenuModel.fill(str(continue_button.get_meta("template", "")), v))
	_set_badge(continue_button, count - next)


## A mode card's subtitle; AudioSection.refresh rewrites it for listen mode.
func _set_text(b: Button, detail: String) -> void:
	var base := str(b.get_meta("base_text", b.text))
	b.set_meta("base_text", base.get_slice("\n", 0) + "\n" + detail)
	b.text = str(b.get_meta("base_text"))
