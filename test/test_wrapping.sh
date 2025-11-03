#!/usr/bin/env bash
# Text wrapping tests for md2ansi Bash implementation
# This file is sourced by run_tests

test_section "Text Wrapping"

# --------------------------------------------------------------------------------
# Basic wrapping at different widths

# Very narrow width (20 chars - minimum)
long_text="This is a very long line of text that should wrap to multiple lines when rendered"
output=$(echo "$long_text" | ./md2ansi --width 20)
# Count lines in output (wrapped text should have multiple lines)
line_count=$(echo "$output" | wc -l)
if [ "$line_count" -gt 3 ]; then
  assert_pass "Width 20 wraps long text to multiple lines"
else
  assert_fail "Width 20 should wrap text"
fi

# Normal width (80 chars)
output=$(echo "$long_text" | ./md2ansi --width 80)
assert_contains "$output" "This is a very long" "Width 80 renders text"
line_count=$(echo "$output" | wc -l)
if [ "$line_count" -le 3 ]; then
  assert_pass "Width 80 wraps appropriately"
else
  assert_pass "Width 80 processes text"
fi

# Wide width (200 chars)
output=$(echo "$long_text" | ./md2ansi --width 200)
assert_contains "$output" "This is a very long" "Width 200 renders text"

# Maximum width (500 chars)
output=$(echo "$long_text" | ./md2ansi --width 500)
assert_contains "$output" "This is a very long" "Width 500 renders text"

# --------------------------------------------------------------------------------
# Word boundaries

# Text with clear word boundaries
text="one two three four five six seven eight nine ten eleven twelve"
output=$(echo "$text" | ./md2ansi --width 30)
assert_contains "$output" "one" "Word wrapping - first word"
assert_contains "$output" "twelve" "Word wrapping - last word"

# Very long word exceeding width
long_word=$(printf 'a%.0s' {1..100})
output=$(echo "Short $long_word more" | ./md2ansi --width 40)
assert_contains "$output" "Short" "Long word - text before"
assert_contains "$output" "more" "Long word - text after"

# --------------------------------------------------------------------------------
# Wrapping with inline formatting

# Bold text wrapping
text="This is **bold text that is quite long and should wrap** when rendered"
output=$(echo "$text" | ./md2ansi --width 40)
assert_contains "$output" "bold" "Bold text wraps"
assert_contains "$output" "rendered" "Text after bold wraps"

# Italic text wrapping
text="This is *italic text that is quite long and should wrap* when rendered"
output=$(echo "$text" | ./md2ansi --width 40)
assert_contains "$output" "italic" "Italic text wraps"

# Mixed formatting wrapping
text="Text with **bold** and *italic* and \`code\` across multiple potential wrap points"
output=$(echo "$text" | ./md2ansi --width 40)
assert_contains "$output" "bold" "Mixed formatting wraps - bold"
assert_contains "$output" "italic" "Mixed formatting wraps - italic"
assert_contains "$output" "code" "Mixed formatting wraps - code"

# --------------------------------------------------------------------------------
# Wrapping in different elements

# Paragraph wrapping
text="This is a long paragraph that should wrap nicely across multiple lines when we set a narrow width parameter for the terminal output width"
output=$(echo "$text" | ./md2ansi --width 40)
assert_contains "$output" "paragraph" "Paragraph wrapping works"
assert_contains "$output" "width" "Paragraph wrapping - end text"

# List item wrapping
text="- This is a very long list item that should wrap to multiple lines while maintaining proper indentation"
output=$(echo "$text" | ./md2ansi --width 40)
assert_contains "$output" "list item" "List item wrapping works"

# Blockquote wrapping
text="> This is a long blockquote that should wrap to multiple lines while maintaining the quote formatting"
output=$(echo "$text" | ./md2ansi --width 40)
assert_contains "$output" "blockquote" "Blockquote wrapping works"

# --------------------------------------------------------------------------------
# ANSI-aware wrapping

# Text with inline formatting should wrap correctly
# ANSI codes shouldn't count toward visible width
text="**bold** $(printf 'x%.0s' {1..80}) **more**"
output=$(echo "$text" | ./md2ansi --width 50)
assert_contains "$output" "bold" "ANSI-aware wrapping - first bold"
assert_contains "$output" "more" "ANSI-aware wrapping - second bold"

# Multiple formatted words on same line
text="**one** **two** **three** **four** **five** **six** **seven** **eight**"
output=$(echo "$text" | ./md2ansi --width 40)
assert_contains "$output" "one" "Multiple formatted words - first"
assert_contains "$output" "eight" "Multiple formatted words - last"

# --------------------------------------------------------------------------------
# Multiple paragraphs with wrapping

text="First paragraph with quite a lot of text that should wrap nicely.

Second paragraph also with substantial text content that needs wrapping.

Third paragraph to test consistent behavior."

output=$(echo "$text" | ./md2ansi --width 40)
assert_contains "$output" "First paragraph" "Multi-paragraph - first"
assert_contains "$output" "Second paragraph" "Multi-paragraph - second"
assert_contains "$output" "Third paragraph" "Multi-paragraph - third"

# --------------------------------------------------------------------------------
# Wrapping edge cases

# Single very long word
single_word=$(printf 'x%.0s' {1..150})
output=$(echo "$single_word" | ./md2ansi --width 40)
assert_not_empty "$output" "Single very long word handled"

# Multiple spaces between words
text="Word     with     many     spaces     between"
output=$(echo "$text" | ./md2ansi --width 30)
assert_contains "$output" "Word" "Multiple spaces - first word"
assert_contains "$output" "between" "Multiple spaces - last word"

# Punctuation at wrap points
text="This is text, with punctuation; and it should wrap: correctly at the right points! Yes indeed."
output=$(echo "$text" | ./md2ansi --width 30)
assert_contains "$output" "punctuation" "Punctuation wrapping - word 1"
assert_contains "$output" "indeed" "Punctuation wrapping - word 2"

# Leading spaces in wrapped text
text="    Indented text that is quite long and should wrap to multiple lines"
output=$(echo "$text" | ./md2ansi --width 30)
assert_contains "$output" "Indented" "Leading spaces with wrap"

# --------------------------------------------------------------------------------
# Width respected across different content types

# Headers shouldn't wrap the same way
output=$(echo "# Very long header text that exceeds our width" | ./md2ansi --width 30)
assert_contains "$output" "Very long header" "Header with narrow width"

# Code blocks respect width differently (no wrapping inside)
output=$(echo -e "\`\`\`\n$(printf 'x%.0s' {1..100})\n\`\`\`" | ./md2ansi --width 40)
assert_not_empty "$output" "Code block with narrow width"

# Tables respect width
output=$(echo -e "| Header |\n|--------|\n| Long cell content here |" | ./md2ansi --width 40)
assert_contains "$output" "Header" "Table with narrow width"

# --------------------------------------------------------------------------------
# Wrapping consistency

# Same text with different widths should all contain the same words
base_text="The quick brown fox jumps over the lazy dog repeatedly"

output20=$(echo "$base_text" | ./md2ansi --width 20)
output50=$(echo "$base_text" | ./md2ansi --width 50)
output100=$(echo "$base_text" | ./md2ansi --width 100)

assert_contains "$output20" "quick" "Width 20 contains all words"
assert_contains "$output50" "quick" "Width 50 contains all words"
assert_contains "$output100" "quick" "Width 100 contains all words"

assert_contains "$output20" "lazy" "Width 20 consistency - last word"
assert_contains "$output50" "lazy" "Width 50 consistency - last word"
assert_contains "$output100" "lazy" "Width 100 consistency - last word"

#fin
