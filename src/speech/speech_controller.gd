class_name SpeechController
extends RefCounted
## Reads questions aloud: bundled clips, the desktop Edge helper and cache,
## native TTS on mobile, the play queue and the teach gate, and the voice picker.
## main.gd owns one (main.speech) and keeps the UI; this reaches back through host.

const SpeechText = preload("res://src/speech/speech_text.gd")
const SpeechChain = preload("res://src/fx/speech_chain.gd")
## Edge output format every clip must be recorded in (src/speech/speak_question.py
## OUTPUT_FORMAT). A manifest row in any other format is stale.
const SPEECH_FORMAT := "audio-24khz-96kbitrate-mono-mp3"
const PREVIEW_TEXT := "Hi. This is the voice that will read your National Electrical Code questions and answer choices."
## Speech folder id of the preview line; tools/speech/dump_speech.gd bundles it too.
const PREVIEW_ID := "voice-preview"
const SPEECH_BUS := "Speech"

var host: Main
var _native_segments: Array = []
var _native_seg: int = -1
var _native_generation: int = 0
var _native_voice_id: String = ""
var _native_tts_callbacks_registered: bool = false
var _native_watch_id: int = 0
var reader: AudioStreamPlayer
var speak_thread: Thread
var _retired_threads: Array[Thread] = []
var speak_generation := 0
var speak_busy := false
var speech_helper: SpeechHelper
## Desktop Edge clips cache. Tests point it elsewhere.
var speech_cache_root := "user://speech"
## Helper request the playing queue is waiting on (-1 when none).
var _live_request := -1
## Set when the picked voice could not be used, so the status line names the
## voice actually speaking instead of the one in the picker.
var _voice_fallback := ""
var speech_queue: Array = []
var speech_queue_index := 0
var teach_from_index := -1
var want_teach := false
var voice_ids: Dictionary = {}
var voice_tiers: Dictionary = {}  # picker label -> "natural" / "general" / "classic"
var voice_cfg_path := VoiceCatalog.CONFIG_PATH
var _previewing := false

func _load_voice_catalog() -> void:
	VoiceCatalog.load_catalog(voice_ids, voice_tiers)

func _populate_voice_picker() -> void:
	# Desktop: cloud voices from voices.json. Mobile: REAL on-device voices —
	# the old code showed cloud voices on Android while silently speaking OS
	# voice #1 no matter what was picked.
	host.voice_picker.clear()
	if host.ui_mobile or not OS.has_feature("pc"):
		_populate_voice_picker_native()
	else:
		var default_idx := 0
		var last_tier := ""
		for voice_name in voice_ids:
			var tier := str(voice_tiers.get(voice_name, ""))
			if tier != last_tier and VoiceCatalog.VOICE_TIER_HEADINGS.has(tier):
				host.voice_picker.add_separator(VoiceCatalog.VOICE_TIER_HEADINGS[tier])
				last_tier = tier
			if str(voice_ids[voice_name]) == VoiceCatalog.DEFAULT_VOICE_ID:
				default_idx = host.voice_picker.item_count
			host.voice_picker.add_item(voice_name)
		host.voice_picker.selected = default_idx
	if not host.voice_picker.item_selected.is_connected(_on_voice_picked):
		host.voice_picker.item_selected.connect(_on_voice_picked)
	var popup: PopupMenu = host.voice_picker.get_popup()
	if popup != null and not popup.about_to_popup.is_connected(_refresh_native_voices):
		popup.about_to_popup.connect(_refresh_native_voices)
	_load_voice_choice()

func _refresh_native_voices() -> void:
	# OS voice lists can load late on Android, so rebuild until real OS voices
	# actually appear. The old guard counted PICKER ITEMS, and the picker was
	# always seeded with the bundled Aria entry plus "System default" - so
	# item_count was already 2 and this returned early forever, leaving a cloud
	# Edge voice id selectable that the Android TTS engine does not know.
	# Gate on the OS list instead, and only rebuild when the list is non-empty.
	if not host.ui_mobile and OS.has_feature("pc"):
		return
	if host.voice_picker == null:
		return
	if not DisplayServer.has_method("tts_get_voices"):
		return
	if DisplayServer.tts_get_voices().is_empty():
		return  # still nothing to show; try again on the next tick
	_populate_voice_picker_native()
	_load_voice_choice()

func _on_voice_picked(_index: int) -> void:
	_save_voice_choice()
	AudioSection.refresh(host)
	_warm_speech_helper()
	_prefetch_speech()

