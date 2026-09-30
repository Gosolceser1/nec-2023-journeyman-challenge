#!/usr/bin/env python3
"""Schema validator for question_bank.json.

This is the ONLY gate between the builder and shipping. Run it after
tools/pipeline/build_question_bank.py and before tools/speech/pregenerate_speech.py.

Usage:
    python tools/pipeline/validate_question_bank.py                      # validates repo-root question_bank.json
    python tools/pipeline/validate_question_bank.py path/to/bank.json
    python tools/pipeline/validate_question_bank.py --json              # machine-readable output
    python tools/pipeline/validate_question_bank.py --no-warn           # strict: treat warnings as errors

Exit codes:
    0  valid (warnings may still be reported)
    1  invalid -- at least one ERROR
    2  validator could not run (file missing / unparseable JSON)

Design notes
------------
* The validator is STANDALONE. It re-implements the consumer semantics it
  checks against (main.gd, table_viewer.gd) rather than importing the
  builder, so a builder bug cannot silently redefine the contract.
* Where a GDScript function is mirrored (TableViewer.is_note_row), the
  Python port is line-for-line faithful to the shipped implementation,
  including its quirks -- see NOTE_ROW_DOC vs NOTE_ROW_ACTUAL below.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import unicodedata
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pipeline_paths import edition, nec_data  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_BANK = ROOT / "data" / "question_bank.json"
EDITION = edition()["short"]  # "NEC 2023", in messages
EDITION_YEAR = edition()["year"]

SCHEMA_VERSION = 2

REQUIRED_TOP_LEVEL = ["version", "total_expected", "playable", "records", "manifest", "missing_source_items"]
OPTIONAL_TOP_LEVEL = ["audit_notes"]

REQUIRED_RECORD_FIELDS = [
    "id", "prompt", "answers", "correct_index", "article", "article_title",
    "exam", "question_number",
]
# Non-empty required. 'gist' and 'scene' are optional in practice (a large
# share ship empty) so they are type-checked but never required to be filled.
STRING_FIELDS = [
    "id", "prompt", "article", "article_title", "exam",
    "gist", "scene", "lookup_summary", "info_tip", "reference_text",
    "tip_title", "tip_short",
]
NON_EMPTY_FIELDS = [
    "id", "prompt", "article", "article_title", "exam",
    "lookup_summary", "info_tip", "reference_text", "tip_title", "tip_short",
]
LIST_FIELDS = ["answers", "keywords", "reference_table", "choice_notes"]

MIN_ANSWERS, MAX_ANSWERS = 2, 6
NON_CODE_REFERENCE_LABELS = {"general knowledge", "general calculation"}

# ids look like "final-exam-#1-002" / "open-book-exam-#7-014"
ID_RE = re.compile(r"^[a-z0-9#-]+-\d{3}$")
# NEC citations: "210.8(A)(2)", "408.18(C)", "590.5", "Table 220.42(A)"
ARTICLE_RE = re.compile(r"^(?:Table\s+)?\d+\.\d+", re.I)
# Nebraska law: "Neb. Rev. Stat. 81-2113(2)", "Title 100 NAC Rule 13"
STATE_LAW_RE = re.compile(r"^(?:Neb\. Rev\. Stat\. \d{2}-\d{4}|Title \d+ NAC Rule \d+)")
# Records outside the NEC pool name their pool; NEC records have no "section".
VALID_SECTIONS = {"ne_state_law"}

# Chapters of info_tip that the player sees BEFORE committing an answer.
# "LOOKUP FOCUS" and "PLAIN-LANGUAGE BACKGROUND" are background text; a correct
# answer appearing verbatim there hands the answer to the player.
PRE_ANSWER_CHAPTERS = ["WHAT THIS QUESTION MEANS", "PLAIN-LANGUAGE BACKGROUND", "LOOKUP FOCUS"]
LEAK_MIN_LEN = 4  # ignore 1-3 char answers ("no", "yes", "1") -- too noisy

# Stems are shown exactly as printed in the source exam PDF. A few source
# questions state their own answer in the stem (422.33(A) says "an accessible"
# twice, and the exam blanks only the second). Each exception pins the record id
# AND its full prompt: any other record, or any other wording of this one, is
# still a fatal prompt leak.
PROMPT_LEAK_EXCEPTIONS = {
    "final-exam-#3-042": (
        "For cord-and-plug connected appliances, an accessible separable connector or ___ "
        "plug and receptacle is permitted to serve as the disconnecting means."
    ),
}

# --------------------------------------------------------------------------
# Build-time scaffolding that must never ship inside a learner-facing field.
# --------------------------------------------------------------------------
# These are notes-to-self or editorial annotations that were written into the
# bank while it was being built. They read as broken or as instructions to the
# author, not as Code text: 7 records shipped this way. Each pattern is
# anchored on a phrase that has no legitimate use in NEC prose.
#
# Deliberately NOT matched: "the correct choice is ..." in info_tip. That is
# deliberate pedagogy (it tells the learner which KIND of answer to pick, not
# which one), and it appears in ~65 records by design.
SCAFFOLD_PATTERNS = [
    (r"(?i)\bfor th(is|e) (?:exam )?item\b",
     "author scaffolding in a learner-facing field ('For this exam item')"),
    (r"(?i)\bdo not add another\b",
     "author scaffolding ('Do not add another multiplier')"),
    (r"(?i)see individual provision entries",
     "unresolved pointer instead of real Code text"),
    (r"(?i)\bflag it and move on\b",
     "author note to self, and it tells the learner the question is unanswerable"),
    (r"(?i)\bcannot be answered\b",
     "tells the learner the question cannot be answered"),
    (r"(?i)\btested here at\b",
     "the Code's own measurement was replaced with the test value"),
    (r"\(\d{4} NEC\)",
     "editorial edition annotation inside quoted Code text"),
    (r"(?i)\b(lorem ipsum|placeholder|\bTODO\b|\bTBD\b)\b",
     "unresolved placeholder"),
]
SCAFFOLD_RE = [(re.compile(p), why) for p, why in SCAFFOLD_PATTERNS]


# --------------------------------------------------------------------------
# TableViewer.is_note_row -- two ports on purpose.
# --------------------------------------------------------------------------
# What the code accepts (table_viewer.gd is_note_row, via the shared
# _is_note_separator helper):
#     "NOTE:", "NOTE 1:", "NOTE 2:", "NOTE No. 1:"
# and NOT a word that merely starts with "note" ("NOTES ON SUPPLIES").
# Both ports agree, so neither can flag a real note as unrecognised.
def note_row_documented(row: list) -> bool:
    if len(row) != 1:
        return False
    head = str(row[0]).strip().upper()
    if not head.startswith("NOTE"):
        return False
    tail = head[4:]
    if tail == "":
        return True
    return tail[0] in (":", " ", ".", ",")


# Kept as a separate name so the validator still fails loudly if the two ever
# diverge again -- that divergence is what silently re-flagged final-exam-#1-021
# after the fix had already landed. It is deliberately the SAME rule, not a
# second transcription of the old buggy one.
def note_row_actual(row: list) -> bool:
    return note_row_documented(row)


class Report:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []
        self.info: list[str] = []

    def error(self, msg: str) -> None:
        self.errors.append(msg)

    def warn(self, msg: str) -> None:
        self.warnings.append(msg)

    def note(self, msg: str) -> None:
        self.info.append(msg)


# --------------------------------------------------------------------------
# helpers
# --------------------------------------------------------------------------
def is_blank(v) -> bool:
    return v is None or (isinstance(v, str) and not v.strip())


def jtype(v) -> str:
    return type(v).__name__


def truncate(s, n=110):
    s = str(s).replace("\n", "\\n")
    return s if len(s) <= n else s[: n - 1] + "…"


def answer_in_text(answer: str, text: str) -> bool:
    """True if `answer` appears in `text` as a whole word/phrase.

    Word-boundary aware on purpose: 'damage' is not a leak inside 'damages the
    raceway'. A naive substring test produces false positives on every
    inflected form and is unusable as a gate.
    """
    a = answer.strip().casefold()
    if not a:
        return False
    pattern = r"(?<!\w)" + re.escape(a) + r"(?!\w)"
    return re.search(pattern, text.casefold()) is not None


def _pre_answer_tip(tip: str) -> str:
    """The slice of info_tip the player sees BEFORE answering.

    Mirrors main.gd:_gist_task_sentence() exactly: split on blank lines, take
    chunk[1] as the task framing, and only when chunk[2] begins with
    "LOOKUP FOCUS". Returns "" when the record has no safe pre-answer tip, so
    the caller checks nothing rather than everything.
    """
    chunks = tip.split("\n\n")
    if len(chunks) < 3:
        return ""
    task = chunks[1].strip()
    if not task or task.upper().startswith("LOOKUP FOCUS"):
        return ""
    if not chunks[2].strip().upper().startswith("LOOKUP FOCUS"):
        return ""
    return task


STEM_QUOTE_RE = re.compile(
    r'the question is: "(.*)"(?= (?:Subject:|Numbers in the question:|Break it into pieces))')


def stale_stem_quote(tip, prompt) -> str:
    """The stem an info_tip quotes when it is not the record's prompt ("" when it matches).

    The builder quotes the OCR stem; a curated prompt that leaves the old quote
    behind shows the learner a different question, with its typos or answer words.
    """
    if not isinstance(tip, str) or not isinstance(prompt, str):
        return ""
    m = STEM_QUOTE_RE.search(tip)
    if not m:
        return ""
    quoted = m.group(1)
    if quoted.endswith("…"):
        return "" if prompt.strip().startswith(quoted[:-1]) else quoted
    return "" if prompt.strip() == quoted else quoted


def prompt_leak_excepted(record_id, prompt) -> bool:
    return PROMPT_LEAK_EXCEPTIONS.get(record_id) == prompt


def pre_answer_visible_text(record: dict) -> str:
    """Mirror main.gd: prefer gist; use the info_tip task only as its fallback."""
    gist = record.get("gist")
    if isinstance(gist, str) and gist.strip():
        return gist.strip()
    tip = record.get("info_tip")
    return _pre_answer_tip(tip) if isinstance(tip, str) else ""


def article_reference_is_recognized(reference: str) -> bool:
    """Accept NEC/standard citations and explicit non-code reference categories."""
    if not isinstance(reference, str):
        return False
    clean = reference.strip()
    folded = clean.casefold()
    if folded in NON_CODE_REFERENCE_LABELS or folded == "nfpa 70e":
        return True
    if folded in {"def 100", "definition 100", "definitions 100"}:
        return True
    if folded.startswith("nec "):
        clean = clean[4:].strip()
        folded = clean.casefold()
    if folded.startswith("article ") and clean[8:].strip().isdigit():
        return True
    if folded.startswith("chapter 9, note ") and clean[15:].strip().isdigit():
        return True
    if re.fullmatch(r"chapter 9, table \d+|table \d+, chapter 9", folded):
        return True
    if STATE_LAW_RE.match(clean):
        return True
    return ARTICLE_RE.match(clean) is not None


# --------------------------------------------------------------------------
# locations: breadcrumb, reference line and every citation point at the same,
# existing place in the edition (data/edition.json)
# --------------------------------------------------------------------------
NEC_ARTICLES_PATH = nec_data("articles.json")
PRIMARY_ARTICLE_RE = re.compile(r"^(?:NEC\s+)?(?:Table\s+|Article\s+)?(\d{2,3})(?:\.\d|\b)")
PRIMARY_SECTION_RE = re.compile(r"^(?:NEC\s+)?(?:Table\s+)?(\d{3}\.\d+)((?:\([A-Za-z0-9]+\))*)")
CITATION_RE = re.compile(r"(?<![\w.$])([1-8]\d\d)\.(\d+)((?:\([A-Za-z0-9]+\))*)(?!\d)")
ARTICLE_CITATION_RE = re.compile(r"\bArticles?\s+([1-8]\d\d|90)\b")
# Explanatory fields: the exam's own wording (prompt, answers) may quote old
# numbers as distractors; everything the app writes must use the edition's numbering.
EXPLANATION_FIELDS = ["gist", "info_tip", "lookup_summary", "reference_text", "reference_table",
                      "tip_title", "tip_short", "choice_notes", "formula", "worked"]
RENUMBERED_PATH = nec_data("renumbered.json")


def load_renumbered(path: Path = RENUMBERED_PATH) -> list[tuple[re.Pattern, str]]:
    """Section numbers that exist only in earlier editions, with their home in this edition."""
    if not path.exists():
        return []
    data = json.loads(path.read_text(encoding="utf-8"))
    return [(re.compile(e["pattern"]), e["home"]) for e in data["sections"]]


RENUMBERED_SECTIONS = load_renumbered()


CONTENT_AUDIT_PATH = nec_data("content_audit.json")
BLUEPRINT_PATH = ROOT / "data" / "exam_blueprint.json"
AUDIT_STATUSES = {"verified", "fixed", "flagged", "non_nec"}


def provision_digest(rec: dict) -> str:
    """Checksum of the provision a learner sees (text plus table); no NEC text is stored."""
    blob = json.dumps([rec.get("reference_text", ""), rec.get("reference_table", [])],
                      ensure_ascii=False, separators=(",", ":"))
    return hashlib.sha256(blob.encode("utf-8")).hexdigest()[:16]


def content_audit_problems(records: list, audit: dict) -> tuple[list[str], list[str]]:
    """(errors, warnings) for records unaudited, or whose provision or key changed since the edition's content audit."""
    errors: list[str] = []
    warnings: list[str] = []
    entries = audit.get("records", {}) if isinstance(audit, dict) else {}
    nec = [r for r in records if isinstance(r, dict) and r.get("section") is None]
    covered = [r for r in nec if r.get("id") in entries]
    for rec in covered:
        rid = rec["id"]
        entry = entries[rid]
        if entry.get("status") not in AUDIT_STATUSES:
            errors.append(f"{rid}: content audit status {entry.get('status')!r} not in {sorted(AUDIT_STATUSES)}")
            continue
        if entry.get("provision") != provision_digest(rec):
            errors.append(f"{rid}: provision text changed since the {EDITION} content audit "
                          f"({entry.get('verified_on')}); re-verify it and update {CONTENT_AUDIT_PATH.name}")
        if entry.get("correct_index") != rec.get("correct_index"):
            errors.append(f"{rid}: correct_index {rec.get('correct_index')} differs from the audited key "
                          f"{entry.get('correct_index')}; record the evidence in {CONTENT_AUDIT_PATH.name}")
    # Once the audit covers any record of this bank, every NEC record must be audited, however many are new.
    # A fixture bank whose ids the audit has never seen is not held to the checked-in audit.
    if covered:
        for rec in nec:
            if rec.get("id") not in entries:
                errors.append(f"{rec.get('id')}: no {EDITION} content audit entry in {CONTENT_AUDIT_PATH.name}")
    return errors, warnings


