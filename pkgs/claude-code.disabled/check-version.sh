#!/usr/bin/env bash

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEFAULT_NIX="$SCRIPT_DIR/default.nix"

echo -e "${BLUE}🔍 Claude Code Version Information${NC}"
echo ""

# Extract version from default.nix
NIX_VERSION=$(grep -E '^\s*version\s*=\s*"[0-9]+\.[0-9]+\.[0-9]+"' "$DEFAULT_NIX" | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')

echo -e "Version in default.nix: ${GREEN}$NIX_VERSION${NC}"

# Check if claude command is available
if command -v claude &> /dev/null; then
    echo ""
    echo "Installed claude command output:"
    claude --version 2>&1 || echo "  (claude --version command failed)"
else
    echo -e "${YELLOW}Claude command not found in PATH${NC}"
fi

# Check latest version from npm
if command -v npm &> /dev/null; then
    echo ""
    echo "Checking latest version on npm..."
    LATEST_VERSION=$(npm view @anthropic-ai/claude-code version 2>/dev/null || echo "failed to fetch")
    if [ "$LATEST_VERSION" != "failed to fetch" ]; then
        echo -e "Latest version on npm: ${GREEN}$LATEST_VERSION${NC}"
        if [ "$LATEST_VERSION" != "$NIX_VERSION" ]; then
            echo -e "${YELLOW}⚠️  Update available: $NIX_VERSION → $LATEST_VERSION${NC}"
            echo "Run ./update-version.sh to update"
        else
            echo -e "${GREEN}✅ You are on the latest version!${NC}"
        fi
    fi
fi

# Show update log tail if it exists
if [ -f "$SCRIPT_DIR/update.log" ]; then
    echo ""
    echo "Recent update history:"
    tail -n 5 "$SCRIPT_DIR/update.log" | sed 's/^/  /'
fi
