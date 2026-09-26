import json

with open('question_bank.json', 'r', encoding='utf-8') as f:
    qb = json.load(f)

for r in qb.get('records', []):
    tbl = r.get('reference_table', [])
    if not tbl:
        continue
    qid = r.get('id')
    ans = str(r.get('answers')[r.get('correct_index')])
    matches = []
    for r_i, row in enumerate(tbl):
        if r_i == 0 or (len(row) == 1 and str(row[0]).startswith('NOTE:')):
            continue
        for c_i, val in enumerate(row):
            s = str(val)
            # check direct or normalized match
            matches.append((r_i, c_i, s))
    print(f"ID: {qid} | Ans: {ans}")
    print(f"Rows: {len(tbl)}")
