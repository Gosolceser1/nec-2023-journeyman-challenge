# Diagrams audit (September 2026)

Which questions need a figure, whether the figures we ship are right, and
what new figures would help. The short answer: **three questions require a
figure, and all three are now redrawn in the app's own style (section 1);
88 would benefit from an original study figure, and all 88 have one**
(51 drawings for all 91 records, section 5), each checked against the NEC 2023
text by two separate reviews (section 6). Batch 1 of the gap scan adds 26
drawings and 6 re-masks for 72 more questions (section 8): 77 drawings for
163 records in all.

Screenshots: `.audit_tmp/shots/diagrams/` (contact sheets `all_*.png` for
every record, `changed_*.png` for the 1.0.5 changes, `batch1/batch1_*.png`
for batch 1; desktop and phone, before and after answering). Nothing here copies UpCodes, the exam PDFs or
any other source: every figure is drawn in code (`tools/diagrams/`).

## 1. Required figures (redrawn for 1.0.5)

Up to 1.0.4 these three were crops of *Journeyman open book final exam
#1.pdf* (`tools/pipeline/extract_diagrams.py`) on a paper-white card. For
1.0.5 they are drawn from scratch in `tools/diagrams/figs/exam_required.py`
(tier "R" in `records.py`), in the same dark style as every other figure.
They keep the electrical meaning of the printed figure, so the answer keys
stand, and they are outlined after answering by a `highlight` box
(`Fig.highlight`, written to `figures.json`). The PDF crops, their
`.import` files, the `diagrams.json` entries and the per-file mask entries
are gone; `DiagramView` still reads `diagrams.json` (now `{}`), so a future
crop would still work.

| Record | Drawing | What it shows | Keyed part outlined after answering |
|---|---|---|---|
| `final-exam-#1-005` | `lamp_switch_meter_readings` | 120 V supply, switch S1 closed ("ON"), lamp L1 with an unbroken filament, a voltmeter across S1 reading 0 V and one across L1 reading 120 V | lamp L1 (answer A) |
| `final-exam-#1-013` | `meter_hookups_three_meters` | supply, load, meter I in one conductor with a lead to the other, meter II in one conductor only, meter III across the two conductors; labelled only I, II, III | meter II (answer B) |
| `final-exam-#1-047` | `switch_symbols_a_to_d` | four normally open sensing contacts: (a) stepped thermal element, (b) flow flag, (c) pressure diaphragm, (d) float; labelled only (a)-(d) | symbol (a) (answer A) |

Symbols follow the usual control-diagram conventions (temperature-actuated:
stepped element under the blade; flow: flag; pressure/vacuum: diaphragm;
liquid level: float). Before answering nothing needs a mask: the readings,
the ON position and the meter positions are givens from the stem, the
filament is intact, and no meter or symbol carries a name or an A/V letter.

The 1.0.4 review of the crops (kept for the record) found the same:

| Record | Figure | Crop | Matches question | Answer region highlight (post) | Phone 540x960 | Desktop 1280x720 |
|---|---|---|---|---|---|---|
| `final-exam-#1-005` | switch S1, lamp L1, two meters (0 V, 120 V) | complete, stem text masked out | yes | lamp L1 (answer A) | small (fit shrinks it to ~220 px); the "meter"/"OFF" labels need the zoom | clear |
| `final-exam-#1-013` | meters I, II, III and a load | complete | yes | meter II (answer B) | readable | readable |
| `final-exam-#1-047` | symbols (a)-(d) | complete | yes ("Diagram A" = "(a)") | symbol (a) (answer A) | readable | readable |

**Pixel review for answer leaks (before answering): none.** Each figure was
checked at 3x zoom:

- `final-exam-1-005.png`: the 0 V and 120 V readings and the ON position are
  givens from the stem. The lamp filament is drawn intact, so nothing shows the
  open lamp. No mask needed.
- `final-exam-1-013.png`: the meters are labelled only I/II/III METER (no A or
  V symbol); the wiring is the question itself. No mask needed.
- `final-exam-1-047.png`: letters (a)-(d) only, no names. No mask needed.

Those reviews lived in `data/diagram_masks.json` (`diagrams`, now empty);
the redrawn figures have per-record entries like every other original, and
`tools/tests/test_diagrams.gd` fails if a figure ever lacks a review or a
flagged leak lacks a mask.

**Text around the figures (not the images), fixed in 1.0.4** through the
overlay and the pipeline (`tools/pipeline/question_bank_overrides.json`,
`tools/pipeline/gists.py`, then a candidate build that differs from the old
bank only in these two gists). Gists are not spoken, so no speech changed,
and the content audit checksums cover the provision text only:

- `final-exam-#1-013` gist said "An ammeter measures current and must be
  connected in series with the load." With the figure beside it, that picked
  meter II before the learner answered. Now: "Three meters are wired three
  different ways around the load. Trace each meter's leads, then decide which
  hookup measures current."
- `final-exam-#1-047` gist said to "look for the curved sensing line drawn
  across the contact". The printed symbol (a) has a stepped thermal element
  under the blade, not a curved line across it. Now: "Four switch contacts,
  each with a different symbol drawn under the blade. The question asks which
  symbol stands for a thermal (temperature) element."
- `tools/pipeline/gists.py` had stale "needs its missing diagrams ... flag it
  and move on" gists for Final Exam #1 Q13 and Q47; they now match the
  overlay.
- Still open (harmless): `final-exam-#1-013` and `#1-047` carry the generic
  "Electrical math" background paragraph and tip title.

No image fix was needed in 1.0.4: crops, masks and highlights were correct.

## 2. Mask / reveal system (landed)

`data/diagram_masks.json` lists, per figure file, the regions that would give
the answer away (`leaks`: region + what) and the badges that cover them
(`masks`: `rect` as image fractions, optional `label` such as `"? ft"`,
optional `ring`). `DiagramView` draws an opaque slate badge with a cyan
outline and an amber `?` over each mask, in image space, so it scales with
the figure inline, in the fullscreen zoom and in both layouts. Masks draw
over the picture only, so they never change layout. After the answer,
`reveal(correct, reduce_motion)` shrinks and fades the badges over 0.22 s
(instantly with Reduce motion) and rings the regions flagged `ring`. Speech
never reads figure pixels, and the teach gate is unchanged.

Tests (`tools/tests/test_diagrams.gd`, both layouts):
- Every mask entry names a figure that exists, and every figure has a dated
  review. The three required records must be redrawn originals shown before
  answering, with a highlight.
- The guard fails a flagged leak that isn't fully inside a mask (with
  self-tests for "no mask", "partly covered" and "covered").
- For every figure with masks: masked before answering, masked in the zoom
  too, nothing left after answering, and masked again when the question
  returns.
- The same path is also exercised with masks injected on a real figure
  record that has none (`final-exam-#1-005`). That covers masked
  before answering, unchanged size, badges on the picture and scaling 1:1
  with it, a masked zoom, a fade (or instant with Reduce motion), and nothing
  masked afterwards. A deliberately broken reveal makes these checks fail.

## 3. Need analysis (all 283 records)

| | Count |
|---|---|
| Figure **required** to answer | 3 |
| Would **benefit** (A high / B medium / C low or post-answer only) | 88 (23 / 42 / 23) |
| No figure needed (definitions, lists, ampacity/table lookups, NFPA 70E, state law) | 192 |

