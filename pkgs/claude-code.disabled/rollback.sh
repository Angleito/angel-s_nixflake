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

echo -e "${BLUE}🔄 Claude Code Rollback Utility${NC}"
echo ""

# Find all backup files
BACKUP_FILES=($(ls -1t "$DEFAULT_NIX.bak."* 2>/dev/null || true))

if [ ${#BACKUP_FILES[@]} -eq 0 ]; then
    echo -e "${RED}❌ No backup files found!${NC}"
    echo "No rollback possible."
    exit 1
fi

echo "Available backups:"
echo ""

# Display backups with version info
for i in "${!BACKUP_FILES[@]}"; do
    BACKUP="${BACKUP_FILES[$i]}"
    BACKUP_VERSION=$(grep -E '^\s*version\s*=\s*"[0-9]+\.[0-9]+\.[0-9]+"' "$BACKUP" | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/' || echo "unknown")
    BACKUP_DATE=$(echo "$BACKUP" | sed -E 's/.*\.bak\.([0-9]+_[0-9]+)$/\1/' | sed 's/_/ /')
    echo "  $((i+1)). Version $BACKUP_VERSION (backup from $BACKUP_DATE)"
done

# Get current version
CURRENT_VERSION=$(grep -E '^\s*version\s*=\s*"[0-9]+\.[0-9]+\.[0-9]+"' "$DEFAULT_NIX" | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')
echo ""
echo -e "Current version: ${YELLOW}$CURRENT_VERSION${NC}"
echo ""

# Ask user to select a backup
read -p "Select backup to restore (1-${#BACKUP_FILES[@]}) or 'q' to quit: " selection

if [ "$selection" = "q" ]; then
    echo "Rollback cancelled."
    exit 0
fi

# Validate selection
if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#BACKUP_FILES[@]} ]; then
    echo -e "${RED}Invalid selection!${NC}"
    exit 1
fi

# Get selected backup
SELECTED_BACKUP="${BACKUP_FILES[$((selection-1))]}"
SELECTED_VERSION=$(grep -E '^\s*version\s*=\s*"[0-9]+\.[0-9]+\.[0-9]+"' "$SELECTED_BACKUP" | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')

echo ""
echo -e "${YELLOW}⚠️  This will rollback from version $CURRENT_VERSION to $SELECTED_VERSION${NC}"
read -p "Are you sure? (y/N): " confirm

if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Rollback cancelled."
    exit 0
fi

# Create a backup of current version before rollback
ROLLBACK_BACKUP="$DEFAULT_NIX.bak.rollback.$(date +%Y%m%d_%H%M%S)"
cp "$DEFAULT_NIX" "$ROLLBACK_BACKUP"
echo "📋 Created backup of current version: $ROLLBACK_BACKUP"

# Perform rollback
cp "$SELECTED_BACKUP" "$DEFAULT_NIX"
echo -e "${GREEN}✅ Rolled back to version $SELECTED_VERSION${NC}"
log_update "Rolled back from $CURRENT_VERSION to $SELECTED_VERSION"

echo ""
echo "To apply the rollback system-wide, run:"
echo "  darwin-rebuild switch"
echo ""
echo "If you want to undo this rollback, use:"
echo "  cp $ROLLBACK_BACKUP $DEFAULT_NIX"
