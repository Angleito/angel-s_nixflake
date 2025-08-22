#!/bin/bash

echo "🔧 Simple Nix Rebuild Solution"
echo ""
echo "This script will help you rebuild the Nix configuration with the HRM MCP server."
echo ""

# The key is to set the safe.directory for the root user
echo "Step 1: Run this command first (you'll need to enter your password):"
echo ""
echo "  sudo git config --global --add safe.directory /Users/angel/angelsnixconfig"
echo ""
echo "Step 2: Then run the rebuild:"
echo ""
echo "  sudo ./rebuild.sh"
echo ""
echo "Or run both together:"
echo ""
echo "  sudo bash -c 'git config --global --add safe.directory /Users/angel/angelsnixconfig && cd /Users/angel/angelsnixconfig && ./rebuild.sh'"
echo ""
echo "After rebuild, the HRM MCP server will be available in Claude Code!"