#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
EXPECTED='Refusing to overwrite the curated question_bank.json'

before="$(sha256sum data/question_bank.json | cut -d ' ' -f1)"
expect_refusal() {
  local label="$1"; shift
  local output
  if output=$("$@" 2>&1); then
    printf 'FAIL: build guard allowed %s\n' "$label" >&2
    exit 1
  fi
  if [[ "$output" != *"$EXPECTED"* ]]; then
    printf 'FAIL: %s failed for the wrong reason:\n%s\n' "$label" "$output" >&2
    exit 1
  fi
}

for mode in --build --no-speech --full; do
  expect_refusal "default output with $mode" env -u WIRE_BANK_OUT bash tools/pipeline/build_question_bank.sh "$mode"
done

for target in data/question_bank.json "$ROOT/data/question_bank.json" "${ROOT//\//\\}\\data\\question_bank.json"; do
  expect_refusal "repo target '$target'" env WIRE_BANK_OUT="$target" bash tools/pipeline/build_question_bank.sh --build
done

after="$(sha256sum data/question_bank.json | cut -d ' ' -f1)"
if [[ "$before" != "$after" ]]; then
  printf 'FAIL: refused build changed question_bank.json\n' >&2
  exit 1
fi

printf 'PASS: build guard refuses in-place rebuilds; curated bank unchanged\n'
