#!/usr/bin/env bash
# Tests for md-link-extract — markdown link extractor
# This file is sourced by run_tests

test_section "md-link-extract"

# --------------------------------------------------------------------------------
# Help / no-args behaviour

output=$(./md-link-extract --help 2>&1)
assert_contains "$output" "Usage" "--help shows usage"
assert_exit_code 0 "./md-link-extract --help" "--help exits 0"

output=$(./md-link-extract -h 2>&1)
assert_contains "$output" "Usage" "-h shows usage"

output=$(./md-link-extract 2>&1)
assert_contains "$output" "Usage" "no-args prints usage"
assert_exit_code 0 "./md-link-extract" "no-args exits 0"

# --------------------------------------------------------------------------------
# Missing file → exit 3

assert_exit_code 3 "./md-link-extract /no/such.md 2>&1" "Missing file exits 3"
output=$(./md-link-extract /no/such.md 2>&1 ||:)
assert_contains "$output" "not found" "Missing file error message includes 'not found'"

# --------------------------------------------------------------------------------
# Inline link extraction

tmpfile=$(mktemp -t mdlx-test.XXXXXX)
printf '[Google](https://google.com)\n' > "$tmpfile"
output=$(./md-link-extract "$tmpfile" 2>&1)
assert_equals "https://google.com" "$output" "Inline link [t](url) extracted"
rm -f "$tmpfile"

# --------------------------------------------------------------------------------
# Bare URL extraction

tmpfile=$(mktemp -t mdlx-test.XXXXXX)
printf '<https://example.com>\n' > "$tmpfile"
output=$(./md-link-extract "$tmpfile" 2>&1)
assert_equals "https://example.com" "$output" "Bare URL <url> extracted"
rm -f "$tmpfile"

# --------------------------------------------------------------------------------
# Reference-style link extraction

tmpfile=$(mktemp -t mdlx-test.XXXXXX)
printf '[ref text][1]\n\n[1]: https://ref.example.com\n' > "$tmpfile"
output=$(./md-link-extract "$tmpfile" 2>&1)
assert_contains "$output" "https://ref.example.com" "Reference-style [t][r] resolved"
rm -f "$tmpfile"

# --------------------------------------------------------------------------------
# Fenced code block content stripped

tmpfile=$(mktemp -t mdlx-test.XXXXXX)
{
  printf '```\n'
  printf '[skip](http://skip.test)\n'
  printf '```\n'
  printf '[keep](http://keep.test)\n'
} > "$tmpfile"
output=$(./md-link-extract "$tmpfile" 2>&1)
assert_contains "$output" "http://keep.test" "Outside-fence link kept"
if [[ "$output" != *"http://skip.test"* ]]; then
  assert_pass "Inside-fence link stripped"
else
  assert_fail "Inside-fence link stripped"
fi
rm -f "$tmpfile"

# --------------------------------------------------------------------------------
# Inline code spans stripped

tmpfile=$(mktemp -t mdlx-test.XXXXXX)
# shellcheck disable=SC2016  # backticks are literal markdown, not command substitution
printf '`[nope](http://nope.test)` and [yes](http://yes.test)\n' > "$tmpfile"
output=$(./md-link-extract "$tmpfile" 2>&1)
assert_contains "$output" "http://yes.test" "Link outside backticks kept"
if [[ "$output" != *"http://nope.test"* ]]; then
  assert_pass "Link inside backticks stripped"
else
  assert_fail "Link inside backticks stripped"
fi
rm -f "$tmpfile"

# --------------------------------------------------------------------------------
# UTM parameter removal

tmpfile=$(mktemp -t mdlx-test.XXXXXX)
printf '[x](https://example.com?utm_source=test&id=1)\n' > "$tmpfile"
output=$(./md-link-extract "$tmpfile" 2>&1)
assert_equals "https://example.com?id=1" "$output" "utm_source param removed"
rm -f "$tmpfile"

tmpfile=$(mktemp -t mdlx-test.XXXXXX)
printf '[y](https://example.com?utm_source=foo)\n' > "$tmpfile"
output=$(./md-link-extract "$tmpfile" 2>&1)
assert_equals "https://example.com" "$output" "Trailing-only utm_ param leaves no '?'"
rm -f "$tmpfile"

# --------------------------------------------------------------------------------
# Deduplication

tmpfile=$(mktemp -t mdlx-test.XXXXXX)
printf '[a](http://dup.test)\n[b](http://dup.test)\n' > "$tmpfile"
output=$(./md-link-extract "$tmpfile" 2>&1)
line_count=$(printf '%s\n' "$output" | grep -c 'http://dup.test')
assert_equals "1" "$line_count" "Duplicate URLs collapsed to single line"
rm -f "$tmpfile"

# --------------------------------------------------------------------------------
# Sort order

tmpfile=$(mktemp -t mdlx-test.XXXXXX)
printf '[z](http://zebra.test)\n[a](http://alpha.test)\n' > "$tmpfile"
output=$(./md-link-extract "$tmpfile" 2>&1)
first_line=$(printf '%s\n' "$output" | head -1)
assert_equals "http://alpha.test" "$first_line" "Output sorted lexicographically"
rm -f "$tmpfile"

# --------------------------------------------------------------------------------
# Multiple files — union

tmpfile1=$(mktemp -t mdlx-test1.XXXXXX)
tmpfile2=$(mktemp -t mdlx-test2.XXXXXX)
printf '[one](http://one.test)\n' > "$tmpfile1"
printf '[two](http://two.test)\n' > "$tmpfile2"
output=$(./md-link-extract "$tmpfile1" "$tmpfile2" 2>&1)
assert_contains "$output" "http://one.test" "Multi-file: first file's link present"
assert_contains "$output" "http://two.test" "Multi-file: second file's link present"
rm -f "$tmpfile1" "$tmpfile2"

#fin