def blueprint_edition_problems(blueprint: dict) -> list[str]:
    """The exam blueprint (areas by NEC chapter, weights) must be for the edition in data/edition.json."""
    stated = blueprint.get("edition")
    if stated is None:
        return [f"{BLUEPRINT_PATH.name} names no NEC edition; add \"edition\": {EDITION_YEAR}"]
    if str(stated) != str(EDITION_YEAR):
        return [f"{BLUEPRINT_PATH.name} is for NEC {stated} but data/edition.json is {EDITION}; "
                "check the exam bulletin's areas and weights, then update its \"edition\""]
    return []


def load_content_audit(path: Path = CONTENT_AUDIT_PATH) -> dict:
    return json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}


def load_nec_articles(path: Path = NEC_ARTICLES_PATH) -> dict:
    data = json.loads(path.read_text(encoding="utf-8"))
    return {int(k): v for k, v in data["articles"].items()}


def primary_article(reference: str) -> int | None:
    if not isinstance(reference, str) or STATE_LAW_RE.match(reference.strip()):
        return None
    m = PRIMARY_ARTICLE_RE.match(reference.strip())
    return int(m.group(1)) if m else None


def subsections_agree(a: str, b: str) -> bool:
    """'(A)(3)' and '(A)' agree (one narrows the other); '(A)(3)' and '(A)(4)' do not."""
    pa, pb = re.findall(r"\(([A-Za-z0-9]+)\)", a), re.findall(r"\(([A-Za-z0-9]+)\)", b)
    n = min(len(pa), len(pb))
    return pa[:n] == pb[:n]


