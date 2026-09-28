# Android voice names (US English)

On Android the voice picker lists the recorded Andrew voice, then the
**Microsoft Edge natural voices from the Windows app** (US English only, see
"Edge voices" below), then **only US English device voices** (language
`en-US` / `en_US`, or an id starting `en-us-`).
Android reports voices by raw id (`en-us-x-iol-local`), so the app maps each id
to a friendly label such as `Female 1 · US English · Offline` or
`Male 2 · US English · Online (needs internet)`. The mapping lives in
`VoiceCatalog.US_VOICE_NAMES` (`src/speech/voice_catalog.gd`), and
`tools/tests/test_voice_picker.gd` checks every id in the tables below.

Rules:

- A gender is shown only when two independent sources agree. Any id not in the
  tables below gets a neutral label (`Voice A`, `Voice B`, ...), never a guess.
- `-local` means Offline and `-network` means Online (needs internet). When a
  voice has both copies, only the offline one is listed.
- `en-US-language` (Google) and `en-US-default` (Samsung) are listed last as
  `System default`.
- Order: Andrew, the Edge voices, then offline device voices (female, male,
  neutral), then online ones, then System default. With no US device voice on
  the phone the list is Andrew, the Edge voices and System default.
- The saved choice is the real voice id. A saved id that is not US, or that the
  phone no longer has, falls back to Andrew. A saved network copy moves to the
  listed offline copy of the same voice.

## What Android and Godot expose

