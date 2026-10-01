# Diagram gap scan (after the 88 planned diagrams)

Read-only scan of `data/question_bank.json` on master (`e22fcae`, which already contains all 88 original
diagrams: 48 drawings listed in `assets/diagrams/nec/figures.json`) plus the 3 PDF figures in
`assets/diagrams/diagrams.json` (final-exam-#1-005, #1-013, #1-047; redraw is queued separately).
The `wire-diagrams-audit` worktree is at the same commit, so it adds no extra records.

## Summary

- Total questions: **283**
- Covered: **88** by the 88 original diagrams (on 48 drawings) + **3** PDF figures = **91**
- Not covered: **192** -> HIGH **21**, MEDIUM **83**, NONE **88**
- Distinct new drawings needed: **50** (16 HIGH-tier drawings, 34 MEDIUM-only drawings), plus **6** questions that only need a new mask on an existing drawing
- HIGH-tier questions alone need 16 drawings (several of those drawings also serve MEDIUM questions).

Tier rules: HIGH = spatial layout, distances, grounding/fault paths, one-lines, location maps, hazardous boundaries.
MEDIUM = table lookups or calculations where a small card/sketch helps, construction cutaways, markings.
NONE = definitions, 'which article/table', listing/marking recall, NFPA 70E, Nebraska law, simple math.
Proposed concepts only show what the stem gives; the value that answers the question is always masked.

## Suggested batches

### Batch 1: 26 new drawings + 6 re-masks, 72 questions

All HIGH drawings, the MEDIUM drawings that each serve 3+ questions, plus 6 cheap re-masks of existing figures.

- `H02` Ampacity: counting current-carrying conductors and derating (3 q)
- `H16` Fault path to a metal enclosure vs. short vs. open circuit (2 q)
- `H03` Dwelling AFCI / tamper-resistant coverage map (4 q)
- `H04` Motor branch circuit anatomy (Article 430) (4 q)
- `H06` Hazardous locations: classes and divisions (3 q)
- `H05` Disconnect 'within sight' of motor / A-C equipment (2 q)
- `H07` Coordination of series overcurrent devices (one-line) (2 q)
- `H08` Busway passing through an exterior wall (over 1000 V) (1 q)
- `H09` Underground raceways: cinder fill and backfill (3 q)
- `H10` Panelboard interior: neutral terminals and unused openings (2 q)
- `H01` Floor area for load calculations (220.5(C)) (2 q)
- `H12` Multiple supplies to one building: directories and signs (2 q)
- `H13` Electric sign construction (2 q)
- `H11` Transformer-fed panelboard protection (1 q)
- `H14` Antenna clearance from overhead power lines (1 q)
- `H15` Hospital patient bed receptacles (517.18) (1 q)
- `M01` Switchboard sections and field-connection access (3 q)
- `M07` Insulation and cord letter decoder (4 q)
- `M08` Dwelling service/feeder conductor sizing (310.12) (3 q)
- `M09` Branch-circuit rating chain (3 q)
- `M13` Outbuilding disconnect ratings (225.39) (3 q)
- `M18` Flat conductor cable (FCC) under carpet squares (3 q)
- `M19` Cable and conductor construction cutaways (3 q)
- `M21` Raceway fill percentages and 3/8 in FMC (3 q)
- `M23` Dwelling appliance demand tables (220.54, 220.55) (3 q)
- `M26` Receptacle face markings and terminals (3 q)
- `R02` Reuse voltage_drop_percent (1 q)
- `R01` Reuse sine_wave_60hz_quarter_cycle (1 q)
- `R03` Reuse electrode_system_250-52_250-53 (1 q)
- `R04` Reuse equipment_receptacle_210-63 (1 q)
- `R05` Reuse pool_fountain_distances_680 (1 q)
- `R06` Reuse feeder_tap_10ft_240-21b1 (1 q)

### Batch 2: 24 new drawings, 32 questions

Remaining MEDIUM drawings (2-question groups first, then single-question ones).

- `M02` General lighting load from floor area (Table 220.42(A)) (2 q)
- `M06` Ohm's law / power wheel (2 q)
- `M10` EGC sizing from the OCPD (Table 250.122) (2 q)
- `M14` Single-load branch circuits (laundry, central heating) (2 q)
- `M16` Busbar cross-section ampacity (366.23(A)) (2 q)
- `M24` Welder supply calculations (Article 630) (2 q)
- `M25` Temperature limits at conductor end connections (110.14(C)) (2 q)
- `M34` RV park supply (551.71, 551.72) (2 q)
- `M03` Conductor color code (1 q)
- `M04` Fixed multioutlet assembly load (220.14(H)) (1 q)
- `M05` Holiday lighting spans supported by trees (590.4(J)) (1 q)
- `M11` OCPD enclosure mounting position (240.33) (1 q)
- `M12` Room air conditioner cord (440.64) (1 q)
- `M15` Battery room ventilation (480.10(A)) (1 q)
- `M17` Feeder protection for a group of motors (430.62(A)) (1 q)
- `M20` Cable bending radius (TC, 336.24) (1 q)
- `M22` RMC identification interval (344.120) (1 q)
- `M27` Light equipment supported from a box (314.27(D) Ex.) (1 q)
- `M28` Grounded conductor continuity (200.3) (1 q)
- `M29` Diagnostic imaging feeder demand (517.73(B)) (1 q)
- `M30` Spa/hot tub water level term (1 q)
- `M31` Free air circulation around equipment openings (110.13(B)) (1 q)
- `M32` Relay-operated control of a disconnect (1 q)
- `M33` Welding cable tray signs (630.42(C)) (1 q)

## Shared-diagram groups

| group | drawing | tier | questions | ids |
|---|---|---|---|---|
| `M01` Switchboard sections and field-connection access | new | MEDIUM | 3 | `final-exam-#1-002`, `open-book-exam-#1-007`, `open-book-exam-#1-015` |
| `M02` General lighting load from floor area (Table 220.42(A)) | new | MEDIUM | 2 | `final-exam-#1-004`, `open-book-exam-#1-021` |
| `M03` Conductor color code | new | MEDIUM | 1 | `final-exam-#1-009` |
| `M04` Fixed multioutlet assembly load (220.14(H)) | new | MEDIUM | 1 | `final-exam-#1-010` |
| `H02` Ampacity: counting current-carrying conductors and derating | new | HIGH | 3 | `final-exam-#1-014`, `final-exam-#1-027`, `final-exam-#3-057` |
| `M05` Holiday lighting spans supported by trees (590.4(J)) | new | MEDIUM | 1 | `final-exam-#1-016` |
| `M06` Ohm's law / power wheel | new | MEDIUM | 2 | `final-exam-#1-019`, `final-exam-#3-033` |
| `M07` Insulation and cord letter decoder | new | MEDIUM | 4 | `final-exam-#1-026`, `final-exam-#1-034`, `final-exam-#5-022`, `open-book-exam-#4-025` |
| `M08` Dwelling service/feeder conductor sizing (310.12) | new | MEDIUM | 3 | `final-exam-#1-036`, `final-exam-#3-065`, `open-book-exam-#4-022` |
| `H16` Fault path to a metal enclosure vs. short vs. open circuit | new | HIGH | 2 | `final-exam-#1-044`, `open-book-exam-#4-009` |
| `H03` Dwelling AFCI / tamper-resistant coverage map | new | HIGH | 4 | `final-exam-#1-048`, `open-book-exam-#4-005`, `open-book-exam-#4-012`, `open-book-exam-#4-023` |
| `M09` Branch-circuit rating chain | new | MEDIUM | 3 | `final-exam-#1-059`, `final-exam-#3-014`, `open-book-exam-#7-011` |
| `M10` EGC sizing from the OCPD (Table 250.122) | new | MEDIUM | 2 | `final-exam-#1-068`, `final-exam-#3-017` |
| `H04` Motor branch circuit anatomy (Article 430) | new | HIGH | 4 | `final-exam-#1-070`, `final-exam-#3-009`, `final-exam-#3-038`, `final-exam-#3-052` |
| `H06` Hazardous locations: classes and divisions | new | HIGH | 3 | `final-exam-#3-008`, `open-book-exam-#10-017`, `final-exam-#1-061` |
| `M11` OCPD enclosure mounting position (240.33) | new | MEDIUM | 1 | `final-exam-#3-015` |
| `M12` Room air conditioner cord (440.64) | new | MEDIUM | 1 | `final-exam-#3-018` |
| `H05` Disconnect 'within sight' of motor / A-C equipment | new | HIGH | 2 | `final-exam-#3-019`, `open-book-exam-#1-025` |
| `M13` Outbuilding disconnect ratings (225.39) | new | MEDIUM | 3 | `final-exam-#3-024`, `final-exam-#3-056`, `open-book-exam-#7-009` |
| `H07` Coordination of series overcurrent devices (one-line) | new | HIGH | 2 | `final-exam-#3-029`, `open-book-exam-#7-007` |
| `M14` Single-load branch circuits (laundry, central heating) | new | MEDIUM | 2 | `final-exam-#3-039`, `open-book-exam-#1-020` |
| `R02` Reuse voltage_drop_percent | reuse `voltage_drop_percent` | MEDIUM | 1 | `final-exam-#3-044` |
| `R01` Reuse sine_wave_60hz_quarter_cycle | reuse `sine_wave_60hz_quarter_cycle` | MEDIUM | 1 | `final-exam-#3-045` |
| `M15` Battery room ventilation (480.10(A)) | new | MEDIUM | 1 | `final-exam-#3-060` |
| `M16` Busbar cross-section ampacity (366.23(A)) | new | MEDIUM | 2 | `final-exam-#3-063`, `final-exam-#5-039` |
| `R03` Reuse electrode_system_250-52_250-53 | reuse `electrode_system_250-52_250-53` | MEDIUM | 1 | `final-exam-#3-066` |
| `M17` Feeder protection for a group of motors (430.62(A)) | new | MEDIUM | 1 | `final-exam-#3-069` |
| `M18` Flat conductor cable (FCC) under carpet squares | new | MEDIUM | 3 | `final-exam-#5-001`, `final-exam-#5-004`, `final-exam-#5-007` |
| `M19` Cable and conductor construction cutaways | new | MEDIUM | 3 | `final-exam-#5-020`, `open-book-exam-#10-015`, `final-exam-#5-003` |
| `M20` Cable bending radius (TC, 336.24) | new | MEDIUM | 1 | `final-exam-#5-023` |
| `M21` Raceway fill percentages and 3/8 in FMC | new | MEDIUM | 3 | `final-exam-#5-032`, `final-exam-#5-066`, `final-exam-#3-048` |
| `M22` RMC identification interval (344.120) | new | MEDIUM | 1 | `final-exam-#5-033` |
| `H08` Busway passing through an exterior wall (over 1000 V) | new | HIGH | 1 | `final-exam-#5-050` |
| `H09` Underground raceways: cinder fill and backfill | new | HIGH | 3 | `final-exam-#5-068`, `open-book-exam-#10-005`, `open-book-exam-#10-025` |
| `M23` Dwelling appliance demand tables (220.54, 220.55) | new | MEDIUM | 3 | `final-exam-#1-040`, `open-book-exam-#4-015`, `final-exam-#1-021` |
| `H10` Panelboard interior: neutral terminals and unused openings | new | HIGH | 2 | `final-exam-#3-046`, `open-book-exam-#1-009` |
| `M24` Welder supply calculations (Article 630) | new | MEDIUM | 2 | `final-exam-#1-025`, `final-exam-#3-040` |
| `H01` Floor area for load calculations (220.5(C)) | new | HIGH | 2 | `open-book-exam-#1-003`, `open-book-exam-#10-002` |
| `R04` Reuse equipment_receptacle_210-63 | reuse `equipment_receptacle_210-63` | MEDIUM | 1 | `open-book-exam-#1-018` |
| `R05` Reuse pool_fountain_distances_680 | reuse `pool_fountain_distances_680` | MEDIUM | 1 | `open-book-exam-#1-024` |
| `M26` Receptacle face markings and terminals | new | MEDIUM | 3 | `open-book-exam-#4-007`, `open-book-exam-#10-003`, `open-book-exam-#10-018` |
| `M27` Light equipment supported from a box (314.27(D) Ex.) | new | MEDIUM | 1 | `open-book-exam-#4-019` |
| `M28` Grounded conductor continuity (200.3) | new | MEDIUM | 1 | `open-book-exam-#7-001` |
| `M29` Diagnostic imaging feeder demand (517.73(B)) | new | MEDIUM | 1 | `open-book-exam-#7-004` |
| `M30` Spa/hot tub water level term | new | MEDIUM | 1 | `open-book-exam-#7-005` |
| `M31` Free air circulation around equipment openings (110.13(B)) | new | MEDIUM | 1 | `open-book-exam-#7-008` |
| `M25` Temperature limits at conductor end connections (110.14(C)) | new | MEDIUM | 2 | `open-book-exam-#7-015`, `open-book-exam-#7-017` |
| `H12` Multiple supplies to one building: directories and signs | new | HIGH | 2 | `open-book-exam-#7-016`, `open-book-exam-#7-025` |
| `H13` Electric sign construction | new | HIGH | 2 | `open-book-exam-#7-020`, `final-exam-#1-069` |
| `H11` Transformer-fed panelboard protection | new | HIGH | 1 | `open-book-exam-#7-021` |
| `R06` Reuse feeder_tap_10ft_240-21b1 | reuse `feeder_tap_10ft_240-21b1` | MEDIUM | 1 | `open-book-exam-#10-004` |
| `M32` Relay-operated control of a disconnect | new | MEDIUM | 1 | `open-book-exam-#10-006` |
| `M33` Welding cable tray signs (630.42(C)) | new | MEDIUM | 1 | `open-book-exam-#10-008` |
| `H14` Antenna clearance from overhead power lines | new | HIGH | 1 | `open-book-exam-#10-011` |
| `H15` Hospital patient bed receptacles (517.18) | new | HIGH | 1 | `open-book-exam-#10-019` |
| `M34` RV park supply (551.71, 551.72) | new | MEDIUM | 2 | `open-book-exam-#10-023`, `final-exam-#3-002` |

## HIGH (21 questions)

| id | topic | NEC ref | proposed diagram concept | shared group |
|---|---|---|---|---|
| `open-book-exam-#1-003` | Floor area measured from which dimensions | 220.5(C) | Dwelling floor plan: house footprint, attached garage, open porch and unfinished space, with dimension arrows on both wall faces. Which dimensions and which areas count is masked. | `H01` Floor area for load calculations (220.5(C)) |
| `open-book-exam-#10-002` | What dwelling square footage includes | 220.5(C) | Dwelling floor plan: house footprint, attached garage, open porch and unfinished space, with dimension arrows on both wall faces. Which dimensions and which areas count is masked. | `H01` Floor area for load calculations (220.5(C)) |
| `final-exam-#3-057` | Is the grounding conductor counted as current-carrying | 310.15(F) | Raceway cross-section with phase, neutral and equipment grounding conductors plus an ambient thermometer, beside a 3-step flow: Table 310.16 value, ambient correction, conductor-count adjustment. Which conductors count and the factors are masked. | `H02` Ampacity: counting current-carrying conductors and derating |
| `open-book-exam-#4-012` | AFCI protects the entire ___ | 210.12(A)(1) | Plan of a dwelling (with dorm, guest-suite and patient-room insets) shading the rooms that need AFCI; a panel-to-outlet strip showing how far AFCI protection must reach; receptacle symbols tagged for tamper resistance. The asked room/extent is masked. | `H03` Dwelling AFCI / tamper-resistant coverage map |
| `open-book-exam-#4-023` | AFCI receptacle locations (except ___) | 210.12(B), (C), and (D) | Plan of a dwelling (with dorm, guest-suite and patient-room insets) shading the rooms that need AFCI; a panel-to-outlet strip showing how far AFCI protection must reach; receptacle symbols tagged for tamper resistance. The asked room/extent is masked. | `H03` Dwelling AFCI / tamper-resistant coverage map |
| `final-exam-#3-009` | What the motor disconnect disconnects | 430.101 | One-line of a three-phase motor circuit: feeder tap, disconnect, short-circuit/ground-fault device, controller, overload units on the lines, motor and nameplate; note that table FLC (not nameplate) sizes the conductors. What the disconnect isolates and the overload count are masked. | `H04` Motor branch circuit anatomy (Article 430) |
| `final-exam-#3-052` | Overload units for a three-phase motor | Table 430.37 | One-line of a three-phase motor circuit: feeder tap, disconnect, short-circuit/ground-fault device, controller, overload units on the lines, motor and nameplate; note that table FLC (not nameplate) sizes the conductors. What the disconnect isolates and the overload count are masked. | `H04` Motor branch circuit anatomy (Article 430) |
| `final-exam-#3-019` | Device in sight of motor and driven machinery | 430.102(B)(1) | Plan view: motor with driven machinery, controller, disconnect, and a rooftop A-C unit, with sight lines and the 50 ft 'in sight' rule drawn. Which device must be in sight and its accessibility wording are masked. | `H05` Disconnect 'within sight' of motor / A-C equipment |
| `open-book-exam-#1-025` | A-C disconnect within sight and ___ | 440.14 | Plan view: motor with driven machinery, controller, disconnect, and a rooftop A-C unit, with sight lines and the 50 ft 'in sight' rule drawn. Which device must be in sight and its accessibility wording are masked. | `H05` Disconnect 'within sight' of motor / A-C equipment |
| `final-exam-#3-008` | Fibers stored/handled outside manufacturing: class/division | 500.5(D)(2) | Chart of classes (gas/vapor, combustible dust, ignitible fibers/flyings icons) plus a mill plan showing a manufacturing/handling area next to a storage room. Class and division labels are masked. | `H06` Hazardous locations: classes and divisions |
| `open-book-exam-#7-007` | Selective coordination exception for series devices | 708.54 Ex. | One-line: service OCPD, feeder OCPD, branch devices; a fault at one branch shows only the nearest upstream device opening. Second panel: two devices in series with and without other equipment connected in parallel with the downstream device. The term and the missing item are masked. | `H07` Coordination of series overcurrent devices (one-line) |
| `final-exam-#5-050` | Busway at building wall, over 1000 V | 368.234(A) | Section through a building wall with a busway running from inside to outside; the item required at the wall penetration is masked. | `H08` Busway passing through an exterior wall (over 1000 V) |
| `final-exam-#5-068` | RMC in cinder fill: concrete layer thickness | 344.10(C) | Trench section: RMC in cinder fill protected by a noncinder concrete layer (thickness masked) or placed 18 in below the fill; side panel contrasts prohibited backfill (large rocks, paving, cinders, sharp or corrosive material) with clean backfill; the harm it causes is masked. | `H09` Underground raceways: cinder fill and backfill |
| `open-book-exam-#1-009` | Grounded conductor terminal in a panelboard | 408.41 | Panelboard with its neutral bar (one grounded conductor per terminal vs. doubled up) and an empty breaker opening being closed. The terminal term and the closure type are masked. | `H10` Panelboard interior: neutral terminals and unused openings |
| `open-book-exam-#7-021` | Panel OCPD location when fed through a transformer | 408.36(B) | One-line: feeder to a transformer (its two sides drawn but not named) to a panelboard; the location of the panel's required overcurrent protection is masked. | `H11` Transformer-fed panelboard protection |
| `open-book-exam-#7-025` | Plaque/directory for multiple supplies | 225.37 | Building fed by a service plus a feeder and a branch circuit from another building, each supply with its own switching point; service entrance with a sign for an on-site emergency generator. Plaque placement and sign contents are masked. | `H12` Multiple supplies to one building: directories and signs |
| `final-exam-#1-069` | Wood sign enclosure spacing from lampholders | 600.9(C) | Cutaway of an electric sign: the weather-protective outer portion, the electrical enclosure and lampholders (part names masked); a wood enclosure with its spacing from the lampholders masked. | `H13` Electric sign construction |
| `open-book-exam-#10-011` | Antennas away from overhead power over ___ V | 810.16(B) | Elevation: outdoor rod antenna and dish mounted near overhead power conductors with a keep-away zone; the voltage threshold is masked. (Can be a second panel on the existing antenna_leadin_810-13 figure.) | `H14` Antenna clearance from overhead power lines |
| `open-book-exam-#10-019` | Receptacles at a Category 2 patient bed | 517.18(B)(1) | Headwall elevation at a Category 2 patient bed with receptacle positions; count/arrangement masked. | `H15` Hospital patient bed receptacles (517.18) |
| `final-exam-#1-044` | Unintended hot-to-enclosure connection (definition) | Article 100 | Circuit sketch: an ungrounded conductor contacting a metal enclosure, fault current returning over the EGC to the source; small side panels contrast an open circuit and a line-to-line short. Term names masked. | `H16` Fault path to a metal enclosure vs. short vs. open circuit |
| `open-book-exam-#4-009` | Unintended hot-to-enclosure connection (definition) | Article 100 | Circuit sketch: an ungrounded conductor contacting a metal enclosure, fault current returning over the EGC to the source; small side panels contrast an open circuit and a line-to-line short. Term names masked. | `H16` Fault path to a metal enclosure vs. short vs. open circuit |

## MEDIUM (83 questions)

| id | topic | NEC ref | proposed diagram concept | shared group |
|---|---|---|---|---|
| `final-exam-#1-014` | #12 THWN ampacity with ambient and 4 CCC | Table 310.16 | Raceway cross-section with phase, neutral and equipment grounding conductors plus an ambient thermometer, beside a 3-step flow: Table 310.16 value, ambient correction, conductor-count adjustment. Which conductors count and the factors are masked. | `H02` Ampacity: counting current-carrying conductors and derating |
| `final-exam-#1-027` | #10 THWN-2 ampacity at 112 F | Table 310.15(B)(1)(1) | Raceway cross-section with phase, neutral and equipment grounding conductors plus an ambient thermometer, beside a 3-step flow: Table 310.16 value, ambient correction, conductor-count adjustment. Which conductors count and the factors are masked. | `H02` Ampacity: counting current-carrying conductors and derating |
| `final-exam-#1-048` | Hallway receptacle: tamper-resistant | 406.12(1) | Plan of a dwelling (with dorm, guest-suite and patient-room insets) shading the rooms that need AFCI; a panel-to-outlet strip showing how far AFCI protection must reach; receptacle symbols tagged for tamper resistance. The asked room/extent is masked. | `H03` Dwelling AFCI / tamper-resistant coverage map |
| `open-book-exam-#4-005` | Hallway receptacle: tamper-resistant | 406.12(1) | Plan of a dwelling (with dorm, guest-suite and patient-room insets) shading the rooms that need AFCI; a panel-to-outlet strip showing how far AFCI protection must reach; receptacle symbols tagged for tamper resistance. The asked room/extent is masked. | `H03` Dwelling AFCI / tamper-resistant coverage map |
| `final-exam-#1-070` | Motor FLC from Table 430.250 | Table 430.250 | One-line of a three-phase motor circuit: feeder tap, disconnect, short-circuit/ground-fault device, controller, overload units on the lines, motor and nameplate; note that table FLC (not nameplate) sizes the conductors. What the disconnect isolates and the overload count are masked. | `H04` Motor branch circuit anatomy (Article 430) |
| `final-exam-#3-038` | SCGF device must carry the ___ current | 430.52(B) | One-line of a three-phase motor circuit: feeder tap, disconnect, short-circuit/ground-fault device, controller, overload units on the lines, motor and nameplate; note that table FLC (not nameplate) sizes the conductors. What the disconnect isolates and the overload count are masked. | `H04` Motor branch circuit anatomy (Article 430) |
| `final-exam-#1-061` | Class for ignitible fibers/flyings | 503.1 | Chart of classes (gas/vapor, combustible dust, ignitible fibers/flyings icons) plus a mill plan showing a manufacturing/handling area next to a storage room. Class and division labels are masked. | `H06` Hazardous locations: classes and divisions |
| `open-book-exam-#10-017` | Class for ignitible fibers/flyings | 500.5(D) | Chart of classes (gas/vapor, combustible dust, ignitible fibers/flyings icons) plus a mill plan showing a manufacturing/handling area next to a storage room. Class and division labels are masked. | `H06` Hazardous locations: classes and divisions |
| `final-exam-#3-029` | Localizing an overcurrent to the affected circuit (definition) | Article 100 | One-line: service OCPD, feeder OCPD, branch devices; a fault at one branch shows only the nearest upstream device opening. Second panel: two devices in series with and without other equipment connected in parallel with the downstream device. The term and the missing item are masked. | `H07` Coordination of series overcurrent devices (one-line) |
| `open-book-exam-#10-005` | Prohibited backfill (300.5(F)) | 300.5(F) | Trench section: RMC in cinder fill protected by a noncinder concrete layer (thickness masked) or placed 18 in below the fill; side panel contrasts prohibited backfill (large rocks, paving, cinders, sharp or corrosive material) with clean backfill; the harm it causes is masked. | `H09` Underground raceways: cinder fill and backfill |
| `open-book-exam-#10-025` | Prohibited backfill over 1000 V (305.15(E)) | 305.15(E) | Trench section: RMC in cinder fill protected by a noncinder concrete layer (thickness masked) or placed 18 in below the fill; side panel contrasts prohibited backfill (large rocks, paving, cinders, sharp or corrosive material) with clean backfill; the harm it causes is masked. | `H09` Underground raceways: cinder fill and backfill |
| `final-exam-#3-046` | Closing unused panelboard openings | 408.7 | Panelboard with its neutral bar (one grounded conductor per terminal vs. doubled up) and an empty breaker opening being closed. The terminal term and the closure type are masked. | `H10` Panelboard interior: neutral terminals and unused openings |
| `open-book-exam-#7-016` | Sign for on-site emergency power sources | 700.7(A) | Building fed by a service plus a feeder and a branch circuit from another building, each supply with its own switching point; service entrance with a sign for an on-site emergency generator. Plaque placement and sign contents are masked. | `H12` Multiple supplies to one building: directories and signs |
| `open-book-exam-#7-020` | Sign part that is not an electrical enclosure (definition) | Article 100 | Cutaway of an electric sign: the weather-protective outer portion, the electrical enclosure and lampholders (part names masked); a wood enclosure with its spacing from the lampholders masked. | `H13` Electric sign construction |
| `final-exam-#1-002` | Marking for rear/side field connections | 408.18(C) | Switchboard plan view seen from all four sides, with sections that need rear or side access for field connections and conductors routed to the section where they terminate. Marking location and section name masked. | `M01` Switchboard sections and field-connection access |
| `open-book-exam-#1-007` | Conductors in a switchboard section | 408.3(A)(2) | Switchboard plan view seen from all four sides, with sections that need rear or side access for field connections and conductors routed to the section where they terminate. Marking location and section name masked. | `M01` Switchboard sections and field-connection access |
| `open-book-exam-#1-015` | Marking for rear/side field connections | 408.18(C) | Switchboard plan view seen from all four sides, with sections that need rear or side access for field connections and conductors routed to the section where they terminate. Marking location and section name masked. | `M01` Switchboard sections and field-connection access |
| `final-exam-#1-004` | Office general lighting load, 5,000 sq ft | Table 220.42(A) | Office floor plan labeled 5,000 sq ft with a 3-step card: area x VA/sq ft (masked) = load (masked). | `M02` General lighting load from floor area (Table 220.42(A)) |
| `open-book-exam-#1-021` | Office general lighting load, 5,000 sq ft | Table 220.42(A) | Office floor plan labeled 5,000 sq ft with a 3-step card: area x VA/sq ft (masked) = load (masked). | `M02` General lighting load from floor area (Table 220.42(A)) |
| `final-exam-#1-009` | Acceptable ungrounded conductor color | 310.6(C) | Color swatch chart: colors reserved for grounded conductors, colors reserved for equipment grounding, and 'other colors' for ungrounded; the asked color masked. | `M03` Conductor color code |
| `final-exam-#1-010` | 12 ft multioutlet assembly load | 220.14(H) | 12 ft multioutlet assembly drawn to a ruler divided into equal segments with a VA tag per segment; segment length and VA masked. | `M04` Fixed multioutlet assembly load (220.14(H)) |
| `final-exam-#1-016` | Trees supporting holiday lighting spans | 590.4(J) | Overhead holiday-lighting span tied to a tree with a tension take-up device; the other permitted device masked. | `M05` Holiday lighting spans supported by trees (590.4(J)) |
| `final-exam-#1-019` | Meaning of I in W = E x I | General knowledge | Ohm's law and power wheel (E, I, R, P) with a worked example panel (2 W at 20 V DC) and the letter meanings; the asked letter meaning and result masked. | `M06` Ohm's law / power wheel |
| `final-exam-#3-033` | Current from 2 W at 20 V DC | General calculation | Ohm's law and power wheel (E, I, R, P) with a worked example panel (2 W at 20 V DC) and the letter meanings; the asked letter meaning and result masked. | `M06` Ohm's law / power wheel |
| `final-exam-#1-026` | Meaning of -2 in RHW-2 | Table 310.4(1) | Decoder cards for conductor, cable and cord type letters (R, H, W, the -2 suffix, underground-rated cable letters, and cord letters S, T, O, W); the asked letter/suffix meaning and type masked. | `M07` Insulation and cord letter decoder |
| `final-exam-#1-034` | Cord type for wet and sunlight | Table 400.4 | Decoder cards for conductor, cable and cord type letters (R, H, W, the -2 suffix, underground-rated cable letters, and cord letters S, T, O, W); the asked letter/suffix meaning and type masked. | `M07` Insulation and cord letter decoder |
| `final-exam-#5-022` | Cable type for direct burial | 338.100 | Decoder cards for conductor, cable and cord type letters (R, H, W, the -2 suffix, underground-rated cable letters, and cord letters S, T, O, W); the asked letter/suffix meaning and type masked. | `M07` Insulation and cord letter decoder |
| `open-book-exam-#4-025` | Cord type for wet and sunlight | Table 400.4 and Note 9 | Decoder cards for conductor, cable and cord type letters (R, H, W, the -2 suffix, underground-rated cable letters, and cord letters S, T, O, W); the asked letter/suffix meaning and type masked. | `M07` Insulation and cord letter decoder |
| `final-exam-#1-036` | Dwelling service conductor percentage | 310.12(A) | One-line of a single dwelling 120/240 V 3-wire service (100-400 A) with the conductor ampacity as a percentage of the service rating; the percentage and the applicable-system label masked. | `M08` Dwelling service/feeder conductor sizing (310.12) |
| `final-exam-#3-065` | Where Table 310.12(A) applies | 310.12(A) | One-line of a single dwelling 120/240 V 3-wire service (100-400 A) with the conductor ampacity as a percentage of the service rating; the percentage and the applicable-system label masked. | `M08` Dwelling service/feeder conductor sizing (310.12) |
| `open-book-exam-#4-022` | Dwelling service conductor percentage | 310.12(A) | One-line of a single dwelling 120/240 V 3-wire service (100-400 A) with the conductor ampacity as a percentage of the service rating; the percentage and the applicable-system label masked. | `M08` Dwelling service/feeder conductor sizing (310.12) |
| `final-exam-#1-059` | What sets a branch-circuit rating | 210.18 | 20 A breaker, branch-circuit conductors and several 15 A receptacles with cord-and-plug loads; tags show what sets the circuit rating, conductor ampacity vs. rating, and the max cord load per receptacle, all masked. | `M09` Branch-circuit rating chain |
| `final-exam-#3-014` | Max cord load on 15 A receptacle, 20 A circuit | Table 210.21(B)(2) | 20 A breaker, branch-circuit conductors and several 15 A receptacles with cord-and-plug loads; tags show what sets the circuit rating, conductor ampacity vs. rating, and the max cord load per receptacle, all masked. | `M09` Branch-circuit rating chain |
| `open-book-exam-#7-011` | Conductor ampacity vs. branch-circuit rating | 210.19(B) | 20 A breaker, branch-circuit conductors and several 15 A receptacles with cord-and-plug loads; tags show what sets the circuit rating, conductor ampacity vs. rating, and the max cord load per receptacle, all masked. | `M09` Branch-circuit rating chain |
| `final-exam-#1-068` | EGC for a 50 A circuit | Table 250.122 | Mini lookup strip: OCPD rating -> minimum copper EGC, drawn as breaker + wire pairs; the asked rows masked. | `M10` EGC sizing from the OCPD (Table 250.122) |
| `final-exam-#3-017` | EGC same size as circuit conductors | Table 250.122 | Mini lookup strip: OCPD rating -> minimum copper EGC, drawn as breaker + wire pairs; the asked rows masked. | `M10` EGC sizing from the OCPD (Table 250.122) |
| `final-exam-#3-015` | OCPD enclosure mounting position | 240.33 | Two panels mounted on a wall in different orientations; the required orientation masked (after-answer figure). | `M11` OCPD enclosure mounting position (240.33) |
| `final-exam-#3-018` | Room A-C cord length, 120 V | 440.64 | Through-wall room A-C with its cord running to a receptacle; cord length masked. | `M12` Room air conditioner cord (440.64) |
| `final-exam-#3-024` | Disconnect rating, two 2-wire circuits | 225.39(B) | Detached garage fed from a house in three panels: one limited-load circuit, two 2-wire circuits, and a general feeder; the minimum disconnect rating in each masked. | `M13` Outbuilding disconnect ratings (225.39) |
| `final-exam-#3-056` | Disconnect rating, one limited-load circuit | 225.39(A) | Detached garage fed from a house in three panels: one limited-load circuit, two 2-wire circuits, and a general feeder; the minimum disconnect rating in each masked. | `M13` Outbuilding disconnect ratings (225.39) |
| `open-book-exam-#7-009` | Disconnect rating vs. load served | 225.39 | Detached garage fed from a house in three panels: one limited-load circuit, two 2-wire circuits, and a general feeder; the minimum disconnect rating in each masked. | `M13` Outbuilding disconnect ratings (225.39) |
| `final-exam-#3-039` | Central heating equipment circuit type | 422.12 | Panel with a dedicated circuit to a laundry receptacle and another to a furnace, each with no other outlets; circuit rating and circuit type masked. | `M14` Single-load branch circuits (laundry, central heating) |
| `open-book-exam-#1-020` | Laundry branch circuit rating | 210.11(C)(2) | Panel with a dedicated circuit to a laundry receptacle and another to a furnace, each with no other outlets; circuit rating and circuit type masked. | `M14` Single-load branch circuits (laundry, central heating) |
| `final-exam-#3-060` | Battery gas ventilation | 480.10(A) | Battery rack in a room with gas rising to a high vent; the mixture type masked. | `M15` Battery room ventilation (480.10(A)) |
| `final-exam-#3-063` | Busbar ampacity, 1 1/2 sq in | 366.23(A) | Copper busbar cross-sections (1 1/2 sq in; 4 in x 1/2 in) with area worked out and the amps-per-square-inch density; density and result masked. | `M16` Busbar cross-section ampacity (366.23(A)) |
| `final-exam-#5-039` | Busbar ampacity, 4 in x 1/2 in | 366.23(A) | Copper busbar cross-sections (1 1/2 sq in; 4 in x 1/2 in) with area worked out and the amps-per-square-inch density; density and result masked. | `M16` Busbar cross-section ampacity (366.23(A)) |
| `final-exam-#3-069` | Feeder protection for motor group | 430.62(A) | Feeder one-line to several motors, each with its branch SCGF device and FLC; the feeder OCPD formula masked. | `M17` Feeder protection for a group of motors (430.62(A)) |
| `final-exam-#5-001` | FCC carpet square attachment | 324.41 | Layered cross-section: floor, bottom layer, FCC, top shield, carpet square; plus the transition to other wiring. Layer name, attachment method and connection device masked. | `M18` Flat conductor cable (FCC) under carpet squares |
| `final-exam-#5-004` | FCC connection to other wiring | 324.40(D) | Layered cross-section: floor, bottom layer, FCC, top shield, carpet square; plus the transition to other wiring. Layer name, attachment method and connection device masked. | `M18` Flat conductor cable (FCC) under carpet squares |
| `final-exam-#5-007` | FCC protective layer (definition) | Article 100 | Layered cross-section: floor, bottom layer, FCC, top shield, carpet square; plus the transition to other wiring. Layer name, attachment method and connection device masked. | `M18` Flat conductor cable (FCC) under carpet squares |
| `final-exam-#5-003` | Armored / metal-sheathed cable type (definition) | Article 100 | Cutaways of a mineral-insulated cable, an interlocking-armor / metallic-sheath cable and a copper-clad aluminum conductor cross-section; type letters, the asked features and the copper percentage masked. | `M19` Cable and conductor construction cutaways |
| `final-exam-#5-020` | MI cable construction | 332.104, 332.108, and 332.116 | Cutaways of a mineral-insulated cable, an interlocking-armor / metallic-sheath cable and a copper-clad aluminum conductor cross-section; type letters, the asked features and the copper percentage masked. | `M19` Cable and conductor construction cutaways |
| `open-book-exam-#10-015` | Copper-clad aluminum copper percentage | 310.3(B)(3) | Cutaways of a mineral-insulated cable, an interlocking-armor / metallic-sheath cable and a copper-clad aluminum conductor cross-section; type letters, the asked features and the copper percentage masked. | `M19` Cable and conductor construction cutaways |
| `final-exam-#5-023` | TC shielded cable bending radius | 336.24 | Shielded TC cable bent around a radius drawn as multiples of the cable diameter; the multiple masked. | `M20` Cable bending radius (TC, 336.24) |
| `final-exam-#3-048` | Largest THHN in 3/8 in FMC | Table 348.22 | Raceway cross-sections at 1, 2 and over-2 conductor fill, plus a 3/8 in FMC with its conductor-size limit (Table 348.22); the table reference and the largest size masked. | `M21` Raceway fill percentages and 3/8 in FMC |
| `final-exam-#5-032` | Largest conductor in 3/8 in FMC | 348.22 | Raceway cross-sections at 1, 2 and over-2 conductor fill, plus a 3/8 in FMC with its conductor-size limit (Table 348.22); the table reference and the largest size masked. | `M21` Raceway fill percentages and 3/8 in FMC |
| `final-exam-#5-066` | LFNC fill table in Chapter 9 | 356.22 | Raceway cross-sections at 1, 2 and over-2 conductor fill, plus a 3/8 in FMC with its conductor-size limit (Table 348.22); the table reference and the largest size masked. | `M21` Raceway fill percentages and 3/8 in FMC |
| `final-exam-#5-033` | RMC identification every 10 ft | 344.120 | Length of RMC with identification marks at a fixed interval; marking type masked. | `M22` RMC identification interval (344.120) |
| `final-exam-#1-021` | Demand load, 14 kW range | Table 220.55 | Worked cards: five dryers -> demand factor; a 14 kW range -> Column C plus the over-12 kW increase; factors and results masked. | `M23` Dwelling appliance demand tables (220.54, 220.55) |
| `final-exam-#1-040` | Demand factor, five dryers | Table 220.54 | Worked cards: five dryers -> demand factor; a 14 kW range -> Column C plus the over-12 kW increase; factors and results masked. | `M23` Dwelling appliance demand tables (220.54, 220.55) |
| `open-book-exam-#4-015` | Demand factor, five dryers | Table 220.54 | Worked cards: five dryers -> demand factor; a 14 kW range -> Column C plus the over-12 kW increase; factors and results masked. | `M23` Dwelling appliance demand tables (220.54, 220.55) |
| `final-exam-#1-025` | Arc welder OCPD from I1max | 630.12(A) | Arc welder (I1max nameplate -> OCPD multiplier) and resistance welder (duty cycle -> multiplier x primary current) cards; multipliers and results masked. | `M24` Welder supply calculations (Article 630) |
| `final-exam-#3-040` | Resistance welder supply ampacity | 630.31(A)(2) | Arc welder (I1max nameplate -> OCPD multiplier) and resistance welder (duty cycle -> multiplier x primary current) cards; multipliers and results masked. | `M24` Welder supply calculations (Article 630) |
| `open-book-exam-#7-015` | Corrected ampacity limited by the end-connection rating | 310.15(A) | Chain: 90 C conductor -> derated ampacity -> the device at the conductor's end rated 60/75 C; the limiting item and the rating term masked. | `M25` Temperature limits at conductor end connections (110.14(C)) |
| `open-book-exam-#7-017` | Pressure connector temperature rating | 110.14(C)(2) | Chain: 90 C conductor -> derated ampacity -> the device at the conductor's end rated 60/75 C; the limiting item and the rating term masked. | `M25` Temperature limits at conductor end connections (110.14(C)) |
| `open-book-exam-#10-003` | Receptacle grounding terminal use | 406.10(C) | Receptacle face and back: isolated-ground marking, TR/WR markings, terminal colors (brass, silver, green) and which conductor lands on the green screw; asked marking/conductor masked. | `M26` Receptacle face markings and terminals |
| `open-book-exam-#10-018` | Isolated ground receptacle marking | 406.3(E) | Receptacle face and back: isolated-ground marking, TR/WR markings, terminal colors (brass, silver, green) and which conductor lands on the green screw; asked marking/conductor masked. | `M26` Receptacle face markings and terminals |
| `open-book-exam-#4-007` | Isolated ground receptacle marking | 406.3(E) | Receptacle face and back: isolated-ground marking, TR/WR markings, terminal colors (brass, silver, green) and which conductor lands on the green screw; asked marking/conductor masked. | `M26` Receptacle face markings and terminals |
| `open-book-exam-#4-019` | Screws for <= 6 lb equipment on a box | 314.27(D) Ex. | Box with plaster ring and a light (<= 6 lb) fixture yoke fastened with two screws; screw size masked. | `M27` Light equipment supported from a box (314.27(D) Ex.) |
| `open-book-exam-#7-001` | Premises wiring connection to supply | 200.3 | Supply system with a grounded conductor tied to premises wiring vs. a supply without one; the connection term masked. | `M28` Grounded conductor continuity (200.3) |
| `open-book-exam-#7-004` | Imaging equipment feeder demand | 517.73(B) | Bar chart of units ranked by rating with 50% / 25% / 10% applied; the rating type masked. | `M29` Diagnostic imaging feeder demand (517.73(B)) |
| `open-book-exam-#7-005` | Highest water level before spilling (definition) | Article 100 | Hot tub section with a water line at the point it would spill; term masked. | `M30` Spa/hot tub water level term |
| `open-book-exam-#7-008` | Openings that need free air circulation | 110.13(B) | Equipment with side openings placed against a wall vs. with a free air path; opening type masked. | `M31` Free air circulation around equipment openings (110.13(B)) |
| `open-book-exam-#10-006` | Device that controls a disconnect through a relay (definition) | Article 100 | Schematic: remote pushbutton -> relay -> disconnect operator; term masked. | `M32` Relay-operated control of a disconnect |
| `open-book-exam-#10-008` | Welding cable tray sign text | 630.42(C) | Cable tray with permanent signs at 20 ft intervals; sign text masked. | `M33` Welding cable tray signs (630.42(C)) |
| `final-exam-#3-002` | RV feeder conductors, 208Y/120 V | 551.72(B) | RV park site plan with pedestals by receptacle type, and a 208Y/120 V 3-phase feeder cross-section; percentage and permitted conductors masked. | `M34` RV park supply (551.71, 551.72) |
| `open-book-exam-#10-023` | RV sites with 30 A receptacles | 551.71(B) | RV park site plan with pedestals by receptacle type, and a 208Y/120 V 3-phase feeder cross-section; percentage and permitted conductors masked. | `M34` RV park supply (551.71, 551.72) |
| `final-exam-#3-045` | AC cycles per second | General knowledge | Reuse the 60 Hz sine figure; the cycles-per-second term masked. | `R01` Reuse sine_wave_60hz_quarter_cycle |
| `final-exam-#3-044` | Voltage drop, sensitive electronics | 647.4(D) | Reuse the panel-to-load voltage-drop figure with a sensitive-electronics note; percentage masked. | `R02` Reuse voltage_drop_percent |
| `final-exam-#3-066` | Concrete-encased electrode exemption | 250.50 | Reuse the electrode figure with the concrete-encased electrode highlighted in an existing footing; the building type masked. | `R03` Reuse electrode_system_250-52_250-53 |
| `open-book-exam-#1-018` | Which receptacles need GFCI under 210.8(E) | 210.8(E) | Reuse the equipment service receptacle figure; the GFCI note masked. | `R04` Reuse equipment_receptacle_210-63 |
| `open-book-exam-#1-024` | Pool motor outlet GFCI amp limit | 680.21(C) and 680.5(B) | Reuse the pool figure with the pump-motor outlet and its branch-circuit rating note; the amp limit masked. | `R05` Reuse pool_fountain_distances_680 |
| `open-book-exam-#10-004` | Industrial control panel supply conductors | 409.21 | Reuse the tap figure with an industrial control panel on the load end; the conductor classification masked. | `R06` Reuse feeder_tap_10ft_240-21b1 |

## NONE (88 questions)

| id | stem (start) | NEC ref | why no diagram |
|---|---|---|---|
| `final-exam-#3-010` | The definition of “busbar” in Article 100 applies ___. | Article 100 | definition |
| `final-exam-#3-032` | A nursing home is an area used for the lodging, boarding, and nursing care, on a... | Article 100 | definition |
| `final-exam-#3-058` | The definition of “fibers/flyings, ignitible” is found in Article ___. | Article 100 | definition |
| `final-exam-#5-035` | A pliable raceway is a raceway which can be bent ___ with a reasonable force, bu... | Article 100 | definition |
| `open-book-exam-#10-009` | ___. The individual responsible for starting, stopping, and controlling an amuse... | Article 100 | definition |
| `open-book-exam-#4-001` | One who has skills and knowledge related to the construction and operation of th... | Article 100 | definition |
| `open-book-exam-#4-013` | Equipment or materials to which has been attached a symbol or other identifying ... | Article 100 | definition |
| `final-exam-#1-001` | 60% is equivalent to ___. | General knowledge | general knowledge or simple math |
| `final-exam-#1-046` | 40% is equivalent to ___. | General knowledge | general knowledge or simple math |
| `final-exam-#1-064` | When working from an electrical drawing, you should start from the ___. | General knowledge | general knowledge or simple math |
| `final-exam-#3-012` | Which of the following organizations would maintain records of tested electrical... | General knowledge | general knowledge or simple math |
| `final-exam-#3-022` | When working on live electrical circuits, the type of screwdriver that should be... | General knowledge | general knowledge or simple math |
| `final-exam-#3-062` | What is the standard abbreviation for power on an electrical diagram? | General knowledge | general knowledge or simple math |
| `final-exam-#1-006` | Decorative lighting and similar accessories used for holiday lighting and simila... | 590.5 | recall fact / wording |
| `final-exam-#1-007` | Insulated conductors used inside switchgear or switchboards are required to be _... | 408.19 | recall fact / wording |
| `final-exam-#1-015` | If festoon lighting is installed without a messenger, the smallest allowable ove... | 225.6(B) | recall fact / wording |
| `final-exam-#1-017` | The Code requires branch circuits be rated in accordance with the overcurrent pr... | 210.18 | recall fact / wording |
| `final-exam-#1-018` | Duty on elevator and dumbwaiter driving machine motors and driving motors of mot... | 620.61(B)(1) | recall fact / wording |
| `final-exam-#1-030` | Thermostatically controlled switching devices serving as both controllers and di... | 424.20(A)(3) | recall fact / wording |
| `final-exam-#1-037` | Nonmetallic cable trays shall be made of ___ material. | 392.100(F) | recall fact / wording |
| `final-exam-#1-038` | Type UF cable is permitted to be used ___. | 340.10(3) | recall fact / wording |
| `final-exam-#1-039` | A controller that includes motor overload protection ___ for group motor applica... | 430.8 | recall fact / wording |
| `final-exam-#1-054` | Flexible cords shall be used only in continuous lengths, without splices, other ... | 400.13 | recall fact / wording |
| `final-exam-#1-056` | The maximum ampere rating permitted for a 125 volt, single-phase receptacle outl... | 430.42(C) | recall fact / wording |
| `final-exam-#1-058` | Which of the following is not required to be marked on the nameplate of a transf... | 450.11(A) | recall fact / wording |
| `final-exam-#3-001` | A Universal Serial Bus flush device cover plate that additionally provides a nig... | 406.6(D) | recall fact / wording |
| `final-exam-#3-003` | The conductors supplying the supplementary overcurrent protective devices for fi... | 425.22(D) | recall fact / wording |
| `final-exam-#3-004` | In airports where maintenance and supervision conditions ensure that only qualif... | 392.10(E) | recall fact / wording |
| `final-exam-#3-005` | Low voltage heating power unit shall be an isolating type with a rated output no... | 424.101(A) | recall fact / wording |
| `final-exam-#3-016` | Heat generated internally in the conductor as the result of load current flow, i... | 310.14(A)(3) | recall fact / wording |
| `final-exam-#3-023` | Conductors in a non-jacketed multiconductor cable, such as ribbon cable in a per... | 522.21(B) | recall fact / wording |
| `final-exam-#3-025` | Supplementary overcurrent protection ___. | 240.10 | recall fact / wording |
| `final-exam-#3-026` | Electrical services and feeders shall be calculated on the basis of not less tha... | 626.11(A) | recall fact / wording |
| `final-exam-#3-028` | Appliances, ___ provided for public use rated 250v or less and 60 amps or less, ... | 422.5(A) | recall fact / wording |
| `final-exam-#3-030` | Torque requirements for motor control circuit device terminals must be a minimum... | 430.9(C) | recall fact / wording |
| `final-exam-#3-036` | Flexible cords approved for and used with a specific listed appliance or luminai... | 240.5(B)(1) | recall fact / wording |
| `final-exam-#3-037` | For ___ NUCC, the conduit must be trimmed away from the conductors or cables usi... | 354.28 | recall fact / wording |
| `final-exam-#3-042` | For cord-and-plug connected appliances, an accessible separable connector or ___... | 422.33 | recall fact / wording |
| `final-exam-#3-054` | All cut ends of flexible metal conduit must be trimmed or otherwise finished to ... | 348.28 | recall fact / wording |
| `final-exam-#3-061` | Where motors are provided with terminal housings, the housings must be of ___ an... | 430.12(A) | recall fact / wording |
| `final-exam-#3-067` | The rating of the attachment plug and receptacle must not exceed ___ @ 250 volts... | 440.55(B) | recall fact / wording |
| `final-exam-#3-068` | The disconnecting means for the main power supply conductors of an elevator shal... | 620.51(A) | recall fact / wording |
| `final-exam-#5-002` | Armored cable installed in thermal insulation shall have conductors rated at ___... | 320.80(A) | recall fact / wording |
| `final-exam-#5-005` | Tap devices used in FC assemblies shall be rated at not less than ___ amps or mo... | 322.56(B) | recall fact / wording |
| `final-exam-#5-008` | The minimum size copper conductor permitted for control and signal conductors in... | 330.104 | recall fact / wording |
| `final-exam-#5-017` | Which of the following statements about MI cable is correct? | 332.10(7) | recall fact / wording |
| `final-exam-#5-018` | The ampacity of Type UF cable shall be that of ___ conductors. | 340.80 | recall fact / wording |
| `final-exam-#5-019` | ___ cable shall be flame-retardant, moisture-resistant, fungus-resistant, and co... | 334.116(B) | recall fact / wording |
| `final-exam-#5-021` | SE cable used to supply ___ shall not be subject to conductor temperatures in ex... | 338.10(B)(3) | recall fact / wording |
| `final-exam-#5-024` | Types NM, NMC cables shall NOT be used as follows ___. | 334.12(A)(3) | recall fact / wording |
| `final-exam-#5-034` | Aluminum fittings and enclosures shall be permitted to be used with ___. | 358.14 | recall fact / wording |
| `final-exam-#5-036` | Rigid PVC conduit may be used ___. | 352.100, 352.12(B), and 352.60 | recall fact / wording |
| `final-exam-#5-037` | EMT shall be made of which of the following? | 358.100 | recall fact / wording |
| `final-exam-#5-038` | Liquidtight flexible metal conduit shall not be permitted ___. | 350.12 | recall fact / wording |
| `final-exam-#5-051` | Cablebus shall be installed only for ___ work. | 370.10 | recall fact / wording |
| `final-exam-#5-054` | Documentation of engineered design by a licensed professional engineer engaged p... | 395.30(A) | recall fact / wording |
| `final-exam-#5-055` | In general, the voltage limitation between conductors in surface nonmetallic rac... | 388.12(3) | recall fact / wording |
| `open-book-exam-#1-006` | Alternating current snap switches shall be permitted for control of inductive lo... | 404.14(B)(2) | recall fact / wording |
| `open-book-exam-#1-013` | As it relates to load calculations, calculations shall be permitted to be rounde... | 220.5(B) | recall fact / wording |
| `open-book-exam-#1-017` | Insulated conductors used inside switchgear or switchboards are required to be _... | 408.19 | recall fact / wording |
| `open-book-exam-#1-019` | All lamps for general illumination in temporary wiring installations shall be pr... | 590.4(F) | recall fact / wording |
| `open-book-exam-#1-023` | Decorative lighting and similar accessories used for holiday lighting and simila... | 590.5 | recall fact / wording |
| `open-book-exam-#10-001` | Motors and other rotating electrical machinery shall be totally enclosed or desi... | 547.30 | recall fact / wording |
| `open-book-exam-#10-007` | Which of the following statements is false? | 314.2 | recall fact / wording |
| `open-book-exam-#10-012` | A Class 1 power-limited circuit shall be supplied from a source having a rated o... | 724.40 | recall fact / wording |
| `open-book-exam-#10-014` | Size #18 or #16 fixture wires, and flexible cords shall be permitted for the con... | 660.9 | recall fact / wording |
| `open-book-exam-#10-022` | Conductors having ___ insulation and operating at different voltage levels shall... | 305.4 | recall fact / wording |
| `open-book-exam-#4-003` | Type NM cable is permitted for use under all the following conditions or locatio... | 334.12(B)(4) | recall fact / wording |
| `open-book-exam-#4-010` | For temporary wiring, a box, conduit body, or other enclosure shall ___ for spli... | 590.4(G) | recall fact / wording |
| `open-book-exam-#4-016` | A controller that includes motor overload protection ___ for group motor applica... | 430.8 | recall fact / wording |
| `open-book-exam-#4-017` | Type UF cable is permitted to be used ___. | 340.10(3) | recall fact / wording |
| `open-book-exam-#4-020` | Nonmetallic cable trays shall be made of ___ material. | 392.100(F) | recall fact / wording |
| `open-book-exam-#7-002` | ___ lists the direct-current resistance of conductors per kFT. | Table 8, Chapter 9 | recall fact / wording |
| `open-book-exam-#7-003` | Electrical equipment, such as switchboards, switchgear, panelboards, industrial ... | 110.16(A) | recall fact / wording |
| `open-book-exam-#7-006` | Flexible cord used in extension cords made with separately listed and installed ... | 240.5(B)(4) | recall fact / wording |
| `open-book-exam-#7-012` | Ferrous raceways and fittings protected from corrosion solely by ___ shall be pe... | 344.10(A)(3) | recall fact / wording |
| `open-book-exam-#7-014` | Table ___ lists metric designators and trade sizes for conduit, tubing, etc. | Table 300.1(C) | recall fact / wording |
| `open-book-exam-#7-018` | The ___ number of branch circuits shall be determined from the total calculated ... | 210.11(A) | recall fact / wording |
| `open-book-exam-#7-019` | Internal parts of electrical equipment, including busbars, wiring terminals, ins... | 110.12(B) | recall fact / wording |
| `open-book-exam-#7-023` | Terminations on ___ cables rated over 600 volts, nominal, shall be accessible on... | 400.36 | recall fact / wording |
| `final-exam-#3-011` | Most incidents and injuries are initiated by ___. | NFPA 70E | safety practice recall |
| `final-exam-#3-021` | Effective safe work practices are based on which of the following? | NFPA 70E | safety practice recall |
| `final-exam-#3-041` | Lockout/tagout is an important part of isolating electrical equipment to be work... | NFPA 70E | safety practice recall |
| `final-exam-#3-043` | The only way to see an electrical hazard is ___. | NFPA 70E | safety practice recall |
| `ne-state-act-#3-001` | How many apprentice fire alarm installers can be supervised at one time by a lic... | Neb. Rev. Stat. 81-2108(2) and 81-2113(2) | state law / rules |
| `ne-state-act-#3-002` | What type of new electrical work is an unsupervised apprentice electrician allow... | Neb. Rev. Stat. 81-2113(2) and 81-2113(3) | state law / rules |
| `ne-state-act-#3-003` | You are going to send a wiring crew to a new construction project. If you send t... | Neb. Rev. Stat. 81-2113(2) | state law / rules |
| `ne-state-act-#3-004` | According to the State Electrical Act and Board rules, it is the electrical cont... | Title 100 NAC Rule 13 | state law / rules |
