import json
import os
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from gists import GISTS, SCENES
from pipeline_paths import answer_key_ocr_dir, exam_ocr_dir, nec_data
from bank_overrides import apply_overrides
from exam_parser import read_key, read_questions
from exam_sources import discover, record_id
from state_law_source import load_all as load_state_law

ROOT = Path(__file__).resolve().parents[2]
OCR = exam_ocr_dir()
KEYS = answer_key_ocr_dir()
OUT = Path(os.environ.get("WIRE_BANK_OUT", str(ROOT / "data" / "question_bank.json")))
if OUT.resolve() == (ROOT / "data" / "question_bank.json").resolve():
    raise SystemExit("Refusing to write over the curated bank; set WIRE_BANK_OUT to a candidate file.")

EXAMS = discover()
QUESTION_COUNTS = {exam.label: exam.question_count(OCR) for exam in EXAMS}

KEYWORD_TERMS = [
	("ground fault", "ground fault"),
	("ground-fault", "ground fault"),
	("normally non-current-carrying", "normally non-current-carrying"),
	("snap switches", "rating and use of snap switches"),
	("inductive loads", "inductive loads"),
	("inductive load", "inductive loads"),
	("applied voltage", "applied voltage"),
	("ampere rating", "switch ampere rating"),
    ("grounding electrode", "grounding electrode"),
    ("grounding conductor", "equipment grounding conductor"),
    ("grounded conductor", "grounded conductor"),
    ("bonding", "bonding"),
    ("GFCI", "ground-fault circuit-interrupter"),
    ("AFCI", "arc-fault circuit-interrupter"),
    ("branch circuit", "branch circuit"),
    ("feeder", "feeder"),
    ("service equipment", "service equipment"),
    ("receptacle", "receptacle outlet"),
    ("ampacity", "ampacity"),
    ("voltage drop", "voltage drop"),
    ("overcurrent", "overcurrent protection"),
    ("conduit", "conduit"),
    ("raceway", "raceway"),
    ("cable", "cable"),
    ("conductors", "conductors"),
    ("motor", "motor"),
    ("transformer", "transformer"),
    ("pool", "pool / spa"),
    ("mobile home", "mobile home"),
    ("dwelling", "dwelling unit"),
    ("load calculation", "load calculation"),
    ("load", "load calculation"),
    ("disconnect", "disconnecting means"),
    ("box", "box / enclosure"),
    ("hazardous", "hazardous location"),
    ("temporary", "temporary wiring"),
]

def extract_lookup(prompt, answers, article):
    text = (prompt + " " + " ".join(answers)).lower()
    terms = []
    for needle, label in KEYWORD_TERMS:
        if needle.lower() in text and label not in terms:
            terms.append(label)
    if not terms:
        terms.append("identify the equipment, location, and requirement")
    terms = terms[:4]
    summary = "Lookup clues: %s. Start with %s, then read the matching subsection and exceptions." % (", ".join(terms), article)
    return terms, summary

SUBJECT_LABELS = [
    ("mc cable", "Type MC cable"), ("nm cable", "NM cable"),
    ("uf cable", "Type UF cable"), ("se cable", "Type SE cable"),
    ("mi cable", "MI cable"), ("ac cable", "Type AC cable"),
    ("receptacle", "receptacle"), ("outlet", "outlet"),
    ("luminaire", "luminaire"), ("spas", "spa"), ("hot tub", "hot tub"),
    ("swimming pool", "pool"), ("pool", "pool"),
    ("motor", "motor"), ("transformer", "transformer"),
    ("switchboard", "switchboard"), ("switchgear", "switchgear"),
    ("panelboard", "panelboard"), ("busway", "busway"),
    ("conduit", "conduit"), ("raceway", "raceway"),
    ("cable tray", "cable tray"), ("antenna", "antenna"),
    ("welder", "welder"), ("elevator", "elevator"),
    ("dwelling", "dwelling unit"), ("garage", "garage"),
    ("balcon", "balcony/deck/porch"), ("deck", "balcony/deck/porch"),
    ("porch", "balcony/deck/porch"), ("hallway", "hallway"),
    ("kitchen", "kitchen"), ("bathroom", "bathroom"),
    ("crawl space", "crawl space"),
    ("disconnecting means", "disconnecting means"),
    ("overload", "overload protection"),
    ("grounding electrode", "grounding electrode"),
    ("bonding jumper", "bonding jumper"),
    ("service equipment", "service equipment"),
    ("feeder", "feeder"), ("branch circuit", "branch circuit"),
    ("holiday lighting", "holiday lighting"),
    ("fire pump", "fire pump"),
]

def find_subject(text):
    for needle, label in SUBJECT_LABELS:
        if needle in text:
            return label
    return ""

def find_measures(text):
    found = re.findall(
        r"\d[\d,]*(?:\.\d+)?\s*(?:ft|feet|inch|inches|\"|'|"
        r"volts?|amps?|amperes?|watts?|kva|va\b|hp|%|percent|"
        r"sq\.?\s*ft|degrees?\s*[cf])",
        text,
    )
    seen = []
    for item in found:
        item = re.sub(r"\s+", " ", item).strip()
        if item not in seen:
            seen.append(item)
    return seen[:3]

CONCEPT_NOTES = {
    "isolated_ground": (
        "An isolated ground receptacle is a special outlet for sensitive electronics "
        "(computers, lab gear, medical equipment). Its ground terminal is insulated from "
        "the metal outlet box, with a separate insulated ground wire running back to the "
        "service panel — this keeps electrical noise from other circuits out of the equipment. "
        "You can spot one by the orange triangle on its face."
    ),
    "receptacle_rules": (
        "The NEC decides where every receptacle must go so nobody needs an extension cord: "
        "no point along a living-room or bedroom wall may be more than 6 ft from an outlet, "
        "hallways 10 ft or longer need one, balconies and decks need one within reach, "
        "and laundry areas need a dedicated 20-amp circuit. Bathrooms, kitchens, garages, "
        "and outdoor spots add GFCI protection, and wet spots need weather-resistant types."
    ),
    "cable_types": (
        "Decode the letters first: MI = Mineral-Insulated (wires in white mineral powder inside a copper "
        "tube — fireproof, for hazardous and harsh spots). MC = Metal-Clad (metal armor, goes almost "
        "anywhere). NM = Nonmetallic-sheathed, Romex (dry homes only). UF = Underground Feeder (burial "
        "and wet spots). SE = Service-Entrance (brings power in). AC = Armored Cable/BX (grounds through "
        "its armor plus a bonding strip, needs a red anti-short bushing). USE stays buried outside and "
        "may not come indoors."
    ),
    "grounding_basics": (
        "Three jobs, three parts. Grounding connects the system to the earth (rods, plates, "
        "concrete-encased electrodes) to drain lightning and surges. Bonding joins all the metal "
        "parts together so fault current has a fast low-resistance road back to the source that "
        "trips the breaker. The grounded conductor (neutral, white) carries normal current; "
        "the grounding conductor (green/bare) carries only fault current. "
        "The main bonding jumper is where neutral and ground meet — at the service, and only there."
    ),
    "raceway_rules": (
        "Decode the letters first: EMT = Electrical Metallic Tubing (thin-wall, hand-bendable). "
        "RMC = Rigid Metal Conduit (thick threaded steel). IMC = Intermediate (in between). "
        "FMC = Flexible Metal Conduit (bendable whip). ENT = Electrical Nonmetallic Tubing (blue smurf tube). "
        "LFMC = Liquidtight Flexible Metal (sealed whip). RNC = Rigid Nonmetallic Conduit (PVC). "
        "Rules answer three things: clearance from wood framing (1-1/4 in. or a nail plate), burial depth, "
        "and strapping (within a foot of every box, then every few feet by type)."
    ),
    "outside_clearances": (
        "Article 225 covers outside branch circuits and feeders. For a final span at a building, distinguish "
        "the clearance from doors and similar locations from the separate restriction on material-handling openings."
    ),
    "conduit_fill_table": (
        "Read Table 348.22 by first finding the conductor insulation group, then the AWG row, and finally "
        "the column for fittings inside or outside the conduit. A dash means that combination is not listed. "
        "For this question, use the TFN/THHN/THWN group."
    ),
    "gfci_basics": (
        "A GFCI watches the current going out and coming back on a circuit. If even a tiny amount "
        "leaks — say, through a person to ground — it trips in a fraction of a second. That is why "
        "the NEC demands GFCI protection anywhere water and electricity can meet: bathrooms, kitchens, "
        "garages, outdoors, crawl spaces, laundry areas, pools, and spas."
    ),
    "afci_basics": (
        "An AFCI listens for the electrical signature of dangerous arcing — damaged wires sparking "
        "inside walls — and shuts the circuit down before it can start a fire. The NEC requires "
        "combination-type AFCI protection on the kitchens, living rooms, bedrooms, dens, laundry, "
        "hallways, closets, and similar room circuits in dwelling units (210.12(B) lists them all)."
    ),
    "motor_basics": (
        "A motor circuit has two separate protections doing two jobs. The overload device (heaters, "
        "overload relay) guards against a motor slowly cooking from too much load — sized from the "
        "motor's own nameplate amps (125% for sturdy motors, 115% for the rest), with one overload unit "
        "per phase (three units on a three-phase motor). The breaker or fuses handle violent short "
        "circuits and ground faults. The controller starts and stops the motor; the disconnect "
        "within sight of the motor lets a worker be sure it cannot restart while hands are on it."
    ),
    "load_calc_basics": (
        "Load calculations never just add everything up, because a home never runs all loads at once. "
        "Start with 3 VA per square foot of living space (outside dimensions, minus open porches and unfinished spaces), "
        "add 1,500 VA for each small-appliance and laundry circuit, then shrink the subtotal with the "
        "demand factor (first 3,000 VA at full value, 3,001 to 120,000 VA at 35%, the remainder at 25%). Ranges and dryers use their own "
        "tables — a range nameplate is only the starting point. Heat and AC: count the larger one, never both."
    ),
    "disconnect_basics": (
        "A disconnecting means is simply the switch or breaker a worker opens before touching equipment. "
        "The golden rule is 'within sight': visible and no more than 50 ft away, so nobody can re-energize "
        "it unseen. Motors need a disconnect in sight of both the controller and the motor itself; "
        "appliances and AC units need one in sight and quickly reachable. If the disconnect must live far "
        "away, it has to be lockable open with the location marked on the equipment."
    ),
    "working_space": (
        "Working space is the empty bubble an electrician stands in while servicing live gear — "
        "nobody may store boxes or park equipment in it. The NEC measures it three ways: depth in front "
        "(3+ ft depending on voltage and what faces the gear — concrete or brick walls facing you mean "
        "deeper space), 30 in. minimum width (or the equipment's width), and 6-1/2 ft of headroom. "
        "Big gear needs doors that swing 90° and a way out that open doors can't block. Above panels, "
        "the space up to the ceiling belongs to electrics only — no pipes or ducts."
    ),
    "hazloc": (
        "Hazardous locations are sorted by what's in the air. Class I means flammable gases or vapors "
        "(gasoline, spray booths). Class II means combustible dust (grain, flour, coal). "
        "Class III means ignitable fibers or flyings (textiles, wood shops, cotton). "
        "Division 1 means the hazard is there during normal work; Division 2 means only if something "
        "goes wrong. Memory hook: Gas, Dust, Fibers = I, II, III — and normal vs abnormal = Division 1 vs 2."
    ),
    "flex_cords": (
        "Flexible cords are temporary wiring, not a substitute for fixed circuits — they must stay "
        "continuous (no splices except repairing hard-service cord), stay short, and match the job's "
        "toughness: junior hard-service (SJ) for light duty, hard-service (S, ST) for tools and appliances, "
        "extra-hard (SO) for construction sites. The letters are a code: O = oil-resistant, "
        "T = thermoplastic, W = weather/wet-location plus sunlight-resistant. "
        "A cord in a wet place outdoors needs that W — which is why STOOW is the answer there."
    ),
    "boxes_enclosures": (
        "Boxes are sized by volume, not vibes: every wire, clamp, and device yoke eats cubic inches, "
        "so a crowded box is a Code violation and a fire risk. Device boxes need minimum depth "
        "(a flush device needs room behind it), and unused breaker or knockout openings must be closed "
        "with listed fillers so fingers and sparks can't get in. Switchboards and panelboards add their own "
        "rules: conductors belong only in the section they terminate in, and rear-access gear must say so on the front."
    ),
    "round_boxes": (
        "This is the round-box exception in Article 314: a round box cannot be used when a raceway or connector "
        "that needs a locknut or bushing connects to the side. For a false-statement question, compare each choice "
        "against the exact section named in its lookup path."
    ),
    "lighting_temp": (
        "Luminaires (fixtures) follow one idea: bulbs get hot and breakable, so guard them — temporary "
        "job-site lamps need a guard or proper holder, and holiday/decorative lighting must be listed. "
        "Fluorescent and LED fixtures with serviceable ballasts or drivers in commercial buildings need "
        "their own disconnect so relamping doesn't happen live. Outdoors, keep fixtures and their wiring "
        "away from power lines and support festoon spans so plants and weather can't damage them."
    ),
    "switch_basics": (
        "A switch is rated for what it interrupts. Ordinary snap switches handle lighting loads, but "
        "inductive loads like motors and ballasts punish contacts, so the NEC caps them at half the "
        "switch's ampere rating. A three-way switch is secretly a single-pole double-throw — one lever "
        "flipping power between two traveler paths, which is why two of them team up to control one light "
        "from two places."
    ),
    "transformer_service": (
        "Services and transformers are about size and labels. A one-family dwelling service from 100–400 A "
        "may use conductors at 83% of the rating (the diversity of a home makes full size unnecessary). "
        "Every transformer must wear a nameplate with its ratings — but not trivia like the wire gauge "
        "inside it. And transformers generally need a disconnect in sight, or lockable with its location "
        "marked on the unit."
    ),
    "branch_circuits": (
        "Branch circuits are rated by their breaker: the standard sizes are 10, 15, 20, 30, 40, and 50 amps. "
        "A multiwire (shared-neutral) circuit must open all its ungrounded legs together so no leg can stay "
        "live alone. And the number of circuits in a building comes from the total load divided by circuit "
        "size — fractional results always round up, because half a circuit doesn't exist."
    ),
    "appliance_basics": (
        "Appliances play by cord-and-plug rules: a kitchen disposer may use a short flexible cord "
        "(18 in. to 3 ft) instead of hard wiring, and a room air conditioner gets a short cord matched to "
        "its voltage (about 10 ft at 120 V, 6 ft at 240 V). Big fixed appliances — ranges, dryers, water "
        "heaters — skip simple nameplate math and use their own demand tables, and laundry always gets "
        "its own dedicated 20-amp circuit."
    ),
    "connections": (
        "Every splice and terminal must stay tight for decades: torque screws to spec (a loose aluminum "
        "terminal starts fires), use pressure connectors only within their listed ampacity, and house all "
        "splices in boxes with insulation as good as the wire itself. One iron rule: a ground fault must "
        "never be able to start a motor or sneak around a stop button — so switching always goes in the "
        "ungrounded leg."
    ),
    "safety_basics": (
        "You cannot see electricity, so safety is a procedure, not a sense. Plan every job: identify all "
        "energy sources, lock and tag them open, verify zero voltage with a meter, and use insulated tools "
        "on anything that might be live. Treat pools, heaters, old panels, and anything unfamiliar as "
        "energized until your meter proves otherwise."
    ),
    "nec_vocab": (
        "Some questions test NEC vocabulary rather than math. Picture the thing described and match the word: "
        "a busbar is the bare metal bar that distributes power inside gear; 'datum' or maximum water level "
        "is where water would spill over. When asked which article a definition belongs to, remember Article 100 "
        "holds the definitions used throughout the whole Code."
    ),
    "special_systems": (
        "Beyond ordinary wire-in-conduit, the NEC gives each special system its own article: flat FCC/FC cables "
        "glued under carpet squares, busways and cablebus feeding big loads, wireways and auxiliary gutters as "
        "roomy sheet-metal raceways (mind the spacing between live parts), and surface extensions for remodels. "
        "Questions on these almost always ask where the system is allowed, how it attaches, or what it must be marked."
    ),
    "lowvoltage_basics": (
        "Low-voltage and power-limited circuits (thermostats, doorbells, fire alarms, Class 1 control wiring) get "
        "easier rules because a fault can't deliver much energy — but they must stay separated from power wiring "
        "so a fault can't cross over. Class 1 power-limited sources are capped (around 30 V and 1,000 VA) precisely "
        "so that even a dead short stays small."
    ),
    "antenna_basics": (
        "Antennas must fail without touching power lines: masts are corrosion-proof metal strong enough for ice "
        "and wind, guyed where needed, and stood well clear of any overhead conductors above 150 volts to ground. "
        "Lead-in wires get their own clearances, and the whole installation needs lightning protection — "
        "a rooftop mast is often the tallest thing around."
    ),
    "emergency_basics": (
        "Emergency systems must work when normal power doesn't: fire-pump controllers and parts sit high and dry "
        "above floors, the emergency source gets marked at the service entrance, and emergency wiring stays "
        "independent so one fault can't kill both normal and backup power."
    ),
    "sign_basics": (
        "An electric sign is a utilization equipment with a structure: its body, supports, and wiring must handle "
        "weather and weight, wood enclosures are allowed only well clear of hot lampholders, and signs need a "
        "disconnect so service people can kill them without hunting for a breaker."
    ),
    "elevator_basics": (
        "Elevator and dumbwaiter motors live an intermittent life — short hard runs, long rests — so the Code "
        "sizes their conductors and protection by duty rating instead of continuous-duty rules. "
        "Their machine rooms and controllers get the same disconnect-within-sight treatment as any motor."
    ),
    "xray_basics": (
        "X-ray units gulp enormous current for fractions of a second, so their big feeders are sized to momentary "
        "versus long-time demand — but the tiny control wires are a different story: fixture wire and flexible "
        "cords on control circuits still get overcurrent protection matched to their small size."
    ),
    "overcurrent_basics": (
        "Overcurrent protection works in layers. The branch breaker or fuse handles violent short circuits "
        "and ground faults and must carry the motor's starting surge without tripping. Delicate internals — "
        "luminaire ballasts, appliance circuits, control wiring — get smaller supplementary protectors, but "
        "those never replace branch-circuit protection. Where staying online matters, selective coordination "
        "stages the devices so only the faulted circuit goes dark."
    ),
    "drawings_basics": (
        "Electrical drawings read like a book: start at the upper left, check the title block, "
        "use the scale to convert drawing inches to real feet, and learn the symbol legend — "
        "every device on the plan is a symbol, not a picture."
    ),
    "listing_basics": (
        "'Listed' means an independent lab tested it for one specific purpose — use it only that way and follow "
        "its instructions, because the instructions are part of the listing. Novelty and special equipment "
        "(USB cover plates with night lights, holiday lighting) must be listed, and required markings must be "
        "durable and visible where the inspector and the user will actually see them."
    ),
    "electrical_theory": (
        "Three formulas run the math questions. Ohm's law: volts = amps × ohms. "
        "Power: watts = volts × amps (so amps = watts ÷ volts). "
        "Two equal resistors in parallel give half of one (two 2,000-ohm resistors = 1,000 ohms). "
        "Voltage drop percent is volts lost ÷ source volts. And AC frequency: 60 cycles per second means "
        "one full 360° wave takes 1/60 s, so 90° takes a quarter of that — 1/240 s. "
        "To turn a percent into a fraction, write it over 100 and reduce."
    ),
    "pool_basics": (
        "Water plus electricity is why pools get the strictest rules in the book. Everything metal near "
        "the water — shell, ladder, pump, conduit — gets bonded together into one equal-voltage grid so no "
        "stray voltage can exist between touchable parts. Receptacles, lights, and fans near the water need "
        "GFCI protection, and fixtures above the water must stay high (about 7-1/2 ft with GFCI, 12 ft without) "
        "so nobody can touch them from the water."
    ),
}

