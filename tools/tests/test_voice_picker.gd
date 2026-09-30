extends SceneTree
## Mobile voice picker with a device that reports hundreds of voices.
##
## WHY THIS EXISTS: on Android, choosing a voice froze the app. The picker was
## an OptionButton whose PopupMenu only reacts to mouse events, and the app
## turns mouse emulation off, so the list opened and then took no tap, no
## scroll and no tap-outside: every touch went to a popup that never closed
## (Back then quit the app from the menu). Opening it also queried the OS voice
## list twice (a binder call on Android) and rebuilt every row. Now the list is
## queried once and cached, filtered and capped, and shown in a VoiceSheet that
## builds its rows a batch per frame; a pick is applied once, without
## re-entering itself.
##
##   Godot --headless --path . --script tools/tests/test_voice_picker.gd

const FakeEdge = preload("res://tools/tests/fake_edge_server.gd")
const SpeechText = preload("res://src/speech/speech_text.gd")
const FAKE_COUNT := 450
## Opening the sheet and picking a voice must each take less than this.
const BUDGET_MSEC := 150

var failures: Array[String] = []
var checks := 0
var main: Main
var fake: Array = []
var source_calls := [0]
var _picker_done := false


func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func _wait(sec: float) -> void:
	await create_timer(sec).timeout
	await process_frame


func _initialize() -> void:
	if not "--mobile-ui" in OS.get_cmdline_user_args():
		print("=== VOICE NAMES AND US-ONLY LIST (pure) ===")
		_catalog_cases()
		# ui_mobile comes from the command line, so the picker half runs as a child.
		var out: Array = []
		var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ".", "--script",
			"tools/tests/test_voice_picker.gd", "--", "--mobile-ui"], out, true)
		for line in "".join(out).split("\n"):
			if line.begins_with("  ") or line.begins_with("==="):
				print(line)
		check(code == 0, "the mobile voice picker checks pass (exit %d)" % code)
	else:
		await _picker_cases()
		# A script error ends a coroutine early without failing anything.
		check(_picker_done, "the mobile picker cases ran to the end")
	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	for f in failures:
		print("  - %s" % f)
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)


## What a Google TTS phone reports, shuffled: the eight named en-US codes (Male 3
## online only), an unconfirmed code, the en-US default, and hundreds of voices
## in other locales (including en-GB, en-AU, en-IN and es-US) that must stay out.
const US_ROWS := 10  # Female 1-5, Male 1-2, Voice A offline; Male 3 online; System default
const EDGE := 11  # the en-US Edge voices from data/voices.json, Andrew aside

func _fake_voices() -> Array:
	var out: Array = []
	for code in ["tpc", "iob", "iog", "tpf", "sfg", "iom", "iol"]:
		for kind in ["network", "local"]:
			out.append(_voice("en-us-x-%s-%s" % [code, kind], "en_US"))
	out.append(_voice("en-us-x-tpd-network", "en_US"))
	out.append(_voice("en-us-x-msm00013-local", "en_US"))
	out.append(_voice("en-US-language", "en_US"))
	var langs := ["en_GB", "en_AU", "en_IN", "es_US", "de_DE", "fr_FR", "es_ES", "hi_IN", "ja_JP"]
	var i := 0
	while out.size() < FAKE_COUNT:
		var lang: String = langs[i % langs.size()]
		out.append(_voice("%s-x-v%03d-%s" % [lang.to_lower().replace("_", "-"), i, "network" if i % 2 == 0 else "local"], lang))
		i += 1
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in range(out.size() - 1, 0, -1):
		var j := rng.randi_range(0, k)
		var tmp = out[k]
		out[k] = out[j]
		out[j] = tmp
	return out


func _voice(id: String, lang: String) -> Dictionary:
	return {"id": id, "name": id, "language": lang}


