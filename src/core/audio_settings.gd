class_name AudioSettings
extends RefCounted
## Study-audio preferences picked in the main menu, plus the pure rules that
## decide when the app is allowed to speak. The voice itself stays in
## user://voice.cfg (see VoiceCatalog); everything else lives here.

enum Mode { SILENT, TAP, AUTO, LISTEN }
## Hands-free loop: read question -> think pause -> reveal + read the rule ->
## short gap -> next question.
enum ListenPhase { IDLE, QUESTION, THINK, TEACH, GAP }

const PATH := "user://audio.cfg"
## Bumped when a stored default changes meaning. Version 2: Auto-read reads the
## rule after answering by default; configs written before it (no version key)
## often carry auto_teach=false from the old default, not from a user choice.
const CONFIG_VERSION := 2
const SPEEDS: Array[float] = [0.9, 1.0, 1.15, 1.3]
const THINK_PAUSES: Array[int] = [5, 10, 15]
const LISTEN_GAP_SECONDS := 2
## UI sound effects: independent of the voice mode (Silent mutes the voice, not
## the clicks). Levels are the SFX bus volume; per-sound trims live in Sfx.
const SFX_LEVEL_TITLES: Array[String] = ["Low", "Medium", "High"]
const SFX_LEVEL_DB: Array[float] = [-12.0, -6.0, -1.0]
const SFX_DEFAULT_LEVEL := 1
const MODE_TITLES := {
	Mode.SILENT: "Silent",
	Mode.TAP: "Tap to hear",
	Mode.AUTO: "Auto-read",
	Mode.LISTEN: "Listen",
}
const MODE_BLURBS := {
	Mode.SILENT: "Text only. No audio unless you turn sound on from the quiz dock. Best for the library, job site breaks, or real-exam feel.",
	Mode.TAP: "Nothing plays by itself. Tap \"Read question\" to hear the question, or \"Hear the rule\" after answering.",
	Mode.AUTO: "Each question and its choices are read aloud as soon as they appear. You still answer by tapping, and then the answer and the rule are read to you.",
	Mode.LISTEN: "Hands-free for headphones while you work: reads the question, pauses so you can think, says the answer and the rule, then moves on. Untimed and not graded.",
}

var mode: int = Mode.SILENT
var speed: float = 1.0
var think_pause: int = 10
## Auto-read only: also read the explanation right after answering.
var auto_teach: bool = true
var sfx_enabled: bool = true
var sfx_level: int = SFX_DEFAULT_LEVEL
## Answer and results effects without shake, pop, sparks or confetti. Stored in
## the same file (section "display"); until the learner picks, it follows the
## OS "reduce motion / remove animations" switch.
var reduce_motion: bool = system_reduce_motion()
var reduce_motion_picked := false
## Color the code-book Index keywords in the stem and name their Index entry
## before answering (section "study"). Never shown in the Full Exam.
var hunt_keywords := true


static func sanitize_mode(value) -> int:
	var m := int(value) if (value is int or value is float) else Mode.SILENT
	return m if m >= Mode.SILENT and m <= Mode.LISTEN else Mode.SILENT


## Snaps any stored number to the nearest offered speed, so a hand-edited or
## stale config can never push playback to an unsupported rate.
static func sanitize_speed(value) -> float:
	if not (value is int or value is float):
		return 1.0
	var best: float = SPEEDS[0]
	for s in SPEEDS:
		if absf(s - float(value)) < absf(best - float(value)):
			best = s
	return best


static func sanitize_pause(value) -> int:
	if not (value is int or value is float):
		return 10
	var best: int = THINK_PAUSES[0]
	for p in THINK_PAUSES:
		if absf(p - float(value)) < absf(best - float(value)):
			best = p
	return best


## The real exam has no audio at all, so the simulator never autoplays or runs
## hands-free; the Read button stays available as an accessibility aid.
static func session_mode(picked: int, is_exam: bool) -> int:
	if is_exam and (picked == Mode.AUTO or picked == Mode.LISTEN):
		return Mode.TAP
	return picked


