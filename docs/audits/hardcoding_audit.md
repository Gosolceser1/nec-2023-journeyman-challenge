# Hardcoding audit: NEC 2023 Journeyman Challenge

Read-only audit, 2026-09-29 ~15:50–16:30. Repo `redigitalpracticetestsforresidentialwireman`, master at
`8832a03` (Release 1.0.4), plus the **uncommitted** working-tree edits of the PDF-import agent
(`tools/pipeline/exam_sources.py`, builder, OCR scripts, count-agnostic tests). Nothing in the repo was edited.

Goals checked against:

- **(a) New exams:** drop the exam PDF and its answer key into `exams_source_pdf/`, run the pipeline, done.
- **(b) NEC 2026:** switch the edition with as few edits as possible, leaving only the real work: re-checking the
  content against the 2026 text.

Line numbers are for the current working tree. The builder is being edited right now, so its line numbers
will move. In-flight work by the other agents is marked **in progress**.

---

## 1. Summary

| Category | Blocks new exams | Blocks 2026 switch | Cosmetic | Total |
|---|---|---|---|---|
| Exam-specific hardcoding (X) | 11 (3 already being fixed by the PDF-import agent) | 0 | 11 | 22 |
| NEC-edition hardcoding (N) | 0 | 16 | 5 | 21 |
| Other magic values, duplication, dead code (M) | 0 | 0 | 12 | 12 |
| **Total** | **11** | **16** | **28** | **55** |

**Top problems**

1. **Per-exam content is Python code.** The builder holds about 230 hand-typed questions in seven
   `exact_*` lists plus a `manual` list, each with its own copy-pasted loop. It also holds per-question
   repairs, hints, worked solutions and gists keyed by display labels like `("Final Exam #1", 22)`. A new
   exam invites more code of the same kind (X08, X09).
2. **The NEC 2023 text and tables are Python code.** About 1,300 lines of verbatim 2023 provision text,
   tables and glossary sit in `build_question_bank.py`. The 2023 table values are in `nec_calc.py`, with a
   second, drifting copy in `check_worked_solutions.py`. The list of old section numbers is in the
   validator (N09, N11, N13).
3. **"2023" appears as a literal in about 80 places across roughly 35 files.** These include the app name,
   the save folder, the Android package id, 12 UI strings, the breadcrumb, release templates, branding
   images, tests and goldens. There is no single edition setting (N01–N17).
4. **Two quiet gate problems for new exams:** questions numbered above 70 are silently dropped (X05). The
   content-audit coverage warning switches itself off once unaudited records outnumber audited ones, which
   the current 9-exam import will do: about 279 audited against about 594 NEC records (X14).
5. **The exam format (80 items / 240 min / 75%) is set in three places.** It is in `data/exam_blueprint.json`
   (never read), in `QuizSession` constants, and in literal menu and HUD strings (M02).

**How hard is it today, and after the plan?**

| Task | Today (HEAD 8832a03) | With the PDF-import agent's work | After this plan |
|---|---|---|---|
| Add an exam | Edit `SOURCES` in 2 files. Counts are guessed from the filename (70 or 25). Usually a hand-typed `exact_xx` list plus hint dicts in code. Needs Tesseract at a fixed path. The audit gate goes quiet. | Drop the PDFs (they must follow the `Journeyman open book [final] exam #N` naming). Counts come from the cover page or a transcript. The 70-question cap and the audit hole remain. | Drop the PDFs (plus an optional transcript JSON), run `build_question_bank.sh --full`, and review the new records the validator lists as "pending audit". **No code edits.** |
| Switch to NEC 2026 | About 80 literal edits in about 35 files. 1,300 lines of provision text and 2 table modules rewritten inside Python. Renaming the app or package risks losing saves and the Android upgrade path. | Same. | Set `data/edition.json` to 2026, add `data/nec/2026/*.json`, run the sync and migration-report tools. **No code edits.** What remains is the manual content re-audit against the 2026 book (section 5). |

---

## 2. Work already in flight (reconciled)

**PDF-import agent (uncommitted, 15:48–):** adds `tools/pipeline/exam_sources.py`. It discovers exams from
`exams_source_pdf/`, pairs each with its answer key (in any letter case), and reads the question count from a
reviewed transcript (`tools/pipeline/sources/exams/<stem>.json`) or from the OCR cover page ("25 QUESTIONS").
The builder, `compare_tesseract_keys.py` and both OCR scripts now use it. `total_expected` is computed, not
310. The harness and the `test_bank_loader`, `test_shuffle`, `test_no_leak`, `test_question_deck` and
`check_export_pack` suites now compare against the bank's declared `playable` count instead of 283/279. New
suite: `tools/tests/test_exam_sources.py`.

This fixes X01–X04 and most of the count pinning, and it is the right design for goal (a). **This plan builds
on it instead of adding a competing manifest.** Items it does not cover yet: X05 (70 cap), X06/X07 (naming
convention and label-derived ids), X08/X09 (per-exam code), X14 (audit hole), X16 (state-law count 4, first id).

**Diagram-fix agent (15:50–):** owns `assets/diagrams/**`, `tools/diagrams/**`, `data/diagram_masks.json`,
`src/ui/diagram_view.gd` and the diagram tests. N21 (figures cite 2023 sections) and X13 (PDF figure crop
table) wait for it.

