# Architecture

How the code is organised after the 2026 refactor (`docs/REFACTOR_PLAN.md`
has the plan and the reasoning; this file describes the result).

## Layout

```
project.godot  export_presets.cfg  README.md
scenes/main.tscn            one scene, root node "Main" running src/app/main.gd
src/
  app/    main.gd           composition root, quiz flow, menu, input, harness facade
          desktop_layout.gd DesktopLayout.build(host): the Windows UI
          mobile_layout.gd  MobileLayout.build(host): the Android UI
  core/   node-free, unit-tested
          quiz_session.gd   QuizSession: order (one question pool), score, streak, verdicts, missed list, clocks
          question_deck.gd  QuestionDeck: which questions a run gets, reviews, study stats, question_bag.cfg
          exam_blueprint.gd ExamBlueprint: the exam's subject areas, record -> area (NEC pool only), apportionment
          choice_order.gd   ChoiceOrder: per-run choice order, locked questions, pinned choices
          bank_loader.gd    BankLoader: reads data/question_bank.json, normalises records, question pools
          nec_reference.gd  NecReference: article titles (data/nec_2023_articles.json), lookup paths (NEC and Nebraska law)
          safe_area.gd      SafeArea.margins: notch / cutout insets
          audio_settings.gd AudioSettings: audio modes, speed, pauses, sound effects, audio.cfg
          user_dir_migration.gd  UserDirMigration: one-time copy from the pre-1.0 user folder
  speech/ speech_controller.gd  SpeechController: bundled clips, Edge helper and cache,
                                native TTS, play queue, teach gate, voice picker
          voice_catalog.gd      VoiceCatalog: voices.json, US device voice names (docs/ANDROID_VOICES.md), voice.cfg
          speech_helper.gd      SpeechHelper node: talks to speak_question.py --serve
          speak_question.py     desktop Edge TTS helper (shipped, copied out at runtime)
          edge_tts_client.gd    EdgeTtsClient node: Edge voices over WebSocket, no Python (mobile)
          speech_text.gd  speech_rules.gd  audio_explanation_generator.gd  unit_matcher.gd
                                what gets spoken (see docs/VOICE_READING_RULES.md)
  ui/     app_theme.gd      AppTheme: the palette (Tailwind names + role names), panel/font factories
          widgets.gd        Widgets: mode buttons, dock buttons, chips, voice picker, mobile voice button
          touch_scroll.gd   TouchScroll: finger drag-to-scroll for every ScrollContainer, tap vs swipe
          voice_sheet.gd    VoiceSheet: the mobile voice list (rows built a batch per frame)
          fit_controller.gd FitController: keeps the question screen at 0% scroll
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
data/     question_bank.json (never edited by hand)  voices.json
          nec_2023_articles.json  canonical NEC 2023 chapter and article titles (app, builder, validator)
          exam_blueprint.json (content outline, chapter map, area overrides)
assets/   diagrams/  sfx/  speech/<qid>__<voice>/ (generated, gitignored)
          branding/  icon.png/.ico, Android icon layers, splash.png; source/ (SVGs, .gdignore)
docs/     this file, DATA_PIPELINE, VOICE_READING_RULES, SFX_PLAN, KNOWN_ISSUES, RELEASE,
          ANDROID_VOICES, ... (.gdignore: Godot never imports docs/)
tools/    verify.sh  harness.gd  list_pck.py
          branding/  build_branding.py + render_svg.gd: every icon and the splash from the SVGs
          release/   make_release.py, the recipient README/CREDITS, dump_licenses.gd (docs/RELEASE.md)
          pipeline/  bank build, overrides, validator, spellcheck, OCR
          speech/    dump_speech.gd  pregenerate_speech.py  test_bundle.gd  check_export_pack.gd
          visual/    snap.gd  snap_all.gd  snap_motion.gd  snap_tables.gd  measure_fit.gd  compare_shots.py (output: .audit_tmp/)
                     snap_showcase.gd + make_showcase.py: the README screenshots and hero (docs/media/)
          tests/     run_all.gd + suites, golden/ layout snapshots
          study/     blueprint_report.gd (pool per subject area, overrides, draws per mode)
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
puts at `%APPDATA%\NEC2023JourneymanChallenge` on Windows. The first thing
`_ready` does is `UserDirMigration.run()`: on a first launch it copies
`audio.cfg`, `voice.cfg` and `question_bag.cfg` from the pre-1.0 folder
(`%APPDATA%\Godot\app_userdata\<project name>`), never deleting them, and
leaves a marker so it runs once. The version shown in the menu footer
(`Main.version_label()`) comes from `application/config/version`.

Question pools: records without a `section` field are the NEC pool; the
Nebraska State Law records carry `"section": "ne_state_law"`.
`_start_quiz(..., section)` hands the pool to `session.begin`. The NEC pool
goes through the deck below; `ExamBlueprint.area_of` gives other pools no
area, so the NEC drills, the simulator, the reviews and the readiness never
see a state question. Any other pool is simply shuffled, with shuffled
choices. The menu's NEBRASKA STATE LAW drill
(`Widgets.add_state_law_section`) asks for every record in its pool.

The flow of one question: `_show_question` asks `session` for the record,
renders the stem, choices, table or figure, then `fit.begin()` shrinks the
screen until nothing scrolls. `_answer_selected` hands the pick to
`session.submit()`, which grades it and returns the verdict. `main` then
shows the feedback sheet, `QuizFx.play_answer` plays the burst, and
`fit.compact_answered` hides what no longer matters.

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

### Question selection

Every NEC mode draws from the whole NEC pool (all 279 questions, every exam) through
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
- Every run is interleaved so neighbours differ in article and area.
- `begin(..., simulation, area)` picks the draw; an explicit `rng.seed`
  (tests, harness) makes it repeatable, otherwise each session randomizes.
- The deck, reviews and per-question stats persist by question id in
  `user://question_bag.cfg`; `reset_progress()` clears them.
