#!/usr/bin/env bash
# ANSI color definitions for md2ansi
# This is a sourced library, not an executable script
# Version: 0.9.6-bash

# Detect terminal color support
# Multiple detection methods to handle different environments:
# 1. Check if stderr or stdout is a TTY
# 2. Check TERM variable (for piped/non-TTY but colorful terminals)
# 3. Verify terminal supports 256 colors via tput
declare -i HAS_COLOR=0

# Check if we have a terminal
if [[ -t 2 ]] || [[ -t 1 ]] || [[ -n ${TERM:-} && $TERM != "dumb" ]]; then
  declare -i color_count
  color_count=$(tput colors 2>/dev/null || echo 0)
  ((color_count >= 256)) && HAS_COLOR=1
fi

readonly -- HAS_COLOR

# --------------------------------------------------------------------------------
# Basic ANSI formatting codes
if ((HAS_COLOR)); then
  # Use $'...' syntax for ANSI escape sequences
  readonly -- ANSI_RESET=$'\033[0m'
  readonly -- ANSI_BOLD=$'\033[1m'
  readonly -- ANSI_DIM=$'\033[2m'
  readonly -- ANSI_ITALIC=$'\033[3m'
  readonly -- ANSI_UNDERLINE=$'\033[4m'
  readonly -- ANSI_STRIKE=$'\033[9m'

  # Header colors (H1-H6)
  readonly -- COLOR_H1=$'\033[38;5;226m'  # Bright yellow
  readonly -- COLOR_H2=$'\033[38;5;214m'  # Orange
  readonly -- COLOR_H3=$'\033[38;5;118m'  # Green
  readonly -- COLOR_H4=$'\033[38;5;21m'   # Blue
  readonly -- COLOR_H5=$'\033[38;5;93m'   # Purple
  readonly -- COLOR_H6=$'\033[38;5;239m'  # Dark gray

  # Element colors
  readonly -- COLOR_TEXT=$'\033[38;5;7m'        # Light gray
  readonly -- COLOR_BLOCKQUOTE=$'\033[48;5;236m'  # Dark background
  readonly -- COLOR_CODEBLOCK=$'\033[90m'       # Gray
  readonly -- COLOR_LIST=$'\033[36m'            # Cyan
  readonly -- COLOR_HR=$'\033[36m'              # Cyan
  readonly -- COLOR_TABLE=$'\033[90m'           # Gray
  readonly -- COLOR_LINK=$'\033[38;5;45m'       # Cyan-blue

  # Syntax highlighting colors
  readonly -- COLOR_KEYWORD=$'\033[38;5;204m'   # Pink
  readonly -- COLOR_STRING=$'\033[38;5;114m'    # Green
  readonly -- COLOR_NUMBER=$'\033[38;5;220m'    # Yellow
  readonly -- COLOR_COMMENT=$'\033[38;5;245m'   # Gray
  readonly -- COLOR_FUNCTION=$'\033[38;5;81m'   # Blue
  readonly -- COLOR_CLASS=$'\033[38;5;214m'     # Orange
  readonly -- COLOR_BUILTIN=$'\033[38;5;147m'   # Purple
else
  # No color support - all empty strings
  readonly -- ANSI_RESET=''
  readonly -- ANSI_BOLD=''
  readonly -- ANSI_DIM=''
  readonly -- ANSI_ITALIC=''
  readonly -- ANSI_UNDERLINE=''
  readonly -- ANSI_STRIKE=''

  readonly -- COLOR_H1=''
  readonly -- COLOR_H2=''
  readonly -- COLOR_H3=''
  readonly -- COLOR_H4=''
  readonly -- COLOR_H5=''
  readonly -- COLOR_H6=''

  readonly -- COLOR_TEXT=''
  readonly -- COLOR_BLOCKQUOTE=''
  readonly -- COLOR_CODEBLOCK=''
  readonly -- COLOR_LIST=''
  readonly -- COLOR_HR=''
  readonly -- COLOR_TABLE=''
  readonly -- COLOR_LINK=''

  readonly -- COLOR_KEYWORD=''
  readonly -- COLOR_STRING=''
  readonly -- COLOR_NUMBER=''
  readonly -- COLOR_COMMENT=''
  readonly -- COLOR_FUNCTION=''
  readonly -- COLOR_CLASS=''
  readonly -- COLOR_BUILTIN=''
fi

# --------------------------------------------------------------------------------
# Utility functions for ANSI handling

# Strip ANSI escape sequences from text
# Usage: strip_ansi "text with ANSI codes"
strip_ansi() {
  local -- text="$1"
  # Remove ANSI escape sequences: ESC [ ... letter
  sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' <<<"$text"
}

# Get visible length of text (without ANSI codes)
# Usage: visible_length "text with ANSI codes"
visible_length() {
  local -- text="$1"
  local -- stripped
  stripped=$(strip_ansi "$text")
  echo "${#stripped}"
}

# Sanitize input by removing ANSI sequences
# Usage: sanitize_ansi "user input"
sanitize_ansi() {
  local -- text="$1"
  strip_ansi "$text"
}

#fin
