# Changelog

## [Unreleased]

### Added

- **Math Trainer answers on a calculator.** The answer keypad is now a basic
  calculator like the one allowed in the exam room (+ − × ÷ =, memory,
  percent, x², square root, 1/x, ±), so you can work the problem right there:
  Check submits the number showing and finishes a pending operation first
  (12 × 24, then Check, answers 288). A fraction answer goes in as a division
  (19 ÷ 20). On a desktop the keyboard works too: Enter does =, then Check.
  It also fills the empty space under the question. There is no separate
  Calculator tile on the Study tab; the calculator lives where you need it.
- **Try it on the calculator** in Show steps: under a step's calculator keys,
  a calculator walks you through the keys one at a time (the next key lights
  up) and says when you land on the step's number. Earlier steps' results and
  memory are already in it, so rows like "× 14 =" or "1 ÷ MR =" work as shown.

### Changed

- **Study figures look like the real equipment.** Receptacles have proper
  5-15R/5-20R faces (GFCI test and reset buttons, hospital-grade dots),
  panelboards show their breakers, and disconnects, meters, transformers,
  motors, conduit with couplings and one-hole straps, and ground rods with
  their clamps are drawn the same way in every figure. Labels no longer
  overlap or sit on lines, and several depictions were corrected (zones
  measured from the tub edge and the overhead conductors, the pool pump
  receptacle at true scale). The style guide is in docs/DIAGRAM_STYLE.md.

### Fixed

- **Figures no longer give answers away.** Before you answer, a figure now
  hides every rule value the question doesn't state and every word or number
  from any answer choice, right or wrong, for every question that uses the
  same figure. Those spots show a "?" until you answer (69 figures, 190
  questions). Example: the mobile home disconnect figure used to show the
  6 ft 7 in handle-height limit before answering. A new test fails if any
  figure shows such text before the answer.

