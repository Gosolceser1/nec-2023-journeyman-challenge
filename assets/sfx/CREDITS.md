# Sound effects — source and license

All files in this folder except `start.wav` are **original, procedurally
synthesized** audio made for this project (44.1 kHz mono 16-bit WAV,
loudness-matched to about -20 LUFS momentary, K-weighted). `start.wav` is a
processed recording; see "start.wav" below.

The shipped set is the **electrical** family (`tools/sfx/electric.py`):
electric-piano tones with light electrical layers (charge zip, relay tick,
breaker thunk, soft shimmer) and phone-safe harmonics on the low cues.

License: **CC0 1.0 Universal** (public domain dedication) —
https://creativecommons.org/publicdomain/zero/1.0/

Regenerate (deterministic, numpy only, overwrites these files):

    python tools/sfx/make_sfx.py                   # shipped family: electric
    python tools/sfx/make_sfx.py --family keys     # the previous set
    python tools/sfx/make_sfx.py --family mallet   # or: pluck
    python tools/sfx/make_sfx.py --preview         # all families -> .audit_tmp/sfx_preview/v2/

| File | Plays when | Length |
|---|---|---|
| correct.wav | right answer | 0.30 s |
| wrong.wav | wrong answer / item timed out | 0.30 s |
| warning.wav | exam clock reaches 5:00 and 1:00 left | 0.80 s |
| pass.wav | results: passed | 1.45 s |
| fail.wav | results: did not pass | 1.20 s |
| start.wav | a session starts from the menu | 0.60 s |

## start.wav

"Sci-Fi Weapon – Power On – Charge Up Processed Pulse" by **RescopicSound**,
Pixabay #233851 —
https://pixabay.com/sound-effects/film-special-effects-sci-fi-weapon-power-on-charge-up-processed-pulse-233851/

License: **Pixabay Content License** (https://pixabay.com/service/license-summary/):
free for commercial use, no attribution required; bundling in an app is
allowed, redistributing or selling the file on its own is not. Processed for
the app (mono, 44.1 kHz, first 0.60 s, -21 LUFS; details in
`docs/SFX_PLAN.md`, "Session start"). `make_sfx.py` does not generate or
overwrite it. It is a placeholder and will be replaced; update this entry
with the new file.

Why only these: see `docs/SFX_PLAN.md`. Mix and voice ducking: `src/fx/sfx.gd`.
