import json
import os
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pipeline_paths import answer_key_ocr_dir, exam_ocr_dir, nec_data
from bank_overrides import apply_overrides
from exam_parser import read_key, read_questions
from exam_sources import discover, record_id
from state_law_source import load_all as load_state_law

ROOT = Path(__file__).resolve().parents[2]
OCR = exam_ocr_dir()
KEYS = answer_key_ocr_dir()
OUT = Path(os.environ.get("WIRE_BANK_OUT", str(ROOT / "data" / "question_bank.json")))
if OUT.resolve() == (ROOT / "data" / "question_bank.json").resolve():
    raise SystemExit("Refusing to write over the curated bank; set WIRE_BANK_OUT to a candidate file.")

EXAMS = discover()
QUESTION_COUNTS = {exam.label: exam.question_count(OCR) for exam in EXAMS}
ID_PREFIXES = {exam.label: exam.id_prefix for exam in EXAMS}

def _load(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))

# Draft-generation data: edition-neutral vocabulary next to the builder, and
# the edition's provisions, concept notes and answer glossary in data/nec/<year>/.
VOCABULARY = _load(Path(__file__).with_name("draft_vocabulary.json"))
KEYWORD_TERMS = [tuple(t) for t in VOCABULARY["keyword_terms"]]
SUBJECT_LABELS = [tuple(t) for t in VOCABULARY["subject_labels"]]
CONCEPTS = _load(nec_data("concepts.json"))
CONCEPT_NOTES = CONCEPTS["notes"]
CONCEPT_SHORT = CONCEPTS["short"]
CONCEPT_TRIGGERS = [tuple(t) for t in CONCEPTS["triggers"]]
ARTICLE_CONCEPTS = [tuple(t) for t in CONCEPTS["article_concepts"]]
PROVISIONS = _load(nec_data("provisions.json"))
REFERENCE_TEXTS = PROVISIONS["texts"]
REFERENCE_TABLES = PROVISIONS["tables"]
ANSWER_GLOSSARY = _load(nec_data("answer_glossary.json"))["glossary"]

def extract_lookup(prompt, answers, article):
    text = (prompt + " " + " ".join(answers)).lower()
    terms = []
    for needle, label in KEYWORD_TERMS:
        if needle.lower() in text and label not in terms:
            terms.append(label)
    if not terms:
        terms.append("identify the equipment, location, and requirement")
    terms = terms[:4]
    summary = "Lookup clues: %s. Start with %s, then read the matching subsection and exceptions." % (", ".join(terms), article)
    return terms, summary

def find_subject(text):
    for needle, label in SUBJECT_LABELS:
        if needle in text:
            return label
    return ""

def find_measures(text):
    found = re.findall(
        r"\d[\d,]*(?:\.\d+)?\s*(?:ft|feet|inch|inches|\"|'|"
        r"volts?|amps?|amperes?|watts?|kva|va\b|hp|%|percent|"
        r"sq\.?\s*ft|degrees?\s*[cf])",
        text,
    )
    seen = []
    for item in found:
        item = re.sub(r"\s+", " ", item).strip()
        if item not in seen:
            seen.append(item)
    return seen[:3]

def concept_key_for(text, article=""):
    scrubbed = text.replace("ungrounded", "##")
    for needle, key in CONCEPT_TRIGGERS:
        haystack = scrubbed if key == "grounding_basics" else text
        if needle in haystack:
            return key
    match = re.search(r"\b(\d{3})\b", article)
    if match:
        for prefix, key in ARTICLE_CONCEPTS:
            if match.group(1).startswith(prefix):
                return key
    return ""

TIP_LETTERS = ["A", "B", "C", "D"]

def _tip_note_ok(note, choice):
    s = str(note or "").strip()
    if len(s) < 25:
        return ""
    if s.lower() in str(choice or "").lower() or str(choice or "").lower() in s.lower():
        return ""
    return s if s.endswith(".") else s + "."

