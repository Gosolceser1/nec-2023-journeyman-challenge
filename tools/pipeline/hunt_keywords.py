"""Hunt keywords: the stem words to look up in the code book's Index.

Reads the checked-in bank and the edition's curated vocabulary
(data/nec/<year>/index_terms.json) and writes data/nec/<year>/hunt_keywords.json,
which the app uses to color those words in the stem, to name the Index main
entry and subentry to open before answering. Nothing of it shows after
answering. The bank itself is not changed: every keyword is an exact phrase of
its stem.

    python tools/pipeline/hunt_keywords.py            # write the file
    python tools/pipeline/hunt_keywords.py --check    # fail when it is stale or breaks a rule

Rules (also checked by --check on the written file):
- only records that cite the NEC get keywords (1 to MAX_KEYWORDS each); the
  others are listed under no_lookup with the reason;
- a keyword is a phrase of the stem, is not the correct choice, does not contain
  it and is not part of it (unless every choice holds it); its main entry and
  subentry do not name the correct choice;
- neither the keyword nor its main entry or subentry holds any choice,
  distractors included ('rear or side access' colors the choice 'rear');
- a heading is paired only with an article it leads to: one of its own
  articles, or through a subentry that leads there; the article is one the
  record cites and exists in the edition's articles.json;
- what shows (main entry, subentry) names no location: no article, Part,
  section, table, chapter or annex number; finding it is the drill ('article'
  is for the rules above, never shown);
- one keyword is the primary one, the word to start the lookup with.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import pipeline_paths  # noqa: E402

ROOT = pipeline_paths.ROOT
BANK_PATH = ROOT / "data" / "question_bank.json"
MAX_KEYWORDS = 3
CHAPTER_9 = "Chapter 9"
DEFINITIONS = "100"
STATE_LAW_RE = re.compile(r"^(?:Neb\. Rev\. Stat\.|Title \d+ NAC\b)")
ARTICLE_RE = re.compile(r"(?<![\d.])(\d{3})(?![\d])")
WORD_EDGE = r"A-Za-z0-9\-"
# A citation in a bank reference: "Table 220.55", "210.52(E)(3)", "Article 100".
CITATION_RE = re.compile(r"(?:Table\s+)?\d{3}\.\d+(?:\([A-Za-z0-9]+\))*|Article\s+\d{3}")
CHAPTER_9_RE = re.compile(r"\b(Table\s+\d+|Note\s+\d+)\b")
# Any code-book location; none may show before answering.
LOCATION_RE = re.compile(
    r"\bArt(?:icle)?s?\b\.?\s*\d|\bPart\s+[IVX]+\b|\bChapter\s+\d|\bAnnex(?:es)?\s+[A-K]\b|\bTables?\s+\d|\bSection\s+\d"
    r"|\d{3}\.\d|(?<![\d.,])[1-8]\d{2}(?![\d.,])(?!\s*(?:volts?|V)\b)", re.IGNORECASE)
OTHER_THAN_REACH = 30


def terms_path() -> Path:
    return pipeline_paths.nec_data("index_terms.json")


def output_path() -> Path:
    return pipeline_paths.nec_data("hunt_keywords.json")


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def norm(text: str) -> str:
    text = text.replace("\u2019", "'").replace("\u201c", '"').replace("\u201d", '"')
    text = re.sub(r"[^a-z0-9#/.%'\- ]+", " ", text.lower())
    return re.sub(r"\s+", " ", text).strip(" .")


def contains_phrase(haystack: str, needle: str) -> bool:
    """Whole-word containment on normalized text."""
    h, n = norm(haystack), norm(needle)
    if not n:
        return False
    return re.search(r"(?<![a-z0-9])" + re.escape(n) + r"(?![a-z0-9])", h) is not None


def contains_word_start(haystack: str, needle: str) -> bool:
    """Like contains_phrase, but the needle may start a longer word: 'connector' in 'pressure connectors', 'lock' in 'lockable'."""
    h, n = norm(haystack), norm(needle)
    if len(n) < 3:
        return contains_phrase(haystack, needle)
    return re.search(r"(?<![a-z0-9])" + re.escape(n), h) is not None


def names_location(text: str) -> bool:
    return LOCATION_RE.search(text) is not None


def cited_articles(reference: str, article_titles: dict) -> list[str]:
    """NEC articles a record cites, in order: '352.100, 352.12(B)' -> ['352']."""
    reference = reference.strip()
    if STATE_LAW_RE.search(reference):
        return []
    found: list[str] = []
    for m in ARTICLE_RE.finditer(reference):
        number = m.group(1)
        if number in article_titles and number not in found:
            found.append(number)
    if re.search(r"\bChapter\s+9\b", reference) and CHAPTER_9 not in found:
        if re.match(r"^(?:Table\s+\d+,\s*)?Chapter\s+9|^Chapter 9", reference):
            found.insert(0, CHAPTER_9)
        else:
            found.append(CHAPTER_9)
    return found


def citation_for(reference: str, article: str) -> str:
    """The first citation of `article` in the reference: '210.52(E)(3)', 'Table 4' (Chapter 9); '' for a whole article."""
    if article == CHAPTER_9:
        m = CHAPTER_9_RE.search(reference)
        return m.group(1) if m else ""
    for m in CITATION_RE.finditer(reference):
        text = m.group(0)
        if text.startswith("Article"):
            continue
        if section_of(text).split(".")[0] == article:
            return text
    return ""


def section_of(citation: str) -> str:
    """'Table 210.21(B)(2)' -> '210.21'."""
    m = re.search(r"\d{3}\.\d+", citation)
    return m.group(0) if m else ""


def no_lookup_reason(record: dict, cited: list[str]) -> str:
    if record.get("section"):
        return "state law (not in the NEC)"
    if cited:
        return ""
    reference = str(record.get("article", "")).strip()
    if "70E" in reference:
        return "NFPA 70E (not in the NEC)"
    if "calculation" in reference.lower():
        return "math (nothing to look up)"
    return "trade knowledge (not in the NEC)"


def correct_text(record: dict) -> str:
    answers = record.get("answers", [])
    idx = int(record.get("correct_index", -1))
    return str(answers[idx]) if 0 <= idx < len(answers) else ""


def phrase_regex(phrase: str) -> re.Pattern:
    body = r"\s+".join(re.escape(part) for part in phrase.split())
    return re.compile(r"(?<![" + WORD_EDGE + r"])" + body + r"(?![" + WORD_EDGE + r"])", re.IGNORECASE)


def leaks(record: dict, text: str, heading: str, synonyms: list[str]) -> str:
    """Why a keyword would give the answer away, or '' when it is safe. `heading` is the main entry and subentry."""
    answer = correct_text(record)
    if not norm(answer):
        return ""
    others = [str(a) for i, a in enumerate(record.get("answers", [])) if i != int(record.get("correct_index", -1))]
    if contains_word_start(text, answer):
        return "keyword contains the correct choice"
    if contains_phrase(answer, text) and not all(contains_phrase(o, text) for o in others):
        return "keyword is part of the correct choice"
    if contains_word_start(heading, answer):
        return "Index heading names the correct choice"
    for phrase in synonyms:
        if contains_phrase(answer, phrase) and not all(contains_phrase(o, phrase) for o in others):
            return "correct choice is a synonym of the keyword"
    choices = [str(a) for a in record.get("answers", []) if norm(str(a))]
    for choice in choices:
        if all(contains_phrase(c, choice) for c in choices):
            continue
        if contains_phrase(text, choice):
            return f"keyword holds the choice {choice!r}"
        if contains_phrase(heading, choice):
            return f"Index heading names the choice {choice!r}"
    return ""


def heading_text(index: str, sub: str) -> str:
    return index + (" " + sub if sub else "")


def excluded(prompt: str, start: int) -> bool:
    """The phrase at `start` follows 'other than' in the same clause ('In other than one and two family dwellings')."""
    before = prompt[max(0, start - OTHER_THAN_REACH):start].lower()
    at = before.rfind("other than")
    return at >= 0 and not re.search(r"[,;:.]", before[at:])


def find_matches(prompt: str, terms: list[dict]) -> list[dict]:
    """Every term phrase in the stem; the longest wins an overlap. A phrase right
    after 'other than' is what the rule leaves out, not what to look up."""
    hits = []
    for term in terms:
        for phrase in term["match"]:
            for m in phrase_regex(phrase).finditer(prompt):
                if excluded(prompt, m.start()):
                    continue
                hits.append({"start": m.start(), "end": m.end(), "text": m.group(0), "term": term})
    hits.sort(key=lambda h: (-(h["end"] - h["start"]), h["start"]))
    taken: list[dict] = []
    for hit in hits:
        if any(hit["start"] < t["end"] and t["start"] < hit["end"] for t in taken):
            continue
        taken.append(hit)
    taken.sort(key=lambda h: h["start"])
    return taken


def section_sub(subs: dict, section: str) -> str:
    """The subentry keyed by the longest section prefix of `section` ('210.52' for 210.52), or ''."""
    best = ""
    for key in subs:
        if "." in key and section.startswith(key) and not section[len(key):len(key) + 1].isdigit() and len(key) > len(best):
            best = key
    return subs[best] if best else ""


def route(term: dict, article: str, reference: str):
    """(subentry, via_home) when the term leads to `article` for this reference; None when it does not."""
    subs = term.get("subs", {})
    section = section_of(citation_for(reference, article))
    sub = section_sub(subs, section) or subs.get(article, "")
    if article in term.get("articles", []):
        return (sub or subs.get("*", ""), True)
    return (sub, False) if sub else None


def keywords_for(record: dict, cited: list[str], terms: list[dict], override: dict) -> tuple[list[dict], int]:
    prompt = str(record.get("prompt", ""))
    reference = str(record.get("article", ""))
    dropped = {norm(t) for t in override.get("drop", [])}
    by_index = {}
    for term in terms:
        by_index.setdefault(term["index"], term)
    candidates = []
    for add in override.get("add", []):
        if add.get("definition"):
            if DEFINITIONS in cited and not leaks(record, add["text"], "", []):
                candidates.append({"entry": {"text": add["text"], "index": "", "article": DEFINITIONS, "definition": True},
                                   "score": (3, 0, 0)})
            continue
        term = by_index.get(add["index"], {})
        if "sub" in add or not term:
            sub = add.get("sub", "")
        else:
            sub = (route(term, add["article"], reference) or ("", True))[0]
        if leaks(record, add["text"], heading_text(add["index"], sub), []):
            continue
        entry = {"text": add["text"], "index": add["index"], "sub": sub, "article": add["article"]}
        candidates.append({"entry": entry, "score": (2, 0, len(add["text"]))})
    for hit in find_matches(prompt, terms):
        term = hit["term"]
        if norm(hit["text"]) in dropped:
            continue
        found = None
        if cited[0] == DEFINITIONS:
            found = (DEFINITIONS, "definition", True)
        else:
            for article in cited:
                way = route(term, article, reference)
                if way is not None:
                    found = (article, way[0], way[1])
                    break
        if found is None:
            continue
        article, sub, via_home = found
        if leaks(record, hit["text"], heading_text(term["index"], sub), term["match"]):
            continue
        entry = {"text": hit["text"], "index": term["index"], "sub": sub, "article": article}
        if norm(hit["text"]) in {norm(u) for u in term.get("unlisted", [])}:
            entry["try"] = True
        breadth = len(term.get("articles", [])) + len(term.get("subs", {}))
        lead = 2 if article == cited[0] else 1
        candidates.append({"entry": entry, "score": (lead if via_home else lead - 0.5, -breadth, len(hit["text"]))})
    chosen: list[dict] = []
    for cand in candidates:
        entry = cand["entry"]
        if any((c["entry"].get("index"), c["entry"].get("sub")) == (entry.get("index"), entry.get("sub"))
               or c["entry"].get("definition") and entry.get("definition")
               or overlaps(prompt, c["entry"]["text"], entry["text"]) for c in chosen):
            continue
        chosen.append(cand)
        if len(chosen) == MAX_KEYWORDS:
            break
    if not chosen:
        return [], -1
    best = max(chosen, key=lambda c: c["score"])
    chosen.sort(key=lambda c: prompt.find(c["entry"]["text"]))
    out = []
    for c in chosen:
        e = dict(c["entry"])
        if not e.get("sub"):
            e.pop("sub", None)
        out.append(e)
    return out, chosen.index(best)


def overlaps(prompt: str, a: str, b: str) -> bool:
    """The app colors the first occurrence of each keyword, so those spans must not touch."""
    sa, sb = prompt.find(a), prompt.find(b)
    return sa < sb + len(b) and sb < sa + len(a)


def generate(bank: dict, vocab: dict, article_titles: dict) -> dict:
    terms = vocab["terms"]
    overrides = vocab.get("records", {})
    records, no_lookup = {}, {}
    for record in bank["records"]:
        rid = record["id"]
        cited = cited_articles(str(record.get("article", "")), article_titles)
        reason = no_lookup_reason(record, cited)
        if reason:
            no_lookup[rid] = reason
            continue
        override = overrides.get(rid, {})
        if override.get("none"):
            records[rid] = {"keywords": [], "none": override["none"]}
            continue
        keywords, primary = keywords_for(record, cited, terms, override)
        entry = {"keywords": keywords}
        if keywords:
            entry["primary"] = primary
        records[rid] = entry
    return {
        "about": "Generated by tools/pipeline/hunt_keywords.py from data/question_bank.json and index_terms.json; do not edit. "
                 "Per record: the stem phrases to look up in the code book's Index ('text', exact stem text), the main entry "
                 "('index') and subentry ('sub') in our own words, the article they lead to ('article'), 'try' when the stem "
                 "word is not Index wording, 'definition' when the term is read in Article 100 rather than the Index; "
                 "'primary' is the keyword to start with. Shown before answering only, never the article.",
        "records": records,
        "no_lookup": no_lookup,
    }


def render(data: dict) -> str:
    lines = ["{", "\t\"about\": " + json.dumps(data["about"], ensure_ascii=False) + ",", "\t\"records\": {"]
    items = list(data["records"].items())
    for i, (rid, entry) in enumerate(items):
        comma = "," if i < len(items) - 1 else ""
        lines.append("\t\t" + json.dumps(rid, ensure_ascii=False) + ": " + json.dumps(entry, ensure_ascii=False) + comma)
    lines.append("\t},")
    lines.append("\t\"no_lookup\": " + json.dumps(data["no_lookup"], ensure_ascii=False, indent="\t").replace("\n", "\n\t"))
    lines.append("}")
    return "\n".join(lines) + "\n"


def leads_there(keyword: dict, record: dict, terms: list[dict], override: dict) -> bool:
    """The keyword's main entry (and subentry) really lead to its article."""
    if keyword.get("definition"):
        return keyword.get("article") == DEFINITIONS
    reference = str(record.get("article", ""))
    if keyword.get("article") == DEFINITIONS and keyword.get("sub") == "definition":
        return True
    for term in terms:
        if term["index"] != keyword.get("index"):
            continue
        way = route(term, keyword.get("article", ""), reference)
        if way is not None and way[0] == keyword.get("sub", ""):
            return True
    return any(a.get("index") == keyword.get("index") and a.get("article") == keyword.get("article")
               for a in override.get("add", []))


