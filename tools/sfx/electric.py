"""Electrical cue set for make_sfx.py (`--family electric`, the shipped set).

Electric-piano tones (C major) with light electrical layers: a pitched charge
"zip", air-band sparkle grains, soft shimmer, relay ticks, a damped breaker
thunk and phone-safe harmonic hums. No raw buzz, arcs or 50/60 Hz hum. Design,
research and measurements: the electrical SFX plan (candidates A, recommended).

numpy only: scipy's lfilter is used when installed, else the equivalent
direct-form loop below (identical within 16-bit rounding, just slower).
"""

from __future__ import annotations

import numpy as np

try:
    from scipy.signal import lfilter
except ImportError:
    def lfilter(b, a, x):
        b = np.asarray(b, dtype=float)
        a = np.asarray(a, dtype=float)
        b, a = b / a[0], a / a[0]
        v = np.convolve(np.asarray(x, dtype=float), b)[: len(x)].tolist()
        taps = [(int(k), float(a[k])) for k in np.nonzero(a[1:])[0] + 1]
        y = [0.0] * len(v)
        for n in range(len(v)):
            acc = v[n]
            for k, ak in taps:
                if n >= k:
                    acc -= ak * y[n - k]
            y[n] = acc
        return np.array(y)

SR = 44100

SPEC = {
    "correct": {"lufs": -20.0, "seconds": 0.30},
    "wrong": {"lufs": -20.0, "seconds": 0.30},
    "warning": {"lufs": -21.0, "seconds": 0.80},
    "pass": {"lufs": -20.0, "seconds": 1.45},
    "fail": {"lufs": -21.0, "seconds": 1.20},
}

PEAK_CEILING_DBFS = -1.0

## Harmonic weights for low tones: the fundamental stays (desktop weight) but most energy
## sits in harmonics 2-5, so phones (little below ~500 Hz) still hear the same pitch.
PHONE_SAFE = (0.45, 0.9, 0.75, 0.5, 0.32, 0.16)

N = {
    "F3": 174.61, "A3": 220.00, "C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23,
    "G4": 392.00, "A4": 440.00, "B4": 493.88, "C5": 523.25, "D5": 587.33, "E5": 659.25,
    "F5": 698.46, "G5": 783.99, "A5": 880.00, "C6": 1046.50, "E6": 1318.51, "G6": 1567.98,
    "C7": 2093.00, "E7": 2637.02, "G7": 3135.96,
}

def _rbj(kind: str, f0: float, q: float = 0.707, gain_db: float = 0.0):
    w = 2 * np.pi * f0 / SR
    c, s = np.cos(w), np.sin(w)
    alpha = s / (2 * q)
    A = 10 ** (gain_db / 40)
    if kind == "lp":
        b = [(1 - c) / 2, 1 - c, (1 - c) / 2]
        a = [1 + alpha, -2 * c, 1 - alpha]
    elif kind == "hp":
        b = [(1 + c) / 2, -(1 + c), (1 + c) / 2]
        a = [1 + alpha, -2 * c, 1 - alpha]
    elif kind == "bp":
        b = [alpha, 0.0, -alpha]
        a = [1 + alpha, -2 * c, 1 - alpha]
    elif kind == "peak":
        b = [1 + alpha * A, -2 * c, 1 - alpha * A]
        a = [1 + alpha / A, -2 * c, 1 - alpha / A]
    elif kind == "hshelf":
        sa = 2 * np.sqrt(A) * alpha
        b = [A * ((A + 1) + (A - 1) * c + sa), -2 * A * ((A - 1) + (A + 1) * c),
             A * ((A + 1) + (A - 1) * c - sa)]
        a = [(A + 1) - (A - 1) * c + sa, 2 * ((A - 1) - (A + 1) * c), (A + 1) - (A - 1) * c - sa]
    else:
        raise KeyError(kind)
    b, a = np.array(b), np.array(a)
    return b / a[0], a / a[0]

