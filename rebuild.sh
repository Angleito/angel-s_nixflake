#!/usr/bin/env bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔄 Nix Darwin Rebuild Script${NC}"
echo ""

# Source .env file if it exists
ENV_FILES=(
    "/Users/angel/Projects/nix-project/.env"
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

# Run darwin-rebuild with environment variables
echo -e "${GREEN}🚀 Running darwin-rebuild switch...${NC}"
echo ""

# Export variables explicitly for the darwin-rebuild command
export GIT_NAME="${GIT_NAME:-}"
export GIT_EMAIL="${GIT_EMAIL:-}"

# Run the command with sudo, preserving environment variables
sudo -E darwin-rebuild switch --flake ".#angel" "$@"

echo ""
echo -e "${GREEN}✅ Rebuild complete!${NC}"