#!/bin/bash
# generate-claude-config.sh - Generate Claude Code configuration with environment variables

set -e

# Function to check if jq is installed
check_jq() {
  if ! command -v jq &> /dev/null; then
    echo "❌ jq is not installed. Please install jq to use JSON validation."
    echo "On macOS: brew install jq"
    echo "On Ubuntu/Debian: sudo apt-get install jq"
    exit 1
  fi
}

# Function to validate and recover existing configuration
validate_existing_config() {
  local config_file="$1"
  local backup_file="$2"
  
  if [ -f "$config_file" ]; then
    if ! jq empty "$config_file" 2>/dev/null; then
      echo "❌ Corrupted configuration detected: $config_file"
      echo "🔄 Attempting to recover from backup..."
      
      if [ -f "$backup_file" ]; then
        if jq empty "$backup_file" 2>/dev/null; then
          cp "$backup_file" "$config_file"
          echo "✅ Recovery successful. Backup restored for $config_file"
          echo "Configuration corruption recovered on $(date)" >> /tmp/claude_config_errors.log
        else
          echo "❌ Backup file is also corrupted: $backup_file"
          echo "Backup file corruption detected on $(date)" >> /tmp/claude_config_errors.log
        fi
      else
        echo "❌ No backup available for $config_file"
        echo "No backup available for recovery on $(date)" >> /tmp/claude_config_errors.log
      fi
    fi
  fi
}

# Check for required tools
check_jq

echo "🔧 Generating Claude Code configuration..."

# Check existing configurations for corruption
echo "🔍 Checking existing configurations for corruption..."
validate_existing_config "$HOME/.claude.json" "$HOME/.claude.json.bak"
validate_existing_config "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.bak"

# Source the .env file to get API keys
# First check in current directory, then in common locations
if [ -f "./.env" ]; then
  echo "📋 Loading API keys from ./.env file..."
  set -a
  source "./.env"
  set +a
elif [ -f "$HOME/Projects/nix-project/.env" ]; then
  echo "📋 Loading API keys from ~/Projects/nix-project/.env file..."
  set -a
  source "$HOME/Projects/nix-project/.env"
  set +a
elif [ -f "$HOME/.env" ]; then
  echo "📋 Loading API keys from ~/.env file..."
  set -a
  source "$HOME/.env"
  set +a
fi

# Create directories
mkdir -p ~/.claude/commands/frontend ~/.claude/commands/backend ~/.local/bin

