# MD2ANSI (Bash Implementation)

![Version](https://img.shields.io/badge/version-0.9.6--bash-blue.svg)
![License](https://img.shields.io/badge/license-GPL--3.0-green.svg)
![Shell](https://img.shields.io/badge/bash-5.2+-orange.svg)
![Status](https://img.shields.io/badge/status-stable-brightgreen.svg)

A **zero-dependency Bash implementation** of md2ansi that converts Markdown to ANSI-colored terminal output.

**Repository**: https://github.com/Open-Technology-Foundation/md2ansi.bash

## Overview

This is a pure Bash implementation of the md2ansi markdown-to-ANSI formatter, designed to be compatible with the [Python version](https://github.com/Open-Technology-Foundation/md2ansi) while following Bash best practices and the project's coding standards.

## Repository Contents

### Main Scripts

| Script | Purpose | Lines | Usage |
|--------|---------|-------|-------|
| **md2ansi** | Main converter executable | ~270 | `./md2ansi [OPTIONS] file.md` |
| **md** | Pagination wrapper with less | ~13 | `./md file.md` |
| **display-ansi-palette** | ANSI color palette viewer | ~72 | `./display-ansi-palette` |
| **md-link-extract** | Extract links from markdown | ~38 | `./md-link-extract file.md` |

### Library Modules

| Module | Purpose | Lines | Key Functions |
|--------|---------|-------|---------------|
| **lib/ansi-colors.sh** | ANSI color constants & escapes | ~97 | Color definitions, SGR codes |
| **lib/utils.sh** | Core utilities & validation | ~160 | `error`, `warn`, `debug`, `die`, `validate_file_size` |
| **lib/renderer.sh** | Inline formatting engine | ~400 | `render_inline`, `wrap_text`, `highlight_syntax` |
| **lib/parser.sh** | Block-level parser | ~220 | `parse_markdown`, `render_header`, `render_list` |
| **lib/tables.sh** | Table parser & renderer | ~220 | `parse_table`, `render_table_row` |

### Test Suite

| Test File | Coverage | Purpose |
|-----------|----------|---------|
| **test/test_basic.sh** | Basic features | Headers, inline formatting, lists |
| **test/test_code.sh** | Code blocks | Syntax highlighting, fenced blocks |
| **test/test_tables.sh** | Tables | Alignment, formatting, borders |

## Features

### Fully Implemented
- ✅ **Headers** (H1-H6) with distinct color gradients
- ✅ **Inline Formatting**:
  - Bold (`**text**`)
  - Italic (`*text*` or `_text_`)
  - Combined bold+italic (`***text***`)
  - Strikethrough (`~~text~~`)
  - Inline code (`` `code` ``)
  - Links (`[text](url)`)
  - Images (`![alt](url)`)
- ✅ **Lists**:
  - Unordered lists (`-` or `*`)
  - Ordered lists (`1.`, `2.`, etc.)
  - Task lists (`- [ ]` and `- [x]`)
  - Nested lists with proper indentation
- ✅ **Tables**:
  - Pipe-delimited tables with alignment support
  - Left, center, and right alignment
  - Inline formatting in cells
  - Proper borders and spacing
- ✅ **Code Blocks**:
  - Fenced code blocks (` ``` ` and `~~~`)
  - Syntax highlighting for Python, JavaScript, and Bash
  - Language detection and aliases (py, js, sh)
- ✅ **Blockquotes** (`>`)
- ✅ **Horizontal Rules** (`---`, `===`, `___`)
- ✅ **Footnotes** (`[^1]` references and `[^1]: text` definitions)
- ✅ **ANSI-aware text wrapping**
- ✅ **Terminal width auto-detection**
- ✅ **Feature toggles** (--no-tables, --no-syntax-highlight, etc.)
- ✅ **Security**: File size limits (10MB), input sanitization, ReDoS protection

## Installation

```bash
# Clone the repository
git clone https://github.com/Open-Technology-Foundation/md2ansi.bash.git
cd md2ansi.bash

# Make scripts executable
chmod +x md2ansi md display-ansi-palette md-link-extract

# Test it
./md2ansi --version
./md2ansi README.md
```

### System-wide Installation (Optional)

```bash
# Create symlinks in /usr/local/bin
sudo ln -s "$(pwd)/md2ansi" /usr/local/bin/md2ansi-bash
sudo ln -s "$(pwd)/md" /usr/local/bin/md-bash

# Now you can use it from anywhere
md2ansi-bash file.md
md-bash file.md  # With pagination
```

## Usage

### Basic Usage

```bash
# View a markdown file
./md2ansi README.md

# With pagination (recommended for long files)
./md README.md

# Process multiple files
./md2ansi file1.md file2.md file3.md

# Process from stdin
cat README.md | ./md2ansi
echo "# Hello **World**" | ./md2ansi
```

### Utility Scripts

#### `md` - Paginated Viewer
The `md` script wraps `md2ansi` with `less` for comfortable viewing of long markdown files:

```bash
./md README.md              # View with pagination
./md documentation/*.md     # Browse multiple files
```

Uses optimized `less` flags: `-FXRS` (auto-exit if one screen, no init, raw control chars, no line wrapping)

#### `display-ansi-palette` - Color Palette Viewer
View all 256 ANSI colors supported by your terminal:

```bash
./display-ansi-palette      # Display color palette with codes
```

Output includes:
- Standard 16 colors (0-15)
- 6x6x6 color cube (16-231)
- Grayscale ramp (232-255)

Useful for:
- Verifying terminal color support
- Choosing colors for customization
- Testing ANSI rendering

#### `md-link-extract` - Link Extractor
Extract and list all URLs from markdown files:

```bash
./md-link-extract README.md              # Extract all links
./md-link-extract docs/*.md | sort -u    # Deduplicated links from multiple files
```

Features:
- Extracts inline links `[text](url)`
- Extracts bare URLs `<http://example.com>`
- Extracts reference-style links `[text][ref]`
- Removes UTM tracking parameters
- Deduplicates URLs automatically

### Advanced Options

```bash
# Force specific terminal width
./md2ansi --width 100 README.md
./md2ansi -w 80 file.md

# Enable debug mode (output to stderr)
./md2ansi --debug README.md 2>debug.log
./md2ansi -D file.md

# Disable specific features
./md2ansi --no-tables --no-syntax-highlight doc.md
./md2ansi --no-footnotes README.md

# Plain text mode (all formatting disabled)
./md2ansi --plain README.md
./md2ansi -t file.md

# Show version
./md2ansi --version

# Show help
./md2ansi --help
```

## Architecture

The implementation follows the [Bash Coding Standard](https://github.com/Open-Technology-Foundation/bash-coding-standard) and is organized into modules:

```
md2ansi.bash/
├── md2ansi               # Main executable (~270 lines)
├── md                    # Pagination wrapper (~13 lines)
├── display-ansi-palette  # Color palette viewer (~72 lines)
├── md-link-extract       # Link extractor utility (~38 lines)
├── lib/
│   ├── ansi-colors.sh    # ANSI constants and color utilities (~97 lines)
│   ├── utils.sh          # Utilities, messaging, validation (~160 lines)
│   ├── renderer.sh       # Inline formatting and rendering (~400 lines)
│   ├── parser.sh         # Block-level parsing logic (~220 lines)
│   └── tables.sh         # Table parsing and rendering (~220 lines)
├── test/
│   ├── test_basic.sh     # Basic feature tests
│   ├── test_code.sh      # Code block tests
│   └── test_tables.sh    # Table rendering tests
├── README.md             # This file
├── CLAUDE.md             # AI assistant guidance
└── LICENSE               # GPL-3.0 license
```

**Total: ~1,490 lines of code**

### Code Organization

| Component | Responsibility |
|-----------|----------------|
| **md2ansi** | Main script with argument parsing and file processing |
| **lib/ansi-colors.sh** | Color constants, ANSI utilities |
| **lib/utils.sh** | Terminal detection, file validation, messaging, signal handling |
| **lib/renderer.sh** | Inline formatting (bold, italic, links, etc.), text wrapping |
| **lib/parser.sh** | Block-level parsing (headers, lists, code blocks, etc.) |
| **lib/tables.sh** | Complex table parsing, alignment, and rendering |

## Key Differences from [Python Version](https://github.com/Open-Technology-Foundation/md2ansi)

### Implementation Differences

| Aspect | Bash Version | Python Version |
|--------|--------------|----------------|
| **ReDoS Protection** | `timeout` command | multiprocessing |
| **Syntax Highlighting** | Line-based regex | Token-based parsing |
| **Performance** | ~2-3x slower | Baseline |
| **Design** | Modular libraries | Single file |
| **Error Handling** | trap + set -e | try/except |
| **Dependencies** | Zero (only coreutils) | Python 3.7+ |

### Compatibility Matrix

| Feature | Status | Notes |
|---------|--------|-------|
| Command-line arguments | ✅ Identical | All flags supported |
| Feature toggles | ✅ Identical | Same --no-* options |
| Output format | ✅ Compatible | Same colors & styling |
| ANSI codes | ✅ Identical | Full SGR support |
| File size limits | ✅ Same | 10MB maximum |
| Test fixtures | ✅ Compatible | Shares test files |
| Syntax highlighting | ⚠️ Simplified | Line-based patterns |

## Coding Standards

This implementation strictly adheres to the [BASH-CODING-STANDARD](https://github.com/Open-Technology-Foundation/bash-coding-standard):

| Standard | Implementation |
|----------|----------------|
| **Error Handling** | `set -euo pipefail` |
| **Shell Options** | `shopt -s inherit_errexit shift_verbose extglob nullglob` |
| **Indentation** | 2 spaces throughout |
| **Variables** | Type-specific declarations (`declare -i`, `declare -a`, `declare -A`) |
| **Constants** | `readonly` for immutable values |
| **Scoping** | `local` for function variables |
| **Conditionals** | `[[ ]]` for tests, `(( ))` for arithmetic |
| **Quoting** | All variable expansions quoted |
| **Messaging** | Standard functions: `error`, `warn`, `info`, `debug`, `die` |
| **Cleanup** | Signal handling with `trap` |
| **EOF Marker** | All scripts end with `#fin` |

## External Tools Used

All tools are standard and available on any modern Linux system:

| Tool | Package | Purpose |
|------|---------|---------|
| `tput` | ncurses | Terminal capability detection |
| `wc` | coreutils | File size validation |
| `sed` | coreutils | Regex substitution |
| `awk` | coreutils | Text processing |
| `grep` | coreutils | Pattern matching |
| `timeout` | coreutils | ReDoS protection |
| `less` | util-linux | Pagination |

> ** Zero additional dependencies required!**

## Security Features

| Feature | Implementation | Limit/Behavior |
|---------|----------------|----------------|
| **File Size Limits** | Pre-processing validation | 10MB maximum |
| **Line Length Limits** | Per-line checking | 100KB per line |
| **Input Sanitization** | ANSI escape removal | All input cleaned |
| **ReDoS Protection** | `timeout` wrapper | 1 second timeout |
| **Injection Prevention** | Proper quoting | All variables quoted |
| **Signal Handling** | `trap` cleanup | Graceful Ctrl-C |
| **Bounds Checking** | Width validation | 20-500 columns |

## 🧪 Testing

```bash
# Run test suite (if available)
./test/test_basic.sh
./test/test_code.sh
./test/test_tables.sh

# Manual testing
echo -e "# Test\n\nThis is **bold** text." | ./md2ansi

# Test with real README
./md README.md

# Test color support
./display-ansi-palette

# Test link extraction
./md-link-extract README.md
```

### Test Coverage

| Test Suite | Features Tested |
|------------|-----------------|
| **test_basic.sh** | Headers, inline formatting, lists, task lists, links, images, blockquotes, horizontal rules |
| **test_code.sh** | Fenced code blocks, syntax highlighting, language detection |
| **test_tables.sh** | Table parsing, alignment, borders, inline formatting in cells |

## Performance

| Metric | Value | Notes |
|--------|-------|-------|
| **Startup time** | ~50ms | Library sourcing overhead |
| **Processing speed** | ~2-3x slower than Python | Acceptable for terminal viewing |
| **Memory usage** | Low | Efficient line-by-line processing |
| **File size limit** | 10MB | Configurable via `MAX_FILE_SIZE` |
| **Optimization target** | Responsiveness | Terminal viewing over batch processing |

### Performance Comparison

```
Small files (<10KB):   ~100ms   ⚡ Fast
Medium files (100KB):  ~500ms   ✓ Good
Large files (1MB):     ~3-5s    ⚠️ Acceptable
Very large (5-10MB):   ~15-30s  ⏱️ Slow but safe
```

## Examples

### Headers and Text
```bash
echo "# Big Header
## Smaller Header

This is **bold**, *italic*, and ***bold italic*** text.

This is ~~strikethrough~~ and \`inline code\`." | ./md2ansi
```

### Lists
```bash
echo "- Item 1
- Item 2
  - Nested item
  - Another nested

1. First
2. Second
   1. Nested numbered

- [ ] Todo
- [x] Done" | ./md2ansi
```

### Tables

Tables support alignment (left, center, right) and inline formatting within cells:

| Feature | Status | Notes |
|:--------|:------:|------:|
| **Headers** | ✅ | H1-H6 with colors |
| *Emphasis* | ✅ | Bold & italic |
| `Code` | ✅ | Inline code blocks |
| Tables | ✅ | With alignment |
| Links | ✅ | Clickable |

```bash
echo "| Left | Center | Right |
|:-----|:------:|------:|
| A    | B      | C     |" | ./md2ansi
```

### Code Blocks
```bash
echo "\`\`\`python
def hello():
    print('world')
\`\`\`" | ./md2ansi
```

## Development

### Adding New Features

| Component | File | Purpose |
|-----------|------|---------|
| **Block-level parsing** | `lib/parser.sh` | Headers, lists, code blocks, blockquotes |
| **Inline formatting** | `lib/renderer.sh` | Bold, italic, links, inline code |
| **Table support** | `lib/tables.sh` | Table parsing, alignment, rendering |
| **Utilities** | `lib/utils.sh` | Validation, messaging, helpers |
| **Colors** | `lib/ansi-colors.sh` | ANSI constants, color functions |

### Debug Mode

```bash
# Enable debug output (to stderr)
./md2ansi -D file.md 2>debug.log

# View debug output
cat debug.log

# Debug with real-time output
./md2ansi -D file.md 2>&1 | grep 'DEBUG'
```

Debug output includes:
- ✓ Terminal width detection
- ✓ File size validation
- ✓ Table parsing steps
- ✓ Regex operation timeouts
- ✓ Feature flag states

## Known Limitations

| Limitation | Impact | Workaround |
|------------|--------|------------|
| **Syntax Highlighting** | Simpler than Python (line-based) | Use [Python version](https://github.com/Open-Technology-Foundation/md2ansi) for complex code |
| **Unicode** | Depends on terminal | Ensure UTF-8 terminal |
| **Performance** | Slower for files >1MB | Use Python version for large files |
| **Nested Formatting** | Some edge cases differ | Test with specific content |

## Troubleshooting

### Issue: Colors not showing

```bash
# Check terminal color support (should be ≥256)
tput colors

# Verify TERM variable
echo $TERM

# Try forcing 256-color mode
export TERM=xterm-256color
./md2ansi README.md
```

### Issue: Script not found

```bash
# Make sure you're in the repository directory
cd /path/to/md2ansi.bash

# Or use absolute path
/path/to/md2ansi.bash/md2ansi file.md

# Check if script exists
ls -l md2ansi
```

### Issue: Permission denied

```bash
# Make scripts executable
chmod +x md2ansi md display-ansi-palette md-link-extract

# Verify permissions
ls -l md2ansi md
```

### Issue: Output is garbled

```bash
# Disable all formatting
./md2ansi --plain file.md

# Check for conflicting ANSI codes in input
./md2ansi --debug file.md 2>&1 | grep -i sanitiz
```

## Contributing

### Contribution Guidelines

| Requirement | Tool/Process |
|-------------|--------------|
| **Code Style** | Follow [BASH-CODING-STANDARD](https://github.com/Open-Technology-Foundation/bash-coding-standard) strictly |
| **Linting** | Run `shellcheck` on all scripts |
| **Testing** | Test with provided test suite |
| **Compatibility** | Maintain Python version compatibility |
| **Documentation** | Update README for new features |

### Development Workflow

```bash
# 1. Make changes to code
vim lib/renderer.sh

# 2. Run shellcheck
shellcheck md2ansi lib/*.sh test/*.sh

# 3. Test changes
./test/test_basic.sh
./md2ansi README.md

# 4. Create checkpoint backup
checkpoint -q

# 5. Commit changes
git add .
git commit -m "Add feature: description"
```

### Code Review Checklist

- [ ] Follows bash coding standard
- [ ] All variables properly declared with types
- [ ] Functions use `local` for variables
- [ ] No shellcheck warnings
- [ ] Error handling with proper exit codes
- [ ] Scripts end with `#fin`
- [ ] Comments for complex logic
- [ ] Test coverage for new features

## License

**GPL-3.0** - Same as parent project

See [LICENSE](LICENSE) file for full text.

## Acknowledgments

- Based on the [Python md2ansi](https://github.com/Open-Technology-Foundation/md2ansi) implementation
- Follows [BASH-CODING-STANDARD](https://github.com/Open-Technology-Foundation/bash-coding-standard) guidelines
- Designed for readability and maintainability

## Project Stats

| Metric | Value |
|--------|-------|
| **Total Lines** | ~1,490 |
| **Scripts** | 4 main + 5 libraries + 3 tests |
| **Features** | 12+ markdown elements |
| **Test Coverage** | Headers, formatting, lists, tables, code |
| **Dependencies** | 0 (zero) |

---

## Support & Links

- **Repository**: https://github.com/Open-Technology-Foundation/md2ansi.bash
- **Issues**: https://github.com/Open-Technology-Foundation/md2ansi.bash/issues
- **Bash Coding Standard**: https://github.com/Open-Technology-Foundation/bash-coding-standard
- **License**: GPL-3.0

---

**Status**: ✅ Core implementation complete and functional

**Version**: 0.9.6-bash

**Last Updated**: 2025-10-01

#fin
