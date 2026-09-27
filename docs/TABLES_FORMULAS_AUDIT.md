# Tables & Formulas Audit — NEC 2023

Scope: every `reference_table`, table-titled `reference_text`, `formula` and `worked` solution in
`question_bank.json` (279 records; 25 with a `reference_table`, 18 with a formula). NEC 2023 is the
authority. Stems (`prompt`), choices (`answers`) and `correct_index` were not touched — see
*Verification*.

All fixes go through `tools/pipeline/question_bank_overrides.json` (plus one builder string in
`tools/pipeline/build_question_bank.py`) and a candidate build; the bank was never hand-edited.

## Sources and how each edition was used

| Tag | Source | Edition | Use |
|---|---|---|---|
| **UC** | UpCodes viewer, `https://up.codes/viewer/nfpa/nfpa-70-2023/...` (the URLs the bank links to) | 2023 | **Login-gated.** The page's `__NEXT_DATA__` has `"missingRequiredLogin":true` for NFPA 70 2023 and 2020; no code text is served without an account, and none was created. The `/s/` SEO pages are AI summaries that mix editions, so they were not used as evidence. |
| **N23** | *NFPA 70 National Electrical Code 2023* — public OCR copy on studylib.net (Chapters 1–2, through ~Article 235) | **2023** | Primary evidence for Articles 110–250. |
| **FD26** | NFPA A2025-cycle CMP-6 First Draft working draft (docinfofiles.nfpa.org) | 2026 draft quoting the 2023 baseline text | Article 310 table titles, notes and values shown as unchanged baseline text. |
| **SD26-8** | NFPA A2025-cycle CMP-8 Second Draft working draft (docinfofiles.nfpa.org) | 2026 draft quoting the 2023 baseline | Article 344/348/352 table names. |
| **T23** | 2023-labelled trade sources: EC&M 2023 NEC quiz (ecmweb.com), FastTrax 2023 NEC answer key, electricallicenserenewal.com 2023 NEC Chapter 9 notes | 2023 (secondary) | Table 344.30(B), Table 352.30(B), Chapter 9 Note (4) wording. |
| **N20** | 2020 NEC text (Articles 400–630 excerpt) | 2020 | Used only where no 2023 source was available; such items are marked **Unconfirmed for 2023**. |
| **N14** | 2014 NEC Article 220 (MADCAD) | 2014 | History only (2017→2023 renumbering). |

Status meanings:

- **Verified 2023**: the value was matched against N23 (the 2023 text itself).
- **Verified 2023 (secondary)**: the value was matched against T23, or against an NFPA 2026 draft's unchanged baseline text.
- **Unconfirmed for 2023**: the only text available was another edition; the item is flagged, not treated as verified.

