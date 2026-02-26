# Makefile for md2ansi.bash
# Copyright (c) 2024 Open Technology Foundation
# Licensed under GPL-3.0

# Installation paths - customize as needed
PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
MANDIR ?= $(PREFIX)/share/man/man1
COMPLETIONDIR ?= $(PREFIX)/share/bash-completion/completions

# For user-local installation, use:
# make install-local (automatically uses ~/.local paths)

# Source files
MAIN_SCRIPT = md2ansi
WRAPPER_SCRIPT = md
MANPAGE = md2ansi.1
COMPLETION = md2ansi.bash_completion
UTILITIES = display-ansi-palette md-link-extract

# Installation variables
INSTALL = install
INSTALL_PROGRAM = $(INSTALL) -m 0755
INSTALL_DATA = $(INSTALL) -m 0644
MKDIR_P = mkdir -p
RM_F = rm -f

# Phony targets
.PHONY: all install uninstall install-local test clean help

# Default target
all:
	@echo "md2ansi.bash - Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  install        - Install to system directories (requires sudo)"
	@echo "  install-local  - Install to ~/.local (no sudo required)"
	@echo "  uninstall      - Remove installed files from system"
	@echo "  test           - Run shellcheck and test suite"
	@echo "  clean          - Remove temporary files"
	@echo "  help           - Show this help message"
	@echo ""
	@echo "Installation paths (current settings):"
	@echo "  PREFIX:        $(PREFIX)"
	@echo "  BINDIR:        $(BINDIR)"
	@echo "  MANDIR:        $(MANDIR)"
	@echo "  COMPLETIONDIR: $(COMPLETIONDIR)"
	@echo ""
	@echo "To customize installation path, use:"
	@echo "  make install PREFIX=/custom/path"

# System-wide installation (requires root/sudo)
install:
	@echo "Installing md2ansi to $(PREFIX)..."
	$(MKDIR_P) $(BINDIR)
	$(MKDIR_P) $(MANDIR)
	$(MKDIR_P) $(COMPLETIONDIR)

	@echo "  Installing executables to $(BINDIR)..."
	$(INSTALL_PROGRAM) $(MAIN_SCRIPT) $(BINDIR)/
	$(INSTALL_PROGRAM) $(WRAPPER_SCRIPT) $(BINDIR)/
	$(INSTALL_PROGRAM) $(UTILITIES) $(BINDIR)/

	@echo "  Installing manpage to $(MANDIR)..."
	$(INSTALL_DATA) $(MANPAGE) $(MANDIR)/

	@echo "  Installing bash completion to $(COMPLETIONDIR)..."
	$(INSTALL_DATA) $(COMPLETION) $(COMPLETIONDIR)/md2ansi

	@echo "  Updating man database..."
	-mandb 2>/dev/null || true

	@echo ""
	@echo "Installation complete!"
	@echo ""
	@echo "You can now use:"
	@echo "  md2ansi <file>    - Convert markdown to ANSI"
	@echo "  md <file>         - View with pagination"
	@echo "  man md2ansi       - View manual page"
	@echo ""
	@echo "Bash completion will be available in new shell sessions."

# User-local installation (no root required)
install-local:
	@echo "Installing md2ansi to ~/.local..."
	$(MAKE) install \
		PREFIX=$$HOME/.local \
		COMPLETIONDIR=$$HOME/.local/share/bash-completion/completions
	@echo ""
	@echo "NOTE: Ensure ~/.local/bin is in your PATH:"
	@echo "  export PATH=\"\$$HOME/.local/bin:\$$PATH\""
	@echo ""
	@echo "To enable bash completion, add to ~/.bashrc:"
	@echo "  if [ -f ~/.local/share/bash-completion/completions/md2ansi ]; then"
	@echo "    . ~/.local/share/bash-completion/completions/md2ansi"
	@echo "  fi"

# Uninstall from system
uninstall:
	@echo "Uninstalling md2ansi from $(PREFIX)..."
	$(RM_F) $(BINDIR)/$(MAIN_SCRIPT)
	$(RM_F) $(BINDIR)/$(WRAPPER_SCRIPT)
	$(RM_F) $(addprefix $(BINDIR)/,$(UTILITIES))
	$(RM_F) $(MANDIR)/$(MANPAGE)
	$(RM_F) $(COMPLETIONDIR)/md2ansi

	@echo "  Updating man database..."
	-mandb 2>/dev/null || true

	@echo "Uninstallation complete!"

# Run shellcheck validation and test suite
test:
	@echo "Running shellcheck validation..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck $(MAIN_SCRIPT) $(WRAPPER_SCRIPT) $(UTILITIES) || \
		(echo "Shellcheck found issues. Please fix before installation." && exit 1); \
		echo "All scripts passed shellcheck validation!"; \
	else \
		echo "Warning: shellcheck not found. Install it for validation."; \
		echo "  Debian/Ubuntu: sudo apt-get install shellcheck"; \
	fi
	@echo ""
	@echo "Running test suite..."
	@test/run_tests

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	$(RM_F) *~ *.bak *.tmp
	$(RM_F) test/*~ test/*.bak
	@echo "Clean complete!"

# Show help
help: all
