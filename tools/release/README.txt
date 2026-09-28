NEC 2023 Journeyman Challenge  -  version {version}
=====================================================

A study app for the NEC 2023 journeyman electrician exam: timed practice
drills, a full 80-question exam simulator, a Nebraska State Law drill, and a
short lesson with the NEC reference after every answer. Questions can be read
aloud by the built-in voice.


HOW TO RUN
----------
1. Right-click the zip file and choose "Extract All...", then open the
   extracted folder. (Running it from inside the zip preview also works, but
   extracting is tidier.)
2. Double-click "NEC 2023 Journeyman Challenge.exe".

That's it: there is no installer and nothing else to download. The app runs
fully offline.


"WINDOWS PROTECTED YOUR PC"
---------------------------
The first time you open it, Windows SmartScreen may show a blue
"Windows protected your PC" box. That happens with any new app that is not
sold through a store. Click "More info", then "Run anyway". Windows only asks
once.

To make sure your copy is the original, compare its SHA-256 fingerprint with
the one in SHA256SUMS.txt (sent alongside the zip). In PowerShell:
    Get-FileHash "NEC 2023 Journeyman Challenge.exe"


SYSTEM REQUIREMENTS
-------------------
- Windows 10 or Windows 11, 64-bit
- Graphics with OpenGL 3.3 (practically any PC from the last ten years)
- About 300 MB of free disk space
- Speakers or headphones if you want questions read aloud


YOUR PROGRESS
-------------
Progress and settings are saved automatically, on this PC only, in:
    %APPDATA%\NEC2023JourneymanChallenge
(paste that line into the File Explorer address bar to open it).

- To move your progress to another PC, copy that folder to the same place there.
- To start over, close the app and delete that folder.
- To uninstall, delete the .exe (and that folder if you want your progress gone too).


KEYBOARD
--------
A-D or 1-4 ........ pick an answer
Enter / Space / -> . next question


GOOD TO KNOW
------------
This is an independent study aid. It is not affiliated with or endorsed by the
NFPA, PSI, or the Nebraska State Electrical Division, and it does not replace
the code book: always check the current NEC and your local amendments.
NFPA 70 and NEC are registered trademarks of the National Fire Protection
Association.

Sounds, voice and software credits: CREDITS.txt and THIRD_PARTY_LICENSES.txt.
