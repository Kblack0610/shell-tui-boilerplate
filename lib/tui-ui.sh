#!/bin/bash
# Shell TUI Boilerplate - UI Module
# Provides UI components and rendering functionality

# Prevent multiple sourcing
[[ -n "$__TUI_UI_LOADED" ]] && return
__TUI_UI_LOADED=true

# UI theme settings (can be overridden in config)
UI_THEME="default"
UI_BORDER_STYLE="single"
UI_ANIMATION_ENABLED=true

# Border characters for different styles
declare -A BORDER_CHARS
BORDER_CHARS[single_tl]="┌"
BORDER_CHARS[single_tr]="┐"
BORDER_CHARS[single_bl]="└"
BORDER_CHARS[single_br]="┘"
BORDER_CHARS[single_h]="─"
BORDER_CHARS[single_v]="│"

BORDER_CHARS[double_tl]="╔"
BORDER_CHARS[double_tr]="╗"
BORDER_CHARS[double_bl]="╚"
BORDER_CHARS[double_br]="╝"
BORDER_CHARS[double_h]="═"
BORDER_CHARS[double_v]="║"

BORDER_CHARS[round_tl]="╭"
BORDER_CHARS[round_tr]="╮"
BORDER_CHARS[round_bl]="╰"
BORDER_CHARS[round_br]="╯"
BORDER_CHARS[round_h]="─"
BORDER_CHARS[round_v]="│"

# Theme colors
declare -A THEME_COLORS
THEME_COLORS[default_fg]="$WHITE"
THEME_COLORS[default_bg]="$BG_BLACK"
THEME_COLORS[default_title]="$BOLD_WHITE"
THEME_COLORS[default_border]="$CYAN"
THEME_COLORS[default_selected]="$BG_CYAN$BLACK"
THEME_COLORS[default_error]="$RED"
THEME_COLORS[default_success]="$GREEN"
THEME_COLORS[default_warning]="$YELLOW"
THEME_COLORS[default_info]="$BLUE"

THEME_COLORS[dark_fg]="$WHITE"
THEME_COLORS[dark_bg]="$BG_BLACK"
THEME_COLORS[dark_title]="$BOLD_CYAN"
THEME_COLORS[dark_border]="$BLUE"
THEME_COLORS[dark_selected]="$BG_BLUE$WHITE"
THEME_COLORS[dark_error]="$RED"
THEME_COLORS[dark_success]="$GREEN"
THEME_COLORS[dark_warning]="$YELLOW"
THEME_COLORS[dark_info]="$CYAN"

THEME_COLORS[light_fg]="$BLACK"
THEME_COLORS[light_bg]="$BG_WHITE"
THEME_COLORS[light_title]="$BOLD_BLACK"
THEME_COLORS[light_border]="$BLUE"
THEME_COLORS[light_selected]="$BG_BLUE$WHITE"
THEME_COLORS[light_error]="$RED"
THEME_COLORS[light_success]="$GREEN"
THEME_COLORS[light_warning]="$YELLOW"
THEME_COLORS[light_info]="$BLUE"

# Check for needed utilities
command -v tput >/dev/null 2>&1 || {
    log_error "tput command not found, UI may not display correctly"
}

# Initialize UI components
init_ui() {
    # Set up terminal and clear screen
    clear_screen
    hide_cursor
    
    # Apply theme settings
    apply_theme "$UI_THEME"
    
    log_debug "UI initialized with theme: $UI_THEME"
}

# Apply a theme
apply_theme() {
    local theme="${1:-default}"
    UI_THEME="$theme"
    
    # Set terminal colors based on theme
    echo -ne "${THEME_COLORS[${theme}_bg]}${THEME_COLORS[${theme}_fg]}"
    
    log_debug "Applied theme: $theme"
}

