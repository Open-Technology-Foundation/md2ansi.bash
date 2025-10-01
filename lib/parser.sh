#!/usr/bin/env bash
# Parser functions for md2ansi
# Handles block-level markdown parsing and coordination with renderer
# This is a sourced library, not an executable script
# Version: 0.9.6-bash

# Source table rendering library
source "$SCRIPT_DIR/lib/tables.sh"

# --------------------------------------------------------------------------------
# Main markdown parser

# Parse markdown line array and produce ANSI output
# Usage: parse_markdown lines_array_name
parse_markdown() {
  local -n _lines=$1
  local -i i=0
  local -- line original_line

  # Reset parsing state
  IN_CODE_BLOCK=0
  CODE_FENCE_TYPE=''
  CODE_LANG=''
  FOOTNOTES=()
  FOOTNOTE_REFS=()

  while ((i < ${#_lines[@]})); do
    line="${_lines[i]}"
    original_line="$line"

    # Trim trailing whitespace
    line="${line%"${line##*[![:space:]]}"}"

    # --------------------------------------------------------------------------------
    # CODE BLOCKS - Fenced (``` or ~~~)
    # Use literal backticks in regex
    if [[ $line =~ ^(\`\`\`|~~~)(.*)$ ]]; then
      local -- fence="${BASH_REMATCH[1]}"
      local -- lang_spec="${BASH_REMATCH[2]}"
      lang_spec="${lang_spec## }"  # Trim leading spaces
      lang_spec="${lang_spec%% }"  # Trim trailing spaces

      if ((IN_CODE_BLOCK)); then
        # Closing fence
        printf '%s%s%s\n' "$COLOR_CODEBLOCK" "$fence" "$ANSI_RESET"
        IN_CODE_BLOCK=0
        CODE_FENCE_TYPE=''
        CODE_LANG=''
      else
        # Opening fence
        IN_CODE_BLOCK=1
        CODE_FENCE_TYPE="$fence"
        CODE_LANG="$lang_spec"
        printf '%s%s' "$COLOR_CODEBLOCK" "$fence"
        [[ -n $lang_spec ]] && printf ' %s' "$lang_spec"
        printf '%s\n' "$ANSI_RESET"
      fi
      i+=1
      continue
    fi

    # Inside code block - render code lines
    if ((IN_CODE_BLOCK)); then
      render_code_line "$line" "$CODE_LANG"
      i+=1
      continue
    fi

    # --------------------------------------------------------------------------------
    # TABLES - Lines starting with |
    if [[ $line =~ ^[[:space:]]*\| ]] && ((OPTIONS[tables])); then
      render_table _lines i
      # render_table updates i to next line after table
      continue
    elif [[ $line =~ ^[[:space:]]*\| ]] && ((OPTIONS[tables] == 0)); then
      # Tables disabled but looks like a table - treat as plain text
      local -- formatted_line
      formatted_line=$(colorize_line "$line")
      readarray -t wrapped < <(wrap_text "${COLOR_TEXT}${formatted_line}" "$TERM_WIDTH")
      printf '%s\n' "${wrapped[@]}"
      i+=1
      continue
    fi

    # --------------------------------------------------------------------------------
    # HORIZONTAL RULES: --- / === / ___
    if [[ $line =~ ^[[:space:]]*([-_=])\1{2,}[[:space:]]*$ ]]; then
      render_hr "$TERM_WIDTH"
      i+=1
      continue
    fi

    # --------------------------------------------------------------------------------
    # BLOCKQUOTES: Lines starting with >
    if [[ $line =~ ^[[:space:]]*\>[[:space:]]?(.*)$ ]]; then
      local -- quote_content="${BASH_REMATCH[1]}"
      render_blockquote "$quote_content" "$TERM_WIDTH"
      i+=1
      continue
    fi

    # --------------------------------------------------------------------------------
    # HEADERS: # through ######
    if [[ $line =~ ^(#{1,6})[[:space:]]+(.+)$ ]]; then
      local -- hashes="${BASH_REMATCH[1]}"
      local -- header_text="${BASH_REMATCH[2]}"
      render_header "$hashes" "$header_text"
      i+=1
      continue
    fi

    # --------------------------------------------------------------------------------
    # TASK LISTS: - [ ] or - [x]
    if [[ $line =~ ^([[:space:]]*)[-*][[:space:]]+\[([[:space:]x])\][[:space:]]+(.+)$ ]]; then
      local -- indent="${BASH_REMATCH[1]}"
      local -- status="${BASH_REMATCH[2]}"
      local -- task_content="${BASH_REMATCH[3]}"

      if ((OPTIONS[task_lists])); then
        render_task_item "$indent" "$status" "$task_content" "$TERM_WIDTH"
      else
        # Treat as regular list with checkbox as part of content
        render_list_item "$indent" "[$status] $task_content" "$TERM_WIDTH"
      fi
      i+=1
      continue
    fi

    # --------------------------------------------------------------------------------
    # UNORDERED LISTS: - or *
    if [[ $line =~ ^([[:space:]]*)[-*][[:space:]]+(.+)$ ]]; then
      local -- indent="${BASH_REMATCH[1]}"
      local -- list_content="${BASH_REMATCH[2]}"
      render_list_item "$indent" "$list_content" "$TERM_WIDTH"
      i+=1
      continue
    fi

    # --------------------------------------------------------------------------------
    # ORDERED LISTS: 1. 2. etc.
    if [[ $line =~ ^([[:space:]]*)([0-9]+)\.[[:space:]]+(.+)$ ]]; then
      local -- indent="${BASH_REMATCH[1]}"
      local -- number="${BASH_REMATCH[2]}"
      local -- list_content="${BASH_REMATCH[3]}"
      render_ordered_item "$indent" "$number" "$list_content" "$TERM_WIDTH"
      i+=1
      continue
    fi

    # --------------------------------------------------------------------------------
    # FOOTNOTE DEFINITIONS: [^id]: text
    if [[ $line =~ ^\[\^([^]]+)\]:[[:space:]]+(.+)$ ]] && ((OPTIONS[footnotes])); then
      local -- footnote_id="${BASH_REMATCH[1]}"
      local -- footnote_text="${BASH_REMATCH[2]}"

      # Store footnote
      FOOTNOTES[$footnote_id]="$footnote_text"

      # Track reference order
      if [[ ! " ${FOOTNOTE_REFS[*]} " =~ " ${footnote_id} " ]]; then
        FOOTNOTE_REFS+=("$footnote_id")
      fi

      # Skip rendering this line
      i+=1
      continue
    fi

    # --------------------------------------------------------------------------------
    # EMPTY LINES
    if [[ -z $line ]]; then
      echo ""
      i+=1
      continue
    fi

    # --------------------------------------------------------------------------------
    # REGULAR TEXT - with inline formatting
    local -- formatted_line
    local -a wrapped

    # Find and track footnote references in text
    if ((OPTIONS[footnotes])); then
      while [[ $line =~ \[\^([^]]+)\] ]]; do
        local -- ref_id="${BASH_REMATCH[1]}"
        if [[ ! " ${FOOTNOTE_REFS[*]} " =~ " ${ref_id} " ]]; then
          FOOTNOTE_REFS+=("$ref_id")
        fi
        # Remove matched part to find next
        line="${line/${BASH_REMATCH[0]}/}"
      done
      line="$original_line"  # Restore for colorization
    fi

    formatted_line=$(colorize_line "$line")
    readarray -t wrapped < <(wrap_text "${COLOR_TEXT}${formatted_line}" "$TERM_WIDTH")

    printf '%s\n' "${wrapped[@]}"
    i+=1
  done

  # --------------------------------------------------------------------------------
  # Render footnotes section at end if any exist
  if ((OPTIONS[footnotes])) && ((${#FOOTNOTES[@]} > 0)) && ((${#FOOTNOTE_REFS[@]} > 0)); then
    render_footnotes
  fi
}

# --------------------------------------------------------------------------------
# Footnote rendering

# Render collected footnotes at end of document
render_footnotes() {
  local -- ref_id footnote_text formatted_text

  echo ""
  printf '%s%s%s\n' "$COLOR_H2" "Footnotes:" "$ANSI_RESET"
  echo ""

  for ref_id in "${FOOTNOTE_REFS[@]}"; do
    if [[ -n ${FOOTNOTES[$ref_id]:-} ]]; then
      footnote_text="${FOOTNOTES[$ref_id]}"
      formatted_text=$(colorize_line "$footnote_text")
      printf '%s[%s%s^%s%s%s]: %s%s\n' \
        "$COLOR_TEXT" \
        "$ANSI_BOLD" "$ANSI_DIM" "$ref_id" "$ANSI_RESET" "$COLOR_TEXT" \
        "$formatted_text" \
        "$ANSI_RESET"
    else
      # Reference without definition
      printf '%s[%s%s^%s%s%s]: %sMissing footnote definition%s\n' \
        "$COLOR_TEXT" \
        "$ANSI_BOLD" "$ANSI_DIM" "$ref_id" "$ANSI_RESET" "$COLOR_TEXT" \
        "${ANSI_ITALIC}" \
        "$ANSI_RESET"
    fi
  done
}

#fin
