extends SceneTree

# Throwaway probe: replicate the production tree shape (ScrollContainer +
# PASS answer cards, mirror of main.gd::_touch_filter_walk) and drive synthetic
# InputEventScreenTouch / mouse events through Viewport.push_input.

var f := 0
var sc: ScrollContainer
var card: AnswerCard
var clicked := 0
var scroll_started := 0
var gui_seen: Array = []
var log_lines: Array = []
var ctr := Vector2.ZERO

func L(s: String) -> void:
	log_lines.append("PROBE| " + s)

func _initialize() -> void:
	root.size = Vector2i(540, 960)
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(holder)

	sc = ScrollContainer.new()
	sc.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	sc.offset_bottom = 600
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.scroll_started.connect(func(): scroll_started += 1)
	holder.add_child(sc)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(col)

	card = AnswerCard.new()
	card.set_card_data(0, "Test answer text long enough to wrap a little bit here")
	card.card_clicked.connect(func(_i): clicked += 1)
	card.gui_input.connect(_on_gui)
	col.add_child(card)

	for i in 14:
		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(0, 110)
		col.add_child(p)

	filter_walk(holder)

func _on_gui(ev: InputEvent) -> void:
	gui_seen.append("%s pos=%s idx=%d" % [ev.type, str(ev.position), ev.index])

func filter_walk(node: Node) -> void:
	for child in node.get_children():
		filter_walk(child)
	if not node is Control:
		return
	if node is ScrollContainer:
		(node as ScrollContainer).scroll_deadzone = 16
		return
	if node is ScrollBar:
		return
	if node is BaseButton or node.has_method("cancel_press"):
		(node as Control).mouse_filter = Control.MOUSE_FILTER_PASS
		return
	(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

func touch(pressed: bool, pos: Vector2, idx: int = 0) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = idx
	ev.pressed = pressed
	ev.position = pos
	ev.double_tap = false
	root.push_input(ev)

func drag(to: Vector2, idx: int = 0) -> void:
	var ev := InputEventScreenDrag.new()
	ev.index = idx
	ev.position = to
	ev.relative = to - ctr
	root.push_input(ev)

func mouse_btn(pressed: bool, pos: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = pos
	ev.global_position = pos
	root.push_input(ev)

func mouse_move(pos: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = pos
	ev.relative = pos - ctr
	ev.global_position = pos
	root.push_input(ev)

func reset() -> void:
	clicked = 0
	scroll_started = 0
	card.current_state = AnswerCard.State.NORMAL
	card._touch_press_index = -1
	sc.get_v_scroll_bar().value = 0.0
	ctr = card.get_global_rect().get_center()

func _process(_d: float) -> bool:
	f += 1
	match f:
		1:
			L("sc rect=%s card rect=%s card.mouse_filter=%d (PASS=1)" % [str(sc.get_global_rect()), str(card.get_global_rect()), card.mouse_filter])
			L("card visible_in_tree=%s scroll_deadzone=%d" % [str(card.is_visible_in_tree()), sc.scroll_deadzone])
			ctr = card.get_global_rect().get_center()
			L("center=%s" % str(ctr))
			touch(true, ctr)
		2:
			L("A press: press_idx=%d state=%d PRESSED=%d gui=%s" % [card._touch_press_index, card.current_state, AnswerCard.State.PRESSED, str(gui_seen)])
			touch(false, ctr + Vector2(1, 2))
		3:
			L("A tap -> clicked=%d state=%d scroll_started=%d" % [clicked, card.current_state, scroll_started])
			reset()
			touch(true, ctr)
		4:
			L("B press: press_idx=%d state=%d" % [card._touch_press_index, card.current_state])
			drag(ctr + Vector2(0, 60))
		5:
			L("B after 60px drag: press_idx=%d state=%d vscroll=%f scroll_started=%d" % [card._touch_press_index, card.current_state, sc.get_v_scroll_bar().value, scroll_started])
			touch(false, ctr + Vector2(0, 61))
		6:
			L("B after release: clicked=%d press_idx=%d state=%d vscroll=%f scroll_started=%d" % [clicked, card._touch_press_index, card.current_state, sc.get_v_scroll_bar().value, scroll_started])
			L("B STUCK in PRESSED? %s" % str(card.current_state == AnswerCard.State.PRESSED))
			reset()
			touch(true, ctr)
		7:
			drag(ctr + Vector2(0, 18))
			L("C mid 18px: press_idx=%d state=%d scroll_started=%d vscroll=%f" % [card._touch_press_index, card.current_state, scroll_started, sc.get_v_scroll_bar().value])
			touch(false, ctr + Vector2(0, 18))
		8:
			L("C 18px release: clicked=%d press_idx=%d state=%d scroll_started=%d" % [clicked, card._touch_press_index, card.current_state, scroll_started])
			reset()
			touch(true, ctr)
		9:
			drag(ctr + Vector2(5, 10))
			touch(false, ctr + Vector2(5, 10))
			L("D 10px release: clicked=%d scroll_started=%d" % [clicked, scroll_started])
			reset()
			mouse_btn(true, ctr)
			mouse_move(ctr + Vector2(0, 40))
		10:
			L("E mid: state=%d vscroll=%f" % [card.current_state, sc.get_v_scroll_bar().value])
			mouse_btn(false, ctr + Vector2(0, 40))
			L("E mouse press+40px drag+release ON card: clicked=%d state=%d vscroll=%f scroll_started=%d" % [clicked, card.current_state, sc.get_v_scroll_bar().value, scroll_started])
			reset()
			touch(true, ctr)
		11:
			L("F press: press_idx=%d" % card._touch_press_index)
			drag(ctr + Vector2(0, 55))
		12:
			touch(false, ctr + Vector2(0, 400))
			L("F release far outside: clicked=%d press_idx=%d state=%d" % [clicked, card._touch_press_index, card.current_state])
			for s in log_lines:
				print(s)
			return true
	return false
