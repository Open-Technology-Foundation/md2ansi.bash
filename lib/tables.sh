#!/usr/bin/env bash
# Table parsing and rendering functions for md2ansi
# Handles complex table formatting with alignment and inline styling
# This is a sourced library, not an executable script
# Version: 0.9.6-bash

# --------------------------------------------------------------------------------
# Main table rendering function

# Parse and render a complete table
# Usage: render_table lines_array_name current_index_varname
# Updates the index to point to first line after table
render_table() {
  local -n _md_lines=$1
  local -n _md_idx=$2

  local -a table_lines=() all_rows=() data_rows=() alignments=() col_widths=()
  local -i has_alignment=0 col_count=0
  local -- line

  debug "Parsing table starting at line $_md_idx"

  # --------------------------------------------------------------------------------
  # Step 1: Collect all consecutive table lines
  while ((_md_idx < ${#_md_lines[@]})); do
    line="${_md_lines[_md_idx]}"
    # Check if line starts with | (possibly after spaces)
    [[ $line =~ ^[[:space:]]*\| ]] || break
    table_lines+=("$line")
    _md_idx+=1
  done

  debug "Collected ${#table_lines[@]} table lines"

  # Need at least 2 lines for a valid table (header + separator or header + data)
  if ((${#table_lines[@]} < 2)); then
    warn "Invalid table: too few lines"
    return 1
  fi

  # --------------------------------------------------------------------------------
  # Step 2: Parse all rows and detect alignment row
  _parse_table_structure table_lines all_rows alignments has_alignment col_count

  debug "Parsed table: $col_count columns, alignment=$has_alignment"

  # --------------------------------------------------------------------------------
  # Step 3: Separate data rows from alignment row
  if ((has_alignment)); then
    # First row is header, second is alignment, rest are data
    data_rows=("${all_rows[0]}")  # Header
    data_rows+=("${all_rows[@]:2}")  # Skip alignment row (index 1)
  else
    # No alignment row - all rows are data
    data_rows=("${all_rows[@]}")
  fi

  # Ensure we have alignment info for all columns
  while ((${#alignments[@]} < col_count)); do
    alignments+=('left')
  done

  # --------------------------------------------------------------------------------
  # Step 4: Calculate column widths
  _calculate_column_widths data_rows col_count col_widths

  # --------------------------------------------------------------------------------
  # Step 5: Render the table
  _render_table_output data_rows alignments col_widths col_count has_alignment

  return 0
}

# --------------------------------------------------------------------------------
# Parse table structure

# Parse table lines into rows and detect alignment
# Usage: _parse_table_structure table_lines all_rows alignments has_alignment col_count
_parse_table_structure() {
  local -n _table_lines=$1
  local -n _all_rows=$2
  local -n _alignments=$3
  local -n _has_alignment=$4
  local -n _col_count=$5

  local -- line cell
  local -a cells
  local -i row_num=0 max_cols=0 i

  for line in "${_table_lines[@]}"; do
    # Remove leading/trailing whitespace
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"

    # Remove leading and trailing pipes
    line="${line#|}"
    line="${line%|}"

    # Split by pipe into cells
    IFS='|' read -ra cells <<<"$line"

    # Trim whitespace from each cell
    for ((i=0; i<${#cells[@]}; i+=1)); do
      cell="${cells[i]}"
      cell="${cell#"${cell%%[![:space:]]*}"}"
      cell="${cell%"${cell##*[![:space:]]}"}"
      cells[i]="$cell"
    done

    # Check if this is an alignment row (row 2, all cells match :?-+:?)
    if ((row_num == 1)); then
      local -i is_alignment=1
      for cell in "${cells[@]}"; do
        [[ $cell =~ ^:?-+:?$ ]] || { is_alignment=0; break; }
      done

      if ((is_alignment)); then
        _has_alignment=1
        # Parse alignment for each column
        for cell in "${cells[@]}"; do
          if [[ $cell =~ ^:-+:$ ]]; then
            _alignments+=('center')
          elif [[ $cell =~ ^-+:$ ]]; then
            _alignments+=('right')
          else
            _alignments+=('left')
          fi
        done
      fi
    fi

    # Store row (as delimited string for easier handling)
    local -- row_str
    printf -v row_str '%s\037' "${cells[@]}"  # Use unit separator character
    _all_rows+=("$row_str")

    # Track maximum column count
    ((${#cells[@]} > max_cols)) && max_cols=${#cells[@]}
    row_num+=1
  done

  _col_count=$max_cols
}

# --------------------------------------------------------------------------------
# Calculate column widths

# Calculate the width needed for each column
# Usage: _calculate_column_widths data_rows col_count col_widths
_calculate_column_widths() {
  local -n _data_rows=$1
  local -i _col_count=$2
  local -n _col_widths=$3

  local -- row cell formatted_cell stripped_cell
  local -a cells
  local -i i width

  # Initialize widths to 0
  for ((i=0; i<_col_count; i+=1)); do
    _col_widths[i]=0
  done

  # Process each row
  for row in "${_data_rows[@]}"; do
    # Parse cells (split by unit separator)
    IFS=$'\037' read -ra cells <<<"$row"

    # Measure each cell
    for ((i=0; i<${#cells[@]} && i<_col_count; i+=1)); do
      cell="${cells[i]}"

      # Apply inline formatting to get actual rendered text
      formatted_cell=$(colorize_line "$cell")

      # Get visible length (strip ANSI codes)
      stripped_cell=$(strip_ansi "$formatted_cell")
      width=${#stripped_cell}

      # Update max width for this column
      ((width > _col_widths[i])) && _col_widths[i]=$width
    done
  done

  debug "Column widths: ${_col_widths[*]}"
}

# --------------------------------------------------------------------------------
# Render table output

# Render complete table with borders and formatting
# Usage: _render_table_output data_rows alignments col_widths col_count has_alignment
_render_table_output() {
  local -n _data_rows=$1
  local -n _alignments=$2
  local -n _col_widths=$3
  local -i _col_count=$4
  local -i _has_alignment=$5

  local -- horiz_line row cell_text aligned_cell
  local -a cells
  local -i i width row_num=0

  # --------------------------------------------------------------------------------
  # Build horizontal divider line
  horiz_line='+'
  for ((i=0; i<_col_count; i+=1)); do
    width=${_col_widths[i]}
    horiz_line+=$(printf -- '-%.0s' $(seq 1 $((width + 2))))
    horiz_line+='+'
  done

  # --------------------------------------------------------------------------------
  # Print top border
  printf '%s%s%s\n' "$COLOR_TABLE" "$horiz_line" "$ANSI_RESET"

  # --------------------------------------------------------------------------------
  # Print each row
  for row in "${_data_rows[@]}"; do
    # Parse cells
    IFS=$'\037' read -ra cells <<<"$row"

    # Pad cells array to column count
    while ((${#cells[@]} < _col_count)); do
      cells+=('')
    done

    # Start row
    printf '%s|' "$COLOR_TABLE"

    # Print each cell
    for ((i=0; i<_col_count; i+=1)); do
      cell_text="${cells[i]}"

      # Apply inline formatting
      cell_text=$(colorize_line "$cell_text")

      # Align cell
      width=${_col_widths[i]}
      aligned_cell=$(_align_cell "$cell_text" "$width" "${_alignments[i]}")

      # Print cell with table color restoration
      printf ' %s%s |' "$aligned_cell" "$COLOR_TABLE"
    done

    printf '%s\n' "$ANSI_RESET"

    # Print divider after header row (if alignment was detected)
    if ((row_num == 0 && _has_alignment)); then
      printf '%s%s%s\n' "$COLOR_TABLE" "$horiz_line" "$ANSI_RESET"
    fi

    row_num+=1
  done

  # --------------------------------------------------------------------------------
  # Print bottom border
  printf '%s%s%s\n' "$COLOR_TABLE" "$horiz_line" "$ANSI_RESET"
}

# --------------------------------------------------------------------------------
# Cell alignment

# Align cell content to specified width
# Usage: _align_cell "cell_text" width "alignment"
_align_cell() {
  local -- text="$1"
  local -i width="$2"
  local -- alignment="$3"
  local -- stripped_text
  local -i visible_len padding left_pad right_pad

  # Get visible length
  stripped_text=$(strip_ansi "$text")
  visible_len=${#stripped_text}

  # Calculate padding needed
  padding=$((width - visible_len))
  ((padding < 0)) && padding=0

  case "$alignment" in
    center)
      # Center alignment
      left_pad=$((padding / 2))
      right_pad=$((padding - left_pad))
      printf '%*s%s%*s' "$left_pad" '' "$text" "$right_pad" ''
      ;;
    right)
      # Right alignment
      printf '%*s%s' "$padding" '' "$text"
      ;;
    *)
      # Left alignment (default)
      printf '%s%*s' "$text" "$padding" ''
      ;;
  esac
}

#fin