CONCEPT_SHORT = {
    "isolated_ground": ("Isolated-ground receptacle", "An isolated-ground outlet runs its ground wire separately back to the panel to keep electrical noise away from sensitive electronics — look for the orange triangle."),
    "receptacle_rules": ("Receptacle placement", "The NEC puts outlets where people need them so cords never stretch across rooms."),
    "cable_types": ("Cable types", "MI = Mineral-Insulated, MC = Metal-Clad, NM = Nonmetallic-sheathed, UF = Underground Feeder, SE = Service-Entrance, AC = Armored Cable."),
    "grounding_basics": ("Grounding vs bonding", "Grounding connects the electrical system to earth; bonding connects metal parts so fault current opens the overcurrent device quickly."),
    "raceway_rules": ("Conduit and raceways", "EMT = thin-wall tubing, RMC = rigid steel, IMC = intermediate, FMC = Flexible Metal Conduit, ENT = plastic tubing, RNC = PVC."),
    "outside_clearances": ("Outside conductor clearances", "Article 225 sets one clearance rule for doors and similar locations and a separate restriction for material-handling openings."),
    "conduit_fill_table": ("Conduit fill table", "Find the TFN/THHN/THWN group, read the AWG row, and check the inside/outside fitting column. A dash means that combination is not listed."),
    "gfci_basics": ("GFCI protection", "A GFCI trips when current leaks — through water or a person."),
    "afci_basics": ("AFCI protection", "An AFCI detects arc faults in wiring and opens the circuit before ignition."),
    "motor_basics": ("Motor circuits", "Motors require overload protection sized from nameplate current, separate from short-circuit and ground-fault protection."),
    "load_calc_basics": ("Load calculations", "Start from the Code's unit value for the occupancy, then apply only the demand the question allows — and skip factors it tells you to disregard."),
    "disconnect_basics": ("Disconnecting means", "Every major equipment needs a lockable disconnect within sight — match the question to the right rule (motor, service, or appliance)."),
    "pool_basics": ("Pools and spas", "Pool and spa areas require bonding of metal parts and ground-fault protection of electrical equipment."),
    "working_space": ("Working space", "Working space requires minimum depth in front, 30 inches of width, 6-1/2 feet of headroom, and an exit path."),
    "hazloc": ("Hazardous locations", "Gas = Class I, dust = Class II, fibers = Class III; normal conditions = Division 1, abnormal = Division 2."),
    "flex_cords": ("Flexible cords", "Flexible cords are for temporary use: short runs, continuous length, matched to the load and environment (SJ light-duty, ST heavy-duty, W weather-rated)."),
    "electrical_theory": ("Electrical math", "Translate the units, pick the one relationship the question tests, and calculate before selecting."),
    "boxes_enclosures": ("Boxes and enclosures", "Enclosure size is determined by conductor volume; equipment is restricted to its own section."),
    "round_boxes": ("Round boxes • Article 314.2", "Article 314.2 prohibits round boxes where a side entry needs a locknut or bushing. Check the word NOT carefully when comparing the choices."),
    "lighting_temp": ("Lighting", "Luminaires generate heat and use breakable parts, so the Code requires guards and listing of decorative lighting."),
    "switch_basics": ("Switches", "Switches are rated by what they interrupt — inductive loads get only half the rating."),
    "transformer_service": ("Services and transformers", "Dwelling services may count only part of the load; transformers wear nameplates and need visible disconnects."),
    "branch_circuits": ("Branch circuits", "A circuit takes its rating from its fuse or breaker — match the load to the right circuit type and size."),
    "appliance_basics": ("Appliances", "Appliances use short cords, dedicated circuits, and demand tables instead of nameplate math."),
    "connections": ("Connections", "Terminations must be torqued, connectors listed, and splices enclosed."),
    "safety_basics": ("Electrical safety", "You can't see electricity — plan, lock out, verify dead, use insulated tools."),
    "nec_vocab": ("NEC vocabulary", "Article 100 definitions are exact: match every word of the description to the term."),
    "special_systems": ("Special systems", "Flat cables, busways, wireways, and gutters each have their own article."),
    "lowvoltage_basics": ("Low-voltage circuits", "Small energy, easier rules — but still separated from power wiring."),
    "antenna_basics": ("Antennas", "Antenna masts must withstand weather and fall clear of power conductors."),
    "emergency_basics": ("Emergency systems", "Backup power must work when normal power fails and stay independent of it."),
    "sign_basics": ("Electric signs", "Signs need sound structure, clearances from heat, and a disconnect."),
    "elevator_basics": ("Elevators", "Elevator motors work intermittently, so sizing follows duty ratings."),
    "xray_basics": ("X-ray equipment", "X-ray equipment draws brief high-current pulses, so feeders follow momentary ratings while small-gauge control conductors keep low-rated protection."),
    "listing_basics": ("Listed equipment", "Listed means lab-tested for one purpose — use it only that way."),
    "drawings_basics": ("Reading drawings", "Start at the upper left, check scale and legend."),
    "overcurrent_basics": ("Overcurrent protection", "Branch overcurrent devices protect conductors; supplementary devices protect equipment internals only and cannot replace branch protection."),
}

CONCEPT_TRIGGERS = [
    ("round boxes", "round_boxes"),
    ("material-handling door", "outside_clearances"),
    ("material handling opening", "outside_clearances"),
    ("table 348.22", "conduit_fill_table"),
    ("largest conductor size listed for thhn", "conduit_fill_table"),
    ("isolated ground", "isolated_ground"),
    ("isolating equipment grounding", "isolated_ground"),
    ("safe work", "safety_basics"),
    ("hazard", "safety_basics"),
    ("live electrical", "safety_basics"),
    ("screwdriver", "safety_basics"),
    ("see an electrical", "safety_basics"),
    ("lockout/tagout", "safety_basics"),
    ("gfci", "gfci_basics"),
    ("ground-fault circuit", "gfci_basics"),
    ("ground fault", "gfci_basics"),
    ("arc-fault", "afci_basics"),
    ("arc fault", "afci_basics"),
    ("grounding electrode", "grounding_basics"),
    ("bonding jumper", "grounding_basics"),
    ("grounding conductor", "grounding_basics"),
    ("grounded conductor", "grounding_basics"),
    ("ground rod", "grounding_basics"),
    ("main bonding", "grounding_basics"),
    ("electrode", "grounding_basics"),
    ("working space", "working_space"),
    ("dedicated space", "working_space"),
    ("egress", "working_space"),
    ("guarded", "working_space"),
    ("considered as being", "working_space"),
    ("hazardous", "hazloc"),
    ("class i", "hazloc"),
    ("fibers", "hazloc"),
    ("flyings", "hazloc"),
    ("division", "hazloc"),
    ("ignitible", "hazloc"),
    ("ignitable", "hazloc"),
    ("cord-and-plug", "flex_cords"),
    ("flexible cord", "flex_cords"),
    ("hard-service", "flex_cords"),
    ("hard service", "flex_cords"),
    ("extension cord", "flex_cords"),
    ("festoon", "flex_cords"),
    ("sunlight resistant", "flex_cords"),
    ("cord type", "flex_cords"),
    ("messenger", "flex_cords"),
    ("tinsel", "flex_cords"),
    ("identifying mark", "listing_basics"),
    ("symbol", "electrical_theory"),
    ("cable tray", "special_systems"),
    ("portable", "flex_cords"),
    ("fcc", "special_systems"),
    ("flat conductor", "special_systems"),
    ("busway", "special_systems"),
    ("cablebus", "special_systems"),
    ("wireway", "special_systems"),
    ("surface extension", "special_systems"),
    ("tap device", "special_systems"),
    ("copper bus", "special_systems"),
    ("bus bar", "special_systems"),
    ("gutter", "special_systems"),
    ("communicat", "special_systems"),
    ("catv", "special_systems"),
    ("antenna", "antenna_basics"),
    ("lead-in", "antenna_basics"),
    ("clearance", "raceway_rules"),
    ("overhead conductor", "raceway_rules"),
    ("rnc", "raceway_rules"),
    ("definition of", "nec_vocab"),
    ("is defined as", "nec_vocab"),
    ("is referred to as", "nec_vocab"),
    ("abbreviation", "nec_vocab"),
    ("highest level", "nec_vocab"),
    ("busbar", "nec_vocab"),
    (    "responsible for", "nec_vocab"),
    ("stated in article", "nec_vocab"),
    ("drawing", "drawings_basics"),
    ("nursing home", "nec_vocab"),
    ("supplementary", "overcurrent_basics"),
    ("overcurrent", "overcurrent_basics"),
    ("short-circuit", "overcurrent_basics"),
    ("short circuit", "overcurrent_basics"),
    ("selective", "overcurrent_basics"),
    ("localization", "overcurrent_basics"),
    ("multiconductor", "cable_types"),
    ("battery", "emergency_basics"),
    ("tested", "listing_basics"),
    ("initiated", "safety_basics"),
    ("e x i", "electrical_theory"),
    ("alpha", "electrical_theory"),
    ("ohm", "electrical_theory"),
    ("resist", "electrical_theory"),
    ("parallel", "electrical_theory"),
    ("frequency", "electrical_theory"),
    ("cycle", "electrical_theory"),
    ("voltage drop", "electrical_theory"),
    ("ammeter", "electrical_theory"),
    ("diagram", "electrical_theory"),
    ("drawing", "electrical_theory"),
    ("scale", "electrical_theory"),
    ("equivalent to", "electrical_theory"),
    ("percent", "electrical_theory"),
    ("fraction", "electrical_theory"),
    ("circuit current", "electrical_theory"),
    ("factory assembly", "cable_types"),
    ("tc cable", "cable_types"),
    ("nm cable", "cable_types"),
    ("uf cable", "cable_types"),
    ("mc cable", "cable_types"),
    ("se cable", "cable_types"),
    ("mi cable", "cable_types"),
    ("ac cable", "cable_types"),
    ("armored cable", "cable_types"),
    ("metal-clad", "cable_types"),
    ("nonmetallic-sheathed", "cable_types"),
    ("service-entrance cable", "cable_types"),
    ("underground feeder", "cable_types"),
    ("pool", "pool_basics"),
    ("spa ", "pool_basics"),
    ("spas", "pool_basics"),
    ("hot tub", "pool_basics"),
    ("fountain", "pool_basics"),
    ("paddle fan", "pool_basics"),
    ("elevator", "elevator_basics"),
    ("dumbwaiter", "elevator_basics"),
    ("motor-generator", "elevator_basics"),
    ("driving machine", "elevator_basics"),
    ("overload", "motor_basics"),
    ("controller", "motor_basics"),
    ("three-phase motor", "motor_basics"),
    ("3-phase motor", "motor_basics"),
    ("motor starter", "motor_basics"),
    ("locked-rotor", "motor_basics"),
    ("motor", "motor_basics"),
    ("heated ceiling", "appliance_basics"),
    ("space heating", "appliance_basics"),
    ("air conditioner", "appliance_basics"),
    ("waste disposer", "appliance_basics"),
    ("in-sink", "appliance_basics"),
    ("supply cord", "appliance_basics"),
    ("laundry equipment", "appliance_basics"),
    ("range installed", "appliance_basics"),
    ("demand factor", "load_calc_basics"),
    ("demand load", "load_calc_basics"),
    ("lighting load", "load_calc_basics"),
    ("calculated load", "load_calc_basics"),
    ("multioutlet assembly", "load_calc_basics"),
    ("service and feeder", "load_calc_basics"),
    ("feeder demand", "load_calc_basics"),
    ("floor area", "load_calc_basics"),
    ("square footage", "load_calc_basics"),
    ("rounded", "load_calc_basics"),
    ("nearest whole", "load_calc_basics"),
    ("branch circuit", "branch_circuits"),
    ("multiwire", "branch_circuits"),
    ("disconnecting means", "disconnect_basics"),
    ("disconnect", "disconnect_basics"),
    ("in sight", "disconnect_basics"),
    ("readily accessible", "disconnect_basics"),
    ("lockout", "disconnect_basics"),
    ("fire pump", "emergency_basics"),
    ("emergency power", "emergency_basics"),
    ("emergency source", "emergency_basics"),
    ("generator", "emergency_basics"),
    ("low-voltage", "lowvoltage_basics"),
    ("low voltage", "lowvoltage_basics"),
    ("class 1", "lowvoltage_basics"),
    ("power-limited", "lowvoltage_basics"),
    ("isolating type", "lowvoltage_basics"),
    ("antenna", "antenna_basics"),
    ("lead-in", "antenna_basics"),
    ("sign body", "sign_basics"),
    ("sign enclosure", "sign_basics"),
    ("sign shall", "sign_basics"),
    ("x-ray", "xray_basics"),
    ("pressure connector", "connections"),
    ("torque", "connections"),
    ("terminal housing", "connections"),
    ("splice", "connections"),
    ("shall be listed", "listing_basics"),
    ("must be listed", "listing_basics"),
    ("marked", "listing_basics"),
    ("switchboard", "boxes_enclosures"),
    ("switchgear", "boxes_enclosures"),
    ("panelboard", "boxes_enclosures"),
    (" box", "boxes_enclosures"),
    ("enclosure", "boxes_enclosures"),
    ("cabinet", "boxes_enclosures"),
    ("conduit body", "boxes_enclosures"),
    ("flush device", "boxes_enclosures"),
    ("unused opening", "boxes_enclosures"),
    ("luminaire", "lighting_temp"),
    ("lamp", "lighting_temp"),
    ("ballast", "lighting_temp"),
    ("holiday lighting", "lighting_temp"),
    ("festoon", "lighting_temp"),
    ("temporary", "lighting_temp"),
    ("decorative lighting", "lighting_temp"),
    ("switch", "switch_basics"),
    ("snap switch", "switch_basics"),
    ("three-way", "switch_basics"),
    ("stop switch", "switch_basics"),
    ("transformer", "transformer_service"),
    ("nameplate", "transformer_service"),
    ("service rated", "transformer_service"),
    ("service conductor", "transformer_service"),
    ("feeder", "transformer_service"),
    ("electrified truck", "transformer_service"),
    ("rv feeder", "transformer_service"),
    ("receptacle", "receptacle_rules"),
    ("outlet", "receptacle_rules"),
    ("raceway", "raceway_rules"),
    ("conduit", "raceway_rules"),
    ("emt", "raceway_rules"),
    ("rmc", "raceway_rules"),
    ("imc", "raceway_rules"),
    ("fmc", "raceway_rules"),
    ("pvc", "raceway_rules"),
    (" ent ", "raceway_rules"),
    ("direct-buried", "raceway_rules"),
    ("burial", "raceway_rules"),
    ("trench", "raceway_rules"),
    ("underground", "raceway_rules"),
    ("fastened", "raceway_rules"),
    ("secured", "raceway_rules"),
    ("support", "raceway_rules"),
]

ARTICLE_CONCEPTS = [
    ("225", "outside_clearances"),
    ("400", "flex_cords"),
    ("430", "motor_basics"),
    ("220", "load_calc_basics"),
    ("250", "grounding_basics"),
    ("680", "pool_basics"),
    ("500", "hazloc"),
    ("503", "hazloc"),
    ("110", "working_space"),
    ("314", "boxes_enclosures"),
    ("404", "switch_basics"),
    ("408", "boxes_enclosures"),
    ("406", "receptacle_rules"),
    ("210", "receptacle_rules"),
    ("310", "load_calc_basics"),
]

def concept_key_for(text, article=""):
    scrubbed = text.replace("ungrounded", "##")
    for needle, key in CONCEPT_TRIGGERS:
        haystack = scrubbed if key == "grounding_basics" else text
        if needle in haystack:
            return key
    match = re.search(r"\b(\d{3})\b", article)
    if match:
        for prefix, key in ARTICLE_CONCEPTS:
            if match.group(1).startswith(prefix):
                return key
    return ""

TIP_LETTERS = ["A", "B", "C", "D"]

def _tip_note_ok(note, choice):
    s = str(note or "").strip()
    if len(s) < 25:
        return ""
    if s.lower() in str(choice or "").lower() or str(choice or "").lower() in s.lower():
        return ""
    return s if s.endswith(".") else s + "."

def concept_tip_short(concept_key, choices, correct_index):
    # Principle + per-record verdict, mirroring the retired fix_memory_tips.py so rebuilds
    # stay answer-aligned: "Correct: <L> — <answer>." plus substantive choice notes.
    principle = CONCEPT_SHORT.get(concept_key, ("In plain language", ""))[1]
    if not isinstance(choices, list) or correct_index < 0 or correct_index >= len(choices):
        return principle
    notes = choice_notes_for(choices)
    answer = str(choices[correct_index])
    letter = TIP_LETTERS[correct_index] if correct_index < len(TIP_LETTERS) else str(correct_index + 1)
    tip = principle.rstrip()
    if tip and not tip.endswith("."):
        tip += "."
    tip += " Correct: %s — %s." % (letter, answer)
    if correct_index < len(notes):
        note = _tip_note_ok(notes[correct_index], answer)
        if note:
            tip += " " + note
    for i, choice in enumerate(choices):
        if i == correct_index or i >= len(notes):
            continue
        note = _tip_note_ok(notes[i], choice)
        if note:
            tag = TIP_LETTERS[i] if i < len(TIP_LETTERS) else str(i + 1)
            tip += " Not %s: %s" % (tag, note)
    return tip

def concept_note(text, article=""):
    key = concept_key_for(text, article)
    return CONCEPT_NOTES[key] if key else ""

