#!/usr/bin/env bash

set -e

echo "Setting up nix-darwin environment..."

# Check if .env file exists, if not prompt user to create it
if [ ! -f ".env" ]; then
    if [ -f ".env.sample" ]; then
        echo ""
        echo "⚠️  IMPORTANT: Environment configuration required!"
        echo "================================================"
        echo "Before running darwin-rebuild, you need to set up your environment variables."
        echo ""
        echo "Please:"
        echo "1. Copy .env.sample to .env:"
        echo "   cp .env.sample .env"
        echo ""
        echo "2. Edit .env and replace the sample values with your real configuration"
        echo ""
        read -p "Would you like to copy .env.sample to .env now? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cp .env.sample .env
            echo "✓ Created .env from .env.sample"
            echo ""
            echo "Please edit .env with your actual values before proceeding."
            echo "Opening .env in your default editor..."
            ${EDITOR:-nano} .env
        else
            echo "Please set up your .env file before running darwin-rebuild."
            exit 1
        fi
    else
        echo "Warning: No .env.sample file found. Please create a .env file with your configuration."
    fi
fi

echo ""
echo "Installing and configuring direnv..."

# Check if Nix is available
if command -v nix &> /dev/null; then
    # Check if home-manager is already configured
    if command -v home-manager &> /dev/null; then
        echo "home-manager is available, direnv should be managed through home-manager configuration"
        echo "Make sure direnv is included in your home.nix packages"
    else
        # Install direnv via nix profile install
        if ! command -v direnv &> /dev/null; then
            echo "Installing direnv via nix profile..."
            nix profile install nixpkgs#direnv
        else
            echo "direnv is already installed"
        fi
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Fallback to Homebrew on macOS if Nix is not available
    if ! command -v brew &> /dev/null; then
        echo "Neither Nix nor Homebrew found. Please install Nix first."
        echo "Visit: https://nixos.org/download.html"
        exit 1
    fi
    
    # Install direnv via Homebrew
    if ! command -v direnv &> /dev/null; then
        echo "Installing direnv via Homebrew..."
        brew install direnv
    else
        echo "direnv is already installed"
    fi
else
    echo "Please install Nix first. Visit: https://nixos.org/download.html"
    exit 1
fi

# Configure direnv for zsh
ZSH_RC="$HOME/.zshrc"

# Check if zsh hook is already configured
if ! grep -q 'eval "$(direnv hook zsh)"' "$ZSH_RC" 2>/dev/null; then
    echo "Adding direnv hook to ~/.zshrc..."
    echo '' >> "$ZSH_RC"
    echo '# direnv hook' >> "$ZSH_RC"
    echo 'eval "$(direnv hook zsh)"' >> "$ZSH_RC"
    echo "direnv hook added to ~/.zshrc"
else
    echo "direnv hook already configured in ~/.zshrc"
fi

# Allow the .envrc in the current directory
if command -v direnv &> /dev/null; then
    echo "Allowing .envrc in current directory..."
    direnv allow .
fi

echo ""
echo "✅ Setup complete!"
echo ""

# Check if nix-darwin is already installed
if ! command -v darwin-rebuild &> /dev/null; then
    echo "Installing nix-darwin..."
    nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake .
    echo "nix-darwin installed successfully!"
else
    echo "nix-darwin is already installed"
fi

echo ""
echo "Next steps:"
echo "1. Ensure your .env file contains the correct values"
echo "2. Restart your shell or run: source ~/.zshrc"
echo "3. Run 'rebuild' (alias) or 'darwin-rebuild switch --flake .' to apply changes"
echo ""
echo "To customize your setup:"
echo "- Edit darwin-configuration.nix to add/remove system apps (casks)"
echo "- Edit home.nix to add/remove user packages"
echo "- Run 'rebuild' after making changes"