## Every voice id in docs/ANDROID_VOICES.md and the label it must get.
const TABLE := {
	# Google Speech Services, current engines
	"en-us-x-tpc-local": "Female 1 · US English · Offline",
	"en-us-x-tpc-network": "Female 1 · US English · Online (needs internet)",
	"en-us-x-iob-local": "Female 2 · US English · Offline",
	"en-us-x-iob-network": "Female 2 · US English · Online (needs internet)",
	"en-us-x-iog-local": "Female 3 · US English · Offline",
	"en-us-x-iog-network": "Female 3 · US English · Online (needs internet)",
	"en-us-x-tpf-local": "Female 4 · US English · Offline",
	"en-us-x-tpf-network": "Female 4 · US English · Online (needs internet)",
	"en-us-x-sfg-local": "Female 5 · US English · Offline",
	"en-us-x-sfg-network": "Female 5 · US English · Online (needs internet)",
	"en-us-x-iom-local": "Male 1 · US English · Offline",
	"en-us-x-iom-network": "Male 1 · US English · Online (needs internet)",
	"en-us-x-iol-local": "Male 2 · US English · Offline",
	"en-us-x-iol-network": "Male 2 · US English · Online (needs internet)",
	"en-us-x-tpd-local": "Male 3 · US English · Offline",
	"en-us-x-tpd-network": "Male 3 · US English · Online (needs internet)",
	"en-US-language": "System default",
	# Google Speech Services, older engines
	"en-us-x-sfg#female_1-local": "Female 1 · US English · Offline",
	"en-us-x-sfg#female_2-local": "Female 2 · US English · Offline",
	"en-us-x-sfg#female_3-local": "Female 3 · US English · Offline",
	"en-us-x-sfg#male_1-local": "Male 1 · US English · Offline",
	"en-us-x-sfg#male_2-local": "Male 2 · US English · Offline",
	"en-us-x-sfg#male_3-local": "Male 3 · US English · Offline",
	# Samsung TTS
	"en-US-SMTf00": "Female 1 · US English · Offline",
	"en-US-SMTl03": "Female 2 · US English · Offline",
	"en-US-SMTl04": "Female 3 · US English · Offline",
	"en-US-SMTg02": "Male 1 · US English · Offline",
	"en-US-default": "System default",
	# Not confirmed anywhere: neutral
	"en-us-x-msm00013-local": "Voice A · US English · Offline",
	"en-US-SMTm00": "Voice A · US English · Offline",
}


