# NEC 2023 content audit

Audit date: 2026-09-28. Source: NFPA 70 (NEC) 2023 on UpCodes Premium (https://up.codes/viewer/nfpa/nfpa-70-2023). Every NEC-bank record (279) was checked against the 2023 text:

1. The keyed answer is correct under 2023.
2. The provision (`reference_text`) is 2023 wording with the right subsection labels.
3. The per-choice notes are accurate and cite 2023 sections.
4. The memory tip is accurate.
5. The stem uses 2023 terminology.
6. Every cited section exists in 2023 under that heading.

The full 2023 text was cached locally, outside the repository, and every provision line was compared to it by script. Each record was then reviewed by hand. Only the short excerpts the questions already show are committed. Fixes go through `tools/pipeline/question_bank_overrides.json`.

## Summary

| Status | Records |
|---|---|
| verified | 196 |
| fixed | 58 |
| flagged | 2 |
| non_nec | 23 |
| total | 279 |

The 4 Nebraska state-law records are outside the NEC bank and are not part of this audit.

**Answer changes: none.** No keyed answer is wrong under NEC 2023. The existing key corrections still hold: `final-exam-#5-052` (368.17(B)) and `open-book-exam-#10-002` (220.5(C)) are overrides of PDF key errors, and the PDF key for `final-exam-#5-003` (Article 100, Type MC cable) was re-checked. All three verified.

## Priority items

- **#1-027, 105–113 °F band.** The Table 310.15(B)(1)(1) 41–45 °C / 105–113 °F row is 0.71 / 0.82 / 0.87 for 60 / 75 / 90 °C, so 40 A × 0.87 = 34.8 A is right. The table header in the provision was restored.
- **TYPO_FIXES medium-confidence provisions (50).** Each was compared with the 2023 text. Those still paraphrased, truncated or on 2020 wording were fixed (see below). The rest verified.
- **LOCATION_AUDIT sections the automated pass did not match.** All 34 sections and 10 tables on that list exist in 2023 under the cited headings (for example 210.8(E) Equipment Requiring Servicing, 110.26(B) Clear Spaces, 590.4(G) Splices). The 620.51(D) question is settled: 2023 has no driving-machine numbering rule (see the flags below).

## Flagged for a human

- `final-exam-#1-029` (408.5): UpCodes heading reads '408.5 Clearance for Conductor Entering Bus Enclosures' (singular) while its Table 408.5 title says 'Conductors'. Record keeps 'Conductors'; confirm against the printed code. https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#408
- `final-exam-#3-068` (620.51): Tests the 2020 620.51(D)(1) 'More Than One Driving Machine' numbering rule. 2023 620.51(D) has only (1) Available Fault Current Field Marking and Article 620 has no driving-machine numbering rule. Keyed answer cannot be re-anchored to 2023 text without changing it; retire or rewrite (human decision). https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment#620

## Notable fixes

- `open-book-exam-#7-004`: [article, choice_notes, formula, gist, lookup_summary, prompt, reference_text, tip_short] The 2020 517.73(A)(2) biplane sentence ('100 percent of the momentary demand rating') is not in 2023. Stem rewritten to the 2023 517.73(B) feeder rule (50/25/10 percent of the momentary demand rating); keyed answer 'momentary' unchanged. Provision, notes, formula, tip and gist updated.
- `open-book-exam-#1-012`: [article, choice_notes, gist, lookup_summary, prompt, reference_text] 2023 splits 210.8(B)(2) Kitchens from (3) 'Areas with sinks and permanent provisions for food preparation, beverage preparation, or cooking'. Article now 210.8(B)(3); stem uses the 2023 wording, key unchanged.
- `final-exam-#3-015`: [gist, prompt, reference_text] 2023 240.33 dropped 'unless that is shown to be impracticable'. Removed it from the stem and provision; key unchanged.
- `open-book-exam-#10-019`: [prompt, tip_short] 517.18 is 'Category 2 Spaces' in 2023; stem and tip use that term, key unchanged.
- `final-exam-#5-070`: [article, lookup_summary, reference_table, reference_text] 2023 numbers the table 'Table 352.30(B)'. Article, provision, table note and lookup updated.
- `final-exam-#3-052`: [choice_notes, reference_text, tip_short] Table 430.37: 2023 row reads "3-phase ac / Any 3-phase / 3, one in each phase*" and the footnote is "*Exception: An overload unit in each phase shall not be required where overload protection is provided by other approved means."
- `final-exam-#3-053`: [choice_notes, reference_table, reference_text, tip_short] 344.30(B)(2): 2023 text refers to "Table 344.30(B)" (not 344.30(B)(2)) and reads "provided the conduit is made up with threaded couplings and supports that prevent transmission of stresses".
- `open-book-exam-#7-010`: [reference_text] 424.36: 2023 last sentence ends "it shall be subject to the ambient correction in accordance with 310.15(B)(1)"; the record's "the wiring shall not require correction for temperature" is 2020 text and states the opposite.
- `final-exam-#1-012`: [choice_notes, reference_text] 210.8(A) (2023) intro reads "installed in the following locations and supplied by ... for personnel:" (record had "specified in 210.8(A)(1) through (A)(12)").
- `final-exam-#5-036`: [reference_text] 352.60 heading is 'Grounding' in 2023. UpCodes prints 'separate grounding conductor' without 'a'; the word 'a' was kept, as in the parallel 353.60, 355.60 and 356.60.

## Per-record status

Key: `verified` means no change was needed. `fixed` means explanation fields changed (listed in brackets); no key changed. `non_nec` means General knowledge, General calculation or NFPA 70E items, reviewed for accuracy. The URL is the UpCodes 2023 article anchor.

| Record | Cited | Status | Note | 2023 source |
|---|---|---|---|---|
| `final-exam-#1-002` | 408.18(C) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#408 |
| `final-exam-#1-003` | 210.63(B)(1) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `final-exam-#1-004` | Table 220.42(A) | fixed | [reference_table, reference_text] Table 220.42(A) note completed ('..., therefore no additional multiplier shall be required') and header aligned to the 2023 table. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#220 |
| `final-exam-#1-006` | 590.5 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/5/special-occupancies#590 |
| `final-exam-#1-008` | 210.52(E)(3) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `final-exam-#1-009` | 310.6(C) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#310 |
| `final-exam-#1-010` | 220.14(H) | fixed | [reference_text] 220.14(H) (2023): intro ends "shall be calculated in accordance with the following:"; the permissive sentence follows the list and ends "portion that contains receptacles." Record had non-2023 wording. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#220 |
| `final-exam-#1-011` | 210.52(A)(2) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `final-exam-#1-012` | 210.8(A)(2) | fixed | [choice_notes, reference_text] 210.8(A) (2023) intro reads "installed in the following locations and supplied by ... for personnel:" (record had "specified in 210.8(A)(1) through (A)(12)"). | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `final-exam-#1-014` | Table 310.16 | fixed | [reference_text] Table 310.16: record rewrote the row as prose and marked notes with "*"; 2023 notes are numbered "1."/"2." Replaced with verbatim header/row/notes. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#310 |
| `final-exam-#1-015` | 225.6(B) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#225 |
| `final-exam-#1-016` | 590.4(J) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/5/special-occupancies#590 |
| `final-exam-#1-018` | 620.61(B)(1) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment#620 |
| `final-exam-#1-019` | General knowledge | non_nec | Not an NEC question (General knowledge); explanation reviewed for accuracy. |  |
| `final-exam-#1-020` | 250.53(A)(3) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#250 |
| `final-exam-#1-024` | 680.58 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment#680 |
| `final-exam-#1-026` | Table 310.4(1) | fixed | [reference_text] Table 310.4(1): record's provision line was a paraphrase sentence, not NEC text; replaced with the table rows (RHW 75°C vs RHW-2 90°C, dry and wet locations). | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#310 |
| `final-exam-#1-027` | Table 310.15(B)(1)(1) | fixed | [reference_text] Table 310.15(B)(1)(1): record merged two header rows and omitted "Temperature Rating of Conductor"; restored header and the table's instruction sentence. Values unchanged. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#310 |
| `final-exam-#1-028` | 514.11(A) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/5/special-occupancies#514 |
| `final-exam-#1-029` | 408.5 | flagged | UpCodes heading reads '408.5 Clearance for Conductor Entering Bus Enclosures' (singular) while its Table 408.5 title says 'Conductors'. Record keeps 'Conductors'; confirm against the printed code. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#408 |
| `final-exam-#1-030` | 424.20(A)(3) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#424 |
| `final-exam-#1-032` | 240.21(B)(1) | fixed | [reference_text] 240.21(B)(1)(1) (2023) reads "The ampacity of the tap conductors is as follows:" and items a./b. have no ", and"/final period (record had 2020 wording). | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#240 |
| `final-exam-#1-033` | General knowledge | non_nec | Not an NEC question (General knowledge); explanation reviewed for accuracy. |  |
| `final-exam-#1-034` | Table 400.4 | fixed | [reference_text] Provision replaced by Table 400.4 Note 9 (the 'W' suffix note) instead of a paraphrase. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#400 |
| `final-exam-#1-036` | 310.12(A) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#310 |
| `final-exam-#1-037` | 392.100(F) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#392 |
| `final-exam-#1-041` | General knowledge | non_nec | Not an NEC question (General knowledge); explanation reviewed for accuracy. |  |
| `final-exam-#1-042` | 406.9(B) | fixed | [reference_text] 406.9(B)(1) excerpt aligned with open-book-exam-#4-014 (both sentences of (B)(1)). | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#406 |
| `final-exam-#1-043` | 680.43(B)(1)(a) | fixed | [reference_text] 680.43(B)(1)(c)(2): 2023 reads "a metallic body isolated from contact" (record had "metal body"). | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment#680 |
| `final-exam-#1-044` | Article 100 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#100 |
| `final-exam-#1-045` | 422.16(B)(1)(1) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#422 |
| `final-exam-#1-046` | General knowledge | non_nec | Not an NEC question (General knowledge); explanation reviewed for accuracy. |  |
| `final-exam-#1-048` | 406.12(1) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#406 |
| `final-exam-#1-049` | Table 300.5(A) | fixed | [reference_text] Table 300.5(A) Column 1 row quoted in table form (same excerpt in #4-004 and #7-013). | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#300 |
| `final-exam-#1-050` | 800.44(B) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/8/communications-systems#800 |
| `final-exam-#1-056` | 430.42(C) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#430 |
| `final-exam-#1-057` | 110.26(E)(1) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#110 |
| `final-exam-#1-058` | 450.11(A) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#450 |
| `final-exam-#1-059` | 210.18 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `final-exam-#1-060` | 680.11(A) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment#680 |
| `final-exam-#1-062` | General knowledge | non_nec | Not an NEC question (General knowledge); explanation reviewed for accuracy. |  |
| `final-exam-#1-065` | General knowledge | non_nec | Not an NEC question (General knowledge); explanation reviewed for accuracy. |  |
| `final-exam-#1-066` | 330.30(D)(2) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#330 |
| `final-exam-#1-068` | Table 250.122 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#250 |
| `final-exam-#1-070` | Table 430.250 | fixed | [reference_text] Table 430.250: record rewrote the row as prose ("Horsepower: 50 // ... 230 Volts: 130; 460 Volts: 65"); replaced with verbatim header, the 40 and 50 hp rows (distractors 104/52/41 come from them), and the table's sentence allowing 440 to 480 V systems to use the 460 V column. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#430 |
| `final-exam-#3-001` | 406.6(D) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#406 |
| `final-exam-#3-004` | 392.10(E) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#392 |
| `final-exam-#3-005` | 424.101(A) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#424 |
| `final-exam-#3-006` | 210.8(C) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `final-exam-#3-008` | 500.5(D)(2) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/5/special-occupancies#500 |
| `final-exam-#3-009` | 430.101 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#430 |
| `final-exam-#3-010` | Article 100 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#100 |
| `final-exam-#3-011` | NFPA 70E | non_nec | Not an NEC question (NFPA 70E); explanation reviewed for accuracy. |  |
| `final-exam-#3-012` | General knowledge | non_nec | Not an NEC question (General knowledge); explanation reviewed for accuracy. |  |
| `final-exam-#3-013` | 358.30(A) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#358 |
| `final-exam-#3-014` | Table 210.21(B)(2) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `final-exam-#3-015` | 240.33 | fixed | [gist, prompt, reference_text] 2023 240.33 dropped 'unless that is shown to be impracticable'. Removed it from the stem and provision; key unchanged. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#240 |
| `final-exam-#3-017` | Table 250.122 | fixed | [reference_text] Table 250.122: header column "Copper (AWG)" / "Aluminum ... (AWG)" is not NEC wording; 2023 header is "Size (AWG or kcmil)" over Copper / Aluminum or Copper-Clad Aluminum. Values unchanged (same form as final-exam-#1-068). | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#250 |
| `final-exam-#3-018` | 440.64 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#440 |
| `final-exam-#3-019` | 430.102(B)(1) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#430 |
| `final-exam-#3-020` | 810.13 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/8/communications-systems#810 |
| `final-exam-#3-021` | NFPA 70E | non_nec | Not an NEC question (NFPA 70E); explanation reviewed for accuracy. |  |
| `final-exam-#3-023` | 522.21(B) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/5/special-occupancies#522 |
| `final-exam-#3-024` | 225.39(B) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#225 |
| `final-exam-#3-025` | 240.10 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#240 |
| `final-exam-#3-026` | 626.11(A) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment#626 |
| `final-exam-#3-027` | 250.66(B) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#250 |
| `final-exam-#3-028` | 422.5(A) | verified | UpCodes 422.5(A) lacks 'rated' before '150 volts or less to ground'; record kept (confirm in print). | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#422 |
| `final-exam-#3-029` | Article 100 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#100 |
| `final-exam-#3-030` | 430.9(C) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#430 |
| `final-exam-#3-031` | 800.44 | fixed | [reference_text] 800.44(B) Exception No. 2 (2023) ends "terminated at a through- or above-the-roof raceway or approved support" (record omitted "or above-"). | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/8/communications-systems#800 |
| `final-exam-#3-032` | Article 100 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#100 |
| `final-exam-#3-034` | 314.24(B)(5) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#314 |
| `final-exam-#3-037` | 354.28 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#354 |
| `final-exam-#3-038` | 430.52(B) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#430 |
| `final-exam-#3-039` | 422.12 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#422 |
| `final-exam-#3-041` | NFPA 70E | non_nec | Not an NEC question (NFPA 70E); explanation reviewed for accuracy. |  |
| `final-exam-#3-043` | NFPA 70E | non_nec | Not an NEC question (NFPA 70E); explanation reviewed for accuracy. |  |
| `final-exam-#3-044` | 647.4(D) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment#647 |
| `final-exam-#3-045` | General knowledge | non_nec | Not an NEC question (General knowledge); explanation reviewed for accuracy. |  |
| `final-exam-#3-047` | 230.54(B) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#230 |
| `final-exam-#3-049` | 210.63 | fixed | [reference_text] 210.63(B)(2): 2023 text ends "shall not be connected to the load side of the equipment's disconnecting means" (record had "branch-circuit disconnecting means"). | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `final-exam-#3-050` | 250.68(B) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#250 |
| `final-exam-#3-051` | 550.32(F) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/5/special-occupancies#550 |
| `final-exam-#3-056` | 225.39(A) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#225 |
| `final-exam-#3-057` | 310.15(F) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#310 |
| `final-exam-#3-058` | Article 100 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#100 |
| `final-exam-#3-060` | 480.10(A) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#480 |
| `final-exam-#3-061` | 430.12(A) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#430 |
| `final-exam-#3-062` | General knowledge | non_nec | Not an NEC question (General knowledge); explanation reviewed for accuracy. |  |
| `final-exam-#3-063` | 366.23(A) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#366 |
| `final-exam-#3-064` | 210.8(A) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `final-exam-#3-066` | 250.50 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#250 |
| `final-exam-#3-067` | 440.55(B) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#440 |
| `final-exam-#3-068` | 620.51 | flagged | Tests the 2020 620.51(D)(1) 'More Than One Driving Machine' numbering rule. 2023 620.51(D) has only (1) Available Fault Current Field Marking and Article 620 has no driving-machine numbering rule. Keyed answer cannot be re-anchored to 2023 text without changing it; retire or rewrite (human decision). | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment#620 |
| `final-exam-#3-069` | 430.62(A) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#430 |
| `final-exam-#5-001` | 324.41 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#324 |
| `final-exam-#5-002` | 320.80(A) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#320 |
| `final-exam-#5-004` | 324.40(D) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#324 |
| `final-exam-#5-006` | 320.30(D)(2) | fixed | [reference_text] 320.30(D)(2) is cited: list labels (1)-(3) restored in NEC order (item 2 = 600 mm (2 ft) at terminals); text unchanged. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#320 |
| `final-exam-#5-007` | Article 100 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#100 |
| `final-exam-#5-008` | 330.104 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#330 |
| `final-exam-#5-017` | 332.10(7) | fixed | [reference_text] 332.10(7) is cited: list labels (1)-(11) restored in NEC order (item 7 = hazardous (classified) locations); text unchanged. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#332 |
| `final-exam-#5-018` | 340.80 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#340 |
| `final-exam-#5-020` | 332.104, 332.108, and 332.116 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#332 |
| `final-exam-#5-021` | 338.10(B)(3) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#338 |
| `final-exam-#5-022` | 338.100 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#338 |
| `final-exam-#5-023` | 336.24 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#336 |
| `final-exam-#5-032` | 348.22 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#348 |
| `final-exam-#5-033` | 344.120 | fixed | [tip_short] Tip claimed 110.21(A) uses the same wording; 110.21(A)(1) does not say "clearly and durably" — 344.120 only refers to the first sentence of 110.21(A). | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#344 |
| `final-exam-#5-034` | 358.14 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#358 |
| `final-exam-#5-036` | 352.100, 352.12(B), and 352.60 | fixed | [reference_text] 352.60 heading is 'Grounding' in 2023. UpCodes prints 'separate grounding conductor' without 'a'; the word 'a' was kept, as in the parallel 353.60, 355.60 and 356.60. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#352 |
| `final-exam-#5-037` | 358.100 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#358 |
| `final-exam-#5-038` | 350.12 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#350 |
| `final-exam-#5-039` | 366.23(A) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#366 |
| `final-exam-#5-050` | 368.234(A) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#368 |
| `final-exam-#5-051` | 370.10 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#370 |
| `final-exam-#5-052` | 368.17(B) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#368 |
| `final-exam-#5-053` | 384.30(A) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#384 |
| `final-exam-#5-054` | 395.30(A) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#395 |
| `final-exam-#5-069` | 334.30(B)(2) | fixed | [reference_text] 334.30(B)(2) is cited: list labels (1)-(2) restored in NEC order; text unchanged (4 1/2 fraction spacing per cache artifact rule). | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#334 |
| `final-exam-#1-001` | General knowledge | non_nec | Not an NEC question (General knowledge); explanation reviewed for accuracy. |  |
| `final-exam-#1-022` | 210.52(G)(1) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `final-exam-#3-042` | 422.33 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#422 |
| `final-exam-#1-031` | 210.52(H) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `final-exam-#1-035` | 250.52(A)(2) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#250 |
| `final-exam-#1-054` | 400.13 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#400 |
| `final-exam-#3-052` | Table 430.37 | fixed | [choice_notes, reference_text, tip_short] Table 430.37: 2023 row reads "3-phase ac / Any 3-phase / 3, one in each phase*" and the footnote is "*Exception: An overload unit in each phase shall not be required where overload protection is provided by other approved means." | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#430 |
| `final-exam-#3-053` | 344.30(B)(2) | fixed | [choice_notes, reference_table, reference_text, tip_short] 344.30(B)(2): 2023 text refers to "Table 344.30(B)" (not 344.30(B)(2)) and reads "provided the conduit is made up with threaded couplings and supports that prevent transmission of stresses". | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#344 |
| `final-exam-#3-059` | 680.22(A)(2) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment#680 |
| `final-exam-#5-048` | 366.100(E) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#366 |
| `final-exam-#5-049` | 382.15(A) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#382 |
| `final-exam-#5-064` | 470.11 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#470 |
| `final-exam-#5-066` | 356.22 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#356 |
| `final-exam-#5-068` | 344.10(C) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#344 |
| `final-exam-#1-005` | General knowledge | non_nec | Not an NEC question (General knowledge); explanation reviewed for accuracy. |  |
| `final-exam-#1-064` | General knowledge | non_nec | Not an NEC question (General knowledge); explanation reviewed for accuracy. |  |
| `final-exam-#3-065` | 310.12(A) | fixed | [reference_text, tip_short] 310.12(A): record inserted non-Code commentary ("NEC 2023 deleted former Table 310.12 ...") and wrote "100 through 400 amperes"; 2023 text is "For a service rated 100 amperes through 400 amperes ..." and ends "If no adjustment or correction factors are required, Table 310.12(A) shall be permitted to be applied." | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#310 |
| `final-exam-#5-005` | 322.56(B) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#322 |
| `final-exam-#1-040` | Table 220.54 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#220 |
| `final-exam-#1-067` | Chapter 9, Note 4 | fixed | [reference_text] Chapter 9 Notes to Tables Note (4) has no title in 2023; "Conduit and Tubing Nipples" removed from the heading (text unchanged). | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/9/tables |
| `final-exam-#3-003` | 425.22(D) | fixed | [reference_text] 425.22(D): in 2023 the 50 kW provision is a second paragraph ("Where the heaters are rated 50 kW or more, ..."), not an "Exception:"; label removed, text unchanged. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#425 |
| `final-exam-#3-007` | 680.35(D) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment#680 |
| `final-exam-#3-046` | 408.7 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#408 |
| `final-exam-#5-019` | 334.116(B) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#334 |
| `final-exam-#1-025` | 630.12(A) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment#630 |
| `final-exam-#1-047` | General knowledge | non_nec | Not an NEC question (General knowledge); explanation reviewed for accuracy. |  |
| `final-exam-#3-033` | General calculation | non_nec | Not an NEC question (General calculation); explanation reviewed for accuracy. |  |
| `final-exam-#3-048` | Table 348.22 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#348 |
| `final-exam-#3-070` | General knowledge | non_nec | Not an NEC question (General knowledge); explanation reviewed for accuracy. |  |
| `open-book-exam-#1-001` | 210.4(B) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `open-book-exam-#1-002` | Article 100 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#100 |
| `open-book-exam-#1-003` | 220.5(C) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#220 |
| `open-book-exam-#1-004` | 300.4(A)(2) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#300 |
| `open-book-exam-#1-005` | 210.63 | fixed | [reference_text] 210.63(B)(2): 2023 text ends "and shall not be connected to the load side of the equipment's disconnecting means"; the record's "shall not be more than 7.5 m (25 ft) from the equipment" is not in 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `open-book-exam-#1-006` | 404.14(B)(2) | fixed | [reference_text] Citation is list item 404.14(B)(2): restored list labels (1)-(4) in NEC order; text unchanged and verbatim. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#404 |
| `open-book-exam-#1-007` | 408.3(A)(2) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#408 |
| `open-book-exam-#1-008` | 250.53(A)(5) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#250 |
| `open-book-exam-#1-009` | 408.41 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#408 |
| `open-book-exam-#1-010` | 210.8(A)(10) | fixed | [reference_text] 210.8(A): added the governing 2023 lead-in sentence (record listed items with no rule sentence) and restored labels (1)-(12) since the citation is 210.8(A)(10); dropped exceptions not needed for the answer. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `open-book-exam-#1-011` | 110.26(B) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#110 |
| `open-book-exam-#1-012` | 210.8(B)(3) | fixed | [article, choice_notes, gist, lookup_summary, prompt, reference_text] 2023 splits 210.8(B)(2) Kitchens from (3) 'Areas with sinks and permanent provisions for food preparation, beverage preparation, or cooking'. Article now 210.8(B)(3); stem uses the 2023 wording, key unchanged. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `open-book-exam-#1-013` | 220.5(B) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#220 |
| `open-book-exam-#1-014` | 210.8(C) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `open-book-exam-#1-015` | 408.18(C) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#408 |
| `open-book-exam-#1-016` | 210.63(B)(1) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `open-book-exam-#1-017` | 408.19 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#408 |
| `open-book-exam-#1-018` | 210.8(E) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `open-book-exam-#1-019` | 590.4(F) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/5/special-occupancies#590 |
| `open-book-exam-#1-020` | 210.11(C)(2) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `open-book-exam-#1-021` | Table 220.42(A) | fixed | [reference_text] Same Table 220.42(A) excerpt as final-exam-#1-004 (full 2023 note). | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#220 |
| `open-book-exam-#1-022` | 210.50(C) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `open-book-exam-#1-023` | 590.5 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/5/special-occupancies#590 |
| `open-book-exam-#1-024` | 680.21(C) and 680.5(B) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment#680 |
| `open-book-exam-#1-025` | 440.14 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#440 |
| `open-book-exam-#4-001` | Article 100 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#100 |
| `open-book-exam-#4-002` | 210.8(F) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `open-book-exam-#4-003` | 334.12(B)(4) | fixed | [reference_text] Citation is list item 334.12(B)(4): restored list labels (1)-(4) in NEC order; text unchanged and verbatim. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#334 |
| `open-book-exam-#4-004` | Table 300.5(A) Column 1 | fixed | [reference_text] Table 300.5(A) Column 1 row quoted in table form (same excerpt in #1-049 and #7-013). | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#300 |
| `open-book-exam-#4-005` | 406.12(1) | fixed | [reference_text] Citation is 406.12(1): trimmed the list to the cited item with its label; the unlabeled list in the record mixed items (1)-(8) with the (5)a.-c. sub-items, making item numbers unclear. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#406 |
| `open-book-exam-#4-006` | 422.16(B)(1)(1) | fixed | [reference_text] Citation is list item 422.16(B)(1)(1): restored list labels (1)-(4) in NEC order; text unchanged and verbatim. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#422 |
| `open-book-exam-#4-007` | 406.3(E) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#406 |
| `open-book-exam-#4-008` | 210.4(C) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `open-book-exam-#4-009` | Article 100 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#100 |
| `open-book-exam-#4-010` | 590.4(G) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/5/special-occupancies#590 |
| `open-book-exam-#4-011` | 680.43(B)(1)(a) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment#680 |
| `open-book-exam-#4-012` | 210.12(A)(1) | fixed | [reference_text] Citation is list item 210.12(A)(1): restored labels (1) and (2) in NEC order; text unchanged and verbatim. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `open-book-exam-#4-013` | Article 100 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#100 |
| `open-book-exam-#4-014` | 406.9(B) | fixed | [reference_text] 406.9(B)(1): 2023 heading is "Receptacles of 15 Amperes and 20 Amperes in a Wet Location" and the text reads "15 amperes and 20 amperes, 125 volts and 250 volts"; the record's hood sentence ("extra-duty" only at other than one- or two-family dwellings) is 2020 text; replaced with the verbatim 2023 sentences needed for the answer. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#406 |
| `open-book-exam-#4-015` | Table 220.54 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#220 |
| `open-book-exam-#4-016` | 430.8 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#430 |
| `open-book-exam-#4-017` | 340.10(3) | fixed | [choice_notes, reference_text] Citation is list item 340.10(3): restored labels (1)-(6) in NEC order. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#340 |
| `open-book-exam-#4-018` | 312.5(C) Ex. 1 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#312 |
| `open-book-exam-#4-019` | 314.27(D) Ex. | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#314 |
| `open-book-exam-#4-020` | 392.100(F) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#392 |
| `open-book-exam-#4-021` | 210.8(A) Ex. 1 | fixed | [reference_text] 210.8(A): 2023 lead-in reads "installed in the following locations and supplied by"; the record's "installed in the locations specified in 210.8(A)(1) through (A)(12)" is not 2023 text. Trimmed to the lead-in, the Outdoors item (3) and Exception No. 1 that supports the answer. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `open-book-exam-#4-022` | 310.12(A) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#310 |
| `open-book-exam-#4-023` | 210.12(B), (C), and (D) | fixed | [reference_text] 210.12(B): last 2023 item is "Similar areas" (record had "Similar rooms or areas"). | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `open-book-exam-#4-024` | 250.52(A)(2) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#250 |
| `open-book-exam-#4-025` | Table 400.4 and Note 9 | fixed | [reference_text] Provision replaced by Table 400.4 Note 9 (the 'W' suffix note) instead of a paraphrase. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#400 |
| `open-book-exam-#7-001` | 200.3 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#200 |
| `open-book-exam-#7-002` | Table 8, Chapter 9 | fixed | [reference_text] Chapter 9 Table 8: the record's provision line was a summary sentence, not NEC text; replaced with the table heading and verbatim values for the rows already shown in the app table (12 and 10 AWG copper, uncoated). | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/9/tables |
| `open-book-exam-#7-003` | 110.16(A) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#110 |
| `open-book-exam-#7-004` | 517.73(B) | fixed | [article, choice_notes, formula, gist, lookup_summary, prompt, reference_text, tip_short] The 2020 517.73(A)(2) biplane sentence ('100 percent of the momentary demand rating') is not in 2023. Stem rewritten to the 2023 517.73(B) feeder rule (50/25/10 percent of the momentary demand rating); keyed answer 'momentary' unchanged. Provision, notes, formula, tip and gist updated. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/5/special-occupancies#517 |
| `open-book-exam-#7-005` | Article 100 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#100 |
| `open-book-exam-#7-006` | 240.5(B)(4) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#240 |
| `open-book-exam-#7-007` | 708.54 Ex. | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/7/special-conditions#708 |
| `open-book-exam-#7-008` | 110.13(B) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#110 |
| `open-book-exam-#7-009` | 225.39 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#225 |
| `open-book-exam-#7-010` | 424.36 | fixed | [reference_text] 424.36: 2023 last sentence ends "it shall be subject to the ambient correction in accordance with 310.15(B)(1)"; the record's "the wiring shall not require correction for temperature" is 2020 text and states the opposite. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#424 |
| `open-book-exam-#7-011` | 210.19(B) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `open-book-exam-#7-012` | 344.10(A)(3) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#344 |
| `open-book-exam-#7-013` | Table 300.5(A) | fixed | [reference_text] Paraphrase replaced by the Table 300.5(A) title and Column 1 row. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#300 |
| `open-book-exam-#7-014` | Table 300.1(C) | fixed | [reference_text] 300.1(C): 2023 text says "shall be in accordance with Table 300.1(C)", not "shall be as designated in". | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#300 |
| `open-book-exam-#7-015` | 310.15(A) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#310 |
| `open-book-exam-#7-016` | 700.7(A) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/7/special-conditions#700 |
| `open-book-exam-#7-017` | 110.14(C)(2) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#110 |
| `open-book-exam-#7-018` | 210.11(A) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `open-book-exam-#7-019` | 110.12(B) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#110 |
| `open-book-exam-#7-020` | Article 100 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#100 |
| `open-book-exam-#7-021` | 408.36(B) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#408 |
| `open-book-exam-#7-022` | 110.26 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#110 |
| `open-book-exam-#7-023` | 400.36 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#400 |
| `open-book-exam-#7-024` | 408.3(F)(1) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#408 |
| `open-book-exam-#7-025` | 225.37 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#225 |
| `open-book-exam-#10-001` | 547.30 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/5/special-occupancies#547 |
| `open-book-exam-#10-002` | 220.5(C) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#220 |
| `open-book-exam-#10-003` | 406.10(C) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#406 |
| `open-book-exam-#10-004` | 409.21 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#409 |
| `open-book-exam-#10-005` | 300.5(F) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#300 |
| `open-book-exam-#10-006` | Article 100 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#100 |
| `open-book-exam-#10-007` | 314.2 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#314 |
| `open-book-exam-#10-008` | 630.42(C) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment#630 |
| `open-book-exam-#10-009` | Article 100 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#100 |
| `open-book-exam-#10-010` | 225.19(D)(1) and 225.19(D)(3) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#225 |
| `open-book-exam-#10-011` | 810.16(B) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/8/communications-systems#810 |
| `open-book-exam-#10-012` | 724.40 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/7/special-conditions#724 |
| `open-book-exam-#10-013` | 314.23(E) | fixed | [choice_notes, reference_text] Dropped the conduit-body exception (not what the stem tests); choice A note restated from 314.23(E). | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#314 |
| `open-book-exam-#10-014` | 660.9 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment#660 |
| `open-book-exam-#10-015` | 310.3(B)(3) | fixed | [reference_text] 310.3(B): the record omitted the lead-in sentence and its stranded-aluminum line didn't match the cache (the cache reads "Type RHH. RHW"). Trimmed to the lead-in plus item (3), which the citation 310.3(B)(3) points to. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#310 |
| `open-book-exam-#10-016` | 110.26(A)(1) Condition 2 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#110 |
| `open-book-exam-#10-017` | 500.5(D) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/5/special-occupancies#500 |
| `open-book-exam-#10-018` | 406.3(E) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#406 |
| `open-book-exam-#10-019` | 517.18(B)(1) | fixed | [prompt, tip_short] 517.18 is 'Category 2 Spaces' in 2023; stem and tip use that term, key unchanged. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/5/special-occupancies#517 |
| `open-book-exam-#10-020` | 210.52(E)(3) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `open-book-exam-#10-021` | 695.12(D) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment#695 |
| `open-book-exam-#10-022` | 305.4 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#305 |
| `open-book-exam-#10-023` | 551.71(B) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/5/special-occupancies#551 |
| `open-book-exam-#10-024` | Article 100 | fixed | [answers, choice_notes] Choice D spelled out as 'grounding electrode conductor' (Article 100 term); key unchanged. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#100 |
| `open-book-exam-#10-025` | 305.15(E) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#305 |
| `final-exam-#1-007` | 408.19 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#408 |
| `final-exam-#1-013` | General knowledge | non_nec | Not an NEC question (General knowledge); explanation reviewed for accuracy. |  |
| `final-exam-#1-017` | 210.18 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `final-exam-#1-061` | 503.1 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/5/special-occupancies#503 |
| `final-exam-#1-023` | 250.122(F)(1)(b) | fixed | [reference_text] 250.122(F)(1): the item (a) line didn't match the cache, which reads "Single Raceway or Cable Tray, Auxiliary Gutter, or Cable Tray." Dropped item (a) and kept the cited item (b) verbatim. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#250 |
| `final-exam-#1-038` | 340.10(3) | fixed | [choice_notes, reference_text] 340.10 list labels (1)-(6) restored, same excerpt as open-book-exam-#4-017. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#340 |
| `final-exam-#1-052` | 550.32(F) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/5/special-occupancies#550 |
| `final-exam-#1-053` | 225.18(5) | fixed | [reference_text] 225.18 item (5) reads "7.5 m (24 1/2 ft)", not "(24.5 ft)". | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#225 |
| `final-exam-#1-055` | 300.4(D) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#300 |
| `final-exam-#1-063` | General knowledge | non_nec | Not an NEC question (General knowledge); explanation reviewed for accuracy. |  |
| `final-exam-#1-039` | 430.8 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use#430 |
| `final-exam-#1-051` | 110.26(C)(3) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#110 |
| `final-exam-#1-021` | Table 220.55 | fixed | [formula] Formula restated from Table 220.55 Note 1 (Column C plus 5 percent per kW over 12 kW). | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#220 |
| `final-exam-#1-069` | 600.9(C) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment#600 |
| `final-exam-#3-002` | 551.72(B) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/5/special-occupancies#551 |
| `final-exam-#3-022` | General knowledge | non_nec | Not an NEC question (General knowledge); explanation reviewed for accuracy. |  |
| `final-exam-#3-054` | 348.28 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#348 |
| `final-exam-#3-055` | General knowledge | non_nec | Not an NEC question (General knowledge); explanation reviewed for accuracy. |  |
| `final-exam-#3-016` | 310.14(A)(3) | fixed | [reference_text] 310.14(A)(3) Informational Note No. 1 (2023) reads "See Table 310.4(1) and Table 315.10(A) for the temperature rating ..." and has no "allowable" or "ampere ratings"; the record carried the 2020 wording. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#310 |
| `final-exam-#3-035` | 210.50(C) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#210 |
| `final-exam-#3-036` | 240.5(B)(1) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection#240 |
| `final-exam-#3-040` | 630.31(A)(2) | fixed | [choice_notes, reference_text, worked] In 2023, 630.31(A) "Individual Welders" is a list, and the specific-operation rule is unheaded item (2); there is no "630.31(A)(2) Specific Operation" heading. The table is "Table 630.31(A)", not 630.31(A)(2). | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment#630 |
| `final-exam-#5-003` | Article 100 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#100 |
| `final-exam-#5-024` | 334.12(A)(3) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#334 |
| `final-exam-#5-035` | Article 100 | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general#100 |
| `final-exam-#5-055` | 388.12(3) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#388 |
| `final-exam-#5-065` | 376.30(B) | verified | Key, provision, notes, tip and headings match NEC 2023. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#376 |
| `final-exam-#5-067` | 342.30(B)(3) | fixed | [reference_text] 342.30(B) item (2) reads "in accordance with Table 344.30(B), provided ... threaded couplings and supports that prevent" (not Table 344.30(B)(2) / "such supports prevent"). | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#342 |
| `final-exam-#5-070` | Table 352.30(B) | fixed | [article, lookup_summary, reference_table, reference_text] 2023 numbers the table 'Table 352.30(B)'. Article, provision, table note and lookup updated. | https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials#352 |

## Guard

`tools/pipeline/content_audit_2023.json` records status, `verified_on`, sections, URL, `correct_index` and a 16-hex checksum of each record's provision (`reference_text` + `reference_table`). `validate_question_bank.py` reports an error when a provision or key changes without the entry being updated, and a warning when an NEC record has no entry. The file stores no NEC text.
