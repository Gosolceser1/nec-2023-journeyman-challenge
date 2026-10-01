# Sound effects plan

Who hears these: someone studying for the journeyman exam, often with the voice
reading questions, sometimes on headphones for an hour or more. Every sound has
to earn its place: it must tell them something they would otherwise miss, and
still be pleasant on the 100th repetition.

The shipped set is "Set C" with four hand-picked replacements: an electric
confirm zap for correct, an electric boom for wrong, a soft pop for hover and
a full swoosh for the screen transition (sourced from Pixabay, processed per role; sources
and license in `assets/sfx/CREDITS.md`): six event cues plus five quiet
interface sounds. `tools/sfx/make_sfx.py` still renders the old synthesized
set, but only writes into `assets/sfx/` with `--replace-shipped`.

## Event cues

| Moment | Sound | Why |
|---|---|---|
| A session starts (any menu mode card, the weakest-area chip) | `start`: "Interface 13", a bright, glassy two-step chime (hits at ~40 and ~120 ms), 0.70 s | The one commitment point on the menu. Once per session, so it can't fatigue. It is also the menu → quiz transition: the press plays nothing else. |
| Answer correct | `correct`: "UI Alert - Confirm Medium", an instant zap sweeping upward ("circuit completed"), silent by 0.73 s, 0.78 s | The core feedback loop; confirms the pick without having to read the verdict. |
| Answer wrong / item timed out | `wrong`: "Electric Boom 1", a crackling electric short-circuit boom that hits at once and pulses, 0.90 s | Equally important; fits the X shorting out. A low boom rather than a buzzer. |
| Results: passed | `pass`: "Level Up", a bright 5-step arpeggio, 2.13 s | Once per session, marks the end of real effort. |
| Results: did not pass | `fail`: "Game Over 39", five gently descending notes, 1.85 s | Closes the session honestly. |
| Exam clock at 5:00 and 1:00 left (timed sessions) | `warning`: "Beep warning", four classic clock-low beeps, 1.50 s | Heads-down on a lookup, you can miss the clock turning red; two cues per session, never per second. |

## Interface sounds

Quiet (-24 LUFS max momentary, hover -27: 7 to 10 dB under the answer tones)
and short. One user action makes at most one sound.

| Sound | File | Plays on | Never on |
|---|---|---|---|
| `click` | "Click", a short dry click, 0.11 s | Plain button presses: Next question / Finish, Read / Stop, Pause / Resume, Skip, Menu (the first, arming press), Change, Preview, opening the voice picker | Session starts (start cue), answer cards |
| `hover` | "Pop Atmos", a tiny soft pop, 0.11 s, pitch varied ±4 % per play so a sweep never sounds like one sample repeated | Mouse pointer entering a menu mode card, desktop layout only | Plain buttons, chips and switches, answer cards, mobile, while a voice reads |
| `toggle` | "Light Switch", a real switch flick, 0.14 s | Switches and chips: voice Mute / Turn on, the Audio & Voice mode, speed and think-pause chips, "Also read the rule", "Reduce motion" | The Sounds level chips (they preview with `correct`) |
| `select` | "Pop Click", 0.19 s, pitch varied ±3 % per play | Keyboard or controller focus moving onto an answer card, before answering; every calculator key (Math Trainer answer pad, Show steps pad) | A click or tap on a card (the answer tone covers it), after answering |
| `transition` | "Swoosh 1", a full airy swoosh with its natural rise and fall, 0.62 s | Screen changes: quiz → report, back to the menu (Return to Main Menu, Menu, Android back) | The launch menu; menu → quiz (the start cue is that transition) |

How "one per action" works (`Sfx.play` / `Sfx.flush_ui`): interface sounds
asked for while handling an action are queued and, at the end of the frame,
only the highest-ranked one plays (transition > toggle = select > click >
hover). An event cue started within 40 ms silences them all, so a start press
is the start cue alone and an answer is the answer tone alone, played at
once. Each interface sound has a minimum gap before it repeats (hover
0.15 s), so sweeping the mouse down the menu cards gives a few soft pops at
slightly different pitches, not a burst. Click, select and hover also recede
when repeated quickly: each play within 0.5 s of the last is 1.5 dB softer,
down to -4.5 dB, and a pause resets it, so typing a number on the calculator
settles into the background. Keyboard answering (A–D, 1–4), Enter / Space / → for Next, and the
Listen loop stay silent apart from the event cues.

Math screens: the Math Trainer's Check plays `correct` / `wrong` like an
answer; Check with nothing entered is a click and a shake of the pad (not the
clock warning), and Steps before answering counts as a miss without the
`wrong` tone. A Show steps calculator row that lands on the step's figure
ends on `correct`; a mismatch only nudges the hint.

On the report, `transition` plays as the screen changes (the 0.62 s swoosh
is over before the dial lands) and `pass` / `fail` when the dial lands 1.15 s later (with Reduce motion the dial lands at once
and only the result sound plays).

## What stays silent