func _voice_short() -> String:
	if not is_instance_valid(host.voice_picker) or host.voice_picker.item_count <= 0:
		return ""
	return VoiceCatalog.short_name(host.voice_picker.get_item_text(host.voice_picker.selected))

func _status_with_voice(base: String) -> String:
	var who := _voice_fallback if _voice_fallback != "" else _voice_short()
	return base + (" · " + who if who != "" else "")

func _populate_voice_picker_native() -> void:
	# US-English-only list (mirrors the curated desktop picker): collect tiers,
	# show the best non-empty tier so the list is never empty.
	voice_ids.clear()
	# Clear here, not only in the caller: _refresh_native_voices can run more than
	# once (timer + about_to_popup) and a bare add_item loop duplicated every
	# entry on the second pass.
	host.voice_picker.clear()
	var tiers: Array = [[], [], []]
	if DisplayServer.has_method("tts_get_voices"):
		for info in DisplayServer.tts_get_voices():
			if not info is Dictionary:
				continue
			var vid := str(info.get("id", ""))
			if vid == "":
				continue
			var vname := str(info.get("name", vid))
			var vlang := str(info.get("language", ""))
			if vname == "":
				vname = vid
			tiers[VoiceCatalog.native_tier(info)].append([vname, vlang, vid])
	var chosen: Array = tiers[0] if not tiers[0].is_empty() else (tiers[1] if not tiers[1].is_empty() else tiers[2])
	# The recorded voice ships with the app (every question, offline); device
	# voices are the fallback for anything it has no clip for.
	voice_ids[VoiceCatalog.BUNDLED_VOICE_LABEL] = VoiceCatalog.BUNDLED_VOICE_ID
	var seen := {}
	for pair in chosen:
		var label := "Device voice · " + VoiceCatalog.display_label(str(pair[0]), str(pair[1]), str(pair[2]))
		if seen.has(label):
			label = "%s [%s]" % [label, str(pair[2])]
		seen[label] = true
		voice_ids[label] = str(pair[2])
	if chosen.is_empty():
		voice_ids["Device voice · System default"] = ""
	for label in voice_ids:
		host.voice_picker.add_item(label)
	host.voice_picker.selected = 0

func _selected_voice_id() -> String:
	var label := host.voice_picker.get_item_text(host.voice_picker.selected)
	var voice_id := str(voice_ids.get(label, ""))
	return voice_id.replace("Multilingual", "")

func _load_voice_choice() -> void:
	var saved = VoiceCatalog.load_choice(voice_cfg_path, host.ui_mobile or not OS.has_feature("pc"))
	if saved == null:
		return
	for i in host.voice_picker.item_count:
		if str(voice_ids.get(host.voice_picker.get_item_text(i), "")) == saved:
			host.voice_picker.selected = i
			return

func _save_voice_choice() -> void:
	VoiceCatalog.save_choice(voice_cfg_path, _selected_voice_id())

func _stop_reading() -> void:
	speak_generation += 1
	speak_busy = false
	# The helper keeps synthesizing into the cache; only playback detaches.
	_live_request = -1
	_native_seg = -1
	want_teach = false
	teach_from_index = -1
	speech_queue.clear()
	speech_queue_index = 0
	_halt_player()
	# Unconditional: an utterance queued but not yet started reads is_speaking=false
	# and would otherwise play on as ghost audio after Stop.
	DisplayServer.tts_stop()
	host._clear_speech_highlight()
	if is_instance_valid(host.dock_visualizer):
		host.dock_visualizer.visible = false
		host.dock_visualizer.set_active(false)
	if host.read_button:
		host.read_button.text = _idle_read_label()
		host.read_button.disabled = false
	_previewing = false
	if is_instance_valid(host.preview_button):
		host.preview_button.text = "Preview"

## Read-button text while nothing is playing. After answering in a mode that
## reads the rule by itself, the rule has just played (or is about to), so the
## button offers a replay rather than asking the learner to push for it.
func _idle_read_label() -> String:
	if not host.current_answered:
		return "Read question"
	if not host.session_muted and AudioSettings.autoplays_teach(host.session_audio_mode, host.audio.auto_teach):
		return "Replay rule"
	return "Hear the rule"

