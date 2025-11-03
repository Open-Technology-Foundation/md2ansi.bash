#!/usr/bin/env bash
#
# install.sh - Installation script for md2ansi.bash
# Copyright (c) 2024 Open Technology Foundation
# Licensed under GPL-3.0
#
# This script provides interactive installation of md2ansi with options for
# system-wide or user-local installation, automatic sudo elevation, and
# rollback on failure.

set -euo pipefail
shopt -s inherit_errexit shift_verbose extglob nullglob

# Script metadata
declare -r SCRIPT_NAME="${0##*/}"
declare -r SCRIPT_VERSION="0.9.6-bash"
declare SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -r SCRIPT_DIR

# ANSI color codes
declare -r COLOR_RESET='\033[0m'
declare -r COLOR_BOLD='\033[1m'
declare -r COLOR_RED='\033[31m'
declare -r COLOR_GREEN='\033[32m'
declare -r COLOR_YELLOW='\033[33m'
declare -r COLOR_BLUE='\033[34m'
declare -r COLOR_CYAN='\033[36m'

# Installation state tracking
declare -a INSTALLED_FILES=()

# Messaging functions
error() {
  echo -e "${COLOR_RED}✗ Error:${COLOR_RESET} $*" >&2
}

warn() {
  echo -e "${COLOR_YELLOW}▲ Warning:${COLOR_RESET} $*" >&2
}

info() {
  echo -e "${COLOR_BLUE}◉ Info:${COLOR_RESET} $*"
}

success() {
  echo -e "${COLOR_GREEN}✓ Success:${COLOR_RESET} $*"
}

die() {
  error "$@"
  exit 1
}

# Cleanup on failure
cleanup_on_failure() {
  if (( ${#INSTALLED_FILES[@]} > 0 )); then
    warn "Installation failed. Rolling back changes..."
    local file
    for file in "${INSTALLED_FILES[@]}"; do
      if [[ -f "$file" ]]; then
        rm -f "$file" && info "Removed: $file"
      fi
    done
  fi
}

# Set up signal handlers
trap cleanup_on_failure ERR EXIT

# Display header
show_header() {
  echo -e "${COLOR_BOLD}${COLOR_CYAN}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  md2ansi.bash Installation Script"
  echo "  Version: ${SCRIPT_VERSION}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${COLOR_RESET}"
}

# Display usage
show_usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Interactive installation script for md2ansi.bash

OPTIONS:
  -s, --system      System-wide installation (requires sudo)
  -u, --user        User-local installation (~/.local)
  -p, --prefix DIR  Custom installation prefix
  -y, --yes         Non-interactive mode (auto-confirm)
  -h, --help        Show this help message
  -V, --version     Show version information

EXAMPLES:
  # Interactive installation (will prompt for location)
  $SCRIPT_NAME

  # System-wide installation
  $SCRIPT_NAME --system

  # User-local installation
  $SCRIPT_NAME --user

  # Custom prefix
  $SCRIPT_NAME --prefix /opt/md2ansi

EOF
}

# Check prerequisites
check_prerequisites() {
  info "Checking prerequisites..."

  # Check for required files
  declare -a required_files=(
    "md2ansi"
    "md"
    "md2ansi.1"
    "md2ansi.bash_completion"
    "display-ansi-palette"
    "md-link-extract"
  )

  local file
  for file in "${required_files[@]}"; do
    if [[ ! -f "${SCRIPT_DIR}/${file}" ]]; then
      die "Required file not found: ${file}"
    fi
  done

  # Check for shellcheck (optional but recommended)
  if command -v shellcheck >/dev/null 2>&1; then
    info "Found shellcheck - will validate scripts"
    return 0
  else
    warn "shellcheck not found - skipping validation"
    warn "  Install: sudo apt-get install shellcheck (Debian/Ubuntu)"
    warn "           brew install shellcheck (macOS)"
  fi
}

# Run shellcheck validation
validate_scripts() {
  if ! command -v shellcheck >/dev/null 2>&1; then
    return 0
  fi

  info "Validating scripts with shellcheck..."
  declare -a scripts=("md2ansi" "md" "display-ansi-palette" "md-link-extract")

  local script
  for script in "${scripts[@]}"; do
    if ! shellcheck "${SCRIPT_DIR}/${script}" 2>/dev/null; then
      warn "Shellcheck found issues in ${script}"
      warn "Continuing anyway, but please review the warnings"
    fi
  done

  success "Script validation complete"
}

# Prompt user for installation type
prompt_installation_type() {
  echo ""
  info "Select installation type:"
  echo "  1) System-wide installation (${COLOR_BOLD}/usr/local${COLOR_RESET}) - requires sudo"
  echo "  2) User-local installation (${COLOR_BOLD}~/.local${COLOR_RESET}) - no sudo required"
  echo "  3) Custom prefix - specify your own location"
  echo "  4) Cancel installation"
  echo ""

  local choice
  read -rp "Enter choice [1-4]: " choice

  case "$choice" in
    1)
      echo "system"
      ;;
    2)
      echo "user"
      ;;
    3)
      echo "custom"
      ;;
    4)
      info "Installation cancelled by user"
      exit 0
      ;;
    *)
      error "Invalid choice: $choice"
      prompt_installation_type
      ;;
  esac
}