def explain_question(prompt, keywords, article=""):
    text = prompt.lower()
    note = concept_note(text, article)
    subject = find_subject(text)
    measures = find_measures(text)
    detail = ""
    if subject:
        detail = " Subject: %s." % subject
    if measures:
        detail += " Numbers in the question: %s." % ", ".join(measures)
    if "unsupported" in text or "unsecured" in text:
        if "mc cable" in text and ("luminaire" in text or "fixture" in text):
            meaning = "This asks for the maximum length of Type MC cable that may hang unsupported near a luminaire. Look for the cable-support rule and identify the distance limit."
        else:
            meaning = ("This asks for the longest run allowed before the wiring must be supported or secured.%s "
                       "You are looking for a distance limit, so compare each answer choice against that maximum." % detail)
    elif "minimum number" in text or "maximum number" in text:
        meaning = ("This asks for a required count.%s "
                   "Decide what is being counted and whether the rule sets a floor or a ceiling, then pick the matching number." % detail)
    elif "more than" in text or "less than" in text or "at least" in text or "minimum" in text or "maximum" in text or "minimum" in text:
        limit = "maximum" if ("more than" in text or "maximum" in text) else "minimum"
        meaning = ("This is a %s-limit question.%s "
                   "The correct choice is the %s value the NEC allows — "
                   "eliminate any choice on the wrong side of that limit." % (limit, detail, limit))
    elif "ampacity" in text:
        meaning = ("This asks how many amps the conductor may safely carry under the stated conditions.%s "
                   "Apply temperature and adjustment factors first, then read the resulting ampacity." % detail)
    elif "voltage drop" in text:
        meaning = ("This asks what percentage of voltage is lost between source and load.%s "
                   "Divide the volts lost by the source volts." % detail)
    elif "load" in text and ("calculation" in text or "calculated" in text):
        meaning = ("This is a load-calculation question.%s "
                   "Find the unit load for the occupancy, multiply by the area or quantity, "
                   "and apply any demand factor the question allows." % detail)
    elif "ground fault" in text or "grounding" in text or "bonding" in text:
        meaning = ("This asks you to name the grounding or bonding part in this installation.%s "
                   "Trace the fault-current path: what connects the equipment back to the source?" % detail)
    elif "gfc" in text or "arc-fault" in text:
        device = "GFCI" if "gfc" in text else "AFCI"
        meaning = ("This asks where %s protection is required.%s "
                   "Match the location and equipment in the question to the list of places the NEC names." % (device, detail))
    elif "receptacle" in text or "outlet" in text:
        meaning = ("This asks for the receptacle rule in this spot.%s "
                   "Decide whether the question wants a location, a height, a count, or a protection requirement, "
                   "then match that to the rule." % detail)
    elif "motor" in text or "transformer" in text:
        meaning = ("This asks you to match this motor or transformer setup to its rule.%s "
                   "Identify whether the question is about protection size, conductor size, disconnect location, or marking." % detail)
    elif "cable" in text or "conduit" in text or "raceway" in text:
        meaning = ("This asks which wiring-method rule fits this installation.%s "
                   "Focus on whether the question is about support spacing, fill, burial cover, protection from damage, "
                   "or where the method is permitted." % detail)
    elif "mark" in text:
        meaning = ("This asks about a required marking or label.%s "
                   "Decide what must be marked, where the marking goes, and what it must say — "
                   "the answer is the location or wording the NEC specifies." % detail)
    elif "equivalent to" in text or ("%" in text and "circuit" not in text and "amp" not in text):
        meaning = ("This is a straight math conversion — no NEC lookup needed.%s "
                   "Convert the given value and match it to the equal choice." % detail)
    elif "disconnect" in text or "disconnecting means" in text:
        meaning = ("This asks about the disconnect for this equipment.%s "
                   "Decide whether the question wants its location, its height, its rating, or who may access it." % detail)
    elif "switch" in text:
        meaning = ("This asks which switch rule fits.%s "
                   "Check whether the question is about the ampere rating, the type of load, "
                   "or where and how the switch is installed." % detail)
    elif "listed" in text or "listing" in text:
        meaning = ("This asks what listing or marking the NEC demands here.%s "
                   "Look for the condition — location, use, or construction — that triggers the listing rule." % detail)
    elif "is defined as" in text or "is referred to as" in text or "is recognized as" in text:
        meaning = ("This asks for the NEC term that matches the description.%s "
                   "Read each choice as a vocabulary answer and pick the term the description defines." % detail)
    elif "color" in text:
        meaning = ("This asks which conductor color the NEC allows here.%s "
                   "Recall which colors are reserved (grounded, grounding) and which remain for ungrounded conductors." % detail)
    elif "which of the following" in text:
        meaning = ("Read the situation, then test each choice against it.%s "
                   "Eliminate choices that contradict the stated conditions; the survivor that fits all of them is the answer." % detail)
    else:
        short = prompt.strip()
        if len(short) > 140:
            short = short[:140].rsplit(" ", 1)[0] + "…"
        meaning = ("In plain terms, the question is: \"%s\"%s "
                   "Break it into pieces — what equipment, what location or measurement, "
                   "and what the NEC must say about it — then find the choice that satisfies every piece." % (short, detail))
    if note:
        meaning = "PLAIN-LANGUAGE BACKGROUND\n%s\n\n%s" % (note, meaning)
    return "WHAT THIS QUESTION MEANS\n%s\n\nLOOKUP FOCUS\n%s" % (meaning, ", ".join(keywords))


def _stem_paragraph(info_tip):
    """(index, prefix) of the paragraph of an explain_question() tip that restates the stem."""
    parts = info_tip.split("\n\n")
    if len(parts) < 2 or not parts[-1].startswith("LOOKUP FOCUS\n"):
        return None, parts
    return len(parts) - 2, parts


def restate_stem(info_tip, prompt, keywords, article=""):
    """info_tip with its stem paragraph rebuilt from prompt; the background note is kept."""
    i, parts = _stem_paragraph(info_tip)
    j, fresh = _stem_paragraph(explain_question(prompt, keywords, article))
    if i is None or j is None:
        return info_tip
    head = "WHAT THIS QUESTION MEANS\n"
    old, new = parts[i], fresh[j].removeprefix(head)
    parts[i] = head + new if old.startswith(head) else new
    return "\n\n".join(parts)

MOTOR_CONTROLLER_TEXT = """430.8 Marking on Motor Controllers
A motor controller shall be marked with the manufacturer's name or identification, the voltage, the current or horsepower rating, the short-circuit current rating, and other necessary data to properly indicate the applications for which it is suitable. Exception No. 1: The short-circuit current rating is not required for motor controllers applied in accordance with 430.81(A) or (B). Exception No. 2: The short-circuit current rating is not required to be marked on the motor controller when the short-circuit current rating of the motor controller is marked elsewhere on the assembly. Exception No. 3: The short-circuit current rating is not required to be marked on the motor controller when the assembly into which it is installed has a marked short-circuit current rating. Exception No. 4: Short-circuit current ratings are not required for motor controllers rated less than 2 hp at 300 V or less and listed exclusively for general-purpose branch circuits. A motor controller that includes motor overload protection suitable for group motor application shall be marked with the motor overload protection and the maximum branch-circuit short-circuit and ground-fault protection for such applications. Combination motor controllers that employ adjustable instantaneous trip circuit breakers shall be clearly marked to indicate the ampere settings of the adjustable trip element. Where a motor controller is built in as an integral part of a motor or of a motor-generator set, individual marking of the motor controller shall not be required if the necessary data are on the nameplate. For motor controllers that are an integral part of equipment approved as a unit, the above marking shall be permitted on the equipment nameplate. Informational Note: See 110.10 for information on circuit impedance and other characteristics."""

