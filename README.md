# MD2ANSI (Bash Implementation)

A **zero-dependency Bash implementation** of md2ansi that converts Markdown to ANSI-colored terminal output.

Version: 0.9.6-bash

## Overview

This is a pure Bash implementation of the md2ansi markdown-to-ANSI formatter, designed to be compatible with the Python version while following Bash best practices and the project's coding standards.

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
cd /ai/scripts/lib/md2ansi/md2ansi.bash

# Make scripts executable
chmod +x md2ansi md

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

The implementation follows the Bash Coding Standard and is organized into modules:

```
md2ansi.bash/
├── md2ansi               # Main executable (~270 lines)
├── md                    # Pagination wrapper (~13 lines)
├── lib/
│   ├── ansi-colors.sh    # ANSI constants and color utilities (~97 lines)
│   ├── utils.sh          # Utilities, messaging, validation (~160 lines)
│   ├── renderer.sh       # Inline formatting and rendering (~400 lines)
│   ├── parser.sh         # Block-level parsing logic (~220 lines)
│   └── tables.sh         # Table parsing and rendering (~220 lines)
├── test/                 # Test framework (future)
└── README.md             # This file
```

**Total: ~1,380 lines of code**

### Code Organization

- **md2ansi**: Main script with argument parsing and file processing
- **lib/ansi-colors.sh**: Color constants, ANSI utilities
- **lib/utils.sh**: Terminal detection, file validation, messaging, signal handling
- **lib/renderer.sh**: Inline formatting (bold, italic, links, etc.), text wrapping
- **lib/parser.sh**: Block-level parsing (headers, lists, code blocks, etc.)
- **lib/tables.sh**: Complex table parsing, alignment, and rendering

## Key Differences from Python Version

### Implementation Differences

1. **ReDoS Protection**: Uses `timeout` command instead of multiprocessing
2. **Syntax Highlighting**: Line-based regex matching (simpler than Python's whole-block approach)
3. **Performance**: ~2-3x slower for large files (acceptable for terminal viewing)
4. **Modular Design**: Split into sourced libraries vs. single Python file
5. **Error Handling**: Bash-native error handling with trap and set -e

### Compatibility

- ✅ Same command-line arguments
- ✅ Same feature flags
- ✅ Same output format and colors
- ✅ Compatible with Python version's test fixtures
- ✅ Same 10MB file size limit
- ⚠️ Slightly different syntax highlighting patterns (simplified)

## Coding Standards

This implementation strictly adheres to `/ai/scripts/lib/md2ansi/BASH-CODING-STANDARD.md`:

- `set -euo pipefail` for error handling
- `shopt -s inherit_errexit shift_verbose extglob nullglob`
- 2-space indentation throughout
- Type-specific variable declarations (`declare -i`, `declare -a`, `declare -A`)
- `readonly` for constants
- `local` for function variables
- `[[ ]]` for conditionals, `(( ))` for arithmetic
- Proper quoting of all variables
- Standard messaging functions (error, warn, info, debug, die)
- Signal handling with trap
- End all scripts with `#fin`

## External Tools Used

All tools are standard and available on any modern Linux system:

- `tput` - Terminal capability detection (ncurses)
- `wc` - File size validation (coreutils)
- `sed` - Regex substitution (coreutils)
- `awk` - Text processing (coreutils)
- `grep` - Pattern matching (coreutils)
- `timeout` - ReDoS protection (coreutils)
- `less` - Pagination (common utility)

**No additional dependencies required!**

## Security Features

- **File Size Limits**: 10MB maximum for files and stdin
- **Line Length Limits**: 100KB per line to prevent memory issues
- **Input Sanitization**: ANSI escape sequences removed from input
- **ReDoS Protection**: Regex operations wrapped with timeout (1 second)
- **Command Injection Prevention**: Proper quoting throughout
- **Signal Handling**: Graceful cleanup on Ctrl-C
- **Bounds Checking**: Terminal width validated (20-500 columns)

## Testing

```bash
# Test with included fixtures (from parent directory)
./md2ansi ../test_fixtures/basic.md
./md2ansi ../test_fixtures/tables.md
./md2ansi ../test_fixtures/code_blocks.md

# Test with stdin
echo -e "# Test\n\nThis is **bold** text." | ./md2ansi

# Test with real README
./md ../README.md  # From parent directory
```

## Performance

- **Startup time**: ~50ms (library sourcing)
- **Processing**: ~2-3x slower than Python for large files
- **Memory**: Efficient line-by-line processing
- **File size limit**: 10MB (configurable in source)

Performance is optimized for terminal viewing where responsiveness matters more than raw speed.

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

1. **Parser changes**: Edit `lib/parser.sh`
2. **Rendering changes**: Edit `lib/renderer.sh`
3. **Table changes**: Edit `lib/tables.sh`
4. **Utilities**: Edit `lib/utils.sh` or `lib/ansi-colors.sh`

### Debug Mode

```bash
# Enable debug output
./md2ansi -D file.md 2>debug.log

# View debug output
cat debug.log
```

Debug output includes:
- Terminal width detection
- File size validation
- Table parsing steps
- Regex operation timeouts

## Known Limitations

1. **Syntax Highlighting**: Simpler than Python version (line-based vs. token-based)
2. **Unicode**: Depends on terminal support
3. **Performance**: Slower than Python for very large files (>1MB)
4. **Edge Cases**: Some complex nested formatting combinations may differ slightly

## Troubleshooting

### Colors not showing
```bash
# Check terminal color support
tput colors

# Should output 256 or higher
```

### Script not found
```bash
# Make sure you're in the right directory
cd /ai/scripts/lib/md2ansi/md2ansi.bash

# Or use absolute path
/ai/scripts/lib/md2ansi/md2ansi.bash/md2ansi file.md
```

### Permission denied
```bash
# Make scripts executable
chmod +x md2ansi md
```

## Contributing

When contributing to the Bash implementation:

1. Follow BASH-CODING-STANDARD.md strictly
2. Run shellcheck on all scripts
3. Test with provided fixtures
4. Maintain compatibility with Python version
5. Document any deviations in this README

## License

GPL-3.0 - Same as parent project

## Acknowledgments

- Based on the Python md2ansi implementation
- Follows BASH-CODING-STANDARD.md guidelines
- Designed for readability and maintainability

---

**Status**: ✅ Core implementation complete and functional

**Last Updated**: 2025-10-01

For more information about md2ansi, see the main project README at `/ai/scripts/lib/md2ansi/README.md`

#fin
