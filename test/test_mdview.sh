#!/usr/bin/env bash
# Tests for mdview — Markdown viewer wrapper
# This file is sourced by run_tests

test_section "mdview"

# ================================================================================
# Script mode: CLI options
# ================================================================================

# --version
output=$(./mdview --version 2>&1)
assert_contains "$output" "mdview" "--version contains program name"
assert_contains "$output" "1.0.1" "--version contains version number"
assert_exit_code 0 "./mdview --version" "--version exits 0"

# --help
output=$(./mdview --help 2>&1)
assert_contains "$output" "Usage:" "--help contains usage line"
assert_contains "$output" "--theme" "--help documents --theme option"
assert_contains "$output" "--window-size" "--help documents --window-size option"
assert_contains "$output" "--browser" "--help documents --browser option"
assert_exit_code 0 "./mdview --help" "--help exits 0"

# Short flags equivalent to long
output_V=$(./mdview -V 2>&1)
assert_contains "$output_V" "1.0.1" "-V is equivalent to --version"
output_h=$(./mdview -h 2>&1)
assert_contains "$output_h" "Usage:" "-h is equivalent to --help"

# ================================================================================
# Script mode: argument validation
# ================================================================================

# No arguments → exit 2
assert_exit_code 2 "./mdview 2>&1" "No arguments exits 2"

# Missing file → exit 1
assert_exit_code 1 "./mdview /nonexistent/file.md 2>&1" "Nonexistent file exits 1"

# Invalid option → exit 22
assert_exit_code 22 "./mdview --bogus 2>&1" "Invalid option exits 22"
assert_exit_code 22 "./mdview -z 2>&1" "Invalid short option exits 22"

# Options requiring argument, missing → exit 2
assert_exit_code 2 "./mdview --theme 2>&1" "--theme without value exits 2"
assert_exit_code 2 "./mdview --window-size 2>&1" "--window-size without value exits 2"
assert_exit_code 2 "./mdview --browser 2>&1" "--browser without value exits 2"

# Invalid window size format → exit 22
assert_exit_code 22 "./mdview --window-size bad README.md 2>&1" "Invalid window-size format exits 22"
assert_exit_code 22 "./mdview --window-size 100 README.md 2>&1" "Window-size missing 'x' exits 22"
assert_exit_code 22 "./mdview --window-size axb README.md 2>&1" "Non-numeric window-size exits 22"

# Error messages go to stderr
stderr=$(./mdview 2>&1 1>/dev/null ||:)
assert_contains "$stderr" "mdview" "Error message includes program name"

# ================================================================================
# Script mode: option stacking (short flags combined)
# ================================================================================

# -tnonexistent parses as -t nonexistent (theme), then /nonexistent is the file
# File not found → exit 1 (proves stacking parsed -t correctly, not as invalid option)
assert_exit_code 1 "./mdview -tnonexistent /nonexistent 2>&1" "Stacked -t flag parsed correctly (file error, not option error)"

# ================================================================================
# Sourced mode tests
# ================================================================================

# Function is available after sourcing
output=$(bash -c 'source ./mdview 2>/dev/null; type -t mdview' 2>&1)
assert_equals "function" "$output" "mdview function available after sourcing"

# No EXIT trap leaks when sourced
output=$(bash -c 'source ./mdview 2>/dev/null; trap -p EXIT' 2>&1)
assert_equals "" "$output" "No EXIT trap after sourcing (fix #1)"

# Function validates arguments in sourced mode
output=$(bash -c 'source ./mdview 2>/dev/null; mdview 2>&1; echo "exit:$?"' 2>&1)
assert_contains "$output" "exit:2" "Sourced mdview with no args returns 2"

output=$(bash -c 'source ./mdview 2>/dev/null; mdview a b 2>&1; echo "exit:$?"' 2>&1)
assert_contains "$output" "exit:2" "Sourced mdview with too many args returns 2"

