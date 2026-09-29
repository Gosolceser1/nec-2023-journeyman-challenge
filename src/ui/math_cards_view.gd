class_name MathCardsView
extends RefCounted
## Formula Cards: a list of every card, and one card with its picture, the
## formula and its rearrangements, what each letter means, a tip, the
## calculator keys, and a worked example solved by the math engine.


static func list(hub: MathHub) -> Control:
	var scroll := MathUi.scroll()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", AppTheme.SPACE_SM)
	grid.add_theme_constant_override("v_separation", AppTheme.SPACE_SM)
	scroll.add_child(grid)
	var cards := MathData.cards()
	for i in cards.size():
		var card: Dictionary = cards[i]
		var b := MathUi.tile(str(card.get("title", "")), str(card.get("formula", "")), MathUi.skill_color(str(card.get("skill", ""))),
			MathUi.px(MathUi.TILE_H, hub.mobile), MathUi.px(MathUi.TILE, hub.mobile),
			func() -> void:
				hub.sfx("click")
				hub.push(str(card.get("title", "")), "FORMULA CARD", MathCardsView.card_screen.bind(hub, i, true)))
		grid.add_child(b)
	return scroll


## One card. browse: Previous / Next walk the list (off when opened from a problem).
static func card_screen(hub: MathHub, index: int, browse: bool) -> Control:
	var cards := MathData.cards()
	var card: Dictionary = cards[clampi(index, 0, cards.size() - 1)]
	var accent := MathUi.skill_color(str(card.get("skill", "")))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	var top := BoxContainer.new()
	top.vertical = hub.mobile
	top.add_theme_constant_override("separation", AppTheme.SPACE_MD)
	col.add_child(top)
	var pic := MathPicture.new()
	pic.picture = card.get("picture", {})
	pic.custom_minimum_size = Vector2(0, 170) if hub.mobile else Vector2(230, 200)
	if hub.mobile:
		pic.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(pic)
	var formulas := VBoxContainer.new()
	formulas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	formulas.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	formulas.add_theme_constant_override("separation", AppTheme.SPACE_XS)
	top.add_child(formulas)
	var main_formula := MathUi.label(str(card.get("formula", "")), MathUi.px(MathUi.BIG, hub.mobile) + 2, accent, AppTheme.WEIGHT_BOLD, true)
	main_formula.add_theme_font_override("font", AppTheme.numeric_font())
	formulas.add_child(main_formula)
	for f in card.get("formulas", []):
		var alt := MathUi.label(str(f), MathUi.px(MathUi.TEXT, hub.mobile), AppTheme.SLATE_200, AppTheme.WEIGHT_SEMIBOLD, true)
		alt.add_theme_font_override("font", AppTheme.numeric_font(AppTheme.WEIGHT_SEMIBOLD))
		formulas.add_child(alt)
	var scroll := MathUi.scroll()
	col.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	scroll.add_child(body)
	var vars := GridContainer.new()
	vars.columns = 3
	vars.add_theme_constant_override("h_separation", AppTheme.SPACE_MD)
	vars.add_theme_constant_override("v_separation", AppTheme.SPACE_XS)
	for v in card.get("vars", []):
		var sym := MathUi.label(str(v.get("sym", "")), MathUi.px(MathUi.TEXT, hub.mobile), accent, AppTheme.WEIGHT_BOLD)
		sym.add_theme_font_override("font", AppTheme.numeric_font())
		vars.add_child(sym)
		vars.add_child(MathUi.label(str(v.get("meaning", "")), MathUi.px(MathUi.NOTE, hub.mobile), AppTheme.SLATE_100, AppTheme.WEIGHT_MEDIUM, true))
		var unit := MathUi.label(str(v.get("unit", "")), MathUi.px(MathUi.NOTE, hub.mobile) - 2, AppTheme.SLATE_400, AppTheme.WEIGHT_REGULAR, true)
		vars.add_child(unit)
	var vars_panel := MathUi.panel(AppTheme.TABLE_PANEL_BG, AppTheme.HAIRLINE_BRIGHT)
	vars_panel.add_child(vars)
	body.add_child(vars_panel)
	if str(card.get("tip", "")) != "":
		body.add_child(_captioned("TIP", str(card["tip"]), AppTheme.AMBER_400, hub.mobile))
	if str(card.get("calc", "")) != "":
		body.add_child(_captioned("ON YOUR CALCULATOR", str(card["calc"]), AppTheme.VIOLET_400, hub.mobile))
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	col.add_child(foot)
	var h: float = MathUi.px(MathUi.BUTTON_H, hub.mobile)
	if browse:
		var prev := MathUi.ghost_button("Previous", h, func() -> void:
			hub.sfx("select")
			hub.replace(str(cards[index - 1].get("title", "")), "FORMULA CARD", MathCardsView.card_screen.bind(hub, index - 1, true)))
		prev.disabled = index == 0
		foot.add_child(prev)
		var next := MathUi.ghost_button("Next", h, func() -> void:
			hub.sfx("select")
			hub.replace(str(cards[index + 1].get("title", "")), "FORMULA CARD", MathCardsView.card_screen.bind(hub, index + 1, true)))
		next.disabled = index >= cards.size() - 1
		foot.add_child(next)
	var ex: Dictionary = card.get("example", {})
	var sol := MathEngine.solve(str(ex.get("type", "")), ex.get("inputs", {}))
	var example := Widgets.make_primary_button("Worked example", h, MathUi.px(MathUi.BUTTON, hub.mobile), func() -> void:
		hub.sfx("click")
		hub.push("Worked example", str(card.get("title", "")).to_upper(), hub.steps_screen.bind(sol, str(sol.get("prompt", "")))))
	example.name = "WorkedExample"
	example.disabled = not sol.get("ok", false)
	foot.add_child(example)
	return col


static func _captioned(caption: String, text: String, accent: Color, mobile: bool) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.add_child(MathUi.meta_label(caption, accent))
	box.add_child(MathUi.label(text, MathUi.px(MathUi.NOTE, mobile), AppTheme.SLATE_200, AppTheme.WEIGHT_REGULAR, true))
	return box
