import json, re

def main():
    with open('question_bank.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    records = data['records']
    print(f"Total records loaded: {len(records)}")

    suspects = []

    for r in records:
        rid = r.get('id', '')
        art = r.get('article', '')
        prompt = r.get('prompt', '')
        c_idx = r.get('correct_index', -1)
        ans = r.get('answers', [])
        c_ans = str(ans[c_idx]) if (c_idx is not None and 0 <= c_idx < len(ans)) else 'UNKNOWN'
        ref = r.get('reference_text', '')
        table = r.get('reference_table', [])
        formula = r.get('formula', '')

        # Check: Is c_ans supported by reference_text or reference_table or formula?
        c_clean = c_ans.lower().strip()
        ref_clean = ref.lower().strip()
        
        # Check if numbers or key words in c_ans appear in ref
        nums_in_ans = re.findall(r'\b\d+(?:\.\d+)?\b', c_clean)
        words_in_ans = [w for w in re.findall(r'[a-zA-Z]+', c_clean) if len(w) > 3 and w not in ['feet', 'foot', 'inch', 'inches', 'than', 'more', 'less', 'with', 'from', 'each', 'both', 'only', 'have', 'been', 'wire', 'cable', 'conductor', 'conductors']]

        found = False
        if c_clean in ref_clean:
            found = True
        elif nums_in_ans and all(n in ref_clean for n in nums_in_ans):
            found = True
        elif words_in_ans and any(w in ref_clean for w in words_in_ans):
            found = True
        elif table or formula:
            found = True
        elif art in ['General knowledge', 'General calculation', 'Final Exam #1, Question 5', 'NFPA 70E']:
            found = True

        if not found:
            suspects.append({
                'id': rid,
                'art': art,
                'prompt': prompt,
                'answer': c_ans,
                'ref': ref
            })

    print(f"Items needing manual/reference verification: {len(suspects)}")
    for s in suspects:
        print(f"--- {s['id']} | {s['art']} ---")
        print(f"Prompt: {s['prompt']}")
        print(f"Answer: {s['answer']}")
        print(f"Ref: {s['ref']}")
        print()

if __name__ == '__main__':
    main()
