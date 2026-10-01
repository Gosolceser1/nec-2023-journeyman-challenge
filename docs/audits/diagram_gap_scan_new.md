# Diagram gap scan: the 315 new questions

Read-only scan of the questions imported at `09dc6b5` (598-question bank): Open Book #2, #3, #5, #6, #9, #11, #12
and Final #2, #4. Same tier rules as `diagram_gap_scan.md`. Each new question was compared with the 279 older NEC
questions (text similarity plus a manual read); where it asks the same thing, it is mapped to the older question's
drawing with the same masks and timing (`like` in the figure registry).

## Summary

- New questions: **315** -> HIGH **39**, MEDIUM **131**, NONE **145**
- Duplicates of older questions mapped to their existing drawing: **48**
- Other questions served by an existing drawing (new mask, or shown after answering): **24**
- New drawings: **19** figures for 18 groups (8 HIGH, 10 MEDIUM groups of 2+), serving **80** questions
- MEDIUM single questions not drawn (reason listed): **18**
- Questions with a figure after batch 3: **152** of 315

Tier rules: HIGH = spatial layout, distances, grounding/fault paths, one-lines, location maps.
MEDIUM = table lookups or calculations where a card or sketch helps, construction, markings.
NONE = definitions, 'which table', recall wording, simple math.
A duplicate keeps the tier of the question it repeats. The answer value is always masked or the figure is shown after answering.

## New drawings (batch 3)

| group | drawing | figure(s) | tier | when | questions | ids |
|---|---|---|---|---|---|---|
| `N-H1` | Driven electrodes: sizes and the three ways to install a rod | `electrode_rod_pipe_ring_250-52_250-53a4` | HIGH | before | 6 | `final-exam-#2-003`, `final-exam-#2-005`, `open-book-exam-#5-021`, `open-book-exam-#6-003`, `open-book-exam-#6-006`, `open-book-exam-#11-020` |
| `N-H2` | Portable fair structures near overhead power lines (525.5(B)) | `fair_structures_lines_525-5b` | HIGH | before | 2 | `final-exam-#2-001`, `open-book-exam-#5-001` |
| `N-H3` | Metal fence bonding near exposed live parts (250.194(A)) | `fence_bonding_250-194a` | HIGH | before | 2 | `final-exam-#2-059`, `open-book-exam-#11-007` |
| `N-H4` | Kitchen counter, bathroom and outdoor receptacles (210.52(B)-(E)) | `bath_counter_outdoor_210-52d_e1`, `kitchen_counter_210-52c` | HIGH | mixed | 5 | `open-book-exam-#2-007`, `open-book-exam-#3-001`, `final-exam-#4-010`, `final-exam-#4-015`, `final-exam-#4-016` |
| `N-H5` | Show window receptacles and load (210.62, 220.14(G)) | `show_window_210-62_220-14g` | HIGH | before | 2 | `open-book-exam-#2-009`, `final-exam-#4-012` |
| `N-H6` | Therapeutic tub: GFCI zone around the tub (680.62(E)) | `therapeutic_tub_gfci_680-62e` | HIGH | before | 1 | `open-book-exam-#2-023` |
| `N-H7` | Direct-buried conductors: emerging from grade and frost S-loops (300.5(D)(1), 300.5(J)) | `buried_conductors_grade_300-5d1_300-5j` | HIGH | before | 2 | `open-book-exam-#6-008`, `open-book-exam-#5-020` |
| `N-H8` | Luminaire under metal roof decking (410.10(F)) | `luminaire_roof_decking_410-10f` | HIGH | before | 1 | `open-book-exam-#3-021` |
| `N-M1` | Series vs. parallel circuits: what is shared | `series_vs_parallel` | MEDIUM | after | 3 | `final-exam-#2-013`, `final-exam-#2-014`, `final-exam-#2-016` |
| `N-M2` | AC waveforms: peak, effective, alternation, lead and lag | `ac_wave_values_phase` | MEDIUM | after | 4 | `final-exam-#2-018`, `final-exam-#2-034`, `final-exam-#2-017`, `final-exam-#2-056` |
| `N-M3` | Transformer turns ratio | `transformer_turns_ratio` | MEDIUM | after | 2 | `final-exam-#2-012`, `final-exam-#2-015` |
| `N-M4` | What changes a conductor's resistance | `resistance_factors` | MEDIUM | after | 2 | `final-exam-#2-019`, `final-exam-#2-055` |
| `N-M5` | Box fill: counting and volume (314.16) | `box_fill_steps_314-16` | MEDIUM | after | 8 | `final-exam-#2-065`, `open-book-exam-#11-023`, `final-exam-#4-005`, `final-exam-#4-011`, `final-exam-#4-021`, `final-exam-#4-038`, `final-exam-#4-054`, `final-exam-#4-064` |
| `N-M6` | Ampacity: ambient correction and conductor-count adjustment | `ampacity_steps_310-15` | MEDIUM | after | 7 | `final-exam-#4-024`, `final-exam-#4-031`, `final-exam-#4-033`, `final-exam-#4-035`, `final-exam-#4-040`, `final-exam-#4-041`, `final-exam-#4-063` |
| `N-M7` | Conduit fill: conductor areas against the 40% column | `conduit_fill_steps_ch9` | MEDIUM | after | 9 | `final-exam-#4-022`, `final-exam-#4-050`, `final-exam-#4-057`, `final-exam-#4-059`, `final-exam-#4-060`, `final-exam-#4-062`, `final-exam-#4-065`, `final-exam-#4-066`, `final-exam-#4-068` |
| `N-M8` | Ranges, ovens and dryers: demand columns (Table 220.55, 220.54) | `cooking_dryer_demand_220-54_220-55` | MEDIUM | after | 8 | `final-exam-#4-023`, `final-exam-#4-025`, `final-exam-#4-036`, `final-exam-#4-045`, `final-exam-#4-046`, `final-exam-#4-049`, `final-exam-#4-051`, `final-exam-#4-069` |
| `N-M9` | Motor circuit sizing by percentages (Article 430) | `motor_percentages_430` | MEDIUM | after | 11 | `final-exam-#4-026`, `final-exam-#4-030`, `final-exam-#4-032`, `final-exam-#4-034`, `final-exam-#4-037`, `final-exam-#4-039`, `final-exam-#4-053`, `final-exam-#4-056`, `final-exam-#4-061`, `final-exam-#4-067`, `final-exam-#4-070` |
| `N-M10` | Dwelling general lighting and small-appliance load (220.41, 220.52, 220.53) | `dwelling_loads_220-41_220-53` | MEDIUM | after | 5 | `final-exam-#4-027`, `final-exam-#4-028`, `final-exam-#4-047`, `final-exam-#4-048`, `final-exam-#4-042` |