def problems(data: dict, bank: dict, article_titles: dict, vocab: dict | None = None) -> list[str]:
    """Every rule the written file must meet (the leak rules included)."""
    vocab = vocab if vocab is not None else load_json(terms_path())
    out: list[str] = []
    by_id = {r["id"]: r for r in bank["records"]}
    listed = set(data.get("records", {})) | set(data.get("no_lookup", {}))
    for rid in by_id:
        if rid not in listed:
            out.append(f"{rid}: not in hunt_keywords.json")
    for rid in listed:
        if rid not in by_id:
            out.append(f"{rid}: not in the bank")
    for rid, entry in data.get("records", {}).items():
        record = by_id.get(rid)
        if record is None:
            continue
        cited = cited_articles(str(record.get("article", "")), article_titles)
        keywords = entry.get("keywords", [])
        override = vocab.get("records", {}).get(rid, {})
        if entry.get("none"):
            if keywords:
                out.append(f"{rid}: marked none ({entry['none']}) but has keywords")
        elif not 1 <= len(keywords) <= MAX_KEYWORDS:
            out.append(f"{rid}: {len(keywords)} keywords (want 1-{MAX_KEYWORDS})")
        if keywords and not 0 <= entry.get("primary", -1) < len(keywords):
            out.append(f"{rid}: no primary keyword")
        prompt = str(record.get("prompt", ""))
        for i, kw in enumerate(keywords):
            for other in keywords[i + 1:]:
                if overlaps(prompt, kw.get("text", ""), other.get("text", "")):
                    out.append(f"{rid}: keywords {kw.get('text')!r} and {other.get('text')!r} overlap")
            text, article = kw.get("text", ""), kw.get("article", "")
            heading = heading_text(kw.get("index", ""), kw.get("sub", ""))
            if not text or text not in prompt:
                out.append(f"{rid}: keyword {text!r} is not in the stem")
            reason = leaks(record, text, heading, [])
            if reason:
                out.append(f"{rid}: keyword {text!r}: {reason}")
            if names_location(heading):
                out.append(f"{rid}: keyword {text!r}: '{heading}' names a location before answering")
            if article != CHAPTER_9 and article not in article_titles:
                out.append(f"{rid}: article {article!r} is not in the edition's articles.json")
            if article not in cited:
                out.append(f"{rid}: article {article!r} is not cited by the record ({record.get('article')})")
            if not leads_there(kw, record, vocab["terms"], override):
                out.append(f"{rid}: '{heading}' does not lead to {article}")
    return out


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--check", action="store_true", help="fail when the file is stale or breaks a rule")
    ap.add_argument("--bank", type=Path, default=BANK_PATH)
    args = ap.parse_args(argv)
    bank = load_json(args.bank)
    vocab = load_json(terms_path())
    article_titles = load_json(pipeline_paths.nec_data("articles.json"))["articles"]
    fresh = render(generate(bank, vocab, article_titles))
    out = output_path()
    if args.check:
        current = out.read_text(encoding="utf-8") if out.exists() else ""
        errors = problems(json.loads(current), bank, article_titles, vocab) if current else [f"{out} is missing"]
        if current != fresh:
            errors.append(f"{out.relative_to(ROOT)} is stale: run python tools/pipeline/hunt_keywords.py and review the diff")
        for e in errors:
            print("HUNT:", e)
        print(f"hunt keywords: {'OK' if not errors else str(len(errors)) + ' problem(s)'}")
        return 1 if errors else 0
    out.write_text(fresh, encoding="utf-8", newline="\n")
    data = json.loads(fresh)
    errors = problems(data, bank, article_titles, vocab)
    counts = [len(e["keywords"]) for e in data["records"].values()]
    print(f"wrote {out.relative_to(ROOT)}: {len(counts)} records with keywords ({sum(counts)} keywords), "
          f"{sum(1 for c in counts if c == 0)} without, {len(data['no_lookup'])} no_lookup; {len(errors)} problem(s)")
    for e in errors:
        print("HUNT:", e)
    return 0


if __name__ == "__main__":
    sys.exit(main(argv=None))
