extends SceneTree
## Sound and motion polish. The promises: every cue ships at its role's
## loudness (event cues well over the interface sounds, hover quietest), under
## a -1 dBFS peak, starting and ending at silence (no click); quick repeats of
## the busy interface sounds recede; the shared motion helpers restart instead
## of stacking and do nothing under Reduce motion; the calculator dips its keys
## and rings the correct tone only for a guided row that matched; and the Math
## Trainer never plays the exam-clock warning or the wrong tone for a press
## that is not an answer.
##
##   Godot --headless --path . --script tools/tests/test_motion_polish.gd

## Max momentary loudness (LUFS) per cue: mirrors TARGET_LUFS in
## tools/sfx/polish_sfx.py, which levels the files.
const TARGET_LUFS := {
	"start": -18.5, "correct": -17.0, "wrong": -17.0, "warning": -17.0, "pass": -16.0, "fail": -17.0,
	"click": -24.0, "toggle": -24.0, "select": -24.0, "transition": -24.0, "hover": -27.0,
}
const LUFS_TOL := 1.0
const PEAK_CEILING_DB := -0.9
## First and last sample, as a share of the file's peak.
const EDGE_MAX := 0.01

var failures: Array[String] = []
var checks := 0


func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func _frames(n: int = 2) -> void:
	for i in n:
		await process_frame


func _wait(seconds: float) -> void:
	var until := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		await process_frame


