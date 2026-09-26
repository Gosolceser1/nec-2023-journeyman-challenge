# Python dictionary mapping question ID to reference_text and worked solution
REFERENCES_TO_ADD = {
    # 1. final-exam-#1-019
    "final-exam-#1-019": {
        "reference_text": "Electrical Theory • Power Equation (Watt's Law)\nIn the electrical power equation W = E x I (Watts = Volts x Amperes), the letter I traditionally designates 'Intensity of current' (from the French 'intensité du courant'), representing current flow in amperes.",
        "worked": "W = E x I where W is electrical power in watts, E is electromotive force in volts, and I is intensity of current in amperes."
    },
    # 2. final-exam-#1-033
    "final-exam-#1-033": {
        "reference_text": "Switch Terminology & Classification • Three-Way Switches\nA standard three-way switch connects a common terminal to either of two traveler terminals. In standard electrical switch configuration terminology, this single-pole, double-throw mechanism is designated as an SPDT switch.",
        "worked": "A three-way switch has one input (single pole) and alternates between two traveler outputs (double throw), making it electrically equivalent to an SPDT switch."
    },
    # 3. final-exam-#1-041
    "final-exam-#1-041": {
        "reference_text": "Motor Control Circuits • Control Station Wiring\nA stop pushbutton switch has normally closed (NC) contacts that must open the control circuit to de-energize the magnetic holding coil. Therefore, the stop switch is always wired in series with the motor control circuit.",
        "worked": "Safety and control devices intended to interrupt operation must be wired in series with the control loop so that opening the contact breaks the circuit."
    },
    # 4. final-exam-#1-044
    "final-exam-#1-044": {
        "reference_text": "NEC Article 100 Definitions • Ground Fault\nGround Fault: An unintentional, electrically conducting connection between an ungrounded conductor of an electrical circuit and the normally non-current-carrying conductors, metallic enclosures, metallic raceways, metallic equipment, or earth.",
        "worked": "By NEC Article 100, an unintentional conductive path from an energized conductor to metal enclosures, raceways, or earth is defined as a ground fault."
    },
    # 5. final-exam-#3-010
    "final-exam-#3-010": {
        "reference_text": "NEC Article 100 Definitions • Busbar\nBusbar (as applied to Article 393): A noninsulated conductor of any shape (usually rectangular) with a cross-sectional area of at least 1 mm² (0.00155 in.²), installed in a suspended ceiling power distribution system.",
        "worked": "The specific definition of 'busbar' in Article 100 is explicitly qualified with parenthetical scope stating that it applies only to Article 393 (Low-Voltage Suspended Ceiling Power Distribution Systems)."
    },
    # 6. final-exam-#3-011
    "final-exam-#3-011": {
        "reference_text": "NFPA 70E Standard for Electrical Safety in the Workplace • Human Factors\nSafety studies consistently demonstrate that the vast majority of workplace electrical incidents and injuries are initiated by people (human performance factors, unsafe acts, or procedural deviations) rather than spontaneous equipment failure.",
        "worked": "According to NFPA 70E Annex Q (Human Performance), unsafe acts, lack of awareness, and human error initiate the vast majority of workplace electrical incidents."
    },
    # 7. final-exam-#3-012
    "final-exam-#3-012": {
        "reference_text": "Testing Laboratories & Product Certification • Records of Tested Equipment\nNationally Recognized Testing Laboratories (NRTL) such as Underwriters' Laboratories (UL) test electrical equipment to safety standards and maintain directories and records of listed and certified electrical equipment.",
        "worked": "Underwriters' Laboratories (UL) tests electrical equipment to established standards and maintains published directories of listed and labeled products."
    },
    # 8. final-exam-#3-021
    "final-exam-#3-021": {
        "reference_text": "NFPA 70E Standard for Electrical Safety in the Workplace • Safe Work Practices\nEffective electrical safe work practices are based on identifying the type of hazard (shock, arc flash, arc blast), the manner of exposure (contact, proximity), and the degree of exposure (voltage, incident energy).",
        "worked": "Effective safe work practices comprehensively address all of these: type of hazard, manner of exposure, and degree of exposure."
    },
    # 9. final-exam-#3-029
    "final-exam-#3-029": {
        "reference_text": "NEC Article 100 Definitions • Coordination, Selective\nCoordination, Selective (Selective Coordination): Localization of an overcurrent condition to restrict outages to the circuit or equipment affected, accomplished by the selection and installation of overcurrent protective devices and their ratings or settings for the full range of available overcurrents.",
        "worked": "Article 100 defines selective coordination as localizing an overcurrent to restrict outages specifically to the faulted circuit."
    },
    # 10. final-exam-#3-032
    "final-exam-#3-032": {
        "reference_text": "NEC Article 100 Definitions • Nursing Home\nNursing Home: A building or portion of a building used on a 24-hour basis for the lodging, boarding, and nursing care of four or more persons who, because of mental or physical incapacity, may be unable to provide for their own needs and safety without the assistance of another person.",
        "worked": "Under NEC Article 100 Health Care Facility definitions, a nursing home provides care on a 24-hour basis for 4 or more inpatients."
    },
    # 11. final-exam-#3-041
    "final-exam-#3-041": {
        "reference_text": "NFPA 70E Standard for Electrical Safety in the Workplace • Lockout/Tagout Principles\nBefore lockout/tagout is executed, workers must have a supplemental list showing all involved energy sources and isolating devices, and each person must ensure they control all energy sources affecting their workspace.",
        "worked": "Both securing the supplemental list of energy sources and ensuring individual worker control over all isolating devices are mandatory under NFPA 70E 120.4."
    },
    # 12. final-exam-#3-043
    "final-exam-#3-043": {
        "reference_text": "NFPA 70E Standard for Electrical Safety in the Workplace • Hazard Recognition\nElectricity cannot be directly seen, heard, or smelled in normal operational conditions; the only way to recognize an electrical hazard is by observing signs, warning labels, measurement signals, and test instruments indicating its presence.",
        "worked": "Because electric current is invisible, workers identify hazards by observing safety signs, danger labels, and test instrument readings indicating voltage."
    },
    # 13. final-exam-#3-045
    "final-exam-#3-045": {
        "reference_text": "Electrical Theory • Alternating Current Characteristics\nThe frequency of an alternating current (AC) waveform is defined as the total number of complete cycles completed in one second, measured in hertz (Hz).",
        "worked": "Cycles per second defines frequency (1 cycle per second = 1 Hz; in North America standard utility frequency is 60 Hz)."
    },
    # 14. final-exam-#3-058
    "final-exam-#3-058": {
        "reference_text": "NEC Article 100 Definitions • Fibers/Flyings, Ignitible\nIn the 2023 NEC, hazardous location definitions previously scattered across Articles 500 through 506—including 'Fibers/Flyings, Ignitible'—have been consolidated into Article 100.",
        "worked": "In the 2023 NEC reorganization, all general and specialized definitions, including ignitible fibers/flyings, are located in Article 100."
    },
    # 15. final-exam-#3-062
    "final-exam-#3-062": {
        "reference_text": "Electrical Blueprint Symbols & Abbreviations • Power\nOn electrical construction drawings, schedules, and riser diagrams, standard industry conventions designate 'Power' with the abbreviation PWR.",
        "worked": "Standard electrical drafting abbreviations use PWR for power (PB for pushbutton, PF for power factor)."
    },
    # 16. final-exam-#5-007
    "final-exam-#5-007": {
        "reference_text": "NEC Article 100 Definitions • Bottom Shield\nBottom Shield: A protective layer that is installed between the floor and Type FCC flat conductor cable to protect the cable from physical damage and may or may not be incorporated as an integral part of the cable.",
        "worked": "Under Article 100 (Type FCC definitions), the bottom shield is the protective layer placed between the floor and the flat conductor cable."
    },
    # 17. final-exam-#5-022
    "final-exam-#5-022": {
        "reference_text": "NEC Article 100 & 338 • Underground Service-Entrance Cable (Type USE)\nType USE (Underground Service-Entrance) cable is identified for underground use, including direct burial in the earth for general wiring applications and branch circuits or feeders.",
        "worked": "Type USE cable is specifically constructed, tested, and listed for direct burial in earth without raceways."
    },
    # 18. final-exam-#1-064
    "final-exam-#1-064": {
        "reference_text": "Electrical Blueprint Reading • Standard Reading Pattern\nWhen reading and surveying electrical architectural blueprints, standard drafting practice is to begin reading from the upper left-hand corner, moving systematically across and down the plan sheet.",
        "worked": "Standard plan-reading practice starts at the upper left-hand corner of the drawing so circuits and layout are traced without omission."
    },
    # 19. final-exam-#1-047
    "final-exam-#1-047": {
        "reference_text": "Electrical Blueprint Symbols • Temperature-Actuated Switch\nStandard architectural/schematic electrical switch symbols include temperature-actuated switches, which are shown with a switch contact symbol combined with a bimetallic/thermal sensing symbol.",
        "worked": "In standard schematic diagrams, Diagram A illustrates the temperature-actuated switch contact."
    },
    # 20. final-exam-#3-070
    "final-exam-#3-070": {
        "reference_text": "Electrical Schematic Symbols • Delta-Wound Generator\nOn electrical single-line diagrams, a three-phase delta-connected alternator or generator is represented by a circle with an inscribed equilateral triangle (representing the closed delta loop).",
        "worked": "A delta (Δ) connection is symbolized by a triangle scribed inside the circular generator symbol."
    },
    # 21. open-book-exam-#1-002
    "open-book-exam-#1-002": {
        "reference_text": "NEC Article 100 Definitions • Main Bonding Jumper\nMain Bonding Jumper: The connection between the grounded circuit conductor and the equipment grounding conductor, or the supply-side bonding jumper, or both, at the service.",
        "worked": "Article 100 defines the main bonding jumper as the essential conductor or screw connecting the neutral (grounded conductor) to the service disconnect enclosure and equipment ground."
    },
    # 22. open-book-exam-#4-001
    "open-book-exam-#4-001": {
        "reference_text": "NEC Article 100 Definitions • Qualified Person\nQualified Person: One who has skills and knowledge related to the construction and operation of the electrical equipment and installations and has received safety training to recognize and avoid the hazards involved.",
        "worked": "Article 100 defines a qualified person by both their technical skills/knowledge and their specific electrical safety training."
    },
    # 23. open-book-exam-#4-009
    "open-book-exam-#4-009": {
        "reference_text": "NEC Article 100 Definitions • Ground Fault\nGround Fault: An unintentional, electrically conducting connection between an ungrounded conductor of an electrical circuit and the normally non-current-carrying conductors, metallic enclosures, metallic raceways, metallic equipment, or earth.",
        "worked": "By Article 100, an accidental connection between an energized conductor and grounded metallic surfaces or earth is a ground fault."
    },
    # 24. open-book-exam-#4-013
    "open-book-exam-#4-013": {
        "reference_text": "NEC Article 100 Definitions • Labeled\nLabeled: Equipment or materials to which has been attached a label, symbol, or other identifying mark of an organization that is acceptable to the authority having jurisdiction and concerned with product evaluation, that maintains periodic inspection of production of labeled equipment or materials, and by whose labeling the manufacturer indicates compliance with appropriate standards or performance in a specified manner.",
        "worked": "Under Article 100, equipment bearing the mark of an approved testing organization is defined as labeled."
    },
    # 25. open-book-exam-#7-005
    "open-book-exam-#7-005": {
        "reference_text": "NEC Article 100 Definitions • Maximum Water Level\nMaximum Water Level: The highest level that water can reach before it spills out of the swimming pool, spa, or hot tub basin.",
        "worked": "Article 100 defines Maximum Water Level as the threshold water elevation prior to spilling over the perimeter of a pool or basin."
    },
    # 26. open-book-exam-#7-020
    "open-book-exam-#7-020": {
        "reference_text": "NEC Article 100 Definitions • Sign Body\nSign Body: A portion of a sign that may provide protection from the weather but is not an electrical enclosure.",
        "worked": "Under Article 100 (Electric Signs and Outline Lighting), the sign body provides physical/weather housing without functioning as an electrical enclosure."
    },
    # 27. open-book-exam-#10-006
    "open-book-exam-#10-006": {
        "reference_text": "NEC Article 100 Definitions • Remote Disconnect Control\nRemote Disconnect Control: An electric device and circuit that controls a disconnecting means through a relay or equivalent device.",
        "worked": "Article 100 defines Remote Disconnect Control as the device/circuit operating a power disconnect remotely via relay or actuator."
    },
    # 28. open-book-exam-#10-024
    "open-book-exam-#10-024": {
        "reference_text": "NEC Article 100 Definitions • Grounding Conductor\nGrounding Conductor: A conductor used to connect equipment or the grounded circuit of a wiring system to a grounding electrode or electrodes.",
        "worked": "Article 100 defines the grounding conductor as the conductor connecting the system or equipment to the earth electrode."
    },
    # 29. final-exam-#1-013
    "final-exam-#1-013": {
        "reference_text": "Electrical Meters & Measurement • Ammeter Connection\nAn ammeter measures electric current and has very low internal resistance; it must always be connected in series with the load to measure the rate of charge flow through that branch.",
        "worked": "Meter diagram II shows the meter wired directly in series with the load circuit, which is the proper connection for an ammeter."
    },
    # 30. final-exam-#3-022
    "final-exam-#3-022": {
        "reference_text": "Insulated Hand Tools & Live Work Safety • ASTM F1505 / IEC 60900\nInsulated tools rated for energized electrical work must comply with ASTM F1505 or IEC 60900. They are marked with the official double triangle symbol and the rated voltage (typically 1000 V) stamped on the handle.",
        "worked": "Tools certified for live electrical work bear the double triangle symbol and specific voltage rating on the insulated handle."
    },
    # 31. final-exam-#5-003
    "final-exam-#5-003": {
        "reference_text": "NEC Article 100 Definitions & Article 330 • Metal-Clad Cable (Type MC)\nType MC Cable: A factory assembly of one or more insulated circuit conductors with or without optical fiber members enclosed in an armor of interlocking metal tape, or a smooth or corrugated metallic sheath.",
        "worked": "Article 100 and Article 330 define Type MC (Metal-Clad) cable by its interlocking metal tape or continuous metallic sheath."
    }
}