REFERENCE_TEXTS = {
    "400.36": "400.36 Splices and Terminations\nPortable cables shall not contain splices unless the splices are of the permanent molded, vulcanized types in accordance with 110.14(B). Terminations on portable cables rated over 600 volts, nominal, shall be accessible only to authorized and qualified personnel.",
    "408.18(C)": "408.18 Clearances (C) Connections\nEach section of equipment that requires rear or side access to make field connections shall be so marked by the manufacturer on the front. Section openings requiring rear or side access shall comply with 110.26. Load terminals for field wiring shall comply with 408.18(C)(1), (C)(2), or (C)(3) as applicable.",
    "408.3(A)(2)": "408.3 Support and Arrangement of Busbars and Conductors (2) Same Vertical Section\nOther than the required interconnections and control wiring, only those conductors that are intended for termination in a vertical section of a switchboard or switchgear shall be located in that section. Exception: Conductors shall be permitted to travel horizontally through vertical sections of switchboards and switchgear where such conductors are isolated from busbars by a barrier.",
    "210.63(B)(1)": "210.63 Equipment Requiring Servicing (B) Other Electrical Equipment (1) Indoor Service Equipment\nThe required receptacle outlet shall be located within the same room or area as the service equipment.",
    "800.44(B)": "800.44(B) Above Roofs\nCommunications wires and cables and CATV-type coaxial cables shall have a vertical clearance of not less than 2.5 m (8 ft) from all points of roofs above which they pass.",
    "220.5(C)": "220.5(C) Floor Area\nThe floor area for each floor shall be calculated from the outside dimensions of the building, dwelling unit, or other area involved. For dwelling units, the calculated floor area shall not include open porches or unfinished areas not adaptable for future use as a habitable room or occupiable space.",
    "210.8(C)": "210.8(C) Crawl Space Lighting Outlets\nGFCI protection shall be provided for lighting outlets not exceeding 120 volts installed in crawl spaces.",
    "210.63": "210.63 Equipment Requiring Servicing\nA 125-volt, single-phase, 15- or 20-ampere-rated receptacle outlet shall be installed at an accessible location within 7.5 m (25 ft) of the equipment as specified in 210.63(A) and (B). Informational Note: See 210.8(E) for requirements on GFCI protection.",
    "210.52(E)(3)": "210.52(E)(3) Balconies, Decks, and Porches\nDecks within 102 mm (4 in.) sideways of the house need one outlet reachable from the deck. That outlet must be no more than 2.0 m (6 1/2 ft, which is 78 inches) above the walking surface.",
    "210.50(C)": "210.50(C) Appliance Receptacle Outlets\nAppliance receptacle outlets installed in a dwelling unit for specific appliances, such as laundry equipment, shall be installed within 1.8 m (6 ft) of the intended location of the appliance.",
    "210.18": "210.18 Rating\nBranch circuits shall be rated in accordance with the maximum permitted ampere rating or setting of the overcurrent device. The rating for other than individual branch circuits shall be 10, 15, 20, 30, 40, and 50 amperes.",
    "210.52(A)(2)(1)": "210.52(A)(2)(1) Wall Space\nOutlets go so no point along the floor line is more than 1.8 m (6 ft) from one. A wall stretch counts if it is 600 mm (2 ft, which is 24 inches) or wider, measured around corners.",
    "630.42(C)": "630.42(C) Signs\nA permanent sign shall be attached to the cable tray at intervals not greater than 6.0 m (20 ft). The sign shall read as follows: CABLE TRAY FOR WELDING CABLES ONLY",
    "110.16(A)": "110.16(A) General\nElectrical equipment, such as switchboards, switchgear, enclosed panelboards, industrial control panels, meter socket enclosures, and motor control centers, that is in other than dwelling units, and is likely to require examination, adjustment, servicing, or maintenance while energized, shall be field or factory marked to warn qualified persons of potential electric arc flash hazards. The marking shall meet the requirements in 110.21(B) and shall be located so as to be clearly visible to qualified persons before examination, adjustment, servicing, or maintenance of the equipment.",
    "300.4(D)": "300.4(D) Cables and Raceways Parallel to Framing Members and Furring Strips\nIn both exposed and concealed locations, where a cable- or raceway-type wiring method is installed parallel to framing members, such as joists, rafters, or studs, or is installed parallel to furring strips, the cable or raceway shall be installed and supported so that the nearest outside surface of the cable or raceway is not less than 32 mm (1 1/4 in.) from the nearest edge of the framing member or furring strips where nails or screws are likely to penetrate. Where this distance cannot be maintained, the cable or raceway shall be protected from penetration by nails or screws by a steel plate, sleeve, or equivalent at least 1.6 mm (1/16 in.) thick. Exception No. 1: Steel plates, sleeves, or the equivalent shall not be required to protect rigid metal conduit, intermediate metal conduit, rigid nonmetallic conduit, or electrical metallic tubing. Exception No. 2: For concealed work in finished buildings, or finished panels for prefabricated buildings where such supporting is impracticable, it shall be permissible to fish the cables between access points. Exception No. 3: A listed and marked steel plate less than 1.6 mm (1/16 in.) thick that provides equal or better protection against nail or screw penetration shall be permitted.",
    "312.5(C)": "312.5 Cabinets, Cutout Boxes, and Meter Socket Enclosures\nCable assemblies and insulated conductors entering enclosures within the scope of this article shall be protected from abrasion and shall comply with 312.5(A) through (C). (C) Cables\nWhere cable is used, each cable shall be secured to the cabinet, cutout box, or meter socket enclosure. Exception No. 1: Cables with entirely nonmetallic sheaths shall be permitted to enter the top of a surface-mounted enclosure through one or more nonflexible raceways not less than 450 mm (18 in.) and not more than 3.0 m (10 ft) in length, provided all of the following conditions are met: (1) Each cable is fastened within 300 mm (12 in.), measured along the sheath, of the outer end of the raceway. (2) The raceway extends directly above the enclosure and does not penetrate a structural ceiling. (3) A fitting is provided on each end of the raceway to protect the cable(s) from abrasion and the fittings remain accessible after installation. (4) The raceway is sealed or plugged at the outer end using approved means so as to prevent access to the enclosure through the raceway. (5) The cable sheath is continuous through the raceway and extends into the enclosure beyond the fitting not less than 6 mm (1/4 in.). (6) The raceway is fastened at its outer end and at other points in accordance with the applicable article. (7) Where installed as conduit or tubing, the cable fill does not exceed the amount that would be permitted for complete conduit or tubing systems by Table 1 of Chapter 9 of this Code and all applicable notes thereto. Note 2 to the tables in Chapter 9 does not apply to this condition. Informational Note: See Chapter 9, Table 1, including Note 9, for allowable cable fill in circular raceways. See 310.15(C)(1) for required ampacity reductions for multiple cables installed in a common raceway. Exception No. 2: Single conductors and multiconductor cables shall be permitted to enter enclosures in accordance with 392.46(A) or (B).",
    "Table 220.42(A)": "Table 220.42(A) Office lighting load\nOffice is 1.3 volt-amperes per square foot. For this exam item, 5,000 sq ft × 1.3 = 6,500 VA. Do not add another multiplier. The table note says the 125 percent continuous-load multiplier is already included.",
    "810.16(B)": "810.16(B) Self-Supporting Antennas\nOutdoor antennas, such as vertical rods and flat, parabolic, or dipole structures, shall be of corrosion-resistant materials and of strength suitable to withstand ice and wind loading conditions and shall be located well away from overhead conductors of electric light and power circuits of over 150 volts to ground, so as to avoid the possibility of the antenna or structure falling into or making accidental contact with such circuits.",
    "430.8": MOTOR_CONTROLLER_TEXT,
    "table 430.8": MOTOR_CONTROLLER_TEXT,
    "250.68(B)": "250.68(B) Effective Grounding Path\nThe connection of the grounding electrode conductor or bonding jumper shall be made in a manner that will ensure a permanent and effective grounding path. Where necessary to ensure effective grounding for a metal piping system used as a grounding electrode, effective bonding shall be provided around insulated joints and sections and around any equipment that is likely to be disconnected for repairs or replacement. Bonding jumpers shall be of sufficient length to permit removal of such equipment while retaining the integrity of the grounding path.",
    "406.9(B)": "406.9(B) Receptacles in Damp or Wet Locations\nReceptacles in damp locations shall be weatherproof enclosures or otherwise protected. 15- and 20-ampere, 125- and 250-volt receptacles installed in a wet location shall have an enclosure that is weatherproof whether or not the attachment plug cap is inserted. Outlet box hoods for this purpose shall be listed and identified as extra duty. 15- and 20-ampere, 125- and 250-volt nonlocking receptacles installed in wet locations shall be listed and so identified as the weather-resistant type.",
    "310.12(A)": "310.12(A) Single-Phase Dwelling Services\nFor a service rated 100 through 400 amperes, the service conductors supplying the entire load associated with a one-family dwelling, or the service conductors supplying the entire load associated with an individual dwelling unit in a two-family dwelling, shall have an ampacity of not less than 83 percent of the service rating.",
    "392.100(F)": "392.100(F) Nonmetallic Cable Tray\nCable trays of nonmetallic material shall be made of flame-retardant material.",
    "340.10": "340.10 Uses Permitted (Type UF)\nType UF cable shall be permitted for underground use including direct burial; for wiring in wet, dry, or corrosive locations; as nonmetallic-sheathed cable where the installation meets Article 334; as single-conductor cable with all circuit conductors grouped; and for solar photovoltaic systems. Type UF shall not be used as service-entrance cable.",
    "406.3(E)": "406.3(E) Isolated Ground Receptacles\nReceptacles with an isolated grounding terminal for the reduction of electrical noise shall be identified by an orange triangle marked on the face of the receptacle.",
    "422.16(B)(1)": "422.16(B)(1) Electrically Operated In-Sink Waste Disposers\nA disposer may be cord-and-plug connected only with a maker-approved cord, a protected and reachable outlet, and a ground wire with a grounded plug. The cord must be not less than 450 mm (18 in.) and not more than 900 mm (36 in.) long.",
    "590.5": "590.5 Listed (Temporary Decorative Lighting)\nDecorative lighting and similar accessories used for holiday lighting and similar purposes shall be listed and labeled.",
    "210.11(C)(2)": "210.11(C)(2) Laundry Branch Circuits\nAt least one additional 20-ampere branch circuit shall be provided to supply the laundry receptacle outlet(s). This circuit shall have no other outlets.",
    "210.52(G)(1)": "210.52(G) Basements, Garages, and Accessory Buildings\nAt least one receptacle outlet, besides any for specific equipment, shall be installed in each separate unfinished basement portion, in each vehicle bay of an attached garage, and in each vehicle bay of a detached garage or accessory building that has electric power.",
    "210.52(H)": "210.52(H) Hallways\nAt least one receptacle outlet shall be installed in each hallway 10 ft or more in length, measured along the centerline without passing through a doorway.",
    "220.14(4)": "220.14 Fixed Multioutlet Assemblies (Commercial, Not Simultaneous)\nEach 5 ft or fraction of continuous multioutlet assembly counts as one 180 VA outlet: 12 ft → three sections × 180 VA = 540 VA.",
    "Table 310.16": "Table 310.16 #12 THWN\nTHWN is the 75°C column. #12 copper is 25 A. At 86°F, Note 1 says no temperature correction. Four current-carrying conductors use the 80 percent adjustment. 25 × 0.80 = 20 A.",
    "225.6(B)": "225.6(B) Festoon Lighting Without a Messenger\nOverhead festoon conductors without a messenger: smallest permitted overhead conductor is #12 AWG.",
    "590.4(J)": "590.4(J) Holiday Trees as Supports\nTrees may support overhead holiday spans only with strain-relief or tension take-up devices protecting the wiring from live growth.",
    "620.61(B)(1)": "620.61(B)(1) Elevator Driving-Machine Motors\nDuty for elevator and dumbwaiter driving-machine motors, and driving motors of motor-generators with generator field control, is rated intermittent.",
    "250.53(A)(3)": "250.53(A)(3) Multiple Rod Electrodes\nWhere multiple driven rods form the grounding electrode system, they shall be spaced not less than 6 ft (72 in.) apart to remain effective.",
    "680.58": "680.58 Fountain Receptacle GFCI\n15- and 20-ampere, 125- through 250-volt receptacles within 20 ft of a fountain edge shall have GFCI protection.",
    "Table 310.4(1)": "Table 310.4(1) Conductor Applications and Insulations\nRHW-2 is flame-retardant, moisture-resistant thermoset insulation rated 90°C for dry and wet locations.",
    "315.14": "315.14 Conductor Identification\nPink is an acceptable color for ungrounded conductors.",
    "514.11(A)": "514.11(A) Fuel Dispensing Emergency Shutoff\nEmergency shutoff devices for fuel dispensing systems shall be installed not less than 20 ft and not more than 100 ft from the dispensing devices served.",
    "408.5": "408.5 Conduits Entering the Bottom\nWhere conduits enter a floor-standing switchboard, switchgear, or panelboard at the bottom, the conduits including end fittings shall rise not more than 3 in. above the bottom of the enclosure.",
    "424.20(A)(3)": "424.20(A)(3) No Automatic Restart\nA thermostat may double as the heater disconnect only with a marked off position that opens every hot wire. Even then, the device must be designed so that the circuit cannot be energized automatically after the device has been manually placed in the off position.",
    "240.21(B)(1)": "240.21(B)(1) Taps not over 10 ft, field installation\nIf the tap leaves the enclosure where it is made, the tap ampacity must be at least one-tenth of the overcurrent device protecting the feeder. A 40 A tap can be supplied by a device rated no more than 400 A.",
    "Table 400.4": "Table 400.4 Flexible Cord Types\nSTOOW is the cord type permitted in wet locations that is also sunlight resistant.",
    "430.42(C)": "430.42(C) Receptacle Rating for Motor Loads\nThe maximum ampere rating permitted for a 125-volt, single-phase receptacle with a cord-and-plug motor load and no individual overload protection is 15 amperes.",
    "110.26(E)(1)(a)(c)": "110.26(E)(1) Dedicated Equipment Space\nThe space above a panelboard is dedicated electrical space: sprinkler protection (not water piping, leak protection, or ducts) is permitted there.",
    "450.11(A)": "450.11(A) Transformer Nameplates\nFrequency, insulating-liquid amount, and ventilating clearance are required on the nameplate; conductor AWG size is not.",
    "680.11(A)": "680.11(A) Pool Underground Wiring\nUnderground pool wiring within a stated horizontal distance of the inside pool wall may run in liquidtight flexible metal conduit listed for direct burial (tested here at 60 in.).",
    "330.30(D)(2)": "330.30(D)(2) Unsupported MC to Luminaires\nType MC cable may run unsupported and unsecured up to 72 in. from the last connection point to luminaires.",
    "Table 430.250": "Table 430.250 50 hp wound-rotor motor\nA wound-rotor motor uses the induction-type column, not the synchronous column. A 480-volt system uses the 460-volt column. That cell is 65 A.",
    "406.6(D)": "406.6(D) USB Cover Plates\nA flush device cover plate that also provides a night light or output connectors (USB) shall be listed as Class 2.",
    "392.10(E)": "392.10(E) Airfield Cable in Tray\nAirfield lighting series-circuit cable up to 5,000 volts, under qualified supervision, may run in cable tray.",
    "424.101(A)": "424.101(A) Low-Voltage Heating Units\nAn isolating-type low-voltage heating power unit shall have a rated output not exceeding 42.4 volts peak AC.",
    "500.5(D)(2)": "500.5(D)(2) Class III, Division 2\nLocations where easily ignitable fibers are stored or handled outside the manufacturing process are Class III, Division 2.",
    "430.101": "430.101 Disconnect the Motor and Controller\nA motor disconnecting means must disconnect both the motor and the controller from the circuit.",
    "358.30(A)": "358.30(A) EMT Fastening\nUnbroken EMT runs may be fastened up to 5 ft from the termination where structural members prevent fastening within 3 ft.",
    "Table 210.21(B)(2)": "Table 210.21(B)(2) Cord Load on Receptacles\nMaximum cord-and-plug load on a 15-ampere receptacle fed by a 20-ampere multi-outlet circuit is 12 amperes.",
    "440.64": "440.64 Room Air-Conditioner Cord Length\nA 120-volt room air conditioner cord shall be not longer than 10 ft.",
    "430.102(B)(1)": "430.102(B)(1) Motor Disconnect in Sight\nA disconnecting means for the motor shall be located in sight from the motor location and the driven machinery location.",
    "810.13": "810.13 Antenna Clearances\nOpen antenna and lead-in conductors near electric light or power circuits under 250 volts shall keep at least 24 in. of clearance where proximity cannot be avoided.",
    "522.21(B)": "522.21(B) Ribbon Cable Size\nConductors in non-jacketed multiconductor (ribbon) cable in permanent amusement attractions shall be no smaller than 26 AWG.",
    "225.39(B)": "225.39(B) Small Building Disconnect\nFor installations of not more than two 2-wire branch circuits, the building disconnecting means shall be rated not less than 30 amperes.",
    "225.39(A)": "225.39(A) One-Circuit Disconnect\nA building disconnect for a one-circuit installation with limited loads shall be rated not less than 15 amperes.",
    "240.10": "240.10 Supplementary Overcurrent Protection\nWhere used for luminaires, appliances, and other equipment or for internal circuits and components of equipment, supplementary overcurrent protection shall not be used as a substitute for required branch-circuit overcurrent devices. Supplementary overcurrent devices shall not be required to be readily accessible.",
    "626.11": "626.11 Truck Parking Load\nElectrical services and feeders for electrified truck parking spaces shall be calculated at not less than 11 kVA per space.",
    "250.66(B)": "250.66(B) Concrete-Encased Electrode Conductor\nThe grounding electrode conductor to a concrete-encased electrode need not be larger than #4 copper.",
    "422.5(A)": "422.5(A) Vending GFCI\nVending machines and similar public appliances rated 250 V or less and 60 A or less shall have GFCI personnel protection — including tire inflators and water coolers: all of these.",
    "430.9(C)": "430.9(C) Terminal Torque\nScrew-type pressure terminals for #14 and smaller copper in motor control circuits shall be torqued to at least 7 lb-in unless otherwise marked.",
    "314.24(B)(5)": "314.24(B)(5) Flush Device Box Depth\nThe minimum-size box containing a flush device shall be not less than 15/16 in. deep.",
    "354.28": "354.28 NUCC Trimming\nNUCC conduit ends shall be trimmed from conductors with an approved method that does not damage insulation (a proper termination).",
    "430.52(B)": "430.52(B) Carrying Starting Current\nMotor branch-circuit short-circuit and ground-fault devices must carry the motor starting current.",
    "422.12": "422.12 Central Heating Branch\nCentral heating equipment (other than fixed electric space heat) shall be on an individual branch circuit.",
    "422.33": "422.33 Appliance Disconnect Access\nFor cord-and-plug-connected appliances, an accessible separable connector or plug and receptacle is permitted to serve as the disconnecting means; it is not required to be readily accessible.",
    "647.4(D)": "647.4(D) Sensitive-Equipment Voltage Drop\nBranch-circuit voltage drop on sensitive electronic systems shall not exceed 1.5%.",
    "230.54(B)": "230.54(B) SE Gooseneck\nType SE cable may form a gooseneck taped with weather-resistant thermoplastic at the service.",
    "430.62(A)": "430.62(A) Motor Feeder Rating\nA feeder supplying a specific fixed motor load shall have a protective device rated or set not greater than the largest rating or setting of the branch-circuit short-circuit and ground-fault device for any motor in the group, plus the sum of the full-load currents of the other motors.",
    "324.41": "324.41 Floor Coverings\nFlat conductor cable (Type FCC) on floors shall be covered with carpet squares not larger than 914 mm (36 in.) square. Carpet squares that are adhered to the floor shall be attached with release-type adhesives.",
    "320.80(A)": "320.80(A) AC in Thermal Insulation\nArmored cable installed in thermal insulation shall have conductors rated at 90 degrees C (194 degrees F). The ampacity shall not exceed that of a 60 degrees C rated conductor.",
    "324.40(D)": "324.40(D) Connection to Other Systems\nPower feed, grounding connection, and shield system connection between the FCC system and other wiring systems shall be accomplished in a transition assembly identified for the use.",
    "320.30(D)(2)": "320.30(D)(2) Unsupported AC at Terminals\nType AC cable is fastened within 12 in. of every box and at least every 4.5 ft. A tail not over 600 mm (2 ft) at terminals needing flexibility may go unsupported.",
    "330.104": "330.104 Conductors\nConductors in Type MC cable shall be of copper, aluminum, copper-clad aluminum, nickel or nickel-coated copper, solid or stranded. The minimum conductor size shall be 18 AWG copper, nickel or nickel-coated copper, and 12 AWG aluminum or copper-clad aluminum.",
    "332.10(7)": "332.10(7) Uses Permitted (Type MI)\nType MI cable shall be permitted in hazardous (classified) locations where specifically permitted by other articles in this Code.",
    "340.80": "340.80 UF Ampacity\nThe ampacity of Type UF cable shall be that of 60 degrees C conductors.",
    "332.104": "332.104, 332.108, and 332.116 MI Cable Construction\n332.104 Conductors: solid copper, nickel, or nickel-coated copper. 332.108 Equipment Grounding: the sheath is permitted to serve as the equipment grounding conductor, with an added copper grounding conductor where needed. 332.116 Sheath: a continuous copper or alloy steel sheath that provides mechanical protection and a moisture seal.",
    "338.10(B)(3)": "338.10(B)(3) Temperature Limitations\nType SE service-entrance cable used to supply appliances shall not be subject to conductor temperatures in excess of the temperature specified for the type of insulation involved.",
    "336.24": "336.24 Bending Radius (Type TC)\nBends in Type TC cable shall be made so as not to damage the cable. Type TC cable with metallic shielding shall have a minimum bending radius of not less than 12 times the cable overall diameter.",
    "348.22": "348.22 Number of Conductors\nThe number of conductors in FMC shall not exceed the percentage fill in Table 1, Chapter 9. For 3/8-in. FMC, Table 348.22 gives the maximum number of insulated conductors; the largest size it lists is 10 AWG.",
    "344.120": "344.120 Marking\nEach length of rigid metal conduit shall be clearly and durably identified in every 3 m (10 ft) as required in the first sentence of 110.21(A).",
    "358.14": "358.14 Dissimilar Metals\nWhere practicable, dissimilar metals in contact anywhere in the system shall be avoided to eliminate the possibility of galvanic action. Stainless steel and aluminum fittings and enclosures shall be permitted to be used with steel EMT where not subject to severe corrosive influences.",
    "352.100": "352.100 Construction\nPVC conduit shall be made of rigid (nonplasticized) polyvinyl chloride (PVC). PVC conduit and fittings for use above ground shall have flame-retardant properties and shall be resistant to impact and crushing, distortion from heat under conditions likely to be encountered in service, and low temperature and sunlight effects. For use underground, the material shall be acceptably resistant to moisture and corrosive agents.",
    "358.100": "358.100 Construction\nEMT shall be made of one of the following: (1) steel (ferrous) with protective coatings, (2) aluminum (nonferrous), (3) stainless steel.",
    "350.12": "350.12 Uses Not Permitted (LFMC)\nLFMC shall not be used where subject to physical damage, or where any combination of ambient and conductor temperature produces an operating temperature in excess of that for which the material is approved.",
    "368.234(A)": "368.234(A) Vapor Seals\nBusway runs over 1000 volts that have sections located both inside and outside of buildings shall have a vapor seal at the building wall to prevent interchange of air between indoor and outdoor sections.",
    "370.10(1)": "370.10(1) Uses Permitted (Cablebus)\nCablebus shall be permitted for services, feeders, and branch circuits, and shall be installed only for exposed work.",
    "368.17(B)": "368.17(B) Reduction in Ampacity Size of Busway\nOvercurrent protection shall be required where busways are reduced in ampacity.\nException: For industrial establishments only, omission of overcurrent protection is permitted where the smaller busway does not exceed 15 m (50 ft) and has an ampacity of at least one-third the rating or setting of the overcurrent device next back on the line, and is free from contact with combustible material.",
    "384.30(A)": "384.30(A) Surface Mount\nA surface mount strut-type channel raceway shall be secured to the mounting surface with retention straps external to the channel at intervals not exceeding 3 m (10 ft) and within 900 mm (3 ft) of each outlet box, cabinet, junction box, or other channel raceway termination.",
    "395.30(A)": "395.30(A) Conductors and Supports\nConductors and their supports for outdoor overhead conductors over 1000 volts shall be designed and installed to withstand the expected mechanical loads. Documentation of the engineered design by a licensed professional engineer engaged primarily in the design of such systems, for the spacing between conductors, shall be available upon request of the authority having jurisdiction.",
    "334.30(B)(2)": "334.30(B)(2) Unsupported Cables\nNM cable shall be permitted to be unsupported where it is not more than 1.4 m (4 1/2 ft) from the last point of support to the point of connection to a luminaire or other piece of electrical equipment, and the cable and point of connection are within an accessible ceiling.",
    "Table 430.37": "Table 430.37 Minimum Number of Overload Units\nThe table gives the minimum number and placement of overload units for motor supply configurations. A three-phase motor requires 3 overload units: one in each of the three ungrounded conductors, unless an approved alternative is provided.",
    "680.22(A)(2)": "680.22(A)(2) Circulation System Receptacles\nReceptacles that provide power for water-pump motors or other loads directly related to the circulation and sanitation system shall be located not less than 1.83 m (6 ft) from the inside walls of the pool, shall be of the grounding type, and shall have GFCI protection.",
    "680.21(C)": "680.21(C) GFCI Protection\nOutlets supplying all pool motors on branch circuits rated 150 volts or less to ground and 60 amperes or less, single- or 3-phase, shall be provided with Class A ground-fault circuit-interrupter protection (whether by receptacle or direct connection).",
    "Table 310.12(A)": "310.12(A) Single-Phase Dwelling Services and Feeders (2023)\nFor a service rated 100 through 400 amperes, 120/240-volt, 3-wire, single-phase, supplying the entire load of a one-family dwelling or an individual dwelling unit, the service conductors shall have an ampacity of not less than 83 percent of the service rating. NEC 2023 deleted former Table 310.12; apply the 83 percent rule with Table 310.16.",
    "Chapter 9, Note 4": "Chapter 9, Notes to Tables, Note 4\nWhere conduit or tubing nipples having a maximum length not to exceed 600 mm (24 in.) are installed between boxes, cabinets, and similar enclosures, the nipples shall be permitted to be filled to 60 percent of their total cross-sectional area.",
    "Table 348.22": "Table 348.22 Maximum Number of Insulated Conductors in 3/8-in. FMC\nThe table gives conductor counts by insulation type and whether the fitting is inside or outside the conduit. One additional insulated, covered, or bare equipment grounding conductor of the same size is permitted.",
    "210.4(B)": "210.4(B) Multiwire Branch Circuit Handle Tie\nA multiwire branch circuit's two ungrounded conductors and the neutral shall be capable of being disconnected simultaneously — group handle ties or a listed two-pole breaker.",
    "300.4(A)(1)": "300.4(A)(1) Protection from Physical Damage\nConductors shall be protected from physical damage where run through metal studs — use listed grommet/plaster guard or bushing.",
    "404.14(B)(2)": "404.14(B)(2) AC or DC General-Use Snap Switch — Inductive Loads\nA general-use snap switch suitable for use on AC or DC circuits shall control inductive loads not exceeding 50 percent of the ampere rating of the switch at the applied voltage. Switches rated in horsepower are suitable for controlling motor loads within their rating at the voltage applied.",
    "250.53(A)(5)": "250.53(A)(5) Plate Electrode\nGrounding electrodes must be buried deep enough in the earth to maintain solid, permanent soil contact. Plate electrodes shall be installed not less than 750 mm (30 in. = 2 1/2 ft) below the surface of the earth.",
    "408.41": "408.41 Grounded Conductors\nEach grounded conductor shall terminate within the panelboard on an individual terminal that is not also used for another conductor.",
    "110.26(B)": "110.26(B) Clear Spaces\nWorking space required by this section shall not be used for storage. When normally enclosed live parts are exposed for inspection or servicing, the working space, if in a passageway or general open space, shall be suitably guarded.",
    "110.26(A)(1)": "110.26(A)(1) Depth of Working Space\nDepth is per Table 110.26(A)(1) (e.g., 900 mm / 3 ft for 150 V or less under Condition 1 or 2). Condition 2: exposed live parts on one side and grounded parts on the other side — concrete, brick, or tile walls shall be considered as grounded.",
    "110.26(C)(3)": "110.26(C)(3) Personnel Doors\nFor equipment rated 800 amperes or more containing overcurrent, switching, or control devices, personnel doors intended for entrance to or egress from the working space and located less than 25 ft from its nearest edge shall open at least 90 degrees in the direction of egress and be equipped with listed panic hardware or listed fire exit hardware (2023 NEC).",
    "210.8(B)(2)": "210.8(B)(2) Kitchens or Food Prep Areas\nGFCI protection is required for all 125-volt through 250-volt receptacles supplied by single-phase branch circuits rated 150 volts or less to ground, 50 amperes or less, in kitchens or areas with a sink and permanent provisions for either food preparation or cooking.",
    "210.8(B)(3)": "210.8(B)(2) Kitchens or Areas with a Sink (2023)\nGFCI protection is required for receptacles in kitchens or areas with a sink and permanent provisions for food preparation, beverage preparation, or cooking. (In NEC 2023, 210.8(B)(3) is Rooftops.)",
    "220.5(B)": "220.5(B) Fractions\nBranch-circuit, feeder, and service load calculations shall be permitted to be rounded to the nearest whole ampere, with decimal fractions smaller than 0.5 dropped.",
    "210.8(E)": "210.8(E) Equipment Requiring Servicing\nGFCI protection shall be provided for receptacles for equipment requiring servicing (the receptacles required by 210.63, within 25 ft of the equipment).",
    "590.4(F)": "590.4(F) Lamp Protection\nAll lamps for general illumination in temporary wiring installations shall be protected from accidental contact or breakage by a suitable luminaire or lampholder with a guard.",
    "680.22(A)(4)": "680.22(A)(4) GFCI and SPGFCI Protection\nAll receptacles rated 125 volts through 250 volts, 60 amperes or less, located within 6.0 m (20 ft) of the inside walls of a pool shall have GFCI protection complying with 680.5(B) or SPGFCI protection complying with 680.5(C), as applicable.",
    "440.14": "440.14 Location\nDisconnecting means shall be located within sight from, and readily accessible from, the air-conditioning or refrigerating equipment. The disconnecting means shall be permitted to be installed on or within the equipment and shall meet the working space requirements of 110.26(A) (2023 NEC).",
    "210.8(F)": "210.8(F) Outdoor Outlets\nAll outdoor outlets for dwellings (other than those covered in 210.8(A)(3)) supplied by single-phase branch circuits rated 150 volts to ground or less, 50 amperes or less, shall have GFCI protection for personnel. Exception: GFCI is not required for lighting outlets other than those covered in 210.8(C).",
    "334.12(B)(4)": "334.12(B)(4) NM Cable Exposed in Garage\nNM cable is not permitted exposed on the unfinished surfaces of a garage or unfinished basement walls/ceilings where subject to physical damage — use conduit, MC, or listed raceway.",
    "210.4(C)": "210.4(C) Line-to-Neutral Loads\nMultiwire branch circuits shall supply only line-to-neutral loads. Exceptions permit a multiwire branch circuit to supply a single piece of utilization equipment, or line-to-line loads where all ungrounded conductors are opened simultaneously by the branch-circuit overcurrent device.",
    "590.4(G)": "590.4(G) Splices\nA box, conduit body, or other enclosure shall be required for all splices in temporary wiring installations, such as at tree lots and similar installations.",
    "210.12(A)(1)": "210.12(A) Means of Protection\n(1) A listed combination-type AFCI installed to provide protection of the entire branch circuit — one of the permitted means of providing the AFCI protection required by 210.12(B) through (E).",
    "314.27(D) Ex.": "314.27 Outlet Boxes — Utilization Equipment\nBoxes used for the support of utilization equipment shall be designed for the purpose. Exception: Utilization equipment weighing not more than 3 kg (6 lb) shall be permitted to be supported on other boxes or plaster rings secured to other boxes, provided the equipment is secured with no fewer than two No. 6 or larger screws.",
    "210.12(B)(C)": "210.12(B)/(C) AFCI — Dwelling and Dormitory Units (2023)\n210.12(B): all 120 V, single-phase, 10/15/20 A branch circuits supplying outlets or devices in dwelling unit kitchens, family rooms, dining rooms, living rooms, parlors, libraries, dens, bedrooms, sunrooms, recreation rooms, closets, hallways, laundry areas, and similar areas. 210.12(C): dormitory unit bedrooms, living rooms, hallways, closets, bathrooms, and similar rooms. 210.12(D) adds other occupancies (guest rooms/suites, patient sleeping rooms, fire/police stations). Residential garages are not on any AFCI list.",
    "250.52(A)(2)": "250.52(A)(2) Metal In-Ground Support Structures\nOne or more metal in-ground support structures in direct contact with the earth vertically for 3.0 m (10 ft) or more, with or without concrete encasement, shall be permitted as a grounding electrode.",
    "200.3": "200.3 Connection to Grounded System\nGrounded conductors of premises wiring systems shall be electrically connected to the supply system grounded conductor to ensure a common, continuous grounded system. The section defines an electrical connection as a direct connection capable of carrying current, as distinguished from induced currents; it includes an exception for specified utility-interactive inverters.",
    "517.73(A)": "517.73(A) Diagnostic Equipment (X-Ray)\nThe ampacity of supply branch-circuit conductors and the overcurrent protection shall be not less than 50 percent of the momentary rating or 100 percent of the long-time rating, whichever is greater. Where simultaneous biplane examinations are undertaken, the supply conductors and overcurrent devices shall be 100 percent of the momentary demand rating of the two X-ray tubes.",
    "240.5(B)(4)": "240.5(B)(4) Extension Cord Sets\nFlexible cord used in extension cords made with separately listed and installed components shall be permitted to be supplied by a branch circuit in accordance with: 20-ampere circuits — 16 AWG and larger.",
    "708.54 Ex.": "708.54 Selective Coordination\nCritical operations power system overcurrent devices shall be selectively coordinated with all supply-side overcurrent devices.\nException: Selective coordination shall not be required between two overcurrent devices located in series if no loads are connected in parallel with the downstream device.",
    "110.13(B)": "110.13(B) Cooling of Equipment\nElectrical equipment that depends on the natural circulation of air and convection principles for cooling of exposed surfaces shall be installed so that room airflow over such surfaces is not prevented by walls or by adjacent installed equipment. For equipment designed for floor mounting, clearance between top surfaces and adjacent surfaces shall be provided to dissipate rising warm air. Equipment provided with ventilating openings shall be installed so that walls or other obstructions do not prevent the free circulation of air through the equipment.",
    "225.39": "225.39 Building Disconnect Ratings\nBuilding disconnecting means ratings: one-circuit installation minimum 15 A, two-circuit minimum 30 A, limited load feeder 60 A (see individual subdivisions).",
    "424.36": "424.36 Clearances of Wiring in Ceilings\nWiring located above heated ceilings shall be spaced not less than 50 mm (2 in.) above the heated ceiling and shall be considered as operating at an ambient temperature of 50°C (122°F).",
    "210.19(A)(2)": "210.19(B) Branch Circuits with More Than One Receptacle (2020: 210.19(A)(2))\nConductors of branch circuits supplying more than one receptacle for cord-and-plug-connected portable loads shall have an ampacity of not less than the rating of the branch circuit.",
    "344.10(A)(3)": "344.10(A)(3) RMC in Corrosive Locations\nRigid metal conduit in corrosive locations shall be of a listed corrosion-resistant material (e.g., stainless, PVC-coated) or protected as required.",
    "310.15(A)": "310.15(A) Ampacity Tables\nAmpacities in Tables 310.16 and 310.18 are based on not more than three current-carrying conductors in a raceway, cable, or earth (directly buried), at an ambient of 86°F.",
    "700.7(A)": "700.7(A) Emergency Sources\nA sign shall be placed at the service-entrance equipment, indicating the type and location of each on-site emergency power source.",
    "110.14(C)(2)": "110.14(C)(2) Separate Connector Provisions\nSeparately installed pressure connectors shall be used with conductors at the ampacities not exceeding the ampacity at the listed and identified temperature rating of the connector.",
    "210.11(A)": "210.11(A) Number of Branch Circuits\nThe minimum number of branch circuits shall be determined from the total calculated load and the size or rating of the circuits used. In all installations, the number of circuits shall be sufficient to supply the load served.",
    "110.12(B)": "110.12(B) Integrity of Electrical Equipment and Connections\nInternal parts of electrical equipment, including busbars, wiring terminals, insulators, and other surfaces, shall not be damaged or contaminated by foreign materials such as paint, plaster, cleaners, abrasives, or corrosive residues.",
    "408.36(B)": "408.36(B) Supplied Through a Transformer\nWhere a panelboard is supplied through a transformer, the overcurrent protection required by 408.36 shall be located on the secondary side of the transformer.",
    "110.26": "110.26 Spaces About Electrical Equipment\nAccess and working space shall be provided about all electrical equipment; working space shall be at least 30 in. wide and its depth set by Table 110.26(A)(1) (3 ft for 150 V or less under Condition 2). 2023: open equipment doors shall not impede access to or egress from the working space — access is considered impeded if the doors reduce the space to less than 24 in. wide and 6 1/2 ft high.",
    "408.3(F)(1)": "408.3(F)(1) High-Leg Identification\nA switchboard, switchgear, or panelboard containing a 4-wire, delta-connected system where the midpoint of one phase winding is grounded shall be legibly and permanently field marked: CAUTION ___ PHASE HAS ___ VOLTS TO GROUND.",
    "225.37": "225.37 Disconnect Location\nEach building or structure supplied by a feeder shall have a means for disconnecting all ungrounded conductors — located within sight of the building/structure or capable of being locked (supplied from another building).",
    "547.3(A)(B)": "547.3(A)/(B) Agricultural Building Disconnect\nDisconnecting means for agricultural buildings shall be within sight of the livestock equipment and shall disconnect all ungrounded conductors simultaneously.",
    "406.10(C)": "406.10(C) Grounding Terminal Use\nA receptacle grounding terminal shall not be used for purposes other than connection to the equipment grounding conductor.",
    "409.21(B)(2)": "409.21(B) Location (Industrial Control Panel Overcurrent Protection)\nWhere overcurrent protection is provided as part of the industrial control panel, the supply conductors shall be considered as either feeders or taps as covered by 240.21.",
    "300.5(F)": "300.5(F) Backfill\nBackfill containing large rocks, paving materials, cinders, large or sharply angular substances, or corrosive material shall not be placed where it may damage raceways, cables, conductors, or other substructures, prevent adequate compaction, or contribute to corrosion. Where necessary, protect the wiring method with granular or selected material, suitable running boards or sleeves, or other approved means.",
    "314.2": "314.2 Round Boxes\nRound boxes shall not be used where raceways or connectors requiring locknuts or bushings are connected to the side of the box.",
    "225.19(D)(1)": "225.19(D)(1) Final Spans — Clearance from Windows and Doors\nOverhead final spans shall maintain at least 900 mm (3 ft) horizontal clearance from operable windows, doors, porches, balconies, ladders, stairs, fire escapes, and similar locations, subject to the Code exception for conductors above the top of a window.",
    "225.19(D)(3)": "225.19(D)(3) Building Openings\nOverhead branch-circuit and feeder conductors shall not be installed beneath openings through which materials might be moved, and shall not be installed where they obstruct entrance to those building openings.",
    "724.40": "724.40 Class 1 Power-Limited Circuits\nClass 1 power-limited circuits shall be supplied from a source that has a rated output of not more than 30 volts and 1000 volt-amperes.",
    "314.23(E)": "314.23(E) Raceway-Supported Enclosure, With Devices, Luminaires, or Lampholders\nAn enclosure not over 1650 cm3 (100 in.3) that contains devices, luminaires, or lampholders shall be permitted to be supported by two or more conduits threaded wrenchtight into the enclosure or into hubs identified for the purpose, with each conduit secured within 450 mm (18 in.) of the enclosure.",
    "660.9": "660.9 Minimum Size of Conductors (X-Ray Equipment)\nSize 18 AWG or 16 AWG fixture wires and flexible cords shall be permitted for the control and operating circuits of X-ray and auxiliary equipment where protected by not larger than 20-ampere overcurrent devices.",
    "310.3(B)(3)": "310.3(B)(3) Separation of Circuits\nConductors of different circuits in the same raceway shall be maintained as a system with the same conductor insulation temperature rating (no mixing 90°C and 60/75°C in a fill calculation as mixed).",
    "500.5(D)": "500.5(D) Class III Locations Defined\nClass III locations are those in which combustible flyings or fibers are manufactured, processed, or stored but where ignition is not likely under normal operation.",
    "517.18(B)(1)": "517.18(B)(1) Patient Bed Location Receptacles (General Care)\nEach patient bed location in a general care (Category 2) space shall be provided with a minimum of eight receptacles (for example, four duplex or eight single receptacles).",
    "695.12(D)": "695.12(D) Energized Equipment Parts\nEnergized equipment parts of fire pump controllers shall be located not less than 300 mm (12 in.) above the floor level.",
    "305.4": "305.4 Conductors of Different Systems\nConductors of circuits rated over 1000 volts AC or 1500 volts DC shall not occupy the same enclosure, cable, or raceway with conductors rated at or below those voltages, except as permitted by the listed exceptions. Conductors with nonshielded insulation operating at different voltage levels shall not occupy the same enclosure, cable, or raceway.",
    "551.71(B)": "551.71(B) 30-Ampere (RV Park Supply)\nEvery recreational vehicle site with electrical supply shall be equipped with a 30-ampere, 125-volt receptacle, and at least 70 percent of all sites shall be so equipped.",
    "305.15(E)": "305.15 Underground Installations (E) Backfill\nBackfill containing large rocks, paving materials, cinders, large or sharply angular substances, or corrosive materials shall not be placed in an excavation where materials can damage or contribute to the corrosion of raceways, cables, or other substructures or where it might prevent adequate compaction of fill. Protection in the form of granular or selected material or suitable sleeves shall be provided to prevent physical damage to the raceway or cable.",
    "503.1": "503.1 Class III Div 2 (Fibers) Defined\nClass III, Division 1: locations where combustible fibers are manufactured, processed, or handled under conditions where ignition hazards exist from ignition sources — Division 2 adds storage areas (see 500.5(D)).",
    "250.122(F)(1)(b)": "250.122(F)(1)(b) Conductors in Parallel — Multiple Raceways or Cables\nIf conductors are installed in multiple raceways or cables, and an equipment grounding conductor is used, it shall be installed in parallel in each raceway or cable and sized per Table 250.122 based on the overcurrent protective device for the feeder or branch circuit.",
    "225.18(5)": "225.18(5) Clearance for Overhead Conductors and Cables\nOverhead spans of open conductors and cables not over 1000 volts shall have a clearance of not less than 7.5 m (24 1/2 ft) over track rails of railroads.",
    "600.9(C)": "600.9(C) Wood and Combustible Materials\nWood or other combustible materials used in or on signs shall be located not less than 50 mm (2 in.) from the nearest lampholder or current-carrying part.",
    "551.72(B)": "551.72(B) RV Pedestal Disconnect\nEach RV lot pedestal shall have a disconnecting means for the pedestal branch circuit capable of being locked in the open position.",
    "348.28": "348.28 Trimming\nAll cut ends of FMC shall be trimmed or otherwise finished to remove rough edges, except where fittings that thread into the convolutions are used.",
    "310.14(A)(3)(2)": "310.14(A)(3) Temperature Limitation of Conductors\nNo conductor shall be used where its operating temperature exceeds its rated temperature. Principal determinants include (2) heat generated internally in the conductor as the result of load current flow, including fundamental and harmonic currents.",
    "240.5(B)(1)": "240.5(B)(1) Supply Cord of Listed Appliance or Luminaire\nWhere flexible cord or tinsel cord is approved for and used with a specific listed appliance or luminaire, it shall be considered to be protected when applied within the appliance or luminaire listing requirements.",
    "334.12(A)(3)": "334.12(A)(3) Uses Not Permitted\nTypes NM and NMC cables shall not be used as service-entrance cable.",
    "362.24(A)": "362.24 Bends — How Made\nBends of ENT shall be made so that the tubing is not damaged and the internal diameter is not effectively reduced. Article 100 defines ENT as a pliable raceway: one that can be bent by hand with a reasonable force but without other assistance.",
    "388.12(3)": "388.12(3) Uses Not Permitted\nSurface nonmetallic raceways shall not be used where the voltage is 300 volts or more between conductors, unless listed for higher voltage.",
    "376.30(B)": "376.30(B) Vertical Runs\nVertical runs of metal wireways shall be securely supported at intervals not exceeding 4.5 m (15 ft) and shall not have more than one joint between supports.",
    "342.30(B)(3)": "342.30(B)(3) Vertical Risers\nExposed vertical risers of IMC from industrial machinery or fixed equipment shall be permitted to be supported at intervals not exceeding 6 m (20 ft) if the conduit is made up with threaded couplings, firmly supported at the top and bottom of the riser, and no other means of intermediate support is readily available.",
    "400.13": "400.13 Cord and Cable Table\nFlexible cord ampacity per Table 400.5(A): an 18 AWG SJT cord at 60°C is rated 10 A in continuous duty (check exact row per Table 400.5(A)(1)).",
    "344.30(B)(2)": "344.30(B)(2) Supports for Straight Runs\nStraight runs of RMC made up with threaded couplings shall be permitted to be supported in accordance with the distances in Table 344.30(B)(2), provided such supports prevent transmission of stresses to terminations where the conduit is deflected between supports.",
    "366.100(E)": "366.100(E) Clearance of Bare Live Parts\nBare conductors in auxiliary gutters shall be securely and rigidly supported so that the minimum clearance between bare current-carrying metal parts of different potential mounted on the same surface is not less than 50 mm (2 in.), nor less than 25 mm (1 in.) for parts held free in the air.",
    "382.15(A)": "382.15(A) Nonmetallic Extensions\nOne or more extensions shall be permitted to be run in any direction from an existing outlet, but not on the floor or within 50 mm (2 in.) from the floor.",
    "470.11": "470.11 Location\nResistors and reactors shall not be placed where exposed to physical damage. Where the space between them and any combustible material is less than 305 mm (12 in.), a thermal barrier shall be required.",
    "356.22": "356.22 Number of Conductors\nThe number of conductors in LFNC shall not exceed that permitted by the percentage fill specified in Table 1, Chapter 9.",
    "344.10(C)": "344.10(C) Cinder Fill\nRMC shall be permitted in or under cinder fill where subject to permanent moisture where protected on all sides by a layer of noncinder concrete not less than 50 mm (2 in.) thick, where the conduit is not less than 450 mm (18 in.) under the fill, or where protected by corrosion protection approved for the condition.",
    "Final Exam #1, Question 5": "Switch and Lamp Troubleshooting",
    "322.56(B)": "322.56(B) Taps\nTaps shall be made between any phase conductor and the grounded conductor or any other phase conductor by means of devices and fittings identified for the use. Tap devices shall be rated at not less than 15 amperes, or more than 300 volts to ground, and shall be color-coded in accordance with 322.120(C).",
    "425.22(D)": "425.22(D) Process Heating Overload Protection\nElectric process heating equipment shall be provided with overload protection per 427.5 for continuous-duty heating elements where marked.",
    "680.35(D)": "680.35(D) Audio Equipment\nAudio equipment shall not be installed in or on self-contained storable or portable immersion pools. Audio equipment operating above the low-voltage contact limit and located within 1.83 m (6 ft) of the inside walls of a storable or portable immersion pool shall be grounded and provided with GFCI protection.",
    "408.7": "408.7 Box Entry — Unused Openings\nUnused openings in panelboard enclosures and cutout boxes shall be closed with listed closures (blank plugs/covers).",
    "334.116(B)": "334.116(B) Type NMC\nThe overall covering of Type NMC cable shall be flame retardant, moisture resistant, fungus resistant, and corrosion resistant.",
    "630.12(A)": "630.12(A) Overcurrent Protection for Arc Welders\nEach welder shall have overcurrent protection rated or set at not more than 200 percent of I1max. Where that value does not correspond to a standard rating, the next higher standard rating shall be permitted.",
    "General calculation": "See the question's WORKED SOLUTION for the calculation method (load, ampacity, or voltage-drop computation).",
    "Table 8, Chapter 9": "Chapter 9, Table 8 Conductor Properties\nTable 8 lists conductor dimensions, circular-mil area, stranding, and direct-current resistance at 75°C in ohms per 1000 ft (kFT).",
    "Table 300.1(C)": "Table 300.1(C) Metric Designators and Trade Sizes\nThe table pairs metric designators with trade sizes for conduit, tubing, and associated fittings. The designators identify trade sizes; they are not actual dimensions.",
    "Table 220.55": "Table 220.55 Household Cooking Appliance Demand\nFor one household range rated 12 kW or less, Column C gives an 8 kW maximum demand. Note 1 increases Column C by 5 percent for each additional kilowatt or major fraction above 12 kW; a 14 kW range therefore uses 8.8 kW.",
    "Table 630.31(A)(2)": "Table 630.31(A)(2) Duty-Cycle Multiplication Factors for Resistance Welders\nFor a resistance welder wired for a specific operation with known, unchanged primary current and duty cycle, multiply actual primary current by the table factor for that duty cycle.",
    "Table 352.30(B)": "Table 352.30(B) Support of Rigid PVC Conduit\nA 1/2-in. RNC has a maximum support interval of 3 ft. The table increases support spacing for larger trade sizes; secure the raceway within 3 ft of each termination.",
    "310.15(F)": "310.15(F) Grounding Conductor Not Counted\nA grounding conductor is a noncurrent-carrying conductor and is not counted among current-carrying conductors.",
    "480.10(A)": "480.10(A) Battery Ventilation\nBattery rooms need ventilation to prevent an explosive gas mixture.",
    "430.12(A)": "430.12(A) Terminal Housings\nMotor terminal housings shall be of metal and of substantial construction.",
    "210.8(A)": "210.8(A) Dwelling Units — GFCI Locations\nAll 125-volt through 250-volt receptacles in the listed dwelling unit locations — bathrooms, garages, outdoors, crawl spaces, basements, kitchens, food/beverage prep areas, sinks within 6 ft, boathouses, bathtubs or shower stalls within 6 ft, laundry areas, and indoor damp/wet locations — supplied by single-phase branch circuits rated 150 volts or less to ground shall have GFCI protection.",
    "210.8(A) Ex. 1": "210.8(A) Exception No. 1 — Snow-Melting Equipment\nReceptacles that are not readily accessible and are supplied by a branch circuit dedicated to electric snow-melting, deicing, or pipeline and vessel heating equipment shall be permitted to be installed in accordance with 426.28 or 427.22 (ground-fault protection of equipment instead of GFCI).",
    "210.8(A)(10)": "210.8(A)(10) Bathtubs and Shower Stalls\nGFCI protection is required for receptacles installed within 1.83 m (6 ft) of the outside edge of a bathtub or shower stall where the receptacle is not installed within the bathroom itself.",
    "250.50": "250.50 Existing Buildings\nConcrete-encased electrodes need not join the grounding system where the rebar is unreachable without disturbing concrete in existing buildings.",
    "440.55(B)": "440.55(B) AC Cord Rating\nCord-and-plug room air conditioners are limited to a 15-ampere attachment plug and receptacle at 250 volts.",
    "620.53": "620.51(D)(1) More Than One Driving Machine\nWhere there is more than one driving machine in a machine room, the disconnecting means shall be numbered to correspond to the identifying number of the driving machine that they control. (620.53 covers car light, receptacle, and ventilation disconnecting means.)",
    "240.33": "240.33 Vertical Mounting\nEnclosures for overcurrent devices shall be mounted vertically (upright) unless impracticable.",
    "310.15(B)(1)(1)": "310.15(B)(1)(1) Temperature Correction\nThree #10 THWN-2 conductors at 112°F ambient: 40 A × 0.87 correction = 34.8 A.",
    "210.8(A)(2)": "210.8(A)(2) Garages and Accessory Buildings\n125-volt through 250-volt receptacles in garages and grade-level unfinished accessory buildings, supplied by single-phase branch circuits rated 150 volts or less to ground, shall have GFCI protection for personnel.",
    "408.19": "408.19 Insulated Conductors in Switchgear\nInsulated conductors used inside switchgear or switchboards shall be listed.",
    "406.12(1)": "406.12 Tamper-Resistant Receptacles\nIn dwelling units and other areas specified by the Code, 15- and 20-ampere, 125- and 250-volt nonlocking-type receptacles shall be listed tamper-resistant receptacles. Exceptions cover receptacles high above the floor, parts of luminaires or appliances, and dedicated hard-to-move appliance receptacles.",
    "Table 220.54": "Table 220.54 Demand Factors for Household Electric Clothes Dryers\nFive household dryers use an 85% demand factor.",
    "Table 250.122": "Table 250.122 Minimum Equipment Grounding Conductors\nSized from the overcurrent device ahead of the circuit: a 50-ampere branch circuit takes a #10 copper equipment grounding conductor.",
    "Table 300.5(A)": "Table 300.5(A) Minimum Cover Requirements\nDirect-buried cables in a trench below 2 in. of concrete require a minimum cover of 18 in. in Column 1.",
    "366.23(A)": "366.23(A) Ampacity in Auxiliary Gutters\nCopper busbars in unventilated enclosures are rated at 1,000 amperes per square inch of cross-section (1.5 sq in = 1,500 A; 2 sq in = 2,000 A).",
    "680.43(B)(1)(a)": "680.43(B)(1) Low-Voltage Luminaires Without GFCI\nLuminaires, lighting outlets, and ceiling-suspended paddle fans located over the spa or hot tub or within 5 ft of the inside walls, where no GFCI protection is provided, shall be located not less than 12 ft above the maximum water level.",
    "550.32(F)": "550.32(F) Mobile Home Disconnect Height\nThe handle grip at its highest must be no more than 2.0 m above grade. The bottom of the box must be not less than 600 mm (2 ft, which is 24 inches) above finished grade or working platform."
}

