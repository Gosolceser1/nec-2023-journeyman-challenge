"""Parse Tesseract OCR text of an exam PDF and of its answer key.

Question numbers are bounded by the exam's own question count (exam_sources),
never by a fixed cap, so a longer exam keeps its tail; numbers above the count
(page numbers, footers) are ignored. Scan-specific repairs (page headers,
misread words and choice letters) are data in ocr_fixes.json.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

FIXES = json.loads(Path(__file__).with_name("ocr_fixes.json").read_text(encoding="utf-8"))
HEADERS = [re.compile(rx, re.I if ignore_case else 0)
           for rx, ignore_case in zip(FIXES["header_patterns"], FIXES["header_ignore_case"])]


def _number(count: int) -> str:
    # As many digits as the count: "408.36" at a line start is not question 408 of a 70-question exam.
    return r"(\d{1,%d})" % len(str(count))


def _question_start(count: int):
    return re.compile(r"(?m)^\s*[_|:;!]*\s*" + _number(count) + r"[\.,]\s*")


def _key_line(count: int):
    return re.compile(r"(?m)^\s*[_|:;]*\s*" + _number(count) + r"[\.,]?\s*\(([a-d])\)\s*([^\n]*)", re.I)


def normalize(text):
    text = text.replace("\u000c", " ")
    text = re.sub(r"=== PAGE \d+ ===", " ", text, flags=re.I)
    for header in HEADERS:
        text = header.sub(" ", text)
    text = text.replace("|", " ")
    text = re.sub(r"(\w)-\s+(\w)", r"\1\2", text)
    for bad, good in FIXES["replacements"].items():
        text = text.replace(bad, good)
    text = re.sub(r"\s+", " ", text)
    return text.strip(" |\t")


def parse_questions(text: str, count: int) -> dict:
    starts = list(_question_start(count).finditer(text))
    found = {}
    for pos, match in enumerate(starts):
        number = int(match.group(1))
        if not 1 <= number <= count or number in found:
            continue
        block_end = starts[pos + 1].start() if pos + 1 < len(starts) else len(text)
        block = text[match.end():block_end]
        for bad, good in FIXES["option_fixes"]:
            block = block.replace(bad, good)
        for rx, good in FIXES["option_regex_fixes"]:
            block = re.sub(rx, good, block)
        option_matches = list(re.finditer(r"\(([a-d])\)\s*", block, re.I))
        if len(option_matches) < 4:
            continue
        prompt = normalize(block[:option_matches[0].start()])
        choices = []
        for i, option in enumerate(option_matches[:4]):
            end = option_matches[i + 1].start() if i + 1 < len(option_matches[:4]) else len(block)
            choices.append(normalize(block[option.end():end]))
        choices = [re.sub(r"\s*[:;]\s*\d{2,3}\s*$", "", re.sub(r"\s+", " ", choice).strip(" |;:")) for choice in choices]
        choices = [choice if choice else f"Diagram option {chr(65 + i)}" for i, choice in enumerate(choices)]
        if prompt:
            found[number] = {"prompt": prompt, "choices": choices}
    return found


def parse_key(text: str, count: int) -> tuple[dict, dict]:
    answer = {}
    refs = {}
    for match in _key_line(count).finditer(text):
        number = int(match.group(1))
        if 1 <= number <= count and number not in answer:
            answer[number] = ord(match.group(2).lower()) - ord("a")
            tail = normalize(match.group(3))
            references = re.findall(r"(Table\s+\d+(?:\.\d+)?(?:\([A-Z0-9]+\))*|T\.\s*\d+(?:\.\d+)?(?:\([A-Z0-9]+\))*|\d{3}\.\s*\d+(?:\([A-Z0-9]+\))*|DEF\s+100|NFPA\s+70E)", tail, re.I)
            ref = references[-1] if references else "General knowledge"
            refs[number] = re.sub(r"^T\.\s*", "", ref, flags=re.I)
            refs[number] = re.sub(r"(\d{3})\.\s+", r"\1.", refs[number])
    return answer, refs


def read_questions(path: Path, count: int) -> dict:
    return parse_questions(path.read_text(encoding="utf-8", errors="replace"), count)


def read_key(path: Path, count: int) -> tuple[dict, dict]:
    return parse_key(path.read_text(encoding="utf-8", errors="replace"), count)
