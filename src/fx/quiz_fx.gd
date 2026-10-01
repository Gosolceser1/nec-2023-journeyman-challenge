class_name QuizFx
extends RefCounted
## Quiz-screen decoration: the fx layer, segmented progress bar and countdown
## gauges attached after the layout builders, and the answer feedback burst.

## Decoration shared by both layouts, attached after the builder ran so the two
## builders stay separate: the fx layer for particles/flashes, the segmented
## progress bar (desktop: beside the progress line; phone: a full-width row
## under the header) and the countdown gauges on the HUD time cells.
static func attach(host: Main) -> void:
	host.fx_layer = UiFx.make_fx_layer()
	host.add_child(host.fx_layer)

	host.progress_segments = ProgressSegments.new()
	var progress_parent := host.progress_label.get_parent()
	if host.ui_mobile:
		var header := progress_parent.get_parent()
		header.add_child(host.progress_segments)
		header.move_child(host.progress_segments, progress_parent.get_index() + 1)
	else:
		var progress_row := HBoxContainer.new()
		progress_row.add_theme_constant_override("separation", AppTheme.SPACE_MD)
		progress_parent.add_child(progress_row)
		progress_parent.move_child(progress_row, host.progress_label.get_index())
		host.progress_label.reparent(progress_row)
		progress_row.add_child(host.progress_segments)

	host.exam_gauge = attach_time_gauge(host, host.timer_label)
	host.pace_gauge = attach_time_gauge(host, host.question_timer_label)


## The label sits directly in its HUD cell (a PanelContainer). Phone: a thin
## bar along the cell's bottom edge; desktop: a ring beside the time.
static func attach_time_gauge(host: Main, label: Label) -> TimeGauge:
	var gauge := TimeGauge.new()
	var cell := label.get_parent()
	if host.ui_mobile:
		gauge.mode = TimeGauge.Mode.EDGE
		cell.add_child(gauge)
		cell.move_child(gauge, 0)
		return gauge
	gauge.custom_minimum_size = Vector2(18, 18)
	gauge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", AppTheme.SPACE_SM)
	cell.add_child(row)
	label.reparent(row)
	row.add_child(gauge)
	row.move_child(gauge, 0)
	return gauge


static func update_time_gauges(host: Main) -> void:
	if is_instance_valid(host.exam_gauge):
		host.exam_gauge.visible = host.timed_session
		var exam_col := UiFx.CYAN
		if host.time_left <= 300:
			exam_col = UiFx.RED
		elif host.time_left <= 900:
			exam_col = UiFx.AMBER
		host.exam_gauge.set_value(float(maxi(host.time_left, 0)) / float(maxi(host.session_time_limit, 1)), exam_col,
			not host.timer.is_stopped() and host.time_left > 0 and host.time_left <= 60)
	if is_instance_valid(host.question_timer_label):
		var pace_badge: Node = host.question_timer_label.get_parent()
		while pace_badge != null and not pace_badge is PanelContainer:
			pace_badge = pace_badge.get_parent()
		if pace_badge != null:
			pace_badge.visible = host.timed_session
	if is_instance_valid(host.pace_gauge):
		host.pace_gauge.visible = host.timed_session
		var pace_col := UiFx.CYAN
		if host.current_answered:
			pace_col = UiFx.EMERALD
		elif host.question_time_left <= 30:
			pace_col = UiFx.RED
		elif host.question_time_left <= 60:
			pace_col = UiFx.AMBER
		host.pace_gauge.set_value(float(maxi(host.question_time_left, 0)) / float(ExamBlueprint.seconds_per_item()), pace_col,
			not host.current_answered and host.question_time_left > 0 and host.question_time_left <= 30)


## Answer feedback, electrical theme (docs/SFX_PLAN.md for the sound side).
## Everything starts in the grading frame and settles within ~0.6 s; it only
## animates scale, position.x, styleboxes, the card shader and particles
## parented to the card, so it never changes the fitted layout, and the cards
## already carry their final state style, so synchronous callers (the harness)
## see the graded screen without waiting. Reduce motion: final icons only.
##   right:  zap sweeping upward; the check draws itself as a
##           cyan trace with a spark running down it, a solder pad pulses at
##           the tip, current runs once around the card; one light haptic tick
##   wrong:  low "short" tone; the X strokes cross with a spark pop, flicker
##           once, the pick glitches sideways; then the right card (only now)
##           gets the softer current; two soft haptic ticks
static func play_answer(host: Main, cards: Array, correct: int, selected: int) -> void:
	var is_right := selected == correct and selected >= 0
	var graded := AudioSettings.grades_answers(host.session_audio_mode)
	var calm := host.audio.reduce_motion
	host._sfx(Sfx.answer_sound(graded, is_right))
	if host.ui_mobile and graded:
		haptic(host, is_right)
	if correct >= 0 and correct < cards.size():
		var right_card: AnswerCard = cards[correct]
		if is_right:
			right_card.celebrate(calm)
		else:
			right_card.reveal_right(0.2 if selected >= 0 else 0.06, calm)
	if not is_right and selected >= 0 and selected < cards.size():
		(cards[selected] as AnswerCard).reject(calm)
	if calm:
		return
	UiFx.pop(host.pass_badge, 1.04)
	UiFx.pop(host.feedback_title, 1.06 if is_right else 1.03, 0.3, Vector2(0.0, 0.5))
	UiFx.glow_pulse(host.feedback_panel, UiFx.CYAN if is_right else AppTheme.ROSE_400, 20 if is_right else 14, 0.55)


## Android: a light tick for right, two softer ticks for wrong (the platform's
## "confirm" / "reject" patterns), never a long buzz.
static func haptic(host: Main, is_right: bool) -> void:
	if is_right:
		Input.vibrate_handheld(20, 0.45)
		return
	Input.vibrate_handheld(30, 0.35)
	if host.is_inside_tree():
		host.get_tree().create_timer(0.11).timeout.connect(func(): Input.vibrate_handheld(30, 0.35))