func _catalog_cases() -> void:
	for id in TABLE:
		var got := str(VoiceCatalog.device_voice_rows([_voice(id, "en_US")])[0][0])
		check(got == TABLE[id], "%s is labelled '%s' (got '%s')" % [id, TABLE[id], got])
	var mapped := {}
	for id in TABLE:
		mapped[VoiceCatalog.parse_voice_id(id)["code"]] = true
	for code in VoiceCatalog.US_VOICE_NAMES:
		check(mapped.has(code), "the table covers mapped code %s" % code)
	check(VoiceCatalog.device_voice_rows([_voice("en-US-SMTf00", "eng-x-lvariant-f00")])[0][1] == "en-US-SMTf00",
		"a Samsung voice counts as US by its id even with Samsung's odd locale")

	var rows := VoiceCatalog.device_voice_rows(_fake_voices())
	var labels := rows.map(func(r): return str(r[0]))
	var ids := rows.map(func(r): return str(r[1]))
	check(labels == [
		"Female 1 · US English · Offline", "Female 2 · US English · Offline",
		"Female 3 · US English · Offline", "Female 4 · US English · Offline",
		"Female 5 · US English · Offline", "Male 1 · US English · Offline",
		"Male 2 · US English · Offline", "Voice A · US English · Offline",
		"Male 3 · US English · Online (needs internet)", "System default",
	], "%d voices become the friendly US list in order: %s" % [FAKE_COUNT, labels])
	check(ids.slice(0, 7) == ["en-us-x-tpc-local", "en-us-x-iob-local", "en-us-x-iog-local",
		"en-us-x-tpf-local", "en-us-x-sfg-local", "en-us-x-iom-local", "en-us-x-iol-local"],
		"each named voice keeps its real id, the offline copy of a local/network pair: %s" % [ids])
	check(ids[7] == "en-us-x-msm00013-local" and ids[8] == "en-us-x-tpd-network" and ids[9] == "en-US-language",
		"unconfirmed code, online-only voice and the en-US default keep their real ids")
	check(ids.all(func(id): return id.to_lower().begins_with("en-us")), "only US English voices are listed (no en-GB, en-AU, en-IN, es-US, ...)")
	var one := func(id: String, lang := "en_US") -> String:
		return str(VoiceCatalog.device_voice_rows([_voice(id, lang)])[0][0])
	check(one.call("en-us-x-iol-network") == "Male 2 · US English · Online (needs internet)", "iol online: Male 2, online")
	check(one.call("en-us-x-sfg-local") == "Female 5 · US English · Offline", "sfg offline: Female 5")
	check(one.call("en-us-x-zzq-local") == "Voice A · US English · Offline", "an unknown code gets a neutral label")
	check(one.call("en-us-x-sfg#male_1-local") == "Male 1 · US English · Offline", "older engines' #male_1 names keep their gender")
	check(one.call("en-us-x-sfg#female_2-network") == "Female 2 · US English · Online (needs internet)", "older engines' #female_2 names keep their gender")
	check(one.call("en-us-x-tpc-local", "") == "Female 1 · US English · Offline", "an en-us- id counts as US without a language")
	check(VoiceCatalog.device_voice_rows([_voice("en-us-x-sfg-network", "en_US"), _voice("en-us-x-sfg-local", "en_US")]).size() == 2,
		"a local/network pair is one entry (plus System default)")
	var empty := [["System default", ""]]
	check(VoiceCatalog.device_voice_rows([]) == empty, "no voices: System default only, never an empty list")
	check(VoiceCatalog.device_voice_rows([_voice("en-gb-x-rjs-local", "en_GB"), _voice("es-us-x-sfb-local", "es_US"),
		_voice("en-au-x-aub-network", "en_AU")]) == empty, "no US voice: System default only")
	check(VoiceCatalog.device_voice_rows([{"id": ""}, "junk", {"name": "x"}]) == empty, "rows without an id are skipped")
	check(VoiceCatalog.migrate_voice_id("en-us-x-iol-local", rows) == "en-us-x-iol-local", "a listed saved voice stays")
	check(VoiceCatalog.migrate_voice_id("en-us-x-sfg-network", rows) == "en-us-x-sfg-local", "a saved network copy moves to the listed offline copy")
	check(VoiceCatalog.migrate_voice_id("en-gb-x-rjs-local", rows) == VoiceCatalog.DEFAULT_VOICE_ID, "a saved non-US voice migrates to Andrew")
	check(VoiceCatalog.migrate_voice_id("en-us-x-gone-local", rows) == VoiceCatalog.DEFAULT_VOICE_ID, "a saved voice the phone lost migrates to Andrew")
	check(VoiceCatalog.migrate_voice_id("en-US-language", rows) == "en-US-language", "a saved system default stays")
	_edge_catalog_cases()
	_default_voice_cases()


## The Edge voices from Windows, as the phone lists them.
const EDGE_LABELS := [
	"Ava · Female · Online (natural)", "Brian · Male · Online (natural)", "Emma · Female · Online (natural)",
	"Jenny · Female · Online (natural)", "Aria · Female · Online (natural)", "Christopher · Male · Online (natural)",
	"Eric · Male · Online (natural)", "Guy · Male · Online (natural)", "Michelle · Female · Online (natural)",
	"Roger · Male · Online (natural)", "Steffan · Male · Online (natural)",
]

