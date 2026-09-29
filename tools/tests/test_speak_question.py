from __future__ import annotations

import asyncio
import importlib.util
import json
import tempfile
import time
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("speak_question", ROOT / "src" / "speech" / "speak_question.py")
speak = importlib.util.module_from_spec(spec)
spec.loader.exec_module(speak)


class FakeRender:
    """Stands in for Edge: per-call delays, optional failures, counts calls."""

    def __init__(self, delays, fail_calls=(), size=4000):
        self.delays = list(delays)
        self.fail_calls = set(fail_calls)
        self.size = size
        self.calls = 0

    async def __call__(self, text, part, voice):
        call = self.calls
        self.calls += 1
        await asyncio.sleep(self.delays[min(call, len(self.delays) - 1)])
        if call in self.fail_calls:
            raise OSError("fake failure %d" % call)
        Path(part).write_bytes(b"ID3" + bytes(self.size))


class SpeakClip(unittest.TestCase):
    def setUp(self):
        self.dir = Path(tempfile.mkdtemp())
        self.saved = (speak._render, speak.HEDGE_AFTER, speak.RETRY_DELAYS, speak.FAKE_CLIP)
        speak.HEDGE_AFTER = 0.1
        speak.RETRY_DELAYS = (0.01, 0.01)
        speak.FAKE_CLIP = ""

    def tearDown(self):
        speak._render, speak.HEDGE_AFTER, speak.RETRY_DELAYS, speak.FAKE_CLIP = self.saved

    def leftovers(self):
        return sorted(p.name for p in self.dir.iterdir() if p.name.endswith(".part"))

    def test_slow_clip_is_hedged(self):
        speak._render = FakeRender([2.0, 0.05])
        start = time.perf_counter()
        asyncio.run(speak._speak("hi", self.dir / "0.mp3", "v"))
        self.assertLess(time.perf_counter() - start, 1.0, "the second request should win")
        self.assertEqual(speak._render.calls, 2)
        self.assertTrue((self.dir / "0.mp3").exists())
        self.assertEqual(self.leftovers(), [])

    def test_fast_clip_is_not_hedged(self):
        speak._render = FakeRender([0.01])
        asyncio.run(speak._speak("hi", self.dir / "0.mp3", "v"))
        self.assertEqual(speak._render.calls, 1)

    def test_failure_is_retried(self):
        speak._render = FakeRender([0.01], fail_calls={0})
        asyncio.run(speak._speak("hi", self.dir / "0.mp3", "v"))
        self.assertTrue((self.dir / "0.mp3").exists())
        self.assertEqual(self.leftovers(), [])

    def test_persistent_failure_raises_and_cleans_up(self):
        speak._render = FakeRender([0.01], fail_calls=set(range(20)))
        with self.assertRaises(OSError):
            asyncio.run(speak._speak("hi", self.dir / "0.mp3", "v"))
        self.assertFalse((self.dir / "0.mp3").exists())
        self.assertEqual(self.leftovers(), [])

    def test_cut_off_clip_is_refused(self):
        text = "A sign must be placed at the service-entrance equipment, indicating the type and location of each on-site emergency power source."
        self.assertGreater(speak.min_clip_bytes(text), 40_000)
        speak._render = FakeRender([0.01], size=2_880)
        with self.assertRaisesRegex(RuntimeError, "cut-off audio"):
            asyncio.run(speak._speak(text, self.dir / "0.mp3", "v"))
        self.assertEqual(speak._render.calls, 3)
        self.assertFalse((self.dir / "0.mp3").exists())
        self.assertEqual(self.leftovers(), [])

    def test_long_enough_clip_is_kept(self):
        text = "Section 700 point 7: a sign at the service equipment."
        speak._render = FakeRender([0.01], size=speak.min_clip_bytes(text) + 1)
        asyncio.run(speak._speak(text, self.dir / "0.mp3", "v"))
        self.assertTrue((self.dir / "0.mp3").exists())

    def test_failed_synthesis_leaves_no_clips_or_manifest(self):
        speak._render = FakeRender([0.01], fail_calls=set(range(1, 40)))
        segments = [{"text": "a"}, {"text": "b"}, {"text": "c"}]
        with self.assertRaises(OSError):
            speak.synthesize(segments, self.dir, "v")
        self.assertEqual(sorted(p.name for p in self.dir.iterdir()), [])

    def test_synthesis_writes_manifest_last_with_format(self):
        speak._render = FakeRender([0.01])
        rows = speak.synthesize([{"text": "a", "rules": 3}, {"text": " "}, {"text": "c", "teach": True}], self.dir, "v")
        manifest = json.loads((self.dir / "manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest, rows)
        self.assertEqual([r["file"] for r in manifest], ["0.mp3", "2.mp3"])
        self.assertTrue(all(r["format"] == speak.OUTPUT_FORMAT for r in manifest))


if __name__ == "__main__":
    unittest.main()
