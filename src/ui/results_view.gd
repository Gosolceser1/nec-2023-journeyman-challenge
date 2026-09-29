class_name ResultsView
extends RefCounted
## The end-of-session report: verdict, score gauge, chapter bars, missed-item
## study list, the listen-mode summary, and the pass confetti.

static func show(host: Main) -> void:
	host.timer.stop()
	host.speech._stop_reading()
	# The screen change; pass / fail follows when the dial lands.
	host._sfx("transition")
	# The report is not a question: keys 1-4 / A-D must not grade anything here.
	host.current_answered = true
	clear_confetti(host)
	var is_exam := host.session.session_simulation
	var state_law := host.session.session_section == BankLoader.SECTION_NE_STATE_LAW
	var provisions := "Nebraska State Electrical Act and Board Rules" if state_law else Edition.short_label()
	host.question_label.text = "Official Examination Report" if is_exam else "Practice Report"
	host.chapter_hint_label.visible = false
	host.lookup_box.visible = false
	host.formula_box.visible = false
	host.question_table_panel.visible = false
	host.question_diagram_panel.visible = false
	host.question_formula_label.visible = false
	host.exam_label.text = ExamBlueprint.authority()
	host.article_label.text = "CANDIDATE PERFORMANCE SUMMARY  •  " + ("NEBRASKA STATE ELECTRICAL ACT & BOARD RULES" if state_law else standards_label())
	if is_instance_valid(host.question_hint_row):
		host.question_hint_row.visible = true
	host.exam_pills_row.visible = not host.ui_mobile
	host.timer_bar.visible = false
	host.fit.refresh_ref_column()
	host.feedback_scroll.visible = true
	host.feedback_scroll.scroll_vertical = 0
	host.fit.apply_level(0)
	host._auto_token += 1
	if is_instance_valid(host._listen_timer):
		host._listen_timer.stop()
	host.listen_phase = AudioSettings.ListenPhase.IDLE
	host.listen_paused = false
	host._refresh_dock_audio()
	# Quiz-only chrome would contradict the report ("QUESTION 01 OF 10",
	# "Hear the rule" for a question no longer on screen, a second menu button).
	if host.ui_mobile:
		host.progress_label.text = "COMPLETE  •  %d / %d" % [host.answered_count, host.order.size()]
	else:
		host.progress_label.text = "SESSION COMPLETE  •  %d OF %d ANSWERED" % [host.answered_count, host.order.size()]
	host.question_timer_label.text = "REVIEW"
	host.question_timer_label.add_theme_color_override("font_color", AppTheme.SKY_400)
	if is_instance_valid(host.dock_panel):
		host.dock_panel.visible = false
	if host.session_audio_mode == AudioSettings.Mode.LISTEN:
		show_listen(host)
		host._update_key_hint()
		return
	# Items left unanswered when the session clock ran out count against the score.
	var total := maxi(host.answered_count, host.order.size())
	var unanswered := total - host.answered_count
	var accuracy := 100.0 * float(host.score) / maxf(1.0, float(total))
	var passed := accuracy >= ExamBlueprint.pass_percent()
	if passed:
		host.score_label.text = "RESULT: PASSED"
		host.score_label.add_theme_color_override("font_color", AppTheme.EMERALD_300)
		if is_instance_valid(host.pass_badge):
			Widgets.tint_hud_segment(host.pass_badge, AppTheme.EMERALD_400)
	else:
		host.score_label.text = "RESULT: DID NOT PASS"
		host.score_label.add_theme_color_override("font_color", AppTheme.ROSE_300)
		if is_instance_valid(host.pass_badge):
			Widgets.tint_hud_segment(host.pass_badge, AppTheme.RED_400)
	host.streak_label.text = "FINAL: %d/%d (%d%%)" % [host.score, total, roundi(accuracy)]
	for child in host.answers_box.get_children():
		host.answers_box.remove_child(child)
		child.queue_free()
	host.feedback_panel.visible = true
	host.feedback_reference.visible = false
	if passed:
		host._set_feedback_verdict(("EXAMINATION" if is_exam else "PRACTICE") + " RESULT: PASS", AppTheme.EMERALD_400, "check")
	else:
		host._set_feedback_verdict(("EXAMINATION" if is_exam else "PRACTICE") + " RESULT: DID NOT PASS", AppTheme.RED_400, "cross")
	
	# The gauge and the title already state the percentage and the verdict.
	var summary_text := "%d of %d correct  •  %d%% needed to pass  •  %s" % [
		host.score, total, ExamBlueprint.pass_percent(),
		"%d missed item%s to review below" % [host.missed_questions.size(), "" if host.missed_questions.size() == 1 else "s"] if not host.missed_questions.is_empty() else "no misses"
	]
	if unanswered > 0:
		summary_text += "  •  %d unanswered" % unanswered
	# The results screen reuses this label after it may have been hidden by a "Correct" verdict.
	host.feedback_body.text = summary_text
	host.feedback_body.visible = true
	show_visual(host, accuracy, passed)

	host.info_label.clear()
	append_study_feedback(host, is_exam, total)
	if host.missed_questions.is_empty() and unanswered > 0:
		host.info_panel.append_heading("TIME EXPIRED\n", AppTheme.AMBER_400)
		host.info_label.add_text("Every question you reached was correct, but %d %s left unanswered when the session clock ran out." % [unanswered, "was" if unanswered == 1 else "were"])
	elif host.missed_questions.is_empty():
		host.info_panel.append_heading("PERFECT SCORE ACHIEVED\n", AppTheme.EMERALD_400)
		host.info_label.add_text("Congratulations! You answered 100%% of questions correctly. You have demonstrated full mastery of these %s provisions." % provisions)
	else:
		host.info_panel.append_heading("AREAS FOR TARGETED CODE STUDY (%d FAILED ITEM%s)\n" % [host.missed_questions.size(), "" if host.missed_questions.size() == 1 else "S"], AppTheme.RED_400)
		host.info_label.add_text("The following questions were answered incorrectly or timed out. Review each %s carefully before retaking the test:\n\n" % ("cited statute or board rule" if state_law else "NEC article reference"))

		for i in host.missed_questions.size():
			var item: Dictionary = host.missed_questions[i]
			var num: int = int(item.get("index", i + 1))
			var prompt: String = str(item.get("prompt", ""))
			var selected: String = str(item.get("selected", ""))
			var correct: String = str(item.get("correct", ""))
			var article: String = str(item.get("article", "General"))
			var art_title: String = str(item.get("article_title", ""))
			var tip: String = str(item.get("tip_short", ""))

			var code := NecReference.code_label(article)
			host.info_panel.append_heading("ITEM #%d  •  %s %s%s\n" % [num, code, article, " — " + art_title if art_title != "" else ""], AppTheme.SKY_300)
			host.info_label.push_color(AppTheme.SLATE_200)
			host.info_label.add_text("Question: %s\n" % prompt)
			host.info_label.pop()
			
			host.info_label.push_color(AppTheme.RED_300)
			host.info_label.add_text("Your answer:  %s\n" % selected)
			host.info_label.pop()
			
			host.info_label.push_color(AppTheme.GREEN_300)
			host.info_label.push_bold()
			host.info_label.add_text("Correct %s answer:  %s\n" % [code, correct])
			host.info_label.pop()
			host.info_label.pop()

			if tip != "":
				var ri := int(item.get("record_index", -1))
				if ri >= 0 and ri < host.records.size():
					host.info_panel.append_heading("Code key:  ", AppTheme.BLUE_300)
					host.info_panel.append_tip_rows(host.session.display_record(ri), tip)
					host.info_label.add_text("\n")
				else:
					host.info_label.push_color(AppTheme.BLUE_300)
					host.info_label.add_text("Code key:  %s\n" % tip)
					host.info_label.pop()

			host.info_label.add_text("\n")

	host.info_label.visible = true
	host.feedback_table_scroll.visible = false
	host.feedback_table_note.visible = false
	host.next_button.text = "Return to Main Menu"
	host.next_button.visible = true
	host.next_button.disabled = false
	host._update_key_hint()