## The default voice is data/voices.json's row marked "default": true.
func _default_voice_cases() -> void:
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string(VoiceCatalog.CATALOG_PATH))
	var marked := rows.filter(func(r): return r.get("default", false) == true)
	check(marked.size() == 1, "exactly one catalog voice is marked default (%d)" % marked.size())
	check(VoiceCatalog.DEFAULT_VOICE_ID == str(marked[0]["id"]) and VoiceCatalog.DEFAULT_VOICE_ID == "en-US-AndrewNeural", "the default voice is the marked row: %s" % VoiceCatalog.DEFAULT_VOICE_ID)
	check(VoiceCatalog.BUNDLED_VOICE_ID == VoiceCatalog.DEFAULT_VOICE_ID, "the recorded clips are in the default voice")
	check(VoiceCatalog.BUNDLED_VOICE_LABEL == str(marked[0]["label"]).get_slice(" · ", 0) + " · Recorded (offline)", "recorded row label: %s" % VoiceCatalog.BUNDLED_VOICE_LABEL)
	check(Main.BUNDLED_VOICE_ID == VoiceCatalog.BUNDLED_VOICE_ID and Main.BUNDLED_VOICE_LABEL == VoiceCatalog.BUNDLED_VOICE_LABEL, "Main exposes the same recorded voice")
	var path := "user://test_voice_picker_default.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify([{"label": "Ava · Female", "id": "en-US-AvaNeural"}, {"label": "Brian · Male", "id": "en-US-BrianNeural", "default": true}]))
	f.close()
	check(str(VoiceCatalog.default_row(path).get("id")) == "en-US-BrianNeural", "the marked row wins over the first")
	f = FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify([{"label": "Ava · Female", "id": "en-US-AvaNeural"}]))
	f.close()
	check(str(VoiceCatalog.default_row(path).get("id")) == "en-US-AvaNeural", "no mark: the first row")
	check(VoiceCatalog.default_row("user://no_such_catalog.json").is_empty(), "no catalog: no row")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _edge_catalog_cases() -> void:
	var rows := VoiceCatalog.edge_voice_rows()
	check(rows.map(func(r): return str(r[0])) == EDGE_LABELS, "the Windows Edge voices are listed with name, gender and Online (natural): %s" % [rows])
	check(rows.all(func(r): return str(r[1]).begins_with("en-US-") and str(r[1]).ends_with("Neural")), "each keeps its Edge id")
	check(not rows.any(func(r): return str(r[1]) == "en-GB-RyanNeural"), "the British Ryan is not listed (US English only)")
	check(not rows.any(func(r): return str(r[1]) == VoiceCatalog.BUNDLED_VOICE_ID), "Andrew is not listed twice (the recorded row is Andrew)")
	var path := "user://test_voice_picker_edge.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify([
		{"label": "Ava · Female · Expressive", "id": "en-US-AvaNeural", "tier": "natural", "locale": "en-US", "gender": "Female"},
		{"label": "Ryan · Male · Calm British narrator", "id": "en-GB-RyanNeural", "tier": "natural", "locale": "en-GB", "gender": "Male"},
		{"label": "Natasha · Female · Clear", "id": "en-AU-NatashaNeural", "tier": "classic", "locale": "en-AU", "gender": "Female"},
		{"label": "Prabhat · Male · Clear", "id": "en-IN-PrabhatNeural", "tier": "classic", "locale": "en-IN", "gender": "Male"},
		{"label": "Andrew · Male · Warm", "id": "en-US-AndrewNeural", "tier": "natural", "locale": "en-US", "gender": "Male"},
		{"label": "Sam · Friendly", "id": "en-US-SamNeural", "tier": "classic", "locale": "en-US"},
		{"label": "Old", "id": "en-US-OldVoice", "locale": "en-US", "gender": "Male"},
		{"label": "Guy · Male", "id": "en-US-GuyNeural", "tier": "classic"},
	]))
	f.close()
	check(VoiceCatalog.edge_voice_rows(path) == [["Ava · Female · Online (natural)", "en-US-AvaNeural"], ["Sam · Online (natural)", "en-US-SamNeural"]],
		"non-US Edge voices (en-GB, en-AU, en-IN), rows without en-US and non-neural ids are filtered out; no gender, no guess")
	check(VoiceCatalog.edge_voice_rows("user://no_such_catalog.json").is_empty(), "no catalog: no Edge rows")
	check(VoiceCatalog.is_edge_voice("en-US-AvaNeural") and not VoiceCatalog.is_edge_voice("en-us-x-iol-local") and not VoiceCatalog.is_edge_voice(""),
		"Edge ids are told apart from device ids")
	check(VoiceCatalog.migrate_voice_id("en-US-AvaNeural", [["Ava", "en-US-AvaNeural"]]) == "en-US-AvaNeural", "a saved Edge voice stays")