def _flat(value) -> str:
    if isinstance(value, list):
        return "\n".join(_flat(v) for v in value)
    return value if isinstance(value, str) else ""


def location_problems(rec: dict, articles: dict) -> list[str]:
    """Every way a record can point the learner at the wrong place in the NEC."""
    problems: list[str] = []
    if rec.get("section") == "ne_state_law":
        return problems
    reference = rec.get("article", "")
    article = primary_article(reference)
    if article is None:
        return problems
    if article not in articles:
        return [f"article {reference!r}: {article} is not an {EDITION} article"]
    if rec.get("article_title") != articles[article]:
        problems.append(f"article_title {rec.get('article_title')!r} is not the {EDITION} title of "
                        f"Article {article} ({articles[article]!r})")

    heading = _flat(rec.get("reference_text")).split("\n", 1)[0]
    heading_article = primary_article(heading)
    if heading and heading_article != article:
        problems.append(f"provision heading {truncate(heading, 60)!r} is not in Article {article}")
    primary = PRIMARY_SECTION_RE.match(reference.strip())
    if primary and heading:
        base = primary.group(1)
        head = PRIMARY_SECTION_RE.match(heading.strip())
        if head is None or head.group(1) != base:
            problems.append(f"provision heading {truncate(heading, 60)!r} does not start with {base}")
        elif not subsections_agree(head.group(2), primary.group(2)):
            problems.append(f"provision heading {head.group(0)} and citation {primary.group(0)} name different subsections")

    start = re.search(r"Start with ([^,]+?)(?:, then|\.\s|$)", _flat(rec.get("lookup_summary")))
    if start and primary:
        hint = PRIMARY_SECTION_RE.match(start.group(1).strip())
        if hint is None or hint.group(1) != primary.group(1) or not subsections_agree(hint.group(2), primary.group(2)):
            problems.append(f"lookup_summary starts with {start.group(1)!r}, not {primary.group(0)}")

    # The correct choice's rationale and the tip cite the primary section; a
    # neighbouring subsection of the same section is a typo unless the quoted
    # provision itself mentions it.
    if primary:
        base, sub = primary.group(1), primary.group(2)
        provision = _flat(rec.get("reference_text")) + "\n" + _flat(rec.get("reference_table"))
        ci = rec.get("correct_index")
        notes = rec.get("choice_notes") if isinstance(rec.get("choice_notes"), list) else []
        tip = _flat(rec.get("tip_short"))
        correct_part = re.search(r"Correct: .*?(?= Not [A-D]: |$)", tip, re.S)
        texts = [correct_part.group(0) if correct_part else tip]
        if isinstance(ci, int) and 0 <= ci < len(notes):
            texts.append(_flat(notes[ci]))
        first_sub = re.match(r"\(([A-Za-z0-9]+)\)", sub)
        for text in texts:
            for m in CITATION_RE.finditer(text):
                cited = f"{m.group(1)}.{m.group(2)}"
                cited_sub = re.match(r"\(([A-Za-z0-9]+)\)", m.group(3))
                if cited == base and first_sub and cited_sub and cited_sub.group(1) != first_sub.group(1) \
                        and m.group(0) not in provision and m.group(0) not in reference:
                    problems.append(f"rationale cites {m.group(0)} but the provision is {reference}")

    for field in EXPLANATION_FIELDS:
        text = _flat(rec.get(field))
        for m in CITATION_RE.finditer(text):
            if int(m.group(1)) not in articles:
                problems.append(f"{field} cites {m.group(0)}: {m.group(1)} is not an {EDITION} article")
        for m in ARTICLE_CITATION_RE.finditer(text):
            if int(m.group(1)) not in articles:
                problems.append(f"{field} cites Article {m.group(1)}, not an {EDITION} article")
        for rx, home in RENUMBERED_SECTIONS:
            for m in rx.finditer(text):
                sentence = text[text.rfind(".", 0, m.start()) + 1:text.find(".", m.end()) + 1 or None]
                if not re.search(r"\b(?:old|numbering|renumbered|earlier edition)\b", sentence, re.I):
                    problems.append(f"{field} cites {m.group(0)}, pre-{EDITION_YEAR} numbering: {home}")
    return problems


