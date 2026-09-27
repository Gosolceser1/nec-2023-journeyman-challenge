class_name ResultsView
extends RefCounted
## The end-of-session report: verdict, score gauge, chapter bars, missed-item
## study list, the listen-mode summary, and the pass confetti.

static func show(host: Main) -> void:
	host.timer.stop()
	host.speech._stop_reading()
	# The report is not a question: keys 1-4 / A-D must not grade anything here.
	host.current_answered = true
	clear_confetti(host)
	var is_exam := host.session_name.begins_with("Full Journeyman Exam")
	host.question_label.text = "Official Examination Report" if is_exam else "Practice Report"
	host.chapter_hint_label.visible = false
	host.lookup_box.visible = false
	host.formula_box.visible = false
	host.question_table_panel.visible = false
	host.question_diagram_panel.visible = false
	host.question_formula_label.visible = false
	host.exam_label.text = "STATE ELECTRICAL DIVISION  •  NEBRASKA (NSED / PSI)"
	host.article_label.text = "CANDIDATE PERFORMANCE SUMMARY  •  NEC 2023 STANDARDS"
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
	var passed := accuracy >= Main.PASS_PERCENT
	if passed:
		host.score_label.text = "RESULT: PASSED"
		host.score_label.add_theme_color_override("font_color", AppTheme.EMERALD_300)
		if is_instance_valid(host.pass_badge):
			host.pass_badge.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.BADGE_GREEN_BG, AppTheme.EMERALD_600, 1, 8))
	else:
		host.score_label.text = "RESULT: DID NOT PASS"
		host.score_label.add_theme_color_override("font_color", AppTheme.ROSE_300)
		if is_instance_valid(host.pass_badge):
			host.pass_badge.add_theme_stylebox_override("panel", AppTheme.panel_style(AppTheme.BADGE_RED_BG, AppTheme.ROSE_800, 1, 8))
	host.streak_label.text = "FINAL: %d/%d (%d%%)" % [host.score, total, roundi(accuracy)]
	for child in host.answers_box.get_children():
		host.answers_box.remove_child(child)
		child.queue_free()
	host.feedback_panel.visible = true
	host.feedback_reference.visible = false
	if passed:
		host.feedback_title.text = ("EXAMINATION" if is_exam else "PRACTICE") + " RESULT: PASS"
		host.feedback_title.add_theme_color_override("font_color", AppTheme.EMERALD_400)
	else:
		host.feedback_title.text = ("EXAMINATION" if is_exam else "PRACTICE") + " RESULT: DID NOT PASS"
		host.feedback_title.add_theme_color_override("font_color", AppTheme.RED_400)
	
	# The gauge and the title already state the percentage and the verdict.
	var summary_text := "%d of %d correct  •  %d%% needed to pass  •  %s" % [
		host.score, total, Main.PASS_PERCENT,
		"%d missed item%s to review below" % [host.missed_questions.size(), "" if host.missed_questions.size() == 1 else "s"] if not host.missed_questions.is_empty() else "no misses"
	]
	if unanswered > 0:
		summary_text += "  •  %d unanswered" % unanswered
	# The results screen reuses this label after it may have been hidden by a "Correct" verdict.
	host.feedback_body.text = summary_text
	host.feedback_body.visible = true
	show_visual(host, accuracy, passed)

	host.info_label.clear()
	if host.missed_questions.is_empty() and unanswered > 0:
		host.info_panel.append_heading("TIME EXPIRED\n", AppTheme.AMBER_400)
		host.info_label.add_text("Every question you reached was correct, but %d were left unanswered when the session clock ran out." % unanswered)
	elif host.missed_questions.is_empty():
		host.info_panel.append_heading("PERFECT SCORE ACHIEVED\n", AppTheme.EMERALD_400)
		host.info_label.add_text("Congratulations! You answered 100% of questions correctly. You have demonstrated full mastery of these NEC 2023 provisions.")
	else:
		host.info_panel.append_heading("AREAS FOR TARGETED CODE STUDY (%d FAILED ITEMS)\n" % host.missed_questions.size(), AppTheme.RED_400)
		host.info_label.add_text("The following questions were answered incorrectly or timed out. Review each NEC article reference carefully before retaking the test:\n\n")

		for i in host.missed_questions.size():
			var item: Dictionary = host.missed_questions[i]
			var num: int = int(item.get("index", i + 1))
			var prompt: String = str(item.get("prompt", ""))
			var selected: String = str(item.get("selected", ""))
			var correct: String = str(item.get("correct", ""))
			var article: String = str(item.get("article", "General"))
			var art_title: String = str(item.get("article_title", ""))
			var tip: String = str(item.get("tip_short", ""))

			host.info_panel.append_heading("ITEM #%d  •  NEC %s%s\n" % [num, article, " — " + art_title if art_title != "" else ""], AppTheme.SKY_300)
			host.info_label.push_color(AppTheme.SLATE_200)
			host.info_label.add_text("Question: %s\n" % prompt)
			host.info_label.pop()
			
			host.info_label.push_color(AppTheme.RED_300)
			host.info_label.add_text("Your answer:  %s\n" % selected)
			host.info_label.pop()
			
			host.info_label.push_color(AppTheme.GREEN_300)
			host.info_label.push_bold()
			host.info_label.add_text("Correct NEC answer:  %s\n" % correct)
			host.info_label.pop()
			host.info_label.pop()

			if tip != "":
				var ri := int(item.get("record_index", -1))
				if ri >= 0 and ri < host.records.size():
					host.info_panel.append_heading("Code key:  ", AppTheme.BLUE_300)
					host.info_panel.append_tip_rows(host.records[ri], tip)
					host.info_label.add_text("\n")
				else:
					host.info_label.push_color(AppTheme.BLUE_300)
					host.info_label.add_text("Code Key:  %s\n" % tip)
					host.info_label.pop()

			host.info_label.add_text("\n")

	host.info_label.visible = true
	host.feedback_table_scroll.visible = false
	host.feedback_table_note.visible = false
	host.next_button.text = "Return to Main Menu"
	host.next_button.visible = true
	host.next_button.disabled = false
	host._update_key_hint()


