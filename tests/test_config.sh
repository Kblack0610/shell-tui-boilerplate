#!/bin/bash
# Test configuration functionality

# Get the directory of this script
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$TEST_DIR")"

# Set up test environment
export CONFIG_DIR="$TEST_DIR/test_config"
export CACHE_DIR="$TEST_DIR/test_cache"
export DATA_DIR="$TEST_DIR/test_data"
CONFIG_FILE="$CONFIG_DIR/config"

# Clean up any previous test data
rm -rf "$CONFIG_DIR" "$CACHE_DIR" "$DATA_DIR"
mkdir -p "$CONFIG_DIR" "$CACHE_DIR" "$DATA_DIR"

# Source the modules for testing
source "$REPO_ROOT/lib/tui-utils.sh"
source "$REPO_ROOT/lib/tui-config.sh"

# Test configuration functions
echo "Testing configuration module functions..."

# Test creating default config
echo "Testing create_default_config..."
create_default_config
if [[ -f "$CONFIG_FILE" ]]; then
    echo "PASS: Default configuration file created"
else
    echo "FAIL: Default configuration file not created"
    exit 1
fi

# Test setting a configuration value
echo "Testing set_config..."
set_config "TEST_VALUE" "hello_world"
if grep -q "TEST_VALUE=\"hello_world\"" "$CONFIG_FILE"; then
    echo "PASS: Configuration value set correctly"
else
    echo "FAIL: Failed to set configuration value"
    exit 1
fi

# Test getting a configuration value
echo "Testing get_config..."
value=$(get_config "TEST_VALUE")
if [[ "$value" == "hello_world" ]]; then
    echo "PASS: Configuration value retrieved correctly"
else
    echo "FAIL: Failed to retrieve configuration value, got '$value'"
    exit 1
fi

# Test getting a default value for non-existent key
echo "Testing get_config with default..."
value=$(get_config "NONEXISTENT_KEY" "default_value")
if [[ "$value" == "default_value" ]]; then
    echo "PASS: Default value returned for non-existent key"
else
    echo "FAIL: Failed to return default value, got '$value'"
    exit 1
fi

# Test resetting configuration
echo "Testing reset_config..."
reset_config
if [[ -f "$CONFIG_FILE" ]] && ! grep -q "TEST_VALUE" "$CONFIG_FILE"; then
    echo "PASS: Configuration reset successfully"
else
    echo "FAIL: Failed to reset configuration"
    exit 1
fi

# Clean up test directory
rm -rf "$CONFIG_DIR" "$CACHE_DIR" "$DATA_DIR"

# All tests passed
echo "Configuration features - All tests PASSED"
exit 0
