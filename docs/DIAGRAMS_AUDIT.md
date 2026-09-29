# Diagrams audit (September 2026)

Which questions need a figure, whether the three figures we ship are right, and
what new figures would help. The short answer: **three questions require a
figure and already have a correct one; about two dozen would clearly benefit
from an original study figure.** Four prototypes are drawn (not wired in).

Screenshots: `.audit_tmp/shots/diagrams/` (contact sheet `overview.png`,
existing figures in `existing/`). Nothing here copies UpCodes or any other
source: the prototypes are drawn in code from the NEC 2023 text
(`tools/diagrams/protos.py`). The prototype sources (`tools/diagrams/`,
`docs/diagrams_proto/`, `tools/visual/snap_diagram_protos.gd`) are on the
local branch `diagrams-protos` and will not land until they are approved.

## 1. Existing figures (`assets/diagrams/`)

All three are crops of *Journeyman open book final exam #1.pdf*
(`tools/pipeline/extract_diagrams.py`), shown on a paper-white card with a tap
to zoom, and outlined after answering by the `highlight` box in
`diagrams.json`.

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

The three reviews are recorded in `data/diagram_masks.json` (empty `leaks` and
`masks`), and `tools/tests/test_diagrams.gd` fails if a figure ever lacks a
review or a flagged leak lacks a mask.

**Text around the figures (not the images).** These are bank-text changes, so
they are proposed here rather than landed; the content audit owns the overlay:

- `final-exam-#1-013` gist: "An ammeter measures current and must be connected
  in series with the load." With the figure beside it, that sentence picks
  meter II before the learner has answered (the answer is not quoted, so the
  validator doesn't catch it). Proposed: "Three meters are wired three
  different ways around the load. Trace each meter's leads, then decide which
  hookup measures current."
- `final-exam-#1-047` gist says to "look for the curved sensing line drawn
  across the contact". The printed symbol (a) has a stepped thermal element
  under the blade, not a curved line across it, so the hint points at the
  wrong shape. Proposed: "Four switch contacts, each with a different
  actuator mark under the blade. The question asks which mark stands for a
  thermal (temperature) element."
- `final-exam-#1-013` and `#1-047` carry the generic "Electrical math"
  background paragraph ("Three formulas run the math questions...") and tip
  title. It is harmless, but unrelated to meters or symbols.
- `tools/pipeline/gists.py` still has stale gists for Final Exam #1 Q13 and
  Q47 ("needs its missing diagrams ... flag it and move on"). The overlay
  replaces them, but they are dead text that the spellcheck still reads.

No image fix was needed: crops, masks and highlights are all correct.

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
- Every mask entry names a figure in `diagrams.json` that exists in
  `assets/diagrams`, and every figure has a dated review.
- The guard fails a flagged leak that isn't fully inside a mask (with
  self-tests for "no mask", "partly covered" and "covered").
- For every figure with masks: masked before answering, masked in the zoom
  too, nothing left after answering, and masked again when the question
  returns.
- Because no shipped figure needs a mask today, the same path is also
  exercised with masks injected on a real figure record. That covers masked
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

## 5. Prototypes (original; awaiting approval, not wired into the bank)

Drawn in code from the NEC 2023 text in the app's dark slate + cyan style
(`tools/diagrams/protos.py` writes `docs/diagrams_proto/<name>.svg` and
`masks.json`). Each is **one** picture with the answer drawn in, plus masks
that hide it until the answer is in (the same mechanism as above). Labels are
sized for the phone: main values at 28-36 canvas px, nothing under 22, which
comes out at about 11-18 screen px. Screenshots come from
`tools/visual/snap_diagram_protos.gd`.

| # | Figure | Records | Masked before answering (revealed after) |
|---|---|---|---|
| P1 | 110.26 working space + dedicated space, front and side views (30 in, 6 1/2 ft, 3 ft at 0-150 V, 6 ft or ceiling) | `final-exam-#1-057` | the verdict band, and the sprinkler head in the dedicated space (ringed) |
| P2 | Deck/balcony receptacle height, deck within 4 in of the dwelling | `final-exam-#1-008`, `open-book-exam-#10-020` | "6 ft 6 in max (78 in)" shown as "? max" (ringed) |
| P3 | Cover under 2 in of concrete, measured from the top of the slab | `final-exam-#1-049`, `open-book-exam-#4-004` | "18 in min" shown as "cover ?" (ringed) |
| P4 | Service panel: neutral bar, ground bar, jumper, GEC to rods, load with EGC | `open-book-exam-#1-002` (GEC variant for `#10-024`) | "MAIN BONDING JUMPER" (ringed) |

Shots, before, zoom (before) and after, for each prototype at desktop
1280x720 and phone 540x960: `.audit_tmp/shots/diagrams/<desk|mob>_<size>_<name>_<pre|zoom|post>.png`,
contact sheet `.audit_tmp/shots/diagrams/overview.png`.

To wire a prototype in later: copy its PNG into `assets/diagrams/`, add the
record to `diagrams.json` (without `pdf`/`page`, or widen the test's PDF
check), add its `masks.json` entry to `data/diagram_masks.json`, and decide
the card colour. The card is paper-white for PDF scans, and the zoom card is
too, so a dark figure sits on a white frame there.

Observed while prototyping: swapping to a *different* texture after
answering on the phone layout sent `DiagramView._update_height` and the page
layout into a resize loop (message-queue overflow). The mask approach keeps
one texture, so it never swaps, and the loop did not recur. Still, check a
new wide figure on the phone with `measure_fit.gd` before wiring it in.
