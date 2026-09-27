import json

updates = {
    # 1. open-book-exam-#7-021: 408.36(B)
    "open-book-exam-#7-021": {
        "reference_text": "408.36(B) Overcurrent Protection for Panelboards Supplied Through a Transformer\nWhere a panelboard is supplied through a transformer, the overcurrent protection required by 408.36 shall be located on the secondary side of the transformer. Exception: A panelboard supplied by the secondary side of a transformer shall be considered protected by the overcurrent protection provided on the primary side of the transformer in accordance with 240.21(C)(1)."
    },

    # 2. open-book-exam-#10-002: 220.5(C) — NEC 2023 no longer excludes garages from dwelling floor area.
    "open-book-exam-#10-002": {
        "prompt": "For the purpose of load calculations, the square footage of a dwelling unit includes ___.",
        "answers": [
            "open porches",
            "garages",
            "areas not adaptable as future occupiable space",
            "all of these"
        ],
        "correct_index": 1,
        "article": "220.5(C)",
        "reference_text": "220.5(C) Floor Area\nThe floor area for each floor shall be calculated from the outside dimensions of the building, dwelling unit, or other area involved. For dwelling units, the calculated floor area shall not include open porches or unfinished areas not adaptable for future use as a habitable room or occupiable space.",
        "choice_notes": [
            "Open porches are excluded from dwelling floor area.",
            "Garages are no longer excluded in the 2023 NEC, so they are counted.",
            "Areas not adaptable for future occupiable space are excluded.",
            "Porches and unadaptable areas are still excluded."
        ]
    },

    # 3. open-book-exam-#10-003: 406.10(C)
    "open-book-exam-#10-003": {
        "reference_text": "406.10(C) Grounding Terminal Use\nA grounding terminal shall not be used for purposes other than the connection to the equipment grounding conductor."
    },

    # 4. open-book-exam-#10-004: 409.21(B)
    "open-book-exam-#10-004": {
        "article": "409.21",
        "reference_text": "409.21 Overcurrent Protection — Supply Conductors\nWhere overcurrent protection is provided as part of the industrial control panel, the supply conductors shall be considered as either feeders or taps as covered by 240.21."
    },

    # 5. open-book-exam-#10-012: 724.40
    "open-book-exam-#10-012": {
        "reference_text": "724.40 Class 1 Power-Limited Circuits\nA Class 1 power-limited circuit shall be supplied from a source having a rated output of not more than 30 volts and 1,000 volt-amperes."
    },

    # 6. open-book-exam-#10-013: 314.23(E)
    "open-book-exam-#10-013": {
        "reference_text": "314.23(E) Raceway-Supported Enclosure, Without Devices, Luminaires, or Lampholders\nAn enclosure that does not contain a device(s) other than splicing devices or support a luminaire(s), lampholder, or other equipment and is not over 100 cu in. shall be supported by two or more conduits threaded into hubs identified for the purpose (or wrenchtight into the enclosure) and supported within 3 ft of the enclosure."
    },

    # 7. open-book-exam-#10-014: 660.9
    "open-book-exam-#10-014": {
        "reference_text": "660.9 Minimum Size of Conductors\nSize 18 AWG or 16 AWG fixture wires and flexible cords shall be permitted for the control and operating circuits of X-ray and auxiliary equipment where protected by not larger than 20-ampere overcurrent devices."
    },

    # 8. open-book-exam-#10-015: 310.3(B)(3)
    "open-book-exam-#10-015": {
        "reference_text": "310.3(B)(3) Copper-Clad Aluminum Conductors\nConductors drawn from a copper-clad aluminum rod with the copper metallurgically bonded to an aluminum core: the copper forms a minimum of 10 percent of the cross-sectional area of a solid conductor or each strand of a stranded conductor."
    },

    # 9. open-book-exam-#10-019: 517.18(B)(1)
    "open-book-exam-#10-019": {
        "reference_text": "517.18(B)(1) Hospital General Care Bed Locations\nEach patient bed location shall be provided with a minimum of eight receptacles, which can be single, duplex (e.g. 4 duplex), or quadruplex type, listed hospital grade."
    },

    # 10. final-exam-#5-004: 324.56(B)
    "final-exam-#5-004": {
        "article": "324.56(B)",
        "reference_text": "324.56(B) Transition Assemblies\nPower feed, grounding connection, and shield system connection between the FCC system and other wiring systems shall be accomplished in a transition assembly identified for this use."
    },

    # 11. final-exam-#5-021: 338.10(B)(3)
    "final-exam-#5-021": {
        "reference_text": "338.10(B)(3) Temperature Limitations\nType SE service-entrance cable used to supply appliances shall not be subject to conductor temperatures in excess of the temperature specified for the type of insulation involved."
    },

    # 12. final-exam-#5-023: 336.24
    "final-exam-#5-023": {
        "reference_text": "336.24 Bending Radius\nType TC cables with metallic shielding shall have a minimum bending radius of not less than 12 times the cable overall diameter."
    },

    # 13. final-exam-#5-033: 344.120
    "final-exam-#5-033": {
        "reference_text": "344.120 Marking\nEach length of rigid metal conduit (RMC) shall be clearly and durably identified at least every 3 m (10 ft) as required by 110.21."
    },

    # 14. final-exam-#5-034: 358.14
    "final-exam-#5-034": {
        "reference_text": "358.14 Dissimilar Metals\nAluminum fittings and enclosures shall be permitted to be used with steel electrical metallic tubing (EMT) where not subject to severe corrosive influences."
    },

    # 15. final-exam-#5-037: 358.100
    "final-exam-#5-037": {
        "reference_text": "358.100 Construction\nElectrical metallic tubing (EMT) shall be made of steel with protective coatings, aluminum, or stainless steel (any of these listed materials)."
    },

    # 16. final-exam-#5-050: 368.234(A)
    "final-exam-#5-050": {
        "reference_text": "368.234(A) Busways Passing Through Walls and Floors (Over 1000 Volts)\nBusways having sections located both inside and outside of buildings shall have a vapor seal at the building wall to prevent the passage of air or vapor."
    },

    # 17. final-exam-#5-051: 370.10
    "final-exam-#5-051": {
        "article": "370.10",
        "reference_text": "370.10 Cablebus Uses Permitted\nCablebus shall be installed only for exposed work, except where permitted to pass through walls or partitions."
    },

    # 18. final-exam-#1-054: 400.13
    "final-exam-#1-054": {
        "article": "400.13",
        "reference_text": "400.13 Splices in Flexible Cords\nFlexible cords shall be used only in continuous lengths without splice or tap. Repair of hard-service cord and junior hard-service cord 14 AWG and larger shall be permitted if conducted in accordance with 110.14(B)."
    },

    # 19. final-exam-#5-005: 322.56(B)
    "final-exam-#5-005": {
        "article": "322.56(B)",
        "reference_text": "322.56(B) Taps in Flat Cable Assemblies (Type FC)\nTap devices used in FC assemblies shall be rated at not less than 15 amperes and not more than 300 volts to ground."
    },

    # 20. final-exam-#3-003: 425.22(D)
    "final-exam-#3-003": {
        "article": "425.22(D)",
        "reference_text": "425.22(D) Conductors Supplying Supplementary Overcurrent Protective Devices\nThe conductors supplying supplementary overcurrent protective devices for fixed industrial process heating equipment shall be considered branch-circuit conductors."
    },

    # 21. final-exam-#5-019: 334.116(B)
    "final-exam-#5-019": {
        "article": "334.116(B)",
        "reference_text": "334.116(B) Type NMC Sheath Construction\nThe overall covering of Type NMC cable shall be flame-retardant, moisture-resistant, fungus-resistant, and corrosion-resistant."
    },

    # 22. open-book-exam-#4-003: 334.12(B)(4)
    "open-book-exam-#4-003": {
        "reference_text": "334.12(B)(4) Uses Not Permitted — Type NM\nType NM cable shall not be used in damp or wet locations, or where embedded in masonry or concrete."
    },

    # 23. open-book-exam-#7-008: 110.13(B)
    "open-book-exam-#7-008": {
        "reference_text": "110.13(B) Cooling and Free Circulation of Air\nElectrical equipment provided with ventilating openings shall be installed so that walls or other obstructions do not prevent the free circulation of air through the equipment."
    },

    # 24. open-book-exam-#7-009: 225.39
    "open-book-exam-#7-009": {
        "reference_text": "225.39 Rating of Disconnect\nThe feeder or branch circuit disconnecting means shall have a rating not less than the calculated load to be served."
    },

    # 25. open-book-exam-#7-011: 210.19(A)(2)
    "open-book-exam-#7-011": {
        "reference_text": "210.19(A)(2) Branch Circuits with More Than One Receptacle\nConductors of branch circuits supplying more than one receptacle for cord-and-plug-connected portable tools shall have an ampacity of not less than the rating of the branch circuit."
    },

    # 26. open-book-exam-#7-012: 344.10(A)(3)
    "open-book-exam-#7-012": {
        "reference_text": "344.10(A)(3) Enamel-Protected Raceways\nFerrous raceways and fittings protected from corrosion solely by enamel shall be permitted only indoors and in occupancies not subject to severe corrosive influences."
    },

    # 27. open-book-exam-#7-015: 310.15(A)
    "open-book-exam-#7-015": {
        "reference_text": "310.15(A) General Ampacity\nThe temperature correction and adjustment factors shall be permitted to be applied to the ampacity for the temperature rating of the conductor, if the corrected and adjusted ampacity does not exceed the ampacity for the temperature rating of the termination in accordance with 110.14(C)."
    },

    # 28. open-book-exam-#7-016: 700.7(A)
    "open-book-exam-#7-016": {
        "reference_text": "700.7(A) Signs at Emergency Service Entrance\nA sign shall be placed at the service entrance equipment, indicating the type and location of each on-site emergency power source."
    },

    # 29. open-book-exam-#7-017: 110.14(C)(2)
    "open-book-exam-#7-017": {
        "reference_text": "110.14(C)(2) Separately Installed Pressure Connectors\nSeparately installed pressure connectors shall be used with conductors at ampacities not exceeding the ampacity at the listed and identified temperature rating of the conductor."
    },

    # 30. open-book-exam-#7-019: 110.12(B)
    "open-book-exam-#7-019": {
        "reference_text": "110.12(B) Integrity of Electrical Equipment and Connections\nInternal parts of electrical equipment, including busbars, wiring terminals, insulators, and other surfaces, shall not be damaged or contaminated by foreign materials such as paint, plaster, cleaners, abrasives, or corrosive residues."
    },

    # 31. open-book-exam-#7-024: 408.3(F)(1)
    "open-book-exam-#7-024": {
        "reference_text": "408.3(F)(1) High-Leg Identification on 4-Wire Delta Systems\nA switchboard, switchgear, or panelboard containing a 4-wire, delta-connected system where the midpoint of one phase winding is grounded shall be legibly and permanently marked: 'Caution ___ Phase Has ___ Volts to Ground.'"
    },

    # 32. final-exam-#1-023: 250.122(F)(1)(b)
    "final-exam-#1-023": {
        "reference_text": "250.122(F)(1)(b) Conductors in Parallel in Multiple Raceways\nWhere ungrounded conductors are run in parallel in multiple raceways, the equipment grounding conductor, where used, shall be run in parallel in each raceway and sized per Table 250.122."
    },

    # 33. final-exam-#1-053: 225.18(5)
    "final-exam-#1-053": {
        "reference_text": "225.18(5) Overhead Clearance Above Track Rails of Railroads\nOverhead conductors not over 1,000 volts passing over track rails of railroads shall have a minimum clearance of not less than 24 1/2 feet (7.5 m) above finished grade."
    },

    # 34. final-exam-#1-069: 600.9(C)
    "final-exam-#1-069": {
        "reference_text": "600.9(C) Wood Used in Electric Sign Enclosures\nWood used for decorative parts of an electric sign enclosure or structure shall be kept 2 inches (50 mm) from lampholders or current-carrying parts."
    },

    # 35. final-exam-#3-054: 348.28
    "final-exam-#3-054": {
        "reference_text": "348.28 Trimming Flexible Metal Conduit\nAll cut ends of flexible metal conduit must be trimmed or otherwise finished to remove rough edges, except where fittings thread into the convolutions."
    },

    # 36. final-exam-#3-016: 310.14(A)(3)
    "final-exam-#3-016": {
        "article": "310.14(A)(3)",
        "reference_text": "310.14(A)(3) Informational Note — Determinants of Conductor Temperature\nHeat generated internally in the conductor as the result of load current flow, including fundamental and harmonic currents, is a primary determinant of operating temperature."
    },

    # 37. final-exam-#3-036: 240.5(B)(1)
    "final-exam-#3-036": {
        "reference_text": "240.5(B)(1) Flexible Cord in Listed Appliance or Luminaire\nFlexible cords approved for and used with a specific listed appliance or luminaire are considered to be protected when applied within the listing requirements."
    },

    # 38. final-exam-#5-024: 334.12(A)(3)
    "final-exam-#5-024": {
        "reference_text": "334.12(A)(3) Uses Not Permitted — Service-Entrance\nTypes NM and NMC cables shall NOT be used as service-entrance cable."
    },

    # 39. final-exam-#5-035: Article 100
    "final-exam-#5-035": {
        "article": "Article 100",
        "article_title": "Definitions",
        "reference_text": "Article 100 Definitions • Pliable Raceway\nA pliable raceway is a raceway which can be bent manually with a reasonable force, but without other assistance."
    },

    # 40. final-exam-#5-055: 388.12(3)
    "final-exam-#5-055": {
        "reference_text": "388.12(3) Voltage Limitation for Surface Nonmetallic Raceways\nIn general, the voltage limitation between conductors in surface nonmetallic raceways is 300 volts, unless listed for higher voltages."
    },

    # 41. final-exam-#3-002: 551.72(B)
    "final-exam-#3-002": {
        "reference_text": "551.72(B) RV Distribution Systems (208Y/120V)\nRV site feeders from 208Y/120 volt, 3-phase systems shall be permitted to include one equipment grounding conductor, one grounded conductor, and up to three ungrounded conductors."
    },

    # 42. final-exam-#5-065: 376.30(B)
    "final-exam-#5-065": {
        "reference_text": "376.30(B) Metal Wireway Vertical Support\nVertical runs of metal wireways must be securely supported at intervals not exceeding 15 feet and must not have more than one joint between supports."
    },

    # 43. final-exam-#5-067: 342.30(B)(3)
    "final-exam-#5-067": {
        "reference_text": "342.30(B)(3) IMC Vertical Risers\nExposed vertical risers of IMC for industrial machinery or fixed equipment can be supported at intervals not exceeding 20 feet if the conduit is made up with threaded couplings, firmly supported at the top and bottom of the riser, and no other means of support is available."
    },

    # Clean up prefixes: "NEC 210.52(G)(1)" -> "210.52(G)(1)"
    "final-exam-#1-022": {"article": "210.52(G)(1)"},
    "final-exam-#1-031": {"article": "210.52(H)"},
    "final-exam-#1-035": {"article": "250.52(A)(2)"},
    "final-exam-#3-053": {"article": "344.30(B)(2)"},
    "final-exam-#3-059": {"article": "680.22(A)(2)"},
    "final-exam-#5-048": {"article": "366.100(E)"},
    "final-exam-#5-049": {"article": "382.15(A)"},
    "final-exam-#5-064": {"article": "470.11"},
    "final-exam-#5-066": {"article": "356.22"},
    "final-exam-#5-068": {"article": "344.10(C)"},
    "final-exam-#3-007": {"article": "680.35(D)"},
    "final-exam-#3-046": {"article": "408.7"},
    "final-exam-#1-025": {"article": "630.12(A)"},
    "final-exam-#1-044": {"article": "Article 100", "article_title": "Definitions"},

    # Standardize definitions format to "Article 100"
    "final-exam-#3-010": {"article": "Article 100", "article_title": "Definitions"},
    "final-exam-#3-029": {"article": "Article 100", "article_title": "Definitions"},
    "final-exam-#3-032": {"article": "Article 100", "article_title": "Definitions"},
    "final-exam-#3-058": {"article": "Article 100", "article_title": "Definitions"},
    "final-exam-#5-007": {"article": "Article 100", "article_title": "Definitions"},
    "final-exam-#5-022": {"article": "Article 100", "article_title": "Definitions"},
    "open-book-exam-#1-002": {"article": "Article 100", "article_title": "Definitions"},
    "open-book-exam-#4-001": {"article": "Article 100", "article_title": "Definitions"},
    "open-book-exam-#4-009": {"article": "Article 100", "article_title": "Definitions"},
    "open-book-exam-#4-013": {"article": "Article 100", "article_title": "Definitions"},
    "open-book-exam-#7-005": {"article": "Article 100", "article_title": "Definitions"},
    "open-book-exam-#7-020": {"article": "Article 100", "article_title": "Definitions"},
    "open-book-exam-#10-006": {"article": "Article 100", "article_title": "Definitions"},
    "open-book-exam-#10-009": {"article": "Article 100", "article_title": "Definitions"},
    "open-book-exam-#10-024": {"article": "Article 100", "article_title": "Definitions"},
    "final-exam-#5-003": {"article": "Article 100", "article_title": "Definitions"}
}

def apply_updates():
    with open('question_bank.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    records = data['records']
    questions = data['questions']

    # Build mapping for questions array: (exam, question_number) -> index
    # questions items format: [exam_upper, prompt, answers, correct_idx, article, exam_name, q_num, difficulty]
    q_map = {}
    for i, q in enumerate(questions):
        if len(q) >= 7:
            key = (q[5], q[6])
            q_map[key] = i

    applied_count = 0
    for r in records:
        rid = r['id']
        if rid in updates:
            up = updates[rid]
            for k, v in up.items():
                r[k] = v
            applied_count += 1

            # Sync into questions array if relevant fields changed
            key = (r.get('exam'), r.get('question_number'))
            if key in q_map:
                qi = q_map[key]
                if 'prompt' in up:
                    questions[qi][1] = up['prompt']
                if 'answers' in up:
                    questions[qi][2] = up['answers']
                if 'correct_index' in up:
                    questions[qi][3] = up['correct_index']
                if 'article' in up:
                    questions[qi][4] = up['article']

    print(f"Applied verified code updates to {applied_count} records.")

    with open('question_bank.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)

    print("question_bank.json updated successfully.")

if __name__ == '__main__':
    apply_updates()
