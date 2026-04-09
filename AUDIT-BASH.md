# Bash Code Audit — md2ansi

**Date:** 2026-04-09
**Script:** `/ai/scripts/Markdown/md2ansi.bash/md2ansi`
**Standard:** Bash Coding Standard (BCS) — `/usr/local/share/yatti/BCS/data/BASH-CODING-STANDARD.md`

## File Statistics

| Metric | Value |
|--------|-------|
| Total lines | 1,426 |
| Functions | 33 |
| ShellCheck | **CLEAN** (zero warnings) |
| `#shellcheck disable` directives | 4 (all documented) |
| `#bcscheck disable` directives | 3 (all documented) |

---

## Tool Results

### ShellCheck

```
shellcheck -x md2ansi → 0 warnings, 0 errors
```

All four `#shellcheck disable` directives are documented and justified:
- **SC2001** (line 248): `sed` used for ANSI stripping — regex too complex for `${var//}`
- **SC2034** (line 236): Syntax-highlight color vars appear unused in no-color branch
- **SC2034** (line 663): `table_lines` populated for nameref consumption
- **SC2178** (lines 843, 845): Nameref to array looks like scalar to ShellCheck

### bcscheck

*(Submitted; results pending — tool uses LLM backend, up to 10 min)*

---

## Findings

### F01 — BCS0107 VIOLATION — Function ordering: highlight functions after caller

**Lines:** 548 → 590, 615, 633
**Severity:** VIOLATION

`render_code_line()` (line 548) calls `highlight_python()`, `highlight_javascript()`, and `highlight_bash()`, but all three are defined **after** it (lines 590, 615, 633).

BCS0107 requires bottom-up organization: *"each function calls only previously defined functions."*

**Fix:** Move the three `highlight_*()` functions above `render_code_line()`.

---

### F02 — BCS0107 VIOLATION — Function ordering: table helpers after caller

**Lines:** 659 → 726, 798, 841, 922
**Severity:** VIOLATION

`render_table()` (line 659) calls `_parse_table_structure()` (726), `_calculate_column_widths()` (798), and `_render_table_output()` (841). Additionally, `_render_table_output()` calls `_align_cell()` (922). All helpers are defined **after** their callers.

**Fix:** Reorder to: `_align_cell()`, `_render_table_output()`, `_calculate_column_widths()`, `_parse_table_structure()`, then `render_table()`.

---

### F03 — BCS0405 VIOLATION — Unused variables

**Lines:** 223–227, 237
**Severity:** VIOLATION

Four syntax-highlighting color variables are declared but never referenced anywhere in the code:

| Variable | Line (color) | Line (no-color) |
|----------|-------------|-----------------|
| `COLOR_NUMBER` | 223 | 237 |
| `COLOR_FUNCTION` | 225 | 237 |
| `COLOR_CLASS` | 226 | 237 |
| `COLOR_BUILTIN` | 227 | 237 |

BCS0405: *"Remove unused functions and variables."* The `#shellcheck disable=SC2034` on line 236 suppresses ShellCheck but does not override BCS0405.

**Fix:** Remove these four variables from both the `if` and `else` branches. If future syntax highlighting needs them, add them back when they are actually referenced.

---

### F04 — BCS0501 WARNING — Explicit `== 0` instead of arithmetic negation

**Lines:** 557, 905, 1066, 1347, 1367
**Severity:** WARNING

BCS0501 prefers arithmetic truthiness over explicit comparisons:

| Line | Current | BCS Preferred |
|------|---------|---------------|
| 557 | `((OPTIONS[syntax_highlight] == 0))` | `((!OPTIONS[syntax_highlight]))` |
| 905 | `((row_num == 0 && _has_alignment))` | `((!row_num && _has_alignment))` |
| 1066 | `((OPTIONS[tables] == 0))` | `((!OPTIONS[tables]))` |
| 1347 | `((${#lines[@]} == 0))` | `((!${#lines[@]}))` |
| 1367 | `((${#lines[@]} == 0))` | `((!${#lines[@]}))` |

**Note:** All are functionally correct. This is a style preference, not a correctness issue.

---

### F05 — BCS0501 WARNING — `(($#==0))` instead of `((!$#))`

**Line:** 1311
**Severity:** WARNING

```bash
(($#==0)) || INPUT_FILES+=("$@")
```

BCS idiom: `(($#)) && INPUT_FILES+=("$@") ||:` or `((!$#)) || INPUT_FILES+=("$@")`.

---

### F06 — BCS1201 WARNING — Lines exceeding 120 characters

**Lines:** 237, 608, 626, 644 (+ 291, 315, 497 at 121 chars)
**Severity:** WARNING

| Line | Length | Context |
|------|--------|---------|
| 644 | 148 | `sed` for Bash keyword highlighting |
| 626 | 145 | `sed` for JavaScript keyword highlighting |
| 608 | 141 | `sed` for Python keyword highlighting |
| 237 | 128 | No-color branch `declare` for syntax colors |
| 291 | 121 | `sed` for link formatting |
| 315 | 121 | `sed` for footnote formatting |
| 497 | 121 | `printf` for task item rendering |

BCS1201: *"Lines under 120 characters (except URLs/paths)."*

