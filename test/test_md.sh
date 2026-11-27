#!/usr/bin/env bash
# Tests for md — pagination wrapper around md2ansi
# This file is sourced by run_tests
[[ ${BASH_SOURCE[0]} != "$0" ]] || {
  >&2 echo "Error: ${0@Q} must be sourced by run_tests"
  exit 1
}

test_section "md (pagination wrapper)"

# --------------------------------------------------------------------------------
# Version / help: md answers these itself rather than passing them to md2ansi

output=$(./md --version 2>&1)
assert_equals "md 1.0.0" "$output" "md --version reports the wrapper's own version"
assert_exit_code 0 "md --version exits 0" ./md --version

output=$(./md --help 2>&1)
assert_contains "$output" "Wrapper for md2ansi" "md --help shows the wrapper's own usage"
assert_exit_code 0 "md --help exits 0" ./md --help

# --------------------------------------------------------------------------------
# Stdin pipeline (less -F auto-quits on short input when stdout is not a tty)

output=$(echo "# Hello" | ./md 2>&1)
assert_contains "$output" "Hello" "md stdin pipeline renders"

output=$(printf '# Hi' | ./md 2>&1)
assert_exit_code_input 0 "md stdin-only invocation exits 0" '# Hi' ./md

# --------------------------------------------------------------------------------
# File argument

output=$(./md README.md 2>&1)
assert_not_empty "$output" "md README.md produces output"
assert_contains "$output" "md2ansi" "md README.md contains expected content"

# --------------------------------------------------------------------------------
# Error propagation from md2ansi

assert_exit_code 3 "md propagates exit 3 on missing file" ./md /nonexistent/file.md

# --------------------------------------------------------------------------------
# LESS env var is exported by the wrapper (verify via static grep — sourcing
# would run the pipeline)

assert_contains "$(grep -E '^export LESS' md)" "-FXRS" "md exports LESS=-FXRS"

#fin
