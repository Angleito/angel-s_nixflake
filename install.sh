#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Installing Angel's Nix Darwin Configuration"
echo ""

# Check if Nix is installed
if ! command -v nix &> /dev/null; then
    echo "❌ Nix is not installed. Please install Nix first:"
    echo "   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
    exit 1
fi

echo "✓ Nix is installed"

# Install Homebrew if not already installed (required for casks)
if ! command -v brew &> /dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for this session
    if [[ "$(uname -m)" == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    echo "✓ Homebrew is already installed"
fi

# Check if nix-darwin is already installed
if ! command -v darwin-rebuild &> /dev/null; then
    echo "📦 Installing nix-darwin..."
    nix run nix-darwin -- switch --flake .
else
    echo "🔄 Updating configuration..."
    sudo darwin-rebuild switch --flake .
fi

echo ""
echo "=================================================="
echo "✅ Installation Complete!"
echo "=================================================="
echo ""
echo "Installed applications:"
echo "  • Warp - AI-powered terminal"
echo "  • Cursor - AI code editor"
echo "  • Brave Browser - Privacy-focused browser"
echo "  • Orbstack - Docker/container management"
echo "  • Zoom - Video conferencing"
echo "  • Slack - Team messaging"
echo "  • GarageBand - Music creation (from Mac App Store)"
echo ""
echo "Installed development tools:"
echo "  • Node.js, Python, Go, Rust"
echo "  • Git, GitHub CLI, Lazygit"
echo "  • Docker, Docker Compose"
echo "  • Xcode Command Line Tools"
echo "  • Modern CLI tools (ripgrep, fzf, bat, etc.)"
echo "  • AI & Blockchain CLIs: Claude Code, Sui, Walrus (testnet configured)"
echo ""
echo "System configurations:"
echo "  • Display sleep disabled (screen stays on)"
echo "  • Git hooks to remove Claude co-authorship"
echo "  • Environment variables loaded from .env"
echo ""
echo "Next steps:"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. Your apps should be available in /Applications"
echo "3. Use 'rebuild' alias to apply any future changes"
echo ""
echo "To customize:"
echo "  • Edit darwin-configuration.nix for system apps"
echo "  • Edit home.nix for CLI tools and packages"
echo "  • Run 'rebuild' after making changes"
