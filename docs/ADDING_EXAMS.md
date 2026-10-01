# Adding a practice exam

No code changes. An exam is two PDFs, one transcript and curated data; the
builder, the menu (Exams tab), the simulator's area pools and every test pick it
up from there. Commands run from the repository root; Python and Godot runs use
a temporary `APPDATA` as in `tools/verify.sh`.

## 1. Drop in the PDFs

Copy the exam and its answer key into `exams_source_pdf/`:

```
Journeyman open book exam #13.pdf
Journeyman open book exam #13 answer key.pdf
```

The name must match a family in `tools/pipeline/sources/exams/families.json`
(today: `Journeyman open book exam #N` and `Journeyman open book final exam #N`,
any letter case). The family gives the label the app shows (`Open Book Exam #13`)
and the record id prefix (`open-book-exam-#13`, ids `open-book-exam-#13-001`…).

Another publisher or exam type: add a family (`pattern` with a `(?P<number>…)`
group, `label`, `id_prefix`, `final`). The list order is the bank's exam order.
Never change an existing `id_prefix`: overrides, audits, diagram masks, speech
clips and learners' saved progress are keyed by those ids. Labels can change.

## 2. Transcript

`tools/pipeline/sources/exams/<pdf stem>.json` holds the exam and its key as
reviewed text; the build never parses a PDF for an exam that has one.

```
python tools/pipeline/draft_transcript.py --ocr
```

OCRs the new PDFs (Tesseract on `PATH`, or `WIRE_TESSERACT`) and writes a draft
for every exam without a transcript, listing the question numbers it could not
read. Then, against the PDF page images:

- check every stem, choice, key letter and key reference, word for word (PDF
  typos stay; they are fixed through the overlay in step 4);
- type in the questions the OCR missed;
- a key line whose question page is missing from the scan goes in `key_only`
  (`number`, `correct_index`) with a `key_only_note`; the question becomes a
  "missing source item";
- replace the `provenance` line (it starts `UNREVIEWED OCR DRAFT`) with what was
  checked, by whom and when. `tools/tests/test_exam_sources.py` fails while a
  draft is unreviewed.

Schema: `question_count`, `provenance`, `questions` (`number`, `prompt`,
`answers`, `correct_index`, `reference`, optional `key_note`), optional
`key_only` and `key_only_note`.

## 3. Raw build

```
WIRE_SKIP_BANK_OVERRIDES=1 WIRE_BANK_OUT=/tmp/raw.json python tools/pipeline/build_question_bank.py
```

New records get draft explanations from the edition's draft data
(`data/nec/<year>/provisions.json`, `concepts.json`, `answer_glossary.json`,
`tools/pipeline/draft_vocabulary.json`). Drafts are a starting point only.

## 4. Curate

For each new id, in `tools/pipeline/question_bank_overrides.json` (id-keyed; a
field here always wins over the builder):

- `reference_text` (and `reference_table` when a table is needed) quoting the
  edition's provision word for word;
- `gist`, `info_tip`, `tip_title`, `tip`, `tip_short`, `choice_notes`,
  `lookup_summary`, and `formula` / `worked` for calculations;
- wording fixes to `prompt` / `answers` (log each in `docs/TYPO_FIXES.md`).

`refresh_question_bank_overrides.py` can regenerate the overlay from a raw build
and a hand-reviewed bank (`docs/DATA_PIPELINE.md`).

Then:

- `data/question_requirements.json`: classify every new id (`recall`, `table`,
  `calc`, `formula`, `table+calc`) with its tables, steps, `pre_answer_table`
  and, for calculations, a `check` that `nec_calc.py` recomputes from the
  edition's `tables.json`;
- `data/nec/<year>/content_audit.json`: one entry per new NEC record (status,
  `verified_on`, sections, URL, `correct_index`, and the provision digest from
  `validate_question_bank.provision_digest(record)`);
- `data/exam_blueprint.json` `overrides`: only if a record's NEC chapter puts it
  in the wrong exam area.

## 5. Candidate build and gates

```
WIRE_BANK_OUT=/tmp/candidate.json bash tools/pipeline/build_question_bank.sh --build
python tools/pipeline/validate_question_bank.py --no-warn /tmp/candidate.json
python tools/pipeline/check_requirements.py /tmp/candidate.json
python tools/pipeline/check_worked_solutions.py /tmp/candidate.json
```

Diff the candidate against `data/question_bank.json`: only the new exam's
records and manifest entries may change. Copy it over `data/question_bank.json`
(the build refuses to write there itself), then run
`python tools/pipeline/spellcheck_bank.py --offline` (it reads the checked-in
bank; add reviewed domain words to `spellcheck_allowlist.txt`, or rerun with
`--update-lexicon` after installing `pyspellchecker`).

## 6. App assets and release notes

- Code-book keywords: `python tools/pipeline/hunt_keywords.py` regenerates
  `data/nec/<year>/hunt_keywords.json` for the new records; add vocabulary or
  per-question overrides to `index_terms.json` when a record gets none, and
  `hunt_keywords.py --check` must pass.
- Show steps (optional): a calculation question gets steps from its
  `question_requirements.json` check, or from an entry in
  `data/math/exam_steps.json` (`docs/MATH_TRAINER.md`); `test_math_engine.gd`
  fails when a solution misses the keyed answer.
- Figures (optional): `docs/DIAGRAMS_AUDIT.md` and `data/diagram_masks.json`.
- Speech: `tools/speech/dump_speech.gd`, then
  `tools/speech/pregenerate_speech.py --bundle`, then
  `Godot --headless --path . --import` so the new clips are found (`README.md`).
- `bash tools/verify.sh` must pass. No test pins a question or exam count.
- `CHANGELOG.md` (`## [Unreleased]`) and the README counts.
