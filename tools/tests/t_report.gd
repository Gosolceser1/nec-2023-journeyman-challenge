extends RefCounted
## Minimal assertion collector shared by the pure-logic test scripts.
##
## Deliberately dependency-free (no nodes, no autoloads) so every test file can
## run headless in a fraction of a second:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . \
##       --script tools/tests/test_<name>.gd
##
## TWO BUCKETS, on purpose:
##   failures  - a regression in behaviour we assert. Non-empty => suite is RED.
##   defects   - a KNOWN defect in the product, reproduced here and reported
##               loudly, but not counted as a test failure so the suite can
##               still go green and stay in CI. Each one names the file/line,
##               the bad output, the expected output, and bank reachability.
##               A new defect should be added as `defect(...)`; a FIXED defect
##               must be promoted back into a `check(...)` assertion.

var checks := 0
var failures: Array[String] = []
var defects: Array[String] = []


func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: ", label)


func eq(actual, expected, label: String) -> void:
	check(actual == expected, "%s -- got %s, want %s" % [label, str(actual), str(expected)])


func ne(actual, unexpected, label: String) -> void:
	check(actual != unexpected, "%s -- should not equal %s" % [label, str(unexpected)])


func has(haystack: String, needle: String, label: String) -> void:
	check(haystack.contains(needle), "%s -- %s does not contain %s" % [label, haystack, needle])


func lacks(haystack: String, needle: String, label: String) -> void:
	check(not haystack.contains(needle), "%s -- %s unexpectedly contains %s" % [label, haystack, needle])


## The product's core guarantee: after redaction, the answer must be unfindable.
func no_leak(redacted: String, answer: String, label: String) -> void:
	var hit: Dictionary = _find(redacted, answer)
	check(hit.is_empty(), "ANSWER LEAK in %s -- %s still matches at %s" % [label, str(hit), redacted])


func _find(text: String, answer: String) -> Dictionary:
	return AudioExplanationGenerator.find_match_in(text, answer)


func defect(file: String, summary: String, actual: String, expected: String, reach: String) -> void:
	defects.append("%s: %s" % [file, summary])
	print("  DEFECT [%s] %s" % [file, summary])
	print("      actual  : %s" % actual)
	print("      expected: %s" % expected)
	print("      reach   : %s" % reach)


func report() -> Dictionary:
	print("")
	print("checks: %d  failures: %d  known-defects: %d" % [checks, failures.size(), defects.size()])
	for f in failures:
		print("  FAILED: ", f)
	return {"checks": checks, "failures": failures, "defects": defects}