- The Android `Voice` API has quality, latency, requiresNetwork and features,
  but **no gender field**
  ([Voice reference](https://developer.android.com/reference/android/speech/tts/Voice);
  [StackOverflow 36681232](https://stackoverflow.com/questions/36681232/android-tts-male-voices):
  "an enhancement request is needed so that the gender can be included").
- Godot 4.7 passes even less through. `GodotTTS.getVoices()` returns only
  `Locale.toString() + ";" + getName()` strings (so the language reads `en_US`), and `TTS_Android::get_voices` turns them into
  `name`, `id` and `language`
  ([tts_android.cpp](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/android/tts_android.cpp),
  [GodotTTS.java](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/android/java/lib/src/main/java/org/godotengine/godot/tts/GodotTTS.java)).
  There is no quality, gender or network flag, so Offline/Online comes from the
  `-local` / `-network` suffix and the gender comes from this table.

## Google Speech Services (com.google.android.tts)

### Current engines: 8 voices, 16 ids

Every code ships as a `-local` and a `-network` copy.

| Code | Ids | Gender | App label | Sources |
| --- | --- | --- | --- | --- |
| tpc | en-us-x-tpc-local, en-us-x-tpc-network | Female | Female 1 | [R], [RT] |
| iob | en-us-x-iob-local, en-us-x-iob-network | Female | Female 2 | [R], [RT] |
| iog | en-us-x-iog-local, en-us-x-iog-network | Female | Female 3 | [R], [RT] |
| tpf | en-us-x-tpf-local, en-us-x-tpf-network | Female | Female 4 | [R], [RT] |
| sfg | en-us-x-sfg-local, en-us-x-sfg-network | Female | Female 5 | [R], [RT], [GP], [SP] |
| iom | en-us-x-iom-local, en-us-x-iom-network | Male | Male 1 | [R], [RT] |
| iol | en-us-x-iol-local, en-us-x-iol-network | Male | Male 2 | [R], [RT], [BD], [SO64860903] |
| tpd | en-us-x-tpd-local, en-us-x-tpd-network | Male | Male 3 | [R], [RT] |
| (default) | en-US-language | n/a | System default | [BD-list] |

The numbering follows Readium's `Female voice 1..5` / `Male voice 1..3`.

The complete set comes from a 956-voice device dump, [BD-list]. Its en-US
entries are exactly these 16 ids plus `en-US-language`, and they match
Readium's list, [R], one for one. A 2026 user listing of the offline US voices
([PTT](https://www.ptt.cc/bbs/WomenTalk/M.1776366645.A.E6A.html)) shows the
same eight codes.

### Older engines: 7 voices, 8 ids

Only `sfg` existed for en-US, plus gender-tagged variants of it. The app takes
the gender straight from the `#male_N` / `#female_N` part of the id.

| Id | Gender | App label | Sources |
| --- | --- | --- | --- |
| en-us-x-sfg-local, en-us-x-sfg-network | Female | Female 5 | [GP], [SP] |
| en-us-x-sfg#female_1-local | Female | Female 1 | [SP], the engine's own id |
| en-us-x-sfg#female_2-local | Female | Female 2 | [SP], [SO36681232] |
| en-us-x-sfg#female_3-local | Female | Female 3 | [SP], the engine's own id |
| en-us-x-sfg#male_1-local | Male | Male 1 | [SP], [SO36681232], [SC] |
| en-us-x-sfg#male_2-local | Male | Male 2 | [SP], [SC] |
| en-us-x-sfg#male_3-local | Male | Male 3 | [SP], the engine's own id |

The eight "Natural" codes (tpc, iob, iog, tpf, iom, iol, tpd, and sfg in its
current form) appear only in newer engine versions. Google's own public voice
lists ([GP]: voices-list r1/r2) still name only `sfg` for en-US. The
`#male_N` / `#female_N` variants appear only in older engines, in posts from
2016 onwards ([SO41199064], [SO36681232], [SP]).

### Seen but unconfirmed

| Id | App label | Why |
| --- | --- | --- |
| en-us-x-msm00013-local (and other msm variants) | Voice A (neutral) | No public source gives a gender for msm. It is not in [R], [BD-list] or [GP]. |

## Samsung TTS (com.samsung.SMT)

Samsung voices are downloaded packs named `com.samsung.SMT.lang_en_us_<variant>`.
The engine reports the default US voice as `en-US-SMTf00`, with locale
`eng-x-lvariant-f00` ([FT516]), and its default entry as `en-US-default`. All
Samsung voices are offline.

| Variant | Id | Samsung name | Gender | App label | Sources |
| --- | --- | --- | --- | --- | --- |
| f00 | en-US-SMTf00 | US English Default voice 1 | Female | Female 1 | [BY-f00], [AM-f], [FT516] |
| l03 | en-US-SMTl03 | US English Voice 1 (Stephanie) | Female | Female 2 | [AC-l03], [AN-l03], [AM-s] |
| l04 | en-US-SMTl04 | US English Voice 3 - Bixby (Julia) | Female | Female 3 | [GS-l04], [AM-j] |
| g02 | en-US-SMTg02 | US English Voice 2 (John) | Male | Male 1 | [AM-john], [99-g02] |
| (default) | en-US-default | n/a | n/a | System default | [FT516] |

Notes:

- `en-US-SMTf00` is the only Samsung id observed verbatim ([FT516]). The ids
  for l03, l04 and g02 follow the same `<locale>-SMT<variant>` pattern, where
  the variant is the pack's package suffix. Each gender is confirmed per pack.
- "US English Default voice 2" is a male pack ([AM-m]), but no source gives its
  package suffix or voice id. It is not mapped, so it gets a neutral label.
- Since a June 2025 update, Samsung TTS serves only Samsung's own apps
  ([NamuWiki](https://en.namu.wiki/w/%EC%82%BC%EC%84%B1%20TTS)). On current
  Samsung phones this app usually gets Google's engine; the Samsung rows cover
  older firmware.

## Other engines

Microsoft does not ship a system TTS engine for Android; its Edge voices are
cloud-only and come from the app itself (next section). Other OEM engines
(Xiaomi, Huawei, Vivo, and so on) publish no voice ids, so their voices get
neutral labels.

## Edge voices (the Windows voices)

The Windows app's voices are Microsoft Edge "read aloud" neural voices from
`data/voices.json` (built by `tools/speech/export_voices.py`, which stores
each voice's Edge `Gender` and `Locale`). On Windows the Python helper
(`speak_question.py`, edge-tts) synthesizes them; Android cannot start a
Python process, so before 1.0.2 the phone listed none of them. Since 1.0.2
`EdgeTtsClient` (`src/speech/edge_tts_client.gd`) speaks the same WebSocket
protocol in GDScript, and the Android presets ask for the INTERNET permission.

- Listed: every `en-US` row, labelled `<Name> · <Gender> · Online (natural)`
  (for example `Ava · Female · Online (natural)`), in catalog order. The
  British Ryan (`en-GB`) stays desktop-only. Andrew is not listed twice: the
  recorded row is Andrew, and a line without a clip uses online Andrew.
- They need internet. Clips are cached in `user://speech`, so a question
  heard once plays offline later. With no connection the read falls back to
  the recorded Andrew (every question has a clip) or a device voice, and the
  status line says so.

## Totals (US English)

| Engine | Unique voices | Ids | Local | Network | Female | Male | Mapped |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Google, current | 8 | 16 (+ en-US-language) | 8 | 8 | 5 | 3 | 8 of 8 |
| Google, older | 7 | 8 (+ en-US-language) | 7 | 1 | 4 | 3 | 7 of 7 |
| Samsung | 5 packs | 5 (+ en-US-default) | 5 | 0 | 3 | 2 | 4 of 5 (Default voice 2 unmapped) |

## Sources

- [R] Readium Speech `json/en.json`, commit
  [dce7206](https://github.com/readium/speech/blob/dce72068dafa4f4367ae635b7c7029736feeed36/json/en.json):
  gender, label and native ids for each Google en-US voice, and ChromeOS names
  ("Google US English 1..7 (Natural)"). The older
  HadrienGardeur/web-speech-recommended-voices repository is the same dataset,
  so it is not counted separately.
- [RT] crosstales RT-Voice,
  [Unity forum, page 78](https://discussions.unity.com/t/rt-voice-run-time-text-to-speech-solution/588886?page=78):
  lists every male English voice on Android 11 (en-us iol, iom, tpd among
  "10 out of 32 are male"). The other en-US codes are therefore female.
- [GP] Google's voice lists
  [voices-list-r1.proto](https://dl.google.com/dl/android/tts/v2/voices-list-r1.proto) and
  [voices-list-r2.proto](https://dl.google.com/dl/android/tts/v2/voices-list-r2.proto):
  `en-us-x-sfg` female.
- [BD] ArminJo/Arduino-BlueDisplay commit 35232140:
  `speakSetVoice(F("en-us-x-iol-local")); // male voice`.
- [BD-list] [Arduino-BlueDisplay TTS-ListOfAllVoices.txt](https://github.com/ArminJo/Arduino-BlueDisplay/blob/master/src/TTS-ListOfAllVoices.txt):
  a full device dump of Google TTS voices.
- [SO64860903] [StackOverflow 64860903](https://stackoverflow.com/questions/64860903):
  "en-us-x-iol-local … one of the male voice".
- [SO36681232] [StackOverflow 36681232](https://stackoverflow.com/questions/36681232/android-tts-male-voices):
  `en-us-x-sfg#male_1-local` (male) and `en-us-x-sfg#female_2-local` (female).
- [SO41199064] [StackOverflow 41199064](https://stackoverflow.com/questions/41199064/what-do-the-android-voice-names-codes-mean):
  the `#female_N` / `#male_N` naming.
- [SP] brandall76/Saiy-PS
  [TTSDefaults.java](https://github.com/brandall76/Saiy-PS/blob/master/app/src/main/java/ai/saiy/android/tts/helper/TTSDefaults.java):
  gender for each sfg id (sfg local and network female, `#female_1..3` female,
  `#male_1..3` male).
- [SC] Spiral Code Studio
  [getLanguagesAndVoices voices](https://docs.spiralcodestudio.com/plugin/texttospeech/event/getLanguagesAndVoices/voices/):
  a device dump with the `sfg#male_N` / `#female_N` ids.
- [FT516] [flutter_tts issue 516](https://github.com/dlutton/flutter_tts/issues/516):
  Samsung engine ids `en-US-SMTf00` (`eng-x-lvariant-f00`) and `en-US-default`.
- [BY-f00] [BAYTON: com.samsung.SMT.lang_en_us_f00](https://sysapps.bayton.org/packages/com.samsung.SMT.lang_en_us_f00):
  "SamsungTTS US English Default voice 1".
- [AM-f] [APKMirror: US English Default voice 1](https://www.apkmirror.com/apk/samsung-electronics-co-ltd/samsungtts-us-english-female/):
  "Voice Type: Female".
- [AM-m] [APKMirror: US English Default voice 2](https://www.apkmirror.com/apk/samsung-electronics-co-ltd/samsungtts-us-english-male/samsungtts-us-english-male-312304000-release/):
  "Voice Type: Male".
- [AC-l03] [APKCombo: com.samsung.SMT.lang_en_us_l03](https://apkcombo.com/samsung-tts-us-english-voice-1/com.samsung.SMT.lang_en_us_l03/):
  "Voice Type: Female (Stephanie)".
- [AN-l03] [apk.now: US English Voice 1](https://apk.now/apk/samsung-electronics-co-ltd/samsung-tts-us-english-stephanie/samsung-tts-us-english-voice-1-3-2-24-30-release/samsung-tts-us-english-voice-1-3-2-24-30-2-android-apk-download/):
  package `lang_en_us_l03`.
- [AM-s] [APKMirror: US English Voice 1 (listed as "stephanie")](https://www.apkmirror.com/apk/samsung-electronics-co-ltd/samsung-tts-us-english-stephanie/samsung-tts-us-english-stephanie-3-1-24-40-release/).
- [GS-l04] [Galaxy Store: com.samsung.SMT.lang_en_us_l04](https://galaxystore.samsung.com/detail/com.samsung.SMT.lang_en_us_l04):
  "Voice Type: Female (Julia)".
- [AM-j] [APKMirror: US English Voice 3 - Bixby](https://www.apkmirror.com/apk/samsung-electronics-co-ltd/samsung-tts-us-english-julia/samsung-tts-us-english-julia-312315000-release/):
  "Voice Type: Female (Julia)".
- [AM-john] APKMirror, US English Voice 2:
  [release 302210281](https://www.apkmirror.com/apk/samsung-electronics-co-ltd/samsung-tts-us-english-john/samsung-tts-us-english-john-302210281-release/)
  ("Voice Type: male (John)") and
  [release 3.2.28.8](https://www.apkmirror.com/apk/samsung-electronics-co-ltd/samsung-tts-us-english-john/samsung-tts-us-english-voice-2-3-2-28-8-release/samsung-tts-us-english-voice-2-3-2-28-8-android-apk-download/)
  (package `com.samsung.SMT.lang_en_us_g02`).
- [99-g02] [99play: com.samsung.SMT.lang_en_us_g02](https://99play.app/app/com-samsung-SMT-lang_en_us_g02):
  "SamsungTTS US English Voice 2".
