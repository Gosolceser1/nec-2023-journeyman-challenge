"""Re-level the shipped sound effects in res://assets/sfx/ in place.

    python tools/sfx/polish_sfx.py            # dry run: before -> after table
    python tools/sfx/polish_sfx.py --write    # overwrite the WAVs
    python tools/sfx/polish_sfx.py --write --eq   # once: also tame start.wav's top

Per file: DC removed, a short raised-cosine fade-in (a sound that starts on
its transient no longer clicks), a squared fade over the last few
milliseconds, then one gain change to the role's max momentary loudness
(TARGET_LUFS) under a -1 dBFS sample-peak ceiling. Event cues sit about 6 LU
over the interface sounds, which are heard far more often; hover, the most
frequent, is quietest. Re-running keeps the levels (it only deepens the
first 3 ms a little more), so it is safe to repeat; --eq is not, run it once.

Length, channels and sample rate are kept, so the budgets in test_sfx.gd and
the start cue's tail timing still hold.
"""

from __future__ import annotations

import argparse
import os
import sys
import wave

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_sfx  # noqa: E402
import measure_sfx  # noqa: E402

## Max momentary loudness per cue (LUFS, K-weighted 400 ms). Mirrored in
## tools/tests/test_motion_polish.gd, which checks the shipped files against it.
TARGET_LUFS = {
    "start": -18.5, "correct": -17.0, "wrong": -17.0, "warning": -17.0, "pass": -16.0, "fail": -17.0,
    "click": -24.0, "toggle": -24.0, "select": -24.0, "transition": -24.0, "hover": -27.0,
}
PEAK_CEILING_DB = -1.0
FADE_IN_S = 0.003
FADE_OUT_S = 0.012
## start.wav is a sparkle centred near 8 kHz; a high shelf takes the edge off on
## phone and laptop speakers without dulling it.
EQ = {"start": (8000.0, -4.0)}


def fade(x: np.ndarray, rate: int) -> np.ndarray:
    n_in = max(1, int(rate * FADE_IN_S))
    n_out = max(1, int(rate * FADE_OUT_S))
    ramp_in = 0.5 - 0.5 * np.cos(np.pi * np.arange(n_in) / n_in)
    x[:n_in] *= ramp_in[:, None]
    x[-n_out:] *= (np.linspace(1.0, 0.0, n_out) ** 2)[:, None]
    return x


def shelf(x: np.ndarray, rate: int, f0: float, gain_db: float) -> np.ndarray:
    if rate != make_sfx.SR:
        saved, make_sfx.SR = make_sfx.SR, rate
    else:
        saved = None
    out = np.stack([make_sfx.high_shelf(x[:, c], f0, gain_db, 0.7071) for c in range(x.shape[1])], 1)
    if saved is not None:
        make_sfx.SR = saved
    return out


def write(path: str, x: np.ndarray, rate: int) -> None:
    pcm = np.round(np.clip(x, -1.0, 32767 / 32768) * 32768.0).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(x.shape[1])
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(pcm.tobytes())


def polish(name: str, x: np.ndarray, rate: int, eq: bool) -> np.ndarray:
    x = x - x.mean(axis=0)
    if eq and name in EQ:
        x = shelf(x, rate, *EQ[name])
    x = fade(x, rate)
    gain = TARGET_LUFS[name] - measure_sfx.lufs(x, rate)
    x = x * 10 ** (gain / 20)
    peak = measure_sfx.db(float(np.max(np.abs(x))))
    if peak > PEAK_CEILING_DB:
        x *= 10 ** ((PEAK_CEILING_DB - peak) / 20)
    return x


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--write", action="store_true", help="overwrite assets/sfx/*.wav")
    ap.add_argument("--eq", action="store_true", help="apply the one-time EQ (start.wav); run once")
    args = ap.parse_args()
    print(f"{'file':<12}{'LUFS':>14}{'peak dBFS':>16}{'head dB':>16}")
    for name in TARGET_LUFS:
        path = os.path.join(measure_sfx.SFX_DIR, name + ".wav")
        before = measure_sfx.measure(path)
        x, rate, _ = measure_sfx.read_wav(path)
        y = polish(name, x, rate, args.eq)
        if args.write:
            write(path, y, rate)
            after = measure_sfx.measure(path)
        else:
            tmp = os.path.join(os.environ.get("TEMP", "/tmp"), "polish_sfx_" + name + ".wav")
            write(tmp, y, rate)
            after = measure_sfx.measure(tmp)
            os.remove(tmp)
        print(f"{name:<12}{before['lufs']:>6} -> {after['lufs']:<6}{before['peak_db']:>7} -> {after['peak_db']:<6}"
              f"{before['head_db']:>7} -> {after['head_db']:<6}")
    if not args.write:
        print("dry run; --write overwrites assets/sfx/")


if __name__ == "__main__":
    main()
