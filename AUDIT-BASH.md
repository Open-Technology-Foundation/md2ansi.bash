# Bash Code Audit — md2ansi

**Date:** 2026-05-06
**Auditor:** Leet (Claude Code) via `/audit-bash`
**Target:** `/ai/scripts/Markdown/md2ansi.bash/md2ansi`
**Standard:** Bash Coding Standard (BCS) — `/usr/local/share/yatti/BCS/data/BASH-CODING-STANDARD.md`
**Predecessor:** `f93e321:AUDIT-BASH.md` (deleted in `14ac10d`)

## File Statistics

| Metric | Value |
|--------|-------|
| Total lines | 1,424 |
| File size | 41.7 KB |
| Functions | 35 |
| Distinct exit codes used | 6 (3, 4, 8, 9, 13, 22) |
| `#bcscheck disable` directives | 8 (all documented) |
| `#shellcheck disable` directives | 6 (all documented) |
| External dependencies | `tput`, `wc`, `sed`, `grep`, `timeout`, `less` (all coreutils/ncurses) |

---

## Executive Summary

**Overall Health Score: 8.5 / 10**

`md2ansi` is a production-quality, security-hardened, monolithic Bash script with strong BCS compliance. Strict mode is correctly configured, the messaging dispatch (`_msg`/`warn`/`error`/`die`) is concise, the argument parser is textbook BCS §08, and security baseline is exemplary (locked `PATH`, no `eval`, file-size cap, ANSI-injection sanitisation, ReDoS guard via `timeout`).

bcscheck (`balanced` model, `effort=medium`, `strict=off`) returned **3 [WARN], 0 [ERROR]**. ShellCheck (`-x`) is **clean** (zero warnings). Of the three findings, two are continuations of historical issues (F02, F03 from the prior audit); one is a **regression** introduced by commit `fefc6c0` (helper-collapse refactor) that simplified `die()` past the BCS0602 reference form.

### Top Issues

1. **`die()` regression — BCS0602** (md2ansi:59). Recent refactor stripped the `(($# < 2)) ||` guard and the `${1:-0}` default. Calling `die 0` (no message) emits a blank `error ""` line; calling bare `die` with no args triggers `set -u` unbound-variable failure before exit. Trivial 1-line fix.
2. **Function ordering — BCS0107** (md2ansi:658, 726, 798, 841, 922). Table renderer defines orchestrator before its helpers. No runtime impact (Bash resolves names at call time), but BCS requires bottom-up.
3. **Unused colour vars — BCS0405** (md2ansi:218–222, 232). Four declared, never read. Currently masked by `#shellcheck disable=SC2034` on line 231 — but BCS0405 takes precedence over the shellcheck suppression.

### Quick Wins (combined effort: ~10 min)
- Restore the BCS0602 `die()` form (1 line edit).
- Delete the four unused `COLOR_*` declarations and the matching `#shellcheck disable=SC2034`.

### What's Done Well
- **Security (BCS §10)**: `declare -rx PATH=...` + `declare -rx PS4=...` (md2ansi:7-8); no `eval`; `validate_file_size()` (md2ansi:118-134); `sanitize_ansi`/`strip_ansi` (md2ansi:240-263); ReDoS guard via `timeout` wrapper.
- **Error handling (BCS §06)**: `set -euo pipefail` + 4 `shopt`s (md2ansi:4-5); BCS0602-mapped exit codes; `cleanup` EXIT trap with recursion guard via `trap -` (md2ansi:144-150).
- **CLI parsing (BCS §08)**: `while (($#))` + `case`, `noarg` validator, `--` end-of-options handler, `-*) die 22` invalid-option fallback, bundled-short-option support `-[wDVht]?*` (md2ansi:1261-1330).
- **Variable discipline (BCS §02)**: every variable typed (`-i`/`-a`/`-A`/`-r`/`-rx`); proper `local` scoping; `readonly` after argument parsing (md2ansi:1390-1392).
- **Style (BCS §12)**: 2-space indent throughout (no tabs); standalone `var+=1` everywhere (zero `((var++))` or `((var+=1))`); `#fin` terminator present.

