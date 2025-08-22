#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEFAULT_NIX="$SCRIPT_DIR/default.nix"
UPDATE_LOG="$SCRIPT_DIR/update.log"

# Function to log updates
log_update() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$UPDATE_LOG"
}

echo -e "${BLUE}🧹 Claude Code Backup Cleanup${NC}"
echo ""

# Find all backup files
BACKUP_FILES=($(ls -1t "$DEFAULT_NIX.bak."* 2>/dev/null || true))
TOTAL_BACKUPS=${#BACKUP_FILES[@]}

if [ $TOTAL_BACKUPS -eq 0 ]; then
    echo "No backup files found."
    exit 0
fi

echo "Found $TOTAL_BACKUPS backup file(s):"
echo ""

# Calculate total size
TOTAL_SIZE=0
for backup in "${BACKUP_FILES[@]}"; do
    size=$(stat -f%z "$backup" 2>/dev/null || stat -c%s "$backup" 2>/dev/null || echo 0)
    TOTAL_SIZE=$((TOTAL_SIZE + size))
done

# Display backup info
for i in "${!BACKUP_FILES[@]}"; do
    BACKUP="${BACKUP_FILES[$i]}"
    BACKUP_VERSION=$(grep -E '^\s*version\s*=\s*"[0-9]+\.[0-9]+\.[0-9]+"' "$BACKUP" | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/' || echo "unknown")
    BACKUP_DATE=$(echo "$BACKUP" | sed -E 's/.*\.bak\.([0-9]+_[0-9]+)$/\1/' | sed 's/_/ /')
    SIZE=$(stat -f%z "$BACKUP" 2>/dev/null || stat -c%s "$BACKUP" 2>/dev/null || echo "?")
    
    if [ $i -lt 5 ]; then
        echo -e "  ${GREEN}[KEEP]${NC} Version $BACKUP_VERSION (backup from $BACKUP_DATE) - ${SIZE} bytes"
    else
        echo -e "  ${YELLOW}[DELETE]${NC} Version $BACKUP_VERSION (backup from $BACKUP_DATE) - ${SIZE} bytes"
    fi
done

echo ""
echo "Total disk usage: $TOTAL_SIZE bytes"
echo ""

# Default is to keep 5 most recent
KEEP_COUNT=5

echo "How many recent backups would you like to keep? (default: 5)"
read -p "Enter number or press Enter for default: " user_keep

if [[ "$user_keep" =~ ^[0-9]+$ ]] && [ "$user_keep" -gt 0 ]; then
    KEEP_COUNT=$user_keep
fi

if [ $TOTAL_BACKUPS -le $KEEP_COUNT ]; then
    echo -e "${GREEN}All backups will be kept (total: $TOTAL_BACKUPS, keeping: $KEEP_COUNT)${NC}"
    exit 0
fi

DELETE_COUNT=$((TOTAL_BACKUPS - KEEP_COUNT))
echo ""
echo -e "${YELLOW}This will delete the $DELETE_COUNT oldest backup(s) and keep the $KEEP_COUNT most recent.${NC}"
read -p "Continue? (y/N): " confirm

if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Delete old backups
DELETED=0
for i in "${!BACKUP_FILES[@]}"; do
    if [ $i -ge $KEEP_COUNT ]; then
        BACKUP="${BACKUP_FILES[$i]}"
        rm -f "$BACKUP"
        DELETED=$((DELETED + 1))
        echo "Deleted: $(basename "$BACKUP")"
    fi
done

echo ""
echo -e "${GREEN}✅ Cleanup complete! Deleted $DELETED backup(s).${NC}"
log_update "Cleaned up $DELETED old backup(s), kept $KEEP_COUNT most recent"
