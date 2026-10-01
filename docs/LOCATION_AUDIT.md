# NEC location audit (2026-09-28)

Every "pointer" in the 283 records was checked against NFPA 70-2023: the
breadcrumb (chapter and article), the "Article N Title — section" line shown
after answering, the provision heading and text, the per-choice rationales,
the memory tip, lookup-table headers, the formula hint, diagram captions (the
three diagrams are PDF crops with no added caption), the sections cited in the
question text, and the lookup hint. Multi-article questions are judged by
their primary cited section (the first one in `article`). The four Nebraska
State Electrical Act records use their own breadcrumb and claim no NEC
chapter; they were checked for that and pass.

## The reported question (open-book-exam-#10-013, 314.23(E))

The Android screenshot showed "Chapter 4 ► Article 430 (Motors, Motor
Circuits, and Controllers)" above the answers of the 314.23(E) question.

**Neither the data nor the UI puts Article 430 on that question.**

- Data: the record has cited `314.23(E)` in every release, and its provision
  heading, rationales and lookup hint all name 314.23(E). Its breadcrumb is
  Chapter 3, Article 314. The only defect was the article title, which was
  shortened to "Outlet, Device, Pull, and Junction Boxes". It now carries the
  full 2023 title (below).
- UI: `main.gd` `_show_question` sets the stem, the breadcrumb and the answer
  cards from one `session.current_record()` in the same call. No other code
  writes the breadcrumb. `current_record()` and `submit()` both use
  `order[current_index]`.
- Reproduction: `tools/tests/test_breadcrumb.gd` walks every record in a
  shuffled order with shuffled choices through the real answer and Next flow,
  in both layouts. Before and after answering it asserts that the breadcrumb
  is the record's own chapter and article, and never the previous record's.
  Result: 0 wrong-article breadcrumbs across 283 records × 2 layouts. Before
  the data fix the only failures were title wording (see below).
- Most likely explanation: the crop showed no question stem, and 11 records
  cite Article 430. The breadcrumb in the screenshot belonged to one of them,
  not to the 314.23(E) answers it was paired with.

The rendered breadcrumb for this question on the phone layout now reads
"NEC 2023 ► Chapter 3: Wiring Methods and Materials ► Article 314 (Outlet,
Device, Pull, and Junction Boxes; Conduit Bodies; Fittings; and Handhole
Enclosures)". The 314.23(E) provision text in the record matches UpCodes word
for word, including the 2023 heading "Raceway-Supported Enclosure, Without
Devices, Luminaires, or Lampholders" and "threaded wrenchtight into the
enclosure or hubs" (answer B stays correct).

## Counts

