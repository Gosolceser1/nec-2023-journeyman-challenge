"""Synthesize the app's sound effects into res://assets/sfx/ (see docs/SFX_PLAN.md).

    python tools/sfx/make_sfx.py                   # default family -> sfx/*.wav
    python tools/sfx/make_sfx.py --family mallet   # ship another family instead
    python tools/sfx/make_sfx.py --preview         # also every family -> .audit_tmp/sfx_preview/v2/

Five cues only: correct, wrong, pass, fail, warning. Each family plays the same
notes (C major) with a different instrument, so picking one is purely a timbre
choice:

    keys    warm electric piano (FM tine + body, soft saturation)   [default]
    mallet  soft marimba bar (inharmonic bar partials, felt mallet)
    pluck   kalimba-like pluck (Karplus-Strong string + sine body)

All original synthesis (CC0, see sfx/CREDITS.md), deterministic, 44.1 kHz mono
16-bit, loudness-matched with a K-weighted momentary (400 ms) measure.
"""

from __future__ import annotations

import argparse
import os
import wave

import numpy as np

SR = 44100
FAMILIES = ("keys", "mallet", "pluck")
DEFAULT_FAMILY = "keys"
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT_DIR = os.path.join(ROOT, "assets", "sfx")
PREVIEW_DIR = os.path.join(ROOT, ".audit_tmp", "sfx_preview", "v2")

## Target max momentary loudness (LUFS, K-weighted) and total length per cue.
SPEC = {
    "correct": {"lufs": -20.0, "seconds": 0.30},
    "wrong": {"lufs": -20.0, "seconds": 0.30},
    "warning": {"lufs": -21.0, "seconds": 0.80},
    "pass": {"lufs": -20.0, "seconds": 1.45},
    "fail": {"lufs": -21.0, "seconds": 1.20},
}
PEAK_CEILING_DBFS = -1.0

NOTE = {
    "A3": 220.00, "C4": 261.63, "E4": 329.63, "F4": 349.23, "G4": 392.00, "A4": 440.00,
    "C5": 523.25, "E5": 659.25, "G5": 783.99, "C6": 1046.50,
}


# --------------------------------------------------------------------------
# DSP helpers
# --------------------------------------------------------------------------

def t_axis(seconds: float) -> np.ndarray:
    return np.arange(int(round(SR * seconds))) / SR


def biquad(x: np.ndarray, b: tuple, a: tuple) -> np.ndarray:
    b0, b1, b2 = (float(v) for v in b)
    a1, a2 = float(a[1]), float(a[2])
    out = []
    append = out.append
    x1 = x2 = y1 = y2 = 0.0
    for xi in x.tolist():  # plain floats: far faster than numpy scalar indexing
        yi = b0 * xi + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1, y2, y1 = x1, xi, y1, yi
        append(yi)
    return np.array(out)


def lowpass(x: np.ndarray, cutoff: float, q: float = 0.707) -> np.ndarray:
    w = 2 * np.pi * cutoff / SR
    alpha = np.sin(w) / (2 * q)
    c = np.cos(w)
    a0 = 1 + alpha
    b = ((1 - c) / 2 / a0, (1 - c) / a0, (1 - c) / 2 / a0)
    a = (1.0, -2 * c / a0, (1 - alpha) / a0)
    return biquad(x, b, a)


def highpass(x: np.ndarray, cutoff: float, q: float = 0.707) -> np.ndarray:
    w = 2 * np.pi * cutoff / SR
    alpha = np.sin(w) / (2 * q)
    c = np.cos(w)
    a0 = 1 + alpha
    b = ((1 + c) / 2 / a0, -(1 + c) / a0, (1 + c) / 2 / a0)
    a = (1.0, -2 * c / a0, (1 - alpha) / a0)
    return biquad(x, b, a)


