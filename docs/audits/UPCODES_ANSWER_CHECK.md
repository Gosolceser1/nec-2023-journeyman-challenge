# UpCodes NEC 2023 answer-key and citation check

Date: 2026-09-30. Scope: all 598 records of data/question_bank.json (key `records`). Source: the NFPA 70-2023 text (read through an UpCodes subscription; no code text is stored in this repo); 10 batch reviewers opened the cited 2023 section for every record, the lead re-checked every non-OK finding against the 2023 text. Quotes below are cut to a few words; look up the cited section in the code book for the full text.

## Counts per class

- OK: 538
- Wrong answer key: 0
- Citation moved/wrong in 2023: 0
- Value/wording changed in 2023 (key kept): 8
- Ambiguous: 2
- N/A (state law / non-NEC): 50

Notes on the counts: "Value/wording changed" means the record's stem or quoted provision no longer matches the 2023 text, but the keyed answer is still right. No record has a wrong key under NEC 2023, and no citation moved or was wrong. N/A = 4 Nebraska statute / Title 100 NAC records plus 46 general-knowledge, trade-math, NFPA 70E or figure-only items (math and logic sanity-checked; no errors).

## Confirmed mismatches (NEC 2023 text clearly supports; all fixed via the overlay, key unchanged)

| Id | Old | New | NEC 2023 section (first words) |
|---|---|---|---|
| final-exam-#4-034 | provision: temp rise 40°C or less 125%, all other motors 115% | 140%, 130% | 430.32(C): "Motors with a marked temperature rise ..." |
| final-exam-#4-037 | same provision error | 140%, 130% | 430.32(C) (as above) |
| final-exam-#4-056 | same provision error | 140%, 130% | 430.32(C) (as above) |
| final-exam-#3-028 | stem "provided for public use rated 250v or less" | "rated 150 volts or less to ..." | 422.5(A): "Appliances identified in 422.5(A)(1) through (A)(7) ..." (list adds sump pumps, dishwashers) |
| final-exam-#2-049 | stem "attached to the dwelling unit and ..." | "within 4 in. horizontally of the dwelling unit" | 210.52(E)(3): "Balconies, decks, and porches that are ..." |
| open-book-exam-#10-020 | same as #2-049 | same | 210.52(E)(3) |
| final-exam-#2-021 | stem "Warning signs ... conduit systems" | "Danger signs ... raceway systems" | 305.12 Danger Signs: "Danger signs shall be conspicuously posted ..." |
| final-exam-#4-061 (ambiguous) | stem "5 hp, single-phase, 230 volt, wound rotor" (single-phase row = 300, choice A) | "5 hp, 230 volt, wound rotor" | Table 430.52(C)(1): Single-phase motors 300; Wound-rotor 150 (nontime-delay fuse) |
| open-book-exam-#4-021 (ambiguous) | stem "... are required to have GFCI protection" | "... shall be permitted to be ..." | 210.8(A) Exception No. 1: "Receptacles that are not readily accessible ..." |

Explanation-only errors fixed (key and stem unchanged): final-exam-#1-049 note B (Table 300.5(A): under 2 in. concrete, Column 3 = 12 in., Column 4 = 6 in.); open-book-exam-#12-011 tip (695.7(D): "voltage at the contactor load terminals"); final-exam-#3-065 lookup hint (Table 310.12(A) exists in 2023).

Pre-answer leaks fixed (not NEC mismatches, but they revealed the answer before answering): shared background paragraphs in data/nec/2023/concepts.json (and override copies) no longer state the answer for final-exam-#1-064, #1-065, #2-009, #2-036, #2-047, #3-055, open-book-exam-#3-003, #3-022, #4-007, #4-022, #7-005; gists of open-book-exam-#7-005 (also mislabeled a floodplain term), #9-023 and #4-017 rewritten.

## Left for the user