Only the three "required" records mention a figure or depend on one; every
other stem can be answered from its text. "Benefit" means a figure would make
the rule easier to learn and remember. A-tier figures can show the setup with
the answer masked. C-tier ones either only make sense after answering (the
picture *is* the answer, e.g. the delta symbol) or add little.

### Top 10 recommended new figures (ranked by study value)

One figure can serve several records, each with its own mask.

1. **F1 Grounding electrode system + service bonding**: MBJ, GEC, EGC, rods
   6 ft apart, plate 30 in deep, in-ground steel 10 ft, concrete-encased #4,
   water-meter bonding jumper. 8 records (prototype P4).
2. **F2 110.26 working space family**: 30 in width, 6 1/2 ft height, depth
   by condition, dedicated space, open doors (24 in), 25 ft egress door.
   5 records (prototype P1).
3. **F3 Pool/spa/fountain clearances**: 5 ft LFMC (680.11), 6 ft pump
   receptacle (680.22), 12 ft spa fan (680.43), 20 ft fountain (680.58),
   6 ft storable-pool audio. 6 records.
4. **F6 Dwelling receptacle placement plan**: 6/12 ft rule and 24 in walls,
   10 ft hallway, garage, 6 ft appliance outlet, 25 ft service receptacle.
   9 records.
5. **F4 Raceway and cable support spacing**: within 3 ft of boxes (5 ft EMT
   exception), 10 ft / 12 ft RMC, PVC 3 ft, strut, MC 72 in, AC 2 ft, NM
   54 in, wireway, IMC riser. 9 records.
6. **F5 Burial cover**: cover measured from the top of the concrete, Table
   300.5(A). 3 records (prototype P3).
7. **F8 Overhead clearance ladder**: 225.18 heights up to 24 1/2 ft over rails,
   3 ft from openings (225.19(D)), 8 ft over roofs (800.44), 2 ft antenna
   clearance. 5 records.
8. **F10 Dwelling GFCI location map**: 210.8(A)/(C)/(F), 6 ft from tub or
   shower, with the asked location masked. 8 records.
9. **F7 Balcony/deck receptacle height** 210.52(E)(3). 2 records
   (prototype P2).
10. **F9 Stud/framing protection**: 1 1/4 in from the framing edge, 1/16 in
    plate. 2 records.

After those, single-purpose figures: 408.5 stub-up, 550.32(F) mobile-home
disconnect, 312.5(C) nipple, 314.23(E) conduit-supported box, the 10 ft tap,
MWBC and high-leg delta schematics, and parallel resistors/sine wave for the
theory questions.

### Need table (required and benefit; every other record is "none")