def high_shelf(x: np.ndarray, f0: float, gain_db: float, q: float) -> np.ndarray:
    A = 10 ** (gain_db / 40)
    w = 2 * np.pi * f0 / SR
    alpha = np.sin(w) / (2 * q)
    c = np.cos(w)
    sa = 2 * np.sqrt(A) * alpha
    a0 = (A + 1) - (A - 1) * c + sa
    b = (A * ((A + 1) + (A - 1) * c + sa) / a0,
         -2 * A * ((A - 1) + (A + 1) * c) / a0,
         A * ((A + 1) + (A - 1) * c - sa) / a0)
    a = (1.0, 2 * ((A - 1) - (A + 1) * c) / a0, ((A + 1) - (A - 1) * c - sa) / a0)
    return biquad(x, b, a)


def momentary_lufs(x: np.ndarray) -> float:
    """Max 400 ms K-weighted loudness (ITU-R BS.1770 filters, mono)."""
    k = high_shelf(x, 1681.97, 4.0, 0.7071)
    k = highpass(k, 38.135, 0.5003)
    win = int(SR * 0.4)
    if len(k) < win:
        k = np.concatenate([k, np.zeros(win - len(k))])
    csum = np.concatenate([[0.0], np.cumsum(k * k)])
    power = (csum[win:] - csum[:-win]) / win
    return float(-0.691 + 10 * np.log10(max(float(power.max()), 1e-12)))


def envelope(n: int, attack: float, tau: float, release: float = 0.0) -> np.ndarray:
    t = np.arange(n) / SR
    env = np.exp(-np.maximum(t - attack, 0.0) / tau)
    a = max(1, int(SR * attack))
    env[:a] = 0.5 - 0.5 * np.cos(np.pi * np.arange(a) / a)  # smooth (raised-cosine) attack
    if release > 0:
        r = min(n, int(SR * release))
        env[-r:] *= np.linspace(1.0, 0.0, r) ** 2
    return env


def glide_phase(freq: float, n: int, bend: float = 0.0, bend_tau: float = 0.1) -> np.ndarray:
    t = np.arange(n) / SR
    f = freq * (1.0 - bend * (1.0 - np.exp(-t / bend_tau)))
    return 2 * np.pi * np.cumsum(f) / SR


def saturate(x: np.ndarray, drive: float = 1.5) -> np.ndarray:
    return np.tanh(drive * x) / np.tanh(drive)


def room(x: np.ndarray, wet: float = 0.14, size: float = 1.0) -> np.ndarray:
    """Small damped room: 4 parallel lowpass-feedback combs into 2 allpasses."""
    combs = (0.0297, 0.0371, 0.0411, 0.0437)
    xs = x.tolist()
    n = len(xs)
    out = np.zeros(n)
    for d_s in combs:
        d = int(SR * d_s * size)
        buf = [0.0] * n
        lp = 0.0
        for i in range(n):
            fb = buf[i - d] if i >= d else 0.0
            lp = 0.6 * fb + 0.4 * lp  # high-frequency damping in the loop
            buf[i] = xs[i] + 0.72 * lp
        out += np.array(buf)
    out /= len(combs)
    for d_s, g in ((0.005, 0.7), (0.0017, 0.7)):
        d = int(SR * d_s)
        src = out.tolist()
        y = [0.0] * n
        for i in range(n):
            xd = src[i - d] if i >= d else 0.0
            yd = y[i - d] if i >= d else 0.0
            y[i] = -g * src[i] + xd + g * yd
        out = np.array(y)
    return x + wet * highpass(out, 250)


def place(total: float, parts: list[tuple[float, np.ndarray]]) -> np.ndarray:
    out = np.zeros(int(round(SR * total)))
    for start, sig in parts:
        s = int(SR * start)
        e = min(len(out), s + len(sig))
        if e > s:
            out[s:e] += sig[: e - s]
    return out


def finish(x: np.ndarray, fade: float) -> np.ndarray:
    x = x - np.mean(x)
    a = int(SR * 0.002)
    x[:a] *= np.linspace(0.0, 1.0, a)  # removing DC can leave a step at sample 0
    n = min(len(x), int(SR * fade))
    x[-n:] *= (np.linspace(1.0, 0.0, n)) ** 2
    return x


# --------------------------------------------------------------------------
# Instruments: note(freq, seconds, vel, muted, bend) -> signal
# --------------------------------------------------------------------------

