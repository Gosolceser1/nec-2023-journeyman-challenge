"""Does a figure show a record's answer before it is answered?

A label leaks record R when it is not under one of R's masks and it states a
value (or the words) of R's correct answer that neither the stem nor any
wrong choice contains. Lengths compare in inches, so "6 1/2 ft" and "78 in"
are the same value. tools/tests/test_diagrams.gd runs the same rule in the
app over the committed labels.
"""
import re

_FRAC = r"(?:\d+\s+\d+/\d+|\d+-\d+/\d+|\d+/\d+|\d+(?:,\d{3})*(?:\.\d+)?|\.\d+)"
_UNIT = (r"(?:inches|inch|in\.?|\"|feet|foot|ft\.?|'|mm|m\b|meters?|percent|%|volts?|v\b|kv\b|"
         r"amperes?|amps?|a\b|va\b|kva\b|kw\b|w\b|watts?|degrees?|hz\b|ohms?|awg)")
_NUM_RE = re.compile(rf"(?<![\w.])({_FRAC})\s*({_UNIT})?", re.I)
_FT_IN_RE = re.compile(rf"(?<![\w.])({_FRAC})\s*(?:feet|foot|ft\.?|')\s*,?\s*({_FRAC})\s*(?:inches|inch|in\.?|\")", re.I)
_NO_RE = re.compile(r"(?:no\.|#)\s*(\d+(?:/0)?)", re.I)

STOP = {"a", "an", "the", "of", "to", "and", "or", "in", "on", "at", "for", "is", "be", "by", "with",
        "shall", "not", "all", "above", "none", "both", "only", "any", "each", "from", "than",
        "these", "those", "this", "that", "below", "following", "of"}


def _num(s):
    s = s.replace(",", "").strip()
    m = re.fullmatch(r"(\d+)[\s-]+(\d+)/(\d+)", s)
    if m:
        return int(m[1]) + int(m[2]) / int(m[3])
    m = re.fullmatch(r"(\d+)/(\d+)", s)
    if m:
        return int(m[1]) / int(m[2])
    return float(s)


def _unit_kind(u):
    u = (u or "").lower().rstrip(".")
    if u in ("inches", "inch", "in", '"'):
        return "len", 1.0
    if u in ("feet", "foot", "ft", "'"):
        return "len", 12.0
    if u == "mm":
        return "len", 1 / 25.4
    if u in ("m", "meter", "meters"):
        return "len", 39.37
    if u in ("percent", "%"):
        return "pct", 1.0
    if u in ("v", "volt", "volts"):
        return "V", 1.0
    if u == "kv":
        return "V", 1000.0
    if u in ("a", "amp", "amps", "ampere", "amperes"):
        return "A", 1.0
    if u in ("va",):
        return "VA", 1.0
    if u == "kva":
        return "VA", 1000.0
    if u in ("w", "watt", "watts"):
        return "W", 1.0
    if u == "kw":
        return "W", 1000.0
    if u in ("degree", "degrees"):
        return "deg", 1.0
    if u == "hz":
        return "Hz", 1.0
    if u in ("ohm", "ohms"):
        return "ohm", 1.0
    if u == "awg":
        return "awg", 1.0
    return "n", 1.0


def values(text):
    """{(kind, value)} stated in text; bare numbers are ('n', v)."""
    out = set()
    t = str(text)
    spans = []
    for m in _FT_IN_RE.finditer(t):
        out.add(("len", round(_num(m[1]) * 12 + _num(m[2]), 4)))
        spans.append(m.span())
    for m in _NO_RE.finditer(t):
        out.add(("awg", m[1].replace("/0", "0/")))
    for m in _NUM_RE.finditer(t):
        if any(a <= m.start() < b for a, b in spans):
            continue
        try:
            v = _num(m[1])
        except ValueError:
            continue
        kind, k = _unit_kind(m[2])
        if kind == "awg":
            out.add(("awg", m[1]))
            continue
        out.add((kind, round(v * k, 4)))
        if kind != "n":
            out.add(("n", round(v, 4)))
    return out


def words(text):
    return [w for w in re.findall(r"[a-z0-9]+", str(text).lower()) if w not in STOP]


def answer_keys(record, extra_terms=()):
    """(values, phrases) that would give record's answer away."""
    answers = record.get("answers", [])
    ci = int(record.get("correct_index", -1))
    if not (0 <= ci < len(answers)):
        return set(), []
    correct = str(answers[ci])
    given = values(record.get("prompt", ""))
    others = set()
    for i, a in enumerate(answers):
        if i != ci:
            others |= values(a)
    vals = {v for v in values(correct) if v not in given and v not in others}
    # A bare number only counts when the answer is unit-less (a count, a size).
    if any(k != "n" for k, _ in vals):
        vals = {v for v in vals if v[0] != "n"}
    phrases = []
    w = words(correct)
    other_words = set()
    for i, a in enumerate(answers):
        if i != ci:
            other_words |= set(words(a))
    keywords = []
    if w and not values(correct) and len(" ".join(w)) >= 5:
        stem_words = set(words(record.get("prompt", "")))
        distinct = [x for x in w if x not in other_words]
        if distinct:
            phrases.append(" ".join(w))
        keywords = [x for x in distinct if len(x) >= 5 and x not in stem_words and not x.isdigit()]
    phrases += [str(p).lower() for p in extra_terms]
    return vals, phrases, keywords


def _center_in(box, rect):
    cx, cy = box[0] + box[2] / 2, box[1] + box[3] / 2
    return rect[0] <= cx <= rect[0] + rect[2] and rect[1] <= cy <= rect[1] + rect[3]


def _overlap(box, rect):
    ix = max(0.0, min(box[0] + box[2], rect[0] + rect[2]) - max(box[0], rect[0]))
    iy = max(0.0, min(box[1] + box[3], rect[1] + rect[3]) - max(box[1], rect[1]))
    area = max(1e-9, box[2] * box[3])
    return ix * iy / area


def covered(box, masks):
    return any(_center_in(box, m["rect"]) and _overlap(box, m["rect"]) >= 0.6 for m in masks)


def leaks(record, labels, masks, extra_terms=()):
    """Labels ([text, x, y, w, h], unit rects) that give record's answer away."""
    vals, phrases, keywords = answer_keys(record, extra_terms)
    out = []
    for text, *box in labels:
        if covered(box, masks):
            continue
        lv = values(text)
        hit = sorted(str(v) for v in vals & lv)
        lw = words(text)
        low = " ".join(lw)
        for p in phrases:
            pw = " ".join(words(p)) or p
            if pw and re.search(rf"(?<![a-z0-9]){re.escape(pw)}(?![a-z0-9])", low):
                hit.append(p)
        hit += [k for k in keywords if k in lw]
        if hit:
            out.append((text, hit))
    return out
