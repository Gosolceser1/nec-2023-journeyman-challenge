# Voice reading rules

How the trainer reads a question aloud. The on-screen wording in
`question_bank.json` is never changed; everything here applies to the
**spoken** text only.

One normaliser does all of this: `speech_rules.gd` (`Rules.normalize`), a
table-driven pipeline of named rules run in order. `speech_text.gd` turns a
record into segments (one audio clip each), and both voices use it:

- Recorded clips: the Edge neural voice (`src/speech/speak_question.py`, default
  en-US-AndrewNeural, 96 kbps / 24 kHz mono MP3). Python only synthesises the
  text it is handed. Andrew's clips for every question ship in `res://assets/speech`
  and play on desktop **and Android**. Other desktop voices are synthesised on
  demand and cached (see "Runtime synthesis" below).
- Device voice (`DisplayServer.tts_speak`): the Android fallback when no
  recorded clip matches, or when a "Device voice · …" entry is picked. The
  mobile picker lists "Andrew · Recorded (offline)" first.

### Runtime synthesis (desktop, voices other than bundled Andrew)

`speech_helper.gd` keeps one `speak_question.py --serve` process running, so
the ~3 s import of edge_tts + aiohttp is paid once (at start, or when such a
voice is picked) instead of on every question. It always synthesises the
question's whole plan (stem, choices, rule) into `user://speech/<id>__<voice>`,
so the read, "Hear the rule" and replays share one cached folder.

- Clips stream: each one is announced as it lands and playback starts with the
  stem while the rest are still coming. If the next clip is not there yet the
  status reads "PREPARING <VOICE>…". Stop, skip and Next detach playback
  immediately; the synthesis finishes into the cache.
- Prefetch: showing a question requests it and the next one in the background,
  rule included. The teach gate in `_play_speech_clip` still holds the rule
  until the answer is in.
- A new live read cancels the previous live one (the learner moved on);
  prefetches are left alone.
- Robustness: every clip is retried (1, 2, 4 s) with a 20 s timeout, written to
  `N.mp3.part` and renamed when complete; `manifest.json` is written last. A
  failed or cancelled request removes its clips.
- Honest fallback: if Edge cannot be used (no Python, no network, helper died),
  the game logs one line with the reason and reads with the system voice, and
  the status line says "System voice (Edge unavailable)", never the picked name.
  On Android a question without a recording says "Device voice (no recording)".

Golden input → spoken cases for every rule live in
`tools/tests/test_speech_rules.gd`. The suite fails if a rule has no case.

## 1. Reading order

| # | Segment | Example | When |
|---|---------|---------|------|
| 1 | Stem | "Which section requires G F C I protection in a garage?" | before answering |
| 2–5 | Choices, lettered | "Option A, 20 amps." … "Option D, 1 only." | before answering |
| 6 | Answer callout | "Answer D, 12 kilowatts." | after answering only |
| 7+ | Rule, then calculation | "Section 210 point 8, paragraph A, item 2 …", "Calculation: …" | after answering only |

- Choices always start with "Option X,". A bare "A," is voiced as the article
  "uh" and runs straight into the choice ("A20 amps").
- Each segment ends with exactly one terminator. A trailing `: , ;` becomes
  `.`, and a `.` that is already there is not doubled.
- Roman-numeral lists read as "Item 1, …", and Roman choices as numbers
  ("1 and 2 only").

## 2. Pauses

Pauses come from segment boundaries, not SSML (the free Edge endpoint rejects
SSML). Each clip has about 0.35 s of trailing and 0.15 s of leading silence,
so there is about 0.5 s between stem, choices and rule lines. Within a segment:

- A newline becomes a sentence break (". ").
- "—" becomes ", ", and "→" becomes ", so ".
- A table is replaced by one sentence (§5).

## 3. Pronunciation table (NEC notation)

