# Changelog

## [Unreleased]

Every NEC question was checked against the 2023 code for content, tables and
calculations, and figures got a way to hide answer giveaways. No answer key
changed.

### Fixed

- **NEC 2023 content audit** (docs/CONTENT_AUDIT_2023.md). All 279 NEC
  questions were checked against NFPA 70-2023: the keyed answer, the quoted
  provision, the per-choice notes, the memory tip and every cited section.
  60 questions had explanation fixes (2020 or paraphrased provision text,
  subsection labels, 2023 table numbers such as Table 344.30(B) and Table
  352.30(B), notes that stated a wrong fact). Two questions changed more:
  final-exam-#3-068 tested a 620.51(D)(1) rule that NEC 2023 removed and now
  tests 620.51(A) (disconnect lockable only in the open position), and
  final-exam-#5-008 now says it asks about control and signal conductors
  (330.104). One heading (408.5) is left to confirm in print
  (docs/KNOWN_ISSUES.md).
- **Tables and formulas audit** (docs/TABLES_FORMULAS_AUDIT.md). Every
  question is classified as recall, table, calculation or formula. All 33
  calculations were recomputed from NEC 2023 values and match their keys.
  Questions that could not be answered without the codebook got a real
  lookup table or formula hint (Table 300.5(A), Table 400.4 with Note 9, the
  240.6(A) standard ratings, the Nebraska apprentice ratio), and the Table
  220.45 note now includes the 25% tier.
- **Spell check** (docs/TYPO_FIXES.md). Typos and grammar slips fixed in 8
  questions ("ignitible" and "on-site" as NEC spells them, "Class II, Division
  2", four hint sentences) and in the results screen (singular/plural of
  failed, unanswered and slow items). No answer changed. Follow-up: the
  PDF's own slips are now fixed too (final-exam-#1-019 "equation", complete
  stems for final-exam-#1-011 and #1-051, the #1-066 hint no longer calls MC
  cable a raceway), docs use American spelling, and a regression test
  (tools/tests/test_typo_regressions.py) keeps the fixed typos out.
- **Voice:** the Table 310.16 "COPPER" / "ALUMINUM" headers are read as words,
  not spelled out.
- **Voice completeness and reading.** The rule line no longer stops mid-thought
  ("...two No." for "two No. 6 screws", "...Exception No.", "...overcurrent
  devic.", a lone "Labeled."): it quotes whole sentences only. Fixed misreadings
  "an hot wire", "an reachable location", "motors are has", "rated at at
  most", "cables is not permitted", and the "(C M P, 18)" / "[499:3.3.4.2]"
  tags, table pipes and footnote stars are no longer read out; IBEW is spelled.
  Edge clips are cached only when they are whole MP3 streams long enough for
  their words (the service once ended a 27-word clip after 0.24 s), long text is
  chunked at sentence ends, and every bundled clip is audited for length and
  clean edges (tools/speech/audit_bundle.py). Andrew's bundle was re-recorded.
- **Hints next to the figures.** The Final Exam #1 Q13 hint named the meter
  hookup the question asks for, and the Q47 hint described a symbol shape
  the figure doesn't have; both now describe the figure without giving the
  answer away.
- **Tablet landscape layout.** Answering a figure question in the phone
  layout at 1024x768 could send the figure and the page scrollbar into a
  resize loop that overflowed the engine's message queue; the figure now
  settles on the smaller height.

### Changed

- **New study figures.** 23 questions (working space, grounding electrodes
  and bonding, burial cover, pool and spa clearances, framing protection,
  deck receptacles, support spacing, overhead clearances, GFCI locations)
  now have an original figure drawn from the NEC 2023 text, in one dark
  style. Before you answer, anything that would give the answer away is
  under a "?" (inline and in the zoom); after you answer it is revealed.
  Figures that only teach appear after answering. Each was checked against
  the 2023 text (docs/DIAGRAMS_AUDIT.md).
- **"?" masks on figures.** A figure can now cover any spot that gives the
  answer away with a "?" badge until you answer, inline and in the zoom; the
  badge fades after answering (instantly with Reduce motion). The three
  shipped figures were reviewed and none needs one yet
  (docs/DIAGRAMS_AUDIT.md).
- **Guards** so the audits stay true: the bank validator fails when an
  audited provision or key changes without re-checking
  (`tools/pipeline/content_audit_2023.json`), `check_requirements.py` fails
  when a table or calculation question loses its table, formula or result
  (`data/question_requirements.json`), and `test_diagrams` fails when a
  flagged figure region has no mask (`data/diagram_masks.json`).

## 1.0.3 (2026-09-28)

Windows: the natural online voices work on any PC, no Python needed. Every
NEC location and reference in the question bank was audited against NFPA
70-2023 (docs/LOCATION_AUDIT.md).

### Fixed

- **NEC locations and titles.** Every question's chapter, article, section
  line, lookup hint and cited sections were checked against the 2023 code.
  72 questions showed a shortened or out-of-date article title (for example
  "Branch Circuits" instead of "Branch Circuits Not Over 1000 Volts AC, 1500
  Volts DC, Nominal", or the old "Rigid Metal Conduit: Type RMC"); all titles
  now come from one table of the 2023 article titles. Two citations were
  corrected (344.10(A)(3) for ferrous raceways, and 800.44 as a whole for the
  "any of the above" question) and two "Start with …" hints now point at the
  right section (338.100 and 300.4(A)(2)). No answers changed. A new test
  walks every question in both layouts and checks the breadcrumb is always
  that question's own chapter and article.

### Changed

- **Windows: natural voices without Python.** The Windows build now uses the
  same built-in voice client as Android, so Ava, Brian, Emma, the British Ryan
  and the rest of the desktop list work on any PC with internet; Python and
  edge-tts are no longer needed and the app never starts a helper process.
  Clips are still cached, and with no internet the recorded Andrew reads at
  once, with the status line saying "Andrew (recorded, no internet)" (or
  "System voice (no internet)" for a line without a recording).

## 1.0.2 (2026-09-28)

Android: the natural online voices from Windows are now available. Verified
on desktop (a local fake of the voice service, and the phone layout against
the real service); not yet checked on a real Android device (see
docs/KNOWN_ISSUES.md).

### Fixed

- **Android: the Windows voices were missing.** On Windows the voices other
  than the recorded Andrew are Microsoft Edge neural voices made by a Python
  helper (edge-tts). Android cannot run Python, so the phone only ever listed
  its own device voices. A new built-in client talks to the same Edge voice
  service directly, and the phone's voice list now reads: Andrew · Recorded
  (offline), then the US English Edge voices such as
  "Ava · Female · Online (natural)" and "Brian · Male · Online (natural)"
  (gender from Microsoft's voice data), then the device voices. The British
  Ryan stays on Windows only (US English on the phone). The app now asks for
  the Internet permission.

### Changed

- **No internet, no waiting.** If an online voice cannot be reached, the
  question is read at once by the recorded Andrew (or a device voice when a
  line has no recording), and the status line says so, for example
  "Andrew (recorded, no internet)". After a failed connection the app does
  not try again for 30 seconds, so the next questions do not wait either.
  Clips are cached, so a question heard once plays offline later. The same
  fallback to the recorded Andrew now also applies on Windows when an Edge
  voice is unavailable.
- The rule still never plays before you answer, with every voice.

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
