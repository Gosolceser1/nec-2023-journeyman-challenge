# Fix Plan — NEC 2023 Journeyman Challenge

Status: all items below are DONE and verified unless marked OPEN.
Verification: `tools/harness.gd` — 342 checks, 0 failures, on desktop + `--mobile-ui`.
Run: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/harness.gd`

## Fixed — correctness

1. **Answer leak via missing audio clip** (`main.gd` `_play_speech_clip`)
   The teach-gate only existed in the callers. The skip-and-recurse branch for an
   unopenable mp3 bypassed it and narrated the answer pre-answer. Gate moved into
   the function that owns the loop.

2. **TTS thread never joined** (`main.gd` `_exit_tree` / `_join_speak_thread`)
   `speak_thread` was started and never `wait_to_finish()`'d. Godot warned on every
   teardown and could tear the thread down mid-write.

3. **Stale speech callback cleared the live busy flag** (`main.gd` `_on_speech_ready`)
   Generation check ran *after* `speak_busy = false`, so a cancelled request
   cleared the flag of the request that superseded it, letting a duplicate
   synthesis replace a running thread. Check now precedes the mutation.

4. **"Hear the rule" never used bundled clips** (`main.gd` `_bundled_teach_tail_offset`)
   A teach-only request was matched against the WHOLE manifest, so it always missed
   and re-synthesised over the network. Teach segments are a contiguous tail of the
   bundle; now matched as a suffix and playback seeks to the offset.
   Verified: 279/279 resolve, 0 offsets pointing at a non-teach clip.

5. **`NOTE 1:` not recognised as a note row** (`table_viewer.gd` `is_note_row`)
   Only the bare `NOTE:` prefix matched, so numbered notes rendered as data rows,
   inflating the row count and hiding the note from the note strip.

6. **`highlighted` true with zero highlighted cells** (`table_viewer.gd`)
   The flag OR'd in a keyword-only row match, which paints nothing, so it suppressed
   the ANSWER DETAIL fallback in `main.gd` while nothing was actually highlighted.
   Flag now means "an answer cell is coloured".

7. **`speakable()` mangled 4+ underscore runs** (`speech_text.gd`)
   `"___"` then `"__"` left a trailing `_`: `"a____at"` was spoken as
   "a blank _at". Now one regex consumes the whole run.

8. **`redact_answer_spans` skipped all 1-char needles** (`audio_explanation_generator.gd`)
   Single digits are now allowed (boundary-anchored, and the exact form a word
   answer takes). 5 records have a 1-char answer.

## Removed — dead code

- `main.gd::_scroll_question_table_to_match()` — never called
- `main.gd::question_table_match_row`, `question_table_row_count` — written, never read
- `speech_text.gd::is_word_character()`, `_is_spoken_duplicate()`, `code_lesson()` — no callers

Verified by reference analysis that counts `.method()` calls and string-based
callbacks (`Callable(self,"x")`, `call_deferred("x")`). An earlier naive pass
reported 19 "dead" functions; all 15 of those were false positives.

## Gemini / third-party AI in UI

**None found.** Byte-level search of every file in the project (source, data,
build, `.pck`, binaries) for `gemini` returns 6 hits, all substring false
positives inside binaries: `languageministers` and `GetLargePageMinimum`
(Win32 API). No `google`/`bard`/`openai` reference in any `.gd`, `.json`, `.cfg`
or `.tscn`; the `google` strings in the shipped `.exe` are SDL2's
"Google Stadia Controller" database and `com/google/android` Java paths.
No AI attribution in any UI string or question-bank field. Nothing to remove.

## Fixed — Android TTS (round 2)

9. **"Hear the rule" bundle** — regenerated. `pregenerate_speech.py` rebuilt
   `final-exam-#5-050` (7 clips); 278 already cached, 0 failed. The manifest
   comparison then accepts it.

10. **Android voice refresh was dead code** (`main.gd` `_refresh_native_voices`)
    The guard was `voice_picker.item_count > 1`, but the picker was always seeded
    with the bundled Aria entry + "System default" = 2 items, so it returned early
    forever and late-arriving real OS voices never installed — leaving a cloud
    Edge voice id selectable that Android TTS does not know. Now gates on the OS
    voice list being non-empty.

11. **Fake cloud voice offered on Android** (`_populate_voice_picker_native`)
    Seeded `Aria · US · Female` (an Azure Edge cloud id) unconditionally. Removed;
    the picker is now built purely from real OS voices, with "System default" only
    when the OS reports none.

12. **Duplicate picker entries on refresh** (`_populate_voice_picker_native`)
    Only `_populate_voice_picker` cleared the picker; the refresh path called the
    native populator directly, so a second refresh (timer + `about_to_popup`)
    appended every entry again. The native populator now clears itself.

