#!/usr/bin/env bash
# Edge case and error handling tests for md2ansi Bash implementation
# This file is sourced by run_tests

test_section "Edge Cases and Error Handling"

# --------------------------------------------------------------------------------
# Empty and whitespace input

# Completely empty file
output=$(echo "" | ./md2ansi)
assert_exit_code 0 "echo '' | ./md2ansi" "Empty input returns success"

# Whitespace only
output=$(echo "   " | ./md2ansi)
assert_exit_code 0 "echo '   ' | ./md2ansi" "Whitespace-only input succeeds"

# Multiple blank lines
output=$(echo -e "\n\n\n" | ./md2ansi)
assert_exit_code 0 "echo -e '\\n\\n\\n' | ./md2ansi" "Multiple blank lines succeed"

# --------------------------------------------------------------------------------
# Code block edge cases

# Unclosed code block (file ends mid-block)
output=$(echo -e "\`\`\`python\ndef test():\n    pass" | ./md2ansi)
assert_contains "$output" "def" "Unclosed code block renders content"

# Code block with no content
output=$(echo -e "\`\`\`\n\`\`\`" | ./md2ansi)
assert_exit_code 0 "echo -e '\`\`\`\\n\`\`\`' | ./md2ansi" "Empty code block succeeds"

# Code block at end without trailing newline
printf '```\ncode\n```' | ./md2ansi >/dev/null
assert_exit_code 0 "printf '\`\`\`\\ncode\\n\`\`\`' | ./md2ansi >/dev/null" "Code block without trailing newline"

# Mixed fence types (open with ```, close with ~~~)
output=$(echo -e "\`\`\`\ncode\n~~~" | ./md2ansi 2>&1)
# Should handle gracefully
assert_not_empty "$output" "Mixed fence types handled"

# Nested-looking code fences
output=$(echo -e "\`\`\`\nOuter \`\`\` fence\n\`\`\`" | ./md2ansi)
assert_contains "$output" "fence" "Nested fence markers in code handled"

# Code block with very long language specifier
long_lang=$(printf 'python%.0s' {1..50})
output=$(echo -e "\`\`\`$long_lang\ncode\n\`\`\`" | ./md2ansi)
assert_contains "$output" "code" "Very long language specifier handled"

# --------------------------------------------------------------------------------
# Table edge cases

# Table without alignment row
output=$(echo -e "| A | B |\n| 1 | 2 |" | ./md2ansi)
assert_contains "$output" "A" "Table without alignment row - header"
assert_contains "$output" "1" "Table without alignment row - data"

# Misaligned column counts
output=$(echo -e "| A | B |\n|---|---|\n| 1 | 2 | 3 |" | ./md2ansi)
assert_contains "$output" "A" "Misaligned columns - renders header"
assert_contains "$output" "1" "Misaligned columns - renders data"

# Table with only header
output=$(echo -e "| Header |\n|--------|" | ./md2ansi)
assert_contains "$output" "Header" "Table with only header renders"

# Table at end of file without trailing newline
printf '| A | B |\n|---|---|\n| 1 | 2 |' | ./md2ansi >/dev/null
assert_exit_code 0 "printf '| A |\\n|---|\\n| 1 |' | ./md2ansi >/dev/null" "Table without trailing newline"

# Table with very wide cell content
wide_cell=$(printf 'x%.0s' {1..200})
output=$(echo -e "| A | B |\n|---|---|\n| $wide_cell | short |" | ./md2ansi)
assert_contains "$output" "short" "Very wide table cell handled"

# Empty table cells
output=$(echo -e "| A | B |\n|---|---|\n| 1 |  |\n|  | 2 |" | ./md2ansi)
assert_contains "$output" "1" "Empty table cells - renders present data"
assert_contains "$output" "2" "Empty table cells - handles empty cells"

# --------------------------------------------------------------------------------
# List edge cases

# Deeply nested lists (5 levels)
output=$(echo -e "- Level 1\n  - Level 2\n    - Level 3\n      - Level 4\n        - Level 5" | ./md2ansi)
assert_contains "$output" "Level 1" "Deeply nested lists - level 1"
assert_contains "$output" "Level 5" "Deeply nested lists - level 5"

# Empty list items
output=$(echo -e "- \n- Item\n- " | ./md2ansi)
assert_contains "$output" "Item" "Empty list items handled"

# List item with very long content
long_item=$(printf 'word %.0s' {1..100})
output=$(echo "- $long_item" | ./md2ansi)
assert_contains "$output" "word" "Very long list item handled"

