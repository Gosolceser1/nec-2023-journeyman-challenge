extends SceneTree
## Sfx: the six event cues and five interface sounds from docs/SFX_PLAN.md and
## the rules for when they play. The promises: only the planned sounds exist
## (no tick/whoosh creep), each ships as a short mono or stereo clip within its
## length budget, answers and results map to the right cue, the exam clock
## warns exactly twice, only the cue that can overlap the voice (the warning)
## is ducked by the Speech sidechain, interface sounds are one per action,
## rate-limited, gated by the Sounds setting and kept off the voice, SFX live
## on their own bus, and a missing tree/asset is a no-op.

const PLANNED := {
	"start": 0.7, "correct": 0.9, "wrong": 0.9, "warning": 1.5, "pass": 3.0, "fail": 2.5,
	"click": 0.15, "hover": 0.15, "toggle": 0.2, "select": 0.2, "transition": 0.65,
}
const UI_SOUNDS: Array[String] = ["click", "hover", "toggle", "select", "transition"]
## Auto-read waits this long after the question appears (main._schedule_auto_read),
## and the question appears after the menu's MOTION_SCREEN fade: the start cue
## must be inaudible by then so the voice never lands on it.
const AUTO_READ_DELAY := 0.45
## "Inaudible": every sample from here on is this far under the file's peak.
const TAIL_DB := -40.0
const MAX_TOTAL_KB := 1536

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
			info["data_at"] = f.get_position()
			break
		else:
			f.seek(f.get_position() + size)
	return info


## The wiring in the real app (desktop layout): one sound per action, and the
## Sounds setting silences the interface sounds too.
func _check_app() -> void:
	print("=== in the app: which press plays what ===")
	# The run turns Sounds off at the end, which saves; start from defaults.
	var cfg := "user://test_sfx_audio.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(cfg))
	var main: Main = load("res://scenes/main.tscn").instantiate()
	main.audio_cfg_path = cfg
	main.session.bag_path = ""
	root.add_child(main)
	await _wait(0.4)
	var fx := main.sfx
	check(fx.last_ui == "" and fx.last_event == "", "launch: the menu opens silently")
	var start_button: Button = main.menu.quick_button
	start_button.pressed.emit()
	await _frames()
	check(fx.last_event == Sfx.START and fx.last_ui == "", "start press: the start cue only (no click, no transition)")
	await _wait(0.5)
	check(not main.menu_overlay.visible and main.answers_box.get_child_count() > 0, "the quiz is up")
	var players := 0
	for card in main.answers_box.get_children():
		players += 1 if card is AudioStreamPlayer else 0
	check(players == 0, "no sound player inside answers_box")
	main._nav_input = true
	(main.answers_box.get_child(1) as Control).grab_focus()
	await _frames()
	check(fx.last_ui == "select", "keyboard focus onto an answer card: select")
	fx.last_ui = ""
	await _wait(0.1)
	main._nav_input = false
	(main.answers_box.get_child(2) as Control).grab_focus()
	await _frames()
	check(fx.last_ui == "", "focus from a click or tap: no select (the answer tone covers it)")
	await _wait(0.1)
	fx.last_event = ""
	main._answer_selected(0)
	await _frames()
	check(fx.last_event in ["correct", "wrong"] and fx.last_ui == "", "answer: correct / wrong only, right away")
	await _wait(0.1)
	main.mute_button.pressed.emit()
	await _frames()
	check(fx.last_ui == "toggle", "voice mute / unmute: toggle")
	await _wait(0.1)
	main.mute_button.pressed.emit()
	await _wait(0.1)
	fx.last_ui = ""
	main.next_button.pressed.emit()
	await _frames()
	check(fx.last_ui == "click" or fx.last_ui == "transition", "Next: a click (a transition if it opened the report)")
	await _wait(0.3)
	main._answer_selected(0)
	await _wait(0.1)
	fx.last_ui = ""
	main.restart_button.pressed.emit()
	await _frames()
	if main.menu_overlay.visible:
		check(fx.last_ui == "transition", "Menu with nothing to lose: the transition only")
	else:
		check(fx.last_ui == "click", "Menu, first press (arms Leave?): a click")
		await _wait(0.3)
		main.restart_button.pressed.emit()
		await _frames()
		check(main.menu_overlay.visible and fx.last_ui == "transition", "Menu, second press: back to the menu with the transition only")
	await _wait(0.3)
	fx.last_ui = ""
	start_button.mouse_entered.emit()
	await _frames()
	check(fx.last_ui == "hover", "pointer over a menu card: hover (desktop)")
	fx.last_ui = ""
	main.study_button.mouse_entered.emit()
	await _frames()
	check(fx.last_ui == "", "sweeping on to the next card at once: rate-limited")
	await _wait(0.3)
	main.menu.tiles[0].mouse_entered.emit()
	await _frames()
	check(fx.last_ui == "hover", "pointer over a menu tile: hover (desktop)")
	await _wait(0.3)
	fx.last_ui = ""
	main.menu.tab_buttons[1].pressed.emit()
	await _frames()
	check(fx.last_ui == "toggle", "a menu tab: toggle")
	main.menu_show_tab(0)
	await _wait(0.3)
	fx.last_ui = ""
	for plain: BaseButton in [main.next_button, main.restart_button, main.mute_button, main.audio_toggle_button, main.menu.tab_buttons[2]]:
		plain.mouse_entered.emit()
	await _frames()
	check(fx.last_ui == "", "pointer over plain buttons and switches: no hover (menu cards only)")
	await _wait(0.3)
	main.auto_teach_toggle.pressed.emit()
	await _frames()
	check(fx.last_ui == "toggle", "a switch in Audio & Voice: toggle")
	main._on_sfx_level_picked(-1)
	await _wait(0.3)
	fx.last_ui = ""
	fx.last_event = ""
	main.audio_toggle_button.pressed.emit()
	start_button.mouse_entered.emit()
	start_button.pressed.emit()
	await _wait(0.5)
	check(fx.last_ui == "" and fx.last_event == "", "Sounds off: no interface sound and no start cue")
	main.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(cfg))
	await _wait(0.3)


