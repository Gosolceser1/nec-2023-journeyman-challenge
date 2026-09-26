"""One-shot migration: align every MEMORY TIP with its record's answer.

Problem: tips were topic templates ending in a generic "The blank asks ..." tail,
so none of them named or explained the record's correct answer.

Fix per record (post-answer only, so naming the answer is safe):
    <topic principle>. Correct: <L> — <answer>. [<correct choice note>]
    [Not <X>: <distractor note>. ...]

- Principles are rewritten per concept: true for every record in the topic, no
  generic tails (audited: the old "within 50 ft", "10-50 A", "demand factors" and
  "83% break" claims were false for some of their records).
- Choice notes are appended only when substantive (>=25 chars and not a mere
  restatement of the choice itself).
- Tips that already name their answer (hand-written NEC cites) are left untouched.
- Every composed tip is echo-guarded with the same matcher the game UI uses, so a
  tip that would merely requote CODE PROVISION/gist falls back instead of printing
  the same sentence twice on screen.

Also rewrites CONCEPT_SHORT in build_question_bank.py to the new principles so
future rebuilds stay aligned. Run from the project folder:
    python tools/fix_memory_tips.py
"""

import ast
import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BANK = ROOT / "question_bank.json"
BUILDER = ROOT / "tools" / "build_question_bank.py"

LETTERS = ["A", "B", "C", "D"]

# Mirrors audio_explanation_generator.gd::_is_duplicate_text stopwords.
STOPWORDS = {"the", "and", "for", "with", "that", "this", "from", "answer",
             "correct", "shall", "within", "have", "has", "are", "was", "were",
             "will", "must", "than", "then"}

NEW_PRINCIPLES = {
    "isolated_ground": "An isolated-ground outlet runs its ground wire separately back to the panel to keep electrical noise away from sensitive electronics — look for the orange triangle.",
    "receptacle_rules": "The NEC puts outlets where people need them so cords never stretch across rooms.",
    "cable_types": "MI = Mineral-Insulated, MC = Metal-Clad, NM = Nonmetallic-sheathed, UF = Underground Feeder, SE = Service-Entrance, AC = Armored Cable.",
    "grounding_basics": "Grounding connects the electrical system to earth; bonding connects metal parts so fault current opens the overcurrent device quickly.",
    "raceway_rules": "EMT = thin-wall tubing, RMC = rigid steel, IMC = intermediate, FMC = Flexible Metal Conduit, ENT = plastic tubing, RNC = PVC.",
    "outside_clearances": "Article 225 sets one clearance rule for doors and similar locations and a separate restriction for material-handling openings.",
    "conduit_fill_table": "Find the TFN/THHN/THWN group, read the AWG row, and check the inside/outside fitting column. A dash means that combination is not listed.",
    "gfci_basics": "A GFCI trips when current leaks — through water or a person.",
    "afci_basics": "An AFCI detects arc faults in wiring and opens the circuit before ignition.",
    "motor_basics": "Motors require overload protection sized from nameplate current, separate from short-circuit and ground-fault protection.",
    "load_calc_basics": "Start from the Code's unit value for the occupancy, then apply only the demand the question allows — and skip factors it tells you to disregard.",
    "disconnect_basics": "Every major equipment needs a lockable disconnect within sight — match the question to the right rule (motor, service, or appliance).",
    "pool_basics": "Pool and spa areas require bonding of metal parts and ground-fault protection of electrical equipment.",
    "working_space": "Working space requires minimum depth in front, 30 inches of width, 6-1/2 feet of headroom, and an exit path.",
    "hazloc": "Gas = Class I, dust = Class II, fibers = Class III; normal conditions = Division 1, abnormal = Division 2.",
    "flex_cords": "Flexible cords are for temporary use: short runs, continuous length, matched to the load and environment (SJ light-duty, ST heavy-duty, W weather-rated).",
    "electrical_theory": "Translate the units, pick the one relationship the question tests, and calculate before selecting.",
    "boxes_enclosures": "Enclosure size is determined by conductor volume; equipment is restricted to its own section.",
    "round_boxes": "Article 314.2 prohibits round boxes where a side entry needs a locknut or bushing. Check the word NOT carefully when comparing the choices.",
    "lighting_temp": "Luminaires generate heat and use breakable parts, so the Code requires guards and listing of decorative lighting.",
    "switch_basics": "Switches are rated by what they interrupt — inductive loads get only half the rating.",
    "transformer_service": "Dwelling services may count only part of the load; transformers wear nameplates and need visible disconnects.",
    "branch_circuits": "A circuit takes its rating from its fuse or breaker — match the load to the right circuit type and size.",
    "appliance_basics": "Appliances use short cords, dedicated circuits, and demand tables instead of nameplate math.",
    "connections": "Terminations must be torqued, connectors listed, and splices enclosed.",
    "safety_basics": "You can't see electricity — plan, lock out, verify dead, use insulated tools.",
    "nec_vocab": "Article 100 definitions are exact: match every word of the description to the term.",
    "special_systems": "Flat cables, busways, wireways, and gutters each have their own article.",
    "lowvoltage_basics": "Small energy, easier rules — but still separated from power wiring.",
    "antenna_basics": "Antenna masts must withstand weather and fall clear of power conductors.",
    "emergency_basics": "Backup power must work when normal power fails and stay independent of it.",
    "sign_basics": "Signs need sound structure, clearances from heat, and a disconnect.",
    "elevator_basics": "Elevator motors work intermittently, so sizing follows duty ratings.",
    "xray_basics": "X-ray equipment draws brief high-current pulses, so feeders follow momentary ratings while small-gauge control conductors keep low-rated protection.",
    "listing_basics": "Listed means lab-tested for one purpose — use it only that way.",
    "drawings_basics": "Start at the upper left, check scale and legend.",
    "overcurrent_basics": "Branch overcurrent devices protect conductors; supplementary devices protect equipment internals only and cannot replace branch protection.",
}


