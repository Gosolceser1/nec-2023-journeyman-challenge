# Stem and choice corrections

Rule: **PDF wording, typos corrected.** Question stems and answer choices follow the
source exam PDF word for word, including its odd phrasing, with two exceptions:

1. Text the OCR lost or mangled is restored from the PDF page image (dropped blanks,
   stray letters, `:` read in place of `___`, merged words, `3g` for `3ø`).
2. Genuine misspellings, dropped words and obvious grammar slips in the PDF itself are
   corrected, without changing meaning or numbers. Quoted NEC text still matches the
   2023 edition word for word.

Bank conventions kept: `3ø` written as "three-phase", first letters capitalised.
Hyphenation of number compounds ("125 volt", "one family") is left as printed.

All corrections live in `tools/pipeline/question_bank_overrides.json` (hints in `tools/pipeline/gists.py`)
and survive a rebuild. `tools/pipeline/spellcheck_bank.py` guards against regressions.

Baseline: `question_bank.json` at git HEAD (c8ff389). 129 records differ.

## Typos and slips in the PDF, corrected (38 changes)

Includes Final #3 Q42, which now shows the exact PDF stem ("an accessible separable
connector or ___ plug and receptacle"). The stem contains the answer because 422.33(A)
says "accessible" twice; the validator allows this for that single record only
(`PROMPT_LEAK_EXCEPTIONS`).

| Record | Field | Before | After |
|---|---|---|---|
| `final-exam-#1-004` | stem | Disregarding demand factors, the calculated lighting load for a 5,000 sq.ft. office building is ___ volt-amperes. | Disregarding demand factors, the calculated lighting load for a 5,000 sq. ft. office building is ___ volt-amperes. |
| `final-exam-#1-022` | stem | Where a dwelling has an attached garage built to accommodate a pair of vehicles, the Code requires a minimum of ___ receptacle outlet(s) to be installed in the garage. | Where a dwelling has a two car attached garage, the Code requires a minimum of ___ receptacle outlet(s) to be installed in the garage. |
| `final-exam-#1-026` | stem | The conductor is marked RHW-2 on the insulation, what does the -2 represent? | The conductor is marked RHW-2 on the insulation. What does the -2 represent? |
| `final-exam-#1-030` | stem | Thermostatically controlled switching devices serving as both controllers and disconnecting means for fixed electric space-heating equipment shall ___. | Thermostatically controlled switching devices serving as both controllers and disconnecting means for fixed electric space heating equipment shall ___. |
| `final-exam-#1-034` | stem | Which of the following cord types is permitted in wet location and is sunlight resistant? | Which of the following cord types is permitted in a wet location and is sunlight resistant? |
| `final-exam-#1-042` | choice A | weather proof | weatherproof |
| `final-exam-#1-042` | choice B | water proof | waterproof |
| `final-exam-#1-053` | stem | Overhead conductors not over 1,000 volts passing over track rails of railroads shall have a minimum clearance of not less than ___ feet above finished grade. | Where overhead conductors not over 1,000 volts pass over track rails of railroads, they shall have a minimum clearance of not less than ___ feet above finished grade. |
| `final-exam-#1-056` | stem | The maximum ampere rating permitted for a 125 volt, single-phase, receptacle outlet having a cord-and-plug connected motor load that does not have individual overload protection is ___. | The maximum ampere rating permitted for a 125 volt, single-phase receptacle outlet having a cord-and-plug connected motor load that does not have individual overload protection is ___. |
| `final-exam-#1-058` | stem | Which of the following is not required to be marked on the name plate of a transformer? | Which of the following is not required to be marked on the nameplate of a transformer? |
| `final-exam-#1-070` | stem | What is the full load current of a 50 horsepower, 3, 480v, wound-rotor AC motor? | What is the full load current of a 50 horsepower, three-phase, 480v, wound-rotor AC motor? |
| `final-exam-#3-012` | choice A | Underwriters' Laboratories | Underwriters Laboratories |
| `final-exam-#3-042` | stem | For cord-and-plug-connected appliances, ___ separable connector or plug and receptacle is permitted to serve as the disconnecting means. | For cord-and-plug connected appliances, an accessible separable connector or ___ plug and receptacle is permitted to serve as the disconnecting means. |
| `final-exam-#3-068` | stem | Where there is more than one driving machine in an elevator room, the disconnecting means must be numbered to correspond to the identifying number of the . | Where there is more than one driving machine in an elevator room, the disconnecting means must be numbered to correspond to the identifying number of the ___. |
| `final-exam-#3-068` | choice C | the branch circuit feeding it | branch circuit feeding it |
| `final-exam-#5-006` | stem | Lengths of not more than ___ of AC cable at terminals where flexibility is necessary does not have to be supported. | Lengths of not more than ___ of AC cable at terminals where flexibility is necessary do not have to be supported. |
| `final-exam-#5-023` | stem | Type TC cables with metallic shielding shall have a minimum bending radius of not less than ___. times the cable overall diameter. | Type TC cables with metallic shielding shall have a minimum bending radius of not less than ___ times the cable overall diameter. |
| `final-exam-#5-023` | choice C | twenty four | twenty-four |
| `final-exam-#5-023` | choice D | thirty six | thirty-six |
| `final-exam-#5-038` | stem | Liquidtight flexible metal conduit shall not be permitted . | Liquidtight flexible metal conduit shall not be permitted ___. |
| `final-exam-#5-038` | choice D | where installations requires flexibility or protection from liquids, vapors or solids | where installations require flexibility or protection from liquids, vapors or solids |
| `final-exam-#5-039` | stem | A copper bus bar is 4" wide by 1/2" thick. What is the ampacity? | A copper busbar is 4" wide by 1/2" thick. What is the ampacity? |
| `final-exam-#5-050` | stem | For over 1000 volts, busways having sections located both inside and outside of buildings, shall have a____at the building wall. | For over 1000 volts, busways having sections located both inside and outside of buildings shall have a ___ at the building wall. |
| `final-exam-#5-066` | stem | The number of conductors allowed in LFNC must not exceed the percentage fill specified in Chapter 9, Table... | The number of conductors allowed in LFNC must not exceed that permitted by the percentage fill specified in ___, Chapter 9. |
| `open-book-exam-#1-005` | stem | A motor control center in an equipment room requires GFCI protected 125-volt, single-phase, 15 or 20 amp rated receptacle outlet within ___ feet. | A motor control center in an equipment room requires a GFCI protected 125-volt, single-phase, 15 or 20 amp rated receptacle outlet within ___ feet. |
| `open-book-exam-#1-010` | stem | In dwelling units, GFCI protection is required for all 15 and 20 ampere, 125 volt receptacles that are installed within ___ feet of the outside edge of a bathtub or shower stall. | In dwelling units, GFCI protection is required for all 15 and 20 ampere, 125 volt receptacles installed within ___ feet of the outside edge of a bathtub or shower stall. |
| `open-book-exam-#1-021` | stem | Disregarding demand factors, the calculated lighting load for a 5,000 sq.ft. office building is ___ volt-amperes. | Disregarding demand factors, the calculated lighting load for a 5,000 sq. ft. office building is ___ volt-amperes. |
| `open-book-exam-#4-014` | choice A | weather proof | weatherproof |
| `open-book-exam-#4-014` | choice B | water proof | waterproof |
| `open-book-exam-#7-005` | stem | ___ The highest level that water can reach before it spills out. | ___. The highest level that water can reach before it spills out. |
| `open-book-exam-#7-005` | choice A | Over Flow | Overflow |
| `open-book-exam-#10-009` | stem | The individual responsible for starting, stopping, and controlling an amusement ride or supervising a concession. | ___. The individual responsible for starting, stopping, and controlling an amusement ride or supervising a concession. |
| `open-book-exam-#10-010` | stem | A commercial building has a second-floor material-handling door used to move items into and out of a storage area. A 120V overhead branch-circuit final span will run from the building near this opening to a pole-mounted floodlight. Which installation complies with the 2023 NEC? | A commercial building has an opening door in the wall on the second floor through which materials are moved into and out of a storage area located on the second floor. An overhead 120v branch circuit is to be installed from the second floor area of the building to a pole on which a floodlight will be mounted. Which of the following best describes Code requirements for the installation of this branch circuit? |
| `open-book-exam-#10-010` | choice A | Overhead installation is prohibited. | It is not permitted to be installed overhead. |
| `open-book-exam-#10-010` | choice B | Keep 3 ft of horizontal clearance from the door, but passing beneath the material opening is allowed. | It must be at least 3 feet from the side of the door. |
| `open-book-exam-#10-010` | choice C | Provide 3 ft of vertical clearance above the door. | It must be at least 3 feet above the bottom of the door. |
| `open-book-exam-#10-010` | choice D | Keep at least 3 ft of horizontal clearance from the door, do not run beneath the material-handling opening, and do not obstruct its entrance. | It must not obstruct entrance to the material handling door and be 3 feet from the door. |
| `open-book-exam-#10-012` | stem | A Class 1 power-limited circuit shall be supplied from a source having a rated output of not more than 30 volts and ___ volt amperes. | A Class 1 power-limited circuit shall be supplied from a source having a rated output of not more than 30 volts and ___ volt-amperes. |