def filt(x, kind, f0, q=0.707, gain_db=0.0):
    b, a = _rbj(kind, f0, q, gain_db)
    return lfilter(b, a, x)

def lp(x, f, q=0.707):
    return filt(x, "lp", f, q)

def hp(x, f, q=0.707):
    return filt(x, "hp", f, q)

def env(n: int, attack: float, tau: float, release: float = 0.0) -> np.ndarray:
    t = np.arange(n) / SR
    e = np.exp(-np.maximum(t - attack, 0.0) / tau)
    a = max(1, int(SR * attack))
    e[:a] = 0.5 - 0.5 * np.cos(np.pi * np.arange(a) / a)
    if release > 0:
        r = min(n, int(SR * release))
        e[-r:] *= np.linspace(1.0, 0.0, r) ** 2
    return e

def bend_phase(freq: float, n: int, semis: float = 0.0, tau: float = 0.1) -> np.ndarray:
    """Phase of a tone that glides by `semis` semitones (negative = down) with time constant tau."""
    t = np.arange(n) / SR
    target = 2 ** (semis / 12.0)
    f = freq * (1.0 + (target - 1.0) * (1.0 - np.exp(-t / tau)))
    return 2 * np.pi * np.cumsum(f) / SR

def saturate(x, drive=1.3):
    return np.tanh(drive * x) / np.tanh(drive)

def room(x, wet=0.12, size=0.8):
    """Same damped 4-comb / 2-allpass room as make_sfx.py, via lfilter."""
    out = np.zeros_like(x)
    for d_s in (0.0297, 0.0371, 0.0411, 0.0437):
        d = int(SR * d_s * size)
        a = np.zeros(d + 1)
        a[0], a[1], a[d] = 1.0, -0.4, -0.432
        out += lfilter([1.0, -0.4], a, x)
    out /= 4
    for d_s, g in ((0.005, 0.7), (0.0017, 0.7)):
        d = int(SR * d_s)
        b = np.zeros(d + 1)
        a = np.zeros(d + 1)
        b[0], b[d] = -g, 1.0
        a[0], a[d] = 1.0, -g
        out = lfilter(b, a, out)
    return x + wet * hp(out, 250)

def place(total: float, parts) -> np.ndarray:
    out = np.zeros(int(round(SR * total)))
    for start, sig in parts:
        s = int(round(SR * start))
        e = min(len(out), s + len(sig))
        if e > s:
            out[s:e] += sig[: e - s]
    return out

def finish(x, fade):
    x = x - np.mean(x)
    a = int(SR * 0.002)
    x[:a] *= np.linspace(0.0, 1.0, a)
    n = min(len(x), int(SR * fade))
    x[-n:] *= np.linspace(1.0, 0.0, n) ** 2
    x[0] = 0.0
    x[-1] = 0.0
    return x

def tine(freq, secs, vel=1.0, bright=1.0, decay=1.0, semis=0.0, bend_tau=0.1, lp_hz=6000, muted=False):
    """Electric-piano FM tine (the app's current 'keys' family, a little brighter)."""
    n = int(SR * secs)
    t = np.arange(n) / SR
    ph = bend_phase(freq, n, semis, bend_tau)
    if muted:
        bright *= 0.45
    index = (0.25 + 1.4 * bright * vel) * np.exp(-t / 0.08) + 0.10
    body = np.sin(ph + index * np.sin(ph))
    bell = 0.14 * bright * np.sin(7.0 * ph) * np.exp(-t / 0.010)
    fund = 0.35 * np.sin(ph)
    tau = float(np.clip(0.55 * (440.0 / freq) ** 0.5, 0.15, 0.9)) * decay * (0.6 if muted else 1.0)
    sig = (body + bell + fund) * env(n, 0.003, tau, 0.02)
    sig = saturate(0.8 * sig, 1.2)
    return lp(sig, 1800 if muted else lp_hz) * vel

