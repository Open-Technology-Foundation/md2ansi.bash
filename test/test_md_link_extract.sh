#!/usr/bin/env bash
# Tests for md-link-extract — markdown link extractor
# This file is sourced by run_tests
[[ ${BASH_SOURCE[0]} != "$0" ]] || {
  >&2 echo "Error: ${0@Q} must be sourced by run_tests"
  exit 1
}

test_section "md-link-extract"

# --------------------------------------------------------------------------------
# Help / no-args behaviour

output=$(./md-link-extract --help 2>&1)
assert_contains "$output" "Usage" "--help shows usage"
assert_exit_code 0 "--help exits 0" ./md-link-extract --help

output=$(./md-link-extract -h 2>&1)
assert_contains "$output" "Usage" "-h shows usage"

output=$(./md-link-extract 2>&1)
assert_contains "$output" "Usage" "no-args prints usage"
assert_exit_code 0 "no-args exits 0" ./md-link-extract

# --------------------------------------------------------------------------------
# Missing file → exit 3

assert_exit_code 3 "Missing file exits 3" ./md-link-extract /no/such.md
output=$(./md-link-extract /no/such.md 2>&1 ||:)
assert_contains "$output" "not found" "Missing file error message includes 'not found'"

# --------------------------------------------------------------------------------
# Inline link extraction

# TEST_TMPDIR comes from run_tests (mktemp -d, removed by its EXIT trap)
tmpfile="$TEST_TMPDIR"/mdlx-test
printf '[Google](https://google.com)\n' > "$tmpfile" || assert_fail "Cannot write fixture ${tmpfile##*/}"
output=$(./md-link-extract "$tmpfile" 2>&1)
assert_equals "https://google.com" "$output" "Inline link [t](url) extracted"
rm -f -- "$tmpfile"

# --------------------------------------------------------------------------------
# Bare URL extraction

tmpfile="$TEST_TMPDIR"/mdlx-test
printf '<https://example.com>\n' > "$tmpfile" || assert_fail "Cannot write fixture ${tmpfile##*/}"
output=$(./md-link-extract "$tmpfile" 2>&1)
assert_equals "https://example.com" "$output" "Bare URL <url> extracted"
rm -f -- "$tmpfile"

# --------------------------------------------------------------------------------
# Reference-style link extraction

tmpfile="$TEST_TMPDIR"/mdlx-test
printf '[ref text][1]\n\n[1]: https://ref.example.com\n' > "$tmpfile" || assert_fail "Cannot write fixture ${tmpfile##*/}"
output=$(./md-link-extract "$tmpfile" 2>&1)
assert_contains "$output" "https://ref.example.com" "Reference-style [t][r] resolved"
rm -f -- "$tmpfile"

# --------------------------------------------------------------------------------
# Fenced code block content stripped

tmpfile="$TEST_TMPDIR"/mdlx-test
{
  printf '```\n'
  printf '[skip](http://skip.test)\n'
  printf '```\n'
  printf '[keep](http://keep.test)\n'
} > "$tmpfile" || assert_fail "Cannot write fixture ${tmpfile##*/}"
output=$(./md-link-extract "$tmpfile" 2>&1)
assert_contains "$output" "http://keep.test" "Outside-fence link kept"
if [[ "$output" != *"http://skip.test"* ]]; then
  assert_pass "Inside-fence link stripped"
else
  assert_fail "Inside-fence link stripped"
fi
rm -f -- "$tmpfile"

# --------------------------------------------------------------------------------
# Inline code spans stripped

tmpfile="$TEST_TMPDIR"/mdlx-test
# shellcheck disable=SC2016  # backticks are literal markdown, not command substitution
printf '`[nope](http://nope.test)` and [yes](http://yes.test)\n' > "$tmpfile" || assert_fail "Cannot write fixture ${tmpfile##*/}"
output=$(./md-link-extract "$tmpfile" 2>&1)
assert_contains "$output" "http://yes.test" "Link outside backticks kept"
if [[ "$output" != *"http://nope.test"* ]]; then
  assert_pass "Link inside backticks stripped"
else
  assert_fail "Link inside backticks stripped"
fi
rm -f -- "$tmpfile"

# --------------------------------------------------------------------------------
# UTM parameter removal

tmpfile="$TEST_TMPDIR"/mdlx-test
printf '[x](https://example.com?utm_source=test&id=1)\n' > "$tmpfile" || assert_fail "Cannot write fixture ${tmpfile##*/}"
output=$(./md-link-extract "$tmpfile" 2>&1)
assert_equals "https://example.com?id=1" "$output" "utm_source param removed"
rm -f -- "$tmpfile"

tmpfile="$TEST_TMPDIR"/mdlx-test
printf '[y](https://example.com?utm_source=foo)\n' > "$tmpfile" || assert_fail "Cannot write fixture ${tmpfile##*/}"
output=$(./md-link-extract "$tmpfile" 2>&1)
assert_equals "https://example.com" "$output" "Trailing-only utm_ param leaves no '?'"
rm -f -- "$tmpfile"

# --------------------------------------------------------------------------------
# Deduplication

tmpfile="$TEST_TMPDIR"/mdlx-test
printf '[a](http://dup.test)\n[b](http://dup.test)\n' > "$tmpfile" || assert_fail "Cannot write fixture ${tmpfile##*/}"
output=$(./md-link-extract "$tmpfile" 2>&1)
line_count=$(printf '%s\n' "$output" | grep -c 'http://dup.test')
assert_equals "1" "$line_count" "Duplicate URLs collapsed to single line"
rm -f -- "$tmpfile"

# --------------------------------------------------------------------------------
# Sort order

tmpfile="$TEST_TMPDIR"/mdlx-test
printf '[z](http://zebra.test)\n[a](http://alpha.test)\n' > "$tmpfile" || assert_fail "Cannot write fixture ${tmpfile##*/}"
output=$(./md-link-extract "$tmpfile" 2>&1)
first_line=$(printf '%s\n' "$output" | head -1)
assert_equals "http://alpha.test" "$first_line" "Output sorted lexicographically"
rm -f -- "$tmpfile"

# --------------------------------------------------------------------------------
# Multiple files — union

tmpfile1="$TEST_TMPDIR"/mdlx-test1
tmpfile2="$TEST_TMPDIR"/mdlx-test2
printf '[one](http://one.test)\n' > "$tmpfile1" || assert_fail "Cannot write fixture ${tmpfile1##*/}"
printf '[two](http://two.test)\n' > "$tmpfile2" || assert_fail "Cannot write fixture ${tmpfile2##*/}"
output=$(./md-link-extract "$tmpfile1" "$tmpfile2" 2>&1)
assert_contains "$output" "http://one.test" "Multi-file: first file's link present"
assert_contains "$output" "http://two.test" "Multi-file: second file's link present"
rm -f -- "$tmpfile1" "$tmpfile2"

#fin