13. **Stale CANCELED stalled playback forever** (`_on_native_utterance_canceled`)
    It ignored its utterance id and had no generation check, unlike its ENDED and
    STARTED siblings. A late CANCELED from a previous Stop cleared `_native_seg`
    for the utterance now playing, so both the ENDED advance and the watchdog
    failed their checks — audio played out, then silence, button stuck on "Stop".
    Now uses the same id + generation guards.

## Verification harness gotchas (learned the hard way)

- `ui_mobile` is set in `_ready()` from cmdline args, so setting it on the
  instance before `add_child` is silently overwritten. A layout audit must pass
  `-- --mobile-ui` on the command line or it measures the desktop build.
- In headless, `get_combined_minimum_size()` returns 0 (no layout pass) and
  `get_visible_rect()` ignores `window_set_size` (reports 960x960). Measure
  `custom_minimum_size`, and compute viewport-derived values yourself, or you
  will "discover" phantom overflow.

## Fixed — Android UI (round 3, research-backed)

14. **Menu overlay ScrollContainer had `scroll_deadzone = 0`** (`_apply_touch_filters`)
    The walk covered `main_margin` and `menu_center_box` but NOT `menu_overlay`,
    whose own ScrollContainer sits above `menu_center_box` in the tree. So the
    mode-button list scrolled on the very first pixel of finger movement, the
    opposite of the deadzone's purpose — taps on the mode buttons were eaten as
    scrolls. `menu_overlay` is now walked too. Verified: 4/4 ScrollContainers
    now report deadzone=16 in both layouts.

15. **Safe-area insets mixed coordinate spaces** (`_apply_safe_area`)
    `get_display_safe_area()` and `get_display_cutouts()` are documented as
    PHYSICAL-SCREEN coordinates; the UI is laid out in stretched viewport units
    (`canvas_items` + `expand`). The old code compared them directly, so insets
    were wrong on any device whose pixel density is not 1:1. Now scaled into
    viewport space.

16. **Cutout insets ignored** (`_apply_safe_area`)
    Android 15+ forces edge-to-edge, and `WindowInsets.systemBars()` EXCLUDES
    the cutout. Display cutouts are now unioned into the insets so no control
    sits under a notch or punch-hole.

17. **Edge-to-edge made explicit** (`export_presets.cfg`, both Android presets)
    Added `screen/edge_to_edge=true`. Godot 4.7 targets android-36, where
    edge-to-edge is enforced anyway; setting it means the app's safe-area code
    is reliably load-bearing instead of silently OS-version-dependent.

## Research findings ALREADY handled by existing code (no change needed)

- **Back-button double-fire** (godot#123454: one press delivers
  `NOTIFICATION_WM_GO_BACK_REQUEST` twice ~1ms apart on 4.7 at targetSdk 36).
  `_on_go_back()` already debounces at 600ms — an order of magnitude more than
  the reported gap. Already safe.
- **Mouse/touch double-firing**: the engine guards every ScrollContainer touch
  branch with `event_device_id != DEVICE_ID_EMULATION`, so the project's
  deliberate `emulate_mouse_from_touch=false` is not required for correctness —
  but it also doesn't cause double-scroll. Left as-is.
- **`MOUSE_FILTER_PASS` on children**: `_touch_filter_walk` already assigns PASS
  to BaseButtons and IGNORE to decoration, which matches the documented
  behaviour (PASS keeps the child's own input and lets drags bubble to the
  ScrollContainer).

## OPEN — needs a real device, cannot be verified headless

- **TalkBack / AccessibilityServer on Android** — Godot 4.5+ has
  `AccessibilityServer` (AccessKit-based) with `ROLE_BUTTON`, `ROLE_RADIO_BUTTON`
  etc., but Godot's own dev log still lists mobile accessibility as incomplete.
  Verify on-device before assuming any screen-reader support.
- **Android font-scale (`sp`) honouring** — Godot `font_size` is pixels. If
  Godot does not map it to Android's font-scale setting, the UI will ignore the
  user's accessibility font size. Test with Font size = Large.
- **`get_display_safe_area()` accuracy** — godot#105462 reports it returning a
  too-narrow safe area on Pixel 9 in some orientations. The scaling fix above
  makes it correct in principle; confirm against a notched device.
- **`exam_label` / `question_diagram_label` use AUTOWRAP_OFF** — long NEC values
  may clip on narrow phones.
- **Native-TTS watchdog tweens accumulate** (min 6s each, bounded by teardown).
  Minor, not a correctness bug.

## Researched but deliberately not changed

- **Contrast / dark-mode tokens**: the app's palette was already designed dark
  (near-black `#020408`–`#08101e` with light text) and computes well above WCAG
  AA. Answer state is carried by colour PLUS an icon and a border
  (`answer_card.gd` `_draw_state_icon`, accent bar), not colour alone. No
  change needed.
- **48dp touch targets**: the mobile builder already uses 56px minimums for
  dock/next buttons. The 42px values seen in the desktop builder are the
  Windows layout, where the 44dp pointer guideline applies instead.



## Test tooling added

- `tools/harness.gd` — the regression suite. Keep it; it is the only thing that
  catches these.