func _toggle_read() -> void:
	if reader.playing or speak_busy or DisplayServer.tts_is_speaking():
		_stop_reading()
		return
	if host.order.is_empty() or host.menu_overlay.visible:
		return
	var record: Dictionary = host.records[host.order[host.current_index]]
	if host.current_answered:
		# "Hear the rule" must replay ONLY the learn part, never the Q + choices again.
		# Old code fell through to a full speech_plan on the native path
		# (teach_from_index stays -1 there), re-reading the whole question.
		want_teach = true
		if teach_from_index >= 0:
			_jump_to_teach()
			return
		_begin_reading(SpeechText.teach_segments(record))
		return
	var segments: Array = SpeechText.speech_plan(record)
	_begin_reading(segments)

## Bundled clips are imported resources: an exported build ships only the
## imported stream, not the raw .mp3, so res:// clips go through ResourceLoader.
## Cached clips in user:// are raw files.
func _clip_available(path: String) -> bool:
	if path.begins_with("res://"):
		return ResourceLoader.exists(path, "AudioStream")
	var clip := FileAccess.open(path, FileAccess.READ)
	if clip == null:
		return false
	var ok := clip.get_length() > 0
	clip.close()
	return ok

func _load_clip(path: String) -> AudioStream:
	if path.begins_with("res://"):
		return load(path) as AudioStream if ResourceLoader.exists(path, "AudioStream") else null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var stream := AudioStreamMP3.new()
	stream.data = file.get_buffer(file.get_length())
	file.close()
	return stream

func _bundled_speech_folder(safe_qid: String, voice_id: String, segments: Array) -> String:
	# Pre-generated default-voice clips shipped inside the app (tools/speech/pregenerate_speech.py).
	# Same neural voice as desktop, zero network, zero quota, exact clip sync.
	# The manifest comparison guarantees the bundle matches the CURRENT speech plan;
	# a stale bundle simply misses and falls through to live synthesis.
	if voice_id != VoiceCatalog.BUNDLED_VOICE_ID or safe_qid == "":
		return ""
	var folder := "res://assets/speech".path_join(safe_qid + "__" + voice_id)
	if _speech_cache_matches(folder, segments):
		return folder
	# A teach-only request ("Hear the rule") is a contiguous TAIL of the bundled
	# full plan, so it must be matched against that tail rather than the whole
	# manifest. Without this, every "Hear the rule" tap missed the bundle and
	# re-synthesised over the network, defeating the offline/zero-quota design.
	var tail_index := _bundled_teach_tail_offset(folder, segments)
	if tail_index > 0:
		return folder
	return ""

func _bundled_teach_tail_offset(folder: String, segments: Array) -> int:
	# Returns the manifest index at which `segments` starts, or 0 when the
	# requested clips are not a suffix of the bundle. Every requested segment
	# must be a teach clip, and each must match the manifest row at that offset
	# on text, choice and teach flag.
	if segments.is_empty():
		return 0
	var manifest_path := folder.path_join("manifest.json")
	if not FileAccess.file_exists(manifest_path):
		return 0
	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		return 0
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Array or parsed.is_empty():
		return 0
	for seg in segments:
		if not seg is Dictionary or not bool(seg.get("teach", false)):
			return 0
	var start: int = parsed.size() - segments.size()
	if start <= 0:
		return 0
	for i in segments.size():
		var row = parsed[start + i]
		if not row is Dictionary:
			return 0
		if str(row.get("text", "")) != str(segments[i].get("text", "")):
			return 0
		if int(row.get("choice", -1)) != int(segments[i].get("choice", -1)):
			return 0
		if bool(row.get("teach", false)) != bool(segments[i].get("teach", false)):
			return 0
		if int(row.get("rules", 0)) != int(segments[i].get("rules", 0)):
			return 0
		if str(row.get("format", "")) != SPEECH_FORMAT:
			return 0
		if not _clip_available(folder.path_join(str(row.get("file", "")))):
			return 0
	return start