| id | need | topic | proposed figure |
|---|---|---|---|
| `final-exam-#1-005` | **required** | Troubleshooting a switch/lamp circuit | Has PDF figure (meter readings) |
| `final-exam-#1-013` | **required** | Meter hookups (ammeter in series) | Has PDF figure (three meter hookups) |
| `final-exam-#1-047` | **required** | Switch symbols | Has PDF figure (four symbols) |
| `final-exam-#1-020` | benefit (A) | 250.53(A)(3) rod spacing 6 ft | F1 Grounding electrode system + service bonding |
| `open-book-exam-#1-008` | benefit (A) | 250.53(A)(5) plate electrode depth 30 in | F1 Grounding electrode system + service bonding |
| `open-book-exam-#10-024` | benefit (A) | Grounding electrode conductor (definition) | F1 Grounding electrode system + service bonding (P4, GEC masked) |
| `open-book-exam-#1-002` | benefit (A) | Main bonding jumper (definition, 250.28) | F1 Grounding electrode system + service bonding (PROTOTYPE P4) |
| `open-book-exam-#1-010` | benefit (A) | 210.8(A) receptacles within 6 ft of tub/shower | F10 Dwelling GFCI location map |
| `final-exam-#1-051` | benefit (A) | 110.26(C)(3) personnel door 25 ft, 800 A | F2 110.26 working space family |
| `open-book-exam-#10-016` | benefit (A) | 110.26(A)(1) Condition 2 (concrete = grounded) | F2 110.26 working space family |
| `open-book-exam-#7-022` | benefit (A) | 110.26 open doors impede access (24 in / 6 1/2 ft) | F2 110.26 working space family |
| `final-exam-#1-057` | benefit (A) | 110.26(E)(1) dedicated space | F2 110.26 working space family (PROTOTYPE P1) |
| `final-exam-#1-043` | benefit (A) | 680.43(B)(1)(a) spa paddle fan 12 ft | F3 Pool / spa / fountain clearances |
| `final-exam-#1-060` | benefit (A) | 680.11(A) underground wiring within 5 ft of pool | F3 Pool / spa / fountain clearances |
| `final-exam-#3-059` | benefit (A) | 680.22(A)(2) pump receptacle 6 ft from pool | F3 Pool / spa / fountain clearances |
| `open-book-exam-#4-011` | benefit (A) | 680.43(B)(1)(a) spa paddle fan 12 ft | F3 Pool / spa / fountain clearances |
| `final-exam-#3-013` | benefit (A) | 358.30(A) EMT fastening 3 ft / 5 ft | F4 Raceway and cable support spacing |
| `final-exam-#1-049` | benefit (A) | Table 300.5(A) cover under 2 in concrete | F5 Burial cover (Table 300.5(A)) (PROTOTYPE P3) |
| `open-book-exam-#4-004` | benefit (A) | Table 300.5(A) cover under 2 in concrete | F5 Burial cover (Table 300.5(A)) (PROTOTYPE P3) |
| `final-exam-#1-011` | benefit (A) | 210.52(A)(2) 24 in wall space | F6 Dwelling receptacle placement plan |
| `final-exam-#1-008` | benefit (A) | 210.52(E)(3) deck receptacle max height | F7 Balcony/deck receptacle height (PROTOTYPE P2) |
| `open-book-exam-#10-020` | benefit (A) | 210.52(E)(3) deck receptacle max height | F7 Balcony/deck receptacle height (PROTOTYPE P2) |
| `final-exam-#1-053` | benefit (A) | 225.18(5) railroad clearance 24 1/2 ft | F8 Overhead clearance ladder |
| `open-book-exam-#10-010` | benefit (A) | 225.19(D) 3 ft from openings, material-handling door | F8 Overhead clearance ladder |
| `final-exam-#1-055` | benefit (A) | 300.4(D) 1 1/4 in from framing edge | F9 Stud/framing protection |
| `open-book-exam-#1-004` | benefit (A) | 300.4(A)(2) 1/16 in steel plate in notches | F9 Stud/framing protection |
| `final-exam-#1-035` | benefit (B) | 250.52(A)(2) in-ground steel 10 ft | F1 Grounding electrode system + service bonding |
| `final-exam-#3-027` | benefit (B) | 250.66(B) GEC to concrete-encased electrode, #4 Cu | F1 Grounding electrode system + service bonding |
| `final-exam-#3-050` | benefit (B) | 250.68(B) bonding around water meter / insulated joints | F1 Grounding electrode system + service bonding |
| `open-book-exam-#4-024` | benefit (B) | 250.52(A)(2) in-ground steel 10 ft | F1 Grounding electrode system + service bonding |
| `final-exam-#1-012` | benefit (B) | 210.8(A)(2) garage GFCI | F10 Dwelling GFCI location map |
| `final-exam-#3-006` | benefit (B) | 210.8(C) crawl space lighting outlets | F10 Dwelling GFCI location map |
| `final-exam-#3-064` | benefit (B) | 210.8(A) laundry/garage/shower | F10 Dwelling GFCI location map |
| `open-book-exam-#1-014` | benefit (B) | 210.8(C) crawl space lighting outlets | F10 Dwelling GFCI location map |
| `open-book-exam-#4-002` | benefit (B) | 210.8(F) outdoor outlets | F10 Dwelling GFCI location map |
| `open-book-exam-#1-011` | benefit (B) | 110.26(B) guarded working space in a passageway | F2 110.26 working space family |
| `final-exam-#1-024` | benefit (B) | 680.58 fountain receptacles 20 ft | F3 Pool / spa / fountain clearances |
| `final-exam-#3-007` | benefit (B) | 680.35(D) storable pool audio 6 ft | F3 Pool / spa / fountain clearances |
| `final-exam-#1-066` | benefit (B) | 330.30(D)(2) MC unsupported 72 in | F4 Raceway and cable support spacing |
| `final-exam-#3-053` | benefit (B) | 344.30(B)(2) RMC 1 in, 12 ft | F4 Raceway and cable support spacing |
| `final-exam-#5-006` | benefit (B) | 320.30(D)(2) AC unsupported 2 ft | F4 Raceway and cable support spacing |
| `final-exam-#5-053` | benefit (B) | 384.30(A) strut channel 10 ft / 3 ft | F4 Raceway and cable support spacing |
| `final-exam-#5-069` | benefit (B) | 334.30(B)(2) NM in access ceiling 54 in | F4 Raceway and cable support spacing |
| `final-exam-#5-070` | benefit (B) | Table 352.30(B) PVC 1/2 in, 3 ft | F4 Raceway and cable support spacing |
| `final-exam-#1-003` | benefit (B) | 210.63(B)(1) service receptacle, same room | F6 Dwelling receptacle placement plan |
| `final-exam-#1-022` | benefit (B) | 210.52(G)(1) garage receptacles | F6 Dwelling receptacle placement plan |
| `final-exam-#1-031` | benefit (B) | 210.52(H) hallway 10 ft | F6 Dwelling receptacle placement plan |
| `final-exam-#3-035` | benefit (B) | 210.50(C) appliance outlet within 6 ft | F6 Dwelling receptacle placement plan |
| `final-exam-#3-049` | benefit (B) | 210.63 receptacle within 25 ft | F6 Dwelling receptacle placement plan |
| `open-book-exam-#1-005` | benefit (B) | 210.63 receptacle within 25 ft | F6 Dwelling receptacle placement plan |
| `open-book-exam-#1-016` | benefit (B) | 210.63(B)(1) service receptacle, same room | F6 Dwelling receptacle placement plan |
| `open-book-exam-#1-022` | benefit (B) | 210.50(C) appliance outlet within 6 ft | F6 Dwelling receptacle placement plan |
| `final-exam-#1-050` | benefit (B) | 800.44(B) 8 ft over roofs | F8 Overhead clearance ladder |
| `final-exam-#3-031` | benefit (B) | 800.44 overhead communications entering buildings | F8 Overhead clearance ladder |
| `final-exam-#1-028` | benefit (B) | 514.11(A) fuel dispenser shutoff 20-100 ft | Single-purpose figure |
| `final-exam-#1-029` | benefit (B) | 408.5 conduit stub-up 3 in | Single-purpose figure |
| `final-exam-#1-032` | benefit (B) | 240.21(B)(1) 10 ft tap | Single-purpose figure |
| `final-exam-#1-052` | benefit (B) | 550.32(F) mobile home disconnect 24 in | Single-purpose figure |
| `final-exam-#1-065` | benefit (B) | Sine wave, 90 degrees of a 60 Hz cycle | Single-purpose figure |
| `final-exam-#3-047` | benefit (B) | 230.54(B) SE cable gooseneck (name masked) | Single-purpose figure |
| `final-exam-#3-051` | benefit (B) | 550.32(F) mobile home disconnect 24 in | Single-purpose figure |
| `final-exam-#3-055` | benefit (B) | Two resistors in parallel (value masked) | Single-purpose figure |
| `final-exam-#5-052` | benefit (B) | 368.17(B) busway reduction | Single-purpose figure |
| `open-book-exam-#1-001` | benefit (B) | 210.4(B) multiwire branch circuit | Single-purpose figure |
| `open-book-exam-#10-013` | benefit (B) | 314.23(E) box supported by two conduits | Single-purpose figure |
| `open-book-exam-#4-008` | benefit (B) | 210.4(C) multiwire branch circuit, line-to-neutral | Single-purpose figure |
| `open-book-exam-#4-018` | benefit (B) | 312.5(C) Ex. 1 nipple 18 in - 10 ft | Single-purpose figure |
| `open-book-exam-#7-024` | benefit (B) | 408.3(F)(1) high-leg delta marking | Single-purpose figure |
| `open-book-exam-#1-012` | benefit (C) | 210.8(B)(3) sink + food prep areas | F10 Dwelling GFCI location map |
| `open-book-exam-#4-021` | benefit (C) | 210.8(A) Ex. snow-melting receptacles | F10 Dwelling GFCI location map |
| `final-exam-#5-065` | benefit (C) | 376.30(B) vertical wireway 15 ft | F4 Raceway and cable support spacing |
| `final-exam-#5-067` | benefit (C) | 342.30(B)(3) IMC riser 20 ft | F4 Raceway and cable support spacing |
| `open-book-exam-#7-013` | benefit (C) | Table 300.5(A) (reference-seeking: post-answer only) | F5 Burial cover (Table 300.5(A)) |
| `final-exam-#3-020` | benefit (C) | 810.13 antenna lead-in 2 ft from power | F8 Overhead clearance ladder |
| `final-exam-#1-023` | benefit (C) | 250.122(F) EGC in each parallel raceway | Single-purpose figure |
| `final-exam-#1-033` | benefit (C) | Three-way switch = SPDT (post-answer) | Single-purpose figure |
| `final-exam-#1-041` | benefit (C) | Stop button in series (post-answer) | Single-purpose figure |
| `final-exam-#1-042` | benefit (C) | 406.9(B) wet-location receptacle | Single-purpose figure |
| `final-exam-#1-045` | benefit (C) | 422.16(B)(1) disposer cord 18-36 in | Single-purpose figure |
| `final-exam-#1-062` | benefit (C) | Voltage drop panel-to-load | Single-purpose figure |
| `final-exam-#1-063` | benefit (C) | Drawing scale 1/4 in = 1 ft | Single-purpose figure |
| `final-exam-#1-067` | benefit (C) | Chapter 9 Note 4 nipple fill 60% | Single-purpose figure |
| `final-exam-#3-034` | benefit (C) | 314.24(B)(5) box depth for a flush device | Single-purpose figure |
| `final-exam-#3-070` | benefit (C) | Delta generator symbol (triangle masked) | Single-purpose figure |
| `final-exam-#5-048` | benefit (C) | 366.100(E) gutter bare-part spacing | Single-purpose figure |
| `final-exam-#5-049` | benefit (C) | 382.15(A) not within 2 in of floor | Single-purpose figure |
| `final-exam-#5-064` | benefit (C) | 470.11 thermal barrier 12 in | Single-purpose figure |
| `open-book-exam-#10-021` | benefit (C) | 695.12(D) fire pump parts 12 in above floor | Single-purpose figure |
| `open-book-exam-#4-006` | benefit (C) | 422.16(B)(1) disposer cord 18-36 in | Single-purpose figure |
| `open-book-exam-#4-014` | benefit (C) | 406.9(B) wet-location receptacle | Single-purpose figure |
| `open-book-exam-#7-010` | benefit (C) | 424.36 wiring 2 in above heated ceiling | Single-purpose figure |