def keys_note(freq: float, seconds: float, vel: float = 1.0, muted: bool = False, bend: float = 0.0,
              decay: float = 1.0) -> np.ndarray:
    n = int(SR * seconds)
    t = np.arange(n) / SR
    ph = glide_phase(freq, n, bend)
    bright = 0.45 if muted else 1.0
    index = (0.25 + 1.6 * bright * vel) * np.exp(-t / 0.09) + 0.12
    body = np.sin(ph + index * np.sin(ph))
    tine = 0.18 * bright * np.sin(7.0 * ph) * np.exp(-t / 0.012)
    fund = 0.35 * np.sin(ph)
    tau = float(np.clip(0.55 * (440.0 / freq) ** 0.5, 0.18, 0.9)) * (0.6 if muted else 1.0) * decay
    sig = (body + tine + fund) * envelope(n, 0.004, tau, 0.02)
    sig = saturate(0.8 * sig, 1.4)
    return lowpass(lowpass(sig, 1500 if muted else 4200), 1500 if muted else 4200) * vel


def mallet_note(freq: float, seconds: float, vel: float = 1.0, muted: bool = False, bend: float = 0.0,
              decay: float = 1.0) -> np.ndarray:
    n = int(SR * seconds)
    ph = glide_phase(freq, n, bend)
    tau = float(np.clip(0.42 * (440.0 / freq) ** 0.6, 0.12, 0.9)) * (0.55 if muted else 1.0) * decay
    sig = np.sin(ph) * envelope(n, 0.003, tau)
    sig += 0.32 * (0.5 if muted else 1.0) * np.sin(3.93 * ph) * envelope(n, 0.002, tau / 4.0)
    sig += 0.10 * (0.3 if muted else 1.0) * np.sin(9.2 * ph) * envelope(n, 0.001, tau / 10.0)
    thump = np.random.default_rng(int(freq)).standard_normal(n) * envelope(n, 0.0005, 0.004) * 0.12
    sig += lowpass(thump, 1200)
    sig = saturate(0.9 * sig, 1.2) * envelope(n, 0.0, 10.0, 0.02)
    return lowpass(sig, 1400 if muted else 5000) * vel


def pluck_note(freq: float, seconds: float, vel: float = 1.0, muted: bool = False, bend: float = 0.0,
              decay: float = 1.0) -> np.ndarray:
    n = int(SR * seconds)
    period = SR / freq
    rng = np.random.default_rng(int(freq * 10))
    excite_len = int(period) + 2
    excite = lowpass(rng.uniform(-1, 1, excite_len), 2500 if muted else 5000)
    ys = [0.0] * n
    ys[:excite_len] = excite[: min(excite_len, n)].tolist()
    loss = (0.985 if muted else 0.996) ** (1.0 / decay)
    for i in range(excite_len, n):
        p = i - period
        j = int(p)
        frac = p - j
        d0 = ys[j] * (1 - frac) + ys[j + 1] * frac
        d1 = ys[j - 1] * (1 - frac) + ys[j] * frac
        ys[i] = loss * 0.5 * (d0 + d1)
    y = np.array(ys)
    y /= max(1e-9, float(np.max(np.abs(y))))
    body = 0.45 * np.sin(glide_phase(freq, n, bend)) * envelope(n, 0.003, (0.25 if muted else 0.4) * decay)
    sig = (y + body) * envelope(n, 0.002, 10.0, 0.02)
    return lowpass(saturate(0.8 * sig, 1.2), 1600 if muted else 4500) * vel


INSTRUMENTS = {"keys": keys_note, "mallet": mallet_note, "pluck": pluck_note}


# --------------------------------------------------------------------------
# Cues (same notes for every family)
# --------------------------------------------------------------------------

