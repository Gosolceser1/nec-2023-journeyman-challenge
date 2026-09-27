# Sound effects plan

Who hears these: someone studying for the journeyman exam, often with the voice
reading questions, sometimes on headphones for an hour or more. Every sound has
to earn its place: it must tell them something they would otherwise miss, and
still be pleasant on the 100th repetition.

The shipped set is "Set C" (sourced from Pixabay, processed per role; sources
and license in `assets/sfx/CREDITS.md`): six event cues plus five quiet
interface sounds. `tools/sfx/make_sfx.py` still renders the old synthesized
set, but only writes into `assets/sfx/` with `--replace-shipped`.

## Event cues

| Moment | Sound | Why |
|---|---|---|
| A session starts (any menu mode card, the weakest-area chip) | `start`: "Interface 13", a bright, glassy two-step chime (hits at ~40 and ~120 ms), 0.70 s | The one commitment point on the menu. Once per session, so it can't fatigue. It is also the menu → quiz transition: the press plays nothing else. |
| Answer correct | `correct`: "Interface 9", a quick crystalline 4-hit chime, 0.90 s; up to a fourth higher on a streak | The core feedback loop; confirms the pick without having to read the verdict. |
| Answer wrong / item timed out | `wrong`: "Notification Error", a soft low two-hit "bonk-bonk", 0.83 s | Equally important, but must feel like "not quite", never a buzzer or a punishment. |
| Results: passed | `pass`: "Level Up", a bright 5-step arpeggio, 2.13 s | Once per session, marks the end of real effort. |
| Results: did not pass | `fail`: "Game Over 39", five gently descending notes, 1.85 s | Closes the session honestly. |
| Exam clock at 5:00 and 1:00 left (timed sessions) | `warning`: "Beep warning", four classic clock-low beeps, 1.50 s | Heads-down on a lookup, you can miss the clock turning red; two cues per session, never per second. |

## Interface sounds

Quiet (-22 LUFS max momentary, hover -25: 6 to 9 dB under the answer tones)
and short. One user action makes at most one sound.

| Sound | File | Plays on | Never on |
|---|---|---|---|
| `click` | "Click", a short dry click, 0.11 s | Plain button presses: Next question / Finish, Read / Stop, Pause / Resume, Skip, Menu (the first, arming press), Change, Preview, opening the voice picker | Session starts (start cue), answer cards |
| `hover` | "Pop Clean", a tiny pop, 0.09 s | Mouse pointer entering a plain button or menu card, desktop layout only | Mobile, answer cards, chips and switches, while a voice reads |
| `toggle` | "Light Switch", a real switch flick, 0.14 s | Switches and chips: voice Mute / Turn on, the Audio & Voice mode, speed and think-pause chips, "Also read the rule", "Reduce motion" | The Sounds level chips (they preview with `correct`) |
| `select` | "Pop Click", 0.19 s | Keyboard or controller focus moving onto an answer card, before answering | A click or tap on a card (the answer tone covers it), after answering |
| `transition` | "Movement Swipe Whoosh 1", a short airy swipe, 0.30 s | Screen changes: quiz → report, back to the menu (Return to Main Menu, Menu, Android back) | The launch menu; menu → quiz (the start cue is that transition) |

How "one per action" works (`Sfx.play` / `Sfx.flush_ui`): interface sounds
asked for while handling an action are queued and, at the end of the frame,
only the highest-ranked one plays (transition > toggle = select > click >
hover). An event cue started within 40 ms silences them all, so a start press
is the start cue alone and an answer is the answer tone alone, played at
once. Each interface sound has a minimum gap before it repeats (hover
0.15 s), so sweeping the mouse down the menu gives one or two pops, not a
burst. Keyboard answering (A–D, 1–4), Enter / Space / → for Next, and the
Listen loop stay silent apart from the event cues.

On the report, `transition` plays as the screen changes and `pass` / `fail`
when the dial lands 1.15 s later (with Reduce motion the dial lands at once
and only the result sound plays).

## What stays silent

| Moment | Why it's cut |
|---|---|
| Next-question keys and the Listen loop advancing | Plays 80× in a full simulator; the voice reading the next question is the cue. |
| Per-second countdown ticks | Nagging and stressful; replaced by the two exam-clock warnings. |
| Per-item clock warnings | The item clock restarts every question: a cue there would fire constantly. The pulse and red colour are enough. |
| Streak milestones | Arcade reward; the streak meter shows it. (A streak only pitches the normal `correct` up: +2 semitones at 3 in a row, +4 at 5, +5 at 8. No extra cue.) |
| Confetti sparkle | Doubles the pass sound; one result sound is enough. |
| Listen mode answers | Ungraded, and the voice is about to read the answer. |

## Levels, the voice and settings

- Loudness-matched per role (max momentary, 400 ms, K-weighted, true peak
  ≤ -1 dBTP, one gain change, no EQ or limiter): start -18 LUFS, correct and
  wrong -16, warning and pass -15, fail -17, click / toggle / select /
  transition -22, hover -25. The per-sound trims in `Sfx.SOUNDS` stay at 0.
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
  `correct` is below -30 dB and `wrong` below -40 dB by then.
- Independent of the voice mode: Silent mutes the voice, not these.
- Files: 16-bit WAV, stereo except `warning` (mono), 44.1 or 48 kHz,
  1.45 MB together, imported with QOA compression (`compress/mode=2`).

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

| Moment | `correct` (chime hits from ~10 ms) | `wrong` (first low hit at ~10 ms) |
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
