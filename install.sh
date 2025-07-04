#!/usr/bin/env bash

set -e

echo "Installing and configuring direnv..."

# Check if we're on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Install direnv via Homebrew
    if ! command -v direnv &> /dev/null; then
        echo "Installing direnv..."
        brew install direnv
    else
        echo "direnv is already installed"
    fi
else
    # For non-macOS systems, check if Nix is available
    if command -v nix-env &> /dev/null; then
        if ! command -v direnv &> /dev/null; then
            echo "Installing direnv via Nix..."
            nix-env -iA nixpkgs.direnv
        else
            echo "direnv is already installed"
        fi
    else
        echo "Please install direnv manually for your system"
        exit 1
    fi
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

echo "Setup complete! Please restart your shell or run: source ~/.zshrc"
