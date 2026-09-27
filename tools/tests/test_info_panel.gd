extends SceneTree
## info_panel_renderer.gd -- the post-answer explanation panel: which sections
## show, and where the answer chip lands.
##
##   ./Godot_v4.7.2-stable_win64_console.exe --headless --path . \
##       --script tools/tests/test_info_panel.gd

const R = preload("res://tools/tests/t_report.gd")

var t: R = R.new()


func _init() -> void:
	if not t.run_suite_body():
		return
	run()
	quit(0 if t.failures.is_empty() else 1)


func run() -> void:
	memory_tip_visibility()
	answer_chip()
	bank_sweep()
	report()


func report() -> void:
	t.report()


func render(record: Dictionary) -> String:
	var panel := InfoPanelRenderer.new()
	panel.label = RichTextLabel.new()
	var answers: Array = record.get("answers", [])
	panel.show(record, str(answers[int(record.get("correct_index", 0))]), false)
	var text := panel.label.get_parsed_text()
	panel.label.free()
	return text


## A tip with per-choice rows is never hidden as an echo: a short provision
## quoted by the notes used to hide every choice explanation (final-exam-#3-025).
func memory_tip_visibility() -> void:
	print("=== MEMORY TIP visibility ===")
	var rec := {
		"id": "t-short", "prompt": "A ___ is required.",
		"answers": ["fuse", "switch", "relay", "timer"], "correct_index": 0,
		"reference_text": "240.10 Supplementary Overcurrent Protection\nA fuse is required.",
		"choice_notes": ["240.10: a fuse is required.", "A switch is not a fuse.", "A relay is not a fuse.", "A timer is not a fuse."],
		"tip_short": "Fuse first. Correct: A — fuse. 240.10: a fuse is required. Not B: A switch is not a fuse. Not C: A relay is not a fuse. Not D: A timer is not a fuse.",
		"tip_title": "Fuses", "article": "240.10",
	}
	var text := render(rec)
	t.has(text, "MEMORY TIP — Fuses", "a tip with choice rows shows despite a short provision")
	t.has(text, "A switch is not a fuse.", "the per-choice notes are shown")
	# The plain legacy tip keeps the declutter filter.
	var legacy: Dictionary = rec.duplicate(true)
	legacy.erase("tip_short")
	legacy.erase("choice_notes")
	legacy["info_tip"] = "A fuse is required."
	t.lacks(render(legacy), "MEMORY TIP", "a plain tip that only requotes the provision stays hidden")


func answer_chip() -> void:
	print("=== answer chip ===")
	var rec := {
		"id": "t-chip", "prompt": "The copper shall form a minimum of ___ percent of the cross-sectional area.",
		"answers": ["5", "10", "15", "20"], "correct_index": 1,
		"reference_text": "310.3(B) Conductor Material\nSolid aluminum conductors 8, 10, and 12 AWG shall be made of an AA-8000 alloy. The copper shall form a minimum 10 percent of the cross-sectional area.",
		"tip_short": "", "article": "310.3(B)",
	}
	var panel := InfoPanelRenderer.new()
	panel.label = RichTextLabel.new()
	panel.show(rec, "10", false)
	var text := panel.label.get_parsed_text()
	panel.label.free()
	t.has(text, "minimum  10  percent", "the chip marks the 10 next to the blank's words")
	t.has(text, "8, 10, and 12 AWG", "the earlier 10 is left alone")


## Every record renders a MEMORY TIP when it has tip rows.
func bank_sweep() -> void:
	print("=== bank sweep ===")
	var bank = JSON.parse_string(FileAccess.get_file_as_string("res://data/question_bank.json"))
	var hidden: Array[String] = []
	var count := 0
	for rec in bank["records"]:
		if str(rec.get("tip_short", "")).find(" Correct: ") <= 0:
			continue
		count += 1
		if not render(rec).contains("MEMORY TIP"):
			hidden.append(str(rec.get("id", "")))
	t.check(count > 0, "the bank has tips with choice rows (%d)" % count)
	t.eq(hidden, [] as Array[String], "no record hides its MEMORY TIP")
