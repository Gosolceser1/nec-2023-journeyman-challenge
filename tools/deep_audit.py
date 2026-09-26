import json, re

def deep_audit():
    with open('question_bank.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    records = data['records']
    print(f"Auditing all {len(records)} records for reference text accuracy and code provision alignment...")
    
    mismatches = []
    
    for r in records:
        rid = r['id']
        art = r.get('article', '')
        prompt = r.get('prompt', '')
        c_idx = r.get('correct_index', -1)
        ans = r.get('answers', [])
        c_ans = ans[c_idx] if 0 <= c_idx < len(ans) else ''
        ref = r.get('reference_text', '')
        
        # Check if the title in ref text matches art
        # e.g. ref text header vs art
        header = ref.split('\n')[0] if ref else ''
        
        # Let's inspect cases where ref doesn't contain core numbers of answer, or ref heading seems mismatched
        # We will log all records so we can inspect them systematically.
        
    print("Done initial check.")

if __name__ == '__main__':
    deep_audit()