REFERENCE_TABLES = {
    "Table 310.16": [
        ["Conductor size", "Copper 60°C", "Copper 75°C", "Copper 90°C"],
        ["#12 THWN", "20 A", "25 A", "30 A"],
        ["NOTE: At 86°F ambient, no temperature correction is needed. Four current-carrying conductors use the 80% adjustment factor from Table 310.15(C)(1)."],
    ],
    "Table 310.4(1)": [
        ["Conductor type", "Insulation", "Maximum temperature", "Application"],
        ["RHW-2", "Flame-retardant, moisture-resistant thermoset", "90°C", "Dry and wet locations"],
    ],
    "Table 400.4": [
        ["Flexible cord type", "Wet-location use", "Sunlight-resistant"],
        ["STOOW", "Yes", "Yes"],
        ["NOTE: For this item, find a cord type marked for both wet use and sunlight resistance."],
    ],
    "Table 300.5(A)": [
        ["Installation condition", "Minimum cover"],
        ["Direct-buried cable in a trench below 2 in. of concrete", "18 in."],
    ],
    "Table 250.122": [
        ["OCPD rating", "Minimum copper EGC", "Minimum aluminum EGC"],
        ["15 A", "14 AWG", "12 AWG"],
        ["20 A", "12 AWG", "10 AWG"],
        ["30 A", "10 AWG", "8 AWG"],
        ["40–60 A", "10 AWG", "8 AWG"],
        ["NOTE: Select the equipment grounding conductor from the rating of the overcurrent device, not from the ungrounded conductor size."],
    ],
    "Table 430.250": [
        ["Motor horsepower", "Table voltage column for 480 V system", "Three-phase full-load current"],
        ["50 hp", "460 V", "65 A"],
    ],
    "Table 210.21(B)(2)": [
        ["Branch-circuit rating", "Receptacle rating", "Maximum cord-and-plug load"],
        ["20 A", "15 A", "12 A"],
        ["20 A", "20 A", "16 A"],
    ],
    "Table 430.37": [
        ["Motor supply type", "Minimum overload units"],
        ["Three-phase motor", "3 — one for each ungrounded conductor"],
    ],
    "Table 310.12(A)": [
        ["Table 310.12(A) applies to", "Service/feeder scope"],
        ["Single-phase dwelling service or feeder", "100–400 A; 120/240 V, 3-wire; entire load of a one-family dwelling or an individual dwelling unit"],
        ["Sizing allowance", "Conductor ampacity may be 83% of the service or feeder rating"],
    ],
    "Table 220.54": [
        ["Household dryers served", "Demand factor"],
        ["1–4", "100%"],
        ["5", "85%"],
        ["6", "80%"],
        ["7", "75%"],
        ["8", "70%"],
    ],
    "Chapter 9, Note 4": [
        ["Conduit/tubing nipple length", "Maximum fill"],
        ["24 in. or less between enclosures", "60% of total cross-sectional area"],
    ],
    "Table 300.1(C)": [
        ["Metric designator", "Trade size"],
        ["12", "3/8 in."], ["16", "1/2 in."], ["21", "3/4 in."],
        ["27", "1 in."], ["35", "1 1/4 in."], ["41", "1 1/2 in."],
        ["53", "2 in."], ["63", "2 1/2 in."], ["78", "3 in."],
        ["91", "3 1/2 in."], ["103", "4 in."], ["129", "5 in."], ["155", "6 in."],
        ["NOTE: Metric designators identify trade sizes; they are not actual dimensions."],
    ],
    "Table 220.55": [
        ["Household cooking appliance case", "Column C maximum demand"],
        ["One range rated 12 kW or less", "8 kW"],
        ["NOTE 1: For an individual range over 12 kW through 27 kW, increase Column C by 5% for each additional kilowatt or major fraction above 12 kW."],
    ],
    "Table 630.31(A)(2)": [
        ["Resistance-welder duty cycle", "Multiplication factor"],
        ["20%", "0.45"], ["15%", "0.39"], ["10%", "0.32"], ["7.5%", "0.27"], ["5% or less", "0.22"],
        ["NOTE: Supply-conductor ampacity = actual primary current × duty-cycle factor."],
    ],
    "Table 352.30(B)": [
        ["Rigid PVC conduit trade size", "Maximum support spacing"],
        ["1/2–1 in.", "3 ft"], ["1 1/4–2 in.", "5 ft"], ["2 1/2–3 in.", "6 ft"],
        ["3 1/2–5 in.", "7 ft"], ["6 in.", "8 ft"],
        ["NOTE: This question's 1/2-in. RNC uses the 3-ft row."],
    ],
    "Table 8, Chapter 9": [
        ["Conductor size", "Stranding", "Copper DC resistance (Ω/kFT) at 75°C"],
        ["#12 AWG", "Solid", "1.93"], ["#12 AWG", "7 strands", "1.98"],
        ["#10 AWG", "Solid", "1.21"], ["#10 AWG", "7 strands", "1.24"],
        ["NOTE: Table 8 lists conductor properties, including direct-current resistance per 1000 ft."],
    ],
    "Table 348.22": [
        ["Size AWG", "RFH-2/SF-2 In", "Out", "TF/XHHW/AF/TW In", "Out", "TFN/THHN/THWN In", "Out", "FEP/FEPB/PF/PGF In", "Out"],
        ["18", "2", "3", "3", "5", "5", "8", "5", "8"],
        ["16", "1", "2", "3", "4", "4", "6", "4", "6"],
        ["14", "1", "2", "2", "3", "3", "4", "3", "4"],
        ["12", "—", "—", "1", "2", "2", "3", "2", "3"],
        ["10", "—", "—", "1", "1", "1", "1", "1", "2"],
        ["NOTE: One additional insulated, covered, or bare equipment grounding conductor of the same size is permitted."],
    ],
    "Table 220.42(A)": [
        ["Occupancy", "VA/ft2"],
        ["Automotive facility", "1.5"], ["Convention center", "1.4"],
        ["Courthouse", "1.4"], ["Dormitory", "1.5"],
        ["Exercise center", "1.4"], ["Fire station", "1.3"],
        ["Gymnasium", "1.7"], ["Health care clinic", "1.6"],
        ["Hospital", "1.6"], ["Hotel/motel/apartment without cooking", "1.7"],
        ["Library", "1.5"], ["Manufacturing facility", "2.2"],
        ["Motion picture theater", "1.6"], ["Museum", "1.6"],
        ["Office", "1.3"], ["Parking garage", "0.3"],
        ["Penitentiary", "1.2"], ["Performing arts theater", "1.5"],
        ["Police station", "1.3"], ["Post office", "1.6"],
        ["Religious facility", "2.2"], ["Restaurant", "1.5"],
        ["Retail", "1.9"], ["School/university", "1.5"],
        ["Sports arena", "1.5"], ["Town hall", "1.4"],
        ["Transportation", "1.2"], ["Warehouse", "1.2"],
        ["Workshop", "1.7"]
    ]
}

