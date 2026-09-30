#!/usr/bin/env bash
# Single entry point: verify the project is healthy.
#
#   bash tools/verify.sh
#
# Runs, in order:
#   0. Import (rebuilds the class_name cache after scripts move)
#   1. GDScript parse check (catches syntax errors without booting)
#   2. Unit tests for pure logic  (tools/tests/run_all.gd, including the
#      touch-scroll and Android voice-picker suites)
#   3. Scene harness, desktop layout
#   4. Scene harness, mobile layout
#   5. Question bank checks (build guard, python unit tests, spellcheck, schema)
#
# Exit 0 = all green. Non-zero = at least one stage failed, with its output.
#
# Env overrides:
#   GODOT   Godot console binary   (default: <repo>/<GODOT_BINARY from tools/godot.env>)
#   PYTHON  Python 3 interpreter   (default: first working python / python.exe / py.exe / python3)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT/tools/godot.env"
GODOT="${GODOT:-$ROOT/$GODOT_BINARY}"

# Godot spews harmless static-string/NavMesh teardown noise on exit.
NOISE='Unreferenced static string|string_name\.cpp:|NavMeshGeometryParser|PagedAllocator'
FAILED=0

stage() {
  local name="$1"; shift
  echo ""
  echo "──────────────────────────────────────────────────────────────"
  echo "  $name"
  echo "──────────────────────────────────────────────────────────────"
  "$@" 2>&1 | grep -vE "$NOISE"
  local rc=${PIPESTATUS[0]}
  if [ "$rc" -eq 0 ]; then
    return 0
  fi
  echo "  ✗ STAGE FAILED: $name (exit $rc)"
  FAILED=1
  return 1
}

if [ ! -x "$GODOT" ] && [ ! -f "$GODOT" ]; then
  echo "Godot not found at: $GODOT"
  echo "Set GODOT=/path/to/Godot_v4.x-stable_win64_console.exe"
  exit 127
fi

cd "$ROOT" || exit 1

# Python is python.exe on Windows. git-bash sees it as `python`; WSL's bash
# (what `bash` resolves to from PowerShell) only has a Linux `python3` unless
# the Windows interpreter is called by its .exe name, so try those first there.
# A candidate must actually run: the WindowsApps `python3` stub only opens the
# Store.
find_python() {
  local c
  for c in ${PYTHON:+"$PYTHON"} python python.exe py.exe python3; do
    if command -v "$c" >/dev/null 2>&1 \
      && "$c" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)' >/dev/null 2>&1; then
      printf '%s\n' "$c"
      return 0
    fi
  done
  return 1
}

# 0. Build the class_name cache so --script runs resolve AnswerCard, AudioSettings, ...
import_project() {
  local out rc
  out=$("$GODOT" --headless --path . --import 2>&1)
  rc=$?
  # A first import on a fresh clone can log transient class-cache errors, so
  # show them without failing; the parse stage is the gate for scripts.
  printf '%s\n' "$out" | grep -E "ERROR" | grep -vE "$NOISE" | head -20
  [ $rc -eq 0 ] && echo "  import done"
  return $rc
}

# 1. Parse every app script (and the tools that verify.sh does not run) without booting the app.
parse_check() {
  local rc=0 n=0
  local files
  files=$(find . -name '*.gd' \
            -not -path './.godot/*' -not -path './.audit_tmp/*' -not -path './build/*' \
            -not -path './tools/tests/*' | sort)
  for f in $files; do
    f="${f#./}"
    n=$((n + 1))
    out=$("$GODOT" --headless --path . --check-only --script "$f" 2>&1)
    code=$?
    out=$(printf '%s\n' "$out" | grep -vE "$NOISE")
    if [ "$code" -ne 0 ] || printf '%s' "$out" | grep -qiE "SCRIPT ERROR|Parse Error"; then
      echo "  ✗ $f failed to parse (exit $code):"
      printf '%s\n' "$out" | head -5
      rc=1
    fi
  done
  if [ "$n" -eq 0 ]; then
    echo "  ✗ no .gd files found to parse"
    return 1
  fi
  [ $rc -eq 0 ] && echo "  all $n scripts parse cleanly"
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
  local py
  if ! py="$(find_python)"; then
    echo "  ✗ no working Python 3 found (tried \$PYTHON, python, python.exe, py.exe, python3)"
    echo "    Set PYTHON=/path/to/python to run the bank checks."
    return 1
  fi
  echo "  python: $py ($("$py" -c 'import sys; print(sys.version.split()[0])'))"
  export PYTHON="$py"
  bash tools/tests/test_build_guard.sh || return $?
  "$py" -m unittest tools.tests.test_validate_question_bank tools.tests.test_spellcheck_bank tools.tests.test_typo_regressions tools.tests.test_speak_question tools.tests.test_audit_bundle tools.tests.test_question_requirements tools.tests.test_diagram_figures tools.tests.test_exam_sources tools.tests.test_edition_migration_report tools.tests.test_sync_identity tools.tests.test_bump_version tools.tests.test_branding_text tools.tests.test_godot_env || return $?
  "$py" tools/pipeline/spellcheck_bank.py --offline || return $?
  "$py" tools/pipeline/validate_question_bank.py --no-warn
  return $?
}

stage "0/5  Import"                  import_project   || true
stage "1/5  Parse check"             parse_check      || true
stage "2/5  Unit tests"              unit_tests       || true
stage "3/5  Scene harness (desktop)" scene_harness "" || true
stage "4/5  Scene harness (mobile)"  scene_harness mobile || true
stage "5/5  Question bank"           bank_validate    || true

# The voice bundle is gitignored, so fresh clones and CI skip this; where it
# exists, a stale or partial bundle must not pass silently.
bundle_audio() {
  local py
  py="${PYTHON:-$(find_python)}" || { echo "  ✗ no working Python 3 found"; return 1; }
  "$py" tools/speech/audit_bundle.py
}

if [ -d assets/speech ]; then
  stage "+    Speech bundle (every record)"  "$GODOT" --headless --path . --script tools/speech/test_bundle.gd || true
  # Every clip whole: clean MP3 frames, a plausible length for its words,
  # silence before and after the speech (edges need Python's av + numpy).
  stage "+    Speech bundle audio"      bundle_audio || true
else
  echo ""
  echo "  (assets/speech/ not generated — bundled-voice checks skipped)"
fi

echo ""
echo "══════════════════════════════════════════════════════════════"
if [ $FAILED -eq 0 ]; then
  echo "  ALL CHECKS PASSED"
else
  echo "  VERIFICATION FAILED"
fi
echo "══════════════════════════════════════════════════════════════"
exit $FAILED