**Fix:** Break `sed` patterns using line continuation (`\`) or intermediate variables. The no-color declare (line 237) could be split across two `declare` statements.

---

### F07 — BCS1205 WARNING — Excessive subprocess spawning in hot paths

**Lines:** 245–250 (`strip_ansi`), 277–319 (`colorize_line`)
**Severity:** WARNING

**`strip_ansi()` (line 245):** Forks `sed` on every call. Called from `visible_length()`, which is called per-word in `wrap_text()` and per-cell in table rendering. For a 200-line document with tables, this can spawn hundreds of `sed` processes.

**`colorize_line()` (line 277):** Spawns up to 10 `sed` subprocesses per line of markdown. Over a 500-line document, that is ~5,000 process forks.

BCS1205: *"Prefer shell builtins over external commands (10-100x faster)."*

**Possible optimization for `strip_ansi()`:**
```bash
strip_ansi() {
  local -- text=$1
  while [[ $text =~ $'\033\['[0-9\;]*[a-zA-Z] ]]; do
    text=${text/"$BASH_REMATCH"/}
  done
  echo "$text"
}
```

This eliminates the `sed` fork entirely. The `colorize_line()` sed calls are harder to replace with builtins due to complex regex, but caching or batching could reduce forks.

---

### F08 — BCS0107 WARNING — `usage()` placement

**Line:** 1203
**Severity:** WARNING

BCS0107 layer ordering places documentation functions (layer 2) before helper/utility functions (layer 3). `usage()` is defined at line 1203, after all business logic (layer 5). It is only called from `parse_arguments()` (line 1279), so this has no runtime impact.

**Fix:** Move `usage()` to after the messaging functions and before the utility functions (~line 82).

---

## Inline Suppressions — Verified

| Line | Directive | Scope | Justified? |
|------|-----------|-------|------------|
| 12 | `#bcscheck disable=BCS0103` | Line 13: `SCRIPT_NAME=${0##*/}` | ✓ Script doesn't need `SCRIPT_PATH`/`SCRIPT_DIR`; BCS0103 allows partial metadata |
| 72 | `#bcscheck disable=BCS0703` | Lines 73–80: Custom `debug()` | ✓ Adds timestamp/counter beyond standard `_msg()` dispatch |
| 259 | `#bcscheck disable=BCS0804` | Lines 1260–1329: `parse_arguments()` | ✓ Separate function acceptable for testability; `main()` delegates to it |

All three suppressions are reasonable and documented.

---

## Compliance by Section

| BCS Section | Status | Notes |
|-------------|--------|-------|
| 01 — Structure & Layout | ✓ PASS | Shebang, strict mode, metadata, main(), `#fin` all correct |
| 02 — Variables & Data Types | ✓ PASS | All variables typed, proper scoping, namerefs used correctly |
| 03 — Strings & Quoting | ✓ PASS | Single quotes for static, double for expansion, `@Q` for errors |
| 04 — Functions & Libraries | ▲ 3 findings | F01, F02 (ordering), F03 (unused vars), F08 (usage placement) |
| 05 — Control Flow | ▲ 2 findings | F04, F05 (arithmetic truthiness style) |
| 06 — Error Handling | ✓ PASS | Proper exit codes (3,4,8,9,13,22), trap with recursion guard |
| 07 — I/O & Messaging | ✓ PASS | `_msg()` dispatch, `>&2` at front, no stream mixing |
| 08 — Command-Line Arguments | ✓ PASS | `while (($#))`, `noarg`, bundling, `--` handling all correct |
| 09 — File Operations | ✓ PASS | `[[ ]]` for tests, proper quoting, process substitution |
| 10 — Security | ✓ PASS | PATH locked, no eval, input sanitized, file size limits |
| 11 — Concurrency & Jobs | N/A | No background jobs or parallel execution |
| 12 — Style & Development | ▲ 2 findings | F06 (line length), F07 (subprocess performance) |

---

## Executive Summary

**Overall Health Score: 8.5 / 10**

This is a well-written, production-quality Bash script that demonstrates strong BCS compliance. ShellCheck passes clean, strict mode is properly configured, security is solid (PATH locked, input sanitized, no eval), and the messaging/error-handling patterns are textbook BCS.

### What's Done Well

- **Security** (BCS §10): PATH locked with `declare -rx`, file size validation, ANSI sanitization, no `eval`, no SUID. Exemplary.
- **Error handling** (BCS §06): Correct BCS exit codes throughout, `die()` with context, trap with recursion guard.
- **Argument parsing** (BCS §08): Standard `while (($#))` pattern, `noarg` validation, short option bundling, `--` terminator.
- **Variable discipline** (BCS §02): All variables explicitly typed, proper `local` scoping, `readonly` after parsing.
- **End marker**: `#fin` present.

### Top Issues

1. **Function ordering** (F01, F02) — 7 functions defined after their callers. Easy reorder fix, no logic changes needed.
2. **4 unused color variables** (F03) — `COLOR_NUMBER`, `COLOR_FUNCTION`, `COLOR_CLASS`, `COLOR_BUILTIN` declared but never used.
3. **Subprocess performance** (F07) — `strip_ansi()` and `colorize_line()` fork many `sed` processes in hot loops. Replacing `strip_ansi()` with a builtin loop would give the biggest performance win.

### Quick Wins

- Remove 4 unused `COLOR_*` variables (F03) — 2 minutes
- Replace `== 0` with `((!var))` at 5 locations (F04) — 5 minutes
- Rewrite `strip_ansi()` with bash builtins (F07) — 15 minutes, significant perf gain

### Findings Summary

| Severity | Count | IDs |
|----------|-------|-----|
| VIOLATION | 3 | F01, F02, F03 |
| WARNING | 5 | F04, F05, F06, F07, F08 |
| **Total** | **8** | |
