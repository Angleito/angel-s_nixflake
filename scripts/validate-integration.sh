#!/bin/bash
# Integration validation script for nix-darwin configurations

set -e

echo "🔍 Validating nix-darwin integration..."
echo "========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a command exists
check_command() {
    local cmd="$1"
    local description="$2"
    
    if command -v "$cmd" &> /dev/null; then
        echo -e "✅ ${GREEN}$description${NC} - $cmd found"
        return 0
    else
        echo -e "❌ ${RED}$description${NC} - $cmd not found"
        return 1
    fi
}

# Function to check if a file exists
check_file() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        echo -e "✅ ${GREEN}$description${NC} - $file exists"
        return 0
    else
        echo -e "❌ ${RED}$description${NC} - $file missing"
        return 1
    fi
}

# Function to check if a directory exists
check_dir() {
    local dir="$1"
    local description="$2"
    
    if [ -d "$dir" ]; then
        echo -e "✅ ${GREEN}$description${NC} - $dir exists"
        return 0
    else
        echo -e "❌ ${RED}$description${NC} - $dir missing"
        return 1
    fi
}

echo "🛠️  Core Development Tools"
echo "-------------------------"
check_command "nix" "Nix Package Manager"
check_command "git" "Git"
check_command "node" "Node.js"
check_command "pnpm" "PNPM"
check_command "cargo" "Rust Cargo"
check_command "rustc" "Rust Compiler"

echo ""
echo "🌐 Web3 Tools"
echo "-------------"
check_command "sui" "Sui CLI"
check_command "walrus" "Walrus CLI"
check_command "vercel" "Vercel CLI"

echo ""
echo "💾 Database Tools"  
echo "----------------"
check_command "psql" "PostgreSQL Client"
check_command "postgres-start" "PostgreSQL Start Script"
check_command "postgres-stop" "PostgreSQL Stop Script" 
check_command "postgres-status" "PostgreSQL Status Script"

echo ""
echo "🤖 AI Development Tools"
echo "----------------------"
check_command "claude-code" "Claude Code CLI"
check_command "cursor" "Cursor (if installed via Homebrew)"

echo ""
echo "📁 Configuration Files"
echo "---------------------"
check_file "$HOME/.claude/settings.json" "Claude Code Settings"
check_file "$HOME/.cursor/mcp.json" "Cursor MCP Configuration"
check_dir "$HOME/.claude/scripts" "Claude Scripts Directory"
check_file "$HOME/.local/bin/update-web3-tools" "Web3 Tools Update Script"

echo ""
echo "🏠 Homebrew Integration"
echo "----------------------"
if command -v brew &> /dev/null; then
    echo -e "✅ ${GREEN}Homebrew${NC} - Available"
    
    # Check for specific packages
    if brew list flock &> /dev/null; then
        echo -e "✅ ${GREEN}flock${NC} - Installed via Homebrew"
    else
        echo -e "❌ ${RED}flock${NC} - Not installed via Homebrew"
    fi
    
    if brew list --cask cursor &> /dev/null; then
        echo -e "✅ ${GREEN}Cursor${NC} - Installed via Homebrew"
    else
        echo -e "⚠️  ${YELLOW}Cursor${NC} - Not installed via Homebrew (may be installed another way)"
    fi
else
    echo -e "❌ ${RED}Homebrew${NC} - Not available"
fi

echo ""
echo "🔧 Environment Variables"
echo "-----------------------"
# Check for important environment variables
if [ -n "$CLAUDE_CODE_API_KEY" ]; then
    echo -e "✅ ${GREEN}CLAUDE_CODE_API_KEY${NC} - Set"
else
    echo -e "⚠️  ${YELLOW}CLAUDE_CODE_API_KEY${NC} - Not set (may need manual configuration)"
fi

if [ -n "$TAVILY_API_KEY" ]; then
    echo -e "✅ ${GREEN}TAVILY_API_KEY${NC} - Set"
else
    echo -e "⚠️  ${YELLOW}TAVILY_API_KEY${NC} - Not set (optional for MCP omnisearch)"
fi

echo ""
echo "🧪 Quick Functionality Tests"
echo "---------------------------"

# Test Nix
if nix --version &> /dev/null; then
    echo -e "✅ ${GREEN}Nix${NC} - Working ($(nix --version | head -1))"
else
    echo -e "❌ ${RED}Nix${NC} - Not working properly"
fi

# Test Node.js
if node --version &> /dev/null; then
    echo -e "✅ ${GREEN}Node.js${NC} - Working ($(node --version))"
else
    echo -e "❌ ${RED}Node.js${NC} - Not working properly"
fi

# Test Rust
if rustc --version &> /dev/null; then
    echo -e "✅ ${GREEN}Rust${NC} - Working ($(rustc --version | cut -d' ' -f1-2))"
else
    echo -e "❌ ${RED}Rust${NC} - Not working properly"
fi

# Test Sui CLI if available
if command -v sui &> /dev/null; then
    if sui --version &> /dev/null; then
        echo -e "✅ ${GREEN}Sui CLI${NC} - Working"
    else
        echo -e "⚠️  ${YELLOW}Sui CLI${NC} - Found but may not be fully functional"
    fi
fi

# Test PostgreSQL setup
if command -v postgres-status &> /dev/null; then
    echo -e "✅ ${GREEN}PostgreSQL Scripts${NC} - Available"
else
    echo -e "⚠️  ${YELLOW}PostgreSQL Scripts${NC} - Not found in PATH"
fi

echo ""
echo "📊 Summary"
echo "========="
echo "Integration validation complete!"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. If any CLI tools are missing, run: darwin-rebuild switch"
echo "2. For API keys, check .env files and update as needed"
echo "3. For PostgreSQL, run 'postgres-start' to initialize the database"
echo "4. For Claude Code, ensure API key is set and run a test command"
echo ""
echo -e "${GREEN}Your nix-darwin configuration should now manage:${NC}"
echo "• All development tools and dependencies"
echo "• Claude Code and Cursor configurations"
echo "• Web3 tool installations via cargo"
echo "• PostgreSQL database setup"
echo "• Homebrew applications"