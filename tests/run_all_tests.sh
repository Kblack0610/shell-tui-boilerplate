#!/bin/bash
# Shell TUI Boilerplate - Test Runner Script
# Runs all tests for the boilerplate

# Get the directory of this script
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$TEST_DIR")"

# Set up test environment
SUMMARY_LOG="$TEST_DIR/summary.log"
TEST_LOG="$TEST_DIR/test_output.log"
PASSED=0
FAILED=0
SKIPPED=0
TOTAL=0

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Initialize log files
echo "# Shell TUI Boilerplate Test Results - $(date)" > "$SUMMARY_LOG"
echo "# Test run started at $(date)" > "$TEST_LOG"

# Print banner
echo -e "${CYAN}================================================${NC}"
echo -e "${CYAN}    Shell TUI Boilerplate Test Runner           ${NC}"
echo -e "${CYAN}================================================${NC}"
echo ""

# Run a single test and record results
run_test() {
    local test_script="$1"
    local test_name="$(basename "$test_script" .sh)"
    
    echo -e "Running test: ${CYAN}$test_name${NC}..."
    
    # Log the test execution
    echo "## Running $test_name" >> "$TEST_LOG"
    echo "" >> "$TEST_LOG"
    
    # Run the test
    bash "$test_script" >> "$TEST_LOG" 2>&1
    local status=$?
    
    # Record the result
    ((TOTAL++))
    if [ $status -eq 0 ]; then
        echo -e "  ${GREEN}✓ PASS${NC} - $test_name"
        echo "- :white_check_mark: $test_name - PASS" >> "$SUMMARY_LOG"
        ((PASSED++))
    elif [ $status -eq 77 ]; then  # SKIP status
        echo -e "  ${YELLOW}○ SKIP${NC} - $test_name"
        echo "- :large_blue_circle: $test_name - SKIPPED" >> "$SUMMARY_LOG"
        ((SKIPPED++))
    else
        echo -e "  ${RED}✗ FAIL${NC} - $test_name"
        echo "- :x: $test_name - FAIL (exit code: $status)" >> "$SUMMARY_LOG"
        ((FAILED++))
    fi
    
    echo "" >> "$TEST_LOG"
}

# Print test summary
print_summary() {
    echo ""
    echo -e "${CYAN}Test Summary:${NC}"
    echo "  Total: $TOTAL"
    echo -e "  Passed: ${GREEN}$PASSED${NC}"
    
    if [ $SKIPPED -gt 0 ]; then
        echo -e "  Skipped: ${YELLOW}$SKIPPED${NC}"
    else
        echo "  Skipped: 0"
    fi
    
    if [ $FAILED -gt 0 ]; then
        echo -e "  Failed: ${RED}$FAILED${NC}"
    else
        echo "  Failed: 0"
    fi
    
    # Add summary to log file
    echo "" >> "$SUMMARY_LOG"
    echo "## Summary" >> "$SUMMARY_LOG"
    echo "- Total: $TOTAL" >> "$SUMMARY_LOG"
    echo "- Passed: $PASSED" >> "$SUMMARY_LOG"
    echo "- Skipped: $SKIPPED" >> "$SUMMARY_LOG"
    echo "- Failed: $FAILED" >> "$SUMMARY_LOG"
    
    echo ""
    echo "Detailed logs written to $TEST_LOG"
}

# Find and run all test scripts
echo "Discovering tests..."
TEST_SCRIPTS=$(find "$TEST_DIR" -name "test_*.sh" -type f | sort)
TEST_COUNT=$(echo "$TEST_SCRIPTS" | wc -l)

echo "Found $TEST_COUNT test scripts"
echo ""

# Run each test
for test_script in $TEST_SCRIPTS; do
    run_test "$test_script"
done

# Feature coverage report
echo -e "\n${CYAN}Feature Coverage Overview:${NC}"

# Add feature coverage to log file
echo "" >> "$SUMMARY_LOG"
echo "## Feature Coverage" >> "$SUMMARY_LOG"

# Core features
CORE_FEATURES=("UI components" "Input handling" "Configuration" "Logging" "Terminal management")
echo "Core Features:" >> "$SUMMARY_LOG"
for feature in "${CORE_FEATURES[@]}"; do
    if grep -q "$feature" "$TEST_LOG"; then
        echo -e "  ${GREEN}✓${NC} $feature"
        echo "- :white_check_mark: $feature" >> "$SUMMARY_LOG"
    else
        echo -e "  ${YELLOW}○${NC} $feature (not tested)"
        echo "- :warning: $feature (not tested)" >> "$SUMMARY_LOG"
    fi
done

echo "" >> "$SUMMARY_LOG"

# Print final summary
print_summary

# Return status based on test results
if [ $FAILED -gt 0 ]; then
    exit 1
else
    exit 0
fi
