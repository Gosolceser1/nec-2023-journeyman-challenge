import json

with open('tools/anomalies.json', 'r', encoding='utf-8') as f:
    items = json.load(f)

for it in items:
    print('=' * 60)
    print(f"{it['id']} | Article: {it['art']}")
    print(f"Prompt: {it['prompt']}")
    print(f"Answer: {it['ans']}")
    print(f"Ref:\n{it['ref_text']}")
