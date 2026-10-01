# Architecture

How the code is organized after the 2026 refactor (`docs/REFACTOR_PLAN.md`
has the plan and the reasoning; this file describes the result).

## Layout

```
project.godot  export_presets.cfg  README.md
scenes/main.tscn            one scene, root node "Main" running src/app/main.gd
src/
  app/    main.gd           composition root, quiz flow, menu, input, harness facade
          desktop_layout.gd DesktopLayout.build(host): the Windows UI
          mobile_layout.gd  MobileLayout.build(host): the Android UI
          menu/             the main menu, built from data/menu.json (see "Main menu" below):
                            main_menu.gd (MainMenu), menu_model.gd (MenuModel), menu_tile.gd,
                            meter_bar.gd, outline_bars.gd
  core/   node-free, unit-tested
          quiz_session.gd   QuizSession: order (one question pool), score, streak, verdicts, missed list, clocks
          question_deck.gd  QuestionDeck: which questions a run gets, reviews, study stats, question_bag.cfg
          exam_blueprint.gd ExamBlueprint: the exam's subject areas, record -> area (NEC pool only), apportionment
          choice_order.gd   ChoiceOrder: per-run choice order, locked questions, pinned choices
          bank_loader.gd    BankLoader: reads data/question_bank.json, normalizes records, question pools
          nec_reference.gd  NecReference: article titles (data/nec/<year>/articles.json), lookup paths (NEC and Nebraska law)
          hunt_keywords.gd  HuntKeywords: the stem words to look up in the code book's Index (data/nec/<year>/hunt_keywords.json)
          safe_area.gd      SafeArea.margins: notch / cutout insets
          edition.gd        Edition: the NEC edition labels and data folder, from data/edition.json
          app_identity.gd   AppIdentity: app name templates, frozen save folder, legacy names (data/app.json)
          study_progress.gd StudyProgress: best score per exam and the unfinished run, study_progress.cfg
          audio_settings.gd AudioSettings: audio modes, speed, pauses, sound effects, audio.cfg
          user_dir_migration.gd  UserDirMigration: one-time copy from the pre-1.0 user folder
  speech/ speech_controller.gd  SpeechController: bundled clips, Edge voices and cache,
                                native TTS, play queue, teach gate, voice picker
          voice_catalog.gd      VoiceCatalog: voices.json, US device voice names (docs/ANDROID_VOICES.md), voice.cfg
          edge_tts_client.gd    EdgeTtsClient node: Edge voices over WebSocket, no Python (Windows and Android)
          speak_question.py     dev tool: edge-tts synthesis for tools/speech/pregenerate_speech.py (not shipped)
          speech_text.gd  speech_rules.gd  audio_explanation_generator.gd  unit_matcher.gd
                                what gets spoken (see docs/VOICE_READING_RULES.md)
  ui/     app_theme.gd      AppTheme: the palette (Tailwind names + role names), panel/font factories
          widgets.gd        Widgets: mode buttons, dock buttons, chips, voice picker, mobile voice button
          touch_scroll.gd   TouchScroll: finger drag-to-scroll for every ScrollContainer, tap vs swipe
          voice_sheet.gd    VoiceSheet: the mobile voice list (rows built a batch per frame)
          fit_controller.gd FitController: keeps the question screen at 0% scroll
          hunt_view.gd      HuntView: highlighter-marked hunt keywords in the stem, the INDEX line, tap and hover
          keyword_stem_label.gd  KeywordStemLabel: the stem RichTextLabel, no hover tooltip
          math_hub.gd  math_*.gd  Show steps, Math trainer, formula cards, table drills, weak spots
                            (loaded by path from data/menu.json; docs/MATH_TRAINER.md)
          calc_pad.gd       CalcPad: the on-screen calculator (trainer answers, guided Show steps rows)
          table_viewer.gd   TableViewer: reference tables that never scroll (column fit, folding, type steps)
          info_panel_renderer.gd  InfoPanelRenderer: the explanation RichTextLabel
          results_view.gd   ResultsView: graded and listen results, confetti
          audio_section.gd  AudioSection: the menu's Audio & Voice block
          icons.gd          Icons: small SDF glyphs drawn in code (tinted by modulate)
          answer_card.gd  diagram_view.gd  voice_visualizer.gd
  fx/     quiz_fx.gd        QuizFx: fx layer, segmented progress, time gauges, answer burst
          ui_fx.gd          UiFx: surface material, glass/shine/current, screen enter, Reduce motion
          sfx.gd  speech_chain.gd  time_gauge.gd  progress_segments.gd  readiness_ring.gd
          result_gauge.gd  chapter_bars.gd  pace_sparkline.gd  mode_badge.gd
          shaders/          surface (panels, cards, buttons), circuit_backdrop, electric_title
  math/   math_engine.gd  calc_engine.gd  math_data.gd  math_drills.gd  math_stats.gd  math_format.gd
          math_functions.gd: the math helpers' engine, calculator, data access and statistics
data/     question_bank.json (never edited by hand)  voices.json (default voice marked)
          menu.json         the main menu tabs and blocks (see "Main menu" below)
          math/             problem types, formula cards, table drills, exam step inputs, study tools
          edition.json      the NEC edition (year, labels, data folder): the one place the year is written
          app.json          app name templates; frozen save folder and Android id; legacy names
          nec/2023/         the edition's data: articles.json (chapter and article titles), tables.json
                            (table values for the math helpers and nec_calc.py), hunt_keywords.json
                            (generated); pipeline only (excluded from exports): content_audit.json,
                            renumbered.json, provisions.json, concepts.json, answer_glossary.json,
                            index_terms.json
          exam_blueprint.json (exam format, content outline, chapter map, area overrides, edition)
          diagram_masks.json  per figure (PDF crops) or per record (original figures): answer-revealing
                              regions and the "?" masks DiagramView draws over them until the answer is in
                              (docs/DIAGRAMS_AUDIT.md)
          question_requirements.json  which records need a table, calculation or formula
                              (read by tools/pipeline, not by the app; docs/TABLES_FORMULAS_AUDIT.md)
assets/   diagrams/ (PDF crops)  diagrams/nec/ (original figures, generated by tools/diagrams/build.py)
          sfx/  speech/<qid>__<voice>/ (generated, gitignored)
          branding/  icon.png/.ico, Android icon layers, splash.png; source/ (SVGs, .gdignore)
docs/     this file, DATA_PIPELINE, VOICE_READING_RULES, SFX_PLAN, KNOWN_ISSUES, RELEASE,
          ANDROID_VOICES, ...; audits/ (working audit reports, see audits/README.md)
          (.gdignore: Godot never imports docs/)
tools/    verify.sh  harness.gd  list_pck.py
          branding/  build_branding.py + render_svg.gd: every icon and the splash from the SVGs
          release/   make_release.py, the recipient README/CREDITS, dump_licenses.gd (docs/RELEASE.md)
          pipeline/  bank build, overrides, validator, spellcheck, OCR (ocr_fixes.json); exam
                     families and transcripts in sources/exams/; audit guards: check_requirements.py
                     + nec_calc.py; edition_migration_report.py (docs/EDITION_MIGRATION.md)
          release/   also sync_identity.py (names from data/app.json) and bump_version.py
          godot.env  the Godot version every script and CI job uses
          diagrams/  build.py + nec_style.py + figs/: the original NEC figures; leakscan.py, preview.py,
                     contact_sheet.py (in-app shots from visual/snap_diagrams.gd)
          speech/    dump_speech.gd  pregenerate_speech.py  test_bundle.gd  check_export_pack.gd
          visual/    snap.gd  snap_all.gd  snap_motion.gd  snap_tables.gd  snap_hunt.gd  snap_diagrams.gd
                     measure_fit.gd  compare_shots.py (output: .audit_tmp/)
                     snap_showcase.gd + make_showcase.py: the README screenshots and hero (docs/media/)
          tests/     run_all.gd + suites, golden/ layout snapshots
          study/     blueprint_report.gd (pool per subject area, overrides, draws per mode)
          math/      nec_tables_from_cache.py: builds or checks data/nec/2023/tables.json from a local
                     NEC text cache (the cache is never in the repo)
          sfx/       make_sfx.py  electric.py: the sound-effect pipeline (docs/SFX_PLAN.md)
```

