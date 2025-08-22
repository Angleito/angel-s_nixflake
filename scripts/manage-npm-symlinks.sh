#!/usr/bin/env bash

# Script to manage npm symlinks with detailed logging
# This ensures symlinks are created after npm install and before PATH setup

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
USER_HOME="${HOME:-/Users/angel}"
LOCAL_BIN="$USER_HOME/.local/bin"

# Detect npm global directory dynamically
if command -v npm &> /dev/null; then
    NPM_PREFIX="$(npm config get prefix 2>/dev/null || echo "")"
    NPM_GLOBAL_BIN="$NPM_PREFIX/bin"
else
    # Fallback to default
    NPM_GLOBAL_BIN="$USER_HOME/.npm-global/bin"
fi
LOG_FILE="$USER_HOME/.npm-symlinks.log"

# Initialize log file
echo "=== NPM Symlink Management Log ===" > "$LOG_FILE"
echo "Started at: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
echo "NPM Prefix: ${NPM_PREFIX:-Not detected}" >> "$LOG_FILE"
echo "NPM Global Bin: $NPM_GLOBAL_BIN" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Logging function
log_action() {
    local action="$1"
    local details="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log to file
    echo "[$timestamp] [$action] $details" >> "$LOG_FILE"
    
    # Log to console with colors
    case "$action" in
        "CREATE")
            echo -e "${GREEN}[CREATE]${NC} $details"
            ;;
        "UPDATE")
            echo -e "${BLUE}[UPDATE]${NC} $details"
            ;;
        "REMOVE")
            echo -e "${RED}[REMOVE]${NC} $details"
            ;;
        "SKIP")
            echo -e "${YELLOW}[SKIP]${NC} $details"
            ;;
        "INFO")
            echo -e "${NC}[INFO] $details"
            ;;
        *)
            echo "[$action] $details"
            ;;
    esac
}

# Ensure directories exist
mkdir -p "$LOCAL_BIN"

echo -e "${GREEN}=== NPM Symlink Management ===${NC}"
log_action "INFO" "Starting symlink management process"
log_action "INFO" "NPM Global Bin: $NPM_GLOBAL_BIN"
log_action "INFO" "Local Bin: $LOCAL_BIN"

# Step 1: Clean up stale symlinks
echo -e "\n${BLUE}Step 1: Cleaning up stale symlinks...${NC}"
log_action "INFO" "Starting cleanup of stale symlinks"

cleaned_count=0
checked_count=0

if [ -d "$LOCAL_BIN" ]; then
    for symlink in "$LOCAL_BIN"/*; do
        if [ -L "$symlink" ]; then
            checked_count=$((checked_count + 1))
            target=$(readlink "$symlink")
            symlink_name=$(basename "$symlink")
            
            # Check if it's pointing to npm-global
            if [[ "$target" == "$NPM_GLOBAL_BIN/"* ]] || [[ "$target" == *"/.npm-global/bin/"* ]]; then
                # Check if the target exists
                if [ ! -e "$target" ]; then
                    log_action "REMOVE" "Broken symlink: $symlink_name -> $target"
                    rm -f "$symlink"
                    cleaned_count=$((cleaned_count + 1))
                fi
            fi
        fi
    done
fi

log_action "INFO" "Cleanup complete: checked $checked_count symlinks, removed $cleaned_count"

# Step 2: Create/Update symlinks for npm global executables
echo -e "\n${BLUE}Step 2: Creating/updating symlinks for npm global executables...${NC}"
log_action "INFO" "Starting symlink creation/update process"

created_count=0
updated_count=0
skipped_count=0

if [ -d "$NPM_GLOBAL_BIN" ]; then
    for executable in "$NPM_GLOBAL_BIN"/*; do
        if [ -f "$executable" ] && [ -x "$executable" ]; then
            exec_name=$(basename "$executable")
            target_link="$LOCAL_BIN/$exec_name"
            
            # Check if symlink already exists
            if [ -L "$target_link" ]; then
                # Symlink exists, check if it points to the correct location
                current_target=$(readlink "$target_link")
                if [ "$current_target" != "$executable" ]; then
                    log_action "UPDATE" "$exec_name: $current_target -> $executable"
                    rm -f "$target_link"
                    ln -sf "$executable" "$target_link"
                    updated_count=$((updated_count + 1))
                else
                    # Symlink is already correct, log it quietly
                    echo "[$exec_name] Already linked correctly" >> "$LOG_FILE"
                fi
            elif [ -e "$target_link" ]; then
                # File exists but is not a symlink
                log_action "SKIP" "$target_link exists but is not a symlink"
                skipped_count=$((skipped_count + 1))
            else
                # Create new symlink
                log_action "CREATE" "$exec_name -> $executable"
                ln -sf "$executable" "$target_link"
                created_count=$((created_count + 1))
            fi
        fi
    done
else
    log_action "INFO" "Warning: $NPM_GLOBAL_BIN directory not found"
fi

log_action "INFO" "Symlink creation complete: created $created_count, updated $updated_count, skipped $skipped_count"

# Step 3: List all current npm symlinks
echo -e "\n${BLUE}Step 3: Current npm symlinks status...${NC}"
log_action "INFO" "Listing current npm symlinks"

symlink_count=0
if [ -d "$LOCAL_BIN" ]; then
    echo -e "\n${YELLOW}NPM symlinks in $LOCAL_BIN:${NC}"
    for symlink in "$LOCAL_BIN"/*; do
        if [ -L "$symlink" ]; then
            target=$(readlink "$symlink")
            symlink_name=$(basename "$symlink")
            
            # Only show npm-related symlinks
            if [[ "$target" == "$NPM_GLOBAL_BIN/"* ]] || [[ "$target" == *"/.npm-global/bin/"* ]]; then
                if [ -e "$target" ]; then
                    echo -e "  ${GREEN}✓${NC} $symlink_name -> $target"
                    symlink_count=$((symlink_count + 1))
                else
                    echo -e "  ${RED}✗${NC} $symlink_name -> $target (broken)"
                fi
            fi
        fi
    done
fi

# Summary
echo -e "\n${GREEN}=== Summary ===${NC}"
echo -e "  • Symlinks removed: $cleaned_count"
echo -e "  • Symlinks created: $created_count"
echo -e "  • Symlinks updated: $updated_count"
echo -e "  • Symlinks skipped: $skipped_count"
echo -e "  • Total active npm symlinks: $symlink_count"

log_action "INFO" "Symlink management completed successfully"
echo "" >> "$LOG_FILE"
echo "Completed at: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

echo -e "\n${NC}Log file saved to: $LOG_FILE"
