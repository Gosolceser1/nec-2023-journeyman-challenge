# ARCHITECTURE — refactoring `main.gd`

**Status:** design only. No code in this document has been applied.
**Current baseline:** `main.gd` @ 3,327 lines, 86 functions, 88 member vars. Harness **342 checks / 0 failures**. Godot 4.7.2, GDScript.

**Reading order:** §1 what hurts → §2 target architecture → §3 migration phases → §4 what *not* to do → §5 the state problem.

---

## 0. Baseline facts this plan is built on

Detailed function ranges and dependency measurements below describe the original planning baseline, not the current tree. Re-measure before each phase; do not use those historical line ranges as migration targets.

### 0.1 The safety net

`tools/harness.gd` (254 lines) is the only thing standing between a refactor and a silent regression. Verified green before writing this:

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/harness.gd
checks: 342  failures: 0    RESULT: PASS    EXIT=0
```

The harness reaches into `main.gd` through a **36-symbol surface** (members + methods). This is the migration contract — see §3.0.

| Harness symbol class | Symbols |
|---|---|
| Session state | `records` `order` `current_index` `score` `streak` `answered_count` `missed_questions` `session_length` `timed_session` `time_left` `timer` `current_answered` |
| Speech state | `speak_thread` `speak_generation` `speak_busy` `speech_queue` `speech_queue_index` `teach_from_index` `want_teach` |
| UI nodes | `answers_box` `read_button` `read_status_label` `menu_overlay` |
| Methods | `_start_quiz` `_show_question` `_answer_selected` `_next_question` `_show_results` `_tick_timer` `_stop_reading` `_toggle_read` `_play_speech_clip` `_on_speech_ready` `_exit_tree` `_join_speak_thread` |
| Const | `SESSION_TIME_SECONDS` |

**Consequence, stated once and obeyed throughout:** every phase must either (a) leave all 36 symbols valid on `main`, or (b) change `tools/harness.gd` in the *same commit* as the move. There is no third option. A phase that "would need a harness change later" is a phase that is not done.

### 0.2 Node-dependence audit — the fact that reshapes the plan

For every candidate function I measured two things: references to the 68 typed node-typed member vars, and node/engine operations (`create_tween`, `add_child`, `.visible=`, `.text=`, `add_theme_*`, `get_children()`, `get_viewport`, `OS.`, `DisplayServer.`, `Input.`, `Time.`).

| Cluster | Lines | Node-free | Verdict |
|---|---|---|---|
| `theme.gd` candidates (1757–1776) | 20 | **100%** | Extract first. Zero risk. |
| `nec_reference` + format helpers | 178 | **75%** | Extract early. |
| `bank_loader` (218–263) | 46 | 56% | Extract early. |
| `speech_controller` (2237–3013) | 777 | **22%** | Extract *last*, and only in two bites. |
| `quiz_session` (naive reading) | 522 | **0%** | **Cannot be extracted as written.** See §2.1. |

That last row is the single most important measurement in this document. The brief's framing — "own the 442 lines of game logic, testable without any Godot node" — does not hold against the current code. `_show_question` (1818–1927) makes 34 node ops and 55 node-var refs; `_show_results` (3151–3240) makes 30 and 56; `_answer_selected` (1945–2050) makes 28 and 46. Not one of the eight game functions is node-free. §2.1 explains what the 442-line module actually is, and it is not a straight move.

---

## 1. Current state analysis

### 1.1 The breakdown

`main.gd` is `extends Control` and owns four unrelated jobs. Line ranges are exact, taken from the current file.

| Concern | Lines | Range | % |
|---|---|---|---|
| UI construction | 1,378 | `_build_ui` 370–1070 (701), `_build_mobile_ui` 1071–1677 (607) | 42% |
| Speech / TTS | 777 | 2237–3013 | 25% |
| Game / session logic | 522 | 340–369, 1818–1944, 1945–2084, 3107–3150, 3151–3240 | 13% |
| Layout / input | 186 | 110–217, 3025–3106, 3252–3299 | 6% |
| Data / format | 196 | 218–339, 1777–1817, 2085–2125, 2126–2236 | 4% |

The speech figure is 777, not 835 — the 835 in the original brief folds in 43 tail lines (`_apply_touch_filters` 3025–3039, `_touch_filter_walk` 3040–3054, `_reset_pressed_cards` 3055–3063, `_clear_speech_highlight` 3064–3082, `_set_question_stem_glow` 3083–3106) that are touch/highlight concerns, not TTS.

### 1.2 What actually makes it hard

**(a) 88 member vars, of which 68 are typed node references.** Declarations occupy lines 16–108. Of these, 68 have a type like `Label`, `PanelContainer`, `Button`, `HBoxContainer`, `ProgressBar`, `RichTextLabel`, `VoiceVisualizer`, `AudioStreamPlayer`, `Thread`, `Timer`, `Control`, `MarginContainer`, `ScrollContainer`, `GridContainer`, `OptionButton`, `VBoxContainer`, `StyleBoxFlat`. The remaining 20 are the actual domain state.

The distribution shows the split plainly (line-cluster ref counts):

```
info_label      93 refs / 11 funcs      records          12 refs /  8 funcs
voice_picker    44 /  9                order            18 /  7
read_button     42 /  9                current_index    15 /  7
next_button     37 /  7                current_answered 12 /  8
dock_visualizer 32 /  7                speak_generation 16 /  9
```

There is no boundary because there is no layer: `_answer_selected` (1945) reads `records`/`order` and writes `feedback_title.text` and `speak_generation`'s neighbour `want_teach` in the same breath. Domain and presentation are interleaved at statement granularity.

**(b) Two UI builders that are structurally identical and textually different.**

This is the finding that most changes the answer, so here it is precisely.

- Member vars constructed by `_build_ui`: **47**. By `_build_mobile_ui`: **45**.
- Constructed by **both**: **45**. Desktop-only: `prompt_visualizer`, `prompt_voice_badge`.
- **Construction order is identical** for 38 of the 45 shared anchors; it first diverges at anchor #39, where desktop builds `dock_visualizer` and mobile builds `restart_button`.
- Structural events (`.new()`, `.add_child()`, theme overrides, visibility/size assignments): desktop 439, mobile 423, **396 shared (90.2% / 93.6%)**.
- Shared local variable names: **65 of 78 / 71**.

And yet:

- Verbatim identical **statements**: 454 of 635 desktop / 587 mobile = **71.5% / 77.3%** (Jaccard 0.592).
- Verbatim identical **4-line blocks across the two builders: ZERO.**

So the two builders are the same program with different numbers. Same tree shape, same call sequence, same variable names — different sizes, font sizes, colours, spacing, and ordering in the dock. The 71% statement overlap is almost entirely trivial one-liners (`read_status_label = Label.new()`, `x.add_child(y)`, `)`). The *meaningful* overlap — the sequences that build a header, a badge row, the question panel, the feedback panel — is **structurally 90% and textually 0%**.

**The 80% premise in the brief is wrong in a way that matters.** You cannot factor out shared builder helpers by moving text, because no text is shared. You would have to *re-author* both builders against a common helper vocabulary, parameterised by layout metrics. That is a large behavioural change wearing a refactor's clothes, and it is the reason the migration plan below ends at a partial UI consolidation rather than a full one.

**(c) 42 `is_instance_valid` guards, and they are load-bearing.**

```
pass_badge           6    dock_visualizer      5    prompt_voice_badge   4
prompt_visualizer    4    info_label           3    lookup_box           2
chapter_hint_label   2    formula_box          2    question_formula_label 2
question_hint_row    2    voice_picker         2    + 12 singletons
```

Representative guards:

- `654` / `1310` — `if is_instance_valid(lookup_box) and is_instance_valid(chapter_hint_label):`
- `2055`, `2068`, `2074`, `2080` — four separate `pass_badge` guards inside `_update_score_badges`
- `3168`, `3173` — `pass_badge` inside `_show_results`
- `2693` / `2957` — `if is_instance_valid(info_label) and info_label.visible:`
- `1790` — `if not is_instance_valid(question_table_scroll): return`

These exist because shared logic runs against a node graph that only *one* of the two builders created. `_update_score_badges` (2051–2084) runs in both layouts but `pass_badge` is created by both too — so those guards are not obviously necessary there. Meanwhile `2693`/`2957` guard a field that genuinely is not built in both. **The guards encode a real asymmetry that nobody documented**, which means the correct move is to *keep every guard verbatim* through the migration and delete them only in a separate, provable pass. Phase 6 handles that.

**(d) No signals at all.** `grep '^signal '` returns nothing. The node graph is wired entirely through direct member access and `Callable(self, "...")` strings at lines 2619–2621. There is no event seam to refactor toward — every decoupling decision has to be invented, which raises the cost of each one.

**(e) Cross-module duplication already present.** Eight function names are defined in more than one module:

```
format_answer_number   speech_text.gd:7    unit_matcher.gd:5
answer_match_candidates speech_text.gd:10  unit_matcher.gd:10
prompt_intent          speech_text.gd:78   audio_explanation_generator.gd:8
plain_words            speech_text.gd:81   audio_explanation_generator.gd:285
lesson_point           speech_text.gd:84   audio_explanation_generator.gd:175
prompt_with_answer     speech_text.gd:87   audio_explanation_generator.gd:192
answer_sentence        speech_text.gd:90   audio_explanation_generator.gd:202
```

`speech_text.gd` (389) and `audio_explanation_generator.gd` (346) both own answer-matching and lesson phrasing. `main.gd` and `table_viewer.gd:5` both define `panel_style`. This is outside the refactor's scope — see §4.5 — but it is why the plan does not propose touching the audio-content layer at all.

### 1.3 The 4,879-line project context

```
main.gd                              3299      speech_text.gd                    389
answer_card.gd                        427      audio_explanation_generator.gd   346
table_viewer.gd                       200      unit_matcher.gd                   119
voice_visualizer.gd                    99
```

`main.gd` is 68% of all GDScript in the project. Every sibling is already a well-behaved `RefCounted`/`Control` with a `class_name` and static helpers. The pattern to follow already exists in the codebase.

---

## 2. Target architecture

### 2.1 Design principle, and one deliberate departure from the brief

The brief proposes `quiz_session.gd` as a `RefCounted` holding "session state machine — order, score, streak, timing, question flow", testable without any Godot node, owning "the 442 lines of game logic."

**The 442 lines do not exist as a node-free unit, and cannot be made into one by moving them.** The audit in §0.2 is unambiguous: 0% of the eight game functions is node-free. `_show_question` interleaves state reads with 34 node operations. A `QuizSession` that "owns" that code must either receive 30+ node parameters per call or reach back into the UI — which is the current coupling with an extra hop.

The resolution: **split by node-dependence, not by line range.** Two modules instead of one:

- **`quiz_session.gd` (`RefCounted`)** — the *pure* state machine. Order, score, streak, timing, question advance, verdict computation, missed-list construction. **This is the part that is genuinely node-free and genuinely worth testing without an engine.**
- **`quiz_presenter.gd` (`Node`)** — the *rendering* of that state. Keeps the tween/populate/format code from `_show_question`, `_answer_selected`, `_show_results`, `_update_score_badges`, `_tick_timer`, `_do_render_info_label`.

This is the same split `speech_controller` needs anyway (§2.2), so the two hardest clusters end up with one consistent architecture. It is also the only split that makes the pure half *actually* pure rather than nominally pure.

### 2.2 Module inventory

Paths are project-root relative. `class_name` matches the existing sibling convention (`TableViewer`, `AnswerCard`, `VoiceVisualizer` are all `class_name` + `RefCounted`/`Control`).

| # | File | `class_name` | Base | Owns | Lines moved | Nature |
|---|---|---|---|---|---|---|
| 1 | `theme.gd` | `AppTheme` | `RefCounted` | `_panel_style` 1757–1763, `_ui_font` 1765–1770, `_monospace_font` 1772–1775, colour constants | 20 + consts | **MECHANICAL** |
| 2 | `nec_reference.gd` | `NecReference` | `RefCounted` | `_article_title` 264–285, `_format_nec_reference` 287–294, `_lookup_navigation_path` 296–338, `_is_reference_seeking` 1796–1802, `_chapter_only_path` 1804–1809 | 108 | **MECHANICAL** |
| 3 | `bank_loader.gd` | `BankLoader` | `RefCounted` | `_load_bank` 218–237, `_normalize_record` 238–262 | 46 | **MECHANICAL** (one seam: `records`) |
| 4 | `speech_controller.gd` | `SpeechController` | `Node` | TTS, `speak_thread`, generation counters, bundle cache, voice catalog | 777 | **BEHAVIOURAL** |
| 5 | `quiz_session.gd` | `QuizSession` | `RefCounted` | pure state machine | ~200 | **MECHANICAL** state, **BEHAVIOURAL** timing |
| 6 | `quiz_presenter.gd` | `QuizPresenter` | `Node` | render half of the game cluster | ~420 | **BEHAVIOURAL** |

`main.gd` after all phases: **~500–600 lines**, and it becomes what it should have been from the start — a composition root that builds the UI, holds the node references, and forwards events.

### 2.3 What moves where, in detail

**`theme.gd` — 20 lines, 100% node-free.** Pure static factories. `AppTheme.panel_style(fill, border, width, radius)`, `AppTheme.ui_font(weight)`, `AppTheme.monospace_font()`. The palette belongs here too: 74 unique hex literals, 295 occurrences, and `#38bdf8` alone appears 48 times. Naming them (`AppTheme.ACCENT`, `AppTheme.OK`, `AppTheme.BAD`, `AppTheme.MUTED`, `AppTheme.PANEL_BG`) is a mechanical substitution with zero behaviour change.