output=$(bash -c 'source ./mdview 2>/dev/null; mdview /nonexistent 2>&1; echo "exit:$?"' 2>&1)
assert_contains "$output" "exit:1" "Sourced mdview with missing file returns 1"

# set -euo pipefail NOT active in sourced mode (line 120 only runs in script mode)
output=$(bash -c '
  source ./mdview 2>/dev/null
  # If set -e were active, this false would abort the shell
  false
  echo "survived"
' 2>&1)
assert_contains "$output" "survived" "Sourced mode does not impose set -e on caller"

# ================================================================================
# Full pipeline tests (requires pandoc + themes)
# ================================================================================

if command -v pandoc &>/dev/null && [[ -d themes ]]; then

  # Use /bin/true as browser mock — accepts any args, does nothing
  MDVIEW_TMPDIR=${XDG_RUNTIME_DIR:-"${TMPDIR:-/tmp}"}/mdview

  # Full pipeline succeeds with mock browser
  assert_exit_code 0 "MDVIEW_BROWSER=/bin/true ./mdview README.md" "Full pipeline with mock browser exits 0"

  # Temp file created in expected directory
  if [[ -d "$MDVIEW_TMPDIR" ]]; then
    tmpcount=$(find "$MDVIEW_TMPDIR" -name 'README.*.html' -mmin -1 2>/dev/null | wc -l)
    if ((tmpcount > 0)); then
      assert_pass "Temp HTML file created in $MDVIEW_TMPDIR"
    else
      assert_fail "Temp HTML file should exist in $MDVIEW_TMPDIR"
    fi
  else
    assert_fail "Temp directory $MDVIEW_TMPDIR should exist"
  fi

  # Temp file contains HTML (spot check)
  tmpfile=$(find "$MDVIEW_TMPDIR" -name 'README.*.html' -mmin -1 2>/dev/null | head -1)
  if [[ -n "$tmpfile" && -f "$tmpfile" ]]; then
    content=$(head -5 "$tmpfile")
    assert_contains "$content" "html" "Temp file contains HTML content"
  fi

  # Theme override works end-to-end
  assert_exit_code 0 \
    "MDVIEW_BROWSER=/bin/true ./mdview --theme github-dark README.md" \
    "CLI --theme override works"

  # Invalid theme produces error (not crash)
  assert_exit_code 1 \
    "MDVIEW_BROWSER=/bin/true ./mdview --theme nonexistent-theme README.md" \
    "Invalid theme exits 1 with error"

  # Error message for invalid theme is descriptive
  stderr=$(MDVIEW_BROWSER=/bin/true ./mdview --theme nonexistent-theme README.md 2>&1 ||:)
  assert_contains "$stderr" "not found" "Invalid theme error mentions 'not found'"

  # Window size override accepted (no crash)
  assert_exit_code 0 \
    "MDVIEW_BROWSER=/bin/true ./mdview --window-size 1200x900 README.md" \
    "CLI --window-size override works"

  # Browser override accepted
  assert_exit_code 0 \
    "MDVIEW_BROWSER=/bin/true ./mdview --browser /bin/true README.md" \
    "CLI --browser override works"

  # -- separator works
  assert_exit_code 0 \
    "MDVIEW_BROWSER=/bin/true ./mdview -- README.md" \
    "Double-dash separator works"

  # No EXIT trap after full pipeline run (sourced mode)
  output=$(bash -c '
    source ./mdview 2>/dev/null
    MDVIEW_BROWSER=/bin/true mdview README.md 2>/dev/null
    trap -p EXIT
  ' 2>&1)
  assert_equals "" "$output" "No EXIT trap after full sourced pipeline (fix #1 verified)"

  # Clean up any test temp files (don't wait for the 30s delayed cleanup)
  find "$MDVIEW_TMPDIR" -name 'README.*.html' -mmin -1 -delete 2>/dev/null ||:

else
  echo "${YELLOW}⊘${NC} Skipping full pipeline tests (pandoc or themes/ not available)"
fi

#fin
