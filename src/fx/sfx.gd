class_name Sfx
extends Node

## The sound effects the app plays (docs/SFX_PLAN.md). Six event cues: session
## start, answer correct / wrong, results pass / fail and an exam-clock warning.
## Five quiet interface sounds: click, hover, toggle, select and transition.
## They live on their own "SFX" bus, separate from the voice, with one
## pre-loaded player each so a cue never waits on a load.
##
## Event cues play at once. Only the clock warning can overlap the voice
## (starting a session, answers and results stop it first, and auto-read waits
## past the start cue), so only the warning goes through the ducker: a
## compressor keyed by the Speech bus stays clamped for a while after the voice
## is cut off, and would swallow an answer tone fired in that same instant.
##
## Interface sounds are one per user action: requests made while handling an
## action are collected and, at the end of the frame, only the highest-ranked
## one plays, and none at all if an event cue started within UI_EVENT_WINDOW_MS
## (a start press is the start cue alone; an answer tap is correct / wrong
## alone). Each has a minimum gap before it repeats, hover is skipped while a
## voice reads, and the others play VOICE_DUCK_DB down under it. They are
## judged after the action ran, so a press that stops the voice plays in full.
##
## The static part is the sound map and the rules for when a cue plays; it is
## pure and unit-tested. Every instance method is a quiet no-op without a tree,
## bus or imported asset (headless harness).
##
## Assets are sourced recordings (Pixabay Content License), processed and
## loudness-matched per role; see assets/sfx/CREDITS.md. The trims below stay
## at zero.

const BUS := "SFX"
## Sub-bus of SFX carrying the sidechain ducker; only "duck" cues play on it.
const DUCK_BUS := "SFXDuck"
const SPEECH_BUS := "Speech"
const DIR := "res://assets/sfx/"

## db: trim on top of the bus level. vary_db: random level spread per play, so
## the 100th answer tone is not a byte-identical copy of the first. vary_pitch:
## random pitch spread per play (0.04 = about ±4 %), only on hover, the sound
## that repeats most; the correct tone is pitched by the streak instead. duck: the
## cue can play while the voice is still reading and is squeezed under it.
const SOUNDS := {
	"correct": {"db": 0.0, "vary_db": 1.0, "vary_pitch": 0.0, "duck": false},
	"wrong": {"db": 0.0, "vary_db": 1.0, "vary_pitch": 0.0, "duck": false},
	"warning": {"db": 0.0, "vary_db": 0.0, "vary_pitch": 0.0, "duck": true},
	"pass": {"db": 0.0, "vary_db": 0.0, "vary_pitch": 0.0, "duck": false},
	"fail": {"db": 0.0, "vary_db": 0.0, "vary_pitch": 0.0, "duck": false},
	"start": {"db": 0.0, "vary_db": 0.0, "vary_pitch": 0.0, "duck": false},
	"click": {"db": 0.0, "vary_db": 1.0, "vary_pitch": 0.0, "duck": false},
	"hover": {"db": 0.0, "vary_db": 1.0, "vary_pitch": 0.04, "duck": false},
	"toggle": {"db": 0.0, "vary_db": 0.0, "vary_pitch": 0.0, "duck": false},
	"select": {"db": 0.0, "vary_db": 1.0, "vary_pitch": 0.0, "duck": false},
	"transition": {"db": 0.0, "vary_db": 0.0, "vary_pitch": 0.0, "duck": false},
}
## Interface sounds. rank: when one action asks for several (a Menu press asks
## for click and transition), the highest plays. gap: seconds before the same
## sound may play again, so sweeping the mouse down the menu doesn't machine-gun.
const UI := {
	"transition": {"rank": 3, "gap": 0.25},
	"toggle": {"rank": 2, "gap": 0.05},
	"select": {"rank": 2, "gap": 0.05},
	"click": {"rank": 1, "gap": 0.05},
	"hover": {"rank": 0, "gap": 0.15},
}
## An event cue this recent silences pending interface sounds.
const UI_EVENT_WINDOW_MS := 40
## Played by every menu control that starts a session (Widgets.connect_session_start).
const START := "start"

## Semitones the correct tone rises on a streak (index = streak, last entry
## holds): 3 in a row +2, 5 +4, 8 (a full streak meter) +5. Same asset, no new cue.
const STREAK_SEMITONES: Array[int] = [0, 0, 0, 2, 2, 4, 4, 4, 5]

## Applied to the warning while a voice the Speech-bus ducker cannot hear is
## reading (Android / system TTS), about what the ducker takes off a recorded
## clip; and to interface sounds while any voice reads.
const VOICE_DUCK_DB := -8.0
## Exam-clock seconds left at which the warning plays once: 5:00 is where the
## clock turns red, 1:00 is the last call.
const WARN_AT_SECONDS: Array[int] = [300, 60]

var enabled := true
## Returns true while a voice outside the Speech bus (system TTS) is reading;
## set by the host. Recorded clips on the Speech bus are ducked by DUCK_BUS.
var voice_active: Callable = Callable()
## Returns true while any voice (recorded clip or system TTS) is reading; set
## by the host. Drives the interface sounds' voice rules.
var voice_reading: Callable = Callable()
## The event cue and the interface sound that last actually played (for tests
## and tools).
var last_event := ""
var last_ui := ""
var _players: Dictionary = {}
var _pending: Array[String] = []
var _event_msec := -100000
var _ui_msec: Dictionary = {}


static func path_for(id: String) -> String:
	return DIR + id + ".wav"


static func is_ui(id: String) -> bool:
	return UI.has(id)


