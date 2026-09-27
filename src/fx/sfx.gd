class_name Sfx
extends Node

## The few sound effects the app plays (docs/SFX_PLAN.md): session start,
## answer correct / wrong, results pass / fail, and an exam-clock warning. They
## live on their own "SFX" bus, separate from the voice, with one pre-loaded
## player each so a cue never waits on a load. Only the clock warning can
## overlap the voice (starting a session, answers and results stop it first,
## and auto-read waits past the start cue), so only the warning goes through
## the ducker: a compressor keyed by the Speech bus stays clamped for a while
## after the voice is cut off, and would swallow an answer tone fired in that
## same instant. The
## static part is the sound map and the rules for when a cue plays; it is pure
## and unit-tested. Every instance method is a quiet no-op without a tree, bus
## or imported asset (headless harness).
##
## Assets are synthesized by tools/sfx/make_sfx.py (CC0), except start.wav, a
## sourced recording (Pixabay Content License); see assets/sfx/CREDITS.md. All
## are loudness-matched, so the trims below stay near zero.

const BUS := "SFX"
## Sub-bus of SFX carrying the sidechain ducker; only "duck" cues play on it.
const DUCK_BUS := "SFXDuck"
const SPEECH_BUS := "Speech"
const DIR := "res://assets/sfx/"

## db: trim on top of the bus level. vary_db: random level spread per play, so
## the 100th answer tone is not a byte-identical copy of the first. duck: the
## cue can play while the voice is still reading and is squeezed under it.
const SOUNDS := {
	"correct": {"db": 0.0, "vary_db": 1.0, "duck": false},
	"wrong": {"db": 0.0, "vary_db": 1.0, "duck": false},
	"warning": {"db": 0.0, "vary_db": 0.0, "duck": true},
	"pass": {"db": 0.0, "vary_db": 0.0, "duck": false},
	"fail": {"db": 0.0, "vary_db": 0.0, "duck": false},
	"start": {"db": 0.0, "vary_db": 0.0, "duck": false},
}
## Played by every menu mode button that starts a session (Widgets.add_mode_button).
const START := "start"

## Semitones the correct tone rises on a streak (index = streak, last entry
## holds): 3 in a row +2, 5 +4, 8 (a full streak meter) +5. The tone is a rising
## fourth, so every step stays in C major. Same asset, no new cue.
const STREAK_SEMITONES: Array[int] = [0, 0, 0, 2, 2, 4, 4, 4, 5]

## Applied only while a voice the Speech-bus ducker cannot hear is reading
## (Android / system TTS); about what the ducker takes off a recorded clip.
const VOICE_DUCK_DB := -8.0
## Exam-clock seconds left at which the warning plays once: 5:00 is where the
## clock turns red, 1:00 is the last call.
const WARN_AT_SECONDS: Array[int] = [300, 60]

var enabled := true
## Returns true while a voice outside the Speech bus (system TTS) is reading;
## set by the host. Recorded clips on the Speech bus are ducked by DUCK_BUS.
var voice_active: Callable = Callable()
var _players: Dictionary = {}


static func path_for(id: String) -> String:
	return DIR + id + ".wav"


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
	return VOICE_DUCK_DB if voice_on and bool(SOUNDS[id]["duck"]) else 0.0


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


## Returns whether a cue was started (false when off, unknown or not loaded).
func play(id: String, pitch: float = 1.0) -> bool:
	if not enabled or not _players.has(id) or not is_inside_tree():
		return false
	var voice_on := voice_active.is_valid() and bool(voice_active.call())
	var p: AudioStreamPlayer = _players[id]
	p.volume_db = float(SOUNDS[id]["db"]) + voice_offset_db(id, voice_on)
	p.pitch_scale = pitch
	p.play()
	return true


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
	if vary > 0.0:
		var rnd := AudioStreamRandomizer.new()
		rnd.add_stream(-1, wav)
		rnd.random_pitch = 1.0
		rnd.random_volume_offset_db = vary
		stream = rnd
	var p := AudioStreamPlayer.new()
	p.name = "Sfx_" + id
	p.stream = stream
	p.bus = DUCK_BUS if bool(SOUNDS[id]["duck"]) else BUS
	p.max_polyphony = 2
	return p