def charge_zip(f0, f1, secs, level=0.3, tau_frac=0.35):
    """Capacitor 'charge-up': pitch rises along 1-exp(-t/RC) and lands on f1 (a chord tone)."""
    n = int(SR * secs)
    t = np.arange(n) / SR
    rc = secs * tau_frac
    curve = (1 - np.exp(-t / rc)) / (1 - np.exp(-secs / rc))
    f = f0 * (f1 / f0) ** curve
    ph = 2 * np.pi * np.cumsum(f) / SR
    sig = np.sin(ph) + 0.25 * np.sin(2 * ph) + 0.08 * np.sin(3 * ph)
    e = 0.4 + 0.6 * (t / secs) ** 0.8
    a = int(SR * 0.003)
    e[:a] *= 0.5 - 0.5 * np.cos(np.pi * np.arange(a) / a)
    r = int(SR * 0.008)
    e[-r:] *= np.linspace(1, 0, r)
    return lp(sig * e, 5000) * level

def sparkle(secs, grains=6, seed=1, level=0.05, f_lo=6000, f_hi=9000, tau=0.08):
    """Sparse, air-band noise grains: a whisper of 'spark', kept above the 2-5 kHz harsh zone."""
    rng = np.random.default_rng(seed)
    n = int(SR * secs)
    out = np.zeros(n)
    times = np.sort(rng.uniform(0, 1, grains) ** 1.6) * secs * 0.85
    for t0 in times:
        g = int(SR * rng.uniform(0.0015, 0.0035))
        burst = rng.standard_normal(g) * np.hanning(g)
        burst = filt(np.concatenate([burst, np.zeros(200)]), "bp", rng.uniform(f_lo, f_hi), 3.0)
        s = int(SR * t0)
        e = min(n, s + len(burst))
        out[s:e] += burst[: e - s] * np.exp(-t0 / tau) * rng.uniform(0.5, 1.0)
    return lp(out, 11000) * level * 6.0

def shimmer(freqs, secs, level=0.04, seed=2, attack=0.03, tau=0.25, trem=(17.0, 23.0)):
    """'Tesla shimmer': high chord partials with fast, slightly irregular tremolo (not 50/60 Hz hum)."""
    rng = np.random.default_rng(seed)
    n = int(SR * secs)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for f in freqs:
        rate = rng.uniform(*trem)
        jitter = np.cumsum(rng.standard_normal(n)) / np.sqrt(SR) * 3.0
        am = 0.5 + 0.5 * np.sin(2 * np.pi * rate * t + jitter + rng.uniform(0, 6.28))
        out += np.sin(2 * np.pi * f * t + rng.uniform(0, 6.28)) * am ** 2
    out *= env(n, attack, tau, 0.02)
    return lp(out / len(freqs), 7000) * level

def relay(level=0.25, seed=3, bright=1.0):
    """Soft relay pull-in: armature knock + one contact bounce, rounded attack, no crack."""
    rng = np.random.default_rng(seed)
    n = int(SR * 0.035)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for t0, amp in ((0.0, 1.0), (0.0068, 0.45)):
        s = int(SR * t0)
        tt = t[: n - s]
        click = rng.standard_normal(n - s) * np.exp(-tt / 0.0011)
        click = filt(click, "bp", 1500, 1.1) * 0.9
        body = np.sin(2 * np.pi * 820 * tt) * np.exp(-tt / 0.006)
        tick = 0.35 * bright * np.sin(2 * np.pi * 2250 * tt) * np.exp(-tt / 0.0022)
        out[s:] += amp * (click + body + tick)
    a = int(SR * 0.0005)
    out[:a] *= 0.5 - 0.5 * np.cos(np.pi * np.arange(a) / a)
    return lp(out, 4500) * level

