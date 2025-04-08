#!/bin/bash
# Shell TUI Boilerplate - Utilities Module
# Provides utility functions for the TUI framework

# Prevent multiple sourcing
[[ -n "$__TUI_UTILS_LOADED" ]] && return
__TUI_UTILS_LOADED=true

# Logging levels
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_WARNING=2
LOG_LEVEL_ERROR=3

# Current log level
LOG_LEVEL=$LOG_LEVEL_INFO

# Log file path
LOG_FILE="${CACHE_DIR}/tui-app.log"

# Initialize logging
init_logging() {
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Initialize log file
    cat > "$LOG_FILE" << EOL
# Shell TUI Application Log
# Started on $(date)
# --------------------------------------------------

EOL
    
    # Set log level based on debug flag
    if [[ "$DEBUG" == "true" ]]; then
        LOG_LEVEL=$LOG_LEVEL_DEBUG
    fi
    
    log_debug "Logging initialized with level: $LOG_LEVEL"
}

# Log a message with timestamp
_log() {
    local level="$1"
    local message="$2"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    # Write to log file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Display to stderr if appropriate for level
    if [[ "$level" == "ERROR" || "$level" == "WARNING" ]]; then
        echo -e "${RED}[$level] $message${NC}" >&2
    fi
}

# Log a debug message
log_debug() {
    [[ $LOG_LEVEL -le $LOG_LEVEL_DEBUG ]] && _log "DEBUG" "$1"
}

# Log an info message
log_info() {
    [[ $LOG_LEVEL -le $LOG_LEVEL_INFO ]] && _log "INFO" "$1"
}

# Log a warning message
log_warning() {
    [[ $LOG_LEVEL -le $LOG_LEVEL_WARNING ]] && _log "WARNING" "$1"
}

# Log an error message
log_error() {
    [[ $LOG_LEVEL -le $LOG_LEVEL_ERROR ]] && _log "ERROR" "$1"
}

# Set the log level
set_log_level() {
    local level="$1"
    
    case "$level" in
        debug|DEBUG)
            LOG_LEVEL=$LOG_LEVEL_DEBUG
            ;;
        info|INFO)
            LOG_LEVEL=$LOG_LEVEL_INFO
            ;;
        warning|WARNING)
            LOG_LEVEL=$LOG_LEVEL_WARNING
            ;;
        error|ERROR)
            LOG_LEVEL=$LOG_LEVEL_ERROR
            ;;
        *)
            log_warning "Unknown log level: $level. Using INFO."
            LOG_LEVEL=$LOG_LEVEL_INFO
            ;;
    esac
    
    log_info "Log level set to: $level"
}

# Generate a unique ID
generate_id() {
    local length="${1:-8}"
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w "$length" | head -n 1
}

# Get current timestamp
get_timestamp() {
    date +%s
}

