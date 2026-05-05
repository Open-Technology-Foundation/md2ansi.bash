#!/usr/bin/env bash
# Tests for ansi-info — terminal capability report
# This file is sourced by run_tests

test_section "ansi-info"

# --------------------------------------------------------------------------------
# Version / help

output=$(./ansi-info --version 2>&1)
assert_contains "$output" "1.1.0" "--version contains version 1.1.0"
assert_exit_code 0 "./ansi-info --version" "--version exits 0"

output=$(./ansi-info -V 2>&1)
assert_contains "$output" "1.1.0" "-V is short for --version"
assert_exit_code 0 "./ansi-info -V" "-V exits 0"

output=$(./ansi-info --help 2>&1)
assert_contains "$output" "Usage" "--help shows usage"
assert_exit_code 0 "./ansi-info --help" "--help exits 0"

output=$(./ansi-info -h 2>&1)
assert_contains "$output" "Usage" "-h is short for --help"

# --------------------------------------------------------------------------------
# Full report (less -F auto-dumps when stdout is not a tty)

output=$(./ansi-info 2>&1)
assert_exit_code 0 "./ansi-info" "Full run exits 0"
assert_not_empty "$output" "Full run produces non-empty output"

# Section 1: 256-colour palette with #RRGGBB labels
assert_contains "$output" "#000000" "Output contains palette label #000000"
assert_contains "$output" "#ffffff" "Output contains palette label #ffffff"
assert_contains "$output" "256-colour palette" "Output contains palette section header"

# Section 2: SGR attributes
assert_contains "$output" "bold" "Output contains SGR 'bold'"
assert_contains "$output" "italic" "Output contains SGR 'italic'"
assert_contains "$output" "underline" "Output contains SGR 'underline'"

# Section 3: 24-bit truecolor ramps
assert_contains "$output" "24-bit truecolor" "Output contains truecolor section header"

# Section 4: terminal capability footer
assert_contains "$output" "TERM" "Footer contains TERM label"
assert_contains "$output" "COLORTERM" "Footer contains COLORTERM label"
assert_contains "$output" "tput colors" "Footer contains tput colors label"
assert_contains "$output" "Truecolor" "Footer contains Truecolor label"

# --------------------------------------------------------------------------------
# Argument validation

assert_exit_code 22 "./ansi-info --bogus 2>&1" "Invalid option exits 22"
assert_exit_code 22 "./ansi-info -z 2>&1" "Invalid short option exits 22"
assert_exit_code 2 "./ansi-info junk 2>&1" "Unexpected positional arg exits 2"

#fin