func _begin_reading(segments: Array) -> void:
	if segments.is_empty() or host.menu_overlay.visible:
		return

	var question_id := ""
	var record: Dictionary = {}
	if not host.order.is_empty() and host.current_index >= 0 and host.current_index < host.order.size():
		record = host.records[host.order[host.current_index]]
		question_id = str(record.get("id", ""))
	var safe_qid := _safe_speech_id(question_id)
	_voice_fallback = ""
	# Mobile defaults to the bundled recorded voice too; a device voice is only
	# used when that is picked or when no recorded clip matches.
	var bundle := _bundled_speech_folder(safe_qid, _selected_voice_id(), segments)
	if bundle != "":
		speak_generation += 1
		host.read_button.text = "Stop"
		host.read_button.disabled = false
		# Start where the requested clips actually begin: a teach-only request
		# matched a SUFFIX of the manifest, so index 0 would replay the question
		# stem and all four choices instead of the lesson.
		var start_index := 0
		if want_teach:
			start_index = _bundled_teach_tail_offset(bundle, segments)
		_on_speech_ready(speak_generation, bundle, 0, "bundle", start_index)
		return
	# On Android or mobile platforms without python runtime, use native OS TTS engine!
	if _speech_mobile():
		if _selected_voice_id() == VoiceCatalog.BUNDLED_VOICE_ID:
			_voice_fallback = "Device voice (no recording)"
			push_warning("Speech: no recorded clip for %s, using the device voice." % safe_qid)
		_begin_native_tts(segments)
		return
	_save_voice_choice()
	# Always synthesize the whole question: "Hear the rule" is its tail, so one
	# cached folder serves the read, the rule, and every replay.
	_read_with_helper(safe_qid, SpeechText.speech_plan(record) if not record.is_empty() else segments)

## ui_mobile too: the mobile layout's picker lists OS voices, which edge-tts
## does not know.
func _speech_mobile() -> bool:
	return host.ui_mobile or OS.get_name() == "Android" or not OS.has_feature("pc")

func _safe_speech_id(question_id: String) -> String:
	var safe := question_id.replace("/", "_").replace("\\", "_")
	return safe if safe != "" else "item"

func _speech_cache_folder(safe_id: String, voice_id: String) -> String:
	return ProjectSettings.globalize_path(speech_cache_root).path_join(safe_id + "__" + voice_id)

## Desktop Edge voice: cached clips play at once; otherwise the warm helper
## synthesizes `plan` and each clip plays as soon as it lands.
func _read_with_helper(safe_id: String, plan: Array) -> void:
	speak_generation += 1
	var voice_id := _selected_voice_id()
	var folder := _speech_cache_folder(safe_id, voice_id)
	if _speech_cache_matches(folder, plan):
		_on_speech_ready(speak_generation, folder, 0, "cache")
		return
	var rid := speech_helper.request(folder, voice_id, plan, SpeechHelper.PRIO_LIVE)
	if rid < 0:
		_fallback_to_native(speech_helper.fail_reason)
		return
	_live_request = rid
	speech_queue.clear()
	for i in plan.size():
		var seg = plan[i]
		if seg is Dictionary and str(seg.get("text", "")).strip_edges() != "":
			speech_queue.append({
				"path": folder.path_join("%d.mp3" % i),
				"choice": int(seg.get("choice", -1)),
				"teach": bool(seg.get("teach", false)),
				"request": rid,
				"segment": i,
			})
	teach_from_index = -1
	for i in speech_queue.size():
		if bool(speech_queue[i]["teach"]):
			teach_from_index = i
			break
	speech_queue_index = teach_from_index if want_teach and teach_from_index >= 0 else 0
	host.read_button.text = "Stop"
	host.read_button.disabled = false
	_play_speech_clip()

func _on_helper_clip(request_id: int, index: int) -> void:
	if request_id != _live_request or not speak_busy:
		return
	if speech_queue_index < speech_queue.size() and int(speech_queue[speech_queue_index].get("segment", -1)) == index:
		speak_busy = false
		_play_speech_clip()

func _on_helper_failed(request_id: int, why: String) -> void:
	if request_id == _live_request:
		_fallback_to_native(why)

## The picked Edge voice cannot speak: say so, log why, read with the system voice.
func _fallback_to_native(why: String) -> void:
	var wanted := _voice_short()
	_live_request = -1
	speak_busy = false
	_halt_player()
	push_warning("Speech: %s unavailable, using the system voice. %s" % [wanted, why])
	_voice_fallback = "System voice (Edge unavailable)"
	if _previewing:
		_begin_native_tts([{"text": PREVIEW_TEXT, "choice": -1, "teach": false}])
		return
	if not host.order.is_empty() and host.current_index >= 0 and host.current_index < host.order.size():
		var fallback_record: Dictionary = host.records[host.order[host.current_index]]
		_begin_native_tts(SpeechText.teach_segments(fallback_record) if want_teach else SpeechText.speech_plan(fallback_record))
		return
	host.read_button.text = _idle_read_label()
	_set_read_status("")