| Written | Spoken |
|---------|--------|
| `210.8(A)(1)` | section 210 point 8, paragraph A, item 1 |
| `422.16(B)(1)(a)` | … item 1, sub-item A |
| `Table 310.15(B)(1)(1)` | Table 310 point 15, B, 1, 1 |
| `680.58:` at line start, `§ 90.2` | Section 680 point 58, Section 90 point 2 |
| `708.54 Ex.:` | Section 708 point 54 Exception: |
| bare `210.12` choice to a "which section" question | 210 point 12 |
| `31.6 amps` (not a reference) | 31.6 amps |
| `1/0`, `4/0` | one aught, four aught |
| `12/3 NM` | 12 slash 3 N M |
| `250 kcmil` | 250 thousand circular mil |
| `208Y/120 V` | 208 wye 120 volts |
| `120/240-volt` | 120 slash 240-volt (never "to": that is a range) |
| `THHN wire`, `THWN conductors` | T H H N, wire; T H W N, conductors (pause after a type ending in N) |
| `THWN-2`, `XHHW-2`, `SPT-2` | T H W N, dash 2 (pause, then "dash") |
| `NM-B`, `XHHW insulation` | N M B, X H H W insulation |
| `GFCI AFCI AWG EMT PVC STOOW MI HARC` | spelled letter by letter |
| `OCPD EGC GEC AHJ HP` | overcurrent protective device, equipment grounding conductor, grounding electrode conductor, authority having jurisdiction, horsepower |
| `IEEE`, `NEMA`, `OSHA`, `HVAC` | I triple E; the others are passed through for the voice to say as words |
| `CU/AL`, `and/or` | copper or aluminum, and or |
| `11/2"` (bank typo for 1 1/2) | 1 and one half inches |
| `1/2"`, `1/2-inch`, `1/4 in.` | half inch, quarter inch (trade sizes) |
| `3/4"`, `3/4-inch` | three quarter inch |
| `3/8-inch`, `15/16 in.`, `1/16"` | three eighths of an inch, fifteen sixteenths of an inch, one sixteenth of an inch |
| `1 1/2"`, `1 3/4 in.` | 1 and one half inches, 1 and three quarters inches |
| `1/60` | 1 over 60 |
| `8'`, `5'9"`, `6 ft.`, `5-ft` | 8 feet, 5 feet 9 inches, 6 feet, 5-foot |
| `20 A`, `1 A`, `5 mA`, `10 kA` | 20 amps, 1 amp, 5 milliamps, 10 kiloamps |
| `200 A service`, `20 A breaker`, `240 V single-phase` | 200 amp service, 20 amp breaker, 240 volt single-phase (a unit used as an adjective is singular) |
| `240V`, `48 VDC`, `15 kV` | 240 volts, 48 volts D C, 15 kilovolts |
| `180 VA`, `10 kVA`, `1.5 kW`, `100 W` | volt amperes, kilovolt amperes, kilowatts, watts |
| `90°C`, `112°F`, `90°` | 90 degrees Celsius, 112 degrees Fahrenheit, 90 degrees |
| `125%`, `#10`, `No. 12` | 125 percent, number 10, number 12 |
| `mm² in² sq. ft. cu. in.` | square millimeters, square inches, square feet, cubic inches |
| `7 lb-in.`, `20 lb-ft` | 7 pound-inches, 20 pound-feet |
| `100-400 A` | 100 to 400 amps |
| `___` | blank (after "Article/Section": "which Article") |
| `connector(s)` | connectors |
| `e.g.`, `i.e.`, `approx.`, `min.`, `max.` | for example, that is, approximately, minimum, maximum |

Unknown all-caps tokens: consonant-only ones are spelled ("Q R Z"). A line
shouted in capitals is lowercased. `ON`, `OFF`, `NOT` and `ONLY` are read as words.

### Voice-independent by design

Every rule applies to all 13 voices in `voices.json`; there are no per-voice
tweaks. Each spelling above was picked by rendering the candidates through
every voice and transcribing them with Whisper (`small.en`, no prompt). The
tuning renders were scratch and are not kept; what they showed:

