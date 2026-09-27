class_name QuizFx
extends RefCounted
## Quiz-screen decoration: the fx layer, streak meter and countdown gauges
## attached after the layout builders, and the answer feedback burst.

## Decoration shared by both layouts, attached after the builder ran so the two
## builders stay separate: the fx layer for particles/flashes, the streak meter
## beside the progress line, and the countdown gauges on the time badges.
static func attach(host: Main) -> void:
	host.fx_layer = UiFx.make_fx_layer()
	host.add_child(host.fx_layer)

	host.streak_meter = StreakMeter.new()
	host.streak_meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 12)
	var progress_parent := host.progress_label.get_parent()
	progress_parent.add_child(progress_row)
	progress_parent.move_child(progress_row, host.progress_label.get_index())
	host.progress_label.reparent(progress_row)
	progress_row.add_child(host.streak_meter)

	host.exam_gauge = attach_time_gauge(host, host.timer_label)
	host.pace_gauge = attach_time_gauge(host, host.question_timer_label)


static func attach_time_gauge(host: Main, label: Label) -> TimeGauge:
	var gauge := TimeGauge.new()
	var margin := label.get_parent()
	if host.ui_mobile:
		gauge.mode = TimeGauge.Mode.EDGE
		var badge := margin.get_parent()
		badge.add_child(gauge)
		badge.move_child(gauge, 0)
		return gauge
	gauge.custom_minimum_size = Vector2(18, 18)
	gauge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
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
		host.pace_gauge.set_value(float(maxi(host.question_time_left, 0)) / float(Main.SECONDS_PER_SCORED_ITEM), pace_col,
			not host.current_answered and host.question_time_left > 0 and host.question_time_left <= 30)


static func play_answer(host: Main, cards: Array, correct: int, selected: int) -> void:
	var is_right := selected == correct and selected >= 0
	host._sfx(Sfx.answer_sound(AudioSettings.grades_answers(host.session_audio_mode), is_right))
	if host.ui_mobile:
		Input.vibrate_handheld(25 if is_right else 90)
	if correct >= 0 and correct < cards.size():
		var right_card: AnswerCard = cards[correct]
		UiFx.glow_pulse(right_card, UiFx.EMERALD, 30 if is_right else 18)
		if is_right:
			var spark_at := right_card.vector_state_icon.get_global_rect().get_center()
			if quiz_view_rect(host).has_point(spark_at):
				UiFx.spark_burst(host.fx_layer, spark_at, UiFx.EMERALD)
			UiFx.screen_flash(host.fx_layer, UiFx.EMERALD, 0.07)
	if not is_right:
		UiFx.screen_flash(host.fx_layer, UiFx.RED, 0.11)
		if selected >= 0 and selected < cards.size():
			UiFx.glow_pulse(cards[selected], UiFx.RED, 24)
	UiFx.pop(host.pass_badge, 1.06)
	UiFx.pop(host.feedback_title, 1.12, 0.3)
	UiFx.glow_pulse(host.feedback_panel, UiFx.EMERALD if is_right else UiFx.RED, 22, 0.8)


## On-screen rect of the scrolling quiz column (sparks outside it would land on
## the Next button or dock).
static func quiz_view_rect(host: Main) -> Rect2:
	var n: Node = host.answers_box
	while n != null and not n is ScrollContainer:
		n = n.get_parent()
	return (n as Control).get_global_rect() if n != null else host.get_global_rect()