## {rate, channels, frames: Array[PackedFloat32Array] per channel} of a 16-bit WAV.
func _read_wav(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	f.seek(12)
	var rate := 0
	var channels := 0
	while f.get_position() + 8 <= f.get_length():
		var id := f.get_buffer(4).get_string_from_ascii()
		var size := f.get_32()
		if id == "fmt ":
			f.get_16()
			channels = f.get_16()
			rate = f.get_32()
			f.seek(f.get_position() + size - 8)
		elif id == "data":
			var pcm := f.get_buffer(size)
			var n := pcm.size() / (2 * channels)
			var chans: Array[PackedFloat32Array] = []
			for c in channels:
				var ch := PackedFloat32Array()
				ch.resize(n)
				chans.append(ch)
			for i in n:
				for c in channels:
					chans[c][i] = pcm.decode_s16((i * channels + c) * 2) / 32768.0
			return {"rate": rate, "channels": channels, "data": chans}
		else:
			f.seek(f.get_position() + size)
	return {}


## RBJ biquad, as tools/sfx/make_sfx.py builds the BS.1770 K-weighting.
func _biquad(x: PackedFloat32Array, b: Array, a: Array) -> PackedFloat32Array:
	var y := PackedFloat32Array()
	y.resize(x.size())
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0
	for i in x.size():
		var xi := x[i]
		var yi: float = b[0] * xi + b[1] * x1 + b[2] * x2 - a[0] * y1 - a[1] * y2
		x2 = x1
		x1 = xi
		y2 = y1
		y1 = yi
		y[i] = yi
	return y


func _k_weight(x: PackedFloat32Array, rate: int) -> PackedFloat32Array:
	# High shelf +4 dB at 1681.97 Hz, Q 0.7071.
	var big_a := pow(10.0, 4.0 / 40.0)
	var w := TAU * 1681.97 / rate
	var alpha := sin(w) / (2.0 * 0.7071)
	var c := cos(w)
	var sa := 2.0 * sqrt(big_a) * alpha
	var a0 := (big_a + 1) - (big_a - 1) * c + sa
	var shelf := _biquad(x,
		[big_a * ((big_a + 1) + (big_a - 1) * c + sa) / a0, -2 * big_a * ((big_a - 1) + (big_a + 1) * c) / a0, big_a * ((big_a + 1) + (big_a - 1) * c - sa) / a0],
		[2 * ((big_a - 1) - (big_a + 1) * c) / a0, ((big_a + 1) - (big_a - 1) * c - sa) / a0])
	# High pass at 38.135 Hz, Q 0.5003.
	w = TAU * 38.135 / rate
	alpha = sin(w) / (2.0 * 0.5003)
	c = cos(w)
	a0 = 1 + alpha
	return _biquad(shelf, [(1 + c) / 2 / a0, -(1 + c) / a0, (1 + c) / 2 / a0], [-2 * c / a0, (1 - alpha) / a0])


## Max 400 ms K-weighted loudness, channel powers summed (measure_sfx.py).
func _lufs(wav: Dictionary) -> float:
	var rate: int = wav["rate"]
	var win := int(rate * 0.4)
	var total := 0.0
	for ch: PackedFloat32Array in wav["data"]:
		var k := _k_weight(ch, rate)
		var sq := PackedFloat64Array()
		sq.resize(maxi(k.size(), win) + 1)
		for i in k.size():
			sq[i + 1] = sq[i] + k[i] * k[i]
		for i in range(k.size() + 1, sq.size()):
			sq[i] = sq[i - 1]
		var best := 0.0
		for i in range(win, sq.size()):
			best = maxf(best, (sq[i] - sq[i - win]) / win)
		total += best
	return -0.691 + 10.0 * log(maxf(total, 1e-12)) / log(10.0)


func _check_levels() -> void:
	print("=== every cue at its role's loudness, clean edges ===")
	check(TARGET_LUFS.size() == Sfx.SOUNDS.size(), "a loudness target for every cue")
	var level := {}
	for id in Sfx.SOUNDS:
		check(TARGET_LUFS.has(id), "%s has a loudness target" % id)
		var wav := _read_wav(ProjectSettings.globalize_path(Sfx.path_for(id)))
		check(not wav.is_empty(), "%s.wav reads" % id)
		if wav.is_empty() or not TARGET_LUFS.has(id):
			continue
		var loud := _lufs(wav)
		level[id] = loud
		check(absf(loud - float(TARGET_LUFS[id])) <= LUFS_TOL, "%s: %.1f LUFS, target %.1f" % [id, loud, float(TARGET_LUFS[id])])
		var peak := 0.0
		var head := 0.0
		var tail := 0.0
		for ch: PackedFloat32Array in wav["data"]:
			for v in ch:
				peak = maxf(peak, absf(v))
			head = maxf(head, absf(ch[0]))
			tail = maxf(tail, absf(ch[ch.size() - 1]))
		check(20.0 * log(peak) / log(10.0) <= PEAK_CEILING_DB, "%s: peak %.1f dBFS under the ceiling" % [id, 20.0 * log(peak) / log(10.0)])
		check(head <= peak * EDGE_MAX and tail <= peak * EDGE_MAX, "%s: starts and ends at silence (no click)" % id)
	if level.size() == Sfx.SOUNDS.size():
		var quietest_event := INF
		var loudest_ui := -INF
		for id in level:
			if Sfx.is_ui(id):
				loudest_ui = maxf(loudest_ui, level[id])
			else:
				quietest_event = minf(quietest_event, level[id])
		check(quietest_event - loudest_ui >= 4.0, "event cues sit at least 4 LU over the interface sounds")
		for id in Sfx.UI:
			check(id == "hover" or level["hover"] < level[id], "hover is quieter than %s" % id)


func _check_repeats() -> void:
	print("=== quick repeats recede ===")
	check(Sfx.repeat_db("select", 0) == 0.0 and Sfx.repeat_db("click", 0) == 0.0, "a first press plays in full")
	check(is_equal_approx(Sfx.repeat_db("select", 1), Sfx.REPEAT_STEP_DB), "a quick second press is a step down")
	check(Sfx.repeat_db("select", 50) == Sfx.REPEAT_FLOOR_DB and Sfx.REPEAT_FLOOR_DB >= -6.0, "never below the floor, which stays audible")
	check(Sfx.repeat_db("toggle", 3) == 0.0 and Sfx.repeat_db("transition", 3) == 0.0, "toggles and screen changes always play in full")
	check(Sfx.repeat_db("correct", 3) == 0.0, "event cues are never softened")
	var host := Node.new()
	root.add_child(host)
	var s := Sfx.new()
	host.add_child(s)
	s.setup()
	s.apply_settings(true, 0.0)
	await _frames()
	var select := s.get_node("Sfx_select") as AudioStreamPlayer
	check(select.stream is AudioStreamRandomizer and (select.stream as AudioStreamRandomizer).random_pitch > 1.0,
		"select (calculator keys) varies its pitch a little per press")
	var vols: Array[float] = []
	for i in 4:
		s.play("select")
		await _frames()
		vols.append(select.volume_db)
		await _wait(0.08)
	check(vols[0] == 0.0 and vols[1] < vols[0] and vols[2] < vols[1] and vols[3] >= Sfx.REPEAT_FLOOR_DB, "typing fast: each key a little softer (%s)" % str(vols))
	await _wait(Sfx.REPEAT_WINDOW + 0.1)
	s.play("select")
	await _frames()
	check(select.volume_db == 0.0, "after a pause the next key is full level again")
	s.apply_settings(false, 0.0)
	for p in s.get_children():
		(p as AudioStreamPlayer).stop()
	await create_timer(0.25).timeout
	host.free()


func _check_motion() -> void:
	print("=== shared motion helpers ===")
	check(AppTheme.MOTION_FAST < AppTheme.MOTION_NORMAL and AppTheme.MOTION_NORMAL < AppTheme.MOTION_SLOW, "fast < normal < slow")
	check(AppTheme.MOTION_SCREEN <= AppTheme.MOTION_NORMAL, "screen entrances stay short")
	var box := VBoxContainer.new()
	box.size = Vector2(300, 200)
	root.add_child(box)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 80)
	box.add_child(panel)
	await _frames()
	UiFx.reduce_motion = false
	var first := UiFx.reveal(panel, false)
	check(first != null and panel.modulate.a == 0.0 and panel.scale.x < 1.0, "reveal starts faded and slightly small")
	var second := UiFx.reveal(panel, false)
	check(not first.is_valid() and second.is_valid(), "a second reveal restarts it instead of stacking")
	await _wait(AppTheme.MOTION_NORMAL + 0.1)
	check(panel.modulate.a == 1.0 and panel.scale == Vector2.ONE and panel.pivot_offset == panel.size * 0.5, "reveal settles at rest, scaled about its centre")
	var e1 := UiFx.screen_enter(panel, false)
	var e2 := UiFx.screen_enter(panel, false)
	check(not e1.is_valid() and e2.is_valid(), "a second screen entrance restarts it")
	await _wait(AppTheme.MOTION_SCREEN + 0.1)
	check(panel.position.x == 0.0 and panel.modulate.a == 1.0, "the entrance ends in the slot")
	UiFx.press_scale(panel, AppTheme.PRESS_SCALE)
	await _wait(AppTheme.MOTION_FAST + 0.05)
	check(is_equal_approx(panel.scale.x, AppTheme.PRESS_SCALE), "held: dips to the press scale")
	UiFx.press_scale(panel, 1.0)
	await _wait(AppTheme.MOTION_FAST + 0.05)
	check(panel.scale == Vector2.ONE, "released: back to rest")
	UiFx.shake(panel)
	await _frames(3)
	check(panel.position.x != 0.0, "shake moves sideways")
	await _wait(AppTheme.MOTION_SLOW + 0.1)
	check(panel.position.x == 0.0, "shake settles in the slot")
	var bars := ChapterBars.new()
	box.add_child(bars)
	bars.set_rows([{"label": "Ch 1", "correct": 1, "total": 2, "weak": true, "weakest": true}])
	check(bars._grow == 0.0, "chapter bars grow in")

	print("=== Reduce motion: nothing moves ===")
	UiFx.reduce_motion = true
	check(UiFx.reveal(panel, true) == null and panel.modulate.a == 1.0 and panel.scale == Vector2.ONE, "reveal shows at once")
	UiFx.press_scale(panel, AppTheme.PRESS_SCALE)
	check(panel.scale == Vector2.ONE, "no press dip")
	UiFx.tap(panel)
	check(panel.scale == Vector2.ONE, "no keyboard tap dip")
	UiFx.shake(panel)
	await _frames(3)
	check(panel.position.x == 0.0, "no shake")
	bars.set_rows([{"label": "Ch 2", "correct": 2, "total": 2, "weak": false, "weakest": false}])
	check(bars._grow == 1.0, "chapter bars drawn full at once")
	var card := AnswerCard.new()
	box.add_child(card)
	await _frames()
	card.set_speaking(true)
	await _wait(AppTheme.MOTION_FAST + 0.05)
	check(card.scale == Vector2.ONE and card.position.x == 0.0, "the reading card stays still")
	card.set_speaking(false)
	UiFx.reduce_motion = false
	box.free()