| Check | Records checked | Issues |
|---|---|---|
| Breadcrumb article number and chapter | 279 NEC + 4 Nebraska | 0 |
| Article title shown in breadcrumb and reference line | 279 | 72 (56 wrong or shortened wording, 16 old raceway style "…: Type RMC") |
| Citation vs provision heading (subsection) | 279 | 1 (open-book-exam-#7-012) |
| Citation narrower than the rule the answer needs | 279 | 1 (final-exam-#3-031) |
| Lookup hint ("Start with …") pointing elsewhere | 279 | 2 (final-exam-#5-022, open-book-exam-#1-004) |
| Rationale or tip citing a neighboring subsection | 279 | 0 |
| Citation of an article not in NEC 2023 | 279 | 0 |
| Pre-2023 section numbers not labeled as old | 279 | 0 (one labeled note, open-book-exam-#7-013 "Table 310.104 is old 2017 numbering", is correct) |
| Answers changed | — | 0 |

Code defects behind the title errors:

- `build_question_bank.py` computed `article_title` from the raw OCR article
  *before* the curated overlay was applied, so an override that changed
  `article` kept a stale title.
- Its hard-coded title table had wrong entries (650 "Sensitive Electronic
  Equipment", 510 "Special Occupancies", 555 "Marinas", 210 "Branch
  Circuits", 406 "Wiring Devices", 810 "Radio and Television Equipment", …).
  `NecReference` kept a second copy with its own differences.

Fixes:

- One canonical table, `data/nec_2023_articles.json` (now
  `data/nec/2023/articles.json`): all 162 NEC 2023
  articles, titles as listed in the UpCodes table of contents. The app, the
  builder and the validator all read it.
- The builder now sets `article_title` from the primary cited article after
  the overlay. The four `article_title` overrides were removed.

## Records with issues

Shown = what the app displayed before the fix; correct = after. Source =
where the NEC 2023 fact was verified.

| id | shown chapter/article | correct chapter/article | cited section | fix | source |
|---|---|---|---|---|---|
| open-book-exam-#7-012 | Ch 3, Art 344; citation 344.10(A)(4), heading, tip and rationales 344.10(A)(3) | Ch 3, Art 344, 344.10(A)(3) Ferrous Raceways and Fittings | 344.10(A)(3) | override `article` → `344.10(A)(3)`; 2023 344.10(A) has only (A)(1)–(A)(3) | UpCodes Ch 3 |
| final-exam-#3-031 | Ch 8, Art 800; citation and provision only 800.44(B), but the answer "any of the above" also rests on (A)(1) and (A)(2), which the rationales cite | Ch 8, Art 800, 800.44 | 800.44 | override `article` → `800.44`; provision now quotes 800.44(A)(1), (A)(2) and (B) verbatim; Exception No. 2 corrected to "through-the-roof raceway" | UpCodes Ch 8 |
| final-exam-#5-022 | lookup hint "Start with DEF 100" | 338.100 Construction | 338.100 | override `lookup_summary` | UpCodes Ch 3 |
| open-book-exam-#1-004 | lookup hint "Start with 300.4(A)(1)" (Bored Holes) | 300.4(A)(2) Notches in Wood | 300.4(A)(2) | override `lookup_summary` | UpCodes Ch 3 |
| final-exam-#1-003 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.63(B)(1) | title wording: title from canonical table | UpCodes Ch 2 ToC |
| final-exam-#1-008 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.52(E)(3) | title wording: title from canonical table | UpCodes Ch 2 ToC |
| final-exam-#1-011 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.52(A)(2) | title wording: title from canonical table | UpCodes Ch 2 ToC |
| final-exam-#1-012 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.8(A)(2) | title wording: title from canonical table | UpCodes Ch 2 ToC |
| final-exam-#1-042 | Ch 4, Art 406 (Wiring Devices) | Ch 4: Equipment for General Use, Art 406 (Receptacles, Cord Connectors, and Attachment Plugs (Caps)) | 406.9(B) | title wording: title from canonical table | UpCodes Ch 4 ToC |
| final-exam-#1-048 | Ch 4, Art 406 (Wiring Devices) | Ch 4: Equipment for General Use, Art 406 (Receptacles, Cord Connectors, and Attachment Plugs (Caps)) | 406.12(1) | title wording: title from canonical table | UpCodes Ch 4 ToC |
| final-exam-#1-057 | Ch 1, Art 110 (Requirements for Electrical Installations) | Ch 1: General, Art 110 (General Requirements for Electrical Installations) | 110.26(E)(1) | title wording: title from canonical table | UpCodes Ch 1 ToC |
| final-exam-#1-058 | Ch 4, Art 450 (Transformers and Transformer Vaults) | Ch 4: Equipment for General Use, Art 450 (Transformers and Transformer Vaults (Including Secondary Ties)) | 450.11(A) | title wording: title from canonical table | UpCodes Ch 4 ToC |
| final-exam-#1-059 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.18 | title wording: title from canonical table | UpCodes Ch 2 ToC |
| final-exam-#3-001 | Ch 4, Art 406 (Wiring Devices) | Ch 4: Equipment for General Use, Art 406 (Receptacles, Cord Connectors, and Attachment Plugs (Caps)) | 406.6(D) | title wording: title from canonical table | UpCodes Ch 4 ToC |
| final-exam-#3-006 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.8(C) | title wording: title from canonical table | UpCodes Ch 2 ToC |
| final-exam-#3-008 | Ch 5, Art 500 (Hazardous (Classified) Locations) | Ch 5: Special Occupancies, Art 500 (Hazardous (Classified) Locations, Classes I, II, and III, Divisions 1 and 2) | 500.5(D)(2) | title wording: title from canonical table | UpCodes Ch 5 ToC |
| final-exam-#3-013 | Ch 3, Art 358 (Electrical Metallic Tubing: Type EMT) | Ch 3: Wiring Methods and Materials, Art 358 (Electrical Metallic Tubing (EMT)) | 358.30(A) | raceway title style: title from canonical table | UpCodes Ch 3 ToC |
| final-exam-#3-014 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | Table 210.21(B)(2) | title wording: title from canonical table | UpCodes Ch 2 ToC |
| final-exam-#3-020 | Ch 8, Art 810 (Radio and Television Equipment) | Ch 8: Communications Systems, Art 810 (Antenna Systems) | 810.13 | title wording: title from canonical table | UpCodes Ch 8 ToC |
| final-exam-#3-034 | Ch 3, Art 314 (Outlet, Device, Pull, and Junction Boxes) | Ch 3: Wiring Methods and Materials, Art 314 (Outlet, Device, Pull, and Junction Boxes; Conduit Bodies; Fittings; and Handhole Enclosures) | 314.24(B)(5) | title wording: title from canonical table | UpCodes Ch 3 ToC |
| final-exam-#3-037 | Ch 3, Art 354 (Nonmetallic Underground Conduit: Type NUCC) | Ch 3: Wiring Methods and Materials, Art 354 (Nonmetallic Underground Conduit With Conductors (NUCC)) | 354.28 | raceway title style: title from canonical table | UpCodes Ch 3 ToC |
| final-exam-#3-049 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.63 | title wording: title from canonical table | UpCodes Ch 2 ToC |
| final-exam-#3-064 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.8(A) | title wording: title from canonical table | UpCodes Ch 2 ToC |
| final-exam-#5-032 | Ch 3, Art 348 (Flexible Metal Conduit: Type FMC) | Ch 3: Wiring Methods and Materials, Art 348 (Flexible Metal Conduit (FMC)) | 348.22 | raceway title style: title from canonical table | UpCodes Ch 3 ToC |
| final-exam-#5-033 | Ch 3, Art 344 (Rigid Metal Conduit: Type RMC) | Ch 3: Wiring Methods and Materials, Art 344 (Rigid Metal Conduit (RMC)) | 344.120 | raceway title style: title from canonical table | UpCodes Ch 3 ToC |
| final-exam-#5-034 | Ch 3, Art 358 (Electrical Metallic Tubing: Type EMT) | Ch 3: Wiring Methods and Materials, Art 358 (Electrical Metallic Tubing (EMT)) | 358.14 | raceway title style: title from canonical table | UpCodes Ch 3 ToC |
| final-exam-#5-036 | Ch 3, Art 352 (Rigid Polyvinyl Chloride Conduit: Type PVC) | Ch 3: Wiring Methods and Materials, Art 352 (Rigid Polyvinyl Chloride Conduit (PVC)) | 352.100, 352.12(B), and 352.60 | raceway title style: title from canonical table | UpCodes Ch 3 ToC |
| final-exam-#5-037 | Ch 3, Art 358 (Electrical Metallic Tubing: Type EMT) | Ch 3: Wiring Methods and Materials, Art 358 (Electrical Metallic Tubing (EMT)) | 358.100 | raceway title style: title from canonical table | UpCodes Ch 3 ToC |
| final-exam-#5-038 | Ch 3, Art 350 (Liquidtight Flexible Metal Conduit: Type LFMC) | Ch 3: Wiring Methods and Materials, Art 350 (Liquidtight Flexible Metal Conduit (LFMC)) | 350.12 | raceway title style: title from canonical table | UpCodes Ch 3 ToC |
| final-exam-#1-022 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.52(G)(1) | title wording: title from canonical table | UpCodes Ch 2 ToC |
| final-exam-#1-031 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.52(H) | title wording: title from canonical table | UpCodes Ch 2 ToC |
| final-exam-#3-053 | Ch 3, Art 344 (Rigid Metal Conduit: Type RMC) | Ch 3: Wiring Methods and Materials, Art 344 (Rigid Metal Conduit (RMC)) | 344.30(B)(2) | raceway title style: title from canonical table | UpCodes Ch 3 ToC |
| final-exam-#5-066 | Ch 3, Art 356 (Liquidtight Flexible Nonmetallic Conduit: Type LFNC) | Ch 3: Wiring Methods and Materials, Art 356 (Liquidtight Flexible Nonmetallic Conduit (LFNC)) | 356.22 | raceway title style: title from canonical table | UpCodes Ch 3 ToC |
| final-exam-#5-068 | Ch 3, Art 344 (Rigid Metal Conduit: Type RMC) | Ch 3: Wiring Methods and Materials, Art 344 (Rigid Metal Conduit (RMC)) | 344.10(C) | raceway title style: title from canonical table | UpCodes Ch 3 ToC |
| final-exam-#3-048 | Ch 3, Art 348 (Flexible Metal Conduit: Type FMC) | Ch 3: Wiring Methods and Materials, Art 348 (Flexible Metal Conduit (FMC)) | Table 348.22 | raceway title style: title from canonical table | UpCodes Ch 3 ToC |
| open-book-exam-#1-001 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.4(B) | title wording: title from canonical table | UpCodes Ch 2 ToC |
| open-book-exam-#1-005 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.63 | title wording: title from canonical table | UpCodes Ch 2 ToC |
| open-book-exam-#1-010 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.8(A)(10) | title wording: title from canonical table | UpCodes Ch 2 ToC |
| open-book-exam-#1-011 | Ch 1, Art 110 (Requirements for Electrical Installations) | Ch 1: General, Art 110 (General Requirements for Electrical Installations) | 110.26(B) | title wording: title from canonical table | UpCodes Ch 1 ToC |
| open-book-exam-#1-012 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.8(B)(2) | title wording: title from canonical table | UpCodes Ch 2 ToC |
| open-book-exam-#1-014 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.8(C) | title wording: title from canonical table | UpCodes Ch 2 ToC |
| open-book-exam-#1-016 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.63(B)(1) | title wording: title from canonical table | UpCodes Ch 2 ToC |
| open-book-exam-#1-018 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.8(E) | title wording: title from canonical table | UpCodes Ch 2 ToC |
| open-book-exam-#1-020 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.11(C)(2) | title wording: title from canonical table | UpCodes Ch 2 ToC |
| open-book-exam-#1-022 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.50(C) | title wording: title from canonical table | UpCodes Ch 2 ToC |
| open-book-exam-#4-002 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.8(F) | title wording: title from canonical table | UpCodes Ch 2 ToC |
| open-book-exam-#4-005 | Ch 4, Art 406 (Wiring Devices) | Ch 4: Equipment for General Use, Art 406 (Receptacles, Cord Connectors, and Attachment Plugs (Caps)) | 406.12(1) | title wording: title from canonical table | UpCodes Ch 4 ToC |
| open-book-exam-#4-007 | Ch 4, Art 406 (Wiring Devices) | Ch 4: Equipment for General Use, Art 406 (Receptacles, Cord Connectors, and Attachment Plugs (Caps)) | 406.3(E) | title wording: title from canonical table | UpCodes Ch 4 ToC |
| open-book-exam-#4-008 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.4(C) | title wording: title from canonical table | UpCodes Ch 2 ToC |
| open-book-exam-#4-012 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.12(A)(1) | title wording: title from canonical table | UpCodes Ch 2 ToC |
| open-book-exam-#4-014 | Ch 4, Art 406 (Wiring Devices) | Ch 4: Equipment for General Use, Art 406 (Receptacles, Cord Connectors, and Attachment Plugs (Caps)) | 406.9(B) | title wording: title from canonical table | UpCodes Ch 4 ToC |
| open-book-exam-#4-019 | Ch 3, Art 314 (Outlet, Device, Pull, and Junction Boxes) | Ch 3: Wiring Methods and Materials, Art 314 (Outlet, Device, Pull, and Junction Boxes; Conduit Bodies; Fittings; and Handhole Enclosures) | 314.27(D) Ex. | title wording: title from canonical table | UpCodes Ch 3 ToC |
| open-book-exam-#4-021 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.8(A) Ex. 1 | title wording: title from canonical table | UpCodes Ch 2 ToC |
| open-book-exam-#4-023 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.12(B), (C), and (D) | title wording: title from canonical table | UpCodes Ch 2 ToC |
| open-book-exam-#7-003 | Ch 1, Art 110 (Requirements for Electrical Installations) | Ch 1: General, Art 110 (General Requirements for Electrical Installations) | 110.16(A) | title wording: title from canonical table | UpCodes Ch 1 ToC |
| open-book-exam-#7-008 | Ch 1, Art 110 (Requirements for Electrical Installations) | Ch 1: General, Art 110 (General Requirements for Electrical Installations) | 110.13(B) | title wording: title from canonical table | UpCodes Ch 1 ToC |
| open-book-exam-#7-011 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.19(B) | title wording: title from canonical table | UpCodes Ch 2 ToC |
| open-book-exam-#7-012 | Ch 3, Art 344 (Rigid Metal Conduit: Type RMC) | Ch 3: Wiring Methods and Materials, Art 344 (Rigid Metal Conduit (RMC)) | 344.10(A)(4) | raceway title style: title from canonical table | UpCodes Ch 3 ToC |
| open-book-exam-#7-017 | Ch 1, Art 110 (Requirements for Electrical Installations) | Ch 1: General, Art 110 (General Requirements for Electrical Installations) | 110.14(C)(2) | title wording: title from canonical table | UpCodes Ch 1 ToC |
| open-book-exam-#7-018 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.11(A) | title wording: title from canonical table | UpCodes Ch 2 ToC |
| open-book-exam-#7-019 | Ch 1, Art 110 (Requirements for Electrical Installations) | Ch 1: General, Art 110 (General Requirements for Electrical Installations) | 110.12(B) | title wording: title from canonical table | UpCodes Ch 1 ToC |
| open-book-exam-#7-022 | Ch 1, Art 110 (Requirements for Electrical Installations) | Ch 1: General, Art 110 (General Requirements for Electrical Installations) | 110.26 | title wording: title from canonical table | UpCodes Ch 1 ToC |
| open-book-exam-#10-003 | Ch 4, Art 406 (Wiring Devices) | Ch 4: Equipment for General Use, Art 406 (Receptacles, Cord Connectors, and Attachment Plugs (Caps)) | 406.10(C) | title wording: title from canonical table | UpCodes Ch 4 ToC |
| open-book-exam-#10-007 | Ch 3, Art 314 (Outlet, Device, Pull, and Junction Boxes) | Ch 3: Wiring Methods and Materials, Art 314 (Outlet, Device, Pull, and Junction Boxes; Conduit Bodies; Fittings; and Handhole Enclosures) | 314.2 | title wording: title from canonical table | UpCodes Ch 3 ToC |
| open-book-exam-#10-011 | Ch 8, Art 810 (Radio and Television Equipment) | Ch 8: Communications Systems, Art 810 (Antenna Systems) | 810.16(B) | title wording: title from canonical table | UpCodes Ch 8 ToC |
| open-book-exam-#10-013 | Ch 3, Art 314 (Outlet, Device, Pull, and Junction Boxes) | Ch 3: Wiring Methods and Materials, Art 314 (Outlet, Device, Pull, and Junction Boxes; Conduit Bodies; Fittings; and Handhole Enclosures) | 314.23(E) | title wording: title from canonical table | UpCodes Ch 3 ToC |
| open-book-exam-#10-016 | Ch 1, Art 110 (Requirements for Electrical Installations) | Ch 1: General, Art 110 (General Requirements for Electrical Installations) | 110.26(A)(1) Condition 2 | title wording: title from canonical table | UpCodes Ch 1 ToC |
| open-book-exam-#10-017 | Ch 5, Art 500 (Hazardous (Classified) Locations) | Ch 5: Special Occupancies, Art 500 (Hazardous (Classified) Locations, Classes I, II, and III, Divisions 1 and 2) | 500.5(D) | title wording: title from canonical table | UpCodes Ch 5 ToC |
| open-book-exam-#10-018 | Ch 4, Art 406 (Wiring Devices) | Ch 4: Equipment for General Use, Art 406 (Receptacles, Cord Connectors, and Attachment Plugs (Caps)) | 406.3(E) | title wording: title from canonical table | UpCodes Ch 4 ToC |
| open-book-exam-#10-020 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.52(E)(3) | title wording: title from canonical table | UpCodes Ch 2 ToC |
| final-exam-#1-017 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.18 | title wording: title from canonical table | UpCodes Ch 2 ToC |
| final-exam-#1-051 | Ch 1, Art 110 (Requirements for Electrical Installations) | Ch 1: General, Art 110 (General Requirements for Electrical Installations) | 110.26(C)(3) | title wording: title from canonical table | UpCodes Ch 1 ToC |
| final-exam-#3-054 | Ch 3, Art 348 (Flexible Metal Conduit: Type FMC) | Ch 3: Wiring Methods and Materials, Art 348 (Flexible Metal Conduit (FMC)) | 348.28 | raceway title style: title from canonical table | UpCodes Ch 3 ToC |
| final-exam-#3-035 | Ch 2, Art 210 (Branch Circuits) | Ch 2: Wiring and Protection, Art 210 (Branch Circuits Not Over 1000 Volts AC, 1500 Volts DC, Nominal) | 210.50(C) | title wording: title from canonical table | UpCodes Ch 2 ToC |
| final-exam-#5-067 | Ch 3, Art 342 (Intermediate Metal Conduit: Type IMC) | Ch 3: Wiring Methods and Materials, Art 342 (Intermediate Metal Conduit (IMC)) | 342.30(B)(3) | raceway title style: title from canonical table | UpCodes Ch 3 ToC |
| final-exam-#5-070 | Ch 3, Art 352 (Rigid Polyvinyl Chloride Conduit: Type PVC) | Ch 3: Wiring Methods and Materials, Art 352 (Rigid Polyvinyl Chloride Conduit (PVC)) | Table 352.30 | raceway title style: title from canonical table | UpCodes Ch 3 ToC |

## Flagged, not changed

- **open-book-exam-#10-024** (Article 100): the keyed answer "grounding
  conductor" is the source exam's term. NEC 2023 defines "grounding electrode
  conductor"; "grounding conductor" has not been a defined term since 2014.
  The record's rationale already explains this. The answer is kept per the
  "don't change answers unless provably wrong" rule, since it is the only
  choice that names that conductor. **Resolved:** the stem is the 2023 Article
  100 definition of *Grounding Electrode Conductor*, and the only definition
  starting "Grounding Conductor" is "Grounding Conductor, Equipment (EGC)". Choice D
  now reads "grounding electrode conductor" (same letter and meaning, content
  audit). The background line says "equipment grounding conductor" for the
  green/bare wire (tables/formulas audit).
- **open-book-exam-#1-018** (210.8(E)): the rationale for choice C cites
  "210.8(A) Exception No. 2" for a permanently installed security system
  receptacle. **Verified:** 2023 210.8(A) Exception No. 2 reads "A receptacle
  supplying only a permanently installed premises security system shall be
  permitted to omit ground-fault circuit-interrupter protection". No change.
- **final-exam-#3-068** (620.51): the citation is "620.51" and the provision heading "620.51(D)(1) More Than One Driving Machine". The UpCodes text extraction returned "Available Fault Current Field Marking" for 620.51(D)(1), which may be a mis-sliced neighbor (the extraction matched the first "(1)" after "(D)"). The record was left unchanged: the citation and the breadcrumb (Chapter 6, Article 620) are right either way. Re-check the 620.51(D) list numbering by hand. Resolved in `docs/CONTENT_AUDIT_2023.md`: 2023 620.51(D) has only (1) Available Fault Current Field Marking, so the record tests a removed rule and is flagged there. The tables/formulas audit confirmed
  this: the phrase "numbered to correspond to the identifying number" appears in 2023 Chapter 6
  only in 620.53, 620.54 and 620.55. The record was then rewritten to test 2023 620.51(A) (disconnect
  lockable only in the open position per 110.25); key position A unchanged.
- **open-book-exam-#10-002** (220.5(C), garages now counted): verified. The
  2023 220.5(C) excludes only open porches and unfinished areas not
  adaptable for future use, and the record matches it word for word.

## Guards added

- `validate_question_bank.py` `location_problems` (runs in the `--no-warn`
  gate) reports:
  - a non-canonical `article_title`;
  - a provision heading in another article or section, or naming a different
    subsection;
  - a lookup hint pointing to another section or subsection;
  - a correct-choice rationale citing a neighboring subsection the provision
    never mentions;
  - a citation of an article missing from NEC 2023;
  - pre-2023 numbers (e.g. Table 310.15(B)(16), 310.104, 311, 399, 725.4x)
    unless the sentence calls them old.

  Ten unit tests in `tools/tests/test_validate_question_bank.py` cover these
  rules.
- `tools/tests/test_breadcrumb.gd` (in `run_all.gd`): the sweep described
  above, plus the "Article N Title — section" line after answering, in both
  layouts.
- `tools/tests/test_nec_reference.gd`: canonical table lookups, chapter
  membership and the expected breadcrumb for the reported record.

## Verified on UpCodes

Source: the logged-in UpCodes viewer for NFPA 70-2023,
https://up.codes/viewer/nfpa/nfpa-70-2023, read on 2026-09-28. Navigation used
chapter pages and the sidebar only, never the search box; text was read with
snapshots and with in-page text extraction.

- **Article titles and chapter membership, all 162 articles, Chapters 1–8.**
  - Ch 1: https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/1/general
  - Ch 2: https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection
  - Ch 3: https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials
  - Ch 4: https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/4/equipment-for-general-use
  - Ch 5: https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/5/special-occupancies
  - Ch 6: https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment
  - Ch 7: https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/7/special-conditions
  - Ch 8: https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/8/communications-systems

  UpCodes title-cases every word ("…; Fittings; And Handhole Enclosures").
  The table keeps the UpCodes wording, except that it lowercases "and" after a
  semicolon in 314. Article 712 (Direct Current Microgrids, 2020) is not in
  NEC 2023 and was dropped from the table.
- **Broad sweep of the bank's cited sections:** 199 distinct primary
  sections and tables, grouped by chapter and read with in-page text
  extraction. 156 were located with their headings as cited. 43 were not
  matched by the text search, which proves nothing either way: the matcher
  misses deep subsections and tables, and several of the 43 (210.52(A)(2),
  240.21(B)(1), 250.122(F)(1), Table 310.15(B)(1)(1)) were read directly in
  the targeted pass below. Not matched:
  - Ch 1: 110.14(C)(2), 110.26(B), 110.26(C)(3), 110.26(E)(1).
  - Ch 2: Tables 210.21(B)(2), 220.54, 220.55, 250.122; 210.8(C), 210.8(E),
    210.11(C)(2), 210.52(A)(2), 210.52(E)(3), 210.52(H), 210.63(B)(1),
    225.19(D)(1), 240.5(B)(1), 240.5(B)(4), 240.21(B)(1), 250.52(A)(2),
    250.53(A)(5), 250.122(F)(1).
  - Ch 3: 300.5(F), 305.15(E), 310.15(F), 314.24(B)(5), 314.27(D),
    338.10(B)(3), 366.23(A), Tables 310.15(B)(1)(1), 310.16, 348.22.
  - Ch 4: 422.16(B)(1), Tables 400.4, 430.37, 430.250.
  - Ch 5: 500.5(D), 500.5(D)(2), 590.4(F), 590.4(G), 590.4(J).
  - Ch 6: 630.31(A)(2), 680.22(A)(2), 680.43(B)(1).
  A follow-up pass, with the viewer's search box working, still reported
  these as "not found". That includes sections that are
  certainly in NEC 2023, such as 210.8(E) Equipment Requiring Servicing,
  110.26(B) Clear Spaces and 590.4(G) Splices. It also contradicted its own
  earlier reading of 620.51(D). So "not found" here means "not verified by
  the automated extraction", not "does not exist". No record was changed on
  that basis. The 2026-09-28 content audit (`docs/CONTENT_AUDIT_2023.md`)
  found every section and table on this list in NEC 2023 under the cited
  heading.
  The tables/formulas audit (`docs/TABLES_FORMULAS_AUDIT.md`) then checked all
  44 section/heading pairs cited by records independently: it walked each
  chapter page's heading tree and read the tables by their `#table_…`
  anchors. **All 44 are verified; none is wrong.** Three need a note:
  - 225.19(D)(1) is headed "Clearance From Windows". open-book-exam-#10-010
    cites "225.19(D)(1) and 225.19(D)(3)", which is consistent.
  - 630.31(A)(2) is an unheaded list item (the "specific operation" welder
    rule), and 220.14(H)(1) is list item (1) of 220.14(H). Both exist, even
    though they are not headings.
  - The 2023 table numbers are Table 344.30(B), Table 352.30(B), Table 630.31(A)
    and Table 314.16(B)(1). The bank uses these names.
- **Section numbers, headings and text (targeted pass):**
  - https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/3/wiring-methods-and-materials
    - 314.23(E) Raceway-Supported Enclosure, Without Devices, Luminaires, or Lampholders: full text matches open-book-exam-#10-013.
    - 344.10(A) Atmospheric Conditions and Occupancies: (1) Galvanized Steel, Stainless Steel, and Red Brass RMC; (2) Aluminum RMC; (3) Ferrous Raceways and Fittings (enamel, indoors only). 344.10(B) Corrosive Environments: (B)(1), (B)(2).
    - 300.4(A) Cables and Raceways Through Wood Members: (1) Bored Holes; (2) Notches in Wood (1.6 mm (1/16 in.) steel plate).
    - 338.100 Construction (Part III), with (A) Assemblies and (B) Uninsulated Conductor.
    - Table 310.15(B)(1)(1): 41–45 °C / 105–113 °F row = 0.71 / 0.82 / 0.87 (60/75/90 °C); final-exam-#1-027 (40 A × 0.87 = 34.8 A) is right.
    - Headings present as cited: 300.1(C), 310.6(C), 310.14(A)(3), 312.5(C), 324.41, 334.116(B), 342.30(B), 344.30(B), 348.22, 352.30(B), 352.100.
  - https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/2/wiring-and-protection
    - 220.5(B) Fractions of an Ampere; 220.5(C) Floor Area (excludes open porches and unfinished areas only; no garage exclusion). Text matches open-book-exam-#10-002.
    - Headings present as cited: 210.8(A), 210.8(B), 210.12(A), 210.12(B), 210.52(A)(2), 210.63, 220.14(H), 240.21(B)(1), 250.122(F)(1).
  - https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/5/special-occupancies
    - 547.30 Motors (Article 547 Agricultural Buildings).
  - https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/6/special-equipment
    - 620.51 Disconnecting Means (lead-in and (A) Type read); 620.51(D)(1) see the flag above.
  - https://up.codes/viewer/nfpa/nfpa-70-2023/chapter/8/communications-systems
    - 800.44 Overhead (Aerial) Wires and Cables; (A)(1) Relative Location, (A)(2) Attachment to Cross-Arms, (A)(3) Climbing Space, (A)(4) Clearances; (B) Above Roofs with Exceptions No. 1 and 2. Quoted verbatim in final-exam-#3-031.

## Exam import (2026-09-29)

The 315 records of Open Book #2, #3, #5, #6, #9, #11, #12 and Final #2 and #4
got the same pointer checks before they entered the bank:

- Every `article` resolves to a 2023 article in `data/nec/2023/articles.json`
  (chapter and full 2023 title), enforced by `validate_question_bank.py`.
- Every `reference_text` line is a verbatim line of the NEC 2023 text cache,
  with the cited section's heading first; Chapter 9 tables are cited as
  "Table N, Chapter 9".
- Choice notes, tips and lookup hints cite the same section as `article`, or
  name the other section on purpose (for example the 310.60 choice of
  final-exam-#2-024 says medium-voltage ampacities are Article 315 in 2023).
- Citations the PDF keys got wrong for 2023 were moved to the 2023 section:
  open-book-exam-#6-019 cites 250.53(A)(2) (the key cites the 250.52(A)
  items), and open-book-exam-#9-004 now tests 620.54 (the 620.51(D) sentence
  the key cites is not in 2023). The keyed answers did not change.
- `tools/tests/test_breadcrumb.gd` walks all 598 records in both layouts.