## OCR damage restored from the PDF (78 changes)

| Record | Field | Before | After |
|---|---|---|---|
| `final-exam-#1-039` | stem | A controller that includes motor overload protection for group motor application shall be marked with the motor overload protection and the maximum branch-circuit short-circuit and ground-fault protection for such applications. | A controller that includes motor overload protection ___ for group motor application shall be marked with the motor overload protection and the maximum branch-circuit short-circuit and ground-fault protection for such applications. |
| `final-exam-#1-067` | stem | Conduit nipples not over 24 inches in length may be filled to a maximum of ___. | Conduit nipples not over 24 inches in length may be filled to a maximum of ___ of their CSA. |
| `final-exam-#3-001` | stem | A Universal Serial Bus flush device cover plate that additionally provides a night light and/or output connector(s) shall be listed. | A Universal Serial Bus flush device cover plate that additionally provides a night light and/or ___ output connector(s) shall be listed. |
| `final-exam-#3-004` | stem | In airports where maintenance and supervision conditions ensure that only qualified persons can access, install, or service the cable, airfield lighting cable used in series circuits that are rated up to : volts and are powered by constant current regulators shall be permitted to be installed in cable trays. i | In airports where maintenance and supervision conditions ensure that only qualified persons can access, install, or service the cable, airfield lighting cable used in series circuits that are rated up to ___ volts and are powered by constant current regulators shall be permitted to be installed in cable trays. |
| `final-exam-#3-005` | stem | Low voltage heating power unit shall be an isolating type with a rated output not exceeding volts peak ac. | Low voltage heating power unit shall be an isolating type with a rated output not exceeding ___ volts peak ac. |
| `final-exam-#3-006` | stem | GFCI protection shall be provided for lighting outlets not exceeding volts installed in crawl spaces. | GFCI protection shall be provided for lighting outlets not exceeding ___ volts installed in crawl spaces. |
| `final-exam-#3-008` | stem | Locations in which easily ignitible combustible fibers are stored or handled other than in the process of manufacturing are designated as . | Locations in which easily ignitible combustible fibers are stored or handled other than in the process of manufacturing are designated as ___. |
| `final-exam-#3-009` | stem | A disconnecting means is required to disconnect the from the circuit. | A disconnecting means is required to disconnect the ___ from the circuit. |
| `final-exam-#3-010` | stem | The definition of “busbar” in Article 100 applies . | The definition of “busbar” in Article 100 applies ___. |
| `final-exam-#3-011` | stem | Most incidents and injuries are initiated by . | Most incidents and injuries are initiated by ___. |
| `final-exam-#3-013` | stem | Fastening of unbroken lengths of EMT conduit can be increased to a distance of from the termination point where the structural members do not readily permit fastening within 3 feet. | Fastening of unbroken lengths of EMT conduit can be increased to a distance of ___ from the termination point where the structural members do not readily permit fastening within 3 feet. |
| `final-exam-#3-015` | stem | Enclosures for overcurrent protection devices must be mounted in a/an position unless that is shown to be impracticable. | Enclosures for overcurrent protection devices must be mounted in a/an ___ position unless that is shown to be impracticable. |
| `final-exam-#3-017` | stem | Equipment grounding conductors must be the same size as the circuit conductors for amp circuits. | Equipment grounding conductors must be the same size as the circuit conductors for ___ amp circuits. |
| `final-exam-#3-019` | stem | A must be located in sight from the motor location and the driven machinery location. | A ___ must be located in sight from the motor location and the driven machinery location. |
| `final-exam-#3-020` | stem | Outdoor antennas and lead-in conductors for radio and TV equipment must not cross over open conductors of electric light or power circuits, and must be kept well away from all such circuits to avoid the possibility of accidental contact. Where proximity to open electric light or power service conductors of less than 250 volts between conductors cannot be avoided, the installation must provide a clearance of at least : | Outdoor antennas and lead-in conductors for radio and TV equipment must not cross over open conductors of electric light or power circuits, and must be kept well away from all such circuits to avoid the possibility of accidental contact. Where proximity to open electric light or power service conductors of less than 250 volts between conductors cannot be avoided, the installation must provide a clearance of at least ___. |
| `final-exam-#3-023` | stem | Conductors in a non-jacketed multiconductor cable, such as ribbon cable in a permanent amusement attraction shall not be smaller than AWG. | Conductors in a non-jacketed multiconductor cable, such as ribbon cable in a permanent amusement attraction shall not be smaller than ___ AWG. |
| `final-exam-#3-024` | stem | For installations consisting of not more than two 2-wire branch circuits, the building disconnecting means must have a rating of not less than amps. | For installations consisting of not more than two 2-wire branch circuits, the building disconnecting means must have a rating of not less than ___ amps. |
| `final-exam-#3-025` | stem | Supplementary overcurrent protection . | Supplementary overcurrent protection ___. |
| `final-exam-#3-026` | stem | Electrical services and feeders shall be calculated on the basis of not less than per electrified truck parking space. | Electrical services and feeders shall be calculated on the basis of not less than ___ per electrified truck parking space. |
| `final-exam-#3-026` | choice B | 12KVA | 12 kVA |
| `final-exam-#3-026` | choice C | 15kVA | 15 kVA |
| `final-exam-#3-027` | stem | The largest size grounding electrode conductor to a concrete-encased electrode is not required to be larger than copper. | The largest size grounding electrode conductor to a concrete-encased electrode is not required to be larger than ___ copper. |
| `final-exam-#3-028` | stem | Appliances, provided for public use rated 250v or less and 60 amps or less, single-phase or three-phase, shall be provided with GFCI protection for personnel. | Appliances, ___ provided for public use rated 250v or less and 60 amps or less, single-phase or three-phase, shall be provided with GFCI protection for personnel. |
| `final-exam-#3-029` | stem | The localization of an overcurrent condition to restrict outages to the circuit or equipment affected, accomplished by the choice of overcurrent-protective devices is called . | The localization of an overcurrent condition to restrict outages to the circuit or equipment affected, accomplished by the choice of overcurrent-protective devices is called ___. |
| `final-exam-#3-031` | stem | Where overhead communications wires and cables enter buildings, they must . | Where overhead communications wires and cables enter buildings, they must ___. |
| `final-exam-#3-032` | stem | A nursing home is an area used for the lodging, boarding, and nursing care, on a 24-hour basis, of or more inpatients. | A nursing home is an area used for the lodging, boarding, and nursing care, on a 24-hour basis, of ___ or more inpatients. |
| `final-exam-#3-034` | choice D | 11/2" | 1 1/2" |
| `final-exam-#3-037` | stem | For NUCC, the conduit must be trimmed away from the conductors or cables using an approved method that will not damage the conductor or cable insulation or jacket. | For ___ NUCC, the conduit must be trimmed away from the conductors or cables using an approved method that will not damage the conductor or cable insulation or jacket. |
| `final-exam-#3-038` | stem | The motor branch-circuit short-circuit and ground-fault protective device must be capable of carrying the current of the motor. | The motor branch-circuit short-circuit and ground-fault protective device must be capable of carrying the ___ current of the motor. |
| `final-exam-#3-039` | stem | Central heating equipment, other than fixed electric space-heating equipment, must be supplied by a/an branch circuit. | Central heating equipment, other than fixed electric space-heating equipment, must be supplied by a/an ___ branch circuit. |
| `final-exam-#3-043` | stem | The only way to see an electrical hazard is . | The only way to see an electrical hazard is ___. |
| `final-exam-#3-045` | stem | The total number of AC cycles completed in one second is the current's . | The total number of AC cycles completed in one second is the current's ___. |
| `final-exam-#3-047` | stem | Type SE cable is permitted to be formed ina and taped with self-sealing weather-resistant thermoplastic. | Type SE cable is permitted to be formed in a ___ and taped with self-sealing weather-resistant thermoplastic. |
| `final-exam-#3-049` | stem | At least one 125-volt, single-phase, 15or 20-ampere-rated receptacle outlet shall be installed within of the electrical service equipment requiring servicing. | At least one 125-volt, single-phase, 15- or 20-ampere-rated receptacle outlet shall be installed within ___ of the electrical service equipment requiring servicing. |
| `final-exam-#3-049` | choice B | 10" | 10' |
| `final-exam-#3-049` | choice D | 50" | 50' |
| `final-exam-#3-050` | stem | When an underground metal water-piping system is used as a grounding electrode, effective bonding must be provided around insulated joints and around any equipment that is likely to be disconnected for repairs or replacement. Bonding conductors must be of to permit removal of such equipment while retaining the integrity of the bond. | When an underground metal water-piping system is used as a grounding electrode, effective bonding must be provided around insulated joints and around any equipment that is likely to be disconnected for repairs or replacement. Bonding conductors must be of ___ to permit removal of such equipment while retaining the integrity of the bond. |
| `final-exam-#3-051` | stem | An outdoor disconnecting means for a mobile home must be installed so the bottom of the enclosure is not less than above the finished grade or working platform. | An outdoor disconnecting means for a mobile home must be installed so the bottom of the enclosure is not less than ___ above the finished grade or working platform. |
| `final-exam-#3-052` | stem | The minimum number of overload units required for a three-phase motor is... | The minimum number of overload unit(s) required for a three-phase motor is ___. |
| `final-exam-#3-053` | stem | Straight runs of 1-inch RMC using threaded couplings may be secured at intervals not exceeding... | Straight runs of 1-inch RMC using threaded couplings may be secured at intervals not exceeding ___. |
| `final-exam-#3-056` | stem | The building disconnecting means for a one-circuit installation that supplies only limited loads of a single branch circuit must have a rating not less than . | The building disconnecting means for a one-circuit installation that supplies only limited loads of a single branch circuit must have a rating not less than ___. |
| `final-exam-#3-058` | stem | The definition of “fibers/flyings, ignitible” is found in Article__. | The definition of “fibers/flyings, ignitible” is found in Article ___. |
| `final-exam-#3-060` | stem | Provisions shall be made for sufficient diffusion and ventilation of the gases from the storage battery if present to prevent the accumulation of a/an mixture. | Provisions shall be made for sufficient diffusion and ventilation of the gases from the storage battery if present to prevent the accumulation of a/an ___ mixture. |
| `final-exam-#3-061` | stem | Where motors are provided with terminal housings, the housings must be of and of substantial construction. | Where motors are provided with terminal housings, the housings must be of ___ and of substantial construction. |
| `final-exam-#3-063` | stem | The continuous current-carrying capacity of a 1 1/2 square inch copper busbar mounted in an unventilated enclosure is amps. | The continuous current-carrying capacity of a 1 1/2 square inch copper busbar mounted in an unventilated enclosure is ___ amps. |
| `final-exam-#3-064` | stem | GFCI protection for personnel is required for all 15 and 20 amp, 125 volt single-phase receptacles installed in a dwelling unit . | GFCI protection for personnel is required for all 15 and 20 amp, 125 volt single-phase receptacles installed in a dwelling unit ___. |
| `final-exam-#3-066` | stem | Concrete-encased electrodes of are not required to be part of the grounding electrode system where the steel rebars or rods aren't accessible for use without disturbing the concrete. | Concrete-encased electrodes of ___ are not required to be part of the grounding electrode system where the steel rebars or rods aren't accessible for use without disturbing the concrete. |
| `final-exam-#3-067` | stem | The rating of the attachment plug and receptacle must not exceed @ 250 volts for a cord-and-plug connected air conditioner. | The rating of the attachment plug and receptacle must not exceed ___ @ 250 volts for a cord-and-plug connected air conditioner. |
| `final-exam-#3-070` | stem | The symbol for a three-phase delta-wound generator consists of a circle with a... scribed inside. | The symbol for a three-phase delta wound generator consists of a circle with a ___ scribed inside. |
| `final-exam-#5-001` | stem | FCC carpet squares that are adhered to the floor shall be attached with . | FCC carpet squares that are adhered to the floor shall be attached with ___. |
| `final-exam-#5-004` | stem | Power feed, grounding connection, and shield system connection between the FCC system and : other wiring systems shall be accomplished in a . | Power feed, grounding connection, and shield system connection between the FCC system and other wiring systems shall be accomplished in a ___. |
| `final-exam-#5-005` | stem | Tap devices used in FC assemblies shall be rated at not less than how many amps? | Tap devices used in FC assemblies shall be rated at not less than ___ amps or more than 300 volts, and they shall be color-coded in accordance with the requirements of 322.120(C). |
| `final-exam-#5-005` | choice A | 20 amps | 20 |
| `final-exam-#5-005` | choice B | 15 amps | 15 |
| `final-exam-#5-005` | choice C | 30 amps | 30 |
| `final-exam-#5-005` | choice D | 40 amps | 40 |
| `final-exam-#5-007` | stem | A protective layer which is installed between the floor and type FCC flat conductor cable to protect . the cable from physical damage and may or may not be incorporated as an integral part of the cable is the . | A protective layer which is installed between the floor and type FCC flat conductor cable to protect the cable from physical damage and may or may not be incorporated as an integral part of the cable is the ___. |
| `final-exam-#5-008` | stem | The minimum size copper conductor permitted in metal-clad cable is . | The minimum size copper conductor permitted in metal-clad cable is ___. |
| `final-exam-#5-020` | stem | MI cable has . | MI cable has ___. |
| `final-exam-#5-021` | stem | SE cable used to supply shall not be subject to conductor temperatures in excess of the temperature specified for the type of insulation involved. | SE cable used to supply ___ shall not be subject to conductor temperatures in excess of the temperature specified for the type of insulation involved. |
| `final-exam-#5-022` | stem | For general wiring, type cable containing one or more conductors is approved for direct burial in earth. | For general wiring, ___ type cable containing one or more conductors is approved for direct burial in earth. |
| `final-exam-#5-024` | choice C | fished in voids in masonry block | fished in voids in masonry blocks |
| `final-exam-#5-032` | stem | The largest conductor permitted in 3/8" flexible metal conduit is . | The largest conductor permitted in 3/8" flexible metal conduit is ___. |
| `final-exam-#5-033` | stem | Rigid metal conduit shall be every 10 feet as required by section 110.21. | Rigid metal conduit shall be ___ every 10 feet as required by section 110.21. |
| `final-exam-#5-034` | stem | Aluminum fittings and enclosures shall be permitted to be used with __. | Aluminum fittings and enclosures shall be permitted to be used with ___. |
| `final-exam-#5-036` | stem | Rigid PVC conduit may be used . | Rigid PVC conduit may be used ___. |
| `final-exam-#5-051` | stem | Cablebus shall be installed only for work. ; | Cablebus shall be installed only for ___ work. |
| `final-exam-#5-053` | choice B | 41/2 | 4 1/2 |
| `final-exam-#5-054` | stem | Documentation of engineered design by a licensed professional engineer engaged primarily in the design of such systems for the spacing between conductors shall be available upon request of the AHJ and this is stated in Article . | Documentation of engineered design by a licensed professional engineer engaged primarily in the design of such systems for the spacing between conductors shall be available upon request of the AHJ and this is stated in Article ___. |
| `open-book-exam-#1-001` | stem | Each multiwire branch circuit shall be provided with a means that will simultaneously disconnect all. | Each multiwire branch circuit shall be provided with a means that will simultaneously disconnect all ___. |
| `open-book-exam-#1-002` | stem | The connection between the grounded circuit conductor and the equipment grounding conductor, or the supply-side bonding jumper, or both at the service is recognized as the. | The connection between the grounded circuit conductor and the equipment grounding conductor, or the supply-side bonding jumper, or both at the service is recognized as the ___. |
| `open-book-exam-#1-003` | stem | When calculating floor area for branch circuit load calculations, the floor area is measured from the dimensions of the building, dwelling unit, or area involved. | When calculating floor area for branch circuit load calculations, the floor area is measured from the ___ dimensions of the building, dwelling unit, or area involved. |
| `open-book-exam-#4-003` | stem | Type NM cable is permitted for use under all the following conditions or locations except. | Type NM cable is permitted for use under all the following conditions or locations except ___. |
| `open-book-exam-#4-016` | stem | A controller that includes motor overload protection for group motor application shall be marked with the motor overload protection and the maximum branch-circuit short-circuit and ground-fault protection for such applications. | A controller that includes motor overload protection ___ for group motor application shall be marked with the motor overload protection and the maximum branch-circuit short-circuit and ground-fault protection for such applications. |
| `open-book-exam-#7-006` | stem | Flexible cord used in extension cords made with separately listed and installed components shall be permitted to be supplied by a branch circuit in accordance with the following: 20 ampere circuits and larger. | Flexible cord used in extension cords made with separately listed and installed components shall be permitted to be supplied by a branch circuit in accordance with the following: 20 ampere circuits ___ and larger. |
| `open-book-exam-#7-024` | stem | A switchboard, switchgear, or panelboard containing a 4-wire, ___-connected system where the midpoint of one phase winding is grounded shall be legibly and permanently marked as follows: 'Caution Phase Has ___ Volts to Ground.' | A switchboard, switchgear, or panelboard containing a 4-wire, ___-connected system where the midpoint of one phase winding is grounded shall be legibly and permanently marked as follows: “Caution ___ Phase Has ___ Volts to Ground.” |
| `open-book-exam-#10-004` | stem | Where overcurrent protection is provided as part of the industrial control panel, the supply conductors shall be considered as either feeders or as covered by 240.21. | Where overcurrent protection is provided as part of the industrial control panel, the supply conductors shall be considered as either feeders or ___ as covered by 240.21. |
| `open-book-exam-#10-006` | stem | An electric device and circuit that controls a disconnecting means through a relay or equivalent device. | ___. An electric device and circuit that controls a disconnecting means through a relay or equivalent device. |