---

## Tool Output

### ShellCheck

```
$ shellcheck -x md2ansi
$ echo $?
0
```

Zero warnings. All six in-source `#shellcheck disable` directives carry inline justifications (see Suppression Review below).

### bcscheck

```
$ bcscheck md2ansi
bcs: ◉ Backend 'claude' inferred from model 'balanced'
bcs: ◉ Checking '/ai/scripts/Markdown/md2ansi.bash/md2ansi' against BCS (backend=claude)...
bcs: ◉ bcs check --model 'balanced' --effort 'medium' --strict 'off' '/ai/scripts/Markdown/md2ansi.bash/md2ansi'
bcs: ◉ Elapsed: 356s
bcs: ◉ Exit: 1
```

Three findings, all [WARN]. Verdict: respect-suppressed rules `BCS0103` (L12), `BCS0703` (L65), `BCS0207` (L176, L272, L604, L622, L642), `BCS0804` (L1260) — i.e. the eight in-source bcscheck disables are accepted as legitimate.

---

## Findings by Severity

### CRITICAL — none

### HIGH — none

### MEDIUM

#### M1 — BCS0602 regression: `die()` missing guard and default exit code

**Location:** `md2ansi:59`
**BCS code:** BCS0602 (recommended tier)
**Severity:** [WARN] · MEDIUM (regression)

```bash
# Current (md2ansi:59)
die() { error "${@:2}"; exit "$1"; }
```

Two deviations from the BCS0602 reference form:

1. **No `(($# < 2)) ||` guard** — `die 0` with no message fires `error ""` and emits a blank-prefixed error line.
2. **`exit "$1"` not `exit "${1:-0}"`** — bare `die` (zero args) hits `set -u` and crashes on the unbound `$1` *before* the intended exit, masking whatever error the caller meant to surface.

**Impact:** Cosmetic for the blank-message case; potentially hides intent in the bare-`die` case. No call site in the current script invokes `die` with fewer than two arguments, so the bug is latent rather than active — but the helper is part of the messaging contract used elsewhere in the BCS ecosystem.

**Provenance:** Introduced by commit `fefc6c0` ("refactor(md2ansi): collapse _msg/warn/error/die helpers"). The collapse was net-positive (≈20 lines saved) but truncated the BCS0602 boilerplate.

**Fix:**
```bash
die() { (($# < 2)) || error "${@:2}"; exit "${1:-0}"; }
```

Reuses existing `error` helper (md2ansi:58) — no new helpers required.

---

#### M2 — BCS0107: table helpers defined after orchestrator

**Location:** `md2ansi:658, 726, 798, 841, 922`
**BCS code:** BCS0107 (style tier)
**Severity:** [WARN] · MEDIUM
**Status:** Continuation of historical F02 (still present)

| Line | Function | Forward-references |
|------|----------|--------------------|
| 658 | `render_table` | calls `_parse_table_structure` (726), `_calculate_column_widths` (798), `_render_table_output` (841) |
| 841 | `_render_table_output` | calls `_align_cell` (922) |

BCS0107 mandates bottom-up: each function may call only previously defined functions. Bash's late binding makes this stylistic, not functional — but it lets reviewers trace data flow without scrolling forward.

**Fix:** Reorder the §645–951 table block:

```
_align_cell                 → first  (terminal)
_parse_table_structure      → second (terminal)
_calculate_column_widths    → third  (terminal)
_render_table_output        → fourth (calls _align_cell)
render_table                → last   (orchestrates above three)
```

Pure cut-and-paste; no logic changes.

---

#### M3 — BCS0405: four unused syntax-highlight colour variables

**Location:** `md2ansi:218, 220, 221, 222` (colour branch); `md2ansi:232` (no-colour branch)
**BCS code:** BCS0405 (style tier)
**Severity:** [WARN] · MEDIUM
**Status:** Continuation of historical F03 (still present)