- `N-H1` Section view: an 8 ft rod driven vertically, at an angle, and laid in a trench where rock is hit, next to size tags for a copper-coated steel rod, a steel pipe electrode and a ground-ring conductor. The asked size, angle or trench depth is masked.
- `N-H2` Elevation: carnival ride and tent with overhead conductors, the 15 ft horizontal keep-out zone drawn under and beside the lines; the voltage threshold is masked.
- `N-H3` Plan of a fenced outdoor substation: exposed conductors inside, fence sections within the bonding distance bonded to the grounding electrode system; the distance is masked.
- `N-H4` Kitchen counter elevation with the wall-line spacing and the height above the counter, a bathroom basin counter, a small-appliance circuit map (kitchen, dining, pantry), and a house plan with outlets at the front and back. The asked distance/count/room is masked.
- `N-H5` Show window elevation: receptacle within a distance of the top of the window and no point more than 6 ft away, plus the per-foot load along the window length; the distance and VA are masked.
- `N-H6` Plan of a therapy room with a hydrotherapy tub and the GFCI radius drawn around it; the radius is masked.
- `N-H7` Section at a pole/wall: direct-buried conductors rising out of grade inside a raceway up to a height (masked), and a trench with slack loops where the soil heaves; the loop form is masked.
- `N-H8` Section under corrugated metal roof decking with a luminaire held down from the lowest surface; the clearance is masked.
- `N-M1` Two small schematics: a series string (same current, voltages add) with a lamp and a heater, and a parallel circuit (same voltage across each branch, currents add). The asked rule is masked. Built as a teaching card shown after answering (the answer is the concept itself); each question's step is outlined.
- `N-M2` Sine wave with peak and effective (RMS) levels and a half cycle marked, plus a voltage/current pair shifted in time for an inductive load. The asked name is masked. Built as a teaching card shown after answering (the answer is the concept itself); each question's step is outlined.
- `N-M3` Primary and secondary windings drawn with turn counts and voltages for a step-down transformer; ratio meaning and which side has more turns masked. Built as a teaching card shown after answering (the answer is the concept itself); each question's step is outlined.
- `N-M4` Conductor drawn longer and thinner with the resistance scaling, plus length / area / temperature / material tags; the scaled result and the non-factor are masked. Built as a teaching card shown after answering (the answer is the concept itself); each question's step is outlined.
- `N-M5` Device box opened up: conductors, clamps, a device on its yoke and EGCs with how each is counted, and the box-volume formula (length x width x depth). The asked count/volume is masked. Built as a teaching card shown after answering (the answer is the concept itself); each question's step is outlined.
- `N-M6` Raceway with N current-carrying conductors and a thermometer; the steps Table 310.16 -> x ambient factor (Table 310.15(B)(1)(1)) -> x count factor (Table 310.15(C)(1)). The asked factor is masked. Built as a teaching card shown after answering (the answer is the concept itself); each question's step is outlined.
- `N-M7` Raceway cross-section with mixed conductors; steps Table 5 area x count = total, Table 4 allowable fill for the raceway type and size, compare or divide. Results masked. Built as a teaching card shown after answering (the answer is the concept itself); each question's step is outlined.
- `N-M8` Column chooser by nameplate kW (A, B, C), the Note 1 increase over 12 kW, the Note 4 branch-circuit rules and the dryer 5 kW minimum with the neutral factor. No answer values drawn. Built as a teaching card shown after answering (the answer is the concept itself); each question's step is outlined.
- `N-M9` Motor branch circuit one-line: table FLC -> conductors 125%, feeder 125% of largest + others, SCGF device from Table 430.52(C)(1), overloads 125%/115% of nameplate (and the 140%/130% ceiling). The asked percentage masked. Built as a teaching card shown after answering (the answer is the concept itself); each question's step is outlined.
- `N-M10` House plan with living area x 3 VA, general-purpose receptacles included, circuits from the load, two small-appliance circuits and the laundry circuit at 1,500 VA, and the 75% factor for 4+ fastened-in-place appliances. Results masked. Built as a teaching card shown after answering (the answer is the concept itself); each question's step is outlined.

## Existing drawings reused

