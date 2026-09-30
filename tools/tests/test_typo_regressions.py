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
SHOWN = ("prompt", "answers", "gist", "tip_short", "choice_notes", "reference_text", "worked", "formula")

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
    # Grammar slips the voice rules once produced ("an hot wire", "motors are
    # has", "rated at at most", "NM cables is not permitted"); none may appear
    # in text shown on screen either.
    (None, SHOWN, "re", r"\b[Aa]n (hot|reachable)\b"),
    (None, SHOWN, "re", r"\b(is|are) has\b"),
    (None, SHOWN, "re", r"\bat at\b"),
    (None, SHOWN, "re", r"\b(cables|cords|cord types|motors) is (not )?(permitted|required)\b"),
    (None, SHOWN, "re", r"(?<!\.)\.\.(?!\.)"),
    # Final Exam #1
    ("final-exam-#1-004", STEM, "has", "sq.ft."),
    ("final-exam-#1-005", GIST, "has", "yet the lamp is dark:"),
    ("final-exam-#1-011", STEM, "has", "bedroom, any wall space"),
    ("final-exam-#1-019", STEM, "has", "stating the question"),
    ("final-exam-#1-022", STEM, "has", "accommodate a pair of vehicles"),
    ("final-exam-#1-026", STEM, "has", "on the insulation, what does"),
    ("final-exam-#1-030", STEM, "has", "space-heating equipment"),
    ("final-exam-#1-034", STEM, "has", "permitted in wet location"),
    ("final-exam-#1-034", STEM, "has", "cord types is permitted"),
    ("final-exam-#1-034", STEM, "has", "cord types are permitted"),
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
    ("final-exam-#3-052", NOTES, "has", "four units is not required"),
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
    ("open-book-exam-#4-025", STEM, "has", "cord types is permitted"),
    ("open-book-exam-#4-025", STEM, "has", "cord types are permitted"),
    ("open-book-exam-#7-002", GIST, "has", "which table holds it."),
    ("open-book-exam-#7-005", STEM, "re", r"^___ The highest"),
    ("open-book-exam-#7-016", GIST, "has", "During normal power loss"),
    ("open-book-exam-#10-006", STEM, "re", r"^An electric device"),
    ("open-book-exam-#10-009", STEM, "re", r"^The individual responsible"),
    ("open-book-exam-#10-010", STEM, "has", "material-handling door"),
    ("open-book-exam-#10-012", STEM, "has", "___ volt amperes"),
    ("open-book-exam-#10-017", CHOICES, "is", "Class II, Division II"),
    ("open-book-exam-#10-023", GIST, "has", "must have it."),
    # Exams imported 2026-09-29 (open book #2, #3, #5, #6, #9, #11, #12; final #2, #4)
    ("final-exam-#2-023", CHOICES, "has", "Type 4 X"),
    ("final-exam-#2-030", CHOICES, "has", "1/2'"),
    ("final-exam-#2-055", CHOICES, "has", "Length of the Conductor"),
    ("final-exam-#2-055", CHOICES, "has", "Diameter of the Conductor"),
    ("final-exam-#2-055", CHOICES, "has", "Insulation of the Conductor"),
    ("final-exam-#2-062", STEM, "has", "one-and two-family"),
    ("final-exam-#2-062", STEM, "has", "the date of the calculation was performed"),
    ("final-exam-#2-066", STEM, "has", "at normal voltage"),
    ("final-exam-#2-070", CHOICES, "has", "3/4”"),
    ("final-exam-#4-022", STEM, "has", "0.30 sq. in.,"),
    ("final-exam-#4-047", STEM, "has", "sq.ft,"),
    ("open-book-exam-#11-018", STEM, "has", "one-and two-family"),
    ("open-book-exam-#11-018", STEM, "has", "the date of the calculation was performed"),
    ("open-book-exam-#12-006", STEM, "has", "at normal voltage"),
    ("open-book-exam-#12-021", CHOICES, "has", "3/4”"),
    ("open-book-exam-#12-022", CHOICES, "has", "5’"),
    ("open-book-exam-#2-010", STEM, "has", "messsenger"),
    ("open-book-exam-#2-011", STEM, "has", "in all of the following locations listed locations except"),
    ("open-book-exam-#2-024", STEM, "has", "recptacles"),
    ("open-book-exam-#2-025", STEM, "has", "with in"),
    ("open-book-exam-#3-004", CHOICES, "has", "neither GFCI and AFCI"),
    ("open-book-exam-#3-007", STEM, "has", "serving both controllers"),
    ("open-book-exam-#3-008", STEM, "has", "switchgear or, panelboard"),
    ("open-book-exam-#3-011", STEM, "has", "on the insulation, what does"),
    ("open-book-exam-#3-017", STEM, "has", "receptacle outlet(s) shall be installed"),
    ("open-book-exam-#3-023", STEM, "has", "grounded electrode system"),
    ("open-book-exam-#3-024", CHOICES, "has", "to withstand environment"),
    ("open-book-exam-#5-002", STEM, "has", "name plate"),
    ("open-book-exam-#5-006", STEM, "has", "A household electric range"),
    ("open-book-exam-#5-009", STEM, "has", "carnivals and fairs, shall"),
    ("open-book-exam-#5-012", STEM, "has", "shall be provided ground-fault protection"),
    ("open-book-exam-#5-014", STEM, "has", "Overhead conductors not over 1,000 volts pass over a track rails of railroads"),
    ("open-book-exam-#5-017", STEM, "has", "overcurrent devices, is installed"),
    ("open-book-exam-#5-018", STEM, "has", "roofs which they pass"),
    ("open-book-exam-#5-019", STEM, "has", "sytems"),
    ("open-book-exam-#6-005", STEM, "has", "Overhead conductors not over 1,000 volts pass over"),
    ("open-book-exam-#6-018", STEM, "has", "being charged, requires"),
    ("open-book-exam-#6-019", STEM, "has", "25 ohms or less, can be"),
    ("open-book-exam-#9-003", STEM, "has", "Information note:"),
    ("open-book-exam-#9-008", STEM, "has", "point of connection ."),
    ("open-book-exam-#9-010", CHOICES, "has", "1/2'"),
    ("open-book-exam-#7-017", STEM, "has", "temperature rating of the conductor"),
    # A curated stem must also replace the OCR stem quoted in the plain-language background.
    ("open-book-exam-#2-010", ("info_tip",), "has", "messsenger"),
    ("open-book-exam-#5-019", ("info_tip",), "has", "sytems"),
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
            {"id": "open-book-exam-#4-025", "prompt": "Which of the following cord types is permitted in a wet location and is sunlight resistant?"},
            {"id": "final-exam-#3-061", "choice_notes": ["Motors are has terminal housings rated at at most 167 percent."]},
            {"id": "final-exam-#1-030", "tip_short": "Located in an reachable location, next to an hot wire."},
        ]
        found = violations(before)
        for rid in ("final-exam-#1-019", "final-exam-#1-051", "final-exam-#1-061", "final-exam-#5-023",
                    "final-exam-#3-058", "final-exam-#3-011", "open-book-exam-#7-016",
                    "open-book-exam-#4-025", "final-exam-#3-061", "final-exam-#1-030"):
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


