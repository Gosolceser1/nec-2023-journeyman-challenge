# Sound effects plan

Who hears these: someone studying for the journeyman exam, often with the voice
reading questions, sometimes on headphones for an hour or more. Every sound has
to earn its place: it must tell them something they would otherwise miss, and
still be pleasant on the 100th repetition. Anything the screen already says
clearly stays silent.

## What gets a sound

Six sounds, no more. Adding one needs the same case the sixth (`start`) made:
information the screen alone does not give, pleasant at its real repeat rate.

| Moment | Sound | Why |
|---|---|---|
| A session starts (any menu mode card, the weakest-area chip) | `start` — a sci-fi "power on" charge-up: a faint click, then a pulsing charge that settles, 0.6 s (a sourced recording, see "Session start") | The one commitment point on the menu: "the panel is switched on, the clock is running". Once per session, so it can't fatigue; a texture rather than a tone, so it never reads as a right answer. |
| Answer correct | `correct` — a small charge "zip" into two soft rising notes (G5 → C6) with a faint high sparkle, ~0.3 s; up to a fourth higher on a streak | The core feedback loop; confirms the pick without having to read the verdict. |
| Answer wrong / item timed out | `wrong` — a soft breaker "thunk" under a low tone that sags slightly, ~0.3 s | Equally important, but must feel like "not quite" (the circuit clicked off), never a buzzer or a punishment. |
| Results: passed | `pass` — a short power-up glide into a rising C-major arpeggio that rings, ≤1.5 s | Once per session, marks the end of real effort. |
| Results: did not pass | `fail` — a gentle A → F fall over a quiet power-down, ≤1.2 s | Closes the session honestly without sounding like a game-over. |
| Exam clock at 5:00 and 1:00 left (timed sessions) | `warning` — soft two-note doorbell, each note on a quiet relay tick, ≤0.8 s | Heads-down on a lookup, you can miss the clock turning red; two cues per session, never per second. |

## What stays silent

| Moment | Why it's cut |
|---|---|
| Generic button taps, chips, toggles | Buttons already react visually; clicks on every tap are fatiguing and add nothing. |
| Answer select tap | Selecting *is* answering: the correct/wrong sound fires at the same instant. |
| Menu open/close, navigation, audio settings | Pure navigation; no information. (Starting a session is not navigation: that gets `start`.) |
| Next-question whoosh | Plays 80× in a full simulator; the voice reading the next question is the cue. |
| Per-second countdown ticks | Nagging and stressful; replaced by the two exam-clock warnings. |
| Per-item clock warnings | The item clock restarts every question: a cue there would fire constantly. The pulse and red colour are enough. |
| Streak milestones | Arcade reward; the streak meter shows it. (A streak only pitches the normal `correct` up: +2 semitones at 3 in a row, +4 at 5, +5 at 8. No extra cue.) |
| Confetti sparkle | Doubles the pass sound 1 s later; one result sound is enough. |
| Listen mode answers | Ungraded, and the voice is about to read the answer. |

## Character

- Warm, soft and rounded: electric-piano tones with light electrical textures
  (charge zip, relay tick, breaker thunk, faint shimmer) layered on top, never
  instead of the tone. No raw buzz, arcs or 50/60 Hz hum, no square waves,
  nothing above ~5 kHz carrying the sound.
- Phone-safe: low cues carry their pitch in harmonics above ~500 Hz, so a phone
  speaker still plays them (no cue loses more than ~4 dB through one).
- Short: feedback ≤ 0.3 s, start ≤ 0.6 s, warning ≤ 0.8 s, results ≤ 1.5 s.
- Not arcade-y: no fanfares, no coins, no buzzers.
- Consonant family: all tones in C major, so correct → pass sound related.
  (`start` is the exception: a sourced, brighter "digital HUD" texture with no
  pitch to clash, heard only before any other cue.)
- Loudness-matched: every file is normalized to a max momentary (400 ms,
  K-weighted) loudness of -20 LUFS (warning, fail and start -21), so no cue jumps out;
  the Sounds Off / Low / Medium / High setting scales them together on the SFX bus.