def cue(name: str, note) -> np.ndarray:
    total = SPEC[name]["seconds"]
    if name == "correct":
        # Rising fourth G5 -> C6: resolved, positive, over in a blink.
        parts = [(0.0, note(NOTE["G5"], 0.30, 0.75, decay=0.35)), (0.07, note(NOTE["C6"], 0.23, 1.0, decay=0.4))]
        return finish(room(place(total, parts), 0.10, 0.7), 0.06)
    if name == "wrong":
        # One low muted note that sags a little: "not quite", no buzzer.
        parts = [(0.0, note(NOTE["A3"], 0.30, 1.0, True, 0.035, decay=0.4))]
        return finish(room(place(total, parts), 0.08, 0.7), 0.07)
    if name == "warning":
        # Doorbell-style G5 -> E5: "notice", not alarm.
        parts = [(0.0, note(NOTE["G5"], 0.6, 0.9)), (0.2, note(NOTE["E5"], 0.6, 0.85))]
        return finish(room(place(total, parts), 0.14), 0.15)
    if name == "pass":
        # C5 E5 G5 then C6, each left ringing into a chord.
        parts = [(0.0, note(NOTE["C5"], 1.45, 0.7)), (0.11, note(NOTE["E5"], 1.34, 0.75)),
                 (0.22, note(NOTE["G5"], 1.23, 0.8)), (0.36, note(NOTE["C6"], 1.09, 0.9)),
                 (0.36, note(NOTE["C4"], 1.09, 0.35))]
        return finish(room(place(total, parts), 0.18), 0.3)
    if name == "fail":
        # A4 -> F4: a soft settling fall (major third), not a sad trombone.
        parts = [(0.0, note(NOTE["A4"], 0.9, 0.8, True)), (0.22, note(NOTE["F4"], 0.98, 0.75, True))]
        return finish(room(place(total, parts), 0.16), 0.3)
    raise KeyError(name)


def render(name: str, family: str) -> np.ndarray:
    x = cue(name, INSTRUMENTS[family])
    x = x * 10 ** ((SPEC[name]["lufs"] - momentary_lufs(x)) / 20.0)
    peak_db = 20 * np.log10(max(1e-9, float(np.max(np.abs(x)))))
    if peak_db > PEAK_CEILING_DBFS:
        x *= 10 ** ((PEAK_CEILING_DBFS - peak_db) / 20.0)
    return x


def write_wav(path: str, x: np.ndarray) -> None:
    pcm = (np.clip(x, -1.0, 1.0) * 32767.0).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--family", choices=FAMILIES, default=DEFAULT_FAMILY, help="instrument written to sfx/")
    ap.add_argument("--preview", action="store_true", help="render every family to .audit_tmp/sfx_preview/v2/")
    args = ap.parse_args()
    families = FAMILIES if args.preview else (args.family,)
    os.makedirs(OUT_DIR, exist_ok=True)
    gap = np.zeros(int(SR * 0.7))
    compare: list[np.ndarray] = []
    for family in families:
        tour: list[np.ndarray] = []
        for name in SPEC:
            x = render(name, family)
            loud = momentary_lufs(x)
            peak = 20 * np.log10(max(1e-9, float(np.max(np.abs(x)))))
            print(f"  {family:<7} {name:<8} {len(x) / SR * 1000:5.0f} ms  {loud:6.1f} LUFS  peak {peak:5.1f} dBFS")
            if family == args.family:
                write_wav(os.path.join(OUT_DIR, f"{name}.wav"), x)
            if args.preview:
                os.makedirs(os.path.join(PREVIEW_DIR, family), exist_ok=True)
                write_wav(os.path.join(PREVIEW_DIR, family, f"{name}.wav"), x)
                tour += [x, gap]
            if name in ("correct", "wrong"):
                compare += [x, gap[: len(gap) // 2]]
        if args.preview:
            write_wav(os.path.join(PREVIEW_DIR, f"{family}_all_cues.wav"), np.concatenate(tour))
            compare.append(gap)
    if args.preview:
        # correct, wrong, correct, wrong ... per family, in FAMILIES order.
        write_wav(os.path.join(PREVIEW_DIR, "compare_correct_wrong.wav"), np.concatenate(compare))
        print(f"  preview -> {PREVIEW_DIR}")
    print(f"  shipped family '{args.family}' -> {OUT_DIR}")


if __name__ == "__main__":
    main()
