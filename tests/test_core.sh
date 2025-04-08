#!/bin/bash
# Test core functionality

# Get the directory of this script
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$TEST_DIR")"

# Source the modules for testing
source "$REPO_ROOT/lib/tui-core.sh"

# Test suite for core functionality
echo "Testing core module functions..."

# Test center_text
output=$(center_text "Hello World" 20)
expected="    Hello World    "
if [[ "$output" == "$expected" ]]; then
    echo "PASS: center_text works correctly"
else
    echo "FAIL: center_text expected '$expected', got '$output'"
    exit 1
fi

# Test horizontal_line
output=$(horizontal_line "-" 5)
expected="-----"
if [[ "$output" == "$expected" ]]; then
    echo "PASS: horizontal_line works correctly"
else
    echo "FAIL: horizontal_line expected '$expected', got '$output'"
    exit 1
fi

# All tests passed
echo "Core features: Terminal management - All tests PASSED"
exit 0