# Mixed list markers
output=$(echo -e "- Item 1\n* Item 2\n+ Item 3" | ./md2ansi)
assert_contains "$output" "Item 1" "Mixed markers - dash"
assert_contains "$output" "Item 2" "Mixed markers - asterisk"
assert_contains "$output" "Item 3" "Mixed markers - plus"

# Ordered list with large numbers
output=$(echo -e "1. First\n99. Ninety-nine\n1000. Thousand" | ./md2ansi)
assert_contains "$output" "First" "Large numbers - first"
assert_contains "$output" "Ninety-nine" "Large numbers - ninety-nine"
assert_contains "$output" "Thousand" "Large numbers - thousand"

# --------------------------------------------------------------------------------
# Header edge cases

# Header with trailing hashes
output=$(echo "# Header #" | ./md2ansi)
assert_contains "$output" "Header" "Header with trailing hash"

# Header with no space after hash
output=$(echo "#NoSpace" | ./md2ansi)
# May or may not render as header
assert_not_empty "$output" "Header without space handled"

# Very long header
long_header=$(printf 'word %.0s' {1..100})
output=$(echo "# $long_header" | ./md2ansi)
assert_contains "$output" "word" "Very long header handled"

# Setext-style headers (underline with = or -)
output=$(echo -e "Header 1\n========" | ./md2ansi)
assert_contains "$output" "Header 1" "Setext H1 style renders"

output=$(echo -e "Header 2\n--------" | ./md2ansi)
assert_contains "$output" "Header 2" "Setext H2 style renders"

# --------------------------------------------------------------------------------
# Link and image edge cases

# Link with no URL
output=$(echo "[link]()" | ./md2ansi)
assert_contains "$output" "link" "Link with empty URL renders text"

# Link with very long URL (500 chars)
long_url=$(printf 'http://example.com/%s' $(printf 'a%.0s' {1..500}))
output=$(echo "[link]($long_url)" | ./md2ansi)
assert_contains "$output" "link" "Link with very long URL handled"

# Image with special characters in alt text
output=$(echo '![Alt "with" special <chars>](image.png)' | ./md2ansi)
assert_contains "$output" "with" "Image with special chars in alt text"

# --------------------------------------------------------------------------------
# Inline formatting edge cases

# Unmatched formatting markers
output=$(echo "**bold without close" | ./md2ansi)
assert_contains "$output" "bold" "Unmatched bold marker handled"

output=$(echo "*italic without close" | ./md2ansi)
assert_contains "$output" "italic" "Unmatched italic marker handled"

# Multiple consecutive formatting markers
output=$(echo "***three asterisks***" | ./md2ansi)
assert_contains "$output" "three" "Three consecutive asterisks handled"

# Formatting markers with no content
output=$(echo "Text **** more" | ./md2ansi)
assert_contains "$output" "Text" "Empty formatting markers - before"
assert_contains "$output" "more" "Empty formatting markers - after"

# Escaped formatting
output=$(echo "\\*not italic\\*" | ./md2ansi)
assert_contains "$output" "not italic" "Escaped asterisks handled"

# --------------------------------------------------------------------------------
# Special characters and encoding

# UTF-8 characters
output=$(echo "Text with émojis 🎉 and ümlauts" | ./md2ansi)
assert_contains "$output" "Text" "UTF-8 characters - basic text"
assert_not_empty "$output" "UTF-8 characters handled"

# Multiple consecutive spaces
output=$(echo "Text     with     spaces" | ./md2ansi)
assert_contains "$output" "Text" "Multiple spaces handled"

# Tabs
output=$(echo -e "Text\twith\ttabs" | ./md2ansi)
assert_contains "$output" "Text" "Tabs handled"

# Line endings (CRLF vs LF)
output=$(printf "Line 1\r\nLine 2" | ./md2ansi)
assert_contains "$output" "Line 1" "CRLF line endings - line 1"
assert_contains "$output" "Line 2" "CRLF line endings - line 2"

# --------------------------------------------------------------------------------
# Mixed content edge cases

# Everything mixed together
output=$(echo -e "# Header\n\n**Bold** and *italic*\n\n\`\`\`\ncode\n\`\`\`\n\n- List\n\n> Quote" | ./md2ansi)
assert_contains "$output" "Header" "Mixed content - header"
assert_contains "$output" "Bold" "Mixed content - bold"
assert_contains "$output" "italic" "Mixed content - italic"
assert_contains "$output" "code" "Mixed content - code"
assert_contains "$output" "List" "Mixed content - list"
assert_contains "$output" "Quote" "Mixed content - quote"

#fin