```bash
# md2ansi:216-222 (colour branch)
declare -r  COLOR_KEYWORD=$'\033[38;5;204m' \
            COLOR_STRING=$'\033[38;5;114m' \
            COLOR_NUMBER=$'\033[38;5;220m' \      ← never read
            COLOR_COMMENT=$'\033[38;5;245m' \
            COLOR_FUNCTION=$'\033[38;5;81m' \     ← never read
            COLOR_CLASS=$'\033[38;5;214m' \       ← never read
            COLOR_BUILTIN=$'\033[38;5;147m'       ← never read

# md2ansi:231-232 (no-colour branch)
#shellcheck disable=SC2034
declare -r COLOR_KEYWORD='' COLOR_STRING='' COLOR_NUMBER='' COLOR_COMMENT='' COLOR_FUNCTION='' COLOR_CLASS='' COLOR_BUILTIN=''
```

`grep -n` confirms the four flagged variables appear only at their declaration sites (218/220/221/222 and 232). Each `highlight_*()` function reads only `COLOR_KEYWORD`, `COLOR_STRING`, `COLOR_COMMENT`, and `COLOR_CODEBLOCK`.

**BCS reference:** *"Remove unused functions and variables. This rule takes precedence over template completeness — do not add functions, variables, or color definitions from reference templates unless the script actually uses them."*

The `#shellcheck disable=SC2034` on line 231 silences shellcheck but does not override BCS0405.

**Fix:** Remove the four variables from both branches; remove the now-unnecessary `#shellcheck disable=SC2034`. Re-introduce them only when an actual highlight function references them.

---

### LOW — style/idiom

These are bcscheck-silent under `strict=off` but are flagged by manual review against the BCS style guidance. None affects correctness.

#### L1 — BCS0501: explicit `== 0` instead of arithmetic negation

**Locations:** `md2ansi:553, 905, 1067, 1348, 1368`

| Line | Current | BCS-preferred |
|------|---------|---------------|
| 553 | `((OPTIONS[syntax_highlight] == 0))` | `((!OPTIONS[syntax_highlight]))` |
| 905 | `((row_num == 0 && _has_alignment))` | `((!row_num && _has_alignment))` |
| 1067 | `((OPTIONS[tables] == 0))` | `((!OPTIONS[tables]))` |
| 1348 | `((${#lines[@]} == 0))` | `((!${#lines[@]}))` |
| 1368 | `((${#lines[@]} == 0))` | `((!${#lines[@]}))` |

Functionally equivalent; cosmetic.

#### L2 — BCS0501: `(($#==0))` idiom

**Location:** `md2ansi:1312`

```bash
(($#==0)) || INPUT_FILES+=("$@")
```

BCS-preferred: `((!$#)) || INPUT_FILES+=("$@")` or `(($#)) && INPUT_FILES+=("$@") ||:`.

#### L3 — BCS1201: lines exceeding 120 characters

| Line | Length | Context |
|------|--------|---------|
| 232  | 128 | `declare -r` of seven empty colour vars on the no-colour branch |
| 287  | 121 | `sed` for link-formatting regex |
| 311  | 121 | `sed` for footnote-formatting regex |
| 493  | 121 | `printf` for task-item rendering |
| 605  | 141 | `sed` for Python keyword highlighting |
| 624  | 145 | `sed` for JavaScript keyword highlighting |
| 643  | 148 | `sed` for Bash keyword highlighting |

The four `sed` lines (605/624/643) are the principal offenders and the reason for the five `#bcscheck disable=BCS0207` directives at lines 176, 272, 604, 623, 642. Splitting them with line-continuations or hoisting the regex into a variable would let those suppressions be removed.

#### L4 — BCS1205: subprocess churn in hot paths

**Locations:**
- `strip_ansi()` — md2ansi:240-247 (forks `sed` per call)
- `colorize_line()` — md2ansi:273-320 (up to 9 `sed` calls per line)

