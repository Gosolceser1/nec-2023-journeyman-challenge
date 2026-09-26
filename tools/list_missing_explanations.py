import json

with open('question_bank.json', 'r', encoding='utf-8') as f:
    qb = json.load(f)

count = 0
for r in qb.get('records', []):
    if not r.get('reference_text', '').strip() and not r.get('worked', '').strip():
        count += 1
        answers = r.get('answers', [])
        c = r.get('correct_index', -1)
        ans = answers[c] if 0 <= c < len(answers) else '?'
        print(f"{count}. {r.get('id')} | {r.get('article')} | Ans: {ans}")
        print(f"   Prompt: {r.get('prompt')}")
        print()