def concept_tip_short(concept_key, choices, correct_index):
    # Principle + per-record verdict, mirroring the retired fix_memory_tips.py so rebuilds
    # stay answer-aligned: "Correct: <L> — <answer>." plus substantive choice notes.
    principle = CONCEPT_SHORT.get(concept_key, ("In plain language", ""))[1]
    if not isinstance(choices, list) or correct_index < 0 or correct_index >= len(choices):
        return principle
    notes = choice_notes_for(choices)
    answer = str(choices[correct_index])
    letter = TIP_LETTERS[correct_index] if correct_index < len(TIP_LETTERS) else str(correct_index + 1)
    tip = principle.rstrip()
    if tip and not tip.endswith("."):
        tip += "."
    tip += " Correct: %s — %s." % (letter, answer)
    if correct_index < len(notes):
        note = _tip_note_ok(notes[correct_index], answer)
        if note:
            tip += " " + note
    for i, choice in enumerate(choices):
        if i == correct_index or i >= len(notes):
            continue
        note = _tip_note_ok(notes[i], choice)
        if note:
            tag = TIP_LETTERS[i] if i < len(TIP_LETTERS) else str(i + 1)
            tip += " Not %s: %s" % (tag, note)
    return tip

def concept_note(text, article=""):
    key = concept_key_for(text, article)
    return CONCEPT_NOTES[key] if key else ""

def explain_question(prompt, keywords, article=""):
    text = prompt.lower()
    note = concept_note(text, article)
    subject = find_subject(text)
    measures = find_measures(text)
    detail = ""
    if subject:
        detail = " Subject: %s." % subject
    if measures:
        detail += " Numbers in the question: %s." % ", ".join(measures)
    if "unsupported" in text or "unsecured" in text:
        if "mc cable" in text and ("luminaire" in text or "fixture" in text):
            meaning = "This asks for the maximum length of Type MC cable that may hang unsupported near a luminaire. Look for the cable-support rule and identify the distance limit."
        else:
            meaning = ("This asks for the longest run allowed before the wiring must be supported or secured.%s "
                       "You are looking for a distance limit, so compare each answer choice against that maximum." % detail)
    elif "minimum number" in text or "maximum number" in text:
        meaning = ("This asks for a required count.%s "
                   "Decide what is being counted and whether the rule sets a floor or a ceiling, then pick the matching number." % detail)
    elif "more than" in text or "less than" in text or "at least" in text or "minimum" in text or "maximum" in text or "minimum" in text:
        limit = "maximum" if ("more than" in text or "maximum" in text) else "minimum"
        meaning = ("This is a %s-limit question.%s "
                   "The correct choice is the %s value the NEC allows — "
                   "eliminate any choice on the wrong side of that limit." % (limit, detail, limit))
    elif "ampacity" in text:
        meaning = ("This asks how many amps the conductor may safely carry under the stated conditions.%s "
                   "Apply temperature and adjustment factors first, then read the resulting ampacity." % detail)
    elif "voltage drop" in text:
        meaning = ("This asks what percentage of voltage is lost between source and load.%s "
                   "Divide the volts lost by the source volts." % detail)
    elif "load" in text and ("calculation" in text or "calculated" in text):
        meaning = ("This is a load-calculation question.%s "
                   "Find the unit load for the occupancy, multiply by the area or quantity, "
                   "and apply any demand factor the question allows." % detail)
    elif "ground fault" in text or "grounding" in text or "bonding" in text:
        meaning = ("This asks you to name the grounding or bonding part in this installation.%s "
                   "Trace the fault-current path: what connects the equipment back to the source?" % detail)
    elif "gfc" in text or "arc-fault" in text:
        device = "GFCI" if "gfc" in text else "AFCI"
        meaning = ("This asks where %s protection is required.%s "
                   "Match the location and equipment in the question to the list of places the NEC names." % (device, detail))
    elif "receptacle" in text or "outlet" in text:
        meaning = ("This asks for the receptacle rule in this spot.%s "
                   "Decide whether the question wants a location, a height, a count, or a protection requirement, "
                   "then match that to the rule." % detail)
    elif "motor" in text or "transformer" in text:
        meaning = ("This asks you to match this motor or transformer setup to its rule.%s "
                   "Identify whether the question is about protection size, conductor size, disconnect location, or marking." % detail)
    elif "cable" in text or "conduit" in text or "raceway" in text:
        meaning = ("This asks which wiring-method rule fits this installation.%s "
                   "Focus on whether the question is about support spacing, fill, burial cover, protection from damage, "
                   "or where the method is permitted." % detail)
    elif "mark" in text:
        meaning = ("This asks about a required marking or label.%s "
                   "Decide what must be marked, where the marking goes, and what it must say — "
                   "the answer is the location or wording the NEC specifies." % detail)
    elif "equivalent to" in text or ("%" in text and "circuit" not in text and "amp" not in text):
        meaning = ("This is a straight math conversion — no NEC lookup needed.%s "
                   "Convert the given value and match it to the equal choice." % detail)
    elif "disconnect" in text or "disconnecting means" in text:
        meaning = ("This asks about the disconnect for this equipment.%s "
                   "Decide whether the question wants its location, its height, its rating, or who may access it." % detail)
    elif "switch" in text:
        meaning = ("This asks which switch rule fits.%s "
                   "Check whether the question is about the ampere rating, the type of load, "
                   "or where and how the switch is installed." % detail)
    elif "listed" in text or "listing" in text:
        meaning = ("This asks what listing or marking the NEC demands here.%s "
                   "Look for the condition — location, use, or construction — that triggers the listing rule." % detail)
    elif "is defined as" in text or "is referred to as" in text or "is recognized as" in text:
        meaning = ("This asks for the NEC term that matches the description.%s "
                   "Read each choice as a vocabulary answer and pick the term the description defines." % detail)
    elif "color" in text:
        meaning = ("This asks which conductor color the NEC allows here.%s "
                   "Recall which colors are reserved (grounded, grounding) and which remain for ungrounded conductors." % detail)
    elif "which of the following" in text:
        meaning = ("Read the situation, then test each choice against it.%s "
                   "Eliminate choices that contradict the stated conditions; the survivor that fits all of them is the answer." % detail)
    else:
        short = prompt.strip()
        if len(short) > 140:
            short = short[:140].rsplit(" ", 1)[0] + "…"
        meaning = ("In plain terms, the question is: \"%s\"%s "
                   "Break it into pieces — what equipment, what location or measurement, "
                   "and what the NEC must say about it — then find the choice that satisfies every piece." % (short, detail))
    if note:
        meaning = "PLAIN-LANGUAGE BACKGROUND\n%s\n\n%s" % (note, meaning)
    return "WHAT THIS QUESTION MEANS\n%s\n\nLOOKUP FOCUS\n%s" % (meaning, ", ".join(keywords))