## Tables

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
| **517.73(A)** (open-book-exam-#7-004) | **Unconfirmed for 2023.** N20 has a biplane 100%-momentary sentence under (A)(2) Feeders; a 2026 public comment (PC 961) rewrites the section without it. | The formula ("biplane uses 100% of momentary") contradicted both the reference text and the tip ("2023 no longer has a biplane rule"); neither claim could be checked against 2023. | The formula now restates the reference text: not less than 50% of the momentary rating or 100% of the long-time rating, whichever is greater. The tip no longer makes the unverified edition claim. The keyed answer "momentary" holds either way. |

### Renumbering between 2017 and 2023 (for readers of older study material)

- Table 310.15(B)(16) became **Table 310.16**, and 310.15(B)(3)(a) became **Table 310.15(C)(1)**.
- The dwelling service table of 310.15(B)(7) became **Table 310.12(A)**.
- Table 220.12 (general lighting) became **Table 220.42(A)**, and Table 220.42 (lighting demand factors) became **Table 220.45**.
- Table 344.30(B)(2) became **Table 344.30(B)**.
- Table 352.30 became **Table 352.30(B)**.
- Table 630.31(A)(2) became **Table 630.31(A)** (renamed in 2020; 2023 unconfirmed).
- Table 220.54's values did not change. The bank's 80/75/70% rows were simply wrong.

### Brief items not present in the bank

There are no questions on box fill (314.16(B)), conduit-fill calculations, 250.102(C)(1), Article 358 (EMT) tables, or 430.248. Nothing was added, because stems must come from the source PDFs.

## Formulas and worked solutions

`tools/pipeline/check_worked_solutions.py` (new) holds the NEC 2023 table constants and recomputes the keyed answer for 30 records from first principles. It also re-evaluates every arithmetic chain ("a × b = c", percent forms, and unit-bearing chains) found in `formula`, `worked`, `reference_text`, `tip_short`, `info_tip` and `choice_notes`.

- The 30 recomputed records cover lighting loads, dryer and range demand, EGC sizing, ampacity derating, motor FLC, welder duty cycle, busbar capacity, receptacle loads, FMC fill, PVC support, and Chapter 9 resistance.
- 2 records have non-numeric formulas: final-exam-#3-069 and open-book-exam-#7-004.
- Result on the final bank: `recomputed: 30, arithmetic chains evaluated: 24, RESULT: PASS`.

Formula text changed in: final-exam-#3-026, #3-040, #3-063, #5-039, and open-book-exam-#7-004 (all described above). The #3-040 worked solution changed from "√0.15 ≈ 0.39 …" to "Table 630.31(A): 15% → 0.39; 21 × 0.39 = 8.19 A".

## Spoken-text changes (for the voice agent — clips were not regenerated)

| Record | Fields |
|---|---|
| final-exam-#1-040, open-book-exam-#4-015 | `tip_short`, `choice_notes` (A–C), `info_tip` |
| final-exam-#3-040 | `tip_short`, `choice_notes` (B), `formula`, `worked` |
| final-exam-#3-053 | `tip_short`, `choice_notes` (C) |
| open-book-exam-#7-004 | `tip_short`, `formula` |
| final-exam-#3-026, #3-063, #5-039 | `formula` |
| final-exam-#1-021, #1-067, #3-017, #3-052 | `reference_text` |
| final-exam-#1-004, #1-009, #1-010, #3-016, #3-065; open-book-exam-#1-003, #1-021, #7-015, #7-018, #7-024, #10-002 | `info_tip` (Table 220.45 tiers) |

## Verification

- **Candidate build** (Git Bash, written to `WIRE_BANK_OUT`): passed validation with 0 errors and 0 warnings before being copied over `question_bank.json`.
- **Field diff vs the pre-change bank:** only the 26 records and fields listed above changed.
- **Stem / choice / key hash**: SHA-256 over `(id, prompt, answers, correct_index)` for all 279 records.
  - Before: `67fd8475769cde14c4f4a532e67c5c3d10208538b215293f98489411c7f07ecb`
  - After: the same hash, so stems, choices and keys are **unchanged**.
- **Highlight probe** (`TableViewer` matcher):
  - Every changed table highlights exactly the answer cell (220.54 "85%", 250.122 "10", 430.37 "Three*", Note (4) "60%").
  - 310.16, 220.42(A) and 630.31(A) highlight no cell, instead of a wrong one.
- **Fit check** (`.audit_tmp/measure_fit.gd`): 0% of the 279 records need scrolling, before or after answering, on desktop (1280×720) and mobile (540×960).
- `python tools/pipeline/validate_question_bank.py --no-warn`: VALID, 0 errors, 0 warnings.
- `bash tools/verify.sh` (Git Bash): all 5 stages passed.
- **Screenshots** (desktop and mobile, before and after answering) are in `.audit_tmp/tf/shots/`, taken with `.audit_tmp/tf/snap_tables.gd`. They cover #1-040, #1-068, #1-014, #3-052, #1-067, #1-004, #1-021 and #3-040, and confirm that ², ¾ and φ render.
