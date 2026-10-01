# Tables & Formulas Audit — NEC 2023

Second pass, 2026-09-28. Scope: all 283 records (279 NEC, 4 Nebraska State Electrical Act).
The 315 records of the 9 exams imported on 2026-09-29 were classified and checked the same
way (see *Exam import*); the class counts below cover all 598 records.
The question for each record is whether it needs a table lookup, a calculation or a formula.
If it does, the audit checks that the app gives the student what they need to answer without
the codebook, and that the numbers are right for NEC 2023. The first pass (2026-09, when UpCodes
was login-gated) is kept below under *First pass* for history. Where the two passes disagree,
this pass wins, because every value was re-read on UpCodes.

All fixes go through `tools/pipeline/question_bank_overrides.json` and a candidate build. One
state-law formula went into its curated source instead,
`tools/pipeline/sources/ne_state_act_quiz3_keys.json`, because state-law records are built from
those files and a test requires the shipped records to equal them. `data/question_bank.json`
was never hand-edited.

## Classification

`data/question_requirements.json` classifies every record. For each record that is not plain
recall, it lists the tables or values and the formula steps needed. `tools/pipeline/check_requirements.py`
and `tools/tests/test_question_requirements.py` enforce it (see *Guards*).

| Class | Records | Meaning |
|---|---|---|
| recall | 492 | Answer is a rule or definition; no lookup or arithmetic |
| table | 37 | Answer is read from an NEC table or tabular provision |
| calc | 24 | Arithmetic on values in the stem or in a short rule (for example 1/10 tap rule, 1000 A/in²) |
| table+calc | 40 | A table lookup feeds a calculation (ampacity, range demand, welder duty cycle) |
| formula | 5 | A general electrical formula (voltage drop %, phase time, Ohm's law, parallel resistance) |

86 records carry a machine-checkable `check`. `nec_calc.evaluate` recomputes each one from
NEC 2023 constants and compares it with the keyed answer.

## Coverage gaps found and fixed

| Record(s) | Gap | Fix |
|---|---|---|
| ne-state-act-#3-003 | Calculation (3 licensees × 3 apprentices) with no formula hint | Formula "apprentices = licensees × 3" (Neb. Rev. Stat. 81-2113(2)) in the curated quiz source |
| final-exam-#1-025 | 86 A → 90 A needs the 240.6(A) standard ratings, which the formula did not give | Formula adds the 630.12 next-higher-rating rule and "240.6(A) ratings rise by 10 A from 60 A to 110 A" (worded so pre-answer redaction leaves no telling gap) |
| final-exam-#1-049, open-book-exam-#4-004 | Pre-answer table had one row and one cell (the blanked answer), so it was not a lookup | Table 300.5(A) row "trench below 2 in. concrete" with all five columns (18 / 6 / 12 / 6 / 6 in.) |
| final-exam-#1-034, open-book-exam-#4-025 | Pre-answer table was a lone STOOW row plus a "NOTE: For this item…" scaffolding line | Table 400.4 excerpt (SPT-2, SPT-2W, STOOW with voltage and use) plus Note 9 (the W suffix means wet locations and sunlight resistant). The reference text already quotes Note 9 (content audit) |
| final-exam-#3-040 | Lookup hint still said "Start with Table 630.31(A)(2)" | "Table 630.31(A)". The list-item reference 630.31(A)(2) is kept |

The NEC 2023 content audit (`docs/CONTENT_AUDIT_2023.md`) landed during this pass. It fixed the
following independently, and this pass confirmed each one on UpCodes:

- "Table 344.30(B)" in #3-053 and #5-067, which had the 2017 name "(B)(2)";
- "Table 630.31(A)" in #3-040's provision, notes and worked solution;
- "Table 352.30(B)" in #5-070;
- Note 9 as the provision for the cord records;
- the #10-024 answer wording.

When a fix here changes a provision, its checksum is re-stamped in
`tools/pipeline/content_audit_2023.json` (now `data/nec/2023/content_audit.json`) with a note. That applies to #1-034, #4-025, #1-049,
#4-004 and #3-068.

Every other table/calc/formula record already had a lookup table and/or a correct formula hint.
Both layouts still fit with no scrolling after the changes (see *Checks*).

## Calculation mismatches

None. All 33 recomputed checks equal the keyed answers, and every `worked` solution ends on the
checked value. `check_worked_solutions.py` independently recomputes 31 records and evaluates
25 arithmetic chains, and also passes. The only earlier failure was a missing entry for
ne-state-act-#3-003, which was added.

## Answer concerns (flagged, keys unchanged)

- **final-exam-#3-068** (620.51): the stem and the keyed answer ("driving machine they
  control") come from NEC 2020 620.51(D)(1) "More Than One Driving Machine". **NEC 2023 removed
  that sentence.** On UpCodes, 2023 620.51(D) "Identification and Signs" contains only
  (1) "Available Fault Current Field Marking". The "numbered to correspond to the identifying
  number" rule survives only in 620.53 (car light), 620.54 (car heating and air-conditioning)
  and 620.55 (other utilization equipment). This pass first labeled the record's provision
  "(NEC 2020 text, removed in NEC 2023)" and kept the key. **Resolved:** the question was then
  rewritten to test 2023 620.51(A) (disconnect lockable only in the open position per 110.25);
  the NEC 2020 label is gone (`CONTENT_AUDIT_2023.md`).
- **final-exam-#5-008** (330.104): the key "#18" is literally right, because 330.104 allows
  18 AWG copper for *control and signal* conductors (UpCodes text matches the record). But the
  stem ("minimum size copper conductor permitted in metal-clad cable") does not say "control".
  Many readers would answer 14 AWG, the minimum for power conductors. The choice notes explain
  both. The key is kept. **Resolved:** the stem now asks for control and signal conductors in
  Type MC cable, and the notes cite both 330.104 minimums (`CONTENT_AUDIT_2023.md`).
- **open-book-exam-#10-024** (Article 100), fixed without a key change (the answer wording by
  the content audit, the background line here): the stem is the
  Article 100 definition of *Grounding Electrode Conductor* ("A conductor used to connect the
  system grounded conductor or the equipment to a grounding electrode…"). NEC 2023 has no
  standalone "Grounding Conductor" definition; the only definition starting "Grounding
  Conductor" is "Grounding Conductor, Equipment (EGC)". Choice D now reads "grounding
  electrode conductor" (same letter, same intended meaning). The tip and choice D note quote the
  2023 definition, and the background line now says "equipment grounding conductor" where
  it describes the green/bare fault-current conductor.

## Verified on UpCodes (NFPA 70-2023, Premium viewer, 2026-09-28)

The chapter pages were read with in-page text and DOM extraction in a separate browser tab,
read-only. Values listed are the ones the bank or `tools/pipeline/nec_calc.py` uses.

Chapter URLs: [Ch 1](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general) ·
[Ch 2](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection) ·
[Ch 3](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials) ·
[Ch 4](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use) ·
[Ch 5](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/5/special-occupancies) ·
[Ch 6](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment) ·
[Ch 9](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/9/tables).
Table anchors are `#table_<number>` with parentheses turned into dashes.

| Item | 2023 finding | Link |
|---|---|---|
| Table 110.26(A)(1), Condition 2 | 0–150 V: 3 ft all conditions; Condition 2: "Concrete, brick, or tile walls shall be considered as grounded" | [Ch 1](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general) |
| Article 100 GEC / EGC | GEC definition as quoted above; no standalone "Grounding Conductor" | [Ch 1](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general) |
| 210.8(A) exceptions | No. 1 snow-melting/deicing receptacles; **No. 2 a receptacle supplying only a permanently installed premises security system**; No. 3 WSCR; No. 4 bath-fan internal receptacles | [Ch 2](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection) |
| Table 210.21(B)(2) | 15 A receptacle on a 15/20 A circuit = 12 A | [#table_210.21-B-2](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#table_210.21-B-2) |
| 210.52(G)(1) | One receptacle outlet in each vehicle bay, not more than 1.7 m (5½ ft) above the floor | [Ch 2](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection) |
| 220.14(H)(1) | List item (1): each 1.5 m (5 ft) or fraction = one outlet of not less than 180 VA (appliances unlikely to be used simultaneously) | [Ch 2](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection) |
| Table 220.42(A) | 29 occupancy unit loads, office 1.3 VA/ft² (as in `nec_calc`) | [#table_220.42-A](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#table_220.42-A) |
| Table 220.45 | Dwelling: first 3000 VA 100%, 3001–120,000 VA 35%, remainder 25% | [#table_220.45](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#table_220.45) |
| 220.54 / Table 220.54 | 5000 W or nameplate, whichever is larger; 1–4 100%, 5 85%, 6 75%, 7 65%, 8 60%, 9 55%, 10 50%, 11 47%, 12–23 47% − 1%/dryer over 11, 24–42 35% − 0.5%/dryer over 23, 43+ 25% | [Ch 2](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection) (table has no anchor) |
| Table 220.55 | Column C 1–5 ranges = 8/11/14/17/20 kW; Note 1: +5% per kW or major fraction over 12 kW | [Ch 2](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection) (no anchor) |
| 240.4(D) | 14/12/10 AWG copper = 15/20/30 A | [Ch 2](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection) |
| Table 240.6(A) | 10, 15, 20 … 60, 70, 80, 90, 100, 110, 125 … 6000 A | [#table_240.6-A](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#table_240.6-A) |
| 240.21(B)(1) | Heading "Taps Not Over 3 m (10 ft) Long"; the 1/10 rule is list item (4) | [Ch 2](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection) |
| Table 250.122 | 15→14, 20→12, 60→10, 100→8, 200→6, 300→4, 400→3 AWG Cu | [#table_250.122](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#table_250.122) |
| 250.66(B) | Concrete-encased electrode GEC rule (heading as cited) | [Ch 2](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection) |
| Table 300.1(C) | Metric designator ↔ trade size (16 = 1/2, 21 = 3/4, 27 = 1…) | [#table_300.1-C](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#table_300.1-C) |
| Table 300.5(A) | Trench below 2 in. concrete: columns 1–5 = 18 / 6 / 12 / 6 / 6 in. | [#table_300.5-A](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#table_300.5-A) |
| Table 310.4(1) | RHW-2: 90°C (194°F), dry and wet locations, flame-retardant moisture-resistant thermoset | [#table_310.4-1](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#table_310.4-1) |
| 310.12(A) / Table 310.12(A) | 83 percent of the service rating; 100 A → 4 Cu … 200 A → 2/0 Cu | [#table_310.12-A](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#table_310.12-A) |
| Table 310.15(B)(1)(1) | 78–86°F 1.00; 87–95°F 0.91/0.94/0.96; 96–104°F 0.82/0.88/0.91; 105–113°F 0.71/0.82/0.87 | [#table_310.15-B-1-1](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#table_310.15-B-1-1) |
| Table 310.15(C)(1) | 4–6 80%, 7–9 70%, 10–20 50%, 21–30 45%, 31–40 40%, 41+ 35% | [#table_310.15-C-1](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#table_310.15-C-1) |
| Table 310.16 | Cu 60/75/90°C: 14 = 15/20/25, 12 = 20/25/30, 10 = 30/35/40, 8 = 40/50/55, 6 = 55/65/75, 4 = 70/85/95 | [Ch 3](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials) |
| 314.16(B) / Table 314.16(B)(1) | 18–6 AWG = 1.50/1.75/2.00/2.25/2.50/3.00/5.00 in³; the 2023 table number is **314.16(B)(1)** | [#table_314.16-B-1](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#table_314.16-B-1) |
| 330.104 | Power conductors min. 14 AWG Cu; control and signal 18 AWG Cu | [Ch 3](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials) |
| Table 344.30(B) | Numbered **344.30(B)** (no "(2)"); 1/2–3/4 = 10 ft, 1 = 12 ft, 1¼–1½ = 14 ft, 2–2½ = 16 ft, 3+ = 20 ft | [#table_344.30-B](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#table_344.30-B) |
| Table 348.22 | 3/8 FMC, TFN/THHN/THWN: 10 AWG = 1 (fittings inside or outside); footnote allows one EGC | [#table_348.22](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#table_348.22) |
| Table 352.30(B) | Numbered **352.30(B)**; 1/2–1 = 900 mm (3 ft), 1¼–2 = 5 ft | [#table_352.30-B](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#table_352.30-B) |
| 358.30(A) | EMT fastened within 3 ft of terminations and at intervals not over 10 ft | [Ch 3](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials) |
| 366.23(A) | Bare copper bars 1.55 A/mm² (1000 A/in²); aluminum 1.09 A/mm² (700 A/in²) | [Ch 3](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials) |
| Table 400.4 + Note 9 | SPT-2 300 V damp; SPT-2W 300 V damp and wet; STOOW 600 V damp and wet; Note 9: "W" cords are suitable for wet locations and sunlight resistant | [#table_400.4](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#table_400.4) |
| 430.6(A)(1) | Use Tables 430.247–430.250, not the nameplate, for conductor ampacity | [Ch 4](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use) |
| Table 430.37 | 3-phase ac, any 3-phase supply: "3, one in each phase*" (*unless protected by other approved means) | [Ch 4](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use) (no anchor) |
| Table 430.250 | 50 hp induction: 200 V 150, 208 V 143, 230 V 130, **460 V 65**, 575 V 52 A | [#table_430.250](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#table_430.250) |
| 620.51(D) | Only (1) Available Fault Current Field Marking (see #3-068 above) | [Ch 6](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment) |
| 626.11(A) | Not less than 11 kVA per electrified truck parking space | [Ch 6](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment) |
| 630.12 / 630.12(A) | Not more than 200% of I1max; next higher 240.6 standard rating permitted | [Ch 6](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment) |
| Table 630.31(A) | Numbered **630.31(A)**; 50% 0.71, 40% 0.63, 30% 0.55, 25% 0.50, 20% 0.45, 15% 0.39, 10% 0.32, 7.5% 0.27, ≤5% 0.22. 630.31(A)(2) is the "specific operation" list item (no printed heading) | [#table_630.31-A](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment#table_630.31-A) |
| Chapter 9 Table 1 | 1 conductor 53%, 2 31%, over 2 40% | [#table_1](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/9/tables#table_1) |
| Chapter 9 Note (4) | Nipples ≤ 600 mm (24 in.) between enclosures: 60% fill; 310.15(C)(1) factors need not apply | [Ch 9](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/9/tables) |
| Chapter 9 Table 4, EMT | Total area 1/2 0.304, 3/4 0.533, 1 0.864, 1¼ 1.496, 1½ 2.036, 2 3.356 in² | [#table_4](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/9/tables#table_4) |
| Chapter 9 Table 5, THHN | 14 0.0097, 12 0.0133, 10 0.0211, 8 0.0366, 6 0.0507, 4 0.0824, 3 0.0973, 2 0.1158, 1 0.1562 in² | [#table_5](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/9/tables#table_5) |
| Chapter 9 Table 8 | Circular mils 14–1 AWG and uncoated stranded Cu Ω/kFT 3.14, 1.98, 1.24, 0.778, 0.491, 0.308, 0.245, 0.194, 0.154 | [#table_8](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/9/tables#table_8) |

Every table constant in `tools/pipeline/nec_calc.py` matches these readings. Two edits came
out of the pass: `STD_240_6A` now starts at 10 A like Table 240.6(A), and the welder table
constant is named `T630_31A`. Some `nec_calc` values were not re-read in this pass and are used
only by helper tests, not by any bank record's check:

- the dwelling unit load of 3 VA/ft² (220.41);
- the 1500 VA small-appliance and laundry circuit loads (220.52);
- K = 12.9 and 21.2, which are textbook voltage-drop constants, not NEC values.

## Guards

- `data/question_requirements.json` is the machine-readable classification. Its entries hold
  class, tables, steps, whether the table shows before answering, and an optional `check`
  spec.
- `tools/pipeline/check_requirements.py` enforces the following rules (the new unit tests
  run it inside `tools/verify.sh`):
  - every bank id is classified, and no ids are stale;
  - `table` classes have a `reference_table` or a tab-separated table in `reference_text`;
  - calc, formula and table+calc records have a `formula` hint and a `check`;
  - `pre_answer_table` agrees with `table_after_answer`;
  - each `check` recomputes to the keyed answer;
  - the last number in `worked` equals the check value.
- `tools/pipeline/nec_calc.py` holds the NEC 2023 constants plus helpers for the simple
  recomputable cases:
  - box fill (314.16(B));
  - conduit fill and maximum conductor count (Chapter 9 Tables 1, 4 and 5, Note 7 rounding);
  - voltage drop (Table 8 resistance, or the K method);
  - dwelling lighting demand (220.42, 220.45, 220.52);
  - range demand (Table 220.55 Note 1) and dryer demand (Table 220.54);
  - multioutlet assemblies;
  - ampacity with correction and adjustment;
  - EGC size, welder OCPD and duty cycle, busbar capacity, and the 1/10 tap rule.
- `tools/tests/test_question_requirements.py` has 19 tests:
  - the bank passes `check_requirements`;
  - one negative case per rule;
  - helper cases for box fill, Annex C EMT counts, voltage drop, dwelling demand, and dryer and
    range demand.

  `check_worked_solutions.main_for()` is now callable from tests.

## Per-record requirements

"Table shown" means when the lookup table appears. "Before answering" tables blank any cell
that matches the answer.

| Record | Class | Tables / values and steps needed | Table shown | Formula hint | Fixed | Verified on UpCodes |
|---|---|---|---|---|---|---|
| final-exam-#1-004 | calc | Table 220.42(A): office = 1.3 VA/ft²; General lighting load = floor area × unit load (220.42); 5,000 ft² × 1.3 VA/ft² = 6,500 VA | before answering | yes | — | [220.42(A)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#table_220.42-A), [220.42](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection) |
| final-exam-#1-010 | calc | 220.14(H)(1): each 5 ft or fraction of multioutlet assembly = one outlet of 180 VA (appliances not used simultaneously); Outlets = 12 ft ÷ 5 ft = 2.4, round up to 3; 3 × 180 VA = 540 VA | none | yes | — | [220.14(H)(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection) |
| final-exam-#1-014 | table+calc | Table 310.16: 12 AWG Cu, 75°C (THWN) = 25 A; Table 310.15(B)(1)(1): 86°F (30°C) ambient = 1.00; Table 310.15(C)(1): 4–6 current-carrying conductors = 80%; Ampacity = table ampacity × temperature correction × adjustment; 25 A × 1.00 × 0.80 = 20 A | before answering | yes | — | [310.16](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials), [310.15(B)(1)(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#table_310.15-B-1-1), [310.15(C)(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#table_310.15-C-1) |
| final-exam-#1-026 | table | Table 310.4(1): RHW-2 = 90°C, dry and wet locations; The -2 suffix marks a 90°C rating in wet and dry locations | after answering | none | — | [310.4(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#table_310.4-1) |
| final-exam-#1-027 | table+calc | Table 310.16: 10 AWG Cu, 90°C (THWN-2) = 40 A; Table 310.15(B)(1)(1): 105–113°F (41–45°C), 90°C column = 0.87; Table 310.15(C)(1): 3 current-carrying conductors, no adjustment; Ampacity = table ampacity × temperature correction; 40 A × 0.87 = 34.8 A | before answering | yes | — | [310.16](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials), [310.15(B)(1)(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#table_310.15-B-1-1), [310.15(C)(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#table_310.15-C-1) |
| final-exam-#1-032 | calc | 240.21(B)(1), list item (4): field-installed tap leaving the enclosure: tap ampacity ≥ 1/10 of the feeder OCPD rating; Maximum feeder OCPD = 10 × tap ampacity; 10 × 40 A = 400 A | none | yes | — | [240.21(B)(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection) |
| final-exam-#1-034 | table | Table 400.4: SPT-2 = damp locations; SPT-2W and STOOW = damp and wet locations; Table 400.4 Note 9: cords with the W suffix are suitable for wet locations and sunlight resistant; THWN and XHWN are building wire (Table 310.4(1)), not flexible cords; Find the cord type rated for wet locations that is also sunlight resistant | before answering | none | Table 400.4 excerpt + Note 9 | [400.4](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#table_400.4), [310.4(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#table_310.4-1) |
| final-exam-#1-046 | calc | 40% = 40/100; Reduce by 20: 2/5 | none | yes | — | value in the stem |
| final-exam-#1-049 | table | Table 300.5(A), row 'In trench below 2-in. thick concrete or equivalent': Column 1 direct burial = 18 in.; Columns 2-5 = 6, 12, 6, 6 in.; Pick the row for the location, then the column for the wiring method | before answering | none | Table 300.5(A) columns 1-5 | [300.5(A)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#table_300.5-A) |
| final-exam-#1-062 | formula | % voltage drop = (source V − load V) ÷ source V × 100; (125 − 115) ÷ 125 × 100 = 8% | none | yes | — | value in the stem |
| final-exam-#1-065 | formula | t = (angle ÷ 360°) × (1 ÷ frequency); (90 ÷ 360) × (1 ÷ 60) = 1/240 s | none | yes | — | value in the stem |
| final-exam-#1-068 | table | Table 250.122: a 50 A rating falls in the 'not exceeding 60 A' row = 10 AWG copper; Size the EGC from the OCPD rating; a rating between rows takes the next larger row | before answering | yes | — | [250.122](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#table_250.122) |
| final-exam-#1-070 | table | Table 430.250: 50 hp, induction-type wound rotor, 460 V column (used for a 480 V system) = 65 A; 430.6(A)(1): use the table current, not the nameplate; Read the full-load current for the horsepower in the 460 V column | before answering | yes | — | [430.250](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#table_430.250), [430.6(A)(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use) |
| final-exam-#3-014 | table | Table 210.21(B)(2): 15 or 20 A circuit, 15 A receptacle = 12 A maximum load; Read the row for the circuit and receptacle rating | before answering | none | — | [210.21(B)(2)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#table_210.21-B-2) |
| final-exam-#3-017 | table | Table 250.122: 15 A = 14 AWG, 20 A = 12 AWG, 30 A (60 A row) = 10 AWG copper; 240.4(D): 14/12/10 AWG circuit conductors on 15/20/30 A; Compare each EGC size with the circuit conductor size for that rating | before answering | none | — | [250.122](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#table_250.122), [240.4(D)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection) |
| final-exam-#3-063 | calc | 366.23(A): bare copper bars, 1000 A per in² of cross section (aluminum 700 A); Capacity = cross section × 1000 A/in²; 1.5 in² × 1000 = 1500 A | none | yes | — | [366.23(A)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials) |
| final-exam-#5-032 | table | Table 348.22: 3/8 FMC, THHN column: 10 AWG = 1 conductor (fittings inside or outside); The largest size with a nonzero count is the answer | after answering | none | — | [348.22](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#table_348.22) |
| final-exam-#5-039 | calc | 366.23(A): bare copper bars, 1000 A per in² of cross section (aluminum 700 A); Cross section = 4 in × 0.5 in = 2 in²; 2 in² × 1000 = 2000 A | none | yes | — | [366.23(A)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials) |
| final-exam-#1-001 | calc | 60% = 60/100; Reduce by 20: 3/5 | none | yes | — | value in the stem |
| final-exam-#1-022 | calc | 210.52(G)(1): at least one receptacle outlet in each vehicle bay; Outlets = bays × 1; 2 × 1 = 2 | none | yes | — | [210.52(G)(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection) |
| final-exam-#3-052 | table | Table 430.37: 3-phase ac motor, any 3-phase supply = three overload units, one in each phase; Read the row for the motor and supply system | before answering | none | — | [430.37](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use) |
| final-exam-#3-053 | table | Table 344.30(B): RMC trade size 1 = 12 ft between supports (threaded couplings); Read the support spacing for the trade size | after answering | none | — | [344.30(B)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#table_344.30-B) |
| final-exam-#1-040 | table | Table 220.54: 5 dryers = 85%; Read the demand factor for the number of dryers | before answering | yes | — | [220.54](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection) |
| final-exam-#1-067 | table | Chapter 9, Note (4): nipples 24 in. or shorter between enclosures may be filled to 60%; Apply Note (4) instead of Table 1 for short nipples | before answering | yes | — | [Ch 9 Note (4)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/9/tables) |
| final-exam-#1-025 | calc | 630.12(A): arc-welder OCPD not more than 200% of I1max; 630.12 and 240.6(A): the next higher standard rating is permitted (standard ratings step 10 A from 60 A to 110 A); 43 A × 200% = 86 A; Next higher standard rating = 90 A | none | yes | formula: 240.6(A) next-higher-rating step | [630.12(A)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment), [630.12](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment), [240.6(A)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#table_240.6-A) |
| final-exam-#3-033 | formula | I = P ÷ E; 2 W ÷ 20 V = 0.10 A | none | yes | — | value in the stem |
| final-exam-#3-048 | table | Table 348.22: 3/8 FMC, THHN column: 10 AWG = 1 conductor (fittings inside or outside); The largest size with a nonzero count is the answer | after answering | none | — | [348.22](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#table_348.22) |
| open-book-exam-#1-021 | calc | Table 220.42(A): office = 1.3 VA/ft²; General lighting load = floor area × unit load (220.42); 5,000 ft² × 1.3 VA/ft² = 6,500 VA | before answering | yes | — | [220.42(A)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#table_220.42-A), [220.42](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection) |
| open-book-exam-#4-004 | table | Table 300.5(A), row 'In trench below 2-in. thick concrete or equivalent': Column 1 direct burial = 18 in.; Columns 2-5 = 6, 12, 6, 6 in.; Pick the row for the location, then the column for the wiring method | before answering | none | Table 300.5(A) columns 1-5 | [300.5(A)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#table_300.5-A) |
| open-book-exam-#4-015 | table | Table 220.54: 5 dryers = 85%; Read the demand factor for the number of dryers | before answering | yes | — | [220.54](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection) |
| open-book-exam-#4-025 | table | Table 400.4: SPT-2 = damp locations; SPT-2W and STOOW = damp and wet locations; Table 400.4 Note 9: cords with the W suffix are suitable for wet locations and sunlight resistant; THWN and XHWN are building wire (Table 310.4(1)), not flexible cords; Find the cord type rated for wet locations that is also sunlight resistant | before answering | none | Table 400.4 excerpt + Note 9 | [400.4](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#table_400.4), [310.4(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#table_310.4-1) |
| open-book-exam-#10-016 | table | Table 110.26(A)(1), Condition 2 note: concrete, brick, or tile walls are considered grounded; Read the Condition 2 definition under Table 110.26(A)(1) | in the provision text | none | — | [110.26(A)(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general) |
| final-exam-#1-063 | calc | Feet = drawing inches ÷ scale inches per foot; 3.5 ÷ 0.25 = 14 ft | none | yes | — | value in the stem |
| final-exam-#1-021 | table+calc | Table 220.55, Column C: one range not over 12 kW = 8 kW; Table 220.55 Note 1: +5% for each kW or major fraction over 12 kW; 14 kW − 12 kW = 2 kW over; 2 × 5% = 10%; 8 kW × 1.10 = 8.8 kW | before answering | yes | — | [220.55](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection) |
| final-exam-#3-055 | formula | Equal resistors in parallel: R_total = R ÷ n; 2,000 Ω ÷ 2 = 1,000 Ω | none | yes | — | value in the stem |
| final-exam-#3-040 | table+calc | Table 630.31(A): 15% duty cycle = 0.39; Supply ampacity = primary current × duty-cycle multiplier; 21 A × 0.39 = 8.19 A | before answering | yes | lookup hint: Table 630.31(A) | [630.31(A)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment#table_630.31-A) |
| final-exam-#5-070 | table | Table 352.30(B): PVC trade size 1/2–1 = 3 ft between supports; Read the support spacing for the trade size | before answering | none | — | [352.30(B)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#table_352.30-B) |
| ne-state-act-#3-003 | calc | Neb. Rev. Stat. 81-2113(2): not more than three apprentice electricians per licensee; Apprentices = licensees × 3; 3 × 3 = 9 | none | yes | formula added | State law (Neb. Rev. Stat. 81-2113(2)), not NEC |

### Recall records (245)

No table, calculation or formula is needed. Question numbers by exam:

- **Final Exam #1** (50): 1-002, 1-003, 1-005, 1-006, 1-007, 1-008, 1-009, 1-011, 1-012, 1-013, 1-015, 1-016, 1-017, 1-018, 1-019, 1-020, 1-023, 1-024, 1-028, 1-029, 1-030, 1-031, 1-033, 1-035, 1-036, 1-037, 1-038, 1-039, 1-041, 1-042, 1-043, 1-044, 1-045, 1-047, 1-048, 1-050, 1-051, 1-052, 1-053, 1-054, 1-055, 1-056, 1-057, 1-058, 1-059, 1-060, 1-061, 1-064, 1-066, 1-069
- **Final Exam #3** (61): 3-001, 3-002, 3-003, 3-004, 3-005, 3-006, 3-007, 3-008, 3-009, 3-010, 3-011, 3-012, 3-013, 3-015, 3-016, 3-018, 3-019, 3-020, 3-021, 3-022, 3-023, 3-024, 3-025, 3-026, 3-027, 3-028, 3-029, 3-030, 3-031, 3-032, 3-034, 3-035, 3-036, 3-037, 3-038, 3-039, 3-041, 3-042, 3-043, 3-044, 3-045, 3-046, 3-047, 3-049, 3-050, 3-051, 3-054, 3-056, 3-057, 3-058, 3-059, 3-060, 3-061, 3-062, 3-064, 3-065, 3-066, 3-067, 3-068, 3-069, 3-070
- **Final Exam #5** (36): 5-001, 5-002, 5-003, 5-004, 5-005, 5-006, 5-007, 5-008, 5-017, 5-018, 5-019, 5-020, 5-021, 5-022, 5-023, 5-024, 5-033, 5-034, 5-035, 5-036, 5-037, 5-038, 5-048, 5-049, 5-050, 5-051, 5-052, 5-053, 5-054, 5-055, 5-064, 5-065, 5-066, 5-067, 5-068, 5-069
- **NE State Act #3** (3): 3-001, 3-002, 3-004
- **Open Book Exam #1** (24): 1-001, 1-002, 1-003, 1-004, 1-005, 1-006, 1-007, 1-008, 1-009, 1-010, 1-011, 1-012, 1-013, 1-014, 1-015, 1-016, 1-017, 1-018, 1-019, 1-020, 1-022, 1-023, 1-024, 1-025
- **Open Book Exam #10** (24): 10-001, 10-002, 10-003, 10-004, 10-005, 10-006, 10-007, 10-008, 10-009, 10-010, 10-011, 10-012, 10-013, 10-014, 10-015, 10-017, 10-018, 10-019, 10-020, 10-021, 10-022, 10-023, 10-024, 10-025
- **Open Book Exam #4** (22): 4-001, 4-002, 4-003, 4-005, 4-006, 4-007, 4-008, 4-009, 4-010, 4-011, 4-012, 4-013, 4-014, 4-016, 4-017, 4-018, 4-019, 4-020, 4-021, 4-022, 4-023, 4-024
- **Open Book Exam #7** (25): 7-001, 7-002, 7-003, 7-004, 7-005, 7-006, 7-007, 7-008, 7-009, 7-010, 7-011, 7-012, 7-013, 7-014, 7-015, 7-016, 7-017, 7-018, 7-019, 7-020, 7-021, 7-022, 7-023, 7-024, 7-025
| final-exam-#2-019 | formula | Length × 3: 5 × 3 = 15 ohms; Area × 1/2: 15 ÷ 0.5 = 30 ohms | none | yes | new (2026-09-29 import) | [General calculation]() |
| final-exam-#2-023 | table | Table 110.28 outdoor use, Corrosive agents row: X under Types 3X, 3RX, 3SX, 4X, 6P; Types 12 and 13 are indoor only | after answering | none | new (2026-09-29 import) | [Table 110.28](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#110) |
| final-exam-#2-046 | table | Table 110.26(A)(1), Condition 2 note: concrete, brick, or tile walls are considered grounded; Read the Condition 2 definition under Table 110.26(A)(1) | none | none | new (2026-09-29 import) | [110.26(A)(1) Condition 2](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#110) |
| final-exam-#2-057 | calc | Decimal = numerator ÷ denominator; 11 ÷ 16 = 0.6875 | none | yes | new (2026-09-29 import) | [General calculation]() |
| final-exam-#4-005 | table | Table 314.16(A): 3 x 2 x 2 device box = 10.0 in.3; Find the 3 x 2 x 2 device box row and read the minimum volume | none | none | new (2026-09-29 import) | [Table 314.16(A)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#314) |
| final-exam-#4-006 | table | Chapter 9, Table 9: 4/0 aluminum, steel conduit, per 1000 ft: AC resistance 0.11, effective Z at 0.85 PF 0.11; Use the per-1000-ft row for 4/0 and read the aluminum, steel conduit columns | none | none | new (2026-09-29 import) | [Table 9, Chapter 9](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/9/tables) |
| final-exam-#4-009 | table | Table 392.60(B) steel: 200 A = 0.70 in.2; 400 A = 1.00 in.2; 0.79 in.2 meets the 0.70 in.2 row but not the 1.00 in.2 row | after answering | none | new (2026-09-29 import) | [Table 392.60(B)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#392) |
| final-exam-#4-011 | table | Table 314.16(A): 3 x 2 x 2 = 10.0 in.3; 3 x 2 x 2-1/4 = 10.5 in.3; Pick the smallest listed device box with at least 10.25 in.3 | none | none | new (2026-09-29 import) | [Table 314.16(A)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#314) |
| final-exam-#4-021 | table | Table 314.16(B)(1): 12 AWG = 2.25 in.3, 14 AWG = 2.00 in.3; Table 314.16(A): 4 x 2-1/8 octagon = 21.5 in.3; 5 x 2.25 + 4 x 2.00 = 19.25 in.3; Smallest octagon box of at least 19.25 in.3: 4 x 2-1/8 in. (21.5 in.3) | none | yes | new (2026-09-29 import) | [Table 314.16(B)(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#314) |
| final-exam-#4-022 | table | Chapter 9, Table 4, EMT: 1 in., over 2 wires 40% = 0.346 in.2; Compare 0.30 in.2 with 0.346 in.2 | none | none | new (2026-09-29 import) | [Table 4, Chapter 9](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/9/tables) |
| final-exam-#4-023 | table+calc | Table 220.55 Column B: 8 appliances = 36%; Table 220.55 Column C: 8 appliances = 23 kW; 32 kW x 0.36 = 11.52 kW (Column B, Note 3); Column B gives less than the 23 kW of Column C | none | yes | new (2026-09-29 import) | [Table 220.55](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#220) |
| final-exam-#4-024 | table+calc | Table 310.16: 14 AWG Cu, 75°C (THW) = 20 A; Table 310.15(C)(1): 4–6 conductors = 80%; 20 A x 1.00 x 0.80 = 16 A | none | yes | new (2026-09-29 import) | [Table 310.15(C)(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#310) |
| final-exam-#4-025 | table+calc | Table 220.55 Column C: 2 appliances = 11 kW; Two appliances, none over 12 kW: Column C = 11 kW | none | yes | new (2026-09-29 import) | [Table 220.55](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#220) |
| final-exam-#4-026 | table+calc | Table 430.248: 3/4 hp, 115 V = 13.8 A; 13.8 A x 1.25 = 17.25 A | none | yes | new (2026-09-29 import) | [Table 430.248](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#430) |
| final-exam-#4-027 | calc | 2000 ft2 x 3 VA/ft2 = 6000 VA | none | yes | new (2026-09-29 import) | [220.5(C)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#220) |
| final-exam-#4-028 | calc | 3 circuits x 1500 VA = 4500 VA | none | yes | new (2026-09-29 import) | [220.52](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#220) |
| final-exam-#4-029 | table | Table 250.66: 2/0 or 3/0 Cu = 4 AWG Cu GEC; Find the 2/0 copper row and read the copper GEC size | none | none | new (2026-09-29 import) | [Table 250.66](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#250) |
| final-exam-#4-030 | table+calc | Table 430.248: 1-1/2 hp, 230 V = 10 A; 10 x 1.25 + 10 = 22.5 A | none | yes | new (2026-09-29 import) | [430.24](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#430) |
| final-exam-#4-031 | table+calc | Table 310.16: 12 AWG Cu, 60°C (TW) = 20 A; Table 310.15(B)(1)(1): 69–77°F, 60°C column = 1.08; 20 A x 1.08 = 21.6 A | none | yes | new (2026-09-29 import) | [Table 310.15(B)(1)(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#310) |
| final-exam-#4-032 | table+calc | Table 430.248: 3 hp, 115 V = 34 A; Table 430.52(C)(1): dual element fuse = 175%; 34 x 1.75 = 59.5 A; Next standard size (240.6(A)) = 60 A | none | yes | new (2026-09-29 import) | [Table 430.52(C)(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#430) |
| final-exam-#4-033 | table+calc | Table 310.16: 14 AWG Cu, 75°C (THW) = 20 A; Table 310.15(C)(1): 4–6 conductors = 80%; 20 A x 1.00 x 0.80 = 16 A | none | yes | new (2026-09-29 import) | [Table 310.15(C)(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#310) |
| final-exam-#4-034 | table+calc | Table 430.248: 3 hp, 230 V = 17 A; 430.32(C): all other motors = 130%; 17 x 1.30 = 22.1 A | none | yes | new (2026-09-29 import) | [430.32(C)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#430) |
| final-exam-#4-035 | table | Table 310.15(B)(1)(1): 96–104°F, 60°C = 0.82; Read the 96–104°F row in the 60°C column | none | none | new (2026-09-29 import) | [Table 310.15(B)(1)(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#310) |
| final-exam-#4-037 | calc | 430.32(C): service factor 1.15 or greater = 140%; 24 x 1.40 = 33.6 A | none | yes | new (2026-09-29 import) | [430.32(C)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#430) |
| final-exam-#4-038 | table+calc | Table 314.16(B)(1): 12 AWG = 2.25 in.3; 4 conductors + 1 clamp + 2 device + 1 EGC = 8 allowances; 8 x 2.25 = 18 in.3 | none | yes | new (2026-09-29 import) | [314.16(B)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#314) |
| final-exam-#4-039 | table+calc | Table 430.250: 10 hp, 230 V = 28 A; 28 x 1.25 = 35 A | none | yes | new (2026-09-29 import) | [Table 430.250](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#430) |
| final-exam-#4-040 | table+calc | Table 310.16: 12 AWG Cu, 90°C (THHN) = 30 A; Table 310.15(C)(1): 7–9 conductors = 70%; 30 x 0.70 = 21 A | none | yes | new (2026-09-29 import) | [Table 310.15(C)(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#310) |
| final-exam-#4-041 | table+calc | Table 310.16: 12 AWG Cu, 75°C (THW) = 25 A; Table 310.15(B)(1)(1): 26–30°C = 1.00; 25 x 1.00 = 25 A | none | yes | new (2026-09-29 import) | [Table 310.16](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#310) |
| final-exam-#4-042 | calc | 10 x 4.5 = 45 kW; 45 x 0.75 = 33.75 kW | none | yes | new (2026-09-29 import) | [220.53](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#220) |
| final-exam-#4-043 | table+calc | Table 310.16: 10 AWG Cu, 90°C (RHH) = 40 A; Table 310.15(B)(1)(1): 96–104°F, 90°C = 0.91; 240.4(D)(8): 10 AWG Cu = 30 A; 40 x 0.91 = 36.4 A; 240.4(D) limit = 30 A | after answering | yes | new (2026-09-29 import) | [240.4(D)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#240) |
| final-exam-#4-045 | table+calc | Table 220.55 Column B: 3 appliances = 55%; 13 kW x 0.55 = 7.15 kW | none | yes | new (2026-09-29 import) | [Table 220.55](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#220) |
| final-exam-#4-046 | table+calc | 220.54: 5 kW minimum per dryer; Table 220.54: 6 dryers = 75%; 220.61(B)(1): neutral 70%; 6 x 5 = 30 kW; 30 x 0.75 = 22.5 kW; 22.5 x 0.70 = 15.75 kW | none | yes | new (2026-09-29 import) | [Table 220.54](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#220) |
| final-exam-#4-047 | calc | 2500 x 3 = 7500 VA; 7500 / 1800 = 4.17, round up to 5 | none | yes | new (2026-09-29 import) | [220.41](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#220) |
| final-exam-#4-049 | table+calc | Table 220.55 Column B: 15 appliances = 32%; Table 220.55 Column C: 15 appliances = 30 kW; 52.5 x 0.32 = 16.8 kW (Column B, Note 3); Column B gives less than the 30 kW of Column C | none | yes | new (2026-09-29 import) | [Table 220.55](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#220) |
| final-exam-#4-050 | table | Chapter 9, Table 5: 14 AWG RHH* (no outer covering) = 0.0209 in.2; Use the asterisk row for RHH without an outer covering | none | none | new (2026-09-29 import) | [Table 5, Chapter 9](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/9/tables) |
| final-exam-#4-051 | table+calc | Table 220.55 Column B: 1 appliance = 80%; Table 220.55 Column C: 1 appliance = 8 kW; 8 x 0.80 = 6.4 kW (Column B, Notes 3 and 4) | none | yes | new (2026-09-29 import) | [Table 220.55](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#220) |
| final-exam-#4-052 | calc | 1800 ft2 x 3 VA/ft2 = 5400 VA | none | yes | new (2026-09-29 import) | [220.5(C)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#220) |
| final-exam-#4-053 | table+calc | Table 430.248: 2 hp, 208 V = 13.2 A; Table 430.52(C)(1): dual element fuse = 175%; 13.2 x 1.75 = 23.1 A; Next standard size (240.6(A)) = 25 A maximum; Only the 20 A choice is within it | none | yes | new (2026-09-29 import) | [Table 430.52(C)(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#430) |
| final-exam-#4-054 | table+calc | Table 314.16(B)(1): 12 AWG = 2.25 in.3; 2 x 2.25 + 2.25 = 6.75 in.3 | none | yes | new (2026-09-29 import) | [314.16(B)(5)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#314) |
| final-exam-#4-055 | table+calc | Table 250.122: 100 A = 8 AWG Cu; 80 A is not over 100 A: 8 AWG copper | none | yes | new (2026-09-29 import) | [Table 250.122](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#250) |
| final-exam-#4-056 | table+calc | Table 430.248: 2 hp, 208 V = 13.2 A; 430.32(C): all other motors = 130%; 13.2 x 1.30 = 17.16 A | none | yes | new (2026-09-29 import) | [430.32(C)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#430) |
| final-exam-#4-057 | table+calc | Chapter 9, Table 5 XHHW: 8 AWG = 0.0437 in.2, 6 AWG = 0.0590 in.2; 6 x 0.0437 = 0.2622; 2 x 0.0590 = 0.1180; 0.2622 + 0.1180 = 0.3802 in.2 | none | yes | new (2026-09-29 import) | [Table 5, Chapter 9](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/9/tables) |
| final-exam-#4-058 | calc | 9500 / 120 = 79.2 A | none | yes | new (2026-09-29 import) | [General calculation]() |
| final-exam-#4-059 | table+calc | Chapter 9, Table 4, RMC: 1 in., 40% = 0.355 in.2; Chapter 9, Table 5: 12 AWG XHHW = 0.0181 in.2; 9 x 0.0181 = 0.1629; 0.355 - 0.1629 = 0.1921 in.2 | none | yes | new (2026-09-29 import) | [Table 4, Chapter 9](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/9/tables) |
| final-exam-#4-060 | table+calc | Chapter 9, Table 4, IMC: 1 in., 60% = 0.575 in.2; Chapter 9, Table 5: 8 AWG TW = 0.0437 in.2; Chapter 9, Note 4: nipples 24 in. or less = 60%; 0.575 / 0.0437 = 13.16; Decimal below 0.8: 13 conductors | none | yes | new (2026-09-29 import) | [Table 4, Chapter 9](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/9/tables) |
| final-exam-#4-061 | table | Table 430.52(C)(1): wound-rotor, nontime delay fuse = 150%; Read the wound-rotor row, nontime delay fuse column | none | none | new (2026-09-29 import) | [Table 430.52(C)(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#430) |
| final-exam-#4-062 | table+calc | Chapter 9, Table 4, PVC Schedule 80: 2 in., 40% = 1.150 in.2; Chapter 9, Table 5: 6 AWG XHHW = 0.0590 in.2; 1.150 / 0.0590 = 19.49; Decimal below 0.8: 19 conductors | none | yes | new (2026-09-29 import) | [Table 4, Chapter 9](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/9/tables) |
| final-exam-#4-063 | table+calc | Table 310.16: 14 AWG Cu, 90°C (RHH) = 25 A; Table 310.15(B)(1)(1): 41–45°C, 90°C = 0.87; Table 310.15(C)(1): 7–9 conductors = 70%; 25 x 0.87 x 0.70 = 15.225 A | none | yes | new (2026-09-29 import) | [Table 310.15(C)(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#310) |
| final-exam-#4-064 | table+calc | Table 314.16(B)(1): 12 AWG = 2.25 in.3, 10 AWG = 2.50 in.3; 3 x 2.25 + 3 x 2.50 = 14.25 in.3 | none | yes | new (2026-09-29 import) | [Table 314.16(B)(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#314) |
| final-exam-#4-065 | table | Chapter 9, Table 5: 3 AWG THWN = 0.0973, 8 AWG THW = 0.0437, 10 AWG THW = 0.0243 in.2; Chapter 9, Table 4, PVC Schedule 80: 1-1/2 in. 40% = 0.684, 2 in. 40% = 1.150 in.2; 0.5838 + 0.1311 + 0.0486 = 0.7635 in.2; Smallest size with 40% area of at least 0.7635: 2 in. | none | yes | new (2026-09-29 import) | [Table 4, Chapter 9](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/9/tables) |
| final-exam-#4-066 | table+calc | Chapter 9, Table 4, RMC: 1 in., 60% = 0.532 in.2; Chapter 9, Table 5: 8 AWG THW = 0.0437 in.2; Chapter 9, Note 4: nipples 24 in. or less = 60%; 0.532 / 0.0437 = 12.17; Decimal below 0.8: 12 conductors | none | yes | new (2026-09-29 import) | [Table 4, Chapter 9](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/9/tables) |
| final-exam-#4-067 | table+calc | Table 430.248: 3 hp, 230 V = 17 A; Table 430.52(C)(1): inverse time breaker = 250%; 17 x 2.50 = 42.5 A; Next standard size (240.6(A)) = 45 A | none | yes | new (2026-09-29 import) | [Table 430.52(C)(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#430) |
| final-exam-#4-068 | table+calc | Chapter 9, Table 4, IMC: 1-1/2 in., 40% = 0.890 in.2; Chapter 9, Table 5: 6 AWG XHHW = 0.0590 in.2; 0.890 / 0.0590 = 15.08; 15 conductors | none | yes | new (2026-09-29 import) | [Table 4, Chapter 9](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/9/tables) |
| final-exam-#4-069 | table+calc | Table 220.55 Column C: 26–30 ranges = 15 kW + 1 kW per range; 15 + 28 = 43 kW | none | yes | new (2026-09-29 import) | [Table 220.55](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#220) |
| final-exam-#4-070 | table+calc | Table 430.250: 15 hp, 208 V = 46.2 A; 46.2 x 208 x 1.732 = 16,644 VA; Closest choice: 17,000 VA | none | yes | new (2026-09-29 import) | [Table 430.250](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#430) |
| open-book-exam-#2-012 | table+calc | Table 310.16: 12 AWG Cu, 75°C (THWN) = 25 A; Table 310.15(B)(1)(1): 86°F (30°C) ambient = 1.00; Table 310.15(C)(1): 4–6 current-carrying conductors = 80%; Ampacity = table ampacity × temperature correction × adjustment; 25 A × 1.00 × 0.80 = 20 A | before answering | yes | new (2026-09-29 import) | [Table 310.16](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#310) |
| open-book-exam-#2-018 | calc | 220.14(H)(1): each 5 ft or fraction of multioutlet assembly = one outlet of 180 VA (appliances not used simultaneously); Outlets = 12 ft ÷ 5 ft = 2.4, round up to 3; 3 × 180 VA = 540 VA | none | yes | new (2026-09-29 import) | [220.14(H)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#220) |
| open-book-exam-#3-002 | calc | 240.21(B)(1), list item (4): field-installed tap leaving the enclosure: tap ampacity ≥ 1/10 of the feeder OCPD rating; Maximum feeder OCPD = 10 × tap ampacity; 10 × 40 A = 400 A | none | yes | new (2026-09-29 import) | [240.21(B)(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#240) |
| open-book-exam-#3-010 | table+calc | Table 310.16: 10 AWG Cu, 90°C (THWN-2) = 40 A; Table 310.15(B)(1)(1): 105–113°F (41–45°C), 90°C column = 0.87; Table 310.15(C)(1): 3 current-carrying conductors, no adjustment; Ampacity = table ampacity × temperature correction; 40 A × 0.87 = 34.8 A | before answering | yes | new (2026-09-29 import) | [Table 310.15(B)(1)(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#310) |
| open-book-exam-#3-011 | table | Table 310.4(1): RHW = 75°C, RHW-2 = 90°C, dry and wet locations; The -2 suffix marks a 90°C rating in dry and wet locations | after answering | none | new (2026-09-29 import) | [Table 310.4(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#310) |
| open-book-exam-#3-013 | calc | 630.12(A): arc-welder OCPD not more than 200% of I1max; 630.12 and 240.6(A): the next higher standard rating is permitted (standard ratings step 10 A from 60 A to 110 A); 43 A × 200% = 86 A; Next higher standard rating = 90 A | none | yes | new (2026-09-29 import) | [630.12(A)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment#630) |
| open-book-exam-#3-017 | calc | 210.52(G)(1): at least one receptacle outlet in each vehicle bay; Outlets = vehicle bays × 1; 2 × 1 = 2 | none | yes | new (2026-09-29 import) | [210.52(G)(1)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210) |
| open-book-exam-#3-019 | table+calc | Table 220.55, Column C: one range not over 12 kW = 8 kW; Table 220.55 Note 1: +5% for each kW or major fraction over 12 kW; 14 kW − 12 kW = 2 kW over; 2 × 5% = 10%; 8 kW × 1.10 = 8.8 kW | before answering | yes | new (2026-09-29 import) | [Table 220.55](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#220) |
| open-book-exam-#6-010 | table | Table 430.250: 50 hp, induction-type wound rotor, 460 V column (used for a 480 V system) = 65 A; 430.6(A)(1): use the table current, not the nameplate; Read the full-load current for the horsepower in the 460 V column | before answering | yes | new (2026-09-29 import) | [Table 430.250](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#430) |
| open-book-exam-#6-012 | table | Table 250.122: a 50 A rating falls in the 'not exceeding 60 A' row = 10 AWG copper; Size the EGC from the OCPD rating; a rating between rows takes the next larger row | before answering | yes | new (2026-09-29 import) | [Table 250.122](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#250) |
| open-book-exam-#6-014 | table | Chapter 9, Note (4): nipples 24 in. or shorter between enclosures may be filled to 60%; Apply Note (4) instead of Table 1 for short nipples | before answering | yes | new (2026-09-29 import) | [Chapter 9, Note 4](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/9/tables) |
| open-book-exam-#6-016 | table | Table 352.30(B): PVC trade size 1 1/4-2 = 1.5 m (5 ft) between supports; Find the row that contains the trade size and read the spacing | after answering | none | new (2026-09-29 import) | [Table 352.30(B)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#352) |
| open-book-exam-#12-023 | table | Table 250.122: 30 A device -> 10 AWG copper (60 A row); 250.122(A): not required larger than the 12 AWG circuit conductors | after answering | none | new (2026-09-29 import) | [250.122(A)](https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#250) |

## Exam import (2026-09-29)

Open Book #2, #3, #5, #6, #9, #11, #12 and Final #2 and #4 add 68 table, calculation or formula
records (rows marked "new" below). Every table value in their lookup tables and provisions is a
verbatim line of the NEC 2023 text cache, and `check_requirements.py` recomputes every `check`
from NEC 2023 constants: PASS, 0 mismatches.

- `nec_calc` gained the Table 310.15(B)(1)(1) 69–77°F row (1.08 / 1.05 / 1.04), which
  final-exam-#4-031 needs (12 AWG TW at 75°F: 20 A × 1.08 = 21.6 A).
- Final #4 Q25, Q49, Q51 and Q69 stems now name the Table 310.16 column the key uses.
- final-exam-#4-006 (Chapter 9 Table 9): the PDF choice 0.102 is the older value; 2023 lists 0.11,
  and the choice was updated (key unchanged).
- Final Exam #1 Q22 and Q32 formula strips no longer state the rule's answer before answering
  (request from the diagrams audit); the full rule stays in the post-answer tip.

## Checks (worktree, before landing)

- `check_requirements.py`: PASS, 283 classified, 33 recomputed.
- `check_worked_solutions.py`: PASS, 31 recomputed, 25 chains.
- `validate_question_bank.py --no-warn`: 0 errors, 0 warnings.
- `spellcheck_bank.py --offline`: 0 findings.
- `measure_fit`: 0% of 283 records need scrolling before or after answering, and no table
  scrolls, on desktop 1280×720 and mobile 540×960.
- Spoken text: no record's speech plan differs from master's (`dump_speech.gd` compared before and after). The changed fields (tables, formula, lookup hint, #3-068 notes, #10-024 background line) are not read aloud, so no clips are re-rendered. `pregenerate_speech.py --bundle` still confirms 283/283 clips.

## First pass (history)

The rest of this document is the first pass. It predates UpCodes access, so its "Unconfirmed
for 2023" statuses are superseded by the verification table above. Where it disagrees with the
tables above, trust the tables above.


Scope: every `reference_table`, table-titled `reference_text`, `formula` and `worked` solution in
`question_bank.json` (279 records; 25 with a `reference_table`, 18 with a formula). NEC 2023 is the
authority. Stems (`prompt`), choices (`answers`) and `correct_index` were not touched — see
*Verification*.

All fixes go through `tools/pipeline/question_bank_overrides.json` (plus one builder string in
`tools/pipeline/build_question_bank.py`) and a candidate build; the bank was never hand-edited.

### Sources and how each edition was used

| Tag | Source | Edition | Use |
|---|---|---|---|
| **UC** | UpCodes viewer, `https://up.codes/viewer/nfpa/nfpa-70-2023/...` (the URLs the bank links to) | 2023 | **Login-gated.** The page's `__NEXT_DATA__` has `"missingRequiredLogin":true` for NFPA 70 2023 and 2020; no code text is served without an account, and none was created. The `/s/` SEO pages are AI summaries that mix editions, so they were not used as evidence. |
| **N23** | *NFPA 70 National Electrical Code 2023* — public OCR copy on studylib.net (Chapters 1–2, through ~Article 235) | **2023** | Primary evidence for Articles 110–250. |
| **FD26** | NFPA A2025-cycle CMP-6 First Draft working draft (docinfofiles.nfpa.org) | 2026 draft quoting the 2023 baseline text | Article 310 table titles, notes and values shown as unchanged baseline text. |
| **SD26-8** | NFPA A2025-cycle CMP-8 Second Draft working draft (docinfofiles.nfpa.org) | 2026 draft quoting the 2023 baseline | Article 344/348/352 table names. |
| **T23** | 2023-labeled trade sources: EC&M 2023 NEC quiz (ecmweb.com), FastTrax 2023 NEC answer key, electricallicenserenewal.com 2023 NEC Chapter 9 notes | 2023 (secondary) | Table 344.30(B), Table 352.30(B), Chapter 9 Note (4) wording. |
| **N20** | 2020 NEC text (Articles 400–630 excerpt) | 2020 | Used only where no 2023 source was available; such items are marked **Unconfirmed for 2023**. |
| **N14** | 2014 NEC Article 220 (MADCAD) | 2014 | History only (2017→2023 renumbering). |

Status meanings:

- **Verified 2023**: the value was matched against N23 (the 2023 text itself).
- **Verified 2023 (secondary)**: the value was matched against T23, or against an NFPA 2026 draft's unchanged baseline text.
- **Unconfirmed for 2023**: the only text available was another edition; the item is flagged, not treated as verified.

### Tables

| Table (records) | Status and source | What was wrong | Fix |
|---|---|---|---|
| **Table 220.54** Demand Factors for Household Electric Clothes Dryers (final-exam-#1-040, open-book-exam-#4-015) | Verified 2023 (N23). The values are the same in N14, so these rows are unchanged since 2014. | The table showed 6 dryers = 80%, 7 = 75%, 8 = 70%. The 2023 values are 75%, 65% and 60%. The tip and choice notes repeated the wrong values; one tip said "dropping 5 percent per added dryer". The correct answer (85% for 5) was right. | Full 2023 table: 1–4 at 100%, then 5 through 11 at 85/75/65/60/55/50/47%, then 12–23, 24–42, and 43 and over (25%). Added a note on the 5000 W-or-nameplate rule. Rewrote `tip_short` and the three wrong-choice notes. |
| **Table 250.122** Minimum Size Equipment Grounding Conductors… (final-exam-#1-068, final-exam-#3-017) | Verified 2023 (N23). Rows are 15/20/60/100 A → Cu 14/12/10/8. | The table had invented "30 A" and "40–60 A" rows. The answer "#10" highlighted three cells, including an aluminum one. #3-017's reference text was copied from #1-068 (the 50 A example). | Copper excerpt with the real rows and a note on sizing from the OCPD and using the next larger row. #1-068 now highlights exactly one cell. Wrote a correct reference text for #3-017 (15/20/30 A → 14/12/10 AWG). |
| **Table 310.16** Ampacities of Insulated Conductors with Not More Than Three Current-Carrying Conductors… (final-exam-#1-014) | Verified 2023 (secondary): FD26 baseline title, Notes 1–3, and #12 Cu 20/25/30. | The cells read "20 A", which matched the answer "20a". So the 60°C cell was highlighted as the answer, and blanked before answering. The answer actually comes from 25 A (75°C) × 0.80. | Headers are now "AWG / type · 60°C TW · 75°C THWN · 90°C THHN" and the row is "#12 THWN · 20 · 25 · 30", with no false highlight. The note cites Note 1 / 310.15(B) and Table 310.15(C)(1) at 80%. |
| **Table 430.37** Overload Units (final-exam-#3-052) | **Unconfirmed for 2023.** N20 has "3-phase ac, any 3-phase: three, one in each phase*". | The answer "3" also matched "Three-phase motor", so the row label was blanked before answering. The mobile layout clipped the wrapped row. | Row "3φ ac, any 3φ supply · Three*" with the note "*One in each phase, unless protected by other approved means." Only the answer cell highlights. Reference text rewritten the same way. |
| **Chapter 9 Notes to Tables, Note (4)** (final-exam-#1-067) | Verified 2023 (secondary): T23 gives the 2023 wording. | The reference text was unrelated ("…each conductor's area from Chapter 5 of Table 5"). | Reference text now quotes Note (4) (24 in./600 mm nipples between enclosures, 60% fill, 310.15(C)(1) factors need not apply). The table is shortened so it stays on one line on mobile. |
| **Table 220.42(A)** General Lighting Loads by Non-Dwelling Occupancy (final-exam-#1-004, open-book-exam-#1-021) | Verified 2023 (N23). All 29 values match; Office = 1.3. | The header was "VA/ft2". The hotel row used a paraphrase. The table's 125% note was missing. | Header "Type of occupancy · Unit load (VA/ft²)". Hotel row uses the 2023 label ("Hotel or motel, or apartment house without provision for cooking by tenant"). Added a note that the 210.20(A) 125% multiplier is already included. |
| **Table 220.45** Lighting Load Demand Factors (13 `info_tip`s and the builder default) | Verified 2023 (N23): dwelling units are the first 3000 VA at 100%, 3001–120,000 VA at 35%, and the remainder at 25%. | The blurb said "the rest at 35%", leaving out the 25% tier. | Changed to "3,001 to 120,000 VA at 35%, the remainder at 25%" in 13 overrides and in `build_question_bank.py`. |
| **Table 220.55** (final-exam-#1-021) | Verified 2023 (N23): Column C is 8 kW; Note 1 adds 5% per kW over 12 kW, so 14 kW → 8.8 kW. | The title had an OCR artifact: "over 13/4 kW Rating". | Changed to "over 1¾ kW Rating" (renders correctly; see screenshots). |
| **Table 210.21(B)(2)** (final-exam-#3-014) | Verified 2023 (N23): a 20 A circuit with a 20 A receptacle is 16 A; a 15 A receptacle on it is 12 A. | — | No change. |
| **Table 344.30(B)** Supports for Rigid Metal Conduit (final-exam-#3-053) | Verified 2023 (secondary): T23 (EC&M 2023) and SD26-8. | The tip and correct-choice note said "Table 344.30(B)(2)". That was the 2017 name. | Changed to "Table 344.30(B)". The code reference 344.30(B)(2) is the section and was kept. |
| **Table 352.30(B)** Support of Rigid PVC Conduit (final-exam-#5-070) | Verified 2023 (secondary): T23 (FastTrax 2023) and SD26-8. | — (2017 called it "Table 352.30"; the bank already uses the 2023 name.) | No change. |
| **Table 348.22** Maximum Number of Insulated Conductors in Metric Designator 12 FMC (final-exam-#3-048) | **Unconfirmed for 2023.** Values match N20; SD26-8 only confirms the table still exists under this number. | Header typos: "TF/XHHW/AF/TW" and "FEP/FEPB/PF/PGF". | Changed to "TF/XHHW/TW" and "FEP/FEBP/PF/PGF". Values unchanged. |
| **Table 630.31(A)** Duty Cycle Multiplication Factors for Resistance Welders (final-exam-#3-040) | **Unconfirmed for 2023.** N20: the table is "Table 630.31(A)" and section 630.31(A)(2) refers to it; values 0.45/0.39/0.32/0.27/0.22 match. | The code reference and tip called it "Table 630.31(A)(2)" (2017 name). The formula presented √(duty cycle) as the rule. | Code reference set to section "630.31(A)(2)". The tip and choice note say "Table 630.31(A)". The formula now says to multiply by the table multiplier and notes that the multipliers are √duty cycle, rounded. Headers "Duty cycle · Multiplier". |
| **Table 310.15(B)(1)(1)**, **Table 310.15(C)(1)**, **Table 310.12(A)**, **Table 310.4(1)** | Verified 2023 (secondary): FD26 baseline titles and values (40 °C ×0.87; 4–6 CCC 80%, 7–9 70%). | — | No change. |
| **Table 430.250** (50 hp, 460 V = 65 A), **Table 300.5(A)**, **Table 300.1(C)**, **Chapter 9 Table 8** (#12 1.93/1.98 Ω, #10 1.21/1.24 Ω per 1000 ft), **Table 400.4** | **Unconfirmed for 2023.** Values match N20 or earlier-edition references; no 2023 text was reachable. | — | No change. |
| **626.11(A)** (final-exam-#3-026) | **Unconfirmed for 2023.** N20: 11 kVA per electrified truck parking space. | The citation was "NEC 626.11"; the 11 kVA rule is in (A). | Code reference, table cell, note and formula now cite 626.11(A). |
| **366.23(A)** (final-exam-#3-063, final-exam-#5-039) | **Unconfirmed for 2023.** N20: 1000 A/in² Cu, 700 A/in² Al. | The formula said "Unventilated copper busbar ≈ 1,000 A per square inch". That is not the 366.23(A) wording and it hedged with "≈". | Formula: "366.23(A): bare copper bars may carry no more than 1,000 A per square inch of cross section (aluminum 700 A)". |
| **517.73(A)** (open-book-exam-#7-004) | **Unconfirmed for 2023.** N20 has a biplane 100%-momentary sentence under (A)(2) Feeders; a 2026 public comment (PC 961) rewrites the section without it. | The formula ("biplane uses 100% of momentary") contradicted both the reference text and the tip ("2023 no longer has a biplane rule"); neither claim could be checked against 2023. | The formula now restates the reference text: not less than 50% of the momentary rating or 100% of the long-time rating, whichever is greater. The tip no longer makes the unverified edition claim. The keyed answer "momentary" holds either way. Settled by `CONTENT_AUDIT_2023.md`: 2023 has no biplane sentence; the record now tests 517.73(B) Feeders. |

#### Renumbering between 2017 and 2023 (for readers of older study material)

- Table 310.15(B)(16) became **Table 310.16**, and 310.15(B)(3)(a) became **Table 310.15(C)(1)**.
- The dwelling service table of 310.15(B)(7) became **Table 310.12(A)**.
- Table 220.12 (general lighting) became **Table 220.42(A)**, and Table 220.42 (lighting demand factors) became **Table 220.45**.
- Table 344.30(B)(2) became **Table 344.30(B)**.
- Table 352.30 became **Table 352.30(B)**.
- Table 630.31(A)(2) became **Table 630.31(A)** (renamed in 2020; 2023 unconfirmed).
- Table 220.54's values did not change. The bank's 80/75/70% rows were simply wrong.

#### Brief items not present in the bank

There are no questions on box fill (314.16(B)), conduit-fill calculations, 250.102(C)(1), Article 358 (EMT) tables, or 430.248. Nothing was added, because stems must come from the source PDFs.

### Formulas and worked solutions

`tools/pipeline/check_worked_solutions.py` (new) holds the NEC 2023 table constants and recomputes the keyed answer for 30 records from first principles. It also re-evaluates every arithmetic chain ("a × b = c", percent forms, and unit-bearing chains) found in `formula`, `worked`, `reference_text`, `tip_short`, `info_tip` and `choice_notes`.

- The 30 recomputed records cover lighting loads, dryer and range demand, EGC sizing, ampacity derating, motor FLC, welder duty cycle, busbar capacity, receptacle loads, FMC fill, PVC support, and Chapter 9 resistance.
- 2 records have non-numeric formulas: final-exam-#3-069 and open-book-exam-#7-004.
- Result on the final bank: `recomputed: 30, arithmetic chains evaluated: 24, RESULT: PASS`.

Formula text changed in: final-exam-#3-026, #3-040, #3-063, #5-039, and open-book-exam-#7-004 (all described above). The #3-040 worked solution changed from "√0.15 ≈ 0.39 …" to "Table 630.31(A): 15% → 0.39; 21 × 0.39 = 8.19 A".

### Spoken-text changes (for the voice agent — clips were not regenerated)

| Record | Fields |
|---|---|
| final-exam-#1-040, open-book-exam-#4-015 | `tip_short`, `choice_notes` (A–C), `info_tip` |
| final-exam-#3-040 | `tip_short`, `choice_notes` (B), `formula`, `worked` |
| final-exam-#3-053 | `tip_short`, `choice_notes` (C) |
| open-book-exam-#7-004 | `tip_short`, `formula` |
| final-exam-#3-026, #3-063, #5-039 | `formula` |
| final-exam-#1-021, #1-067, #3-017, #3-052 | `reference_text` |
| final-exam-#1-004, #1-009, #1-010, #3-016, #3-065; open-book-exam-#1-003, #1-021, #7-015, #7-018, #7-024, #10-002 | `info_tip` (Table 220.45 tiers) |

### Verification

- **Candidate build** (Git Bash, written to `WIRE_BANK_OUT`): passed validation with 0 errors and 0 warnings before being copied over `question_bank.json`.
- **Field diff vs the pre-change bank:** only the 26 records and fields listed above changed.
- **Stem / choice / key hash**: SHA-256 over `(id, prompt, answers, correct_index)` for all 279 records.
  - Before: `67fd8475769cde14c4f4a532e67c5c3d10208538b215293f98489411c7f07ecb`
  - After: the same hash, so stems, choices and keys are **unchanged**.
- **Highlight probe** (`TableViewer` matcher):
  - Every changed table highlights exactly the answer cell (220.54 "85%", 250.122 "10", 430.37 "Three*", Note (4) "60%").
  - 310.16, 220.42(A) and 630.31(A) highlight no cell, instead of a wrong one.
- **Fit check** (`.audit_tmp/measure_fit.gd`, now `tools/visual/measure_fit.gd`): 0% of the 279 records need scrolling, before or after answering, on desktop (1280×720) and mobile (540×960).
- `python tools/pipeline/validate_question_bank.py --no-warn`: VALID, 0 errors, 0 warnings.
- `bash tools/verify.sh` (Git Bash): all 5 stages passed.
- **Screenshots** (desktop and mobile, before and after answering) are in `.audit_tmp/tf/shots/`, taken with `.audit_tmp/tf/snap_tables.gd`. They cover #1-040, #1-068, #1-014, #3-052, #1-067, #1-004, #1-021 and #3-040, and confirm that ², ¾ and φ render.
