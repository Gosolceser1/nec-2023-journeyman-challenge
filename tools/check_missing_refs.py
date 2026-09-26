import json

with open('question_bank.json', 'r', encoding='utf-8') as f:
    qb = json.load(f)

for r in qb.get('records', []):
    ref = r.get('reference_text', '').strip()
    worked = r.get('worked', '').strip()
    if not ref and not worked:
        answers = r.get('answers', [])
        correct = r.get('correct_index', -1)
        ans_str = answers[correct] if 0 <= correct < len(answers) else "?"
        print(f"ID: {r.get('id')}")
        print(f"Prompt: {r.get('prompt')}")
        print(f"Correct Answer: {ans_str}")
        print(f"Gist: {r.get('gist')}")
        print(f"Article: {r.get('article')}")
        print("-" * 50)
