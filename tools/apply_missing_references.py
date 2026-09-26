import json
from missing_references_data import REFERENCES_TO_ADD

with open('question_bank.json', 'r', encoding='utf-8') as f:
    qb = json.load(f)

updated_count = 0
for r in qb.get('records', []):
    qid = r.get('id')
    if qid in REFERENCES_TO_ADD:
        data = REFERENCES_TO_ADD[qid]
        r['reference_text'] = data['reference_text']
        r['worked'] = data['worked']
        updated_count += 1

print(f"Updated {updated_count} records with reference_text and worked solutions.")

with open('question_bank.json', 'w', encoding='utf-8') as f:
    json.dump(qb, f, indent=2, ensure_ascii=False)

print("Saved question_bank.json successfully.")