static func show_listen(host: Main) -> void:
	host.question_label.text = "Listening Session Summary"
	host.article_label.text = "HANDS-FREE REVIEW  •  NEC 2023 STANDARDS"
	host._update_score_badges()
	for child in host.answers_box.get_children():
		host.answers_box.remove_child(child)
		child.queue_free()
	if is_instance_valid(host.results_visual):
		host.results_visual.visible = false
	host.feedback_panel.visible = true
	host.feedback_reference.visible = false
	host.feedback_title.text = "LISTENING SESSION COMPLETE"
	host.feedback_title.add_theme_color_override("font_color", AppTheme.SKY_400)
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
		host.results_visual.add_theme_constant_override("separation", 18)
		host.result_gauge = ResultGauge.new()
		host.result_gauge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		host.result_gauge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		host.results_visual.add_child(host.result_gauge)
		host.chapter_bars = ChapterBars.new()
		host.chapter_bars.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		host.results_visual.add_child(host.chapter_bars)
		var column := host.feedback_body.get_parent()
		column.add_child(host.results_visual)
		column.move_child(host.results_visual, host.feedback_body.get_index() + 1)
	host.results_visual.visible = true
	host._results_seq += 1
	var seq := host._results_seq
	host.result_gauge.landed.connect(func(): land(host, seq, passed), CONNECT_ONE_SHOT)
	host.result_gauge.play(accuracy, float(Main.PASS_PERCENT), host.audio.reduce_motion)
	host.chapter_bars.set_rows(ChapterBars.rows_from_stats(host.chapter_stats))
	UiFx.glow_pulse(host.feedback_panel, ResultGauge.tint_for(accuracy, float(Main.PASS_PERCENT)), 30, 1.2)


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