# Install files
install_files() {
  local prefix="$1"
  local bindir="${prefix}/bin"
  local mandir="${prefix}/share/man/man1"
  local completiondir="$2"

  info "Installing to ${COLOR_BOLD}${prefix}${COLOR_RESET}..."
  echo ""
  info "Installation paths:"
  info "  Executables:  ${bindir}"
  info "  Man page:     ${mandir}"
  info "  Completions:  ${completiondir}"
  echo ""

  # Create directories
  info "Creating directories..."
  mkdir -p "$bindir" || die "Failed to create $bindir"
  mkdir -p "$mandir" || die "Failed to create $mandir"
  mkdir -p "$completiondir" || die "Failed to create $completiondir"

  # Install executables
  info "Installing executables..."
  declare -a executables=("md2ansi" "md" "display-ansi-palette" "md-link-extract")
  local exec_file
  for exec_file in "${executables[@]}"; do
    local target="${bindir}/${exec_file}"
    install -m 0755 "${SCRIPT_DIR}/${exec_file}" "$target" || \
      die "Failed to install ${exec_file}"
    INSTALLED_FILES+=("$target")
    success "Installed: ${exec_file}"
  done

  # Install manpage
  info "Installing manpage..."
  local manpage_target="${mandir}/md2ansi.1"
  install -m 0644 "${SCRIPT_DIR}/md2ansi.1" "$manpage_target" || \
    die "Failed to install manpage"
  INSTALLED_FILES+=("$manpage_target")
  success "Installed: md2ansi.1"

  # Install bash completion
  info "Installing bash completion..."
  local completion_target="${completiondir}/md2ansi.bash_completion"
  install -m 0644 "${SCRIPT_DIR}/md2ansi.bash_completion" "$completion_target" || \
    die "Failed to install bash completion"
  INSTALLED_FILES+=("$completion_target")
  success "Installed: bash completion"

  # Update man database
  if command -v mandb >/dev/null 2>&1; then
    info "Updating man database..."
    mandb 2>/dev/null || warn "Could not update man database"
  fi
}

