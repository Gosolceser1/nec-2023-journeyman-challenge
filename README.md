# NEC 2023 Journeyman Challenge

A solo exam trainer for the NEC 2023 journeyman electrician exam: 279
questions from seven practice exams, each with the answer, the NEC 2023
reference and a short lesson. Runs on Windows and Android (Godot 4.7.2,
GDScript). Questions can be read aloud by a recorded neural voice that ships
with the app.

Every drill and the Full Journeyman Simulator draw from all 279 questions,
weighted like the Nebraska exam's content outline (10/20/15/15/10/5/5 items
per subject area). Drills avoid repeats until an area is used up, and missed
questions come back two sessions later. The report breaks your score down by
subject area, shows your pace against the exam's 3:00 per question, and
estimates exam readiness. "10 Questions • Weakest Area" drills the area
that needs it most. See `docs/STUDY_SYSTEM.md`.

## Run

Open the folder in Godot 4.7.2, or from a terminal:

```
Godot_v4.7.2-stable_win64_console.exe --path .                 # desktop layout
Godot_v4.7.2-stable_win64_console.exe --path . -- --mobile-ui  # Android layout on desktop
```

The bundled voice clips (`assets/speech/`, ~138 MB) are generated, not committed.
Without them the app falls back to the system voice. To build them:

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/speech/dump_speech.gd
python tools/speech/pregenerate_speech.py --bundle
Godot_v4.7.2-stable_win64_console.exe --headless --path . --import
```

## Verify

```
bash tools/verify.sh                               # import, parse, unit suites, harness x2, bank checks
python tools/pipeline/validate_question_bank.py --no-warn   # bank schema + spoiler gate
```

`GODOT` and `PYTHON` override the binaries verify.sh uses.

## Export

Presets live in `export_presets.cfg` (Windows Desktop, Android Debug/Release).
Their exclude filters keep tests, tools, docs and source PDFs out of the build.

```
mkdir build
Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release "Windows Desktop" build/NEC2023JourneymanChallenge.exe
python tools/list_pck.py build/NEC2023JourneymanChallenge.pck --desktop   # fails if the voice bundle or a runtime file is missing
```

Godot will not create `build/`, and an export without `assets/speech/`
succeeds silently with no recorded voice, so generate the bundle first.

## Docs

- `docs/ARCHITECTURE.md`: how the code is organised
- `docs/STUDY_SYSTEM.md`: exam blueprint, question selection, study feedback
- `docs/DATA_PIPELINE.md`: how the question bank is built and validated
- `docs/VOICE_READING_RULES.md`: how questions are spoken
- `docs/SFX_PLAN.md`: which moments get a sound
- `docs/KNOWN_ISSUES.md`: open items and verification traps
