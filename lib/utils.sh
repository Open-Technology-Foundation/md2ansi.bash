#!/usr/bin/env bash
# Utility functions for md2ansi
# This is a sourced library, not an executable script
# Version: 0.9.6-bash

# --------------------------------------------------------------------------------
# Message colors (independent of ANSI color library)
if [[ -t 1 && -t 2 ]]; then
  declare -- RED=$'\033[0;31m'
  declare -- GREEN=$'\033[0;32m'
  declare -- YELLOW=$'\033[0;33m'
  declare -- CYAN=$'\033[0;36m'
  declare -- NC=$'\033[0m'
else
  declare -- RED='' GREEN='' YELLOW='' CYAN='' NC=''
fi
readonly -- RED GREEN YELLOW CYAN NC

# --------------------------------------------------------------------------------
# Core messaging functions

# Internal message function using FUNCNAME for context
_msg() {
  local -- prefix="${SCRIPT_NAME}:" msg
  case "${FUNCNAME[1]}" in
    success) prefix+=" ${GREEN}✓${NC}" ;;
    warn)    prefix+=" ${YELLOW}⚡${NC}" ;;
    info)    prefix+=" ${CYAN}◉${NC}" ;;
    error)   prefix+=" ${RED}✗${NC}" ;;
    debug)   prefix+=" ${YELLOW}DEBUG${NC}:" ;;
    *) ;;
  esac
  for msg in "$@"; do
    printf '%s %s\n' "$prefix" "$msg"
  done
}

# Conditional output based on verbosity
vecho()   { ((VERBOSE)) || return 0; _msg "$@"; }
success() { ((VERBOSE)) || return 0; >&2 _msg "$@"; }
warn()    { ((VERBOSE)) || return 0; >&2 _msg "$@"; }
info()    { ((VERBOSE)) || return 0; >&2 _msg "$@"; }

# Debug output with timestamp
debug() {
  ((DEBUG)) || return 0
  local -- timestamp
  timestamp=$(date +%H:%M:%S.%3N 2>/dev/null || date +%H:%M:%S)
  >&2 printf '[%s] [DEBUG] %s\n' "$timestamp" "$*"
}

# Unconditional output
error() { >&2 _msg "$@"; }

# Exit with error
die() {
  (($# > 1)) && error "${@:2}"
  exit "${1:-0}"
}

# --------------------------------------------------------------------------------
# Terminal detection functions

# Get terminal width with multiple fallback methods
# Returns: width as integer (bounds: 20-500)
get_terminal_width() {
  local -i width=80

  # Method 1: tput cols
  width=$(tput cols 2>/dev/null || echo 0)
  if ((width > 0)); then
    ((width < 20)) && width=20
    ((width > 500)) && width=500
    debug "Terminal width from tput: $width"
    echo "$width"
    return 0
  fi

  # Method 2: stty size
  if [[ -t 1 ]]; then
    read -r _ width < <(stty size 2>/dev/null || echo "0 0")
    if ((width > 0)); then
      ((width < 20)) && width=20
      ((width > 500)) && width=500
      debug "Terminal width from stty: $width"
      echo "$width"
      return 0
    fi
  fi

  # Method 3: COLUMNS environment variable
  width=${COLUMNS:-80}
  ((width < 20)) && width=20
  ((width > 500)) && width=500
  debug "Terminal width from COLUMNS or default: $width"
  echo "$width"
}

# --------------------------------------------------------------------------------
# File validation functions

# Validate file exists, is readable, and within size limits
# Usage: validate_file_size "filepath" max_size_bytes
validate_file_size() {
  local -- filepath="$1"
  local -i max_size="$2"
  local -i file_size

  [[ -f "$filepath" ]] || die 1 "File not found: '$filepath'"
  [[ -r "$filepath" ]] || die 1 "Cannot read file: '$filepath'"

  # Check if it's a directory
  [[ -d "$filepath" ]] && die 1 "'$filepath' is a directory, not a file"

  # Get file size in bytes
  file_size=$(wc -c <"$filepath" 2>/dev/null || echo 0)

  if ((file_size > max_size)); then
    die 1 "File too large: $file_size bytes (maximum: $max_size bytes / 10MB)"
  fi

  debug "File size validation passed: $file_size bytes"
  return 0
}

# --------------------------------------------------------------------------------
# Signal handling

# Cleanup function called on exit/interrupt
cleanup() {
  local -i exitcode=${1:-0}
  # Reset terminal to clean state
  [[ -n ${ANSI_RESET:-} ]] && printf '%s' "$ANSI_RESET"
  exit "$exitcode"
}

# Install signal handlers
install_signal_handlers() {
  trap 'cleanup $?' EXIT
  trap 'cleanup 130' INT
  trap 'cleanup 143' TERM
}

# --------------------------------------------------------------------------------
# Argument validation

# Check if argument is present and not an option
# Usage: noarg "$1" "$2" (checks if $2 exists and doesn't start with -)
noarg() {
  if (($# < 2)) || [[ ${2:0:1} == '-' ]]; then
    die 2 "Missing argument for option '$1'"
  fi
  return 0
}

# --------------------------------------------------------------------------------
# String manipulation

# Trim leading and trailing whitespace
# Usage: trim "  text  "
trim() {
  local -- v="$*"
  v="${v#"${v%%[![:blank:]]*}"}"
  echo -n "${v%"${v##*[![:blank:]]}"}"
}

# Pluralization helper
# Usage: echo "Found $count file$(s $count)"
s() {
  (( ${1:-1} == 1 )) || echo -n 's'
}

# --------------------------------------------------------------------------------
# ReDoS protection using timeout command

# Safe regex substitution with timeout
# Usage: safe_regex_sub "pattern" "replacement" "text" [timeout_seconds]
safe_regex_sub() {
  local -- pattern="$1"
  local -- replacement="$2"
  local -- text="$3"
  local -i timeout="${4:-1}"

  # For simple patterns (short, no quantifiers), execute directly
  if [[ ${#pattern} -lt 50 ]] && [[ ! $pattern =~ [\*\+\{\?] ]]; then
    sed "s/$pattern/$replacement/g" <<<"$text" 2>/dev/null || echo "$text"
    return $?
  fi

  # For complex patterns, use timeout command
  if timeout "$timeout" sed "s/$pattern/$replacement/g" <<<"$text" 2>/dev/null; then
    return 0
  else
    warn "Regex timeout for pattern: ${pattern:0:50}..."
    echo "$text"  # Return original on timeout
    return 1
  fi
}

# --------------------------------------------------------------------------------
# Display declared variables (debugging aid)
# Usage: decp VAR1 VAR2
decp() {
  declare -p "$@" | sed 's/^declare -[a-zA-Z-]* //'
}

#fin