func _check_pad() -> void:
	print("=== calculator: key dips, guided row tones ===")
	var heard: Array[String] = []
	var pad := CalcPad.new()
	pad.sfx = func(id: String) -> void: heard.append(id)
	root.add_child(pad)
	await _frames()
	pad.press("7")
	check(pad.key_button("7").has_meta("_press_tween"), "a typed key dips on screen")
	check(heard == ["select"], "a key press is the select sound")
	await _wait(AppTheme.MOTION_FAST * 2.0)
	check(pad.key_button("7").scale == Vector2.ONE, "and springs back")
	var finished: Array = []
	pad.guide_finished.connect(func(m: bool) -> void: finished.append(m))
	pad.guide("6 × 7 =", [], ["42"])
	heard.clear()
	for k in CalcEngine.sequence_keys("6 × 7 ="):
		pad.press(k)
	check(finished == [true] and heard.back() == "correct", "a guided row that matches ends on the correct tone")
	pad.guide("6 × 7 =", [], ["40"])
	heard.clear()
	for k in CalcEngine.sequence_keys("6 × 7 ="):
		pad.press(k)
	check(finished == [true, false] and not heard.has("correct") and not heard.has("wrong"), "a mismatch gets no answer tone")
	pad.free()


func _check_trainer() -> void:
	print("=== Math Trainer: tones only for answers ===")
	MathHub.stats_path = "user://test_motion_polish_stats.cfg"
	MathStats.new(MathHub.stats_path).reset()
	var cfg := "user://test_motion_polish_audio.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(cfg))
	var main: Main = load("res://scenes/main.tscn").instantiate()
	main.audio_cfg_path = cfg
	main.session.bag_path = ""
	root.add_child(main)
	await _wait(0.4)
	MathHub.open(main, "trainer")
	var hub := main.get_node("MathHub") as MathHub
	hub.push("Find current", "OHMS", MathTrainerView.solve.bind(hub, "ohms", "ohm_current"))
	await _wait(0.4)
	var view := hub.current_screen() as MathTrainerView
	main.sfx.last_event = ""
	main.sfx.last_ui = ""
	view._on_check()
	await _frames()
	check(main.sfx.last_event == "" and main.sfx.last_ui == "click", "Check with nothing entered: a click, not the clock warning")
	check(view._pad.modulate.a == 1.0 and not view.answered, "the pad stays visible and unanswered")
	await _wait(0.6)
	view._show_steps()
	await _frames()
	check(main.sfx.last_event == "" and view.answered, "Steps before answering: counted as a miss without the wrong tone")
	main.free()
	MathStats.new(MathHub.stats_path).reset()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(cfg))
	await _wait(0.3)


