# Question-bank and speech data pipeline

## Current bank

`question_bank.json` is schema v2. It contains 279 playable records across 7 exams, plus a 310-entry manifest and 31 unavailable source entries. Its current top-level keys are `version`, `total_expected`, `playable`, `missing_source_items`, `audit_notes`, `records`, and `manifest`. The old `questions` array is absent; the validator accepts it only as an optional legacy key and checks it if present.

The bank validator is a structural and spoiler-safety gate, not a proof that each answer is technically correct. The regression suite explicitly leaves NEC answer correctness to source review (`tools/tests/README.md`, “What is NOT covered”). Section-level NEC claims must be checked against the 2023 NEC.

## Commands

```bash
./tools/verify.sh                         # full app/test gate, including strict bank validation
python tools/pipeline/validate_question_bank.py --no-warn
bash tools/pipeline/build_question_bank.sh --validate
WIRE_BANK_OUT=/path/to/candidate.json bash tools/pipeline/build_question_bank.sh --build
WIRE_BANK_OUT=/path/to/candidate.json bash tools/pipeline/build_question_bank.sh --full
```

`--no-warn` makes validator warnings fail the gate. The local and CI gates use it. `tools/tests/test_build_guard.sh`, the Python tests (`test_validate_question_bank.py`, `test_spellcheck_bank.py`, `test_speak_question.py`) and `spellcheck_bank.py --offline` run inside the gate before the strict bank validator. The Godot suites cover app behavior and the no-answer-leak guarantee.

## OCR input/output locations

`tools/pipeline/pipeline_paths.py` is the shared path definition for both OCR scripts, the builder, and the answer-key comparison tool:

| Variable | Default | Purpose |
|---|---|---|
| `WIRE_OCR_PATH` | `<system temp>/opencode/wire_ocr` | OCR'd exam text; OCR script output and builder input |
| `WIRE_OCR_KEYS` | `<system temp>/opencode/wire_ocr_keys` | OCR'd answer keys; OCR script output and builder input |
| `WIRE_BANK_OUT` | none — required for `--build`/`--no-speech`/`--full`; `<repo>/data/question_bank.json` is refused | generated candidate bank |
| `PYTHON` | `python` | interpreter used by `tools/pipeline/build_question_bank.sh` |

The OCR scripts skip output files that already exist. Remove or replace a stale OCR text file when the source PDF needs to be processed again.

## Curated bank reproducibility

The raw OCR/parser output is normalized by the deterministic field overlay in `tools/pipeline/question_bank_overrides.json`. `tools/pipeline/bank_overrides.py` applies those reviewed, record-ID keyed changes after parsing, preserving the curated bank without scattering one-off edits through the OCR pipeline.

Every build still writes to a separate candidate path. `tools/pipeline/build_question_bank.sh` refuses the checked-in `question_bank.json` so an unreviewed candidate cannot overwrite the learner bank. A controlled build with the current source and overlay produced all 279 records and exactly matched the checked-in bank; strict validation reported 0 errors and 0 warnings. This proves reproducibility and schema validity, not NEC answer correctness.

To intentionally refresh the overlay after a reviewed bank change:

```bash
WIRE_SKIP_BANK_OVERRIDES=1 WIRE_BANK_OUT=/path/to/raw.json python tools/pipeline/build_question_bank.py
python tools/pipeline/refresh_question_bank_overrides.py /path/to/raw.json
WIRE_BANK_OUT=/path/to/candidate.json bash tools/pipeline/build_question_bank.sh --build
python tools/pipeline/validate_question_bank.py --no-warn /path/to/candidate.json
```

Review the generated overlay and candidate diff before accepting either. The refresh script does not replace the curated bank. The old one-off scripts that rewrote `question_bank.json` in place were removed; every bank change goes through the overlay and a candidate build.

## Wording rule: PDF wording, typos corrected

Question stems and answer choices follow the source exam PDF word for word, odd phrasing included. Two kinds of change are allowed, both through the override overlay (hints through `tools/pipeline/gists.py`):

- **OCR damage** is restored from the PDF page image: dropped `___` blanks, stray letters, `:` read in place of a blank, merged words, `3g` for `3ø`.
- **Typos in the PDF itself** are corrected: misspellings (`sevices` → services, `kvVA` → kVA), dropped words (`roofs which they pass` → roofs *above* which they pass), split compounds (`name plate` → nameplate), and obvious grammar slips (`installations requires` → require). Meaning and numbers never change.

Quoted NEC provision text (`reference_text`) must still match the 2023 edition word for word, so a finding there is fixed only where the NEC itself reads differently. Bank conventions: `3ø` is written "three-phase" and first letters are capitalised; hyphenation of number compounds ("125 volt", "one family") is left as printed. Every change against HEAD is listed in `docs/TYPO_FIXES.md`.

The one stem that intentionally contains its answer is `final-exam-#3-042` (422.33(A) says "accessible" twice and the exam blanks only the second). `PROMPT_LEAK_EXCEPTIONS` in the validator and `prompt_allowlist` in `tools/tests/test_no_leak.gd` pin that record id and exact wording; any other record with a prompt leak is still an error.

`tools/pipeline/spellcheck_bank.py` checks every learner-facing string (bank fields and `tools/pipeline/gists.py`) for misspellings, doubled words, punctuation spacing, unit case (kVA, kW, kcmil, AWG) and unbalanced brackets or quotes. Domain words go in `tools/pipeline/spellcheck_allowlist.txt`. `verify.sh` runs it with `--offline`, against `tools/pipeline/spellcheck_lexicon.txt`, so it needs no extra packages; install `pyspellchecker` for the full dictionary run and `--update-lexicon`.

## What validation checks

- Required schema and field types, unique IDs, answer ranges, and manifest arithmetic.
- Recognized NEC/standard citations or explicit non-code categories.
- Table row shape, allowing recognized single-cell note rows.
- Pre-answer answer mentions using the same visible-text precedence as the app (gist first; task-framing tip only when gist is empty).
- Learner-facing editorial scaffolding that should not ship.
- Correct answers leaking verbatim into the prompt (one pinned exception, see the wording rule).

Current validation result: **0 errors, 0 warnings**. That is not an NEC answer-key audit.

## Speech assets

`tools/speech/dump_speech.gd` exports the speech plan of the checked-in `data/question_bank.json`; `tools/speech/pregenerate_speech.py --bundle` writes bundled MP3s into `assets/speech/` (without `--bundle` it fills the per-user cache). Spoken text comes from `src/speech/speech_rules.gd` (see `docs/VOICE_READING_RULES.md`); bump its `VERSION` when a rule changes output so stale clips are re-rendered. Generated `assets/speech/` clips are gitignored. Rebuild them with the three commands in `README.md`; `build_question_bank.sh --full` also runs them, but always against the checked-in bank, not the candidate it just built.
