#!/usr/bin/env bash

_diary_config() {
	local config_file="${HOME}/.config/diary.conf"
	
	if [[ ! -f "$config_file" ]]; then
		echo "Error: Config file not found at $config_file" >&2
		echo "Create it with: echo 'DIARY_DIR=~/.diary' > $config_file" >&2
		return 1
	fi
	
	source "$config_file"
	
	# Expand ~ in path
	DIARY_DIR="${DIARY_DIR/#\~/$HOME}"
	
	if [[ -z "$DIARY_DIR" ]]; then
		echo "Error: DIARY_DIR not set in $config_file" >&2
		return 1
	fi
	
	# Create directory if it doesn't exist
	mkdir -p "$DIARY_DIR" || {
		echo "Error: Cannot create directory $DIARY_DIR" >&2
		return 1
	}
}

diary() {
	cat <<EOF
Usage: diary <command> [args]

Commands:
  diary-add <text>           Add a new diary entry
  diary-cat [FILTERS...]     List entries (optional filters)

Date Filters:
  diary-cat 2024             List entries from year 2024
  diary-cat 2024-03          List entries from March 2024
  diary-cat 2024-03-15       List entries from March 15, 2024

Tag/Project Filters:
  diary-cat +project         List entries with +project
  diary-cat @tag             List entries with @tag

Combined Filters:
  diary-cat 2024 +backend    List 2024 entries with +backend
  diary-cat 2024-03 @bug     List March 2024 entries tagged @bug
  diary-cat 2024 +proj @tag  List 2024 with +proj and @tag

Examples:
  diary-add "Deployed v1.2.0 +backend @production"
  diary-cat 2024
  diary-cat +backend
  diary-cat 2024 +backend @done
EOF
}

diary-add-usage() {
	cat <<EOF
Usage: diary-add "entry text"

Entry text can include:
  Plain text              Any content to record
  +project                Mark with project name
  @tag                    Mark with tag
  Multiple tags/projects  +backend @urgent @deploy

Examples:
  diary-add "Deployed v1.2.0"
  diary-add "Fixed bug in auth +security @urgent"
  diary-add "Meeting with team +project @done"
  diary-add "Refactored parser +backend @tech-debt"

Entry format in diary files:
  [YYYY-MM-DD] entry text +project @tag
EOF
}

diary-add() {
	[[ "$1" == "-h" || "$1" == "--help" ]] && { diary-add-usage; return 0; }
	_diary_config || return 1

	local entry_text
	if [[ $# -eq 0 ]]; then
		read -r -p "Entry: " entry_text
		[[ -z "$entry_text" ]] && return 0
	else
		entry_text="$*"
	fi
	local today=$(date +%Y-%m-%d)
	local month=$(date +%Y-%m)
	local diary_file="$DIARY_DIR/${month}.md"
	
	# Append entry with date prefix
	echo "[${today}] ${entry_text}" >> "$diary_file"
	echo "Entry added to $diary_file"
}

diary-cat-usage() {
	cat <<EOF
Usage: diary-cat [FILTERS...]

Date Filters (optional):
  2024              Entries from year 2024
  2024-03           Entries from March 2024
  2024-03-15        Entries from March 15, 2024

Tag/Project Filters (optional):
  +project          Entries with +project
  @tag              Entries with @tag

Combined Filters (all must match):
  diary-cat 2024 +backend          Year 2024 with +backend
  diary-cat 2024-03 @bug           March 2024 tagged @bug
  diary-cat 2024 +proj @done       2024 with both +proj and @done
  diary-cat 2024-03-15 +work @test Specific date with multiple tags

No arguments:
  diary-cat                         List all entries
EOF
}

diary-cat() {
	[[ "$1" == "-h" || "$1" == "--help" ]] && { diary-cat-usage; return 0; }
	_diary_config || return 1
	
	# Build patterns array from all arguments
	local -a patterns=()
	local date_pattern=""
	
	for arg in "$@"; do
		if [[ "$arg" =~ ^[0-9]{4}$ ]]; then
			# Year only: yyyy
			date_pattern="^\[${arg}-"
		elif [[ "$arg" =~ ^[0-9]{4}-[0-9]{2}$ ]]; then
			# Year-Month: yyyy-MM
			date_pattern="^\[${arg}-"
		elif [[ "$arg" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
			# Full date: yyyy-MM-dd
			date_pattern="^\[${arg}\]"
		elif [[ "$arg" =~ ^\+ ]] || [[ "$arg" =~ ^@ ]]; then
			# Project (+name) or Tag (@name)
			patterns+=("$arg")
		else
			echo "Error: Invalid filter format '$arg'. Use yyyy, yyyy-MM, yyyy-MM-dd, +project, or @tag" >&2
			return 1
		fi
	done
	
	# Find and display matching entries
	local found=0
	for file in "$DIARY_DIR"/*.md; do
		if [[ -f "$file" ]]; then
			while IFS= read -r line; do
				# Check date pattern if specified
				if [[ -n "$date_pattern" ]] && ! [[ "$line" =~ $date_pattern ]]; then
					continue
				fi
				
				# Check all tag/project patterns
				local all_match=true
				for pattern in "${patterns[@]}"; do
					if ! [[ "$line" =~ $pattern ]]; then
						all_match=false
						break
					fi
				done
				
				if $all_match; then
					echo "$line"
					((found++))
				fi
			done < "$file"
		fi
	done
	
	if (( found == 0 )); then
		echo "No entries found matching: $*" >&2
		return 1
	fi
}