## A practice test, not a game: no streak count, badge, pitch rise or bigger
## celebration, and a save written while there was one still resumes.
func _check_no_streak() -> void:
	print("=== no streak ===")
	check(not (Sfx as Script).get_script_constant_map().has("STREAK_SEMITONES"), "no streak pitch table")
	for m in (Sfx as Script).get_script_method_list():
		check(not str(m["name"]).begins_with("streak"), "no %s on Sfx" % m["name"])
	var bar := ProgressSegments.new()
	check(not ("streak" in bar), "the progress bar has no streak (no bolt, full width)")
	bar.free()
	var s := QuizSession.new()
	check(not ("streak" in s), "the session keeps no streak")
	var recs := []
	for i in 3:
		recs.append({"id": "r%d" % i, "prompt": "Q", "answers": ["a", "b", "c", "d"], "correct_index": 0, "article": "NEC 210.8"})
	s.records = recs
	s.begin(3, 540, true, "Practice")
	s.submit(0, true)
	var snap := s.snapshot()
	check(not snap.is_empty() and not snap.has("streak"), "a new save has no streak key")
	snap["streak"] = 4
	var resumed := QuizSession.new()
	resumed.records = recs
	check(resumed.restore(snap) and resumed.score == s.score and resumed.current_index == 1 and resumed.answered_count == 1,
		"an old save with a streak key still resumes")


func _initialize() -> void:
	_check_no_streak()
	_check_levels()
	await _check_repeats()
	await _check_motion()
	await _check_pad()
	await _check_trainer()
	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
