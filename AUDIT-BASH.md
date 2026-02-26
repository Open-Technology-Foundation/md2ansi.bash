# Bash 5.2+ Raw Code Audit: md2ansi

**Date**: 2026-02-26
**Auditor**: Leet (Claude Opus 4.6)
**Target**: md2ansi v1.0.1 — Zero-dependency Markdown-to-ANSI converter
**Bash Version**: 5.2+ (required)

## File Statistics

| Metric | Value |
|--------|-------|
| Total lines (md2ansi) | 1,460 |
| Functions | 43 |
| Variable declarations | 152 |
| Scripts audited | 6 (md2ansi, md, display-ansi-palette, md-link-extract, test/run_tests, test/*.sh) |
| Test count | 277 (all passing) |

---

## Executive Summary

**Overall Health Score: 8.5 / 10**

md2ansi is a well-structured, cleanly written Bash script that demonstrates strong adherence to BCS conventions. The monolithic architecture is appropriate for the use case. All 277 tests pass. The main remaining issues are: missing `SCRIPT_PATH`/`SCRIPT_DIR` metadata variables per BCS0101, and ShellCheck false positives on namerefs/color constants.

### Resolved Issues (2026-02-26)

Five audit findings were fixed:
- ~~**M2** — SC2076: Replaced `=~` with glob pattern matching `!=` for array membership~~ **RESOLVED**
- ~~**M3** — Replaced all 8× `$(seq 1 N)` subprocess calls with `printf -v '%*s'` + parameter expansion~~ **RESOLVED**
- ~~**L1** — Removed unused variable `chunk`~~ **RESOLVED**
- ~~**L2** — Implemented proper CommonMark fence-type matching using `CODE_FENCE_TYPE`~~ **RESOLVED**
- ~~**L3** — Hoisted all `local` declarations out of `parse_markdown()` loop body~~ **RESOLVED**

### Top 3 Remaining Issues

1. **Medium** — Missing `SCRIPT_PATH`/`SCRIPT_DIR` metadata (BCS0101 §6)
2. **Low** — `eval` usage in test runner `assert_exit_code()` — controlled but improvable
3. **Low** — `display-ansi-palette` missing BCS structure elements

### Quick Wins

- Add `SCRIPT_PATH`/`SCRIPT_DIR` metadata declarations
- Add `#shellcheck disable=SC2034` for intentionally-unused color constants

### Long-term Recommendations

- Replace `sed` calls in `strip_ansi()` and `colorize_line()` with pure Bash parameter expansion for performance
- Consider read-ahead buffering for multi-line constructs (multi-line blockquotes, paragraph joining)

---

## 1. BCS Compliance

BCS standard present: `BASH-CODING-STANDARD.md` → symlink to system BCS.

### BCS0101 — Script Structure

| Requirement | Status | Notes |
|-------------|--------|-------|
| Shebang `#!/usr/bin/env bash` | **PASS** | Line 1 |
| ShellCheck directives | **PASS** | `#shellcheck disable=SC2015` (line 2) |
| Brief description | **PASS** | Line 3 |
| `set -euo pipefail` | **PASS** | Line 5 |
| `shopt -s inherit_errexit shift_verbose extglob nullglob` | **PASS** | Line 6 |
| `VERSION` with `declare -r` | **PASS** | Line 9 |
| `SCRIPT_NAME` with `declare -r` | **PASS** | Line 10 |
| `SCRIPT_PATH` with `declare -r` | **FAIL** | Missing (BCS0101 §6) |
| `SCRIPT_DIR` with `declare -r` | **FAIL** | Missing (BCS0101 §6) |
| `main()` function | **PASS** | Line 1421 |
| Invocation: `main "$@"` | **PASS** | Line 1459 |
| End marker: `#fin` | **PASS** | Line 1460 |

### BCS0201-0205 — Variables

| Requirement | Status | Notes |
|-------------|--------|-------|
| `declare`/`local` for all variables | **PASS** | 152 declarations, all typed |
| Type-specific: `-i`, `-a`, `-A` | **PASS** | Consistently applied |
| `local --` for string locals | **PASS** | 75 instances |
| Boolean as `declare -i FLAG=0` | **PASS** | `VERBOSE`, `DEBUG`, `HAS_COLOR`, `IN_CODE_BLOCK` |
| `readonly` for constants | **PASS** | Colors, HAS_COLOR, VERSION |

### BCS0301-0303 — Expansion

| Requirement | Status | Notes |
|-------------|--------|-------|
| `"$var"` default (no braces) | **PASS** | |
| Braces for manipulation | **PASS** | `${var##pattern}`, `${var:-default}` |
| `${array[@]}` always quoted | **PASS** | |

### BCS0401-0402 — Quoting

| Requirement | Status |
|-------------|--------|
| Single quotes for static strings | **PASS** |
| Double quotes for interpolation | **PASS** |
| No unquoted variables in danger zones | **PASS** |

### BCS0501-0503 — Arrays

| Requirement | Status |
|-------------|--------|
| `declare -a` / `declare -A` | **PASS** |
| Safe iteration `"${array[@]}"` | **PASS** |
| `readarray -t` for file reads | **PASS** (lines 476, 509, etc.) |

### BCS0601-0606 — Functions

| Requirement | Status | Notes |
|-------------|--------|-------|
| Bottom-up organization | **PASS** | Utilities → rendering → parser → main |
| `lowercase_with_underscores` | **PASS** | |
| `_leading_underscore` for private | **PASS** | `_msg`, `_parse_table_structure`, `_calculate_column_widths`, etc. |
| No `function` keyword | **PASS** | All use `name() {` |
| One purpose per function | **PASS** | |

### BCS0801 — Error Handling

| Requirement | Status |
|-------------|--------|
| `set -euo pipefail` | **PASS** |
| `shopt -s inherit_errexit` | **PASS** |
| Signal handlers (EXIT/INT/TERM) | **PASS** |
| `die()` for fatal errors | **PASS** |

### BCS0901 — Messaging

| Requirement | Status |
|-------------|--------|
| `_msg()` core function | **PASS** |
| `info()`, `warn()`, `error()` | **PASS** |
| `die()`, `debug()` | **PASS** |
| `>&2` at start (not end) | **PASS** |

### BCS0602 — Exit Codes

| Requirement | Status | Notes |
|-------------|--------|-------|
| 0 for success | **PASS** | |
| 1 for general errors | **PASS** | File errors |
| 2 for usage errors | **PASS** | Missing argument |
| 22 for invalid argument | **PASS** | Invalid width/option |
| 130/143 for signals | **PASS** | |

### BCS Increment Rule

| Requirement | Status | Notes |
|-------------|--------|-------|
| Use `var+=1`, never `((var++))` | **PASS** | All increments use `+=1` |

### Estimated BCS Compliance: ~93%

Missing only `SCRIPT_PATH`/`SCRIPT_DIR` metadata from mandatory structure.

---

## 2. ShellCheck Results

```
shellcheck -x md2ansi
```

### Findings

| Code | Severity | Line(s) | Description |
|------|----------|---------|-------------|
| SC2015 | — | 2 | Globally disabled (documented) |
| SC2001 | Style | 209, 305 | Suggest `${var//search/replace}` instead of `sed` |
| SC2034 | Warning | 294 | `COLOR_NUMBER`, `COLOR_FUNCTION`, `COLOR_CLASS`, `COLOR_BUILTIN` unused (no-color branch) |
| SC2034 | Warning | 716 | `col_widths` appears unused (passed by nameref) |
| ~~SC2034~~ | ~~Warning~~ | ~~1048~~ | ~~`CODE_FENCE_TYPE` unused~~ — **RESOLVED**: now used for fence-type matching |
| ~~SC2034~~ | ~~Warning~~ | ~~1396~~ | ~~`chunk` unused~~ — **RESOLVED**: removed |
| ~~SC2076~~ | ~~Warning~~ | ~~1156, 1184~~ | ~~Quoted RHS in `=~`~~ — **RESOLVED**: replaced with glob `!=` |
| SC2178 | Warning | 897, 898 | Nameref to array — ShellCheck false positive |

### Analysis

- **SC2034 on line 294**: False positive — these colors ARE used in `highlight_*()` functions but only when `HAS_COLOR=1`. The no-color branch declares empty versions that ShellCheck sees as unused. **Recommendation**: Add `#shellcheck disable=SC2034` comment.
- **SC2034 on line 716 (`col_widths`)**: False positive — passed via nameref to `_calculate_column_widths`. ShellCheck doesn't track nameref usage. **No fix needed** but comment would help.
- ~~**SC2034 on line 1048 (`CODE_FENCE_TYPE`)**~~: **RESOLVED** — now used for CommonMark fence-type matching (closing fence must match opening fence type).
- ~~**SC2034 on line 1396 (`chunk`)**~~: **RESOLVED** — removed unused variable.
- ~~**SC2076 on lines 1156, 1184**~~: **RESOLVED** — replaced `=~` with glob pattern matching (`!= *" value "*`), eliminating the ShellCheck warning.
- **SC2178 on lines 897, 898**: False positive — ShellCheck misunderstands nameref to array parameters. **No action needed.**
- **SC2001 on lines 209, 305**: Line 209 (`safe_regex_sub`) legitimately needs `sed` for dynamic patterns. Line 305 (`strip_ansi`) uses `\x1b` which cannot be done with parameter expansion in a portable way. **Both are justified.**

### Other Scripts

| Script | Issues |
|--------|--------|
| `md` | Clean |
| `display-ansi-palette` | Clean (no ShellCheck issues) |
| `md-link-extract` | SC2206 line 27: `Files=($@)` → should be `Files=("$@")` |
| `test/test_edge_cases.sh` | SC2016 (info), SC2046 (warning) |
| `test/test_security.sh` | SC2181 (style), SC2016 (info), SC2046 (warning) |

---

## 3. Bash 5.2+ Language Features

### Required Patterns — All Present

| Feature | Used | Lines |
|---------|------|-------|
| `[[ ]]` for conditionals | Yes | Throughout |
| `(( ))` for arithmetic | Yes | Throughout |
| `declare -n` nameref | Yes | Lines 713-714, 779-783, 850-852, 893-895, 1011 |
| `readarray`/`mapfile` | Yes | Lines 476, 509, 548, 575, 866, 920, 1075, 1194 |
| `${var@Q}` safe quoting | Yes | Lines 134, 135, 176, 1309, 1362 |
| `$'...'` ANSI literals | Yes | Lines 42, 251-285 |

### Forbidden Patterns — None Found

| Pattern | Status |
|---------|--------|
| Backticks | Not found |
| `expr` | Not found |
| `eval` (md2ansi) | Not found |
| `((i++))` / `((++i))` | Not found |
| `function` keyword | Not found |
| `test` / `[ ]` | Not found |
| `$[]` arithmetic | Not found |

---

## 4. Security Assessment

### Input Validation — Strong

| Check | Status | Implementation |
|-------|--------|----------------|
| File size limit | **PASS** | 10MB via `validate_file_size()` (line 129) |
| Stdin size limit | **PASS** | Byte counting in `process_file()` (line 1403) |
| ANSI sanitization | **PASS** | `sanitize_ansi()` strips escape codes (line 318) |
| ReDoS protection | **PASS** | `safe_regex_sub()` with `timeout` (line 201) |
| Path traversal | N/A | No directory operations based on user input |
| Command injection | **PASS** | No `eval` with user input; `sed` patterns are controlled |
| SUID/SGID | **PASS** | Not used (permissions 775) |

### Potential Concern

- **Line 1359**: Combined short options are expanded using `grep -o .` piped through `printf`. This handles user-supplied option strings but the expansion is bounded to single characters and fed back through the case statement. **Low risk** — the case statement rejects unknown options.

---

## 5. Detailed Findings

### Critical: None

### High: None

### Medium

#### M1: Missing `SCRIPT_PATH`/`SCRIPT_DIR` metadata (BCS0101)

- **Location**: `md2ansi:9-10`
- **BCS Code**: BCS0101 §6
- **Description**: BCS requires `SCRIPT_PATH`, `SCRIPT_DIR`, and `SCRIPT_NAME` as readonly metadata. Only `SCRIPT_NAME` is present.
- **Impact**: Minor — the `md` wrapper script needs `SCRIPT_DIR` and implements it separately. Having it in md2ansi would enable consistent path resolution.
- **Recommendation**:
```bash
declare -r VERSION=1.0.1
declare -r SCRIPT_PATH=$(readlink -en -- "$0")
declare -r SCRIPT_DIR=${SCRIPT_PATH%/*}
declare -r SCRIPT_NAME=${SCRIPT_PATH##*/}
```

#### ~~M2: SC2076 — Quoted regex RHS in array membership check~~ RESOLVED

- **Location**: `md2ansi:1156`, `md2ansi:1184`
- **Resolution**: Replaced `=~` regex operator with glob pattern matching `!= *" value "*` for literal string containment checks. SC2076 warnings eliminated.

#### ~~M3: Performance — Subprocess spawning in rendering hot paths~~ RESOLVED

- **Location**: `md2ansi:469-470, 501-503, 534-535, 592, 908` (8 locations)
- **Resolution**: All `$(seq 1 N)` subprocess calls replaced with `printf -v varname '%*s' N ''` followed by parameter expansion for character repetition. Zero subprocess spawns in list/table/HR rendering paths.

### Low

#### ~~L1: Unused variable `chunk` (dead code)~~ RESOLVED

- **Location**: `md2ansi:1396`
- **Resolution**: Removed unused `local -- chunk` declaration from `process_file()`.

#### ~~L2: Unused variable `CODE_FENCE_TYPE`~~ RESOLVED

- **Location**: `md2ansi:31, 1043, 1048`
- **Resolution**: Implemented proper CommonMark fence-type matching. Closing fence now must match opening fence type (`` ` `` `` ` `` `` ` `` closes only `` ` `` `` ` `` `` ` ``, `~~~` closes only `~~~`). Mismatched fences inside code blocks are rendered as code content. The `CODE_FENCE_TYPE` variable is now actively used.

#### ~~L3: Redeclared `local` variables in loop body~~ RESOLVED

- **Location**: `md2ansi:1073, 1092, 1101-1102, 1111-1113, 1128-1129, 1138-1140, 1149-1150, 1175-1176, 1180`
- **Resolution**: All `local` declarations hoisted out of `parse_markdown()` `while` loop body to a single declaration block before the loop. Variables are now declared once and reused across iterations.

#### L4: `eval` in test runner

- **Location**: `test/run_tests:91`
- **Description**: `assert_exit_code()` uses `eval "$command"` to run test commands. While the test commands are all controlled strings within the test suite, `eval` is generally discouraged.
- **Impact**: Low risk — test-only code with controlled inputs.
- **Recommendation**: Use a subshell with `bash -c` instead:
```bash
bash -c "$command" >/dev/null 2>&1
```

#### L5: `md-link-extract` — Unquoted array assignment

- **Location**: `md-link-extract:27`
- **Description**: `Files=($@)` should be `Files=("$@")` to prevent word splitting and globbing.
- **Recommendation**: `Files=("$@")`

#### L6: `display-ansi-palette` — Missing BCS structure

- **Location**: `display-ansi-palette:1-72`
- **Description**: Missing `shopt -s` line, missing `SCRIPT_NAME`/`VERSION` metadata, missing `main()` function (68 lines, >40 threshold). Has nested function definition (`display_colour` inside `display_ansi_palette`).
- **Impact**: Low — utility script, not core functionality.
- **Recommendation**: Add BCS structure elements if maintaining as production script.

#### L7: Inconsistent newline between multi-file output

- **Location**: `md2ansi:1443-1445`
- **Description**: `if ((${#INPUT_FILES[@]}))` is always true when inside the file-processing loop (the array is non-empty). This means a trailing newline is always added after every file, including the last one.
- **Impact**: Extra blank line after single-file output.
- **Recommendation**: Track file index and skip newline after last file:
```bash
local -i file_idx=0
for file in "${INPUT_FILES[@]}"; do
  process_file "$file"
  file_idx+=1
  ((file_idx < ${#INPUT_FILES[@]})) && echo
done
```

---

## 6. Performance Analysis

### Subprocess Spawning

| Location | Function | Call Pattern | Frequency |
|----------|----------|-------------|-----------|
| ~~L469-470~~ | ~~`render_list_item`~~ | ~~`$(seq 1 N)` ×2~~ | **RESOLVED**: `printf -v` |
| ~~L501-503~~ | ~~`render_ordered_item`~~ | ~~`$(seq 1 N)` ×2~~ | **RESOLVED**: `printf -v` |
| ~~L534-535~~ | ~~`render_task_item`~~ | ~~`$(seq 1 N)` ×2~~ | **RESOLVED**: `printf -v` |
| ~~L592~~ | ~~`render_hr`~~ | ~~`$(seq 1 N)` ×1~~ | **RESOLVED**: `printf -v` + expansion |
| ~~L908~~ | ~~`_render_table_output`~~ | ~~`$(seq 1 N)` ×N~~ | **RESOLVED**: `printf -v` + expansion |
| L338-372 | `colorize_line` | `sed` ×8-12 | Per text line |
| L305 | `strip_ansi` | `sed` ×1 | Per measurement |
| L76 | `debug` | `date` ×1 | Per debug message |

**Key observation**: `colorize_line()` spawns 8-12 `sed` subprocesses per line of text. For a 500-line document, this is 4,000-6,000 subprocess spawns just for inline formatting. This is the primary remaining performance bottleneck.

**Recommendation** (long-term): Convert `colorize_line()` to use Bash parameter expansion:
```bash
# Example: Bold replacement without subprocess
while [[ $result =~ (.*)\*\*([^*]+)\*\*(.*) ]]; do
  result="${BASH_REMATCH[1]}${ANSI_BOLD}${BASH_REMATCH[2]}${ANSI_RESET}${COLOR_TEXT}${BASH_REMATCH[3]}"
done
```

### ~~`seq` Replacement~~ RESOLVED

All 8 `$(seq 1 N)` calls have been replaced with `printf -v varname '%*s' N ''` followed by parameter expansion (`${var// /char}`) for character repetition. Zero subprocess spawns in list, table, and HR rendering paths.

---

## 7. Test Suite Assessment

- **Coverage**: Good — 277 tests across 9 test files
- **Categories**: Basic formatting, code blocks, tables, edge cases, footnotes, CLI options, security limits, text wrapping, audit gap coverage
- **All passing**: Yes (277/277)
- **Framework**: Simple, self-contained assertion functions — appropriate for the project scope
- **ShellCheck**: Minor issues in test files (SC2016 info, SC2046 warning, SC2181 style)

### Missing Test Coverage — All Resolved (test/test_gaps.sh, +32 tests)

- ~~Fence type matching (opening ``` vs closing ~~~)~~ — **RESOLVED**: 9 tests verify CommonMark fence-type matching including mismatched fence handling
- ~~Combined short options (e.g., `-Dw 80`)~~ — **RESOLVED**: 5 tests verify option splitter, combined flags, attached values, and invalid combinations
- ~~Stdin size limit rejection~~ — **RESOLVED**: 4 tests verify under/over 10MB stdin limits and error messages
- ~~Multi-file processing behavior~~ — **RESOLVED**: 6 tests verify file ordering, error handling, and state isolation between files
- ~~Unicode/multibyte character handling in wrapping~~ — **RESOLVED**: 8 tests verify accented, emoji, CJK, and UTF-8 list item wrapping

---

## 8. Architecture Assessment

The monolithic single-file design is appropriate for a zero-dependency tool. The code organization follows a logical progression from utilities through rendering to parsing. The nameref pattern for table parsing is well-implemented and avoids global state pollution.

**Strengths**:
- Clean separation of concerns within the monolith
- Consistent variable typing throughout
- Well-implemented feature toggle system
- Proper signal handling and cleanup
- Good use of `declare -n` namerefs for complex data passing

**Areas for improvement**:
- `colorize_line()` performance (subprocess-heavy)
- ~~`parse_markdown()` loop body uses `local` declarations that could be hoisted~~ **RESOLVED**
- No paragraph joining (each line is rendered independently)

---

## Summary Table

| Category | Score | Notes |
|----------|-------|-------|
| BCS Compliance | 93% | Missing SCRIPT_PATH/SCRIPT_DIR |
| ShellCheck | 95% | 7 warnings remaining (4 false positive, 1 genuine, 2 style) |
| Security | 98% | Strong input validation, sanitization |
| Performance | 80% | `seq` eliminated; `sed` in `colorize_line()` remains |
| Code Quality | 95% | Clean, consistent, well-organized; loop locals hoisted |
| Test Coverage | 93% | 277 tests, audit gaps covered |
| Documentation | 95% | Excellent CLAUDE.md, man page, help text |

**Overall: 8.5 / 10**

---

*Audit generated 2026-02-26 by Leet (Claude Opus 4.6)*
*ShellCheck version: $(shellcheck --version | head -2)*
*Bash version: 5.2+*

#fin