def thunk(level=0.5, seed=4, low=1.0):
    """Soft breaker 'thunk': damped low + mid modes (mids carry it on phones) and a dull click."""
    rng = np.random.default_rng(seed)
    n = int(SR * 0.14)
    t = np.arange(n) / SR
    lowm = low * np.sin(bend_phase(165.0, n, -1.5, 0.03)) * np.exp(-t / 0.045)
    mid = 0.6 * np.sin(2 * np.pi * 490 * t) * np.exp(-t / 0.028)
    upper = 0.32 * np.sin(2 * np.pi * 1010 * t) * np.exp(-t / 0.012)
    knock = lp(rng.standard_normal(n) * np.exp(-t / 0.003), 1600) * 0.35
    out = (lowm + mid + upper + knock) * env(n, 0.0015, 10.0, 0.01)
    return lp(out, 2500) * level

def hum(freq, secs, amps=(1.0, 0.55, 0.38, 0.22, 0.14, 0.08), semis=0.0, bend_tau=0.1, attack=0.006,
        tau=0.15, am_rate=0.0, am_depth=0.0, lp_hz=2200, level=1.0):
    """Musical 'transformer' tone: a harmonic stack on a scale note (never 50/60 Hz), optional sag/flicker."""
    n = int(SR * secs)
    t = np.arange(n) / SR
    ph = bend_phase(freq, n, semis, bend_tau)
    sig = sum(a * np.sin((k + 1) * ph) for k, a in enumerate(amps) if (k + 1) * freq < 12000)
    if am_rate > 0:
        sig = sig * (1 - am_depth * (0.5 - 0.5 * np.cos(2 * np.pi * am_rate * t)))
    sig = sig * env(n, attack, tau, 0.02)
    return lp(saturate(0.6 * sig / sum(amps) * 2, 1.2), lp_hz) * level

def sweep(f0, f1, secs, b0, b1, level=0.3, attack=0.02, release=0.05, glide_curve=1.0):
    """Power-up / power-down whirr: band-limited saw whose pitch and brightness glide together."""
    n = int(SR * secs)
    t = np.arange(n) / SR
    u = (t / secs) ** glide_curve
    f = f0 * (f1 / f0) ** u
    ph = 2 * np.pi * np.cumsum(f) / SR
    bright = b0 + (b1 - b0) * u
    out = np.zeros(n)
    for k in range(1, 25):
        amp = (1.0 / k) * np.exp(-(k - 1) / np.maximum(bright, 0.3))
        amp = np.where(k * f < 14000, amp, 0.0)
        out += amp * np.sin(k * ph)
    e = np.ones(n)
    a = int(SR * attack)
    e[:a] = 0.5 - 0.5 * np.cos(np.pi * np.arange(a) / a)
    r = int(SR * release)
    e[-r:] *= np.linspace(1, 0, r) ** 1.5
    return out * e * level

def correct_A():
    # Spark chime: a 35 ms charge 'zip' lands on G5, C6 answers (current rising fourth), air-band sparkle.
    T = SPEC["correct"]["seconds"]
    parts = [
        (0.000, charge_zip(N["G4"], N["G5"], 0.035, 0.30)),
        (0.028, tine(N["G5"], 0.27, 0.70, decay=0.35)),
        (0.095, tine(N["C6"], 0.205, 1.0, decay=0.42)),
        (0.100, sparkle(0.19, 6, seed=11, level=0.035)),
        (0.100, shimmer([N["C7"], N["G7"]], 0.20, 0.018, seed=12, attack=0.01, tau=0.07)),
    ]
    return finish(room(place(T, parts), 0.09, 0.7), 0.06)

def wrong_A():
    # Breaker thunk + hum dip: soft thunk, A3 'transformer' tone with octave support sags 1 semitone.
    T = SPEC["wrong"]["seconds"]
    parts = [
        (0.000, thunk(0.50, low=0.45)),
        (0.004, hum(N["A3"], 0.296, amps=PHONE_SAFE, semis=-1.2, bend_tau=0.09, tau=0.11, level=0.9)),
        (0.004, hum(N["A4"], 0.296, amps=(1.0, 0.45, 0.25), semis=-1.2, bend_tau=0.09, tau=0.08, level=0.8)),
    ]
    return finish(room(place(T, parts), 0.07, 0.7), 0.07)

