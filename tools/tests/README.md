# Pure-logic test suite

Unit tests for the project's **static, node-free helper classes**. These are the
functions that decide what the learner sees and hears, and the ones that enforce
the product's core promise: **the answer must not appear anywhere above the
question until the learner answers.**

Everything here runs headless with no autoloads. Most suites are node-free;
the layout-tree, menu-alignment, figure, table-fit and speech-helper suites instantiate
`scenes/main.tscn`. A full run takes about a minute.

## Running

Already wired into `tools/verify.sh` (step 2/5) and the `verify` CI workflow,
so these run automatically on every push.

```bash
cd "C:/Users/vadim/Desktop/All Projects/redigitalpracticetestsforresidentialwireman"

# all suites, one process, combined pass/fail
./Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/tests/run_all.gd

# or one suite at a time (exit code 0 = pass, 1 = fail)
./Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/tests/test_no_leak.gd
./Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/tests/test_audio_explanation_generator.gd
./Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/tests/test_speech_text.gd
./Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/tests/test_speech_rules.gd
./Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/tests/test_unit_matcher.gd
./Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/tests/test_table_viewer.gd
```

`run_all.gd` exits 0 only when every suite passes, and its exit code is the
number of failing suites, so it drops straight into CI. Each suite `extends
SceneTree`, which cannot be instantiated in-process, so the runner launches each
one as a child Godot process and reads its exit code. Slower than an in-process
runner, but it exercises exactly the path a developer runs by hand, and one
suite's failure cannot abort the rest.

**Current status: 5,805 Godot checks across 25 suites, 22 Python tests (validator, spellcheck, speak_question), 1 build-guard shell test, 0 failures, 0 documented product defects.** The scene harness adds 372 (desktop) / 376 (mobile) checks. The speech-helper suite needs a clip from the gitignored `assets/speech/` bundle; on a fresh clone it prints `SKIPPED` and passes with 0 checks.

Every formerly pinned defect is fixed and promoted to a real assertion, so a
regression fails its suite rather than appearing in the defect list. The test table prefix case is covered directly: `NOTED: x` must remain unchanged.

## Layout

| File | Covers |
|---|---|
| `t_report.gd` | shared assertion collector (`check` / `eq` / `ne` / `has` / `lacks` / `no_leak` / `defect`). Not a suite. |
| `test_no_leak.gd` | the leak guard: `redact_answer_spans`, `find_match_in`, `answer_sentence`, + a sweep of all 283 bank records |
| `test_audio_explanation_generator.gd` | `_normalize_for_compare`, `_is_duplicate_text`, `_rule_adds_value`, `prompt_intent`, `prompt_with_answer`, `lesson_point`, `plain_words`, `lesson_lines`, `format_lesson_text`, `generate_explanation` |
| `test_speech_text.gd` | `speakable`, `spoken_fraction`, `_normalize_spoken`, `spoken_segments`, `teach_segments`, `speech_plan`, the delegation shims + a sweep of all 283 speech plans |
| `test_speech_rules.gd` | `speech_rules.gd`: golden input -> spoken cases for every pipeline rule (fails if a rule has none), idempotence, reading order and "Option X." letter clips, the rules version stamp, no answer before answering, and a whole-bank sweep for unspelled caps / raw symbols / doubled periods (spec: `docs/VOICE_READING_RULES.md`) |
| `test_unit_matcher.gd` | `format_answer_number`, `answer_match_candidates` + a sweep of all 283 answers |
| `test_info_panel.gd` | `InfoPanelRenderer`: a MEMORY TIP with per-choice rows is never hidden as an echo (plus a 283-record sweep), and the answer chip lands on the occurrence next to the stem's blank |
| `test_shuffle.gd` | question and choice shuffling: per-mode size and no duplicates, own seedable RNG, chi-square fairness of the first question and of choice slots, locked / pinned choices, grading and display letters under random choice orders, speech letter order |
| `test_question_deck.gd` | `ExamBlueprint` and `QuestionDeck`: area classification and overrides, blueprint apportionment and remainder rotation, per-area no-repeat decks and coverage, article cap and interleaving, missed-question reviews (gap, cap), simulator blueprint, single-area drills, fixed seeds, save / relaunch / version-1 migration / damaged file / reset, mastery and readiness |
| `test_study_feedback.gd` | session area tallies and pace (fake clock, 6:00 flag), area bars and weak rows, the report's study feedback (scored line, weak areas, pace, readiness) and the weakest-area menu button, desktop and mobile |
| `test_menu_cards.gd` | menu mode cards (the Nebraska State Law card included) and answer cards sit in their column slot (same x and width as the column and each other, scale 1) after the menu settles, quick hover passes, a hover spanning a re-sort (hover is glow only, no slide), focus moves, the start press animation and a quiz round-trip; one content box for every card state; audio toggles flush with the row labels; the desktop menu fits 960 px. Desktop and mobile |
| `test_table_viewer.gd` | the pure parts: folding (`_folded_lines`, `max_blocks`), column widths (`_column_floors`, `_column_widths`), `extract_target_keyword`, `is_note_row`, `_strip_note_prefix` + a sweep of all 30 bank tables |
| `test_table_fit.gd` | every table question, both layouts: the lookup table before answering and the feedback table after show whole, with no scrollbar and nothing left to scroll either way |
| `run_all.gd` | combined runner |
| `test_validate_question_bank.py` | Python regression checks for validator/render parity and shared OCR path resolution |
| `test_build_guard.sh` | proves builds refuse default, relative, and absolute targets that would overwrite the curated bank |

