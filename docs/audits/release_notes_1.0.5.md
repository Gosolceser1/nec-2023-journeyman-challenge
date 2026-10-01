# 1.0.5 release notes (GitHub release page)

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

**Downloads:** Windows zip (unzip, run the exe) or Android APK (allow installs from unknown sources). SHA256SUMS.txt has the hashes. Updating Android from 1.0.4 installs over it and keeps your progress.