## How the pieces fit

`main.gd` owns the scene and every node reference. The builders assign those
references (`host.question_label = ...`), so the rest of the code reaches the
UI through `main`. Two patterns hang off it:

- **Owned objects** for things with state: `session` (QuizSession),
  `speech` (SpeechController), `fit` (FitController), `info_panel`
  (InfoPanelRenderer), `audio` (AudioSettings). The objects that need the UI
  have a `host: Main` field, set in `Main._init`, so they work on a bare
  `Main.new()` too (test_bundle and check_export_pack rely on that).
- **Static helpers** for stateless work: `DesktopLayout`, `MobileLayout`,
  `Widgets`, `AudioSection`, `ResultsView`, `QuizFx`, `AppTheme`,
  `BankLoader`, `NecReference`, `SafeArea`, `VoiceCatalog`. The ones that
  touch the UI take `host: Main` as their first argument.

`class_name Main` makes every `host.x` access type-checked, so a renamed
member fails at parse time, not at runtime.

Saved state lives in `user://`, which `application/config/use_custom_user_dir`
puts at `%APPDATA%\NEC2023JourneymanChallenge` on Windows. That folder name and
the Android package id (`com.livewire.nec2023.trainer`) are frozen in
`data/app.json` and do not follow the edition: a new folder would strand every
install's progress, a new package id would install a second app instead of
upgrading. The first thing `_ready` does is `UserDirMigration.run()`: on a first
launch it copies `audio.cfg`, `voice.cfg` and `question_bag.cfg` from the pre-1.0
folder (`%APPDATA%\Godot\app_userdata\<legacy project name>`, names listed in
`data/app.json`), never deleting them, and leaves a marker so it runs once. The version shown in the menu footer
(`Main.version_label()`) comes from `application/config/version`.

