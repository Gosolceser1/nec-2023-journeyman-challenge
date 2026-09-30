"""Hunt keywords: the stem words to look up in the code book's Index.

Reads the checked-in bank and the edition's curated vocabulary
(data/nec/<year>/index_terms.json) and writes data/nec/<year>/hunt_keywords.json,
which the app uses to color those words in the stem and to name the Index
heading to open. The bank itself is not changed: every keyword is an exact
phrase of its stem.

    python tools/pipeline/hunt_keywords.py            # write the file
    python tools/pipeline/hunt_keywords.py --check    # fail when it is stale or breaks a rule

Rules (also checked by --check on the written file):
- only records that cite the NEC get keywords (1 to MAX_KEYWORDS each); the
  others are listed under no_lookup with the reason;
- a keyword is a phrase of the stem, is not the correct choice, does not contain
  it and is not part of it (unless every choice holds it); its Index heading does
  not name the correct choice;
- neither the keyword nor its Index heading holds any choice, distractors
  included ('rear or side access' colors the choice 'rear');
- its article is one the record cites and exists in the edition's articles.json;
- show_article is false when the stem asks for the reference itself or the
  correct choice holds the article number (the hint then names the heading only).
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
STATE_LAW_RE = re.compile(r"^(?:Neb\. Rev\. Stat\.|Title \d+ NAC\b)")
ARTICLE_RE = re.compile(r"(?<![\d.])(\d{3})(?![\d])")
WORD_EDGE = r"A-Za-z0-9\-"


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


CITATION_ANSWER = re.compile(r"^(?:NEC\s+)?(?:(?:Article|Table|Section)\s+\S|\d{3}\.\d+(?:\([A-Za-z0-9]+\))*$)")


def is_reference_seeking(prompt: str, answers: list | None = None) -> bool:
    """Same test as NecReference.is_reference_seeking in the app."""
    lowered = prompt.lower()
    if "___" in lowered and any(w in lowered for w in ("table", "article", "section")):
        return True
    return sum(1 for a in answers or [] if CITATION_ANSWER.search(str(a).strip())) >= 2


def show_article(record: dict, cited: list[str]) -> bool:
    if is_reference_seeking(str(record.get("prompt", "")), record.get("answers", [])):
        return False
    answer = correct_text(record)
    for article in cited:
        token = "9" if article == CHAPTER_9 else article
        if re.search(r"(?<![\d.])" + re.escape(token) + r"(?![\d])", answer):
            return False
    return True


def correct_text(record: dict) -> str:
    answers = record.get("answers", [])
    idx = int(record.get("correct_index", -1))
    return str(answers[idx]) if 0 <= idx < len(answers) else ""


def phrase_regex(phrase: str) -> re.Pattern:
    body = r"\s+".join(re.escape(part) for part in phrase.split())
    return re.compile(r"(?<![" + WORD_EDGE + r"])" + body + r"(?![" + WORD_EDGE + r"])", re.IGNORECASE)


def leaks(record: dict, text: str, heading: str, synonyms: list[str]) -> str:
    """Why a keyword would give the answer away, or '' when it is safe."""
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


def find_matches(prompt: str, terms: list[dict]) -> list[dict]:
    """Every term phrase in the stem; the longest wins an overlap."""
    hits = []
    for term in terms:
        for phrase in term["match"]:
            for m in phrase_regex(phrase).finditer(prompt):
                hits.append({"start": m.start(), "end": m.end(), "text": m.group(0), "term": term})
    hits.sort(key=lambda h: (-(h["end"] - h["start"]), h["start"]))
    taken: list[dict] = []
    for hit in hits:
        if any(hit["start"] < t["end"] and t["start"] < hit["end"] for t in taken):
            continue
        taken.append(hit)
    taken.sort(key=lambda h: h["start"])
    return taken


def keywords_for(record: dict, cited: list[str], terms: list[dict], override: dict) -> list[dict]:
    prompt = str(record.get("prompt", ""))
    primary = cited[0]
    dropped = {norm(t) for t in override.get("drop", [])}
    specific, broad = [], []
    for hit in find_matches(prompt, terms):
        term = hit["term"]
        if norm(hit["text"]) in dropped:
            continue
        if primary == "100":
            article = "100"
        elif term.get("broad"):
            if primary == CHAPTER_9 or primary not in term.get("seen_in", [primary]):
                continue
            article = primary
        else:
            usable = [a for a in term["articles"] if a in cited]
            if not usable:
                continue
            article = primary if primary in usable else usable[0]
        if leaks(record, hit["text"], term["index"], term["match"]):
            continue
        entry = {"text": hit["text"], "index": term["index"], "article": article}
        (broad if term.get("broad") else specific).append(entry)
    chosen: list[dict] = []
    for entry in list(override.get("add", [])) + specific + broad:
        if any(c["index"] == entry["index"] or overlaps(prompt, c["text"], entry["text"]) for c in chosen):
            continue
        chosen.append({"text": entry["text"], "index": entry["index"], "article": entry["article"]})
        if len(chosen) == MAX_KEYWORDS:
            break
    chosen.sort(key=lambda e: prompt.find(e["text"]))
    return chosen


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
        entry = {
            "keywords": [] if override.get("none") else keywords_for(record, cited, terms, override),
            "show_article": show_article(record, cited),
        }
        if override.get("none"):
            entry["none"] = override["none"]
        records[rid] = entry
    return {
        "about": "Generated by tools/pipeline/hunt_keywords.py from data/question_bank.json and index_terms.json; do not edit. Per record: the stem phrases to look up in the code book's Index ('text', exact stem text), the Index heading ('index') and the article it leads to ('article'); show_article false hides the article before answering.",
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


def problems(data: dict, bank: dict, article_titles: dict) -> list[str]:
    """Every rule the written file must meet (the leak rules included)."""
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
        if entry.get("none"):
            if keywords:
                out.append(f"{rid}: marked none ({entry['none']}) but has keywords")
        elif not 1 <= len(keywords) <= MAX_KEYWORDS:
            out.append(f"{rid}: {len(keywords)} keywords (want 1-{MAX_KEYWORDS})")
        prompt = str(record.get("prompt", ""))
        for i, kw in enumerate(keywords):
            for other in keywords[i + 1:]:
                if overlaps(prompt, kw.get("text", ""), other.get("text", "")):
                    out.append(f"{rid}: keywords {kw.get('text')!r} and {other.get('text')!r} overlap")
            text, heading, article = kw.get("text", ""), kw.get("index", ""), kw.get("article", "")
            if not text or text not in prompt:
                out.append(f"{rid}: keyword {text!r} is not in the stem")
            reason = leaks(record, text, heading, [])
            if reason:
                out.append(f"{rid}: keyword {text!r}: {reason}")
            if article != CHAPTER_9 and article not in article_titles:
                out.append(f"{rid}: article {article!r} is not in the edition's articles.json")
            if article not in cited:
                out.append(f"{rid}: article {article!r} is not cited by the record ({record.get('article')})")
        if entry.get("show_article") and not show_article(record, cited):
            out.append(f"{rid}: show_article must be false (the stem asks for the reference or the answer holds the article)")
    return out


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--check", action="store_true", help="fail when the file is stale or breaks a rule")
    ap.add_argument("--bank", type=Path, default=BANK_PATH)
    args = ap.parse_args(argv)
    bank = load_json(args.bank)
    article_titles = load_json(pipeline_paths.nec_data("articles.json"))["articles"]
    fresh = render(generate(bank, load_json(terms_path()), article_titles))
    out = output_path()
    if args.check:
        current = out.read_text(encoding="utf-8") if out.exists() else ""
        errors = problems(json.loads(current), bank, article_titles) if current else [f"{out} is missing"]
        if current != fresh:
            errors.append(f"{out.relative_to(ROOT)} is stale: run python tools/pipeline/hunt_keywords.py and review the diff")
        for e in errors:
            print("HUNT:", e)
        print(f"hunt keywords: {'OK' if not errors else str(len(errors)) + ' problem(s)'}")
        return 1 if errors else 0
    out.write_text(fresh, encoding="utf-8", newline="\n")
    data = json.loads(fresh)
    errors = problems(data, bank, article_titles)
    counts = [len(e["keywords"]) for e in data["records"].values()]
    print(f"wrote {out.relative_to(ROOT)}: {len(counts)} records with keywords ({sum(counts)} keywords), "
          f"{sum(1 for c in counts if c == 0)} without, {len(data['no_lookup'])} no_lookup; {len(errors)} problem(s)")
    for e in errors:
        print("HUNT:", e)
    return 0


if __name__ == "__main__":
    sys.exit(main())