`strip_ansi` is invoked from `visible_length()` (md2ansi:249-255), which is called per-word in `wrap_text` and per-cell in table rendering. A 200-line markdown with tables can spawn hundreds of `sed` processes. Replacing `strip_ansi` with a pure-Bash regex loop would eliminate the fork overhead:

```bash
strip_ansi() {
  local -- text=$1
  while [[ $text =~ $'\033\['[0-9\;]*[a-zA-Z] ]]; do
    text=${text/"$BASH_REMATCH"/}
  done
  echo "$text"
}
```

`colorize_line` is harder to convert (complex regex), but caching results for repeated lines or batching `sed` calls would reduce forks.

Performance is "acceptable for terminal viewing" per the project's own CLAUDE.md ("~2-3x slower than Python for large files"); this is a Long-Term improvement, not a Quick Win.

---

## Pre-existing Findings — Status Check

Prior `f93e321:AUDIT-BASH.md` listed eight findings (F01–F08). Status against current `HEAD`:

| ID | BCS | Description | Verdict | Notes |
|----|-----|-------------|---------|-------|
| F01 | 0107 | `render_code_line` calls `highlight_python/javascript/bash` defined after it | **Structurally still present** at md2ansi:544 → 586/612/631; **NOT flagged** by current bcscheck run. Mark as **superseded** — bcscheck's authoritative verdict scopes BCS0107 to the table block only. Treat as cosmetic at most. |
| F02 | 0107 | Table helpers defined after `render_table` | **Still present** (M2 above). |
| F03 | 0405 | Four unused `COLOR_*` vars | **Still present** (M3 above). |
| F04 | 0501 | `((var == 0))` style | **Still present** (L1 above). Lines drifted: 557 → 553, 1066 → 1067, 1347 → 1348, 1367 → 1368 (905 unchanged). |
| F05 | 0501 | `(($#==0))` style | **Still present** (L2 above) at md2ansi:1312 (was 1311). |
| F06 | 1201 | Lines >120 chars | **Still present** (L3 above). Same 7 lines, line-numbers drifted by 1–4. |
| F07 | 1205 | Subprocess churn in `strip_ansi`/`colorize_line` | **Still present** (L4 above). |
| F08 | 0107 | `usage()` placement (now `show_help` at md2ansi:1204) | **Layer-ordering still atypical** but not flagged by bcscheck. Treat as cosmetic. |

**New finding** (not in prior audit): **M1 — BCS0602 `die()` regression** introduced by commit `fefc6c0`.

---

## Suppression-Directive Review

All 14 in-source disables (8 bcscheck, 6 shellcheck) reviewed individually:

### bcscheck

| Line | Code | Justification | Verdict |
|------|------|---------------|---------|
| 12 | BCS0103 | Script omits `SCRIPT_DIR`/`SCRIPT_PATH`; only `SCRIPT_NAME` needed. BCS0103 explicitly allows partial metadata. | ✓ Reasonable |
| 65 | BCS0703 | Custom `debug()` (md2ansi:66-73) adds timestamp + per-message counter beyond the BCS0703 reference. | ✓ Reasonable |
| 176 | BCS0207 | Below-it `if [[ -t 1 && -t 2 ]] || [[ -n ${TERM:-} && $TERM != dumb ]]` — bcscheck flags the chained TTY/TERM detection as parameter-expansion-style preference. | ✓ Reasonable |
| 272 | BCS0207 | `colorize_line()` body uses `sed` for regex inline-formatting; pure parameter-expansion would not handle nested patterns. | ✓ Reasonable |
| 604 | BCS0207 | `highlight_python` keyword `sed`. | ✓ Reasonable |
| 623 | BCS0207 | `highlight_javascript` keyword `sed`. | ✓ Reasonable |
| 642 | BCS0207 | `highlight_bash` keyword `sed`. | ✓ Reasonable |
| 1260 | BCS0804 | `parse_arguments()` separated from `main()` for testability; `main()` delegates with `parse_arguments "$@"`. | ✓ Reasonable |

