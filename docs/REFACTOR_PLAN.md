# REFACTOR PLAN — project organization + `main.gd` decomposition

**Status:** Phase 1 (audit + plan) only. Nothing in the project has been moved, edited or deleted.
**Audited:** 2026-09-26 ~23:15, while another agent was still editing `main.gd`, `speech_rules.gd`,
`speech_text.gd`, `audio_settings.gd`, `tools/speak_question.py`, `tools/pregenerate_speech.py`,
`tools/tests/*` and regenerating `speech/`. **Every line number below must be re-measured before
execution** (`rg -n '^(static )?func ' main.gd`).

**Hard constraints carried through every step**

1. `question_bank.json` content never changes. Every step that touches it (only a `git mv`) is
   checked with `git hash-object` before/after — the byte hash must be identical.
2. Desktop and mobile builders stay separate (ARCHITECTURE.md §2.4/§4.1). The desktop builder also
   carries a "do not restyle" note (`main.gd` ~812). This plan keeps that constraint; see §3.5 for
   why, and for the narrower thing that *is* safe to share.
3. The harness contract (§3.1) stays valid on `main` at every commit, or the harness is changed in
   the same commit.
4. Gate for every step: `bash tools/verify.sh` (parse + 12 unit suites + harness desktop + harness
   mobile + bank checks) **and** `python tools/validate_question_bank.py --no-warn` run from
   PowerShell (python is not on git-bash's PATH, so verify.sh silently skips stage 5 there), plus
   screenshots via `.audit_tmp/snap.gd` for any step that touches UI code.

---

## 1. Inventory

Git: 10 commits on the branch; working tree has 26 modified tracked files and ~40 untracked
(`audio_settings.gd`, `speech_rules.gd`, `fx/`, `sfx/`, `docs/`, many new tests/`.uid`s) — i.e. the
last several hours of work are **not committed**. Step 0 of execution commits them.

`.gitignore` already excludes: `.godot/`, `/Godot_v*.exe`, `/build/`, `*.apk/*.pck/*.exe/*.tmp`,
`/speech/`, `.vscode/`, `.audit_tmp/`, `tools/*.txt|*.png|anomalies.json|out_*.txt`, `__pycache__`.

Export presets (`export_presets.cfg`): all 3 presets use `export_filter="all_resources"` with
**empty include/exclude filters**. Consequences found:

- `tools/exam5_key_p1.png`, `exam5_key_p2.png`, `exam5_key_p2_hi.png` (1.8 MB, have `.import`
  files, confirmed in `.godot/imported/`) **ship inside the APK/PCK** as textures.
- All `tools/**/*.gd` (harness, tests, dump scripts) ship as scripts. Harmless but dead weight.
- `.audit_tmp/` is dot-prefixed → Godot does not scan it (no imports found). Safe.
- `.py`, `.md`, `.pdf` are not resources → not exported. **This matters:** `main.gd` runs
  `res://tools/speak_question.py` at runtime for desktop Edge TTS; in an exported build it falls
  back to `<exe_dir>/tools/speak_question.py` (the stale copy in `build/tools/`), and failing that
  writes out a **54-line Python heredoc embedded in `main.gd` (~3947–4000)** — a third, drifting
  copy of `speak_question.py`.

### 1.1 Root files

| Path | What it is | Referenced by | Verdict |
|---|---|---|---|
| `project.godot` | engine config, main scene `res://Main.tscn` | engine | **keep**, update `run/main_scene` on move |
| `export_presets.cfg` | Windows + Android Debug/Release | Godot export | **keep, edit**: add `exclude_filter` (§2.3) |
| `Main.tscn` | 1-node scene, `script=res://main.gd` (path, no uid) | project.godot, harness, snap.gd, test_main_headless | **move** → `scenes/main.tscn` |
| `main.gd` (+`.uid`) | 4,544 lines, ~150 member vars, ~190 funcs; everything | Main.tscn, test_safe_area (static `safe_area_margins`), test_bundle (`_bundled_speech_folder`, `BUNDLED_VOICE_ID`), harness | **rewrite by extraction** (§3) |
| `answer_card.gd` | `class_name AnswerCard` (PanelContainer), tap-vs-drag | main.gd, test_answer_card_input | **move** → `src/ui/` |
| `audio_explanation_generator.gd` | `class_name AudioExplanationGenerator`, redaction + lesson phrasing | main.gd, speech_text, 5 test suites | **move** → `src/speech/` |
| `audio_settings.gd` | `class_name AudioSettings`, modes/autoplay rules, `user://audio.cfg` | main.gd, harness, snap.gd, test_audio_settings | **move** → `src/core/` (other agent editing — wait) |
| `speech_rules.gd` | pronunciation rules, **no class_name**, preloaded | speech_text.gd, test_speech_rules | **move** → `src/speech/` (other agent editing — wait) |
| `speech_text.gd` | speech plan builder, **no class_name**, preloaded as `SpeechText` | main.gd, harness, dump_speech, test_bundle, 3 tests | **move** → `src/speech/` (other agent editing — wait) |
| `table_viewer.gd` | `class_name TableViewer`, table layout/highlight + its own `panel_style` | main.gd, tests | **move** → `src/ui/`; its `panel_style` becomes the single `AppTheme.panel_style` |
| `unit_matcher.gd` | `class_name UnitMatcher`, answer number/unit matching | speech_text, AEG, tests | **move** → `src/speech/` |
| `voice_visualizer.gd` | `class_name VoiceVisualizer` (Control) | main.gd | **move** → `src/ui/` |
| `question_bank.json` | 828 KB, 279 records, schema v2 — **the product** | main.gd, dump_speech, test_bundle, 6 test suites, ~15 python tools, build guard | **move** → `data/question_bank.json` (content frozen, `git mv`, hash-checked) |
| `voices.json` | Edge voice catalog for the desktop picker | main.gd `_load_voice_catalog`, `tools/export_voices.py` | **move** → `data/voices.json` |
| `ARCHITECTURE.md` | refactor design; baseline numbers stale (3,327 lines / 342 checks / 36-symbol surface — now 4,544 / 12 suites + harness / ~50 symbols) | FIX_PLAN, this plan | **rewrite** → `docs/ARCHITECTURE.md` describing the *result*, not the plan |
| `FIX_PLAN.md` | 17 fixed items (all DONE) + OPEN device-only list + harness gotchas | ARCHITECTURE | **stale → replace**: keep the OPEN list + gotchas in `docs/KNOWN_ISSUES.md`, the fixed list is git history (commits `77e2cf7`, `16589d5`, `3c5971f`…); delete the root file |
| `.gitignore` | see above | git | **keep, edit** (§2.3) |
| `Godot_v4.7.2-stable_win64.exe` | 172 MB editor, untracked | nothing in code (humans) | **user decision** (§1.6) |
| `Godot_v4.7.2-stable_win64_console.exe` | 194 KB console wrapper, untracked | `verify.sh`, `build_question_bank.sh`, CI (downloads to root) | **user decision**; if moved, verify.sh must honour `$GODOT` (it currently overwrites it — bug) |

### 1.2 Folders

| Path | What it is | Verdict |
|---|---|---|
| `fx/` | 8 scripts (`UiFx`, `Sfx`, `TimeGauge`, `StreakMeter`, `ResultGauge`, `ChapterBars`, `ModeBadge`) + 3 shaders; `ui_fx.gd` preloads `res://fx/*.gdshader`, `sfx.gd` loads `res://sfx/` | **move** → `src/fx/` (shaders → `src/fx/shaders/`); update 3 preload paths + verify.sh parse list |
| `sfx/` | 11 generated WAVs + `.import` + `CREDITS.md` (CC0, made by `tools/make_sfx.py`) | **move** → `assets/sfx/`; update `fx/sfx.gd` and `tools/make_sfx.py` output path |
| `speech/` | 279 folders `<qid>__en-US-AndrewNeural/` (≈7 mp3 + `.import` + `manifest.json`), ~69 MB, **gitignored**, currently being regenerated | **move** → `assets/speech/` *after* regeneration finishes; update `main.gd` (`res://speech`), `pregenerate_speech.py` (`ROOT/"speech"`), `test_bundle.gd`, `.gitignore`. Full re-import (~2k mp3) expected. See §1.6 re: fresh clones |
| `tools/` | pipeline + tests + one-offs + scratch | **reorganize** (§1.3) |
| `tools/tests/` | 12 GDScript suites, `t_report.gd` (`class_name TReport`), `run_all.gd`, `test_build_guard.sh`, `test_validate_question_bank.py`, README | **keep**; update `res://` paths per move |
| `tools/archive/` | `build_question_bank.pre-technical-rewrite.py` (210 KB, unreferenced) | **delete** (git history has it — confirm it was ever committed; if not, commit once then delete) |
| `docs/` | `VOICE_READING_RULES.md` (new, referenced by speech_text.gd) | **keep**; becomes home for all docs |
| `study_guides/` | 8 small tracked `.md` exam overviews, referenced by nothing | **user decision**: move → `docs/study_guides/` (default) or delete |
| `exams_source_pdf/` | 14 tracked PDFs (1.4 MB) — the ground truth the bank must match; OCR input | **keep**, move → `data/source_pdf/` or leave; add to export exclude (already not exported, but make it explicit) |
| `build/` | 361 MB, gitignored: `NEC2023JourneymanChallenge.apk` (+`.idsig`, Sep 25), `.exe` + `.pck` (Sep 25), `NEC…exe~RF1511c1a2.TMP` (104 MB Windows temp dup), `assets.sparsepck.fromapk`, `tools/speak_question.py` (stale copy, runtime dependency of the exported exe) | stale artifacts **delete** (regenerable by export); `build/tools/speak_question.py` is replaced by the export-time copy step (§3.4 S5) |
| `.audit_tmp/` | 671 MB scratch, gitignored: page PNGs, OCR text, NEC chapter text dumps, voice samples, a scraped website (`luv/`), probes, logs, **plus the live measurement scripts** `snap.gd`, `snap_all.gd`, `measure_fit.gd`, `auto_read_live.gd`, `dump_all_speech.gd`, `listen_trace.gd` | promote the 3 useful scripts to `tools/visual/` (snap.gd → `tools/visual/snap.gd`, writing to `.audit_tmp/shots/`), then **delete the rest** (user confirm, §1.6) |
| `.godot/` | editor cache (gitignored), contains ~4.4k stale imported mp3s from older voice folders | **delete the folder once after the moves** and let `--import` rebuild (cleans stale imports + class cache) |
| `.github/workflows/verify.yml` | CI: downloads Godot to repo root, runs verify.sh | **keep**; update if the console exe location / `$GODOT` changes |
| `.vscode/settings.json` | `{}`, gitignored | **delete** (empty) |

### 1.3 `tools/` script by script

References = who imports/runs it (grep of all non-scratch files).

| File | Purpose | Referenced by | Verdict |
|---|---|---|---|
| `verify.sh` | the gate | CI, docs | **keep**; fix `GODOT="${GODOT:-$ROOT/…}"`; parse-check list generated from `src/**/*.gd` instead of hand list |
| `harness.gd` (+uid) | scene regression suite | verify.sh | **keep** (§3.1) |
| `build_question_bank.sh` / `.py` | OCR→bank pipeline (guarded) | DATA_PIPELINE, build guard test | **keep** → `tools/pipeline/` |
| `validate_question_bank.py` | schema + spoiler gate | verify.sh, build.sh, tests | **keep** → `tools/pipeline/` |
| `bank_overrides.py`, `question_bank_overrides.json`, `refresh_question_bank_overrides.py`, `pipeline_paths.py`, `gists.py` | pipeline modules (imported by builder) | builder | **keep** → `tools/pipeline/` |
| `ocr_pdfs_tesseract.py`, `ocr_answer_keys_tesseract.py`, `compare_tesseract_keys.py` | OCR stage + key cross-check | build.sh / manual | **keep** → `tools/pipeline/` |
| `dump_speech.gd`, `pregenerate_speech.py`, `speak_question.py`, `test_bundle.gd`, `export_voices.py` | speech pipeline | build.sh, main.gd (speak_question) | **keep** → `tools/speech/` (other agent editing two of them — wait) |
| `make_sfx.py` | SFX synthesizer | sfx.gd comment, CREDITS | **keep** → `tools/sfx/make_sfx.py` |
| `DATA_PIPELINE.md` | pipeline doc | — | **move** → `docs/DATA_PIPELINE.md` |
| `test_main_headless.gd` | "does Main.tscn instantiate" — strict subset of harness | nothing | **delete** |
| `gists.bak.py` | backup of gists.py | nothing (tracked!) | **delete** |
| `validate_question_bank.py.bak` | backup of validator | nothing (tracked!) | **delete** |
| `apply_code_updates.py`, `apply_missing_references.py` (+`missing_references_data.py`), `update_explanations.py`, `apply_gist_corrections.py`, `fix_literal_language.py`, `fix_memory_tips.py` | **one-shot mutation scripts that write `question_bank.json` in place** — their effect is now captured in `question_bank_overrides.json`; DATA_PIPELINE already warns "do not run blindly" | nothing live (fix_memory_tips / fix_literal_language only mentioned in comments) | **delete** (dangerous: they bypass the build guard and could change the bank). Git history keeps them |
| `audit_code_provisions.py`, `check_missing_refs.py`, `deep_audit.py`, `dump_tables.py`, `find_anomalies.py`, `inspect_tables.py`, `list_missing_explanations.py`, `print_31.py`, `print_anomalies.py` | ad-hoc read-only probes superseded by `validate_question_bank.py` | nothing | **delete** |
| `anomalies.json`, `exam5_key_*.png/.txt/.import`, `exam5_key_text.txt`, `out_31.txt`, `tables_out.txt` | OCR scratch (gitignored, but PNGs ship in exports) | nothing | **delete** |
| `__pycache__/`, `tests/__pycache__/` | bytecode (3 Python versions) | — | **delete** (ignored anyway) |

### 1.4 Dead / duplicated code found

- `main.gd` consts `EXAM_NON_SCORED_ITEMS`, `EXAM_NON_SCORED_MINUTES`: declared, never read → delete
  (or surface in the menu copy if the product wants them — they describe the real exam).
- `main.gd` embedded Python heredoc (~3943–4000) duplicates `tools/speak_question.py` → delete,
  replace with one shipped copy (§3.4 S5).
- `main.gd` `_panel_style`, `_ui_font`, `_monospace_font` duplicate `TableViewer.panel_style` and
  `answer_card.gd`'s font setup → one `AppTheme`.
- `speech_text.gd` `format_answer_number`, `answer_match_candidates`, `prompt_intent`, `plain_words`,
  `lesson_point`, `prompt_with_answer`, `answer_sentence`, `spoken_fraction`: now thin forwarders to
  `UnitMatcher` / `AudioExplanationGenerator` / `speech_rules`. Once the other agent is done, grep
  callers and point them at the owner; delete forwarders with zero external callers. **Spoken output
  must be byte-identical** — verify with `.audit_tmp/dump_all_speech.gd` before/after diff (0 lines).
- 73 `is_instance_valid` guards in `main.gd` (was 42). Keep verbatim during moves; many exist only
  because desktop-only nodes (`prompt_visualizer`, `prompt_voice_badge`, `key_hint_label`,
  `answers_row`, `ref_column`) are null on mobile. Document, don't remove, in this refactor.
- Static unused-symbol scan of `main.gd` (all funcs/vars/consts vs. every non-scratch `.gd`,
  counting string callbacks): only the 2 consts above are dead. No dead functions — the earlier
  FIX_PLAN cleanup was thorough.
- Tracked backups: `tools/gists.bak.py`, `tools/validate_question_bank.py.bak`.

### 1.5 Magic values to centralize

- 335 hex colour literals, 79 unique, in `main.gd` alone. Top: `38bdf8`×54 (accent), `7dd3fc`×16,
  `ffffff`×14, `0284c7`×13, `cbd5e1`×13, `1e3a5f`×12, `111928`×12, `1e293b`×9, `34d399`×9 (ok),
  `94a3b8`×8 (muted), `6ee7b7`×8, `f8fafc`×7, `f43f5e`×6 (bad). Plus the same palette in
  `answer_card.gd`, `table_viewer.gd`, `fx/*`.
- 82 `add_theme_font_size_override` with literal sizes; 77 `_panel_style(...)` calls with literal
  radii/widths; `FIT_*` arrays are already named (good pattern to follow).
- Timings: 600 ms back debounce, 4.0 s native-voice refresh, 1.0 s timers, watchdog ≥6 s.

→ `src/ui/app_theme.gd` (`class_name AppTheme`): named colours (`ACCENT`, `ACCENT_SOFT`, `ACCENT_DEEP`,
`TEXT`, `TEXT_MUTED`, `PANEL_BG`, `PANEL_BORDER`, `OK`, `OK_SOFT`, `BAD`, `BG_TOP`, `BG_BOTTOM`…),
`panel_style()`, `ui_font()`, `monospace_font()`, `focus_ring()`. Substitution is literal-for-literal,
so pixels do not change (screenshot diff must be empty).

Naming inconsistencies: `Main.tscn` vs `main.gd` casing; root node named `LiveWireTrivia` while the
app is "NEC 2023 Journeyman Challenge"; `_do_render_info_label` (no non-`_do` sibling);
`speech_text.gd`/`speech_rules.gd` lack `class_name` while every sibling has one.

### 1.6 Needs user confirmation before deletion

| Item | Size | Why ask | Default proposal |
|---|---|---|---|
| `Godot_v4.7.2-stable_win64.exe` (editor) | 172 MB | you launch it from here | move to `C:\Tools\Godot\` (or keep in root — it is already gitignored and not exported) |
| `Godot_v4.7.2-stable_win64_console.exe` | 194 KB | verify.sh/CI expect it in root | keep in root, **or** move with the editor and set `GODOT` env var (after the verify.sh fix) |
| `exams_source_pdf/` | 1.4 MB, tracked | ground truth for the bank | **keep** (move to `data/source_pdf/`) — not a deletion candidate unless you say so |
| `study_guides/` | 8 KB, tracked, unreferenced | may be yours | move to `docs/study_guides/` |
| `.audit_tmp/` (all but promoted scripts) | 671 MB | has your voice samples (`voice_samples/`, `luvvoice_dylan_marlow_original.mp3`), research renders, before/after screenshots | delete everything except `shots/` of the final state and anything you want to keep from `voice_samples/` |
| `build/` artifacts | 361 MB | last shipped APK/EXE (Sep 25) | delete; re-export when needed |
| One-shot bank mutation scripts (§1.3) | ~120 KB, tracked | historical record of how the bank was curated | delete (git history keeps them) |
| `FIX_PLAN.md` fixed-items list | 10 KB | history | fold into git history + `docs/KNOWN_ISSUES.md` |
| `speech/` in git? | 69 MB | currently gitignored, but it **ships in the app**; a fresh clone cannot export without a network regeneration | decide: keep ignored (status quo) or track via Git LFS |

---

## 2. Target structure

```
res://
├─ project.godot                 run/main_scene = res://scenes/main.tscn
├─ export_presets.cfg            + exclude_filter (see 2.3)
├─ README.md                     short: what it is, how to run, verify, export (new, ~40 lines)
├─ .gitignore  .github/
├─ scenes/
│  └─ main.tscn                  (renamed from Main.tscn; root node renamed "Main")
├─ src/
│  ├─ app/
│  │  ├─ main.gd                 composition root + harness facade (~900–1,200 lines at the end)
│  │  ├─ desktop_layout.gd       _build_ui body, verbatim  (DesktopLayout, static build(host))
│  │  └─ mobile_layout.gd        _build_mobile_ui body, verbatim (MobileLayout, static build(host))
│  ├─ core/                      node-free, unit-testable
│  │  ├─ quiz_session.gd         QuizSession  (order/score/streak/timing/verdicts/missed/chapter_stats)
│  │  ├─ bank_loader.gd          BankLoader   (_load_bank/_normalize_record)
│  │  ├─ nec_reference.gd        NecReference (article titles, lookup path, chapter-only path)
│  │  ├─ safe_area.gd            SafeArea     (static safe_area_margins, tested today)
│  │  └─ audio_settings.gd       AudioSettings
│  ├─ speech/
│  │  ├─ speech_controller.gd    SpeechController (Node): thread, queue, bundle lookup, player, native TTS
│  │  ├─ voice_catalog.gd        VoiceCatalog: voices.json, native voice tiers/labels, voice.cfg
│  │  ├─ speech_text.gd  speech_rules.gd  audio_explanation_generator.gd  unit_matcher.gd
│  │  └─ speak_question.py       single copy, shipped via include_filter (see S5)
│  ├─ ui/
│  │  ├─ app_theme.gd            AppTheme: palette + style/font factories
│  │  ├─ widgets.gd              Widgets: _add_mode_button/_make_dock_button/_make_chip/_make_voice_picker/_audio_row_label
│  │  ├─ info_panel_renderer.gd  InfoPanelRenderer: _do_render_info_label + helpers (RichTextLabel)
│  │  ├─ audio_section.gd        menu audio settings block + handlers
│  │  ├─ results_view.gd         _show_results/_show_listen_results/_show_results_visual/confetti
│  │  ├─ answer_card.gd  table_viewer.gd  voice_visualizer.gd
│  └─ fx/
│     ├─ ui_fx.gd sfx.gd time_gauge.gd streak_meter.gd result_gauge.gd chapter_bars.gd mode_badge.gd
│     └─ shaders/ card_shine.gdshader circuit_backdrop.gdshader electric_title.gdshader
├─ data/
│  ├─ question_bank.json         byte-identical move
│  ├─ voices.json
│  └─ source_pdf/                (exams_source_pdf, if you agree)
├─ assets/
│  ├─ sfx/*.wav  CREDITS.md
│  └─ speech/<qid>__<voice>/     generated, gitignored
├─ docs/
│  ├─ ARCHITECTURE.md  DATA_PIPELINE.md  VOICE_READING_RULES.md  KNOWN_ISSUES.md  REFACTOR_PLAN.md
│  └─ study_guides/
└─ tools/
   ├─ verify.sh  harness.gd
   ├─ pipeline/   build_question_bank.{sh,py} validate_question_bank.py bank_overrides.py
   │              question_bank_overrides.json refresh_question_bank_overrides.py pipeline_paths.py
   │              gists.py ocr_*.py compare_tesseract_keys.py
   ├─ speech/     dump_speech.gd pregenerate_speech.py export_voices.py test_bundle.gd
   ├─ sfx/        make_sfx.py
   ├─ visual/     snap.gd snap_all.gd measure_fit.gd  (outputs to .audit_tmp/)
   └─ tests/      (unchanged layout)
```

Why this shape: Godot 4 has no enforced layout, but `scenes/` + `src/` (by feature) + `assets/` +
`data/` is the common idiom, keeps the root to config files, and puts every node-free script in
`core/` where it can be unit-tested without `Main.tscn`. `src/` subfolders by *responsibility* rather
than by node type, so the speech stack lives together.

### 2.1 Godot mechanics for the moves

- Move each script **with its `.uid`** (and each asset with its `.import`). Godot 4.4+ resolves
  `uid://` references regardless of path; our code uses `res://` paths, so every `preload/load`
  string must be updated too (list below). Do moves with `git mv` so history follows.
- `class_name` scripts are found through `.godot/global_script_class_cache.cfg`; after moving, run
  `Godot_…console.exe --headless --path . --import` (or `--editor --quit`) to rebuild it, otherwise
  `AudioSettings`/`AnswerCard`/… fail to resolve in `--script` runs.
- `Main.tscn` references `res://main.gd` by path only (no uid) → edit `ext_resource path`.
  `project.godot` `run/main_scene` must follow.
- Moving mp3/wav re-imports them (import hash includes the path). Delete `.godot/` once after the
  asset moves to also drop ~4k stale imports from old voice folders.
- Python tools moved one level deeper: `Path(__file__).resolve().parents[1]` → `parents[2]` in
  `build_question_bank.py`, `validate_question_bank.py`, `refresh_question_bank_overrides.py`,
  `compare_tesseract_keys.py`, `ocr_*.py`, `pregenerate_speech.py`, `export_voices.py`,
  `make_sfx.py` (`dirname(dirname(...))`), `test_build_guard.sh` (`../..` → `../../..`) — better:
  one `tools/paths.py`-style constant per package (`pipeline_paths.py` already exists; extend it
  with `ROOT`, `BANK`, `VOICES`, `SPEECH_DIR`) so the next move is a one-line change.

### 2.2 Every path string that changes

| Old | New | Files that reference it |
|---|---|---|
| `res://Main.tscn` | `res://scenes/main.tscn` | project.godot, harness.gd, tools/visual/*.gd |
| `res://main.gd` | `res://src/app/main.gd` | main.tscn, test_safe_area.gd (→ `SafeArea` after S3), test_bundle.gd (→ `SpeechController` after S8) |
| `res://speech_text.gd` | `res://src/speech/speech_text.gd` | main.gd, harness.gd, dump_speech.gd, test_bundle.gd, test_speech_text, test_speech_rules, test_audio_explanation_generator |
| `res://speech_rules.gd` | `res://src/speech/speech_rules.gd` | speech_text.gd, test_speech_rules |
| `res://audio_explanation_generator.gd` / `unit_matcher.gd` / `table_viewer.gd` | `res://src/…` | 6 test suites (preload by path) |
| `res://fx/*.gdshader` | `res://src/fx/shaders/*` | ui_fx.gd |
| `res://sfx/` | `res://assets/sfx/` | fx/sfx.gd, make_sfx.py, test_sfx.gd |
| `res://speech` | `res://assets/speech` | main.gd (→ SpeechController), pregenerate_speech.py, test_bundle.gd, .gitignore `/speech/` |
| `res://question_bank.json` | `res://data/question_bank.json` | main.gd `BANK_PATH`, dump_speech.gd, test_bundle.gd, test_fx, test_no_leak, test_speech_rules, test_speech_text, test_table_viewer, test_unit_matcher, every pipeline py (via paths module), build.sh, test_build_guard.sh, validator default, DATA_PIPELINE.md |
| `res://voices.json` | `res://data/voices.json` | main.gd, export_voices.py |
| `res://tools/speak_question.py` | `res://src/speech/speak_question.py` | main.gd, pregenerate_speech.py (`from speak_question import …` → sys.path), export_voices.py, VOICE_READING_RULES.md |
| hand list in verify.sh parse stage | `find src -name '*.gd'` | verify.sh |

Tests that preload by path should prefer the `class_name` where one exists (`TableViewer`,
`UnitMatcher`, `AudioExplanationGenerator`) — removes most of the rows above permanently. Giving
`speech_text.gd` / `speech_rules.gd` a `class_name` (`SpeechText`, `SpeechRules`) requires deleting
the `const SpeechText = preload(...)` lines in the same commit (a const named like a global class
shadows it — error or warning depending on settings; don't leave it to chance).

### 2.3 Keep out of git / out of exports

`.gitignore` additions: `/tools/**/__pycache__/`, `*.bak`, `*.bak.*`, `/assets/speech/`
(replacing `/speech/`), `/.audit_tmp/` (anchor), `*.TMP` already there. Remove the now-moot
`tools/*.png` rules once those files are gone (keep `/tools/**/*.png` to be safe).

`export_presets.cfg`, all three presets:

```
include_filter="src/speech/speak_question.py"        ; desktop preset only
exclude_filter="tools/*,docs/*,data/source_pdf/*,exams_source_pdf/*,study_guides/*,build/*,*.md"
```

Verify with a real export + listing the PCK (`--export-pack` then check size drops by ≥1.8 MB and
no `tools/` paths; Android: `unzip -l` on the APK `assets/`).

---

## 3. `main.gd` decomposition

### 3.1 Harness / test contract (must stay valid on `main`)

**`tools/harness.gd`** reads/writes/calls on `main`:

- State: `records order current_index score streak answered_count current_answered missed_questions
  session_length time_left timed_session timer chapter_stats`
- Const: `SESSION_TIME_SECONDS`
- Speech: `speak_thread speak_busy speak_generation speech_queue speech_queue_index teach_from_index
  want_teach`
- Audio: `audio audio_cfg_path session_audio_mode session_muted listen_phase listen_paused _auto_token`
- Nodes: `answers_box read_button menu_overlay pause_button skip_button`
- Methods: `_start_quiz _show_question _answer_selected _next_question _show_results _tick_timer
  _show_menu _stop_reading _play_speech_clip _on_speech_ready _exit_tree _idle_read_label
  _toggle_session_mute _toggle_listen_pause _listen_skip` (+ `has_method("_join_speak_thread")`)

**`.audit_tmp/snap.gd` (→ `tools/visual/snap.gd`)** additionally: `_on_audio_mode_picked
_on_sfx_level_picked _toggle_audio_section _refresh_dock_audio _show_listen_countdown
_listen_countdown _listen_timer _native_seg _native_segments reader read_status_label voice_picker
feedback_panel audio_expanded ui_mobile`.

**`tools/test_bundle.gd`**: `main.gd.new()._bundled_speech_folder(...)`, `BUNDLED_VOICE_ID`.
**`tools/tests/test_safe_area.gd`**: `load("res://main.gd").safe_area_margins(...)` (static).

Facade rule: when a member moves into a component, `main` keeps a same-named **property with
get/set forwarding** (GDScript 4 `var x: T: get: return session.x; set(v): session.x = v`) and a
same-named **method that forwards**. The harness keeps passing unchanged; a later, separate commit may
migrate the harness to the component API and drop the facade. Note: several harness lines *write*
state (`main.order.clear()`, `main.speech_queue.append`, `main.speak_generation += 1`) — forwarding
properties must return the component's actual Array/Dictionary instance (not a copy) so in-place
mutation still lands.

### 3.2 Responsibility map (lines as of the audit; re-measure)

| Lines | Responsibility | Target |
|---|---|---|
| 1–177 | 14 consts, ~150 member vars (domain + ~90 node refs + audio/listen/fit state) | split per component; node refs stay on main (builders assign them) |
| 179–213 | speech thread lifecycle `_exit_tree/_join_speak_thread/_start_speak_thread` | SpeechController (main keeps `_exit_tree` forwarding) |
| 214–249 | `_ready` composition | stays, shrinks |
| 250–330 | fx attach, focus ring, `_polish_controls`, key hint | main (chrome), `focus_ring` → AppTheme |
| 331–534 | adaptive fit (`_fit_*`, side-by-side, compact answered, time gauges, answer fx) | `src/ui/fit_controller.gd` (late step; layout-sensitive) |
| 535–642 | safe area + `static safe_area_margins` | `core/safe_area.gd` (static part), apply stays |
| 643–693 | `_load_bank/_normalize_record` | `core/bank_loader.gd` |
| 694–769 | `_article_title/_format_nec_reference/_lookup_navigation_path` | `core/nec_reference.gd` |
| 770–807 | `_start_quiz` | QuizSession.begin + main render |
| 808–1482 | **desktop builder** (675) | `app/desktop_layout.gd` verbatim |
| 1483–2075 | **mobile builder** (593) | `app/mobile_layout.gd` verbatim |
| 2076–2242 | widget factories used by both builders | `ui/widgets.gd` |
| 2243–2562 | menu audio section UI + handlers, sfx setup, speech bus, preview, dock audio, mute | `ui/audio_section.gd` (+ Sfx wiring stays in main) |
| 2563–2690 | auto-read scheduling + listen-mode loop (`_listen_*`, `_on_playback_complete`) | `speech/listen_loop.gd` or inside SpeechController (decide at step) |
| 2691–2731 | menu `_show_menu`, `_practice_time` | main |
| 2732–2751 | `_panel_style/_ui_font/_monospace_font` | AppTheme |
| 2752–2792 | reference-table helpers | InfoPanelRenderer / presenter |
| 2793–2933 | `_show_question`, `_gist_task_sentence` | main (render) + NecReference/QuizSession (pure bits) |
| 2934–3132 | `_answer_selected`, `_scroll_to_verdict`, `_update_score_badges` | QuizSession.submit (verdict, score, missed, chapter_stats) + main render |
| 3133–3325 | info panel rendering (memory tip, code provision, lesson lines) | `ui/info_panel_renderer.gd` |
| 3326–3512 | voice catalog + picker (Edge + native), voice.cfg | `speech/voice_catalog.gd` + picker UI stays |
| 3513–3721 | read control, bundled clip lookup, read status | SpeechController |
| 3722–3879 | native Android TTS (3 `Callable(self, …)` callbacks at ~3731) | SpeechController (callbacks become `Callable(speech, …)`) |
| 3880–4152 | Edge worker thread, cache match, `_on_speech_ready`, `_play_speech_clip`, player | SpeechController; heredoc 3943–4000 deleted |
| 4153–4230 | touch filters, speech highlight, stem glow | main (touch), highlight → presenter |
| 4231–4284 | `_tick_timer`, `_format_time`, `_next_question`, exam tint | QuizSession.tick(speech_idle) + main render |
| 4285–4472 | results (graded, listen, gauges, confetti) | `ui/results_view.gd` |
| 4473–4544 | error screen, back button (600 ms debounce), keyboard input, next button | main |

### 3.3 Proposed components

| Component | Base | Node-free | Host refs | Notes |
|---|---|---|---|---|
| `AppTheme` | RefCounted (static) | yes | 0 | palette + factories; also used by answer_card, table_viewer, fx |
| `NecReference` | RefCounted (static) | yes | 0 | pure string/regex |
| `BankLoader` | RefCounted (static) | yes | 0 | returns `Array`; main keeps `records` |
| `SafeArea` | RefCounted (static) | yes | 0 | test_safe_area switches to it (+ keep main static forwarder one step) |
| `QuizSession` | RefCounted | yes | 0 | state + `begin/submit/advance/tick(speech_idle)`; first node-free harness test |
| `VoiceCatalog` | RefCounted | mostly | 0 | voices.json, native tiers/labels, voice.cfg |
| `Widgets` | RefCounted (static) | no | 0 | factories take explicit sizes; used by both layouts |
| `DesktopLayout` / `MobileLayout` | RefCounted (static `build(host)`) | no | writes host's node vars | **verbatim move**: `x = Label.new()` → `host.x = Label.new()`; no restyle |
| `InfoPanelRenderer` | RefCounted | no | RichTextLabel + record | keeps redaction call order |
| `AudioSection` | Node/Control helper | no | ~12 | menu audio block |
| `ResultsView` | RefCounted | no | ~10 | results + gauges + confetti |
| `SpeechController` | Node child of main | no | ~8 (read_button, read_status_label, dock/prompt visualizers, voice badge, info_label, answers_box) | highest risk, needs device check |

### 3.4 Why the builders stay separate (and what is shared)

Unchanged conclusion from ARCHITECTURE.md §1.2(b)/§4.1, re-checked: the builders build the same
member set with different metrics/order and *zero* shared text; the desktop one is explicitly frozen
visually. Unifying needs a node-tree golden test that does not exist. What this plan does instead:
(a) move each builder verbatim into its own file so `main.gd` loses ~1,270 lines with no behavioural
change; (b) centralize colours/fonts/panel styles both already call; (c) route both through the
existing shared factories in `Widgets`. A unified builder remains a separate, optional project,
gated on first adding a tree-serialization golden test (type/path/size flags/stylebox fill per node,
both layouts) — that test is cheap and is worth adding in step S7 regardless.

---

## 4. Execution steps (each = one commit, each gated)

Gate G = `bash tools/verify.sh` → `ALL CHECKS PASSED` **and** (PowerShell)
`python tools/validate_question_bank.py --no-warn` → 0 errors/0 warnings **and**
`git hash-object question_bank.json` unchanged (value recorded at S0). UI steps add
G+shots = `Godot…console.exe --path . --script tools/visual/snap.gd` (and `-- --mobile-ui`) and
compare against the S0 baseline shots (pixel-identical expected unless noted).

| # | Step | Risk | Gate |
|---|---|---|---|
| **S0** | Wait for the other agent. Commit its work as-is. Record baseline: verify output, bank hash, snap shots (desktop+mobile), speech dump (`dump_all_speech.gd`), PCK file list. | none | G |
| **S1** | Garbage removal (no code change): delete tracked backups (`gists.bak.py`, `validate_question_bank.py.bak`), `test_main_headless.gd`, `tools/archive/`, read-only probe scripts, one-shot bank mutators, tools scratch (png/txt/json), `__pycache__`, empty `.vscode/`. Promote `snap.gd`/`snap_all.gd`/`measure_fit.gd` to `tools/visual/`. User-confirmed items (§1.6) only after an explicit yes. | low (grep proved no refs) | G |
| **S2** | Hygiene: `.gitignore` additions, export `exclude_filter`, `verify.sh` honours `$GODOT` + auto parse list, delete `EXAM_NON_SCORED_*` (or wire them), docs: `FIX_PLAN.md` → `docs/KNOWN_ISSUES.md`, `tools/DATA_PIPELINE.md` → `docs/`, README.md. | low | G + export listing |
| **S3** | Folder moves, scripts: `git mv` every `.gd`+`.uid` into `src/…`, `Main.tscn` → `scenes/main.tscn`, shaders, update every path in §2.2 (GDScript side), `--import`, delete `.godot/`, reimport. | medium (path typos) — the parse stage + harness catch all of them | G + shots |
| **S4** | Data/asset moves: `question_bank.json`, `voices.json` → `data/`; `sfx/` → `assets/sfx/`; `speech/` → `assets/speech/` (only after regeneration is finished); python paths via one paths module; `test_build_guard.sh`; pipeline scripts → `tools/pipeline|speech|sfx/`. | medium; bank hash check is mandatory here | G + `bash tools/pipeline/build_question_bank.sh --validate` + `test_bundle.gd` = 279/279 |
| **S5** | Single `speak_question.py`: move to `src/speech/`, ship via desktop `include_filter`, at runtime copy `res://…/speak_question.py` → `user://speech/speak_question.py` once (FileAccess can read from the PCK), run that; delete heredoc and `exe_dir/tools` fallback. | medium; desktop Edge TTS only — test in an **exported** exe with the bundle folder renamed | G + manual exported-exe Read test |
| **S6** | `AppTheme` + `NecReference` + `BankLoader` + `SafeArea` (pure statics). Literal-for-literal palette substitution in main, answer_card, table_viewer, fx. Add unit suites `test_app_theme`, `test_nec_reference`, `test_bank_loader`. | low | G + shots identical |
| **S7** | Add node-tree golden test (`tools/tests/test_layout_tree.gd`: serialize both builders' trees, compare to a checked-in snapshot). Then move `_build_ui`/`_build_mobile_ui` verbatim into `DesktopLayout`/`MobileLayout`, and the shared factories into `Widgets`. | medium-low (text move with `host.` prefix) — golden test makes it provable | G + golden + shots |
| **S8** | `QuizSession` (pure) with forwarding properties on main; node-free `test_quiz_session.gd` incl. "clock does not tick while speech busy". | moderate (verdict branch order; `score+missed==answered` invariant guards it) | G |
| **S9** | `InfoPanelRenderer`, `ResultsView`, `AudioSection` extractions. | moderate (layout) | G + shots |
| **S10** | `VoiceCatalog` (pure part), then `SpeechController` bite 1 (pure bundle/cache/status funcs), then bite 2 (thread, queue, player, native TTS; `Callable(self,…)` → `Callable(speech,…)`). Harness speech members forwarded. | **high** — FIX_PLAN items 1–4, 10–13 live here | G + speech-dump diff 0 + **on-device Android** Read/Stop/Read-again, teach gate, voice refresh |
| **S11** | Optional: migrate harness/snap to component APIs, drop facades; `speech_text.gd` forwarder cleanup (spoken output byte-identical). Rewrite `docs/ARCHITECTURE.md` to describe the final layout. | low–moderate | G + speech-dump diff 0 |

Stop points: S1–S6 are safe to land in one sitting and deliver the "organized project" the request
asks for. S7–S9 deliver most of the `main.gd` shrink. S10 needs a phone; don't ship it on headless
evidence alone.

### 4.1 Risk notes

- **Concurrent edits:** do not start S1 until the other agent has finished and S0 is committed; the
  moves in S3/S4 would otherwise collide with its in-flight edits and speech regeneration.
- **Path typos** after moves fail loudly (parse stage / `preload` errors) — good. The quiet failure is
  a `load()` of a data path returning null → harness `records == 279` catches the bank; `voices.json`
  has no test → add `check(main.voice_ids.size() > 0)` to the harness in S4.
- **class cache**: forgetting `--import` after S3 makes every `--script` run fail on unknown classes;
  verify.sh should run `--import` first (add to stage 1).
- **Speech bundle move** invalidates nothing semantically (manifests hold filenames, not paths), but
  triggers a long re-import; run `test_bundle.gd` → `BUNDLE_HITS=279/279`.
- **Exports**: confirm Android build still contains `data/question_bank.json`, `data/voices.json`,
  `assets/speech/**`, `assets/sfx/**` after adding `exclude_filter` (`*.md` exclusion must not catch
  anything under `assets/`; `sfx/CREDITS.md` is intentionally not shipped).
- **question_bank.json**: only ever `git mv`'d. The deleted mutation scripts are the main historical
  way it got hand-edited; removing them lowers that risk.

---

## 5. Scope estimate

| Block | Steps | Files touched | Effort |
|---|---|---|---|
| Cleanup + hygiene | S0–S2 | ~35 deletions, 5 edits | ~1 h |
| Folder/data moves | S3–S5 | ~60 moves, ~30 path edits | ~2–3 h incl. re-import + export check |
| Pure extractions + theme | S6 | 5 new files, main −250 lines, ~400 literal substitutions | ~2 h |
| Builders + golden test | S7 | 4 new files, main −1,450 lines | ~2–3 h |
| Session/presenters | S8–S9 | 4 new files, main −900 lines | ~4–5 h |
| Speech controller | S10 | 2 new files, main −1,000 lines | ~4 h + device session |
| Facade cleanup/docs | S11 | harness, snap, docs | ~1–2 h |

End state: `main.gd` ≈ 900–1,200 lines (composition, node refs, menu, input, render glue), root
reduced to `project.godot`, `export_presets.cfg`, `README.md`, `.gitignore`; ~1 GB of scratch and
stale builds gone from the working folder (after confirmation); APK loses ~2 MB of stray tool PNGs.