## Scored line (simulator), subject areas under the pass line, pace against
## the exam's 3:00 per item, and the readiness estimate across sessions.
static func append_study_feedback(host: Main, is_exam: bool, total: int) -> void:
	host.info_panel.append_heading("STUDY FEEDBACK\n", AppTheme.SKY_300)
	host.info_label.push_color(AppTheme.SLATE_200)
	if is_exam:
		var needed := ceili(total * ExamBlueprint.pass_percent() / 100.0)
		host.info_label.add_text("Scored line: %d of %d correct, %d needed for %d%%: %s.\n" % [host.score, total, needed, ExamBlueprint.pass_percent(), "PASS" if host.score >= needed else "DID NOT PASS"])
	var rows := ChapterBars.rows_from_areas(host.session.area_stats, float(ExamBlueprint.pass_percent()))
	var weak := PackedStringArray()
	var weakest := ""
	for row in rows:
		if row["weak"]:
			weak.append("%s %d/%d (%d%%)" % [row["label"], row["correct"], row["total"], roundi(100.0 * row["correct"] / maxf(1.0, row["total"]))])
		if row["weakest"] and weakest == "":
			weakest = str(row["label"])
	if not weak.is_empty():
		host.info_label.add_text("Below %d%%: %s. Weakest: %s.\n" % [ExamBlueprint.pass_percent(), ", ".join(weak), weakest])
	elif not rows.is_empty():
		host.info_label.add_text("Every subject area at or above %d%%.\n" % ExamBlueprint.pass_percent())
	var pace := QuizSession.pace(host.session.answer_seconds)
	if float(pace["mean"]) > 0.0:
		var line := "Pace: %s per answer (exam pace %s)." % [clock_text(pace["mean"]), clock_text(ExamBlueprint.seconds_per_item())]
		var slow := PackedStringArray()
		for n in pace["slow"]:
			slow.append("#%d" % n)
		if not slow.is_empty():
			line += " Over %s: item%s %s." % [clock_text(QuizSession.slow_seconds()), "" if slow.size() == 1 else "s", ", ".join(slow)]
		host.info_label.add_text(line + "\n")
	if host.session.session_section == BankLoader.SECTION_NEC:
		var mastery := host.session.deck.mastery(host.records)
		host.info_label.add_text("Exam readiness: %d%% (recent accuracy per subject area, weighted like the exam). Next: drill %s.\n" % [
			roundi(100.0 * QuestionDeck.readiness(mastery)), ExamBlueprint.title(QuestionDeck.weakest_area(mastery, host.records))])
	host.info_label.add_text("\n")
	host.info_label.pop()