## Edge voices other than the bundled one need the helper; start it early so
## its ~3 s of imports are done before the first Read.
func _warm_speech_helper() -> void:
	if speech_helper == null or _speech_mobile() or not is_instance_valid(host.voice_picker):
		return
	if _selected_voice_id() != VoiceCatalog.BUNDLED_VOICE_ID:
		speech_helper.start()

## Synthesizes the current and next question in the background (whole plans,
## rule included; the teach gate in _play_speech_clip still holds the rule
## until the answer is in), so Read and Next start from the cache.
func _prefetch_speech() -> void:
	if speech_helper == null or host.session_muted or _speech_mobile() or host.order.is_empty():
		return
	var voice_id := _selected_voice_id()
	for idx in [host.current_index, host.current_index + 1]:
		if idx < 0 or idx >= host.order.size():
			continue
		var record: Dictionary = host.records[host.order[idx]]
		var safe_id := _safe_speech_id(str(record.get("id", "")))
		var plan: Array = SpeechText.speech_plan(record)
		if _bundled_speech_folder(safe_id, voice_id, plan) != "":
			continue
		var folder := _speech_cache_folder(safe_id, voice_id)
		if speech_helper.busy_request_for(folder) >= 0 or _speech_cache_matches(folder, plan):
			continue
		if speech_helper.request(folder, voice_id, plan, SpeechHelper.PRIO_PREFETCH) < 0:
			return

func _set_read_status(text: String) -> void:
	if not is_instance_valid(host.read_status_label):
		return
	if text == "":
		host.read_status_label.visible = false
	else:
		host.read_status_label.text = text
		host.read_status_label.visible = true

func _count_teach(segments: Array) -> int:
	var n := 0
	for seg in segments:
		if seg is Dictionary and bool(seg.get("teach", false)):
			n += 1
	return n

func _teach_index_of(segments: Array, seg_idx: int) -> int:
	var n := 0
	for si in mini(seg_idx, segments.size()):
		var row = segments[si]
		if row is Dictionary and bool(row.get("teach", false)):
			n += 1
	return n

func _update_read_status(choice: int, is_teach: bool, teach_idx: int, teach_total: int) -> void:
	if is_teach:
		_set_read_status(_status_with_voice("TEACHING: RULE %d OF %d" % [teach_idx + 1, maxi(teach_total, teach_idx + 1)]))
	elif choice >= 0:
		var letter: String = str(Main.ANSWER_LETTERS[choice]) if choice >= 0 and choice < Main.ANSWER_LETTERS.size() else str(choice + 1)
		_set_read_status(_status_with_voice("READING: CHOICE " + letter))
	else:
		_set_read_status(_status_with_voice("READING: QUESTION"))

func _register_native_tts_callbacks() -> void:
	# Docs: DisplayServer.tts_set_utterance_callback fires STARTED / ENDED / CANCELED /
	# BOUNDARY per utterance_id. Engine events drive everything: ENDED advances,
	# STARTED syncs the highlight to actual audio start, and a generous watchdog
	# covers drivers that never report back. Tight duration estimates are banned —
	# on Android they fire mid-utterance and pile speech into the OS queue.
	if _native_tts_callbacks_registered:
		return
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_STARTED, Callable(self, "_on_native_utterance_started"))
		DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, Callable(self, "_on_native_utterance_ended"))
		DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_CANCELED, Callable(self, "_on_native_utterance_canceled"))
	_native_tts_callbacks_registered = true

func _pick_native_voice() -> String:
	# Honor the picker (on mobile it holds real OS voices, including an explicit
	# "System default" whose id is ""). Fall back to first English, then default.
	# The bundled recorded voice is not an OS voice: fall through to a device one.
	if is_instance_valid(host.voice_picker) and host.voice_picker.item_count > 0:
		var label := host.voice_picker.get_item_text(host.voice_picker.selected)
		if voice_ids.has(label) and str(voice_ids[label]) != VoiceCatalog.BUNDLED_VOICE_ID:
			return str(voice_ids[label])
	if DisplayServer.has_method("tts_get_voices_for_language"):
		var voices := DisplayServer.tts_get_voices_for_language("en")
		if not voices.is_empty():
			return str(voices[0])
	return ""

func _on_native_utterance_ended(utterance_id: int) -> void:
	var seg := utterance_id - 1
	if seg < 0 or seg != _native_seg:
		return
	if _native_generation != speak_generation:
		return
	_play_next_native_tts_segment(_native_segments, seg + 1, speak_generation)

