class_name Sfx
extends Node

## The few sound effects the app plays (docs/SFX_PLAN.md): answer correct /
## wrong, results pass / fail, and an exam-clock warning. They live on their own
## "SFX" bus, separate from the voice, with one pre-loaded player each so a cue
## never waits on a load. The static part is the sound map and the rules for
## when a cue plays; it is pure and unit-tested. Every instance method is a
## quiet no-op without a tree, bus or imported asset (headless harness).
##
## Assets are synthesized by tools/make_sfx.py (CC0, see sfx/CREDITS.md) and
## loudness-matched there, so the trims below stay near zero.

const BUS := "SFX"
const SPEECH_BUS := "Speech"
const DIR := "res://sfx/"

## db: trim on top of the bus level. vary_db: random level spread per play, so
## the 100th answer tone is not a byte-identical copy of the first.
const SOUNDS := {
	"correct": {"db": 0.0, "vary_db": 1.0},
	"wrong": {"db": 0.0, "vary_db": 1.0},
	"warning": {"db": 0.0, "vary_db": 0.0},
	"pass": {"db": 0.0, "vary_db": 0.0},
	"fail": {"db": 0.0, "vary_db": 0.0},
}

const VOICE_DUCK_DB := -10.0
## Exam-clock seconds left at which the warning plays once: 5:00 is where the
## clock turns red, 1:00 is the last call.
const WARN_AT_SECONDS: Array[int] = [300, 60]

var enabled := true
## Returns true while the voice is reading; set by the host.
var voice_active: Callable = Callable()
var _players: Dictionary = {}


static func path_for(id: String) -> String:
	return DIR + id + ".wav"


## Listen mode is ungraded and the voice reads the answer next, so it is silent.
static func answer_sound(graded: bool, is_right: bool) -> String:
	if not graded:
		return ""
	return "correct" if is_right else "wrong"


static func result_sound(passed: bool) -> String:
	return "pass" if passed else "fail"


static func time_warning(timed: bool, exam_left: int) -> bool:
	return timed and WARN_AT_SECONDS.has(exam_left)


## Volume offset for a cue given the voice state; NAN means "unknown cue".
static func voice_offset_db(id: String, voice_on: bool) -> float:
	if not SOUNDS.has(id):
		return NAN
	return VOICE_DUCK_DB if voice_on else 0.0


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
func play(id: String) -> bool:
	if not enabled or not _players.has(id) or not is_inside_tree():
		return false
	var voice_on := voice_active.is_valid() and bool(voice_active.call())
	var p: AudioStreamPlayer = _players[id]
	p.volume_db = float(SOUNDS[id]["db"]) + voice_offset_db(id, voice_on)
	p.play()
	return true


func _ensure_bus() -> void:
	if AudioServer.get_bus_index(BUS) >= 0:
		return
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, BUS)
	AudioServer.set_bus_send(idx, "Master")
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
	p.bus = BUS
	p.max_polyphony = 2
	return p