# Generate main configuration with environment variables
# Validate JSON and create backup before writing
MAIN_CONFIG=$(mktemp)
cat > "$MAIN_CONFIG" << EOF
{
  "numStartups": 0,
  "autoUpdaterStatus": "enabled",
  "theme": "dark",
  "hasCompletedOnboarding": true,
  "dangerouslySkipPermissions": true,
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
      "args": ["-y", "@microsoft/mcp-server-playwright"]
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

# Validate the JSON
if jq empty "$MAIN_CONFIG"; then
  echo "✅ JSON is valid."
  # Backup existing configuration if it exists
  if [ -f ~/.claude.json ]; then
    cp ~/.claude.json ~/.claude.json.bak
    echo "🔄 Backup of the existing configuration created."
  fi
  # Move new configuration to final location
  mv "$MAIN_CONFIG" ~/.claude.json
else
  echo "❌ JSON validation failed!"
  echo "🔄 Attempting to recover from backup..."
  # Attempt recovery from backup
  if [ -f ~/.claude.json.bak ]; then
    cp ~/.claude.json.bak ~/.claude.json
    echo "✅ Recovery successful. Backup restored."
  else
    echo "❌ No backup available. Recovery failed."
  fi
  # Log the error
  echo "JSON validation error occurred on $(date)" >> /tmp/claude_config_errors.log
  rm "$MAIN_CONFIG"
fi
EOF

# Generate settings.json
SETTINGS_CONFIG=$(mktemp)
cat > "$SETTINGS_CONFIG" << EOF
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

# Validate settings.json
if jq empty "$SETTINGS_CONFIG"; then
  echo "✅ Settings JSON is valid."
  # Backup existing settings if it exists
  if [ -f ~/.claude/settings.json ]; then
    cp ~/.claude/settings.json ~/.claude/settings.json.bak
    echo "🔄 Backup of the existing settings created."
  fi
  # Move new settings to final location
  mv "$SETTINGS_CONFIG" ~/.claude/settings.json
else
  echo "❌ Settings JSON validation failed!"
  echo "🔄 Attempting to recover from backup..."
  # Attempt recovery from backup
  if [ -f ~/.claude/settings.json.bak ]; then
    cp ~/.claude/settings.json.bak ~/.claude/settings.json
    echo "✅ Recovery successful. Settings backup restored."
  else
    echo "❌ No settings backup available. Recovery failed."
  fi
  # Log the error
  echo "Settings JSON validation error occurred on $(date)" >> /tmp/claude_config_errors.log
  rm "$SETTINGS_CONFIG"
fi

# Create claude wrapper script with permissions bypass
echo "Creating claude wrapper script..."
cat > ~/.local/bin/claude << 'EOF'
#!/bin/bash
# Source .env file - check multiple locations
if [ -f "./.env" ]; then
  export $(grep -v '^#' "./.env" | xargs)
elif [ -f "$HOME/Projects/nix-project/.env" ]; then
  export $(grep -v '^#' "$HOME/Projects/nix-project/.env" | xargs)
elif [ -f "$HOME/.env" ]; then
  export $(grep -v '^#' "$HOME/.env" | xargs)
fi

# Refresh shell command cache to ensure all commands are available
hash -r

# Find the latest claude-code binary in nix store
CLAUDE_BIN=$(find /nix/store -name "*claude*" -type f -executable 2>/dev/null | grep "bin/claude" | head -1)
if [ -z "$CLAUDE_BIN" ]; then
    echo "Error: Claude Code binary not found in nix store"
    echo "Please ensure claude-code is installed via nix"
    exit 1
fi
exec "$CLAUDE_BIN" --dangerously-skip-permissions "$@"
EOF

chmod +x ~/.local/bin/claude

# Ensure ~/.local/bin is in PATH for new terminals
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.zshrc 2>/dev/null; then
    echo 'Adding ~/.local/bin to PATH in ~/.zshrc...'
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
fi

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

cat > ~/.claude/commands/workflow.md << 'EOF'
---
allowed-tools: Task, TodoRead, TodoWrite, Read, Grep, Bash(git:*), Bash(npm:*)
description: Orchestrate parallel Task agents for large workflows
---

# Parallel Workflow Orchestrator

Execute large workflows using parallel Task tool sub-agents with intelligent batching and coordination.

## Workflow: $ARGUMENTS

## Execution Strategy

### Phase 1: Task Analysis and Planning
First, I'll analyze the requested workflow and break it down into:
- **Independent tasks**: Can be executed in parallel without conflicts
- **Sequential dependencies**: Must be executed in order
- **Resource-intensive tasks**: Should be limited per batch

### Phase 2: Batch Orchestration
Execute tasks in optimized batches:
- **Batch size**: Maximum 10 parallel agents per batch
- **Collision prevention**: Each agent works on specific files/directories
- **Progress tracking**: Monitor completion via TodoRead/TodoWrite

### Phase 3: Task Agent Instructions
Each Task agent will receive:
1. **Specific scope**: Clear boundaries (files/directories to work on)
2. **Isolation requirements**: Avoid modifying shared resources
3. **Output format**: Structured results for aggregation
4. **Error handling**: Report failures without blocking other agents

### Phase 4: Synchronization Points
Between batches:
- **Verify completion**: Check all agents finished successfully
- **Resolve conflicts**: Handle any file conflicts if they arise
- **Update progress**: Mark todos as completed
- **Plan next batch**: Based on dependencies and results

## Example Workflow Breakdown

For a request like "Refactor all components to use TypeScript":
1. **Batch 1**: Analyze and list all components (1 agent)
2. **Batch 2**: Convert simple components (10 agents, 1 per component)
3. **Batch 3**: Convert complex components (5 agents for resource-intensive work)
4. **Batch 4**: Update imports and tests (10 agents for different modules)
5. **Batch 5**: Final verification and cleanup (1 agent)

## Coordination Rules

1. **File locking**: Agents declare which files they'll modify upfront
2. **Directory isolation**: Prefer agents working in separate directories
3. **Merge strategy**: Later batches handle integration of earlier work
4. **Rollback capability**: Each batch creates a checkpoint

## Progress Reporting

Regular updates will include:
- Current batch number and size
- Completed vs pending tasks
- Any failures or conflicts
- Estimated remaining time

## Failure Handling

If any agent fails:
1. Continue with other agents in the batch
2. Collect all failure reports
3. Attempt retry with adjusted strategy
4. Report unrecoverable failures to user

This orchestrator ensures efficient parallel execution while maintaining code quality and preventing conflicts between concurrent operations.
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

# Final validation check
echo "🔍 Performing final validation check..."
CONFIG_VALID=true

if [ -f ~/.claude.json ]; then
  if jq empty ~/.claude.json 2>/dev/null; then
    echo "✅ Main configuration validated successfully."
  else
    echo "❌ Main configuration validation failed!"
    CONFIG_VALID=false
  fi
else
  echo "❌ Main configuration file not found!"
  CONFIG_VALID=false
fi

if [ -f ~/.claude/settings.json ]; then
  if jq empty ~/.claude/settings.json 2>/dev/null; then
    echo "✅ Settings configuration validated successfully."
  else
    echo "❌ Settings configuration validation failed!"
    CONFIG_VALID=false
  fi
else
  echo "❌ Settings configuration file not found!"
  CONFIG_VALID=false
fi

if [ "$CONFIG_VALID" = true ]; then
  echo "✅ Claude Code configuration generated successfully!"
  echo "Configuration generation completed successfully on $(date)" >> /tmp/claude_config_errors.log
else
  echo "❌ Configuration generation completed with errors!"
  echo "Configuration generation failed on $(date)" >> /tmp/claude_config_errors.log
fi

echo ""
echo "Configuration files created:"
echo "  📁 ~/.claude.json - Main configuration with MCP servers"
echo "  🔧 ~/.claude/settings.json - Advanced settings"
echo "  📝 ~/.claude/commands/ - Custom slash commands"
echo ""
echo "Backup files:"
echo "  🔄 ~/.claude.json.bak - Backup of main configuration"
echo "  🔄 ~/.claude/settings.json.bak - Backup of settings"
echo ""
echo "Error logging:"
echo "  📝 /tmp/claude_config_errors.log - Error and recovery log"
echo ""
echo "Custom commands available:"
echo "  /user:security-review  - Comprehensive security audit"
echo "  /user:optimize        - Code performance analysis"
echo "  /user:deploy          - Smart deployment with checks"
echo "  /user:debug           - Systematic debugging"
echo "  /user:research        - Multi-source research using omnisearch"
echo "  /user:workflow        - Orchestrate parallel Task agents for large workflows"
echo "  /user:frontend:component - React/Vue component generator"
echo "  /user:backend:api     - API endpoint generator"
echo ""
echo "🚀 Start Claude Code with: claude"
echo "   (Configured to bypass permissions for development environments)"
