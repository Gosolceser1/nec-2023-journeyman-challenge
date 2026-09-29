# Known issues

Open items that could not be closed headless, plus the verification traps
that produced false results before. Fixed defects are in git history
(`77e2cf7`, `16589d5`, `3c5971f`, `3bfc526`, `c8ff389`, for 1.0.1 the
Android touch scrolling `d6667a6` and voice picker `e5d4a7c`, for 1.0.2
the Edge voices on Android, and for 1.0.3 the Edge voices on Windows without
Python and the NEC location audit), each pinned by a test.

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
  Read / Stop / Read again, and that the rule stays silent until an answer is
  in.
- **1.0.1 touch scrolling and voice sheet were verified on desktop only.**
  `test_touch_scroll` and `test_voice_picker` push synthetic ScreenTouch /
  ScreenDrag events through the real viewport; no Android device or emulator
  was available. On a phone confirm: every list scrolls by finger (menu,
  question, explanation, results, voice list), a swipe never presses a button
  or answers a card, a tap still does, a fling stops on touch, the voice list
  opens at once, a tap picks and closes it, Back closes it, and the labels
  read "Female 1 · US English · Offline" and so on.
- **1.0.2 Edge voices on Android were verified on desktop only.**
  `test_edge_client` and `test_voice_picker` run `EdgeTtsClient` against a
  local fake of the service (streaming, cache, cancel, no-internet fallback),
  and the mobile layout was checked live against the real service from
  Windows (Emma played after about 1 s). On a phone confirm: the Edge voices
  are listed after Andrew, Preview and Read play them with Wi-Fi or mobile
  data, a question heard once replays in airplane mode, and in airplane mode an
  unheard question falls back to the recorded Andrew at once with the status
  line saying "no internet".
- **The Edge read-aloud endpoint is unofficial.** `EdgeTtsClient` copies
  edge-tts 7.2.8: the trusted client token, the Chromium version in
  `Sec-MS-GEC-Version` and the Origin header. If Microsoft changes them, the
  handshake fails and every read falls back to the recorded Andrew or a device
  voice until the constants are updated (pregenerating the bundle needs a new
  edge-tts then too). The token is built from the device clock; unlike
  edge-tts, the client does not correct a clock that is more than about
  5 minutes off, so such a PC or phone always falls back.
- **`TTS_Android` utterance-id map is not thread-safe (engine).** Godot's
  `TTS_Android::ids` HashMap is written from the Android TTS callback thread
  and from the main thread without a lock. The app cannot fix that; it now
  calls `tts_stop` only when it handed an utterance to the OS, which keeps the
  two sides from racing on every Stop.
- **Samsung TTS voice ids other than `en-US-SMTf00` are inferred.** The l03,
  l04 and g02 ids follow the observed `<locale>-SMT<variant>` pattern
  (docs/ANDROID_VOICES.md); if a Samsung phone reports them differently they
  get a neutral label, never a wrong gender.

## Open: found during the refactor

- **`measure_fit.gd` crashes the engine on the desktop layout at 540x960.**
  After ~250 of the 279 records the run prints "Object was deleted while
  awaiting a callback" and dies with signal 11. It reproduces on the
  pre-refactor checkpoint (`c0aaa1b`), so it is not caused by the moves.
  The other six measured sizes finish with 0% scroll. The app itself never
  awaits (only the tool scripts do), so the crash is most likely in the
  measuring loop or the engine; the Windows build opens at 540x960, so it is
  worth a look. It is intermittent: the 1.0.0 and 1.0.1 release runs at
  540x960 finished with 0% scroll.
- **`measure_fit.gd` crashes the engine on the mobile layout at 1024x768.**
  The run dies inside the engine (message queue overflow under
  `Container::_sort_children`) before it finishes. The base commit
  (`2d6b960`, before the premium visual pass) crashes the same way, so it is
  not caused by the restyle. Desktop at all six sizes and mobile at the other
  five finish with 0% scroll. A phone never gets a 1024x768 window with the
  mobile UI, but a tablet in landscape could. Still crashes in 1.0.1
  (signal 11); the other eleven size/layout runs finish with 0% scroll.
  Same crash in 1.0.2 and 1.0.3; desktop 1280x720 and mobile 540x960 finish
  with 0%.
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