`table_viewer.gd:5` and `answer_card.gd:21` each build their own copies of the same factories. They should call `AppTheme`. That is one line each — but see §4.5 on why it is deferred.

**`nec_reference.gd` — 108 lines, 100% node-free.** Five functions, zero node references, zero engine calls beyond `RegEx`. `AppTheme`-style static utility. This is textbook shared logic and it is currently polluting a `Control`.

**`bank_loader.gd` — 46 lines.** `_normalize_record` (238–262) is already pure. `_load_bank` (218–237) has exactly 3 node-var references and zero node operations — it uses `FileAccess` and `JSON`, which are engine *core* classes that work perfectly well in a `RefCounted` with no scene tree. The "ui refs" it trips are the `records` member it appends to; the seam is trivial: `BankLoader.load(path) -> Array[Dictionary]`, caller assigns `records = ...`. The `for raw in source` loop at 228–231 and its twin at 233–236 are the same loop over two shapes; worth collapsing while moving.

**`speech_controller.gd` — 777 lines, only 22% node-free.** This is the hard one and the plan splits it:

- **Phase 3 moves the 12 node-free functions (174 lines).** `_native_voice_tier` (2292–2305), `_pretty_voice_lang` (2306–2325), `_voice_display_label` (2326–2334), `_bundled_speech_folder` (2457–2475), `_bundled_teach_tail_offset` (2476–2516), `_speech_cache_matches` (2762–2796), `_count_teach` (2586–2592), `_teach_index_of` (2593–2600), `_update_read_status` (2601–2609), `_status_with_voice` (2352–2355), `_save_voice_choice` (2410–2414), `_on_voice_picked` (2289–2291). These are pure string/dict/array logic — bundle path construction, manifest matching, voice-label formatting. `_bundled_teach_tail_offset` (41 lines) is the single densest win in the file: it contains FIX_PLAN item 4, the teach-tail suffix match that fixed 279/279 clip lookups, and it touches no node at all.
- **Phase 4 moves the remaining 603 lines** as a whole `Node`, accepting that it needs a `host` reference for the UI members it legitimately drives (`dock_visualizer`, `prompt_visualizer`, `prompt_voice_badge`, `read_button`, `read_status_label`, `info_label`, `answers_box`). That is a real coupling and Phase 4 is where it is introduced — deliberately, in its own commit, where the harness can watch it.