static func autoplays_question(m: int) -> bool:
	return m == Mode.AUTO or m == Mode.LISTEN


## Teach audio narrates the answer, so it may only ever start after answering.
static func autoplays_teach(m: int, teach_after_answer: bool) -> bool:
	return m == Mode.LISTEN or (m == Mode.AUTO and teach_after_answer)


static func grades_answers(m: int) -> bool:
	return m != Mode.LISTEN


static func starts_muted(m: int) -> bool:
	return m == Mode.SILENT


static func listen_next(phase: int) -> int:
	match phase:
		ListenPhase.QUESTION:
			return ListenPhase.THINK
		ListenPhase.THINK:
			return ListenPhase.TEACH
		ListenPhase.TEACH:
			return ListenPhase.GAP
		ListenPhase.GAP:
			return ListenPhase.QUESTION
	return ListenPhase.IDLE


## Playback speed is applied on the player (pitch_scale), which also raises the
## pitch; a pitch-shift effect on the speech bus undoes that by 1/speed.
static func pitch_compensation(playback_speed: float) -> float:
	return 1.0 / maxf(playback_speed, 0.1)


static func speed_label(s: float) -> String:
	return ("%.2f" % s).rstrip("0").rstrip(".") + "×"


static func sanitize_sfx_level(value) -> int:
	if not (value is int or value is float):
		return SFX_DEFAULT_LEVEL
	return clampi(roundi(float(value)), 0, SFX_LEVEL_DB.size() - 1)


static func sfx_bus_db(level: int) -> float:
	return SFX_LEVEL_DB[sanitize_sfx_level(level)]


static func sfx_label(on: bool, level: int) -> String:
	return "Sounds %s" % (SFX_LEVEL_TITLES[sanitize_sfx_level(level)].to_lower() if on else "off")


## 1 = the OS asks for less animation; 0 = no; -1 = unknown (headless, old OS).
static func system_reduce_motion() -> bool:
	return DisplayServer.accessibility_should_reduce_animation() == 1


func load_from(path: String = PATH) -> void:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return
	mode = sanitize_mode(config.get_value("audio", "mode", Mode.SILENT))
	speed = sanitize_speed(config.get_value("audio", "speed", 1.0))
	think_pause = sanitize_pause(config.get_value("audio", "think_pause", 10))
	var teach = config.get_value("audio", "auto_teach", true)
	auto_teach = teach if teach is bool else true
	if int(config.get_value("audio", "version", 1)) < CONFIG_VERSION:
		auto_teach = true
	var sfx_on = config.get_value("audio", "sfx_enabled", true)
	sfx_enabled = sfx_on if sfx_on is bool else true
	sfx_level = sanitize_sfx_level(config.get_value("audio", "sfx_level", SFX_DEFAULT_LEVEL))
	var calm = config.get_value("display", "reduce_motion") if config.has_section_key("display", "reduce_motion") else null
	reduce_motion_picked = calm is bool
	reduce_motion = calm if calm is bool else system_reduce_motion()
	var hunt = config.get_value("study", "hunt_keywords", true)
	hunt_keywords = hunt if hunt is bool else true


func save_to(path: String = PATH) -> Error:
	var config := ConfigFile.new()
	config.set_value("audio", "version", CONFIG_VERSION)
	config.set_value("audio", "mode", mode)
	config.set_value("audio", "speed", speed)
	config.set_value("audio", "think_pause", think_pause)
	config.set_value("audio", "auto_teach", auto_teach)
	config.set_value("audio", "sfx_enabled", sfx_enabled)
	config.set_value("audio", "sfx_level", sfx_level)
	if reduce_motion_picked:
		config.set_value("display", "reduce_motion", reduce_motion)
	config.set_value("study", "hunt_keywords", hunt_keywords)
	return config.save(path)
