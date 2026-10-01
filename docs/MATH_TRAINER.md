# Math trainer and study helpers

Math help for learners who find the exam calculations hard. It works the
way a tutor would: one idea per step, big numbers, a picture for every
formula, and the exact keys to press on a calculator.

Everything is data-driven: formulas, table values, problem types, cards and
drills live in `data/`, and the code only reads them.

## What the learner sees

| Tool | What it does |
| --- | --- |
| Show steps | After an exam calculation question is answered, a "Show steps" button solves it step by step |
| Math trainer | Endless generated problems by topic, three levels, hint, steps, weak-spot mix |
| Formula cards | Picture, formula, what each letter means, units, calculator keys, worked example |
| Table drills | Timed 10-question lookups in the NEC tables, with a best run to beat |
| Math weak spots | Accuracy by topic and by drill, weakest first, and a practice mix of them |

### Step-by-step solutions

- Shown **only after the question is answered**: the button stays hidden
  until then, and the question's answer is never used before that
  (`tools/tests/test_math_ui.gd` checks both).
- One step per screen: STEP 2 OF 6 with progress dots, then Back, Read
  (read-aloud voice) and Next step. Arrow keys, Enter, Space and Backspace
  work too.
- Read uses the voice picked in the app, like the quiz. It reads the title,
  the working, the note and then the calculator keys one by one ("277,
  times, 1.732, equals, memory plus"), each part as a sentence
  (`src/speech/math_step_speech.gd`). Every step of the 70 exam solutions is
  recorded in the Andrew bundle (`math_<question id>_s<step>` folders, from
  `tools/speech/dump_speech.gd`). Trainer steps use the online voice, cached
  after the first read. Offline, the recorded Andrew or the device voice
  reads the step, and a note under the buttons names that voice. Read turns
  into Stop while it plays. Next, Back, Done and Close stop it. Voice off
  (the quiz's mute, or Silent from the menu) hides Read. In Auto-read and
  Listen modes, each step reads itself when shown. The quiz below stays
  quiet, and its Listen loop waits until the steps close.
- Step kinds: the formula, the numbers from the question, a table lookup
  (table name and row), a Code rule, the math, rounding or choosing the next
  standard size, and the answer.
- Math steps show the working in a large panel and the calculator keys as
  key caps, with a second row for a basic calculator when a scientific key
  (such as √ or x²) is used.
- "Try it on the calculator" under a step's keys opens a guided calculator
  (`src/ui/calc_pad.gd` over `src/math/calc_engine.gd`): the next key of the
  row is lit and named, and when the row is done it says whether the number
  matches the step. Earlier steps' results and memory are already in it, so
  rows such as "× 14 =" or "1 ÷ MR =" work as shown. Any other key still
  works; the guide steps aside until Restart.
- 70 exam calculation questions have a solution and every one reaches the
  keyed answer exactly (`test_math_engine.gd`, "exam calculation questions
  reach the keyed answer"). One is skipped on purpose: Final Exam #4 Q53 is
  answered by ruling out choices, not by a calculation. No answer key was
  changed or looked wrong.

### Math trainer

- 12 topics and 58 problem types (60 types in the engine; two are exam-only):

| Topic | Types |
| --- | --- |
| Ohm's law & power | 8 (I, E, R, watts, I²R, three-phase current, neutral) |
| Series & parallel | 5 |
| Box fill (314.16) | 3 |
| Conduit fill (Chapter 9) | 4 |
| Ampacity & derating (310.15) | 2 |
| Voltage drop | 3 |
| Dwelling load (Article 220) | 6 |
| Range & dryer demand (220.54/55) | 4 |
| Motors (Article 430) | 7 |
| Transformer current | 2 |
| Percent, fractions & efficiency | 6 |
| Other Code calculations | 8 in the trainer (10 in the engine) |

- Levels: Easy, Medium, Hard (bigger numbers, more steps, more rules).
- Answer on the on-screen calculator (the same `CalcPad`: + − × ÷ =,
  memory, percent, x², square root, 1/x, ±), like the basic calculator
  allowed in the exam room, or on the keyboard. Check submits the number
  showing and finishes a pending operation first (12 × 24, then Check,
  answers 288); a fraction goes in as a division. The answer is checked
  with the tolerance that type allows (for example ±1% on a calculated
  current). Table and size answers are picked from choices. There is no
  separate calculator tool on the Study tab.
- Hint, Card (that topic's formula card) and Steps buttons. Opening the
  steps before answering counts as a miss.
- "Practice my weak spots" picks types weighted toward low accuracy.

### Formula cards

17 cards: Ohm's law, power, three-phase power, series and parallel, box
fill, conduit fill, ampacity and derating, voltage drop, dwelling load,
range demand, dryer demand, motors, transformer current, percent and
efficiency, unit loads and counts, busbars and taps, welders. Each card has
an original drawing (`src/ui/math_picture.gd` draws it from primitives in
the data), the formula and its rearranged forms, a table of the letters with
units, a tip, the calculator keys and a "Worked example" button that opens
the step-by-step view.

### Table drills

17 timed drills: Table 310.16 copper and aluminum, ambient correction
310.15(B)(1)(1), adjustment 310.15(C)(1), Chapter 9 Table 1, EMT and
Schedule 40 PVC areas (Table 4), THHN/THWN areas (Table 5), Table 8,
Table 314.16(A) and (B)(1), Tables 220.54 and 220.55, Tables 430.248 and
430.250, Tables 250.66 and 250.122. Ten questions, the clock runs only
while a question is open, each answer shows the row and column that give
it, and the best run is saved.

### Weak spots

`src/math/math_stats.gd` saves answers in `user://math_stats.cfg`: attempts,
correct answers and the last 12 results for each topic, problem type and
drill, plus the best run per drill. Accuracy uses the last 12 results.
Anything with fewer than 3 answers counts as new and gets extra weight
(2.5); otherwise the weight is 1 + 3 × (1 − accuracy). Exam calculation
questions count toward their topic too. "Reset math progress" needs a second
press.

## Accuracy

- Table values are in `data/nec/2023/tables.json` (26 NEC 2023 tables and 36
  single rule values, only the values the math needs). They come from the
  local NFPA 70-2023 cache through `tools/math/nec_tables_from_cache.py`,
  and `--check` compares every value with the cache again. No UpCodes text
  or drawing is copied; the pictures are original.
- `tools/tests/test_math_engine.gd` (about 79,000 checks) covers:
  - hand-worked answers for every problem type
  - every exam solution reaching its key
  - 12 generated problems per type and level, each with complete steps
  - read-aloud text for the steps: symbols are spoken as words, and a
    number is never read as a Code section
  - every card's worked example
  - 30 questions per drill, plus fixed table cells checked by hand
  - the weak-spot statistics
- `tools/tests/test_math_voice.gd` checks the spoken text of every exam
  step, plus 5 generated problems per type and level: whole sentences, no
  math symbol left, every calculator key named, and no part cut off. It
  also checks Read and Stop, the stop on Next, Back and Done, Voice off,
  Auto-read, and the offline fallbacks.
- K = 12.9 (copper) and 21.2 (aluminum) are textbook constants, not NEC
  values, and the steps say so.

## Screens and layout

- The screens are an overlay (`MathHub`, z_index 30) over the app, with a
  Back stack. Escape or Android Back goes back one screen.
- No page scrolling at desktop 1280×720, 1024×600 and 1920×1080, or phone
  360×640, 412×915, 540×960 and 800×1280. Only a long step or prompt scrolls
  inside its own panel. `test_math_ui.gd` walks every screen, every problem
  type and level, all cards and drills at each size.
- Text sizes are tokens in `src/ui/math_ui.gd` (numbers 34 to 38 px),
  larger on phones. The app's colors, sounds (click, correct, wrong, start,
  pass, fail) and read-aloud voice are reused.

## How the app opens it

The Study tab of the main menu lists `data/math/tools.json` (id, title,
description, detail with `{n}`, count_of, icon, accent). The `study_tools`
block in `data/menu.json` names the entry script `res://src/ui/math_hub.gd`,
loaded by path, so the menu also runs without the math files. Opening a
tile calls `MathHub.open(main, id)` with id `trainer`, `cards`, `drills` or
`weak_spots`. `MathData.tool_detail(id)` fills in the count ("58 problem
types · 3 levels").

`main.gd` calls the hooks named in `study_tools.hooks`:

- `attach(main)` in `_ready`: adds the hidden "Show steps" button
- `on_question(main)` when a question is shown: hides it
- `on_answered(main, record, correct, graded)` after the answer: records
  the weak-spot stats and shows the button when the question has steps
- `handle_back(main)` in `_on_go_back`: true when a math screen took Back

## Files

| Path | Role |
| --- | --- |
| `data/math/constants.json` | Constants such as 1.732 and K |
| `data/math/problem_types.json` | Skills, levels, the 60 problem types (inputs, ranges, formula, steps, tolerance) |
| `data/math/exam_steps.json` | Which exam questions get steps and their inputs |
| `data/math/formula_cards.json` | The 17 cards and their drawings |
| `data/math/drills.json` | The 17 table drills |
| `data/math/tools.json` | Entry tools for the menu |
| `data/nec/2023/tables.json` | NEC 2023 table values used by the math |
| `src/math/*.gd` | Engine, calculator engine, data access, formatting, drills, statistics |
| `src/ui/math_*.gd`, `src/ui/calc_pad.gd` | Hub, steps view, trainer, cards, drills, drawings, shared widgets; the on-screen calculator |
| `tools/tests/test_math_engine.gd`, `tools/tests/test_math_ui.gd` | Tests |
