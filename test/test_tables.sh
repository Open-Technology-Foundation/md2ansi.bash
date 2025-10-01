#!/usr/bin/env bash
# Table rendering tests for md2ansi Bash implementation
# This file is sourced by run_tests

test_section "Table Rendering"

# --------------------------------------------------------------------------------
# Simple table

input="| Col1 | Col2 |
|------|------|
| A    | B    |"

output=$(echo "$input" | ./md2ansi)
assert_contains "$output" "Col1" "Table header column 1"
assert_contains "$output" "Col2" "Table header column 2"
assert_contains "$output" "A" "Table data cell A"
assert_contains "$output" "B" "Table data cell B"
assert_contains "$output" "+" "Table has borders"

# --------------------------------------------------------------------------------
# Table with alignment

input="| Left | Center | Right |
|:-----|:------:|------:|
| A    | B      | C     |"

output=$(echo "$input" | ./md2ansi)
assert_contains "$output" "Left" "Left-aligned column header"
assert_contains "$output" "Center" "Center-aligned column header"
assert_contains "$output" "Right" "Right-aligned column header"
assert_contains "$output" "A" "Left-aligned data"
assert_contains "$output" "B" "Center-aligned data"
assert_contains "$output" "C" "Right-aligned data"

# --------------------------------------------------------------------------------
# Table with formatting in cells

input="| **Bold** | *Italic* | \`Code\` |
|----------|----------|---------|
| Text     | Text     | Text    |"

output=$(echo "$input" | ./md2ansi)
assert_contains "$output" "Bold" "Bold text in table cell"
assert_contains "$output" "Italic" "Italic text in table cell"
assert_contains "$output" "Code" "Code in table cell"

# --------------------------------------------------------------------------------
# Multiple row table

input="| Name  | Age |
|-------|-----|
| Alice | 30  |
| Bob   | 25  |
| Carol | 35  |"

output=$(echo "$input" | ./md2ansi)
assert_contains "$output" "Alice" "Multi-row table row 1"
assert_contains "$output" "Bob" "Multi-row table row 2"
assert_contains "$output" "Carol" "Multi-row table row 3"
assert_contains "$output" "30" "Multi-row table data 1"
assert_contains "$output" "25" "Multi-row table data 2"
assert_contains "$output" "35" "Multi-row table data 3"

# --------------------------------------------------------------------------------
# Table with empty cells

input="| Col1 | Col2 |
|------|------|
| A    |      |
|      | B    |"

output=$(echo "$input" | ./md2ansi)
assert_contains "$output" "A" "Table with empty cell - has data A"
assert_contains "$output" "B" "Table with empty cell - has data B"

# --------------------------------------------------------------------------------
# Wide table

input="| Column 1 | Column 2 | Column 3 | Column 4 | Column 5 |
|----------|----------|----------|----------|----------|
| Data 1   | Data 2   | Data 3   | Data 4   | Data 5   |"

output=$(echo "$input" | ./md2ansi)
assert_contains "$output" "Column 1" "Wide table column 1"
assert_contains "$output" "Column 5" "Wide table column 5"
assert_contains "$output" "Data 1" "Wide table data 1"
assert_contains "$output" "Data 5" "Wide table data 5"

# --------------------------------------------------------------------------------
# Table disable flag

output=$(echo "$input" | ./md2ansi --no-tables)
assert_not_empty "$output" "Table renders as plain text with --no-tables"

#fin