The `_speak_worker` thread body (2797–2884, 88 lines) is the single most dangerous function in the project. It touches zero UI vars, but it calls `call_deferred("_on_speech_ready", ...)` three times (2804, 2809, 2883) — the *return path from a worker thread*. It is the reason Phase 4 requires a real on-device check and cannot be signed off headless alone.

**`quiz_session.gd` — the pure state core, ~200 lines.**

Extracted from: `_start_quiz` 341–362 (order build, resets, timer start/stop), `_answer_selected` 1953/1968–2006 (verdict branches, missed-list append), `_next_question` 3144–3150, `_tick_timer` 3108–3110/3119–3120/3133–3139, `_show_results` 3163–3164/3175 and the `missed_questions` loop 3202–3232, `_format_time` 3141–3143, `_gist_task_sentence` 1928–1944, `_echoes_any` 2103–2110.

The classification in §0.2 shows the split point: of `_answer_selected`'s 106 lines, **57 are pure state** (`answered_count += 1`, the `streak`/`score` branches, the two `missed_questions.append({...})` dict literals at 1974–1982 and 1998–2006) and 45 are UI. The dict literals are the tell — they are *data about an answer*, not a rendering of one. They belong in the session.

API shape: `QuizSession.begin(question_count, time_limit, timed, mode_name)`, `.submit(selected: int) -> Dictionary` (returns a verdict describing what changed, which the presenter renders), `.tick(seconds: int) -> Array[String]` (returns "which clocks expired"), `.current_record() -> Dictionary`, `.advance() -> bool`. No `Node`, no `Control`, no tween, no theme. **Testable with `QuizSession.new()` and nothing else** — which is the entire point.

