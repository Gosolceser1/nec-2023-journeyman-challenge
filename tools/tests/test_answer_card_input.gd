extends SceneTree
## Answer card tap-vs-drag state machine.
##
## WHY THIS EXISTS: scrolling off an answer card SELECTED it, and grading is
## irreversible (_answer_selected sets current_answered = true). Two causes:
##   1. project.godot used "#" comments, which ConfigFile does not recognise, so
##      pointing/emulate_mouse_from_touch stayed at Godot's default TRUE and every
##      finger also drove answer_card.gd's mouse branch.
##   2. That mouse branch emitted card_clicked unconditionally on release, with
##      no drag-slop check and no cancel_press guard. The ScreenTouch branch
##      always had a slop check, but it was unreachable.
## Both are fixed; these assertions pin the behaviour so neither can regress.

var failures: Array[String] = []
var checks := 0

func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func _init() -> void:
	print("=== ANSWER CARD TAP-VS-DRAG ===")

	# --- the real thing: drive _on_gui_input with synthetic events ---
	for drag in [0.0, 15.0, 25.0, 60.0, 150.0, 300.0]:
		_drag_case(true, drag)
	for drag in [0.0, 25.0, 150.0]:
		_drag_case(false, drag)

	# --- cancel_press must not leave the card stuck in PRESSED ---
	_stuck_press_case()

	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	for f in failures:
		print("  - %s" % f)
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)


## Send an event the way the engine does: through the Control's `gui_input`
## signal, which is what _init() connects _on_gui_input to. Calling
## _on_gui_input() directly also works, but it skips the viewport's hit-testing
## and any accept_event() semantics, so it is not what ships.
func _send(card: AnswerCard, ev: InputEvent) -> void:
	card.gui_input.emit(ev)

func _new_card() -> AnswerCard:
	var card := AnswerCard.new()
	card.set_card_data(0, "Front")
	root.add_child(card)
	# The release test is Rect2(Vector2.ZERO, size).has_point(pos), so an
	# un-laid-out card has size (0,0) and rejects EVERY release. Give it the
	# real on-screen geometry a laid-out card would have.
	card.size = Vector2(500, 70)
	card.custom_minimum_size = Vector2(500, 70)
	return card


func _drag_case(use_touch: bool, drag: float) -> void:
	var kind := "touch" if use_touch else "mouse"
	var card := _new_card()
	# A GDScript lambda captures locals BY VALUE, so `clicks += 1` inside the
	# handler mutates a copy and the counter never moves. An Array is a
	# reference, so this actually counts.
	var clicks := [0]
	card.card_clicked.connect(func(_i: int) -> void: clicks[0] += 1)

	var origin := Vector2(200, 20)
	var end := origin + Vector2(0.0, drag)

	if use_touch:
		var down := InputEventScreenTouch.new()
		down.index = 0
		down.pressed = true
		down.position = origin
		_send(card, down)

		if drag > 0.0:
			var move := InputEventScreenDrag.new()
			move.index = 0
			move.position = end
			move.relative = Vector2(0.0, drag)
			_send(card, move)

		var up := InputEventScreenTouch.new()
		up.index = 0
		up.pressed = false
		up.position = end
		_send(card, up)
	else:
		var down := InputEventMouseButton.new()
		down.button_index = MOUSE_BUTTON_LEFT
		down.pressed = true
		down.position = origin
		_send(card, down)

		if drag > 0.0:
			var move := InputEventMouseMotion.new()
			move.position = end
			move.relative = Vector2(0.0, drag)
			_send(card, move)

		var up := InputEventMouseButton.new()
		up.button_index = MOUSE_BUTTON_LEFT
		up.pressed = false
		up.position = end
		_send(card, up)

	var is_scroll := drag > AnswerCard.TOUCH_SLOP_PX
	var want := 0 if is_scroll else 1
	print("  %s drag %-5.0fpx -> %d click(s)  [%s]" % [
		kind, drag, clicks[0], "correct" if clicks[0] == want else "WRONG"])
	check(clicks[0] == want,
		"%s drag of %.0fpx should fire %d click(s), fired %d" % [kind, drag, want, clicks[0]])
	card.queue_free()


func _stuck_press_case() -> void:
	var card := _new_card()
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.pressed = true
	down.position = Vector2(200, 20)
	_send(card, down)
	check(card.current_state == AnswerCard.State.PRESSED, "card should be PRESSED after touch down")
	# A scroll starts; the ScrollContainer calls cancel_press on every card.
	card.cancel_press()
	print("  after cancel_press, state = %d (NORMAL=%d)" % [card.current_state, AnswerCard.State.NORMAL])
	check(card.current_state != AnswerCard.State.PRESSED,
		"cancel_press left the card stuck in PRESSED (it re-applied PRESSED styling instead of resetting)")
	check(card.current_state == AnswerCard.State.NORMAL,
		"cancel_press should return the card to NORMAL")
	card.queue_free()
