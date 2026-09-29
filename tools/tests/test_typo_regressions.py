"""Fixed typos (docs/TYPO_FIXES.md) must not come back.

Each rule bans a "before" string that was corrected, scoped to the record and
fields it was fixed in (or to every stem and choice when the text is wrong
anywhere). Needles are chosen so the corrected "after" text never contains them.
A rebuild that drops an override, or a builder change that re-imports the PDF
wording, fails here instead of shipping the old typo.
"""
from __future__ import annotations

import json
import re
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
BANK = ROOT / "data" / "question_bank.json"

STEM = ("prompt",)
CHOICES = ("answers",)
STEM_CHOICES = ("prompt", "answers")
NOTES = ("choice_notes", "tip_short")
GIST = ("gist",)

# (record id or None for every record, fields, kind, needle)
# kind: "has" = case-sensitive substring, "is" = whole value (or list item), "re" = regex search.
BANK_RULES = [
    # Wrong in any stem or choice.
    (None, STEM_CHOICES, "has", "sq.ft."),
    (None, STEM_CHOICES, "has", "name plate"),
    (None, STEM_CHOICES, "has", "weather proof"),
    (None, STEM_CHOICES, "has", "water proof"),
    (None, STEM_CHOICES, "has", "Over Flow"),
    (None, STEM_CHOICES, "has", "copper bus bar"),
    (None, STEM_CHOICES, "has", "Underwriters' Laboratories"),
    (None, STEM_CHOICES, "has", "ignitable"),
    (None, STEM_CHOICES, "re", r"\bonsite\b"),
    (None, STEM_CHOICES, "re", r"\bDivision II\b"),
    (None, STEM_CHOICES, "re", r"\b\d+or\b"),
    (None, CHOICES, "re", r"^\d+k[Vv][Aa]$"),
    # OCR blank damage: "designated as .", "at least :", "Article__.", "with __."
    (None, STEM, "re", r"\s[.:]$"),
    (None, STEM, "re", r"[A-Za-z]__"),
    (None, STEM, "re", r"(?<!_)__(?!_)"),
    (None, STEM, "has", "____"),
    # Final Exam #1
    ("final-exam-#1-004", STEM, "has", "sq.ft."),
    ("final-exam-#1-005", GIST, "has", "yet the lamp is dark:"),
    ("final-exam-#1-011", STEM, "has", "bedroom, any wall space"),
    ("final-exam-#1-019", STEM, "has", "stating the question"),
    ("final-exam-#1-022", STEM, "has", "accommodate a pair of vehicles"),
    ("final-exam-#1-026", STEM, "has", "on the insulation, what does"),
    ("final-exam-#1-030", STEM, "has", "space-heating equipment"),
    ("final-exam-#1-034", STEM, "has", "permitted in wet location"),
    ("final-exam-#1-042", CHOICES, "is", "weather proof"),
    ("final-exam-#1-048", CHOICES, "is", "need a 20 amp receptacle"),
    ("final-exam-#1-051", STEM, "re", r"^Personnel doors where"),
    ("final-exam-#1-051", STEM, "re", r"working space\.$"),
    ("final-exam-#1-053", STEM, "has", "1,000 volts passing over"),
    ("final-exam-#1-056", STEM, "has", "single-phase, receptacle"),
    ("final-exam-#1-061", CHOICES, "is", "Class II, Division II"),
    ("final-exam-#1-066", GIST, "has", "flexible raceway"),
    ("final-exam-#1-070", STEM, "has", "3, 480v"),
    # Final Exam #3
    ("final-exam-#3-018", CHOICES, "is", '8"'),
    ("final-exam-#3-034", CHOICES, "is", '11/2"'),
    ("final-exam-#3-042", STEM, "has", "___ separable connector"),
    ("final-exam-#3-047", STEM, "has", "formed ina"),
    ("final-exam-#3-049", CHOICES, "is", '10"'),
    ("final-exam-#3-049", CHOICES, "is", '50"'),
    ("final-exam-#3-068", CHOICES, "is", "the branch circuit feeding it"),
    # Final Exam #5
    ("final-exam-#5-006", STEM, "has", "necessary does not have"),
    ("final-exam-#5-023", STEM, "has", "___. times"),
    ("final-exam-#5-023", CHOICES, "is", "twenty four"),
    ("final-exam-#5-023", CHOICES, "is", "thirty six"),
    ("final-exam-#5-023", NOTES, "has", "Twenty four times"),
    ("final-exam-#5-023", NOTES, "has", "Thirty six times"),
    ("final-exam-#5-038", CHOICES, "has", "installations requires"),
    ("final-exam-#5-050", STEM, "has", "buildings, shall have"),
    ("final-exam-#5-053", CHOICES, "is", "41/2"),
    ("final-exam-#5-066", STEM, "has", "Chapter 9, Table..."),
    # Open Book exams
    ("open-book-exam-#1-005", STEM, "has", "requires GFCI protected"),
    ("open-book-exam-#1-010", STEM, "has", "receptacles that are installed within"),
    ("open-book-exam-#7-002", GIST, "has", "which table holds it."),
    ("open-book-exam-#7-005", STEM, "re", r"^___ The highest"),
    ("open-book-exam-#7-016", GIST, "has", "During normal power loss"),
    ("open-book-exam-#10-006", STEM, "re", r"^An electric device"),
    ("open-book-exam-#10-009", STEM, "re", r"^The individual responsible"),
    ("open-book-exam-#10-010", STEM, "has", "material-handling door"),
    ("open-book-exam-#10-012", STEM, "has", "___ volt amperes"),
    ("open-book-exam-#10-017", CHOICES, "is", "Class II, Division II"),
    ("open-book-exam-#10-023", GIST, "has", "must have it."),
]

