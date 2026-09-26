import json

with open("question_bank.json", "r", encoding="utf-8") as f:
    data = json.load(f)

records = data.get("records", [])

updated = 0
for r in records:
    rid = r.get("id", "")
    
    # Fix 1: Grammatical blanks in prompts
    if rid == "final-exam-#3-034":
        r["prompt"] = "The minimum size box that is to contain a flush device must not be less than ___ deep."
        r["tip_short"] = "Under NEC 314.24(B)(5), a box containing a flush-mounted device must have a depth of not less than 15/16 inch."
        updated += 1
    elif rid == "final-exam-#3-044":
        r["prompt"] = "Voltage drop on sensitive electronic equipment systems must not exceed ___ for branch circuits."
        r["tip_short"] = "Per NEC 647.4(D), branch-circuit voltage drop for sensitive electronic equipment cannot exceed 1.5%."
        updated += 1
    elif rid == "final-exam-#5-008":
        r["tip_short"] = "NEC 330.104 states that control and signal conductors in metal-clad (MC) cable can be as small as 18 AWG copper."
        updated += 1
    elif rid == "final-exam-#5-018":
        r["tip_short"] = "Under NEC 340.80, the ampacity of Type UF cable must be determined using the 60°C conductor column."
        updated += 1
        
    # Fix 2: Math/General knowledge reference_text and worked solutions
    elif rid == "final-exam-#1-046":
        r["reference_text"] = "Basic Trade Math — Percent to Fraction Conversion\n40% = 40 / 100 = 4 / 10 = 2 / 5."
        r["worked"] = "40% = 40/100. Divide numerator and denominator by 20 to get 2/5."
        r["formula"] = "Percent / 100 = Fraction"
        updated += 1
    elif rid == "final-exam-#1-001":
        r["reference_text"] = "Basic Trade Math — Percent to Fraction Conversion\n60% = 60 / 100 = 6 / 10 = 3 / 5."
        r["worked"] = "60% = 60/100. Divide numerator and denominator by 20 to get 3/5."
        r["formula"] = "Percent / 100 = Fraction"
        updated += 1
    elif rid == "final-exam-#1-062":
        r["reference_text"] = "Voltage Drop Calculation\nVD = V_source - V_load = 125V - 115V = 10V drop.\n% Voltage Drop = (10V / 125V) * 100 = 8%."
        r["worked"] = "Drop = 125V - 115V = 10V. Percent drop = (10V / 125V) * 100 = 8%."
        r["formula"] = "% Drop = ((V_panel - V_load) / V_panel) × 100"
        updated += 1
    elif rid == "final-exam-#1-065":
        r["reference_text"] = "AC Waveform Period and Phase Angle\nOne full cycle = 360 degrees = 1/60 second = 0.01667 s.\n90 degrees is 1/4 of a cycle: (1/60) / 4 = 1/240 second (0.00417 s)."
        r["worked"] = "One cycle (360°) at 60 Hz takes 1/60 sec. 90° is 1/4 cycle: (1/60) * (1/4) = 1/240 second."
        r["formula"] = "t = (Angle / 360) × (1 / Frequency)"
        updated += 1
    elif rid == "final-exam-#1-063":
        r["reference_text"] = "Blueprint Scale Reading\n1/4 inch on the drawing equals 1 foot actual. Multiply the drawing inches by 4 to get actual feet."
        r["worked"] = "Scale is 1/4\" = 1'. Measured dimension in inches divided by 0.25 yields actual feet."
        r["formula"] = "Actual Feet = Drawing Inches × 4"
        updated += 1
    elif rid == "final-exam-#3-055":
        r["reference_text"] = "Parallel Resistance Formula\nFor identical parallel resistors: R_total = R / N.\nR_total = 2,000 ohms / 2 = 1,000 ohms."
        r["worked"] = "R_total = R / n = 2,000 / 2 = 1,000 ohms."
        r["formula"] = "R_total = R_branch / Number of identical branches"
        updated += 1

print(f"Total records refined: {updated}")
with open("question_bank.json", "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
print("question_bank.json successfully updated!")