PROMPT_REPAIRS = {
    ("Final Exam #5", 6): (
        "Lengths of not more than ___ of AC cable at terminals where flexibility is necessary does not have to be supported.",
        ["28 inches", "2 feet", "30 inches", "3 feet"],
    ),
    ("Final Exam #3", 28): (
        "Appliances, provided for public use rated 250v or less and 60 amps or less, single-phase or three-phase, shall be provided with GFCI protection for personnel.",
        ["vending machines", "tire inflation machines", "drinking water coolers", "all of these"],
    ),
    ("Final Exam #1", 2): (
        "Each section of equipment that requires rear or side access to make field connections shall be so marked by the manufacturer on the ___.",
        ["front", "right side", "left side", "rear"],
    ),
    ("Final Exam #1", 3): (
        "In other than one and two family dwellings, a receptacle outlet for indoor service equipment shall be located within ___ of the service equipment.",
        ["25 feet", "50 feet", "75 feet", "the same room or area"],
    ),
    ("Final Exam #1", 6): (
        "Decorative lighting and similar accessories used for holiday lighting and similar purposes shall be listed and ___.",
        ["marked", "approved", "labeled", "stamped"],
    ),
    ("Final Exam #1", 9): (
        "An acceptable color for ungrounded conductors is ___.",
        ["green", "gray", "pink", "white"],
    ),
    ("Final Exam #1", 10): (
        "The calculated load of a 12 foot length of fixed multioutlet assembly in a commercial facility is ___ volt-amperes if the appliances it supplies are not likely to be used at the same time.",
        ["1000", "720", "540", "380"],
    ),
    ("Final Exam #1", 12): (
        "A wall-mounted central vacuum assembly connected to a single receptacle located in an attached garage shall be provided with ___ protection for personnel.",
        ["LCDI", "GFCI", "AFCI", "both AFCI and GFCI"],
    ),
    ("Final Exam #1", 15): (
        "If festoon lighting is installed without a messenger, the smallest allowable overhead conductor is ___ AWG.",
        ["#10", "#12", "#14", "#16"],
    ),
    ("Final Exam #1", 16): (
        "For temporary holiday lighting, trees shall be permitted for supporting overhead spans of conductors and cables if the overhead wiring is arranged with ___, tension take-up devices, or other approved means to avoid damage from live vegetation.",
        ["fittings", "cable ties", "strain relief devices", "overhead clamps"],
    ),
    ("Final Exam #1", 18): (
        "Duty on elevator and dumbwaiter driving machine motors and driving motors of motor-generators used with generator field control shall be rated as ___.",
        ["intermittent", "lockable", "continuous", "varying"],
    ),
    ("Final Exam #1", 19): (
        "What does the alpha character I represent when stating the equation W = E x I?",
        ["Intrinsic circuit", "Intrinsic electromotive force", "Intensity of current", "Isotopic character"],
    ),
    ("Final Exam #1", 20): (
        "Where multiple driven ground rods are used to form the grounding electrode system, in order to maintain an effective grounding electrode system, they shall be spaced not less than ___ apart.",
        ["36 inches", "48 inches", "60 inches", "72 inches"],
    ),
    ("Final Exam #1", 24): (
        "All 15 or 20 amp, single-phase, 125 volt through 250 volt receptacles located within ___ feet of a fountain edge shall be provided with GFCI protection.",
        ["20", "24", "25", "30"],
    ),
    ("Final Exam #1", 27): (
        "The ampacity of three #10 THWN-2 conductors installed in a raceway is ___ amps if the ambient temperature is 112°F.",
        ["31.6", "34.8", "35", "37.2"],
    ),
    ("Final Exam #1", 28): (
        "Fuel dispensing systems shall be provided with one or more clearly identified emergency shutoff devices or electrical disconnects. Such disconnects or devices shall be installed in approved locations but not less than 20 feet or more than ___ feet from the fuel dispensing devices that they serve.",
        ["50", "75", "80", "100"],
    ),
    ("Final Exam #1", 29): (
        "Where conduits enter a floor-standing switchboard, switchgear, or panelboard at the bottom, the conduits, including their end fittings, shall not rise more than ___ inches above the bottom of the enclosure.",
        ["2", "3", "4", "6"],
    ),
    ("Final Exam #1", 36): (
        "For a service rated 100 through 400 amps, the service conductors supplying the entire load of a one family dwelling shall be permitted to have an ampacity ___ of the service rating.",
        ["83%", "80%", "75%", "70%"],
    ),
    ("Final Exam #1", 37): (
        "Nonmetallic cable trays shall be made of ___ material.",
        ["watertight", "waterproof", "fire-resistant", "flame-retardant"],
    ),
    ("Final Exam #1", 40): (
        "The permitted demand factor for five household clothes dryers in a multifamily dwelling is ___.",
        ["70%", "75%", "80%", "85%"],
    ),
    ("Final Exam #1", 41): (
        "A stop switch is wired in ___ with a motor circuit.",
        ["series", "series-shunt", "series-parallel", "parallel"],
    ),
    ("Final Exam #1", 42): (
        "All 15 and 20 amp, 125 and 250 volt, nonlocking receptacles located in a wet location shall be listed ___ type.",
        ["weather proof", "water proof", "water resistant", "weather resistant"],
    ),
    ("Final Exam #1", 43): (
        "Where no GFCI protection is provided, the mounting height of a paddle fan located above a spa or hot tub shall not be less than ___ feet.",
        ["6", "8", "10", "12"],
    ),
    ("Final Exam #1", 44): (
        "An unintentional, electrically conducting connection between an ungrounded conductor of an electrical circuit and the normally non-current-carrying conductors, metallic enclosures, metallic raceways, metallic equipment or earth is referred to as a ___.",
        ["ground fault", "open circuit", "short circuit", "circuit bypass"],
    ),
    ("Final Exam #1", 46): (
        "40% is equivalent to ___.",
        ["5/8", "3/5", "2/5", "5/16"],
    ),
    ("Final Exam #1", 48): (
        "A 125 volt, 15 amp rated receptacle located in a hallway of a dwelling unit is required to be ___.",
        ["GFCI protected", "on a dedicated circuit", "need a 20 amp receptacle", "listed tamper-resistant"],
    ),
    ("Final Exam #1", 49): (
        "Direct-buried cables located in a trench below 2 inches of concrete shall have a minimum cover of ___.",
        ["6 inches", "12 inches", "18 inches", "24 inches"],
    ),
    ("Final Exam #1", 56): (
        "The maximum ampere rating permitted for a 125 volt, single-phase, receptacle outlet having a cord-and-plug connected motor load that does not have individual overload protection is ___.",
        ["15 amps", "20 amps", "25 amps", "30 amps"],
    ),
    ("Final Exam #1", 57): (
        "___ is permitted in the dedicated electrical space above a panelboard.",
        ["Water piping", "Leak protection", "Sprinkler protection", "Air-conditioning ducts"],
    ),
    ("Final Exam #1", 59): (
        "Branch circuits shall be rated in accordance with the ___.",
        ["ampere rating of the largest receptacle", "maximum permitted rating of the fuse or breaker", "number of receptacle outlets in the branch circuit", "ampere rating of the largest conductor"],
    ),
    ("Final Exam #1", 60): (
        "Underground wiring within ___ horizontally from the inside wall of the pool shall be permitted in liquidtight flexible metal conduit listed for direct burial use.",
        ["18 inches", "24 inches", "48 inches", "60 inches"],
    ),
    ("Final Exam #1", 62): (
        "You have 125 volts at the panel and 115 volts at the load. What is the percentage of voltage drop?",
        ["5%", "4.35%", "4.17%", "8%"],
    ),
    ("Final Exam #1", 64): (
        "When working from an electrical drawing, you should start from the ___.",
        ["Lower right-hand corner", "Center", "Upper left-hand corner", "Bottom"],
    ),
    ("Final Exam #1", 67): (
        "Conduit nipples not over 24 inches in length may be filled to a maximum of ___.",
        ["50%", "60%", "70%", "80%"],
    ),
    ("Final Exam #1", 4): (
        "Disregarding demand factors, the calculated lighting load for a 5,000 sq.ft. office building is ___ volt-amperes.",
        ["16,500", "15,400", "8,000", "6,500"],
    ),
    ("Final Exam #1", 30): (
        "Thermostatically controlled switching devices serving as both controllers and disconnecting means for fixed electric space-heating equipment shall ___.",
        [
            "not be permitted",
            "be located not more than 8 feet above floor level",
            "open all grounded conductors when placed in the off position",
            "be designed so that the circuit cannot be energized automatically after the device has been manually placed in the off position",
        ],
    ),
    ("Final Exam #5", 18): (
        "The ampacity of Type UF cable shall be that of ___ conductors.",
        ["60 degrees F", "75 degrees C", "140 degrees C", "60 degrees C"],
    ),
    ("Final Exam #3", 69): (
        "A feeder supplying a specific fixed motor load must have a protective device with a rating or setting ___ the largest branch-circuit short-circuit and ground-fault rating or setting in the group, plus the sum of the full-load currents of the other motors.",
        ["125 percent of", "not greater than", "225 percent of", "none of these"],
    ),
    ("Final Exam #3", 57): (
        "When determining the number of conductors considered as current-carrying, a grounding conductor is ___.",
        [
            "counted as one current-carrying conductor",
            "counted as one conductor for each ground wire in the raceway",
            "considered to be a current-carrying conductor but not counted",
            "considered to be a noncurrent-carrying conductor and is not counted",
        ],
    ),
    ("Final Exam #5", 2): (
        "Armored cable installed in thermal insulation shall have conductors rated at ___. The ampacity of the cable installed in these applications shall not exceed that of 60 degree C conductors.",
        ["60 degrees C", "194 degrees F", "75 degrees C", "90 degrees F"],
    ),
    ("Final Exam #1", 11): (
        "In a dwelling bedroom, any wall space ___ or more in width (including space measured around corners) and unbroken along the floor line by doorways and similar openings, fireplaces, and fixed cabinets that do not have countertops or similar work surfaces.",
        ["18 inches", "24 inches", "30 inches", "36 inches"],
    ),
    ("Final Exam #1", 8): (
        "Balconies, decks, and porches that are within 4 inches horizontally of the dwelling unit shall have at least one receptacle outlet accessible from the balcony, deck, or porch. The receptacle outlet shall not be located more than ___ above the balcony, deck, or porch walking surface.",
        ["36 inches", "48 inches", "60 inches", "78 inches"],
    ),
    ("Final Exam #1", 70): (
        "What is the full load current of a 50 horsepower, 3, 480v, wound-rotor AC motor?",
        ["104 amps", "52 amps", "65 amps", "41 amps"],
    ),
    ("Final Exam #1", 50): (
        "Communications wires and cables and CATV type coaxial cables shall have a vertical clearance of not less than ___ from all points of roofs above which they pass.",
        ["18 inches", "36 inches", "6 feet", "8 feet"],
    ),
    ("Final Exam #1", 33): (
        "A three-way switch is equivalent to a ___ switch.",
        ["DPST", "DPDT", "SPST", "SPDT"],
    ),
    ("Final Exam #1", 32): (
        "For a feeder tap not exceeding 10 feet in length and field installation, the maximum overcurrent device rating supplying a tap conductor with an ampacity of 40 amps is ___.",
        ["150 A", "200 A", "350 A", "400 A"],
    ),
    ("Final Exam #1", 45): (
        "Residential in-sink electrically operated kitchen waste disposers shall be permitted to be cord-and-plug connected; however, the flexible cord is to be not less than 18 inches in length and not over ___ in length.",
        ["24 inches", "30 inches", "36 inches", "48 inches"],
    ),
}

