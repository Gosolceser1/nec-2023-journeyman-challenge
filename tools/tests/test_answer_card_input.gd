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

	# --- verdict animation: never a layout change, reduce motion is static ---
	_verdict_case()

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


## The answer animation must leave a synchronous caller (the harness) looking
## at the final graded card, and reduce motion must mean no animation at all.
func _verdict_case() -> void:
	print("=== ANSWER CARD VERDICT ===")
	for state in [AnswerCard.State.CORRECT, AnswerCard.State.WRONG]:
		var card := _new_card()
		card.set_state(state)
		var settled := card.get_theme_stylebox("panel")
		var min_size := card.get_combined_minimum_size()
		if state == AnswerCard.State.CORRECT:
			card.celebrate(true)
		else:
			card.reject(true)
		check(card._verdict_tweens.is_empty(), "reduce motion starts no tween (state %d)" % state)
		check(_same_style(card.get_theme_stylebox("panel"), settled) and card.icon_progress == 1.0 and card.scale == Vector2.ONE,
			"reduce motion shows the final card at once (state %d)" % state)
		if state == AnswerCard.State.CORRECT:
			card.celebrate(false)
		else:
			card.reject(false)
		check(not card._verdict_tweens.is_empty(), "full motion animates (state %d)" % state)
		check(card.current_state == state, "animating keeps the graded state (state %d)" % state)
		check(card.get_combined_minimum_size() == min_size, "animation never changes the card's size (state %d)" % state)
		card._stop_verdict()
		check(card.scale == Vector2.ONE and card.position.x == 0.0 and card.icon_progress == 1.0 and card.icon_heat == 0.0
			and card.icon_pad == 0.0 and card.icon_pop == 0.0 and card.icon_flicker == 1.0,
			"stopping snaps to the settled look (state %d)" % state)
		check(_same_style(card.get_theme_stylebox("panel"), settled), "the settled stylebox is the state style (state %d)" % state)
		card.queue_free()
	var right := _new_card()
	right.set_state(AnswerCard.State.CORRECT)
	right.reveal_right(0.2, true)
	check(right._verdict_tweens.is_empty() and right.icon_progress == 1.0, "reveal under reduce motion: final check at once")
	right.reveal_right(0.2, false)
	check(right.icon_progress == 0.0 and not right._verdict_tweens.is_empty(), "reveal draws the check in after the delay")
	right._stop_verdict()
	right.queue_free()
	var probe := _new_card()
	var widest := 0.0
	for n in 13:
		probe._glitch_at(float(n) / 12.0)
		widest = maxf(widest, absf(probe.position.x))
	check(widest > 0.0 and widest <= 5.0, "glitch moves the card sideways by at most 5 px (got %.1f)" % widest)
	check(probe.position.x == 0.0, "glitch ends back at x = 0")
	probe.queue_free()

func _same_style(a: StyleBox, b: StyleBox) -> bool:
	var fa := a as StyleBoxFlat
	var fb := b as StyleBoxFlat
	if fa == null or fb == null:
		return a == b
	return fa.bg_color == fb.bg_color and fa.border_color == fb.border_color and fa.shadow_size == fb.shadow_size \
		and fa.shadow_color == fb.shadow_color and fa.border_width_left == fb.border_width_left
