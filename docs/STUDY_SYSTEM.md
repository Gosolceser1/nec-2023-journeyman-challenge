# Study system

How the app picks questions and turns answers into study feedback. It is
modeled on the Nebraska Journeyman Electrician exam bulletin (NSED / PSI):
80 scored items, 240 minutes, 75% to pass, open book (NEC 2020 or 2023,
Ugly's), plus 5-10 unscored experimental items the bulletin mentions.

Code: `src/core/exam_blueprint.gd` (outline, classification, apportionment),
`src/core/question_deck.gd` (draws, reviews, saved state, mastery),
`src/core/quiz_session.gd` (one session, area tallies, pace),
`src/ui/results_view.gd` and `src/fx/chapter_bars.gd` (the report). Tests:
`tools/tests/test_question_deck.gd`, `tools/tests/test_shuffle.gd`,
`tools/tests/test_study_feedback.gd`.
Pool report: `tools/study/blueprint_report.gd`.

## 1. Blueprint

`data/exam_blueprint.json` holds the bulletin's content outline, so no
weights live in code. Each area lists the NEC chapters that feed it; chapter
0 means "no NEC article" (trade knowledge, math, NFPA 70E).

| Subject area | Exam items | NEC source | Pool |
|---|---:|---|---:|
| General Electrical Knowledge | 10 | Ch. 1 (90, 100, 110), Ch. 8, Ch. 9 tables and notes, theory and calculations, NFPA 70E, trade knowledge | 54 |
| Wiring and Protection | 20 | Ch. 2 (200-285) | 63 |
| Wiring Methods and Materials | 15 | Ch. 3 (300-399) | 75 |
| Equipment for General Use | 15 | Ch. 4 (400-495) | 50 |
| Special Occupancies | 10 | Ch. 5 (500-590) | 17 |
| Special Equipment | 5 | Ch. 6 (600-695) | 17 |
| Special Conditions | 5 | Ch. 7 (700-770) | **3** |
| Total | 80 | | 279 |

**Special Conditions is short:** the bank has 3 Chapter 7 questions for a
5-item area. The simulator uses all 3 and gives the 2 extra slots to the
heaviest areas (Wiring and Protection 21, Wiring Methods and Materials 16).
Drills of 30 or more questions will repeat those 3 questions often. More
Chapter 7 questions in the bank fix this; no code change is needed.

### Classifying a record

1. An override in `exam_blueprint.json` → `overrides` (question id → area,
   with the reason). The bank text is never edited for this.
2. Else the NEC chapter of the record's `article` (`ChapterBars.chapter_of`:
   "Chapter 9, ..." → 9, first three-digit section → its hundreds, NFPA
   70E and plain labels → 0), mapped through the areas' `chapters` lists.
3. Else the first area (General Electrical Knowledge).

Overrides in use:

| Question | Area | Why |
|---|---|---|
| final-exam-#1-067 | Wiring Methods and Materials | cited as Chapter 9, Note 4, but it asks about raceway (nipple) fill |

Chapter 8 (communications, 4 questions) goes to General Electrical
Knowledge, as the mapping says, since the outline has no communications
area. Re-run `blueprint_report.gd` after a bank rebuild to see the counts
and catch broken overrides (it exits 1 on one).

## 2. Drawing a run

All NEC modes use the whole NEC pool. `QuizSession.begin(count, time, timed, name,
simulation := false, area := "", section := "nec")`. Records with another
`section` (the Nebraska State Law questions) have no subject area, so they
stay out of the blueprint, the decks, the reviews and the readiness; their
own drill shuffles its pool.

### Drills (10/20/30/40/50, listen mode, single-area drills)

- **One deck per area, shared by all drill sizes.** Each is a shuffled pass
  over that area's questions; a draw takes from the top, so no question
  comes back before its whole area has been asked. One shared set of decks
  gives the best coverage: a 10 then a 50 then a 20 never overlap
  (except in areas too small to avoid it).
- **Blueprint split.** The slots left after reviews are split over the areas
  in proportion to the 80-item weights, by largest remainder. The fractions
  that did not become a question carry to the next drill (clamped to ±1),
  so over many drills each area gets exactly its share, and the 5-item areas
  show up every run or two even in 10-question drills. An area with too few
  questions passes its share on the same way.
  A fresh 10-question drill is 1/2/2/2/1/1/1.
- **New pass.** When an area runs dry mid-draw it is reshuffled; that run's
  questions go to the bottom and the previous drill's just above them, so a
  new pass never opens with what you just saw.