## Earlier stem restorations already in the working tree (56 changes)

Made by previous passes (mostly replacing the builder's hand-typed paraphrases with the
PDF wording) before this audit started; listed so the diff against HEAD is complete.

| Record | Field | Before | After |
|---|---|---|---|
| `final-exam-#1-001` | stem | Write 60% as a fraction in simplest form. | 60% is equivalent to ___. |
| `final-exam-#1-005` | stem | Given switch S1 is ON, the light does not come on, voltage across the light is 120 volts, and voltage across S1 is 0 volts. The light does not come on because... | Refer to the figure below. GIVEN: Switch S1 is in the "ON" position, but the light does not come on. Voltage across L1 is measured to be 120 volts. Voltage across S1 is measured to be 0 volts. The light does not come on because ___. |
| `final-exam-#1-005` | choice A | The light is open (bulb burned out) | the light is open (bulb burned out) |
| `final-exam-#1-005` | choice B | The light and switch are shorted | the light and switch are shorted |
| `final-exam-#1-005` | choice C | The light is good but the switch does not make contact | the light is good but the switch does not make contact |
| `final-exam-#1-005` | choice D | There is a break in the circuit wiring | there is a break in the wiring of the circuit |
| `final-exam-#1-019` | stem | What does the alpha character I represent when stating the equation W = E x I? | What does the alpha character I represent when stating the question W = E x I? |
| `final-exam-#1-020` | stem | Where multiple driven ground rods are used to form the grounding electrode system, in order to maintain an effective grounding electrode system, they shall be spaced not less than ___ apart. | Where multiple driven ground rods are used to form the grounding electrode system, in order to maintain an effective grounding electrode system, they shall not be less than ___ apart. |
| `final-exam-#1-031` | stem | In dwelling units, hallways of how many feet or more in length shall have at least one receptacle outlet? | In dwelling units, hallways of ___ feet or more in length shall have at least one receptacle outlet. |
| `final-exam-#1-031` | choice A | 6 feet | 6 |
| `final-exam-#1-031` | choice B | 8 feet | 8 |
| `final-exam-#1-031` | choice C | 10 feet | 10 |
| `final-exam-#1-031` | choice D | 12 feet | 12 |
| `final-exam-#1-035` | stem | One or more metal in-ground support structures in direct contact with the earth vertically for how many feet or more are a permitted grounding electrode? | One or more metal in-ground support structure(s) in direct contact with the earth vertically for ___ feet or more, with or without concrete encasement is a permitted grounding electrode. |
| `final-exam-#1-035` | choice A | 6 feet | 6 |
| `final-exam-#1-035` | choice B | 8 feet | 8 |
| `final-exam-#1-035` | choice C | 10 feet | 10 |
| `final-exam-#1-035` | choice D | 12 feet | 12 |
| `final-exam-#1-036` | stem | For a service rated 100 through 400 amps, the service conductors supplying the entire load of a one family dwelling shall be permitted to have an ampacity ___ of the service rating. | For a service rated 100 through 400 amps, the service conductors supplying the entire load of a one family dwelling shall be permitted to have an ampacity of ___ of the service rating. |
| `final-exam-#1-041` | stem | A stop switch is wired in ___ with a motor circuit. | A stop switch is wired ___ in a motor circuit. |
| `final-exam-#1-054` | stem | Flexible cords may be repaired with splices for hard-service cord or what other cord under certain conditions? | Flexible cords shall be used only in continuous lengths, without splices, other than splices for the repair of hard-service cord or ___ cord under certain conditions. |
| `final-exam-#3-003` | stem | The conductors supplying supplementary overcurrent protective devices for fixed industrial process heating equipment shall be considered... conductors. | The conductors supplying the supplementary overcurrent protective devices for fixed industrial process heating equipment shall be considered ___ conductors. |
| `final-exam-#3-007` | stem | Audio equipment operating above the low-voltage contact limit within how many feet of a storable or portable immersion pool must be grounded and GFCI protected? | All audio equipment operating at greater than the low-voltage contact limit and located within ___ from the inside walls of a storable or portable immersion pool shall be grounded and shall be protected by a GFCI. |
| `final-exam-#3-018` | stem | When supplying a room air conditioner rated 120 volts, the length of the flexible supply cord must not exceed . | When supplying a room air conditioner rated 120 volts, the length of the flexible supply cord must not exceed ___. |
| `final-exam-#3-018` | choice A | 6' | 6 feet |
| `final-exam-#3-018` | choice B | 8" | 8 feet |
| `final-exam-#3-018` | choice C | 10' | 10 feet |
| `final-exam-#3-018` | choice D | 12' | 12 feet |
| `final-exam-#3-046` | stem | Unused openings for breakers in panelboards must be closed using... | Unused openings for breakers in panelboards must be closed using ___ or other approved means. |
| `final-exam-#3-048` | stem | Using Table 348.22 below, what is the largest conductor size listed for THHN in 3/8-inch FMC? | The largest size THHN conductor permitted in a 3/8-inch FMC is ___. |
| `final-exam-#3-057` | stem | When determining the number of conductors considered as current-carrying, a grounding conductor is ___. | When determining the number of conductors that are considered as current-carrying, a grounding conductor is ___. |
| `final-exam-#3-059` | stem | Receptacles that provide power for water-pump motors or loads directly related to pool circulation must be at least how far from the inside pool walls? | Receptacles that provide power for water-pump motors or for other loads directly related to the circulation and sanitation system must be located at least ___ from the inside walls of the pool. |
| `final-exam-#3-065` | stem | Service and feeder conductors may be sized using Table 310.12(A) for... | Service and feeder conductors may be sized using Table 310.12(A) for ___. |
| `final-exam-#3-069` | stem | A feeder supplying a specific fixed motor load must have a protective device with a rating or setting ___ the largest branch-circuit short-circuit and ground-fault rating or setting in the group, plus the sum of the full-load currents of the other motors. | A feeder must have a protective device with a rating or setting ___ branch-circuit short-circuit and ground-fault protective device for any motor in the group, plus the sum of the full-load currents of the other motors of the group. |
| `final-exam-#3-069` | choice A | 125 percent of | 125% of the largest rating |
| `final-exam-#3-069` | choice B | not greater than | not greater than the largest rating or setting of the |
| `final-exam-#3-069` | choice C | 225 percent of | 225% of the largest rating |
| `final-exam-#5-002` | stem | Armored cable installed in thermal insulation shall have conductors rated at ___. The ampacity of the cable installed in these applications shall not exceed that of 60 degree C conductors. | Armored cable installed in thermal insulation shall have conductors rated at ___. The ampacity of the cable installed in these applications shall be that of 60 degree C conductors. |
| `final-exam-#5-019` | stem | Which cable shall be flame-retardant, moisture-resistant, fungus-resistant, and corrosion-resistant? | ___ cable shall be flame-retardant, moisture-resistant, fungus-resistant, and corrosion-resistant. |
| `final-exam-#5-048` | stem | In auxiliary gutters, the minimum clearance between bare current-carrying metal parts of different potential mounted on the same surface is... | In auxiliary gutters, the minimum clearance between bare current-carrying metal parts of different potential mounted on the same surface will not be less than ___ for parts that are held free in the air. |
| `final-exam-#5-049` | stem | Nonmetallic surface extensions shall not be run on the floor or within how many inches from the floor? | Nonmetallic surface extensions with one or more extensions shall be permitted to be run in any direction from an existing outlet, but not on the floor or within ___ inches from the floor. |
| `final-exam-#5-049` | choice A | 6 inches | 6 |
| `final-exam-#5-049` | choice B | 4 inches | 4 |
| `final-exam-#5-049` | choice C | 3 inches | 3 |
| `final-exam-#5-049` | choice D | 2 inches | 2 |
| `final-exam-#5-052` | stem | A 300 foot run of 800 amp busway is installed in a commercial warehouse building. The last 20' of the busway run is reduced to a bus rating of 200 amps. Which of the following best describes : requirements for installation of the smaller bus? | A 300 foot run of 800 amp busway is installed in a commercial warehouse building. The last 20 feet of the busway run is reduced to a bus rating of 200 amps. Which of the following best describes requirements for installation of the smaller bus? |
| `final-exam-#5-064` | stem | For installations of resistors and reactors, a thermal barrier is required if the space to combustible material is less than... | For installations of resistors and reactors, a thermal barrier is required if the space between them and any combustible material is less than ___. |
| `final-exam-#5-068` | stem | Rigid metal conduit may be installed in or under cinder fill when protected on all sides by noncinder concrete not less than... | Rigid metal conduit shall be permitted to be installed in or under cinder fill where subject to permanent moisture where protected on all sides by a layer of noncinder concrete not less than ___ thick; where the conduit is not less than 18 inches under the fill; or where protected by corrosion protection and judged suitable (approved) for the condition. |
| `final-exam-#5-070` | stem | For a 1/2-inch RNC run secured within 36 inches of each termination, what is the maximum permitted spacing between supports along the run? | If a 1/2-inch RNC is securely fastened within 3 ft of termination points, it shall be permitted to be fastened every ___. |
| `open-book-exam-#1-004` | choice C | 1 1/8" | 1/8" |
| `open-book-exam-#4-008` | stem | Except as permitted by 300.3(B)(4), all conductors of a multiwire branch circuit shall originate from the equipment containing the branch-circuit overcurrent protective device(s). The circuit shall have a means to simultaneously disconnect its phase conductors and shall supply only line-to-___ loads. | All conductors of a multiwire branch circuit shall originate from the same panelboard, simultaneously disconnect all ungrounded conductors and supply only line-to-___ loads. |
| `open-book-exam-#7-001` | stem | Grounded conductors of premises wiring systems shall be ___ connected to the supply system grounded conductor to ensure a common, continuous grounded system. | Premises wiring shall not be ___ connected to a supply system unless the latter contains, for any grounded conductor of the interior system, a corresponding conductor that is grounded. |
| `open-book-exam-#7-025` | stem | Where a building or structure has any combination of feeders, branch circuits, or services passing through it or supplying it, a permanent plaque or directory shall be installed at each feeder and branch circuit ___ denoting all other services, feeders, or branch circuits supplying that building or structure or passing through that building or structure and the area served by each. | Where a building or structure has any combination of feeders, branch circuits, or services passing through it or supplying it, a permanent plaque or directory shall be installed at each feeder and branch circuit ___ location denoting all other services, feeders, or branch circuits supplying that building or structure or passing through that building or structure and the area served by each. |
| `open-book-exam-#10-002` | stem | For the purpose of load calculations, the calculated floor area of a dwelling unit shall not include ___. | For the purpose of load calculations, the square footage of a dwelling unit includes ___. |
| `open-book-exam-#10-002` | choice C | unfinished areas not adaptable for future use | areas not adaptable as future occupiable space |
| `open-book-exam-#10-025` | stem | For underground systems over 1000 volts, backfill containing large rocks, paving materials, cinders, large or sharply angular substances, or corrosive material shall not be placed where it can ___ raceways, cables, or other structures, prevent adequate compaction of fill, or contribute to corrosion. | Backfill that contains large rocks, paving materials, cinders, large or sharply angular substances, or corrosive material shall not be placed in an excavation where materials can ___ raceways, cables, or other structures or prevent adequate compaction of fill or contribute to the corrosion of raceways, cables, or other substructures over 1000v. |

