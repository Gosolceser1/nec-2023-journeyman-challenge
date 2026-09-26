import json

with open('question_bank.json', 'r', encoding='utf-8') as f:
    qb = json.load(f)

for r in qb.get('records', []):
    if not r.get('reference_text', '').strip() and not r.get('worked', '').strip():
        answers = r.get('answers', [])
        c = r.get('correct_index', -1)
        ans = answers[c] if 0 <= c < len(answers) else '?'
        print("ID:", r.get('id'))
        print("Article:", r.get('article'))
        print("Prompt:", r.get('prompt'))
        print("Ans:", ans)
        print("Answers:", answers)
        print("Gist:", r.get('gist'))
        print("-" * 60)