QUESTION_REFERENCE_TEXTS = {
    ("Final Exam #1", 5): "Switch and Lamp Troubleshooting" + chr(10) + "With S1 closed and 0 volts measured across it, the switch contacts are conducting. With full 120 volts still present across the lamp, the lamp circuit is open downstream of the switch, so current never reaches the filament.",
    ("Open Book Exam #10", 9): "Operator. The individual responsible for starting, stopping, and controlling an amusement ride or supervising a concession. (525) (CMP—15)",
    ("Open Book Exam #10", 10): "225.19(D)(1) Final Spans — Clearance from Windows and Doors. Maintain at least 900 mm (3 ft) horizontal clearance from operable windows and doors. 225.19(D)(3) Building Openings. Do not install overhead branch-circuit or feeder conductors beneath openings used to move materials, or where they obstruct entrance to those openings."
}

def reference_key(reference):
    clean = reference.replace("NEC ", "").strip()
    if clean in REFERENCE_TEXTS:
        return clean
    for suffix in (" Column 1", " Ex. 1", " Ex.", " Ex"):
        if clean.endswith(suffix) and clean[: -len(suffix)] in REFERENCE_TEXTS:
            return clean[: -len(suffix)]
    for key in sorted(REFERENCE_TEXTS, key=len, reverse=True):
        if clean.startswith(key):
            return key
    return clean

def reference_text(reference, exam="", question_number=0):
    specific = QUESTION_REFERENCE_TEXTS.get((exam, question_number), "")
    if specific:
        return specific
    return REFERENCE_TEXTS.get(reference_key(reference), "")

def reference_table(reference):
    return REFERENCE_TABLES.get(reference_key(reference), [])

ANSWER_GLOSSARY = {
    '125%': 'One and one-quarter times.',
    '125% of the largest rating': 'One-quarter over the biggest.',
    '194 degrees f': 'A temperature rating equal to 90°C.',
    '225% of the largest rating': 'More than double the biggest.',
    '60 degrees c': 'A metric temperature rating.',
    '75 degrees c': 'A metric temperature rating.',
    '90 degrees f': 'A temperature rating near body heat.',
    'a copy of the osha regulations for each person involved.': 'A rulebook for everyone.',
    'a guarded': 'Shielded one.',
    'a metal faceplate not less than 0.030 inches in thickness': 'A metal cover plate at least 0.030 in. thick.',
    'a readily accessible': 'Quickly reachable.',
    'a reset type test button on the face of the receptacle': 'A test button on the outlet face.',
    'a single run of cable shall not contain more than four quarter bends': 'One cable run limited to four 90-degree bends.',
    'a supplemental list that shows all involved energy sources and energy isolating devices.': 'A list of every energy source and lockout.',
    'above ground in direct sunlight': 'Outdoor sun exposure.',
    'acceptable': 'Satisfactory for the inspector and the rule.',
    'accessible': 'Can be reached for service (may need tools or a ladder).',
    'actual': 'Actual.',
    'afci': 'Trips on dangerous arcing that starts fires.',
    'age': 'Age.',
    'aging': 'Aging.',
    'all of these': 'Every listed item.',
    'alternation': 'One half-cycle of alternating current.',
    'aluminum': 'Light silver metal.',
    'an accessible': 'Reachable one.',
    'an adequate path for grounding purposes': 'A low-resistance fault-current path to ground.',
    'an isolated': 'Separated one.',
    'an orange triangle located on the face of the receptacle': 'An orange triangular mark on the outlet face.',
    'any of the above': 'Whichever item above.',
    'any of these': 'Whichever listed item.',
    'any service under 400 amps': 'Every service below 400 amps.',
    'appliance': 'A powered device.',
    'applied within the listing requirements': 'Used as its listing allows.',
    'approved': 'Acceptable to the local inspector (the authority having jurisdiction).',
    'arc-fault interrupter': 'Device tripping on dangerous sparking inside walls.',
    'are listed for grounding': 'Tested for grounding use.',
    'are the compression type': 'Squeeze-tightened fittings.',
    'areas not adaptable as future occupiable space': "Spaces that can't become living space.",
    'as a feeder': 'Use as the subpanel supply conductors.',
    'as a grounding conductor': 'Acting as ground path.',
    'as a support for lighting fixtures': 'Holding up lights.',
    'as service entrance': 'Use bringing utility power into the building.',
    'assistant': 'One who helps another person.',
    'bare': 'Uncovered.',
    'barrier': 'Wall.',
    'be permitted': 'Allowed by the rule.',
    'be required': 'Demanded by the rule.',
    'bonding jumper': 'A short conductor joining metal parts for fault current.',
    'both (b) and (c)': 'Items B and C together.',
    'both ferrous and nonferrous conduits': 'Steel and aluminum raceways.',
    'bottom': 'Lowest part of the sheet.',
    'bottom shield': 'Bottom metal layer.',
    'branch circuit': 'The final circuit to outlets.',
    'branch circuits': 'Final circuits to outlets and equipment.',
    'busway is not permitted in commercial buildings.': 'No busways in shops/offices.',
    'by observing signs and signals indicating its presence': 'Watching posted warnings.',
    'by wearing 3-d glasses': 'Using 3-D glasses.',
    "by wearing a switchman's hood": 'Using special headgear.',
    'by-pass': 'A path routed around a device.',
    'calculated': 'The computed value.',
    'center': 'Middle of the sheet.',
    'certified': 'Certified.',
    'circuit bypass': 'An unintended alternate path around part of a circuit.',
    'class 1': 'Low-voltage wiring class one.',
    'class 2': 'Low-voltage wiring class two.',
    'class i': 'Gas and vapor hazard areas.',
    'class ii': 'Dust hazard areas.',
    'class ii, division 2': 'Dust areas under abnormal conditions.',
    'class ii, division ii': 'Dust areas under abnormal conditions.',
    'class iii': 'Fiber and flying hazard areas.',
    'class iii, division 1': 'Fiber areas under normal conditions.',
    'class iii, division 2': 'Fiber areas under abnormal conditions.',
    'clearly and durably identified': 'Marked to last.',
    'co/alr': 'Devices rated for aluminum and copper-clad aluminum wire.',
    'co/alr orange marking on the face of the receptacle': 'An orange terminal marking for aluminum-rated devices.',
    'commercial': 'Business.',
    'commercial services only': 'Shops and offices only.',
    'concealed': 'Hidden.',
    'condulet': 'Conduit body.',
    'connect to the fitting properly': 'Joined to the fitting correctly.',
    'connection': 'Joint.',
    'connector': 'Connector.',
    'contain insulated bushings': 'Fitted with insulating throat liners.',
    'continuous': 'Always on.',
    'controlled': 'Switched equipment.',
    'controller': 'The device that starts and stops a motor.',
    'corrode': 'To be eaten chemically.',
    'corrosion': 'Chemical eating of metal.',
    'corrosive': 'Eating metal chemically.',
    'corrosive particles': 'Airborne chemicals attacking materials.',
    'corrosive residues': 'Chemical leftovers that eat metal.',
    'covered': 'Covered.',
    'cross': 'A plus-shaped symbol.',
    'cu/al wire': 'Copper-or-aluminum conductor.',
    'damp or wet location': 'Areas with moisture where NM cable is barred.',
    'datum level': 'Base height.',
    'delta': 'Delta.',
    'deteriorate': 'Worsen.',
    'deterioration': 'Decay.',
    'device': 'Device.',
    'devices': 'Devices.',
    'diagram a': 'First diagram.',
    'diagram b': 'Second diagram.',
    'diagram c': 'Third diagram.',
    'diagram d': 'Fourth diagram.',
    'direct burial in earth': 'Laid straight in a trench.',
    'directly': 'Direct.',
    'disconnect': 'A switch that disconnects equipment from power.',
    'disconnecting means': 'The switch or breaker opened before servicing equipment.',
    'disconnection': 'The act of disconnecting (see disconnecting means).',
    'disconnects': 'Switches.',
    'dissipation': 'Heat spreading away from a part.',
    'dormitory closets': 'School-housing closets.',
    'doughnut': 'A ring-shaped bend.',
    'dpdt': 'Double-pole double-throw: two wires flipped between paths.',
    'dpst': 'Double-pole single-throw: two wires switched together.',
    'drawing': 'A scaled plan on paper.',
    'driving machine they control': 'The machine its disconnect serves.',
    'dual': 'Double.',
    'duct seal': 'Sealing putty.',
    'dust': 'Dust.',
    'dust and dirt': 'Dirt.',
    'dwelling units': 'Homes.',
    'easily': 'Easily.',
    'electrical nonmetallic tubing': 'Plastic bendable raceway.',
    'electrically': 'Wired.',
    'enamel': 'Enamel.',
    'enclosure': 'A box housing equipment.',
    'entrance': 'Entrance.',
    'equal to': 'Equal.',
    'equipment bonding jumper': 'Equipment ground link.',
    'equipment failures': 'Breakdowns of machines or devices.',
    'equipment grounding': 'The green-wire safety path on receptacles and equipment.',
    'equipment requiring servicing': 'Gear needing maintenance access.',
    'escape limit': 'Exit limit.',
    'existing buildings': 'Already-built structures.',
    'exothermic welding': 'Chemical-heat weld.',
    'explosive': 'Able to blast apart.',
    'exposed work': 'Wiring run visibly on surfaces.',
    'feeder': 'Conductors from the service to a subpanel.',
    'filtered': 'Passed through a filter.',
    'fire barrier': 'Fire stop.',
    'fire-resistant': 'Withstands fire exposure without quick failure.',
    'fished in voids in masonry block': 'Pulled through hollow block cores.',
    'fixed': 'Permanently fastened equipment.',
    'flame-retardant': 'Self-extinguishing material that stops burning on its own.',
    'flexible': 'Bendable wiring or cord.',
    'flexible conduit': 'Bendable raceway.',
    'for wiring in wet, dry, or corrosive locations': 'Outdoor, damp, and chemical-exposed wiring.',
    'frequency': 'Cycles per second.',
    'front': 'The face of the equipment.',
    'fryer': 'Fry cooker.',
    'fuses': 'Fuses.',
    'galvanize': 'Galvanized.',
    'garage': 'The vehicle bay.',
    'gas stations': 'Fuel-dispensing sites.',
    'gated': 'Fitted with a gate.',
    'gfci': 'Trips on tiny current leaks to ground.',
    'gfci protected': 'Guarded by a ground-fault interrupter.',
    'glue': 'Sticky adhesive.',
    'gooseneck': 'A curved neck bend.',
    'grandfather': 'Older person or thing; not an NEC-defined term for people.',
    'gray': 'Gray insulation marks a grounded (neutral) wire.',
    'greater than': 'Bigger.',
    'green': 'Green insulation marks the grounding wire.',
    'green dot': 'A green circular mark.',
    'ground fault': 'Current leaking to ground through an unintended path.',
    'ground-fault': 'Leakage of current to ground.',
    'grounded': 'Connected to earth (often the white neutral conductor).',
    'grounded conductor': 'The white neutral, carrying normal current, connected to earth.',
    'grounding conductor': 'Green or bare wire carrying fault current to the source.',
    'grounding electrode conductor': 'Ground-rod wire.',
    'guard': 'Shield.',
    'guarded': 'Shielded or enclosed against accidental contact with live parts.',
    'guest suites': 'Hotel living units.',
    'harc': 'A connector rating mark.',
    'harmonic': 'A multiple-frequency distortion of the AC wave.',
    "have a vertical clearance of not less than 8' from all points of roofs above which they pass": 'Eight feet above roofs.',
    'hazardous': 'Dangerous.',
    'hazardous locations': 'Explosive-atmosphere areas.',
    'header': 'Duct section.',
    'health care facilities': 'Hospitals and clinics.',
    'high leg': 'High leg.',
    'horizontal': 'Side-to-side orientation.',
    'hours of fuel': 'Fuel hours.',
    'i and ii only': 'Two.',
    'i, ii and iii': 'Three.',
    'i, ii, or iii': 'Any.',
    'identified': 'Recognizable as suitable for the purpose by marking, listing, or labeling.',
    'identified closures': 'Blank fillers.',
    'ieee': 'An engineering standards organization.',
    'iii only': 'Third.',
    'in a multifamily dwelling unit': 'In an apartment building.',
    'in commercial garages': 'Vehicle repair areas.',
    'in exposed and concealed work': 'In seen and hidden runs.',
    'in exposed work': 'In surface-visible wiring.',
    'in hazardous locations': 'In explosive areas.',
    'in need of a 20 amp receptacle': 'A 20-amp rated outlet.',
    'inadequate regulation enforcement': 'Weak oversight of the rules.',
    'incomplete procedures': 'Unfinished work steps.',
    'individual': 'Its own private one (wire, terminal).',
    'industrial laboratories': 'Lab workspaces.',
    'inrush': 'Startup surge.',
    'inside': 'Indoors.',
    'install in a workmanlike manner': 'Installed neatly and skillfully.',
    'installed in one raceway only': 'Placed in a single raceway.',
    'instantaneous': 'Instant.',
    'insulated': 'Coated.',
    'isolated': 'Separated from everything else (own path or enclosure).',
    'it is not permitted to be installed overhead.': 'No overhead installation.',
    'it may be mounted flush on a wall in a wet location': 'Surface mounting allowed in wet spots.',
    'it may be used in hazardous locations, where permitted': 'Allowed in explosive areas when the rules permit.',
    'it must be at least 1/3 the ampere rating of the larger bus.': 'At least one-third the big bus rating.',
    'it must be protected by an overcurrent device.': 'Needs breaker or fuse protection.',
    'it shall be supported every 10 feet': 'Straps at 10-foot intervals.',
    'junior hard-service': 'Lighter cord grade.',
    'knife switch': 'Knife switch.',
    'knowledge that each person involved in the task is in control of all energy sources.': 'Every worker controlling their own energy.',
    'labeled': 'Carries the mark of a testing lab for a specific purpose.',
    'lamp': 'Bulb cord.',
    'largest': 'Largest.',
    'laundry': 'The clothes-washing area.',
    'lcdi': 'Leakage-current protection built into appliance cords.',
    'left side': 'One side of the equipment.',
    'line': 'Hot.',
    'listed': 'Tested by a lab (like UL) for a specific use.',
    'listed tamper-resistant': 'Lab-tested outlet with kid-proof shutters.',
    'load center': 'The panelboard with branch breakers.',
    'loads': 'Loads.',
    'location': 'The place something sits.',
    'locked': 'Locked.',
    'locked rooms': 'Locked rooms.',
    'loop': 'A circular bend.',
    'lower right-hand corner': 'Bottom-right of the sheet.',
    'luminaire': 'A complete light fixture.',
    'magnetically': 'Magnetic.',
    'main bonding jumper': 'The connection joining neutral to ground at the service.',
    'manager': 'One running the business.',
    'manually': 'By hand force.',
    'marked': 'Carries required text, symbols, or colors on the equipment.',
    'maximum': 'The largest allowed value.',
    'maximum water level': 'Highest water.',
    'may be used as a substitute for a branch-circuit overcurrent protection device': 'May replace branch protection.',
    'may be used to protect internal circuits of equipment': 'May guard inner circuits.',
    'metal': 'Conductive rigid material.',
    'minimum': 'The smallest allowed value.',
    'moisture': 'Moisture.',
    'momentary': 'Moment-long.',
    'multifamily dwelling unit': 'An apartment in a multi-unit building.',
    'multiwire': 'Shared neutral.',
    'must be readily accessible': 'Must stay quickly reachable.',
    'must not be used in luminaires': 'Forbidden in light fixtures.',
    'national electrical contractors association': 'A trade group of electrical contractors.',
    'national fire protection association': 'The organization publishing the NEC.',
    'neutral': 'The grounded conductor (usually white) completing the circuit.',
    'neutral conductor': 'White return wire.',
    'nmc': 'Corrosion-proof NM cable.',
    'no specified distance': 'Without a stated measurement.',
    'non-continuous': 'Not always on.',
    'none of these': 'No listed item.',
    'nonhazardous': 'An ordinary, unclassified area.',
    'nonmetallic': 'Plastic-jacketed wiring.',
    'nonshielded': 'Insulation without metallic shielding.',
    'not be attached to a cross-arm that carries electric light or power conductors': 'Kept off power cross-arms.',
    'not be required': 'Not demanded by the rule.',
    'not greater than the largest rating or setting of the': 'Capped at the biggest rating.',
    'not required': 'Not demanded.',
    'of not less than': 'At least.',
    'on a dedicated circuit': 'The only load on its breaker.',
    'only 240/120v, 3-wire services for a single dwelling unit': 'One-home 240/120V 3-wire services only.',
    'only multifamily dwelling services': 'Apartment buildings only.',
    'open circuit': 'A broken path where no current can flow.',
    'open porches': 'Porches.',
    'operator': 'One who starts, stops, and controls a ride or concession.',
    'orange triangle': 'An orange triangular mark.',
    'organic residues': 'Plant or animal leftovers.',
    'outer sheath': 'Outer jacket.',
    'outer sheath to provide mechanical protection': 'A jacket guarding against damage.',
    'outside': 'Outdoors.',
    'oven': 'Baker.',
    'over flow': 'Spill.',
    'overload': 'Current above rating lasting long enough to overheat equipment.',
    'overload protection': 'Heaters or relays tripping on sustained overload.',
    'panelboard it is fed from': 'The panel supplying it.',
    'par': 'A three-letter abbreviation.',
    'parallel': 'Wired side-by-side across the same voltage.',
    'parts changer': 'Someone swapping parts; not an NEC-defined term.',
    'patient sleeping rooms': 'Nursing-home bedrooms.',
    'people': 'Human beings on the job site.',
    'permanently': 'Forever.',
    'permanently installed burglar alarm': 'Fixed security equipment.',
    'permanently installed fire alarm': 'Fixed fire-alarm equipment.',
    'permitted': 'Allowed by the Code under stated conditions.',
    'phase': 'One AC leg.',
    'pink': 'Pink is an allowed color for ungrounded conductors.',
    'plastic': 'Molded nonmetallic material.',
    'portable': 'Cord-moved.',
    'primary': 'First.',
    'pvc schedule 80 conduit': 'Heavy plastic conduit.',
    'pwr': 'The abbreviation for power.',
    'qualified': 'Trained, skilled, and hazard-aware (a defined person).',
    'raceway': 'A wire channel.',
    'range': 'Cooker.',
    'readily accessible': 'Quick to reach without obstacles or keys.',
    'rear': 'The back of the equipment.',
    'recognized': 'Acknowledged by the Code for an application.',
    'red triangle': 'A red triangular mark.',
    'release-type adhesive': 'Removable glue.',
    'remote disconnect control': 'A relay-operated disconnect control.',
    'residential garages': 'Home vehicle bays.',
    'right side': 'One side of the equipment.',
    'rubber': 'Elastic insulating material.',
    'run in parallel in each raceway': 'Run alongside in every raceway.',
    'running': 'Operating normally.',
    'safety switch': 'Switch.',
    'scale': 'The ratio of drawing to real size.',
    'schools': 'Schools.',
    'screen': 'Mesh.',
    'secondary': 'The stepped-down side of a transformer.',
    'section sign': 'Sign section.',
    'selective coordination': 'Staging protective devices so a fault opens only the nearest one.',
    'series': 'Wired end-to-end in a single path.',
    'series-parallel': 'Groups in series, groups joined in parallel.',
    'series-shunt': 'A combined series/parallel arrangement.',
    'service': 'The main power entrance.',
    'serviceable': 'Made so it can be maintained or repaired in place.',
    'sheet metal': 'Thin plate.',
    'short circuit': 'Hot touching neutral or ground, producing very large current.',
    'short-circuit': 'A violent hot-to-neutral or hot-to-ground fault.',
    'shower stalls': 'Enclosed shower spaces.',
    'shunt trip': 'A breaker add-on tripping it from a remote signal.',
    'shunts': 'Shunts.',
    'sight': 'A visible place.',
    'sign body': "A sign's structural shell.",
    'sign enclosure': 'The electrical enclosure part of a sign.',
    'sign gutter': 'Sign gutter.',
    'silicone': 'Silicone.',
    'silicone rubber': 'High-heat rubber insulation.',
    'single': 'Solo.',
    'sink': 'Basin.',
    'solid copper conductors': 'Solid (not stranded) copper wires.',
    'spdt': 'Single-pole double-throw: one wire flipped between two paths.',
    'spst': 'Single-pole single-throw: one wire in, one out, on/off.',
    'spt-2': 'Light parallel lamp-cord type.',
    'stainless steel': 'Rust-proof steel.',
    'stamped': 'Marking pressed or printed into the equipment surface.',
    'star': 'A star-shaped symbol.',
    'starting': 'Getting going.',
    'steel': 'Strong iron alloy.',
    'steel electrical metallic tubing': 'Steel thin-wall raceway.',
    'steel with protective coatings': 'Coated steel.',
    'stoow': 'Extra-hard portable cord, oil- and weather-resistant.',
    'stranded wire': 'Many fine strands twisted together.',
    'sufficient length': 'Long enough for the job.',
    'suitable': 'Fit for the particular purpose and conditions.',
    'sunlight resistant': 'Jacket surviving outdoor UV exposure.',
    'supplementary': 'Extra protection beyond the branch rating.',
    'supply': 'Supply.',
    'tacking strip': 'Carpet gripper.',
    'tamper-resistant': 'Outlet shutters blocking poked-in objects.',
    'tap': 'A short conductor tapped off a feeder.',
    'taps': 'Taps.',
    'ten': 'The number 10.',
    'termination': 'The point where a wire lands.',
    'tested': 'Tried and verified.',
    'testing areas': 'Test areas.',
    'the branch circuit feeding it': 'The circuit supplying it.',
    'the cable has two conductors.': 'A two-wire cable.',
    'the conductor has a maximum operating temperature of 90°c.': 'Rated up to 90 degrees Celsius.',
    'the conductor is double insulated.': 'Two layers of insulation.',
    'the conductor is thermoplastic.': 'Plastic insulation.',
    'the light and switch are shorted': 'Light and switch shorted together.',
    'the light is good but the switch does not make contact': 'Working bulb, faulty switch contacts.',
    'the light is open (bulb burned out)': 'The bulb filament is broken.',
    'there is a break in the circuit wiring': 'A wire is broken somewhere.',
    'thermoset': 'Set plastic.',
    'thhn': 'Thermoplastic, heat-resistant wire with a nylon jacket.',
    'thhw': 'Thermoplastic, heat- and water-resistant wire.',
    'thirty six': 'The number 36.',
    'this installation meets code requirements.': 'The setup complies.',
    'thread into the convolutions': 'Screwed into the spiral ridges.',
    'thw': 'Thermoplastic, heat- and water-resistant wire.',
    'thwn': 'Heat- and water-resistant building wire.',
    'ticket taker': 'One collecting tickets.',
    'timing': 'Time setting.',
    'tinsel': 'Decorative wire.',
    'total': 'Total.',
    'toxic': 'Poisonous.',
    'transfer': 'Energy moved from one place to another.',
    'transition assembly': 'The listed box joining flat FCC cable to ordinary wiring.',
    'trench': 'A dug ditch.',
    'triangle': 'A three-sided symbol.',
    'turtleback': 'A humped bend.',
    'twelve': 'The number 12.',
    'twenty four': 'The number 24.',
    'type v construction': 'Wood-frame construction.',
    "underwriters' laboratories": 'The safety testing lab (UL).',
    'ungrounded': 'Not connected to earth (often a hot conductor).',
    'upper left-hand corner': 'Top-left of the sheet.',
    'use': 'Underground service-entrance cable.',
    'vapor seal': 'Air-moisture seal.',
    'vented': 'Having vents.',
    'ventilated enclosure': 'Vented box.',
    'ventilating': 'Openings letting cooling air flow.',
    'vertical': 'Up-and-down orientation or section.',
    'voltage': 'Electrical pressure in volts.',
    'water resistant': 'Resists water entry to a rated degree.',
    'waterproof': 'Sealed against water entry.',
    'watertight': 'Sealed so water cannot enter.',
    'weather proof': 'Enclosure keeping water out in wet locations.',
    'weather resistant': 'Built to survive rain and sun in wet locations.',
    'where installations requires flexibility or protection from liquids, vapors or solids': 'Bendy or wet/dirty spots.',
    'where practicable, be located below the electric light or power conductors': 'Run under power lines where possible.',
    'where subject to physical damage': 'Places where cable can be struck or crushed.',
    'white': 'White insulation marks the grounded (neutral) wire.',
    'with heat': 'Hot.',
    'without heat': 'Cold.',
    'wye': 'Wye.',
    'xhwn': 'A wire-type designation.',
    'y': 'A Y-shaped mark.',
    'yellow circle': 'A yellow circular mark.',
}

