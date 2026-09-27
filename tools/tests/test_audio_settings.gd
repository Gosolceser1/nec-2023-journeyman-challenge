extends SceneTree
## AudioSettings: the menu's audio modes and the pure rules deciding when the
## app may speak. The critical promises: Silent is the default, nothing
## narrates the answer before answering, the simulator never autoplays, and a
## stale or hand-edited config cannot push playback out of range.

var failures: Array[String] = []
var checks := 0

func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func _init() -> void:
	var M := AudioSettings.Mode
	print("=== defaults ===")
	var fresh := AudioSettings.new()
	check(fresh.mode == M.SILENT, "default mode is Silent")
	check(is_equal_approx(fresh.speed, 1.0), "default speed 1.0")
	check(AudioSettings.THINK_PAUSES.has(fresh.think_pause), "default think pause is an offered value")
	check(AudioSettings.starts_muted(M.SILENT) and not AudioSettings.starts_muted(M.TAP), "only Silent starts muted")

	print("=== autoplay rules ===")
	check(not AudioSettings.autoplays_question(M.SILENT), "Silent never autoplays")
	check(not AudioSettings.autoplays_question(M.TAP), "Tap never autoplays")
	check(AudioSettings.autoplays_question(M.AUTO), "Auto-read autoplays the question")
	check(AudioSettings.autoplays_question(M.LISTEN), "Listen autoplays the question")
	check(not AudioSettings.autoplays_teach(M.AUTO, false), "Auto-read without the rule option stays quiet after answering")
	check(AudioSettings.autoplays_teach(M.AUTO, true), "Auto-read with the rule option reads it")
	check(AudioSettings.autoplays_teach(M.LISTEN, false), "Listen always reads the rule")
	check(not AudioSettings.autoplays_teach(M.TAP, true), "Tap never autoplays the rule")
	check(not AudioSettings.grades_answers(M.LISTEN), "Listen is not graded")
	for m in [M.SILENT, M.TAP, M.AUTO]:
		check(AudioSettings.grades_answers(m), "mode %d is graded" % m)

	print("=== simulator stays exam-quiet ===")
	check(AudioSettings.session_mode(M.AUTO, true) == M.TAP, "exam: Auto -> Tap")
	check(AudioSettings.session_mode(M.LISTEN, true) == M.TAP, "exam: Listen -> Tap")
	check(AudioSettings.session_mode(M.SILENT, true) == M.SILENT, "exam: Silent stays Silent")
	check(AudioSettings.session_mode(M.LISTEN, false) == M.LISTEN, "drill keeps Listen")

	print("=== listen loop ===")
	var P := AudioSettings.ListenPhase
	var phase: int = P.QUESTION
	var seen: Array = []
	for i in 4:
		seen.append(phase)
		phase = AudioSettings.listen_next(phase)
	check(seen == [P.QUESTION, P.THINK, P.TEACH, P.GAP], "phase order: question, think, teach, gap")
	check(phase == P.QUESTION, "loop returns to QUESTION")
	check(AudioSettings.listen_next(P.IDLE) == P.IDLE, "IDLE stays idle")

	print("=== sanitizing ===")
	check(AudioSettings.sanitize_mode(7) == M.SILENT, "out-of-range mode -> Silent")
	check(AudioSettings.sanitize_mode("listen") == M.SILENT, "non-numeric mode -> Silent")
	check(AudioSettings.sanitize_mode(3.0) == M.LISTEN, "float mode accepted")
	check(is_equal_approx(AudioSettings.sanitize_speed(4.0), 1.3), "speed snaps down to max")
	check(is_equal_approx(AudioSettings.sanitize_speed(0.2), 0.9), "speed snaps up to min")
	check(is_equal_approx(AudioSettings.sanitize_speed(1.1), 1.15), "speed snaps to nearest")
	check(is_equal_approx(AudioSettings.sanitize_speed("fast"), 1.0), "garbage speed -> 1.0")
	check(AudioSettings.sanitize_pause(12) == 10, "pause snaps to nearest")
	check(AudioSettings.sanitize_pause(null) == 10, "missing pause -> 10")
	check(is_equal_approx(AudioSettings.pitch_compensation(1.25), 0.8), "pitch compensation is 1/speed")
	check(is_equal_approx(AudioSettings.pitch_compensation(1.0), 1.0), "no compensation at 1.0")
	check(AudioSettings.speed_label(1.0) == "1×" and AudioSettings.speed_label(1.15) == "1.15×", "speed labels")

	print("=== sound effects settings ===")
	check(fresh.sfx_enabled, "sound effects default on")
	check(fresh.sfx_level == AudioSettings.SFX_DEFAULT_LEVEL and fresh.sfx_level < AudioSettings.SFX_LEVEL_DB.size() - 1, "default level is below the loudest")
	check(AudioSettings.SFX_LEVEL_TITLES.size() == AudioSettings.SFX_LEVEL_DB.size(), "a title per level")
	var sorted_db := AudioSettings.SFX_LEVEL_DB.duplicate()
	sorted_db.sort()
	check(sorted_db == AudioSettings.SFX_LEVEL_DB and AudioSettings.SFX_LEVEL_DB[-1] <= 0.0, "levels rise and never boost")
	check(AudioSettings.sanitize_sfx_level(9) == 2 and AudioSettings.sanitize_sfx_level(-4) == 0, "level clamps")
	check(AudioSettings.sanitize_sfx_level("loud") == AudioSettings.SFX_DEFAULT_LEVEL, "garbage level -> default")
	check(AudioSettings.sanitize_sfx_level(1.4) == 1, "float level rounds")
	check(is_equal_approx(AudioSettings.sfx_bus_db(0), AudioSettings.SFX_LEVEL_DB[0]), "bus dB follows level")
	check(AudioSettings.sfx_label(true, 1) == "Sounds medium" and AudioSettings.sfx_label(false, 2) == "Sounds off", "summary labels")
	check(AudioSettings.starts_muted(M.SILENT) and fresh.sfx_enabled, "Silent voice mode leaves sound effects alone")

	print("=== persistence ===")
	var path := "user://test_audio_settings.cfg"
	var a := AudioSettings.new()
	a.mode = M.LISTEN
	a.speed = 1.15
	a.think_pause = 15
	a.auto_teach = false
	a.sfx_enabled = false
	a.sfx_level = 2
	check(a.save_to(path) == OK, "save ok")
	var b := AudioSettings.new()
	b.load_from(path)
	check(b.mode == M.LISTEN and is_equal_approx(b.speed, 1.15) and b.think_pause == 15 and not b.auto_teach, "round trip")
	check(not b.sfx_enabled and b.sfx_level == 2, "sound effects round trip")
	var junk := ConfigFile.new()
	junk.set_value("audio", "mode", 42)
	junk.set_value("audio", "speed", 9.0)
	junk.set_value("audio", "think_pause", -3)
	junk.set_value("audio", "auto_teach", "yes")
	junk.set_value("audio", "sfx_enabled", "no")
	junk.set_value("audio", "sfx_level", 99)
	junk.save(path)
	var c := AudioSettings.new()
	c.load_from(path)
	check(c.mode == M.SILENT and is_equal_approx(c.speed, 1.3) and c.think_pause == 5 and c.auto_teach, "junk config sanitized")
	check(c.sfx_enabled and c.sfx_level == 2, "junk sound settings sanitized")
	var old := ConfigFile.new()
	old.set_value("audio", "mode", M.TAP)
	old.save(path)
	var e := AudioSettings.new()
	e.load_from(path)
	check(e.sfx_enabled and e.sfx_level == AudioSettings.SFX_DEFAULT_LEVEL, "config from before sound effects gets the defaults")
	var legacy := ConfigFile.new()
	legacy.set_value("audio", "mode", M.AUTO)
	legacy.set_value("audio", "auto_teach", false)
	legacy.save(path)
	var f := AudioSettings.new()
	f.load_from(path)
	check(f.mode == M.AUTO and f.auto_teach, "an unversioned config's auto_teach=false (the old default) migrates to on")
	check(AudioSettings.autoplays_teach(f.mode, f.auto_teach), "migrated Auto-read config reads the rule after answering")
	f.save_to(path)
	var reread := ConfigFile.new()
	reread.load(path)
	check(int(reread.get_value("audio", "version", 0)) == AudioSettings.CONFIG_VERSION, "save stamps the config version")
	f.auto_teach = false
	f.save_to(path)
	var g := AudioSettings.new()
	g.load_from(path)
	check(not g.auto_teach, "turning the rule off AFTER migration is respected")
	var d := AudioSettings.new()
	d.load_from("user://does_not_exist_audio.cfg")
	check(d.mode == M.SILENT, "missing config keeps defaults")

	print("=== reduce motion ===")
	var calm_cfg := AudioSettings.new()
	check(calm_cfg.reduce_motion == AudioSettings.system_reduce_motion() and not calm_cfg.reduce_motion_picked, "follows the system setting until picked")
	calm_cfg.save_to(path)
	var untouched := ConfigFile.new()
	untouched.load(path)
	check(not untouched.has_section_key("display", "reduce_motion"), "an unpicked value is not saved, so a later system change still applies")
	calm_cfg.reduce_motion = not AudioSettings.system_reduce_motion()
	calm_cfg.reduce_motion_picked = true
	calm_cfg.save_to(path)
	var picked := AudioSettings.new()
	picked.load_from(path)
	check(picked.reduce_motion_picked and picked.reduce_motion == calm_cfg.reduce_motion, "a picked value survives a restart, even against the system")
	var bad := ConfigFile.new()
	bad.set_value("display", "reduce_motion", "yes")
	bad.save(path)
	var sane := AudioSettings.new()
	sane.load_from(path)
	check(not sane.reduce_motion_picked and sane.reduce_motion == AudioSettings.system_reduce_motion(), "junk value falls back to the system setting")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
