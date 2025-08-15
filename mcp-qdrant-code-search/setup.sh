#!/bin/bash

# Setup script for MCP Qdrant Code Search Server

echo "🚀 Setting up MCP Qdrant Code Search Server"

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "📥 Installing dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Test Qdrant connection
echo "🧪 Testing Qdrant connection..."
if curl -s http://localhost:6333/collections > /dev/null; then
    echo "✅ Qdrant connection successful!"
    COLLECTIONS=$(curl -s http://localhost:6333/collections | python3 -c "import json, sys; data=json.load(sys.stdin); print(len(data['result']['collections']))")
    echo "📊 Found $COLLECTIONS existing collections"
else
    echo "❌ Qdrant connection failed!"
    echo "💡 Make sure Qdrant is running: docker ps | grep qdrant"
    exit 1
fi

# Create Claude Code configuration
echo "⚙️ Creating Claude Code configuration..."
SCRIPT_DIR=$(pwd)
cat > claude-config-local.json << EOF
{
  "mcpServers": {
    "qdrant-code-search": {
      "command": "$SCRIPT_DIR/venv/bin/python",
      "args": ["$SCRIPT_DIR/server.py"],
      "env": {
        "QDRANT_URL": "http://localhost:6333",
        "EMBEDDING_MODEL": "all-MiniLM-L6-v2",
        "COLLECTION_PREFIX": "claude-code",
        "VECTOR_SIZE": "384",
        "CHUNK_SIZE": "1000",
        "SEARCH_LIMIT": "10",
        "SIMILARITY_THRESHOLD": "0.7"
      }
    }
  }
}
EOF

echo "✅ Setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Add this configuration to your ~/.claude.json:"
echo "   cat claude-config-local.json"
echo ""
echo "2. Test the server:"
echo "   source venv/bin/activate"
echo "   python server.py"
echo ""
echo "3. In Claude Code, use tools like:"
echo "   @qdrant-code-search Index codebase: /path/to/your/project"
echo "   @qdrant-code-search Search for: authentication functions"
echo ""
echo "🔧 Configuration file created: claude-config-local.json"
echo "📚 See README.md for full documentation"