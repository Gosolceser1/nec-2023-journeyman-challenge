# Switching the NEC edition (2023 to 2026)

The year is written once, in `data/edition.json`; everything edition-specific
sits in its folder, `data/nec/<year>/`. The switch is a data change plus a
content re-audit. No GDScript or Python changes are needed.

## What reads the edition

| From `data/edition.json` | Where it shows |
|---|---|
| `short` ("NEC 2023") | header titles, report headers, breadcrumbs, math screens, validator messages, splash and README banner (`build_branding.py`, `make_showcase.py`) |
| `year` | app name templates in `data/app.json` ("NEC {year} Journeyman Challenge"), validator's "pre-{year} number" messages |
| `long` | `Edition.long_label()` (the full title; not on screen today) |
| `dir` ("nec/2023") | every edition data file, for the app (`Edition.data_path`) and the pipeline (`pipeline_paths.nec_data`) |

Files in `data/nec/<year>/`:

| File | Used by | Shipped |
|---|---|---|
| `articles.json` | breadcrumbs, chapter chart labels, builder `article_title`, validator location rules | yes |
| `tables.json` | math helpers, `nec_calc.py` checks | yes |
| `content_audit.json` | validator: every NEC record audited against this edition | no |
| `renumbered.json` | validator (old numbers must be called old), migration report | no |
| `provisions.json`, `concepts.json`, `answer_glossary.json` | builder drafts for records the overlay does not cover | no |
| `index_terms.json` | hunt-keyword vocabulary and per-question overrides (`tools/pipeline/hunt_keywords.py`); review headings, subentries and articles against the new book's Index | no |
| `hunt_keywords.json` | stem keywords, Index heading and article per record; regenerate with `python tools/pipeline/hunt_keywords.py` | yes |

## Frozen on purpose

These stay as they are across editions (`data/app.json`, checked by
`sync_identity.py --check` and `test_project_settings.gd`):

- **Save folder** `NEC2023JourneymanChallenge` (`config/custom_user_dir_name`,
  `%APPDATA%\NEC2023JourneymanChallenge`, `user://` on Android). Renaming it
  would leave every existing install without its settings, voice choice and
  study progress.
- **Android package id** `com.livewire.nec2023.trainer`. A different id
  installs as a second app beside the old one instead of upgrading it, and the
  old app keeps the progress.
- **macOS bundle id** `com.livewire.nec2023.trainer`
  (`application/bundle_identifier`), for the same reason.
- **Record ids** (`final-exam-#1-004`, ...) and the `id_prefix` values in
  `tools/pipeline/sources/exams/families.json`. The overlay, audits, masks,
  speech clips and saved progress are keyed by them.

The visible name, description, file names and export paths do follow the
edition (templates in `data/app.json`).

## Steps

1. **Create the edition folder** `data/nec/2026/`:
   - `articles.json`: the 2026 table of contents (chapters, article titles,
     `chapters_short` for the chart labels), same shape as 2023.
   - `tables.json`: `python tools/math/nec_tables_from_cache.py --year 2026`
     from the 2026 text, then check every value by hand against the book.
   - `renumbered.json`: copy the 2023 entries and add every section 2026
     renumbers or moves, with its 2026 home. Loads reportedly move from
     Article 220 to a new Chapter 1 article; verify in the book.
   - `provisions.json`, `concepts.json`, `answer_glossary.json`: copy from
     2023 and update any text that changed (they only seed drafts for new
     records).
   - `content_audit.json`: `{"version": 1, "source": "...", "note": "...", "records": {}}`.
2. **Worklist**:
   `python tools/pipeline/edition_migration_report.py --to 2026 --out audit_2026.md`
   lists every NEC record to re-check: cited articles that are gone or
   retitled, citations or explanations that hit a new renumbering (with the
   exam-area change it causes), records citing a table or value whose numbers
   changed, and records without a 2026 audit entry (all of them at first).
   A dry run against the current edition (`--to 2023`) reports 0.
3. **Re-audit** each record against NEC 2026: fix `reference_text`,
   explanations, citations and, where the code changed the answer, the key,
   all through `tools/pipeline/question_bank_overrides.json`; update
   `data/question_requirements.json` checks; add the record's entry to
   `data/nec/2026/content_audit.json` (status, date, sections, URL, provision
   digest, `correct_index`). Write the findings up as
   `docs/CONTENT_AUDIT_2026.md`.
4. **Switch**: in `data/edition.json` set `year` 2026, `short` "NEC 2026",
   `long` "NFPA 70, National Electrical Code, 2026 Edition", `dir` "nec/2026".
5. **Exam blueprint**: check the exam bulletin for the 2026 exam (areas,
   weights, items, time, pass mark), update `data/exam_blueprint.json`, and set
   its `"edition": 2026`. The validator warns while it names another edition.
6. **Names**: `python tools/release/sync_identity.py` rewrites the visible names
   in `project.godot` and `export_presets.cfg` ("NEC 2026 Journeyman
   Challenge"); the frozen ids are only checked.
7. **Build and gates**: candidate build, `validate_question_bank.py --no-warn`
   (it warns while the 2026 audit is empty and errors for every unaudited NEC
   record once it is not), `check_requirements.py`, `check_worked_solutions.py`,
   then copy the candidate over `data/question_bank.json` and run
   `bash tools/verify.sh`. Layout goldens hold `{EDITION}` and `{VERSION}`, so
   they need no edit.
8. **Assets and text**: `python tools/pipeline/hunt_keywords.py` (code-book
   keywords from the 2026 `index_terms.json`), the original figures
   (`tools/diagrams/figs/` cite 2023 section numbers on the drawings; re-check
   them and run `tools/diagrams/build.py`),
   `python tools/branding/build_branding.py` (splash
   wordmark), `tools/visual/make_showcase.py` (README banner), speech clips
   (`dump_speech.gd`, `pregenerate_speech.py --bundle`), README, store text and
   `CHANGELOG.md`. Keep `data/nec/2023/` in the tree for reference or delete it
   once nothing points at it.

## What stays manual

- Reading NEC 2026: the table of contents, table values, renumberings and every
  record's provision text and key.
- The exam bulletin's areas and weights.
- Explanation rewrites where the code changed.
- Screenshots and store listings.
