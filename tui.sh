#!/bin/bash
# Shell TUI Boilerplate - Main Script
# A modular framework for creating shell-based text user interfaces
# Version 1.0.0

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set up configuration paths
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/shell-tui"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/shell-tui"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/shell-tui"

# Ensure directories exist
mkdir -p "$CONFIG_DIR" "$CACHE_DIR" "$DATA_DIR"

# Debug mode flag
DEBUG=false

# Source library modules
source "$SCRIPT_DIR/lib/tui-core.sh"
source "$SCRIPT_DIR/lib/tui-ui.sh"
source "$SCRIPT_DIR/lib/tui-input.sh"
source "$SCRIPT_DIR/lib/tui-config.sh"
source "$SCRIPT_DIR/lib/tui-utils.sh"

# Display the application banner
show_banner() {
    clear
    echo "╔═══════════════════════════════════════╗"
    echo "║            Shell TUI App              ║"
    echo "║          Version 1.0.0                ║"
    echo "╚═══════════════════════════════════════╝"
    echo ""
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_help
                exit 0
                ;;
            --version|-v)
                echo "Shell TUI App v1.0.0"
                exit 0
                ;;
            --debug|-d)
                DEBUG=true
                log_debug "Debug mode enabled"
                ;;
            *)
                log_warning "Unknown option: $1"
                ;;
        esac
        shift
    done
}

# Initialize the application
initialize() {
    # Trap ctrl-c to cleanly exit
    trap cleanup SIGINT SIGTERM

    # Load configuration
    load_config

    # Initialize UI components
    init_ui
    
    log_debug "Initialization complete"
}

# Main menu and application loop
main_menu() {
    local running=true
    local selection=""

    while $running; do
        show_banner
        echo "Main Menu:"
        echo "1. Option One"
        echo "2. Option Two"
        echo "3. Option Three"
        echo "4. Settings"
        echo "q. Quit"
        echo ""
        
        read -p "Select an option: " selection
        
        case "$selection" in
            1)
                display_screen "Option One"
                ;;
            2)
                display_screen "Option Two"
                ;;
            3)
                display_screen "Option Three"
                ;;
            4)
                settings_menu
                ;;
            q|Q)
                running=false
                ;;
            *)
                show_message "Invalid selection. Please try again."
                ;;
        esac
    done
}

# Display a generic screen
display_screen() {
    local title="$1"
    clear
    echo "╔═══════════════════════════════════════╗"
    echo "║  $title"
    echo "╚═══════════════════════════════════════╝"
    echo ""
    echo "This is a placeholder for the $title screen."
    echo ""
    read -p "Press Enter to return to the main menu..." dummy
}

# Settings menu
settings_menu() {
    local running=true
    local selection=""

    while $running; do
        clear
        echo "╔═══════════════════════════════════════╗"
        echo "║             Settings                  ║"
        echo "╚═══════════════════════════════════════╝"
        echo ""
        echo "1. Change Theme"
        echo "2. Edit Configuration"
        echo "3. Clear Cache"
        echo "b. Back to Main Menu"
        echo ""
        
        read -p "Select an option: " selection
        
        case "$selection" in
            1)
                change_theme
                ;;
            2)
                edit_config
                ;;
            3)
                clear_cache
                show_message "Cache cleared successfully."
                ;;
            b|B)
                running=false
                ;;
            *)
                show_message "Invalid selection. Please try again."
                ;;
        esac
    done
}

# Clean up resources before exiting
cleanup() {
    echo "Cleaning up and exiting..."
    # Add cleanup tasks here
    exit 0
}

# Main function - entry point
main() {
    # Parse command line arguments
    parse_args "$@"
    
    # Initialize application
    initialize
    
    # Show main menu
    main_menu
    
    # Clean exit
    cleanup
}

# If script is being sourced, export functions but don't run
# If script is being executed directly, run the main function
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Script is being sourced
    log_debug "Script is being sourced"
else
    # Script is being executed directly
    main "$@"
fi