| Moment | Why it's cut |
|---|---|
| Next-question keys and the Listen loop advancing | Plays 80× in a full simulator; the voice reading the next question is the cue. |
| Per-second countdown ticks | Nagging and stressful; replaced by the two exam-clock warnings. |
| Per-item clock warnings | The item clock restarts every question: a cue there would fire constantly. The pulse and red color are enough. |
| Streaks | It's a practice test, not a game: no streak cue, no rising pitch, no streak badge. |
| Confetti sparkle | Doubles the pass sound; one result sound is enough. |
| Listen mode answers | Ungraded, and the voice is about to read the answer. |

## Levels, the voice and settings

- Loudness-matched per role (max momentary, 400 ms, K-weighted, sample peak
  ≤ -1 dBFS, one gain change, no limiter; no EQ except a -3 dB low shelf at
  150 Hz on `wrong` for phone speakers and a -4 dB high shelf at 8 kHz on
  `start`, whose sparkle sits near 8 kHz): start -18.5 LUFS, correct, wrong,
  warning and fail -17, pass -16, click / toggle / select / transition -24,
  hover -27. Every file starts with a 3 ms raised-cosine fade-in and ends
  with a 12 ms fade, so none clicks. `tools/sfx/polish_sfx.py` applies this,
  `tools/sfx/measure_sfx.py` reports it, and `test_motion_polish.gd` holds
  the shipped files to it. The per-sound trims in `Sfx.SOUNDS` stay at 0.
- One bus: every sound, interface sounds included, plays on the `SFX` bus, so
  Sounds Off / Low / Medium / High applies to all of them. Off mutes the bus
  and `Sfx.play` refuses everything, including an interface sound already
  queued in that frame.
- Voice first, event cues: answering and results stop the voice, so those
  cues play at full level; only the clock warning can overlap it, so only the
  warning goes through the `SFXDuck` sub-bus (compressor keyed by the Speech
  bus), plus -8 dB under a system TTS voice.
- Voice first, interface sounds: they never stop or duck the voice. They are
  judged after the action ran, so a press that stops the voice (Menu, Stop)
  plays in full. While a voice (recorded clip or system TTS) is still
  reading, hover is skipped and the others play 8 dB down. They bypass the
  Speech-keyed ducker on purpose: it stays clamped for a moment after the
  voice is cut and would swallow them.
- `start` and auto-read: starting a session stops any voice, and auto-read /
  Listen wait 0.45 s after the question appears, which is itself 0.18 s
  (`AppTheme.MOTION_SCREEN`) after the press: the first word comes at 0.63 s
  at the earliest. The 0.70 s start file is 40 dB under its peak from 0.58 s
  (-63 dB at 0.63 s). `test_sfx` pins that against the file's samples.
- The rule after an answer (Auto-read) starts 0.6 s after the answer tone;
  `correct` is below -40 dB by then; the `wrong` boom is still near full level
  and fades out under the first 0.3 s of the voice.
- Independent of the voice mode: Silent mutes the voice, not these.
- Files: 16-bit WAV, stereo except `warning` (mono), 44.1 or 48 kHz,
  1.5 MB together, imported with QOA compression (`compress/mode=2`).

## Session start: motion

Every menu control that starts a session is wired through
`Widgets.connect_session_start` (mode cards via `Widgets.add_mode_button`,
the hero's weakest-area chip), so a new mode button gets the cue and the
animation automatically, and no click:

| Time | Sound | Card |
|---|---|---|
| 0 ms | (press) | the card dips 1.5 % |
| ~40 ms | first chime | the card springs back, current runs once around its border (130 ms) and the badge ring charges to full (`START_CUE_ONSET` 50 ms) |
| ~120 ms | second chime | current still running |

The menu fades out over 0.18 s (`MOTION_SCREEN`) at the same time, so the
motion is keyed to the first 180 ms and the chime's tail carries on under the
fade into the question. Reduce motion keeps the sound, skips the motion;
Sounds Off and the Low / Medium / High level apply to it like every SFX.

## Answer feedback: sound and motion together

The answer animation (`AnswerCard`, started by `QuizFx.play_answer`) starts
with the cue, lasts at most ~0.6 s and never delays grading or the layout.

| Moment | `correct` (zap from ~10 ms, sweep peaks ~0.23 s) | `wrong` (boom hits at ~3 ms) |
|---|---|---|
| 0 ms | The check starts drawing itself as a hot cyan trace, an electron spark running down it | The two strokes of the X shoot in and cross; spark pop at the crossing |
| 30 ms | The spark turns the check's corner | The card glitches sideways in steps (5 / 4 / 3 / 3 / 1.5 px), settled by ~0.2 s |
| ~100 ms | The trace reaches the tip: solder-pad pulse and a small spark puff; card punch | The X cools from white-hot to red |
| 100–460 ms | Current runs once around the card's border; the trace cools to emerald | The X flickers twice like a failing tube (at 0.16 s and 0.49 s, dimming to 55 % / 75 %: under 3 Hz, low contrast) |
| 200–560 ms | | The right card, only now: its check draws in and a softer current runs around it |

Every right answer gets the same cue at the same pitch and the same
animation: there is no streak (a practice test, not a game). Reduce motion (Settings, or the system setting until changed there) shows the
final icons only; the sounds still play.