# Draw a box with optional title
draw_box() {
    local top_row="$1"
    local left_col="$2"
    local width="$3"
    local height="$4"
    local title="${5:-}"
    local style="${6:-$UI_BORDER_STYLE}"
    
    # Get border characters based on style
    local tl="${BORDER_CHARS[${style}_tl]}"
    local tr="${BORDER_CHARS[${style}_tr]}"
    local bl="${BORDER_CHARS[${style}_bl]}"
    local br="${BORDER_CHARS[${style}_br]}"
    local h="${BORDER_CHARS[${style}_h]}"
    local v="${BORDER_CHARS[${style}_v]}"
    
    # Set border color
    echo -ne "${THEME_COLORS[${UI_THEME}_border]}"
    
    # Draw top border
    move_cursor "$top_row" "$left_col"
    echo -n "$tl"
    
    # If title is provided, add it to the top border
    if [[ -n "$title" ]]; then
        # Calculate positions for title
        local title_len=${#title}
        local border_len=$(( width - 2 ))
        local left_padding=$(( (border_len - title_len - 2) / 2 ))
        local right_padding=$(( border_len - title_len - 2 - left_padding ))
        
        printf "%${left_padding}s" | tr " " "$h"
        echo -ne "${THEME_COLORS[${UI_THEME}_title]} $title ${THEME_COLORS[${UI_THEME}_border]}"
        printf "%${right_padding}s" | tr " " "$h"
    else
        printf "%${width}s" | tr " " "$h"
    fi
    
    echo -n "$tr"
    
    # Draw sides
    for (( i=1; i<height-1; i++ )); do
        move_cursor "$((top_row + i))" "$left_col"
        echo -n "$v"
        move_cursor "$((top_row + i))" "$((left_col + width - 1))"
        echo -n "$v"
    done
    
    # Draw bottom border
    move_cursor "$((top_row + height - 1))" "$left_col"
    echo -n "$bl"
    printf "%$(( width - 2 ))s" | tr " " "$h"
    echo -n "$br"
    
    # Reset color
    echo -ne "$NC"
}

# Draw a menu and handle selection
draw_menu() {
    local top_row="$1"
    local left_col="$2"
    local width="$3"
    local title="${4:-Menu}"
    local items=("${@:5}")
    
    local num_items=${#items[@]}
    local height=$((num_items + 4)) # Title + top/bottom borders + padding
    
    # Draw the menu box
    draw_box "$top_row" "$left_col" "$width" "$height" "$title"
    
    # Draw the menu items
    for (( i=0; i<num_items; i++ )); do
        move_cursor "$((top_row + i + 2))" "$((left_col + 2))"
        echo -ne "${THEME_COLORS[${UI_THEME}_fg]}"
        echo -n "${items[$i]}"
    done
    
    # Reset color
    echo -ne "$NC"
}

# Display a selection menu and return the selected index
selection_menu() {
    local top_row="$1"
    local left_col="$2"
    local width="$3"
    local title="${4:-Menu}"
    shift 4
    local items=("$@")
    
    local num_items=${#items[@]}
    local height=$((num_items + 4)) # Title + top/bottom borders + padding
    local selected=0
    local key=""
    
    # Show cursor for this interaction
    show_cursor
    
    while true; do
        # Draw the menu box
        draw_box "$top_row" "$left_col" "$width" "$height" "$title"
        
        # Draw the menu items
        for (( i=0; i<num_items; i++ )); do
            move_cursor "$((top_row + i + 2))" "$((left_col + 2))"
            
            # Highlight selected item
            if [[ $i -eq $selected ]]; then
                echo -ne "${THEME_COLORS[${UI_THEME}_selected]}"
                printf "%-$((width - 4))s" "${items[$i]}"
                echo -ne "$NC"
            else
                echo -ne "${THEME_COLORS[${UI_THEME}_fg]}"
                echo -n "${items[$i]}"
            fi
        done
        
        # Read keyboard input
        read -rsn1 key
        case "$key" in
            "A"|"k") # Up arrow or k
                ((selected--))
                [[ $selected -lt 0 ]] && selected=$((num_items - 1))
                ;;
            "B"|"j") # Down arrow or j
                ((selected++))
                [[ $selected -ge $num_items ]] && selected=0
                ;;
            "") # Enter key
                hide_cursor
                return $selected
                ;;
            "q") # Quit
                hide_cursor
                return 255
                ;;
        esac
    done
}

