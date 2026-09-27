#!/usr/bin/env bash
# Single entry point: verify the project is healthy.
#
#   ./tools/verify.sh
#
# Runs, in order:
#   1. GDScript parse check (catches syntax errors without booting)
#   2. Unit tests for pure logic  (fast, no scene)
#   3. Scene harness, desktop layout
#   4. Scene harness, mobile layout
#   5. Question bank schema validation
#
# Exit 0 = all green. Non-zero = the first failing stage, with its output.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="$ROOT/Godot_v4.7.2-stable_win64_console.exe"

# Godot spews harmless static-string/NavMesh teardown noise on exit.
NOISE='Unreferenced static string|string_name\.cpp:|NavMeshGeometryParser|PagedAllocator'
FAILED=0

stage() {
  local name="$1"; shift
  echo ""
  echo "──────────────────────────────────────────────────────────────"
  echo "  $name"
  echo "──────────────────────────────────────────────────────────────"
  if "$@" 2>&1 | grep -vE "$NOISE"; then
    return 0
  fi
  # Pipeline exit code is grep's; re-run the command to get the real status.
  if "$@" >/dev/null 2>&1; then
    return 0
  fi
  echo "  ✗ STAGE FAILED: $name"
  FAILED=1
  return 1
}

if [ ! -x "$GODOT" ] && [ ! -f "$GODOT" ]; then
  echo "Godot not found at: $GODOT"
  echo "Set GODOT=/path/to/Godot_v4.x-stable_win64_console.exe"
  exit 127
fi

cd "$ROOT" || exit 1

# 1. Parse every script without booting the app.
parse_check() {
  local rc=0
  for f in main.gd speech_text.gd speech_rules.gd audio_explanation_generator.gd table_viewer.gd \
           unit_matcher.gd answer_card.gd voice_visualizer.gd audio_settings.gd diagram_view.gd \
           fx/ui_fx.gd fx/time_gauge.gd fx/streak_meter.gd fx/result_gauge.gd \
           fx/chapter_bars.gd fx/mode_badge.gd fx/sfx.gd fx/speech_chain.gd speech_helper.gd; do
    out=$("$GODOT" --headless --path . --check-only --script "$f" 2>&1 | grep -vE "$NOISE")
    if printf '%s' "$out" | grep -qiE "SCRIPT ERROR|Parse Error"; then
      echo "  ✗ $f failed to parse:"
      printf '%s\n' "$out" | head -5
      rc=1
    fi
  done
  [ $rc -eq 0 ] && echo "  all scripts parse cleanly"
  return $rc
}

# 2. Pure-logic unit tests, if present.
unit_tests() {
  if [ ! -f tools/tests/run_all.gd ]; then
    echo "  (no tools/tests/run_all.gd yet — skipping)"
    return 0
  fi
  "$GODOT" --headless --path . --script tools/tests/run_all.gd
  return $?
}

scene_harness() {
  local mode="${1:-}"
  if [ -n "$mode" ]; then
    "$GODOT" --headless --path . --script tools/harness.gd -- --mobile-ui
  else
    "$GODOT" --headless --path . --script tools/harness.gd
  fi
  return $?
}

bank_validate() {
  if ! command -v python >/dev/null 2>&1; then
    echo "  (python not found — skipping bank validation)"
    return 0
  fi
  if [ ! -f tools/validate_question_bank.py ]; then
    echo "  (no validator yet — skipping)"
    return 0
  fi
  bash tools/tests/test_build_guard.sh || return $?
  python -m unittest tools.tests.test_validate_question_bank tools.tests.test_spellcheck_bank tools.tests.test_speak_question || return $?
  python tools/spellcheck_bank.py --offline || return $?
  python tools/validate_question_bank.py --no-warn
  return $?
}

stage "1/5  Parse check"            parse_check      || true
stage "2/5  Unit tests"             unit_tests       || true
stage "3/5  Scene harness (desktop)" scene_harness "" || true
stage "4/5  Scene harness (mobile)"  scene_harness mobile || true
stage "5/5  Question bank schema"    bank_validate    || true

echo ""
echo "══════════════════════════════════════════════════════════════"
if [ $FAILED -eq 0 ]; then
  echo "  ALL CHECKS PASSED"
else
  echo "  VERIFICATION FAILED"
fi
echo "══════════════════════════════════════════════════════════════"
exit $FAILED
