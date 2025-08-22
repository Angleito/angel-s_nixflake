#!/usr/bin/env bash

# Script to clean up stale npm symlinks in ~/.local/bin
# This removes symlinks that point to non-existent npm executables

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function for symlink actions
log_symlink_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [Symlink] $1: $2 -> $3"
}

echo -e "${GREEN}Cleaning up stale npm symlinks...${NC}"

USER_HOME="${HOME:-/Users/angel}"
LOCAL_BIN="$USER_HOME/.local/bin"
NPM_GLOBAL_BIN="$USER_HOME/.npm-global/bin"

if [ ! -d "$LOCAL_BIN" ]; then
    echo -e "${YELLOW}Warning: $LOCAL_BIN directory not found. Nothing to clean.${NC}"
    exit 0
fi

cleaned_count=0
checked_count=0

# List all symlinks before cleanup
echo -e "\n${YELLOW}Current symlinks in $LOCAL_BIN:${NC}"
for symlink in "$LOCAL_BIN"/*; do
    if [ -L "$symlink" ]; then
        target=$(readlink "$symlink")
        symlink_name=$(basename "$symlink")
        if [ -e "$target" ]; then
            echo -e "  ✓ $symlink_name -> $target"
        else
            echo -e "  ${RED}✗ $symlink_name -> $target (broken)${NC}"
        fi
    fi
done

echo -e "\n${GREEN}Checking for stale symlinks...${NC}"

# Clean up stale symlinks
for symlink in "$LOCAL_BIN"/*; do
    if [ -L "$symlink" ]; then
        checked_count=$((checked_count + 1))
        
        # Get the target of the symlink
        target=$(readlink "$symlink")
        
        # Check if it's pointing to npm-global
        if [[ "$target" == "$NPM_GLOBAL_BIN/"* ]] || [[ "$target" == *"/.npm-global/bin/"* ]]; then
            # Check if the target exists
            if [ ! -e "$target" ]; then
                symlink_name=$(basename "$symlink")
                echo -e "${RED}Removing broken symlink: $symlink_name -> $target${NC}"
                log_symlink_action "Removing" "$symlink_name" "$target"
                rm -f "$symlink"
                cleaned_count=$((cleaned_count + 1))
            fi
        fi
    fi
done

# Summary
echo -e "\n${GREEN}Cleanup summary:${NC}"
echo -e "  • Checked: $checked_count symlinks"
echo -e "  • Removed: $cleaned_count stale symlinks"

if [ $cleaned_count -gt 0 ]; then
    echo -e "\n${GREEN}✓ Cleanup completed successfully!${NC}"
else
    echo -e "\n${GREEN}✓ No stale symlinks found. Everything is clean!${NC}"
fi

# List remaining symlinks
if [ -n "$(find "$LOCAL_BIN" -type l 2>/dev/null)" ]; then
    echo -e "\n${YELLOW}Remaining symlinks in $LOCAL_BIN:${NC}"
    for symlink in "$LOCAL_BIN"/*; do
        if [ -L "$symlink" ]; then
            target=$(readlink "$symlink")
            symlink_name=$(basename "$symlink")
            echo -e "  • $symlink_name -> $target"
        fi
    done
fi