## Listen mode is ungraded and the voice reads the answer next, so it is silent.
static func answer_sound(graded: bool, is_right: bool) -> String:
	if not graded:
		return ""
	return "correct" if is_right else "wrong"


static func streak_pitch(streak: int) -> float:
	var semis: int = STREAK_SEMITONES[clampi(streak, 0, STREAK_SEMITONES.size() - 1)]
	return pow(2.0, semis / 12.0)


## 0 for a first correct answer, rising to 1 at the top streak step; drives how
## big the visual celebration is, in step with the pitch.
static func streak_strength(streak: int) -> float:
	var semis: int = STREAK_SEMITONES[clampi(streak, 0, STREAK_SEMITONES.size() - 1)]
	return float(semis) / float(STREAK_SEMITONES[-1])


static func result_sound(passed: bool) -> String:
	return "pass" if passed else "fail"


static func time_warning(timed: bool, exam_left: int) -> bool:
	return timed and WARN_AT_SECONDS.has(exam_left)


## Volume offset for a cue given the voice state; NAN means "unknown cue".
static func voice_offset_db(id: String, voice_on: bool) -> float:
	if not SOUNDS.has(id):
		return NAN
	return VOICE_DUCK_DB if voice_on and (bool(SOUNDS[id]["duck"]) or is_ui(id)) else 0.0


## The one interface sound an action gets: the highest rank, the first asked on a tie.
static func pick_ui(requested: Array) -> String:
	var best := ""
	for id in requested:
		if is_ui(id) and (best == "" or int(UI[id]["rank"]) > int(UI[best]["rank"])):
			best = id
	return best


static func gap_ok(id: String, since_last: float) -> bool:
	return since_last >= float(UI[id]["gap"])


## Hover is the least informative sound: it never plays over a voice.
static func plays_over_voice(id: String) -> bool:
	return id != "hover"


func setup() -> void:
	_ensure_bus()
	for id in SOUNDS:
		var p := _make_player(id)
		if p != null:
			add_child(p)
			_players[id] = p


func apply_settings(on: bool, bus_db: float) -> void:
	enabled = on
	var idx := AudioServer.get_bus_index(BUS)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, bus_db)
		AudioServer.set_bus_mute(idx, not on)


## Returns whether a cue was started, or for an interface sound queued for the
## end of the frame (false when off, unknown or not loaded).
func play(id: String, pitch: float = 1.0) -> bool:
	if not enabled or not _players.has(id) or not is_inside_tree():
		return false
	if is_ui(id):
		if _pending.is_empty():
			flush_ui.call_deferred()
		_pending.append(id)
		return true
	_event_msec = Time.get_ticks_msec()
	_pending.clear()
	last_event = id
	_start(id, pitch, voice_active.is_valid() and bool(voice_active.call()))
	return true


## Plays the pending interface sound, if the rules allow; runs deferred after
## the first request of a frame.
func flush_ui() -> void:
	var id := pick_ui(_pending)
	_pending.clear()
	if id == "" or not enabled or not is_inside_tree():
		return
	var now := Time.get_ticks_msec()
	if now - _event_msec < UI_EVENT_WINDOW_MS:
		return
	if _ui_msec.has(id) and not gap_ok(id, float(now - int(_ui_msec[id])) / 1000.0):
		return
	var reading := voice_reading.is_valid() and bool(voice_reading.call())
	if reading and not plays_over_voice(id):
		return
	_ui_msec[id] = now
	last_ui = id
	_start(id, 1.0, reading)


func _start(id: String, pitch: float, voice_on: bool) -> void:
	var p: AudioStreamPlayer = _players[id]
	p.volume_db = float(SOUNDS[id]["db"]) + voice_offset_db(id, voice_on)
	p.pitch_scale = pitch
	p.play()


func _ensure_bus() -> void:
	if AudioServer.get_bus_index(BUS) < 0:
		var bus_idx := AudioServer.bus_count
		AudioServer.add_bus(bus_idx)
		AudioServer.set_bus_name(bus_idx, BUS)
		AudioServer.set_bus_send(bus_idx, "Master")
	if AudioServer.get_bus_index(DUCK_BUS) >= 0:
		return
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, DUCK_BUS)
	# Through SFX, so the Sounds level and Off apply to it too.
	AudioServer.set_bus_send(idx, BUS)
	# Sidechain ducking: whatever still overlaps the voice is squeezed under it.
	var duck := AudioEffectCompressor.new()
	duck.sidechain = SPEECH_BUS
	duck.threshold = -30.0
	duck.ratio = 6.0
	duck.attack_us = 2000.0
	duck.release_ms = 250.0
	AudioServer.add_bus_effect(idx, duck)


func _make_player(id: String) -> AudioStreamPlayer:
	var path := path_for(id)
	if not ResourceLoader.exists(path):
		return null
	var wav := load(path) as AudioStream
	if wav == null:
		return null
	var stream: AudioStream = wav
	var vary := float(SOUNDS[id]["vary_db"])
	var vary_pitch := float(SOUNDS[id]["vary_pitch"])
	if vary > 0.0 or vary_pitch > 0.0:
		var rnd := AudioStreamRandomizer.new()
		rnd.add_stream(-1, wav)
		# Picks a pitch scale between 1 / random_pitch and random_pitch per play.
		rnd.random_pitch = 1.0 + vary_pitch
		rnd.random_volume_offset_db = vary
		stream = rnd
	var p := AudioStreamPlayer.new()
	p.name = "Sfx_" + id
	p.stream = stream
	p.bus = DUCK_BUS if bool(SOUNDS[id]["duck"]) else BUS
	p.max_polyphony = 2
	return p
