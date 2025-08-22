#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEFAULT_NIX="$SCRIPT_DIR/default.nix"
UPDATE_LOG="$SCRIPT_DIR/update.log"

# Function to log updates
log_update() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$UPDATE_LOG"
}

echo "🔍 Checking for Claude Code updates..."
log_update "Starting update check"

# Check if npm is available
if ! command -v npm &> /dev/null; then
    echo -e "${RED}Error: npm is not installed. Please install Node.js/npm first.${NC}"
    exit 1
fi

# Check if nix-prefetch-url is available
if ! command -v nix-prefetch-url &> /dev/null; then
    echo -e "${RED}Error: nix-prefetch-url is not installed. Please install Nix first.${NC}"
    exit 1
fi

# Get the latest version from npm registry
echo "📦 Fetching latest version from npm registry..."
LATEST_VERSION=$(npm view @anthropic-ai/claude-code version 2>/dev/null)

if [ -z "$LATEST_VERSION" ]; then
    echo -e "${RED}Error: Failed to fetch latest version from npm registry${NC}"
    exit 1
fi

echo "Latest version available: $LATEST_VERSION"

# Extract current version from default.nix
CURRENT_VERSION=$(grep -E '^\s*version\s*=\s*"[0-9]+\.[0-9]+\.[0-9]+"' "$DEFAULT_NIX" | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')

if [ -z "$CURRENT_VERSION" ]; then
    echo -e "${RED}Error: Could not extract current version from default.nix${NC}"
    exit 1
fi

echo "Current version in default.nix: $CURRENT_VERSION"

# Compare versions
if [ "$LATEST_VERSION" = "$CURRENT_VERSION" ]; then
    echo -e "${GREEN}✅ Already up to date!${NC}"
    log_update "Already up to date at version $CURRENT_VERSION"
    exit 0
fi

echo -e "${YELLOW}🔄 New version available: $CURRENT_VERSION → $LATEST_VERSION${NC}"

# Download and get the sha256 hash
echo "📥 Downloading tarball and computing sha256 hash..."
TARBALL_URL="https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${LATEST_VERSION}.tgz"

# Use nix-prefetch-url to get the sha256 hash in the format Nix expects
# First, try with --unpack flag
NEW_SHA256=$(nix-prefetch-url --unpack "$TARBALL_URL" 2>/dev/null | tail -n 1)

# If the hash seems to be in the old format, convert it
if [[ ! "$NEW_SHA256" =~ ^sha256- ]]; then
    # Try to get the SRI hash format
    NEW_SHA256=$(nix hash to-sri --type sha256 "$NEW_SHA256" 2>/dev/null || echo "$NEW_SHA256")
fi

if [ -z "$NEW_SHA256" ]; then
    echo -e "${RED}Error: Failed to compute sha256 hash${NC}"
    exit 1
fi

echo "New sha256 hash: $NEW_SHA256"

# Create a backup of the original file with timestamp
BACKUP_FILE="$DEFAULT_NIX.bak.$(date +%Y%m%d_%H%M%S)"
cp "$DEFAULT_NIX" "$BACKUP_FILE"
echo "📋 Created backup: $BACKUP_FILE"
log_update "Created backup: $BACKUP_FILE"

# Update version in default.nix
sed -i.tmp -E "s/version = \"[0-9]+\.[0-9]+\.[0-9]+\"/version = \"$LATEST_VERSION\"/" "$DEFAULT_NIX"

# Update sha256 in default.nix
# Handle both old-style and SRI-style hashes
if [[ "$NEW_SHA256" =~ ^sha256- ]]; then
    # SRI format
    sed -i.tmp -E "s/sha256 = \"[^\"]+\"/sha256 = \"$NEW_SHA256\"/" "$DEFAULT_NIX"
else
    # Old format
    sed -i.tmp -E "s/sha256 = \"[a-z0-9]+\"/sha256 = \"$NEW_SHA256\"/" "$DEFAULT_NIX"
fi

# Remove temporary file created by sed
rm -f "$DEFAULT_NIX.tmp"

echo -e "${GREEN}✅ Successfully updated default.nix!${NC}"
log_update "Updated default.nix: $CURRENT_VERSION → $LATEST_VERSION (sha256: $NEW_SHA256)"

echo ""
echo "Changes made:"
echo "  - Version: $CURRENT_VERSION → $LATEST_VERSION"
echo "  - SHA256: Updated to new hash"
echo "  - Backup: $BACKUP_FILE"
echo ""
echo -e "${BLUE}📦 Building and testing the new version...${NC}"

# Build the package
BUILD_RESULT=$(nix-build -E 'with import <nixpkgs> {}; callPackage ./default.nix {}' 2>&1)
BUILD_EXIT_CODE=$?

if [ $BUILD_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}❌ Build failed! Rolling back...${NC}"
    echo "Build output: $BUILD_RESULT"
    cp "$BACKUP_FILE" "$DEFAULT_NIX"
    log_update "Build failed for version $LATEST_VERSION, rolled back to $CURRENT_VERSION"
    exit 1
fi

echo -e "${GREEN}✅ Build successful!${NC}"
BUILT_PATH=$(echo "$BUILD_RESULT" | tail -n 1)

# Test the new version
echo -e "${BLUE}🧪 Testing claude --version...${NC}"
VERSION_OUTPUT=$($BUILT_PATH/bin/claude --version 2>&1 || true)
echo "Version output: $VERSION_OUTPUT"

if echo "$VERSION_OUTPUT" | grep -q "$LATEST_VERSION"; then
    echo -e "${GREEN}✅ Version verification successful!${NC}"
    log_update "Successfully updated and verified Claude Code version $LATEST_VERSION"
else
    echo -e "${YELLOW}⚠️  Warning: Could not verify version in output${NC}"
    echo "Expected version: $LATEST_VERSION"
    echo "Got output: $VERSION_OUTPUT"
    log_update "Updated to $LATEST_VERSION but version verification had warnings"
fi

# Run additional tests
echo ""
echo -e "${BLUE}🧪 Running additional tests...${NC}"
if $BUILT_PATH/bin/claude --help 2>&1 | grep -q "Usage:"; then
    echo -e "${GREEN}✅ Help command works${NC}"
else
    echo -e "${YELLOW}⚠️  Help command may have issues${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Update complete!${NC}"
echo ""
echo "To use the new version system-wide, run:"
echo "  darwin-rebuild switch"
echo ""
echo "If you encounter any issues, you can rollback using:"
echo "  cp $BACKUP_FILE $DEFAULT_NIX"
echo ""
echo "Update log available at: $UPDATE_LOG"
