#!/bin/bash

# Script to update Claude and Cursor MCP configurations with environment variables

# Source the .env file
if [ -f "/Users/angel/angelsnixconfig/.env" ]; then
    echo "Loading environment variables from .env file..."
    set -a  # automatically export all variables
    source "/Users/angel/angelsnixconfig/.env"
    set +a
else
    echo "Error: .env file not found at /Users/angel/angelsnixconfig/.env"
    exit 1
fi

# Update Claude configuration
echo "Updating Claude MCP configuration..."

# Create MCP server configuration with actual values
cat > /tmp/claude-mcp-servers.json << EOF
{
  "puppeteer": {
    "command": "npx",
    "args": ["-y", "puppeteer-mcp-server"]
  },
  "playwright": {
    "command": "npx",
    "args": ["-y", "@playwright/mcp"]
  },
  "mcp-omnisearch": {
    "command": "npx",
    "args": ["-y", "mcp-omnisearch"],
    "env": {
      "TAVILY_API_KEY": "$TAVILY_API_KEY",
      "BRAVE_API_KEY": "$BRAVE_API_KEY",
      "KAGI_API_KEY": "$KAGI_API_KEY",
      "PERPLEXITY_API_KEY": "$PERPLEXITY_API_KEY",
      "JINA_AI_API_KEY": "$JINA_AI_API_KEY",
      "FIRECRAWL_API_KEY": "$FIRECRAWL_API_KEY"
    }
  },
  "ruv-swarm": {
    "command": "npx",
    "args": ["-y", "ruv-swarm", "mcp", "start"],
    "env": {
      "NODE_ENV": "production"
    }
  },
  "sequential-thinking": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
  },
  "memory": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-memory"]
  },
  "filesystem": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/angel/Projects", "/Users/angel/Documents", "/Users/angel/.claude", "/tmp"]
  }
}
EOF

# Update ~/.claude.json with MCP servers
if [ -f "$HOME/.claude.json" ]; then
    jq --slurpfile new /tmp/claude-mcp-servers.json '. as $orig | $orig | .mcpServers = $new[0]' "$HOME/.claude.json" > "$HOME/.claude.json.tmp" && \
    mv "$HOME/.claude.json.tmp" "$HOME/.claude.json"
else
    echo '{}' | jq --argjson servers "$(cat /tmp/claude-mcp-servers.json)" '.mcpServers = $servers' > "$HOME/.claude.json"
fi

rm -f /tmp/claude-mcp-servers.json

echo "Claude MCP configuration updated!"

# Update Cursor configuration
echo "Updating Cursor MCP configuration..."

cat > "$HOME/.cursor/mcp.json" << EOF
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-filesystem", "/Users/angel/Projects", "/Users/angel/Documents"],
      "env": {}
    },
    "memory": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-memory"],
      "env": {}
    },
    "puppeteer": {
      "command": "npx",
      "args": ["@cloudflare/mcp-server-puppeteer"],
      "env": {}
    },
    "mcp-omnisearch": {
      "command": "npx",
      "args": ["mcp-omnisearch"],
      "env": {
        "PERPLEXITY_API_KEY": "$PERPLEXITY_API_KEY",
        "BRAVE_API_KEY": "$BRAVE_API_KEY",
        "TAVILY_API_KEY": "$TAVILY_API_KEY",
        "KAGI_API_KEY": "$KAGI_API_KEY",
        "JINA_AI_API_KEY": "$JINA_AI_API_KEY",
        "FIRECRAWL_API_KEY": "$FIRECRAWL_API_KEY"
      }
    },
    "ruv-swarm": {
      "command": "npx",
      "args": ["ruv-swarm", "mcp", "start"],
      "env": {
        "NODE_ENV": "production"
      }
    }
  }
}
EOF

echo "Cursor MCP configuration updated!"

echo "Done! MCP configurations have been updated with environment variables from .env"
