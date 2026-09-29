"""The original study figures are built from code and must match what's committed.

tools/diagrams/build.py --check redraws every figure in memory and fails if a
record lacks a figure, a record's answer shows outside its masks (leak scan),
a label runs off the canvas, or the committed SVG / figures.json / masks /
labels are stale.
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


if __name__ == "__main__":
    unittest.main()
