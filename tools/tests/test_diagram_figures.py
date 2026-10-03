"""The original study figures are built from code and must match what's committed.

tools/diagrams/build.py --check redraws every figure in memory and fails if a
record lacks a figure, a record's answer shows outside its masks (leak scan),
a label runs off the canvas, or the committed SVG / figures.json / masks /
labels are stale. Every question gets at most one figure, and each figure
teaches the single section its questions cite.
"""
import importlib.util
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


@unittest.skipUnless(importlib.util.find_spec("pymupdf") and importlib.util.find_spec("PIL"),
                     "PyMuPDF and Pillow draw the figures")
class DiagramFiguresTest(unittest.TestCase):
    def test_build_check(self):
        run = subprocess.run([sys.executable, str(ROOT / "tools" / "diagrams" / "build.py"), "--check"],
                             capture_output=True, text=True, cwd=ROOT)
        self.assertEqual(run.returncode, 0, run.stdout + run.stderr)

    def test_leak_scan_rules(self):
        sys.path.insert(0, str(ROOT / "tools" / "diagrams"))
        import leakscan
        rec = {"prompt": "Rods shall be not less than ___ apart.",
               "answers": ["36 inches", "48 inches", "60 inches", "72 inches"], "correct_index": 3}
        lab = [["6 ft min", 0.4, 0.4, 0.1, 0.05]]
        self.assertTrue(leakscan.leaks(rec, lab, []))
        self.assertFalse(leakscan.leaks(rec, lab, [{"rect": [0.35, 0.35, 0.2, 0.15]}]))
        self.assertFalse(leakscan.leaks(rec, [["8 ft rod", 0.4, 0.4, 0.1, 0.05]], []))
        deck = {"prompt": "not more than ___ above the deck", "answers": ["6'", "6'6\"", "7'", "8'"], "correct_index": 1}
        self.assertTrue(leakscan.leaks(deck, [["78 in max", 0.1, 0.1, 0.1, 0.05]], []))
        word = {"prompt": "The link is the ___.", "answers": ["neutral", "equipment bonding jumper",
                                                             "main bonding jumper", "GEC"], "correct_index": 2}
        self.assertTrue(leakscan.leaks(word, [["MAIN BONDING JUMPER", 0.4, 0.4, 0.2, 0.05]], []))

    def test_strict_rule_unit_variants(self):
        sys.path.insert(0, str(ROOT / "tools" / "diagrams"))
        import leakscan
        rec = {"prompt": "The handle grip in its highest position shall be not more than ___ above grade.",
               "answers": ["6 ft 7 in", "6 ft", "7 ft", "8 ft"], "correct_index": 0}
        given, vals, phrases = leakscan.strict_keys(rec)
        for shown in ("6 ft 7 in max", "6'7\"", "79 in", "2.0 m", "2 m", "(2.0 m)", "7 ft", "96 in"):
            self.assertTrue(leakscan.strict_hits(shown, given, vals, phrases), shown)
        for shown in ("handle grip", "Article 680", "finished grade"):
            self.assertFalse(leakscan.strict_hits(shown, given, vals, phrases), shown)
        self.assertEqual(leakscan.strict_hits("120/240 V", {("V", 120.0), ("V", 240.0)}, set(), set()), [])
        sib = {"prompt": "x", "answers": ["GFCI", "AFCI", "LCDI", "none of these"], "correct_index": 0}
        _, vals, phrases = leakscan.strict_keys(rec, [sib])
        self.assertTrue(leakscan.strict_hits("AFCI breaker", set(), vals, phrases))

    def test_section_numbers_never_show_before_answering(self):
        sys.path.insert(0, str(ROOT / "tools" / "diagrams"))
        import leakscan
        for shown in ("NEC 408.36(B)", "NEC 550.32(F)", "Table 310.16", "Ex.: 240.21(C)(1) note",
                      "Part II", "90.2", "NEC 700.32, 701.32, 708.54"):
            self.assertTrue(leakscan.location_refs(shown), shown)
            self.assertTrue(leakscan.strict_hits(shown, set(), set(), set()), shown)
        for shown in ("Article 680", "NEC", "12.5 ft", "155.5 A", "34.8 A", "21.25 kW", "10.0", "part of"):
            self.assertFalse(leakscan.location_refs(shown), shown)


