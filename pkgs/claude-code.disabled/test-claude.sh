#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Testing Claude Code Installation${NC}"
echo ""

# Function to check command
check_command() {
    local cmd="$1"
    local expected="$2"
    local description="$3"
    
    echo -n "Testing $description... "
    
    if output=$($cmd 2>&1); then
        if [[ -n "$expected" ]] && [[ "$output" == *"$expected"* ]]; then
            echo -e "${GREEN}✓ PASS${NC}"
            echo "  Output: $output"
            return 0
        elif [[ -z "$expected" ]]; then
            echo -e "${GREEN}✓ PASS${NC}"
            echo "  Output: $output"
            return 0
        else
            echo -e "${YELLOW}⚠ WARNING${NC}"
            echo "  Expected to contain: $expected"
            echo "  Got: $output"
            return 1
        fi
    else
        echo -e "${RED}✗ FAIL${NC}"
        echo "  Error: $output"
        return 1
    fi
}

# Check if claude is in PATH
echo -n "Checking if 'claude' is in PATH... "
if command -v claude &> /dev/null; then
    echo -e "${GREEN}✓ Found${NC}"
    CLAUDE_PATH=$(which claude)
    echo "  Path: $CLAUDE_PATH"
else
    echo -e "${RED}✗ Not found${NC}"
    echo ""
    echo "Claude command not found. Make sure to run:"
    echo "  darwin-rebuild switch"
    echo "Or test the local build:"
    echo "  nix-build -E 'with import <nixpkgs> {}; callPackage ./default.nix {}'"
    echo "  ./result/bin/claude --version"
    exit 1
fi

echo ""

# Run tests
TESTS_PASSED=0
TESTS_FAILED=0

# Test 1: Version command
if check_command "claude --version" "" "claude --version"; then
    ((TESTS_PASSED++))
else
    ((TESTS_FAILED++))
fi

echo ""

# Test 2: Help command
if check_command "claude --help" "Usage:" "claude --help"; then
    ((TESTS_PASSED++))
else
    ((TESTS_FAILED++))
fi

echo ""

# Test 3: Check Node.js availability
echo -n "Checking Node.js integration... "
if claude --version 2>&1 | grep -q "node"; then
    echo -e "${YELLOW}⚠ Node.js error detected${NC}"
    ((TESTS_FAILED++))
elif [[ -f "$CLAUDE_PATH" ]] && grep -q "node" "$CLAUDE_PATH"; then
    echo -e "${GREEN}✓ PASS${NC}"
    echo "  Claude is properly wrapped with Node.js"
    ((TESTS_PASSED++))
else
    echo -e "${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Summary:"
echo "  Passed: $TESTS_PASSED"
echo "  Failed: $TESTS_FAILED"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "  Result: ${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "  Result: ${RED}Some tests failed${NC}"
    exit 1
fi