- Voice first: answering and results already stop the voice, so those cues
  play at full level; only the clock warning can overlap it, so only the
  warning is ducked under the Speech bus (the `SFXDuck` sub-bus). `start` is
  routed like the answer tones (straight to `SFX`, never ducked): starting a
  session stops any voice, and auto-read / Listen wait 0.45 s after the
  question appears, which is itself 0.18 s (`AppTheme.MOTION_SCREEN`) after the
  press: the first word comes at 0.63 s at the earliest. The 0.6 s cue is below
  -38 dB from 0.55 s, so it is over before then. `test_sfx` pins "start ends
  before auto-read" against the file's real length.
- Independent of the voice mode: Silent mutes the voice, not these.

## Session start: spec and motion

`assets/sfx/start.wav` is a sourced recording, not synthesized, so
`tools/sfx/make_sfx.py` does not write it (it regenerates the other five only).
It is a placeholder: it ships as is and will be replaced by the final start
sound (same file name, onset and bus).

- Source: "Sci-Fi Weapon – Power On – Charge Up Processed Pulse" by
  RescopicSound, Pixabay #233851
  (https://pixabay.com/sound-effects/film-special-effects-sci-fi-weapon-power-on-charge-up-processed-pulse-233851/),
  Pixabay Content License: free for commercial use, no attribution required,
  bundling in an app allowed, not to be redistributed as a standalone file.
  Only the processed in-app WAV is committed, never the source mp3.
- Processing: mixed to mono, resampled to 44.1 kHz, 90 Hz high-pass, leading
  silence trimmed, first 0.60 s kept with a squared fade-out, 1 ms edge fades,
  DC removed, normalized to -21 LUFS max momentary (like warning and fail:
  heard every session, so a step under the answer tones), true peak ≤ -1 dBTP
  (sample peak -8.3 dBFS). No clipping, no loop, same import settings as the
  other cues.
- Phone speaker: loses 2.8 dB through the phone model (24 dB/oct high-pass at
  500 Hz); the charge's pulses sit in the 300 Hz–4 kHz band.
- Shape: a faint click at 0–30 ms, the charge onset at ~50 ms (full level by
  60 ms), pulses peaking around 180, 240, 340 and 410–440 ms, then a tail that
  is below -38 dB from 0.55 s.

Every menu control that starts a session is wired through
`Widgets.connect_session_start` (mode cards via `Widgets.add_mode_button`,
the hero's weakest-area chip), so a new mode button gets the cue and the
animation automatically:

| Time | Sound | Card |
|---|---|---|
| 0 ms | faint click | the card dips 1.5 % |
| 50 ms | charge onset | the card springs back, current runs once around its border (130 ms) and the badge ring charges to full |

The menu fades out over 0.18 s (`MOTION_SCREEN`) at the same time, so the
motion is keyed to the first 180 ms and the charge's pulses carry on under the
fade into the question. Reduce motion keeps the sound, skips the motion;
Sounds Off and the Low / Medium / High level apply to it like every SFX.

## Answer feedback: sound and motion together

The answer animation (`AnswerCard`, started by `QuizFx.play_answer`) is timed
to the cue, lasts at most ~0.6 s and never delays grading or the layout.

| Moment | `correct` (G5 at 30 ms, C6 + sparkle at ~95 ms) | `wrong` (thunk at ~5 ms) |
|---|---|---|
| 0 ms | The check starts drawing itself as a hot cyan trace, an electron spark running down it | The two strokes of the X shoot in and cross; spark pop at the crossing |
| 30 ms | The spark turns the check's corner | The card glitches sideways in steps (5 / 4 / 3 / 3 / 1.5 px), settled by ~0.2 s |
| ~100 ms | The trace reaches the tip: solder-pad pulse and a small spark puff; card punch | The X cools from white-hot to red |
| 100–460 ms | Current runs once around the card's border; the trace cools to emerald | The X flickers twice like a failing tube (at 0.16 s and 0.49 s, dimming to 55 % / 75 %: under 3 Hz, low contrast) |
| 200–560 ms | | The right card, only now: its check draws in and a softer current runs around it |

On a streak the cue plays up to a fourth higher, so it lands sooner; the
animation scales its timing by the same pitch factor and grows its sparks.
Reduce motion (Settings, or the system setting until changed there) shows the
final icons only; the sounds still play.
