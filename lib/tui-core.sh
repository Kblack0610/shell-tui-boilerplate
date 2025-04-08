#!/bin/bash
# Shell TUI Boilerplate - Core Module
# Provides core functionality for the TUI framework

# Prevent multiple sourcing
[[ -n "$__TUI_CORE_LOADED" ]] && return
__TUI_CORE_LOADED=true

# Terminal dimensions
TERM_COLS=$(tput cols 2>/dev/null || echo 80)
TERM_ROWS=$(tput lines 2>/dev/null || echo 24)

# Color definitions
NC='\033[0m'              # No Color
BLACK='\033[0;30m'        # Black
RED='\033[0;31m'          # Red
GREEN='\033[0;32m'        # Green
YELLOW='\033[0;33m'       # Yellow
BLUE='\033[0;34m'         # Blue
PURPLE='\033[0;35m'       # Purple
CYAN='\033[0;36m'         # Cyan
WHITE='\033[0;37m'        # White

# Bold colors
BOLD_BLACK='\033[1;30m'   # Bold Black
BOLD_RED='\033[1;31m'     # Bold Red
BOLD_GREEN='\033[1;32m'   # Bold Green
BOLD_YELLOW='\033[1;33m'  # Bold Yellow
BOLD_BLUE='\033[1;34m'    # Bold Blue
BOLD_PURPLE='\033[1;35m'  # Bold Purple
BOLD_CYAN='\033[1;36m'    # Bold Cyan
BOLD_WHITE='\033[1;37m'   # Bold White

# Background colors
BG_BLACK='\033[40m'       # Black Background
BG_RED='\033[41m'         # Red Background
BG_GREEN='\033[42m'       # Green Background
BG_YELLOW='\033[43m'      # Yellow Background
BG_BLUE='\033[44m'        # Blue Background
BG_PURPLE='\033[45m'      # Purple Background
BG_CYAN='\033[46m'        # Cyan Background
BG_WHITE='\033[47m'       # White Background

# Text styles
BOLD='\033[1m'            # Bold
UNDERLINE='\033[4m'       # Underline
REVERSE='\033[7m'         # Reverse (invert foreground and background)
BLINK='\033[5m'           # Blink

# Global variables
TUI_APP_NAME="Shell TUI App"
TUI_VERSION="1.0.0"

# Refresh rate for animation or dynamic content (in seconds)
TUI_REFRESH_RATE=0.5

# Store the state of terminal when we start
_save_terminal_state() {
    tput smcup 2>/dev/null    # Save terminal content and clear screen
    stty -echo 2>/dev/null    # Disable terminal echo
}

# Restore terminal state when exiting
_restore_terminal_state() {
    tput rmcup 2>/dev/null    # Restore terminal content
    stty echo 2>/dev/null     # Re-enable terminal echo
    tput cnorm 2>/dev/null    # Restore cursor
    tput sgr0 2>/dev/null     # Reset all attributes
}

# Initialize core functionality
init_core() {
    # Update terminal dimensions
    TERM_COLS=$(tput cols 2>/dev/null || echo 80)
    TERM_ROWS=$(tput lines 2>/dev/null || echo 24)
    
    # Set up terminal
    _save_terminal_state
    
    # Trap function to ensure terminal is restored on exit
    trap _restore_terminal_state EXIT
    
    log_debug "Core initialized - Terminal: ${TERM_COLS}x${TERM_ROWS}"
}

# Display a centered text string
center_text() {
    local text="$1"
    local width="${2:-$TERM_COLS}"
    local pad=$(( (width - ${#text}) / 2 ))
    printf "%${pad}s%s%${pad}s\n" "" "$text" ""
}

# Create a horizontal line
horizontal_line() {
    local char="${1:-─}"
    local width="${2:-$TERM_COLS}"
    printf "%${width}s\n" | tr " " "$char"
}

# Clear the screen
clear_screen() {
    tput clear
}

# Move cursor to position
move_cursor() {
    local row="$1"
    local col="$2"
    tput cup "$row" "$col"
}

# Hide cursor
hide_cursor() {
    tput civis
}

# Show cursor
show_cursor() {
    tput cnorm
}

# Set text color and style
set_text_color() {
    local color="$1"
    echo -ne "$color"
}

# Reset text formatting
reset_text_format() {
    echo -ne "$NC"
}

# Wait for key press
wait_for_key() {
    read -n1 -s
}

# Wait for specific key
wait_for_specific_key() {
    local key="$1"
    local pressed=""
    while [[ "$pressed" != "$key" ]]; do
        read -n1 -s pressed
    done
}

# Non-blocking check if a key was pressed
check_key_press() {
    local key
    read -t 0.1 -n 1 key
    echo "$key"
}

# Exit the application cleanly
exit_application() {
    _restore_terminal_state
    exit 0
}

# Sleep for a fraction of a second
sleep_ms() {
    local ms="$1"
    sleep "$(echo "scale=3; $ms/1000" | bc)"
}