static func clock_text(seconds: float) -> String:
	var s := roundi(seconds)
	return "%d:%02d" % [s / 60, s % 60]


## "NEC 2023 STANDARDS", the report header's code book.
static func standards_label() -> String:
	return Edition.short_label().to_upper() + " STANDARDS"


static func show_listen(host: Main) -> void:
	host.question_label.text = "Listening Session Summary"
	host.article_label.text = "HANDS-FREE REVIEW  •  " + standards_label()
	host._update_score_badges()
	for child in host.answers_box.get_children():
		host.answers_box.remove_child(child)
		child.queue_free()
	if is_instance_valid(host.results_visual):
		host.results_visual.visible = false
	host.feedback_panel.visible = true
	host.feedback_reference.visible = false
	host._set_feedback_verdict("LISTENING SESSION COMPLETE", AppTheme.SKY_400, "speaker")
	host.feedback_body.text = "Reviewed %d of %d questions hands-free.\nListen mode is not graded — run a drill in Tap or Auto-read mode to test yourself." % [host.answered_count, host.order.size()]
	host.feedback_body.visible = true
	host.info_label.clear()
	host.info_label.visible = false
	host.feedback_table_scroll.visible = false
	host.feedback_table_note.visible = false
	host.feedback_scroll.visible = false
	host.next_button.text = "Return to Main Menu"
	host.next_button.visible = true
	host.next_button.disabled = false


static func show_visual(host: Main, accuracy: float, passed: bool) -> void:
	if not is_instance_valid(host.results_visual):
		host.results_visual = VBoxContainer.new() if host.ui_mobile else HBoxContainer.new()
		host.results_visual.add_theme_constant_override("separation", AppTheme.SPACE_LG)
		host.result_gauge = ResultGauge.new()
		host.result_gauge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		host.result_gauge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		host.results_visual.add_child(host.result_gauge)
		var detail := VBoxContainer.new()
		detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		detail.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		detail.add_theme_constant_override("separation", AppTheme.SPACE_MD)
		host.results_visual.add_child(detail)
		host.chapter_bars = ChapterBars.new()
		detail.add_child(host.chapter_bars)
		var pace := PaceSparkline.new()
		pace.name = "PaceSparkline"
		detail.add_child(pace)
		var column := host.feedback_body.get_parent()
		column.add_child(host.results_visual)
		column.move_child(host.results_visual, host.feedback_body.get_index() + 1)
	host.results_visual.visible = true
	host._results_seq += 1
	var seq := host._results_seq
	host.result_gauge.landed.connect(func(): land(host, seq, passed), CONNECT_ONE_SHOT)
	host.result_gauge.play(accuracy, float(ExamBlueprint.pass_percent()), host.audio.reduce_motion)
	if host.session.area_stats.is_empty():
		host.chapter_bars.set_rows(ChapterBars.rows_from_stats(host.chapter_stats))
	else:
		host.chapter_bars.set_rows(ChapterBars.rows_from_areas(host.session.area_stats, float(ExamBlueprint.pass_percent())))
	var pace := host.chapter_bars.get_parent().get_node("PaceSparkline") as PaceSparkline
	pace.set_points(host.session.answer_seconds)
	UiFx.glow_pulse(host.feedback_panel, ResultGauge.tint_for(accuracy, float(ExamBlueprint.pass_percent())), 30, 1.2)


## The dial reached the score: the result sound plays on the landing, and a pass
## gets a bounce, a spark puff from the dial and the confetti.
static func land(host: Main, seq: int, passed: bool) -> void:
	if seq != host._results_seq or not is_instance_valid(host.results_visual) or not host.results_visual.visible:
		return
	host._sfx(Sfx.result_sound(passed))
	if not passed or host.audio.reduce_motion:
		return
	host.result_gauge.punch()
	UiFx.spark_burst(host.fx_layer, host.result_gauge.get_global_rect().get_center(), UiFx.EMERALD, 36)
	UiFx.confetti(host.fx_layer)


static func clear_confetti(host: Main) -> void:
	host._results_seq += 1
	if not is_instance_valid(host.fx_layer):
		return
	for child in host.fx_layer.get_children():
		if child is CPUParticles2D:
			child.queue_free()