**`quiz_presenter.gd` — the render half, ~420 lines.** Absorbs `_show_question` (1818–1927), `_answer_selected`'s UI half, `_update_score_badges` (2051–2084), `_show_results`' UI half, `_do_render_info_label` (2126–2236), `_render_code_provision` (2118–2125), `_append_answer_highlight` (2085–2102), `_populate_reference_table` (1777–1784), `_scroll_feedback_table_to_match` (1786–1787), `_scroll_question_table_to_top` (1789–1794). 111 lines of `_do_render_info_label` alone reference 31 UI vars and zero node operations — pure `RichTextLabel` mutation, which is presentation by definition.

### 2.4 UI: honest recommendation

The measurement in §1.2(b) says the 80% premise is false. So:

- **Do not** build a `ui_builder.gd` with shared header/dock/question-panel helpers. There is no shared text to move, and authoring one means rewriting 1,308 lines against an invented API with no harness coverage of layout. Highest risk, lowest certainty, in the entire plan.
- **Do** introduce `ui_nodes.gd` (a `RefCounted` holding **references**, not construction) as the §5 mechanism. This is the part that pays off: it replaces the 68 node-typed member vars with one object, which is the precondition for phases 4–6, and it moves no construction logic.
- **Do** treat desktop-vs-mobile unification as a *separate future project*, not a phase. If it is ever attempted, the first step is a golden-output test that serialises the built node tree (type, path, size flags, stylebox fills) for both builders, captured *before* any change. Without that baseline the refactor is unfalsifiable.

---

## 3. Incremental migration plan

Every phase is independently shippable, independently revertible, and harness-green on arrival. Ordering is by **value ÷ risk**, descending.

### 3.0 Standing rules