## Enough frames for a deferred call to run.
func _frames() -> void:
	await process_frame
	await process_frame


## Wall-clock wait: a SceneTree timer can fire on the first frame, whose delta
## includes the whole startup.
func _wait(seconds: float) -> void:
	var until := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		await process_frame


## Seconds until the last sample louder than TAIL_DB under the peak (16-bit PCM).
func _audible_end(path: String, info: Dictionary) -> float:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null or not info.has("data_at"):
		return INF
	f.seek(int(info["data_at"]))
	var pcm := f.get_buffer(int(info["data"]))
	var n := pcm.size() / 2
	var peak := 0
	for i in n:
		peak = maxi(peak, absi(pcm.decode_s16(i * 2)))
	var floor_amp := float(peak) * pow(10.0, TAIL_DB / 20.0)
	var last := 0
	for i in range(n - 1, -1, -1):
		if absi(pcm.decode_s16(i * 2)) > floor_amp:
			last = i
			break
	var frame_samples := maxi(1, int(info.get("channels", 1)))
	return float(last / frame_samples) / float(maxi(1, int(info.get("rate", 1))))


func _initialize() -> void:
	print("=== only the planned cues ===")
	check(Sfx.SOUNDS.size() == PLANNED.size(), "exactly %d cues (got %d)" % [PLANNED.size(), Sfx.SOUNDS.size()])
	for id in PLANNED:
		check(Sfx.SOUNDS.has(id), "map has %s" % id)
	check(Sfx.UI.size() == UI_SOUNDS.size(), "exactly %d interface sounds" % UI_SOUNDS.size())
	for id in UI_SOUNDS:
		check(Sfx.is_ui(id) and Sfx.SOUNDS.has(id), "%s is registered as an interface sound" % id)
	for id in ["start", "correct", "wrong", "warning", "pass", "fail"]:
		check(not Sfx.is_ui(id), "%s is an event cue, not an interface sound" % id)
	for cut in ["tick", "next", "menu", "streak", "confetti", "whoosh"]:
		check(not Sfx.SOUNDS.has(cut), "cut cue stays cut: %s" % cut)
		check(not FileAccess.file_exists(ProjectSettings.globalize_path(Sfx.path_for(cut))), "cut asset deleted: %s" % cut)

	print("=== assets ===")
	var total_bytes := 0
	var seconds := {}
	for id in Sfx.SOUNDS:
		var spec: Dictionary = Sfx.SOUNDS[id]
		check(float(spec["db"]) <= 0.0 and float(spec["db"]) >= -12.0, "%s: trim is a small attenuation" % id)
		check(float(spec["vary_db"]) >= 0.0 and float(spec["vary_db"]) <= 2.0, "%s: level variation stays subtle" % id)
		if id == "hover":
			check(float(spec["vary_pitch"]) >= 0.03 and float(spec["vary_pitch"]) <= 0.05, "hover: pitch varies about ±4 % per play")
		elif id == "select":
			check(float(spec["vary_pitch"]) > 0.0 and float(spec["vary_pitch"]) <= 0.03, "select (calculator keys): pitch varies up to ±3 % per play")
		else:
			check(float(spec["vary_pitch"]) == 0.0, "%s: fixed pitch (only hover and select are jittered)" % id)
		var info := _wav_info(ProjectSettings.globalize_path(Sfx.path_for(id)))
		check(not info.is_empty() and bool(info.get("ok", false)), "%s: wav file present" % id)
		if info.is_empty():
			continue
		total_bytes += int(info["bytes"])
		var channels := int(info.get("channels", 0))
		check(channels in [1, 2] and int(info.get("bits", 0)) == 16, "%s: mono or stereo 16-bit" % id)
		check(int(info.get("rate", 0)) >= 44100, "%s: full-band sample rate" % id)
		# data bytes / (2 bytes per sample * channels * rate)
		var secs := float(info.get("data", 0)) / (2.0 * float(maxi(1, channels)) * float(maxi(1, int(info.get("rate", 1)))))
		seconds[id] = secs
		var min_secs := 0.05 if Sfx.is_ui(id) else 0.1
		check(secs > min_secs and secs <= float(PLANNED.get(id, 0.0)) + 0.001, "%s: %.3f s within its %.2f s budget" % [id, secs, float(PLANNED.get(id, 0.0))])
		check(ResourceLoader.exists(Sfx.path_for(id)), "%s: imported" % id)
		if id == "start":
			seconds["start_audible"] = _audible_end(ProjectSettings.globalize_path(Sfx.path_for(id)), info)
	check(total_bytes < MAX_TOTAL_KB * 1024, "all sfx under %d KB (%d KB)" % [MAX_TOTAL_KB, total_bytes / 1024])

	print("=== answer and result cues ===")
	check(Sfx.answer_sound(true, true) == "correct", "right -> correct")
	check(Sfx.answer_sound(true, false) == "wrong", "wrong or timed out -> wrong")
	check(Sfx.answer_sound(false, true) == "" and Sfx.answer_sound(false, false) == "", "Listen mode (ungraded) is silent")
	check(Sfx.result_sound(true) == "pass" and Sfx.result_sound(false) == "fail", "results map to pass / fail")
	check(Sfx.START == "start" and Sfx.SOUNDS.has(Sfx.START), "session start -> start")
	var start_audible := float(seconds.get("start_audible", INF))
	check(start_audible < AppTheme.MOTION_SCREEN + AUTO_READ_DELAY,
		"start cue is %d dB down by %.2f s, before auto-read can begin (%.2f s)" % [TAIL_DB, start_audible, AppTheme.MOTION_SCREEN + AUTO_READ_DELAY])
	check(Widgets.START_CUE_ONSET <= AppTheme.MOTION_SCREEN, "start press motion lands inside the menu fade")
	check(float(Sfx.SOUNDS["start"]["vary_db"]) == 0.0, "start plays as-is (once per session)")

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
	check(is_equal_approx(Sfx.voice_offset_db("warning", true), Sfx.VOICE_DUCK_DB), "warning ducks under a system voice")
	for id in ["correct", "wrong", "pass", "fail", "start"]:
		check(not bool(Sfx.SOUNDS[id]["duck"]) and Sfx.voice_offset_db(id, true) == 0.0,
			"%s plays right after the voice is stopped: never ducked" % id)
	check(Sfx.VOICE_DUCK_DB <= -6.0 and Sfx.VOICE_DUCK_DB >= -10.0, "duck is audible but not a mute")
	check(is_nan(Sfx.voice_offset_db("tick", false)), "unknown id -> NAN")
	for id in UI_SOUNDS:
		check(not bool(Sfx.SOUNDS[id]["duck"]), "%s bypasses the Speech-keyed ducker (judged after the action instead)" % id)
		check(Sfx.voice_offset_db(id, false) == 0.0 and is_equal_approx(Sfx.voice_offset_db(id, true), Sfx.VOICE_DUCK_DB),
			"%s: full level alone, %d dB under a voice" % [id, Sfx.VOICE_DUCK_DB])
	check(not Sfx.plays_over_voice("hover") and Sfx.plays_over_voice("click"), "hover never plays over a voice")

	print("=== interface sound rules ===")
	check(Sfx.pick_ui(["click", "transition"]) == "transition" and Sfx.pick_ui(["transition", "click"]) == "transition", "a screen change outranks the press that caused it")
	check(Sfx.pick_ui(["hover", "click"]) == "click" and Sfx.pick_ui(["toggle", "click"]) == "toggle", "a press outranks hover; a switch sounds as a toggle")
	check(Sfx.pick_ui(["correct", "start"]) == "" and Sfx.pick_ui([]) == "", "event cues are never picked as interface sounds")
	check(not Sfx.gap_ok("hover", 0.05) and Sfx.gap_ok("hover", 0.2), "hover waits %.2f s before repeating" % float(Sfx.UI["hover"]["gap"]))
	for id in UI_SOUNDS:
		check(float(Sfx.UI[id]["gap"]) > 0.0 and float(Sfx.UI[id]["gap"]) <= 0.3, "%s has a short repeat gap" % id)

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
	check(AudioServer.get_bus_effect_count(bus) == 0, "answer/result cues bypass the ducker")
	var duck_bus := AudioServer.get_bus_index(Sfx.DUCK_BUS)
	check(duck_bus > bus and AudioServer.get_bus_send(duck_bus) == &"SFX", "duck bus feeds the SFX bus (level and Off apply)")
	check(AudioServer.get_bus_effect_count(duck_bus) == 1 and AudioServer.get_bus_effect(duck_bus, 0) is AudioEffectCompressor, "sidechain ducker on the duck bus")
	check((AudioServer.get_bus_effect(duck_bus, 0) as AudioEffectCompressor).sidechain == &"Speech", "ducker keyed by the Speech bus")
	check(s.get_child_count() == Sfx.SOUNDS.size(), "one pre-loaded player per cue")
	var hover_stream := (s.get_node("Sfx_hover") as AudioStreamPlayer).stream as AudioStreamRandomizer
	check(hover_stream != null and is_equal_approx(hover_stream.random_pitch, 1.0 + float(Sfx.SOUNDS["hover"]["vary_pitch"])),
		"hover player jitters its pitch per play")
	var click_stream := (s.get_node("Sfx_click") as AudioStreamPlayer).stream as AudioStreamRandomizer
	check(click_stream != null and click_stream.random_pitch == 1.0, "click keeps its pitch (level variation only)")
	var routed := true
	for p in s.get_children():
		var id := String(p.name).trim_prefix("Sfx_")
		routed = routed and (p as AudioStreamPlayer).bus == (Sfx.DUCK_BUS if bool(Sfx.SOUNDS[id]["duck"]) else Sfx.BUS)
	check(routed, "warning routes through the duck bus, every other cue straight to SFX")
	var correct_stream := (s.get_node("Sfx_correct") as AudioStreamPlayer).stream
	check(correct_stream is AudioStreamRandomizer and is_equal_approx((correct_stream as AudioStreamRandomizer).random_pitch, 1.0), "answer tones vary randomly in level only, never in pitch")
	check(not ((s.get_node("Sfx_pass") as AudioStreamPlayer).stream is AudioStreamRandomizer), "result cues play as-is")
	s.apply_settings(true, AudioSettings.sfx_bus_db(0))
	check(is_equal_approx(AudioServer.get_bus_volume_db(bus), AudioSettings.SFX_LEVEL_DB[0]), "level sets the bus volume")
	check(not AudioServer.is_bus_mute(bus), "on: bus unmuted")
	check(s.play("correct"), "on: correct plays (dummy driver is fine)")
	check((s.get_node("Sfx_correct") as AudioStreamPlayer).pitch_scale == 1.0, "a plain correct plays at its own pitch")
	check(not s.play("tick"), "a cut cue cannot play")
	s.voice_active = func() -> bool: return true
	check(s.play("warning"), "voice on: warning still plays, ducked")
	check(is_equal_approx((s.get_node("Sfx_warning") as AudioStreamPlayer).volume_db, float(Sfx.SOUNDS["warning"]["db"]) + Sfx.VOICE_DUCK_DB), "ducked volume applied")
	s.voice_active = Callable()

	print("=== interface sounds in tree: one per action, rate limit, voice ===")
	for id in UI_SOUNDS:
		check(s.has_node("Sfx_" + id), "%s has a pre-loaded player" % id)
	# Clear the event window left by the cues above.
	await _wait(0.1)
	s.last_ui = ""
	check(s.play("click") and s.play("transition"), "interface sounds queue for the end of the frame")
	await _frames()
	check(s.last_ui == "transition", "one action, one sound: the transition, not the click")
	s.last_ui = ""
	s.play(Sfx.START)
	s.play("transition")
	s.play("click")
	await _frames()
	check(s.last_ui == "", "start press: the start cue alone (no click, no transition)")
	await _wait(0.1)
	s.play("select")
	s.play("wrong")
	await _frames()
	check(s.last_ui == "", "answer chosen: the answer tone alone, no select")
	await _wait(0.1)
	s.play("correct")
	s.play("select")
	await _frames()
	check(s.last_ui == "", "an interface sound asked for right after an answer tone is dropped")
	await _wait(0.1)
	s.play("hover")
	await _frames()
	check(s.last_ui == "hover", "hover plays on its own")
	s.last_ui = ""
	s.play("hover")
	await _frames()
	check(s.last_ui == "", "sweeping the pointer: a second hover right away is rate-limited")
	await _wait(0.2)
	s.play("hover")
	await _frames()
	check(s.last_ui == "hover", "hover plays again after its gap")
	await _wait(0.2)
	s.last_ui = ""
	s.voice_reading = func() -> bool: return true
	s.play("hover")
	await _frames()
	check(s.last_ui == "", "no hover while a voice reads")
	s.play("toggle")
	await _frames()
	check(s.last_ui == "toggle" and is_equal_approx((s.get_node("Sfx_toggle") as AudioStreamPlayer).volume_db, Sfx.VOICE_DUCK_DB),
		"a toggle while a voice reads plays %d dB down, and never stops the voice" % Sfx.VOICE_DUCK_DB)
	s.voice_reading = Callable()
	await _wait(0.1)
	s.play("toggle")
	await _frames()
	check((s.get_node("Sfx_toggle") as AudioStreamPlayer).volume_db == 0.0, "no voice: full level again")

	print("=== the Sounds setting gates everything ===")
	await _wait(0.3)
	s.last_ui = ""
	s.play("click")
	s.apply_settings(false, AudioSettings.sfx_bus_db(1))
	await _frames()
	check(s.last_ui == "", "turning Sounds off drops a pending interface sound")
	check(AudioServer.is_bus_mute(bus), "off: bus muted")
	check(not s.play("correct"), "off: nothing plays")
	for id in UI_SOUNDS:
		check(not s.play(id), "off: %s does not play" % id)
	s.apply_settings(true, AudioSettings.sfx_bus_db(2))
	check(is_equal_approx(AudioServer.get_bus_volume_db(bus), AudioSettings.SFX_LEVEL_DB[2]) and s.play("click"), "back on: interface sounds follow the Sounds level (one bus)")
	await _frames()
	s.apply_settings(false, AudioSettings.sfx_bus_db(1))
	for p in s.get_children():
		(p as AudioStreamPlayer).stop()
	# The mixer releases stopped playbacks on its own thread; give it a beat so
	# the clean exit check (no leaked streams) stays meaningful.
	await create_timer(0.25).timeout
	host.free()
	await _check_app()

	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