## What IS covered

**The no-answer-leak guarantee** (`test_no_leak.gd`, 225 checks) — the highest-value
part of the suite:

- `redact_answer_spans` as a table of `(text, answer) -> expected` cases, covering
  every regression that has already been fixed: single-digit needles, the
  digit-inside-a-larger-number false positive (`"25"` must not eat `"125"`), the
  `"two"` <-> `"2"` word mapping in both directions, multi-word answers, and the
  `125`-volt case.
- Boundary mechanics: which neighbours count as word characters, and the
  deliberate asymmetry between a *digit* glued to a letter (not a match) and a
  *digit* glued to punctuation (a match).
- Every known spelling variant of an answer is redacted when it appears.
- Redaction is **idempotent** — main.gd re-renders and the gist loop blanks up to
  8 times over the same string, so a second pass must be a no-op.
- `find_match_in` span correctness: the reported `start`/`length` must actually
  point at the answer with clean boundaries on both sides.
- A **whole-bank sweep**: for all 283 records, redact every pre-answer field
  (`reference_text`, `formula`, `worked`, `gist`, `tip_short`, `info_tip`,
  `lookup_summary`, `article`, `article_title`) and assert the answer is then
  unfindable. Also asserts the reverse: every record's `lesson_lines` DO state the
  answer, so the teardown can actually teach it.

**TTS readability** (`test_speech_text.gd`, 456 checks) — `speakable()` is
asserted against exact output for inches, feet, mixed numbers and fractions
(`1 1/4"` -> `1 and one quarter inches`), every electrical unit (`240V` ->
`240 volts`, `mA` vs `A`, `kVA`, `kW`, `deg C`/`deg F`, `Hz`, `mm`), jargon
spelling and expansions (`GFCI` -> `G F C I`, `OCPD` -> `overcurrent protective
device`, …), NEC section references (`240.4(D)(5)` -> `section 240 point 4,
paragraph D, item 5`), Roman numerals, aught
sizes, conductor types, blank runs, and every symbol. Plus `spoken_fraction`,
the segment planners, and the guarantee that teach clips are a contiguous tail of
the speech plan (the playback gate depends on that).

**Answer matching** (`test_unit_matcher.gd`, 189 checks) — `answer_match_candidates`
is the foundation of redaction: a missing candidate is a leak. Asserts the
number-word map both ways, feet<->inches<->metric conversion in both directions,
thousands separators (`1200` <-> `1,200`), unit spellings, and the leading-`#` form.

**Table layout** (`test_table_viewer.gd`, 66 checks) — folding order and limits,
column floors that break after `/` and `-`, the width split (never wider than the
box, long headers wrap over number columns), keyword extraction, and a bank sweep
that folding keeps every cell once. `test_table_fit.gd` checks the live tables.

## What is NOT covered (and why)

- **`main.gd` and the UI-bound components** (`SpeechController`,
  `FitController`, the layout builders). The builders are pinned by
  `test_layout_tree.gd`; the rest has its own end-to-end harness at
  `tools/harness.gd`, which drives the real quiz flow headlessly (283 records, all
  render branches, the teach gate, the speech thread join, timer expiry, stale
  speech callbacks). That is the right tool for those; these unit tests are for
  the pure functions underneath it.
- **`TableViewer.populate_table`, `predict_height` and `pick_layout`** — they
  need live labels and fonts, so `test_table_fit.gd` and the harness drive them;
  the pure folding and width helpers underneath *are* covered here.
- **`answer_card.gd`**, `voice_visualizer.gd` — UI nodes and audio playback.
- **Audio output** — nothing here asserts what the TTS engine actually says, only
  the text handed to it. A mispronounced word that survives `speakable()` is
  invisible to this suite.
- **`question_bank.json` content correctness** — the suite uses the bank as
  fixtures and will catch structural breakage (a missing field, an unresolvable
  `correct_index`, an answer that appears nowhere in its own record), but it does
  not judge whether an answer is *right*. Where it pins specific records
  (numbered notes, underscore subscripts) it is as a regression guard, not a
  content audit.