1. **One commit per phase.** No phase bundled with the next.
2. **Harness green before commit**, on both layouts where relevant:
   ```
   ./Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/harness.gd
   ./Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/harness.gd -- --mobile-ui
   ```
3. **Rollback is `git revert <sha>`.** Every phase is additive-then-redirect, never redirect-then-delete. The old function survives in `main.gd` (unreferenced) until the *following* phase deletes it. That gives a window where a failure is a one-line pointer swap back, not a rebase.
4. **Guards move verbatim.** `is_instance_valid` is never reworded, reordered, or "cleaned up" during a move. §3.7 handles them separately.
5. **Verify the patch landed** — `grep` for the new symbol and confirm the match count. A `patch` on a 3,327-line file has reported success without changing anything.
6. **No new `signal`s until phase 5.** Adding signals and moving code together makes failures unattributable.

### 3.1 Phase 1 — `theme.gd` (MECHANICAL) · highest value ÷ risk

**Moves:** `_panel_style` 1757–1763, `_ui_font` 1765–1770, `_monospace_font` 1772–1775 → `AppTheme` statics. Name the top ~12 colours as constants; replace the 48 `"38bdf8"` literals with `AppTheme.ACCENT` and the rest by frequency.

**Why first:** 20 lines that are **100% node-free**; zero semantic content; the call sites are pure text substitution. It also establishes the `class_name` + `RefCounted` + statics pattern that phases 2–4 all follow, so the first commit teaches the codebase the convention. And it gives every later phase a home for colours, which stops the palette spreading further.

**Risk:** none behavioural. `SystemFont` construction is identical, so no font resolution changes.

**Rollback:** `git revert`. Nothing depends on it.

**Harness proves:** 342/0 unchanged. Fonts and panels are constructed identically, so every one of the 279 records still renders.

**Note:** do **not** touch `table_viewer.gd:5` or `answer_card.gd:21` in this phase (see §4.5).

### 3.2 Phase 2 — `nec_reference.gd` (MECHANICAL)

**Moves:** the five pure functions of §2.3, 108 lines, plus `_gist_task_sentence` (1928–1944) and `_echoes_any` (2103–2110) if they come free.

**Risk:** low. `RegEx.create_from_string` is a `RefCounted` core type, usable anywhere. The NEC article-title table (268–284) and chapter-name table (299–309) are literal data — pure move.

**Rollback:** revert. Call sites are one-line each.

**Harness proves:** 342/0. `_show_question` and `_show_results` both format references; the 279-record sweep exercises every branch of `_article_title` and `_format_nec_reference`, and `_answer_every_record` covers `_gist_task_sentence` for all 279.

**Do not** fold in `_populate_reference_table` (1777–1784) or the two scroll helpers (1786–1794) — they write `feedback_table_match_row`/`feedback_table_row_count` and touch `feedback_table_scroll`. They belong to the presenter (§3.6).

### 3.3 Phase 3 — `bank_loader.gd` (MECHANICAL, one seam)

**Moves:** `_load_bank` 218–237, `_normalize_record` 238–262.

**Seam:** `records` is assigned, not appended-in-place, by the caller. `main.gd:139` becomes `records = BankLoader.load(BANK_PATH)`.

**Risk:** low, with one sharp edge. `_load_bank` currently *appends* to `records` and returns early on a missing file (220, 223) leaving `records` untouched. A `load()` that returns `[]` on failure is a behaviour change if anything ever re-calls it. Preserve the early-return-`[]` semantics explicitly and let `_ready`'s existing `if records.is_empty(): _show_error(...)` (140–141) be the single failure path.

**Rollback:** revert.

**Harness proves:** `main.records.size() == 279` (harness line 24) is the direct assertion. The 4× `_run_session` and `_answer_every_record` sweep then prove every normalised record is still well-formed — this is the strongest single check in the suite and it lands on this phase.

### 3.4 Phase 4 — `speech_controller.gd`, bite 1 (MECHANICAL)

**Moves:** the 12 node-free speech functions, 174 lines (§3.1 of §2.3).

**Why not the whole thing at once:** the 22% node-free figure means the other 78% needs a host reference. Splitting the move means the low-risk 174 lines land under full harness coverage first, and the risky 603 lines land in Phase 5 with a known-good precedent and a smaller diff to review.

**Risk:** low for these twelve. They are string/dict/array logic.

**Rollback:** revert.

**Harness proves:** 342/0. The bundle cache is exercised for real: `_speech_sanity` (harness 124–146) walks all 279 records × all segments in both modes, and the teach-gate tests (148–194) drive `_bundled_teach_tail_offset` through the missing-file and corrupt-file branches. That is genuine coverage of the code being moved, not a smoke test.

**Add to the harness now** (same commit): a direct assertion that `_speech_cache_matches` still resolves 279/279. Today that coverage is only *indirect* — it exists only insofar as the teach-gate tests happen to call it. FIX_PLAN item 4 claimed 279/279; there is no check that asserts that number. Make it one.

