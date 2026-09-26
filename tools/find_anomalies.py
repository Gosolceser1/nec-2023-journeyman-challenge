import json, re

def find_all_anomalies():
    with open('question_bank.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    records = data['records']
    results = []

    for idx, r in enumerate(records):
        rid = r['id']
        art = r['article']
        prompt = r['prompt']
        c_idx = r['correct_index']
        ans = r['answers'][c_idx]
        ref = r['reference_text']

        # Look for indicators that ref text does NOT actually mention the concept or section
        # or where the ref text title is about something completely different
        # Let's extract section number from art
        clean_art = art.replace('NEC ', '').replace('Table ', '').replace('DEF ', '').replace('Definitions ', '').replace('Definition ', '')
        sec_match = re.match(r'(\d+[\.\d]*[A-Za-z0-9\(\)]*)', clean_art)
        sec = sec_match.group(1) if sec_match else clean_art

        # Check if the title line of ref matches the topic
        first_line = ref.split('\n')[0] if ref else ''
        
        # Check if key answer words or numbers are in ref
        ans_clean = str(ans).lower()
        # strip punctuation
        ans_words = [w for w in re.findall(r'[a-zA-Z0-9]+', ans_clean) if len(w) >= 3 and w not in [
            'the', 'and', 'for', 'with', 'from', 'than', 'more', 'less', 'each', 'both', 'only',
            'feet', 'foot', 'inch', 'inches', 'circuit', 'circuits', 'rating', 'ampere', 'amperes'
        ]]

        ans_in_ref = any(w in ref.lower() for w in ans_words) if ans_words else True
        if not ans_in_ref and not r.get('reference_table') and not r.get('formula') and art not in ['General knowledge', 'General calculation', 'Final Exam #1, Question 5', 'NFPA 70E']:
            results.append({
                'idx': idx,
                'id': rid,
                'art': art,
                'sec': sec,
                'prompt': prompt,
                'ans': ans,
                'ref_title': first_line,
                'ref_text': ref
            })

    print(f"Total found with answer not in reference text: {len(results)}")
    with open('tools/anomalies.json', 'w', encoding='utf-8') as out:
        json.dump(results, out, indent=2)

if __name__ == '__main__':
    find_all_anomalies()