## Two conventions worth knowing

**Assertions vs. documented defects.** A behaviour we assert goes through
`check()`, and a failure is red. A *known* defect in the product goes through
`defect()`, which prints the file, the actual output, the expected output, and
its reach, without failing the run. **When you fix one, promote it to a
`check()`.** There are none left — see the table below
for what was closed and where the assertion now lives.

**Never write `dict.get(k, "") or ""` in GDScript.** `or` is a *boolean*
operator, so that expression yields `str(true) == "true"`, not a fallback. It
silently turns a whole-bank sweep into a sweep of the literal string `"true"`,
which passes while testing nothing. Every test file here routes optional reads
through a `field()` / `_str()` helper instead.

**Never put `\t` in a GDScript double-quoted string.** GDScript recognises a
much smaller escape set than C, and `"[ \t]"` is a *parse* error ("Invalid
escape in string"), not a silent wrong answer. For a whitespace class write a
literal tab inside the brackets, or use `\s`. A parse error in one of these
files surfaces as `Could not preload resource script` in whatever *other* file
preloads it — including the test suites, so the suite appears to break for an
unrelated reason. Same trap applies to `\"` inside a `#` comment: it is fine,
but a stray `"` in a comment is not.

## Defects this suite found, and where they went

All 14 are fixed and now asserted. The `defect()` pins that recorded them were
removed, so a regression is red rather than a printed warning.

| # | Where | What it was | Now asserted in |
|---|---|---|---|
| 1 | `speech_text.gd` | a lone `_` was read aloud as the word "underscore", so `R_total` reached the voice | `speakable("R_total = R / n")` -> `"R total = R / n"` |
| 2 | `speech_text.gd` | no foot-mark rule, so `"5'"` was narrated with a raw apostrophe | `speakable("5'")` -> `"5 feet"`; a possessive (`the Code's`) stays whole |
| 3 | `table_viewer.gd` | `is_note_row` rejected `NOTE 1:`, so a numbered note rendered as a data row | `is_note_row(["NOTE 1: x"])` is true; `_strip_note_prefix` and the classifier share `_is_note_separator` |
| 4 | `unit_matcher.gd` | a fractional inch answer got no `N/M in.` candidate, so `15/16"` could not match its own reference text | `15/16"` -> `15/16 in.` / `15/16 inches`; the bank sweep asserts **0** records whose answer is unfindable |
| 5 | `audio_explanation_generator.gd` | a 4-underscore blank left a stray `_` and glued the answer to the next word | `prompt_intent` / `prompt_with_answer` match `_{2,}`; `"a____at"` fills as `"a vapor seal at"` |
| 6 | `audio_explanation_generator.gd` | `Article__.` filled as `Article100.` | fills as `Article 100.` — the run plus its surrounding space is replaced |
| 7 | `audio_explanation_generator.gd` | `plain_words` had no plural entries, so 26 records narrated code jargon | `plain_words("Luminaires in dwelling units ...")` -> `"light fixtures in houses ..."` |
| 8 | `question_bank.json` | `final-exam-#3-030` wrote its blank as a single `_`, invisible on screen and narrated | fixed in the data: `"... minimum of ___ lbs-inch"`; the bank has **0** lone underscores |
| 9 | `speech_text.gd` | Roman `VIII`/`XII`/`XIII` degraded to `V3`/`X2`/`X3` | longest-first table behind a word boundary; a bare `I` in `W = E x I` is deliberately left alone |
| 10 | `speech_text.gd` | `12/3` was read as "twelve thirds" | `12/3` -> `"12 slash 3"`, while `1/3` and `15/16` stay real fractions |
| 11 | `speech_text.gd` | `1-1/4"` needed whitespace, so the hyphenated form was unconverted | hyphenated mixed numbers normalise to the spaced form |
| 12 | `table_viewer.gd` | `_strip_note_prefix` ate 4 characters off any word starting with `note` | `strip("NOTED: x")` -> `"NOTED: x"` |
| 13 | `unit_matcher.gd` | an `NN%` answer had no `N percent` candidate, so it was never redacted | `83%` -> `83 percent`, `eighty-three percent`. The **bare** number is deliberately excluded: as a candidate it blanked the 8 in `8 AWG` |
| 14 | `speech_text.gd` | `unspaced_mixed` rewrote the live `15/16` fraction as `"1 and five sixteenths"` | the numerator is pinned to `1`, so `15/16 in.` stays a fraction (`Fifteen sixteenths of an inch`) |

**The leak guarantee itself currently holds:** 0 of 283 records leak a surviving
answer into any pre-answer field. The gaps that were found are now closed in
fidelity as well — a number that reads as a unit the TTS mangles, and a lesson
that could not highlight its own answer, are both fixed.
