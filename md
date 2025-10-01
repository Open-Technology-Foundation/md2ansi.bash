#!/usr/bin/env bash
# Wrapper script for md2ansi that pipes output through less
# Provides paginated viewing of markdown files
set -euo pipefail

# Set less options for optimal markdown viewing
export LESS='-FXRS'

# Get the directory where this script is located
SCRIPT_DIR=$(dirname "$(readlink -en -- "$0")")

# Run md2ansi and pipe to less
"$SCRIPT_DIR/md2ansi" "$@" | less

#fin
