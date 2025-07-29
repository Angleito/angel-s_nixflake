#!/usr/bin/env bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect platform
PLATFORM=""
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="darwin"
elif [[ -f /etc/nixos/configuration.nix ]] || [[ -f /etc/NIXOS ]]; then
    PLATFORM="nixos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
else
    echo -e "${RED}❌ Unsupported platform: $OSTYPE${NC}"
    exit 1
fi

echo -e "${GREEN}🔄 Nix Configuration Rebuild Script${NC}"
echo -e "${BLUE}📦 Platform: $PLATFORM${NC}"
echo ""

# Source .env file if it exists
ENV_FILES=(
    "$(pwd)/.env"
    "$HOME/.config/nix-project/.env"
    "$HOME/.env"
    "./.env"
)

ENV_LOADED=false
for env_file in "${ENV_FILES[@]}"; do
    if [[ -f "$env_file" ]]; then
        echo -e "${YELLOW}📄 Loading environment from: $env_file${NC}"
        set -a  # Mark all new variables for export
        source "$env_file"
        set +a  # Stop marking for export
        ENV_LOADED=true
        break
    fi
done

if [[ "$ENV_LOADED" == false ]]; then
    echo -e "${RED}⚠️  No .env file found. Git config will use defaults.${NC}"
    echo "Searched locations:"
    for env_file in "${ENV_FILES[@]}"; do
        echo "  - $env_file"
    done
    echo ""
fi

# Verify git configuration
if [[ -n "${GIT_NAME:-}" && -n "${GIT_EMAIL:-}" ]]; then
    echo -e "${GREEN}✅ Git configuration loaded:${NC}"
    echo "   Name: $GIT_NAME"
    echo "   Email: $GIT_EMAIL"
else
    echo -e "${YELLOW}⚠️  Git configuration not found in environment${NC}"
    echo "   Using defaults from git.nix"
fi

echo ""

# Run platform-specific rebuild command
echo -e "${GREEN}🚀 Running rebuild...${NC}"
echo ""

# Export variables explicitly for the rebuild command
export GIT_NAME="${GIT_NAME:-}"
export GIT_EMAIL="${GIT_EMAIL:-}"

# Run the appropriate rebuild command based on platform
case "$PLATFORM" in
    darwin)
        # Detect configuration name (default to "angel")
        CONFIG_NAME="${NIX_CONFIG_NAME:-angel}"
        echo -e "${BLUE}🍎 Using Darwin configuration: $CONFIG_NAME${NC}"
        sudo -E darwin-rebuild switch --flake ".#$CONFIG_NAME" "$@"
        ;;
    nixos)
        # Detect hostname for configuration selection
        HOSTNAME=$(hostname)
        CONFIG_NAME=""
        
        # Check for ARM architecture
        if [[ "$(uname -m)" == "aarch64" ]] || [[ "$HOSTNAME" == *"arm"* ]]; then
            CONFIG_NAME="${NIX_CONFIG_NAME:-angel-nixos-arm}"
        else
            CONFIG_NAME="${NIX_CONFIG_NAME:-angel-nixos}"
        fi
        
        echo -e "${BLUE}🐧 Using NixOS configuration: $CONFIG_NAME${NC}"
        sudo nixos-rebuild switch --flake ".#$CONFIG_NAME" "$@"
        ;;
    linux)
        echo -e "${RED}❌ Non-NixOS Linux detected. This configuration requires NixOS.${NC}"
        echo "Please install NixOS first or use home-manager standalone."
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✅ Rebuild complete!${NC}"