def ragged_table_rows(table: list) -> list[tuple[int, int]]:
    """Return malformed width deviations, excluding recognized one-cell notes."""
    if not table or not isinstance(table[0], list):
        return []
    header_width = len(table[0])
    return [
        (index, len(row))
        for index, row in enumerate(table)
        if isinstance(row, list)
        and len(row) != header_width
        and not note_row_documented(row)
    ]


# --------------------------------------------------------------------------
def check_top_level(data, rep: Report) -> None:
    if not isinstance(data, dict):
        rep.error(f"top level: expected object, got {jtype(data)}")
        return

    for k in REQUIRED_TOP_LEVEL:
        if k not in data:
            rep.error(f"top level: missing required key '{k}'")
    for k in data:
        if k not in REQUIRED_TOP_LEVEL and k not in OPTIONAL_TOP_LEVEL:
            rep.warn(f"top level: unrecognised key '{k}'")

    if "version" in data and data["version"] != SCHEMA_VERSION:
        rep.error(f"version: expected {SCHEMA_VERSION}, got {data['version']!r}")

    for k in ("total_expected", "playable"):
        if k in data and not isinstance(data[k], int):
            rep.error(f"{k}: expected int, got {jtype(data[k])} ({data[k]!r})")

    for k in ("records", "manifest", "missing_source_items", "audit_notes"):
        if k in data and not isinstance(data[k], list):
            rep.error(f"{k}: expected array, got {jtype(data[k])}")

    # missing_source_items element shape
    for i, m in enumerate(data.get("missing_source_items") or []):
        if not isinstance(m, dict):
            rep.error(f"missing_source_items[{i}]: expected object, got {jtype(m)}")
            continue
        for f in ("source", "number"):
            if f not in m:
                rep.error(f"missing_source_items[{i}]: missing '{f}'")


