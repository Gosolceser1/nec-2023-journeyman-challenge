# Data pipeline — the ONE correct path

`question_bank.json` is **generated**, not hand-authored. Never edit it directly:
every manual change is destroyed by the next build, and nothing catches the
regression before it ships.

## The pipeline

```
  exams_source_pdf/*.pdf
          |
          |  (1) tools/ocr_pdfs_tesseract.py        OCR the exam text
          v
  $WIRE_OCR_PATH/*.txt
          |
          |  (2) tools/ocr_answer_keys_tesseract.py OCR the answer keys
          v
  $WIRE_OCR_KEYS/*.txt
          |
          |  (3) tools/build_question_bank.py       THE builder
          v
  question_bank.json                                 generated, never edited
          |
          |  (4) tools/validate_question_bank.py     THE GATE  <-- required
          v
      exit 0 = shippable
          |
          |  (5) tools/dump_speech.gd (headless Godot)
          |      tools/pregenerate_speech.py
          v
  %APPDATA%/Godot/app_userdata/<app>/speech/*.mp3    gitignored, regenerated
```

## Run it

```bash
bash tools/build_question_bank.sh            # steps 3-4: build, then validate (default)
bash tools/build_question_bank.sh --validate # step 4 only — the fast CI check
bash tools/build_question_bank.sh --build    # steps 3-4
bash tools/build_question_bank.sh --no-speech # steps 1-4, incl. OCR
bash tools/build_question_bank.sh --full     # steps 1-5, incl. speech (~71 MB, slow)
```

The script **refuses to continue** when validation fails, and tells you to fix the
builder rather than the bank. There is intentionally no "skip the gate" flag:
if you need to bypass it, you are debugging the validator, not the data.

The validator can also be run directly:

```bash
python tools/validate_question_bank.py                      # repo-root bank
python tools/validate_question_bank.py path/to/bank.json
python tools/validate_question_bank.py --json               # machine-readable
python tools/validate_question_bank.py --no-warn            # CI: warnings fail too
```

Exit codes: `0` valid · `1` invalid · `2` could not run (missing/unparseable).

### Environment overrides

| Variable | Default | Purpose |
|---|---|---|
| `WIRE_OCR_PATH` | `%TEMP%/opencode/wire_ocr` | OCR'd exam text |
| `WIRE_OCR_KEYS` | `%TEMP%/opencode/wire_ocr_keys` | OCR'd answer keys |
| `WIRE_BANK_OUT` | `<repo>/question_bank.json` | output bank |
| `PYTHON` | `python` | interpreter |

## What the validator checks

**Top level** — `version == 2`, `total_expected`, `playable`, `records`,
`questions`, `manifest`, `missing_source_items` present and correctly typed;
unknown top-level keys warned.

**Duplication (`records` vs `questions`)** — lengths, element shape, and a
field-by-field positional comparison. See "Known data bug" below.

**Per record** — required fields present; string/list types; non-empty where
non-empty is required; `id` format and global uniqueness; `difficulty` domain;
`article` looks like an NEC citation; `question_number` a positive int;
`answers` is 2–6 non-empty, non-duplicate strings; `correct_index` in range;
no correct answer leaking verbatim into `prompt`.

**Manifest arithmetic** — `total_expected == len(manifest)`,
`playable == len(records)`, manifest `available`/`unavailable` split equals
records/missing counts, `total_expected == playable + missing`, no duplicate
manifest slots, every record maps to an `available` slot, and no record also
appears in `missing_source_items`.

**Reference tables** — `reference_table` is a list of lists of strings; ragged
rows (width != header width) flagged; note rows flagged when
`TableViewer.is_note_row` would **not** recognise them.

**Answer leaks** — word-boundary match of the correct answer in `gist` and in
each `info_tip` chapter, attributed to the chapter that shows it pre-answer.

The validator is deliberately standalone: it re-implements the consumer
semantics it checks against (`main.gd`, `table_viewer.gd`) rather than importing
the builder, so a builder bug cannot silently redefine the contract.

## Known data bug: `questions` is a stale duplicate

The shipped bank fails validation today. The cause is structural, not cosmetic:

- `build_question_bank.py:2320` writes `"questions": bank` (the **raw,
  pre-repair OCR tuples**, positional 8-element lists) alongside
  `"records": records` (the **normalised, repaired dicts**).
- `main.gd:226` does `parsed.get("records", parsed.get("questions", []))`, so
  `records` always wins and `questions` is dead weight — ~280 KB of the 850 KB
  file that no code path reads.

It is not merely redundant; it is **inconsistent** with `records` on 60 fields
across 49 of 279 entries (see the validator's `duplication:` errors). The
`records` values are the correct, repaired ones.

**Fix:** drop the `"questions": bank` key from the builder payload and keep
only `records`. The positional arrays are a v1 schema leftover; `version: 2`
signals the move to dict records, and the v1 shape was never removed.

## Repo hygiene

- `tools/build_question_bank.bak.py` — a **duplicate builder that has already
  diverged** from `build_question_bank.py` (45 diff lines, stale tip copy in
  `CONCEPT_SHORT`). It is git-tracked. Delete it, or move it out of `tools/`
  into an archive directory. There must be exactly one builder.
- `tools/gists.bak.py` — same problem, same recommendation.
- `question_bank.bak.json` / `question_bank.bak2.json` — throwaway snapshots of
  past builds. Already covered by `.gitignore`
  (`/question_bank.bak*.json`) and correctly untracked. Delete them.
- One-off patch scripts (`apply_code_updates.py`, `fix_literal_language.py`,
  `fix_memory_tips.py`, `apply_gist_corrections.py`, `update_explanations.py`)
  mutate bank content as a side effect of running them. They are the reason the
  generated file and the builder can drift apart: their fixes belong in
  `build_question_bank.py` / `gists.py`, not in a post-hoc patch pass. Prefer
  fixing the builder.

## Adding or fixing a question

1. Fix it in `tools/build_question_bank.py` (or `gists.py` for tips/gists).
2. `bash tools/build_question_bank.sh --build`
3. Fix whatever the validator reports. Do not edit `question_bank.json`.
