#!/usr/bin/env python3
"""Spelling and typography check for every learner-facing string in the bank.

    python tools/pipeline/spellcheck_bank.py              # full check (pyspellchecker if installed)
    python tools/pipeline/spellcheck_bank.py --offline    # reviewed-lexicon check, no dependencies
    python tools/pipeline/spellcheck_bank.py --update-lexicon

Policy (see docs/DATA_PIPELINE.md, "PDF wording, typos corrected"): stems and
choices follow the source PDF word for word, but genuine misspellings and slips
are corrected through tools/pipeline/question_bank_overrides.json. Quoted NEC text
(reference_text) must still match the 2023 wording, so a finding there is fixed
only when the NEC itself spells it the other way.

Checks
  spelling      word unknown to the dictionary and to tools/pipeline/spellcheck_allowlist.txt
  doubled       the same word twice in a row ("the the")
  spacing       missing space after , ; : ? ! or a sentence period, space before
                , ; : ? !, doubled spaces, doubled punctuation
  unit-case     kva/Kva/KVA, kw/KW, Kcmil/KCMIL, Awg -- NEC writes kVA, kW, kcmil, AWG
  brackets      unbalanced () [] {} or curly quotes, odd count of straight "

Dictionary
  Full mode uses pyspellchecker (pip install pyspellchecker) plus the allowlist.
  Offline mode (used by tools/verify.sh) uses tools/pipeline/spellcheck_lexicon.txt, the
  vocabulary of the bank as last reviewed in full mode, plus the allowlist, so
  any NEW word must be reviewed once. Regenerate the lexicon with
  --update-lexicon (needs pyspellchecker; it stores only dictionary words, so
  domain terms belong in the allowlist).

Exit 0 = clean, 1 = findings.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BANK = ROOT / "data" / "question_bank.json"
ALLOWLIST = ROOT / "tools" / "pipeline" / "spellcheck_allowlist.txt"
LEXICON = ROOT / "tools" / "pipeline" / "spellcheck_lexicon.txt"

TEXT_FIELDS = [
    "prompt", "answers", "gist", "article_title", "lookup_summary", "info_tip",
    "reference_text", "reference_table", "tip_title", "tip_short", "formula",
    "worked", "choice_notes", "keywords",
]

WORD_RE = re.compile(r"[^\W\d_]+(?:['\u2019][^\W\d_]+)*")
# Same line only: NEC headings repeat their first word ("547.30 Motors\nMotors and ...").
DOUBLED_RE = re.compile(r"\b([A-Za-z]+)[ \t]+\1\b", re.I)
SPACING_RES = [
    ("missing space after punctuation", re.compile(r"[a-z][,;?!][A-Za-z]")),
    ("missing space after colon", re.compile(r"[a-z]{2}:[A-Za-z]")),
    ("missing space after sentence", re.compile(r"[a-z]{2}\.[A-Z][a-z]")),
    ("space before punctuation", re.compile(r"\w [.,;:?!](?=\s|$|[\"\u201d'])")),
    ("doubled space", re.compile(r"\S  +\S")),
    ("doubled punctuation", re.compile(r"(?<!\.)([,;:!?])\1|,\.|(?<!\bEx)(?<!\betc)\.,|(?<!\.)\.\.(?!\.)")),
]
UNIT_RE = re.compile(r"\b(?:kva|Kva|KVA|KVa|kw|KW|Kw|Kcmil|KCMIL|KCmil|Awg|awg)\b")
PAIRS = [("(", ")"), ("[", "]"), ("{", "}"), ("\u201c", "\u201d")]
# Inch and foot marks after a number (6", 3/4", 6'6") are not quotation marks.
MEASURE_MARK_RE = re.compile(r"(?<=\d)['\"\u2019\u201d]")


def load_allowlist() -> tuple[set[str], set[str]]:
    """Return (words, ignored findings). Ignore lines look like `!<id>|<check>|<snippet>`."""
    words: set[str] = set()
    ignores: set[str] = set()
    if ALLOWLIST.exists():
        for line in ALLOWLIST.read_text(encoding="utf-8").splitlines():
            line = line.split("#", 1)[0].strip() if not line.startswith("!") else line.strip()
            if not line:
                continue
            if line.startswith("!"):
                ignores.add(line[1:])
            else:
                words.update(w.lower() for w in line.split())
    return words, ignores


def iter_strings(value, path: str):
    if isinstance(value, str):
        yield path, value
    elif isinstance(value, list):
        for i, v in enumerate(value):
            yield from iter_strings(v, f"{path}[{i}]")


def bank_sources():
    bank = json.loads(BANK.read_text(encoding="utf-8"))
    for rec in bank["records"]:
        for field in TEXT_FIELDS:
            for path, text in iter_strings(rec.get(field), field):
                yield rec["id"], path, text


def words_of(text: str):
    for m in WORD_RE.finditer(text):
        w = m.group(0).replace("\u2019", "'")
        if w.endswith("'s"):
            w = w[:-2]
        yield w


def mechanical(text: str):
    for m in DOUBLED_RE.finditer(text):
        yield "doubled", m.group(0)
    for label, rx in SPACING_RES:
        for m in rx.finditer(text):
            yield "spacing", f"{label}: {text[max(0, m.start() - 12):m.end() + 12]!r}"
    for m in UNIT_RE.finditer(text):
        yield "unit-case", m.group(0)
    quoted = MEASURE_MARK_RE.sub("", text)
    for a, b in PAIRS:
        if quoted.count(a) != quoted.count(b):
            yield "brackets", f"{a}{b} {quoted.count(a)}/{quoted.count(b)}"
    if quoted.count('"') % 2:
        yield "brackets", 'odd number of "'


def make_known(offline: bool, allow: set[str]):
    if not offline:
        try:
            from spellchecker import SpellChecker
        except ImportError:
            print("pyspellchecker not installed; falling back to --offline", file=sys.stderr)
            offline = True
    if offline:
        lex = set(LEXICON.read_text(encoding="utf-8").split()) if LEXICON.exists() else set()
        return lambda w: w.lower() in lex or w.lower() in allow, None
    sc = SpellChecker(distance=1)
    return (lambda w: w.lower() in allow or w.lower() in sc), sc


def is_candidate(w: str) -> bool:
    # Acronyms and designators (THHN, GFCI, NM-B parts) are checked via the
    # allowlist only when mixed-case; ALL-CAPS tokens are left alone.
    return len(w) > 1 and not w.isupper()


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--offline", action="store_true", help="use the reviewed lexicon instead of pyspellchecker")
    ap.add_argument("--update-lexicon", action="store_true", help="rewrite the lexicon from the current bank")
    args = ap.parse_args(argv)

    allow, ignores = load_allowlist()
    sources = list(bank_sources())

    if args.update_lexicon:
        # Only dictionary words go in, so an unreviewed typo can never be grandfathered.
        from spellchecker import SpellChecker
        sc = SpellChecker(distance=1)
        words = {w.lower() for _, _, t in sources for w in words_of(t) if is_candidate(w)}
        vocab = sorted(w for w in words - allow if w in sc)
        LEXICON.write_text("\n".join(vocab) + "\n", encoding="utf-8", newline="\n")
        print(f"wrote {len(vocab)} words to {LEXICON.relative_to(ROOT)}")
        return 0

    known, sc = make_known(args.offline, allow)
    findings: list[tuple[str, str, str, str]] = []
    for rid, path, text in sources:
        for w in words_of(text):
            if is_candidate(w) and not known(w):
                findings.append((rid, path, "spelling", w))
        for check, detail in mechanical(text):
            findings.append((rid, path, check, detail))

    findings = [f for f in findings if f"{f[0]}|{f[2]}|{f[3]}" not in ignores]
    suggestions: dict[str, str] = {}
    for rid, path, check, detail in findings:
        hint = ""
        if check == "spelling" and sc is not None:
            key = detail.lower()
            if key not in suggestions:
                suggestions[key] = sc.correction(key) or ""
            best = suggestions[key]
            hint = f"  -> {best}?" if best and best != key else ""
        print(f"{rid}  {path}  [{check}] {detail}{hint}")
    counts: dict[str, int] = {}
    for f in findings:
        counts[f[2]] = counts.get(f[2], 0) + 1
    mode = "offline lexicon" if sc is None else "pyspellchecker"
    print(f"\n{len(findings)} finding(s) [{mode}] {counts or ''}".rstrip())
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())
