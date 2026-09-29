from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("audit_bundle", ROOT / "tools" / "speech" / "audit_bundle.py")
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)

# One 24 kHz / 96 kbps MPEG-2 Layer III frame: 288 bytes, 576 samples (24 ms).
FRAME = bytes([0xFF, 0xF3, 0xA4, 0xC4]) + bytes(284)


def frames(count: int) -> bytes:
    return FRAME * count


class ParseFrames(unittest.TestCase):
    def test_clean_run(self):
        got = audit.parse_frames(frames(50))
        self.assertEqual(got["problem"], "")
        self.assertEqual(got["frames"], 50)
        self.assertEqual(got["rates"], {24000})
        self.assertEqual(got["kbps"], {96})

    def test_torn_last_frame(self):
        self.assertIn("torn", audit.parse_frames(frames(10)[:-100])["problem"])

    def test_junk_after_frames(self):
        self.assertNotEqual(audit.parse_frames(frames(10) + b"\x01\x02\x03\x04\x05")["problem"], "")

    def test_id3_tag_is_skipped(self):
        tag = b"ID3\x04\x00\x00\x00\x00\x00\x05" + bytes(5)
        self.assertEqual(audit.parse_frames(tag + frames(3))["frames"], 3)


class TextAndDuration(unittest.TestCase):
    def test_unfinished_text(self):
        self.assertEqual(audit.text_problem("Stainless steel."), "")
        self.assertIn("does not end", audit.text_problem("Stainless steel"))
        self.assertIn("parenthesis", audit.text_problem("A rule (with a note."))

    def test_duration_bounds(self):
        shortest, longest = audit.expected_bounds(2)
        self.assertEqual(shortest, audit.MIN_CLIP_SEC)
        shortest, longest = audit.expected_bounds(100)
        self.assertGreater(shortest, 20.0)
        self.assertLess(longest, 115.0)


class AuditFolder(unittest.TestCase):
    def _bundle(self, audio: bytes, text: str) -> Path:
        root = Path(tempfile.mkdtemp())
        folder = root / "q-1__en-US-AndrewNeural"
        folder.mkdir()
        (folder / "0.mp3").write_bytes(audio)
        (folder / "manifest.json").write_text(json.dumps([
            {"file": "0.mp3", "choice": -1, "teach": False, "rules": 4, "format": audit.EXPECTED_FORMAT, "text": text}]))
        return root

    def test_plausible_clip_passes(self):
        # 4 words over 2.4 s of frames.
        report = audit.audit(self._bundle(frames(100), "Four words said here."), structure_only=True)
        self.assertEqual(report["problems"], [])

    def test_clip_too_short_for_its_text(self):
        report = audit.audit(self._bundle(frames(40), " ".join(["word"] * 60) + "."), structure_only=True)
        self.assertTrue(any("too short" in p["why"] for p in report["problems"]))

    def test_torn_clip_fails(self):
        report = audit.audit(self._bundle(frames(100)[:-50], "Four words said here."), structure_only=True)
        self.assertTrue(any("torn" in p["why"] for p in report["problems"]))


if __name__ == "__main__":
    unittest.main()