---

## 3. The earlier 54-step clean-code plan

**It exists, but not in the repo.** `docs/` has only `REFACTOR_PLAN.md` (steps S0–S11, executed through
83104fd). The 54-step plan is in a private agent notes folder outside the repo
(`clean_code/PLAN.md`, with `AUDIT.md`, lint configs and metrics), written 2026-09-27 against commit `874286e`.

**Status: not started.** None of its phase-L artifacts are in the repo: no `gdlintrc`, `ruff.toml`,
`.editorconfig`, `tools/lint/` or `docs/CODING_STANDARDS.md`.

**Stale parts:**

- Its base commit `874286e` predates the content, location, tables, diagram, voice and spell-check work.
- It references `test_speech_helper` and `BUNDLE_HITS=279/279`. The Python speech helper has since been
  replaced by the built-in Edge client, and the bundle is now 283 clips and growing.
- Its core rule, "`data/question_bank.json` text never changes (hash gate)", is incompatible with the exam
  import. Its step P0.2 must re-baseline after the import and diagram work land.

**Overlap and reconciliation:**

| 54-plan step | Relation to this audit | Decision |
|---|---|---|
| E3 "split `build_question_bank.py` data from logic → `bank_tables.py`" | Same problem as X08/X09/N11 | **Replace** with this plan's H3/H4/E6: move the data to JSON files (per exam and per edition), not to another `.py` file |
| E5 "shared paths; manifest 310 / 70 / 25 as named constants" | Paths are already done in `pipeline_paths.py`. The numbers are being **removed** by discovery | **Drop the constants part.** Named constants would re-freeze exam counts |
| A4 named timing/threshold constants; score tiers 75/60 | Overlaps M02 | Do M02 (read from the blueprint) instead of new constants for 75/60 |
| A5 colors into `AppTheme` | = M12 | Keep in the 54-plan |
| B9 shared builder blocks | = M04 (duplicate menu lists) | Do M04 as a data-driven menu spec inside B9 |
| A7 session mode enum | Independent | Keep |
| L3a whole-tree `gdformat` (62 files) | Collides with every open patch | Run it **after** this plan's phases H and E, when nothing else is in flight |

**Suggested order:** this plan's phase H (exams) → phase E (edition) → the 54-plan from P0.2 (re-baselined),
without E3 and the E5 constants.

---

## 4. Findings

Severity: **BNE** = blocks new exams, **B26** = blocks the 2026 switch, **C** = cosmetic or maintenance.

### 4.1 Exam-specific hardcoding

