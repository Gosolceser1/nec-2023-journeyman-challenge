class_name TReport
extends RefCounted
## Shared assertion collector for the pure-logic test suites.
##
## A suite holds one of this, calls check()/eq()/ne()/defect() per assertion,
## then calls report() at the end. `defects` are KNOWN product bugs pinned by a
## test so they cannot silently regress once fixed - they do NOT fail the run.
##
## The suites `extends SceneTree` so they can be run standalone with --script.
## run_all.gd shells out to each one as a child process (a SceneTree cannot be
## instantiated in-process), so _init() guards on run_suite_body().
##
## GDScript GOTCHA, hit while writing these tests: `or` is a BOOLEAN operator,
## so `dict.get(k, "") or ""` yields str(true) == "true", NOT a fallback. That
## silently turns a whole-bank sweep into a sweep of the literal string "true",
## which passes while testing nothing. Route optional field reads through a
## helper instead.

var checks := 0
var failures: Array[String] = []
var defects: Array[String] = []
var autostart_disabled := false


## _init() in a standalone suite calls this to decide whether it is being run
## directly (do the work) or driven by run_all.gd (stay quiet; it calls run()).
func run_suite_body() -> bool:
	return not autostart_disabled


func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func eq(got, want, label: String) -> void:
	checks += 1
	if got != want:
		var msg := "%s -- got %s, want %s" % [label, str(got), str(want)]
		failures.append(msg)
		print("  FAIL: %s" % msg)


func ne(got, unwanted, label: String) -> void:
	checks += 1
	if got == unwanted:
		var msg := "%s -- got %s, expected anything else" % [label, str(got)]
		failures.append(msg)
		print("  FAIL: %s" % msg)


func has(haystack: String, needle: String, label: String) -> void:
	check(haystack.contains(needle), "%s -- '%s' does not contain '%s'" % [label, haystack, needle])


func lacks(haystack: String, needle: String, label: String) -> void:
	check(not haystack.contains(needle), "%s -- '%s' unexpectedly contains '%s'" % [label, haystack, needle])


## The product's core guarantee: after redaction, the answer must be unfindable.
func no_leak(redacted: String, answer: String, label: String) -> void:
	var hit: Dictionary = AudioExplanationGenerator.find_match_in(redacted, answer)
	check(hit.is_empty(), "ANSWER LEAK in %s -- %s still matches at %s" % [label, str(hit), redacted])


## Pin a KNOWN-BROKEN behaviour. Does NOT fail the run; it records the bug so
## it stays visible and greppable. GDScript arity-checks at parse time, so this
## keeps the full explicit signature rather than a variadic.
##
## When someone fixes the bug, the suite's own assertion flips and fails,
## forcing this pin to be removed - so a fix cannot land unnoticed.
func defect(file: String, summary: String, actual: String, expected: String, reach: String) -> void:
	var text := "%s: %s" % [file, summary]
	defects.append(text)
	print("  KNOWN DEFECT: %s" % text)
	if actual != "":
		print("      actual  : %s" % actual)
	if expected != "":
		print("      expected: %s" % expected)
	if reach != "":
		print("      reach   : %s" % reach)


func result() -> Dictionary:
	return {"checks": checks, "failures": failures, "defects": defects}


## Prints the machine-readable tail. run_all.gd greps for "checks: ", "FAIL:"
## and "KNOWN DEFECT:" -- keep those markers in sync with run_all.gd.
func report() -> void:
	for f in failures:
		print("  FAIL: %s" % f)
	print("checks: %d  failures: %d  known-defects: %d" % [checks, failures.size(), defects.size()])
