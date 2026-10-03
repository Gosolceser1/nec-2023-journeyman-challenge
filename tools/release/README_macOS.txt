{app_name}  -  version {version}  (macOS)
=====================================================

A study app for the {edition} journeyman electrician exam: timed practice
drills, a full {scored_items}-question exam simulator, a Nebraska State Law drill, and a
short lesson with the NEC reference after every answer. Questions can be read
aloud by the built-in voice.


HOW TO INSTALL
--------------
1. Unzip the download if your Mac has not already (Safari unzips it for you):
   double-click the zip file.
2. Drag "{app_name}.app" into your Applications folder, and open it from
   there. Opening it straight from Downloads can make macOS block it.
3. Double-click the app. The first time, macOS asks you to confirm it (next
   section). After that it opens like any other app.

There is no installer and nothing else to download. It runs on Apple Silicon
and Intel Macs, and fully offline.


"APPLE COULD NOT VERIFY ..." (FIRST LAUNCH ONLY)
------------------------------------------------
The app is not notarized by Apple (that takes a paid Apple developer
account), so macOS stops it the first time. You only do this once.

macOS 15 Sequoia and later:
  1. Double-click the app. When macOS says it could not verify the app, click
     "Done" (not "Move to Trash").
  2. Open System Settings > Privacy & Security and scroll down to Security.
  3. Next to the line saying "{app_name}" was blocked, click "Open Anyway".
  4. Click "Open Anyway" in the box that appears and enter your Mac password.

macOS 14 Sonoma and earlier:
  Right-click (or Control-click) the app in Applications, choose "Open", then
  click "Open" in the box that appears.

If macOS says the app "is damaged and can't be opened", or the steps above do
not offer "Open Anyway", open Terminal (press Cmd+Space, type Terminal) and
run this one line, then open the app normally:
    xattr -dr com.apple.quarantine "/Applications/{app_name}.app"
It only removes the "downloaded from the internet" mark from this one app.

To make sure your copy is the original, compare its SHA-256 fingerprint with
the one in SHA256SUMS.txt (sent alongside the zip). In Terminal:
    shasum -a 256 ~/Downloads/{file_stem}_v{version}_macOS.zip


SYSTEM REQUIREMENTS
-------------------
- macOS 11 Big Sur or later on Apple Silicon (M1 and newer), or
  macOS 10.13 High Sierra or later on an Intel Mac
- About 400 MB of free disk space
- Speakers or headphones if you want questions read aloud


YOUR PROGRESS
-------------
Progress and settings are saved automatically, on this Mac only, in:
    ~/Library/Application Support/{user_dir}
(in Finder choose Go > Go to Folder... and paste that line).

- To start over, quit the app and delete that folder.
- To uninstall, drag the app from Applications to the Trash (and delete that
  folder too if you want your progress gone).


KEYBOARD
--------
A-D or 1-4 ........ pick an answer
Enter / Space / -> . next question
Cmd+Q ............. quit


GOOD TO KNOW
------------
This is an independent study aid. It is not affiliated with or endorsed by the
NFPA, PSI, or the Nebraska State Electrical Division, and it does not replace
the code book: always check the current NEC and your local amendments.
NFPA 70 and NEC are registered trademarks of the National Fire Protection
Association.

Sounds, voice and software credits: CREDITS.txt and THIRD_PARTY_LICENSES.txt.