## 4. What UpCodes illustrates (reference only)

A read-only survey of UpCodes Premium diagrams filtered to Nebraska and
*Electrical Code 2023* (NFPA 70) found 88 diagrams in the list. About 58 are
NEC topics; the rest are building, fire or ADA diagrams cross-referenced to
electrical work. The list view shows only titles. Sections below come from
the titles and one opened detail page ("AFCI in dwelling units": 210.12(A),
(B)), so treat them as the likely section. **No UpCodes image was downloaded,
traced or copied**, and the repo is public.

- **Working space and clearances, 110.26 (about 15):** Clearances at
  Electrical Equipment; Electrical Working Space Conditions (110.26(A));
  Electrical Panel - Work Space Height; Allowed Clearance at Open Equipment
  Doors; Impeding Access and Egress by Equipment Doors; Entrance/Egress from
  Working Space pts 1-3; Doors at Equipment Spaces; Rooms w/ Electrical
  Equipment: Exits; Indoor and Outdoor Dedicated Equipment Space; Illumination
  of Working Spaces; Equipment with Limited Access; Extension of Support Pads
  into Required Clearance. Over 1000 V: 110.31, 110.32.
- **Receptacle placement (about 10):** 210.52(A) general distribution,
  (C) countertops (2023), (D) bathrooms, (E) outdoors, (F) laundry,
  (H) hallways, (I) foyers; 210.63 HVAC; receptacles at tubs/showers (406.9);
  hospital corridors (517.18).
- **GFCI/AFCI:** GFCI locations other than dwellings (210.8); AFCI in
  dwelling units (210.12).
- **Grounding and bonding (8):** Grounding Electrodes (250.50); GEC Material
  (250.62); electrode system installation: bonding jumper, electrode spacing,
  ground ring, metal underground water pipe, rod/pipe/plate, supplemental
  electrode bonding jumper size (250.53).
- **Services:** overhead service conductor vertical clearance (230.24);
  service conductors at building openings and clearances on buildings
  (230.9); service disconnect (230.70).
- **Wiring methods:** bored holes and nail plates (300.4); cabinet position
  in walls; wet and damp locations (300.6); surface enclosures in wet
  locations (312.2); cable-tray trapeze bracing (392).
- **Lighting:** lighting outlet locations (210.70, three diagrams); dwelling
  stair illumination; luminaires in tub/shower zones (410.10) and clothes
  closets (410.16).
- **Other:** HVAC disconnect (440.14); vaults (450.45, 450.46); pool
  equipotential bonding (680.26); PV setbacks (690); emergency and standby
  (700, 702); EV charging location (625).

Takeaway: the concepts UpCodes chose to draw overlap our top picks: working
space, receptacle placement, grounding electrodes, service and overhead
clearances, 300.4 framing protection and pools. It has no burial-depth or
support-spacing figure; those are ours to draw.

## 5. New original figures (all 88 "benefit" records)

**Status:** all three tiers ship in the app: high (A, 23 records), medium (B, 42) and low (C, 23), 88 records on 48 drawings, landed in that order, each with the full checks. With the three required figures (tier R, section 1) that is 91 records on 51 drawings.

**One visual system.** `tools/diagrams/nec_style.py` holds the palette (dark
slate `#0f172a` ground, cyan `#38bdf8` dimensions, green `#34d399` answer
values, amber for warnings), the stroke widths (4 structure, 3 objects and
dimensions, 2 thin), the type sizes (30 values, 24 labels, 22 notes, never
under 20 canvas px), one dimension-line style (extension lines, filled
arrowheads, value centred on the line), the section chip and the shared parts:
wall, floor, ceiling, soil and grade, concrete, trench, panel, box,
receptacle (elevation and plan), conduit, cable, strap, stud, rod, pool,
person, OK/NO marks. Each topic module in `tools/diagrams/figs/` draws its
figures with those parts only, so the 48 drawings read as one set.

**One drawing, several questions.** Records that share a concept share a
drawing, with their own masks: the 110.26 plan view serves four questions
(the 25 ft door, Condition 2, open doors, the guarded passageway), the
dwelling plan five, the GFCI map eight, the electrode section four. A value
that answers one record is masked for that record only.

**Build.** `python tools/diagrams/build.py` draws every figure as SVG
(review copy in `docs/diagrams/svg/`), renders it with PyMuPDF at 1.5x and
quantizes it to a 96-colour palette PNG in `assets/diagrams/nec/` (Godot's SVG
import drops text, so the app ships PNG), and writes
`assets/diagrams/nec/figures.json` (record -> figure, `when`, size, NEC
sections), the per-record masks in `data/diagram_masks.json` (`records`) and
every label's text and box (`docs/diagrams/labels.json`). `--check` (run by
`verify.sh` through `tools/tests/test_diagram_figures.py`) fails if any of
those is stale. `WIRED_TIERS` in `build.py` picks the tiers that ship.

**Answer safety.** Before answering, every value or item that answers *that*
question is under a "?" mask; after answering it is revealed with the
highlight ring. The build refuses a figure when an unmasked label states the
current record's answer: a correct-answer number (lengths normalised to
inches, plus percent, volts, amps and AWG) that is not in the stem or a
wrong choice, the whole correct-answer phrase, or a distinctive keyword of it
(`tools/diagrams/leakscan.py`). Because it scans every label on the drawing
against the *current* record, a value drawn for a different question can't
give this one away. `test_diagrams.gd` repeats the scan in GDScript over
`labels.json`, so a hand edit to the masks can't slip one through. The two
drawings whose lengths could be read off the picture (the electrode section
and the spa fan) are drawn out of proportion and say "not to scale"; so is
the pool plan, where the pump receptacle is drawn well outside the 5 ft
zone (at true scale 6 ft would sit on its edge).

**Before or after, per record.** 75 records get the figure *before*
answering (it sets up the question: distances, positions, what is measured
from where). 13 get it only *after* answering (`"when": "after"`), because
the picture is the answer or adds nothing to the setup: the delta symbol,
the SPDT switch, the stop button in series, the nipple fill rule, the
gooseneck, the PVC support table, the overhead clearance ladder for the
railroad question, the communications-entry question, four GFCI-map questions whose whole point is the
location, and the burial "which table" question. `DiagramView` hides an
after-only figure (no panel, no zoom) until the answer is in, then shows it
unmasked.

**Phones.** The figure is a compact thumbnail that `FitController` shrinks
(down to 96 px) so the question never scrolls; tapping it opens the zoom,
which carries the same masks. Where even 96 px would scroll (today only
`open-book-exam-#10-010`, a long stem and long choices, at phone 360x640
and 540x960), the figure collapses to a 40 px strip: a small thumbnail and
"Figure: tap to enlarge", same masks, same zoom. After answering, if the
screen still overflows with the strip, the explanation sheet (it scrolls
inside) gives way down to 60 px. The dark figures sit on a dark card
(`DiagramView.card_style`), inline and in the zoom.

