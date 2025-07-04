#!/bin/bash
# generate-claude-config.sh - Generate Claude Code configuration with environment variables

set -e

echo "🔧 Generating Claude Code configuration..."

# Create directories
mkdir -p ~/.claude/commands/frontend ~/.claude/commands/backend ~/.local/bin

# Generate main configuration with environment variables
cat > ~/.claude.json << EOF
{
  "numStartups": 0,
  "autoUpdaterStatus": "enabled",
  "theme": "dark",
  "hasCompletedOnboarding": true,
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/Users/$USER",
        "/Users/$USER/Projects",
        "/Users/$USER/Documents"
      ]
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    },
    "fetch": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-fetch"]
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "puppeteer": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-puppeteer"]
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-playwright"]
    },
    "mcp-omnisearch": {
      "command": "npx",
      "args": ["-y", "mcp-omnisearch"],
      "env": {
        "TAVILY_API_KEY": "${TAVILY_API_KEY:-}",
        "BRAVE_API_KEY": "${BRAVE_API_KEY:-}",
        "KAGI_API_KEY": "${KAGI_API_KEY:-}",
        "PERPLEXITY_API_KEY": "${PERPLEXITY_API_KEY:-}",
        "JINA_AI_API_KEY": "${JINA_AI_API_KEY:-}",
        "FIRECRAWL_API_KEY": "${FIRECRAWL_API_KEY:-}"
      }
    }
  },
  "projects": {}
}
EOF

# Generate settings.json
cat > ~/.claude/settings.json << EOF
{
  "env": {
    "DISABLE_TELEMETRY": "1",
    "DISABLE_ERROR_REPORTING": "1",
    "ANTHROPIC_API_KEY": ""
  },
  "allowedTools": [
    "Task",
    "Bash(git:*)",
    "Bash(npm:*)",
    "Glob",
    "Grep",
    "Read",
    "Edit",
    "MultiEdit",
    "Write",
    "WebFetch"
  ],
  "maxFileSize": 1000000,
  "contextWindow": 200000
}
EOF

# Create claude wrapper script with permissions bypass
echo "Creating claude wrapper script..."
cat > ~/.local/bin/claude << 'EOF'
#!/bin/bash
# Find the latest claude-code binary in nix store
CLAUDE_BIN=$(find /nix/store -name "claude" -path "*/claude-code-*/bin/claude" -type f -executable 2>/dev/null | head -1)
if [ -z "$CLAUDE_BIN" ]; then
    echo "Error: Claude Code binary not found in nix store"
    echo "Please ensure claude-code is installed via nix"
    exit 1
fi
exec "$CLAUDE_BIN" --dangerously-skip-permissions "$@"
EOF

chmod +x ~/.local/bin/claude

# Generate custom commands
cat > ~/.claude/commands/security-review.md << 'EOF'
---
allowed-tools: Bash(npm audit), Bash(git:*), Read, Grep
description: Comprehensive security review of codebase
---

# Security Review Command

Perform a comprehensive security review of this codebase:

1. **Dependency audit**: !`npm audit`
2. **Check for hardcoded secrets**: !`grep -r "password\|secret\|token\|key" . --exclude-dir=node_modules --exclude-dir=.git`
3. **Review authentication logic**: Focus on @auth/ directory if present
4. **Check for SQL injection vulnerabilities**
5. **Validate input sanitization** 
6. **Review CORS and security headers**

Provide actionable recommendations for each finding with specific code examples.
EOF

cat > ~/.claude/commands/optimize.md << 'EOF'
---
allowed-tools: Bash(npm:*), Bash(git:*), Read, Edit, MultiEdit, Grep
description: Analyze and optimize code performance
---

# Code Optimization Command

Analyze this code for performance issues and suggest optimizations:

## Context
- **Current git status**: !`git status --porcelain`
- **Current branch**: !`git branch --show-current`
- **Recent commits**: !`git log --oneline -5`

## Analysis Focus
Focus on @$ARGUMENTS if provided

## Tasks
1. **Run existing tests**: !`npm run test`
2. **Check current performance**: !`npm run benchmark` (if available)
3. **Analyze the codebase**: Look for performance bottlenecks
4. **Suggest specific optimizations** with code examples
5. **Verify changes don't break functionality**

Provide concrete, actionable performance improvements.
EOF

cat > ~/.claude/commands/deploy.md << 'EOF'
---
allowed-tools: Bash(git:*), Bash(npm:*), WebFetch
description: Smart deployment with comprehensive checks
---

# Smart Deploy Command

Deploy the application with comprehensive checks:

## Pre-deployment Checks
- **Current branch**: !`git branch --show-current`
- **Uncommitted changes**: !`git status --porcelain`
- **Run tests**: !`npm run test`
- **Build check**: !`npm run build`
- **Check for security vulnerabilities**: !`npm audit`

## Deployment Strategy
Based on the current branch and project type:
- **main/master**: Deploy to production (requires confirmation)
- **staging**: Deploy to staging environment
- **develop**: Deploy to development environment

