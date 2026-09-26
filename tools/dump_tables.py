import json

with open('question_bank.json', 'r', encoding='utf-8') as f:
    qb = json.load(f)

for r in qb.get('records', []):
    tbl = r.get('reference_table', [])
    if not tbl:
        continue
    qid = r.get('id')
    ans = str(r.get('answers')[r.get('correct_index')])
    prompt = r.get('prompt')
    print(f"=== {qid} ===")
    print(f"Prompt: {prompt}")
    print(f"Ans: {ans}")
    for row in tbl:
        print("   ", row)
    print()