**Size.** 51 drawings, 1,082 KiB of PNG in the repo in 1.0.5 (the three PDF crops, about 250 KiB, are gone). In 1.0.4: 48 drawings, 1,034 KiB of PNG (about 22 KiB each at 1200 px wide; 96-colour palette, no dithering). In the 1.0.4 builds they take 776 KiB as imported textures plus 80 KiB of figure and mask data, about 0.8 MiB per build; the release as a whole shrank (APK -3.7 MiB, Windows zip -3.8 MiB against 1.0.3) because the voice bundle was re-recorded.

**A resize loop fixed.** `DiagramView` sizes its height from its width. On
the phone layout at 1024x768 (a tablet in landscape) answering
`final-exam-#1-013` made the page overflow by a few pixels; the page
scrollbar took width, the figure got shorter, the scrollbar left, the figure
grew back, and so on within one frame until the engine's message queue
overflowed. That was the long-standing `measure_fit.gd` crash at mobile
1024x768, and most likely the intermittent one at desktop 540x960, which
also died around record 250 of the sweep (`#1-013` is record 251). After four height passes in one frame the
figure may now only shrink, so the layout settles; the run finishes with 0%
scroll.

**Tests.** `test_diagrams.gd` (both layouts) checks every original record:
its mask entry matches `figures.json`, it has a dated review, every flagged
region is inside a mask, no unmasked label leaks its answer, the panel shows
before answering exactly when the figure is a setup figure, the card colour
matches the figure, masks cover inline and in the zoom and go after the
answer, and an after-only figure is hidden (no zoom) before and shown
unmasked after. `tools/visual/snap_diagrams.gd` shoots every figure record
before, zoomed and after on both layouts; `tools/diagrams/contact_sheet.py`
lays them out one row per record.

### Every record

| tier | record | figure | shown | masked before answering |
|---|---|---|---|---|
| R | `final-exam-#1-005` | `lamp_switch_meter_readings` | before | nothing (the figure shows only givens) |
| R | `final-exam-#1-013` | `meter_hookups_three_meters` | before | nothing (the figure shows only givens) |
| R | `final-exam-#1-047` | `switch_symbols_a_to_d` | before | nothing (the figure shows only givens) |
| A | `final-exam-#1-008` | `balcony_receptacle_210-52e3` | before | '6 ft 6 in max (2.0 m, 78 in)' |
| A | `final-exam-#1-011` | `dwelling_receptacles_210-52` | before | '2 ft (24 in) or more' |
| A | `final-exam-#1-020` | `electrode_system_250-52_250-53` | before | '6 ft min' |
| A | `final-exam-#1-043` | `spa_fan_height_680-43` | before | '12 ft (3.7 m)' |
| A | `final-exam-#1-049` | `burial_under_concrete_300-5` | before | '18 in min' |
| A | `final-exam-#1-051` | `working_space_110-26` | before | '25 ft' |
| A | `final-exam-#1-053` | `overhead_clearances_225-18` | after | (whole figure after answering) |
| A | `final-exam-#1-055` | `framing_protection_300-4` | before | '1 1/4 in' |
| A | `final-exam-#1-057` | `dedicated_space_110-26e` | before | 'Sprinkler protection: permitted  (E)(1)(c)'; the not-permitted list (it narrows the choices); sprinkler head drawn in the dedicated space |
| A | `final-exam-#1-060` | `pool_fountain_distances_680` | before | '5 ft' |
| A | `final-exam-#3-013` | `supports_emt_strut_358-30` | before | 'within 5 ft' |
| A | `final-exam-#3-059` | `pool_fountain_distances_680` | before | '6 ft'; '6 ft' |
| A | `open-book-exam-#1-002` | `service_bonding_250-24` | before | 'MAIN BONDING JUMPER' |
| A | `open-book-exam-#1-004` | `framing_protection_300-4` | before | '1/16 in' |
| A | `open-book-exam-#1-008` | `electrode_system_250-52_250-53` | before | '30 in' |
| A | `open-book-exam-#1-010` | `gfci_locations_210-8` | before | '6 ft' |
| A | `open-book-exam-#10-010` | `overhead_clearances_225-18` | before | keep-out zone below the material opening; the 225.19(D)(3) building-opening rule |
| A | `open-book-exam-#10-016` | `working_space_110-26` | before | 'considered grounded (Condition 2)' |
| A | `open-book-exam-#10-020` | `balcony_receptacle_210-52e3` | before | '6 ft 6 in max (2.0 m, 78 in)' |
| A | `open-book-exam-#10-024` | `service_bonding_250-24` | before | 'GROUNDING ELECTRODE CONDUCTOR' |
| A | `open-book-exam-#4-004` | `burial_under_concrete_300-5` | before | '18 in min' |
| A | `open-book-exam-#4-011` | `spa_fan_height_680-43` | before | '12 ft (3.7 m)' |
| A | `open-book-exam-#7-022` | `working_space_110-26` | before | '24 in' |
| B | `final-exam-#1-003` | `equipment_receptacle_210-63` | before | 'same room or area'; 'within 25 ft (7.5 m)' |
| B | `final-exam-#1-012` | `gfci_locations_210-8` | after | (whole figure after answering) |
| B | `final-exam-#1-022` | `dwelling_receptacles_210-52` | before | receptacles drawn one per bay, and the one-per-bay rule |
| B | `final-exam-#1-024` | `pool_fountain_distances_680` | before | '20 ft' |
| B | `final-exam-#1-028` | `fuel_dispenser_shutoff_514-11` | before | '100 ft (30 m) max' |
| B | `final-exam-#1-029` | `conduit_stub_up_408-5` | before | '3 in max (75 mm)' |
| B | `final-exam-#1-031` | `dwelling_receptacles_210-52` | before | '10 ft or more' |
| B | `final-exam-#1-032` | `feeder_tap_10ft_240-21b1` | before | '400 A max'; '1/10' |
| B | `final-exam-#1-035` | `electrode_system_250-52_250-53` | before | '10 ft or more' |
| B | `final-exam-#1-050` | `communications_overhead_800-44` | before | '8 ft min' |
| B | `final-exam-#1-052` | `mobile_home_disconnect_550-32f` | before | '24 in min (600 mm)' |
| B | `final-exam-#1-065` | `sine_wave_60hz_quarter_cycle` | before | '1/240 s' |
| B | `final-exam-#1-066` | `supports_unsupported_cable_320-330-334` | before | '6 ft'; '6 ft' |
| B | `final-exam-#3-006` | `gfci_locations_210-8` | before | '120 V or less' |
| B | `final-exam-#3-007` | `pool_fountain_distances_680` | before | '6 ft'; '6 ft' |
| B | `final-exam-#3-027` | `gec_water_bond_250-66_250-68` | before | 'need not exceed 4 AWG Cu' |
| B | `final-exam-#3-031` | `communications_overhead_800-44` | after | (whole figure after answering) |
| B | `final-exam-#3-035` | `dwelling_receptacles_210-52` | before | 'within 6 ft (72 in)' |
| B | `final-exam-#3-047` | `se_cable_gooseneck_230-54b` | after | (whole figure after answering) |
| B | `final-exam-#3-049` | `equipment_receptacle_210-63` | before | 'within 25 ft (7.5 m)' |
| B | `final-exam-#3-050` | `gec_water_bond_250-66_250-68` | before | 'sufficient length' |
| B | `final-exam-#3-051` | `mobile_home_disconnect_550-32f` | before | '24 in min (600 mm)' |
| B | `final-exam-#3-053` | `supports_rmc_344-30` | before | 'every 12 ft max' |
| B | `final-exam-#3-055` | `parallel_resistors_equal` | before | '1,000 ohm'; the parallel formula worked through |
| B | `final-exam-#3-064` | `gfci_locations_210-8` | after | (whole figure after answering) |
| B | `final-exam-#5-006` | `supports_unsupported_cable_320-330-334` | before | '2 ft max' |
| B | `final-exam-#5-052` | `busway_reduction_368-17b` | before | 'overcurrent protection required'; device drawn at the reduction; industrial-only exception box |
| B | `final-exam-#5-053` | `supports_emt_strut_358-30` | before | 'every 10 ft max' |
| B | `final-exam-#5-069` | `supports_unsupported_cable_320-330-334` | before | '4 1/2 ft' |
| B | `final-exam-#5-070` | `supports_pvc_352-30` | after | (whole figure after answering) |
| B | `open-book-exam-#1-001` | `multiwire_branch_circuit_210-4` | before | handle tie across both poles; 'handle tie: all ungrounded conductors open together' |
| B | `open-book-exam-#1-005` | `equipment_receptacle_210-63` | before | 'within 25 ft (7.5 m)' |
| B | `open-book-exam-#1-011` | `working_space_110-26` | before | the guard drawn across the passageway; 'guarded' |
| B | `open-book-exam-#1-014` | `gfci_locations_210-8` | before | '120 V or less' |
| B | `open-book-exam-#1-016` | `equipment_receptacle_210-63` | before | 'same room or area'; 'within 25 ft (7.5 m)' |
| B | `open-book-exam-#1-022` | `dwelling_receptacles_210-52` | before | 'within 6 ft (72 in)' |
| B | `open-book-exam-#10-013` | `raceway_supported_box_314-23e` | before | threaded hub at the box entry; threaded hub at the box entry; 'threaded wrenchtight into the box or identified hubs' |
| B | `open-book-exam-#4-002` | `gfci_locations_210-8` | before | '50 A or less' |
| B | `open-book-exam-#4-008` | `multiwire_branch_circuit_210-4` | before | 'N' bar label; 'shared grounded conductor'; 'line-to-neutral load'; 'line-to-neutral load' |
| B | `open-book-exam-#4-018` | `nm_cable_sleeve_312-5c` | before | '18 in min (450 mm)' |
| B | `open-book-exam-#4-024` | `electrode_system_250-52_250-53` | before | '10 ft or more' |
| B | `open-book-exam-#7-024` | `high_leg_marking_408-3f1` | before | the transformer winding connection; orange marking on the B conductor; 'high leg (orange)'; 'B' phase on the sign; '208' volts on the sign |
| C | `final-exam-#1-023` | `parallel_egc_250-122f` | before | EGC drawn in this raceway; EGC drawn in this raceway; 'wire-type EGC in each raceway, in parallel' |
| C | `final-exam-#1-033` | `three_way_switch_spdt` | after | (whole figure after answering) |
| C | `final-exam-#1-041` | `motor_stop_start_control` | after | (whole figure after answering) |
| C | `final-exam-#1-042` | `wet_location_receptacle_406-9b` | before | WR marking on the face; 'listed weather- resistant type' |
| C | `final-exam-#1-045` | `disposer_cord_422-16b1` | before | '36 in max (900 mm)' |
| C | `final-exam-#1-062` | `voltage_drop_percent` | before | the percent worked out (base voltage and result) |
| C | `final-exam-#1-063` | `drawing_scale_quarter_inch` | before | '3 1/2 x 4 = 14 ft' |
| C | `final-exam-#1-067` | `nipple_fill_ch9_note4` | after | (whole figure after answering) |
| C | `final-exam-#3-020` | `antenna_leadin_810-13` | before | '600 mm (2 ft) min' |
| C | `final-exam-#3-034` | `box_depth_314-24b5` | before | '23.8 mm (15/16 in) min' |
| C | `final-exam-#3-070` | `delta_generator_symbol` | after | (whole figure after answering) |
| C | `final-exam-#5-048` | `gutter_bare_parts_366-100e` | before | '25 mm (1 in)'; '25 mm (1 in)' |
| C | `final-exam-#5-049` | `nm_extension_floor_382-15a` | before | '50 mm (2 in)' |
| C | `final-exam-#5-064` | `resistor_thermal_barrier_470-11` | before | '305 mm (12 in)' |
| C | `final-exam-#5-065` | `supports_vertical_376-30_342-30` | before | '15 ft max' |
| C | `final-exam-#5-067` | `supports_vertical_376-30_342-30` | before | '20 ft max' |
| C | `open-book-exam-#1-012` | `gfci_locations_210-8` | after | (whole figure after answering) |
| C | `open-book-exam-#10-021` | `fire_pump_parts_695-12d` | before | '300 mm (12 in) min' |
| C | `open-book-exam-#4-006` | `disposer_cord_422-16b1` | before | '36 in max (900 mm)' |
| C | `open-book-exam-#4-014` | `wet_location_receptacle_406-9b` | before | WR marking on the face; 'listed weather- resistant type' |
| C | `open-book-exam-#4-021` | `gfci_locations_210-8` | after | (whole figure after answering) |
| C | `open-book-exam-#7-010` | `heated_ceiling_wiring_424-36` | before | '50 mm (2 in) min' |
| C | `open-book-exam-#7-013` | `burial_under_concrete_300-5` | after | (whole figure after answering) |

