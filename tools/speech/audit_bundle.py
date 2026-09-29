"""Audits the bundled voice clips (res://assets/speech) for cut-off speech.

    python tools/speech/audit_bundle.py [--root assets/speech] [--json report.json] [--structure-only]

Every clip named in every manifest.json is checked:
  structure  the file is a clean chain of whole MPEG audio frames in the Edge
             output format (no torn last frame, no junk, no ID3 surprises)
  duration   seconds per spoken word is plausible for the text, so a clip that
             stops early (or a text that lost words) stands out
  edges      decoded with PyAV when installed: the first ~15 ms and the last
             ~100 ms must be quiet, so speech neither starts clipped nor stops
             mid-word

Also fails when a manifest row's text looks cut short (no terminal punctuation
on a long line) or a folder is missing clips. Exit 0 when clean, 1 otherwise.
The decoded checks need `av` and `numpy`; without them (or with
--structure-only) only the structure and frame-count duration are checked.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
EXPECTED_FORMAT = "audio-24khz-96kbitrate-mono-mp3"
EXPECTED_RATE = 24000
EXPECTED_KBPS = 96

# Andrew at rate +0% speaks about 2.3-3.2 words per second on these lines;
# the bounds are loose so only real outliers trip them.
MAX_WORDS_PER_SEC = 4.6
MIN_WORDS_PER_SEC = 0.9
# Short lines ("Option A.") carry fixed lead-in/out silence, so they get a floor.
MIN_CLIP_SEC = 0.45
# Loudness (dBFS RMS) the edges must stay under to count as silence/decay.
TAIL_MS = 100
HEAD_MS = 15
EDGE_MAX_DBFS = -30.0
# Edge clips carry ~290-400 ms of silence after the last word and ~130 ms
# before the first; a player that drops the final frames (or a torn download)
# eats into that first, so less than this means speech itself is at risk.
SPEECH_DBFS = -45.0
MIN_TAIL_SILENCE_MS = 150
MIN_HEAD_SILENCE_MS = 50

_BITRATES = {  # (version_bits, layer_bits) -> kbps table index 1..14
    "v1l3": [32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320],
    "v2l3": [8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160],
}
_RATES = {3: [44100, 48000, 32000], 2: [22050, 24000, 16000], 0: [11025, 12000, 8000]}


def parse_frames(data: bytes) -> dict:
    """Walks MPEG-1/2/2.5 Layer III frames. Returns counts and any problem."""
    pos = 0
    if data[:3] == b"ID3" and len(data) >= 10:
        size = (data[6] << 21) | (data[7] << 14) | (data[8] << 7) | data[9]
        pos = 10 + size
    frames = 0
    samples = 0
    rates: set = set()
    kbps: set = set()
    problem = ""
    while pos < len(data):
        if len(data) - pos < 4:
            problem = "%d stray bytes after the last frame" % (len(data) - pos)
            break
        b1, b2, b3 = data[pos + 1], data[pos + 2], data[pos + 3]
        if data[pos] != 0xFF or (b1 & 0xE0) != 0xE0:
            problem = "lost frame sync at byte %d of %d" % (pos, len(data))
            break
        version = (b1 >> 3) & 3
        layer = (b1 >> 1) & 3
        bitrate_idx = (b2 >> 4) & 15
        rate_idx = (b2 >> 2) & 3
        padding = (b2 >> 1) & 1
        if version == 1 or layer != 1 or bitrate_idx in (0, 15) or rate_idx == 3:
            problem = "bad frame header at byte %d" % pos
            break
        table = _BITRATES["v1l3" if version == 3 else "v2l3"]
        rate = _RATES[version][rate_idx]
        bitrate = table[bitrate_idx - 1] * 1000
        per_frame = 1152 if version == 3 else 576
        size = (per_frame // 8) * bitrate // rate + padding
        if pos + size > len(data):
            problem = "last frame torn: %d of %d bytes" % (len(data) - pos, size)
            break
        frames += 1
        samples += per_frame
        rates.add(rate)
        kbps.add(bitrate // 1000)
        pos += size
    return {"frames": frames, "samples": samples, "rates": rates, "kbps": kbps, "problem": problem}


def spoken_words(text: str) -> int:
    return len(re.findall(r"[A-Za-z0-9]+(?:['\u2019][A-Za-z]+)?", text))


def expected_bounds(words: int) -> tuple:
    """(shortest, longest) plausible seconds for `words` spoken words."""
    shortest = max(MIN_CLIP_SEC, words / MAX_WORDS_PER_SEC)
    longest = 1.2 + words / MIN_WORDS_PER_SEC
    return shortest, longest


def text_problem(text: str) -> str:
    body = text.strip()
    if body == "":
        return "empty text"
    if body[-1] not in ".?!":
        return "text does not end a sentence: ...%r" % body[-30:]
    if body.count("(") != body.count(")"):
        return "unbalanced parenthesis"
    return ""


def _decoder():
    try:
        import av  # noqa: F401
        import numpy  # noqa: F401
    except ImportError:
        return None

    import av
    import numpy as np

    def decode(path: Path):
        with av.open(str(path)) as container:
            chunks = [frame.to_ndarray().astype(np.float32).reshape(-1)
                      for frame in container.decode(audio=0)]
            rate = container.streams.audio[0].rate
        pcm = np.concatenate(chunks) if chunks else np.zeros(0, np.float32)
        if pcm.size and np.abs(pcm).max() > 1.5:
            pcm = pcm / 32768.0
        return pcm, rate

    def dbfs(pcm) -> float:
        if pcm.size == 0:
            return -120.0
        rms = float(np.sqrt(np.mean(np.square(pcm, dtype=np.float64))))
        return 20.0 * np.log10(max(rms, 1e-6))

    return decode, dbfs


def quiet_edges_ms(pcm, rate: int, dbfs) -> tuple:
    """(ms before the first, ms after the last) 10 ms window louder than SPEECH_DBFS."""
    step = max(1, rate // 100)
    loud = [i for i in range(len(pcm) // step) if dbfs(pcm[i * step:(i + 1) * step]) > SPEECH_DBFS]
    if not loud:
        return 0, 0
    return loud[0] * 10, (len(pcm) // step - 1 - loud[-1]) * 10


def audit(root: Path, structure_only: bool = False) -> dict:
    decoder = None if structure_only else _decoder()
    report = {"folders": 0, "clips": 0, "problems": [], "decoded": decoder is not None, "rates": [],
              "tail_ms": []}
    for folder in sorted(p for p in root.iterdir() if p.is_dir()):
        manifest = folder / "manifest.json"
        if not manifest.exists():
            report["problems"].append({"clip": folder.name, "why": "no manifest.json"})
            continue
        rows = json.loads(manifest.read_text(encoding="utf-8"))
        report["folders"] += 1
        for row in rows:
            clip = folder / str(row.get("file", ""))
            name = "%s/%s" % (folder.name, clip.name)
            text = str(row.get("text", ""))

            def flag(why: str) -> None:
                report["problems"].append({"clip": name, "why": why, "text": text})

            report["clips"] += 1
            why = text_problem(text)
            if why:
                flag(why)
            if str(row.get("format", "")) != EXPECTED_FORMAT:
                flag("manifest format %r" % row.get("format"))
            if not clip.exists() or clip.stat().st_size == 0:
                flag("clip missing or empty")
                continue
            frames = parse_frames(clip.read_bytes())
            if frames["problem"]:
                flag(frames["problem"])
            if frames["rates"] != {EXPECTED_RATE} or frames["kbps"] != {EXPECTED_KBPS}:
                flag("stream is %s Hz / %s kbps" % (sorted(frames["rates"]), sorted(frames["kbps"])))
            seconds = frames["samples"] / EXPECTED_RATE
            words = spoken_words(text)
            shortest, longest = expected_bounds(words)
            report["rates"].append((words / seconds) if seconds > 0 else 0.0)
            if seconds < shortest:
                flag("%.2f s is too short for %d words (min %.2f s)" % (seconds, words, shortest))
            elif seconds > longest:
                flag("%.2f s is too long for %d words (max %.2f s)" % (seconds, words, longest))
            if decoder is None:
                continue
            decode, dbfs = decoder
            try:
                pcm, rate = decode(clip)
            except Exception as exc:  # a torn stream is exactly what this looks for
                flag("does not decode: %s" % exc)
                continue
            decoded_sec = pcm.size / rate if rate else 0.0
            if abs(decoded_sec - seconds) > 0.1:
                flag("decodes to %.2f s but the frames say %.2f s" % (decoded_sec, seconds))
            tail = dbfs(pcm[-int(rate * TAIL_MS / 1000):])
            head = dbfs(pcm[: int(rate * HEAD_MS / 1000)])
            if tail > EDGE_MAX_DBFS:
                flag("ends abruptly: last %d ms at %.1f dBFS" % (TAIL_MS, tail))
            if head > EDGE_MAX_DBFS:
                flag("starts clipped: first %d ms at %.1f dBFS" % (HEAD_MS, head))
            lead, trail = quiet_edges_ms(pcm, rate, dbfs)
            report["tail_ms"].append(trail)
            if trail < MIN_TAIL_SILENCE_MS:
                flag("only %d ms of silence after the last word (min %d)" % (trail, MIN_TAIL_SILENCE_MS))
            if lead < MIN_HEAD_SILENCE_MS:
                flag("only %d ms of silence before the first word (min %d)" % (lead, MIN_HEAD_SILENCE_MS))
    return report


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=str(ROOT / "assets" / "speech"))
    parser.add_argument("--json", default="")
    parser.add_argument("--structure-only", action="store_true")
    args = parser.parse_args()
    root = Path(args.root)
    if not root.is_dir():
        print("no bundle at %s (run pregenerate_speech.py --bundle)" % root)
        return 1
    report = audit(root, args.structure_only)
    rates = sorted(report.pop("rates"))
    if rates:
        print("words/s: min %.2f  median %.2f  max %.2f" % (rates[0], rates[len(rates) // 2], rates[-1]))
    tails = sorted(report.pop("tail_ms"))
    if tails:
        print("silence after the last word: min %d ms  median %d ms" % (tails[0], tails[len(tails) // 2]))
    print("folders: %d  clips: %d  decoded edges: %s" % (report["folders"], report["clips"],
                                                      "yes" if report["decoded"] else "no (install av + numpy)"))
    for p in report["problems"]:
        print("  %s: %s | %s" % (p["clip"], p["why"], p.get("text", "")[:90]))
    if args.json:
        Path(args.json).write_text(json.dumps(report, indent=1), encoding="utf-8")
    print("BUNDLE_AUDIT=%s (%d problems)" % ("OK" if not report["problems"] else "FAIL", len(report["problems"])))
    return 0 if not report["problems"] else 1


if __name__ == "__main__":
    sys.exit(main())