- **Article cap.** At most 20% of a run (minimum 2) from one NEC article;
  skipped questions stay on top for the next run.
- **Reviews.** A question answered wrong (or timed out) is due two runs
  later. Due questions go first, oldest first, at most 25% of the drill
  (2 of 10, 5 of 20, ...). Answering it right retires it. A review counts as
  that pass's showing.
- **Coverage.** With the blueprint weighting, a whole area is seen in about
  `pool / (drill size x items / 80)` drills. For 10-question drills that is
  about 44 drills for all 279 (General Electrical Knowledge is the slowest),
  instead of 28 for an unweighted deck. That is the price of drilling in exam
  proportions.

### Simulator (Full Journeyman Exam)

- Exactly the blueprint per area (10/20/15/15/10/5/5; see the Special
  Conditions note above), scaled by largest remainder if the pool or count
  differs. With fewer than 80 questions in the pool it uses all of them.
- Within an area: least recently drawn first, random among equals, so
  consecutive exams share no question wherever the area has enough.
- No review weighting, and it leaves the drill decks alone. Its misses do
  queue for later drills.
- 240 minutes, 75% pass line, unchanged.
- The bulletin's unscored experimental items are **not** simulated. That
  would need a new menu toggle, a longer clock and scoring changes, so it is
  left out.

### Interleaving

The picked set is ordered so no article follows itself while another can go
between. When one article holds more than half of what is left, it goes
next; otherwise the pick is a size-weighted random choice among other
articles, preferring another subject area. The first question stays a
uniform pick from the run. Measured: the same area back to back in under 1%
of neighbors (random order: about 18%).

### Seeds

Each session randomizes its own `RandomNumberGenerator`. The harness and
tests set `session.rng.seed` and `bag_path = ""` for repeatable runs; the
global `seed()` has no effect.

### Resume

The app has no mid-session resume. A session's order and choice order are
fixed when it starts and do not change until it ends. Every new session
reshuffles.

## 3. Saved state

`user://question_bag.cfg` (ConfigFile, version 2), by question id only:

- `[meta]` `version`, `run` (runs drawn, any mode), `credits` (area →
  carried remainder)
- `[decks]` one id list per area (remaining pass, top last)
- `[bag]` `recent`: the last drill's ids
- `[stats]` `by_id`: id → `[times drawn, times wrong, run last drawn, run
  due for review (0 = none), last 4 answers as bits (bit 0 latest, 1 =
  right), answers kept]`

Unknown ids (after a bank rebuild), duplicates and malformed values are
dropped on load. An unreadable file starts fresh. A version 1 file (one
`[bag] ids` deck, no stats) is split into the area decks in order. Stats
without answer history load with an empty history.
`QuizSession.reset_progress()` deletes the file and clears everything.
The app has no settings reset, so nothing calls it yet.

## 4. Study feedback

### Report (every graded session)

- **Subject-area bars.** One bar per area the session touched, in outline
  order, `correct/total  %`, with a tick at 75%. Areas under 75% are amber,
  and the lowest gets a marker. Sessions without area tallies (old tools)
  fall back to the per-chapter bars.
- **Study feedback block** at the top of the report text:
  - simulator only: "Scored line: 62 of 80 correct, 60 needed for 75%: PASS."
  - the areas under 75% with their tallies, and the weakest
  - pace: mean time from showing a question to answering it, against the
    exam's 3:00 per item, listing items over 6:00 (twice the exam pace;
    the item clock stops while a question is read aloud, so wall time can
    run past it)
  - exam readiness and the area to drill next
- Listen sessions are ungraded and add nothing to the tallies, pace or
  mastery.

### Mastery and readiness

- Every graded answer goes into its question's history (the last 4, by
  question id, in the saved state). An area's mastery is the share right
  over those histories, so old misses age out as you improve.
- **Readiness** = sum over areas of (exam items x mastery) / 80. An area not
  practiced yet counts as 0, so the estimate only climbs as you cover the
  outline. 75% is the target, like the pass line.

### Weakest-area drill (menu)

One card on the menu's Home tab: "10 QUESTIONS • WEAKEST AREA", subtitle
`<area> (<mastery>|new) • readiness N% • 30 minutes timed`. It picks the
heaviest area not practiced yet, else the lowest mastery (heavier on ties).
Pressing it starts 10 questions from that area's deck (fewer if the area
is smaller), with that area's due reviews first, 3:00 per question. The
subtitle is recomputed whenever the menu opens. The Drills tab has the full
area picker: one tile per blueprint area with its share of the exam and its
recent accuracy, each starting the same 10-question area drill.