## 6. Accuracy review

Two reviewers who did not draw the figures checked every figure against the
NEC 2023 text (the local cache of NFPA 70-2023): each value and its metric
equivalent, min/max direction, section number (2023 numbering, not 2020),
what the dimension is measured from and to, and agreement with the keyed
answer. 48 figures, 88 records. No wrong value, no 2020 section number and
no figure that contradicts its key were found. Fixed:

- `communications_overhead_800-44`: "(A)(1) below power" now says "if
  practicable", as 800.44(A)(1) does.
- `working_space_110-26`: the egress door "opens at least 90 deg", per
  110.26(C)(3).
- `dedicated_space_110-26e`: "6 ft or ceiling, if lower", per 110.26(E)(1)(a)
  "whichever is lower".
- `supports_unsupported_cable_320-330-334`: the 2 ft AC allowance at a
  terminal is a cable length (320.30(D)(2)), now a callout on the cable, not
  a straight vertical dimension.
- `nm_cable_sleeve_312-5c`: the 12 in fastening distance is measured along
  the sheath from the raceway end (312.5(C) Ex. No. 1(1)).
- `fuel_dispenser_shutoff_514-11`: the 20 ft and 100 ft limits are measured
  from the dispensers, not the island edge (514.11(A)).
- `electrode_system_250-52_250-53`: the title said "to scale" while the
  hidden 6 ft, 30 in and 10 ft could be measured against the visible 8 ft
  rod; now "not to scale" and out of proportion (the spa fan heights too).