### shellcheck

| Line | Rule | Justification | Verdict |
|------|------|---------------|---------|
| 231 | SC2034 | Suppresses unused-var warning for the no-colour-branch declarations. **Conflicts with BCS0405** — see M3. Recommend removing both the directive and the four flagged vars. | ⚠ Reconsider |
| 243 | SC2001 | `sed` for ANSI stripping; in-source comment notes "regex too complex for `${var//}`". | ✓ Reasonable |
| 662 | SC2034 | `local -a table_lines=()` populated for nameref consumption — shellcheck cannot follow the nameref. | ✓ Reasonable |
| 676 | SC2324 | `_md_idx+=1` on a nameref to `declare -i`; comment notes "BCS requires standalone var+=1". | ✓ Reasonable |
| 843, 845 | SC2178 | Nameref to array looks scalar to shellcheck. | ✓ Reasonable |

---

## Recommendations

### Quick wins (do these — under 10 min combined)

1. **Restore BCS0602 `die()` form** (md2ansi:59). One-line edit. Reuses existing `error` helper.
   ```bash
   die() { (($# < 2)) || error "${@:2}"; exit "${1:-0}"; }
   ```
2. **Delete unused colour variables** (md2ansi:218-222, 232) and the now-redundant `#shellcheck disable=SC2034` (md2ansi:231). Removes M3 and one shellcheck suppression.

### Long-term (worth scheduling, no urgency)

3. **Reorder table block** (md2ansi:645-951) bottom-up. Cleans M2 / F02 permanently.
4. **Hoist long `sed` regexes** (md2ansi:605, 624, 643) into named variables or split with backslash continuations. Removes three `#bcscheck disable=BCS0207` directives and brings L3 lines under 120 chars.
5. **Builtin `strip_ansi`** (md2ansi:240-247). Eliminates per-call `sed` fork; meaningful win on large tables.

### Out of scope (this audit)

- Companion utilities `md`, `ansi-info`, `md-link-extract`, `mdview` — separate audit cycles.
- Test harness `test/run_tests` and `test/test_*.sh`.
- Non-script artefacts: `Makefile`, `md2ansi.bash_completion`, `mdview.conf`, `rewrite-md-links.lua`.

---

## Verification Log

```bash
# Static analysis
shellcheck -x md2ansi          # exit 0, zero warnings
bcscheck md2ansi               # 356s, exit 1, 3 [WARN] findings

# File metrics
wc -l md2ansi                                                    # 1424
wc -c md2ansi                                                    # 42727
grep -cE '^[[:alnum:]_]+\s*\(\)\s*\{' md2ansi                    # 35

# BCS section walk
grep -nE '^[a-zA-Z_]+\(\)\s*\{' md2ansi                          # function-definition map
grep -nE 'COLOR_NUMBER|COLOR_FUNCTION|COLOR_CLASS|COLOR_BUILTIN' md2ansi  # F03 verification
grep -n -e 'bcscheck disable' -e 'shellcheck disable' md2ansi    # all 14 suppressions
grep -nE 'die\s+[0-9]' md2ansi                                   # exit-code inventory
awk 'length($0) > 120 { printf "%d: %d chars\n", NR, length($0) }' md2ansi  # L3
grep -nE '\(\(\+\+|\(\(.*\+\+\)\)|\(\(--' md2ansi                # forbidden ++ check (none)
grep -nE '^\s*\(\(.*\)\)\s*$' md2ansi                            # standalone (( )) (none)
grep -n 'eval' md2ansi                                           # eval check (none)
awk '/\t/ {print NR": tab found"}' md2ansi                       # tab check (none)
grep -nE 'function [a-zA-Z_]+\s*\(\)' md2ansi                    # function-keyword (none)

# Historical reference
git show f93e321:AUDIT-BASH.md                                   # prior audit content

# Read-only confirmation
git status                                                       # only AUDIT-BASH.md added
```

#fin
