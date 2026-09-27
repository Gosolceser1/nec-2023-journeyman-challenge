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
          quiz_session.gd   QuizSession: order, score, streak, verdicts, missed list, clocks
          bank_loader.gd    BankLoader: reads data/question_bank.json, normalises records
          nec_reference.gd  NecReference: article titles, lookup paths
          safe_area.gd      SafeArea.margins: notch / cutout insets
          audio_settings.gd AudioSettings: audio modes, speed, pauses, sound effects, audio.cfg
  speech/ speech_controller.gd  SpeechController: bundled clips, Edge helper and cache,
                                native TTS, play queue, teach gate, voice picker
          voice_catalog.gd      VoiceCatalog: voices.json, device voice tiers/labels, voice.cfg
          speech_helper.gd      SpeechHelper node: talks to speak_question.py --serve
          speak_question.py     desktop Edge TTS helper (shipped, copied out at runtime)
          speech_text.gd  speech_rules.gd  audio_explanation_generator.gd  unit_matcher.gd
                                what gets spoken (see docs/VOICE_READING_RULES.md)
  ui/     app_theme.gd      AppTheme: the palette (Tailwind names + role names), panel/font factories
          widgets.gd        Widgets: mode buttons, dock buttons, chips, voice picker
          fit_controller.gd FitController: keeps the question screen at 0% scroll
          info_panel_renderer.gd  InfoPanelRenderer: the explanation RichTextLabel
          results_view.gd   ResultsView: graded and listen results, confetti
          audio_section.gd  AudioSection: the menu's Audio & Voice block
          answer_card.gd  table_viewer.gd  diagram_view.gd  voice_visualizer.gd
  fx/     quiz_fx.gd        QuizFx: fx layer, streak meter, time gauges, answer burst
          sfx.gd  speech_chain.gd  ui_fx.gd  time_gauge.gd  streak_meter.gd
          result_gauge.gd  chapter_bars.gd  mode_badge.gd  shaders/
data/     question_bank.json (never edited by hand)  voices.json
assets/   diagrams/  sfx/  speech/<qid>__<voice>/ (generated, gitignored)
docs/     this file, DATA_PIPELINE, VOICE_READING_RULES, SFX_PLAN, KNOWN_ISSUES, ...
tools/    verify.sh  harness.gd  list_pck.py
          pipeline/  bank build, overrides, validator, spellcheck, OCR
          speech/    dump_speech.gd  pregenerate_speech.py  test_bundle.gd  check_export_pack.gd
          visual/    snap.gd  snap_all.gd  measure_fit.gd  compare_shots.py (output: .audit_tmp/)
          tests/     run_all.gd + suites, golden/ layout snapshots
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

The flow of one question: `_show_question` asks `session` for the record,
renders the stem, choices, table or figure, then `fit.begin()` shrinks the
screen until nothing scrolls. `_answer_selected` hands the pick to
`session.submit()`, which grades it and returns the verdict. `main` then
shows the feedback sheet, `QuizFx.play_answer` plays the burst, and
`fit.compact_answered` hides what no longer matters. `_tick_timer` drives
`session.tick()` once a second.

### Speech

`SpeechController` decides where each readout comes from, in this order:

1. The bundled recorded voice (`assets/speech/`, imported, ships in the pck).
2. On desktop, the Edge helper: a cached folder in `user://speech`, or a live
   request that plays each clip as it lands. The current and next question
   are prefetched.
3. Native OS text-to-speech (Android, or when Edge fails).

The **teach gate** is in `_play_speech_clip`, the one function that plays a
clip. A teach clip (the rule, which gives away the answer) never plays while
`want_teach` is false, and only answering sets it. The native TTS path has
the same check in `_play_next_native_tts_segment`.

The native TTS callbacks are registered as `Callable(self, "...")` on the
controller. Signal targets that the golden layout test records are
`main.speech._on_...`.

### The two layouts

Desktop and mobile have separate builders on purpose. They are about 90%
structurally alike but share almost no lines, and the desktop one reproduces
the legacy Windows UI exactly. Shared pieces are factored into `Widgets`,
`AppTheme` and `AudioSection`. Anything else that differs goes in the
builder, not behind `if ui_mobile` in main.

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
- `tools/tests/run_all.gd`: 20 suites, including `test_no_leak` (nothing
  before answering reveals the answer), `test_layout_tree` (serialised node
  tree of both layouts against `tools/tests/golden/`; `-- --update` rewrites
  the snapshots after an intended change) and `test_quiz_session`;
- `tools/harness.gd` on both layouts (quiz flow, speech queue, teach gate);
- the Python tests and the bank validator (`--no-warn`: 0 errors, 0 warnings).

Also:

- `tools/speech/test_bundle.gd`: every question resolves to its bundled clips (279/279).
- `tools/visual/measure_fit.gd`: share of questions that scroll before answering (0%).
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