| ID | Where | Sev | Finding | Fix |
|---|---|---|---|---|
| X01 | `tools/pipeline/build_question_bank.py:20-28` (HEAD) | BNE | `SOURCES` dict lists the 7 exams by PDF stem and label | **In progress:** `exam_sources.discover()`. Land it |
| X02 | same, HEAD `:1998`, `:2294`, `:2297-2298` | BNE | Question count guessed with `"Final" in source` (70 vs 25). `total_expected = 310 + …` | **In progress:** `QUESTION_COUNTS` from the transcript or cover page. Land it |
| X03 | `tools/pipeline/compare_tesseract_keys.py:11-17, 37` (HEAD) | BNE | Second copy of the exam list and of 70/25 | **In progress** (uses `discover()`) |
| X04 | `ocr_pdfs_tesseract.py`, `ocr_answer_keys_tesseract.py` (HEAD) | C | Two identical 40-line scripts, split by the substring `"answer key"` | **In progress** (shared `ocr_pdf()`) |
| X05 | `build_question_bank.py:56` (`number > 70`), `:85` (`number <= 70`) | BNE | Question numbers above 70 are dropped silently by the OCR parser and the key parser. A 75- or 100-question exam loses its tail | Pass `exam.question_count()` into `read_questions` / `read_key`. Test with a synthetic 80-question OCR fixture |
| X06 | `tools/pipeline/exam_sources.py:26` (`EXAM_NAME`), `:64-70` (`label_for`) | BNE | Only `Journeyman open book [final ]exam #N` is accepted. The label template ("Final Exam #N" / "Open Book Exam #N") is in code. Closed-book, residential, master or another publisher's PDFs fail | Keep the regex as the default. Add optional `tools/pipeline/sources/exams/families.json`: `[{pattern, label, id_prefix}]`. Error message names the file to edit |
| X07 | `exam_sources.py:93` (`record_id`), `state_law_source.py:36` (`_slug`) | BNE (risk) | Record ids are derived from the display label (lower case, dashes, `#` kept). Renaming a label changes every id and orphans overrides, the content audit, requirements, masks, figures, speech folders and saved progress (`question_bag.cfg`) | Freeze an explicit `id_prefix` per family (current prefixes `final-exam-#`, `open-book-exam-#`, `ne-state-act-#`). Unit test: every id in the shipped bank still exists after a rebuild |
| X08 | `build_question_bank.py:2013` `manual`, `:2063` `exact_ob1`, `:2095` `exact_ob4`, `:2127` `exact_ob7`, `:2159` `exact_ob10`, `:2191` `exact_final1`, `:2212` `exact_final3`, `:2227` `exact_final5` | BNE | About 230 hand-typed questions in code, each with an identical copy-pasted 3-line loop. These are exactly what the new `sources/exams/<stem>.json` transcripts are for | Move each list into its exam's transcript (or a `<stem>.corrections.json` overlay). Delete the lists and loops. Gate: the rebuilt candidate bank is byte-identical |
| X09 | `build_question_bank.py:1210` `PROMPT_REPAIRS`, `:1411` `QUESTION_REFERENCE_TEXTS`, `:1869` `FORMULA_HINTS`, `:1901` `WORKED_SOLUTIONS`; `tools/pipeline/gists.py` `GISTS`/`SCENES` | BNE | Per-question curated content keyed by `(label, number)` tuples in code. It couples to the label text and needs a code edit per new question | Move to id-keyed data: `question_bank_overrides.json` already takes id-keyed field overrides. Or use `sources/curated/<exam-id>.json`. Byte-identical rebuild |
| X10 | `build_question_bank.py:29` (header regex `Journeyman Final Exam #\d+\|OB #\d+`), `:32-50` (OCR typo dict), `:60-64` (per-exam OCR option fixes such as `"M6" → "(d) 6"`) | C | Publisher- and scan-specific OCR fixes in code | `tools/pipeline/ocr_fixes.json` (`header_patterns`, `replacements`, `option_fixes`) |
| X11 | `build_question_bank.py:94-99` `difficulty()` | C | ≤8 easy, ≥58 hard, tuned to 70-question finals. The `exact_*` loops force "medium". **The app never reads `difficulty`** (only the legacy branch in `bank_loader.gd:76`) | Drop the field from the validator's required list and the builder, or compute it relative to the question count |
| X12 | `ocr_pdfs_tesseract.py:10` (`TESSERACT = C:\Program Files\...`); `pipeline_paths.py:10` (`%TEMP%\opencode`); counts need the OCR text when there is no transcript | BNE (fresh machine) | "Drop PDFs and run" fails on a machine without Tesseract at that exact path. Rebuilds need a hidden OCR cache in `%TEMP%` | `TESSERACT` from an env var or `shutil.which`, with a clear error. Commit a transcript for every exam so the build never needs OCR. Rename the default cache to `%TEMP%\wire_pipeline` |
| X13 | `tools/pipeline/extract_diagrams.py:28-50` | C | PDF filename, page and crop boxes per record in code | Wait for the diagram agent (it is redrawing these 3 figures). If the tool stays, move `FIGURES` to `data/pdf_figures.json` |
| X14 | `tools/pipeline/validate_question_bank.py:329` | **BNE** | "No content-audit entry" warnings fire only when `len(covered) * 2 >= len(nec)`. That heuristic is meant for unit-test fixtures. After the 9-exam import (about 315 new NEC records against 279 audited) it becomes false, and **every unaudited record passes silently** | Explicit switch: enforce coverage when validating the shipped bank (`DEFAULT_BANK`) or when the audit file says `"enforce": true`. Add status `"pending"` so an imported-but-unreviewed record is visible and counted. Test in `test_validate_question_bank.py` |
| X15 | `validate_question_bank.py:88` `PROMPT_LEAK_EXCEPTIONS` | C | Record id and full prompt in code | Move to the content-audit entry (`prompt_leak_ok: "<prompt>"`) |
| X16 | `tools/harness.gd` ("state-law pool == 4"); `tools/tests/test_no_leak.gd` (first id `final-exam-#1-002`) | C | Still pinned after the import agent's edits | Count the state-law questions from `tools/pipeline/sources/*.json`. Check "first id exists" instead of a position |
| X17 | `tools/tests/golden/layout_tree_{desktop,mobile}.txt` (≈ lines 2567, 2655, 2743, 2781) | C | Goldens pin "4 QUESTIONS … 12 minutes", the weakest-area subtitle, "80 scored questions…", the edition and `v1.0.4`. Every version or edition change forces a regeneration | In `test_layout_tree.gd`, replace the version, edition and counts with placeholders before comparing (`{VERSION}`, `{EDITION}`) |
| X18 | `README.md:38`, `docs/DATA_PIPELINE.md:5`, `docs/STUDY_SYSTEM.md:31,92`, `docs/ARCHITECTURE.md:156`, `tools/tests/README.md:49-54,93,125,192`, `tools/visual/make_showcase.py:102` | C | "283 questions / 279 NEC / seven exams" in docs and in the showcase image | Word the docs without counts, or generate a stats block (`tools/docs/bank_stats.py`) |
| X19 | `tools/speech/test_bundle.gd`, `verify.sh:161-165` | BNE (by design) | New records have no recorded clips, so verify fails until `pregenerate_speech.py --bundle` runs | Keep the gate. Put it in the "add an exam" checklist; `build_question_bank.sh --full` already runs it |
| X20 | `data/question_requirements.json`, `tools/pipeline/check_worked_solutions.py:94` `CHECKS` | C | Calculation checks are opt-in per record id, so new calculation questions go unchecked. `CHECKS` duplicates the requirement file | Validator warning: a record with `formula`/`worked` but no requirements entry. Merge `CHECKS` into `question_requirements.json` |
| X21 | `tools/diagrams/records.py` `NEED`, `assets/diagrams/nec/figures.json` | C | Figures are mapped per record id; new exams get none until a diagram pass | No change; the gap scan (`docs/audits/diagram_gap_scan.md`) is the right process. Add the new exams to the next scan |
| X22 | `docs/study_guides/journeyman_*_overview.md` | C | Hand-written per-exam notes, referenced by nothing | Leave as history or delete (user's choice) |

### 4.2 NEC-edition hardcoding

| ID | Where | Sev | Finding | Fix |
|---|---|---|---|---|
| N01 | `project.godot:17-18, 22, 25` | B26 | `config/name`, `config/description`, `custom_user_dir_name="NEC2023JourneymanChallenge"` | The name and description are written by `tools/release/sync_identity.py` from `data/app.json` plus `data/edition.json`. **Freeze** the user folder name (invisible identifier; changing it loses progress) |
| N02 | `export_presets.cfg:11, 25-26, 41, 47-48, 69, 77-78` | B26 | Product names, export paths, `package/unique_name="com.livewire.nec2023.trainer"` | Names and paths come from `sync_identity.py`. **Decide once:** keep the package id (existing installs upgrade in place, recommended) or ship a new app |
| N03 | `src/core/user_dir_migration.gd:18` | B26 | The pre-1.0 folder is looked up by the *current* `config/name`. Renaming the app breaks that migration, and there is no migration between custom folder names | `LEGACY_PROJECT_NAMES := ["NEC 2023 Journeyman Challenge"]` and `LEGACY_USER_DIRS`, tried in order. Test in `test_user_dir_migration.gd` |
| N04 | `src/core/nec_reference.gd:21` (`nec_2023_articles.json`), `:84`, `:115`, `:116` (`"NEC 2023  ►"`), comments `:19, :31, :135` | B26 | Articles path and breadcrumb prefix are literals | New `src/core/edition.gd` (`Edition.short_label()`, `Edition.data_path("articles.json")`) reading `res://data/edition.json` |
| N05 | `src/app/desktop_layout.gd:63, 496, 516`; `src/app/mobile_layout.gd:49, 423, 440`; `src/ui/widgets.gd:287`; `src/app/main.gd:1293`; `src/ui/results_view.gd:16, 25, 196` | B26 | 12 UI strings with "NEC 2023" (title, hero, menu note, error screen, results headers) | Format from `Edition` (`"%s // JOURNEYMAN CHALLENGE" % Edition.short_label().to_upper()`). The goldens stay identical |
| N06 | `src/app/main.gd:6` (`EXAM_NAME := "NE JOURNEYMAN ELECTRICIAN"`), `results_view.gd:24` | C | Jurisdiction label in code | Move to the blueprint JSON (`"exam_name"`, `"authority"`) |
| N07 | `build_question_bank.py:1931`, `validate_question_bank.py:277` | B26 | Both read `data/nec_2023_articles.json` by literal path | `pipeline_paths.nec_data("articles.json")` from `data/edition.json` |
| N08 | `validate_question_bank.py:298` (`content_audit_2023.json`), messages `:310, :323, :332, :375, :377, :425, :428`; `spellcheck_bank.py:11`; `spellcheck_allowlist.txt:9` | B26 | Audit file and error text are tied to 2023 | `data/nec/<year>/content_audit.json`; messages use `edition["short"]` |
| N09 | `validate_question_bank.py:283-294` `PRE_2023_SECTIONS` | B26 | The table of numbers renumbered by the edition change is in code | `data/nec/2023/renumbered.json` (`[{pattern, new_home, since}]`). The 2026 file is the 2023→2026 relocation list and also drives the migration report (section 5) |
| N10 | `validate_question_bank.py:119` (pattern `\(2023 NEC\)`); `build_question_bank.py:987, 997, 999, 1004, 1011, 1028` ("(2023 NEC)", "(2023)", "NEC 2023 deleted former Table 310.12"); `:2173` (stem "complies with the 2023 NEC?") | B26 | Edition annotations inside provision text and one stem | Make the pattern `\(\d{4} NEC\)`. Rewrite the annotations without the year. Stems can say "the NEC" (the app shows the edition) |
| N11 | `build_question_bank.py:200` `CONCEPT_NOTES`, `:875` `REFERENCE_TEXTS`, `:1094` `REFERENCE_TABLES`, `:1438` `ANSWER_GLOSSARY` (≈1,300 lines) | **B26** | Verbatim NEC 2023 provision text and tables live in Python. For 2026 they must be re-quoted, and that work should be a data diff, not a code edit | `data/nec/2023/provisions.json` (section → text / table) and an edition-neutral `data/concepts.json` for the tips. The builder picks the provisions by edition. Byte-identical rebuild |
| N12 | `build_question_bank.py:1940-1977` (`CHAPTER_SLUGS`, `article_chapter`, `upcodes_url` → `nfpa-70-2023`) | C | Dead code (defined, never called) with a 2023 URL | Delete |
| N13 | `tools/pipeline/nec_calc.py:1-100` (tables "checked against NFPA 70-2023"); `check_worked_solutions.py:31-60` (second copy, subset) | B26 | Edition table values in code, duplicated | `data/nec/2023/tables.json` loaded by `nec_calc.py`; delete the copy in `check_worked_solutions.py`. 2026 = new file re-verified from the book |
| N14 | `data/exam_blueprint.json` (`areas[].chapters`, `covers` "Articles 200-285", `overrides`) | B26 | Areas are assigned by NEC chapter. If 2026 moves articles between chapters, questions silently change area. Load calculations reportedly move from Art. 220 to a new Chapter 1 article; **verify in the 2026 book**. A 2026 PSI bulletin may also change the weights | Add `"edition"` and `"bulletin_date"` to the blueprint. Validator warning when the blueprint edition does not match `edition.json`. The migration report lists records whose area changes |
| N15 | `tools/release/make_release.py:30-31` (`APP_NAME`, `FILE_STEM`); `tools/release/README.txt:1,4,15,30,44`; `CREDITS.txt:1,7`; `dump_licenses.gd:17`; `tools/list_pck.py:3`; `tools/speech/check_export_pack.gd:8` | B26 | App name, file stem and save folder written out | Templates `{app_name}`, `{file_stem}`, `{user_dir}` filled from `data/app.json` (`make_release.py` already formats `{version}`) |
| N16 | `tools/branding/build_branding.py:90, 106`; `assets/branding/splash.png` (text baked in); `tools/visual/make_showcase.py:97-98`; `docs/media/*.png` | B26 | "NEC 2023" is drawn into the images | The branding and showcase scripts read `edition.json`; regenerate at the switch |
| N17 | `tools/tests/test_nec_reference.gd:33-71` (7 literal breadcrumbs); `test_user_dir_migration.gd:45-48, 122, 132`; goldens; `test_validate_question_bank.py:206-239` | B26 | Tests pin "NEC 2023" and the folder name | Build the expected strings from `Edition`. The migration test uses the frozen folder constant. Validator tests pass an explicit edition fixture |
| N18 | `README.md:4-10, 18-23, 38, 62, 152-161, 212, 226, 243`; `docs/ARCHITECTURE.md`, `DATA_PIPELINE.md`, `RELEASE.md`, `CONTENT_AUDIT_2023.md` (file name); GitHub slug `nec-2023-journeyman-challenge` | C | Docs and links name the edition | At the switch: README badge and title, per-edition audit docs under `docs/audits/<year>/`. Keep or rename the repo slug (GitHub redirects renamed repos) |
| N19 | `src/fx/chapter_bars.gd:11-23` `CHAPTER_NAMES` | C | Duplicates the chapter titles in the articles JSON (short forms) | `"chapter_short"` in the articles JSON |
| N20 | `nec_reference.gd:6-17`, `speech_rules.gd:443-458`, `validate_question_bank.py:73, 75`, `bank_loader.gd:9`, `widgets.gd:81-92`, `chapter_bars.gd:10, 22` | C | Nebraska state-law handling is hardcoded. That is jurisdiction, not edition, and fine while the app is Nebraska-only | Optional `data/jurisdiction.json` if another state is ever added |
| N21 | `tools/diagrams/**`, `assets/diagrams/nec/figures.json` (`"nec"` field), filenames like `working_space_110-26.png`, `feeder_tap_10ft_240-21b1.png`; `docs/diagrams/labels.json` | B26 | 48 figures are drawn from 2023 sections. Filenames and on-figure section chips cite 2023 numbers | Wait for the diagram agent. At the switch, generate a figure worklist from the `"nec"` fields and the renumbering file. Treat filenames as opaque ids (do not rename) |

**No edition finding in the speech code:** `speech_rules.gd` reads any 2–3-digit section number generically,
`PREVIEW_TEXT` is edition-neutral, and clips are regenerated from the bank. Changed text re-records
automatically through `audit_bundle.py` and `test_bundle.gd`.

### 4.3 Other magic values, duplication and dead code

| ID | Where | Sev | Finding | Fix |
|---|---|---|---|---|
| M01 | `project.godot:19`; `export_presets.cfg:22-23, 50-51, 69, 80-81`; `src/app/main.gd:244` (fallback `"1.0.4"`); `tools/tests/test_project_settings.gd:58`; goldens; `README.md:7, 22-23`; `docs/RELEASE.md:4, 77` | C | The version is typed in about 12 places, and a test pins the literal | `tools/release/bump_version.py <ver>` rewrites all of them and increments `version/code`. The test checks that the presets equal `project.godot`, not a literal. Fallback `""` |
| M02 | `src/core/quiz_session.gd:17-19` (80/240/75) and `data/exam_blueprint.json:3-7` (`scored_items`, `minutes`, `pass_percent`, `unscored_*`; **never read**) and literal strings `desktop_layout.gd:513, 516`, `mobile_layout.gd:437, 440` ("80 scored questions • 240 minutes • 75%", "3:00 per scored item • 80 questions", simulator `bind(80, …)`); `src/fx/mode_badge.gd:42` (`/ 80.0`); `main.gd:1087, 1099, 1105, 1112` ("TARGET: 75%", 75.0, 60.0, "BELOW 75%"); `src/fx/result_gauge.gd:15`; `test_question_deck.gd:104` | C | Three sources for the exam format | `QuizSession` constants come from `ExamBlueprint` (`minutes()`, `pass_percent()`); strings are formatted. The "at risk" band becomes a blueprint field or `pass - 15` |
| M03 | `desktop_layout.gd:503-507`, `mobile_layout.gd:428-432`, `main.gd:704, 709` | C | "30/60/90/120/150 minutes timed" typed next to `_practice_time()`, which computes the same values | Format from `_practice_time(n)`. One `DRILL_SIZES := [10, 20, 30, 40, 50]` (also `test_shuffle.gd` `MODES`) |
| M04 | both layouts' menu blocks | C | The same 8 menu entries listed twice with different size parameters | A data-driven menu spec in `Widgets` (fold into 54-plan B9) |
| M05 | `tools/verify.sh:24`, `tools/pipeline/build_question_bank.sh:63`, `tools/release/make_release.py:56`, `tools/branding/build_branding.py:47`, `.github/workflows/verify.yml:27-41`, docs | C | `Godot_v4.7.2-stable_win64_console.exe` repeated | `tools/godot.env` (`GODOT_VERSION=4.7.2`) sourced by the shell scripts and CI; Python reads the same file |
| M06 | `pipeline_paths.py:10` | C | Default scratch folder `%TEMP%\opencode`, named after an old tool | `%TEMP%\wire_pipeline` (see X12) |
| M07 | `nec_reference.gd:40` and `:104-108`; `chapter_bars.gd:38-47`; `build_question_bank.py:1948` (dead); the primary-article regex in `nec_reference.gd:48`, `validate_question_bank.py:278` and `build_question_bank.py:~2286` | C | Article-to-chapter logic 4× and the primary-citation regex 3× | One function per language plus a parity test (the validator already mirrors GDScript on purpose; document the pairs) |
| M08 | `src/core/bank_loader.gd:49-72` | C | Legacy fallbacks (`choices`, `answer`, array rows) that schema v2 never produces | Delete the array branch and the aliases; the validator guarantees the shape |
| M09 | `build_question_bank.py:94` (`difficulty`, unused by the app), `source_key` (removed in the working tree) | C | Dead fields and functions | See X11 and N12 |
| M10 | `build_question_bank.py` (≈2,300 lines, about 70% data), `main.gd` (1,313), `speech_controller.gd` (891), `validate_question_bank.py` (≈980), `answer_card.gd` (637) | C | Oversized files | Phases H and E shrink the builder to about 700 lines. The rest belongs to the 54-plan (D1–D4, E4) |
| M11 | `src/speech/voice_catalog.gd:8`, `src/speech/speak_question.py:34` | C | The default voice `en-US-AndrewNeural` is set in 2 languages | Read it from `data/voices.json` (`"default": true`) |
| M12 | about 53 `Color(` outside `AppTheme` (`answer_card.gd` 12, `diagram_view.gd` 7, `time_gauge.gd` 5, …) | C | Palette leaks | 54-plan A5 |

---

## 5. Target design

### 5.1 Files

```
data/
  app.json                  { "display_name": "NEC {year} Journeyman Challenge",
                              "file_stem": "NEC{year}JourneymanChallenge",
                              "company": "Live Wire Training",
                              "user_dir": "NEC2023JourneymanChallenge",       <- frozen, never follows the edition
                              "android_package": "com.livewire.nec2023.trainer", <- frozen (decision N02)
                              "legacy_project_names": ["NEC 2023 Journeyman Challenge"] }
  edition.json              { "year": 2023, "code": "NFPA 70", "short": "NEC 2023",
                              "long": "NFPA 70, National Electrical Code, 2023 Edition",
                              "dir": "nec/2023", "upcodes_slug": "nfpa-70-2023" }
  nec/2023/
    articles.json           <- git mv of data/nec_2023_articles.json
    provisions.json         <- REFERENCE_TEXTS / REFERENCE_TABLES / ANSWER_GLOSSARY (from the builder)
    tables.json             <- nec_calc.py constants
    renumbered.json         <- PRE_2023_SECTIONS
    content_audit.json      <- git mv of tools/pipeline/content_audit_2023.json
  exam_blueprint.json       + "edition", "exam_name", "authority"; read for minutes / pass / items
  question_bank.json        (generated)
tools/pipeline/sources/
  exams/<pdf stem>.json     transcript: questions, key, reference (import agent's format); absorbs exact_*/manual
  exams/families.json       optional: [{pattern, label, id_prefix}]  (default = today's two families)
  curated/<exam-id>.json    or question_bank_overrides.json: repairs, gists, scenes, formula, worked (id-keyed)
  ocr_fixes.json            header patterns, OCR replacements, option fixes
  ne_state_act_quiz3*.json  (unchanged)
```

- **GDScript:** `src/core/edition.gd` (`class_name Edition`, static, lazy-loads `edition.json`):
  `short_label()`, `long_label()`, `data_path(name)`. `NecReference`, the layouts, `ResultsView` and the tests
  use it.
- **Python:** `pipeline_paths.edition()` and `pipeline_paths.nec_data(name)`. The builder, validator,
  `nec_calc.py`, `spellcheck_bank.py` and the branding/showcase scripts use them.
- **Identity:** `tools/release/sync_identity.py` writes `config/name`, `config/description` and the four
  export-preset names and paths from `app.json` plus `edition.json`. It is idempotent.
  `test_project_settings.gd` fails if the files and the JSON disagree, so nobody hand-edits them.
- **App name:** derived as `display_name.format(year=edition.year)`. The **identifiers stay frozen:** the user
  folder, the Android package id and the record ids. Existing installs keep their settings and progress,
  and Android upgrades in place. Only the visible strings change.

### 5.2 Adding an exam (after the plan)

1. Copy `<name>.pdf` and `<name> answer key.pdf` into `exams_source_pdf/`. The name must match a family in
   `families.json` (by default the two current ones).
2. Optional but recommended: write `tools/pipeline/sources/exams/<name>.json` (the typed transcript) so the
   build does not depend on OCR quality.
3. `WIRE_BANK_OUT=<candidate> bash tools/pipeline/build_question_bank.sh --full`. This covers OCR if
   needed, the build, the validator, the speech dump, the recordings and the import.
4. The validator lists the new records as **pending content audit**, and verify fails until they are audited
   (X14 fix). Review each record against the edition's book, write the curated fields in the overrides, and
   add the audit entries.
5. Replace the checked-in bank with the reviewed candidate, run `verify.sh`, commit. **No code file changes.**

### 5.3 Switching to NEC 2026, step by step

**Automated or mechanical (after the plan):**

1. Tag the last 2023 build (`v1.x-nec2023`) and do the switch on a branch.
2. Create `data/nec/2026/`:
   - `articles.json` from the 2026 table of contents (typed from the book or UpCodes).
   - `renumbered.json`: the 2023→2026 relocations (the book's cross-reference and the NFPA "relocated
     sections" list).
   - `tables.json` with every value re-read from the 2026 book.
   - `provisions.json`, empty.
   - `content_audit.json`, empty.
3. Set `data/edition.json` to 2026 and run `sync_identity.py`. The app title, UI strings, breadcrumbs, release
   templates, validator messages and tests follow the edition. Regenerate the goldens and branding
   (placeholders keep most goldens unchanged).
4. Run `tools/pipeline/edition_migration_report.py` (new, PR E9). Per record it lists:
   - cited sections that do not exist in 2026 or were renumbered;
   - the suggested new citation from `renumbered.json`;
   - dependent calculations (`question_requirements.json`) and figures (`figures.json` `"nec"`);
   - blueprint-area changes;
   - records with no 2026 audit entry (all of them at first).
5. Optionally apply the suggested renumbering to the `article` fields and explanation citations as a
   candidate overrides diff, for human review. Never apply it unreviewed.
6. Rebuild. The validator's location rules now check against the 2026 table. The content-audit gate fails on
   every record until each has a 2026 entry, which makes the remaining manual work visible and countable.

**Manual (cannot be automated):**

- **Re-verify every NEC question against the 2026 text:** about 594 records after the current import. For
  each record:
  - confirm the keyed answer still holds;
  - re-quote `reference_text` / `reference_table` (and `provisions.json`) word for word from 2026;
  - fix the tip, choice notes, gist, formula and worked solution;
  - recompute calculations with the 2026 tables;
  - record the 2026 audit entry.
- **Decide what to do with source questions whose answer changed in 2026.** The practice PDFs were written
  for 2023 (or earlier). Options per question: re-key with a note, rewrite the stem, or retire it
  (`available: false`). Any change to the exam's own wording needs the user's decision.
- **Re-check all 48 original figures** against 2026. Section chips and dimensions may change.
- **Re-read the Nebraska/PSI bulletin:** which edition the exam uses, when Nebraska adopts 2026 (the 2023
  exam may accept either edition for a while), and whether the outline weights change.
- **Set the release timing, and choose between one edition per build and both editions side by side.** The
  design supports one edition per build. Shipping both means two bundles or a runtime edition switch;
  that is not recommended.
- **Rough effort:** about 5–10 minutes per record for the re-audit (roughly 50–100 hours for about 594
  records), plus figures, tables and a speech re-record. The tooling cannot remove this work; it only makes
  it visible and prevents any record from slipping through.

---

## 6. Implementation plan (small PRs)

Every PR runs `bash tools/verify.sh` (ALL CHECKS PASSED) and `validate_question_bank.py --no-warn`. PRs that
move data out of the builder also need a **byte-identical candidate bank**
(`WIRE_BANK_OUT=%TEMP%\qb.json`, then compare with `data/question_bank.json`). That needs the OCR cache or
transcripts for every exam.

**Wait markers:**

- **[after import]:** the file is claimed by the PDF-import agent (`build_question_bank.py`,
  `validate_question_bank.py`, `gists.py`, overrides, content audit, bank, harness, bank-size tests).
- **[after diagrams]:** claimed by the diagram-fix agent (`tools/diagrams/**`, `diagram_view.gd`, diagram
  tests, possibly the layout goldens).
- **[now]:** unclaimed files, but still post a claim on the board first.

### Phase H: new exams (goal a)

| # | PR | Files | Test | Wait |
|---|---|---|---|---|
| H0 | Land the PDF-import agent's discovery work (`exam_sources.py`, count-agnostic tests) | theirs | `test_exam_sources.py` | their PR |
| H1 | Remove the 70-question caps (X05); pass `question_count` into both parsers | `build_question_bank.py` | new fixture test: synthetic 80-question OCR and key text parse to 80 | after import |
| H2 | Explicit content-audit coverage for the shipped bank plus a `"pending"` status (X14) | `validate_question_bank.py`, its test | fixture with 1 audited and 3 unaudited records must warn | after import |
| H3 | Move the `manual` and seven `exact_*` lists into `sources/exams/<stem>.json` transcripts or corrections (X08) | builder, new JSON files | byte-identical bank; `test_exam_sources` checks the transcript schema | after import |
| H4 | Move `PROMPT_REPAIRS`, `QUESTION_REFERENCE_TEXTS`, `FORMULA_HINTS`, `WORKED_SOLUTIONS`, `GISTS` and `SCENES` to id-keyed data (X09) | builder, `gists.py` (deleted), overrides or `curated/` | byte-identical bank | after import |
| H5 | `ocr_fixes.json`; Tesseract from env or `which`; rename the OCR cache folder (X10, X12, M06) | OCR scripts, builder `normalize`, `pipeline_paths.py` | unit test: the `normalize` output is unchanged on a sample page | after import |
| H6 | `families.json` plus frozen `id_prefix` (X06, X07) | `exam_sources.py`, `state_law_source.py` | test: every shipped id survives a rebuild; an unknown PDF name gives a clear error | after import |
| H7 | Last pinned counts (X16); state-law count from sources | `harness.gd`, `test_no_leak.gd` | suites green | after import |
| H8 | Docs: "Add an exam" checklist in `DATA_PIPELINE.md`; count-free README and test docs (X18); merge `CHECKS` into requirements and add the warning (X20) | docs, `check_worked_solutions.py`, validator | `test_question_requirements` green | after import |

### Phase E: single edition source (goal b); start after both agents finish

| # | PR | Files | Test | Wait |
|---|---|---|---|---|
| E1 | `data/edition.json`, `src/core/edition.gd`, `pipeline_paths.edition()`; nothing uses them yet | 3 new files | new `test_edition.gd` and a Python unit test | now (new files only) |
| E2 | `git mv` the articles file to `data/nec/2023/articles.json` and the content audit to `data/nec/2023/content_audit.json`; update the readers (N04, N07, N08) | `nec_reference.gd`, builder, validator, docs | byte-identical bank; `test_nec_reference`, `test_breadcrumb` | after import |
| E3 | UI and breadcrumb strings from `Edition` (N05); tests build expected strings from `Edition` (N17) | layouts, `widgets.gd`, `main.gd`, `results_view.gd`, `nec_reference.gd`, tests | goldens **unchanged** (same text); pixel-identical shots | after diagrams (goldens) |
| E4 | Validator and builder: edition-formatted messages; `renumbered.json` (N09); generic `(\d{4} NEC)` pattern and year-free annotations (N10); delete the dead `upcodes_url` (N12) | validator, builder, new JSON | `test_validate_question_bank` (fixture with an explicit edition) | after import |
| E5 | `data/nec/2023/tables.json`; `nec_calc.py` loads it; delete the duplicate tables in `check_worked_solutions.py` (N13) | 2 `.py` files, new JSON | `test_question_requirements` unchanged | after import |
| E6 | Provision text and tables to `data/nec/2023/provisions.json`; concept tips to `data/concepts.json` (N11) | builder, new JSON | byte-identical bank | after import (after H3/H4) |
| E7 | Identity: `data/app.json`, `sync_identity.py`, release templates (N01, N02, N15); `LEGACY_*` in `UserDirMigration` (N03); freeze the folder and package id | `project.godot`, `export_presets.cfg`, `tools/release/*`, `user_dir_migration.gd`, tests | `test_project_settings` checks JSON = files; `test_user_dir_migration` covers the renamed legacy folder | now (post a claim; diagrams agent claimed `project.godot` earlier for the release only) |
| E8 | `bump_version.py`; the version test compares files instead of a literal; golden placeholders for version and edition (M01, X17) | release tool, `test_project_settings`, `test_layout_tree` | a golden change is not needed on the next bump | after diagrams |
| E9 | `edition_migration_report.py` (dry run 2023→2023 must report 0 changes); blueprint `edition` field and mismatch warning (N14) | new tool, blueprint, validator | unit test with a small renumbering fixture | after import |
| E10 | Branding and showcase read the edition (N16) | `build_branding.py`, `make_showcase.py` | regenerated images are identical for 2023 | now |

### Phase M: cleanup (any time after its files are free; low risk)

| # | PR | Findings |
|---|---|---|
| M-a | Exam format from the blueprint; formatted menu and HUD strings; `DRILL_SIZES` (goldens unchanged) | M02, M03, N06 |
| M-b | Dead code: legacy loader branches, `difficulty` field | M08, M09, X11 |
| M-c | `tools/godot.env` single Godot version | M05 |
| M-d | Article-to-chapter and primary-citation helpers deduplicated with a parity test | M07, N19 |
| M-e | Default voice from `voices.json` | M11 |
| then | 54-step plan from P0.2 (re-baselined), minus E3 and the E5 constants; M04 inside B9, M12 as A5 | M04, M10, M12 |

**Order and stop points:**

- After **H0–H2**, adding exams is safe (nothing is dropped and the audit gate is honest).
- After **H3–H6**, adding an exam needs no code at all.
- After **E1–E8**, the 2026 switch is a data change plus the manual re-audit.
- **E9** gives the 2026 worklist.
