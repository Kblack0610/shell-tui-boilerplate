#!/bin/bash
# Shell TUI Boilerplate - Input Module
# Provides input handling functionality

# Prevent multiple sourcing
[[ -n "$__TUI_INPUT_LOADED" ]] && return
__TUI_INPUT_LOADED=true

# Input field types
INPUT_TYPE_TEXT=0
INPUT_TYPE_PASSWORD=1
INPUT_TYPE_NUMBER=2
INPUT_TYPE_OPTION=3

# Character filters for different input types
INPUT_FILTER_ALPHA="[A-Za-z]"
INPUT_FILTER_NUMERIC="[0-9]"
INPUT_FILTER_ALPHANUMERIC="[A-Za-z0-9]"
INPUT_FILTER_ALL="."

# Read a line of input with optional validation
read_input() {
    local prompt="$1"
    local default="${2:-}"
    local validation="${3:-$INPUT_FILTER_ALL}"
    local max_length="${4:-100}"
    
    local input="$default"
    local curpos=${#default}
    local key=""
    
    # Display prompt and default value
    echo -ne "$prompt"
    [[ -n "$default" ]] && echo -n "$default"
    
    # Position cursor at end of default text
    [[ -n "$default" ]] && tput cuf ${#default}
    
    while true; do
        # Read a single character
        read -rsn1 key
        
        # Handle special keys
        case "$key" in
            $'\177'|$'\010') # Backspace/Delete
                if [[ $curpos -gt 0 ]]; then
                    input="${input:0:$((curpos-1))}${input:$curpos}"
                    ((curpos--))
                    echo -ne "\r\033[K$prompt$input"
                    if [[ $curpos -lt ${#input} ]]; then
                        tput cub $((${#input} - curpos))
                    fi
                fi
                ;;
            $'\033') # Escape sequence (arrow keys, etc.)
                read -rsn2 -t 0.001 escseq
                case "$escseq" in
                    "[D") # Left arrow
                        if [[ $curpos -gt 0 ]]; then
                            ((curpos--))
                            tput cub 1
                        fi
                        ;;
                    "[C") # Right arrow
                        if [[ $curpos -lt ${#input} ]]; then
                            ((curpos++))
                            tput cuf 1
                        fi
                        ;;
                    "[H") # Home
                        curpos=0
                        tput cub ${#input}
                        ;;
                    "[F") # End
                        curpos=${#input}
                        tput cuf $((${#input} - curpos))
                        ;;
                esac
                ;;
            "") # Enter/Return
                echo ""
                return 0
                ;;
            *)  # Regular character
                # Check if character passes the validation and max length
                if [[ ${#input} -lt $max_length && "$key" =~ $validation ]]; then
                    input="${input:0:$curpos}$key${input:$curpos}"
                    ((curpos++))
                    echo -ne "\r\033[K$prompt$input"
                    if [[ $curpos -lt ${#input} ]]; then
                        tput cub $((${#input} - curpos))
                    fi
                fi
                ;;
        esac
    done
    
    echo "$input"
}

# Read a password (input is hidden)
read_password() {
    local prompt="$1"
    local validation="${2:-$INPUT_FILTER_ALL}"
    local max_length="${3:-100}"
    
    local input=""
    local key=""
    
    # Display prompt
    echo -ne "$prompt"
    
    while true; do
        # Read a single character
        read -rsn1 key
        
        # Handle special keys
        case "$key" in
            $'\177'|$'\010') # Backspace/Delete
                if [[ ${#input} -gt 0 ]]; then
                    input="${input:0:$((${#input}-1))}"
                    echo -ne "\b \b" # Erase the * character
                fi
                ;;
            "") # Enter/Return
                echo ""
                break
                ;;
            *)  # Regular character
                # Check if character passes the validation and max length
                if [[ ${#input} -lt $max_length && "$key" =~ $validation ]]; then
                    input="$input$key"
                    echo -n "*" # Display * for each character
                fi
                ;;
        esac
    done
    
    echo "$input"
}

# Read numeric input within a range
read_number() {
    local prompt="$1"
    local min="${2:-0}"
    local max="${3:-100}"
    local default="${4:-$min}"
    
    local num=""
    
    while true; do
        echo -ne "$prompt ($min-$max) [$default]: "
        read num
        
        # Use default if empty
        [[ -z "$num" ]] && num="$default"
        
        # Validate input
        if [[ "$num" =~ ^[0-9]+$ && $num -ge $min && $num -le $max ]]; then
            break
        else
            echo "Please enter a number between $min and $max."
        fi
    done
    
    echo "$num"
}

# Display a selection menu with arrow key navigation
select_option() {
    local prompt="$1"
    shift
    local options=("$@")
    
    local selected=0
    local key=""
    
    while true; do
        clear_screen
        echo "$prompt"
        echo ""
        
        # Display options with selected highlighted
        for i in "${!options[@]}"; do
            if [[ $i -eq $selected ]]; then
                echo -ne "${THEME_COLORS[${UI_THEME}_selected]} > ${options[$i]} $NC\n"
            else
                echo "   ${options[$i]}"
            fi
        done
        
        # Read key
        read -rsn1 key
        
        case "$key" in
            "A"|"k") # Up arrow or k
                ((selected--))
                [[ $selected -lt 0 ]] && selected=$((${#options[@]} - 1))
                ;;
            "B"|"j") # Down arrow or j
                ((selected++))
                [[ $selected -ge ${#options[@]} ]] && selected=0
                ;;
            "") # Enter
                return $selected
                ;;
        esac
    done
}

# Display a multi-select menu
multi_select() {
    local prompt="$1"
    shift
    local options=("$@")
    
    local selected=()
    local current=0
    local key=""
    
    # Initialize selected array
    for ((i=0; i<${#options[@]}; i++)); do
        selected[$i]=0
    done
    
    while true; do
        clear_screen
        echo "$prompt"
        echo "Use space to toggle selection, Enter to confirm"
        echo ""
        
        # Display options
        for i in "${!options[@]}"; do
            if [[ $i -eq $current ]]; then
                echo -ne "${THEME_COLORS[${UI_THEME}_selected]}"
            fi
            
            if [[ ${selected[$i]} -eq 1 ]]; then
                echo -n " [X] "
            else
                echo -n " [ ] "
            fi
            
            echo -n "${options[$i]}"
            echo -e "$NC"
        done
        
        # Read key
        read -rsn1 key
        
        case "$key" in
            "A"|"k") # Up arrow or k
                ((current--))
                [[ $current -lt 0 ]] && current=$((${#options[@]} - 1))
                ;;
            "B"|"j") # Down arrow or j
                ((current++))
                [[ $current -ge ${#options[@]} ]] && current=0
                ;;
            " ") # Space
                if [[ ${selected[$current]} -eq 0 ]]; then
                    selected[$current]=1
                else
                    selected[$current]=0
                fi
                ;;
            "") # Enter
                # Return selected items
                local result=""
                for i in "${!selected[@]}"; do
                    [[ ${selected[$i]} -eq 1 ]] && result="$result$i,"
                done
                # Remove trailing comma
                result="${result%,}"
                echo "$result"
                return
                ;;
        esac
    done
}

# Create an input form with multiple fields
input_form() {
    local title="$1"
    shift
    local labels=("$@")
    local values=()
    local types=()
    local validations=()
    
    # Extract field information
    for ((i=0; i<${#labels[@]}; i+=4)); do
        fields+=("${labels[$i]}")
        values+=("${labels[$((i+1))]}")
        types+=("${labels[$((i+2))]}")
        validations+=("${labels[$((i+3))]}")
    done
    
    local num_fields=${#fields[@]}
    local current=0
    local key=""
    
    while true; do
        clear_screen
        draw_box 1 1 60 $((num_fields + 6)) "$title"
        
        # Display form fields
        for ((i=0; i<num_fields; i++)); do
            move_cursor $((i + 3)) 3
            echo -n "${fields[$i]}: "
            
            # Highlight current field
            if [[ $i -eq $current ]]; then
                echo -ne "${THEME_COLORS[${UI_THEME}_selected]}"
            fi
            
            # Display value based on type
            case "${types[$i]}" in
                "$INPUT_TYPE_PASSWORD")
                    local stars=""
                    for ((j=0; j<${#values[$i]}; j++)); do
                        stars="$stars*"
                    done
                    echo -n "$stars"
                    ;;
                *)
                    echo -n "${values[$i]}"
                    ;;
            esac
            
            echo -e "$NC"
        done
        
        # Display navigation instructions
        move_cursor $((num_fields + 4)) 3
        echo "Use arrows to navigate, Enter to edit, ESC to submit"
        
        # Read key
        read -rsn1 key
        
        case "$key" in
            "A"|"k") # Up arrow or k
                ((current--))
                [[ $current -lt 0 ]] && current=$((num_fields - 1))
                ;;
            "B"|"j") # Down arrow or j
                ((current++))
                [[ $current -ge $num_fields ]] && current=0
                ;;
            "") # Enter - edit field
                move_cursor $((current + 3)) $((${#fields[$current]} + 5))
                echo -ne "\033[K" # Clear to end of line
                
                # Edit field based on type
                case "${types[$current]}" in
                    "$INPUT_TYPE_PASSWORD")
                        values[$current]=$(read_password "" "${validations[$current]}")
                        ;;
                    "$INPUT_TYPE_NUMBER")
                        values[$current]=$(read_number "" 0 100 "${values[$current]}")
                        ;;
                    *)
                        values[$current]=$(read_input "" "${values[$current]}" "${validations[$current]}")
                        ;;
                esac
                ;;
            $'\033') # Escape sequence or ESC key
                read -rsn2 -t 0.001 escseq
                if [[ -z "$escseq" ]]; then
                    # Return form data
                    local result=""
                    for v in "${values[@]}"; do
                        result="$result$v|"
                    done
                    # Remove trailing pipe
                    result="${result%|}"
                    echo "$result"
                    return
                fi
                ;;
        esac
    done
}

# Check for key press with timeout (non-blocking)
key_pressed() {
    local timeout="${1:-0.1}"
    local key=""
    
    # Use read with timeout to check for key press
    read -rsn1 -t "$timeout" key
    
    # Return the key pressed, or empty string if none
    echo "$key"
}

# Wait for any key to be pressed
wait_for_any_key() {
    local prompt="${1:-Press any key to continue...}"
    
    echo "$prompt"
    read -rsn1
}

# Accept a yes/no answer (returns 0 for yes, 1 for no)
yes_no_prompt() {
    local prompt="$1"
    local default="${2:-y}"
    
    local response=""
    
    # Make sure default is lower case y or n
    default=$(echo "$default" | tr '[:upper:]' '[:lower:]')
    
    # Show appropriate prompt based on default
    if [[ "$default" == "y" ]]; then
        echo -n "$prompt [Y/n]: "
    else
        echo -n "$prompt [y/N]: "
    fi
    
    # Read response
    read response
    
    # Convert to lowercase
    response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
    
    # Use default if empty
    [[ -z "$response" ]] && response="$default"
    
    # Return 0 for yes, 1 for no
    if [[ "$response" == "y" || "$response" == "yes" ]]; then
        return 0
    else
        return 1
    fi
}