### 3.5 Phase 5 — `speech_controller.gd`, bite 2 (BEHAVIOURAL — the risky one)

**Moves:** the remaining 603 lines as a `Node` child of `main`, holding a `host` reference to `main` for the UI members it drives.

**This is the phase most likely to break the app.** Specific hazards, all previously fixed bugs that live in this code:

- `_on_speech_ready` (2885–2932) — FIX_PLAN item 3. The generation check must precede the `speak_busy = false` mutation. Do not reorder while moving.
- `_play_speech_clip` (2933–2991) — FIX_PLAN item 1. The teach-gate lives in the function that owns the loop, not its callers. Do not "tidy" the skip-and-recurse branch.
- `_on_native_utterance_canceled` (2645–2660) — FIX_PLAN item 13. Needs the same id + generation guards as its ENDED and STARTED siblings. All three are registered as `Callable(self, "...")` at 2619–2621 — **these become `Callable(speech, "...")` and the `self` changes**. This is the single easiest way to silently disable Android TTS.
- `_speak_worker` (2797–2884) — the worker thread. `call_deferred` from a thread onto a different object still marshals correctly in Godot 4, but the object identity changes.
- `_exit_tree` / `_join_speak_thread` (110–119) — harness lines 196–208 assert `not main.speak_thread.is_started()` after cleanup. **The harness will need updating in this same commit** to look at the controller, and it must keep asserting the same invariant. This is rule 3(b) in action.

**Verification beyond the harness:** on-device Android check of Read / Stop / Read-again, teach-gate audible behaviour, and voice-picker refresh. Headless cannot hear audio; the harness proves the *state invariants* (busy flag, queue index, thread joined), not the experience. **Do not ship phase 5 on headless evidence alone.**

**Rollback:** revert. Nothing after phase 5 depends on the controller existing.

**Harness proves:** 342/0 with the two speech tests rewritten against the controller. `_stale_callback` (210–254) and `_teach_gate` (148–194) must keep asserting their exact invariants — the harness comments at 173–176 and 179–181 are precise about what is and isn't being tested, and that precision is the asset here.

### 3.6 Phase 6 — `quiz_session.gd` + `quiz_presenter.gd` (MIXED)

**Moves:** per §2.3. The pure core (`QuizSession`) first, in its own commit, with `main.gd` holding a `QuizSession` instance whose members are read through it.

**Harness load:** this is the heaviest phase. The harness pokes session state directly at lines 70, 86, 91–103, 116–119, 221–239, 225–233. Every one of those becomes `main.session.<field>`.

**Rule:** rewrite the harness in the same commit, and add the thing it is currently missing — **`quiz_session.gd` should be the first thing the harness tests *without* `Main.tscn` at all.** No scene tree, no `Control`, just `QuizSession.new()` and a synthetic record list. That directly delivers the "testable without any Godot node" property, and it is the first place in the project's history that any of this logic has been tested in isolation.

**Risk:** moderate. Two failure modes: (a) a missed field in the harness rewrite, caught immediately by the compile; (b) a *silent* semantics change in the verdict branch — e.g. `submit()` returning before `missed_questions.append` at 1998. The harness's `score + missed == answered` invariant (line 118) is the specific check that catches this, and it is already written. Keep it.

**Timing subtlety:** `_tick_timer` (3107–3140) checks `not speak_busy and not reader.playing` before decrementing `question_time_left` (3119) and before auto-failing (3133). Audio state is *game* state here. The pure core cannot know about it, so the presenter must pass a "speech is idle" boolean into `tick()`. Get this signature right, or the question clock drifts during playback — a bug the existing harness will *not* catch, because the timer-expiry test (51–57) runs with no audio active. **Add a harness case that ticks the clock while `speak_busy` is true.**

**Rollback:** revert.

### 3.7 Phase 7 — guard removal (BEHAVIOURAL, optional, last)

Only after phases 1–6 are shipped and the node graph has a single, known construction path. For each of the 42 guards, establish *why it exists* — usually by deleting it and finding which layout breaks — and delete only those proven unnecessary.

`_update_score_badges`'s four `pass_badge` guards (2055, 2068, 2074, 2080) are the first candidates: `pass_badge` is constructed by **both** builders, so those four look vestigial. "Look vestigial" is not proof. This phase is explicitly allowed to be abandoned; a green 342/0 with 42 guards is a better outcome than a regression chasing a tidy-up.

### 3.8 Ordering summary

| Phase | Content | Nature | Risk | Reversible | Value |
|---|---|---|---|---|---|
| 1 | `theme.gd` | MECHANICAL | ~0 | trivially | establishes pattern; stops palette spread |
| 2 | `nec_reference.gd` | MECHANICAL | low | trivially | −108 lines of noise |
| 3 | `bank_loader.gd` | MECHANICAL | low | trivially | bank parsing becomes testable |
| 4 | speech bite 1 (174L) | MECHANICAL | low | trivially | 12 pure fns out of the UI node |
| 5 | speech bite 2 (603L) | **BEHAVIOURAL** | **high** | yes, single commit | −603 lines; needs on-device |
| 6 | `quiz_session` + `quiz_presenter` | MIXED | moderate | yes | the big one; enables node-free tests |
| 7 | guard removal | BEHAVIOURAL | moderate | yes | optional; may be abandoned |
| — | unified UI builder | — | **very high** | — | **deferred, see §2.4 / §4.1** |

