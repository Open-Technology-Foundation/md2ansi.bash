#!/usr/bin/env bash
# Security feature tests for md2ansi Bash implementation
# This file is sourced by run_tests
[[ ${BASH_SOURCE[0]} != "$0" ]] || {
  >&2 echo "Error: ${0@Q} must be sourced by run_tests"
  exit 1
}

test_section "Security Features"

# --------------------------------------------------------------------------------
# File size limits (MAX_FILE_SIZE = 10MB)

# Create a file approaching the limit. TEST_TMPDIR comes from run_tests (mktemp -d,
# removed by its EXIT trap); the rm calls free the 10MB files straight away.
dd if=/dev/zero bs=1024 count=10000 2>/dev/null | tr '\0' 'a' > "$TEST_TMPDIR"/md2ansi_large.txt \
  || assert_fail "Cannot write fixture md2ansi_large.txt"
echo "# Test" >> "$TEST_TMPDIR"/md2ansi_large.txt || assert_fail "Cannot write fixture md2ansi_large.txt"
output=$(./md2ansi -- "$TEST_TMPDIR"/md2ansi_large.txt 2>&1)
# Should process successfully if under 10MB
assert_contains "$output" "Test" "Large file (10MB) processes successfully"
rm -f -- "$TEST_TMPDIR"/md2ansi_large.txt

# Create a file exceeding the limit (11MB)
dd if=/dev/zero bs=1024 count=11264 2>/dev/null | tr '\0' 'a' > "$TEST_TMPDIR"/md2ansi_toolarge.txt \
  || assert_fail "Cannot write fixture md2ansi_toolarge.txt"
assert_exit_code 9 "File exceeding 10MB limit returns error" ./md2ansi -- "$TEST_TMPDIR"/md2ansi_toolarge.txt
rm -f -- "$TEST_TMPDIR"/md2ansi_toolarge.txt

# --------------------------------------------------------------------------------
# Line length limits (MAX_LINE_LENGTH = 100KB)

# Create a very long line (50KB - should work)
long_line=$(printf 'a%.0s' {1..51200})
output=$(echo "$long_line" | ./md2ansi 2>&1)
assert_not_empty "$output" "Long line (50KB) processes"

# Create an extremely long line (150KB - should be truncated/handled)
very_long_line=$(printf 'a%.0s' {1..153600})
rc=0
output=$(echo "$very_long_line" | ./md2ansi 2>&1) || rc=$?
# Should either process or handle gracefully
if (( rc == 0 || rc == 1 )); then
  assert_pass "Very long line (150KB) handled gracefully"
else
  assert_fail "Very long line should be handled"
fi

# --------------------------------------------------------------------------------
# ANSI escape sequence sanitization

# Input containing ANSI codes should be stripped/sanitized
output=$(echo -e "Text with \x1b[31mred\x1b[0m codes" | ./md2ansi)
assert_contains "$output" "Text with" "ANSI input renders text"
assert_contains "$output" "red" "ANSI input renders color word"
assert_contains "$output" "codes" "ANSI input renders rest of text"

# Verify malicious ANSI codes are handled
output=$(echo -e "\x1b[2J\x1b[H# Header" | ./md2ansi)
assert_contains "$output" "Header" "Malicious ANSI codes (clear screen) handled"

# ANSI codes in code blocks should be preserved/handled correctly
#shellcheck disable=SC2016  # echo -e interprets \n and \x1b, not bash
output=$(echo -e '```\necho -e "\x1b[31mred\x1b[0m"\n```' | ./md2ansi)
assert_contains "$output" "echo" "ANSI codes in code blocks handled"

# --------------------------------------------------------------------------------
# Pathological regex input (no timeout guards the patterns, so these must finish)

# Complex nested formatting that could cause ReDoS
output=$(echo "**bold *italic **nested** more* end**" | ./md2ansi 2>&1)
assert_not_empty "$output" "Complex nested formatting doesn't hang"

# Many nested brackets
output=$(echo "[[[[[[[[[[text]]]]]]]]]]" | ./md2ansi 2>&1)
assert_contains "$output" "text" "Many nested brackets handled"

# Pathological regex cases
output=$(echo "********************test********************" | ./md2ansi 2>&1)
assert_contains "$output" "test" "Many consecutive asterisks handled"

# Very long link URL that could cause regex issues
long_url=$(printf 'http://example.com/%s' "$(printf 'a%.0s' {1..1000})")
output=$(echo "[link]($long_url)" | ./md2ansi 2>&1)
assert_contains "$output" "link" "Very long URL handled"

# --------------------------------------------------------------------------------
# Input validation

# Null bytes in input
exit_code=0
output=$(printf "Text\x00with\x00nulls" | ./md2ansi 2>&1) || exit_code=$?
# Should handle gracefully without crashing
if ((exit_code <= 1)); then
  assert_pass "Null bytes in input handled gracefully"
else
  assert_fail "Null bytes should be handled"
fi

# Binary data
exit_code=0
output=$(dd if=/dev/urandom bs=100 count=1 2>/dev/null | ./md2ansi 2>&1) || exit_code=$?
# Should handle gracefully without crashing
if ((exit_code <= 1)); then
  assert_pass "Binary data handled gracefully"
else
  assert_fail "Binary data should be handled"
fi

# --------------------------------------------------------------------------------
# Signal handling (verify cleanup on interrupt)

# Start a background process and send SIGTERM
echo "# Test" | timeout 1 ./md2ansi >/dev/null 2>&1 &
pid=$!
sleep 0.1
kill -TERM "$pid" 2>/dev/null ||:
exit_code=0
wait "$pid" 2>/dev/null || exit_code=$?
# 0: md2ansi finished before the signal arrived (usual for input this short);
# 143: SIGTERM, which timeout forwards to md2ansi. Anything else is a failure.
if ((exit_code == 0 || exit_code == 143)); then
  assert_pass "SIGTERM handled cleanly"
else
  assert_fail "SIGTERM run exited $exit_code (expected 0 or 143)"
fi

# --------------------------------------------------------------------------------
# Terminal reset on error

# cleanup() runs on the error path too. Stdout is exactly two resets: main()
# writes one before reading any file, cleanup() the other on the way out, so a
# lost cleanup() reset leaves one. TERM names a 256-colour terminal because
# md2ansi writes colour codes to a pipe only then.
exit_code=0
output=$(TERM=xterm-256color ./md2ansi /nonexistent 2>/dev/null) || exit_code=$?
assert_equals "3" "$exit_code" "Missing file exits 3 on the error path"
assert_equals $'\033[0m\033[0m' "$output" "cleanup() writes the closing colour reset on the error path"

#fin