- All 598 questions re-checked against the NEC 2023 text: no answer key was
  wrong. The motor overload questions (Final #4 Q34, Q37, Q56) quoted 125% and
  115% in the 430.32(C) text; the 2023 values are 140% and 130%, the ones the
  answers use. Stems updated to 2023 wording, same answers: GFCI appliances
  rated 150 volts to ground (Final #3 Q28), deck receptacles within 4 in. of
  the dwelling (Final #2 Q49, Open Book #10 Q20), Danger signs in raceway
  systems (Final #2 Q21). The wound-rotor fuse question (Final #4 Q61) no
  longer says "single-phase" (that matched a second row), and the snow-melt
  receptacle question (Open Book #4 Q21) now states the exception the right
  way round. Three explanations corrected (Final #1 Q49, Open Book #12 Q11,
  Final #3 Q65).
- Background and summary text shown before answering no longer gives away the
  answer on 13 questions (for example "maximum water level", "1/240 s", the
  orange triangle, 83%, "Z is impedance").
- Range demand for 26 or more ranges: "15 + 1 × 28 =" gives the wrong number on
  a basic calculator, so the step now also shows the basic-calculator order
  (1 × 28 + 15 =).
- Apartment lighting demand over 120,000 VA: the 35% key row used the whole
  load instead of the 117,000 VA band.
- The results report no longer shows the last question's "Show steps" button.
- Phones: the results header ("COMPLETE 10/10") is no longer cut off.
- Code-book keywords: hovering a colored word on desktop, or tapping it on a
  phone, now really shows just that word's Index entry (hover was never wired
  and a finger tap never arrived). A second tap brings back the full line, and
  it works even when the INDEX line was hidden to make room.
- Code-book keywords are colored as whole words ("wire", not the start of
  "wireless").
- Code-book keywords look like highlighter marks, not links: a soft amber tint,
  stronger under the pointer, and the tapped word as a solid amber chip.
  Hovering no longer pops a tooltip over the line under the question. No
  keyword holds an answer choice any more (Final Exam #1 Q2 marks "field
  connections", not "rear or side access", which held the choice "rear").
  The INDEX box text is a little larger on desktop, and the item timer bar
  has room above it.
- Question notes no longer hint at the answer before you answer on Final Exam
  #2 Q40 and Open Book #9 Q17, Q19 and Q21.
- The type-letters figure no longer gives away the wet-location cord (Final
  Exam #1 Q34, Open Book #4 Q25).
- Figures: fixed clipped or overlapping labels, misplaced arrows and outlines on
  15 study figures.
- 24 non-math questions no longer show "Memory tip — Electrical math".
- Exams tab: "Final #1" (was "Finals #1") and "1 exam".
- Figure zoom: the close hint says "Tap anywhere to close" on phones and "Click
  anywhere or press Esc to close" on a PC.
- Voice: the trainer reads "1/R1" as "1 over R1"; recorded questions now say
  "single-phase"/"three-phase" for 1ø/3ø, "the sum of" for Σ, "12 2 with
  ground" for #12-2 (not "12 to 2"), "125 percent or 115 percent", "I 1 max",
  and "volt amperes per square meter/foot"; a footnote dagger is no longer
  read. The 19 affected recordings were re-recorded.
- The trainer's topic list says "Series/parallel", like Math weak spots (it
  said "Resistance" on phones).
- The automatic checks on GitHub pass again: one test expected the voice
  recordings, which are not stored in the repository.
- The timer bars no longer look like an underlined link under the time.
- Math weak spots no longer list topics you got 100% on as the weakest.
- Phones: the explanation after answering a question with a figure gets more
  room (the figure shrinks to at least 140 px instead).
- The math screens' Close button shows a cross, not the menu icon.
- Phones: study tool descriptions are no longer cut off.
- The voice settings note now calls the full exam "Full Journeyman Exam", like
  the rest of the app.

## [1.0.5] - 2026-09-29

### Added

- **Code-book keywords in the question.** The exam is open book, so before you
  answer, the words to look up are colored amber in the question, and an INDEX
  line above the "where to look" path names the Index entry and article
  (for example "Swimming pools → Art. 680"). Hover a colored word on desktop, or
  tap it on a phone, to see just its entry. Keywords never contain the answer.
  After you answer, the words stay colored and the usual section reference
  shows. The voice reads the question as before. Turn it off in Settings
  ("Highlight code-book keywords"). It is always off in the Full Exam, like the
  real test. 547 NEC questions have keywords; state law, math and trade
  questions have none.
- **How to hunt in the code book** on the Study tab: the four-step lookup
  routine (keyword, Index, article, rule).
- **72 more questions get a study figure** (docs/DIAGRAMS_AUDIT.md section 8):
  26 new drawings in the app's own style, among them the floor-area and
  ampacity worked examples, ground fault vs. open vs. short, selective
  coordination, the motor branch circuit, hazardous classes, the AFCI and
  tamper-resistant dwelling map, FCC layers and the type-letter decoder, plus
  new notes on six existing figures. Anything that answers the question stays
  hidden until you answer.
- **31 more questions get a study figure** (docs/DIAGRAMS_AUDIT.md section 9):
  23 new drawings, among them Ohm's law and power, EGC sizing from the
  breaker, the termination temperature limit, busbar and welder worked cards,
  the motor-group feeder, insulation colors, the TC bending radius, battery
  room ventilation and the RV park receptacles. As before, the answer stays
  hidden until you answer.
- **152 of the 315 newly imported questions get a study figure**
  (docs/DIAGRAMS_AUDIT.md section 10). 48 repeat an older question and share
  its figure, 24 use an existing figure, and 19 new drawings cover the rest:
  - ground rods in rock, fair rides near power lines, fence bonding, the
    therapeutic tub GFCI zone, conductors coming out of the ground, luminaires
    under roof decking;
  - kitchen and bathroom counters, show windows;
  - cards for series and parallel circuits, AC waves, transformers, box fill,
    derating, conduit fill, range and dryer demand, motor percentages and
    dwelling loads.
  The answer stays hidden until you answer.
- **New main menu in five tabs: Home, Exams, Drills, Study, Settings.** Home
  has "Continue where you left off" (an unfinished run picks up at the same
  question with the same score, even after closing the app), the quick
  drill, your weakest area, "Review missed questions" and the Full
  Journeyman Exam (80 questions, 240 minutes, 75% to pass) with bars for
  what the real exam asks per subject and how you do in each.
- **Every practice exam on the Exams tab**, grouped as Open Book, Finals and
  State Law, each tile showing how many of its questions you have seen and
  your best score against the pass mark. New exams show up by themselves.
- **Drills tab:** the 10 to 50 question drills plus a 10-question drill for
  each subject area, with its share of the exam and your recent accuracy.
- **Study tab** for the math and table study tools, and a "Show steps"
  button after answering a calculation question when they are installed.
- **Nine more practice exams, 315 new questions** (598 in all: 594 NEC 2023
  from 16 exams plus 4 Nebraska State Law). Open Book #2, #3, #5, #6, #9,
  #11 and #12 (25 questions each) and Final #2 and #4 (70 each), each with
  the NEC 2023 provision, a lesson, a memory tip, a note on every choice and,
  where a lookup or calculation is needed, the table and formula steps. They
  were checked against NEC 2023 like the older questions
  (docs/CONTENT_AUDIT_2023.md). No answer key changed: where the printed exam
  follows an older code, the stem or a choice now uses the 2023 wording, so
  the keyed answer is still the one right answer (for example Open Book #12
  Q17, the 30 V rapid-shutdown limit outside the array boundary).
- **Math help for the calculation questions** (docs/MATH_TRAINER.md).
  "Show steps" appears after you answer one of 70 exam calculation
  questions and solves it one step per screen with the calculator keys,
  always reaching the keyed answer. A math trainer with 58 problem types in
  12 topics and three levels, 17 formula cards with pictures and worked
  examples, 17 timed NEC table drills, and math weak spots that steer
  practice to your weakest topics. Table values come from NEC 2023
  (data/nec/2023/tables.json). Open them from the Study tab.

### Fixed

- **Keyword Index pointers checked against the live NEC 2023 text.** A search
  of NFPA 70 2023 on UpCodes confirmed 493 of the 560 keyword and article
  pairs (Article 100 definitions and Chapter 9 tables, which that search does
  not index well, are right by construction). Big Index headings such as
  Luminaires or Receptacles no longer point to an article where the search
  did not find them (for example "Luminaires → Art. 330" on the MC cable
  question).
- **"What section of the NEC…" questions no longer show the answer's
  article before you answer** (Open Book #9 Q21). When the choices are
  section numbers, the "where to look" path stops at the chapter until you
  answer, as it already did for fill-in-the-blank reference questions.
- **The wet-location cord question makes sense again** (Final Exam #1 Q34,
  Open Book #4 Q25). It now asks for the one flexible cord that is wet-rated
  and sunlight resistant (STOOW, same answer as the printed key); it no longer
  reads as "pick all". The Table 400.4 excerpt shown before answering had one
  blank row that gave the answer away and listed SPT-2W, which is not a
  choice. The table now shows after you answer, with a row for each choice,
  including THWN and XHWN from Table 310.4(1) (building wire, not cords).
- **Voice: numbers in math read as numbers, citations as sections.** A
  decimal in arithmetic ("÷ 831.36", "divided by 240.21", "multiply 240.21 by
  2") is no longer read as "section 831 point 36"; a bare number is a section
  only when its article exists in NEC 2023. Citations written without a
  Section word are now read as sections: "(430.22)" after a formula, "the
  220.41 dwelling unit load", "= 5,000 W 220.54", "conforming to 551.81",
  "Under NEC 626.11", "Table 430.248 or 430.250". Also "17.5a" is 17.5 amps,
  "10^18" is "10 to the power of 18", "a ratio of 20:1" is "20 to 1", and
  "the -2" is "the dash 2". "per ft²" is "per square foot". Nine recorded
  questions re-recorded.
- **Voice: a unit before a noun is an adjective.** "a 12 ft assembly" is "a
  12-foot assembly", "a 4.5 kW water heater" is "a 4.5-kilowatt water heater",
  "a 1 in. EMT" is "a 1-inch E M T" and "a 30 A, 240 V circuit" is "a 30-amp,
  240-volt circuit". A quantity stays plural: "10 feet", "10 feet long", "150
  volts to ground". A sentence ending in "ft." keeps its full stop. 56
  questions and 5 math steps re-recorded.
- **Voice: box sizes read like an electrician says them.** '3" x 2" x 2"
  device box' is "3 by 2 by 2-inch device box" (was "3 inches times 2 inches
  times 2 inches"), "4 x 2-1/8 in. octagon box" is "4 by 2 and one eighth
  inch octagon box", and "1 1/2" is "1 and a half". Multiplication still says
  "times" ("5000 x 1.3 = 6,500"). 34 questions and 5 math steps re-recorded.
- **Show steps: Read now uses your voice and reads the whole step.** Read
  used only the Windows or Android system voice (silent on PCs without one).
  It ignored the voice you picked and Voice off, never stopped, and kept
  talking over the next step. It ran the parts together ("6,500 volt
  amperes On the calculator") and read "÷ 0.87" as "0 point 87". Now it reads
  with the picked voice: every step of the 70 exam solutions is recorded
  with Andrew, and trainer steps use the online voice, or the recorded Andrew
  or device voice offline, with a note naming it. Each step reads as whole
  sentences: title, working, note, then the calculator keys ("277, times,
  1.732, equals, memory plus"). Read turns into Stop. Next, Back, Done and
  Close stop it. Voice off hides it, and Auto-read reads each step.
- **No page scrolling before you answer on Final Exam #1 Q4 and Open Book
  #1 Q21 on phones.** Their office-lighting figure sat next to the 31-row
  Table 220.42(A), which left about 30 px of scroll with shuffled choices.
  The figure now shows after you answer. A new test checks every question that
  has both a figure and a table on all seven standard screen sizes.
- **The FORMULA strip no longer gives the answer away** before you answer
  on Final Exam #1 Q22 (garage receptacles) and Q32 (10 ft feeder tap).
- **"What this question means" quotes the question you see.** 17 lessons
  still quoted the printed wording after the stem had been corrected (its
  typos included). The build now restates the corrected stem, and the bank
  check fails if a lesson quotes a different one.
- **Voice:** ".6875" is read "0.6875", not "six thousand eight hundred
  seventy-five"; a lesson line with two tables names both; a line ending in a
  unit such as "18 cu.in." still ends as a sentence.

- **Figures no longer hint at the answer before you answer**
  (docs/DIAGRAMS_AUDIT.md section 6). Final Exam #1 Q32: the tap figure's
  "1/10 of the feeder OCPD" note is now a 240.21(B)(1) checklist with the
  ratio hidden. Open Book #7 Q24: the orange high leg, its caption and the
  "B" and "208" on the caution sign are hidden until you answer. Open Book #4
  Q8: the "N" bar label and "shared grounded conductor" are hidden. Final
  Exam #1 Q22: the garage receptacles no longer peek out above the "?".
- **Pool plan:** the pump receptacle (6 ft) was drawn on the edge of the 5 ft
  underground-wiring zone; it now sits clearly outside it, and the plan says
  "not to scale".
- **Figure zoom on phones:** "Tap anywhere or press Esc to close" ran into
  choice A. It now sits inside the zoomed card.

### Changed

- **The three figures the exams require are redrawn** in the app's own style
  instead of cropped from the PDF: the switch and lamp circuit with its meter
  readings (Final Exam #1 Q5), the three meter hookups (Q13) and the four
  switch symbols (Q47). Same meaning, same answers, sharper on every screen,
  and the keyed part is outlined after you answer.
- **Everything in the menu fits on one screen** at every supported desktop
  and phone size, with no scrolling; Audio & Voice moved to the Settings
  tab, and Back on another tab returns to Home first.
- **Behind the scenes: exams and the NEC edition are data, not code.** Every
  exam's questions come from a reviewed transcript file and every hand-written
  hint, lesson and fix from one curated overlay; the NEC 2023 article titles,
  table values, provision text and content audit sit in one edition folder,
  and the year, the exam format (80 questions, 240 minutes, 75% to pass), the
  app name and the version are each written in one place. Adding an exam is
  now "drop in the PDFs, add a transcript, curate, build"
  (docs/ADDING_EXAMS.md), and moving to NEC 2026 is a data change plus a
  re-audit worklist from a new report tool (docs/EDITION_MIGRATION.md). The
  save folder and the Android app id stay as they are, so progress and
  upgrades are not affected. No question, answer or explanation changed.

## [1.0.4] - 2026-09-28

Every NEC question was checked against the 2023 code for content, tables and
calculations, and 88 questions got an original study figure that hides its
answer under a "?" until you answer. No answer key changed. 1.0.3 was never
published, so this release also brings its changes (the NEC location audit
and natural voices on Windows without Python).

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
  (tools/tests/test_typo_regressions.py) keeps the fixed typos out. After
  the voice check, the displayed text was scanned for the same slips: the two
  cord-type stems now read "are permitted … and are sunlight resistant", and
  the test bans "an hot", "at at", "is has" and similar in every shown field.
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

- **New study figures.** 88 questions now have an original figure drawn
  from the NEC 2023 text, 48 drawings in one dark style: working space,
  grounding electrodes and bonding, burial cover, pool and spa clearances,
  framing protection, box fill and depth, support spacing, overhead and
  antenna clearances, GFCI and wet locations, conduit fill, motor control,
  switch and meter hookups, voltage drop and more. Before you answer,
  anything that would give the answer away is under a "?" (inline and in the
  zoom); after you answer it is revealed with a ring. 75 figures show before
  you answer, 13 that only teach appear after. On small phone screens a
  figure that doesn't fit becomes a one-line "Figure: tap to enlarge" strip
  with a thumbnail, so the question never scrolls. Each figure was reviewed
  against the 2023 text (7 corrections before release; docs/DIAGRAMS_AUDIT.md).
  The figures add about 0.8 MiB to each build; the re-recorded voice bundle
  saves more, so the APK (178.5 MB) is 3.7 MiB and the Windows zip (186.4 MB)
  3.8 MiB smaller than 1.0.3.
- **"?" masks on figures.** A figure can now cover any spot that gives the
  answer away with a "?" badge until you answer, inline and in the zoom; the
  badge fades after answering (instantly with Reduce motion). The three
  PDF figures were reviewed and none needs one (docs/DIAGRAMS_AUDIT.md).
- **Guards** so the audits stay true: the bank validator fails when an
  audited provision or key changes without re-checking
  (`tools/pipeline/content_audit_2023.json`), `check_requirements.py` fails
  when a table or calculation question loses its table, formula or result
  (`data/question_requirements.json`), `test_diagrams` fails when a
  flagged figure region has no mask (`data/diagram_masks.json`), and
  `tools/diagrams/build.py --check` fails when a figure is stale or shows a
  masked answer unmasked.

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
