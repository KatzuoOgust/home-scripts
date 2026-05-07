#!/bin/bash

# todo.txt command-line interface
# Supports add, list, do (complete), delete, and filtering by priorities/projects/contexts

_todo_find_file() {
    local pwd_todo="todo.txt"
    local pwd_custom_todos
    
    pwd_custom_todos=($(find . -maxdepth 1 -name "*.todo.txt" 2>/dev/null | sort))
    
    # Check for todo.txt in current directory
    if [[ -f "$pwd_todo" ]]; then
        if [[ ${#pwd_custom_todos[@]} -gt 0 ]]; then
            # Both todo.txt and custom .todo.txt files exist
            echo "Multiple todo files found:" >&2
            echo "  0) $pwd_todo" >&2
            for i in "${!pwd_custom_todos[@]}"; do
                echo "  $((i + 1))) ${pwd_custom_todos[$i]}" >&2
            done
            read -p "Select file (0-$((${#pwd_custom_todos[@]})): " choice >&2
            if [[ $choice -eq 0 ]]; then
                echo "$pwd_todo"
            else
                echo "${pwd_custom_todos[$((choice - 1))]}"
            fi
        else
            echo "$pwd_todo"
        fi
    elif [[ ${#pwd_custom_todos[@]} -eq 1 ]]; then
        echo "${pwd_custom_todos[0]}"
    elif [[ ${#pwd_custom_todos[@]} -gt 1 ]]; then
        echo "Multiple custom todo files found:" >&2
        for i in "${!pwd_custom_todos[@]}"; do
            echo "  $((i + 1))) ${pwd_custom_todos[$i]}" >&2
        done
        read -p "Select file (1-${#pwd_custom_todos[@]}): " choice >&2
        echo "${pwd_custom_todos[$((choice - 1))]}"
    else
        echo "$HOME/todo.txt"
    fi
}

_todo_ensure_file() {
    local todo_file="$1"
    if [[ ! -f "$todo_file" ]]; then
        touch "$todo_file"
    fi
}

_todo_list() {
    local todo_file="$1"
    local filter="$2"
    
    if [[ ! -f "$todo_file" ]]; then
        echo "No tasks yet."
        return
    fi
    
    awk -v filter="$filter" '
    NR == FNR {
        if (filter == "") {
            printf "%3d  %s\n", NR, $0
        } else if ($0 ~ filter) {
            printf "%3d  %s\n", NR, $0
        }
        next
    }
    ' "$todo_file" "$todo_file" | grep -v "^[[:space:]]*$"
}

_todo_add() {
    local todo_file="$1"
    shift
    local task="$@"
    
    _todo_ensure_file "$todo_file"
    echo "$task" >> "$todo_file"
    echo "Added: $task"
}

_todo_do() {
    local todo_file="$1"
    local line_num="$2"
    
    if [[ ! $line_num =~ ^[0-9]+$ ]]; then
        echo "Error: line number must be numeric" >&2
        return 1
    fi
    
    if [[ ! -f "$todo_file" ]]; then
        echo "Error: todo file not found" >&2
        return 1
    fi
    
    local total_lines=$(wc -l < "$todo_file")
    if [[ $line_num -lt 1 || $line_num -gt $total_lines ]]; then
        echo "Error: line number out of range (1-$total_lines)" >&2
        return 1
    fi
    
    local task=$(sed -n "${line_num}p" "$todo_file")
    local done_task="x $(date +%Y-%m-%d) $task"
    
    sed -i "${line_num}s/.*/$(echo "$done_task" | sed 's/[\/&]/\\&/g')/" "$todo_file"
    echo "Done: $task"
}

_todo_delete() {
    local todo_file="$1"
    local line_num="$2"
    
    if [[ ! $line_num =~ ^[0-9]+$ ]]; then
        echo "Error: line number must be numeric" >&2
        return 1
    fi
    
    if [[ ! -f "$todo_file" ]]; then
        echo "Error: todo file not found" >&2
        return 1
    fi
    
    local total_lines=$(wc -l < "$todo_file")
    if [[ $line_num -lt 1 || $line_num -gt $total_lines ]]; then
        echo "Error: line number out of range (1-$total_lines)" >&2
        return 1
    fi
    
    local task=$(sed -n "${line_num}p" "$todo_file")
    sed -i "${line_num}d" "$todo_file"
    echo "Deleted: $task"
}

_todo_help() {
    cat << 'EOF'
todo.txt CLI - Simple task management

USAGE:
  todo [command] [args...]

COMMANDS:
  add TEXT              Add a new task
  list                  List all tasks
  list [FILTER]         List tasks matching filter (regex)
  do NUM                Mark task NUM as done
  delete NUM            Delete task NUM
  open                  Open todo file in editor
  help                  Show this help

EXAMPLES:
  todo add Buy milk
  todo add +Project @home -priority
  todo list              # Show all tasks
  todo list "@home"      # Show tasks with @home
  todo list "\+urgent"   # Show tasks with +urgent
  todo do 3              # Mark task 3 as done
  todo delete 5          # Delete task 5
  todo open             # Edit todo file

TASK FORMAT (todo.txt):
  Simple text: Buy milk
  With priority (A-Z): (A) Task name
  With projects: +ProjectName
  With contexts: @home @work
  Completion: x YYYY-MM-DD Task name

EOF
}

todo() {
    local command="${1:-list}"
    
    case "$command" in
        help|--help|-h)
            _todo_help
            ;;
        add)
            shift
            local todo_file
            todo_file=$(_todo_find_file) || return 1
            _todo_add "$todo_file" "$@"
            ;;
        list)
            local filter="${2:-}"
            local todo_file
            todo_file=$(_todo_find_file) || return 1
            _todo_list "$todo_file" "$filter"
            ;;
        do)
            if [[ -z "$2" ]]; then
                echo "Error: task number required" >&2
                return 1
            fi
            local todo_file
            todo_file=$(_todo_find_file) || return 1
            _todo_do "$todo_file" "$2"
            ;;
        delete)
            if [[ -z "$2" ]]; then
                echo "Error: task number required" >&2
                return 1
            fi
            local todo_file
            todo_file=$(_todo_find_file) || return 1
            _todo_delete "$todo_file" "$2"
            ;;
        open)
            local todo_file
            todo_file=$(_todo_find_file) || return 1
            _todo_ensure_file "$todo_file"
            "${EDITOR:-nano}" "$todo_file"
            ;;
        *)
            echo "Unknown command: $command" >&2
            _todo_help
            return 1
            ;;
    esac
}
