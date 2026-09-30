extends RefCounted
## What the voice says for one step of a math solution (MathStepsView's Read):
## the title, the sentence or working line, the worked lines, the note, then the
## calculator keys one by one ("277, times, 1.732, equals, memory plus"). Every
## part ends a sentence, so the voice pauses between them instead of running
## "6,500 volt amperes On the calculator" together. Exam-question steps are
## bundled under folder_id(); generated trainer problems stream live.

const SpeechText = preload("res://src/speech/speech_text.gd")

const KEY_WORDS := {
	"×": "times", "÷": "divided by", "+": "plus", "−": "minus", "-": "minus",
	"=": "equals", "%": "percent", "√": "square root", "x²": "x squared",
	"1/x": "one over x", "^": "to the power of", "yˣ": "y to the x",
	"(": "open parenthesis", ")": "close parenthesis",
	"M+": "memory plus", "M-": "memory minus", "M−": "memory minus",
	"MR": "memory recall", "MC": "memory clear", "±": "change sign", "+/-": "change sign",
}


## The one-segment speech plan for a step, stamped like every other plan.
static func plan(step: Dictionary) -> Array:
	return [{"text": spoken(step), "choice": -1, "teach": false, "rules": SpeechText.RULES_VERSION}]


static func spoken(step: Dictionary) -> String:
	var parts: PackedStringArray = []
	for field in ["title", "text"]:
		_add(parts, str(step.get(field, "")))
	for line in step.get("lines", []):
		_add(parts, str(line))
	_add(parts, str(step.get("note", "")))
	var keys := str(step.get("keys", "")).strip_edges()
	if keys != "":
		_add(parts, "On the calculator, press " + key_words(keys))
	var basic := str(step.get("basic", "")).strip_edges()
	if basic != "":
		_add(parts, "On a basic calculator, press " + key_words(basic))
	return " ".join(parts)


## "277 × 1.732 = M+" -> "277, times, 1.732, equals, memory plus".
static func key_words(keys: String) -> String:
	var words: PackedStringArray = []
	for key in keys.split(" ", false):
		words.append(str(KEY_WORDS.get(key, key)))
	return ", ".join(words)


## The bundle / cache folder id of an exam question's step.
static func folder_id(record_id: String, step_index: int) -> String:
	return "math_%s_s%d" % [record_id.replace("/", "_").replace("\\", "_"), step_index]


## A generated problem's step has no record: its text names the cache folder.
static func live_id(step: Dictionary) -> String:
	return "math_live_" + spoken(step).md5_text().substr(0, 12)


## Each part is worded on its own: the rules drop the dot of "80 ft." or
## "3.5 in.", so the sentence end is put back after them.
static func _add(parts: PackedStringArray, text: String) -> void:
	text = SpeechText.speakable(text.strip_edges()).strip_edges()
	text = text.trim_suffix(":").trim_suffix(";").trim_suffix(",").strip_edges()
	if text == "":
		return
	if not (text.ends_with(".") or text.ends_with("?") or text.ends_with("!")):
		text += "."
	parts.append(text)
