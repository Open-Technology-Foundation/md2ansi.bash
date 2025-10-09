#!/usr/bin/env bash
# Rendering functions for md2ansi
# Handles inline formatting, text wrapping, and code syntax highlighting
# This is a sourced library, not an executable script
# Version: 0.9.6-bash

# --------------------------------------------------------------------------------
# Inline formatting engine

# Apply all inline formatting to a line of text
# Order matters: process code first, then images, links, then bold/italic/strike
# Usage: colorize_line "markdown text"
colorize_line() {
  local -- line="$1"
  local -- result="$line"

  # 1. Inline code: `code` (remove backticks from output)
  result=$(sed -E "s/\`([^\`]+)\`/${COLOR_CODEBLOCK}\1${ANSI_RESET}${COLOR_TEXT}/g" <<<"$result")

  # 2. Images: ![alt](url) - must be before links
  if ((OPTIONS[images])); then
    result=$(sed -E "s/!\[([^]]+)\]\(([^)]+)\)/${ANSI_BOLD}[IMG: \1]${ANSI_RESET}${COLOR_TEXT}/g" <<<"$result")
  fi

  # 3. Links: [text](url)
  if ((OPTIONS[links])); then
    result=$(sed -E "s/\[([^]]+)\]\(([^)]+)\)/${COLOR_LINK}${ANSI_UNDERLINE}\1${ANSI_RESET}${COLOR_TEXT}/g" <<<"$result")
  fi

  # 4. Bold + Italic combined: ***text***
  result=$(sed -E "s/\*\*\*([^*]+)\*\*\*/${ANSI_BOLD}${ANSI_ITALIC}\1${ANSI_RESET}${COLOR_TEXT}/g" <<<"$result")

  # 5. Bold + Italic alternative: **_text_** or _**text**_
  result=$(sed -E "s/\*\*_([^_]+)_\*\*/${ANSI_BOLD}${ANSI_ITALIC}\1${ANSI_RESET}${COLOR_TEXT}/g" <<<"$result")
  result=$(sed -E "s/_\*\*([^*]+)\*\*_/${ANSI_BOLD}${ANSI_ITALIC}\1${ANSI_RESET}${COLOR_TEXT}/g" <<<"$result")

  # 6. Bold: **text**
  result=$(sed -E "s/\*\*([^*]+)\*\*/${ANSI_BOLD}\1${ANSI_RESET}${COLOR_TEXT}/g" <<<"$result")

  # 7. Italic: *text* or _text_ (avoid matching inside already-formatted text)
  # Don't match if preceded by certain characters that indicate formatted text
  result=$(sed -E "s/([^*])\*([^*]+)\*([^*])/\1${ANSI_ITALIC}\2${ANSI_RESET}${COLOR_TEXT}\3/g" <<<"$result")
  # Skip underscore italic inside inline code by not matching adjacent to ANSI codes
  # Don't process _text_ at all - it's too error-prone with code containing underscores

  # 8. Strikethrough: ~~text~~
  result=$(sed -E "s/~~([^~]+)~~/${ANSI_STRIKE}\1${ANSI_RESET}${COLOR_TEXT}/g" <<<"$result")

  # 9. Footnote references: [^id] (if enabled)
  if ((OPTIONS[footnotes])); then
    result=$(sed -E "s/\[\^([^]]+)\]/${COLOR_TEXT}[${ANSI_BOLD}${ANSI_DIM}^\1${ANSI_RESET}${COLOR_TEXT}]/g" <<<"$result")
  fi

  echo "$result"
}

# --------------------------------------------------------------------------------
# Text wrapping with ANSI awareness

# Wrap text to specified width, preserving ANSI codes
# Usage: wrap_text "text with ANSI" width
wrap_text() {
  local -- text="$1"
  local -i width="$2"
  local -i visible_len
  local -a words
  local -- word current_line visible_current stripped_word
  local -i current_len word_len

  # Get visible length
  visible_len=$(visible_length "$text")

  # If text fits, return as-is
  if ((visible_len <= width)); then
    echo "$text"
    return 0
  fi

  # Split into words
  IFS=' ' read -ra words <<<"$text"

  # Build wrapped lines
  current_line="${words[0]}"
  visible_current=$(strip_ansi "$current_line")
  current_len=${#visible_current}

  for word in "${words[@]:1}"; do
    stripped_word=$(strip_ansi "$word")
    word_len=${#stripped_word}

    if ((current_len + word_len + 1 <= width)); then
      # Word fits on current line
      current_line+=" $word"
      current_len+=1
      current_len+=$word_len
    else
      # Start new line
      echo "$current_line"
      current_line="$word"
      current_len=$word_len
    fi
  done

  # Print last line
  [[ -n $current_line ]] && echo "$current_line"
}

# --------------------------------------------------------------------------------
# Header rendering

# Render a markdown header with appropriate color
# Usage: render_header "###" "Header Text"
render_header() {
  local -- hashes="$1"
  local -- text="$2"
  local -- color formatted_text

  # Determine color based on header level
  case "${#hashes}" in
    1) color="$COLOR_H1" ;;
    2) color="$COLOR_H2" ;;
    3) color="$COLOR_H3" ;;
    4) color="$COLOR_H4" ;;
    5) color="$COLOR_H5" ;;
    *) color="$COLOR_H6" ;;
  esac

  # Apply inline formatting to header text
  formatted_text=$(colorize_line "$text")

  printf '%s%s%s\n' "$color" "$formatted_text" "$ANSI_RESET"
}