## Voice clips to regenerate (99 records)

Records from the first two sections, whose spoken stem or choices changed:

- `final-exam-#1-004`
- `final-exam-#1-022`
- `final-exam-#1-026`
- `final-exam-#1-030`
- `final-exam-#1-034`
- `final-exam-#1-039`
- `final-exam-#1-042`
- `final-exam-#1-050`
- `final-exam-#1-053`
- `final-exam-#1-056`
- `final-exam-#1-058`
- `final-exam-#1-067`
- `final-exam-#1-070`
- `final-exam-#3-001`
- `final-exam-#3-004`
- `final-exam-#3-005`
- `final-exam-#3-006`
- `final-exam-#3-008`
- `final-exam-#3-009`
- `final-exam-#3-010`
- `final-exam-#3-011`
- `final-exam-#3-012`
- `final-exam-#3-013`
- `final-exam-#3-015`
- `final-exam-#3-017`
- `final-exam-#3-019`
- `final-exam-#3-020`
- `final-exam-#3-023`
- `final-exam-#3-024`
- `final-exam-#3-025`
- `final-exam-#3-026`
- `final-exam-#3-027`
- `final-exam-#3-028`
- `final-exam-#3-029`
- `final-exam-#3-031`
- `final-exam-#3-032`
- `final-exam-#3-034`
- `final-exam-#3-037`
- `final-exam-#3-038`
- `final-exam-#3-039`
- `final-exam-#3-042`
- `final-exam-#3-043`
- `final-exam-#3-045`
- `final-exam-#3-047`
- `final-exam-#3-049`
- `final-exam-#3-050`
- `final-exam-#3-051`
- `final-exam-#3-052`
- `final-exam-#3-053`
- `final-exam-#3-056`
- `final-exam-#3-058`
- `final-exam-#3-060`
- `final-exam-#3-061`
- `final-exam-#3-063`
- `final-exam-#3-064`
- `final-exam-#3-066`
- `final-exam-#3-067`
- `final-exam-#3-068`
- `final-exam-#3-070`
- `final-exam-#5-001`
- `final-exam-#5-004`
- `final-exam-#5-005`
- `final-exam-#5-006`
- `final-exam-#5-007`
- `final-exam-#5-008`
- `final-exam-#5-020`
- `final-exam-#5-021`
- `final-exam-#5-022`
- `final-exam-#5-023`
- `final-exam-#5-024`
- `final-exam-#5-032`
- `final-exam-#5-033`
- `final-exam-#5-034`
- `final-exam-#5-036`
- `final-exam-#5-038`
- `final-exam-#5-039`
- `final-exam-#5-050`
- `final-exam-#5-051`
- `final-exam-#5-053`
- `final-exam-#5-054`
- `final-exam-#5-066`
- `open-book-exam-#1-001`
- `open-book-exam-#1-002`
- `open-book-exam-#1-003`
- `open-book-exam-#1-005`
- `open-book-exam-#1-010`
- `open-book-exam-#1-021`
- `open-book-exam-#4-003`
- `open-book-exam-#4-014`
- `open-book-exam-#4-016`
- `open-book-exam-#4-025`
- `open-book-exam-#7-005`
- `open-book-exam-#7-006`
- `open-book-exam-#7-024`
- `open-book-exam-#10-004`
- `open-book-exam-#10-006`
- `open-book-exam-#10-009`
- `open-book-exam-#10-010`
- `open-book-exam-#10-012`

