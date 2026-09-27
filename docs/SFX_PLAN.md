# Sound effects plan

Who hears these: someone studying for the journeyman exam, often with the voice
reading questions, sometimes on headphones for an hour or more. Every sound has
to earn its place: it must tell them something they would otherwise miss, and
still be pleasant on the 100th repetition. Anything the screen already says
clearly stays silent.

## What gets a sound

| Moment | Sound | Why |
|---|---|---|
| Answer correct | `correct` — two soft rising notes, ~0.3 s | The core feedback loop; confirms the pick without having to read the verdict. |
| Answer wrong / item timed out | `wrong` — one low, muted, slightly falling note, ~0.3 s | Equally important, but must feel like "not quite", never a buzzer or a punishment. |
| Results: passed | `pass` — warm three-note rise that rings, ≤1.5 s | Once per session, marks the end of real effort. |
| Results: did not pass | `fail` — gentle two-note fall, ≤1.2 s | Closes the session honestly without sounding like a game-over. |
| Exam clock at 5:00 and 1:00 left (timed sessions) | `warning` — soft two-note chime, ≤0.8 s | Heads-down on a lookup, you can miss the clock turning red; two cues per session, never per second. |

## What stays silent

| Moment | Why it's cut |
|---|---|
| Generic button taps, chips, toggles | Buttons already react visually; clicks on every tap are fatiguing and add nothing. |
| Answer select tap | Selecting *is* answering: the correct/wrong sound fires at the same instant. |
| Menu open/close, navigation | Pure navigation; no information. |
| Next-question whoosh | Plays 80× in a full simulator; the voice reading the next question is the cue. |
| Per-second countdown ticks | Nagging and stressful; replaced by the two exam-clock warnings. |
| Per-item clock warnings | The item clock restarts every question: a cue there would fire constantly. The pulse and red colour are enough. |
| Streak milestones | Arcade reward; the streak meter shows it. |
| Confetti sparkle | Doubles the pass sound 1 s later; one result sound is enough. |
| Listen mode answers | Ungraded, and the voice is about to read the answer. |

## Character

- Warm, soft and rounded: mallet / electric-piano tones, no sharp transients,
  no square waves, nothing above ~5 kHz carrying the sound.
- Short: feedback ≤ 0.3 s, warning ≤ 0.8 s, results ≤ 1.5 s.
- Not arcade-y: no fanfares, no coins, no buzzers.
- Consonant family: all tones in C major, so correct → pass sound related.
- Loudness-matched: every file is normalized to the same short-term loudness
  (~-20 LUFS, K-weighted), so no cue jumps out; the Sounds Off / Low / Medium /
  High setting scales them together on the SFX bus.
- Voice first: answering and results already stop the voice; anything that
  still overlaps it (the clock warning) is ducked under the Speech bus.
- Independent of the voice mode: Silent mutes the voice, not these.
