# Pure-logic test suite

Unit tests for the project's **static, node-free helper classes**. These are the
functions that decide what the learner sees and hears, and the ones that enforce
the product's core promise: **the answer must not appear anywhere above the
question until the learner answers.**

Everything here runs headless, with no scene, no autoloads, and no engine
resources, in a few seconds.

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
./Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/tests/test_unit_matcher.gd
./Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/tests/test_table_viewer.gd
```

`run_all.gd` exits 0 only when every suite passes, and its exit code is the
number of failing suites, so it drops straight into CI. Each suite `extends
SceneTree`, which cannot be instantiated in-process, so the runner launches each
one as a child Godot process and reads its exit code. Slower than an in-process
runner, but it exercises exactly the path a developer runs by hand, and one
suite's failure cannot abort the rest.

**Current status: 1042 checks, 0 failures, 16 documented product defects.**

## Layout

| File | Covers |
|---|---|
| `t_report.gd` | shared assertion collector (`check` / `eq` / `ne` / `has` / `lacks` / `no_leak` / `defect`). Not a suite. |
| `test_no_leak.gd` | the leak guard: `redact_answer_spans`, `find_match_in`, `answer_sentence`, + a sweep of all 279 bank records |
| `test_audio_explanation_generator.gd` | `_normalize_for_compare`, `_is_duplicate_text`, `_rule_adds_value`, `prompt_intent`, `prompt_with_answer`, `lesson_point`, `plain_words`, `lesson_lines`, `format_lesson_text`, `generate_explanation` |
| `test_speech_text.gd` | `speakable`, `spoken_fraction`, `_normalize_spoken`, `spoken_segments`, `teach_segments`, `speech_plan`, the delegation shims + a sweep of all 279 speech plans |
| `test_unit_matcher.gd` | `format_answer_number`, `answer_match_candidates` + a sweep of all 279 answers |
| `test_table_viewer.gd` | the pure parts: `preview_layout`, `extract_target_keyword`, `is_note_row`, `_strip_note_prefix` + a sweep of all 25 bank tables |
| `run_all.gd` | combined runner |

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
- A **whole-bank sweep**: for all 279 records, redact every pre-answer field
  (`reference_text`, `formula`, `worked`, `gist`, `tip_short`, `info_tip`,
  `lookup_summary`, `article`, `article_title`) and assert the answer is then
  unfindable. Also asserts the reverse: every record's `lesson_lines` DO state the
  answer, so the teardown can actually teach it.

**TTS readability** (`test_speech_text.gd`, 445 checks) — `speakable()` is
asserted against exact output for inches, feet, mixed numbers and fractions
(`1 1/4"` -> `1 and one quarter inches`), every electrical unit (`240V` ->
`240 volts`, `mA` vs `A`, `kVA`, `kW`, `deg C`/`deg F`, `Hz`, `mm`), jargon
expansions (`GFCI`, `AFCI`, `EMT`, `AWG`, `OCPD`, …), NEC section references
(`240.4(D)(5)` -> `Section 240.4, paragraph D, item 5`), Roman numerals, aught
sizes, conductor types, blank runs, and every symbol. Plus `spoken_fraction`,
the segment planners, and the guarantee that teach clips are a contiguous tail of
the speech plan (the playback gate depends on that).

**Answer matching** (`test_unit_matcher.gd`, 177 checks) — `answer_match_candidates`
is the foundation of redaction: a missing candidate is a leak. Asserts the
number-word map both ways, feet<->inches<->metric conversion in both directions,
thousands separators (`1200` <-> `1,200`), unit spellings, and the leading-`#` form.

**Table layout** (`test_table_viewer.gd`, 75 checks) — the geometry formula, the
220/190 caps, the note-strip allowance, degenerate input, and keyword extraction.

## What is NOT covered (and why)

- **`main.gd`** — 150 KB of stateful UI. It has its own end-to-end harness at
  `tools/harness.gd`, which drives the real quiz flow headlessly (279 records, all
  render branches, the teach gate, the speech thread join, timer expiry, stale
  speech callbacks). That is the right tool for those; these unit tests are for
  the pure functions underneath it.
- **`TableViewer.populate_table` and `TableViewer.scroll_to_row`** — they take a
  live `GridContainer` / `Label` / `ScrollContainer` and read real node geometry.
  They need a scene, so they stay in the harness. The pure geometry they depend
  on (`preview_layout`) *is* covered here.
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
how many real records it reaches — but does not fail the suite. That keeps the
suite green and CI-able while making the bugs impossible to miss. **When you fix
one, promote it to a `check()`.** There are 16 today.

**Never write `dict.get(k, "") or ""` in GDScript.** `or` is a *boolean*
operator, so that expression yields `str(true) == "true"`, not a fallback. It
silently turns a whole-bank sweep into a sweep of the literal string `"true"`,
which passes while testing nothing. Every test file here routes optional reads
through a `field()` / `_str()` helper instead.

## Known product defects found by this suite

All 16 are reproduced in the suite with exact actual/expected output. The ones
that reach real bank data:

| # | Where | What | Reach |
|---|---|---|---|
| 1 | `speech_text.gd:127` | a lone `_` is not converted, so `R_total` is read aloud as an underscore | **2 live records** (`final-exam-#3-055`, `final-exam-#1-062`) reach the voice; the same subscripts appear in `reference_text` for both and in `info_tip` for ~18 more |
| 2 | `speech_text.gd:94` | no foot-mark rule, so `"5'"` is narrated with a literal apostrophe | **14 narrated answer choices** (`final-exam-#3-013/-018/-035/-049`) plus the answer callout |
| 3 | `table_viewer.gd:41` | `is_note_row` rejects `NOTE 1:`, contradicting its own docstring, so a numbered note renders as a data row | **1 live record** (`final-exam-#1-021`) — row count inflated, a 165-char sentence shown in a table cell |
| 4 | `unit_matcher.gd:47` | a fractional inch answer gets no `N/M in.` candidate, so it cannot match the `15/16 in.` wording used everywhere | **1 live record** (`final-exam-#3-034`) — its answer is never highlighted |
| 5 | `audio_explanation_generator.gd:8` | a 4-underscore blank leaves a stray `_` and the fill glues the answer to the next word | **1 live record** (`final-exam-#5-050`) |
| 6 | `audio_explanation_generator.gd:192` | `Article__.` fills as `Article100.` with no space | **1 live record** (`final-exam-#3-058`) |
| 7 | `audio_explanation_generator.gd:285` | `plain_words` has no plural entries, so plurals are narrated as code jargon | **26 of 279 records** (luminaires, ungrounded conductors, dwelling units, overcurrent devices, …) |
| 8 | `question_bank.json` | `final-exam-#3-030` writes its blank as a single `_`, so the fill-in is invisible and the underscore is narrated | **1 live record** (a data bug, not a logic bug) |

The rest (`unit_matcher` percent candidates, `speakable` Roman numerals above
`X`, hyphenated mixed numbers, cable designations, `_strip_note_prefix` `NOTED:`)
are latent — not reachable from today's bank, but recorded so a future edit that
does reach them has a failing test waiting.

**The leak guarantee itself currently holds:** 0 of 279 records leak a surviving
answer into any pre-answer field. The gaps found are in *fidelity* (a number that
reads as a unit the TTS mangles, a lesson that cannot highlight its answer), not
in the no-leak property.
