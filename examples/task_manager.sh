#!/bin/bash
# Example TUI Application: Task Manager
# Uses the Shell TUI Boilerplate framework

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

# Import the TUI framework
source "$PARENT_DIR/tui.sh"

# Application-specific variables
TASKS_FILE="${DATA_DIR}/tasks.txt"
CURRENT_VIEW="list"  # list, add, edit, view
SELECTED_TASK=0

# Initialize the task manager
init_task_manager() {
    # Create tasks file if it doesn't exist
    if [[ ! -f "$TASKS_FILE" ]]; then
        mkdir -p "$(dirname "$TASKS_FILE")"
        touch "$TASKS_FILE"
    fi
    
    log_debug "Task manager initialized"
}

# Show application banner
show_app_banner() {
    clear_screen
    echo -e "${BOLD_CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${BOLD_CYAN}║            Task Manager                ║${NC}"
    echo -e "${BOLD_CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
}

# Count total tasks
count_tasks() {
    if [[ -f "$TASKS_FILE" ]]; then
        wc -l < "$TASKS_FILE" | tr -d ' '
    else
        echo "0"
    fi
}

# Get task by index (1-based)
get_task() {
    local index="$1"
    if [[ -f "$TASKS_FILE" ]]; then
        sed -n "${index}p" "$TASKS_FILE"
    else
        echo ""
    fi
}

# Add a new task
add_task() {
    local task="$1"
    if [[ -n "$task" ]]; then
        echo "$task" >> "$TASKS_FILE"
        log_debug "Task added: $task"
        return 0
    else
        log_error "Cannot add empty task"
        return 1
    fi
}

# Delete a task
delete_task() {
    local index="$1"
    if [[ -f "$TASKS_FILE" ]]; then
        sed -i "${index}d" "$TASKS_FILE"
        log_debug "Task deleted at index: $index"
        return 0
    else
        log_error "Tasks file does not exist"
        return 1
    fi
}

# Mark a task as completed
mark_task_completed() {
    local index="$1"
    local task="$(get_task "$index")"
    
    if [[ -n "$task" ]]; then
        if [[ "$task" == \[X\]* ]]; then
            # Task is already completed, unmark it
            task="${task/\[X\]/\[ \]}"
        else
            # Mark task as completed
            if [[ "$task" == \[\ \]* ]]; then
                task="${task/\[ \]/\[X\]}"
            else
                task="[X] $task"
            fi
        fi
        
        # Update the task in the file
        sed -i "${index}s/.*/$task/" "$TASKS_FILE"
        log_debug "Task marked as completed at index: $index"
        return 0
    else
        log_error "Task not found at index: $index"
        return 1
    fi
}

# Show the list view
show_list_view() {
    show_app_banner
    
    local task_count=$(count_tasks)
    
    if [[ $task_count -eq 0 ]]; then
        echo "No tasks yet. Press 'a' to add a task."
    else
        echo -e "${BOLD_WHITE}Tasks:${NC} ($task_count total)"
        echo ""
        
        local i=1
        while read -r task; do
            if [[ $i -eq $SELECTED_TASK ]]; then
                echo -ne "${REVERSE}"
            fi
            
            # Display task with proper formatting
            if [[ "$task" == \[X\]* ]]; then
                echo -e "${GREEN}$i. $task${NC}"
            elif [[ "$task" == \[\ \]* ]]; then
                echo -e "$i. $task"
            else
                echo -e "$i. [ ] $task"
            fi
            
            if [[ $i -eq $SELECTED_TASK ]]; then
                echo -ne "${NC}"
            fi
            
            ((i++))
        done < "$TASKS_FILE"
    fi
    
    echo ""
    echo -e "${BOLD_WHITE}Commands:${NC}"
    echo "  a: Add task    d: Delete task    c: Toggle completion"
    echo "  j: Down        k: Up             q: Quit"
}

# Add task view
show_add_view() {
    show_app_banner
    echo -e "${BOLD_WHITE}Add Task${NC}"
    echo ""
    
    local task=""
    read -p "Enter task description (or empty to cancel): " task
    
    if [[ -n "$task" ]]; then
        # Check if task starts with a checkbox
        if [[ ! "$task" == \[??\]* ]]; then
            task="[ ] $task"
        fi
        
        add_task "$task"
        show_message "Task added!"
    fi
    
    CURRENT_VIEW="list"
}

# Handle keyboard commands in list view
handle_list_commands() {
    local key=""
    read -rsn1 key
    
    case "$key" in
        a|A)
            CURRENT_VIEW="add"
            ;;
        d|D)
            if [[ $SELECTED_TASK -gt 0 ]]; then
                if show_confirmation "Delete this task?"; then
                    delete_task "$SELECTED_TASK"
                    
                    # Adjust selection if we deleted the last task
                    local task_count=$(count_tasks)
                    if [[ $SELECTED_TASK -gt $task_count ]]; then
                        [[ $task_count -gt 0 ]] && SELECTED_TASK=$task_count || SELECTED_TASK=0
                    fi
                fi
            else
                show_message "No task selected"
            fi
            ;;
        c|C)
            if [[ $SELECTED_TASK -gt 0 ]]; then
                mark_task_completed "$SELECTED_TASK"
            else
                show_message "No task selected"
            fi
            ;;
        j|J|B)  # Down arrow or j
            local task_count=$(count_tasks)
            if [[ $task_count -gt 0 ]]; then
                ((SELECTED_TASK++))
                [[ $SELECTED_TASK -gt $task_count ]] && SELECTED_TASK=1
            fi
            ;;
        k|K|A)  # Up arrow or k
            local task_count=$(count_tasks)
            if [[ $task_count -gt 0 ]]; then
                ((SELECTED_TASK--))
                [[ $SELECTED_TASK -lt 1 ]] && SELECTED_TASK=$task_count
            fi
            ;;
        q|Q)
            if show_confirmation "Really quit?"; then
                clear_screen
                exit 0
            fi
            ;;
    esac
}

# Main application loop
main_loop() {
    # Initialize task manager
    init_task_manager
    
    # Main loop
    while true; do
        case "$CURRENT_VIEW" in
            "list")
                show_list_view
                handle_list_commands
                ;;
            "add")
                show_add_view
                ;;
        esac
    done
}

# Initialize the TUI framework
init_core
init_ui
init_logging

# Start the application
main_loop