def _stem_paragraph(info_tip):
    """(index, prefix) of the paragraph of an explain_question() tip that restates the stem."""
    parts = info_tip.split("\n\n")
    if len(parts) < 2 or not parts[-1].startswith("LOOKUP FOCUS\n"):
        return None, parts
    return len(parts) - 2, parts


def restate_stem(info_tip, prompt, keywords, article=""):
    """info_tip with its stem paragraph rebuilt from prompt; the background note is kept."""
    i, parts = _stem_paragraph(info_tip)
    j, fresh = _stem_paragraph(explain_question(prompt, keywords, article))
    if i is None or j is None:
        return info_tip
    head = "WHAT THIS QUESTION MEANS\n"
    old, new = parts[i], fresh[j].removeprefix(head)
    parts[i] = head + new if old.startswith(head) else new
    return "\n\n".join(parts)

def reference_key(reference):
    clean = reference.replace("NEC ", "").strip()
    if clean in REFERENCE_TEXTS:
        return clean
    for suffix in (" Column 1", " Ex. 1", " Ex.", " Ex"):
        if clean.endswith(suffix) and clean[: -len(suffix)] in REFERENCE_TEXTS:
            return clean[: -len(suffix)]
    for key in sorted(REFERENCE_TEXTS, key=len, reverse=True):
        if clean.startswith(key):
            return key
    return clean

def reference_text(reference):
    return REFERENCE_TEXTS.get(reference_key(reference), "")

def reference_table(reference):
    return REFERENCE_TABLES.get(reference_key(reference), [])

def choice_notes_for(answers):
    notes = []
    for answer in answers:
        key = re.sub(r"\s+", " ", str(answer).strip().lower())
        notes.append(ANSWER_GLOSSARY.get(key, ""))
    return notes

# The edition's article titles: one table shared with the app and the validator.
NEC_ARTICLES = json.loads(nec_data("articles.json").read_text(encoding="utf-8"))
ARTICLE_TITLES = {int(number): title for number, title in NEC_ARTICLES["articles"].items()}

def article_title(reference):
    match = re.search(r"\b(\d{3})\b", reference)
    if not match:
        return reference
    return ARTICLE_TITLES.get(int(match.group(1)), "")