## Explanation content audit (84 records)

Post-answer explanation fields only: `reference_text` (74), `choice_notes` with the
rebuilt `tip_short` (9), `tip_title` (6), `article` (3), `article_title` (2),
`worked` / `formula` (1 each). No stem, choice or `correct_index` changed; a
script compared all 279 records before and after and found zero differences.
Typical fixes: provisions truncated mid-list (680.43(B)(1) lost its (a)/(b)/(c)
labels and items (1)/(2)), provisions that stopped before the tested item,
paraphrases shown as quoted Code text, wrong table or section numbers, and choice
notes that stated a wrong fact (800.44(B) Ex. 3 allows 3 ft on a 4/12 roof).

The NEC 2023 wording was reviewed from recall, without the book. The
medium-confidence `reference_text` replacements (50 records) should be checked
against NFPA 70-2023 when a copy is at hand. Done on 2026-09-28 against the 2023
text on UpCodes Premium; results per record in `docs/CONTENT_AUDIT_2023.md`.

| Record | Fields | Finding (confidence) |
|---|---|---|
| `final-exam-#1-004` | reference_text | formatting / truncation (medium) |
| `final-exam-#1-005` | reference_text | inconsistency (high) |
| `final-exam-#1-009` | article_title, reference_text, tip_title | inconsistency (high); formatting / truncation (high); inconsistency (medium) |
| `final-exam-#1-010` | reference_text | formatting / truncation (medium) |
| `final-exam-#1-011` | tip_title | inconsistency (medium) |
| `final-exam-#1-012` | reference_text | formatting / truncation (medium) |
| `final-exam-#1-014` | reference_text | formatting / truncation (medium) |
| `final-exam-#1-021` | reference_text | wrong NEC content (medium) |
| `final-exam-#1-023` | reference_text | formatting / truncation (medium) |
| `final-exam-#1-027` | reference_text | formatting / truncation (medium) |
| `final-exam-#1-029` | reference_text | formatting / truncation (medium) |
| `final-exam-#1-030` | tip_title | inconsistency (medium) |
| `final-exam-#1-032` | reference_text | formatting / truncation (medium) |
| `final-exam-#1-037` | reference_text | formatting / truncation (high) |
| `final-exam-#1-039` | reference_text | formatting / truncation (medium) |
| `final-exam-#1-040` | reference_text | wrong NEC content (high) |
| `final-exam-#1-042` | reference_text | formatting / truncation (medium) |
| `final-exam-#1-043` | reference_text | formatting / truncation (medium) |
| `final-exam-#1-049` | reference_text | formatting / truncation (medium) |
| `final-exam-#1-050` | choice_notes, reference_text, tip_short | wrong NEC content (medium) |
| `final-exam-#1-053` | reference_text | formatting / truncation (high) |
| `final-exam-#1-057` | reference_text | formatting / truncation (high) |
| `final-exam-#1-058` | reference_text | formatting / truncation (medium) |
| `final-exam-#1-068` | reference_text | formatting / truncation (medium) |
| `final-exam-#1-070` | reference_text | formatting / truncation (medium) |
| `final-exam-#3-003` | reference_text | formatting / truncation (medium) |
| `final-exam-#3-014` | reference_text | wrong NEC content (medium) |
| `final-exam-#3-015` | reference_text | formatting / truncation (high) |
| `final-exam-#3-016` | reference_text | formatting / truncation (medium) |
| `final-exam-#3-017` | reference_text | wrong NEC content (medium) |
| `final-exam-#3-028` | reference_text | wrong NEC content (medium) |
| `final-exam-#3-031` | choice_notes, tip_short | inconsistency (medium) |
| `final-exam-#3-033` | reference_text | formatting / truncation (high) |
| `final-exam-#3-040` | reference_text, choice_notes, worked, tip_short | wrong NEC content (medium); inconsistency (medium) |
| `final-exam-#3-042` | reference_text | formatting / truncation (high) |
| `final-exam-#3-047` | tip_title | inconsistency (high) |
| `final-exam-#3-048` | reference_text | formatting / truncation (medium) |
| `final-exam-#3-049` | reference_text | formatting / truncation (medium) |
| `final-exam-#3-052` | reference_text | wrong NEC content (medium) |
| `final-exam-#3-053` | reference_text, choice_notes, tip_short | wrong NEC content (medium) |
| `final-exam-#3-068` | reference_text, choice_notes, tip_short | wrong NEC content (medium) |
| `final-exam-#5-001` | choice_notes, tip_short | inconsistency (medium) |
| `final-exam-#5-005` | reference_text | formatting / truncation (high) |
| `final-exam-#5-018` | reference_text | formatting / truncation (high) |
| `final-exam-#5-019` | reference_text, tip_title | formatting / truncation (high); inconsistency (medium) |
| `final-exam-#5-020` | reference_text | formatting / truncation (high) |
| `final-exam-#5-022` | article_title | inconsistency (high) |
| `final-exam-#5-032` | reference_text | formatting / truncation (medium) |
| `final-exam-#5-033` | reference_text | formatting / truncation (high) |
| `final-exam-#5-036` | reference_text | formatting / truncation (medium) |
| `final-exam-#5-067` | reference_text | formatting / truncation (medium) |
| `final-exam-#5-070` | reference_text, article | wrong NEC content (medium); inconsistency (medium) |
| `open-book-exam-#1-003` | reference_text | formatting / truncation (high) |
| `open-book-exam-#1-005` | reference_text | formatting / truncation (medium) |
| `open-book-exam-#1-010` | reference_text | formatting / truncation (medium) |
| `open-book-exam-#1-012` | reference_text | wrong NEC content (medium) |
| `open-book-exam-#1-021` | reference_text | formatting / truncation (medium) |
| `open-book-exam-#4-004` | reference_text | formatting / truncation (medium) |
| `open-book-exam-#4-010` | reference_text | formatting / truncation (medium) |
| `open-book-exam-#4-011` | reference_text | formatting / truncation (medium) |
| `open-book-exam-#4-012` | reference_text | formatting / truncation (medium) |
| `open-book-exam-#4-014` | reference_text | formatting / truncation (medium) |
| `open-book-exam-#4-015` | reference_text | wrong NEC content (medium) |
| `open-book-exam-#4-016` | reference_text | formatting / truncation (medium) |
| `open-book-exam-#4-018` | reference_text | formatting / truncation (medium) |
| `open-book-exam-#4-020` | reference_text | formatting / truncation (high) |
| `open-book-exam-#4-021` | reference_text | wrong NEC content (high) |
| `open-book-exam-#4-023` | reference_text | wrong NEC content (medium) |
| `open-book-exam-#4-025` | choice_notes, tip_short | formatting / truncation (high) |
| `open-book-exam-#7-003` | reference_text | formatting / truncation (high) |
| `open-book-exam-#7-004` | article, reference_text, formula, choice_notes, tip_short | inconsistency (high); wrong NEC content (medium); inconsistency (medium) |
| `open-book-exam-#7-007` | reference_text | formatting / truncation (medium) |
| `open-book-exam-#7-009` | reference_text | formatting / truncation (high) |
| `open-book-exam-#7-010` | reference_text | wrong NEC content (medium) |
| `open-book-exam-#7-012` | article | wrong NEC content (medium) |
| `open-book-exam-#7-014` | reference_text | wrong NEC content (medium) |
| `open-book-exam-#7-023` | reference_text | formatting / truncation (high) |
| `open-book-exam-#7-024` | tip_title | inconsistency (medium) |
| `open-book-exam-#10-002` | reference_text | formatting / truncation (high) |
| `open-book-exam-#10-004` | reference_text | formatting / truncation (high) |
| `open-book-exam-#10-008` | reference_text | formatting / truncation (high) |
| `open-book-exam-#10-013` | reference_text | formatting / truncation (medium) |
| `open-book-exam-#10-015` | reference_text | formatting / truncation (high) |
| `open-book-exam-#10-024` | choice_notes, tip_short | inconsistency (medium) |