func _on_native_utterance_canceled(utterance_id: int) -> void:
	# A CANCELED for a DIFFERENT utterance is a stale event: Stop() queues one,
	# and Android can deliver it after the next Read() has already started
	# speaking. This handler used to ignore the id and blindly clear _native_seg,
	# which killed the state machine for the utterance actually playing (both
	# ENDED and the watchdog then failed their _native_seg checks, so playback
	# ran out and never advanced - silence with the button stuck on "Stop").
	# Match the id/generation guards the ENDED and STARTED handlers already use.
	var seg := utterance_id - 1
	if seg < 0 or seg != _native_seg:
		return
	if _native_generation != speak_generation:
		return
	_native_seg = -1
	_stop_reading()
	# An OS-side cancel (audio focus, engine hiccup) must not stall hands-free play.
	host._notify_playback_complete()

func _on_native_utterance_started(utterance_id: int) -> void:
	var seg := utterance_id - 1
	if seg < 0 or seg != _native_seg:
		return
	if _native_generation != speak_generation:
		return
	# Audio really started now (late on network voices): re-affirm the highlight and
	# restart the watchdog from speech start, invalidating the pre-start timer.
	_show_native_highlight(_native_segments, seg)
	_start_native_watchdog(_native_segments, seg, speak_generation)

func _show_native_highlight(segments: Array, seg_idx: int) -> void:
	if seg_idx < 0 or seg_idx >= segments.size():
		return
	var seg: Dictionary = segments[seg_idx]
	var choice := int(seg.get("choice", -1))
	var is_teach := bool(seg.get("teach", false))
	host._clear_speech_highlight()
	if is_instance_valid(host.dock_visualizer):
		host.dock_visualizer.visible = true
		host.dock_visualizer.set_active(true)
	if choice >= 0 and choice < host.answers_box.get_child_count():
		var card = host.answers_box.get_child(choice)
		if card.has_method("set_speaking"):
			card.set_speaking(true)
	elif is_teach:
		# Count how many teach segments came before this one to find the teach-line index
		var teach_line_idx := 0
		for si in seg_idx:
			if bool(segments[si].get("teach", false)):
				teach_line_idx += 1
		host.info_panel.active_teach_line = teach_line_idx
		if is_instance_valid(host.info_label) and host.info_label.visible:
			host.info_panel.render()
	elif choice < 0:
		# Reading question stem
		if is_instance_valid(host.prompt_voice_badge):
			host.prompt_voice_badge.visible = true
		if is_instance_valid(host.prompt_visualizer):
			host.prompt_visualizer.set_active(true)
		# Glow the question panel
		host._set_question_stem_glow(true)
	_update_read_status(choice, is_teach, _teach_index_of(segments, seg_idx), _count_teach(segments))

func _start_native_watchdog(segments: Array, seg_idx: int, generation: int) -> void:
	# Last-resort timer only. Each (re)start bumps the token so a late STARTED event
	# kills the pre-start timer — only the newest timer for the current segment wins.
	_native_watch_id += 1
	var wid := _native_watch_id
	var words := str(segments[seg_idx].get("text", "")).split(" ", false).size()
	var bound: float = maxf(6.0, float(words) / 1.2 + 4.0)
	var tw := host.create_tween()
	tw.tween_interval(bound)
	tw.tween_callback(func():
		if generation == speak_generation and _native_seg == seg_idx and wid == _native_watch_id:
			_play_next_native_tts_segment(segments, seg_idx + 1, generation)
	)

func _begin_native_tts(segments: Array) -> void:
	speak_generation += 1
	var generation := speak_generation
	_register_native_tts_callbacks()
	_native_voice_id = _pick_native_voice()
	host.read_button.text = "Stop"
	host.read_button.disabled = false
	_play_next_native_tts_segment(segments, 0, generation)

