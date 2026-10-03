# Working audits

Reports written while the app was being built and checked. Each one is a
snapshot of the day it was written: counts, commit hashes and "open" items
describe the repo at that time, and later work may have closed them. The
finished, maintained audits are one folder up (`docs/CONTENT_AUDIT_2023.md`,
`docs/TABLES_FORMULAS_AUDIT.md`, `docs/LOCATION_AUDIT.md`,
`docs/DIAGRAMS_AUDIT.md`); open items that still matter are in
`docs/KNOWN_ISSUES.md`.

No NEC text is stored here. Where a report quotes a provision, the quote is cut
to its first few words; look up the cited section in the code book.

| File | Date | What it is |
|---|---|---|
| [UPCODES_ANSWER_CHECK.md](UPCODES_ANSWER_CHECK.md) | 2026-09-30 | All 598 questions re-checked against the NFPA 70-2023 text: keyed answer, cited section and 2023 wording, one row per question. No key was wrong; the fixes shipped in 1.0.6 (CHANGELOG.md). |
| [hardcoding_audit.md](hardcoding_audit.md) | 2026-09-29 | Where exam names, question counts and the NEC year were written into code, and the plan that moved them into data (`docs/ADDING_EXAMS.md`, `docs/EDITION_MIGRATION.md`). Done in 1.0.5. |
| [diagram_gap_scan.md](diagram_gap_scan.md) | 2026-09-28 | Which of the original 279 NEC questions had no figure but would be easier with one, sorted by tier. Drawn as batches 1 and 2 (`docs/DIAGRAMS_AUDIT.md` sections 8 and 9). |
| [diagram_gap_scan_new.md](diagram_gap_scan_new.md) | 2026-09-29 | The same scan for the 315 questions imported on 2026-09-29. Drawn as batch 3 (`docs/DIAGRAMS_AUDIT.md` section 10). |
| [release_notes_1.0.5.md](release_notes_1.0.5.md) | 2026-09-29 | The text of the 1.0.5 GitHub release page (the same changes as CHANGELOG.md, 1.0.5). |
| [archive/study_guides/](archive/study_guides/) | 2026-09 | Early one-page overviews of 6 of the 16 exams (Final #1 and #3, Open Book #1, #4, #7 and #10), written before the app showed per-question lessons. Partial and not maintained; the app itself is the study material. |
