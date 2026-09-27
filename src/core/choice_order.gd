class_name ChoiceOrder
extends RefCounted
## Answer-choice shuffling. A permutation maps display slot -> original choice
## index; the bank record is never changed, a display copy is built from it.
##
## Never moved:
## - a whole question whose choices point at other choices by letter or at
##   labels ("Both (b) and (c)", "Diagram A", "I, II, or III"), or whose
##   explanation names a choice by letter ("choice C states ...");
## - a single choice that sums up the others ("all of these", "none of the
##   above", "both AFCI and GFCI"): it keeps its slot, the rest shuffle.

const LETTERS := ["A", "B", "C", "D"]

static var _re_cache: Dictionary = {}


static func _re(pattern: String) -> RegEx:
	if not _re_cache.has(pattern):
		var re := RegEx.new()
		re.compile(pattern)
		_re_cache[pattern] = re
	return _re_cache[pattern]


## True when the choices must stay in bank order.
static func is_locked(record: Dictionary) -> bool:
	for a in record.get("answers", []):
		var text := str(a)
		# Lower case only: "(A)" is an NEC paragraph, "(b)" a choice.
		if _re("\\([a-d]\\)").search(text) != null:
			return true
		if _re("\\b[A-D]\\s*(,|and|or|&)\\s*[A-D]\\b").search(text) != null:
			return true
		if _re("\\b(?i:choice|option|answer|diagram|figure|item|label)s?\\s+[A-D]\\b").search(text) != null:
			return true
		if _re("^(I|II|III|IV)\\b(,| only| and| or)").search(text) != null:
			return true
	var notes = record.get("choice_notes", [])
	var texts: Array = notes.duplicate() if notes is Array else []
	for field in ["tip_short", "worked", "formula", "gist", "info_tip", "lookup_summary", "reference_text"]:
		texts.append(str(record.get(field, "")))
	for t in texts:
		if _re("\\b(?i:choice|option|answer)s?\\s+(\\([a-dA-D]\\)|[A-D])(?![\\w(])").search(str(t)) != null:
			return true
	return false


## True for a choice that sums up or combines the other choices.
static func is_pinned_choice(text: String) -> bool:
	var t := text.strip_edges()
	return _re("(?i)^(all|none|any|either|neither) of (the above|these|them|the preceding)\\b").search(t) != null \
		or _re("(?i)^both\\b.+\\band\\b").search(t) != null \
		or _re("(?i)^neither\\b.+\\bnor\\b").search(t) != null


static func identity(record: Dictionary) -> Array[int]:
	var perm: Array[int] = []
	for i in (record.get("answers", []) as Array).size():
		perm.append(i)
	return perm


## A random display order: pinned choices keep their slot, the rest shuffle
## among the free slots. Locked questions come back in bank order.
static func shuffled(record: Dictionary, rng: RandomNumberGenerator) -> Array[int]:
	var perm := identity(record)
	if is_locked(record):
		return perm
	var answers: Array = record.get("answers", [])
	var free: Array[int] = []
	for i in answers.size():
		if not is_pinned_choice(str(answers[i])):
			free.append(i)
	var moved := free.duplicate()
	for i in range(moved.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: int = moved[i]
		moved[i] = moved[j]
		moved[j] = t
	for k in free.size():
		perm[free[k]] = moved[k]
	return perm


## The record as shown: answers and choice_notes in display order,
## correct_index pointing at the display slot, and the letters in the tip's
## "Correct: B —" / "Not A:" markers renamed to match.
static func apply(record: Dictionary, perm: Array) -> Dictionary:
	var answers: Array = record.get("answers", [])
	if perm.size() != answers.size():
		return record
	var shown := record.duplicate()
	var shown_answers: Array = []
	for d in perm.size():
		shown_answers.append(answers[perm[d]])
	shown["answers"] = shown_answers
	var notes = record.get("choice_notes", null)
	if notes is Array and (notes as Array).size() == perm.size():
		var shown_notes: Array = []
		for d in perm.size():
			shown_notes.append(notes[perm[d]])
		shown["choice_notes"] = shown_notes
	shown["correct_index"] = perm.find(int(record.get("correct_index", -1)))
	var tip := str(record.get("tip_short", ""))
	if tip != "":
		var marker := _re("(Correct: |Not )([A-D])(?= —|:)")
		var out := ""
		var at := 0
		for m in marker.search_all(tip):
			var orig := LETTERS.find(m.get_string(2))
			var d := perm.find(orig)
			out += tip.substr(at, m.get_start() - at) + m.get_string(1) + (LETTERS[d] if d >= 0 and d < LETTERS.size() else m.get_string(2))
			at = m.get_end()
		shown["tip_short"] = out + tip.substr(at)
	return shown