func _play_next_native_tts_segment(segments: Array, seg_idx: int, generation: int) -> void:
	if generation != speak_generation:
		return
	if seg_idx >= segments.size():
		_stop_reading()
		host._notify_playback_complete()
		return

	var seg: Dictionary = segments[seg_idx]
	var text: String = str(seg.get("text", "")).strip_edges()
	var choice: int = int(seg.get("choice", -1))
	var is_teach: bool = bool(seg.get("teach", false))

	if not want_teach and is_teach:
		_stop_reading()
		host._notify_playback_complete()
		return
	if want_teach and not is_teach:
		# Learn mode on native TTS: skip the Q stem + choices the learner already
		# answered and jump straight to the first teach line (no duplicate read).
		_play_next_native_tts_segment(segments, seg_idx + 1, generation)
		return

	_show_native_highlight(segments, seg_idx)
	_native_segments = segments
	_native_seg = seg_idx
	_native_generation = generation
	if text == "":
		_play_next_native_tts_segment(segments, seg_idx + 1, generation)
		return
	# interrupt=true: never queue behind a stray utterance. On the normal path the
	# previous line already ENDED; anything still speaking gets cut instead of piling
	# into the OS queue while the highlight runs ahead (the Android skip bug).
	# Volume 100: Godot's default of 50 made the native voice half as loud as the
	# desktop clips (Android maps it to a 0.5 TextToSpeech volume).
	DisplayServer.tts_speak(text, _native_voice_id, 100, 1.0, host.audio.speed, seg_idx + 1, true)
	_start_native_watchdog(segments, seg_idx, generation)

func _speech_cache_matches(folder: String, segments: Array) -> bool:
	var manifest_path := folder.path_join("manifest.json")
	if not FileAccess.file_exists(manifest_path):
		return false
	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Array:
		return false
	var wanted: Array = []
	for segment in segments:
		if segment is Dictionary and str(segment.get("text", "")).strip_edges() != "":
			wanted.append(segment)
	if wanted.size() != parsed.size():
		return false
	for i in wanted.size():
		var row = parsed[i]
		if not row is Dictionary:
			return false
		if str(row.get("text", "")) != str(wanted[i].get("text", "")):
			return false
		if int(row.get("choice", -1)) != int(wanted[i].get("choice", -1)):
			return false
		if bool(row.get("teach", false)) != bool(wanted[i].get("teach", false)):
			return false
		# A clip rendered under older speech rules is stale even if the text
		# happens to match (the rules can change more than the text).
		if int(row.get("rules", 0)) != int(wanted[i].get("rules", 0)):
			return false
		if str(row.get("format", "")) != SPEECH_FORMAT:
			return false
		if not _clip_available(folder.path_join(str(row.get("file", "")))):
			return false
	return true

func _on_speech_ready(generation: int, folder: String, code: int, output: String, start_index: int = 0) -> void:
	# A late callback from a CANCELLED request must not touch shared state: the
	# busy flag and the queue now belong to the newer request that superseded it.
	# Clearing speak_busy here let _toggle_read start a duplicate synthesis, and
	# the duplicate replaced speak_thread while the live one was still running.
	if generation != speak_generation:
		return
	speak_busy = false
	var manifest_path := folder.path_join("manifest.json")
	if code != 0 or not FileAccess.file_exists(manifest_path):
		_fallback_to_native(output)
		return
	var file := FileAccess.open(manifest_path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text()) if file else null
	if file:
		file.close()
	speech_queue.clear()
	if parsed is Array:
		for row in parsed:
			if row is Dictionary:
				speech_queue.append({
					"path": folder.path_join(str(row.get("file", ""))),
					"choice": int(row.get("choice", -1)),
					"teach": bool(row.get("teach", false)),
				})
	teach_from_index = -1
	for i in speech_queue.size():
		if bool(speech_queue[i].get("teach", false)):
			teach_from_index = i
			break
	speech_queue_index = teach_from_index if want_teach and teach_from_index >= 0 else maxi(0, start_index)
	if speech_queue.is_empty():
		host.read_button.text = _idle_read_label()
		host._notify_playback_complete()
		return
	host.read_button.text = "Stop"
	_play_speech_clip()