def choice_notes_for(answers):
    notes = []
    for answer in answers:
        key = re.sub(r"\s+", " ", str(answer).strip().lower())
        notes.append(ANSWER_GLOSSARY.get(key, ""))
    return notes

FORMULA_HINTS = {
    ("Final Exam #1", 1): "Write 60 over 100, then divide the numerator and denominator by their greatest common factor.",
    ("Final Exam #1", 4): "Offices use 1.3 VA per sq ft (Table 220.42(A)). Multiply by the floor area.",
    ("Final Exam #1", 10): "Not simultaneous: one 180 VA outlet per 5 ft or fraction (220.14(H)(1)). Count the outlets first.",
    ("Final Exam #1", 14): "At 86°F use the 75°C table value with no temperature correction, then multiply by 0.80 for four current-carrying conductors.",
    ("Final Exam #1", 21): "Ranges use Table 220.55 demand, not the nameplate — look up the row for this kW size.",
    ("Final Exam #1", 25): "Welder overcurrent ≤ 200% of I1max (630.12(A)), then go to the next standard breaker size.",
    ("Final Exam #1", 27): "Multiply the base ampacity by the temperature correction factor for the given ambient.",
    ("Final Exam #1", 32): "Field 10-ft tap, 240.21(B)(1): compare the tap conductor ampacity with the rating of the feeder overcurrent device.",
    ("Final Exam #1", 36): "Dwelling services 100–400 A need only 83% of the rating (310.12(A)).",
    ("Final Exam #1", 40): "Multiple dryers use the Table 220.54 demand factor for that dryer count.",
    ("Final Exam #1", 46): "Divide the percent by 100, then reduce the fraction.",
    ("Final Exam #1", 62): "Volts lost divided by source volts: (panel − load) ÷ panel.",
    ("Final Exam #1", 63): "Divide the drawing inches by the inches-per-foot of the scale.",
    ("Final Exam #1", 65): "One 360° cycle takes 1/60 s — figure out what fraction 90° is.",
    ("Final Exam #1", 67): "Nipples 24 in. or shorter may fill to 60% (Chapter 9, Note 4).",
    ("Final Exam #1", 68): "Size the EGC from Table 250.122 using the branch-circuit rating.",
    ("Final Exam #1", 70): "Read the full-load current straight from Table 430.250 for this HP and voltage.",
    ("Final Exam #1", 22): "Count the receptacle outlets 210.52(G)(1) requires for the garage in the stem.",
    ("Final Exam #3", 26): "Each truck space counts a fixed minimum kVA (626.11).",
    ("Final Exam #3", 33): "Ohm's power law: amps = watts ÷ volts.",
    ("Final Exam #3", 40): "Welder duty factor = √(duty cycle). Multiply the primary current by it.",
    ("Final Exam #3", 55): "Two equal resistors in parallel equal half of one.",
    ("Final Exam #3", 63): "Unventilated copper busbar ≈ 1,000 A per square inch — find the cross-section first.",
    ("Final Exam #3", 69): "Feeder protection = largest motor's protection plus the rest at full load (430.62(A)).",
    ("Final Exam #5", 39): "Unventilated copper busbar ≈ 1,000 A per square inch — find the cross-section first.",
    ("Open Book Exam #1", 21): "Offices use 1.3 VA per sq ft (Table 220.42(A)). Multiply by the floor area.",
    ("Open Book Exam #4", 15): "Multiple dryers use the Table 220.54 demand factor for that dryer count.",
    ("Open Book Exam #4", 22): "Dwelling services 100–400 A need only 83% of the rating (310.12(A)).",
    ("Open Book Exam #7", 4): "Biplane X-ray uses 100% of the momentary demand rating for supply and protection.",
}

WORKED_SOLUTIONS = {
    ("Final Exam #1", 1): "60 ÷ 100 = 3/5.",
    ("Final Exam #1", 4): "5,000 × 1.3 = 6,500 VA.",
    ("Final Exam #1", 10): "12 ft → three 5-ft fractions × 180 VA = 540 VA.",
    ("Final Exam #1", 14): "25 × 0.80 = 20 A.",
    ("Final Exam #1", 21): "14 kW → Table 220.55 = 8.8 kW.",
    ("Final Exam #1", 25): "43 × 2.0 = 86 A → next standard size 90 A.",
    ("Final Exam #1", 27): "40 × 0.87 = 34.8 A.",
    ("Final Exam #1", 32): "40 × 10 = 400 A.",
    ("Final Exam #1", 40): "Table 220.54, five dryers = 85%.",
    ("Final Exam #1", 46): "40 ÷ 100 = 2/5.",
    ("Final Exam #1", 62): "10 ÷ 125 = 8%.",
    ("Final Exam #1", 63): "3.5 ÷ 0.25 = 14 ft.",
    ("Final Exam #1", 65): "(1/60) ÷ 4 = 1/240 s.",
    ("Final Exam #3", 33): "2 ÷ 20 = 0.10 A.",
    ("Final Exam #3", 40): "√0.15 ≈ 0.39; 21 × 0.39 = 8.19 A.",
    ("Final Exam #3", 55): "2,000 ÷ 2 = 1,000 Ω.",
    ("Final Exam #3", 63): "1.5 sq in × 1,000 = 1,500 A.",
    ("Final Exam #5", 39): "4 × 0.5 = 2 sq in × 1,000 = 2,000 A.",
    ("Open Book Exam #1", 21): "5,000 × 1.3 = 6,500 VA.",
    ("Open Book Exam #4", 15): "Table 220.54, five dryers = 85%.",
}

def formula_for(exam, number):
    return FORMULA_HINTS.get((exam, number), "")

def worked_for(exam, number):
    return WORKED_SOLUTIONS.get((exam, number), "")

# The edition's article titles: one table shared with the app and the validator.
NEC_ARTICLES = json.loads(nec_data("articles.json").read_text(encoding="utf-8"))
ARTICLE_TITLES = {int(number): title for number, title in NEC_ARTICLES["articles"].items()}

def article_title(reference):
    match = re.search(r"\b(\d{3})\b", reference)
    if not match:
        return reference
    return ARTICLE_TITLES.get(int(match.group(1)), "")

bank = []
missing = []
report = []
for exam in EXAMS:
    source = exam.label
    transcript = exam.transcript()
    if transcript is not None:
        # Reviewed text of the exam: replaces the OCR parse for this exam.
        typed = {item["number"]: item for item in transcript["questions"]}
        questions = {n: {"prompt": q["prompt"], "choices": q["answers"]} for n, q in typed.items()}
        answers = {n: q["correct_index"] for n, q in typed.items()}
        answers.update({k["number"]: k["correct_index"] for k in transcript.get("key_only", [])})
        refs = {n: q["reference"] for n, q in typed.items()}
    else:
        questions = read_questions(exam.ocr_path(OCR), QUESTION_COUNTS[source])
        answers, refs = read_key(exam.key_ocr_path(KEYS), QUESTION_COUNTS[source])
    for number in range(1, QUESTION_COUNTS[source] + 1):
        if number not in questions:
            missing.append({"source": source, "number": number, "answer_index": answers.get(number)})
            continue
        item = questions[number]
        if number not in answers:
            report.append(f"No answer key match: {source} Q{number}")
            continue
        bank.append([
            source.upper(),
            item["prompt"],
            item["choices"],
            answers[number],
            refs.get(number, ""),
            source,
            number,
        ])

records = []
for item in bank:
    keywords, lookup_summary = extract_lookup(item[1], item[2], item[4])
    records.append({
        "id": record_id(item[5], item[6]),
        "exam": item[5],
        "question_number": item[6],
        "prompt": PROMPT_REPAIRS.get((item[5], item[6]), (item[1], item[2]))[0],
        "answers": PROMPT_REPAIRS.get((item[5], item[6]), (item[1], item[2]))[1],
        "gist": GISTS.get((item[5], item[6]), ""),
        "scene": SCENES.get((item[5], item[6]), ""),
        "correct_index": item[3],
        "article": item[4],
        "article_title": article_title(item[4]),
        "keywords": keywords,
        "lookup_summary": lookup_summary,
        "info_tip": explain_question(item[1], keywords, item[4]),
        "reference_text": reference_text(item[4], item[5], item[6]),
        "reference_table": reference_table(item[4]),
        "tip_title": CONCEPT_SHORT.get(concept_key_for(item[1].lower(), item[4]), ("In plain language", ""))[0],
        "tip_short": concept_tip_short(concept_key_for(item[1].lower(), item[4]), item[2], item[3]),
        "formula": formula_for(item[5], item[6]),
        "worked": worked_for(item[5], item[6]),
        "choice_notes": choice_notes_for(item[2]),
        "available": True,
    })
# State law questions come from curated JSON, not OCR, and follow the NEC records.
state_records, state_manifest = load_state_law()
records.extend(state_records)
# Curated corrections live in a data overlay instead of being lost on rebuild.
# Set WIRE_SKIP_BANK_OVERRIDES=1 only when generating a raw baseline for a
# reviewed overlay refresh.
if os.environ.get("WIRE_SKIP_BANK_OVERRIDES") != "1":
    overrides_path = Path(__file__).with_name("question_bank_overrides.json")
    overlay = json.loads(overrides_path.read_text(encoding="utf-8"))
    apply_overrides(records, overlay)
    # The paragraph that restates the stem quotes it and lists its numbers, so a
    # curated stem must not leave the raw OCR stem (typos, answer words) there.
    # The background note above it stays as reviewed.
    for record in records:
        fields = overlay["records"].get(record["id"], {})
        if "info_tip" not in fields and not record.get("section"):
            record["info_tip"] = restate_stem(record["info_tip"], record["prompt"], record["keywords"], record["article"])
# Titles follow the final citation: an override that moves a record to another
# article must not keep the title of the OCR citation it replaced.
for record in records:
    if record.get("section"):
        continue
    primary = re.match(r"(?:Table\s+|Article\s+)?(\d{2,3})(?:\.\d|\b)", record["article"].strip())
    if primary and int(primary.group(1)) in ARTICLE_TITLES:
        record["article_title"] = ARTICLE_TITLES[int(primary.group(1))]

# "questions" held the RAW pre-curation rows (un-redacted stems, original
# units). main.gd read only "records"; keeping both doubled the file and left a
# latent fallback to unredacted data. Curated rows only.
playable = len(bank) + len(state_records)
payload = {"version": 2, "total_expected": sum(QUESTION_COUNTS.values()) + len(state_records), "playable": playable, "missing_source_items": missing, "audit_notes": report, "records": records}
manifest = []
for source, count in QUESTION_COUNTS.items():
    for number in range(1, count + 1):
        match = next((item for item in bank if item[5] == source and item[6] == number), None)
        manifest.append({"source": source, "number": number, "available": match is not None})
manifest.extend(state_manifest)
payload["manifest"] = manifest
OUT.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")
print(json.dumps({"playable": playable, "missing": len(missing), "notes": len(report), "output": str(OUT)}))
