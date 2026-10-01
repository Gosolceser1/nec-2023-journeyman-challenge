"""Measure the shipped sound effects in res://assets/sfx/.

    python tools/sfx/measure_sfx.py            # table
    python tools/sfx/measure_sfx.py --json     # machine-readable

Per file: length, channels, rate, sample peak, RMS over the audible part, max
momentary loudness (K-weighted 400 ms, the measure make_sfx.py matches), the
level of the first and last millisecond under the peak (a step there clicks),
DC offset and the share of energy above 6 kHz (harshness on phone speakers).
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import wave

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_sfx  # noqa: E402

ROOT = make_sfx.ROOT
SFX_DIR = os.path.join(ROOT, "assets", "sfx")


def read_wav(path: str) -> tuple[np.ndarray, int, int]:
    with wave.open(path, "rb") as w:
        ch, rate, width = w.getnchannels(), w.getframerate(), w.getsampwidth()
        raw = w.readframes(w.getnframes())
    if width != 2:
        raise ValueError(f"{path}: {width * 8}-bit, expected 16")
    x = np.frombuffer(raw, "<i2").astype(np.float64) / 32768.0
    return x.reshape(-1, ch), rate, ch


def db(v: float) -> float:
    return 20 * np.log10(max(v, 1e-9))


def lufs(x: np.ndarray, rate: int) -> float:
    """Max momentary loudness; channels summed by power (BS.1770)."""
    if rate != make_sfx.SR:
        idx = np.arange(0, len(x) - 1, rate / make_sfx.SR)
        x = np.stack([np.interp(idx, np.arange(len(x)), x[:, c]) for c in range(x.shape[1])], 1)
    powers = [10 ** ((make_sfx.momentary_lufs(x[:, c]) + 0.691) / 10) for c in range(x.shape[1])]
    return float(-0.691 + 10 * np.log10(max(sum(powers), 1e-12)))


def measure(path: str) -> dict:
    x, rate, ch = read_wav(path)
    mono = x.mean(axis=1)
    peak = float(np.max(np.abs(x)))
    audible = np.abs(mono) > peak * 10 ** (-40 / 20)
    span = mono[np.argmax(audible): len(mono) - np.argmax(audible[::-1])] if audible.any() else mono
    ms = max(1, rate // 1000)
    spec = np.abs(np.fft.rfft(mono)) ** 2
    freqs = np.fft.rfftfreq(len(mono), 1 / rate)
    return {
        "file": os.path.basename(path),
        "ms": round(len(x) / rate * 1000),
        "ch": ch,
        "rate": rate,
        "peak_db": round(db(peak), 1),
        "rms_db": round(db(float(np.sqrt(np.mean(span ** 2)))), 1),
        "lufs": round(lufs(x, rate), 1),
        "head_db": round(db(float(np.max(np.abs(x[:ms])))) - db(peak), 1),
        "tail_db": round(db(float(np.max(np.abs(x[-ms:])))) - db(peak), 1),
        "dc": round(float(np.mean(mono)), 5),
        "hf_pct": round(100 * float(spec[freqs > 6000].sum() / max(spec.sum(), 1e-12)), 1),
    }


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--dir", default=SFX_DIR)
    args = ap.parse_args()
    rows = [measure(os.path.join(args.dir, f)) for f in sorted(os.listdir(args.dir)) if f.endswith(".wav")]
    if args.json:
        print(json.dumps(rows, indent=1))
        return
    print(f"{'file':<15}{'ms':>6}{'ch':>4}{'rate':>7}{'peak':>7}{'rms':>7}{'LUFS':>7}{'head':>7}{'tail':>7}{'dc':>9}{'>6k%':>6}")
    for r in rows:
        print(f"{r['file']:<15}{r['ms']:>6}{r['ch']:>4}{r['rate']:>7}{r['peak_db']:>7}{r['rms_db']:>7}{r['lufs']:>7}"
              f"{r['head_db']:>7}{r['tail_db']:>7}{r['dc']:>9}{r['hf_pct']:>6}")


if __name__ == "__main__":
    main()
