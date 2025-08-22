#!/usr/bin/env bash

# test-link-dotfiles.sh - Test script for link-dotfiles.sh with edge cases

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINK_SCRIPT="$SCRIPT_DIR/link-dotfiles.sh"
TEST_DIR="$(mktemp -d -t dotfiles-test.XXXXXX)"
TEST_HOME="$TEST_DIR/home"
TEST_CONFIG="$TEST_DIR/config"

# Cleanup on exit
cleanup() {
    if [[ -d "$TEST_DIR" ]]; then
        echo -e "${BLUE}[INFO]${NC} Cleaning up test directory: $TEST_DIR"
        rm -rf "$TEST_DIR"
    fi
}
trap cleanup EXIT

# Test result tracking
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test functions
test_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    echo -e "  ${RED}Reason:${NC} $2"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

run_test() {
    local test_name="$1"
    echo -e "\n${BLUE}[TEST]${NC} $test_name"
    TESTS_RUN=$((TESTS_RUN + 1))
}

# Setup test environment
setup_test_env() {
    echo -e "${BLUE}[INFO]${NC} Setting up test environment in $TEST_DIR"
    
    # Create test directories
    mkdir -p "$TEST_HOME"
    mkdir -p "$TEST_CONFIG"
    
    # Create a fake flake.nix to satisfy the script's check
    echo "# Test flake.nix" > "$TEST_CONFIG/flake.nix"
    
    # Export test environment
    export HOME="$TEST_HOME"
    export CONFIG_ROOT="$TEST_CONFIG"
}

# Test 1: Empty directories
test_empty_directories() {
    run_test "Empty directories handling"
    
    # Create empty dotfiles directory
    mkdir -p "$TEST_CONFIG/dotfiles"
    
    # Run the script
    if HOME="$TEST_HOME" CONFIG_ROOT="$TEST_CONFIG" "$LINK_SCRIPT" --dry-run >/dev/null 2>&1; then
        test_pass "Handles empty directories without errors"
    else
        test_fail "Failed on empty directories" "Script returned non-zero exit code"
    fi
}

# Test 2: Special characters in filenames
test_special_characters() {
    run_test "Special characters in filenames"
    
    # Create files with special characters
    local special_dir="$TEST_CONFIG/dotfiles"
    mkdir -p "$special_dir"
    
    # Test various special characters
    touch "$special_dir/.file with spaces"
    touch "$special_dir/.file'with'quotes"
    touch "$special_dir/.file\"with\"doublequotes"
    touch "$special_dir/.file\$with\$dollar"
    touch "$special_dir/.file&with&ampersand"
    touch "$special_dir/.file(with)parens"
    touch "$special_dir/.file[with]brackets"
    echo "test" > "$special_dir/.file
with
newline"
    
    # Run the script
    if HOME="$TEST_HOME" CONFIG_ROOT="$TEST_CONFIG" "$LINK_SCRIPT" --dry-run 2>&1 | grep -q "ERROR"; then
        test_fail "Failed on special characters" "Script produced errors with special filenames"
    else
        test_pass "Handles special characters in filenames"
    fi
}

# Test 3: Permission errors
test_permission_errors() {
    run_test "Permission error handling"
    
    # Create a directory with restricted permissions
    local restricted_dir="$TEST_CONFIG/dotfiles"
    mkdir -p "$restricted_dir"
    touch "$restricted_dir/.testfile"
    
    # Make home directory read-only temporarily
    chmod 555 "$TEST_HOME"
    
    # Run the script and check if it handles permission errors gracefully
    local output=$(HOME="$TEST_HOME" CONFIG_ROOT="$TEST_CONFIG" "$LINK_SCRIPT" --dry-run 2>&1 || true)
    if echo "$output" | grep -q "not writable"; then
        test_pass "Detects and reports permission errors"
    else
        test_fail "Did not detect permission errors" "Expected permission error message"
    fi
    
    # Restore permissions
    chmod 755 "$TEST_HOME"
}

