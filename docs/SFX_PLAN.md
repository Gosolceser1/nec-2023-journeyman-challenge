# Sound effects plan

Who hears these: someone studying for the journeyman exam, often with the voice
reading questions, sometimes on headphones for an hour or more. Every sound has
to earn its place: it must tell them something they would otherwise miss, and
still be pleasant on the 100th repetition. Anything the screen already says
clearly stays silent.

## What gets a sound

| Moment | Sound | Why |
|---|---|---|
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
| Menu open/close, navigation | Pure navigation; no information. |
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
- Short: feedback ≤ 0.3 s, warning ≤ 0.8 s, results ≤ 1.5 s.
- Not arcade-y: no fanfares, no coins, no buzzers.
- Consonant family: all tones in C major, so correct → pass sound related.
- Loudness-matched: every file is normalized to a max momentary (400 ms,
  K-weighted) loudness of -20 LUFS (warning and fail -21), so no cue jumps out;
  the Sounds Off / Low / Medium / High setting scales them together on the SFX bus.
- Voice first: answering and results already stop the voice, so those cues
  play at full level; only the clock warning can overlap it, so only the
  warning is ducked under the Speech bus (the `SFXDuck` sub-bus).
- Independent of the voice mode: Silent mutes the voice, not these.

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