- Spaced capitals ("T H H N") are the only form every voice spells. Hyphens
  ("T-H-H-N") and dots are voiced as "THN" or "teach", and commas between
  every letter break the word apart.
- A spelled type ending in N runs into the next word: "T H H N wire" is
  heard as "T H H and wire" (Roger, and Andrew, Jenny, Aria and Steffan in
  some sentences). A comma after the type made it 13/13 in all three test
  sentences.
- "T H W N 2" is heard as "T H W and 2" (Jenny, Roger, Steffan).
  "T H W N, dash 2" was 13/13.
- "One half inch" is heard as "1.5 inch" on 10 of 13 voices. "Half inch" was
  13/13.
- A raw `3/4"` loses its inch mark on every voice. The spelled "three
  quarter inch" keeps it.
- Directly before "inch", "three eighths" is heard as "3.8" (6 of 13 voices
  in the bank's 3/8-inch FMC question). "Three eighths of an inch" was 13/13
  there and 49/52 across all test sentences, so every fraction except half,
  quarter and three quarter is read "… of an inch".
- "120 slash 240 volt" and "120 over 240 volt" were both 13/13; the raw
  `120/240` was 4/13. "Slash" is kept.

## 4. Never read before the answer

- The answer callout ("Answer X, …"), the rule text, the reference and the
  calculation are **teach** segments. They always form a contiguous tail of the
  plan.
- The player (`_play_speech_clip`) stops at the first teach clip unless
  `want_teach` is set. A cached or bundled clip therefore cannot leak the answer.
- The spoken stem and choices come from the same fields shown on screen, so
  nothing is read that the student can't see.

## 5. Tables and formulas

- A tab-separated block is never read cell by cell. A table titled
  "Table 408.5 …" becomes "Table 408 point 5 is shown on screen."; otherwise
  "The table is shown on screen."
- In a line containing `=`, operators are spoken: "equals", "minus", "plus",
  "times", "divided by", "squared". `VD = V source - V load` becomes "V D equals V
  source minus V load". Outside formulas a hyphen stays a hyphen.
- `W = E x I` becomes "W equals E times I", and `2x30A` becomes "2 times 30 amps".- `√3 ≈ 1.73` becomes "square root of 3 is about 1.73".

## 6. After answering

- **Auto-read** (default) and **Listen**: after you answer, the answer callout
  and the rule are read automatically (the `auto_teach` option is on by
  default). The dock button shows **Stop** while speaking and **Replay rule**
  after.
- **Tap to hear**: nothing plays on its own. The button reads **Hear the rule**.
- Right or wrong is shown visually and by the sound effect. It is not spoken,
  because the clips are rendered once per question.
- Navigating to another question, or leaving the quiz, stops all speech
  (`_stop_reading` + `tts_stop`).
- `user://audio.cfg` records `version = 2`. Older configs are migrated so that
  `auto_teach` is on; turning it off afterwards is respected.

## 7. Versioning

`Rules.VERSION` is stamped on every segment as `rules`. Cached and bundled clip
manifests store it, along with the Edge output `format`. A clip is reused only
when text, choice/teach flags, `rules` and `format` all match; `format` must
equal `SPEECH_FORMAT` in `main.gd`, which is kept in sync with `OUTPUT_FORMAT`
in `src/speech/speak_question.py`. **Bump `VERSION` whenever a rule changes spoken
output**, then refresh the shipped clips:

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/speech/dump_speech.gd
python tools/speech/pregenerate_speech.py --bundle
Godot_v4.7.2-stable_win64_console.exe --headless --path . --import
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/speech/test_bundle.gd   # expect 279/279
```

The `--import` step matters. Bundled clips are loaded as imported
`AudioStream` resources (`ResourceLoader`), because an exported build (APK or
PCK) contains only the imported streams, not the raw `.mp3` files.
