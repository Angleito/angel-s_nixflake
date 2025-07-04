#!/bin/bash
# bootstrap.sh - Bootstrap script for nix-darwin with Claude Code configuration

set -e

echo "🚀 Setting up nix-darwin with Claude Code configuration..."

# Get current hostname and username
HOSTNAME=$(scutil --get LocalHostName)
USERNAME=$(whoami)

echo "Configuring for hostname: $HOSTNAME, username: $USERNAME"

# Check if Nix is installed
if ! command -v nix &> /dev/null; then
    echo "❌ Nix is not installed. Please install Nix first:"
    echo "curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "flake.nix" ]; then
    echo "❌ flake.nix not found. Please run this script from your nix-project directory."
    exit 1
fi

# Update flake.nix with correct hostname if needed
if grep -q "angels-MacBook-Pro" flake.nix; then
    echo "📝 Updating hostname in flake.nix..."
    sed -i '' "s/angels-MacBook-Pro/$HOSTNAME/g" flake.nix
fi

# Update home.nix with correct username if needed
if grep -q '"angel"' home.nix; then
    echo "📝 Updating username in home.nix..."
    sed -i '' "s/\"angel\"/\"$USERNAME\"/g" home.nix
fi

# Apply the configuration
echo "⚙️  Applying nix-darwin configuration..."
if ! sudo darwin-rebuild switch --flake .#$HOSTNAME; then
    echo "❌ Failed to apply nix-darwin configuration"
    exit 1
fi

# Generate Claude Code configuration with environment variables
echo "🤖 Setting up Claude Code configuration..."
if [ -f "./generate-claude-config.sh" ]; then
    ./generate-claude-config.sh
else
    echo "⚠️  Claude configuration script not found, skipping..."
fi

echo "✅ Setup complete!"
echo ""
echo "Claude Code is now configured with:"
echo "  📁 Global configuration in ~/.claude.json"
echo "  🔧 Custom slash commands in ~/.claude/commands/"
echo "  🔗 MCP servers for enhanced capabilities"
echo "  🎨 Dark theme and completed onboarding"
echo "  ⚡ Permissions bypass enabled for development"
echo ""
echo "Custom commands available:"
echo "  /user:security-review  - Comprehensive security audit"
echo "  /user:optimize        - Code performance analysis"
echo "  /user:deploy          - Smart deployment with checks"
echo "  /user:debug           - Systematic debugging"
echo "  /user:research        - Multi-source research using omnisearch"
echo "  /user:frontend:component - React/Vue component generator"
echo "  /user:backend:api     - API endpoint generator"
echo ""
echo "🔄 Restart your terminal to ensure all changes take effect."
echo "🚀 Run 'claude' to start Claude Code with your new configuration!"
echo "   (Now configured to bypass permissions for smoother development)"