# --------------------------------------------------------------------------
# per-record checks
# --------------------------------------------------------------------------
def check_records(data, rep: Report) -> dict:
    recs = data.get("records")
    stats = {"count": 0, "ids": [], "with_table": 0, "exams": Counter(),
             "empty_gist": 0, "empty_scene": 0}
    if not isinstance(recs, list):
        return stats

    seen_ids: dict[str, int] = {}
    nec_articles = load_nec_articles()

    for i, rec in enumerate(recs):
        if not isinstance(rec, dict):
            rep.error(f"records[{i}]: expected object, got {jtype(rec)}")
            continue
        stats["count"] += 1
        rid = rec.get("id") or f"records[{i}]"
        stats["ids"].append(rid)
        stats["exams"][rec.get("exam")] += 1

        # required presence
        for f in REQUIRED_RECORD_FIELDS:
            if f not in rec:
                rep.error(f"{rid}: missing required field '{f}'")

        # types
        for f in STRING_FIELDS:
            if f in rec and not isinstance(rec[f], str):
                rep.error(f"{rid}: field '{f}' must be string, got {jtype(rec[f])}")
        for f in LIST_FIELDS:
            if f in rec and not isinstance(rec[f], list):
                rep.error(f"{rid}: field '{f}' must be array, got {jtype(rec[f])}")

        # non-empty
        for f in NON_EMPTY_FIELDS:
            if f in rec and is_blank(rec[f]):
                rep.error(f"{rid}: field '{f}' is empty")

        # id format + uniqueness
        if isinstance(rec.get("id"), str):
            if not ID_RE.match(rec["id"]):
                rep.warn(f"{rid}: id does not match <exam-slug>-<NNN>")
            if rec["id"] in seen_ids:
                rep.error(f"{rid}: duplicate id (first seen at records[{seen_ids[rec['id']]}])")
            else:
                seen_ids[rec["id"]] = i

        # citation format (or an explicit non-code reference category)
        if isinstance(rec.get("article"), str) and not article_reference_is_recognized(rec["article"]):
            rep.warn(f"{rid}: article {rec['article']!r} is not a recognized reference")

        # A state-law citation outside its section would put it in the NEC pool.
        if "section" in rec and rec["section"] not in VALID_SECTIONS:
            rep.error(f"{rid}: section {rec['section']!r} not in {sorted(VALID_SECTIONS)}")
        if isinstance(rec.get("article"), str) and STATE_LAW_RE.match(rec["article"].strip()) \
                and rec.get("section") != "ne_state_law":
            rep.error(f"{rid}: Nebraska law citation {rec['article']!r} without section 'ne_state_law'")

        for problem in location_problems(rec, nec_articles):
            rep.error(f"{rid}: location: {problem}")

        # question_number
        qn = rec.get("question_number")
        if not isinstance(qn, int) or isinstance(qn, bool) or qn < 1:
            rep.error(f"{rid}: question_number must be a positive int, got {qn!r}")

        # answers
        answers = rec.get("answers")
        if isinstance(answers, list):
            if not (MIN_ANSWERS <= len(answers) <= MAX_ANSWERS):
                rep.error(
                    f"{rid}: answers has {len(answers)} entries, expected {MIN_ANSWERS}-{MAX_ANSWERS}"
                )
            for ai, a in enumerate(answers):
                if not isinstance(a, str):
                    rep.error(f"{rid}: answers[{ai}] must be string, got {jtype(a)}")
                elif not a.strip():
                    rep.error(f"{rid}: answers[{ai}] is empty")
            # duplicate choices within a question
            norm = [unicodedata.normalize("NFKC", a).strip().casefold() for a in answers if isinstance(a, str)]
            dups = [c for c, n in Counter(norm).items() if n > 1]
            if dups:
                rep.error(f"{rid}: duplicate answer choices: {dups}")

            ci = rec.get("correct_index")
            if not isinstance(ci, int) or isinstance(ci, bool):
                rep.error(f"{rid}: correct_index must be int, got {jtype(ci)}")
            elif answers and not (0 <= ci < len(answers)):
                rep.error(
                    f"{rid}: correct_index {ci} out of range for {len(answers)} answers"
                )

        # answer leak into pre-answer text
        # main.gd blanks the gist at runtime (AudioExplanationGenerator
        # .find_match_in -> "[ ___ ]") before showing it, so a gist hit is a
        # defect worth reporting but not one that ships a visible spoiler.
        # The prompt, by contrast, is displayed verbatim: a prompt leak is fatal.
        ci = rec.get("correct_index")
        if isinstance(answers, list) and isinstance(ci, int) and 0 <= ci < len(answers):
            ans = answers[ci]
            if isinstance(ans, str) and len(ans.strip()) >= LEAK_MIN_LEN:
                target = ans.strip().casefold()
                v = rec.get("prompt")
                if isinstance(v, str) and answer_in_text(ans, v) and not prompt_leak_excepted(rid, v):
                    rep.error(
                        f"{rid}: correct answer {truncate(ans)!r} leaks verbatim into 'prompt' "
                        f"(prompt is displayed unredacted)"
                    )
                v = rec.get("gist")
                if isinstance(v, str) and answer_in_text(ans, v):
                    rep.warn(
                        f"{rid}: correct answer {truncate(ans)!r} appears in 'gist' "
                        f"(main.gd blanks gist at runtime, so no spoiler -- but the data is at risk)"
                    )
                tip = rec.get("info_tip")
                # main.gd uses the task paragraph only when gist is empty. Check
                # that actual fallback, not a paragraph the learner won't see.
                gist = rec.get("gist")
                fallback = not (isinstance(gist, str) and gist.strip())
                visible_tip = pre_answer_visible_text(rec) if fallback else ""
                if isinstance(tip, str) and answer_in_text(ans, visible_tip):
                    low = tip.casefold()
                    pos = low.find(target)
                    chapter = next(
                        (c for c in PRE_ANSWER_CHAPTERS
                         if (p := low.find(c.casefold())) != -1 and p < pos),
                        "<preamble>",
                    )
                    rep.warn(
                        f"{rid}: correct answer {truncate(ans)!r} appears in info_tip "
                        f"chapter '{chapter}' (shown before answering)"
                    )

        stale = stale_stem_quote(rec.get("info_tip"), rec.get("prompt"))
        if stale:
            rep.error(f"{rid}: info_tip quotes a stem other than the prompt: {truncate(stale)!r}")

        # reference_table
        tbl = rec.get("reference_table")
        if isinstance(tbl, list):
            if tbl:
                stats["with_table"] += 1
            widths = Counter()
            note_like_unrecognised = []
            for ri, row in enumerate(tbl):
                if not isinstance(row, list):
                    rep.error(f"{rid}: reference_table[{ri}] must be array, got {jtype(row)}")
                    continue
                widths[len(row)] += 1
                for ci2, cell in enumerate(row):
                    if not isinstance(cell, str):
                        rep.error(
                            f"{rid}: reference_table[{ri}][{ci2}] must be string, got {jtype(cell)}"
                        )
                if len(row) == 1 and str(row[0]).strip().upper().startswith("NOTE"):
                    if not note_row_actual(row):
                        note_like_unrecognised.append((ri, row[0]))
                    elif not note_row_documented(row):
                        note_like_unrecognised.append((ri, row[0]))
            # A one-cell NOTE row is a separate note strip, not a malformed
            # table row. Only flag actual data rows whose width differs.
            odd = ragged_table_rows(tbl)
            if odd:
                header_w = len(tbl[0]) if isinstance(tbl[0], list) else max(widths)
                rep.warn(
                    f"{rid}: reference_table has malformed row widths -- "
                    f"header has {header_w} column(s); deviating rows {odd}"
                )
            for ri, cell in note_like_unrecognised:
                rep.warn(
                    f"{rid}: reference_table[{ri}] looks like a NEC note but "
                    f"TableViewer.is_note_row would NOT classify it as a note: "
                    f"{truncate(cell)!r}"
                )

        # Build-time scaffolding must never reach the learner. ERROR, not warn:
        # this is author-to-self text shipping in a learner-facing field, and it
        # was how 7 records reached the bank. A new one should fail the build.
        for field in STRING_FIELDS:
            val = rec.get(field)
            if not isinstance(val, str) or not val:
                continue
            for rx, why in SCAFFOLD_RE:
                m = rx.search(val)
                if m:
                    rep.error(
                        f"{rid}: {field} contains {why}: "
                        f"{truncate(val[max(0, m.start() - 60):m.end() + 60])!r}"
                    )
                    break

        if is_blank(rec.get("gist")):
            stats["empty_gist"] += 1
        if is_blank(rec.get("scene")):
            stats["empty_scene"] += 1

    audit_errors, audit_warnings = content_audit_problems(recs, load_content_audit())
    for msg in audit_errors:
        rep.error(msg)
    for msg in audit_warnings:
        rep.warn(msg)

    if stats["empty_gist"]:
        rep.note(f"gist is empty on {stats['empty_gist']}/{stats['count']} records (allowed, optional)")
    if stats["empty_scene"]:
        rep.note(f"scene is empty on {stats['empty_scene']}/{stats['count']} records (allowed, optional)")
    return stats