func _picker_cases() -> void:
	print("=== MOBILE VOICE PICKER, %d DEVICE VOICES ===" % FAKE_COUNT)
	fake = _fake_voices()
	main = load("res://scenes/main.tscn").instantiate()
	main.audio_cfg_path = "user://test_voice_picker_audio.cfg"
	main.voice_cfg_path = "user://test_voice_picker_voice.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.voice_cfg_path))
	main.session.bag_path = ""
	main.speech.voice_source = func() -> Array:
		source_calls[0] += 1
		return fake
	root.add_child(main)
	await _wait(0.3)
	var picker := main.voice_picker
	check(main.ui_mobile and main.speech._speech_mobile() and is_instance_valid(main.voice_button), "mobile layout (the phone code path): the voice button stands in for the picker")
	check(not picker.visible, "the OptionButton (popup needs a mouse) is hidden on mobile")
	check(picker.item_count == 1 + EDGE + US_ROWS, "recorded voice + %d Edge voices + %d US device voices listed (got %d)" % [EDGE, US_ROWS, picker.item_count])
	var order: Array = []
	for i in picker.item_count:
		order.append(picker.get_item_text(i))
	check(order.slice(1, 1 + EDGE) == EDGE_LABELS, "the Windows Edge voices follow the recorded one: %s" % [order.slice(1, 1 + EDGE)])
	check(order[1 + EDGE] == "Female 1 · US English · Offline" and order[-1] == VoiceCatalog.SYSTEM_DEFAULT_LABEL,
		"device voices come after them, System default last")
	check(picker.get_item_text(0) == VoiceCatalog.BUNDLED_VOICE_LABEL and picker.selected == 0, "the recorded voice is first and picked by default")
	check(main.voice_button.text == picker.get_item_text(0), "the voice button shows the picked voice")
	check(source_calls[0] == 1, "the OS voice list is asked once at start (asked %d)" % source_calls[0])

	# Opening, again and again: one query total, no rebuild, fast.
	var picks := [0]
	picker.item_selected.connect(func(_i: int) -> void: picks[0] += 1)
	var worst := 0
	for n in 5:
		var t := Time.get_ticks_msec()
		main.open_voice_sheet()
		worst = maxi(worst, Time.get_ticks_msec() - t)
		var sheet := main.voice_sheet
		check(is_instance_valid(sheet) and sheet.rows.size() <= VoiceSheet.FIRST_ROWS,
			"the sheet opens with only its first rows built (%d)" % (sheet.rows.size() if sheet else -1))
		for f in 10:
			await process_frame
		check(sheet.is_complete() and sheet.rows.size() == picker.item_count, "the rest of the rows arrive over a few frames")
		sheet.close()
		await process_frame
	for n in 50:
		main.speech._refresh_native_voices()
	print("  open sheet: worst %d ms over 5 opens" % worst)
	check(worst < BUDGET_MSEC, "opening the voice sheet takes < %d ms (worst %d)" % [BUDGET_MSEC, worst])
	check(source_calls[0] == 1, "opening 5 times and 50 refreshes never ask the OS again (asked %d)" % source_calls[0])
	check(picker.item_count == 1 + EDGE + US_ROWS and picks[0] == 0, "the list is neither rebuilt nor re-picked by opening it")

	# Pick a device voice by tapping its row, while the preview is "speaking".
	main.open_voice_sheet()
	for f in 10:
		await process_frame
	var sheet := main.voice_sheet
	main.speech._previewing = true
	var target := 1 + EDGE + 4
	var t1 := Time.get_ticks_msec()
	sheet.rows[target].pressed.emit()
	var pick_ms := Time.get_ticks_msec() - t1
	await process_frame
	var want_id := str(main.voice_ids[picker.get_item_text(target)])
	print("  pick: %d ms" % pick_ms)
	check(pick_ms < BUDGET_MSEC, "picking a voice takes < %d ms (took %d)" % [BUDGET_MSEC, pick_ms])
	check(picks[0] == 1, "one pick emits item_selected exactly once (got %d)" % picks[0])
	check(picker.selected == target and main.voice_button.text == picker.get_item_text(target), "the picked row is the voice and the button shows it")
	check(not main.speech._previewing and not is_instance_valid(main.voice_sheet), "the pick stops the preview and closes the sheet")
	var cfg := ConfigFile.new()
	check(cfg.load(main.voice_cfg_path) == OK and str(cfg.get_value("speech", "voice", "")) == want_id, "the pick is saved (%s)" % want_id)
	check(main.speech._pick_native_voice() == want_id, "native speech uses the picked device voice")
	check(source_calls[0] == 1, "picking never asks the OS for voices (asked %d)" % source_calls[0])

	# The same row again, a pick while one is applied, a pick mid-rebuild: no-ops.
	main.speech.pick_voice(target)
	check(picks[0] == 1, "picking the current voice again does nothing")
	main.speech._picking = true
	main.speech.pick_voice(7)
	main.speech._picking = false
	main.speech._populating = true
	main.speech.pick_voice(8)
	main.speech._populating = false
	check(picks[0] == 1 and picker.selected == target, "a pick while another is being applied is ignored")
	main.speech.pick_voice(-1)
	main.speech.pick_voice(picker.item_count + 3)
	check(picks[0] == 1, "an out-of-range pick is ignored")

	# A pick from inside an item_selected handler (a signal loop) settles.
	var loop := [0]
	var looper := func(_i: int) -> void:
		loop[0] += 1
		main.speech.pick_voice(9)
	picker.item_selected.connect(looper)
	main.speech.pick_voice(3)
	picker.item_selected.disconnect(looper)
	check(loop[0] == 1 and picker.selected == 3, "a handler that picks again inside the pick is ignored (%d emissions, selected %d)" % [loop[0], picker.selected])

	# Saved voice the phone no longer has: fall back to the recorded voice.
	var stale := ConfigFile.new()
	stale.set_value("speech", "voice", "en-us-x-gone-local")
	stale.set_value("speech", "version", VoiceCatalog.VOICE_CONFIG_VERSION)
	stale.save(main.voice_cfg_path)
	main.speech._populate_voice_picker_native()
	main.speech._load_voice_choice()
	check(picker.selected == 0 and main.voice_button.text == VoiceCatalog.BUNDLED_VOICE_LABEL, "a saved voice missing on the device falls back to the recorded one")
	for case in [["en-gb-x-gbb-local", VoiceCatalog.DEFAULT_VOICE_ID], ["en-us-x-sfg-network", "en-us-x-sfg-local"]]:
		stale.set_value("speech", "voice", case[0])
		stale.save(main.voice_cfg_path)
		main.speech._load_voice_choice()
		var saved_now := ConfigFile.new()
		saved_now.load(main.voice_cfg_path)
		check(main.speech._selected_voice_id() == case[1] and str(saved_now.get_value("speech", "voice", "")) == case[1],
			"saved %s migrates to %s (picked %s)" % [case[0], case[1], main.speech._selected_voice_id()])

	# Voices that load late: the list fills in on the next refresh, once.
	fake = []
	main.speech._device_voices.clear()
	main.speech._device_voices_msec = -10 * SpeechController.VOICE_RETRY_MSEC
	main.speech._populate_voice_picker_native()
	check(picker.item_count == 2 + EDGE and picker.get_item_text(1 + EDGE) == VoiceCatalog.SYSTEM_DEFAULT_LABEL,
		"no device voices yet: recorded voice + Edge voices + System default")
	stale.set_value("speech", "voice", "en-us-x-iom-local")
	stale.save(main.voice_cfg_path)
	main.speech._load_voice_choice()
	check(picker.selected == 0, "a saved US voice not loaded yet shows the recorded voice meanwhile")
	var calls_before: int = source_calls[0]
	for n in 20:
		main.speech._refresh_native_voices()
	check(source_calls[0] == calls_before, "an empty list is not re-asked every call (asked %d more)" % (source_calls[0] - calls_before))
	fake = _fake_voices()
	main.speech._device_voices_msec -= SpeechController.VOICE_RETRY_MSEC
	main.speech._refresh_native_voices()
	check(picker.item_count == 1 + EDGE + US_ROWS, "late voices appear on the next refresh (%d)" % picker.item_count)
	check(main.speech._selected_voice_id() == "en-us-x-iom-local", "the saved US voice comes back once the late list loads (%s)" % main.speech._selected_voice_id())
	var only_other := _fake_voices().filter(func(v): return not str(v["id"]).to_lower().begins_with("en-us"))
	fake = only_other
	main.speech._device_voices.clear()
	main.speech._device_voices_msec = -10 * SpeechController.VOICE_RETRY_MSEC
	main.speech._populate_voice_picker_native()
	check(picker.item_count == 2 + EDGE and picker.get_item_text(0) == VoiceCatalog.BUNDLED_VOICE_LABEL
		and picker.get_item_text(1 + EDGE) == VoiceCatalog.SYSTEM_DEFAULT_LABEL,
		"a phone with %d voices but none US lists Andrew + the Edge voices + System default" % only_other.size())
	fake = _fake_voices()
	main.speech._device_voices.clear()
	main.speech._device_voices_msec = -10 * SpeechController.VOICE_RETRY_MSEC
	main.speech._populate_voice_picker_native()

	# The sheet itself stays responsive with a list the cap would never allow.
	for i in FAKE_COUNT:
		picker.add_item("Device voice · long list %03d" % i)
	picker.selected = picker.item_count - 1
	var t2 := Time.get_ticks_msec()
	main.open_voice_sheet()
	var big_open := Time.get_ticks_msec() - t2
	var big := main.voice_sheet
	var frames := 0
	var slowest := 0
	while not big.is_complete() and frames < 200:
		var tf := Time.get_ticks_msec()
		await process_frame
		slowest = maxi(slowest, Time.get_ticks_msec() - tf)
		frames += 1
	print("  %d-row sheet: open %d ms, complete after %d frames, slowest frame %d ms" % [picker.item_count, big_open, frames, slowest])
	check(big_open < BUDGET_MSEC, "a %d-row sheet opens in < %d ms even with the last row picked (took %d)" % [picker.item_count, BUDGET_MSEC, big_open])
	check(frames > 1 and slowest < BUDGET_MSEC, "its rows arrive in batches, no frame over %d ms (%d frames, slowest %d)" % [BUDGET_MSEC, frames, slowest])
	check(big.is_complete(), "every row of a %d-row sheet is built within 200 frames" % picker.item_count)
	await _wait(0.1)
	check(big.scroll.scroll_vertical > 0, "the sheet scrolls to the picked voice at the end of the list")
	big.close()
	await process_frame
	main.speech._populate_voice_picker_native()

	await _edge_reads()

	# Back closes the sheet instead of quitting the app.
	main.open_voice_sheet()
	await process_frame
	main._last_go_back_msec = 0
	main._on_go_back()
	await process_frame
	check(not is_instance_valid(main.voice_sheet) and not main.is_queued_for_deletion(), "Back closes the voice sheet, not the app")
	main.queue_free()
	await process_frame
	_picker_done = true