class CordQuestionRegressions(unittest.TestCase):
    """The wet-location cord question (Table 400.4): one flexible cord among the
    choices, and a table that names every choice, so it waits until answering."""
    IDS = ("final-exam-#1-034", "open-book-exam-#4-025")

    @classmethod
    def setUpClass(cls):
        records = json.loads(BANK.read_text(encoding="utf-8"))["records"]
        cls.by_id = {r["id"]: r for r in records}

    def test_table_has_a_row_per_choice_and_waits_for_the_answer(self):
        for rid in self.IDS:
            rec = self.by_id[rid]
            types = [row[0] for row in rec["reference_table"][1:] if len(row) > 1]
            self.assertEqual(types, rec["answers"], rid)
            self.assertTrue(rec.get("table_after_answer"), rid)

    def test_stem_asks_for_one_flexible_cord(self):
        for rid in self.IDS:
            rec = self.by_id[rid]
            self.assertIn("is a flexible cord type", rec["prompt"], rid)
            self.assertEqual(rec["answers"][rec["correct_index"]], "STOOW", rid)


class TranscriptRegressions(unittest.TestCase):
    """Transcripts are the exam as printed; words once mistyped there stay fixed."""
    RULES = [
        ("Journeyman open book exam #1", 4, "answers", '1 1/8"'),
        ("Journeyman open book exam #4", 25, "prompt", "in a wet location"),
    ]

    def test_transcript_typos_stay_fixed(self):
        found = []
        for name, number, field, needle in self.RULES:
            data = json.loads((ROOT / "tools/pipeline/sources/exams" / (name + ".json")).read_text(encoding="utf-8"))
            q = next(q for q in data["questions"] if q["number"] == number)
            texts = q[field] if isinstance(q[field], list) else [q[field]]
            if any(needle in str(t) for t in texts):
                found.append("%s Q%d %s contains %r" % (name, number, field, needle))
        self.assertEqual(found, [])


class UiTypoRegressions(unittest.TestCase):
    def test_results_screen_strings_stay_fixed(self):
        found = []
        for rel, needle in UI_RULES:
            if needle in (ROOT / rel).read_text(encoding="utf-8"):
                found.append("%s still contains %r" % (rel, needle))
        self.assertEqual(found, [])


if __name__ == "__main__":
    unittest.main()