Question pools: records without a `section` field are the NEC pool; the
Nebraska State Law records carry `"section": "ne_state_law"`.
`_start_quiz(..., section)` hands the pool to `session.begin`. The NEC pool
goes through the deck below; `ExamBlueprint.area_of` gives other pools no
area, so the NEC drills, the simulator, the reviews and the readiness never
see a state question. Any other pool is simply shuffled, with shuffled
choices. Nebraska State Law shows up in the menu as one more exam family
(its records carry an `exam` label like every other exam).

### Main menu

`data/menu.json` describes the menu; `MainMenu` (`host.menu`, an owned
object) builds it into both layouts' menu column and `MenuModel` does the
node-free part (spec, `{placeholder}` filling, exam discovery, progress
counts). The spec lists the tabs in order (Home, Exams, Drills, Study,
Settings), each with the blocks it shows; every block kind has one builder
in `main_menu.gd` and its texts in the spec's `blocks`. Nothing in the code
names an exam, a count or the edition:

- Exams come from the bank. `MenuModel.families` groups records by their
  `exam` label without the `#N` ("Open Book Exam #3" -> family "Open Book
  Exam"), sorted by `family_order` and number. A new exam in
  `data/question_bank.json` gets a tile on the next launch; a new family
  gets its own chip. Tiles show questions seen, the best score against the
  pass mark, and page when a family outgrows its grid.
- The full exam's item count, time and pass mark come from
  `data/exam_blueprint.json` (`ExamBlueprint.minutes`, `pass_percent`), the
  edition from `data/edition.json` (`Edition`).
- Home shows "Continue where you left off" when `StudyProgress` holds an
  unfinished run (`session.snapshot()` after every graded answer,
  `session.restore()` to resume), the quick drill, the weakest-area drill,
  missed-question review and the full exam with its content outline bars.
- Study lists `data/math/tools.json` through the entry script named in
  `study_tools.entry_script`, loaded by path: when it is not in the build
  the block shows its `missing` text and the quiz hooks
  (`menu.study_hook`: attach, question, answered, back) do nothing.
- Every tab fits without scrolling at the 12 fit sizes; the holder keeps
  Home's height so the panel does not jump between tabs, and Back on a tab
  other than Home returns to Home.

`test_menu.gd` covers the model, every entry, the progress flow, exam
discovery and the fit; `test_menu_cards.gd` the card sizes per tab.

The flow of one question: `_show_question` asks `session` for the record,
renders the stem, choices, table or figure, then `fit.begin()` shrinks the
screen until nothing scrolls. `_answer_selected` hands the pick to
`session.submit()`, which grades it and returns the verdict. `main` then
shows the feedback sheet, `QuizFx.play_answer` plays the burst, and
`fit.compact_answered` hides what no longer matters.

A question figure (`DiagramView`) comes from one of two maps: the original
figures in `assets/diagrams/nec/figures.json` (`tools/diagrams/build.py`, dark
card; this includes the three figures the exams require) and PDF crops in
`assets/diagrams/diagrams.json` (`tools/pipeline/extract_diagrams.py`,
paper-white card; empty since 1.0.5); a record in both gets the PDF crop. It covers any answer-revealing region with
an opaque "?" badge, drawn in image space so it scales with the figure inline
and in the zoom: PDF crops take their masks per file (`diagrams` in
`data/diagram_masks.json`), original figures per record (`records`), so one
drawing can serve several questions with different masks. A figure marked
`"when": "after"` teaches rather than sets up the question: it stays hidden
until the answer is in. `reveal()` fades the badges (instantly with Reduce
motion) and shows the after-only figures; `test_diagrams.gd` fails when a
flagged leak has no mask or a visible label states the answer.

The original figures are Python-drawn SVG (`tools/diagrams/nec_style.py`: the
palette, strokes, type sizes, dimension lines and the shared parts, one
module per topic in `tools/diagrams/figs/`) rendered to palette PNG, because
Godot's SVG import drops text. `build.py` writes the PNGs, both maps' NEC
side, the per-record masks and `docs/diagrams/` (SVG review copies and every
label's box); its leak scan (`tools/diagrams/leakscan.py`, mirrored in
`test_diagrams.gd`) refuses a figure whose unmasked label gives away a
before-answer question. `build.py --check` (in `verify.sh`) fails when the
checked-in outputs are stale.

Reference tables never scroll. The table's ScrollContainer has vertical
scrolling off (it takes the grid's height) and no horizontal bar;
`TableViewer.fit_columns` splits the box's width between the columns from the
measured text. When the page would scroll, `FitController` picks the most
readable layout that fits (`TableViewer.pick_layout`, predicted from the font
metrics): whole words first, then larger type, then fewer blocks, a long narrow
table folding into side-by-side blocks under repeated headers. If even the
smallest layout does not fit, the gist and then the formula hint give way.
After answering, the feedback table gets the layout that shows it whole in the
explanation sheet's first view; the sheet scrolls only for the text below it. `_tick_timer` drives
`session.tick()` once a second.

### Hunt keywords

The printed exam is open book, so each NEC question names the words to look
up in the code book's Index. `tools/pipeline/hunt_keywords.py` writes
`data/nec/<year>/hunt_keywords.json`: per record 1 to 3 exact stem phrases,
the Index-style heading and the article, and `show_article` (false when the
stem asks for the reference or the answer holds the article number). The
curated vocabulary and per-question overrides live in `index_terms.json`
(pipeline only). `--check` (run by `test_hunt_keywords.py` in verify.sh)
fails when a keyword is not in the stem, holds the correct choice or starts a
word of it, its heading names the choice, or its article is not one the record
cites.

The stem is a RichTextLabel (`HuntView.make_stem_label`); `HuntView.show_question`
marks each keyword's first occurrence as a highlighter mark (amber text on a
faint amber tint, stronger under the pointer; the parsed text is the bank stem
exactly) and fills the INDEX line (`host.index_hint_label`) above the chapter
path in the lookup box. Hovering a keyword (desktop) puts just its entry in the
INDEX line until the pointer leaves; a tap or click keeps it there, shown as a
solid amber chip, until a second tap. No tooltip pops up. After answering the
INDEX line goes with the lookup box, the keywords stay marked and the reference
line is unchanged.
Speech reads the record, never the label. `FitController` shortens the INDEX
line to its first entry, then hides it, before the page would scroll. The
setting is `AudioSettings.hunt_keywords` (audio.cfg `[study] hunt_keywords`,
on by default); `HuntKeywords.enabled` keeps it off in the Full Exam. The
Study tab's `hunt_tip` block (data/menu.json) lists the lookup routine.

### Question selection

Every NEC mode draws from the whole NEC pool (all 594 questions, every exam) through
`session.deck` (QuestionDeck), weighted by the licensing exam's content
outline in `data/exam_blueprint.json` (ExamBlueprint). In short:

- Each record has one subject area: an override by id, else the NEC
  chapter of its `article` (Ch. 2 Wiring and Protection, Ch. 3 Wiring
  Methods, ..., Ch. 1/8/9 and non-NEC items General Electrical Knowledge).
- Drills split their slots over the areas in blueprint proportion (largest
  remainder, the leftover fractions carried to the next drill) and take
  them from one no-repeat deck per area, shared by every drill size.
  Missed questions come back two runs later, at most a quarter of a drill.
- The simulator takes exactly 10/20/15/15/10/5/5 per area, least recently
  seen first, without reviews. An area short of records passes its share on.
- Every run is interleaved so neighbors differ in article and area.
- `begin(..., simulation, area)` picks the draw; an explicit `rng.seed`
  (tests, harness) makes it repeatable, otherwise each session randomizes.
- The deck, reviews and per-question stats persist by question id in
  `user://question_bag.cfg`; `reset_progress()` clears them.
- Study feedback reads the same state: `session.area_stats` and
  `answer_seconds` for the report (ResultsView, ChapterBars area rows),
  `deck.mastery()` for readiness and the menu's weakest-area drill
  (`main.study_button`, refreshed by `menu.refresh()` from `_show_menu`).

`docs/STUDY_SYSTEM.md` has the blueprint, the pool counts, and the
algorithms in detail.

### Speech

`SpeechController` decides where each readout comes from, in this order:

1. The bundled recorded voice (`assets/speech/`, imported, ships in the pck).
2. An Edge neural voice: a cached folder in `user://speech`, or a live
   request that plays each clip as it lands. The current and next question
   are prefetched. On Windows and Android alike the clips come from
   `EdgeTtsClient`, a pure-GDScript client for the edge-tts read-aloud
   WebSocket (same Sec-MS-GEC token, same 96 kbps format, same cache layout
   as `speak_question.py`, which only pregenerates the bundle now). The app
   never starts a process for speech (`test_no_speech_process.gd`), so a
   shared Windows build needs no Python.
3. When the Edge voice fails (no internet, service down): the recorded Andrew
   if the line has a clip, else native OS text-to-speech, and the status line
   names the voice speaking ("Andrew (recorded, no internet)", "System voice
   (no internet)").
4. Native OS text-to-speech for device voices (Android).

`EdgeTtsClient` polls DNS, TLS and its sockets from `_process`, so nothing
waits on the network on the main thread. A connection that never opens
(unresolvable host, or 6 s without a handshake) marks the network down for
30 s: queued requests fail with it and new ones are refused at once, so the
next reads fall back without waiting again.

The **teach gate** is in `_play_speech_clip`, the one function that plays a
clip. A teach clip (the rule, which gives away the answer) never plays while
`want_teach` is false, and only answering sets it. The native TTS path has
the same check in `_play_next_native_tts_segment`.

The native TTS callbacks are registered as `Callable(self, "...")` on the
controller. Signal targets that the golden layout test records are
`main.speech._on_...`.

**Device voices (Android).** `_device_voice_list()` asks the OS
(`DisplayServer.tts_get_voices`, a binder call on Android) once and caches
the answer; an empty answer is asked again at most every 2 s, from the launch
timer or when the voice sheet opens, never on every open. Tests swap the OS
in through `voice_source`. `VoiceCatalog.device_voice_rows` keeps only US
English voices, one per voice (the offline copy of a local/network pair),
labels them from `US_VOICE_NAMES` ("Female 1 · US English · Offline"; unknown
codes get a neutral "Voice A") and ends with "System default"; the table and
its sources are in docs/ANDROID_VOICES.md. The mobile picker is the hidden
`voice_picker` OptionButton (it holds the list and the selection) behind
`voice_button`, which opens `VoiceSheet`: a PopupMenu reacts only to mouse
events, which the app does not emulate. `pick_voice` applies a row once and
ignores re-entry. `_load_voice_choice` migrates a saved id with
`VoiceCatalog.migrate_voice_id` (non-US or missing: Andrew).

The mobile list is: the recorded Andrew, then the en-US Edge voices from
`data/voices.json` (`VoiceCatalog.edge_voice_rows`: "Ava · Female · Online
(natural)", gender from the Edge metadata, Andrew left out because the
recorded row is Andrew and uses online Andrew for any line without a clip),
then the device voices. `VoiceCatalog.is_edge_voice` tells the two id kinds
apart (Edge ids end in `Neural`), so a device fallback is never handed an
Edge id.

### Touch input

`input_devices/pointing/emulate_mouse_from_touch` is off, so a finger never
produces mouse events (with emulation, a scroll could select an answer
card). Godot's ScrollContainer and PopupMenu drag and pick only on mouse
events, so `main.touch_scroll` (TouchScroll, a child node) scrolls instead.
In `_input`, before the GUI, it hit-tests the touch point itself; once a drag
passes `DRAG_THRESHOLD` (14 px, under the answer card's 20 px slop) it picks
the axis, finds the innermost ScrollContainer that can scroll that way,
sends `NOTIFICATION_SCROLL_BEGIN` down that container (BaseButton cancels its
press, AnswerCard and DiagramView drop theirs), swallows the rest of the
gesture and flings on release. A touch that never passes the threshold is
left alone, so Buttons (ScreenTouch-native) and AnswerCard still see a tap.

### Sound effects

`main.sfx` (Sfx, a child node with one pre-loaded player per sound on the
`SFX` bus) plays everything through `main._sfx(id)`; docs/SFX_PLAN.md has the
sounds and the rules. Event cues come from the flow: `Widgets.connect_session_start`
(start), `QuizFx.play_answer` (correct / wrong), `ResultsView.land`
(pass / fail), `_tick_timer` (warning). Interface sounds:

- `main._wire_ui_sounds` walks every BaseButton once, after `_setup_sfx`:
  toggle for toggle-mode buttons (chips, CheckButtons) and `mute_button`,
  click for the rest, except session starts (`starts_session` meta), which
  play the start cue alone; hover on `mouse_entered` for the menu mode cards
  (`menu_mode_buttons`) on the desktop layout only, with its pitch jittered
  per play (`vary_pitch` in `Sfx.SOUNDS`). A button built later is not covered.
- Answer cards are wired in `_show_question`: `focus_entered` plays select
  when the last input was a key or controller (`main._input` sets
  `_nav_input`). Nothing is added inside `answers_box`.
- transition: `_start_quiz`, `ResultsView.show`, and `_show_menu` after the
  first time.
- `Sfx.play` queues interface sounds and `Sfx.flush_ui` plays one at the end
  of the frame; an event cue in the same moment silences them.

### The two layouts

Desktop and mobile have separate builders on purpose. They are about 90%
structurally alike but share almost no lines, and the desktop one reproduces
the legacy Windows UI exactly. Shared pieces are factored into `Widgets`,
`AppTheme` and `AudioSection`. Anything else that differs goes in the
builder, not behind `if ui_mobile` in main.

## Visual system

- **Tokens** live in `AppTheme`: palette (Tailwind names plus roles such as
  `SURFACE_BOTTOM`, `HAIRLINE_BRIGHT`, `PAPER_*`), gradient pairs (`GRAD_*`),
  spacing (`SPACE_*`), radii, elevation, type scale (`TYPE_*`), weights and
  motion durations (`MOTION_*`). `test_app_theme` keeps them unique and ordered.
- **Surfaces** are a `StyleBoxFlat` from `AppTheme.surface()` plus one shared
  canvas_item shader (`surface.gdshader`) applied by `UiFx.add_glass` /
  `add_tint` / `add_shine`: fill lift, bevel, a gradient tint, a hover shine
  and a "current" that runs around the border. Labels (pure white) are skipped
  by the shader, so text keeps its exact color.
- **Type**: `ui_font(weight)`, tracked `meta_font()` for small caps labels,
  tabular `numeric_font()` for clocks and scores.
- **Motion never moves layout.** Hover and press use `scale` about the center,
  offsets that return to rest, color and shader uniforms; state styleboxes
  share content margins (checked by `test_menu_cards` and `test_app_theme`).
  Everything that animates on its own joins `UiFx.MOTION_GROUP`, and
  `UiFx.apply_reduce_motion` freezes it when Reduce motion is on.

## The harness facade

`tools/harness.gd`, the snapshot tools and several tests read and write
members on `main` by their old names (`main.speech_queue`, `main.order`,
`main._stop_reading()`, ...). `main` keeps those names:

- forwarding properties (`var order: Array[int]: get: return session.order`)
  that return the component's own Array or Dictionary, so in-place changes
  like `main.speech_queue.append(...)` land in the component;
- one-line forwarding methods (`func _stop_reading() -> void: speech._stop_reading()`).

New code should call the component (`speech.x`, `session.x`), not the facade.
`SpeechController` keeps the old underscore names because the facade, the
tests and the native TTS callbacks refer to them by name.

## Safety net

`bash tools/verify.sh` runs everything below except `measure_fit.gd` and
`check_export_pack.gd`; `test_bundle.gd` runs whenever `assets/speech/` exists:

- import and `--check-only` parse of every script;
- `tools/tests/run_all.gd`: 41 suites (tools/tests/README.md lists them), including `test_breadcrumb` (every
  record, shuffled, through the real Next flow in both layouts: the
  breadcrumb and the "Article N Title — section" line name the record's own
  chapter and article, from `data/nec/2023/articles.json`), `test_touch_scroll` (a
  swipe over buttons and answer cards scrolls and presses nothing; a tap
  presses), `test_voice_picker` (450 device voices within a time budget,
  names, US-only list, migration), `test_no_leak` (nothing
  before answering reveals the answer), `test_layout_tree` (serialized node
  tree of both layouts against `tools/tests/golden/`; `-- --update` rewrites
  the snapshots after an intended change), `test_menu_cards` (cards stay
  in their column slot through hover, focus and a quiz round-trip) and
  `test_quiz_session`;
- `tools/harness.gd` on both layouts (quiz flow, speech queue, teach gate);
- the Python tests (including `check_requirements.py` through
  `test_question_requirements.py`) and the bank validator with its location
  and content-audit guards (`--no-warn`: 0 errors, 0 warnings).

Also:

- `tools/speech/test_bundle.gd`: every question resolves to its bundled clips (598/598), and every Show steps step of the 70 exam solutions to its clip (378/378).
- `tools/visual/measure_fit.gd`: share of questions that scroll before and after answering (0%), and any reference table that shows a scrollbar (none).
- `tools/speech/check_export_pack.gd`: run against an exported `.pck` with
  `--main-pack`. It loads the bank, every clip and the sfx from inside the
  pack, and checks no Python speech script ships.

Headless Godot gives fake layout sizes, so anything about pixels needs a
windowed run (`snap_all.gd`, `measure_fit.gd`). docs/KNOWN_ISSUES.md lists
this and the other traps.

## Deliberately not done

- **A single UI builder for both layouts**: see "The two layouts" above.
- **A signal bus**: `main` still calls components directly. The harness
  depends on that synchronous, deterministic order.
- **Deduplicating `unit_matcher.gd` / `audio_explanation_generator.gd`
  against `speech_text.gd`**: that changes spoken content, which needs a
  listening review and fresh clips. It is a separate job.

## Edition, exam format and identity

The NEC year is written once, in `data/edition.json`. `Edition` (app) and
`pipeline_paths.edition()` / `nec_data()` (Python) read it; header titles,
report headers, breadcrumbs and validator messages are built from it, and every
edition data file is looked up under its `dir` (`data/nec/2023/`). The exam
format (80 scored items, 240 minutes, 75 % pass, at-risk band, exam name and
authority) comes from `data/exam_blueprint.json` through `ExamBlueprint`; no
screen writes those numbers. Visible app names are templates in `data/app.json`;
`tools/release/sync_identity.py` writes them into `project.godot` and
`export_presets.cfg`, and `tools/release/bump_version.py` keeps every copy of the
version in step with `project.godot`. Layout goldens hold `{VERSION}` and
`{EDITION}` placeholders, so a version bump or edition switch needs no golden
edit. `docs/EDITION_MIGRATION.md` has the 2026 steps; `docs/ADDING_EXAMS.md` the
new-exam steps.