# Test 4: Idempotency
test_idempotency() {
    run_test "Idempotency (safe to run multiple times)"
    
    # Create test files
    local dotfiles_dir="$TEST_CONFIG/dotfiles"
    mkdir -p "$dotfiles_dir"
    echo "test content" > "$dotfiles_dir/.testrc"
    echo "another test" > "$dotfiles_dir/.bashrc"
    
    # First run - should create links
    HOME="$TEST_HOME" CONFIG_ROOT="$TEST_CONFIG" "$LINK_SCRIPT" >/dev/null 2>&1
    
    # Check if links were created
    if [[ ! -L "$TEST_HOME/.testrc" ]] || [[ ! -L "$TEST_HOME/.bashrc" ]]; then
        test_fail "Failed to create initial symlinks" "Expected symlinks not found"
        return
    fi
    
    # Second run - should be idempotent
    local output=$(HOME="$TEST_HOME" CONFIG_ROOT="$TEST_CONFIG" "$LINK_SCRIPT" --verbose 2>&1)
    if echo "$output" | grep -q "Already linked correctly"; then
        test_pass "Idempotent - recognizes existing correct links"
    else
        test_fail "Not idempotent" "Expected to recognize existing links"
    fi
}

# Test 5: Existing file conflicts
test_existing_files() {
    run_test "Existing file conflict handling"
    
    # Create a regular file in home that conflicts
    echo "existing content" > "$TEST_HOME/.existingrc"
    
    # Create a dotfile that would conflict
    local dotfiles_dir="$TEST_CONFIG/dotfiles"
    mkdir -p "$dotfiles_dir"
    echo "new content" > "$dotfiles_dir/.existingrc"
    
    # Run without force - should warn
    local output=$(HOME="$TEST_HOME" CONFIG_ROOT="$TEST_CONFIG" "$LINK_SCRIPT" 2>&1)
    if echo "$output" | grep -q "File already exists"; then
        test_pass "Warns about existing files without --force"
    else
        test_fail "Did not warn about existing files" "Expected warning message"
    fi
    
    # Run with force - should backup
    HOME="$TEST_HOME" CONFIG_ROOT="$TEST_CONFIG" "$LINK_SCRIPT" --force >/dev/null 2>&1
    if [[ -f "$TEST_HOME/.existingrc.backup" ]]; then
        test_pass "Creates backups with --force option"
    else
        test_fail "Did not create backup" "Expected .backup file"
    fi
}

# Test 6: Nested directory structures
test_nested_directories() {
    run_test "Nested directory structures"
    
    # Create nested config structure
    local config_dir="$TEST_CONFIG/config"
    mkdir -p "$config_dir/nvim/lua/plugins"
    mkdir -p "$config_dir/tmux/themes"
    
    echo "vim config" > "$config_dir/nvim/init.lua"
    echo "plugin" > "$config_dir/nvim/lua/plugins/test.lua"
    echo "tmux conf" > "$config_dir/tmux/tmux.conf"
    
    # Run the script
    HOME="$TEST_HOME" CONFIG_ROOT="$TEST_CONFIG" "$LINK_SCRIPT" >/dev/null 2>&1
    
    # Check if nested structure is preserved
    if [[ -L "$TEST_HOME/.config/nvim" ]] && [[ -L "$TEST_HOME/.config/tmux" ]]; then
        test_pass "Handles nested directory structures correctly"
    else
        test_fail "Failed to handle nested directories" "Expected .config subdirectories"
    fi
}

# Test 7: Dry run mode
test_dry_run() {
    run_test "Dry run mode"
    
    # Create test files
    local dotfiles_dir="$TEST_CONFIG/dotfiles"
    mkdir -p "$dotfiles_dir"
    echo "test" > "$dotfiles_dir/.dryruntest"
    
    # Run in dry-run mode
    HOME="$TEST_HOME" CONFIG_ROOT="$TEST_CONFIG" "$LINK_SCRIPT" --dry-run >/dev/null 2>&1
    
    # Check that no actual links were created
    if [[ ! -e "$TEST_HOME/.dryruntest" ]]; then
        test_pass "Dry run mode doesn't create actual links"
    else
        test_fail "Dry run created actual files" "No files should be created in dry run"
    fi
}

