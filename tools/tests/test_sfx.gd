extends SceneTree
## Sfx: the five cues from docs/SFX_PLAN.md and the rules for when they play.
## The promises: only the planned cues exist (no click/whoosh/tick creep), each
## ships as a short mono clip within its length budget, answers and results map
## to the right cue, the exam clock warns exactly twice, the voice ducks every
## cue, SFX live on their own bus, and a missing tree/asset is a no-op.

const PLANNED := {"correct": 0.3, "wrong": 0.3, "warning": 0.8, "pass": 1.5, "fail": 1.5}

var failures: Array[String] = []
var checks := 0


func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func _wav_info(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var riff := f.get_buffer(4).get_string_from_ascii()
	f.get_32()
	var wave := f.get_buffer(4).get_string_from_ascii()
	var info := {"ok": riff == "RIFF" and wave == "WAVE", "bytes": f.get_length()}
	while f.get_position() + 8 <= f.get_length():
		var id := f.get_buffer(4).get_string_from_ascii()
		var size := f.get_32()
		if id == "fmt ":
			f.get_16()
			info["channels"] = f.get_16()
			info["rate"] = f.get_32()
			f.get_32()
			f.get_16()
			info["bits"] = f.get_16()
			f.seek(f.get_position() + size - 16)
		elif id == "data":
			info["data"] = size
			break
		else:
			f.seek(f.get_position() + size)
	return info


func _initialize() -> void:
	print("=== only the planned cues ===")
	check(Sfx.SOUNDS.size() == PLANNED.size(), "exactly %d cues (got %d)" % [PLANNED.size(), Sfx.SOUNDS.size()])
	for id in PLANNED:
		check(Sfx.SOUNDS.has(id), "map has %s" % id)
	for cut in ["click", "toggle", "tick", "next", "menu", "streak", "confetti"]:
		check(not Sfx.SOUNDS.has(cut), "cut cue stays cut: %s" % cut)
		check(not FileAccess.file_exists(ProjectSettings.globalize_path(Sfx.path_for(cut))), "cut asset deleted: %s" % cut)

	print("=== assets ===")
	var total_bytes := 0
	for id in Sfx.SOUNDS:
		var spec: Dictionary = Sfx.SOUNDS[id]
		check(float(spec["db"]) <= 0.0 and float(spec["db"]) >= -12.0, "%s: trim is a small attenuation" % id)
		check(float(spec["vary_db"]) >= 0.0 and float(spec["vary_db"]) <= 2.0, "%s: level variation stays subtle" % id)
		var info := _wav_info(ProjectSettings.globalize_path(Sfx.path_for(id)))
		check(not info.is_empty() and bool(info.get("ok", false)), "%s: wav file present" % id)
		if info.is_empty():
			continue
		total_bytes += int(info["bytes"])
		check(int(info.get("channels", 0)) == 1 and int(info.get("bits", 0)) == 16, "%s: mono 16-bit" % id)
		check(int(info.get("rate", 0)) >= 44100, "%s: full-band sample rate" % id)
		var secs := float(info.get("data", 0)) / (2.0 * float(maxi(1, int(info.get("rate", 1)))))
		check(secs > 0.1 and secs <= float(PLANNED.get(id, 0.0)) + 0.001, "%s: %.2f s within its %.2f s budget" % [id, secs, float(PLANNED.get(id, 0.0))])
		check(ResourceLoader.exists(Sfx.path_for(id)), "%s: imported" % id)
	check(total_bytes < 400 * 1024, "all sfx under 400 KB (%d KB)" % (total_bytes / 1024))

	print("=== answer and result cues ===")
	check(Sfx.answer_sound(true, true) == "correct", "right -> correct")
	check(Sfx.answer_sound(true, false) == "wrong", "wrong or timed out -> wrong")
	check(Sfx.answer_sound(false, true) == "" and Sfx.answer_sound(false, false) == "", "Listen mode (ungraded) is silent")
	check(Sfx.result_sound(true) == "pass" and Sfx.result_sound(false) == "fail", "results map to pass / fail")

	print("=== exam clock warning ===")
	var fired: Array[int] = []
	for left in range(14400, -1, -1):
		if Sfx.time_warning(true, left):
			fired.append(left)
	check(fired == [300, 60], "a 4-hour exam warns exactly at 5:00 and 1:00 (got %s)" % str(fired))
	check(not Sfx.time_warning(false, 300) and not Sfx.time_warning(false, 60), "untimed never warns")
	check(not Sfx.time_warning(true, 10) and not Sfx.time_warning(true, 1), "no per-second countdown")

	print("=== voice policy ===")
	check(Sfx.voice_offset_db("correct", false) == 0.0, "no voice: full level")
	for id in Sfx.SOUNDS:
		check(is_equal_approx(Sfx.voice_offset_db(id, true), Sfx.VOICE_DUCK_DB), "%s ducks under the voice" % id)
	check(Sfx.VOICE_DUCK_DB <= -8.0, "duck is substantial")
	check(is_nan(Sfx.voice_offset_db("click", false)), "unknown id -> NAN")

	print("=== instance: no tree is a no-op ===")
	var loose := Sfx.new()
	check(not loose.play("correct"), "no tree, no players: play is a no-op")
	loose.free()

	print("=== instance in tree: bus, players, settings ===")
	var host := Node.new()
	root.add_child(host)
	var s := Sfx.new()
	host.add_child(s)
	s.setup()
	await process_frame
	check(s.is_inside_tree(), "sfx node entered the tree")
	var bus := AudioServer.get_bus_index(Sfx.BUS)
	check(bus >= 0, "SFX bus created")
	check(AudioServer.get_bus_send(bus) == &"Master", "SFX bus sends to Master")
	check(AudioServer.get_bus_effect_count(bus) == 1 and AudioServer.get_bus_effect(bus, 0) is AudioEffectCompressor, "sidechain ducker on the bus")
	check((AudioServer.get_bus_effect(bus, 0) as AudioEffectCompressor).sidechain == &"Speech", "ducker keyed by the Speech bus")
	check(s.get_child_count() == Sfx.SOUNDS.size(), "one pre-loaded player per cue")
	var all_on_bus := true
	for p in s.get_children():
		all_on_bus = all_on_bus and (p as AudioStreamPlayer).bus == Sfx.BUS
	check(all_on_bus, "every player routes to the SFX bus")
	var correct_stream := (s.get_node("Sfx_correct") as AudioStreamPlayer).stream
	check(correct_stream is AudioStreamRandomizer and is_equal_approx((correct_stream as AudioStreamRandomizer).random_pitch, 1.0), "answer tones vary in level, never in pitch")
	check(not ((s.get_node("Sfx_pass") as AudioStreamPlayer).stream is AudioStreamRandomizer), "result cues play as-is")
	s.apply_settings(true, AudioSettings.sfx_bus_db(0))
	check(is_equal_approx(AudioServer.get_bus_volume_db(bus), AudioSettings.SFX_LEVEL_DB[0]), "level sets the bus volume")
	check(not AudioServer.is_bus_mute(bus), "on: bus unmuted")
	check(s.play("correct"), "on: correct plays (dummy driver is fine)")
	check(not s.play("click"), "a cut cue cannot play")
	s.voice_active = func() -> bool: return true
	check(s.play("warning"), "voice on: warning still plays, ducked")
	check(is_equal_approx((s.get_node("Sfx_warning") as AudioStreamPlayer).volume_db, float(Sfx.SOUNDS["warning"]["db"]) + Sfx.VOICE_DUCK_DB), "ducked volume applied")
	s.voice_active = Callable()
	s.apply_settings(false, AudioSettings.sfx_bus_db(1))
	check(AudioServer.is_bus_mute(bus), "off: bus muted")
	check(not s.play("correct"), "off: nothing plays")
	for p in s.get_children():
		(p as AudioStreamPlayer).stop()
	# The mixer releases stopped playbacks on its own thread; give it a beat so
	# the clean exit check (no leaked streams) stays meaningful.
	await create_timer(0.25).timeout
	host.free()

	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