# --------------------------------------------------------------------------
# manifest arithmetic
# --------------------------------------------------------------------------
def check_manifest(data, rep: Report) -> None:
    manifest = data.get("manifest")
    recs = data.get("records")
    missing = data.get("missing_source_items")
    if not isinstance(manifest, list):
        return

    avail = Counter()
    seen: set = set()
    for i, m in enumerate(manifest):
        if not isinstance(m, dict):
            rep.error(f"manifest[{i}]: expected object, got {jtype(m)}")
            continue
        for f in ("source", "number", "available"):
            if f not in m:
                rep.error(f"manifest[{i}]: missing '{f}'")
        if not isinstance(m.get("available"), bool):
            rep.error(f"manifest[{i}]: available must be bool, got {jtype(m.get('available'))}")
        key = (m.get("source"), m.get("number"))
        if key in seen:
            rep.error(f"manifest[{i}]: duplicate entry for {key}")
        seen.add(key)
        avail[bool(m.get("available"))] += 1

    n_manifest = len(manifest)
    n_avail = avail.get(True, 0)
    n_unavail = avail.get(False, 0)
    n_recs = len(recs) if isinstance(recs, list) else 0
    n_missing = len(missing) if isinstance(missing, list) else 0
    declared_total = data.get("total_expected")
    declared_playable = data.get("playable")

    rep.note(
        "arithmetic: "
        f"total_expected={declared_total} | playable={declared_playable} | "
        f"len(records)={n_recs} | len(manifest)={n_manifest} "
        f"(available={n_avail}, unavailable={n_unavail}) | "
        f"len(missing_source_items)={n_missing}"
    )

    if declared_playable != n_recs:
        rep.error(f"playable={declared_playable} but len(records)={n_recs}")
    if isinstance(declared_total, int) and declared_total != n_manifest:
        rep.error(f"total_expected={declared_total} but len(manifest)={n_manifest}")
    if n_avail != n_recs:
        rep.error(f"manifest available={n_avail} but len(records)={n_recs}")
    if n_unavail != n_missing:
        rep.error(f"manifest unavailable={n_unavail} but len(missing_source_items)={n_missing}")
    if isinstance(declared_total, int) and n_recs + n_missing != declared_total:
        rep.error(
            f"total_expected={declared_total} != playable+missing ({n_recs}+{n_missing}={n_recs + n_missing})"
        )

    # cross-check every record maps to an available manifest slot
    if isinstance(recs, list) and manifest:
        by_key = {(m.get("source"), m.get("number")): m for m in manifest if isinstance(m, dict)}
        missing_set = {
            (m.get("source"), m.get("number"))
            for m in (missing or []) if isinstance(m, dict)
        }
        for i, rec in enumerate(recs):
            if not isinstance(rec, dict):
                continue
            rid = rec.get("id") or f"records[{i}]"
            key = (rec.get("exam"), rec.get("question_number"))
            m = by_key.get(key)
            if m is None:
                rep.error(f"{rid}: ({rec.get('exam')}, {rec.get('question_number')}) absent from manifest")
            elif not m.get("available"):
                rep.error(
                    f"{rid}: ({rec.get('exam')}, {rec.get('question_number')}) is a record but "
                    f"manifest marks it unavailable"
                )
            if key in missing_set:
                rep.error(
                    f"{rid}: ({rec.get('exam')}, {rec.get('question_number')}) is both a record "
                    f"and listed in missing_source_items"
                )
        for key in missing_set:
            if key not in by_key:
                rep.warn(f"missing_source_items entry {key} has no matching manifest slot")
            elif by_key[key].get("available"):
                rep.error(f"missing_source_items entry {key} is marked available in manifest")