func _play_speech_clip() -> void:
	host._clear_speech_highlight()
	if speech_queue_index >= speech_queue.size():
		host.read_button.text = _idle_read_label()
		host._notify_playback_complete()
		return
	var clip: Dictionary = speech_queue[speech_queue_index]
	var choice := int(clip.get("choice", -1))
	var is_teach := bool(clip.get("teach", false))
	# The teach gate lives HERE, in the function that plays, so no caller and no
	# skip path can hand it a clip that narrates the answer before answering.
	# It used to be checked only by the callers and in the missing-file branch.
	if is_teach and not want_teach:
		host._clear_speech_highlight()
		if host.read_button:
			host.read_button.text = _idle_read_label()
			host.read_button.disabled = false
		host._notify_playback_complete()
		return

	if is_instance_valid(host.dock_visualizer):
		host.dock_visualizer.visible = true
		host.dock_visualizer.set_active(true)

	# Streaming from the helper: this clip has not landed yet. Wait for it
	# (_on_helper_clip resumes); Stop, skip and Next clear _live_request.
	var request_id := int(clip.get("request", -1))
	if request_id >= 0 and not speech_helper.has_clip(request_id, int(clip.get("segment", -1))):
		speak_busy = true
		_set_read_status("PREPARING %s…" % _voice_short().to_upper())
		return
	speak_busy = false

	if choice >= 0 and choice < host.answers_box.get_child_count():
		var card = host.answers_box.get_child(choice)
		if card.has_method("set_speaking"):
			card.set_speaking(true)
	elif is_teach:
		# Count how many teach clips came before this one in the queue
		var teach_line_idx := 0
		for si in speech_queue_index:
			if bool(speech_queue[si].get("teach", false)):
				teach_line_idx += 1
		host.info_panel.active_teach_line = teach_line_idx
		if is_instance_valid(host.info_label) and host.info_label.visible:
			host.info_panel.render()
	elif choice < 0:
		# Reading question stem
		if is_instance_valid(host.prompt_voice_badge):
			host.prompt_voice_badge.visible = true
		if is_instance_valid(host.prompt_visualizer):
			host.prompt_visualizer.set_active(true)
		# Glow the question panel
		host._set_question_stem_glow(true)

	_update_read_status(choice, is_teach, _teach_index_of(speech_queue, speech_queue_index), _count_teach(speech_queue))
	var stream := _load_clip(str(clip.get("path", "")))
	if stream == null:
		# Skip an unplayable clip; the recursion re-enters the teach gate above.
		speech_queue_index += 1
		_play_speech_clip()
		return
	reader.stream = stream
	reader.play()

func _on_reader_finished() -> void:
	if speak_busy:
		return
	speech_queue_index += 1
	if speech_queue_index < speech_queue.size() and (want_teach or not bool(speech_queue[speech_queue_index].get("teach", false))):
		_play_speech_clip()
		return
	host._clear_speech_highlight()
	if is_instance_valid(host.dock_visualizer):
		host.dock_visualizer.visible = false
		host.dock_visualizer.set_active(false)
	if host.read_button:
		host.read_button.text = _idle_read_label()
	host._notify_playback_complete()

func _jump_to_teach() -> void:
	if teach_from_index < 0 or teach_from_index >= speech_queue.size():
		return
	speech_queue_index = teach_from_index
	_halt_player()
	host.read_button.text = "Stop"
	_play_speech_clip()

func _halt_player() -> void:
	if reader == null:
		return
	var was_connected := reader.finished.is_connected(_on_reader_finished)
	if was_connected:
		reader.finished.disconnect(_on_reader_finished)
	if reader.playing:
		reader.stop()
	if was_connected and not reader.finished.is_connected(_on_reader_finished):
		reader.finished.connect(_on_reader_finished)

func _join_speak_thread() -> void:
	if speak_thread != null and speak_thread.is_started():
		speak_thread.wait_to_finish()
	for t in _retired_threads:
		if t.is_started():
			t.wait_to_finish()
	_retired_threads.clear()

## Speed is applied at playback so the cached per-voice Edge clips stay valid:
## pitch_scale speeds the player up, and a pitch shift on a dedicated bus pulls
## the voice back to its natural pitch. See fx/speech_chain.gd for the rest.
func _setup_speech_bus() -> void:
	var idx := AudioServer.get_bus_index(SPEECH_BUS)
	if idx < 0:
		idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, SPEECH_BUS)
		AudioServer.set_bus_send(idx, "Master")
		SpeechChain.build(idx)
	reader.bus = SPEECH_BUS
	_apply_speed()

func _apply_speed() -> void:
	if reader != null:
		reader.pitch_scale = host.audio.speed
	SpeechChain.apply_speed(AudioServer.get_bus_index(SPEECH_BUS), host.audio.speed)

func _preview_voice() -> void:
	if _previewing:
		_stop_reading()
		return
	_stop_reading()
	var segments: Array = [{"text": PREVIEW_TEXT, "choice": -1, "teach": false}]
	_previewing = true
	host.preview_button.text = "Stop"
	_voice_fallback = ""
	_save_voice_choice()
	var bundle := _bundled_speech_folder(PREVIEW_ID, _selected_voice_id(), segments)
	if bundle != "":
		speak_generation += 1
		_on_speech_ready(speak_generation, bundle, 0, "bundle")
		return
	if _speech_mobile():
		_begin_native_tts(segments)
		return
	_read_with_helper(PREVIEW_ID, segments)