def _norm(text):
    cleaned = []
    for ch in text.lower():
        cleaned.append(ch if ch.isalnum() or ch == " " else " ")
    return re.sub(r"\s+", " ", "".join(cleaned)).strip()


def _is_word_char(c):
    return bool(c) and (c.lower() != c.upper() or c.isdigit())


def _find_spans(text, needle):
    """Boundary-aware occurrences of needle in text (mirrors find_match_in)."""
    spans = []
    low_text, low_needle = text.lower(), needle.lower()
    start = 0
    while start <= len(text) - len(needle):
        idx = low_text.find(low_needle, start)
        if idx < 0:
            break
        before = text[idx - 1] if idx > 0 else ""
        after_index = idx + len(needle)
        after = text[after_index] if after_index < len(text) else ""
        left_ok = (not _is_word_char(needle[0])) or (not _is_word_char(before))
        right_ok = (not _is_word_char(needle[-1])) or (not _is_word_char(after))
        if left_ok and right_ok:
            spans.append((idx, after_index))
            start = after_index
        else:
            start = idx + 1
    return spans


def _is_dupe(a, b):
    na, nb = _norm(a), _norm(b)
    if not na or not nb:
        return False
    if na == nb or na in nb or nb in na:
        return True
    wa, wb = na.split(), nb.split()
    short, long_text = (wa, nb) if len(wa) <= len(wb) else (wb, na)
    meaning = [w for w in short if len(w) > 2 and w not in STOPWORDS]
    if len(meaning) < 3:
        return False
    hits = sum(1 for w in meaning if w in long_text)
    return hits / len(meaning) >= 0.85


def _echoes_any(line, others):
    return any(o.strip() and _is_dupe(line, o) for o in others)


def _substantive_note(note, choice):
    s = str(note or "").strip()
    if len(s) < 25:
        return ""
    if _is_dupe(s, str(choice or "")):
        return ""
    return s if s.endswith(".") else s + "."


def _parse_concept_shorts(path):
    tree = ast.parse(path.read_text(encoding="utf-8"))
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign) and getattr(node.targets[0], "id", "") == "CONCEPT_SHORT":
            return ast.literal_eval(node.value)
    raise SystemExit("CONCEPT_SHORT not found in builder")


def main():
    old_shorts = _parse_concept_shorts(BUILDER)  # key -> (title, tip)
    old_tip_to_key = {tip: key for key, (_t, tip) in old_shorts.items()}

    missing = [k for k in NEW_PRINCIPLES if k not in old_shorts]
    if missing:
        print("WARNING: new principles without builder key:", missing)

    data = json.loads(BANK.read_text(encoding="utf-8"))
    recs = data.get("records", [])

    stats = {"kept_good": 0, "rewritten": 0, "fallback_slim": 0, "fallback_verdict": 0, "unknown_kept": 0}
    for r in recs:
        answers = r.get("answers", [])
        ci = int(r.get("correct_index", -1))
        if ci < 0 or ci >= len(answers):
            continue
        answer = str(answers[ci])
        letter = LETTERS[ci] if ci < len(LETTERS) else str(ci + 1)
        tip = str(r.get("tip_short", ""))

        # Already aligned (names its answer, e.g. hand-written NEC cites): keep.
        if len(tip) >= 60 and _find_spans(tip, answer):
            stats["kept_good"] += 1
            continue

        key = old_tip_to_key.get(tip)
        if key is None or key not in NEW_PRINCIPLES:
            stats["unknown_kept"] += 1
            continue

        principle = NEW_PRINCIPLES[key]
        notes = r.get("choice_notes", []) or []

        verdict = " Correct: %s — %s." % (letter, answer)
        correct_note = _substantive_note(notes[ci] if ci < len(notes) else "", answer)
        extra = (" " + correct_note) if correct_note else ""
        for i, choice in enumerate(answers):
            if i == ci or i >= len(notes):
                continue
            note = _substantive_note(notes[i], choice)
            if note:
                tag = LETTERS[i] if i < len(LETTERS) else str(i + 1)
                extra += " Not %s: %s" % (tag, note)

        source = str(r.get("reference_text", ""))
        gist = str(r.get("gist", ""))
        full = principle + verdict + extra
        if _echoes_any(full, [source, gist]):
            full = principle + verdict  # slim: principle + verdict only
            stats["fallback_slim"] += 1
            if _echoes_any(full, [source, gist]):
                full = "Correct: %s — %s." % (letter, answer)
                stats["fallback_verdict"] += 1
        r["tip_short"] = full
        stats["rewritten"] += 1

    # Rewrite CONCEPT_SHORT principles in the builder so rebuilds stay aligned.
    builder_text = BUILDER.read_text(encoding="utf-8")
    patched = 0
    for key, (_title, old_tip) in old_shorts.items():
        if key not in NEW_PRINCIPLES or old_tip == NEW_PRINCIPLES[key]:
            continue
        if builder_text.count(old_tip) != 1:
            print("WARNING: builder tip not unique, skipped:", key)
            continue
        builder_text = builder_text.replace(old_tip, NEW_PRINCIPLES[key])
        patched += 1
    BUILDER.write_text(builder_text, encoding="utf-8")

    BANK.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    print("records:", len(recs), "| stats:", json.dumps(stats))
    print("builder principles patched:", patched)


if __name__ == "__main__":
    main()