| id | drawing | masks like | when | note |
|---|---|---|---|---|
| `final-exam-#4-052` | `floor_area_220-5c` | `open-book-exam-#1-003` | before | outside vs. inside dimensions (masks of open-book-exam-#1-003) |
| `final-exam-#2-036` | `parallel_resistors_equal` | - | after | the figure shows R/N, so it teaches after the answer |
| `final-exam-#2-038` | `branch_circuit_rating_210` | `final-exam-#1-059` | before | rating label masked as for final-exam-#1-059 |
| `open-book-exam-#9-012` | `branch_circuit_rating_210` | `final-exam-#1-059` | before | same |
| `open-book-exam-#9-018` | `branch_circuit_rating_210` | - | after | 'circuit' is in the drawing's title, so it teaches after the answer |
| `open-book-exam-#9-016` | `termination_temp_110-14c` | - | after | repeat of open-book-exam-#7-017 with the other blank; the drawing names the connector |
| `open-book-exam-#2-002` | `multiwire_branch_circuit_210-4` | - | before | handle tie at the panel = where the circuit originates (word not drawn) |
| `open-book-exam-#2-011` | `afci_tr_dwelling_210-12_406-12` | - | after | shading shows the answer rooms |
| `open-book-exam-#11-021` | `afci_tr_dwelling_210-12_406-12` | - | after | TR note shows the answer |
| `open-book-exam-#3-004` | `gfci_locations_210-8` | - | after | laundry GFCI shown; AFCI half of the answer comes after |
| `open-book-exam-#5-016` | `gfci_locations_210-8` | - | after | shows two of the three locations |
| `open-book-exam-#2-001` | `ocpd_vertical_240-33` | `final-exam-#3-015` | after | mounting position (after, as final-exam-#3-015) |
| `open-book-exam-#5-007` | `high_leg_marking_408-3f1` | - | after | the drawing labels the high leg B |
| `open-book-exam-#12-010` | `high_leg_marking_408-3f1` | - | before | orange is in the stem; the answer is not drawn |
| `open-book-exam-#5-024` | `supports_pvc_352-30` | `final-exam-#5-070` | after | 'within 3 ft' is the answer (after, as final-exam-#5-070) |
| `open-book-exam-#6-016` | `supports_pvc_352-30` | - | before | shows the small-size spacing and points to Table 352.30(B) |
| `final-exam-#4-055` | `egc_size_250-122` | - | after | the 100 A row is drawn unmasked |
| `open-book-exam-#12-023` | `egc_size_250-122` | - | after | the 250.122(A) note is the answer |
| `open-book-exam-#11-001` | `balcony_receptacle_210-52e3` | - | before | new mask over 'within 4 in' |
| `open-book-exam-#6-005` | `overhead_clearances_225-18` | `final-exam-#1-053` | after | clearance ladder (after, as final-exam-#1-053) |
| `open-book-exam-#12-025` | `overhead_clearances_225-18` | `final-exam-#1-053` | after | same |
| `final-exam-#2-064` | `in_sight_disconnect_430-102_440-14` | - | after | in sight vs. out of sight; the lockable exception after |
| `open-book-exam-#11-022` | `in_sight_disconnect_430-102_440-14` | - | after | same |
| `open-book-exam-#6-009` | `in_sight_disconnect_430-102_440-14` | - | after | same |

## Duplicates of older questions

| new id | same as | drawing |
|---|---|---|
| `final-exam-#2-006` | `open-book-exam-#7-020` | `sign_construction_600` |
| `final-exam-#2-008` | `open-book-exam-#7-025` | `multiple_supplies_225-37_700-7` |
| `final-exam-#2-009` | `open-book-exam-#7-005` | `max_water_level_art100` |
| `final-exam-#2-043` | `open-book-exam-#10-005` | `cinder_backfill_344-10c_300-5f` |
| `final-exam-#2-044` | `open-book-exam-#10-013` | `raceway_supported_box_314-23e` |
| `final-exam-#2-045` | `open-book-exam-#10-015` | `cable_cutaways_332_310` |
| `final-exam-#2-046` | `open-book-exam-#10-016` | `working_space_110-26` |
| `final-exam-#2-047` | `open-book-exam-#10-018` | `receptacle_markings_406` |
| `final-exam-#2-048` | `open-book-exam-#10-019` | `patient_bed_receptacles_517-18` |
| `final-exam-#2-049` | `open-book-exam-#10-020` | `balcony_receptacle_210-52e3` |
| `final-exam-#4-003` | `final-exam-#5-066` | `raceway_fill_ch9_348-22` |
| `open-book-exam-#2-004` | `final-exam-#3-006` | `gfci_locations_210-8` |
| `open-book-exam-#2-008` | `final-exam-#1-016` | `holiday_lighting_trees_590-4j` |
| `open-book-exam-#2-012` | `final-exam-#1-014` | `ampacity_derating_310-15` |
| `open-book-exam-#2-013` | `final-exam-#1-012` | `gfci_locations_210-8` |
| `open-book-exam-#2-015` | `final-exam-#1-011` | `dwelling_receptacles_210-52` |
| `open-book-exam-#2-018` | `final-exam-#1-010` | `multioutlet_assembly_220-14h` |
| `open-book-exam-#2-022` | `final-exam-#1-009` | `conductor_colors_310-6` |
| `open-book-exam-#2-025` | `final-exam-#1-008` | `balcony_receptacle_210-52e3` |
| `open-book-exam-#3-002` | `final-exam-#1-032` | `feeder_tap_10ft_240-21b1` |
| `open-book-exam-#3-003` | `final-exam-#1-031` | `dwelling_receptacles_210-52` |
| `open-book-exam-#3-008` | `final-exam-#1-029` | `conduit_stub_up_408-5` |
| `open-book-exam-#3-009` | `final-exam-#1-028` | `fuel_dispenser_shutoff_514-11` |
| `open-book-exam-#3-010` | `final-exam-#1-027` | `ampacity_derating_310-15` |
| `open-book-exam-#3-011` | `final-exam-#1-026` | `type_letters_decoder` |
| `open-book-exam-#3-012` | `open-book-exam-#1-024` | `pool_fountain_distances_680` |
| `open-book-exam-#3-013` | `final-exam-#1-025` | `welder_supply_630` |
| `open-book-exam-#3-015` | `final-exam-#1-024` | `pool_fountain_distances_680` |
| `open-book-exam-#3-016` | `final-exam-#1-023` | `parallel_egc_250-122f` |
| `open-book-exam-#3-017` | `final-exam-#1-022` | `dwelling_receptacles_210-52` |
| `open-book-exam-#3-019` | `final-exam-#1-021` | `appliance_demand_220-54_220-55` |
| `open-book-exam-#3-020` | `final-exam-#1-020` | `electrode_system_250-52_250-53` |
| `open-book-exam-#5-004` | `final-exam-#1-057` | `dedicated_space_110-26e` |
| `open-book-exam-#5-010` | `final-exam-#1-055` | `framing_protection_300-4` |
| `open-book-exam-#5-014` | `final-exam-#1-053` | `overhead_clearances_225-18` |
| `open-book-exam-#5-015` | `final-exam-#1-052` | `mobile_home_disconnect_550-32f` |
| `open-book-exam-#5-017` | `final-exam-#1-051` | `working_space_110-26` |
| `open-book-exam-#5-018` | `final-exam-#1-050` | `communications_overhead_800-44` |
| `open-book-exam-#6-010` | `final-exam-#1-070` | `motor_circuit_430` |
| `open-book-exam-#6-012` | `final-exam-#1-068` | `egc_size_250-122` |
| `open-book-exam-#6-014` | `final-exam-#1-067` | `nipple_fill_ch9_note4` |
| `open-book-exam-#6-018` | `final-exam-#3-060` | `battery_ventilation_480-10a` |
| `open-book-exam-#6-022` | `final-exam-#1-066` | `supports_unsupported_cable_320-330-334` |
| `open-book-exam-#6-023` | `final-exam-#1-060` | `pool_fountain_distances_680` |
| `open-book-exam-#6-024` | `final-exam-#1-059` | `branch_circuit_rating_210` |
| `open-book-exam-#11-002` | `final-exam-#3-046` | `panelboard_interior_408` |
| `open-book-exam-#11-009` | `final-exam-#5-049` | `nm_extension_floor_382-15a` |
| `open-book-exam-#12-022` | `final-exam-#3-013` | `supports_emt_strut_358-30` |

## MEDIUM single questions not drawn

| id | topic | NEC | why not |
|---|---|---|---|
| `final-exam-#2-025` | Overhead spans of ___ conductors, and multiconductor cables of the same kind, shall have a... | 225.19(A) | roof clearance is given in the stem; the asked word (open conductors) is not a picture |
| `final-exam-#2-052` | If a 240 volt heater is used on 120 volts, the amount of heat produced will be ___. | General knowledge | one-line power arithmetic (P = E^2/R); the formula strip covers it |
| `final-exam-#2-063` | If the emergency disconnecting means required in 230.85 for dwelling units is a meter disc... | 230.85(B) | one-word location rule for the dwelling emergency disconnect |
| `final-exam-#4-004` | A single piece of equipment consisting of a multiple receptacle comprised of ___ or more r... | 220.14(I) | one multiplication (receptacles x 90 VA) |
| `final-exam-#4-029` | #2/0 THW copper service conductors would require a grounding electrode conductor of ___. | Table 250.66 | a single Table 250.66 lookup; the existing GEC drawing shows a different rule and its value |
| `final-exam-#4-058` | The maximum current on the neutral with either Line one or Line two on is ___ amps if the ... | General calculation | one division (larger line load / 120 V) |
| `open-book-exam-#2-017` | For the purpose of this section, where using multioutlet assemblies, each ___ of multioutl... | 210.52(C) | one number; the multioutlet drawing uses the 220.14(H) 5 ft / 1 ft rule and would confuse |
| `open-book-exam-#3-018` | Track lighting where installed in a continuous row, each individual section of not more th... | 410.154 | one support interval |
| `open-book-exam-#3-025` | When an installation uses metal conduits entering service equipment or enclosures with con... | 250.92(B) | bonding-type locknut wording; a knockout sketch adds little |
| `open-book-exam-#5-005` | Grounded conductors of circuits with parallel conductors in a panelboard shall be permitte... | 408.41 | exception to the one-conductor-per-terminal rule; the panelboard drawing shows the general rule |
| `open-book-exam-#5-023` | Where exposed NM cable passes through a floor, the NM cable shall be protected from damage... | 334.15(B) | one protection height |
| `open-book-exam-#6-011` | In panelboards, fuses of any type shall be installed on the ___ side of any switches. | 408.39 | one-word line/load placement |
| `open-book-exam-#6-013` | Liquidtight flexible metal conduit (LFMC) shall be securely fastened in place by an approv... | 350.30(A) | one support interval |
| `open-book-exam-#9-009` | For motors marked with design letters B, C, or D, conductors having a higher insulation ra... | 110.14(C)(1) | design-letter exception; the termination drawing shows a different rule |
| `open-book-exam-#9-015` | Boxes that enclose devices or utilization equipment that projects more than ___ rearward f... | 314.24(B)(1) | one projection limit; the box-depth drawing shows 314.24(B)(5) and would confuse |
| `open-book-exam-#11-025` | MI cable shall be supported and secured by staples, straps, hangers, or similar fittings, ... | 332.30 | one support interval |
| `open-book-exam-#12-003` | The emergency shutoff device for a fuel dispenser must simultaneously disconnect all condu... | 514.11(A) | which conductors the shutoff opens; the dispenser drawing is about distances |
| `open-book-exam-#12-024` | In a high bay manufacturing building, what is the maximum total length of a feeder tap con... | 240.21(B)(4) | one tap length (high-bay 100 ft) |

## NONE (145 questions)

| id | stem (start) | NEC | why no diagram |
|---|---|---|---|
| `final-exam-#2-041` | Which of the following is not considered part of a luminaire? | Article 100 | definition |
| `final-exam-#4-007` | A value assigned to a circuit or system for the purpose of conveniently designating its vo... | Article 100 | definition |
| `open-book-exam-#11-003` | A point on the wiring system at which current is taken to supply utilization equipment is ... | Article 100 | definition |
| `open-book-exam-#11-012` | A multifamily dwelling is a building that contains ___ or more dwelling units. | Article 100 | definition |
| `open-book-exam-#12-015` | A device that uses power electronics to convert one form of electrical power into another ... | Article 100 | definition |
| `open-book-exam-#2-020` | A ___ location may be temporarily subject to dampness and wetness. | Article 100 | definition |
| `open-book-exam-#6-002` | The ampacity of a conductor is the current, in amperes, that the conductor can carry conti... | Article 100 | definition |
| `open-book-exam-#9-025` | Which of the following is not considered part of a luminaire? | Article 100 | definition |
| `final-exam-#2-011` | An open resistor when checked with an ohmmeter reads ___. | General knowledge | general knowledge or simple math |
| `final-exam-#2-031` | ___ is the process by which one conductor produces or induces a voltage in another conduct... | General knowledge | general knowledge or simple math |
| `final-exam-#2-032` | Electrical current is measured in terms of ___. | General knowledge | general knowledge or simple math |
| `final-exam-#2-033` | The resistance of a circuit may vary due to ___. | General knowledge | general knowledge or simple math |
| `final-exam-#2-035` | A shunt is used to measure ___. | General knowledge | general knowledge or simple math |
| `final-exam-#2-051` | The total opposition to current flow in an AC circuit is expressed in ohms and is called _... | General knowledge | general knowledge or simple math |
| `final-exam-#2-053` | The length of time that a fault current would flow on the equipment grounding conductor wo... | General knowledge | general knowledge or simple math |
| `final-exam-#2-054` | A one-quarter bend in a raceway is equivalent to an angle of ___ degrees. | General knowledge | general knowledge or simple math |
| `final-exam-#2-057` | The decimal equivalent for 11/16" is ___. | General calculation | general knowledge or simple math |
| `final-exam-#2-002` | Which of the following wiring methods is not permitted in the ceiling space used as a retu... | 300.22(C)(1) | recall fact / wording |
| `final-exam-#2-004` | Shore power for boats shall be provided by single receptacles rated not less than ___ ampe... | 555.33(A)(4) | recall fact / wording |
| `final-exam-#2-007` | Internal parts of electrical equipment, including busbars, wiring terminals, insulators, a... | 110.12(B) | recall fact / wording |
| `final-exam-#2-010` | The ___ number of branch circuits shall be determined from the total calculated load and t... | 210.11(A) | recall fact / wording |
| `final-exam-#2-020` | Flexible cord used in extension cords made with separately listed and installed components... | 240.5(B)(4) | recall fact / wording |
| `final-exam-#2-021` | Warning signs shall be ___ posted at points of access to conductors in all conduit systems... | 305.12 | recall fact / wording |
| `final-exam-#2-022` | The grounding electrode conductor shall be of copper, aluminum, copper-clad aluminum, or t... | 250.62 | recall fact / wording |
| `final-exam-#2-023` | One type of enclosure permitted for use in outdoor corrosive environments is ___. | Table 110.28 | recall fact / wording |
| `final-exam-#2-026` | Nonconductive coatings (such as paint, lacquer, and enamel) on equipment to be grounded sh... | 250.12 | recall fact / wording |
| `final-exam-#2-030` | Signs and outline lighting systems with lampholders for incandescent lamps shall be marked... | 600.4(C) | recall fact / wording |
| `final-exam-#2-042` | Galvanized steel, stainless steel, and ___ RMC shall be permitted under all atmospheric co... | 344.10(A)(1) | recall fact / wording |
| `final-exam-#2-050` | Conductors having ___ insulation and operating at different voltage levels shall not occup... | 305.4 | recall fact / wording |
| `final-exam-#2-058` | Extreme ___ may cause PVC conduit to become brittle, and therefore more susceptible to dam... | 352.10 | recall fact / wording |
| `final-exam-#2-060` | In multifamily dwellings, Type NM Cable is permitted in buildings that are permitted to be... | 334.10 | recall fact / wording |
| `final-exam-#2-061` | When sizing a branch circuit for a fixed storage-type water heater with a capacity of 120 ... | 422.13 | recall fact / wording |
| `final-exam-#2-062` | In other than one- and two-family dwelling units, the available fault current and the date... | 408.6 | recall fact / wording |
| `final-exam-#2-066` | Equipment intended to interrupt current at fault levels shall have a/an ___ rating, at nom... | 110.9 | recall fact / wording |
| `final-exam-#2-067` | Vegetation such as trees shall not be used for support of ___. | 225.26 | recall fact / wording |
| `final-exam-#2-068` | A luminaire in a commercial cooking hood must, among other requirements, exclude grease, o... | 410.10(C) | recall fact / wording |
| `final-exam-#2-069` | Stainless steel rigid metal conduit may use galvanized steel boxes and enclosures if those... | 344.14 | recall fact / wording |
| `final-exam-#2-070` | The maximum size FMT permitted is ___. | 360.20(B) | recall fact / wording |
| `final-exam-#4-001` | When applying the demand factors of Table 220.56, in no case can the feeder or service dem... | 220.56 | recall fact / wording |
| `final-exam-#4-002` | The ampacity of capacitor circuit conductors must not be less than ___ of capacitor curren... | 460.8(A) | recall fact / wording |
| `final-exam-#4-006` | The AC ohms-to-neutral impedance per 1,000 feet of #4/0 aluminum in a steel raceway is ___... | Table 9, Chapter 9 | recall fact / wording |
| `final-exam-#4-008` | A 240 volt single-phase room air conditioner shall be considered as a single-phase motor u... | 440.62(A) | recall fact / wording |
| `final-exam-#4-009` | A steel cable tray of .79 square inches is used as an equipment ground conductor. The maxi... | Table 392.60(B) | recall fact / wording |
| `final-exam-#4-013` | The maximum number of 15 amp receptacles permitted on a free standing office partition is ... | 605.9(C) | recall fact / wording |
| `final-exam-#4-014` | Several motors, each not exceeding 1 horsepower in rating, shall be permitted on a nominal... | 430.53(A) | recall fact / wording |
| `final-exam-#4-017` | Where the ampacity of a conductor does not correspond with the standard ampere rating of a... | 240.4(B) | recall fact / wording |
| `final-exam-#4-018` | Where wet contact is likely to occur in a permanent amusement attraction, ungrounded 2-wir... | 522.28 | recall fact / wording |
| `final-exam-#4-019` | It shall be permissible to apply a demand factor of 75% to the nameplate-rating load of 4 ... | 220.53 | recall fact / wording |
| `final-exam-#4-020` | When more than one calculated or tabulated ampacity could apply for a given circuit length... | 310.14(A)(2) | recall fact / wording |
| `final-exam-#4-043` | The overcurrent protection for a #10 RHH conductor in a conduit at 104°F is ___ amps. | 240.4(D) | recall fact / wording |
| `final-exam-#4-044` | Under the optional calculation, the air conditioning is added to the service at ___. | 220.82(C) | recall fact / wording |
| `open-book-exam-#11-004` | In dwelling units, circuits supplying luminaires may not exceed ___ volts, nominal, betwee... | 210.6(A) | recall fact / wording |
| `open-book-exam-#11-005` | Extreme ___ may cause PVC conduit to become brittle, and therefore more susceptible to dam... | 352.10 | recall fact / wording |
| `open-book-exam-#11-006` | In lieu of the GFCI protection required by 210.8 or 590.6(A) GFCI may be placed in the fee... | 215.9 | recall fact / wording |
| `open-book-exam-#11-008` | A surge protection device is not permitted for circuits exceeding ___ volts. | 242.12 | recall fact / wording |
| `open-book-exam-#11-010` | In multifamily dwellings, Type NM Cable is permitted in buildings that are permitted to be... | 334.10 | recall fact / wording |
| `open-book-exam-#11-011` | Power distribution blocks installed on ___ conductors shall be marked as suitable for use ... | 230.46 | recall fact / wording |
| `open-book-exam-#11-013` | The short circuit current rating of emergency system transfer equipment, based on the spec... | 700.5(F) | recall fact / wording |
| `open-book-exam-#11-014` | When sizing a branch circuit for a fixed storage-type water heater with a capacity of 120 ... | 422.13 | recall fact / wording |
| `open-book-exam-#11-015` | Ground-fault protection of equipment shall be provided for solidly grounded wye electric s... | 230.95(C) | recall fact / wording |
| `open-book-exam-#11-016` | Branch circuits for common areas of a multifamily dwelling shall not be supplied from equi... | 210.25(B) | recall fact / wording |
| `open-book-exam-#11-017` | Pendant conductors longer than 36 inches shall be twisted together where not cabled in a/a... | 410.54(C) | recall fact / wording |
| `open-book-exam-#11-018` | In other than one- and two-family dwelling units, the available fault current and the date... | 408.6 | recall fact / wording |
| `open-book-exam-#11-019` | For electric vehicle supply equipment (EVSE), the larger of either the nameplate or ___ VA... | 220.57 | recall fact / wording |
| `open-book-exam-#11-024` | Dry-type transformers 1,000 volts or less and ___ kVA or less may be installed in hollow s... | 450.13(B) | recall fact / wording |
| `open-book-exam-#12-001` | If an exit enclosure (stair tower) is required to have a fire resistance rating, only elec... | 300.25 | recall fact / wording |
| `open-book-exam-#12-002` | For large-scale PV installations (5,000 kW or more), buildings whose sole purpose is to ho... | 691.9 | recall fact / wording |
| `open-book-exam-#12-004` | Unless otherwise permitted, wiring for ___ loads shall be kept independent from all other ... | 700.10(B) | recall fact / wording |
| `open-book-exam-#12-005` | A building may have more than one service if the capacity requirement exceeds ___ amperes ... | 230.2(C) | recall fact / wording |
| `open-book-exam-#12-006` | Equipment intended to interrupt current at fault levels shall have a/an ___ rating, at nom... | 110.9 | recall fact / wording |
| `open-book-exam-#12-007` | Microgrid systems shall be permitted to disconnect from other sources and operate in ___. | 705.50 | recall fact / wording |
| `open-book-exam-#12-008` | Openings around electrical penetrations into or through fire-resistance rated ___ shall be... | 300.21 | recall fact / wording |
| `open-book-exam-#12-009` | The dc conductors of a PV system shall not occupy the same ___ as PV system ac conductors ... | 690.31(B)(1) | recall fact / wording |
| `open-book-exam-#12-011` | The voltage at the load terminals of a fire pump controller shall not drop more than ___ p... | 695.7(D) | recall fact / wording |
| `open-book-exam-#12-012` | Vegetation such as trees shall not be used for support of ___. | 225.26 | recall fact / wording |
| `open-book-exam-#12-013` | A/an ___ listed shall be installed between a wind electric system and any loads served by ... | 694.7(D) | recall fact / wording |
| `open-book-exam-#12-014` | A luminaire in a commercial cooking hood must, among other requirements, exclude grease, o... | 410.10(C) | recall fact / wording |
| `open-book-exam-#12-016` | Stainless steel rigid metal conduit may use galvanized steel boxes and enclosures if those... | 344.14 | recall fact / wording |
| `open-book-exam-#12-017` | For a PV system, the rapid shutdown for conductors outside the array boundary must limit t... | 690.12(B)(1) | recall fact / wording |
| `open-book-exam-#12-018` | The sum of the multiconductor cable fill area as a percentage of the allowable fill area f... | 392.80(A)(3) | recall fact / wording |
| `open-book-exam-#12-019` | The maximum voltage of an ESS shall be the rated ESS input and ___ voltage(s). | 706.9 | recall fact / wording |
| `open-book-exam-#12-020` | There shall be no voltage marking on a Type TC cable employing ___ wire. | 336.120 | recall fact / wording |
| `open-book-exam-#12-021` | The maximum size FMT permitted is ___. | 360.20(B) | recall fact / wording |
| `open-book-exam-#2-003` | Fastened in place utilization equipment, other than luminaires, that is connected to a bra... | 210.23(B)(2) | recall fact / wording |
| `open-book-exam-#2-005` | The Code requires branch circuits be rated in accordance with the overcurrent protective d... | 210.18 | recall fact / wording |
| `open-book-exam-#2-006` | Panelboards in other than dwelling units that are likely to require examination, adjustmen... | 110.16(A) | recall fact / wording |
| `open-book-exam-#2-010` | If festoon lighting is installed without a messenger, the smallest allowable overhead cond... | 225.6(B) | recall fact / wording |
| `open-book-exam-#2-014` | If a disconnecting means is required to be lockable open, it shall be capable of being loc... | 110.25 | recall fact / wording |
| `open-book-exam-#2-016` | Where the highest continuous current trip setting for which the actual overcurrent device ... | 240.87 | recall fact / wording |
| `open-book-exam-#2-019` | Lighting equipment identified for horticultural use shall be ___. | 410.172 | recall fact / wording |
| `open-book-exam-#2-021` | A service disconnect may be installed in all of the following locations, except ___. | 230.70(A)(2) | recall fact / wording |
| `open-book-exam-#2-024` | For receptacles used during building construction, other than those rated 125-volt, single... | 590.6(B) | recall fact / wording |
| `open-book-exam-#3-005` | In guest rooms of a hotel or motel, the receptacle outlets shall be permitted to be locate... | 210.60(B) | recall fact / wording |
| `open-book-exam-#3-006` | For a dwelling unit service calculation, a demand factor of 75% may be applied to the name... | 220.53 | recall fact / wording |
| `open-book-exam-#3-007` | Thermostatically controlled switching devices serving as both controllers and disconnectin... | 424.20(A)(3) | recall fact / wording |
| `open-book-exam-#3-014` | In dwelling units, all ___ volt receptacles in locations specified and supplied in single-... | 210.8(A) | recall fact / wording |
| `open-book-exam-#3-022` | Duty on elevator and dumbwaiter driving machine motors and driving motors of motor-generat... | 620.61(B)(1) | recall fact / wording |
| `open-book-exam-#3-023` | The frame of a portable generator at a tree lot shall ___ to be connected to a grounding e... | 250.34(A) | recall fact / wording |
| `open-book-exam-#3-024` | Where abandoned communications cables are identified for future use with a tag, the tag sh... | 800.25 | recall fact / wording |
| `open-book-exam-#5-002` | Which of the following is not required to be marked on the nameplate of a transformer? | 450.11(A) | recall fact / wording |
| `open-book-exam-#5-003` | Temporary electric power and lighting installations shall be permitted for a period not to... | 590.3(B) | recall fact / wording |
| `open-book-exam-#5-006` | For a household electric range with a rating of 8 3/4 kW or more, the minimum branch circu... | 210.19(C) | recall fact / wording |
| `open-book-exam-#5-008` | The maximum ampere rating permitted for a 125 volt, single-phase, receptacle outlet having... | 430.42(C) | recall fact / wording |
| `open-book-exam-#5-009` | Service equipment at carnivals and fairs shall not be installed in a location that is acce... | 525.10(A) | recall fact / wording |
| `open-book-exam-#5-011` | Flexible cords shall be used only in continuous lengths, without splices, other than splic... | 400.13 | recall fact / wording |
| `open-book-exam-#5-012` | Feeder and branch circuit conductors that are installed on piers shall be provided with gr... | 682.15(B) | recall fact / wording |
| `open-book-exam-#5-013` | Cartridge fuses in circuits of any voltage, and all fuses in circuits over ___ volts to gr... | 240.40 | recall fact / wording |
| `open-book-exam-#5-019` | Article 647 covers the installation and wiring of separately derived systems operating at ... | 647.1 | recall fact / wording |
| `open-book-exam-#5-022` | All switchboards, switchgear, and panelboards supplied by a ___ in other than one or two-f... | 408.4(B) | recall fact / wording |
| `open-book-exam-#5-025` | Equipment grounding conductors, grounding electrode conductors, and bonding jumpers shall ... | 250.8(A) | recall fact / wording |
| `open-book-exam-#6-001` | Which of the following wiring methods is not permitted in the ceiling space used as a retu... | 300.22(C)(1) | recall fact / wording |
| `open-book-exam-#6-004` | Shore power for boats shall be provided by single receptacles rated not less than ___ ampe... | 555.33(A)(4) | recall fact / wording |
| `open-book-exam-#6-007` | Instruments, pilot lights, voltage transformers, and other switchboard or switchgear devic... | 408.52 | recall fact / wording |
| `open-book-exam-#6-015` | The interior of raceways installed underground shall be considered a/an ___ location. | 300.5(B) | recall fact / wording |
| `open-book-exam-#6-017` | Flat conductor cable (FCC) individual branch circuits shall have ratings not exceeding ___... | 324.10(B)(2) | recall fact / wording |
| `open-book-exam-#6-019` | A single ground rod that does not have a resistance to ground of 25 ohms or less can be su... | 250.53(A)(2) | recall fact / wording |
| `open-book-exam-#6-020` | Openings around electrical penetrations into or through fire-resistant-rated walls, partit... | 300.21 | recall fact / wording |
| `open-book-exam-#6-021` | Panelboards equipped with snap switches rated at 30 amperes or less shall have overcurrent... | 408.36(A) | recall fact / wording |
| `open-book-exam-#6-025` | Color coding shall be permitted to identify intrinsically safe conductors where they are c... | 504.80(C) | recall fact / wording |
| `open-book-exam-#9-001` | In a concealed knob-and-tube wiring system, a minimum clearance of ___ must be maintained ... | 394.19(A) | recall fact / wording |
| `open-book-exam-#9-003` | Informational Note: ANSI ___-2017, Product Safety Signs and Labels, provides guidelines fo... | 110.21(B) | recall fact / wording |
| `open-book-exam-#9-004` | Where there is equipment for more than one elevator car in the machine room, the heating a... | 620.54 | recall fact / wording |
| `open-book-exam-#9-006` | Where the overcurrent device is rated over 800 amperes, the ampacity of the conductors it ... | 240.4(C) | recall fact / wording |
| `open-book-exam-#9-007` | Where corrosion protection is necessary, and the conduit is threaded in the field, the thr... | 300.6(A) | recall fact / wording |
| `open-book-exam-#9-008` | A permanent and legible ___ diagram of the local switching arrangement, clearly identifyin... | 495.25(B) | recall fact / wording |
| `open-book-exam-#9-010` | Signs and outline lighting systems with lampholders for incandescent lamps shall be marked... | 600.4(C) | recall fact / wording |
| `open-book-exam-#9-013` | Ventilating pipes for motors, generators, or other rotating electrical machinery, or for e... | 502.128 | recall fact / wording |
| `open-book-exam-#9-020` | The ampere rating of an electric range receptacle is permitted to be based on the demand l... | 210.21(B)(4) | recall fact / wording |
| `open-book-exam-#9-022` | Torque motors are rated for operation ___. | 430.7(C) | recall fact / wording |
| `open-book-exam-#9-023` | "Z.P." is an abbreviated marking used for motors to indicate ___. | 430.7(A) | recall fact / wording |
| `open-book-exam-#9-024` | Galvanized steel, stainless steel, and ___ RMC shall be permitted under all atmospheric co... | 344.10(A)(1) | recall fact / wording |
| `final-exam-#2-024` | Table ___ lists the volume allowances required per conductor for outlet, device and juncti... | Table 314.16(B)(1) | which table |
| `final-exam-#2-027` | ___ lists the dimensions of insulated conductors and fixture wires. | Chapter 9, Table 5 | which table |
| `final-exam-#2-028` | Table ___ lists demand factors for kitchen equipment other than dwelling units. | Table 220.56 | which table |
| `final-exam-#2-029` | ___ lists the percent of cross sectional fill permitted in conduit and tubing fill for con... | Chapter 9, Table 1 | which table |
| `final-exam-#2-037` | Table ___ lists the maximum rating or setting of motor branch-circuit short circuit and gr... | Table 430.52(C)(1) | which table |
| `final-exam-#2-039` | Table ___ lists the maximum cord-and-plug-connected load to receptacle. | Table 210.21(B)(2) | which table |
| `final-exam-#2-040` | Table ___ lists clearances over roadways, walkways, rail, water, and open land. | Table 235.360(A) | which table |
| `open-book-exam-#9-002` | Table ___ lists the minimum size equipment grounding conductors. | Table 250.122 | which table |
| `open-book-exam-#9-005` | ___ lists the percent of cross sectional fill permitted in conduit and tubing fill for con... | Chapter 9, Table 1 | which table |
| `open-book-exam-#9-011` | Table ___ lists the maximum rating or setting of motor branch-circuit short circuit and gr... | Table 430.52(C)(1) | which table |
| `open-book-exam-#9-014` | Table ___ lists the maximum cord-and-plug-connected load to a receptacle. | Table 210.21(B)(2) | which table |
| `open-book-exam-#9-017` | Table ___ lists clearances over roadways, walkways, rail, water, and open land. | Table 235.360(A) | which table |
| `open-book-exam-#9-019` | Table ___ lists minimum depth of clear working space at electrical equipment. | Table 110.34(A) | which table |
| `open-book-exam-#9-021` | What section of the NEC determines the installation of service equipment on manufactured b... | 545.7 | which table / section |