# Show post-installation instructions
show_post_install() {
  local prefix="$1"
  local install_type="$2"

  echo ""
  echo -e "${COLOR_BOLD}${COLOR_GREEN}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Installation Complete!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${COLOR_RESET}"

  success "md2ansi.bash v${SCRIPT_VERSION} installed successfully"
  echo ""
  info "You can now use:"
  echo "  ${COLOR_CYAN}md2ansi <file>${COLOR_RESET}  - Convert markdown to ANSI"
  echo "  ${COLOR_CYAN}md <file>${COLOR_RESET}       - View with pagination"
  echo "  ${COLOR_CYAN}man md2ansi${COLOR_RESET}    - View manual page"
  echo ""

  if [[ "$install_type" == "user" ]]; then
    info "User-local installation notes:"
    echo ""
    warn "Ensure ${COLOR_BOLD}~/.local/bin${COLOR_RESET} is in your PATH:"
    echo "  ${COLOR_CYAN}export PATH=\"\$HOME/.local/bin:\$PATH\"${COLOR_RESET}"
    echo ""
    warn "To enable bash completion, add to ${COLOR_BOLD}~/.bashrc${COLOR_RESET}:"
    echo "  ${COLOR_CYAN}if [ -f ~/.local/share/bash-completion/completions/md2ansi.bash_completion ]; then${COLOR_RESET}"
    echo "  ${COLOR_CYAN}  . ~/.local/share/bash-completion/completions/md2ansi.bash_completion${COLOR_RESET}"
    echo "  ${COLOR_CYAN}fi${COLOR_RESET}"
    echo ""
    info "Restart your shell or source ~/.bashrc to apply changes"
  else
    info "Bash completion will be available in new shell sessions"
  fi

  echo ""
  info "For more information, visit:"
  echo "  ${COLOR_CYAN}https://github.com/Open-Technology-Foundation/md2ansi.bash${COLOR_RESET}"
  echo ""
}

# Main installation logic
main() {
  local install_type=""
  local prefix=""
  local auto_confirm=0

  # Parse command-line arguments
  while (( $# > 0 )); do
    case "$1" in
      -s|--system)
        install_type="system"
        shift
        ;;
      -u|--user)
        install_type="user"
        shift
        ;;
      -p|--prefix)
        install_type="custom"
        prefix="$2"
        shift 2
        ;;
      -y|--yes)
        auto_confirm=1
        shift
        ;;
      -h|--help)
        show_usage
        exit 0
        ;;
      -V|--version)
        echo "md2ansi.bash installer v${SCRIPT_VERSION}"
        exit 0
        ;;
      *)
        error "Unknown option: $1"
        show_usage
        exit 2
        ;;
    esac
  done

  # Show header
  show_header

  # Check prerequisites
  check_prerequisites

  # Validate scripts
  validate_scripts

  # Determine installation type if not specified
  if [[ -z "$install_type" ]]; then
    install_type=$(prompt_installation_type)
  fi

  # Set installation paths
  local completiondir
  case "$install_type" in
    system)
      prefix="/usr/local"
      completiondir="/etc/bash_completion.d"

      # Check if we need sudo
      if [[ ! -w "$prefix" ]] && (( EUID != 0 )); then
        warn "System-wide installation requires sudo/root privileges"
        if (( auto_confirm == 0 )); then
          local confirm
          read -rp "Re-run with sudo? [y/N]: " confirm
          if [[ "${confirm,,}" != "y" ]]; then
            die "Installation cancelled - insufficient permissions"
          fi
        fi
        info "Re-executing with sudo..."
        exec sudo -E bash "$0" --system --yes
      fi
      ;;
    user)
      prefix="$HOME/.local"
      completiondir="$HOME/.local/share/bash-completion/completions"
      ;;
    custom)
      if [[ -z "$prefix" ]]; then
        read -rp "Enter installation prefix: " prefix
      fi
      completiondir="${prefix}/share/bash-completion/completions"
      ;;
  esac

  # Confirm installation
  if (( auto_confirm == 0 )); then
    echo ""
    read -rp "Proceed with installation to ${prefix}? [y/N]: " confirm
    if [[ "${confirm,,}" != "y" ]]; then
      info "Installation cancelled by user"
      exit 0
    fi
  fi

  # Perform installation
  install_files "$prefix" "$completiondir"

  # Disable cleanup trap on success
  trap - ERR EXIT

  # Show post-installation instructions
  show_post_install "$prefix" "$install_type"
}

# Run main function
main "$@"

#fin