- Study feedback reads the same state: `session.area_stats` and
  `answer_seconds` for the report (ResultsView, ChapterBars area rows),
  `deck.mastery()` for readiness and the menu's weakest-area drill
  (`main.study_button`, refreshed by `_show_menu`).

`docs/STUDY_SYSTEM.md` has the blueprint, the pool counts, and the
algorithms in detail.

### Speech

`SpeechController` decides where each readout comes from, in this order:

1. The bundled recorded voice (`assets/speech/`, imported, ships in the pck).
2. An Edge neural voice: a cached folder in `user://speech`, or a live
   request that plays each clip as it lands. The current and next question
   are prefetched. On desktop the clips come from the Python helper
   (`SpeechHelper` + `speak_question.py`); on mobile, where Python cannot run,
   from `EdgeTtsClient`, a pure-GDScript client for the same read-aloud
   WebSocket (same Sec-MS-GEC token, same 96 kbps format, same cache layout).
   `_synth()` picks the backend; both have the same API and signals.
3. When the Edge voice fails (no internet, no Python): the recorded Andrew if
   the line has a clip, else native OS text-to-speech, and the status line
   names the voice speaking ("Andrew (recorded, no internet)").
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
  by the shader, so text keeps its exact colour.
- **Type**: `ui_font(weight)`, tracked `meta_font()` for small caps labels,
  tabular `numeric_font()` for clocks and scores.
- **Motion never moves layout.** Hover and press use `scale` about the centre,
  offsets that return to rest, colour and shader uniforms; state styleboxes
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

`bash tools/verify.sh` runs everything below except the last three:

- import and `--check-only` parse of every script;
- `tools/tests/run_all.gd`: 31 suites, including `test_breadcrumb` (every
  record, shuffled, through the real Next flow in both layouts: the
  breadcrumb and the "Article N Title — section" line name the record's own
  chapter and article, from `data/nec_2023_articles.json`), `test_touch_scroll` (a
  swipe over buttons and answer cards scrolls and presses nothing; a tap
  presses), `test_voice_picker` (450 device voices within a time budget,
  names, US-only list, migration), `test_no_leak` (nothing
  before answering reveals the answer), `test_layout_tree` (serialised node
  tree of both layouts against `tools/tests/golden/`; `-- --update` rewrites
  the snapshots after an intended change), `test_menu_cards` (cards stay
  in their column slot through hover, focus and a quiz round-trip) and
  `test_quiz_session`;
- `tools/harness.gd` on both layouts (quiz flow, speech queue, teach gate);
- the Python tests and the bank validator (`--no-warn`: 0 errors, 0 warnings).

Also:

- `tools/speech/test_bundle.gd`: every question resolves to its bundled clips (283/283).
- `tools/visual/measure_fit.gd`: share of questions that scroll before and after answering (0%), and any reference table that shows a scrollbar (none).
- `tools/speech/check_export_pack.gd`: run against an exported `.pck` with
  `--main-pack`. It loads the bank, every clip and the sfx from inside the
  pack, and checks the helper script is copied out.

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