# --------------------------------------------------------------------------------
# List rendering

# Render unordered list item with proper indentation
# Usage: render_list_item "indent" "content" term_width
render_list_item() {
  local -- indent="$1"
  local -- content="$2"
  local -i term_width="$3"
  local -i indent_level
  local -- bullet_indent text_indent formatted_content
  local -a wrapped_lines

  # Calculate indentation level (every 2 spaces = 1 level)
  indent_level=$((${#indent} / 2))
  bullet_indent=$(printf '  %.0s' $(seq 1 "$indent_level"))
  text_indent=$(printf '  %.0s' $(seq 1 $((indent_level + 1))))

  # Apply inline formatting
  formatted_content=$(colorize_line "$content")

  # Wrap text to terminal width
  readarray -t wrapped_lines < <(wrap_text "$formatted_content" $((term_width - ${#text_indent} - 2)))

  # Print first line with bullet
  printf '%s%s* %s%s%s\n' "$bullet_indent" "$COLOR_LIST" "$COLOR_TEXT" "${wrapped_lines[0]}" "$ANSI_RESET"

  # Print continuation lines if any
  local -- line
  for line in "${wrapped_lines[@]:1}"; do
    printf '%s%s%s\n' "$text_indent" "$line" "$ANSI_RESET"
  done
}

# Render ordered list item
# Usage: render_ordered_item "indent" "number" "content" term_width
render_ordered_item() {
  local -- indent="$1"
  local -- number="$2"
  local -- content="$3"
  local -i term_width="$4"
  local -i indent_level number_width
  local -- number_indent text_indent formatted_content
  local -a wrapped_lines

  # Calculate indentation
  indent_level=$((${#indent} / 2))
  number_indent=$(printf '  %.0s' $(seq 1 "$indent_level"))
  number_width=$((${#number} + 2))  # number + ". "
  text_indent="${number_indent}$(printf ' %.0s' $(seq 1 "$number_width"))"

  # Apply inline formatting
  formatted_content=$(colorize_line "$content")

  # Wrap text
  readarray -t wrapped_lines < <(wrap_text "$formatted_content" $((term_width - ${#text_indent} - 2)))

  # Print first line with number
  printf '%s%s%s. %s%s%s\n' "$number_indent" "$COLOR_LIST" "$number" "$COLOR_TEXT" "${wrapped_lines[0]}" "$ANSI_RESET"

  # Print continuation lines
  local -- line
  for line in "${wrapped_lines[@]:1}"; do
    printf '%s%s%s\n' "$text_indent" "$line" "$ANSI_RESET"
  done
}

# Render task list item (checkbox)
# Usage: render_task_item "indent" "status" "content" term_width
render_task_item() {
  local -- indent="$1"
  local -- status="$2"  # 'x' or ' '
  local -- content="$3"
  local -i term_width="$4"
  local -i indent_level
  local -- bullet_indent text_indent checkbox formatted_content
  local -a wrapped_lines

  # Calculate indentation
  indent_level=$((${#indent} / 2))
  bullet_indent=$(printf '  %.0s' $(seq 1 "$indent_level"))
  text_indent=$(printf '  %.0s' $(seq 1 $((indent_level + 1))))"     "  # 5 extra for "[ ] "

  # Format checkbox
  if [[ $status == 'x' ]]; then
    checkbox="${COLOR_LIST}[${ANSI_BOLD}x${ANSI_RESET}${COLOR_LIST}]"
  else
    checkbox="${COLOR_LIST}[ ]"
  fi

  # Apply inline formatting
  formatted_content=$(colorize_line "$content")

  # Wrap text
  readarray -t wrapped_lines < <(wrap_text "$formatted_content" $((term_width - ${#text_indent} - 2)))

  # Print first line
  printf '%s%s* %s %s%s%s\n' "$bullet_indent" "$COLOR_LIST" "$checkbox" "$COLOR_TEXT" "${wrapped_lines[0]}" "$ANSI_RESET"

  # Print continuation lines
  local -- line
  for line in "${wrapped_lines[@]:1}"; do
    printf '%s%s%s\n' "$text_indent" "$line" "$ANSI_RESET"
  done
}

# --------------------------------------------------------------------------------
# Blockquote rendering

# Render blockquote with proper formatting
# Usage: render_blockquote "content" term_width
render_blockquote() {
  local -- content="$1"
  local -i term_width="$2"
  local -- formatted_content
  local -a wrapped_lines

  # Apply inline formatting
  formatted_content=$(colorize_line "$content")

  # Wrap text
  readarray -t wrapped_lines < <(wrap_text "$formatted_content" $((term_width - 4)))

  # Print each line with blockquote formatting
  local -- line
  for line in "${wrapped_lines[@]}"; do
    printf '%s  > %s%s%s\n' "$COLOR_TEXT" "$COLOR_BLOCKQUOTE" "$line" "$ANSI_RESET"
  done
}

# --------------------------------------------------------------------------------
# Horizontal rule rendering

# Render horizontal rule
# Usage: render_hr term_width
render_hr() {
  local -i term_width="$1"
  local -- rule
  rule=$(printf '─%.0s' $(seq 1 $((term_width - 1))))
  printf '%s%s%s\n' "$COLOR_HR" "$rule" "$ANSI_RESET"
}

# --------------------------------------------------------------------------------
# Code block rendering (simplified syntax highlighting)

# Render a line of code with basic syntax highlighting
# Usage: render_code_line "code text" "language"
render_code_line() {
  local -- code="$1"
  local -- lang="${2:-}"
  local -- output

  # Sanitize ANSI codes from input
  code=$(sanitize_ansi "$code")

  # If syntax highlighting is disabled, just print with code color
  if ((OPTIONS[syntax_highlight] == 0)) || [[ -z $lang ]]; then
    printf '%s%s%s\n' "$COLOR_CODEBLOCK" "$code" "$ANSI_RESET"
    return 0
  fi

  # Normalize language name
  case "${lang,,}" in
    py) lang='python' ;;
    js) lang='javascript' ;;
    sh|shell) lang='bash' ;;
  esac

  # Apply simple syntax highlighting based on language
  case "${lang,,}" in
    python)
      output=$(highlight_python "$code")
      ;;
    javascript)
      output=$(highlight_javascript "$code")
      ;;
    bash)
      output=$(highlight_bash "$code")
      ;;
    *)
      output="$code"
      ;;
  esac

  printf '%s%s%s\n' "$COLOR_CODEBLOCK" "$output" "$ANSI_RESET"
}

# Simple Python syntax highlighting
# Note: Simplified to avoid nested ANSI code issues
highlight_python() {
  local -- code="$1"

  # Comments (highest priority) - return immediately
  if [[ $code =~ ^[[:space:]]*# ]]; then
    echo "${COLOR_COMMENT}${code}${COLOR_CODEBLOCK}"
    return 0
  fi

  # Docstrings - return immediately
  if [[ $code =~ (\'\'\'|\"\"\") ]]; then
    echo "${COLOR_STRING}${code}${COLOR_CODEBLOCK}"
    return 0
  fi

  # For other lines, use minimal highlighting to avoid ANSI code conflicts
  # Just highlight keywords - keep it simple
  local -- result="$code"
  result=$(sed -E "s/\\b(def|class|if|elif|else|for|while|return|import|from|print)\\b/${COLOR_KEYWORD}\\1${COLOR_CODEBLOCK}/g" <<<"$result")

  echo "$result"
}

# Simple JavaScript syntax highlighting
# Note: Simplified to avoid nested ANSI code issues
highlight_javascript() {
  local -- code="$1"

  # Comments - return immediately
  if [[ $code =~ ^[[:space:]]*// ]]; then
    echo "${COLOR_COMMENT}${code}${COLOR_CODEBLOCK}"
    return 0
  fi

  # Minimal highlighting - just keywords
  local -- result="$code"
  result=$(sed -E "s/\\b(function|const|let|var|if|else|for|while|return|class|console)\\b/${COLOR_KEYWORD}\\1${COLOR_CODEBLOCK}/g" <<<"$result")

  echo "$result"
}

# Simple Bash syntax highlighting
# Note: Simplified to avoid nested ANSI code issues
highlight_bash() {
  local -- code="$1"

  # Comments - return immediately
  if [[ $code =~ ^[[:space:]]*# ]]; then
    echo "${COLOR_COMMENT}${code}${COLOR_CODEBLOCK}"
    return 0
  fi

  # Minimal highlighting - just keywords and common built-ins
  local -- result="$code"
  result=$(sed -E "s/\\b(if|then|else|elif|fi|for|while|do|done|echo|printf|local|declare)\\b/${COLOR_KEYWORD}\\1${COLOR_CODEBLOCK}/g" <<<"$result")

  echo "$result"
}

#fin
