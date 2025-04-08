#!/bin/bash
# Shell TUI Boilerplate - Configuration Module
# Provides configuration management functionality

# Prevent multiple sourcing
[[ -n "$__TUI_CONFIG_LOADED" ]] && return
__TUI_CONFIG_LOADED=true

# Default configuration file path
CONFIG_FILE="${CONFIG_DIR}/config"

# Default configuration values
declare -A DEFAULT_CONFIG
DEFAULT_CONFIG[UI_THEME]="default"
DEFAULT_CONFIG[UI_BORDER_STYLE]="single"
DEFAULT_CONFIG[UI_ANIMATION_ENABLED]="true"
DEFAULT_CONFIG[DEBUG]="false"
DEFAULT_CONFIG[CACHE_TIMEOUT]="3600"
DEFAULT_CONFIG[HISTORY_ENABLED]="true"
DEFAULT_CONFIG[MAX_HISTORY_ENTRIES]="100"

# Initialize configuration
init_config() {
    # Create config directory if it doesn't exist
    mkdir -p "${CONFIG_DIR}"
    
    # Create default config file if it doesn't exist
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_debug "Creating default configuration file: $CONFIG_FILE"
        create_default_config
    fi
    
    log_debug "Configuration initialized"
}

# Create a default configuration file
create_default_config() {
    # Create config directory if it doesn't exist
    mkdir -p "${CONFIG_DIR}"
    
    # Write header
    cat > "$CONFIG_FILE" << EOL
# Shell TUI Boilerplate Configuration
# Created on $(date)
# Edit this file to change your default settings

EOL

    # Write default settings
    for key in "${!DEFAULT_CONFIG[@]}"; do
        echo "$key=\"${DEFAULT_CONFIG[$key]}\"" >> "$CONFIG_FILE"
    done
    
    log_debug "Default configuration created"
}

# Load configuration from file
load_config() {
    # Initialize configuration if needed
    [[ ! -f "$CONFIG_FILE" ]] && init_config
    
    log_debug "Loading configuration from $CONFIG_FILE"
    
    # Source the configuration file to set variables
    source "$CONFIG_FILE"
    
    # Apply loaded settings
    [[ -n "$UI_THEME" ]] && UI_THEME="$UI_THEME"
    [[ -n "$UI_BORDER_STYLE" ]] && UI_BORDER_STYLE="$UI_BORDER_STYLE"
    [[ -n "$UI_ANIMATION_ENABLED" ]] && UI_ANIMATION_ENABLED="$UI_ANIMATION_ENABLED"
    [[ -n "$DEBUG" ]] && DEBUG="$DEBUG"
    
    log_debug "Configuration loaded"
}

# Get a configuration value
get_config() {
    local key="$1"
    local default_val="${2:-}"
    
    # Load config file if it exists
    if [[ -f "$CONFIG_FILE" ]]; then
        # Read from config file
        local value=$(grep -E "^$key=" "$CONFIG_FILE" | cut -d= -f2 | tr -d '"')
        
        # Return value if found, otherwise return default
        if [[ -n "$value" ]]; then
            echo "$value"
        else
            echo "$default_val"
        fi
    else
        # Return default from DEFAULT_CONFIG or passed default
        if [[ -n "${DEFAULT_CONFIG[$key]}" ]]; then
            echo "${DEFAULT_CONFIG[$key]}"
        else
            echo "$default_val"
        fi
    fi
}

# Set a configuration value
set_config() {
    local key="$1"
    local value="$2"
    
    # Load config file if it exists
    if [[ -f "$CONFIG_FILE" ]]; then
        # Check if key already exists in file
        if grep -qE "^$key=" "$CONFIG_FILE"; then
            # Update existing key
            sed -i "s|^$key=.*|$key=\"$value\"|" "$CONFIG_FILE"
        else
            # Add new key
            echo "$key=\"$value\"" >> "$CONFIG_FILE"
        fi
    else
        # Create new config file with this key/value
        mkdir -p "$(dirname "$CONFIG_FILE")"
        echo "$key=\"$value\"" > "$CONFIG_FILE"
    fi
    
    log_debug "Configuration updated: $key = $value"
}