# Format timestamp as readable date/time
format_timestamp() {
    local timestamp="$1"
    local format="${2:-%Y-%m-%d %H:%M:%S}"
    
    date -d "@$timestamp" +"$format" 2>/dev/null || date -r "$timestamp" +"$format" 2>/dev/null || echo "Invalid timestamp"
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if a file exists and is readable
file_readable() {
    [[ -f "$1" && -r "$1" ]]
}

# Check if a directory exists and is writable
dir_writable() {
    [[ -d "$1" && -w "$1" ]]
}

# Create a directory if it doesn't exist
ensure_dir() {
    [[ -d "$1" ]] || mkdir -p "$1"
}

# Get the base name of a file path
basename() {
    local path="$1"
    echo "${path##*/}"
}

# Get the directory name of a file path
dirname() {
    local path="$1"
    local dir="${path%/*}"
    [[ "$dir" == "$path" ]] && echo "." || echo "$dir"
}

# Check if a string contains a substring
string_contains() {
    local string="$1"
    local substring="$2"
    [[ "$string" == *"$substring"* ]]
}

# Check if a string starts with a prefix
string_starts_with() {
    local string="$1"
    local prefix="$2"
    [[ "$string" == "$prefix"* ]]
}

# Check if a string ends with a suffix
string_ends_with() {
    local string="$1"
    local suffix="$2"
    [[ "$string" == *"$suffix" ]]
}

# Trim whitespace from the beginning and end of a string
string_trim() {
    local string="$1"
    string="${string#"${string%%[![:space:]]*}"}"   # Remove leading whitespace
    string="${string%"${string##*[![:space:]]}"}"   # Remove trailing whitespace
    echo "$string"
}

# Convert a string to lowercase
string_lowercase() {
    local string="$1"
    echo "${string,,}"
}

# Convert a string to uppercase
string_uppercase() {
    local string="$1"
    echo "${string^^}"
}

# Replace all occurrences of a substring
string_replace() {
    local string="$1"
    local search="$2"
    local replace="$3"
    echo "${string//$search/$replace}"
}

# Calculate time difference in seconds
time_diff_seconds() {
    local start_time="$1"
    local end_time="$2"
    echo "$((end_time - start_time))"
}

# Format a time duration in seconds to a human-readable format
format_duration() {
    local seconds="$1"
    
    local days=$((seconds / 86400))
    local hours=$(( (seconds % 86400) / 3600 ))
    local minutes=$(( (seconds % 3600) / 60 ))
    local secs=$((seconds % 60))
    
    local result=""
    [[ $days -gt 0 ]] && result="${days}d "
    [[ $hours -gt 0 ]] && result="${result}${hours}h "
    [[ $minutes -gt 0 ]] && result="${result}${minutes}m "
    result="${result}${secs}s"
    
    echo "$result"
}

# Calculate file size in human-readable format
human_filesize() {
    local file="$1"
    
    if [[ -f "$file" ]]; then
        local size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)
        
        if [[ $size -lt 1024 ]]; then
            echo "${size} B"
        elif [[ $size -lt 1048576 ]]; then
            echo "$(( (size * 10 + 512) / 1024 / 10 )) KB"
        elif [[ $size -lt 1073741824 ]]; then
            echo "$(( (size * 10 + 524288) / 1048576 / 10 )) MB"
        else
            echo "$(( (size * 10 + 536870912) / 1073741824 / 10 )) GB"
        fi
    else
        echo "0 B"
    fi
}

# Check if running in a terminal
is_terminal() {
    [[ -t 1 ]]
}

# Get terminal width
get_term_width() {
    tput cols 2>/dev/null || echo 80
}

# Get terminal height
get_term_height() {
    tput lines 2>/dev/null || echo 24
}

# Check terminal capabilities
check_term_capabilities() {
    # Check for color support
    if tput colors &>/dev/null; then
        local colors=$(tput colors)
        [[ $colors -ge 8 ]] && HAS_COLORS=true || HAS_COLORS=false
    else
        HAS_COLORS=false
    fi
    
    # Check for cursor positioning
    if tput cup 0 0 &>/dev/null; then
        HAS_CURSOR_POSITIONING=true
    else
        HAS_CURSOR_POSITIONING=false
    fi
    
    log_debug "Terminal capabilities: colors=$HAS_COLORS, cursor_positioning=$HAS_CURSOR_POSITIONING"
}

# Run a command with timeout
run_command_timeout() {
    local timeout="$1"
    shift
    local cmd="$@"
    
    # Use timeout command if available
    if command_exists timeout; then
        timeout "$timeout" $cmd
        return $?
    else
        # Fall back to manual timeout with background process
        local pid
        local result=0
        
        # Run the command in background
        $cmd &
        pid=$!
        
        # Wait for command to finish or timeout
        (
            sleep "$timeout"
            kill -TERM $pid 2>/dev/null || true
            sleep 1
            kill -KILL $pid 2>/dev/null || true
        ) &
        local watchdog=$!
        
        # Wait for command to finish
        wait $pid 2>/dev/null
        result=$?
        
        # Kill the watchdog
        kill -TERM $watchdog 2>/dev/null || true
        
        return $result
    fi
}

# Create a temporary file
create_temp_file() {
    local prefix="${1:-tui-app}"
    local suffix="${2:-.tmp}"
    
    local tmpfile="$(mktemp "/tmp/${prefix}-XXXXXX${suffix}" 2>/dev/null)"
    if [[ $? -ne 0 || ! -f "$tmpfile" ]]; then
        # Fallback if mktemp fails
        tmpfile="/tmp/${prefix}-$(generate_id)${suffix}"
        touch "$tmpfile"
    fi
    
    echo "$tmpfile"
}

# Clean up temporary files
cleanup_temp_files() {
    local pattern="${1:-/tmp/tui-app-*}"
    
    # Find and remove temporary files
    find /tmp -name "$(basename "$pattern")" -type f -mtime +1 -delete 2>/dev/null
    
    log_debug "Temporary files cleaned up"
}

# Show help message
show_help() {
    echo "Shell TUI Application"
    echo "Version: $TUI_VERSION"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help         Show this help message"
    echo "  -v, --version      Show version information"
    echo "  -d, --debug        Enable debug mode"
    echo ""
    echo "For more information, see the README file."
}