# (file, banned substring) for UI strings fixed in the results screen.
UI_RULES = [
    ("src/ui/results_view.gd", "FAILED ITEMS)"),
    ("src/ui/results_view.gd", "%d were left unanswered"),
    ("src/ui/results_view.gd", '"Code Key:'),
    ("src/ui/results_view.gd", ': item %s."'),
]


def values(record: dict, field: str) -> list[str]:
    value = record.get(field)
    if isinstance(value, list):
        return [str(v) for v in value]
    return [] if value is None else [str(value)]


def hits(text: str, kind: str, needle: str) -> bool:
    if kind == "has":
        return needle in text
    if kind == "is":
        return text == needle
    return re.search(needle, text) is not None


def violations(records: list[dict], rules=BANK_RULES) -> list[str]:
    by_id = {r.get("id"): r for r in records}
    out = []
    for rid, fields, kind, needle in rules:
        targets = records if rid is None else [by_id[rid]] if rid in by_id else []
        for record in targets:
            for field in fields:
                for text in values(record, field):
                    if hits(text, kind, needle):
                        out.append("%s %s: %r matches banned %s %r" % (record.get("id"), field, text[:90], kind, needle))
    return out


class BankTypoRegressions(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.records = json.loads(BANK.read_text(encoding="utf-8"))["records"]

    def test_no_fixed_typo_reappears(self):
        found = violations(self.records)
        self.assertEqual(found, [], "fixed typos are back (see docs/TYPO_FIXES.md):\n" + "\n".join(found))

    def test_every_rule_names_a_live_record(self):
        ids = {r.get("id") for r in self.records}
        stale = sorted({rid for rid, *_ in BANK_RULES if rid is not None and rid not in ids})
        self.assertEqual(stale, [], "rules point at records that no longer exist")

    def test_rules_catch_their_before_text(self):
        before = [
            {"id": "final-exam-#1-019", "prompt": "What does the alpha character I represent when stating the question W = E x I?"},
            {"id": "final-exam-#1-051", "prompt": "Personnel doors where equipment rated 800 amperes or more ... less than ___ feet from the nearest edge of the working space."},
            {"id": "final-exam-#1-061", "answers": ["Class I", "Class II", "Class III", "Class II, Division II"]},
            {"id": "final-exam-#5-023", "choice_notes": ["Twenty four times is double the requirement."]},
            {"id": "final-exam-#3-058", "prompt": "The definition is found in Article__."},
            {"id": "final-exam-#3-011", "prompt": "Most incidents and injuries are initiated by ."},
            {"id": "open-book-exam-#7-016", "prompt": "type and ___ of each onsite emergency power source."},
        ]
        found = violations(before)
        for rid in ("final-exam-#1-019", "final-exam-#1-051", "final-exam-#1-061", "final-exam-#5-023",
                    "final-exam-#3-058", "final-exam-#3-011", "open-book-exam-#7-016"):
            self.assertTrue(any(v.startswith(rid + " ") for v in found), rid)

    def test_corrected_text_is_not_flagged(self):
        after = [
            {"id": "final-exam-#1-061", "prompt": "___ locations are those that are hazardous because of the presence of easily ignitible fibers or flyings.",
             "answers": ["Class I", "Class II", "Class III", "Class II, Division 2"]},
            {"id": "final-exam-#3-026", "answers": ["12 kVA", "15 kVA"]},
            {"id": "final-exam-#3-049", "prompt": "At least one 125-volt, single-phase, 15- or 20-ampere-rated receptacle outlet shall be installed within ___ of the service.",
             "answers": ["10'", "50'"]},
            {"id": "open-book-exam-#7-024", "prompt": "a 4-wire, ___-connected system marked \u201cCaution ___ Phase Has ___ Volts to Ground.\u201d"},
        ]
        self.assertEqual(violations(after), [])


class UiTypoRegressions(unittest.TestCase):
    def test_results_screen_strings_stay_fixed(self):
        found = []
        for rel, needle in UI_RULES:
            if needle in (ROOT / rel).read_text(encoding="utf-8"):
                found.append("%s still contains %r" % (rel, needle))
        self.assertEqual(found, [])


if __name__ == "__main__":
    unittest.main()