Stem wording the reviewers flagged for the content owners (no key is wrong,
nothing changed): `open-book-exam-#4-021` says snow-melt receptacles "are
required to have GFCI" (2023 210.8(A) Ex. No. 1 permits 426.28/427.22
protection instead); `open-book-exam-#10-020` uses the pre-2023 deck
trigger wording; `final-exam-#5-070` says "RNC" (PVC conduit);
`final-exam-#1-066` says "last point of connection" (2023: last point of
cable support); `final-exam-#5-069` omits the dwelling limit;
`final-exam-#3-034` says "flush device" (2023 frames 314.24(B)(5) by
conductor size); `final-exam-#5-048` says "different potential" (2023:
different voltages); `final-exam-#1-045` and `open-book-exam-#4-006` say
"residential" (422.16(B)(1) has no such limit); `final-exam-#1-003` and
`open-book-exam-#1-016`: under 2023 the 25 ft of 210.63 also applies to
indoor service equipment, so choice A is partly true (key D, "same room or
area", is the specific rule).

### Second review (1.0.5)

Every drawing was checked again against the local NFPA 70-2023 text, and
layout realism was checked against public trade sources. Values, min/max
direction and measuring points all agree with the 2023 text, among them
210.52(G)(1) (one in each vehicle bay, 5 1/2 ft), 210.52(H), 210.50(C),
210.52(E)(3), 680.11(A), 680.22(A)(2), 680.35, 680.43(B)(1), 680.58,
110.26(A)/(C)/(E), 240.21(B)(1), 408.3(F)(1), 250.52/250.53/250.68(B),
225.18/225.19(D), 800.44, 810.13, 300.4(D), 300.5, Chapter 9 Note 4,
358.30, 344.30, 376.30(B), 342.30, 320/330/334.30, 312.5(C), 314.24(B)(5),
366.100(E), 382.15(A), 424.36, 470.11, 514.11, 550.32(F), 422.16(B)(1),
406.9(B)(1) and 695.12(D). Nothing was dropped. Changed:

- `pool_fountain_distances_680`: the pump receptacle (labelled 6 ft) was drawn
  on the edge of the 5 ft underground-wiring zone, as if it were at 5 ft. It
  now sits clearly outside the zone, and the plan says "not to scale".
- Before-answer leaks, fixed with masks or a redesign (the figure still sets
  up the question):
  - `feeder_tap_10ft_240-21b1` (`final-exam-#1-032`): a box said
    "tap >= 1/10 of the feeder OCPD rating", which is the answer (10 x 40 A).
    It is now a 240.21(B)(1) checklist with only "1/10" masked.
  - `high_leg_marking_408-3f1` (`open-book-exam-#7-024`): the orange B
    conductor, its "high leg (orange)" caption and the sign's "B" and "208"
    pointed to delta. B is drawn as a plain hot, and the orange band, the
    caption and the two sign values are masked, like the blanks in the stem.
  - `multiwire_branch_circuit_210-4` (`open-book-exam-#4-008`): the "N" bar
    label and "shared grounded conductor" pointed to "neutral"; both are now
    masked for that question only.
  - `dwelling_receptacles_210-52` (`final-exam-#1-022`): the prongs of the
    two garage receptacles showed above the "?" badge; the badge now reaches
    over the wall line.
- Left as is (minor): the electrode section runs the GEC under the slab to
  the footing electrode; unusual but not wrong.

The zoom's "Tap anywhere or press Esc to close" hint was drawn below the card
over the page, where on phones it ran into choice A. It now sits inside the
card, under the figure.

Text next to the figure (not the image) that still gives an answer away
before answering belongs to the question bank and was sent to the bank owner:
the FORMULA / METHOD strips of `final-exam-#1-022` ("one receptacle outlet
per vehicle bay") and `#1-032` ("cannot exceed 10 times the tap ampacity").
The `open-book-exam-#7-024` gist mentions "high leg" (weak).

## 7. Release and follow-ups

The 88 figures, the masks and the phone strip shipped in 1.0.4. For 1.0.5:
the three required figures are redrawn, the second accuracy review is done
and the leaks above are masked. Still open: the two FORMULA / METHOD strips
above (question bank) and the stem wording flagged in section 6.

## 8. Batch 1 from the gap scan (72 more questions)

`audits/diagram_gap_scan.md` listed the questions that still had no figure
but would be easier with one. Batch 1 covers its 16 high and 10 medium
concept groups plus 6 records that fit figures we already had: **26 new
drawings and 6 re-masks for 72 questions** (tier A for the scan's high
records, B for medium; `records.py`, family "Batch 1 ..."). No concept was
skipped. New modules in `tools/diagrams/figs/`: `loads.py` (floor area,
ampacity with derating, 310.12 dwelling service, branch-circuit rating,
225.39 building disconnects, dryer and range demand), `protection.py`
(ground fault vs open vs short, selective coordination, transformer-fed
panelboard, panelboard spaces and neutral terminals, receptacle markings
and terminals, AFCI and tamper-resistant dwelling map), `motors.py` (motor
branch circuit one-line, in-sight disconnects for motors and rooftop A/C),
`locations.py` (hazardous classes and divisions, antenna and power lines,
patient bed receptacles, plaques and emergency-source signs, sign
construction, busway vapor seal, cinder fill and backfill) and
`construction.py` (switchboard marking and sections, type-letter decoder,
FCC layers, MI / MC / copper-clad cross-sections, raceway fill). Re-masks:
the 60 Hz sine (frequency, `#3-045`), voltage drop (647.4(D), `#3-044`),
the water-pipe bond figure (250.50 existing-building exception, `#3-066`),
the equipment receptacle (`#1-018`, after only), the pool plan (pool motor
GFCI, `#1-024`) and the feeder tap (409.21(B), `#10-004`, after only).

Every number and label was checked against the NFPA 70-2023 text cache;
the scanner (`leakscan.py`) passes, and each record's before shot was
compared with its keyed answer by hand. Where a picture could give the answer
away by shape or by elimination rather than by words, it is masked too: the
AFCI reach arrow, the motor disconnect bracket, every hazardous-class numeral,
all four switchboard side names, both OCPD spots on the transformer figure
and the headwall receptacles. Four records get their figure only after
answering (`#4-023`, `#1-007`, `#1-018`, `#10-004`), where the drawing is the
answer. Review with NEC sections per drawing: `audits/diagram_batch1_tmp/review.md`.
| tier | record | figure | shown | masked before answering |
|---|---|---|---|---|
| A | `final-exam-#1-044` | `fault_path_art100` | before | name of case (a); name of this case (open circuit); name of this case (short circuit) |
| A | `final-exam-#1-069` | `sign_construction_600` | before | 2 in (50 mm) min |
| A | `final-exam-#3-008` | `hazardous_classes_500-5` | before | class for gas or vapor; class for combustible dust; class for ignitible fibers; Division 1; Division 2 |
| A | `final-exam-#3-009` | `motor_circuit_430` | before | the bracket showing what the disconnect opens; what the disconnect separates from the circuit |
| A | `final-exam-#3-019` | `in_sight_disconnect_430-102_440-14` | before | the device in sight; disconnecting means |
| A | `final-exam-#3-052` | `motor_circuit_430` | before | how many overload units; the overload block |
| A | `final-exam-#3-057` | `ampacity_derating_310-15` | before | EGC not counted (310.15(F)) |
| A | `final-exam-#5-050` | `busway_wall_368-234` | before | the device at the exterior wall; vapor seal; what the wall device does; the exception |
| A | `final-exam-#5-068` | `cinder_backfill_344-10c_300-5f` | before | concrete thickness |
| A | `open-book-exam-#1-003` | `floor_area_220-5c` | before | dimensions run to the outside faces; the inside-face dimension marked wrong |
| A | `open-book-exam-#1-009` | `panelboard_interior_408` | before | its own terminal |
| A | `open-book-exam-#1-025` | `in_sight_disconnect_430-102_440-14` | before | readily accessible; what readily accessible means |
| A | `open-book-exam-#10-002` | `floor_area_220-5c` | before | garage counted (2023); open porch not counted; unfinished space not counted |
| A | `open-book-exam-#10-011` | `antenna_power_lines_810-16b` | before | 150 V to ground |
| A | `open-book-exam-#10-019` | `patient_bed_receptacles_517-18` | before | receptacles on this side; receptacle count per bed |
| A | `open-book-exam-#4-009` | `fault_path_art100` | before | name of case (a); name of this case (open circuit); name of this case (short circuit) |
| A | `open-book-exam-#4-012` | `afci_tr_dwelling_210-12_406-12` | before | the reach arrow; how far AFCI protection reaches |
| A | `open-book-exam-#4-023` | `afci_tr_dwelling_210-12_406-12` | after | shown after answering only |
| A | `open-book-exam-#7-007` | `selective_coordination_700-32` | before | the load tapped between the devices; nothing tapped in parallel with the downstream device |
| A | `open-book-exam-#7-021` | `transformer_panel_408-36b` | before | the 480 V side marked wrong; panel OCPD between transformer and panel; OCPD for the panel not on the 480 V side; the exception note |
| A | `open-book-exam-#7-025` | `multiple_supplies_225-37_700-7` | before | where the plaques go; the switch at each plaque |
| B | `final-exam-#1-002` | `switchboard_sections_408` | before | the rear side; the left side; the right side; the front side; where the marking goes |
| B | `final-exam-#1-014` | `ampacity_derating_310-15` | before | 25 A; 40 A; 1.00; 0.87; 0.80; 20 A; 34.8 A |
| B | `final-exam-#1-021` | `appliance_demand_220-54_220-55` | before | 85%; 25 kW x 0.85 = 21.25 kW; +10%; 8 kW x 1.10 = 8.8 kW |
| B | `final-exam-#1-026` | `type_letters_decoder` | before | what the -2 means |
| B | `final-exam-#1-027` | `ampacity_derating_310-15` | before | 25 A; 40 A; 1.00; 0.87; 0.80; 20 A; 34.8 A |
| B | `final-exam-#1-034` | `type_letters_decoder` | before | what the W suffix means |
| B | `final-exam-#1-036` | `dwelling_service_310-12` | before | 83% x 200 A = 166 A |
| B | `final-exam-#1-040` | `appliance_demand_220-54_220-55` | before | 85%; 25 kW x 0.85 = 21.25 kW; +10%; 8 kW x 1.10 = 8.8 kW |
| B | `final-exam-#1-048` | `afci_tr_dwelling_210-12_406-12` | before | hallway receptacle type; the 406.12 rule |
| B | `final-exam-#1-059` | `branch_circuit_rating_210` | before | circuit rating = OCPD rating |
| B | `final-exam-#1-061` | `hazardous_classes_500-5` | before | class for gas or vapor; class for combustible dust; class for ignitible fibers |
| B | `final-exam-#1-070` | `motor_circuit_430` | before | table FLC |
| B | `final-exam-#3-014` | `branch_circuit_rating_210` | before | cord-and-plug load: 12 A max |
| B | `final-exam-#3-024` | `outbuilding_disconnect_225-39` | before | 15 A min; 30 A min |
| B | `final-exam-#3-029` | `selective_coordination_700-32` | before | the defined term; caption naming the term |
| B | `final-exam-#3-038` | `motor_circuit_430` | before | starting current |
| B | `final-exam-#3-044` | `voltage_drop_percent` | before | the sensitive-electronics limits |
| B | `final-exam-#3-045` | `sine_wave_60hz_quarter_cycle` | before | the name for cycles per second |
| B | `final-exam-#3-046` | `panelboard_interior_408` | before | the closure plate type |
| B | `final-exam-#3-048` | `raceway_fill_ch9_348-22` | before | largest conductor |
| B | `final-exam-#3-056` | `outbuilding_disconnect_225-39` | before | 15 A min; 30 A min |
| B | `final-exam-#3-065` | `dwelling_service_310-12` | before | the system the table is for; the occupancy the table is for |
| B | `final-exam-#3-066` | `gec_water_bond_250-66_250-68` | before | where unreachable rebar may be left out |
| B | `final-exam-#5-001` | `fcc_layers_324` | before | how the square is held down |
| B | `final-exam-#5-003` | `cable_cutaways_332_310` | before | the cable type |
| B | `final-exam-#5-004` | `fcc_layers_324` | before | where FCC meets other wiring; the box at the wall |
| B | `final-exam-#5-007` | `fcc_layers_324` | before | the layer above the cable; the layer between floor and cable |
| B | `final-exam-#5-020` | `cable_cutaways_332_310` | before | solid copper conductors; sheath: mechanical protection; sheath: grounding path |
| B | `final-exam-#5-022` | `type_letters_decoder` | before | the underground service-entrance cable |
| B | `final-exam-#5-032` | `raceway_fill_ch9_348-22` | before | largest conductor |
| B | `final-exam-#5-066` | `raceway_fill_ch9_348-22` | before | the fill table; where LFNC fill comes from |
| B | `open-book-exam-#1-007` | `switchboard_sections_408` | after | shown after answering only |
| B | `open-book-exam-#1-015` | `switchboard_sections_408` | before | the rear side; the left side; the right side; the front side; where the marking goes |
| B | `open-book-exam-#1-018` | `equipment_receptacle_210-63` | after | shown after answering only |
| B | `open-book-exam-#1-024` | `pool_fountain_distances_680` | before | the amp limit |
| B | `open-book-exam-#10-003` | `receptacle_markings_406` | before | the only conductor on the green screw |
| B | `open-book-exam-#10-004` | `feeder_tap_10ft_240-21b1` | after | shown after answering only |
| B | `open-book-exam-#10-005` | `cinder_backfill_344-10c_300-5f` | before | corrosion |
| B | `open-book-exam-#10-015` | `cable_cutaways_332_310` | before | minimum copper share |
| B | `open-book-exam-#10-017` | `hazardous_classes_500-5` | before | class for gas or vapor; class for combustible dust; class for ignitible fibers |
| B | `open-book-exam-#10-018` | `receptacle_markings_406` | before | the face marking; orange triangle |
| B | `open-book-exam-#10-025` | `cinder_backfill_344-10c_300-5f` | before | damage |
| B | `open-book-exam-#4-005` | `afci_tr_dwelling_210-12_406-12` | before | hallway receptacle type; the 406.12 rule |
| B | `open-book-exam-#4-007` | `receptacle_markings_406` | before | the face marking; orange triangle |
| B | `open-book-exam-#4-015` | `appliance_demand_220-54_220-55` | before | 85%; 25 kW x 0.85 = 21.25 kW; +10%; 8 kW x 1.10 = 8.8 kW |
| B | `open-book-exam-#4-022` | `dwelling_service_310-12` | before | 83% x 200 A = 166 A |
| B | `open-book-exam-#4-025` | `type_letters_decoder` | before | what the W suffix means |
| B | `open-book-exam-#7-009` | `outbuilding_disconnect_225-39` | before | 15 A min; 30 A min; calculated |
| B | `open-book-exam-#7-011` | `branch_circuit_rating_210` | before | conductor ampacity >= 20 A rating |
| B | `open-book-exam-#7-016` | `multiple_supplies_225-37_700-7` | before | where the source is; the second item on the sign |
| B | `open-book-exam-#7-020` | `sign_construction_600` | before | sign body |