# Show a message box with OK button
show_message() {
    local message="$1"
    local title="${2:-Message}"
    
    # Calculate dimensions
    local width=$(( ${#message} + 10 ))
    [[ $width -lt 40 ]] && width=40
    [[ $width -gt $TERM_COLS ]] && width=$TERM_COLS
    
    local height=6
    local top_row=$(( (TERM_ROWS - height) / 2 ))
    local left_col=$(( (TERM_COLS - width) / 2 ))
    
    # Draw the message box
    draw_box "$top_row" "$left_col" "$width" "$height" "$title"
    
    # Display message
    move_cursor "$((top_row + 2))" "$((left_col + 5))"
    echo -n "$message"
    
    # Display prompt
    move_cursor "$((top_row + 4))" "$((left_col + width/2 - 4))"
    echo -ne "${THEME_COLORS[${UI_THEME}_selected]} [ OK ] $NC"
    
    # Wait for key press
    wait_for_key
}

# Show a confirmation dialog (returns 0 for yes, 1 for no)
show_confirmation() {
    local message="$1"
    local title="${2:-Confirmation}"
    
    # Calculate dimensions
    local width=$(( ${#message} + 10 ))
    [[ $width -lt 40 ]] && width=40
    [[ $width -gt $TERM_COLS ]] && width=$TERM_COLS
    
    local height=7
    local top_row=$(( (TERM_ROWS - height) / 2 ))
    local left_col=$(( (TERM_COLS - width) / 2 ))
    
    # Draw the message box
    draw_box "$top_row" "$left_col" "$width" "$height" "$title"
    
    # Display message
    move_cursor "$((top_row + 2))" "$((left_col + 5))"
    echo -n "$message"
    
    # Display options
    move_cursor "$((top_row + 4))" "$((left_col + width/3 - 5))"
    echo -ne "${THEME_COLORS[${UI_THEME}_selected]} [ Yes ] $NC"
    
    move_cursor "$((top_row + 4))" "$((left_col + 2*width/3 - 4))"
    echo -n "[ No ]"
    
    # Handle selection
    local selected=0
    local key=""
    
    while true; do
        # Highlight the selected option
        if [[ $selected -eq 0 ]]; then
            move_cursor "$((top_row + 4))" "$((left_col + width/3 - 5))"
            echo -ne "${THEME_COLORS[${UI_THEME}_selected]} [ Yes ] $NC"
            
            move_cursor "$((top_row + 4))" "$((left_col + 2*width/3 - 4))"
            echo -ne "${THEME_COLORS[${UI_THEME}_fg]} [ No ] $NC"
        else
            move_cursor "$((top_row + 4))" "$((left_col + width/3 - 5))"
            echo -ne "${THEME_COLORS[${UI_THEME}_fg]} [ Yes ] $NC"
            
            move_cursor "$((top_row + 4))" "$((left_col + 2*width/3 - 4))"
            echo -ne "${THEME_COLORS[${UI_THEME}_selected]} [ No ] $NC"
        fi
        
        # Read keyboard input
        read -rsn1 key
        case "$key" in
            "D"|"h") # Left arrow or h
                selected=0
                ;;
            "C"|"l") # Right arrow or l
                selected=1
                ;;
            "") # Enter key
                return $selected
                ;;
        esac
    done
}

# Show a progress bar
show_progress() {
    local percent="$1"
    local title="${2:-Progress}"
    local width=60
    local bar_width=50
    
    # Ensure percent is between 0 and 100
    [[ $percent -lt 0 ]] && percent=0
    [[ $percent -gt 100 ]] && percent=100
    
    local filled_width=$(( percent * bar_width / 100 ))
    local empty_width=$(( bar_width - filled_width ))
    
    # Calculate position
    local top_row=$(( TERM_ROWS / 2 - 2 ))
    local left_col=$(( (TERM_COLS - width) / 2 ))
    
    # Draw the progress box
    draw_box "$top_row" "$left_col" "$width" 5 "$title"
    
    # Draw the progress percentage
    move_cursor "$((top_row + 1))" "$((left_col + width - 8))"
    printf "%3d%%" "$percent"
    
    # Draw the progress bar
    move_cursor "$((top_row + 2))" "$((left_col + 5))"
    echo -ne "${THEME_COLORS[${UI_THEME}_border]}["
    echo -ne "${THEME_COLORS[${UI_THEME}_success]}"
    printf "%${filled_width}s" | tr " " "#"
    echo -ne "${THEME_COLORS[${UI_THEME}_fg]}"
    printf "%${empty_width}s" | tr " " "-"
    echo -ne "${THEME_COLORS[${UI_THEME}_border]}]"
}

# Change the current theme
change_theme() {
    local themes=("default" "dark" "light")
    
    clear_screen
    echo "Available Themes:"
    echo ""
    
    for theme in "${themes[@]}"; do
        echo -ne "${THEME_COLORS[${theme}_bg]}${THEME_COLORS[${theme}_fg]}"
        echo -n " $theme "
        echo -ne "$NC"
        echo ""
    done
    
    echo ""
    read -p "Select theme: " selection
    
    for theme in "${themes[@]}"; do
        if [[ "$selection" == "$theme" ]]; then
            apply_theme "$theme"
            # Save to config
            save_config "UI_THEME" "$theme"
            show_message "Theme changed to $theme"
            return
        fi
    done
    
    show_message "Invalid theme. No changes made."
}

# Show a spinner animation
show_spinner() {
    local message="$1"
    local delay=${2:-0.1}
    local spin_chars=('|' '/' '-' '\')
    local i=0
    
    # Save cursor position
    tput sc
    
    while true; do
        echo -ne "\r$message ${spin_chars[$i]}"
        sleep "$delay"
        i=$(( (i + 1) % 4 ))
        
        # Check if we should stop
        [[ -e "/tmp/stop_spinner" ]] && break
    done
    
    # Restore cursor position
    tput rc
}

# Start a spinner in the background
start_spinner() {
    local message="$1"
    
    # Remove any existing stop file
    rm -f "/tmp/stop_spinner"
    
    # Start spinner in background
    show_spinner "$message" &
    SPINNER_PID=$!
}

# Stop a running spinner
stop_spinner() {
    # Signal the spinner to stop
    touch "/tmp/stop_spinner"
    
    # Wait for spinner to terminate
    [[ -n "$SPINNER_PID" ]] && wait "$SPINNER_PID" 2>/dev/null
    
    # Clean up
    rm -f "/tmp/stop_spinner"
    echo -ne "\r\033[K" # Clear the line
}
