#!/usr/bin/env bash

# Test script to verify npm symlink management

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== NPM Symlink Test ===${NC}"
echo ""

# Check environment
echo -e "${YELLOW}Environment Check:${NC}"
echo "HOME: $HOME"
echo "PATH: $PATH"
echo ""

# Check directories
echo -e "${YELLOW}Directory Status:${NC}"
[ -d "$HOME/.npm-global" ] && echo "✓ ~/.npm-global exists" || echo "✗ ~/.npm-global missing"
[ -d "$HOME/.npm-global/bin" ] && echo "✓ ~/.npm-global/bin exists" || echo "✗ ~/.npm-global/bin missing"
[ -d "$HOME/.local/bin" ] && echo "✓ ~/.local/bin exists" || echo "✗ ~/.local/bin missing"
echo ""

# Count npm executables
if [ -d "$HOME/.npm-global/bin" ]; then
    npm_count=$(find "$HOME/.npm-global/bin" -type f -executable | wc -l)
    echo -e "${YELLOW}NPM Executables:${NC} $npm_count found"
fi

# Count symlinks
if [ -d "$HOME/.local/bin" ]; then
    symlink_count=$(find "$HOME/.local/bin" -type l | wc -l)
    npm_symlink_count=$(find "$HOME/.local/bin" -type l -exec readlink {} \; | grep -c "/.npm-global/bin/" || true)
    echo -e "${YELLOW}Symlinks:${NC} $symlink_count total, $npm_symlink_count pointing to npm-global"
fi

echo ""

# Check if PATH includes necessary directories
echo -e "${YELLOW}PATH Check:${NC}"
if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
    echo "✓ ~/.local/bin is in PATH"
else
    echo "✗ ~/.local/bin is NOT in PATH"
fi

if [[ ":$PATH:" == *":$HOME/.npm-global/bin:"* ]]; then
    echo "✓ ~/.npm-global/bin is in PATH"
else
    echo "✗ ~/.npm-global/bin is NOT in PATH"
fi

echo ""

# Check log file
if [ -f "$HOME/.npm-symlinks.log" ]; then
    echo -e "${YELLOW}Recent log entries:${NC}"
    tail -n 10 "$HOME/.npm-symlinks.log"
fi