bank = []
missing = []
report = []
for exam in EXAMS:
    source = exam.label
    transcript = exam.transcript()
    if transcript is not None:
        # Reviewed text of the exam: replaces the OCR parse for this exam.
        typed = {item["number"]: item for item in transcript["questions"]}
        questions = {n: {"prompt": q["prompt"], "choices": q["answers"]} for n, q in typed.items()}
        answers = {n: q["correct_index"] for n, q in typed.items()}
        answers.update({k["number"]: k["correct_index"] for k in transcript.get("key_only", [])})
        refs = {n: q["reference"] for n, q in typed.items()}
    else:
        questions = read_questions(exam.ocr_path(OCR), QUESTION_COUNTS[source])
        answers, refs = read_key(exam.key_ocr_path(KEYS), QUESTION_COUNTS[source])
    for number in range(1, QUESTION_COUNTS[source] + 1):
        if number not in questions:
            missing.append({"source": source, "number": number, "answer_index": answers.get(number)})
            continue
        item = questions[number]
        if number not in answers:
            report.append(f"No answer key match: {source} Q{number}")
            continue
        bank.append([
            source.upper(),
            item["prompt"],
            item["choices"],
            answers[number],
            refs.get(number, ""),
            source,
            number,
        ])

records = []
for item in bank:
    keywords, lookup_summary = extract_lookup(item[1], item[2], item[4])
    records.append({
        "id": record_id(ID_PREFIXES[item[5]], item[6]),
        "exam": item[5],
        "question_number": item[6],
        "prompt": item[1],
        "answers": item[2],
        "gist": "",
        "scene": "",
        "correct_index": item[3],
        "article": item[4],
        "article_title": article_title(item[4]),
        "keywords": keywords,
        "lookup_summary": lookup_summary,
        "info_tip": explain_question(item[1], keywords, item[4]),
        "reference_text": reference_text(item[4]),
        "reference_table": reference_table(item[4]),
        "tip_title": CONCEPT_SHORT.get(concept_key_for(item[1].lower(), item[4]), ("In plain language", ""))[0],
        "tip_short": concept_tip_short(concept_key_for(item[1].lower(), item[4]), item[2], item[3]),
        "formula": "",
        "worked": "",
        "choice_notes": choice_notes_for(item[2]),
        "available": True,
    })
# State law questions come from curated JSON, not OCR, and follow the NEC records.
state_records, state_manifest = load_state_law()
records.extend(state_records)
# Curated corrections live in a data overlay instead of being lost on rebuild.
# Set WIRE_SKIP_BANK_OVERRIDES=1 only when generating a raw baseline for a
# reviewed overlay refresh.
if os.environ.get("WIRE_SKIP_BANK_OVERRIDES") != "1":
    overrides_path = Path(__file__).with_name("question_bank_overrides.json")
    overlay = json.loads(overrides_path.read_text(encoding="utf-8"))
    apply_overrides(records, overlay)
    # The paragraph that restates the stem quotes it and lists its numbers, so a
    # curated stem must not leave the raw OCR stem (typos, answer words) there.
    # The background note above it stays as reviewed.
    for record in records:
        fields = overlay["records"].get(record["id"], {})
        if "info_tip" not in fields and not record.get("section"):
            record["info_tip"] = restate_stem(record["info_tip"], record["prompt"], record["keywords"], record["article"])
# Titles follow the final citation: an override that moves a record to another
# article must not keep the title of the OCR citation it replaced.
for record in records:
    if record.get("section"):
        continue
    primary = re.match(r"(?:Table\s+|Article\s+)?(\d{2,3})(?:\.\d|\b)", record["article"].strip())
    if primary and int(primary.group(1)) in ARTICLE_TITLES:
        record["article_title"] = ARTICLE_TITLES[int(primary.group(1))]

# "questions" held the RAW pre-curation rows (un-redacted stems, original
# units). main.gd read only "records"; keeping both doubled the file and left a
# latent fallback to unredacted data. Curated rows only.
playable = len(bank) + len(state_records)
payload = {"version": 2, "total_expected": sum(QUESTION_COUNTS.values()) + len(state_records), "playable": playable, "missing_source_items": missing, "audit_notes": report, "records": records}
manifest = []
for source, count in QUESTION_COUNTS.items():
    for number in range(1, count + 1):
        match = next((item for item in bank if item[5] == source and item[6] == number), None)
        manifest.append({"source": source, "number": number, "available": match is not None})
manifest.extend(state_manifest)
payload["manifest"] = manifest
OUT.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")
print(json.dumps({"playable": playable, "missing": len(missing), "notes": len(report), "output": str(OUT)}))
