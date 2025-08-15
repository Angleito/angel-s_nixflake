#!/bin/bash

# Setup script for Qdrant MCP server environment
# This script helps configure the OpenAI API key and other environment variables

set -e

echo "🔧 Setting up Qdrant MCP server environment..."

# Check if running from the correct directory
if [ ! -f "darwin-configuration.nix" ]; then
    echo "❌ Error: Please run this script from the angelsnixconfig directory"
    exit 1
fi

# Function to read API key securely
read_api_key() {
    echo "📝 Please enter your OpenAI API key (input will be hidden):"
    echo "   You can get your API key from: https://platform.openai.com/api-keys"
    read -s OPENAI_API_KEY
    echo
    
    if [ -z "$OPENAI_API_KEY" ]; then
        echo "❌ Error: OpenAI API key cannot be empty"
        return 1
    fi
    
    # Basic validation - OpenAI keys start with 'sk-'
    if [[ ! "$OPENAI_API_KEY" =~ ^sk-.* ]]; then
        echo "⚠️  Warning: OpenAI API keys typically start with 'sk-'"
        echo "   Continue anyway? (y/N)"
        read -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    echo "✅ API key received"
}

# Function to update the Nix configuration
update_nix_config() {
    echo "🔄 Updating Nix configuration with API key..."
    
    # Create a backup
    cp darwin-configuration.nix darwin-configuration.nix.backup
    
    # Update the OPENAI_API_KEY in the configuration
    sed -i "" "s/OPENAI_API_KEY = \"\";/OPENAI_API_KEY = \"$OPENAI_API_KEY\";/" darwin-configuration.nix
    
    if [ $? -eq 0 ]; then
        echo "✅ Nix configuration updated successfully"
        echo "   Backup saved as: darwin-configuration.nix.backup"
    else
        echo "❌ Error: Failed to update Nix configuration"
        mv darwin-configuration.nix.backup darwin-configuration.nix
        return 1
    fi
}

# Function to check Qdrant server
check_qdrant() {
    echo "🔍 Checking Qdrant server..."
    
    if curl -s http://localhost:6333/collections > /dev/null 2>&1; then
        echo "✅ Qdrant server is running at http://localhost:6333"
        
        # Check for existing Roocode collections
        WS_COLLECTIONS=$(curl -s http://localhost:6333/collections | jq -r '.result.collections[]? | select(.name | startswith("ws-")) | .name' | wc -l)
        if [ "$WS_COLLECTIONS" -gt 0 ]; then
            echo "✅ Found $WS_COLLECTIONS Roocode collections (ws-* prefix)"
            echo "✅ Shared Qdrant instance detected - OrbStack container fa8bbffe423a"
        fi
    else
        echo "⚠️  Qdrant server is not running"
        echo "   Your OrbStack container (fa8bbffe423a) may be stopped"
        echo "   Check OrbStack and restart the Qdrant container if needed"
    fi
}

# Function to test the setup
test_setup() {
    echo "🧪 Testing the setup..."
    
    # Check if MCP server directory exists
    MCP_DIR="$HOME/.local/share/mcp-servers/qdrant-code-search"
    if [ -d "$MCP_DIR" ]; then
        echo "✅ MCP server directory exists: $MCP_DIR"
        
        # Check if virtual environment exists
        if [ -f "$MCP_DIR/venv/bin/python" ]; then
            echo "✅ Virtual environment exists"
            
            # Test dependencies
            if "$MCP_DIR/venv/bin/python" -c "import mcp, qdrant_client, openai" > /dev/null 2>&1; then
                echo "✅ Required Python packages are installed"
            else
                echo "⚠️  Some Python packages may be missing"
                echo "   Run: cd $MCP_DIR && venv/bin/pip install -r requirements.txt"
            fi
        else
            echo "⚠️  Virtual environment not found"
            echo "   This will be created during the next system rebuild"
        fi
    else
        echo "⚠️  MCP server directory not found"
        echo "   This will be created during the next system rebuild"
    fi
}

# Main execution
echo "🚀 Qdrant MCP Server Setup"
echo "=========================="
echo

# Step 1: Read API key
if read_api_key; then
    echo
    
    # Step 2: Update configuration
    if update_nix_config; then
        echo
        
        # Step 3: Check Qdrant
        check_qdrant
        echo
        
        # Step 4: Test setup
        test_setup
        echo
        
        echo "🎉 Setup complete!"
        echo
        echo "Next steps:"
        echo "1. Rebuild your system: ./rebuild.sh"
        echo "2. Start Qdrant if not running: docker run -p 6333:6333 qdrant/qdrant"
        echo "3. Test with Claude Code: claude"
        echo "4. Try indexing: @qdrant-code-search Use code_index to index /path/to/your/project"
        echo "5. Try searching: @qdrant-code-search Find functions that handle authentication"
        echo
    else
        echo "❌ Setup failed during configuration update"
        exit 1
    fi
else
    echo "❌ Setup cancelled"
    exit 1
fi