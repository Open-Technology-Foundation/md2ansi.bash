#!/usr/bin/env bash
# shellcheck disable=SC2016
# Audit gap tests for md2ansi Bash implementation
# Covers 5 areas identified in AUDIT-BASH.md §7 "Missing Test Coverage"
# This file is sourced by run_tests

test_section "Audit Gap Coverage"

# ================================================================================
# 1. Fence-type matching (L2 verification)
# CommonMark: closing fence must match opening fence type
# ================================================================================

# Backtick fence opens and closes correctly
output=$(printf '```\ncode inside backticks\n```\n' | ./md2ansi)
assert_contains "$output" "code inside backticks" "Backtick fence opens and closes correctly"

# Tilde fence opens and closes correctly
output=$(printf '~~~\ncode inside tildes\n~~~\n' | ./md2ansi)
assert_contains "$output" "code inside tildes" "Tilde fence opens and closes correctly"

# Backtick opened, tilde does NOT close (tilde rendered as code content)
output=$(printf '```\nline one\n~~~\nline two\n```\n' | ./md2ansi)
# Both lines should appear (~~~ didn't close the block, so line two is still code)
assert_contains "$output" "line one" "Mismatched fence (backtick/tilde) - content before mismatch"
assert_contains "$output" "line two" "Mismatched fence (backtick/tilde) - content after mismatch"
assert_contains "$output" "~~~" "Mismatched fence (backtick/tilde) - tilde rendered as code content"

# Tilde opened, backtick does NOT close (backtick rendered as code content)
output=$(printf '~~~\nline one\n```\nline two\n~~~\n' | ./md2ansi)
assert_contains "$output" "line one" "Mismatched fence (tilde/backtick) - content before mismatch"
assert_contains "$output" "line two" "Mismatched fence (tilde/backtick) - content after mismatch"

# Content between mismatched fences stays inside code block
output=$(printf '```\nbefore\n~~~\nmiddle\n```\n' | ./md2ansi)
assert_contains "$output" "before" "Mismatched fence - content before mismatch preserved"
assert_contains "$output" "middle" "Mismatched fence - content between mismatched and correct close"

# ================================================================================
# 2. Combined short options
# The splitter at md2ansi:1363-1366 handles -[wDVht]* combined forms
# ================================================================================

# -Dw 80 equivalent to --debug --width 80
stderr=$(echo "# Test" | ./md2ansi -Dw 80 2>&1 1>/dev/null)
if echo "$stderr" | grep -qE '\[[0-9]{2}:[0-9]{2}:[0-9]{2}'; then
  assert_pass "Combined -Dw 80 produces debug output"
else
  assert_fail "Combined -Dw 80 should produce debug output"
fi

# Verify -Dw 80 sets width (compare with explicit --debug --width 80)
output_combined=$(echo "This is a test of combined short options for width" | ./md2ansi -Dw 80 2>/dev/null)
output_separate=$(echo "This is a test of combined short options for width" | ./md2ansi --debug --width 80 2>/dev/null)
assert_equals "$output_separate" "$output_combined" "Combined -Dw 80 matches --debug --width 80"

# -tD equivalent to --plain --debug
stderr=$(echo "# Test" | ./md2ansi -tD 2>&1 1>/dev/null)
if echo "$stderr" | grep -qE '\[[0-9]{2}:[0-9]{2}:[0-9]{2}'; then
  assert_pass "Combined -tD produces debug output (debug enabled)"
else
  assert_fail "Combined -tD should produce debug output"
fi

# -w80 (value attached to flag) - should fail because splitter splits characters
assert_exit_code 2 "echo test | ./md2ansi -w80 2>&1" "Attached value -w80 returns error (not supported)"

# Invalid combined option returns error (e.g., -Dz)
assert_exit_code 22 "echo test | ./md2ansi -Dz 2>&1" "Invalid combined option -Dz returns error"

# ================================================================================
# 3. Stdin size limit rejection
# Code at md2ansi:1399-1407 enforces 10MB stdin limit via byte counting
# ================================================================================

# Stdin under 10MB processes successfully (use ~1MB)
output=$(dd if=/dev/zero bs=1024 count=1000 2>/dev/null | tr '\0' 'x' | ./md2ansi 2>&1)
assert_not_empty "$output" "Stdin under 10MB (1MB) processes successfully"

