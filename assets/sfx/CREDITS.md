# Sound effects — source and license

All eleven files in this folder are **processed recordings from Pixabay**
(the "Set C" pick, with wrong.wav and hover.wav replaced by hand-picked
sounds), used under the **Pixabay Content License**
(https://pixabay.com/service/license-summary/): free for commercial and
non-commercial use, no attribution required, modifying and bundling inside an
app allowed; selling or redistributing the files on their own (as stock or a
sound pack) is not, nor implying the creator endorses the app. Credit is given
here anyway. None of the sources is flagged AI-generated on Pixabay (checked
at download, Sep 27, 2026). Electric Boom 1 (wrong.wav) and Swoosh 1
(hover.wav) are flagged low quality there; both were kept as deliberate picks
after listening.

Only the processed in-app WAVs are committed, never the source MP3s.

| File | Plays when | Sound | Creator | Pixabay page | Length |
|---|---|---|---|---|---|
| start.wav | a session starts from the menu | Interface 13 | SoundReality | https://pixabay.com/sound-effects/film-special-effects-interface-13-204784/ | 0.70 s |
| correct.wav | right answer | Interface 9 | SoundReality | https://pixabay.com/sound-effects/film-special-effects-interface-9-204779/ | 0.90 s |
| wrong.wav | wrong answer / item timed out | Electric Boom 1 | AleXZavesa | https://pixabay.com/sound-effects/electric-boom-1-463651/ | 0.90 s |
| warning.wav | exam clock reaches 5:00 and 1:00 left | Beep warning | freesound_community | https://pixabay.com/sound-effects/film-special-effects-beep-warning-6387/ | 1.50 s |
| pass.wav | results: passed | Level Up | SoundReality | https://pixabay.com/sound-effects/film-special-effects-level-up-140966/ | 2.13 s |
| fail.wav | results: did not pass | Game Over 39 | Tuomas_Data | https://pixabay.com/sound-effects/musical-game-over-39-199830/ | 1.85 s |
| click.wav | plain button presses | Click | SoundReality | https://pixabay.com/sound-effects/film-special-effects-click-233950/ | 0.11 s |
| hover.wav | pointer over a button or menu card (desktop) | Swoosh 1 | AleXZavesa | https://pixabay.com/sound-effects/swoosh-1-463607/ | 0.15 s |
| toggle.wav | switches, chips, voice mute | Light Switch | SoundReality | https://pixabay.com/sound-effects/film-special-effects-light-switch-156813/ | 0.14 s |
| select.wav | keyboard / controller focus onto an answer card | Pop Click | SoundReality | https://pixabay.com/sound-effects/film-special-effects-pop-click-312649/ | 0.19 s |
| transition.wav | screen changes (report, back to menu) | Movement Swipe Whoosh 1 | floraphonic | https://pixabay.com/sound-effects/film-special-effects-movement-swipe-whoosh-1-186575/ | 0.30 s |

Processing (the same for all): leading silence trimmed (onset at -40 dB, 5 ms
pre-roll, 3 ms fade-in); the natural end kept when it fits the sound's length
budget, otherwise cut at the quietest point near the end with an exponential
fade to -60 dB; one gain change to a per-role max-momentary loudness (start
-18 LUFS, correct / wrong -16, warning / pass -15, fail -17, click / toggle /
select / transition -22, hover -25), true peak ≤ -1 dBTP; no limiter, and no
EQ except on wrong.wav. wrong.wav starts on the boom itself (source 0.44 s,
skipping the rising crackle before it), ends with a 45 ms fade over the boom's
natural drop (source 1.34 s), and has a -3 dB low shelf at 150 Hz so phone
speakers get more of it. hover.wav is the peak of the swoosh only (source
0.15 to 0.30 s: 10 ms fade-in partway up the swell, 70 ms exponential fade
after the second peak), so it never overlaps itself at its 0.15 s repeat gap.
16-bit PCM, stereo kept (warning is mono at the source), 44.1 or 48 kHz.
Details and the reasoning per sound: `docs/SFX_PLAN.md`.

`tools/sfx/make_sfx.py` renders the previous synthesized set (CC0). It only
writes here with `--replace-shipped`, which overwrites five of these files.

Why only these: see `docs/SFX_PLAN.md`. Mix, voice rules and the one-sound-
per-action logic: `src/fx/sfx.gd`.