- final-exam-#3-065 (310.12): 2023 310.12 also permits 208Y/120-volt single-phase dwelling feeders, so key D "Only 240/120V, 3-wire services for a ..." is the best choice but narrower than the rule. PDF choices kept.
- open-book-exam-#7-001 (200.3): stem is the pre-2020 sentence ("shall not be electrically connected ... unless"); 2023 reads "Grounded conductors of premises wiring systems ...". Same rule and key; rewording would make "directly" arguable, so kept.
- open-book-exam-#7-007: cited "708.54 Ex."; in the 2023 text the exception sits after 708.54(C). Citation still points to the right section.
- Mild pre-answer hints the reviewers noted (not answer-revealing on their own): gists of final-exam-#2-061, open-book-exam-#6-002, #7-008, #7-011, #7-012, #10-022; INFO_TIP of final-exam-#1-069. Off-topic or mismatched background/gist text: final-exam-#1-061, #2-037, #2-042, #2-050, open-book-exam-#2-017, #2-022, #3-005, #3-007, #4-008, #4-019, #7-009.
- Stems that omit a 2023 qualifier but still have one right answer: final-exam-#1-011, #1-024 and open-book-exam-#3-015 ("15 or 20 amp"; 2023 is up to 60 A), final-exam-#3-017, #3-034, #3-063, #5-002, #5-005, #5-069 ("in a dwelling"), #5-070 ("RNC" = PVC), open-book-exam-#1-005, #2-007, #2-015, #9-003, #9-006, #10-019, #10-024, #11-011, #12-024, #12-025.
- Printed-book checks still open from earlier audits: 408.5 heading (final-exam-#1-029), 422.5(A) "rated" (final-exam-#3-028; the new stem uses "rated" as ordinary English).

## Tests, commit and CI

- Candidate build + strict validator (--no-warn): VALID, 0 errors, 0 warnings; candidate diff = 15 target records + 112 background-text trims, no correct_index changed.
- hunt_keywords.py --check OK; spellcheck_bank --offline 0 findings; test_bank_loader 3001/0, test_no_leak 235/0, test_layout_tree PASS; test_bundle 598/598 + 378/378 (6 voice folders re-recorded: final-exam-#2-021, #2-049, #3-028, #4-061, open-book-exam-#4-021, #10-020).
- tools/verify.sh via WSL (temp APPDATA): ALL CHECKS PASSED, BUNDLE_AUDIT OK.
- Commit 017d125 pushed to github and origin (WSL).
- GitHub verify run 36793350130: success (https://github.com/Gosolceser1/nec-2023-journeyman-challenge/actions/runs/36793350130).


## Per-question results

Evidence = the 2023 section checked and the first few words of the provision. Status FIXED = changed in this pass via the overlay.

| Id | Citation | Class | Status | Keyed answer | NEC 2023 evidence | Notes |
|---|---|---|---|---|---|---|
| `final-exam-#1-001` | General knowledge | N/A (state law / non-NEC) |  | B) 3/5 | Math: 60/100 = 3/5; key B correct. |  |
| `final-exam-#1-002` | 408.18(C) | OK |  | A) front | 408.18(C): "Each section of equipment that requires ..." |  |
| `final-exam-#1-003` | 210.63(B)(1) | OK |  | D) the same room or area | 210.63(B)(1): "The required receptacle outlet shall be ..." |  |
| `final-exam-#1-004` | Table 220.42(A) | OK |  | D) 6,500 | Table 220.42(A): "Office 14 1.3" VA/ft2; 5,000 x 1.3 = 6,500 VA. |  |
| `final-exam-#1-005` | General knowledge | N/A (state law / non-NEC) |  | A) the light is open (bulb burned out) | Troubleshooting logic: 0 V across closed switch, 120 V across lamp = open lamp; key A consistent. | Figure-dependent; logic checked only. |
| `final-exam-#1-006` | 590.5 | OK |  | C) labeled | 590.5: "Decorative lighting used for holiday lighting ..." |  |
| `final-exam-#1-007` | 408.19 | OK |  | D) listed | 408.19: "An insulated conductor used within a ..." |  |
| `final-exam-#1-008` | 210.52(E)(3) | OK |  | D) 78 inches | 210.52(E)(3): "shall not be located more than ..." |  |
| `final-exam-#1-009` | 310.6(C) | OK |  | C) pink | 310.6(C): ungrounded conductors "shall be finished to be clearly ..." |  |
| `final-exam-#1-010` | 220.14(H) | OK |  | C) 540 | 220.14(H)(1): "each 1.5 m (5 ft) or ..."; 3 x 180 = 540 VA. |  |
| `final-exam-#1-011` | 210.52(A)(2) | OK |  | B) 24 inches | 210.52(A)(2): "Any space 600 mm (2 ft) ..." | Stem omits 'stationary appliances' from the 2023 list; harmless. |
| `final-exam-#1-012` | 210.8(A)(2) | OK |  | B) GFCI | 210.8(A)(2): "Garages and also accessory buildings that ..." (all 125-250 V receptacles). |  |
| `final-exam-#1-013` | General knowledge | N/A (state law / non-NEC) |  | B) II only | Ammeter connects in series with load; key depends on figure. | Figure-dependent; not verifiable from text. |
| `final-exam-#1-014` | Table 310.16 | OK |  | B) 20a | Table 310.16: "12* 20 25 30"; Table 310.15(C)(1): "4-6 80"; 25 x 0.80 = 20 A. |  |
| `final-exam-#1-015` | 225.6(B) | OK |  | B) #12 | 225.6(B): "Overhead conductors for festoon lighting shall ..." |  |
| `final-exam-#1-016` | 590.4(J) | OK |  | C) strain relief devices | 590.4(J) Exception: "arranged with strain relief devices, tension ..." |  |
| `final-exam-#1-017` | 210.18 | OK |  | D) 10, 15, 20, 30, 40 and 50 amperes | 210.18: "The rating for other than individual ..." |  |
| `final-exam-#1-018` | 620.61(B)(1) | OK |  | A) intermittent | 620.61(B)(1): "Duty on elevator and dumbwaiter driving ..." |  |
| `final-exam-#1-019` | General knowledge | N/A (state law / non-NEC) |  | C) Intensity of current | Theory: I = intensity of current; key C correct. |  |
| `final-exam-#1-020` | 250.53(A)(3) | OK |  | D) 72 inches | 250.53(A)(3): "If multiple rod, pipe, or plate ..." |  |
| `final-exam-#1-021` | Table 220.55 | OK |  | C) 8.8 kW | Table 220.55 Col C 1 appliance = 8 kW; Note 1: "increased 5 percent for each additional kilowatt"; 8 x 1.10 = 8.8 kW. |  |
| `final-exam-#1-022` | 210.52(G)(1) | OK |  | C) two | 210.52(G)(1): "at least one receptacle outlet shall ..."; two bays = two. |  |
| `final-exam-#1-023` | 250.122(F)(1)(b) | OK |  | B) run in parallel in each raceway | 250.122(F)(1) Multiple Raceways: "a wire-type equipment grounding conductor, if ..." |  |
| `final-exam-#1-024` | 680.58 | OK |  | A) 20 | 680.58: "All receptacles rated 125 volts through ..." | Stem says '15 or 20 amp, single-phase'; 2023 covers up to 60 A. Key unaffected. |
| `final-exam-#1-025` | 630.12(A) | OK |  | B) 90 amp | 630.12(A): "not more than 200 percent of I1max"; 630.12 permits next higher standard rating; 86 A -> 90 A. |  |
| `final-exam-#1-026` | Table 310.4(1) | OK |  | D) The conductor has a maximum operating temperature of 90°C. | Table 310.4(1): "RHW 75°C" vs "RHW-2 90°C", dry and wet locations. |  |
| `final-exam-#1-027` | Table 310.15(B)(1)(1) | OK |  | B) 34.8 | Table 310.15(B)(1)(1): "41-45 0.71 0.82 0.87 105-113"; #10 90°C = 40 A; 40 x 0.87 = 34.8 A. |  |
| `final-exam-#1-028` | 514.11(A) | OK |  | D) 100 | 514.11(A): "not less than 6 m (20 ..." |  |
| `final-exam-#1-029` | 408.5 | OK |  | B) 3 | 408.5: "including their end fittings, shall not ..." |  |
| `final-exam-#1-030` | 424.20(A)(3) | OK |  | D) be designed so that the circuit cannot be energized automatically after the device has been manually placed in the off position | 424.20(A): "Designed so that the circuit cannot ..." (item 3). |  |
| `final-exam-#1-031` | 210.52(H) | OK |  | C) 10 | 210.52(H): "In dwelling units, hallways of 3.0 ..." |  |
| `final-exam-#1-032` | 240.21(B)(1) | OK |  | D) 400 A | 240.21(B)(1)(4): "ampacity of the tap conductors is ..."; 40 x 10 = 400 A. |  |
| `final-exam-#1-033` | General knowledge | N/A (state law / non-NEC) |  | D) SPDT | Three-way switch = SPDT; key D correct. |  |
| `final-exam-#1-034` | Table 400.4 | OK |  | B) STOOW | Table 400.4: "STOOW ... Damp and wet locations"; Note 9: "Cords with the 'W' suffix are ..." |  |
| `final-exam-#1-035` | 250.52(A)(2) | OK |  | C) 10 | 250.52(A)(2): "in direct contact with the earth ..." |  |
| `final-exam-#1-036` | 310.12(A) | OK |  | A) 83% | 310.12(A): "shall be permitted to have an ..." |  |
| `final-exam-#1-037` | 392.100(F) | OK |  | D) flame-retardant | 392.100(F): "Nonmetallic cable trays shall be made ..." |  |
| `final-exam-#1-038` | 340.10(3) | OK |  | D) for wiring in wet, dry, or corrosive locations | 340.10(3): "For wiring in wet, dry, or corrosive locations." 340.12 excludes service-entrance, commercial garages, physical damage. |  |
| `final-exam-#1-039` | 430.8 | OK |  | D) suitable | 430.8: "A motor controller that includes motor ..." |  |
| `final-exam-#1-040` | Table 220.54 | OK |  | D) 85% | Table 220.54: "5 85" (five dryers = 85%). |  |
| `final-exam-#1-041` | General knowledge | N/A (state law / non-NEC) |  | A) series | Motor control: NC stop button wired in series; key A correct. |  |
| `final-exam-#1-042` | 406.9(B) | OK |  | D) weather resistant | 406.9(B)(1): "All 15- and 20-ampere, 125- and ..." |  |
| `final-exam-#1-043` | 680.43(B)(1)(a) | OK |  | D) 12 | 680.43(B)(1)(a): "Where no GFCI protection is provided ..." |  |
| `final-exam-#1-044` | Article 100 | OK |  | A) ground fault | Art. 100 Ground Fault: "An unintentional, electrically conductive connection between ..." | LOOKUP says 'Start with General knowledge'; should say Article 100 (Ground Fault). |
| `final-exam-#1-045` | 422.16(B)(1)(1) | OK |  | C) 36 inches | 422.16(B)(1): "The length of the cord is ..." |  |
| `final-exam-#1-046` | General knowledge | N/A (state law / non-NEC) |  | C) 2/5 | Math: 40/100 = 2/5; key C correct. |  |
| `final-exam-#1-047` | General knowledge | N/A (state law / non-NEC) |  | A) Diagram A | Symbol identification; key depends on figure. | Figure-dependent; not verifiable from text. |
| `final-exam-#1-048` | 406.12(1) | OK |  | D) listed tamper-resistant | 406.12: "All 15- and 20-ampere, 125- and ...". |  |
| `final-exam-#1-049` | Table 300.5(A) | OK | FIXED (explanation only) | C) 18 inches | Table 300.5(A): "In trench below 50 mm (2 ..." (Col 1 = 18 in.). | FIXED explanation: note B said 12 in. is the 20 A GFCI residential value; Table 300.5(A) under 2 in. concrete: 12 in. is Column 3 (raceways), Column 4 is 6 in. / TIP 'Not B' is wrong: 12 in. is Column 3 (EMT/nonmetallic raceways) under 2 in. concrete; Column 4 (residential 20 A GFCI) is 6 in. The record's own TABLE shows this. |
| `final-exam-#1-050` | 800.44(B) | OK |  | D) 8 feet | 800.44(B): "shall have a vertical clearance of ..." |  |
| `final-exam-#1-051` | 110.26(C)(3) | OK |  | D) 25 | 110.26(C)(3): "personnel door(s) ... less than 7.6 ...". |  |
| `final-exam-#1-052` | 550.32(F) | OK |  | A) 24 inches | 550.32(F): "bottom of the enclosure ... is ..." |  |
| `final-exam-#1-053` | 225.18(5) | OK |  | D) 24 1/2 | 225.18(5): "7.5 m (24 1/2 ft) - ...". |  |
| `final-exam-#1-054` | 400.13 | OK |  | A) Junior hard-service | 400.13: "The repair of hard-service cord and ...". |  |
| `final-exam-#1-055` | 300.4(D) | OK |  | C) 1 1/4 inch | 300.4(D): "not less than 32 mm (1 ...". |  |
| `final-exam-#1-056` | 430.42(C) | OK |  | A) 15 amps | 430.42(C): "the rating of the attachment plug ..." |  |
| `final-exam-#1-057` | 110.26(E)(1) | OK |  | C) Sprinkler protection | 110.26(E)(1)(c): "Sprinkler protection shall be permitted for ..." |  |
| `final-exam-#1-058` | 450.11(A) | OK |  | C) AWG size | 450.11(A) nameplate list: manufacturer, kVA, frequency, voltages, impedance, clearances, insulating liquid, temperature class; no conductor size. |  |
| `final-exam-#1-059` | 210.18 | OK |  | B) maximum permitted rating of the fuse or breaker | 210.18: "shall be rated in accordance with ..." |  |
| `final-exam-#1-060` | 680.11(A) | OK |  | D) 60 inches | 680.11(A): "Underground wiring within 1.5 m (5 ...". |  |
| `final-exam-#1-061` | 503.1 | OK |  | C) Class III | 503.1: "Class III, Division 1 and Division ..." | INFO_TIP background is generic safety text unrelated to hazardous-location classes. |
| `final-exam-#1-062` | General knowledge | N/A (state law / non-NEC) |  | D) 8% | Math check: (125-115)/125 = 8%. | GIST says 'Divide volts lost by source volts' and INFO_TIP states the same formula; method hint only. |
| `final-exam-#1-063` | General knowledge | N/A (state law / non-NEC) |  | C) 14 feet | Math check: 3.5 in x 4 ft/in = 14 ft. |  |
| `final-exam-#1-064` | General knowledge | N/A (state law / non-NEC) | FIXED (explanation only) | C) Upper left-hand corner | Blueprint-reading convention; no NEC provision. | FIXED pre-answer: background said drawings 'start at the upper left' (answer). / INFO_TIP gives away the answer: 'Electrical drawings read like a book: start at the upper left'. |
| `final-exam-#1-065` | General knowledge | N/A (state law / non-NEC) | FIXED (explanation only) | D) 1/240 | Math check: (1/60)/4 = 1/240 s. | FIXED pre-answer: background said '90° takes a quarter of that — 1/240 s' (answer). / INFO_TIP gives away the answer: '60 cycles per second means one full 360° wave takes 1/60 s, so 90...' (continues toward 1/240). |
| `final-exam-#1-066` | 330.30(D)(2) | OK |  | D) 72” | 330.30(D)(2): "Is not more than 1.8 m ..." | Stem says 'from the last point of connection to luminaires'; Code says 'last point of cable support to the point of connection'. Minor wording. |
| `final-exam-#1-067` | Chapter 9, Note 4 | OK |  | B) 60% | Ch. 9 Note (4): nipples not exceeding 600 mm (24 in.) "shall be permitted to be filled ..." |  |
| `final-exam-#1-068` | Table 250.122 | OK |  | C) #10 | Table 250.122 row: "60  10  8" (copper 10 AWG for OCPD not exceeding 60 A). |  |
| `final-exam-#1-069` | 600.9(C) | OK |  | C) kept 2 inches from lampholders | 600.9(C): "spacing between wood or other combustible ..." | INFO_TIP hints: 'wood enclosures are allowed only well clear of hot lampholders'. |
| `final-exam-#1-070` | Table 430.250 | OK |  | C) 65 amps | Table 430.250 row: "50 - 150 143 130 65 52 -" (induction/wound rotor, 460 V = 65 A). |  |
| `final-exam-#2-001` | 525.5(B)(2) | OK |  | B) 600 | 525.5(B)(2): "shall not be located under or ..." |  |
| `final-exam-#2-002` | 300.22(C)(1) | OK |  | A) PVC | 300.22(C)(1): list is MI, MC, AC cable ... or in EMT, FMT, IMC, RMC, FMC; PVC not listed. |  |
| `final-exam-#2-003` | 250.52(A)(5) | OK |  | D) 5/8" | 250.52(A)(5): "Rod-type grounding electrodes of stainless steel ..." |  |
| `final-exam-#2-004` | 555.33(A)(4) | OK |  | D) 30 | 555.33(A)(4): "Shore power for boats shall be ..." |  |
| `final-exam-#2-005` | 250.53(A)(4) | OK |  | A) 2 1/2 feet | 250.53(A)(4): "the electrode shall be permitted to ..." |  |
| `final-exam-#2-006` | Article 100 | OK |  | B) Sign Body | Art. 100 Sign Body: "A portion of a sign that ..." |  |
| `final-exam-#2-007` | 110.12(B) | OK |  | C) corrosive residues | 110.12(B): "foreign materials such as paint, plaster ..." |  |
| `final-exam-#2-008` | 225.37 | OK |  | A) disconnect | 225.37: "a permanent plaque or directory shall ..." |  |
| `final-exam-#2-009` | Article 100 | OK | FIXED (explanation only) | D) Maximum Water Level | Art. 100 Maximum Water Level: "The highest level that water can ..." | FIXED pre-answer: same 'maximum water level' background sentence as #7-005. |
| `final-exam-#2-010` | 210.11(A) | OK |  | A) minimum | 210.11(A): "The minimum number of branch circuits ..." |  |
| `final-exam-#2-011` | General knowledge | N/A (state law / non-NEC) |  | A) infinite | Electrical theory: open circuit reads infinite (OL). |  |
| `final-exam-#2-012` | General knowledge | N/A (state law / non-NEC) |  | D) all of these | Theory: 20:1 = Np:Ns, Es = Ep/20; A, B, C all true. | A and C are essentially the same statement; 'all of these' is the conventional key. |
| `final-exam-#2-013` | General knowledge | N/A (state law / non-NEC) |  | A) equal to | Theory: parallel branch voltage equals source voltage. |  |
| `final-exam-#2-014` | General knowledge | N/A (state law / non-NEC) |  | A) heater output will decrease | Math check: 60 W lamp 240 ohm, 25 W lamp 576 ohm, heater 28.8 ohm; higher total R lowers current, heater output drops. |  |
| `final-exam-#2-015` | General knowledge | N/A (state law / non-NEC) |  | C) more turns than the secondary | Theory: step-down means Np > Ns. |  |
| `final-exam-#2-016` | General knowledge | N/A (state law / non-NEC) |  | C) the voltage across each branch is equal | Theory: parallel branches share voltage; unequal R gives unequal I and P. |  |
| `final-exam-#2-017` | General knowledge | N/A (state law / non-NEC) |  | C) inductive | Theory: ELI, current lags in inductive circuit. |  |
| `final-exam-#2-018` | General knowledge | N/A (state law / non-NEC) |  | C) effective | Theory: effective (RMS) value used for ratings. |  |
| `final-exam-#2-019` | General calculation | N/A (state law / non-NEC) |  | C) 30Ω | Math check: 5 x 3 x 2 = 30 ohms. |  |
| `final-exam-#2-020` | 240.5(B)(4) | OK |  | D) 20 amp circuits - #16 AWG and larger | 240.5(B)(4): field assembled extension cords "permitted to be supplied by a ..." |  |
| `final-exam-#2-021` | 305.12 | Value/wording changed in 2023 (key kept) | FIXED | D) conspicuously | 305.12: "Danger signs shall be conspicuously posted ..." | Stem 'Warning signs ... conduit systems' -> 2023 305.12 'Danger signs ... raceway systems'. Key 'conspicuously' unchanged. |
| `final-exam-#2-022` | 250.62 | OK |  | B) corrosive | 250.62: "The material selected shall be resistant ..." |  |
| `final-exam-#2-023` | Table 110.28 | OK |  | A) Type 4X | Table 110.28 outdoor: "Corrosive agents - - - X ..." (3X, 3RX, 3SX, 4X, 6P); Types 12/13 indoor only. | TABLE field omits 3RX/3SX columns; harmless. |
| `final-exam-#2-024` | Table 314.16(B)(1) | OK |  | C) 314.16(B)(1) | 314.16(B)(1): "The conductor fill shall be calculated ..." Table: Volume Allowance Required per Conductor. |  |
| `final-exam-#2-025` | 225.19(A) | OK |  | B) open | 225.19(A): "Overhead spans of open conductors and ..." |  |
| `final-exam-#2-026` | 250.12 | OK |  | D) designed | 250.12: "or shall be connected by means ..." |  |
| `final-exam-#2-027` | Chapter 9, Table 5 | OK |  | D) Table 5, Chapter 9 | Chapter 9: "Table 5 Dimensions of Insulated Conductors ..."; Table 2 is "Radius of Conduit and Tubing Bends". |  |
| `final-exam-#2-028` | Table 220.56 | OK |  | B) 220.56 | Table 220.56: "Demand Factors for Kitchen Equipment - ..." |  |
| `final-exam-#2-029` | Chapter 9, Table 1 | OK |  | C) Table 1, Chapter 9 | Ch. 9 Table 1 "Percent of Cross Section of Conduit ...": 1 = 53, 2 = 31, Over 2 = 40. |  |
| `final-exam-#2-030` | 600.4(C) | OK |  | A) 1/4" | 600.4(C): "The markings shall be permanently installed ..." |  |
| `final-exam-#2-031` | General knowledge | N/A (state law / non-NEC) |  | C) Induction | Theory: mutual/electromagnetic induction. |  |
| `final-exam-#2-032` | General knowledge | N/A (state law / non-NEC) |  | B) electrons passing a point per second | Theory: ampere = coulomb (electrons) per second past a point. |  |
| `final-exam-#2-033` | General knowledge | N/A (state law / non-NEC) |  | A) a loose connection | Theory: loose connection adds contact resistance. |  |
| `final-exam-#2-034` | General knowledge | N/A (state law / non-NEC) |  | A) one-half cycle | Theory: alternation = one-half cycle. |  |
| `final-exam-#2-035` | General knowledge | N/A (state law / non-NEC) |  | C) current | Theory: ammeter shunt measures current. |  |
| `final-exam-#2-036` | General knowledge | N/A (state law / non-NEC) | FIXED (explanation only) | C) one-half the resistance of one conductor | Theory: two equal R in parallel = R/2. | FIXED pre-answer: background said two equal parallel resistors 'give half of one' (answer). / INFO_TIP gives away the answer: 'Two equal resistors in parallel give half of one'. |
| `final-exam-#2-037` | Table 430.52(C)(1) | OK |  | B) 430.52(C)(1) | Table 430.52(C)(1): "Maximum Rating or Setting of Motor ..." | INFO_TIP background is about GFCIs, unrelated to motor protection. |
| `final-exam-#2-038` | 210.18 | OK |  | C) setting | 210.18: "rated in accordance with the maximum ..." |  |
| `final-exam-#2-039` | Table 210.21(B)(2) | OK |  | A) 210.21(B)(2) | Table 210.21(B)(2): "Maximum Cord-and-Plug-Connected Load to Receptacle" 15/12, 20/16, 30/24. |  |
| `final-exam-#2-040` | Table 235.360(A) | OK |  | C) 235.360(A) | 235.360(A): "Table 235.360(A) Clearances over Roadways, Walkways ..." |  |
| `final-exam-#2-041` | Article 100 | OK |  | B) a lampholder | Art. 100 Luminaire: "...connect it to the power supply ..." |  |
| `final-exam-#2-042` | 344.10(A)(1) | OK |  | D) Red brass | 344.10(A)(1): "Galvanized steel, stainless steel, and red ..." | LOOKUP clue 'pool / spa' and pool INFO_TIP background are unrelated to RMC. |
| `final-exam-#2-043` | 300.5(F) | OK |  | D) corrosion | 300.5(F): "...prevent adequate compaction of fill or ..." |  |
| `final-exam-#2-044` | 314.23(E) | OK |  | B) threaded into hubs identified for the purpose | 314.23(E): "It shall have threaded entries or ..." |  |
| `final-exam-#2-045` | 310.3(B)(3) | OK |  | A) 10 | 310.3(B)(3): "the copper shall form a minimum ..." |  |
| `final-exam-#2-046` | 110.26(A)(1) Condition 2 | OK |  | C) grounded | Table 110.26(A)(1) Condition 2: "Concrete, brick, or tile walls shall ..." |  |
| `final-exam-#2-047` | 406.3(E) | OK | FIXED (explanation only) | D) an orange triangle located on the face of the receptacle | 406.3(E): "shall be identified by an orange ..." | FIXED pre-answer: background said isolated-ground receptacles are spotted 'by the orange triangle' (answer). / INFO_TIP gives away the answer: 'You can spot one by the ora[nge triangle]'. |
| `final-exam-#2-048` | 517.18(B)(1) | OK |  | D) 4 duplex or 8 single | 517.18(B)(1): "Each patient bed location shall be ..." |  |
| `final-exam-#2-049` | 210.52(E)(3) | Value/wording changed in 2023 (key kept) | FIXED | B) 6'6" | 210.52(E)(3): "The receptacle outlet shall not be ..." | Stem used the 2020 210.52(E)(3) trigger 'attached ... accessible from inside'; 2023: 'within 102 mm (4 in.) horizontally of the dwelling unit'. Key 6'6" unchanged. |
| `final-exam-#2-050` | 305.4 | OK |  | C) nonshielded | 305.4: "Conductors having nonshielded insulation and operating ..." | INFO_TIP background is about box fill, unrelated. |
| `final-exam-#2-051` | General knowledge | N/A (state law / non-NEC) |  | A) impedance | General AC theory: impedance is total opposition in ohms. Key A correct. |  |
| `final-exam-#2-052` | General knowledge | N/A (state law / non-NEC) |  | C) 1/4 as much | P = E^2/R; (120/240)^2 = 1/4. Key C correct. |  |
| `final-exam-#2-053` | General knowledge | N/A (state law / non-NEC) |  | A) 1/2 cycle | General knowledge; 1/2 cycle is the conventional answer for high fault current on a low-impedance EGC path. | GIST ('open almost instantly') leans toward the answer; minor. |
| `final-exam-#2-054` | General knowledge | N/A (state law / non-NEC) |  | A) 90 | 360/4 = 90 degrees. Key A correct. |  |
| `final-exam-#2-055` | General knowledge | N/A (state law / non-NEC) |  | C) Insulation of the conductor | Resistance depends on material, length, area, temperature; not insulation. Key C correct. |  |
| `final-exam-#2-056` | General knowledge | N/A (state law / non-NEC) |  | A) inductive reactance exceeds the capacitive reactance | ELI: XL > XC makes circuit inductive, voltage leads. Key A correct. |  |
| `final-exam-#2-057` | General calculation | N/A (state law / non-NEC) |  | B) .6875 | 11/16 = 0.6875. Key B correct. |  |
| `final-exam-#2-058` | 352.10 | OK |  | B) cold | 352.10 Informational Note: "Extreme cold may cause some nonmetallic ..." |  |
| `final-exam-#2-059` | 250.194(A) | OK |  | D) 16 | 250.194(A): "If metal fences are located within ..." |  |
| `final-exam-#2-060` | 334.10 | OK |  | D) all of these | 334.10 item 2: "Multi-family dwellings and their detached garages ..." |  |
| `final-exam-#2-061` | 422.13 | OK |  | D) continuous load | 422.13: water heaters 120 gal or less "shall have an ampere rating of ..." | 422.13 does not itself say 'continuous load'; the analogy is fine. GIST ('same extra margin as other long-running loads') largely gives away 'continuous'. |
| `final-exam-#2-062` | 408.6 | OK |  | D) all of these | 408.6: "Switchboards, switchgear, and panelboards... the available ..." |  |
| `final-exam-#2-063` | 230.85(B) | OK |  | D) integral to | 230.85(B)(2): "A meter disconnect integral to the ..." |  |
| `final-exam-#2-064` | 430.102(B) | OK |  | C) lockable | 430.102(B) Exception: not required "if the motor controller disconnecting means ..." |  |
| `final-exam-#2-065` | 314.16(B)(4) | OK |  | B) two | 314.16(B)(4): "a double volume allowance... for each ..." | TIP could note the 2023 addition: devices wider than a 2 in. box get double allowance per gang; not relevant to a standard 3-way switch. |
| `final-exam-#2-066` | 110.9 | OK |  | B) interrupting | 110.9: "shall have an interrupting rating at ..." |  |
| `final-exam-#2-067` | 225.26 | OK |  | C) overhead conductor spans | 225.26: "Vegetation such as trees shall not ..." 410.36(G) permits luminaires on trees. |  |
| `final-exam-#2-068` | 410.10(C) | OK |  | D) exhaust vapors | 410.10(C)(2): "constructed so that all exhaust vapors ..." |  |
| `final-exam-#2-069` | 344.14 | OK |  | A) severe corrosive influences | 344.14(3): "Steel (galvanized, painted, powder or PVC ..." |  |
| `final-exam-#2-070` | 360.20(B) | OK |  | B) 3/4" | 360.20(B): "The maximum size of FMT shall ..." |  |
| `final-exam-#3-001` | 406.6(D) | OK |  | D) Class 2 | 406.6(D): "A flush device cover plate that ..." |  |
| `final-exam-#3-002` | 551.72(B) | OK |  | C) I and II only | 551.72(B): "permitted to include two ungrounded conductors ..." |  |
| `final-exam-#3-003` | 425.22(D) | OK |  | D) Branch circuit | 425.22(D): "The conductors supplying the supplementary overcurrent ..." |  |
| `final-exam-#3-004` | 392.10(E) | OK |  | D) 5000 | 392.10(E): "airfield lighting cable used in series ..." |  |
| `final-exam-#3-005` | 424.101(A) | OK |  | B) 42.4 | 424.101(A): "rated output not exceeding 25 amperes ..." |  |
| `final-exam-#3-006` | 210.8(C) | OK |  | D) 120 | 210.8(C): "GFCI protection shall be provided for ..." |  |
| `final-exam-#3-007` | 680.35(D) | OK |  | A) 6 feet | 680.35(D): "located within 1.83 m (6 ft) ..." |  |
| `final-exam-#3-008` | 500.5(D)(2) | OK |  | B) Class III, Division 2 | 500.5(D)(2)(b): "ignitible fibers/flyings are stored or handled ..." |  |
| `final-exam-#3-009` | 430.101 | OK |  | A) motor and controller | 430.101: "disconnecting means capable of disconnecting motors ..." |  |
| `final-exam-#3-010` | Article 100 | OK |  | C) only to Article 393 | Article 100 Busbar: "...low-voltage luminaire assemblies, and similar electrical ..." |  |
| `final-exam-#3-011` | NFPA 70E | N/A (state law / non-NEC) |  | B) people | NFPA 70E / general safety; 'people' is the conventional answer. |  |
| `final-exam-#3-012` | General knowledge | N/A (state law / non-NEC) |  | A) Underwriters Laboratories | General knowledge; UL is the testing lab that maintains listing records. |  |
| `final-exam-#3-013` | 358.30(A) | OK |  | B) 5' | 358.30(A) Exception No. 1: "permitted to be increased to a ..." |  |
| `final-exam-#3-014` | Table 210.21(B)(2) | OK |  | A) 12 amps | Table 210.21(B)(2): circuit "15 or 20", receptacle "15", maximum load "12" amperes. |  |
| `final-exam-#3-015` | 240.33 | OK |  | B) vertical | 240.33: "Enclosures for overcurrent devices shall be ..." | Distractor D 'upright' is a near-synonym of vertical; consider replacing it to avoid argument. |
| `final-exam-#3-016` | 310.14(A)(3) | OK |  | C) harmonic | 310.14(A)(3) Informational Note No. 1: "Heat generated internally in the conductor ..." | Stem is a sentence fragment; source is an informational note (item 2), not a requirement. |
| `final-exam-#3-017` | Table 250.122 | OK |  | D) all of these | Table 250.122 copper: 15 A -> 14, 20 A -> 12, 60 A -> 10 AWG (so 30 A -> 10 AWG). | Wording 'must be the same size' is loose: Table 250.122 sizes the EGC by OCPD rating; it only coincides with typical 14/12/10 circuit conductors. Consider 'are typically the same size as' or 'Table 250.122 gives the same size as'. |
| `final-exam-#3-018` | 440.64 | OK |  | C) 10 feet | 440.64: cord "shall not exceed 3.0 m (10 ..." |  |
| `final-exam-#3-019` | 430.102(B)(1) | OK |  | A) disconnecting means | 430.102(B)(1): "A disconnecting means for the motor ..." |  |
| `final-exam-#3-020` | 810.13 | OK |  | C) 24" | 810.13: "less than 250 volts between conductors ..." |  |
| `final-exam-#3-021` | NFPA 70E | N/A (state law / non-NEC) |  | D) All of these | NFPA 70E concept; hazard type, manner and degree of exposure. Key D reasonable. |  |
| `final-exam-#3-022` | General knowledge | N/A (state law / non-NEC) |  | B) double triangle and rated-for-volts handle | ASTM F1505 / IEC 60900 insulated tools carry double-triangle symbol and voltage rating. Key B reasonable. |  |
| `final-exam-#3-023` | 522.21(B) | OK |  | C) 26 | 522.21(B): "Conductors in a non-jacketed multiconductor cable ..." |  |
| `final-exam-#3-024` | 225.39(B) | OK |  | D) 30 | 225.39(B): "not more than two 2-wire branch ..." |  |
| `final-exam-#3-025` | 240.10 | OK |  | C) may be used to protect internal circuits of equipment | 240.10: supplementary protection used "for internal circuits and components of equipment"; not a substitute; "not be required to be readily accessible." |  |
| `final-exam-#3-026` | 626.11(A) | OK |  | A) 11 kVA | 626.11(A): "calculated on the basis of not ..." |  |
| `final-exam-#3-027` | 250.66(B) | OK |  | D) #4 | 250.66(B): concrete-encased electrode GEC "shall not be required to be ..." |  |
| `final-exam-#3-028` | 422.5(A) | Value/wording changed in 2023 (key kept) | FIXED | D) all of these | 422.5(A): appliances in (A)(1)-(A)(7) "150 volts or less to ground ..."; list includes vending, tire inflation, drinking water coolers, sump pumps, dishwashers. | Stem 'provided for public use rated 250v or less' -> 2023 422.5(A) 'rated 150 volts or less to ground and 60 amperes or less' (list also has sump pumps, dishwashers). Key D unchanged; tip and gist reworded. |
| `final-exam-#3-029` | Article 100 | OK |  | C) selective coordination | Article 100 Coordination, Selective: "Localization of an overcurrent condition to ..." |  |
| `final-exam-#3-030` | 430.9(C) | OK |  | B) 7 | 430.9(C): "14 AWG or smaller copper conductors ..." |  |
| `final-exam-#3-031` | 800.44 | OK |  | D) any of the above | 800.44(A)(1) below power if practicable; (A)(2) "shall not be attached to a cross-arm"; (B) "vertical clearance of not less than ..." above roofs. | 800.44(A) items apply where sharing poles or run parallel in-span; 'any of the above' is acceptable (reads more naturally as 'all of the above'). |
| `final-exam-#3-032` | Article 100 | OK |  | A) 4 | Article 100 Nursing Home: "used on a 24-hour basis for ..." | Stem says 'area'/'inpatients'; 2023 wording is 'building or portion of a building'/'persons'. Minor. |
| `final-exam-#3-033` | General calculation | N/A (state law / non-NEC) |  | A) 0.10 A | I = P/E = 2/20 = 0.10 A. Key A correct. |  |
| `final-exam-#3-034` | 314.24(B)(5) | OK |  | B) 15/16" | 314.24(B)(5): 14 AWG or smaller "shall have a depth that is ..." | Stem omits the '14 AWG and smaller' condition (12/10 AWG needs 1 3/16 in.); 15/16 in. is still the smallest permitted depth, so key holds. |
| `final-exam-#3-035` | 210.50(C) | OK |  | C) 6' | 210.50(C): "shall be installed within 1.8 m ..." |  |
| `final-exam-#3-036` | 240.5(B)(1) | OK |  | D) applied within the listing requirements | 240.5(B)(1): "considered to be protected when applied ..." |  |
| `final-exam-#3-037` | 354.28 | OK |  | B) termination | 354.28: "For termination, the conduit shall be ..." |  |
| `final-exam-#3-038` | 430.52(B) | OK |  | A) starting | 430.52(B): "shall be capable of carrying the ..." |  |
| `final-exam-#3-039` | 422.12 | OK |  | B) individual | 422.12: "Central heating equipment other than fixed ..." |  |
| `final-exam-#3-040` | 630.31(A)(2) | OK |  | B) 8.19 amps | Table 630.31(A): duty cycle 15% multiplier 0.39; 21 x 0.39 = 8.19 A. |  |
| `final-exam-#3-041` | NFPA 70E | N/A (state law / non-NEC) |  | D) Both (b) and (c) | NFPA 70E lockout/tagout; not an NEC provision. Key (b and c) is sensible. |  |
| `final-exam-#3-042` | 422.33 | OK |  | C) an accessible | 422.33(A): "an accessible separable connector or an ..." |  |
| `final-exam-#3-043` | NFPA 70E | N/A (state law / non-NEC) |  | B) by observing signs and signals indicating its presence | General safety / NFPA 70E concept; no NEC provision. |  |
| `final-exam-#3-044` | 647.4(D) | OK |  | A) 1.5% | 647.4(D): "The voltage drop on any branch ..." |  |
| `final-exam-#3-045` | General knowledge | N/A (state law / non-NEC) |  | C) frequency | General electrical theory (frequency = cycles per second). Key correct. |  |
| `final-exam-#3-046` | 408.7 | OK |  | D) Identified closures | 408.7: "Unused openings for circuit breakers and ..." |  |
| `final-exam-#3-047` | 230.54(B) | OK |  | B) gooseneck | 230.54(B) Exception: "Type SE cable shall be permitted ..." |  |
| `final-exam-#3-048` | Table 348.22 | OK |  | D) #10 | Table 348.22 (trade size 3/8 FMC): TFN/THHN/THWN row "10  1  1" is the largest size listed. |  |
| `final-exam-#3-049` | 210.63 | OK |  | C) 25' | 210.63: receptacle outlet "shall be installed at an accessible ..." |  |
| `final-exam-#3-050` | 250.68(B) | OK |  | D) sufficient length | 250.68(B): "Bonding jumpers shall be of sufficient ..." |  |
| `final-exam-#3-051` | 550.32(F) | OK |  | C) 24" | 550.32(F): bottom of enclosure "not less than 600 mm (2 ..." |  |
| `final-exam-#3-052` | Table 430.37 | OK |  | C) 3 | Table 430.37: "3-phase ac Any 3-phase 3, one ..." |  |
| `final-exam-#3-053` | 344.30(B)(2) | OK |  | C) 12 feet | Table 344.30(B): "27  1  3.7  12" (threaded couplings, straight runs per 344.30(B)(2)). |  |
| `final-exam-#3-054` | 348.28 | OK |  | C) thread into the convolutions | 348.28: trimmed "except where fittings that thread into ..." |  |
| `final-exam-#3-055` | General knowledge | N/A (state law / non-NEC) | FIXED (explanation only) | B) 1,000 ohms | Ohm's-law math: 2,000 / 2 = 1,000 ohms. Key correct. | FIXED pre-answer: background said 'two 2,000-ohm resistors = 1,000 ohms' (this exact question). / INFO_TIP(pre-answer) background paragraph states "two 2,000-ohm resistors = 1,000 ohms", which gives away the answer to this exact question. |
| `final-exam-#3-056` | 225.39(A) | OK |  | A) 15 amps | 225.39(A): "the branch circuit disconnecting means shall ..." |  |
| `final-exam-#3-057` | 310.15(F) | OK |  | D) considered to be a noncurrent-carrying conductor and is not counted | 310.15(F): "A grounding or bonding conductor shall ..." |  |
| `final-exam-#3-058` | Article 100 | OK |  | A) 100 | Article 100: "Fibers/Flyings, Ignitible. ... Fibers/flyings where any ..." |  |
| `final-exam-#3-059` | 680.22(A)(2) | OK |  | B) 6 feet | 680.22(A)(2): circulation/sanitation receptacles "shall be located at least 1.83 ..." |  |
| `final-exam-#3-060` | 480.10(A) | OK |  | A) explosive | 480.10(A): ventilation of gases "to prevent the accumulation of an explosive mixture" |  |
| `final-exam-#3-061` | 430.12(A) | OK |  | A) metal | 430.12(A): "the housings shall be of metal ..." |  |
| `final-exam-#3-062` | General knowledge | N/A (state law / non-NEC) |  | D) PWR | Drawing abbreviation (PWR); general knowledge, no NEC provision. |  |
| `final-exam-#3-063` | 366.23(A) | OK |  | D) 1500 | 366.23(A): bare copper bars "shall not exceed 1.55 amperes/mm2 (1000 amperes/in.2)"; 1.5 x 1000 = 1500 A. | Stem says "unventilated enclosure"; 366.23(A) actually applies to bare copper bars in sheet metal auxiliary gutters. Consider rewording the stem to match. |
| `final-exam-#3-064` | 210.8(A) | OK |  | D) all of these | 210.8(A) list includes "Garages...", "Bathtubs or shower stalls - where ...", "Laundry areas". |  |
| `final-exam-#3-065` | 310.12(A) | Value/wording changed in 2023 (key kept) | PARTLY | D) Only 240/120V, 3-wire services for a single dwelling unit | 310.12: dwelling service/feeder conductors "supplied by a single-phase, 120/240-volt system ..." | Lookup hint said 2023 deleted Table 310.12; 2023 has Table 310.12(A) (hint fixed). Left for user: 2023 310.12 also covers 208Y/120 V dwelling feeders, so key D's 'Only 240/120V, 3-wire services' is the best choice but no longer the whole rule (PDF choices kept). |
| `final-exam-#3-066` | 250.50 | OK |  | D) existing buildings | 250.50 Exception: "Concrete-encased electrodes of existing buildings or ..." |  |
| `final-exam-#3-067` | 440.55(B) | OK |  | A) 15 amps | 440.55(B): "shall not exceed 20 amperes at ..." |  |
| `final-exam-#3-068` | 620.51(A) | OK |  | A) only in the open position | 620.51(A): fused motor circuit switch or circuit breaker "that is lockable only in the ..." |  |
| `final-exam-#3-069` | 430.62(A) | OK |  | B) not greater than the largest rating or setting of the | 430.62(A): protective device "not greater than the largest rating ..." plus other FLCs. |  |
| `final-exam-#3-070` | General knowledge | N/A (state law / non-NEC) |  | B) Triangle | Schematic symbol convention (delta = triangle); general knowledge. |  |
| `final-exam-#4-001` | 220.56 | OK |  | A) largest two kitchen equipment loads | 220.56: "in no case shall the feeder ..." |  |
| `final-exam-#4-002` | 460.8(A) | OK |  | D) 135% | 460.8(A): "shall not be less than 135 ..." |  |
| `final-exam-#4-003` | 356.22 | OK |  | C) Table 1 | 356.22: "shall not exceed that permitted by ..." |  |
| `final-exam-#4-004` | 220.14(I) | OK |  | D) four | 220.14(I): "multiple receptacle comprised of four or ..." |  |
| `final-exam-#4-005` | Table 314.16(A) | OK |  | A) 10 | Table 314.16(A): "75 × 50 × 50 (3 ..." |  |
| `final-exam-#4-006` | Table 9, Chapter 9 | OK |  | D) 0.11 | Table 9, 4/0 per-1000-ft row: Effective Z at 0.85 PF, aluminum, steel conduit = 0.11 (Al AC resistance in steel = 0.10). |  |
| `final-exam-#4-007` | Article 100 | OK |  | C) nominal | Article 100: "Voltage, Nominal. ... for the purpose ..." |  |
| `final-exam-#4-008` | 440.62(A) | OK |  | D) 40 amps | 440.62(A)(2): "Its rating is not more than ..." |  |
| `final-exam-#4-009` | Table 392.60(B) | OK |  | C) 200 | Table 392.60(B) steel: "200 ... 0.70"; "400 ... 1.00". 0.79 in2 meets 200 A row only. |  |
| `final-exam-#4-010` | 210.52(D) | OK |  | A) 1 | 210.52(D): "At least one receptacle outlet shall ..." |  |
| `final-exam-#4-011` | Table 314.16(A) | OK |  | B) 3" x 2" x 2 1/4" | Table 314.16(A): 3 × 2 × 2 device = 10.0 in3; 3 × 2 × 21/4 device = 10.5 in3. |  |
| `final-exam-#4-012` | 220.14(G) | OK |  | D) 200 | 220.14(G): "At 200 volt-amperes per linear 300 ..." |  |
| `final-exam-#4-013` | 605.9(C) | OK |  | B) 13 | 605.9(C): "shall not contain more than 13 ..." |  |
| `final-exam-#4-014` | 430.53(A) | OK |  | B) 20 | 430.53(A): "on a nominal 120-volt branch circuit ..." |  |
| `final-exam-#4-015` | 210.52(E)(1) | OK |  | D) one and two family dwellings | 210.52(E)(1): one-family and each grade-level two-family unit, receptacle "shall be installed at the front ..." |  |
| `final-exam-#4-016` | 210.52(B)(2) | OK |  | B) Electric clock in a dining room | 210.52(B)(2) Exception No. 1: "A receptacle installed solely for the ..." |  |
| `final-exam-#4-017` | 240.4(B) | OK |  | B) 800 | 240.4(B)(3): "The next higher standard rating selected ..." |  |
| `final-exam-#4-018` | 522.28 | OK |  | D) 30 volts | 522.28: "limited to 30 volts maximum for ..." |  |
| `final-exam-#4-019` | 220.53 | OK |  | C) I and II only | 220.53: 75 percent for four or more fastened-in-place appliances; "shall not apply to ... Clothes dryers" |  |
| `final-exam-#4-020` | 310.14(A)(2) | OK |  | A) lowest | 310.14(A)(2): "Where more than one ampacity applies ..." |  |
| `final-exam-#4-021` | Table 314.16(B)(1) | OK |  | D) 2 1/8" | Table 314.16(B)(1): 14 = 2.00, 12 = 2.25; 19.25 in3 > 15.5, so 4 × 21/8 octagonal (21.5 in3). |  |
| `final-exam-#4-022` | Table 4, Chapter 9 | OK |  | B) The conductors' area is less than the allowable area of tubing fill. | Table 4, EMT trade size 1: over 2 wires 40% = 0.346 in2; 0.30 < 0.346. | Choice D mentions THW conductors, which the stem never names; harmless distractor. |
| `final-exam-#4-023` | Table 220.55 | OK |  | A) 11.52 | Table 220.55: "8  53  36  23"; Column B 36% x 32 kW = 11.52 kW < Column C 23 kW. |  |
| `final-exam-#4-024` | Table 310.15(C)(1) | OK |  | D) 16 | Table 310.16: "14*  15  20  25"; Table 310.15(C)(1): "4—6  80"; 20 x 0.80 = 16 A. |  |
| `final-exam-#4-025` | Table 220.55 | OK |  | A) 11 | Table 220.55 Column C: "2  75  65  11"; 12 kW range does not exceed 12 kW, so no Note 1 increase. |  |
| `final-exam-#4-026` | Table 430.248 | OK |  | B) 17.25 amps | Table 430.248: "3/4  13.8" at 115 V; 430.22: "not less than 125 percent"; 13.8 x 1.25 = 17.25 A. |  |
| `final-exam-#4-027` | 220.5(C) | OK |  | A) 6000 | 220.41: "not less than 33 volt-amperes/m2 (3 volt-amperes/ft2)"; 2000 x 3 = 6000 VA. |  |
| `final-exam-#4-028` | 220.52 | OK |  | C) 4,500 | 220.52(A)/(B): 1500 VA per 2-wire small-appliance circuit and "not less than 1500 volt-amperes" per laundry circuit; 3 x 1500 = 4500. |  |
| `final-exam-#4-029` | Table 250.66 | OK |  | B) #4 | Table 250.66: "2/0 or 3/0  4/0 or 250  4  2" (copper 2/0 -> 4 AWG copper GEC). |  |
| `final-exam-#4-030` | 430.24 | OK |  | C) 22.5 | Table 430.248: "11/2  20  11.5  11.0  10"; 430.24: 125% of highest + others; 12.5 + 10 = 22.5 A. |  |
| `final-exam-#4-031` | Table 310.15(B)(1)(1) | OK |  | C) 21.6 amps | Table 310.16: "12* 20 25 30"; Table 310.15(B)(1)(1): "21—25 1.08 1.05 1.04 69—77" -> 20 x 1.08 = 21.6 |  |
| `final-exam-#4-032` | Table 430.52(C)(1) | OK |  | C) 60 amps | Table 430.248: "3 34 19.6 18.7 17"; Table 430.52(C)(1): "Single-phase motors 300 175 800 250" -> 34 x 1.75 = 59.5 -> 60 |  |
| `final-exam-#4-033` | Table 310.15(C)(1) | OK |  | D) 16 | Table 310.16: "14* 15 20 25" (THW 75C = 20); Table 310.15(C)(1): "4—6 80" -> 16 |  |
| `final-exam-#4-034` | 430.32(C) | Value/wording changed in 2023 (key kept) | FIXED | C) 22.1 | 430.32(C): "All other motors 130%"; Table 430.248: "3 34 19.6 18.7 17" -> 17 x 1.30 = 22.1 | Quoted 430.32(C) list showed 125% / 115% (the 430.32(A)(1) values); 2023 430.32(C): temperature rise 40°C or less 140%, all other motors 130%. Key 22.1 A (130% x 17 A) unchanged. |
| `final-exam-#4-035` | Table 310.15(B)(1)(1) | OK |  | B) 0.82 | Table 310.15(B)(1)(1): "36—40 0.82 0.88 0.91 96—104" (60C column = 0.82) |  |
| `final-exam-#4-036` | Table 220.55 | OK |  | A) 6 | Table 220.55 Note 4: "The branch-circuit load for one wall-mounted ..." |  |
| `final-exam-#4-037` | 430.32(C) | Value/wording changed in 2023 (key kept) | FIXED | D) 33.6 | 430.32(C): "Motors with marked service factor 1.15 ..." -> 24 x 1.40 = 33.6 | Same 430.32(C) provision error (125% / 115% -> 140% / 130%). Key 33.6 A (140% x 24 A) unchanged. |
| `final-exam-#4-038` | 314.16(B) | OK |  | D) 18 cu.in. | 314.16(B)(4): "a double volume allowance ... for ..."; Table 314.16(B)(1): "12 36.9 2.25" -> 8 x 2.25 = 18 |  |
| `final-exam-#4-039` | Table 430.250 | OK |  | C) 35 | Table 430.250: "10 - 32.2 30.8 28 14 11" (230 V = 28 A); 430.22: "not less than 125 percent of ..." -> 35 |  |
| `final-exam-#4-040` | Table 310.15(C)(1) | OK |  | A) 21 | Table 310.16: "12* 20 25 30" (THHN 90C = 30); Table 310.15(C)(1): "7—9 70" -> 21 |  |
| `final-exam-#4-041` | Table 310.16 | OK |  | B) 25 | Table 310.16: "12* 20 25 30" (THW 75C = 25); Table 310.15(B)(1)(1): "26—30 1.00 1.00 1.00" |  |
| `final-exam-#4-042` | 220.53 | OK |  | C) 33.75 kW | 220.53: "demand factor of 75 percent to ..." (water heaters not excluded) -> 33.75 kW |  |
| `final-exam-#4-043` | 240.4(D) | OK |  | A) 30 | 240.4(D): "shall not exceed that required by ..."; (8) 10 AWG Copper: 30 amperes |  |
| `final-exam-#4-044` | 220.82(C) | OK |  | B) full load | 220.82(C): "100 percent of the nameplate rating(s) ..." |  |
| `final-exam-#4-045` | Table 220.55 | OK |  | B) 7.15 | Table 220.55: "3 70 55 14"; Note 3 permits nameplate sum x Column B factor -> 13 x 0.55 = 7.15 |  |
| `final-exam-#4-046` | Table 220.54 | OK |  | D) 15.75 kW | 220.54: "5000 watts (volt-amperes) or the nameplate ..."; Table 220.54 "6 75"; 220.61(B): "additional demand factor of 70 percent" -> 15.75 |  |
| `final-exam-#4-047` | 220.41 | OK |  | D) 5 | 220.41: "minimum unit load shall be not ..." -> 7500 VA / 1800 = 4.17 -> 5 |  |
| `final-exam-#4-048` | 220.41 | OK |  | D) none of these | 220.41 unit load includes: "All general-use receptacle outlets of 20-ampere ..."; 220.14(I): "Except as covered in 220.41 ... 180 volt-amperes" |  |
| `final-exam-#4-049` | Table 220.55 | OK |  | B) 16.8 | Table 220.55: "15 40 32 30"; Column B (3-1/2 through 8-3/4 kW) 32% -> 52.5 x 0.32 = 16.8 (< Column C 30) |  |
| `final-exam-#4-050` | Table 5, Chapter 9 | OK |  | A) 0.0209 | Chapter 9 Table 5: "RHH*, RHW*, RHW-2* 14 13.48 0.0209 4.140 0.163" |  |
| `final-exam-#4-051` | Table 220.55 | OK |  | C) 6.4 | Table 220.55 Note 4: "Calculating the branch-circuit load for one ..."; Column B "1 80" -> 6.4 |  |
| `final-exam-#4-052` | 220.5(C) | OK |  | D) 5400va | 220.5(C): "The floor area for each floor ..."; 220.41 3 VA/ft2 -> 1800 x 3 = 5400 |  |
| `final-exam-#4-053` | Table 430.52(C)(1) | OK |  | A) 20 amp | Table 430.248: "2 24 13.8 13.2 12"; 175% -> 23.1 (25 max); 430.52(C)(1)(b) dual-element "in no case exceed 225 percent" = 29.7, so 30+ excluded |  |
| `final-exam-#4-054` | 314.16(B)(5) | OK |  | B) 6.75 | 314.16(B)(5): "Where up to four equipment grounding ..."; 12 AWG 2.25 -> 3 x 2.25 = 6.75 |  |
| `final-exam-#4-055` | Table 250.122 | OK |  | C) #8 | Table 250.122: "60 10 8" / "100 8 6" -> 80 A falls in 100 A row, 8 AWG copper |  |
| `final-exam-#4-056` | 430.32(C) | Value/wording changed in 2023 (key kept) | FIXED | C) 17.16 | 430.32(C): "All other motors 130%"; Table 430.248: "2 24 13.8 13.2 12" -> 13.2 x 1.30 = 17.16 | Same 430.32(C) provision error (125% / 115% -> 140% / 130%). Key 17.16 A (130% x 13.2 A) unchanged. |
| `final-exam-#4-057` | Table 5, Chapter 9 | OK |  | D) 0.3802 | Chapter 9 Table 5 XHHW: "8 28.19 0.0437" and "6 38.06 0.0590" -> 6 x 0.0437 + 2 x 0.0590 = 0.3802 |  |
| `final-exam-#4-058` | General calculation | N/A (state law / non-NEC) |  | C) 79 | Trade math: 9500 W / 120 V = 79.2 A (math checks). |  |
| `final-exam-#4-059` | Table 4, Chapter 9 | OK |  | C) 0.1921 sq.in. | Table 4 RMC: "27 1 229 0.355"; Table 5 XHHW "12 11.68 0.0181" -> 0.355 - 0.1629 = 0.1921 |  |
| `final-exam-#4-060` | Table 4, Chapter 9 | OK |  | D) 13 | Table 4 IMC: "27 1 248 0.384 372 0.575"; Note (4) nipples "not to exceed 600 mm (24 ..."; 0.575/0.0437 = 13.16 -> 13 | Stem omits that the 18 in. piece is a nipple between enclosures (Note 4 condition); minor. |
| `final-exam-#4-061` | Table 430.52(C)(1) | Ambiguous | FIXED | C) 150 | Table 430.52(C)(1): "Single-phase motors 300 175 800 250" and "Wound-rotor 150 150 800 150" | 'single-phase, ... wound rotor' matched two Table 430.52(C)(1) rows (single-phase 300 = choice A; wound-rotor 150 = key C). 'single-phase' removed; key unchanged. |
| `final-exam-#4-062` | Table 4, Chapter 9 | OK |  | C) 19 | Table 4 PVC Sch 80: "53 2 742 1.150"; XHHW 6 = 0.0590 -> 19.49; Note 7 rounds up only at ">= 0.8" -> 19 |  |
| `final-exam-#4-063` | Table 310.15(C)(1) | OK |  | B) 15.225a | Table 310.15(B)(1)(1): "41—45 0.71 0.82 0.87"; Table 310.15(C)(1) "7—9 70"; 25 x 0.87 x 0.70 = 15.225 |  |
| `final-exam-#4-064` | Table 314.16(B)(1) | OK |  | C) 14.25 cu.in. | Table 314.16(B)(1): "12 36.9 2.25", "10 41.0 2.50" -> 6.75 + 7.50 = 14.25 |  |
| `final-exam-#4-065` | Table 4, Chapter 9 | OK |  | A) 2" | Table 5: THWN 3 = 0.0973, THW 8 = 0.0437, THW 10 = 0.0243 -> 0.7635; Table 4 PVC Sch 80 1-1/2 "0.684", 2 "1.150" |  |
| `final-exam-#4-066` | Table 4, Chapter 9 | OK |  | A) 12 | Table 4 RMC: "27 1 229 0.355 344 0.532"; Note (4) 60% for nipples <= 24 in.; 0.532/0.0437 = 12.17 -> 12 | Stem omits that the 20 in. conduit is a nipple between enclosures (Note 4 condition); minor. |
| `final-exam-#4-067` | Table 430.52(C)(1) | OK |  | D) 45a | Table 430.248: "3 34 19.6 18.7 17"; inverse time breaker 250% -> 42.5 -> next standard 45 |  |
| `final-exam-#4-068` | Table 4, Chapter 9 | OK |  | C) 15 | Table 4 IMC: "41 11/2 573 0.890"; XHHW 6 = 0.0590 -> 15.08 -> 15 |  |
| `final-exam-#4-069` | Table 220.55 | OK |  | A) 43 kW | Table 220.55: "26—30 30 24 15 kW + ..." -> 15 + 28 = 43 kW |  |
| `final-exam-#4-070` | Table 430.250 | OK |  | D) 17,000 | Table 430.250: "15 - 48.3 46.2 42 21 17" (208 V = 46.2) -> 46.2 x 208 x 1.732 = 16,644 VA |  |
| `final-exam-#5-001` | 324.41 | OK |  | B) release-type adhesive | 324.41: "Carpet squares that are adhered to ..." |  |
| `final-exam-#5-002` | 320.80(A) | OK |  | B) 194 degrees F | 320.80(A): "Armored cable installed in thermal insulation ..." | Stem says ampacity "shall be that of 60 degree C"; Code says "shall not exceed"; minor. |
| `final-exam-#5-003` | Article 100 | OK |  | C) MC | Article 100: "Cable, Metal Clad (Type MC)... enclosed ..." |  |
| `final-exam-#5-004` | 324.40(D) | OK |  | A) transition assembly | 324.40(D): "shall be accomplished in a transition ..." |  |
| `final-exam-#5-005` | 322.56(B) | OK |  | B) 15 | 322.56(B): "Tap devices shall be rated at ..." | Stem says "300 volts" (Code: "300 volts to ground") and "color-coded" (Code: "marked in accordance with 322.120(C)", which is color/word coding of terminal blocks); minor wording. |
| `final-exam-#5-006` | 320.30(D)(2) | OK |  | B) 2 feet | 320.30(D): "Is not more than 600 mm ..." |  |
| `final-exam-#5-007` | Article 100 | OK |  | C) bottom shield | Article 100: "Bottom Shield. A protective layer that ..." |  |
| `final-exam-#5-008` | 330.104 | OK |  | A) #18 | 330.104: "For control and signal conductors, minimum ..." |  |
| `final-exam-#5-017` | 332.10(7) | OK |  | A) it may be used in hazardous locations, where permitted | 332.10: "In hazardous (classified) locations where specifically ..."; 332.30: "intervals not exceeding 1.8 m (6 ft)" |  |
| `final-exam-#5-018` | 340.80 | OK |  | D) 60 degrees C | 340.80: "The ampacity of Type UF cable ..." |  |
| `final-exam-#5-019` | 334.116(B) | OK |  | C) NMC | 334.116(B) Type NMC: "The overall covering shall be flame ..." |  |
| `final-exam-#5-020` | 332.104, 332.108, and 332.116 | OK |  | D) all of these | 332.104 "solid copper, nickel, or nickel-coated copper"; 332.116 "continuous construction to provide mechanical protection"; 332.108 copper sheath "adequate path" |  |
| `final-exam-#5-021` | 338.10(B)(3) | OK |  | B) appliances | 338.10(B)(3): "Type SE service-entrance cable used to ..." |  |
| `final-exam-#5-022` | 338.100 | OK |  | B) USE | 338.100(A): "Cabled assemblies of multiple single-conductor Type ..." |  |
| `final-exam-#5-023` | 336.24 | OK |  | B) twelve | 336.24: "Type TC cables with metallic shielding ..." |  |
| `final-exam-#5-024` | 334.12(A)(3) | OK |  | B) as service-entrance cable | 334.12(A): "Types NM and NMC cables shall ..." (3rd item) |  |
| `final-exam-#5-032` | 348.22 | OK |  | D) #10 | Table 348.22 (3/8 FMC): largest listed size row "10 - - 1 1 1 ..." |  |
| `final-exam-#5-033` | 344.120 | OK |  | B) clearly and durably identified | 344.120: "Each length shall be clearly and ..." |  |
| `final-exam-#5-034` | 358.14 | OK |  | D) steel electrical metallic tubing | 358.14: "Stainless steel and aluminum fittings and ..." |  |
| `final-exam-#5-035` | Article 100 | OK |  | C) manually | Article 100 (ENT): "A pliable raceway is a raceway ..." | LOOKUP points to 362.24(A) (ENT bends, "made manually"); the definition itself is in Article 100 under ENT; minor. |
| `final-exam-#5-036` | 352.100, 352.12(B), and 352.60 | OK |  | A) above ground in direct sunlight | 352.100: "For use aboveground, it shall also ..." 352.12(B) bars luminaire support; 352.60 requires separate grounding conductor. | 352.10 has no explicit 'direct sunlight' item; 352.10(G) (exposed work) plus 352.100 support the key. |
| `final-exam-#5-037` | 358.100 | OK |  | D) any of these | 358.100: "EMT shall be made of one ..." |  |
| `final-exam-#5-038` | 350.12 | OK |  | B) where subject to physical damage | 350.12: "LFMC shall not be used where ..." |  |
| `final-exam-#5-039` | 366.23(A) | OK |  | D) 2000 amps | 366.23(A): bare copper bars "shall not exceed 1.55 amperes/mm2 (1000 amperes/in.2)"; 4 x 0.5 = 2 in.2 x 1000 = 2000 A. |  |
| `final-exam-#5-048` | 366.100(E) | OK |  | B) 1 inch | 366.100(E): "not less than 50 mm (2 ..." |  |
| `final-exam-#5-049` | 382.15(A) | OK |  | D) 2 | 382.15(A): "not on the floor or within ..." |  |
| `final-exam-#5-050` | 368.234(A) | OK |  | A) vapor seal | 368.234(A): "shall have a vapor seal at ..." |  |
| `final-exam-#5-051` | 370.10 | OK |  | A) exposed | 370.10: "where installed only for exposed work ..." |  |
| `final-exam-#5-052` | 368.17(B) | OK |  | B) It must be protected by an overcurrent device. | 368.17(B): "Overcurrent protection shall be required where ..." Exception is "For industrial establishments only". |  |
| `final-exam-#5-053` | 384.30(A) | OK |  | C) 10 | 384.30(A): "at intervals not exceeding 3 m ..." |  |
| `final-exam-#5-054` | 395.30(A) | OK |  | D) 395 | 395.30(A): "Documentation of the engineered design by ..." |  |
| `final-exam-#5-055` | 388.12(3) | OK |  | A) 300 | 388.12 item 3: "Where the voltage is 300 volts ..." |  |
| `final-exam-#5-064` | 470.11 | OK |  | D) 12 inches | 470.11: "A thermal barrier shall be required ..." |  |
| `final-exam-#5-065` | 376.30(B) | OK |  | D) 15 feet | 376.30(B): "Vertical runs of wireways shall be ..." |  |
| `final-exam-#5-066` | 356.22 | OK |  | C) Table 1 | 356.22: "shall not exceed that permitted by ..." |  |
| `final-exam-#5-067` | 342.30(B)(3) | OK |  | C) 20 | 342.30(B)(3): "Exposed vertical risers ... supported at ..." |  |
| `final-exam-#5-068` | 344.10(C) | OK |  | B) 2 inches | 344.10(C): "protected on all sides by a ..." |  |
| `final-exam-#5-069` | 334.30(B)(2) | OK |  | D) 54" | 334.30(B)(2): "not more than 1.4 m (4 ..." | Stem omits the 2023 dwelling-unit condition (one-, two-, or multifamily dwellings); consider adding 'in a dwelling'. |
| `final-exam-#5-070` | Table 352.30(B) | OK |  | A) 3 feet | Table 352.30(B): "16-27 / 1/2-1 / 900 mm / 3" (trade size 1/2-1 max 3 ft between supports). | Stem uses 'RNC' (2023 Article 352 term is PVC conduit); the 'fastened within 3 ft' clause is from 352.30(A) and irrelevant to the answer. Style only. |
| `open-book-exam-#1-001` | 210.4(B) | OK |  | A) ungrounded | 210.4(B): "simultaneously disconnect all ungrounded conductors at ..." |  |
| `open-book-exam-#1-002` | Article 100 | OK |  | C) main bonding jumper | Art. 100 Bonding Jumper, Main: "The connection between the grounded circuit ..." |  |
| `open-book-exam-#1-003` | 220.5(C) | OK |  | C) outside | 220.5(C): "The floor area for each floor ..." |  |
| `open-book-exam-#1-004` | 300.4(A)(2) | OK |  | A) 1/16" | 300.4(A)(2): "protected from penetration by nails or ..." |  |
| `open-book-exam-#1-005` | 210.63 | OK |  | A) 25 | 210.63: "receptacle outlet shall be installed at ..." | An MCC requires dedicated space, so 210.63(B)(2) also requires the receptacle in the same room or area; 25 ft remains the only correct choice. |
| `open-book-exam-#1-006` | 404.14(B)(2) | OK |  | C) 50% | 404.14(B)(2): "Inductive loads not exceeding 50 percent ..." |  |
| `open-book-exam-#1-007` | 408.3(A)(2) | OK |  | C) vertical | 408.3(A)(2): "only those conductors that are intended ..." |  |
| `open-book-exam-#1-008` | 250.53(A)(5) | OK |  | B) 2 1/2 feet | 250.53(A)(5): "Plate electrodes shall be installed not ..." |  |
| `open-book-exam-#1-009` | 408.41 | OK |  | D) individual | 408.41: "Each grounded conductor shall terminate within ..." |  |
| `open-book-exam-#1-010` | 210.8(A)(10) | OK |  | B) 6 | 210.8(A) item 10: "Bathtubs or shower stalls - where ..." |  |
| `open-book-exam-#1-011` | 110.26(B) | OK |  | C) guarded | 110.26(B): "the working space, if in a ..." |  |
| `open-book-exam-#1-012` | 210.8(B)(3) | OK |  | A) sink | 210.8(B) item 3: "Areas with sinks and permanent provisions ..." |  |
| `open-book-exam-#1-013` | 220.5(B) | OK |  | A) 0.5 | 220.5(B): "rounded to the nearest whole ampere ..." |  |
| `open-book-exam-#1-014` | 210.8(C) | OK |  | B) 120 | 210.8(C): "GFCI protection shall be provided for ..." |  |
| `open-book-exam-#1-015` | 408.18(C) | OK |  | A) front | 408.18(C): "requires rear or side access to ..." |  |
| `open-book-exam-#1-016` | 210.63(B)(1) | OK |  | D) the same room or area | 210.63(B)(1): "The required receptacle outlet shall be ..." |  |
| `open-book-exam-#1-017` | 408.19 | OK |  | D) listed | 408.19: "An insulated conductor used within a ..." |  |
| `open-book-exam-#1-018` | 210.8(E) | OK |  | A) equipment requiring servicing | 210.8(E): "GFCI protection shall be provided for ..." |  |
| `open-book-exam-#1-019` | 590.4(F) | OK |  | B) luminaire | 590.4(F): "protected from accidental contact or breakage ..." |  |
| `open-book-exam-#1-020` | 210.11(C)(2) | OK |  | B) 20 | 210.11(C)(2): "at least one additional 20-ampere branch ..." |  |
| `open-book-exam-#1-021` | Table 220.42(A) | OK |  | D) 6,500 | Table 220.42(A): "Office 14 1.3" VA/ft2; 5,000 x 1.3 = 6,500 VA. |  |
| `open-book-exam-#1-022` | 210.50(C) | OK |  | D) 72" | 210.50(C): "shall be installed within 1.8 m ..." |  |
| `open-book-exam-#1-023` | 590.5 | OK |  | C) labeled | 590.5: "shall be listed and shall be ..." |  |
| `open-book-exam-#1-024` | 680.21(C) and 680.5(B) | OK |  | A) 60 | 680.5(B): "branch circuits rated 150 volts or ..." |  |
| `open-book-exam-#1-025` | 440.14 | OK |  | D) readily accessible | 440.14: "Disconnecting means shall be located within ..." |  |
| `open-book-exam-#2-001` | 408.43 | OK |  | A) face-up | 408.43: "Panelboards shall not be installed in ..." |  |
| `open-book-exam-#2-002` | 210.7 | OK |  | C) originates | 210.7: "a means to simultaneously disconnect the ..." |  |
| `open-book-exam-#2-003` | 210.23(B)(2) | OK |  | D) 50% | 210.23(B)(2): "shall not exceed 50 percent of ..." |  |
| `open-book-exam-#2-004` | 210.8(C) | OK |  | B) 120 | 210.8(C): "GFCI protection shall be provided for ..." |  |
| `open-book-exam-#2-005` | 210.18 | OK |  | D) 10, 15, 20, 30, 40 and 50 amperes | 210.18: "The rating for other than individual ..." |  |
| `open-book-exam-#2-006` | 110.16(A) | OK |  | C) qualified | 110.16(A): "shall be field or factory marked ..." |  |
| `open-book-exam-#2-007` | 210.52(C)(1) | OK |  | D) 24" | 210.52(C)(1): "no point along the wall line ..." | Stem omits the countertop/work-surface context of 210.52(C); 6 ft (210.52(A)(1)) is not a choice, so not ambiguous. |
| `open-book-exam-#2-008` | 590.4(J) | OK |  | C) strain relief devices | 590.4(J) Exception: "arranged with strain relief devices, tension ..." |  |
| `open-book-exam-#2-009` | 210.62 | OK |  | C) 18" | 210.62: "shall be installed within 450 mm ..." |  |
| `open-book-exam-#2-010` | 225.6(B) | OK |  | B) #12 | 225.6(B): "Overhead conductors for festoon lighting shall ..." |  |
| `open-book-exam-#2-011` | 210.12(B) | OK |  | C) bathrooms and garages | 210.12(B) list: Kitchens, Family rooms, ... Parlors, Libraries, Dens, Bedrooms, Sunrooms, ... Closets, Hallways, Laundry areas; bathrooms and garages not listed. |  |
| `open-book-exam-#2-012` | Table 310.16 | OK |  | B) 20a | Table 310.16: "12* 20 25 30" (75C = 25 A); Table 310.15(C)(1): "4-6 80"; 25 x 0.80 = 20 A, no correction at 30C/86F. |  |
| `open-book-exam-#2-013` | 210.8(A)(2) | OK |  | B) GFCI | 210.8(A) item 2: "Garages and also accessory buildings that ..."; garages not in 210.12(B) AFCI list. |  |
| `open-book-exam-#2-014` | 110.25 | OK |  | B) lock | 110.25: "The provisions for locking shall remain ..." |  |
| `open-book-exam-#2-015` | 210.52(A)(2) | OK |  | B) 24" | 210.52(A)(2): "Any space 600 mm (2 ft) ..." | 2023 list also includes 'stationary appliances'; stem omits it (style only). |
| `open-book-exam-#2-016` | 240.87 | OK |  | D) 1200 | 240.87: "is rated or can be adjusted ..." |  |
| `open-book-exam-#2-017` | 210.52(C) | OK |  | B) 12" | 210.52(C): "each 300 mm (12 in.) of ..." | INFO_TIP background is about load calculations, unrelated to the question. |
| `open-book-exam-#2-018` | 220.14(H) | OK |  | C) 540 | 220.14(H)(1): "each 1.5 m (5 ft) or ..." 12 ft -> 3 x 180 = 540 VA. |  |
| `open-book-exam-#2-019` | 410.172 | OK |  | D) listed | 410.172: "Lighting equipment identified for horticultural use ..." |  |
| `open-book-exam-#2-020` | Article 100 | OK |  | B) dry | Article 100 Location, Dry: "A location classified as dry may ..." |  |
| `open-book-exam-#2-021` | 230.70(A)(2) | OK |  | D) a bathroom | 230.70(A)(2): "Service disconnecting means shall not be ..." |  |
| `open-book-exam-#2-022` | 310.6(C) | OK |  | C) pink | 310.6(C): ungrounded conductors "shall be finished to be clearly ..." | 310.6(C) itself names no colors; the white/gray and green reservations come from 200.6/200.7 and 250.119 (310.6(C) refers to 210.5(C)). Could add those to TIP. INFO_TIP background is about load calculations, unrelated. |
| `open-book-exam-#2-023` | 680.62(E) | OK |  | D) 72" | 680.62(E): "All receptacles within 1.83 m (6 ..." |  |
| `open-book-exam-#2-024` | 590.6(B) | OK |  | B) assured | 590.6(B): "shall have protection in accordance with ..." |  |
| `open-book-exam-#2-025` | 210.52(E)(3) | OK |  | D) 78" | 210.52(E)(3): "The receptacle outlet shall not be ..." |  |
| `open-book-exam-#3-001` | 210.52(C)(3) | OK |  | C) 20" | 210.52(C)(3)(1): "On or above, but not more ..." |  |
| `open-book-exam-#3-002` | 240.21(B)(1) | OK |  | D) 400a | 240.21(B)(1)(4): tap ampacity "is not less than one-tenth of ..." 40 x 10 = 400 A. |  |
| `open-book-exam-#3-003` | 210.52(H) | OK | FIXED (explanation only) | C) 10 | 210.52(H): "In dwelling units, hallways of 3.0 ..." | FIXED pre-answer: background said 'hallways 10 ft or longer need one' (answer 10). / INFO_TIP background states "hallways 10 ft or longer need one", which gives away the answer before answering. |
| `open-book-exam-#3-004` | 210.8(A)(11) | OK |  | C) both GFCI and AFCI | 210.8(A) list item 11: "Laundry areas"; 210.12(B) dwelling AFCI list includes "Laundry areas" for 120-V 10-, 15-, 20-A branch circuits. |  |
| `open-book-exam-#3-005` | 210.60(B) | OK |  | B) two | 210.60(B): "At least two receptacle outlets shall ..." | INFO_TIP background is about disconnecting means, unrelated. |
| `open-book-exam-#3-006` | 220.53 | OK |  | A) 500 | 220.53: "four or more appliances rated 1/4 ..." may take 75 percent. |  |
| `open-book-exam-#3-007` | 424.20(A)(3) | OK |  | D) be designed so that the circuit cannot be energized automatically after the device has been manually placed in the off position | 424.20(A)(3): "Designed so that the circuit cannot ..." | INFO_TIP background is about motor overloads, unrelated. |
| `open-book-exam-#3-008` | 408.5 | OK |  | B) 3 | 408.5: "The conduit or raceways, including their ..." |  |
| `open-book-exam-#3-009` | 514.11(A) | OK |  | D) 100 | 514.11(A): "not less than 6 m (20 ..." |  |
| `open-book-exam-#3-010` | Table 310.15(B)(1)(1) | OK |  | B) 34.8 | Table 310.15(B)(1)(1) row 105-113°F: 90°C factor 0.87; #10 Cu 90°C = 40 A; 40 x 0.87 = 34.8 A. |  |
| `open-book-exam-#3-011` | Table 310.4(1) | OK |  | D) The conductor has a maximum operating temperature of 90°C. | Table 310.4(1): "RHW-2  90°C" (plain RHW is 75°C). |  |
| `open-book-exam-#3-012` | 680.5(B) | OK |  | A) 60 | 680.5(B): "branch circuits rated 150 volts or ..." |  |
| `open-book-exam-#3-013` | 630.12(A) | OK |  | B) 90 amp | 630.12(A): "not more than 200 percent of I1max"; 630.12 permits next higher standard rating. 43 x 2 = 86 -> 90 A. |  |
| `open-book-exam-#3-014` | 210.8(A) | OK |  | D) 125-250 | 210.8(A): "All 125-volt through 250-volt receptacles installed ..." |  |
| `open-book-exam-#3-015` | 680.58 | OK |  | A) 20 | 680.58: "All receptacles rated 125 volts through ..." | Stem says '15 or 20 amp'; 2023 covers 60 A or less. Still true as a subset; optional stem update. |
| `open-book-exam-#3-016` | 250.122(F)(1) | OK |  | B) run in parallel in each raceway | 250.122(F)(1)(b): "a wire-type equipment grounding conductor, if ..." |  |
| `open-book-exam-#3-017` | 210.52(G)(1) | OK |  | C) two | 210.52(G)(1): "at least one receptacle outlet shall ..." | Assumes two-car garage = two vehicle bays (reasonable). |
| `open-book-exam-#3-018` | 410.154 | OK |  | A) 4 | 410.154: "each individual section of not more ..." |  |
| `open-book-exam-#3-019` | Table 220.55 | OK |  | C) 8.8 | Table 220.55 Note 1: Column C "shall be increased 5 percent for ..." 8 kW x 1.10 = 8.8 kW. |  |
| `open-book-exam-#3-020` | 250.53(A)(3) | OK |  | D) 72" | 250.53(A)(3): "If multiple rod, pipe, or plate ..." |  |
| `open-book-exam-#3-021` | 410.10(F) | OK |  | B) 1 1/2" | 410.10(F): "not less than 38 mm (1 ..." |  |
| `open-book-exam-#3-022` | 620.61(B)(1) | OK | FIXED (explanation only) | A) intermittent | 620.61(B)(1): "Duty on elevator and dumbwaiter driving ..." | FIXED pre-answer: background said elevator motors 'live an intermittent life' (answer). / INFO_TIP says "Elevator and dumbwaiter motors live an intermittent life", giving away the answer. |
| `open-book-exam-#3-023` | 250.34(A) | OK |  | A) not be required | 250.34(A): "The frame of a portable generator ..." |  |
| `open-book-exam-#3-024` | 800.25 | OK |  | D) of sufficient durability to withstand the environment | 800.25: "the tag shall be of sufficient ..." |  |
| `open-book-exam-#3-025` | 250.92(B) | OK |  | D) bonding jumpers, and bonding-type locknuts or bushings | 250.92(B): "Bonding jumpers ... shall be used ..."; item 4 bonding-type locknuts, bushings. |  |
| `open-book-exam-#4-001` | Article 100 | OK |  | C) qualified | Article 100 Qualified Person: "One who has skills and knowledge ..." |  |
| `open-book-exam-#4-002` | 210.8(F) | OK |  | A) 50 | 210.8(F): "all outdoor outlets ... supplied by ..." |  |
| `open-book-exam-#4-003` | 334.12(B)(4) | OK |  | D) in a damp or wet location | 334.12(B)(4): Type NM cables shall not be used "In wet or damp locations." |  |
| `open-book-exam-#4-004` | Table 300.5(A) Column 1 | OK |  | C) 18 inches | Table 300.5(A): "In trench below 50 mm (2 ..." (Column 1). |  |
| `open-book-exam-#4-005` | 406.12(1) | OK |  | D) listed tamper-resistant | 406.12 item 1: 15- and 20-A, 125- and 250-V nonlocking receptacles in "All dwelling units ..." shall be listed tamper-resistant. |  |
| `open-book-exam-#4-006` | 422.16(B)(1)(1) | OK |  | C) 36 inches | 422.16(B)(1)(1): "The length of the cord is ..." |  |
| `open-book-exam-#4-007` | 406.3(E) | OK | FIXED (explanation only) | D) orange triangle | 406.3(E): isolated ground receptacles "shall be identified by an orange ..." | FIXED pre-answer: same orange-triangle sentence as final-exam-#2-047. / INFO_TIP says "You can spot one by the ora[nge triangle]", giving away the answer. |
| `open-book-exam-#4-008` | 210.4(C) | OK |  | D) neutral | 210.4(C): "Multiwire branch circuits shall supply only line-to-neutral loads." | GIST says the question asks what the equipment must contain; it actually asks the load type (line-to-neutral). Mismatched GIST. |
| `open-book-exam-#4-009` | Article 100 | OK |  | A) ground fault | Article 100 Ground Fault: "An unintentional, electrically conductive connection between ..." |  |
| `open-book-exam-#4-010` | 590.4(G) | OK |  | C) be required | 590.4(G): "A box, conduit body, or other ..." Exceptions are construction sites only. |  |
| `open-book-exam-#4-011` | 680.43(B)(1)(a) | OK |  | D) 12 | 680.43(B)(1)(a): "Where no GFCI protection is provided ..." |  |
| `open-book-exam-#4-012` | 210.12(A)(1) | OK |  | B) branch circuit | 210.12(A)(1): "A listed combination-type AFCI installed to ..." |  |
| `open-book-exam-#4-013` | Article 100 | OK |  | A) labeled | Article 100 Labeled: "Equipment or materials to which has ..." |  |
| `open-book-exam-#4-014` | 406.9(B) | OK |  | D) weather resistant | 406.9(B)(1): "All 15- and 20-ampere, 125- and ..." |  |
| `open-book-exam-#4-015` | Table 220.54 | OK |  | D) 85% | Table 220.54: "1-4  100 // 5  85 // 6  75". |  |
| `open-book-exam-#4-016` | 430.8 | OK |  | D) suitable | 430.8: "A motor controller that includes motor ..." |  |
| `open-book-exam-#4-017` | 340.10(3) | OK | FIXED (explanation only) | D) for wiring in wet, dry, or corrosive locations | 340.10(3): Type UF permitted "For wiring in wet, dry, or corrosive locations." 340.12 bars service-entrance and commercial garages. | FIXED pre-answer: gist said UF is rated for wet, dry and corrosive soil (answer D). / GIST says "Type UF cable is rated for ...", essentially giving away choice D. TIP 'Not C' cites 340.12 for physical damage: correct (340.12 list includes 'Where subject to physical damage'). |
| `open-book-exam-#4-018` | 312.5(C) Ex. 1 | OK |  | C) 18 inches | 312.5(C) Ex. No. 1: "through one or more nonflexible raceways ..." |  |
| `open-book-exam-#4-019` | 314.27(D) Ex. | OK |  | A) #6 | 314.27(D) Exception: "secured to the box with no ..." | GIST calls it 'a luminaire supported by an outlet box'; the rule is for utilization equipment (not luminaires). Minor wording fix. |
| `open-book-exam-#4-020` | 392.100(F) | OK |  | D) flame-retardant | 392.100(F): "Nonmetallic cable trays shall be made ..." |  |
| `open-book-exam-#4-021` | 210.8(A) Ex. 1 | Ambiguous | FIXED | D) readily accessible | 210.8(A) Ex. No. 1: "Receptacles that are not readily accessible ..." | Stem said such receptacles 'are required to have GFCI protection'; 210.8(A) Exception No. 1 permits them to follow 426.28 or 427.22 instead. Stem reworded to the exception; key 'readily accessible' unchanged. |
| `open-book-exam-#4-022` | 310.12(A) | OK | FIXED (explanation only) | A) 83% | 310.12(A): "shall be permitted to have an ..." | FIXED pre-answer: background said dwelling services 'may use conductors at 83%' (answer). / INFO_TIP says dwelling services 'may use conductors at 83% of the rating', giving away the answer. |
| `open-book-exam-#4-023` | 210.12(B), (C), and (D) | OK |  | A) residential garages | 210.12(B) dwelling list (kitchens ... closets, hallways, laundry areas) omits garages; 210.12(C) lists dormitory "Closets"; 210.12(D) guest suites and patient sleeping rooms. |  |
| `open-book-exam-#4-024` | 250.52(A)(2) | OK |  | C) 10 | 250.52(A)(2): "in direct contact with the earth ..." |  |
| `open-book-exam-#4-025` | Table 400.4 and Note 9 | OK |  | B) STOOW | Table 400.4: "STOOW ... Damp and wet locations"; Note 9: "Cords with the 'W' suffix are ..." |  |
| `open-book-exam-#5-001` | 525.5(B)(2) | OK |  | B) 600 | 525.5(B)(2): "not be located under or within ..." |  |
| `open-book-exam-#5-002` | 450.11(A) | OK |  | C) AWG size | 450.11(A) nameplate list: manufacturer, kVA, frequency, voltages, impedance, clearances for ventilating openings, amount and kind of insulating liquid, temperature class; no conductor size. |  |
| `open-book-exam-#5-003` | 590.3(B) | OK |  | D) 90 | 590.3(B): "permitted for a period not to ..." |  |
| `open-book-exam-#5-004` | 110.26(E)(1)(c) | OK |  | C) Sprinkler protection | 110.26(E)(1)(c): "Sprinkler protection shall be permitted for ..." |  |
| `open-book-exam-#5-005` | 408.41 | OK |  | A) identified | 408.41 Exception: parallel-conductor grounded conductors "permitted to terminate in a single ..." |  |
| `open-book-exam-#5-006` | 210.19(C) | OK |  | B) 40 | 210.19(C): "For ranges of 8 3/4 kW ..." |  |
| `open-book-exam-#5-007` | 409.102(B) | OK |  | C) required to be phase "B" on a delta connection | 409.102(B): "The B phase shall be that ..." |  |
| `open-book-exam-#5-008` | 430.42(C) | OK |  | A) 15 amps | 430.42(C): plug and receptacle "shall not exceed 15 amperes at ..." where individual overload protection is omitted. |  |
| `open-book-exam-#5-009` | 525.10(A) | OK |  | D) is lockable | 525.10(A): "Service equipment shall not be installed ..." |  |
| `open-book-exam-#5-010` | 300.4(D) | OK |  | C) 1 1/4" | 300.4(D): nearest outside surface "not less than 32 mm (1 ...". |  |
| `open-book-exam-#5-011` | 400.13 | OK |  | A) junior hard-service | 400.13: "The repair of hard-service cord and ...". |  |
| `open-book-exam-#5-012` | 682.15(B) | OK |  | A) 30 mA | 682.15(B): conductors on piers "shall be provided with ground-fault protection ..." |  |
| `open-book-exam-#5-013` | 240.40 | OK |  | A) 150 | 240.40: "Cartridge fuses in circuits of any ...". |  |
| `open-book-exam-#5-014` | 225.18 | OK |  | D) 24 1/2 | 225.18(5): "7.5 m (24 1/2 ft) - ...". |  |
| `open-book-exam-#5-015` | 550.32(F) | OK |  | A) 24" | 550.32(F): bottom of enclosure "not less than 600 mm (2 ..." |  |
| `open-book-exam-#5-016` | 210.8(A) | OK |  | D) I, II, and III | 210.8(A) list items: "Bathrooms" (1), "Crawl spaces - at or below grade level" (4), "Basements" (5). |  |
| `open-book-exam-#5-017` | 110.26(C)(3) | OK |  | D) 25 | 110.26(C)(3): personnel door "less than 7.6 m (25 ft) ..." requires listed panic or fire exit hardware. |  |
| `open-book-exam-#5-018` | 800.44(B) | OK |  | D) 8 feet | 800.44(B): "vertical clearance of not less than ..." |  |
| `open-book-exam-#5-019` | 647.1 | OK |  | C) 60 | 647.1: "separately derived systems operating at 120 ..." |  |
| `open-book-exam-#5-020` | 300.5(J) | OK |  | D) placed with "S" loops | 300.5(J) Informational Note: "This section recognizes 'S' loops in ...". |  |
| `open-book-exam-#5-021` | 250.52(A)(5) | OK |  | B) 3/4" | 250.52(A)(5)(a): pipe or conduit electrodes "shall not be smaller than metric ...". |  |
| `open-book-exam-#5-022` | 408.4(B) | OK |  | A) feeder | 408.4(B): "All switchboards, switchgear, and panelboards supplied ...". |  |
| `open-book-exam-#5-023` | 334.15(B) | OK |  | D) 6" | 334.15(B): through a floor, enclosed in RMC, IMC, EMT, Sch 80 PVC, RTRC-XW "or other approved means extending at ..." |  |
| `open-book-exam-#5-024` | 352.30(A) | OK |  | C) 36" | 352.30(A): "PVC conduit shall be securely fastened ...". |  |
| `open-book-exam-#5-025` | 250.8(A) | OK |  | D) sheet metal screws | 250.8(A) permitted list: listed pressure connectors, terminal bars, exothermic welding, machine screws, thread-forming machine screws...; sheet metal screws not listed. |  |
| `open-book-exam-#6-001` | 300.22(C)(1) | OK |  | A) PVC | 300.22(C)(1): limited to busway, MI, MC, AC cable...; raceways permitted are EMT, FMT, IMC, RMC, FMC, surface metal raceway/metal wireway; no PVC. |  |
| `open-book-exam-#6-002` | Article 100 | OK |  | D) temperature | Article 100 Ampacity: "carry continuously under the conditions of ..." | Mild: GIST ('insulation can only take so much heat') hints the answer. |
| `open-book-exam-#6-003` | 250.52(A)(5) | OK |  | D) 5/8" | 250.52(A)(5)(b): "stainless steel and copper or zinc-coated ..." |  |
| `open-book-exam-#6-004` | 555.33(A)(4) | OK |  | D) 30 | 555.33(A)(4): "Shore power for boats shall be ..." |  |
| `open-book-exam-#6-005` | 225.18 | OK |  | D) 18 | 225.18(4): "5.5 m (18 ft) - over ...". |  |
| `open-book-exam-#6-006` | 250.53(A)(4) | OK |  | A) 2 1/2 feet | 250.53(A)(4): electrode "shall be permitted to be buried ..." |  |
| `open-book-exam-#6-007` | 408.52 | OK |  | C) 15 | 408.52: "supplied by a circuit that is ..." |  |
| `open-book-exam-#6-008` | 300.5(D)(1) | OK |  | A) 8' | 300.5(D)(1): protection "to a point at least 2.5 ..." |  |
| `open-book-exam-#6-009` | 430.102(B)(2) | OK |  | B) the disconnecting means shall be lockable in the open position | 430.102(B) Exception to (1) and (2): motor disconnect not required "if the motor controller disconnecting means ...". |  |
| `open-book-exam-#6-010` | Table 430.250 | OK |  | C) 65 amps | Table 430.250 row 50 hp: induction 460 V = 65 A (row: 150 143 130 65 52 / sync 104 52 42). |  |
| `open-book-exam-#6-011` | 408.39 | OK |  | C) load | 408.39: "In panelboards, fuses of any type ..." |  |
| `open-book-exam-#6-012` | Table 250.122 | OK |  | C) #10 | Table 250.122 row "60 / 10 / 8": 10 AWG copper for OCPD not exceeding 60 A, covers 50 A. |  |
| `open-book-exam-#6-013` | 350.30(A) | OK |  | B) 12" | 350.30(A): LFMC "securely fastened in place by an ...". |  |
| `open-book-exam-#6-014` | Chapter 9, Note 4 | OK |  | B) 60% | Ch. 9 Note (4): nipples not over 600 mm (24 in.) "shall be permitted to be filled ...". |  |
| `open-book-exam-#6-015` | 300.5(B) | OK |  | D) wet | 300.5(B): "The interior of enclosures or raceways ..." |  |
| `open-book-exam-#6-016` | Table 352.30(B) | OK |  | C) 5 feet | Table 352.30(B): "35-53 / 1 1/4-2 / 1.5 ..." ft maximum spacing. |  |
| `open-book-exam-#6-017` | 324.10(B)(2) | OK |  | A) 30 amps | 324.10(B)(2): "Individual branch circuits shall have ratings ..." |  |
| `open-book-exam-#6-018` | 480.10(A) | OK |  | D) an explosive mixture | 480.10(A): ventilation of gases "to prevent the accumulation of an explosive mixture." |  |
| `open-book-exam-#6-019` | 250.53(A)(2) | OK |  | D) Any of these | 250.53(A)(2): "supplemented by an additional electrode of ..." (support structure, concrete-encased, ground ring all included). |  |
| `open-book-exam-#6-020` | 300.21 | OK |  | D) approved | 300.21: openings around penetrations "shall be firestopped using approved methods ..." |  |
| `open-book-exam-#6-021` | 408.36(A) | OK |  | D) 200 | 408.36(A): "Panelboards equipped with snap switches rated ..." |  |
| `open-book-exam-#6-022` | 330.30(D)(2) | OK |  | D) 72" | 330.30(D)(2): "not more than 1.8 m (6 ...". |  |
| `open-book-exam-#6-023` | 680.11(A) | OK |  | D) 60" | 680.11(A): "Underground wiring within 1.5 m (5 ..."; item (7) LFMC listed for direct burial. |  |
| `open-book-exam-#6-024` | 210.18 | OK |  | B) maximum permitted rating of the fuse or breaker | 210.18: "rated in accordance with the maximum ..." |  |
| `open-book-exam-#6-025` | 504.80(C) | OK |  | B) light blue | 504.80(C): "where they are colored light blue ..." |  |
| `open-book-exam-#7-001` | 200.3 | OK |  | C) electrically | 200.3: "Grounded conductors of premises wiring systems ...". | Stem uses the pre-2020 200.3 wording ('Premises wiring shall not be ... connected to a supply system unless ...'); 2023 text is phrased differently but key 'electrically' still holds. Consider rewording stem to the 2023 sentence. |
| `open-book-exam-#7-002` | Table 8, Chapter 9 | OK |  | A) Table 8, Chapter 9 | Ch. 9 "Table 8 Conductor Properties" (DC resistance at 75°C, ohm/kFT); Table 9 is AC resistance/reactance; Table 5 insulated conductor dimensions; Table 4 conduit dimensions. |  |
| `open-book-exam-#7-003` | 110.16(A) | OK |  | D) dwelling units | 110.16(A): equipment "that is in other than dwelling ...". | Minor: 2023 says 'enclosed panelboards'; stem says 'panelboards'. |
| `open-book-exam-#7-004` | 517.73(B) | OK |  | D) momentary | 517.73(B): "not be less than 50 percent ...". |  |
| `open-book-exam-#7-005` | Article 100 | OK | FIXED (explanation only) | D) Maximum Water Level | Article 100: "Maximum Water Level. The highest level ...". | FIXED pre-answer: info_tip said "'datum' or maximum water level is ..." (answer); gist called it a floodplain term (it is an Article 680 pool term). / GIST wrongly frames it as 'Floodplain measurements' (the term is an Article 680 pool/spa term). INFO_TIP gives away the answer: "'datum' or maximum water level is ...". |
| `open-book-exam-#7-006` | 240.5(B)(4) | OK |  | B) #16 | 240.5(B)(4) Field Assembled Extension Cord Sets: "20-ampere circuits - 16 AWG and larger". |  |
| `open-book-exam-#7-007` | 708.54 Ex. | OK |  | D) loads | 708.54 (Exception after (C)): "Selective coordination shall not be required ...". | Minor: in 2023 the Exception sits under 708.54(C); citation could read '708.54(C) Exception'. |
| `open-book-exam-#7-008` | 110.13(B) | OK |  | A) ventilating | 110.13(B): "Electrical equipment provided with ventilating openings ...". | Mild: GIST ('Ventilated equipment...') hints the answer. |
| `open-book-exam-#7-009` | 225.39 | OK |  | C) calculated | 225.39: disconnecting means "shall have a rating of not ...". | GIST wrongly says 'Service equipment must be rated not less than the total computed load'; the question is about outside feeder/branch-circuit disconnects (225.39). |
| `open-book-exam-#7-010` | 424.36 | OK |  | A) 2 inches | 424.36: "Wiring located above heated ceilings shall ..." |  |
| `open-book-exam-#7-011` | 210.19(B) | OK |  | B) of not less than | 210.19(B): conductors "shall have an ampacity of not ..." | Mild: GIST ('rated at least for the branch-circuit protection') hints the answer. Stem says 'portable tools'; 2023 says 'portable loads' (minor). |
| `open-book-exam-#7-012` | 344.10(A)(3) | OK |  | A) enamel | 344.10(A)(3): "Ferrous raceways and fittings protected from ..." | GIST 'thin paint-type coatings' strongly hints at enamel (mild giveaway). |
| `open-book-exam-#7-013` | Table 300.5(A) | OK |  | D) 300.5(A) | 300.5(A): "shall be installed to meet the ..."; title "Minimum Cover Requirements, 0 to 1000 Volts ac" |  |
| `open-book-exam-#7-014` | Table 300.1(C) | OK |  | D) 300.1(C) | 300.1(C): "Metric designators and trade sizes for ..." |  |
| `open-book-exam-#7-015` | 310.15(A) | OK |  | A) termination | 310.15(A): "does not exceed the ampacity for ..." |  |
| `open-book-exam-#7-016` | 700.7(A) | OK |  | D) location | 700.7(A): "A sign shall be placed at ..." |  |
| `open-book-exam-#7-017` | 110.14(C)(2) | OK |  | C) identified | 110.14(C)(2): "not exceeding the ampacity at the ..." |  |
| `open-book-exam-#7-018` | 210.11(A) | OK |  | A) minimum | 210.11(A): "The minimum number of branch circuits ..." |  |
| `open-book-exam-#7-019` | 110.12(B) | OK |  | C) corrosive residues | 110.12(B): "contaminated by foreign materials such as ..." |  |
| `open-book-exam-#7-020` | Article 100 | OK |  | B) Sign Body | Art. 100: "Sign Body. A portion of a ..." |  |
| `open-book-exam-#7-021` | 408.36(B) | OK |  | C) secondary | 408.36(B): "the overcurrent protection required by 408.36 ..." |  |
| `open-book-exam-#7-022` | 110.26 | OK |  | B) 24 | 110.26: "restrict working space access to be ..." |  |
| `open-book-exam-#7-023` | 400.36 | OK |  | A) portable | 400.36: "Terminations on portable cables rated over ..." |  |
| `open-book-exam-#7-024` | 408.3(F)(1) | OK |  | C) delta | 408.3(F)(1): "containing a 4-wire, delta-connected system where ..." |  |
| `open-book-exam-#7-025` | 225.37 | OK |  | A) disconnect | 225.37: "a permanent plaque or directory shall ..." |  |
| `open-book-exam-#9-001` | 394.19(A) | OK |  | B) 3" | 394.19(A): "A clearance of not less than ..." |  |
| `open-book-exam-#9-002` | Table 250.122 | OK |  | D) 250.122 | Table 250.122: "Minimum Size Equipment Grounding Conductors for ..." |  |
| `open-book-exam-#9-003` | 110.21(B) | OK |  | A) Z535.4 | 110.21(B) Inf. Note No. 2: "See ANSI Z535.4-2011 (R2017), Product Safety ..." | Stem says 'ANSI ___-2017'; 2023 note cites Z535.4-2011 (R2017). Minor; key unaffected. |
| `open-book-exam-#9-004` | 620.54 | OK |  | C) location | 620.54: "The disconnecting means shall be provided ..." |  |
| `open-book-exam-#9-005` | Chapter 9, Table 1 | OK |  | C) Table 1, Chapter 9 | Ch. 9 Table 1: "Percent of Cross Section of Conduit ..." 1 = 53, 2 = 31, Over 2 = 40 |  |
| `open-book-exam-#9-006` | 240.4(C) | OK |  | C) equal to or greater than | 240.4(C): "the ampacity of the conductors it ..." | Choice D 'not less than' is semantically the same as C 'equal to or greater than'; keyed on verbatim wording. Consider rewording D to avoid a second defensible answer. |
| `open-book-exam-#9-007` | 300.6(A) | OK |  | A) Approved | 300.6(A): "the threads shall be coated with ..." |  |
| `open-book-exam-#9-008` | 495.25(B) | OK |  | C) single-line | 495.25(B): "A permanent and legible single-line diagram ..." |  |
| `open-book-exam-#9-009` | 110.14(C)(1) | OK |  | B) 75°C | 110.14(C)(1): "For motors marked with design letters ..." |  |
| `open-book-exam-#9-010` | 600.4(C) | OK |  | A) 1/4" | 600.4(C): "The markings shall be permanently installed ..." |  |
| `open-book-exam-#9-011` | Table 430.52(C)(1) | OK |  | B) 430.52(C)(1) | Table 430.52(C)(1): "Maximum Rating or Setting of Motor ..." |  |
| `open-book-exam-#9-012` | 210.18 | OK |  | C) setting | 210.18: "shall be rated in accordance with ..." |  |
| `open-book-exam-#9-013` | 502.128 | OK |  | C) be protected against physical damage and against rusting or other corrosive influences | 502.128: "Be protected against physical damage and ..." |  |
| `open-book-exam-#9-014` | Table 210.21(B)(2) | OK |  | A) 210.21(B)(2) | Table 210.21(B)(2): "Maximum Cord-and-Plug-Connected Load to Receptacle" |  |
| `open-book-exam-#9-015` | 314.24(B)(1) | OK |  | D) 1 7/8" | 314.24(B)(1): "projects more than 48 mm (1 ..." |  |
| `open-book-exam-#9-016` | 110.14(C)(2) | OK |  | A) connector | 110.14(C)(2): "at the listed and identified temperature ..." |  |
| `open-book-exam-#9-017` | Table 235.360(A) | OK |  | C) 235.360(A) | Table 235.360(A): "Clearances over Roadways, Walkways, Rail, Water ..." |  |
| `open-book-exam-#9-018` | 210.18 | OK |  | C) circuit rating | 210.18: "the ampere rating or setting of ..." |  |
| `open-book-exam-#9-019` | Table 110.34(A) | OK |  | B) 110.34(A) | Table 110.34(A): "Minimum Depth of Clear Working Space ..." |  |
| `open-book-exam-#9-020` | 210.21(B)(4) | OK |  | D) 220.55 | 210.21(B)(4): "The ampere rating of a range ..." |  |
| `open-book-exam-#9-021` | 545.7 | OK |  | B) 545.7 | 545.7: "Service equipment shall be installed in ..." |  |
| `open-book-exam-#9-022` | 430.7(C) | OK |  | C) at standstill | 430.7(C): "Torque motors are rated for operation at standstill" |  |
| `open-book-exam-#9-023` | 430.7(A) | OK | FIXED (explanation only) | D) impedance protected | 430.7(A)(14): impedance-protected motors of 100 W or less may be marked "Z.P." | FIXED pre-answer: gist said 'Z is the usual symbol for impedance' (answer: impedance protected). / GIST 'Z is the usual symbol for impedance' gives away the answer. |
| `open-book-exam-#9-024` | 344.10(A)(1) | OK |  | D) Red brass | 344.10(A)(1): "Galvanized steel, stainless steel, and red ..." |  |
| `open-book-exam-#9-025` | Article 100 | OK |  | B) a lampholder | Art. 100 Luminaire: "It may also include parts to ..." |  |
| `open-book-exam-#10-001` | 547.30 | OK |  | D) all of these | 547.30: "designed so as to minimize the ..." |  |
| `open-book-exam-#10-002` | 220.5(C) | OK |  | B) garages | 220.5(C): "For dwelling units, the calculated floor ..." | Correct only under 2023 (2020 220.12 excluded garages); key B relies on garages no longer being excluded. |
| `open-book-exam-#10-003` | 406.10(C) | OK |  | B) equipment grounding | 406.10(C): "A grounding terminal shall not be ..." |  |
| `open-book-exam-#10-004` | 409.21 | OK |  | A) taps | 409.21(B)(2): "the supply conductors shall be considered ..." |  |
| `open-book-exam-#10-005` | 300.5(F) | OK |  | D) corrosion | 300.5(F): "prevent adequate compaction of fill or ..." |  |
| `open-book-exam-#10-006` | Article 100 | OK |  | A) Remote Disconnect Control | Art. 100: "Remote Disconnect Control. An electric device ..." |  |
| `open-book-exam-#10-007` | 314.2 | OK |  | B) Round boxes are required to be used where conduits or connectors requiring the use of locknuts or bushings are to be connected to the side of the box. | 314.2: "Round boxes shall not be used ..." | Other statements verified true: 250.146(D) insulated EGC; 430.9(C) 0.8 N-m (7 lb-in.); Article 330 recognizes single-conductor Type MC. |
| `open-book-exam-#10-008` | 630.42(C) | OK |  | A) CABLE TRAY FOR WELDING CABLES ONLY | 630.42(C): "at intervals not greater than 6.0 ..." |  |
| `open-book-exam-#10-009` | Article 100 | OK |  | C) Operator | Art. 100: "Operator. The individual responsible for starting ..." |  |
| `open-book-exam-#10-010` | 225.19(D)(1) and 225.19(D)(3) | OK |  | D) It must not obstruct entrance to the material handling door and be 3 feet from the door. | 225.19(D)(3): "shall not be installed beneath openings ..." |  |
| `open-book-exam-#10-011` | 810.16(B) | OK |  | C) 150 | 810.16(B): "located well away from overhead conductors ..." |  |
| `open-book-exam-#10-012` | 724.40 | OK |  | A) 1000 | 724.40: "Class 1 circuits shall be supplied ..." |  |
| `open-book-exam-#10-013` | 314.23(E) | OK |  | B) threaded into hubs identified for the purpose | 314.23(E): "It shall have threaded entries or ..." |  |
| `open-book-exam-#10-014` | 660.9 | OK |  | C) 20 | 660.9: "where protected by not larger than ..." |  |
| `open-book-exam-#10-015` | 310.3(B)(3) | OK |  | A) 10 | 310.3(B)(3): "the copper shall form a minimum ..." |  |
| `open-book-exam-#10-016` | 110.26(A)(1) Condition 2 | OK |  | C) grounded | Table 110.26(A)(1) Condition 2: "Concrete, brick, or tile walls shall ..." |  |
| `open-book-exam-#10-017` | 500.5(D) | OK |  | C) Class III | 500.5(D)(1): "Locations where ignitible fibers/flyings are handled ..." |  |
| `open-book-exam-#10-018` | 406.3(E) | OK |  | D) an orange triangle located on the face of the receptacle | 406.3(E): "shall be identified by an orange ..." |  |
| `open-book-exam-#10-019` | 517.18(B)(1) | OK |  | D) 4 duplex or 8 single | 517.18(B)(1): "Each patient bed location shall be ..." | Answer choice D ('4 duplex or 8 single') is an interpretation; per 517.18(B)(2) any combination of single, duplex, or quadruplex totaling eight is allowed. |
| `open-book-exam-#10-020` | 210.52(E)(3) | Value/wording changed in 2023 (key kept) | FIXED | B) 6'6" | 210.52(E)(3): "The receptacle outlet shall not be ..." | Same 210.52(E)(3) stem update as final-exam-#2-049. Key 6'6" unchanged. |
| `open-book-exam-#10-021` | 695.12(D) | OK |  | D) 12 | 695.12(D): "All energized equipment parts shall be ..." |  |
| `open-book-exam-#10-022` | 305.4 | OK |  | C) nonshielded | 305.4: "Conductors having nonshielded insulation and operating ..." | GIST 'require cable with suitable separation construction' mildly hints at shielding; INFO_TIP background is about boxes (off-topic). |
| `open-book-exam-#10-023` | 551.71(B) | OK |  | D) 70 | 551.71(B): "A minimum of 70 percent of ..." |  |
| `open-book-exam-#10-024` | Article 100 | OK |  | D) grounding electrode conductor | Article 100 Grounding Electrode Conductor (GEC): "A conductor used to connect the ..." | Stem says 'grounded circuit of a wiring system' (older wording); 2023 says 'system grounded conductor or the equipment'. Key unaffected. |
| `open-book-exam-#10-025` | 305.15(E) | OK |  | A) damage | 305.15(E): "shall not be placed in an ..." |  |
| `open-book-exam-#11-001` | 210.52(E)(3) | OK |  | A) 4 | 210.52(E)(3): "Balconies, decks, and porches that are ..." |  |
| `open-book-exam-#11-002` | 408.7 | OK |  | B) identified | 408.7: "Unused openings for circuit breakers and ..." |  |
| `open-book-exam-#11-003` | Article 100 | OK |  | A) outlet | Article 100 Outlet: "A point on the wiring system ..." |  |
| `open-book-exam-#11-004` | 210.6(A) | OK |  | A) 120 | 210.6(A): "the voltage shall not exceed 120 ..." |  |
| `open-book-exam-#11-005` | 352.10 | OK |  | B) cold | 352.10 Informational Note: "Extreme cold may cause some nonmetallic ..." |  |
| `open-book-exam-#11-006` | 215.9 | OK |  | B) readily accessible | 215.9: "protected by a listed ground-fault circuit ..." |  |
| `open-book-exam-#11-007` | 250.194(A) | OK |  | D) 16 | 250.194(A): "If metal fences are located within ..." |  |
| `open-book-exam-#11-008` | 242.12 | OK |  | D) 1000 | 242.12: "An SPD device shall not be ..." |  |
| `open-book-exam-#11-009` | 382.15(A) | OK |  | A) 2" | 382.15(A): "run in any direction from an ..." |  |
| `open-book-exam-#11-010` | 334.10 | OK |  | D) all of these | 334.10(2): "Multi-family dwellings and their detached garages ..." |  |
| `open-book-exam-#11-011` | 230.46 | OK |  | C) service | 230.46: "Power distribution blocks installed on service ..." | Stem says 'main disconnecting equipment'; code says 'service equipment'. Minor. |
| `open-book-exam-#11-012` | Article 100 | OK |  | B) three | Article 100 Dwelling, Multifamily: "A building that contains three or ..." |  |
| `open-book-exam-#11-013` | 700.5(F) | OK |  | A) field marked | 700.5(F): "shall be field marked on the ..." |  |
| `open-book-exam-#11-014` | 422.13 | OK |  | D) continuous load | 422.13: "shall have an ampere rating of ..." |  |
| `open-book-exam-#11-015` | 230.95(C) | OK |  | D) when first installed on site | 230.95(C): "The ground-fault protection system shall be ..." |  |
| `open-book-exam-#11-016` | 210.25(B) | OK |  | A) dwelling unit | 210.25(B): "shall not be supplied from equipment ..." |  |
| `open-book-exam-#11-017` | 410.54(C) | OK |  | B) listed | 410.54(C): "Pendant conductors longer than 900 mm ..." |  |
| `open-book-exam-#11-018` | 408.6 | OK |  | D) all of these | 408.6: "Switchboards, switchgear, and panelboards...In other than ..." |  |
| `open-book-exam-#11-019` | 220.57 | OK |  | D) 7,200 | 220.57: "The EVSE load shall be calculated ..." |  |
| `open-book-exam-#11-020` | 250.52(A)(4) | OK |  | D) #2 | 250.52(A)(4): "at least 6.0 m (20 ft) ..." |  |
| `open-book-exam-#11-021` | 406.12 | OK |  | D) all of these | 406.12(1): "All dwelling units...including their attached and ..." |  |
| `open-book-exam-#11-022` | 430.102(B) | OK |  | C) lockable | 430.102(B) Exception: "shall not be required...if the motor ..." |  |
| `open-book-exam-#11-023` | 314.16(B)(4) | OK |  | B) two | 314.16(B)(4): "a double volume allowance...shall be made ..." |  |
| `open-book-exam-#11-024` | 450.13(B) | OK |  | A) 50 | 450.13(B): "Dry-type transformers 1000 volts, nominal, or ..." |  |
| `open-book-exam-#11-025` | 332.30 | OK |  | D) 6 feet | 332.30: "Type MI cable shall be supported ..." |  |
| `open-book-exam-#12-001` | 300.25 | OK |  | D) AHJ | 300.25: "only electrical wiring methods serving equipment ..." |  |
| `open-book-exam-#12-002` | 691.9 | OK |  | C) not be required to | 691.9: "Buildings whose sole purpose is to ..." |  |
| `open-book-exam-#12-003` | 514.11(A) | OK |  | A) grounded | 514.11(A): "shall disconnect simultaneously from the source ..." |  |
| `open-book-exam-#12-004` | 700.10(B) | OK |  | A) emergency | 700.10(B): "Wiring from an emergency source...to emergency ..." | TIP's 701.10 reference verified: 701.10(A) permits legally required standby wiring in same raceways as general wiring. |
| `open-book-exam-#12-005` | 230.2(C) | OK |  | C) 2,000 | 230.2(C)(1): "Where the capacity requirements are in ..." |  |
| `open-book-exam-#12-006` | 110.9 | OK |  | B) interrupting | 110.9: "shall have an interrupting rating at ..." |  |
| `open-book-exam-#12-007` | 705.50 | OK |  | D) island mode | 705.50: "Microgrid systems shall be permitted to ..." |  |
| `open-book-exam-#12-008` | 300.21 | OK |  | D) all of these | 300.21: "penetrations into or through fire-resistant-rated walls ..." |  |
| `open-book-exam-#12-009` | 690.31(B)(1) | OK |  | D) all of these | 690.31(B)(1): "PV system dc circuits shall not ..." | Exceptions (e.g., (2) inverter output circuits in same junction box/wireway when grouped) exist; stem's general rule is fine. |
| `open-book-exam-#12-010` | 110.15 | OK |  | D) other effective means | 110.15: "marked by an outer finish that ..." |  |
| `open-book-exam-#12-011` | 695.7(D) | OK | FIXED (explanation only) | C) 5 | 695.7(D): "shall not drop more than 5 ..." | FIXED explanation: tip said 5% 'at the motor terminals'; 695.7(D) says 'at the contactor load terminals'. / TIP says 5% 'at the motor terminals'; 695.7(D) measures at the contactor (controller) load terminals. Minor wording fix. |
| `open-book-exam-#12-012` | 225.26 | OK |  | C) overhead conductor spans | 225.26: "Vegetation such as trees shall not ..." |  |
| `open-book-exam-#12-013` | 694.7(D) | OK |  | A) surge protective device | 694.7(D): "A listed surge protective device shall ..." |  |
| `open-book-exam-#12-014` | 410.10(C) | OK |  | D) exhaust vapors | 410.10(C)(2): "constructed so that all exhaust vapors ..." |  |
| `open-book-exam-#12-015` | Article 100 | OK |  | D) electronic power converter | Article 100 Electronic Power Converter: "A device that uses power electronics ..." |  |
| `open-book-exam-#12-016` | 344.14 | OK |  | A) severe corrosive influences | 344.14(3): "Steel (galvanized, painted, powder or PVC ..." |  |
| `open-book-exam-#12-017` | 690.12(B)(1) | OK |  | D) 30 | 690.12(B)(1): "Controlled conductors located outside the boundary...shall ..." |  |
| `open-book-exam-#12-018` | 392.80(A)(3) | OK |  | C) 100 | 392.80(A)(3): "...the single-conductor cable fill area as ..." |  |
| `open-book-exam-#12-019` | 706.9 | OK |  | A) output | 706.9: "The maximum voltage of an ESS ..." |  |
| `open-book-exam-#12-020` | 336.120 | OK |  | D) thermocouple extension | 336.120: "There shall be no voltage marking ..." |  |
| `open-book-exam-#12-021` | 360.20(B) | OK |  | B) 3/4" | 360.20(B): "The maximum size of FMT shall ..." |  |
| `open-book-exam-#12-022` | 358.30(A) | OK |  | B) 5' | 358.30(A) Exception No. 1: "Fastening of unbroken lengths shall be ..." |  |
| `open-book-exam-#12-023` | 250.122(A) | OK |  | C) #12 | 250.122(A): "The equipment grounding conductor shall not ..." | Table 250.122: 30 A falls in the 60 A row (10 AWG Cu); capped at 12 AWG circuit conductors. 250.122(D)(1) routes motor circuits to 250.122(A). |
| `open-book-exam-#12-024` | 240.21(B)(4) | OK |  | D) 100 feet | 240.21(B)(4): "The tap conductors are not over ..." | Stem omits 'over 35 ft high at walls' qualifier; answer still clear. |
| `open-book-exam-#12-025` | 225.18 | OK |  | B) 10 | 225.18(1): "3.0 m (10 ft) - above ..." | Stem lacks the 150 V/pedestrian condition but asks for the minimum; 10 ft is the lowest listed clearance. |
| `ne-state-act-#3-001` | Neb. Rev. Stat. 81-2108(2) and 81-2113(2) | N/A (state law / non-NEC) |  | C) 3 | State statute; REF quotes 81-2113(2) ratio of three apprentices per licensee. Key 3 consistent. |  |
| `ne-state-act-#3-002` | Neb. Rev. Stat. 81-2113(2) and 81-2113(3) | N/A (state law / non-NEC) |  | D) none | State statute; REF: apprentice 'shall do no electrical wiring except under the direct personal on-the-job supervision'. Key 'none' consistent. |  |
| `ne-state-act-#3-003` | Neb. Rev. Stat. 81-2113(2) | N/A (state law / non-NEC) |  | B) 9 | State statute; 3 licensees x 3 apprentices = 9. Math checks. |  |
| `ne-state-act-#3-004` | Title 100 NAC Rule 13 | N/A (state law / non-NEC) |  | D) all of these | Board rule; REF lists rough-in, final, and correction-order re-inspections as contractor's notification duty. Key 'all of these' consistent. |  |
