class_name StudyProgress
extends RefCounted
## What the menu remembers between launches beyond the question deck: each
## practice exam's best and last score, and the unfinished run to continue.
## Kept by exam label and question id in user://study_progress.cfg, next to
## (never inside) question_bag.cfg; no answers or choices are stored.

const PATH := "user://study_progress.cfg"

## "" keeps everything in memory only (tests).
var path := PATH
## exam label -> {"best": percent, "last": percent, "runs": count}
var exams: Dictionary = {}
## QuizSession.snapshot() of the unfinished run, or {}.
var resume_snapshot: Dictionary = {}


func _init(save_path: String = PATH) -> void:
	path = save_path
	load_state()


func load_state() -> void:
	exams = {}
	resume_snapshot = {}
	if path == "":
		return
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	var saved = cfg.get_value("exams", "by_label", {})
	if saved is Dictionary:
		for label in saved:
			var v = saved[label]
			if v is Dictionary:
				exams[str(label)] = {"best": clampi(int(v.get("best", 0)), 0, 100), "last": clampi(int(v.get("last", 0)), 0, 100), "runs": maxi(0, int(v.get("runs", 0)))}
	var snap = cfg.get_value("resume", "snapshot", {})
	if snap is Dictionary:
		resume_snapshot = snap


func save_state() -> void:
	if path == "":
		return
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", 1)
	cfg.set_value("exams", "by_label", exams)
	cfg.set_value("resume", "snapshot", resume_snapshot)
	cfg.save(path)


## A finished graded run of one practice exam.
func record_exam(label: String, right: int, total: int) -> void:
	if label == "" or total <= 0:
		return
	var pct := roundi(100.0 * right / total)
	var e: Dictionary = exams.get(label, {"best": 0, "last": 0, "runs": 0})
	e["best"] = maxi(int(e["best"]), pct) if int(e["runs"]) > 0 else pct
	e["last"] = pct
	e["runs"] = int(e["runs"]) + 1
	exams[label] = e
	save_state()


## {"best", "last", "runs"} for an exam; runs 0 when never finished.
func exam_result(label: String) -> Dictionary:
	return exams.get(label, {"best": 0, "last": 0, "runs": 0})


func set_resume(snap: Dictionary) -> void:
	resume_snapshot = snap
	save_state()


func clear_resume() -> void:
	if resume_snapshot.is_empty():
		return
	resume_snapshot = {}
	save_state()


func has_resume() -> bool:
	return not resume_snapshot.is_empty()


func reset() -> void:
	exams.clear()
	resume_snapshot = {}
	if path != "" and FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
