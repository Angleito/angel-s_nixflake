#!/bin/bash
set -e

echo "🔧 Nix Configuration Rebuild with Git Fix"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load environment
if [[ -f ".env" ]]; then
    echo -e "${YELLOW}📄 Loading environment from .env${NC}"
    set -a
    source .env
    set +a
fi

# Method 1: Try with ownership bypass
echo -e "${BLUE}Attempting rebuild with ownership bypass...${NC}"

# Create a temporary copy of the config without Git
TEMP_DIR="/tmp/nix-config-$$"
echo "Creating temporary config copy at $TEMP_DIR..."

# Copy everything except .git
rsync -av --exclude='.git' /Users/angel/angelsnixconfig/ "$TEMP_DIR/"

# Change to temp directory
cd "$TEMP_DIR"

# Initialize a new git repo (owned by root when run with sudo)
sudo git init
sudo git add .
sudo git commit -m "Temporary commit for rebuild"

# Run rebuild from the temporary location
echo -e "${GREEN}Running rebuild from temporary location...${NC}"
sudo darwin-rebuild switch --flake ".#angel" || \
sudo nix run nix-darwin -- switch --flake ".#angel"

# Cleanup
echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

echo -e "${GREEN}✅ Rebuild complete!${NC}"
echo ""
echo "HRM MCP server is now configured in Claude Code with tools:"
echo "  • hierarchical_reason"
echo "  • decompose_task"
echo "  • refine_solution"
echo "  • analyze_reasoning_trace"