## Confirmation Required
Ask for explicit confirmation before proceeding with deployment, especially for production.
EOF

cat > ~/.claude/commands/debug.md << 'EOF'
---
allowed-tools: Bash(npm:*), Bash(git:*), Read, Grep
description: Debug issues with comprehensive analysis
---

# Debug Command

Debug the current issue systematically:

## Issue Analysis
Focus on: $ARGUMENTS

## Debugging Steps
1. **Check recent changes**: !`git log --oneline -10`
2. **Look for error logs**: !`grep -r "error\|Error\|ERROR" . --exclude-dir=node_modules --exclude-dir=.git`
3. **Check dependencies**: !`npm list --depth=0`
4. **Review configuration**: Look for config files
5. **Check environment**: !`env | grep -E "(NODE|PATH|PORT)"`

## Error Context
- **Current git status**: !`git status --porcelain`
- **Last successful commit**: !`git log --oneline --since="1 week ago"`
- **Package.json scripts**: !`grep -A 20 "scripts" package.json`

Provide step-by-step debugging approach with specific commands to run.
EOF

cat > ~/.claude/commands/research.md << 'EOF'
---
allowed-tools: WebFetch, Read, Grep
description: Comprehensive research using multiple search engines and AI tools
---

# Research Command

Conduct comprehensive research on the specified topic using multiple sources:

## Research Topic
Research: $ARGUMENTS

## Research Strategy
Use the mcp-omnisearch server to gather information from multiple sources:

1. **Search Multiple Engines**: Query Tavily, Brave, and Kagi for diverse perspectives
2. **AI Analysis**: Use Perplexity AI for synthesized insights
3. **Content Processing**: Leverage Jina AI Reader for article analysis
4. **Content Summarization**: Use Kagi Summarizer for key points

## Context Analysis
- **Current project**: Check @README.md for project context
- **Related files**: Look for existing documentation on the topic
- **Recent discussions**: !`grep -r "$ARGUMENTS" . --exclude-dir=node_modules --exclude-dir=.git`

## Output Format
Provide:
- **Executive Summary**: Key findings and insights
- **Detailed Analysis**: Comprehensive information from multiple sources
- **Actionable Recommendations**: Specific next steps
- **Source Attribution**: Credit all sources used

Focus on accuracy, comprehensiveness, and actionable insights.
EOF

cat > ~/.claude/commands/frontend/component.md << 'EOF'
---
allowed-tools: Read, Edit, Write, Bash(npm:*)
description: Generate React/Vue component with TypeScript
---

# Component Generator

Create a new frontend component with the following specifications:

## Component Details
- **Component name**: $ARGUMENTS
- **Use TypeScript** with proper typing
- **Include styling** (CSS modules, styled-components, or framework-specific)
- **Add proper prop validation**
- **Include basic unit tests**
- **Follow project style guide** as outlined in @README.md or @CONTRIBUTING.md

## File Structure
Create the component in the appropriate directory based on project structure:
- Check existing components for patterns
- Follow naming conventions
- Include index file if needed

## Additional Context
- **Current project structure**: !`find src -name "*.tsx" -o -name "*.vue" | head -10`
- **Package.json dependencies**: !`grep -E "react|vue|typescript" package.json`
EOF

cat > ~/.claude/commands/backend/api.md << 'EOF'
---
allowed-tools: Read, Edit, Write, Bash(npm:*), Bash(git:*)
description: Generate API endpoint with proper validation and testing
---

# API Endpoint Generator

Create a new API endpoint with the following specifications:

## Endpoint Details
- **Endpoint name**: $ARGUMENTS
- **Include input validation** (joi, yup, or similar)
- **Add proper error handling**
- **Include authentication/authorization** if needed
- **Add comprehensive unit tests**
- **Follow REST/GraphQL conventions**

## Context Files
- **Current API structure**: !`find . -name "*.js" -o -name "*.ts" | grep -E "(api|routes|controllers)" | head -10`
- **Database models**: Check @models/ or @schemas/ directory
- **Authentication setup**: Check @auth/ or @middleware/ directory

## Requirements
- Follow existing code patterns
- Include proper documentation
- Add to API documentation if it exists
EOF

echo "✅ Claude Code configuration generated successfully!"
echo ""
echo "Configuration files created:"
echo "  📁 ~/.claude.json - Main configuration with MCP servers"
echo "  🔧 ~/.claude/settings.json - Advanced settings"
echo "  📝 ~/.claude/commands/ - Custom slash commands"
echo ""
echo "Custom commands available:"
echo "  /user:security-review  - Comprehensive security audit"
echo "  /user:optimize        - Code performance analysis"
echo "  /user:deploy          - Smart deployment with checks"
echo "  /user:debug           - Systematic debugging"
echo "  /user:research        - Multi-source research using omnisearch"
echo "  /user:frontend:component - React/Vue component generator"
echo "  /user:backend:api     - API endpoint generator"
echo ""
echo "🚀 Start Claude Code with: claude"
echo "   (Configured to bypass permissions for development environments)"
