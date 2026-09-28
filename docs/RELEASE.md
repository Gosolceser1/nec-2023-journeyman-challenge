# Release

How to build the shareable Windows zip and Android APK. Everything lands in
`release/` (gitignored). Version 1.0.0 was the first release; 1.0.2 is current (CHANGELOG.md).

## What a recipient gets

- `NEC2023JourneymanChallenge_v<ver>_Windows.zip`: one folder holding
  `NEC 2023 Journeyman Challenge.exe` (single file, the pack is embedded, no
  console window, release template), `README.txt` (how to run, the SmartScreen
  note, requirements, where progress is saved), `CREDITS.txt` (Pixabay sounds,
  the Edge voice, fonts, NFPA trademark note) and `THIRD_PARTY_LICENSES.txt`
  (Godot's MIT license and its components, generated from the engine).
- `NEC2023JourneymanChallenge_v<ver>_Android.apk`: signed with the release key.
- `SHA256SUMS.txt`: hashes of the zip, the exe and the APK.

Nothing a user sees says Godot: the exe icon and version resource, the window
and taskbar icon, the boot splash, the title bar (no "(DEBUG)" in a release
export), the Android launcher, adaptive, themed and Android 12 splash icons.
The engine's license notice is only in `THIRD_PARTY_LICENSES.txt`, which the
MIT license requires.

## Branding sources

`assets/branding/source/` (has a `.gdignore`, so it is never imported or
packed) holds the hand-written SVGs: `icon.svg` (the icon, bolt + pass check),
`icon_small.svg` (plain bolt for 16 and 24 px, where the badge smears),
the three Android adaptive layers, and the rejected `options/`. Rebuild every
PNG, the `.ico`, the splash and the options sheet with:

```
python tools/branding/build_branding.py
```

It rasterises with Godot (`tools/branding/render_svg.gd`, ThorVG) and builds
the rest with Pillow. Outputs: `assets/branding/icon.png` (512,
`application/config/icon`), `icon.ico` (16/24/32/48/64/128/256, each size its
own image; `windows_native_icon` and the exe icon), `android_*.png`,
`splash.png`, `source/png/icon_<16..1024>.png` and
`.audit_tmp/shots/release/icon_options.png`.

The Windows exporter writes its fixed set of 16/32/48/64/128/256 into the exe
(pixel-identical to the `.ico`); it drops 24, which Windows then scales from 32.

## Steps

Run every Godot and Python command with a temporary `APPDATA` (see
`docs/KNOWN_ISSUES.md`). The exporter needs the templates and, for Android, the
editor settings (SDK and JDK paths), so copy those into the temp folder first:

```powershell
$env:APPDATA = "$env:TEMP\nec_rel_appdata"
$env:WSLENV = 'APPDATA/p:GODOT/p'
$env:GODOT = "$PWD\Godot_v4.7.2-stable_win64_console.exe"
$real = "$([Environment]::GetFolderPath('ApplicationData'))\Godot"
$t = "$env:APPDATA\Godot\export_templates\4.7.2.stable"
New-Item -ItemType Directory -Force $t | Out-Null
foreach ($f in 'version.txt','icudt_godot.dat','windows_release_x86_64.exe','windows_debug_x86_64.exe',
               'windows_release_x86_64_console.exe','windows_debug_x86_64_console.exe',
               'android_release.apk','android_debug.apk') {
    Copy-Item "$real\export_templates\4.7.2.stable\$f" $t }
Copy-Item "$real\editor_settings-4.7.tres" "$env:APPDATA\Godot\"
```

1. Bump the version if needed: `application/config/version` in
   `project.godot`, `application/file_version` and `product_version` in the
   Windows preset, `version/name` and `version/code` (+1 every release) in both
   Android presets.
2. Make sure the voice bundle exists (`assets/speech/`, see README); an export
   without it succeeds silently with no recorded voice.
3. `bash tools/verify.sh` must end with ALL CHECKS PASSED.
4. Export (always `--export-release`; a debug export shows "(DEBUG)" in the title):

   ```powershell
   & $env:GODOT --headless --path . --import
   & $env:GODOT --headless --path . --export-release "Windows Desktop" "release/windows/NEC 2023 Journeyman Challenge.exe"
   & $env:GODOT --headless --path . --export-release "Android Release" "release/android/NEC2023JourneymanChallenge_v1.0.2_Android.apk"
   ```

   Godot does not create output folders, so on a fresh clone run
   `New-Item -ItemType Directory -Force release/windows, release/android` first,
   and put an empty `.gdignore` in `release/` so the editor never scans the builds.
5. Check the pack: `python tools/list_pck.py "release/windows/NEC 2023 Journeyman Challenge.exe" --desktop`
   (reads the pack embedded in the exe; fails on tools/, docs, PDFs, `.md`,
   any `.py` (no build runs Python) or a missing runtime file).
6. Package: `python tools/release/make_release.py` (zip, APK copy, SHA256SUMS).
7. Smoke test: run the exe with a temp `APPDATA`. stdout and stderr must stay
   empty, the title must read "NEC 2023 Journeyman Challenge", and the menu
   footer must end in the version.

## Android signing

The release key was made with the JDK's keytool
(`C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot\bin\keytool.exe`):
PKCS12, RSA 2048, 10000 days, alias `nec_release`. It lives outside the repo:

```
C:\Users\vadim\Documents\NEC_release_keystore\nec_release.keystore
C:\Users\vadim\Documents\NEC_release_keystore\keystore_password.txt
```

Back that folder up. Every update must be signed with the same key, or
Android refuses to install it over the existing app.

The path, alias and password are per-user export credentials in
`.godot/export_credentials.cfg` (gitignored, never committed):

```
[preset.2]

[preset.2.options]

keystore/release="C:/Users/vadim/Documents/NEC_release_keystore/nec_release.keystore"
keystore/release_user="nec_release"
keystore/release_password="<from keystore_password.txt>"
```

On a fresh clone, recreate that file (or fill the three fields in the
editor's export dialog). `Android Debug` keeps using the editor's debug
keystore. Confirm a build with
`apksigner verify --print-certs <apk>`: the signer must be
`CN=NEC 2023 Journeyman Challenge, O=Live Wire Training, C=US`.

## Where progress is saved

`application/config/use_custom_user_dir` puts `user://` at
`%APPDATA%\NEC2023JourneymanChallenge` on Windows. Builds before 1.0 used
`%APPDATA%\Godot\app_userdata\NEC 2023 Journeyman Challenge`; on the first
launch `UserDirMigration` copies `audio.cfg`, `voice.cfg` and
`question_bag.cfg` from there if the new folder has none of them, then writes
`user_dir_migration.cfg` so it never runs again. The old folder is left alone.
Android keeps its own app storage and is not affected.