Phases 1–4 are ~350 lines of movement with near-zero risk and can be done in a sitting. The real work is phases 5 and 6, and phase 5 is the one that can lose you the app.

---

## 4. What NOT to extract

### 4.1 A unified desktop/mobile UI builder — **the big one**

1,308 lines, 90% structurally identical, 0% textually identical. Tempting, and the wrong first move. The measured fact is that no code is shared, so "extraction" here is a rewrite of both builders against a new API with **no layout regression coverage** — the harness checks quiz flow and speech, not layout, and headless returns `0` from `get_combined_minimum_size()` and a fake `960x960` from `get_visible_rect()` (FIX_PLAN, verification-gotchas section). A layout refactor cannot be verified by the safety net that exists.

Do it only with a golden-output test that serialises the built tree for both layouts, captured from the current code first. Until that exists, this is not refactoring — it is a rewrite with a rollback.

### 4.2 The `RichTextLabel` / `info_label` rendering (111 lines, `_do_render_info_label`)

It looks like a template concern deserving `info_formatter.gd`. But it is pure `RichTextLabel` mutation — `push_color`/`add_text`/`pop` sequences that only work on a real node. Extracting it changes nothing structurally and risks the answer-leak redaction that `AudioExplanationGenerator.redact_answer_spans` provides (called at 1844). It goes to `quiz_presenter.gd` and stops there.

### 4.3 `_apply_touch_filters` / `_touch_filter_walk` / `_reset_pressed_cards` (3025–3063)

39 lines, node-only, platform-specific, and fixed by three separate FIX_PLAN items (14, and the touch-target research). It is already a self-contained pair. It moves to the presenter when the presenter exists, and not before.

### 4.4 The `Timer` and the `AudioStreamPlayer` as separate modules

Both are 1–3 lines of setup in `_ready` (132–138). Extracting them produces modules smaller than the ceremony of adding them, and the harness asserts on `main.timer` and `main.reader` directly (57, 3119, 3263). Worse, `_tick_timer` reads both — so a "clean" `QuizSession` would have to be told about audio anyway. Leave them in `main.gd`.

### 4.5 The existing cross-module duplication (§1.2(e))

`unit_matcher.gd` (119 lines) duplicates five of `speech_text.gd`'s functions; `audio_explanation_generator.gd` duplicates seven; `table_viewer.gd:5` duplicates `panel_style`; `answer_card.gd:21` duplicates the font list. This is real and it should be cleaned up eventually.

**It is not part of this refactor.** Those modules are consumed by the *audio generation pipeline*, which is a build-time concern (279 pre-bundled clips, `pregenerate_speech.py`). Touching them changes spoken content, which no automated check can verify — the harness asserts structure, never audio. Bundling that cleanup with a structural refactor makes a spoken-content regression invisible in the harness and near-impossible to bisect. **Separate PR, separate review, ear required.**

### 4.6 A `signals` layer on `main.gd`

`main.gd` declares zero signals and wires everything through direct member access plus three `Callable(self, "...")` strings. Introducing signals would be architecturally correct and is explicitly *not* in these phases. Adding an event system and moving code in the same commit makes every failure ambiguous, and the harness — which drives `_answer_selected(i % 2)` and reads `speech_queue_index` after the fact — depends on synchronous, deterministic ordering that signals make harder to reason about. Signals come after phase 6, in their own project, if at all.

### 4.7 Splitting the 88 vars "just because there are 88"

88 is a symptom, not a target. §2.3 moves 68 of them into `ui_nodes.gd` and 20 into `quiz_session.gd` — but the count reaches 88 by a *different route*, not by a line-by-line partition. Do not start by sorting declarations into buckets; that is busywork with a nonzero chance of a typo, and a typo in a declaration is invisible until a layout-dependent code path runs.

---

## 5. The state-management problem

### 5.1 The diagnosis

88 members, 68 of them node references, and 42 guards because shared logic reads fields only one builder assigns. The guards are not defensive programming — they are **the coupling made visible**. Every `is_instance_valid(lookup_box)` is a statement that `main.gd` does not know what shape its own UI is. That ignorance is the actual problem; the 88 vars are its symptom.

### 5.2 Three categories, three treatments

**(a) → Data object. 20 members.** `records` `order` `current_index` `score` `streak` `answered_count` `current_answered` `missed_questions` `time_left` `session_length` `session_time_limit` `timed_session` `session_name` `question_time_left` `_current_record` `_current_correct_answer` `_info_table_highlighted` `feedback_table_match_row` `feedback_table_row_count` `_active_teach_line`.