# Test 8: Symlink to symlink
test_symlink_chains() {
    run_test "Symlink chain handling"
    
    # Create a chain of symlinks
    local dotfiles_dir="$TEST_CONFIG/dotfiles"
    mkdir -p "$dotfiles_dir"
    echo "original" > "$dotfiles_dir/.original"
    ln -s ".original" "$dotfiles_dir/.linktooriginal"
    
    # Run the script
    HOME="$TEST_HOME" CONFIG_ROOT="$TEST_CONFIG" "$LINK_SCRIPT" >/dev/null 2>&1
    
    # Check if both are linked
    if [[ -L "$TEST_HOME/.original" ]] && [[ -L "$TEST_HOME/.linktooriginal" ]]; then
        test_pass "Handles symlink chains correctly"
    else
        test_fail "Failed to handle symlink chains" "Expected both symlinks to be created"
    fi
}

# Test 9: Hidden directories
test_hidden_directories() {
    run_test "Hidden directories (.git exclusion)"
    
    # Create a .git directory that should be excluded
    local dotfiles_dir="$TEST_CONFIG/dotfiles"
    mkdir -p "$dotfiles_dir/.git"
    echo "git data" > "$dotfiles_dir/.git/config"
    echo "normal file" > "$dotfiles_dir/.normalfile"
    
    # Run the script
    HOME="$TEST_HOME" CONFIG_ROOT="$TEST_CONFIG" "$LINK_SCRIPT" >/dev/null 2>&1
    
    # Check that .git was not linked but other files were
    if [[ ! -e "$TEST_HOME/.git" ]] && [[ -L "$TEST_HOME/.normalfile" ]]; then
        test_pass "Correctly excludes .git directories"
    else
        test_fail "Failed to exclude .git" "Git directories should not be linked"
    fi
}

# Test 10: Unicode filenames
test_unicode_filenames() {
    run_test "Unicode characters in filenames"
    
    # Create files with unicode characters
    local dotfiles_dir="$TEST_CONFIG/dotfiles"
    mkdir -p "$dotfiles_dir"
    touch "$dotfiles_dir/.café"
    touch "$dotfiles_dir/.файл"
    touch "$dotfiles_dir/.😀emoji"
    touch "$dotfiles_dir/.中文"
    
    # Run the script
    local output=$(HOME="$TEST_HOME" CONFIG_ROOT="$TEST_CONFIG" "$LINK_SCRIPT" 2>&1)
    
    # Check if it handles unicode without errors
    if ! echo "$output" | grep -q "ERROR"; then
        test_pass "Handles unicode filenames without errors"
    else
        test_fail "Failed on unicode filenames" "Script produced errors with unicode names"
    fi
}

# Main test execution
main() {
    echo -e "${BLUE}=== Dotfiles Linking Script Test Suite ===${NC}\n"
    
    # Check if link script exists
    if [[ ! -f "$LINK_SCRIPT" ]]; then
        echo -e "${RED}[ERROR]${NC} Cannot find link-dotfiles.sh at: $LINK_SCRIPT"
        exit 1
    fi
    
    # Setup test environment
    setup_test_env
    
    # Run all tests
    test_empty_directories
    test_special_characters
    test_permission_errors
    test_idempotency
    test_existing_files
    test_nested_directories
    test_dry_run
    test_symlink_chains
    test_hidden_directories
    test_unicode_filenames
    
    # Summary
    echo -e "\n${BLUE}=== Test Summary ===${NC}"
    echo -e "Tests run:    $TESTS_RUN"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Run tests
main
