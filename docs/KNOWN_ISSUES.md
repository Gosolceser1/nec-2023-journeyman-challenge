# Known issues

Open items that could not be closed headless, plus the verification traps
that produced false results before. Fixed defects are in git history
(`77e2cf7`, `16589d5`, `3c5971f`, `3bfc526`, `c8ff389`), each pinned by a test.

## Open: needs a real device

- **TalkBack / AccessibilityServer on Android.** Godot 4.5+ has
  `AccessibilityServer` (AccessKit) with `ROLE_BUTTON`, `ROLE_RADIO_BUTTON`
  etc., but Godot's own dev log still lists mobile accessibility as
  incomplete. Verify on a device before assuming any screen-reader support.
- **Android font scale (`sp`).** Godot `font_size` is pixels. If Godot does
  not map it to Android's font-scale setting, the UI ignores the user's
  accessibility font size. Test with Font size = Large.
- **`get_display_safe_area()` accuracy.** godot#105462 reports a too-narrow
  safe area on Pixel 9 in some orientations. The inset scaling in
  `SafeArea.margins` is correct in principle; confirm on a notched device.
- **`exam_label` has no autowrap (Label default `AUTOWRAP_OFF`).** Long
  session names may clip on narrow phones.
- **Native-TTS watchdog tweens accumulate** (min 6 s each, bounded by
  teardown). Minor, not a correctness bug.
- **Speech on Android after the SpeechController move.** The native-TTS
  callbacks now target `main.speech` instead of `main`. Headless tests,
  the bundle check and the desktop export pass, but on a device confirm
  Read / Stop / Read again, that the rule stays silent until an answer is
  in, and that the voice list refreshes when the picker opens.

## Open: found during the refactor

- **`measure_fit.gd` crashes the engine on the desktop layout at 540x960.**
  After ~250 of the 279 records the run prints "Object was deleted while
  awaiting a callback" and dies with signal 11. It reproduces on the
  pre-refactor checkpoint (`c0aaa1b`), so it is not caused by the moves.
  The other six measured sizes finish with 0% scroll. The app itself never
  awaits (only the tool scripts do), so the crash is most likely in the
  measuring loop or the engine; the Windows build opens at 540x960, so it is
  worth a look.
- **`measure_fit.gd` crashes the engine on the mobile layout at 1024x768.**
  The run dies inside the engine (message queue overflow under
  `Container::_sort_children`) before it finishes. The base commit
  (`2d6b960`, before the premium visual pass) crashes the same way, so it is
  not caused by the restyle. Desktop at all six sizes and mobile at the other
  five finish with 0% scroll. A phone never gets a 1024x768 window with the
  mobile UI, but a tablet in landscape could.
- **`start.wav` is a placeholder.** The session start sound ships as is and
  will be replaced by the final recording; keep its name, length budget
  (onset at `Widgets.START_CUE_ONSET`) and bus so `test_sfx` still holds.
- **`NecReference.lookup_path` reads any 3-digit number as an NEC article.**
  An `article` of "NFPA 70E 130.5" would show "Chapter 1 ► Article 130"
  instead of the NFPA 70E line. The bank only uses the bare "NFPA 70E", which
  takes the right branch, so nothing shows it today; check the NFPA case first
  if sectioned 70E references are ever added.

## Open: found applying the explanation audit

- **Rule lines can run to a whole provision.** `answer_sentence` splits the
  provision on ". " only, so when the answer sits in a later line of a
  multi-line provision the "sentence" spans every line before it.
  final-exam-#3-053 reads all of 344.30(B) plus its table (997 characters,
  about 25 s of audio); `speak_question.py` gives a clip 20 s, so its bundled
  clip had to be rendered with a longer timeout, and a live read with another
  Edge voice times out on that line. final-exam-#1-012 reads the full 210.8(A)
  list. Splitting on line breaks too would fix it but re-renders many clips.
- **"is permitted" after a plural subject.** `plain_words` maps "shall be
  permitted" to "is permitted", so about a dozen rule lines still read
  "Conductors of different voltage ratings is permitted".

## Verification traps

- `ui_mobile` is set in `_ready()` from the command line, so setting it on
  the instance before `add_child` is silently overwritten. A layout check
  must pass `-- --mobile-ui` or it measures the desktop build.
- Headless, `get_combined_minimum_size()` returns 0 (no layout pass) and
  `get_visible_rect()` ignores `window_set_size` (reports 960x960). Measure
  `custom_minimum_size`, or run windowed (`tools/visual/measure_fit.gd`).
- Screenshots from `tools/visual/snap_all.gd` only compare cleanly with
  `--fixed-fps 60 --disable-vsync` and `-- --det`: without them shader time
  and particle bursts differ run to run.
- `snap_all.gd` switches to `user://snap_audio.cfg` only after `main._ready()`
  has loaded the real `user://audio.cfg`, so the menu shots show whatever
  sound level the app was last set to (and a running copy of the game keeps
  changing it). Compare shots against a copied user folder: point `APPDATA`
  at a temp directory holding a fixed `audio.cfg` for the run.
- `bash` from PowerShell is WSL's bash, which has no `python`; verify.sh now
  finds `python.exe` there, but a script that passes absolute `/mnt/c/...`
  paths to a Windows program still needs `wslpath -m`.
- Never tween a container child's `position` with `as_relative()`. The
  container puts the child back in its slot on every re-sort (text change,
  resize, theme change), and a quick enter/exit overlaps two tweens, so the
  return leg lands off the slot and stays there: the menu cards ended up 1-7 px
  apart. Mode cards no longer slide at all (hover is glow and shine); where
  something must slide, use `UiFx.slide_x` (absolute target, one tween per
  control). `test_menu_cards.gd` pins it.
- New or moved `class_name` scripts need
  `Godot --headless --path . --import` before `--script` runs can resolve
  them (verify.sh stage 0 does this).

## Researched, deliberately not changed

- **Back-button double-fire** (godot#123454: one press delivers
  `NOTIFICATION_WM_GO_BACK_REQUEST` twice ~1 ms apart on 4.7 at targetSdk 36).
  `_on_go_back()` debounces at 600 ms.
- **Mouse/touch double-firing.** The engine guards every ScrollContainer touch
  branch with `event_device_id != DEVICE_ID_EMULATION`, so
  `emulate_mouse_from_touch=false` is not required for scrolling, but it is
  required for the answer cards (see the note in `project.godot`).
- **`MOUSE_FILTER_PASS` on children.** `_touch_filter_walk` assigns PASS to
  BaseButtons and IGNORE to decoration, matching the documented behaviour.
- **Contrast.** The palette is dark by design; body text and the small
  SLATE_400 helper labels pass WCAG AA (6.6:1+). The primary buttons (Next,
  Return to menu) now sit on SKY_700 with a SKY_700 -> BLUE_800 tint: behind
  the label the rendered fill measures 4.9-7.1:1 against white. Answer state
  is carried by colour plus an icon and a border.
- **48 dp touch targets.** Canvas px are not dp: the 540 px canvas maps to
  ~0.76 dp/px on a 1080 px, 420 dpi phone, so 48 px dock buttons are ~37 dp and
  56 px cards ~43 dp. A density-aware content_scale_factor (clamped to 1.15 to
  keep the no-scroll rule) needs a device check. Mobile minimums today: 56 px
  answer cards, 52 px Next, 48 px dock buttons; the 42 px values in the desktop
  builder follow the 44 dp pointer guideline for Windows.
