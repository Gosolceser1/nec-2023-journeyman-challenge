#!/usr/bin/env bash
#
# THE data pipeline for this project. One command, in order:
#
#   1. OCR   source PDFs  -> text       (tools/ocr_pdfs_tesseract.py)
#   2. OCR   answer keys  -> text       (tools/ocr_answer_keys_tesseract.py)
#   3. BUILD text         -> bank JSON  (tools/build_question_bank.py)
#   4. VALIDATE bank JSON                (tools/validate_question_bank.py)   <-- GATE
#   5. SPEECH bank JSON   -> mp3 clips   (tools/dump_speech.gd + pregenerate_speech.py)
#
# Step 4 is the gate. Steps 3-5 refuse to continue on an invalid bank, which is
# the whole point: question_bank.json is GENERATED, so every hand-edit is lost
# on the next build and every regression used to ship silently. There was no
# validation step between the builder and the repo until this script existed.
#
# Usage:
#   bash tools/build_question_bank.sh --validate
#   WIRE_BANK_OUT=/path/to/candidate.json bash tools/build_question_bank.sh --build
#   WIRE_BANK_OUT=/path/to/candidate.json bash tools/build_question_bank.sh --full
#   WIRE_BANK_OUT=/path/to/candidate.json bash tools/build_question_bank.sh --no-speech
#
# Rebuilds always write to a separate candidate path; the checked-in bank is
# protected so an unreviewed candidate cannot replace the curated question set.
#
# Env overrides:
#   WIRE_OCR_PATH   directory of OCR'd exam text      (default: %TEMP%/opencode/wire_ocr)
#   WIRE_OCR_KEYS   directory of OCR'd answer keys   (default: %TEMP%/opencode/wire_ocr_keys)
#   WIRE_BANK_OUT   output bank path                 (default: <repo>/question_bank.json)
#   PYTHON          interpreter to use               (default: python)
#   GODOT           Godot console binary             (default: <repo>/Godot_v4.7.2-stable_win64_console.exe)
#
# Exit codes: 0 = bank valid, 1 = a step failed or the bank is invalid.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# MSYS path translation is disabled for native Windows programs, so a
# /c/Users/... path reaches python.exe verbatim and fails. Normalise to
# C:/... form, which git-bash, python and Godot all accept.
if command -v cygpath >/dev/null 2>&1; then
  winpath() { cygpath -m "$1"; }
elif command -v wslpath >/dev/null 2>&1 && [[ "${PYTHON:-python}" == *.exe ]]; then
  # WSL bash driving Windows python.exe (what verify.sh picks there).
  winpath() { case "$1" in /mnt/*) wslpath -m "$1" ;; *) printf '%s\n' "$1" ;; esac; }
else
  winpath() { case "$1" in
    /[A-Za-z]/*) printf '%s:%s\n' "$(printf '%s' "$1" | cut -c2)" "$(printf '%s' "$1" | cut -c4-)" ;;
    *) printf '%s\n' "$1" ;;
  esac; }
fi

PY="${PYTHON:-python}"
ROOT_W="$(winpath "$ROOT")"
BANK="${WIRE_BANK_OUT:-$ROOT/question_bank.json}"
BANK="${BANK//\\//}"
case "$BANK" in
  /*|[A-Za-z]:/*) ;;
  *) BANK="$ROOT/$BANK" ;;
esac
BANK_W="$(winpath "$BANK")"
GODOT="${GODOT:-$ROOT/Godot_v4.7.2-stable_win64_console.exe}"
GODOT_W="$(winpath "$GODOT")"
BUILDER_W="$(winpath "$ROOT/tools/build_question_bank.py")"
VALIDATOR_W="$(winpath "$ROOT/tools/validate_question_bank.py")"

MODE="${1:-build}"

say()  { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[33m[warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31m[FATAL]\033[0m %s\n' "$*" >&2; exit 1; }

[ -f "$ROOT/tools/build_question_bank.py" ]   || die "missing builder:   $ROOT/tools/build_question_bank.py"
[ -f "$ROOT/tools/validate_question_bank.py" ] || die "missing validator: $ROOT/tools/validate_question_bank.py"

# ---------------------------------------------------------------------------
# The gate. Every path that ships or regenerates a bank runs through here.
# ---------------------------------------------------------------------------
validate() {
  say "VALIDATE $BANK"
  if ! "$PY" "$VALIDATOR_W" --no-warn "$BANK_W"; then
    die "question_bank.json FAILED validation.
    Do NOT hand-edit the bank -- it is generated. Fix the builder
    (tools/build_question_bank.py) or the upstream data, then rebuild:
        bash tools/build_question_bank.sh --build"
  fi
  say "VALIDATION PASSED"
}

require_safe_build_target() {
  local repo_bank_w
  repo_bank_w="$(winpath "$ROOT/question_bank.json")"
  if [ -z "${WIRE_BANK_OUT:-}" ] || [ "$BANK_W" = "$repo_bank_w" ]; then
    die "Refusing to overwrite the curated question_bank.json: builds must target a separate candidate file. Review the candidate before replacing the checked-in bank."
  fi
}

# ---------------------------------------------------------------------------
build() {
  require_safe_build_target
  say "BUILD $BUILDER_W"
  "$PY" "$BUILDER_W"
  [ -f "$BANK" ] || die "builder reported success but $BANK does not exist"
  validate
}

ocr() {
  say "OCR source PDFs"
  "$PY" "$(winpath "$ROOT/tools/ocr_pdfs_tesseract.py")"
  say "OCR answer keys"
  "$PY" "$(winpath "$ROOT/tools/ocr_answer_keys_tesseract.py")"
}

speech() {
  say "SPEECH dump speech plans (headless Godot)"
  [ -f "$GODOT" ] || die "Godot console binary not found: $GODOT"
  "$GODOT_W" --headless --path "$ROOT_W" --script "$(winpath "$ROOT/tools/dump_speech.gd")"
  say "SPEECH pregenerate clips"
  "$PY" "$(winpath "$ROOT/tools/pregenerate_speech.py")" --bundle
  # Exported builds load clips as imported resources, so import the new ones.
  say "SPEECH import clips"
  "$GODOT_W" --headless --path "$ROOT_W" --import
}

case "$MODE" in
  --validate)
    validate
    ;;
  --build)
    build
    ;;
  --no-speech)
    require_safe_build_target
    ocr; build
    ;;
  --full)
    require_safe_build_target
    ocr; build; speech
    warn "speech/ is gitignored and regenerated -- do not commit it"
    ;;
  build)
    build
    ;;
  *)
    die "unknown mode '$MODE' (use --validate | --build | --no-speech | --full)"
    ;;
esac

say "DONE"
