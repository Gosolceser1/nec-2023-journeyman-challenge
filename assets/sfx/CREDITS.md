# Sound effects — source and license

All files in this folder are **original, procedurally synthesized** audio made
for this project by `tools/sfx/make_sfx.py` (FM electric-piano voice, small damped
room reverb, soft saturation; 44.1 kHz mono 16-bit WAV, loudness-matched to
about -20 LUFS momentary). No third-party samples or recordings are used.

License: **CC0 1.0 Universal** (public domain dedication) —
https://creativecommons.org/publicdomain/zero/1.0/

Regenerate (deterministic, overwrites these files):

    python tools/sfx/make_sfx.py                   # shipped family: keys
    python tools/sfx/make_sfx.py --family mallet   # or: pluck
    python tools/sfx/make_sfx.py --preview         # all families -> .audit_tmp/sfx_preview/v2/

| File | Plays when | Length |
|---|---|---|
| correct.wav | right answer | 0.30 s |
| wrong.wav | wrong answer / item timed out | 0.30 s |
| warning.wav | exam clock reaches 5:00 and 1:00 left | 0.80 s |
| pass.wav | results: passed | 1.45 s |
| fail.wav | results: did not pass | 1.20 s |

Why only these: see `docs/SFX_PLAN.md`. Mix and voice ducking: `fx/sfx.gd`.