# Stdin over 10MB rejected with exit code 1
# Generate just over 10MB (10.5MB) piped to stdin
set +e
dd if=/dev/zero bs=1024 count=10752 2>/dev/null | tr '\0' 'x' | ./md2ansi >/dev/null 2>/tmp/md2ansi_stderr_limit.txt
stdin_exit=$?
set -e
assert_equals "1" "$stdin_exit" "Stdin over 10MB returns exit code 1"

# Error message mentions stdin and maximum size
stderr_msg=$(</tmp/md2ansi_stderr_limit.txt)
assert_contains "$stderr_msg" "stdin" "Stdin size error mentions stdin"
assert_contains "$stderr_msg" "maximum size" "Stdin size error mentions maximum size"
rm -f /tmp/md2ansi_stderr_limit.txt

# ================================================================================
# 4. Multi-file processing
# Code at md2ansi:1443-1452 processes multiple files sequentially
# ================================================================================

# Setup temp files
echo '# File One' > /tmp/md2ansi_multi1.md
echo '# File Two' > /tmp/md2ansi_multi2.md

# Two files process in sequence (both headers present in output)
output=$(./md2ansi /tmp/md2ansi_multi1.md /tmp/md2ansi_multi2.md)
assert_contains "$output" "File One" "Multi-file - first file content present"
assert_contains "$output" "File Two" "Multi-file - second file content present"

# File order preserved (file1 content before file2)
# Strip ANSI codes for position comparison
#shellcheck disable=SC2001
stripped=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g')
pos1=$(echo "$stripped" | grep -n 'File One' | head -1 | cut -d: -f1)
pos2=$(echo "$stripped" | grep -n 'File Two' | head -1 | cut -d: -f1)
if [[ -n $pos1 && -n $pos2 ]] && ((pos1 < pos2)); then
  assert_pass "Multi-file - file order preserved"
else
  assert_fail "Multi-file - file order should be preserved"
fi

# Error on nonexistent second file
set +e
./md2ansi /tmp/md2ansi_multi1.md /nonexistent_file.md >/dev/null 2>&1
multi_exit=$?
set -e
assert_equals "1" "$multi_exit" "Multi-file - nonexistent second file returns error"

# State doesn't leak between files (code block in file1 doesn't affect file2)
printf '```\nunclosed code\n' > /tmp/md2ansi_leak1.md
echo '# Normal Header' > /tmp/md2ansi_leak2.md
output=$(./md2ansi /tmp/md2ansi_leak1.md /tmp/md2ansi_leak2.md 2>/dev/null)
assert_contains "$output" "unclosed code" "Multi-file state leak - file1 code content"
assert_contains "$output" "Normal Header" "Multi-file state leak - file2 header renders"

# Cleanup temp files
rm -f /tmp/md2ansi_multi1.md /tmp/md2ansi_multi2.md /tmp/md2ansi_leak1.md /tmp/md2ansi_leak2.md

# ================================================================================
# 5. Unicode/multibyte in wrapping
# test_edge_cases.sh:178 checks UTF-8 presence but not wrapping behavior
# test_wrapping.sh has zero UTF-8 tests
# ================================================================================

# Accented characters in wrapped text preserve all content
output=$(printf '%s\n' "Héllo wörld, this is a tëst with àccented chàracters that should wrap properly" | ./md2ansi --width 30)
assert_contains "$output" "wörld" "Unicode wrapping - accented characters preserved"
assert_contains "$output" "properly" "Unicode wrapping - accented text wraps without data loss"

# Emoji characters in narrow width wrapping
output=$(printf '%s\n' "Here are some emoji: 🎉 one two three four five six seven" | ./md2ansi --width 30)
assert_contains "$output" "emoji" "Unicode wrapping - emoji text renders"
assert_contains "$output" "seven" "Unicode wrapping - text after emoji preserved"

# CJK characters handled without crash
output=$(printf '%s\n' "Some text with CJK: 中文 and more text that should wrap properly here" | ./md2ansi --width 30 2>&1)
assert_not_empty "$output" "Unicode wrapping - CJK characters do not crash"
assert_contains "$output" "text" "Unicode wrapping - CJK mixed text renders"

# UTF-8 in list items wraps correctly
output=$(printf '%s\n' "- This list item has üñîcödé characters and should wrap at narrow width properly" | ./md2ansi --width 30)
assert_contains "$output" "üñîcödé" "Unicode wrapping - UTF-8 in list items preserved"
assert_contains "$output" "properly" "Unicode wrapping - UTF-8 list item wraps completely"

#fin