These are the domain. They move into `QuizSession` (phase 6) and are the part testable without a node. `_current_record`/`_current_correct_answer` are derived from the current position and can become read-only accessors rather than stored fields — a genuine simplification, since they are currently set in two places and can drift.

**(b) → Node references. 68 members.** These stay references. They belong in `ui_nodes.gd`, a `RefCounted` that holds references and is *constructed after* a builder runs:

```
class_name UiNodes extends RefCounted
# holds: main_margin, menu_overlay, question_panel, answers_box, read_button,
#        dock_visualizer, …  (all 68)
```

`main.gd` keeps one member, `ui`, instead of 68. Behaviour is identical: the builders assign into `ui` exactly as they assign into members today, so `is_instance_valid(x)` becomes `is_instance_valid(ui.x)` and every guard still works. **The guards survive the refactor intact** — which is the point, and is why §3.7 exists to remove them later under proof rather than during the move.

**`ui_nodes.gd` holds no construction logic.** It does not build anything. That is a deliberate constraint, and it is what makes this step safe enough to do at any point in the plan: it relocates references without relocating a single `add_child` or `theme_override`.

**(c) → Stays on `main.gd`, deliberately.** Six members are not part of any module:

`ui_mobile` (78) — a build-time layout switch set in `_ready` from cmdline args (123). It selects which builder runs. It is not data and not a UI node; it is a configuration flag. Note the harness gotcha: setting it on the instance before `add_child` is silently overwritten, so any layout test must pass `--mobile-ui` on the command line.

`_last_go_back_msec` (79) — back-button debounce state, 600 ms window (3256–3262). Belongs to whichever node handles back input.

`speak_thread` / `speak_generation` / `speak_busy` (94–96) — owned by `SpeechController` after phase 5.

`menu_mode_buttons` (92) — an `Array[Button]` the menu rebuilds; menu-owned.

`_question_stem_glow_style` (108) — a cached `StyleBoxFlat`. It is theme state and could go in `AppTheme`, but it is mutated in place at runtime (3090–3106); leave it until phase 7.

### 5.3 How the two builders share it

They share a **single `UiNodes` instance**, passed to both. Each builder populates the subset it constructs; the other leaves those fields null. The `is_instance_valid` guards then do exactly what they do today — return early when the field was never assigned. No behaviour change, no new failure mode, and the asymmetry that the guards encode becomes *documented* rather than folklore.

Concretely, the only two fields that differ today are `prompt_visualizer` and `prompt_voice_badge` (desktop-only, per §1.2(b)). Every guard that references them is legitimately desktop-conditional. That is a fact worth writing down next to the guards, because the next person to read `2565: if is_instance_valid(prompt_voice_badge):` will otherwise assume the author was guessing.

The same applies in the other direction: after extraction, `SpeechController` needs 7 host references, `QuizPresenter` needs ~31, and `QuizSession` needs **zero**. That ratio — 0 / 7 / 31 — *is* the architecture, and it is the number to keep getting smaller.

### 5.4 When to do the `ui_nodes.gd` step

After phase 3, before phase 4. Rationale: phases 1–3 are self-contained and don't need it; phase 4 introduces the first module that needs to reach back into the UI; having `UiNodes` in place means the first such reach is written once, correctly, instead of being invented 60 times across phases 4–6.

Because `UiNodes` is pure reference relocation with zero construction logic, it is independently revertible and independently harness-green — the 279-record sweep renders every control the builders create.

---

## 6. One-page summary

- **Baseline is green and verified:** 342 checks, 0 failures, exit 0.
- **The 442-line `quiz_session` does not exist as a node-free unit** — 0% of the game cluster is node-free. It must be split into a pure `QuizSession` (~200 lines, 0 UI refs, testable with no node) and a `QuizPresenter` (~420 lines). This is the single biggest correction to the brief.
- **The 80% UI overlap is also wrong.** 90% structural, 0% textual: zero verbatim 4-line blocks. A shared builder helper is a rewrite, not an extraction, and cannot be verified by the existing harness. Deferred to §4.1.
- **Highest value ÷ risk: Phase 1, `theme.gd`** — 20 lines, 100% node-free, establishes the pattern, contains the 295-literal palette.
- **Highest risk: Phase 5, `speech_controller.gd` bite 2** — 603 lines, contains the thread, the teach-gate, and three `Callable(self,...)` TTS registrations whose `self` must change. Cannot be signed off headless; needs a device.
- **The 42 guards are the coupling made visible** and must move verbatim, then be removed only under proof, in a separate optional phase.
- **The state fix is not "sort 88 vars into buckets"** — it is 20 domain members into `QuizSession`, 68 node references into a reference-only `UiNodes`, and 6 deliberately left on `main.gd`. The 0/7/31 dependency ratio is the architecture.
- **Do not touch the audio pipeline** (`speech_text.gd` / `audio_explanation_generator.gd` duplication). Separate PR, ear required.