# --------------------------------------------------------------------------
# reporting
# --------------------------------------------------------------------------
def render(path: Path, data, rep: Report, stats: dict) -> str:
    L = []
    L.append("=" * 72)
    L.append(f"question_bank validator: {path}")
    L.append("=" * 72)
    if isinstance(data, dict):
        L.append(
            f"version={data.get('version')} total_expected={data.get('total_expected')} "
            f"playable={data.get('playable')} records={len(data.get('records') or [])} "
            f"manifest={len(data.get('manifest') or [])} "
            f"missing={len(data.get('missing_source_items') or [])}"
        )
    if stats:
        L.append(
            f"scanned records={stats['count']} with_reference_table={stats['with_table']} "
            f"exams={len(stats['exams'])}"
        )
    L.append("")

    for m in rep.info:
        L.append(f"  INFO  {m}")
    if rep.info:
        L.append("")

    for label, items in (("ERROR", rep.errors), ("WARN", rep.warnings)):
        if not items:
            continue
        counts = Counter()
        for m in items:
            counts[m.split(":", 1)[0] if False else m.split(": ", 1)[0]] += 1
        L.append(f"--- {label} ({len(items)}) ---")
        for m in items:
            L.append(f"  {label}  {m}")
        L.append("")
        del counts

    if rep.errors:
        L.append(f"RESULT: INVALID — {len(rep.errors)} error(s), {len(rep.warnings)} warning(s)")
    elif rep.warnings:
        L.append(f"RESULT: VALID — 0 errors, {len(rep.warnings)} warning(s)")
    else:
        L.append("RESULT: VALID — 0 errors, 0 warnings")
    L.append("=" * 72)
    return "\n".join(L)


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description="Validate question_bank.json schema.")
    ap.add_argument("path", nargs="?", default=str(DEFAULT_BANK),
                    help="path to question_bank.json (default: repo root)")
    ap.add_argument("--json", action="store_true", help="emit machine-readable JSON")
    ap.add_argument("--no-warn", action="store_true",
                    help="treat warnings as errors (CI gate)")
    ap.add_argument("--max-report", type=int, default=0,
                    help="cap printed problems per severity (0 = no cap)")
    args = ap.parse_args(argv)

    path = Path(args.path).resolve()
    try:
        raw = path.read_text(encoding="utf-8")
    except OSError as e:
        print(f"FATAL: cannot read {path}: {e}", file=sys.stderr)
        return 2
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as e:
        print(f"FATAL: {path} is not valid JSON: {e}", file=sys.stderr)
        return 2

    rep = Report()
    check_top_level(data, rep)
    stats = check_records(data, rep)
    check_manifest(data, rep)
    if BLUEPRINT_PATH.exists():
        for problem in blueprint_edition_problems(json.loads(BLUEPRINT_PATH.read_text(encoding="utf-8"))):
            rep.warn(problem)

    n_err, n_warn = len(rep.errors), len(rep.warnings)
    exit_code = 1 if n_err or (args.no_warn and n_warn) else 0

    if args.json:
        print(json.dumps({
            "path": str(path), "valid": exit_code == 0,
            "errors": n_err, "warnings": n_warn,
            "error_list": rep.errors, "warning_list": rep.warnings,
            "info": rep.info, "records": stats["count"],
        }, indent=2, ensure_ascii=False))
    else:
        cap = args.max_report or 10**9
        if len(rep.errors) > cap:
            rep.errors = rep.errors[:cap] + [f"... {len(rep.errors) - cap} more errors"]
        if len(rep.warnings) > cap:
            rep.warnings = rep.warnings[:cap] + [f"... {len(rep.warnings) - cap} more warnings"]
        print(render(path, data, rep, stats))

    return exit_code


if __name__ == "__main__":
    sys.exit(main())
