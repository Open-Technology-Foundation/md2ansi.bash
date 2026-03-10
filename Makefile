# Makefile - Install md2ansi
# BCS1212 compliant

PREFIX  ?= /usr/local
BINDIR  ?= $(PREFIX)/bin
MANDIR  ?= $(PREFIX)/share/man/man1
COMPDIR ?= /etc/bash_completion.d
DATADIR ?= $(PREFIX)/share/mdview
DESTDIR ?=

.PHONY: all install uninstall check test clean help

all: help

install:
	install -d $(DESTDIR)$(BINDIR)
	install -m 755 md2ansi $(DESTDIR)$(BINDIR)/md2ansi
	install -m 755 md $(DESTDIR)$(BINDIR)/md
	install -m 755 display-ansi-palette $(DESTDIR)$(BINDIR)/display-ansi-palette
	install -m 755 md-link-extract $(DESTDIR)$(BINDIR)/md-link-extract
	install -m 755 mdview $(DESTDIR)$(BINDIR)/mdview
	install -d $(DESTDIR)$(MANDIR)
	install -m 644 md2ansi.1 $(DESTDIR)$(MANDIR)/md2ansi.1
	@if [ -d $(DESTDIR)$(COMPDIR) ]; then \
	  install -m 644 md2ansi.bash_completion $(DESTDIR)$(COMPDIR)/md2ansi; \
	fi
	install -d $(DESTDIR)$(DATADIR)/themes
	install -m 644 mdview.conf $(DESTDIR)$(DATADIR)/
	@if ls themes/*.css >/dev/null 2>&1; then \
	  install -m 644 themes/*.css $(DESTDIR)$(DATADIR)/themes/; \
	fi
	@if ls themes/*.theme >/dev/null 2>&1; then \
	  install -m 644 themes/*.theme $(DESTDIR)$(DATADIR)/themes/; \
	fi
	@if [ -z "$(DESTDIR)" ]; then $(MAKE) --no-print-directory check; fi

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/md2ansi
	rm -f $(DESTDIR)$(BINDIR)/md
	rm -f $(DESTDIR)$(BINDIR)/display-ansi-palette
	rm -f $(DESTDIR)$(BINDIR)/md-link-extract
	rm -f $(DESTDIR)$(BINDIR)/mdview
	rm -f $(DESTDIR)$(MANDIR)/md2ansi.1
	rm -f $(DESTDIR)$(COMPDIR)/md2ansi
	rm -rf $(DESTDIR)$(DATADIR)

check:
	@command -v md2ansi >/dev/null 2>&1 \
	  && echo 'md2ansi: OK' \
	  || echo 'md2ansi: NOT FOUND (check PATH)'
	@command -v mdview >/dev/null 2>&1 \
	  && echo 'mdview: OK' \
	  || echo 'mdview: NOT FOUND (check PATH)'

test:
	test/run_tests

clean:
	rm -f *~ *.bak *.tmp

help:
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@echo '  install     Install to $(PREFIX)'
	@echo '  uninstall   Remove installed files'
	@echo '  check       Verify installation'
	@echo '  test        Run test suite'
	@echo '  clean       Remove temporary files'
	@echo '  help        Show this message'
	@echo ''
	@echo 'Install from GitHub:'
	@echo '  git clone https://github.com/Open-Technology-Foundation/md2ansi.bash.git'
	@echo '  cd md2ansi.bash && sudo make install'