## Open: NEC 2023 content audit

- **final-exam-#3-068 tests a rule NEC 2023 removed.** The 2020 620.51(D)(1)
  "More Than One Driving Machine" numbering rule is gone; 2023 620.51(D) has
  only "Available Fault Current Field Marking". The keyed answer cannot be
  tied to 2023 text without changing it, so the record needs a human decision
  (retire or rewrite). See `docs/CONTENT_AUDIT_2023.md`.
- **final-exam-#1-029 heading.** UpCodes prints "408.5 Clearance for Conductor
  Entering Bus Enclosures" (singular); the record keeps "Conductors", as in the
  Table 408.5 title. Confirm against the printed code.

## Open: release 1.0.0

- **The Windows exe is not code-signed**, so SmartScreen warns on first run
  ("More info", then "Run anyway"; the recipient README says so). Only a
  code-signing certificate removes that.
- **No 24 px image in the exe.** Godot's exporter writes 16/32/48/64/128/256
  into the exe's icon, dropping the `.ico`'s hand-made 24 px; Windows scales
  32 down for a 100% taskbar. The running window uses the full `.ico`
  (`windows_native_icon`), so its title bar and taskbar icon are unaffected.
- **The Edge speech cache is not migrated.** `user://speech` (clips the desktop
  Edge helper downloaded) stays in the old folder; it refills on demand. Only
  the settings and `question_bag.cfg` move.
- **No in-app About or credits screen.** Credits and licenses ship as text
  files next to the exe (`docs/RELEASE.md`); the menu footer shows the version.
- **Alt-tab and a pinned taskbar icon were not screenshotted** (the dev
  machine's taskbar auto-hides); the title bar, Explorer views and the icon
  resource inside the exe were checked.

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
- A window `min_size` grows the headless window, so every headless layout
  number changes. `main.gd` sets `DESKTOP_MIN_WINDOW` only when the display
  server is not headless.
- Godot's own user folder moved in 1.0 (`use_custom_user_dir`): with a temp
  `APPDATA`, runs write to `<temp>\NEC2023JourneymanChallenge`, not
  `<temp>\Godot\app_userdata\...`. To test the migration, put a fake old folder
  at `<temp>\Godot\app_userdata\NEC 2023 Journeyman Challenge` first.
- The boot splash shows for about 0.35 s (`boot_splash/minimum_display_time`
  is 600 ms from process start). `PrintWindow` captures miss it; screen-copy the
  exe started with `--always-on-top` instead.
- A synthetic touch test must hold the finger still long enough for a fling to
  end before tapping: a touch during a fling only stops it (as on a phone), so
  a tap right after a swipe presses nothing. `test_touch_scroll` waits for
  `touch_scroll._fling_speed == 0`.
- Tests that open the app must delete their own `user://*.cfg` first: a saved
  voice from the previous run otherwise makes the tapped row the selected one,
  and the pick becomes a no-op.
- New or moved `class_name` scripts need
  `Godot --headless --path . --import` before `--script` runs can resolve
  them (verify.sh stage 0 does this).

## Researched, deliberately not changed

- **Back-button double-fire** (godot#123454: one press delivers
  `NOTIFICATION_WM_GO_BACK_REQUEST` twice ~1 ms apart on 4.7 at targetSdk 36).
  `_on_go_back()` debounces at 600 ms.
- **Mouse/touch double-firing.** `emulate_mouse_from_touch` stays false: with
  it on, a scroll could select an answer card (see the note in
  `project.godot`). An earlier version of this note said ScrollContainer
  handles touch itself; that was wrong and shipped the 1.0.0 scroll bug. In
  Godot 4.7 `ScrollContainer::gui_input` drag-scrolls only on
  InputEventMouseButton / InputEventMouseMotion (and only when
  `is_touchscreen_available()`), and `PopupMenu::gui_input` handles only mouse
  events, so with emulation off neither reacts to a finger. `TouchScroll` and
  `VoiceSheet` (1.0.1) replace them for touch.
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