## An Edge voice on the phone: streamed by EdgeTtsClient from a local fake of
## the service, and with no internet a quick fall back that never blocks.
func _edge_reads() -> void:
	print("=== EDGE VOICES ON THE PHONE ===")
	var fake := FakeEdge.new()
	check(fake.listen() > 0, "the fake Edge service listens")
	fake.audio = _fixture_audio()
	main.speech_cache_root = "user://test_voice_picker_speech"
	_wipe(ProjectSettings.globalize_path(main.speech_cache_root))
	main.edge_client.url = fake.url()
	main.edge_client.offline_until_msec = 0
	main.speech.pick_voice(1)
	check(main.speech._selected_voice_id() == "en-US-AvaNeural" and main.voice_button.text == EDGE_LABELS[0], "Ava can be picked on the phone")
	check(main.speech._pick_native_voice() != "en-US-AvaNeural", "a device fallback is never handed an Edge id")
	main._start_quiz(5, 10, false, "Edge voice test")
	main.session_muted = false
	main._show_question()
	var rec: Dictionary = main.records[main.order[0]]
	var plan: Array = SpeechText.speech_plan(rec)
	var folder: String = main._speech_cache_folder(main._safe_speech_id(str(rec["id"])), "en-US-AvaNeural")
	check(main.edge_client.busy_request_for(folder) >= 0, "showing a question prefetches it with the Edge voice")
	var worst := [0]
	check(await _until_fake(fake, func() -> bool: return not main.menu_overlay.visible and main._speech_cache_matches(folder, plan), 5.0, worst),
		"the quiz opens with the question already fetched")
	main._stop_reading()
	_wipe(folder)
	var t0 := Time.get_ticks_msec()
	main._begin_reading(plan)
	check(Time.get_ticks_msec() - t0 < BUDGET_MSEC, "Read returns at once while the clips are fetched")
	check(main.speak_busy and main.read_status_label.text.begins_with("PREPARING AVA"), "it says it is preparing Ava (%s)" % main.read_status_label.text)
	worst[0] = 0
	check(await _until_fake(fake, func() -> bool: return main.reader.playing, 5.0, worst), "Ava reads the question on the phone")
	check(main._voice_fallback == "" and main.speech._live_request >= 0, "through the Edge client, no fallback")
	check(main.speech_queue_index == 0 and not bool(main.speech_queue[0]["teach"]), "reading starts at the stem")
	check(await _until_fake(fake, func() -> bool: return main._speech_cache_matches(folder, plan), 5.0, worst), "the whole question lands in the cache under user://")
	var first_teach: int = main.teach_from_index
	main.speech_queue_index = first_teach - 1
	main._halt_player()
	main._on_reader_finished()
	check(not main.reader.playing and main.speech_queue_index == first_teach, "the rule is not read before answering")
	main._stop_reading()
	check(worst[0] < BUDGET_MSEC, "no frame over %d ms while streaming (worst %d)" % [BUDGET_MSEC, worst[0]])

	# No internet: fall back to the recorded Andrew (or a device voice), never hang.
	main.edge_client.url = "wss://no-such-host.invalid/edge/v1"
	main.current_index = 3
	var rec3: Dictionary = main.records[main.order[3]]
	var bundled := main._bundled_speech_folder(main._safe_speech_id(str(rec3["id"])), VoiceCatalog.BUNDLED_VOICE_ID, SpeechText.speech_plan(rec3)) != ""
	worst[0] = 0
	t0 = Time.get_ticks_msec()
	main._begin_reading(SpeechText.speech_plan(rec3))
	check(Time.get_ticks_msec() - t0 < BUDGET_MSEC, "Read with no internet returns at once")
	check(await _until_fake(fake, func() -> bool: return main._voice_fallback != "", 3.0, worst), "with no internet the read falls back within 3 s")
	var want := "Andrew (recorded, no internet)" if bundled else "Device voice (no internet)"
	check(main._voice_fallback == want, "the fallback names the voice speaking (%s)" % main._voice_fallback)
	check(main._status_with_voice("READING").contains(want) and not main._status_with_voice("READING").contains("Ava"), "the status line never claims Ava after a fallback")
	if bundled:
		check(main.reader.playing and not bool(main.speech_queue[main.speech_queue_index]["teach"]), "the recorded Andrew reads the question, not the rule")
	check(worst[0] < BUDGET_MSEC, "no frame over %d ms while failing (worst %d)" % [BUDGET_MSEC, worst[0]])
	main._stop_reading()
	main.current_index = 4
	var rec4: Dictionary = main.records[main.order[4]]
	main._begin_reading(SpeechText.speech_plan(rec4))
	check(main._voice_fallback != "", "the next read falls back at once while the network is down")
	main._stop_reading()
	main.edge_client.offline_until_msec = 0
	main.speech.pick_voice(0)
	fake.stop()


func _until_fake(fake, pred: Callable, limit_s: float, worst: Array) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < limit_s * 1000.0:
		if pred.call():
			return true
		var tf := Time.get_ticks_msec()
		fake.poll()
		await process_frame
		worst[0] = maxi(worst[0], Time.get_ticks_msec() - tf)
	return pred.call()


func _fixture_audio() -> PackedByteArray:
	var speech := ProjectSettings.globalize_path("res://assets/speech")
	if DirAccess.dir_exists_absolute(speech):
		for dir in DirAccess.get_directories_at(speech):
			var clip := speech.path_join(dir).path_join("0.mp3")
			if FileAccess.file_exists(clip):
				return FileAccess.get_file_as_bytes(clip)
	return PackedByteArray()


func _wipe(folder: String) -> void:
	if not DirAccess.dir_exists_absolute(folder):
		return
	for sub in DirAccess.get_directories_at(folder):
		_wipe(folder.path_join(sub))
	for f in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(f))
	DirAccess.remove_absolute(folder)