@unittest.skipUnless(importlib.util.find_spec("pymupdf"), "the figure registry imports PyMuPDF")
class PreAnswerFigureTextTest(unittest.TestCase):
    """Committed figures, as the app shows them before answering: no label outside the
    record's masks may state a rule value the stem doesn't give, or any answer choice
    (right or wrong) of any question that shares the figure."""

    def test_no_choice_or_value_visible_before_answering(self):
        import json
        sys.path.insert(0, str(ROOT / "tools" / "diagrams"))
        import leakscan
        bank = {r["id"]: r for r in json.loads((ROOT / "data" / "question_bank.json").read_text(encoding="utf-8"))["records"]}
        figs = json.loads((ROOT / "assets" / "diagrams" / "nec" / "figures.json").read_text(encoding="utf-8"))
        masks = json.loads((ROOT / "data" / "diagram_masks.json").read_text(encoding="utf-8"))["records"]
        labels = json.loads((ROOT / "docs" / "diagrams" / "labels.json").read_text(encoding="utf-8"))
        import re
        import build
        keep = {n: [re.compile(k, re.I) for k in s.get("keep", ())] for n, s in build.load_figs().items()}
        by_fig = {}
        for rid, e in figs.items():
            by_fig.setdefault(e["figure"], []).append(rid)
        bad, checked = [], 0
        for rid, e in sorted(figs.items()):
            if e["when"] != "before":
                continue
            checked += 1
            sib = [bank[r] for r in by_fig[e["figure"]] if r != rid]
            terms = masks[rid].get("terms", [])
            given, vals, phrases = leakscan.strict_keys(bank[rid], sib, terms)
            ms = masks[rid]["masks"]
            for text, *box in labels[f"{e['figure']}.png"]:
                if any(k.search(text) for k in keep.get(e["figure"], [])) or leakscan.covered(box, ms):
                    continue
                hit = leakscan.strict_hits(text, given, vals, phrases)
                if hit:
                    bad.append(f"{rid} ({e['figure']}): {text!r} {hit}")
        self.assertGreater(checked, 200)
        self.assertEqual(bad, [], "\n".join(bad[:40]))

    def test_no_section_table_or_part_visible_before_answering(self):
        """Every label, title, section chip and note, kept or not: the section,
        table or Part that holds the answer only shows once it is answered."""
        import json
        import re
        sys.path.insert(0, str(ROOT / "tools" / "diagrams"))
        import leakscan
        loc = re.compile(r"(?<![\w.])(?:90|\d{3})\.\d+(?![\d.]*\s*(?i:%|\"|'|in\b|inch|ft\b|feet|foot|mm\b|m\b|v\b|"
                         r"volt|a\b|amp|kva|va\b|kw\b|w\b|hz|ohm|deg))|\b[Tt]ables?\s+\d|\b[Pp]art\s+[IVX]+\b")
        figs = json.loads((ROOT / "assets" / "diagrams" / "nec" / "figures.json").read_text(encoding="utf-8"))
        masks = json.loads((ROOT / "data" / "diagram_masks.json").read_text(encoding="utf-8"))["records"]
        labels = json.loads((ROOT / "docs" / "diagrams" / "labels.json").read_text(encoding="utf-8"))
        bad, chips = [], 0
        for rid, e in sorted(figs.items()):
            if e["when"] != "before":
                continue
            ms = masks[rid]["masks"]
            chips += any(m.get("label") == "NEC ?" for m in ms)
            for text, *box in labels[f"{e['figure']}.png"]:
                if loc.search(text) and not leakscan.covered(box, ms):
                    bad.append(f"{rid} ({e['figure']}): {text!r}")
        self.assertGreater(chips, 150)
        self.assertEqual(bad, [], "\n".join(bad[:40]))


@unittest.skipUnless(importlib.util.find_spec("pymupdf") and importlib.util.find_spec("PIL"),
                     "PyMuPDF and Pillow draw the figures")
class OneFigureOneRuleTest(unittest.TestCase):
    """A question shows one diagram, and that diagram teaches the one rule its stem cites:
    no record is claimed by two figures (or by a figure and a scanned crop), and no
    figure is a composite of panels for different sections."""

    def test_each_record_has_at_most_one_figure(self):
        import json
        sys.path.insert(0, str(ROOT / "tools" / "diagrams"))
        import build
        owners = {}
        for name, spec in build.load_figs().items():
            for rid in spec["records"]:
                owners.setdefault(rid, []).append(name)
        twice = {rid: names for rid, names in owners.items() if len(names) > 1}
        self.assertEqual(twice, {}, "records drawn by more than one figure")
        crops = json.loads((ROOT / "assets" / "diagrams" / "diagrams.json").read_text(encoding="utf-8"))
        self.assertEqual(sorted(set(crops) & set(owners)), [], "records with a figure and a scanned crop")

    def test_each_figure_teaches_one_section(self):
        import json
        sys.path.insert(0, str(ROOT / "tools" / "diagrams"))
        import build
        bank = {r["id"]: r for r in json.loads((ROOT / "data" / "question_bank.json").read_text(encoding="utf-8"))["records"]}
        drawn = build.draw_all(every_tier=True)
        self.assertGreater(len(drawn), 150)
        errors = [e for name, d in sorted(drawn.items()) for e in build.topic_errors(name, d, bank)]
        self.assertEqual(errors, [], "\n".join(errors[:40]))

    def test_sections_parser(self):
        sys.path.insert(0, str(ROOT / "tools" / "diagrams"))
        import build
        self.assertEqual(build.sections("210.52(C)(1)"), {"210.52"})
        self.assertEqual(build.sections("Table 310.4(1)"), {"310.4"})
        self.assertEqual(build.sections("Article 100 (Bottom Shield)"), {"100"})
        self.assertEqual(build.sections("503.1"), {"500.5"})
        self.assertEqual(len(build.sections("408.18(C), 408.3(A)(2)")), 2)


if __name__ == "__main__":
    unittest.main()
