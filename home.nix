{ config, pkgs, ... }:

{
  # Import git configuration
  imports = [
    ./home/git.nix
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "angel";
  home.homeDirectory = "/Users/angel";

  # This value determines the Home Manager release that your
  # configuration is compatible with.
  home.stateVersion = "23.11";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # User packages
  home.packages = with pkgs; [
    # Development tools
    nodejs_20
    python3
    go
    rustup
    docker
    docker-compose
    
    # CLI utilities
    htop
    neofetch
    tree
    ripgrep
    fd
    bat
    eza  # modern ls replacement (formerly exa)
    fzf
    jq
    yq
    gh  # GitHub CLI
    lazygit
    tmux
    
    # Nix tools
    nixpkgs-fmt
    nil  # Nix LSP
    
    # Productivity
    direnv
    starship
    zoxide
    
    # System tools
    coreutils
    findutils
    gnugrep
    gnused
    gawk
    
    # Archive tools
    unzip
    p7zip
  ];

  # Zsh configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    shellAliases = {
      ll = "ls -l";
      la = "ls -la";
      ".." = "cd ..";
      "..." = "cd ../..";
      
      # Git aliases
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log";
      gd = "git diff";
      
      # Nix aliases
      rebuild = "darwin-rebuild switch --flake .";
      update = "nix flake update";
    };
    
    initContent = ''
      # Add local bin to PATH
      export PATH="$HOME/.local/bin:$PATH"
      
      # Source .env file - check multiple locations
      if [ -f "./.env" ]; then
        export $(grep -v '^#' "./.env" | xargs)
      elif [ -f "$HOME/Projects/nix-project/.env" ]; then
        export $(grep -v '^#' "$HOME/Projects/nix-project/.env" | xargs)
      elif [ -f "$HOME/.env" ]; then
        export $(grep -v '^#' "$HOME/.env" | xargs)
      fi
      
      # Starship prompt
      eval "$(starship init zsh)"
      
      # Zoxide (better cd)
      eval "$(zoxide init zsh)"
      
      # FZF
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh
      source ${pkgs.fzf}/share/fzf/completion.zsh
    '';
  };

  # Starship prompt configuration
  programs.starship = {
    enable = true;
    settings = {
      format = "$all$character";
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
    };
  };

  # Add local bin to PATH (npm global no longer needed since claude-code is from nix)
  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  # Create claude wrapper script with permissions bypass
  home.file.".local/bin/claude".text = ''#!/bin/bash
    # Source .env file - check multiple locations
    if [ -f "./.env" ]; then
      export $(grep -v '^#' "./.env" | xargs)
    elif [ -f "$HOME/Projects/nix-project/.env" ]; then
      export $(grep -v '^#' "$HOME/Projects/nix-project/.env" | xargs)
    elif [ -f "$HOME/.env" ]; then
      export $(grep -v '^#' "$HOME/.env" | xargs)
    fi
    
    # Force shell to recognize the new command
    hash -r
    
    exec ${pkgs.claude-code}/bin/claude --dangerously-skip-permissions "$@"
  '';
  
  # Make the claude wrapper executable
  home.file.".local/bin/claude".executable = true;

  # Claude Code Configuration
  # Create the main Claude configuration file with environment variable support
  # Using home.activation to create a writable file instead of read-only home.file
  home.activation.claudeConfig = config.lib.dag.entryAfter ["writeBoundary"] ''
    CLAUDE_CONFIG_PATH="$HOME/.claude.json"
    
    # Source the .env file - check multiple locations
    if [ -f "./.env" ]; then
      export $(grep -v '^#' "./.env" | xargs)
    elif [ -f "$HOME/Projects/nix-project/.env" ]; then
      export $(grep -v '^#' "$HOME/Projects/nix-project/.env" | xargs)  
    elif [ -f "$HOME/.env" ]; then
      export $(grep -v '^#' "$HOME/.env" | xargs)
    fi
    
    # Create the config content with environment variables
    cat > "$CLAUDE_CONFIG_PATH" << EOF
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
        "/Users/${config.home.username}",
        "/Users/${config.home.username}/Projects",
        "/Users/${config.home.username}/Documents"
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
        "TAVILY_API_KEY": "$TAVILY_API_KEY",
        "BRAVE_API_KEY": "$BRAVE_API_KEY",
        "KAGI_API_KEY": "$KAGI_API_KEY",
        "PERPLEXITY_API_KEY": "$PERPLEXITY_API_KEY",
        "JINA_AI_API_KEY": "$JINA_AI_API_KEY",
        "FIRECRAWL_API_KEY": "$FIRECRAWL_API_KEY"
      }
    }
  },
  "projects": {}
}
EOF
    
    # Make the file writable
    chmod 644 "$CLAUDE_CONFIG_PATH"
  '';

  # Claude configuration - using home.activation to create writable files
  home.activation.claudeSetup = config.lib.dag.entryAfter ["writeBoundary"] ''
    # Create Claude directory structure
    mkdir -p "$HOME/.claude/commands/frontend"
    mkdir -p "$HOME/.claude/commands/backend"
    mkdir -p "$HOME/.claude/projects"
    mkdir -p "$HOME/.claude/statsig"
    mkdir -p "$HOME/.claude/todos"
    
    # Create writable settings.json
    cat > "$HOME/.claude/settings.json" << 'EOF'
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
    
    # Make all files writable
    chmod -R 755 "$HOME/.claude"
    chmod 644 "$HOME/.claude/settings.json"
    
    # Create command files
    cat > "$HOME/.claude/commands/security-review.md" << 'EOF'
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
    
    cat > "$HOME/.claude/commands/optimize.md" << 'EOF'
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
    
    cat > "$HOME/.claude/commands/deploy.md" << 'EOF'
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
    
    cat > "$HOME/.claude/commands/frontend/component.md" << 'EOF'
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
    
    cat > "$HOME/.claude/commands/backend/api.md" << 'EOF'
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
    
    cat > "$HOME/.claude/commands/debug.md" << 'EOF'
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
    
    cat > "$HOME/.claude/commands/research.md" << 'EOF'
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
    
    cat > "$HOME/.claude/commands/parallel-workflow.md" << 'EOF'
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
    
    # Make all command files writable
    chmod 644 "$HOME/.claude/commands"/*.md
    chmod 644 "$HOME/.claude/commands/frontend"/*.md
    chmod 644 "$HOME/.claude/commands/backend"/*.md
  '';
  
  # Create git hooks to remove Claude co-authored signature
  home.activation.gitHooks = config.lib.dag.entryAfter ["writeBoundary"] ''
    # Create git hooks directory
    mkdir -p "$HOME/.config/git/hooks"
    
    # Create commit-msg hook to remove Claude co-authored signature
    cat > "$HOME/.config/git/hooks/commit-msg" << 'EOF'
#!/bin/bash
# Remove Claude co-authored signature from commits
TEMP_FILE=$(mktemp)
grep -v "Co-Authored-By: Claude <noreply@anthropic.com>" "$1" > "$TEMP_FILE"
grep -v "🤖 Generated with \[Claude Code\]" "$TEMP_FILE" > "$1"
rm "$TEMP_FILE"
EOF
    
    # Make the hook executable
    chmod +x "$HOME/.config/git/hooks/commit-msg"
  '';
}