def warning_A():
    # Relay doorbell: tick + G5, tick + E5 (keeps the current doorbell pattern), light 14 Hz shimmer.
    T = SPEC["warning"]["seconds"]
    parts = [
        (0.000, relay(0.22, seed=41)),
        (0.008, tine(N["G5"], 0.60, 0.9)),
        (0.008, shimmer([N["G6"]], 0.5, 0.03, seed=42, tau=0.2, trem=(13, 15))),
        (0.200, relay(0.18, seed=43)),
        (0.208, tine(N["E5"], 0.59, 0.85)),
        (0.208, shimmer([N["E6"]], 0.5, 0.03, seed=44, tau=0.25, trem=(13, 15))),
    ]
    return finish(room(place(T, parts), 0.13), 0.15)

def pass_A():
    # Power-up into chord: a 0.28 s whirr C4 -> C5 opens up, arpeggio C5 E5 G5 C6 rings, shimmer + sparkle.
    T = SPEC["pass"]["seconds"]
    parts = [
        (0.000, sweep(N["C4"], N["C5"], 0.30, 1.5, 6.0, 0.18, attack=0.006, release=0.08, glide_curve=0.7)),
        (0.240, tine(N["C5"], 1.21, 0.70)),
        (0.330, tine(N["E5"], 1.12, 0.75)),
        (0.420, tine(N["G5"], 1.03, 0.80)),
        (0.530, tine(N["C6"], 0.92, 0.90)),
        (0.530, tine(N["C4"], 0.92, 0.35)),
        (0.540, shimmer([N["C7"], N["E7"], N["G7"]], 0.9, 0.045, seed=61, attack=0.05, tau=0.35)),
        (0.540, sparkle(0.6, 9, seed=62, level=0.03, tau=0.25)),
    ]
    return finish(room(place(T, parts), 0.18), 0.3)

def fail_A():
    # Gentle power-down: A4 tine, a quiet whirr glides down and darkens, lands on a warm F4/C5 that dims.
    T = SPEC["fail"]["seconds"]
    parts = [
        (0.000, tine(N["A4"], 0.9, 0.75, muted=True, lp_hz=3000)),
        (0.000, tine(N["A5"], 0.5, 0.45, muted=True)),
        (0.040, sweep(N["A4"], N["F4"], 0.42, 5.0, 1.2, 0.07, attack=0.06, release=0.2, glide_curve=0.8)),
        (0.240, tine(N["F4"], 0.96, 0.70, muted=True, semis=-0.25, bend_tau=0.5, lp_hz=3000)),
        (0.240, tine(N["F5"], 0.8, 0.55, muted=True, semis=-0.25, bend_tau=0.5)),
        (0.240, tine(N["C5"], 0.96, 0.50, muted=True, semis=-0.25, bend_tau=0.5)),
    ]
    return finish(room(place(T, parts), 0.16), 0.3)

def momentary_lufs(x):
    k = filt(x, "hshelf", 1681.97, 0.7071, 4.0)
    k = filt(k, "hp", 38.135, 0.5003)
    win = int(SR * 0.4)
    if len(k) < win:
        k = np.concatenate([k, np.zeros(win - len(k))])
    c = np.concatenate([[0.0], np.cumsum(k * k)])
    p = (c[win:] - c[:-win]) / win
    return float(-0.691 + 10 * np.log10(max(float(p.max()), 1e-12)))

def db(v):
    return float(20 * np.log10(max(float(v), 1e-12)))

def render(event, x):
    x = x * 10 ** ((SPEC[event]["lufs"] - momentary_lufs(x)) / 20.0)
    pk = db(np.max(np.abs(x)))
    if pk > PEAK_CEILING_DBFS:
        x = x * 10 ** ((PEAK_CEILING_DBFS - pk) / 20.0)
    return x


CUES = {"correct": correct_A, "wrong": wrong_A, "warning": warning_A, "pass": pass_A, "fail": fail_A}


def render_cue(name: str) -> np.ndarray:
    """One cue, loudness-matched and under the peak ceiling (float, -1..1)."""
    return render(name, CUES[name]())
