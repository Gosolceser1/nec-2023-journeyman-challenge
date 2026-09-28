# Changelog

## 1.0.1 (2026-09-28)

Android fixes. Verified on desktop with synthetic touch input; not yet
checked on a real Android device (see docs/KNOWN_ISSUES.md).

### Fixed

- **Android: choosing a voice froze the app, then it closed.** The voice list
  was a dropdown whose popup reacts only to mouse events, and the app does not
  turn touches into mouse events, so the open list took no tap, no scroll and
  no tap outside it. Every touch went to a list that never closed, and the
  Back button then quit the app. The list is now a full-screen voice sheet
  that opens at once even with hundreds of device voices, scrolls by finger,
  picks with a tap and closes with Back or Done. The phone's voice list is
  read once and cached instead of twice on every open.
- **Android: nothing scrolled by finger.** Godot's scroll containers only
  drag-scroll on mouse events. A new touch scroller moves every list (menu,
  question, explanation, results, voice list) with a fling. A swipe that
  starts on a button or an answer card scrolls and never presses or answers
  it; a tap still does.

### Changed

- **Clear male/female voice names on Android.** Device voices read
  "Female 1 · US English · Offline" or
  "Male 2 · US English · Online (needs internet)" instead of raw codes such as
  `en-us-x-iol-local`. Every Google and Samsung US voice is named from a
  researched table (docs/ANDROID_VOICES.md); a voice not in it gets a neutral
  "Voice A", never a guessed gender. The phone's default voice shows as
  "System default".
- **US English voices only on Android.** Other languages and accents
  (en-GB, en-AU, en-IN, es-US, ...) are hidden; Andrew (recorded, offline)
  stays first. A phone without a US voice shows Andrew and System default. A
  previously saved voice that is no longer listed switches to Andrew.

## 1.0.0 (2026-09-27)

First release: Windows (zip, no install) and Android (APK).

- 283 questions: 279 NEC 2023 questions from seven practice exams plus 4
  Nebraska State Law questions, each with the NEC reference, a lesson, a
  memory tip, why each wrong choice is wrong, and the code provision.
- Timed drills of 10 to 50 questions weighted like the exam's content outline,
  the 80-question Journeyman Simulator with a per-area report, pace chart and
  readiness estimate, a weakest-area drill, and a Nebraska State Law drill.
- Shuffled questions and choices, no-repeat decks per subject area, and missed
  questions returning two sessions later.
- A recorded read-aloud voice shipped with the app (plus Edge voices on
  desktop), with a hands-free Listen mode; the answer is never read before you
  answer.
- Reference tables and diagrams beside the question, tables that never scroll,
  electrical answer animations and sounds with a Reduce motion option.
- Works offline; saves in its own user folder, copying progress once from the
  pre-release folder.