# Save configuration
save_config() {
    local key="$1"
    local value="$2"
    
    # Update configuration in file
    set_config "$key" "$value"
    
    # Update current session
    case "$key" in
        UI_THEME)
            UI_THEME="$value"
            ;;
        UI_BORDER_STYLE)
            UI_BORDER_STYLE="$value"
            ;;
        UI_ANIMATION_ENABLED)
            UI_ANIMATION_ENABLED="$value"
            ;;
        DEBUG)
            DEBUG="$value"
            ;;
    esac
    
    log_debug "Configuration saved and applied: $key = $value"
}

# Reset configuration to defaults
reset_config() {
    log_debug "Resetting configuration to defaults"
    
    # Backup existing config
    [[ -f "$CONFIG_FILE" ]] && cp "$CONFIG_FILE" "${CONFIG_FILE}.bak.$(date +%Y%m%d%H%M%S)"
    
    # Create new default config
    create_default_config
    
    # Reload configuration
    load_config
    
    log_debug "Configuration reset complete"
}

# Edit configuration file
edit_config() {
    # Create config if it doesn't exist
    [[ ! -f "$CONFIG_FILE" ]] && create_default_config
    
    # Determine editor to use
    local editor="${EDITOR:-nano}"
    
    # Check if editor is available
    if ! command -v "$editor" &> /dev/null; then
        # Fallback editors
        for ed in nano vim vi; do
            if command -v "$ed" &> /dev/null; then
                editor="$ed"
                break
            fi
        done
    fi
    
    # Open the file in the editor
    "$editor" "$CONFIG_FILE"
    
    # Reload configuration
    load_config
    
    log_debug "Configuration file edited and reloaded"
}

# Export configuration as JSON
export_config_json() {
    local output_file="$1"
    
    # Default to stdout if no file specified
    [[ -z "$output_file" ]] && output_file="/dev/stdout"
    
    # Start JSON
    echo "{" > "$output_file"
    
    # Read config file and convert to JSON format
    if [[ -f "$CONFIG_FILE" ]]; then
        local first=true
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ "$key" =~ ^# || -z "$key" ]] && continue
            
            # Remove quotes from value
            value=$(echo "$value" | tr -d '"')
            
            # Add comma for all but first entry
            [[ "$first" == "true" ]] && first=false || echo "," >> "$output_file"
            
            # Write key-value pair
            echo "  \"$key\": \"$value\"" >> "$output_file"
        done < "$CONFIG_FILE"
    fi
    
    # End JSON
    echo "}" >> "$output_file"
    
    log_debug "Configuration exported as JSON to $output_file"
}

# Import configuration from JSON
import_config_json() {
    local input_file="$1"
    
    # Check if file exists
    if [[ ! -f "$input_file" ]]; then
        log_error "Config JSON file not found: $input_file"
        return 1
    fi
    
    # Process the JSON file (basic parsing, assumes simple format)
    grep -E '^\s*"[^"]+"\s*:\s*"[^"]+"' "$input_file" | while read -r line; do
        # Extract key and value
        local key=$(echo "$line" | sed -E 's/^\s*"([^"]+)"\s*:.*/\1/')
        local value=$(echo "$line" | sed -E 's/^[^:]+:\s*"([^"]+)"[,]?$/\1/')
        
        # Set config value
        set_config "$key" "$value"
    done
    
    # Reload configuration
    load_config
    
    log_debug "Configuration imported from JSON: $input_file"
}

# Add a configuration section header (for organization)
add_config_section() {
    local section_name="$1"
    
    # Append section header to config file
    echo "" >> "$CONFIG_FILE"
    echo "# --- $section_name ---" >> "$CONFIG_FILE"
    
    log_debug "Configuration section added: $section_name"
}

# Clear cache files
clear_cache() {
    log_debug "Clearing cache directory: $CACHE_DIR"
    
    # Remove all files in cache directory
    rm -rf "${CACHE_DIR:?}/"*
    
    # Recreate cache directory
    mkdir -p "$CACHE_DIR"
    
    log_debug "Cache cleared"
}
