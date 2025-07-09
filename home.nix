{ config, pkgs, lib, ... }:

let
  # Simple JSON utilities for Claude configuration
  escapeJsonString = str:
    let
      escapeMap = {
        "\\" = "\\\\";
        "\"" = "\\\"";
        "\n" = "\\n";
        "\r" = "\\r";
        "\t" = "\\t";
      };
      escapeChar = char: escapeMap.${char} or char;
      chars = lib.stringToCharacters str;
    in lib.concatStrings (map escapeChar chars);
  
  # Get environment variable with default
  getEnvWithDefault = varName: default:
    let value = builtins.getEnv varName;
    in if value == "" then default else value;
  
  # Build JSON object filtering out null values
  buildJsonObject = attrs:
    lib.filterAttrs (n: v: v != null) attrs;
in

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
    nodePackages.pnpm
    bun
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
    
    # Web3 tools
    sui-cli
    walrus-cli
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
      rebuild = "cd /Users/angel/Projects/nix-project && ./rebuild.sh";
      rebuild-quick = "darwin-rebuild switch --flake .#angel";
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
      
      # Load global .env file if it exists
      if [ -f "$HOME/.env" ]; then
        source "$HOME/.env"
      fi
      
      # Darwin-rebuild wrapper function
      darwin-rebuild() {
        local args=("$@")
        
        # Check if --flake . is used without hostname
        for ((i=1; i<=$#args; i++)); do
          if [[ "$args[$i]" == "--flake" ]] && [[ $((i+1)) -le $#args ]]; then
            if [[ "$args[$((i+1))]" == "." ]]; then
              # Always use "angel" configuration
              args[$((i+1))]=".#angel"
            fi
          fi
        done
        
        # Call the real darwin-rebuild
        command darwin-rebuild "$args[@]"
      }
      
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

  # Create Claude wrapper script with permissions bypass
  home.file.".local/bin/claude" = {
    text = ''
      #!/bin/bash
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
    executable = true;
  };
  
  # Main Claude configuration using Nix builtins.toJSON
  home.activation.claudeConfig = 
    let
      # Get environment variables with fallback values
      tavilyApiKey = getEnvWithDefault "TAVILY_API_KEY" "";
      braveApiKey = getEnvWithDefault "BRAVE_API_KEY" "";
      kagiApiKey = getEnvWithDefault "KAGI_API_KEY" "";
      perplexityApiKey = getEnvWithDefault "PERPLEXITY_API_KEY" "";
      jinaAiApiKey = getEnvWithDefault "JINA_AI_API_KEY" "";
      firecrawlApiKey = getEnvWithDefault "FIRECRAWL_API_KEY" "";
      
      # Base configuration object
      baseConfig = {
        numStartups = 0;
        autoUpdaterStatus = "enabled";
        theme = "dark";
        hasCompletedOnboarding = true;
        mcpServers = {
          filesystem = {
            command = "${pkgs.nodejs_20}/bin/node";
            args = [
              "${pkgs.nodejs_20}/bin/npm"
              "exec"
              "--"
              "@modelcontextprotocol/server-filesystem"
              "/Users/${config.home.username}"
              "/Users/${config.home.username}/Projects"
              "/Users/${config.home.username}/Documents"
            ];
          };
          memory = {
            command = "${pkgs.nodejs_20}/bin/node";
            args = [
              "${pkgs.nodejs_20}/bin/npm"
              "exec"
              "--"
              "@modelcontextprotocol/server-memory"
            ];
          };
          puppeteer = {
            command = "${pkgs.nodejs_20}/bin/node";
            args = [
              "${pkgs.nodejs_20}/bin/npm"
              "exec"
              "--"
              "@modelcontextprotocol/server-puppeteer"
            ];
          };
          playwright = {
            command = "${pkgs.nodejs_20}/bin/node";
            args = [
              "${pkgs.nodejs_20}/bin/npm"
              "exec"
              "--"
              "@microsoft/mcp-server-playwright"
            ];
          };
        };
        projects = {};
      };
      
      # Build omnisearch environment variables (only include non-empty keys)
      omnisearchEnv = buildJsonObject {
        TAVILY_API_KEY = if tavilyApiKey != "" then tavilyApiKey else null;
        BRAVE_API_KEY = if braveApiKey != "" then braveApiKey else null;
        KAGI_API_KEY = if kagiApiKey != "" then kagiApiKey else null;
        PERPLEXITY_API_KEY = if perplexityApiKey != "" then perplexityApiKey else null;
        JINA_AI_API_KEY = if jinaAiApiKey != "" then jinaAiApiKey else null;
        FIRECRAWL_API_KEY = if firecrawlApiKey != "" then firecrawlApiKey else null;
      };
      
      # Add omnisearch server if any API keys are available
      finalConfig = if omnisearchEnv != {} then 
        baseConfig // {
          mcpServers = baseConfig.mcpServers // {
            mcp-omnisearch = {
              command = "${pkgs.nodejs_20}/bin/node";
              args = [
                "${pkgs.nodejs_20}/bin/npm"
                "exec"
                "--"
                "mcp-omnisearch"
              ];
              env = omnisearchEnv;
            };
          };
        }
      else baseConfig;
      
      # Convert to JSON string
      configJson = builtins.toJSON finalConfig;
    in
    config.lib.dag.entryAfter ["writeBoundary"] ''
      CLAUDE_CONFIG_PATH="$HOME/.claude.json"
      
      # Write the JSON configuration
      cat > "$CLAUDE_CONFIG_PATH" << 'EOF'
${configJson}
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
    
    cat > "$HOME/.claude/commands/workflow.md" << 'EOF'
---
allowed-tools: Task, TodoRead, TodoWrite, Read, Grep, Bash(git:*), Bash(npm:*), WebFetch
description: Execute efficient multi-agent workflows with code-reuse, ultrathink, and omnisearch
---

# Workflow Orchestrator

Execute efficient workflows using parallel Task tool sub-agents with intelligent coordination.

## Workflow: $ARGUMENTS

## Core Principles

1. **Reuse code from the repo** - Always check for existing implementations before creating new ones
2. **Edit existing files and use existing folders** - Modify what's there before creating new structures
3. **Use ultrathink and omnisearch** - Leverage advanced planning and research capabilities
4. **Create short, efficient, and modular code** - Focus on clarity and maintainability
5. **Always separate concerns** - Each module should have a single, clear responsibility
6. **Execute plans in parallel** - Use multiple Task tool sub-agents for efficiency
7. **Prevent agent collisions** - Ensure agents work on different files/directories
8. **Follow order of operations** - Respect sequential dependencies

## Execution Strategy

### Phase 1: Planning with Ultrathink
Use ultrathink for complex workflow decomposition:
- Analyze the complete scope of work
- Identify reusable components in the codebase
- Plan modular architecture

### Phase 2: Research with Omnisearch
Leverage omnisearch for gathering context:
- Search for best practices and patterns
- Find existing solutions to adapt
- Validate architectural decisions

### Phase 3: Parallel Execution
Deploy Task agents efficiently:
- **Maximum 10 agents per batch** to prevent resource exhaustion
- **Clear file/directory boundaries** for each agent
- **Atomic operations** that can succeed or fail independently

### Phase 4: Coordination
Ensure smooth workflow:
- Agents declare their working files upfront
- Sequential dependencies respected
- Progress tracked via TodoRead/TodoWrite
- Conflicts resolved between batches

## Example Workflow

For "Implement authentication system":
1. **Ultrathink planning**: Decompose into auth provider, middleware, UI components
2. **Omnisearch research**: Find best practices for the chosen auth method
3. **Parallel execution**:
   - Agent 1: Set up auth provider configuration
   - Agent 2: Create middleware functions
   - Agent 3: Build login/logout UI components
   - Agent 4: Add authentication to existing routes
4. **Integration**: Final agent merges all components

## Key Guidelines

- **Code Reuse**: Always `grep` for existing patterns first
- **Modularity**: Each file should export focused functionality
- **Efficiency**: Minimize code duplication and complexity
- **Order**: Respect build dependencies and import chains
- **Safety**: Each agent's work should be independently testable

This orchestrator ensures efficient parallel execution while maintaining code quality and architectural integrity.
EOF
    
    cat > "$HOME/.claude/commands/design.md" << 'EOF'
---
allowed-tools: Read, Edit, MultiEdit, Write, Grep
description: shadcn/ui with Tailwind v4 design system guidelines and best practices
---

# shadcn/ui with Tailwind v4 Design System Guidelines

This document outlines design principles and implementation guidelines for applications using shadcn/ui with Tailwind v4. These guidelines ensure consistency, accessibility, and best practices throughout the UI development process.

## Core Design Principles

### 1. Typography System: 4 Sizes, 2 Weights
- **4 Font Sizes Only**:
  - Size 1: Large headings
  - Size 2: Subheadings/Important content
  - Size 3: Body text
  - Size 4: Small text/labels
- **2 Font Weights Only**:
  - Semibold: For headings and emphasis
  - Regular: For body text and general content
- **Consistent Hierarchy**: Maintain clear visual hierarchy with limited options

### 2. 8pt Grid System
- **All spacing values must be divisible by 8 or 4**
- **Examples**:
  - Instead of 25px padding → Use 24px (divisible by 8)
  - Instead of 11px margin → Use 12px (divisible by 4)
- **Consistent Rhythm**: Creates visual harmony throughout the interface

### 3. 60/30/10 Color Rule
- **60%**: Neutral color (white/light gray)
- **30%**: Complementary color (dark gray/black)
- **10%**: Main brand/accent color (e.g., red, blue)
- **Color Balance**: Prevents visual stress while maintaining hierarchy

### 4. Clean Visual Structure
- **Logical Grouping**: Related elements should be visually connected
- **Deliberate Spacing**: Spacing between elements should follow the grid system
- **Alignment**: Elements should be properly aligned within their containers
- **Simplicity Over Flashiness**: Focus on clarity and function first

## Foundation

### Tailwind v4 Integration
- **Use Tailwind CSS v4 for styling**: Leverage the latest Tailwind features including the new @theme directive, dynamic utility values, and OKLCH colors. [Tailwind CSS v4 Documentation](mdc:https://tailwindcss.com/docs)
- **Modern browsing features**: Tailwind v4 uses bleeding-edge browser features and is designed for modern browsers.
- **Simplified installation**: Fewer dependencies, zero configuration required in many cases.
- **shadcn/ui v4 demo**: Reference the demo site for component examples. [shadcn/ui v4 Demo](mdc:https://v4.shadcn.com/)

### New CSS Structure
- **Replace @layer base with @theme directive**:
  ```css
  /* Old approach in v3 */
  @layer base {
    :root {
      --background: 0 0% 100%;
      --foreground: 0 0% 3.9%;
    }
  }
  
  /* New approach in v4 */
  @theme {
    --color-background: hsl(var(--background));
    --color-foreground: hsl(var(--foreground));
  }
  ```
- **Tailwind imports**: Use `@import "tailwindcss"` instead of `@tailwind base`
- **Container queries**: Built-in support without plugins
- **OKLCH color format**: Updated from HSL for better color perception

## Typography System

### Font Sizes & Weights
- **Strictly limit to 4 distinct sizes**:
  - Size 1: Large headings (largest)
  - Size 2: Subheadings
  - Size 3: Body text
  - Size 4: Small text/labels (smallest)
- **Only use 2 font weights**:
  - Semibold: For headings and emphasis
  - Regular: For body text and most UI elements
- **Common mistakes to avoid**:
  - Using more than 4 font sizes
  - Introducing additional font weights
  - Inconsistent size application

### Typography Implementation
- **Reference shadcn's typography primitives** for consistent text styling
- **Use monospace variant** for numerical data when appropriate
- **data-slot attribute**: Every shadcn/ui primitive now has a data-slot attribute for styling
- **Maintain hierarchy** using consistent sizing patterns

## 8pt Grid System

### Spacing Guidelines
- **All spacing values MUST be divisible by 8 or 4**:
  - ✅ DO: Use 8, 16, 24, 32, 40, 48, etc.
  - ❌ DON'T: Use 25, 11, 7, 13, etc.

- **Practical examples**:
  - Instead of 25px padding → Use 24px (divisible by 8)
  - Instead of 11px margin → Use 12px (divisible by 4)
  - Instead of 15px gap → Use 16px (divisible by 8)

- **Use Tailwind's spacing utilities**:
  - p-4 (16px), p-6 (24px), p-8 (32px)
  - m-2 (8px), m-4 (16px), m-6 (24px)
  - gap-2 (8px), gap-4 (16px), gap-8 (32px)

- **Why this matters**:
  - Creates visual harmony
  - Simplifies decision-making
  - Establishes predictable patterns

### Implementation
- **Tailwind v4 dynamic spacing**: Spacing utilities accept any value without arbitrary syntax
- **Consistent component spacing**: Group related elements with matching gap values
- **Check responsive behavior**: Ensure grid system holds at all breakpoints

## 60/30/10 Color Rule

### Color Distribution
- **60%**: neutral color (bg-background)
  - Usually white or light gray in light mode
  - Dark gray or black in dark mode
  - Used for primary backgrounds, cards, containers

- **30%**: complementary color (text-foreground)
  - Usually dark gray or black in light mode
  - Light gray or white in dark mode
  - Used for text, icons, subtle UI elements

- **10%**: accent color (brand color)
  - Your primary brand color (red, blue, etc.)
  - Used sparingly for call-to-action buttons, highlights, important indicators
  - Avoid overusing to prevent visual stress

### Common Mistakes
- ❌ Overusing accent colors creates visual stress
- ❌ Not enough contrast between background and text
- ❌ Too many competing accent colors (stick to one primary accent)

### Implementation with shadcn/ui
- **Background/foreground convention**: Each component uses the background/foreground pattern
- **CSS variables in globals.css**:
  ```css
  :root {
    --background: oklch(1 0 0);
    --foreground: oklch(0.145 0 0);
    --primary: oklch(0.205 0 0);
    --primary-foreground: oklch(0.985 0 0);
    /* Additional variables */
  }
  
  @theme {
    --color-background: var(--background);
    --color-foreground: var(--foreground);
    /* Register other variables */
  }
  ```
- **OKLCH color format**: More accessible colors, especially in dark mode
- **Reserve accent colors** for important elements that need attention

## Component Architecture

### shadcn/ui Component Structure
- **2-layered architecture**:
  1. Structure and behavior layer (Radix UI primitives)
  2. Style layer (Tailwind CSS)
- **Class Variance Authority (CVA)** for variant styling
- **data-slot attribute** for styling component parts

### Implementation
- **Install components individually** using CLI (updated for v4) or manual installation
- **Component customization**: Modify components directly as needed
- **Radix UI primitives**: Base components for accessibility and behavior
- **New-York style**: Default recommended style for new projects (deprecated "default" style)

## Visual Hierarchy

### Design Principles
- **Simplicity over flashiness**: Focus on clarity and usability
- **Emphasis on what matters**: Highlight important elements
- **Reduced cognitive load**: Use consistent terminology and patterns
- **Visual connection**: Connect related UI elements through consistent patterns

### Implementation
- **Use shadcn/ui Blocks** for common UI patterns
- **Maintain consistent spacing** between related elements
- **Align elements properly** within containers
- **Logical grouping** of related functionality

## Installation & Setup

### Project Setup
- **CLI initialization**:
  ```bash
  npx create-next-app@latest my-app
  cd my-app
  npx shadcn-ui@latest init
  ```
- **Manual setup**: Follow the guide at [Manual Installation](mdc:https://ui.shadcn.com/docs/installation/manual)
- **components.json configuration**:
  ```json
  {
    "style": "new-york",
    "rsc": true,
    "tailwind": {
      "config": "",
      "css": "app/globals.css",
      "baseColor": "neutral",
      "cssVariables": true
    },
    "aliases": {
      "components": "@/components",
      "utils": "@/lib/utils"
    }
  }
  ```

### Adding Components
- **Use the CLI**: `npx shadcn-ui@latest add button`
- **Install dependencies**: Required for each component
- **Find components**: [Component Reference](mdc:https://ui.shadcn.com/docs/components)

## Advanced Features

### Dark Mode
- **Updated dark mode colors** for better accessibility using OKLCH
- **Consistent contrast ratios** across light and dark themes
- **Custom variant**: `@custom-variant dark (&:is(.dark *))`

### Container Queries
- **Built-in support** without plugins
- **Responsive components** that adapt to their container size
- **@min-* and @max-* variants** for container query ranges

### Data Visualization
- **Chart components**: Use with consistent styling
- **Consistent color patterns**: Use chart-1 through chart-5 variables

## Experience Design

### Motion & Animation
- **Consider transitions** between screens and states
- **Animation purpose**: Enhance usability, not distract
- **Consistent motion patterns**: Similar elements should move similarly

### Implementation
- **Test experiences** across the entire flow
- **Design with animation in mind** from the beginning
- **Balance speed and smoothness** for optimal user experience

## Resources

- [shadcn/ui Documentation](mdc:https://ui.shadcn.com/docs)
- [Tailwind CSS v4 Documentation](mdc:https://tailwindcss.com/docs)
- [shadcn/ui GitHub Repository](mdc:https://github.com/shadcn/ui)
- [Tailwind v4 Upgrade Guide](mdc:https://tailwindcss.com/docs/upgrade-guide)
- [shadcn/ui v4 Demo](mdc:https://v4.shadcn.com/)
- [Figma Design System](mdc:https://www.figma.com/community/file/1203061493325953101/shadcn-ui-design-system)

## Code Review Checklist

### Core Design Principles
- [ ] Typography: Uses only 4 font sizes and 2 font weights (Semibold, Regular)
- [ ] Spacing: All spacing values are divisible by 8 or 4
- [ ] Colors: Follows 60/30/10 color distribution (60% neutral, 30% complementary, 10% accent)
- [ ] Structure: Elements are logically grouped with consistent spacing

### Technical Implementation
- [ ] Uses proper OKLCH color variables
- [ ] Leverages @theme directive for variables
- [ ] Components implement data-slot attribute properly
- [ ] Visual hierarchy is clear and consistent
- [ ] Components use Class Variance Authority for variants
- [ ] Dark mode implementation is consistent
- [ ] Accessibility standards are maintained (contrast, keyboard navigation, etc.)

### Common Issues to Flag
- [ ] Too many font sizes (more than 4)
- [ ] Inconsistent spacing values (not divisible by 8 or 4)
- [ ] Overuse of accent colors (exceeding 10%)
- [ ] Random or inconsistent margins/padding
- [ ] Insufficient contrast between text and background
- [ ] Unnecessary custom CSS when Tailwind utilities would suffice
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
  
  # Cursor MCP Configuration
  # Create the Cursor MCP configuration file with environment variable support
  home.activation.cursorMcpConfig = config.lib.dag.entryAfter ["writeBoundary"] ''
    CURSOR_MCP_PATH="$HOME/.cursor/mcp.json"
    
    # Create .cursor directory if it doesn't exist
    mkdir -p "$HOME/.cursor"
    
    # Source the .env file - check multiple locations
    ENV_FILES=(
        "/Users/angel/Projects/nix-project/.env"
        "$HOME/.config/nix-project/.env"
        "$HOME/.env"
        "./.env"
    )
    
    for env_file in "''${ENV_FILES[@]}"; do
        if [[ -f "$env_file" ]]; then
            set -a
            source "$env_file"
            set +a
            break
        fi
    done
    
    # Get environment variables with defaults
    TAVILY_API_KEY="''${TAVILY_API_KEY:-}"
    BRAVE_API_KEY="''${BRAVE_API_KEY:-}"
    KAGI_API_KEY="''${KAGI_API_KEY:-}"
    PERPLEXITY_API_KEY="''${PERPLEXITY_API_KEY:-}"
    JINA_AI_API_KEY="''${JINA_AI_API_KEY:-}"
    FIRECRAWL_API_KEY="''${FIRECRAWL_API_KEY:-}"
    
    # Create the Cursor MCP config content with environment variables
    cat > "$CURSOR_MCP_PATH" << EOF
{
  "mcpServers": {
    "filesystem": {
      "command": "${pkgs.nodejs_20}/bin/node",
      "args": [
        "${pkgs.nodejs_20}/bin/npm",
        "exec",
        "--",
        "@modelcontextprotocol/server-filesystem",
        "/Users/${config.home.username}",
        "/Users/${config.home.username}/Projects",
        "/Users/${config.home.username}/Documents"
      ]
    },
    "memory": {
      "command": "${pkgs.nodejs_20}/bin/node",
      "args": [
        "${pkgs.nodejs_20}/bin/npm",
        "exec",
        "--",
        "@modelcontextprotocol/server-memory"
      ]
    },
    "sequential-thinking": {
      "command": "${pkgs.nodejs_20}/bin/node",
      "args": [
        "${pkgs.nodejs_20}/bin/npm",
        "exec",
        "--",
        "@modelcontextprotocol/server-sequential-thinking"
      ]
    },
    "puppeteer": {
      "command": "${pkgs.nodejs_20}/bin/node",
      "args": [
        "${pkgs.nodejs_20}/bin/npm",
        "exec",
        "--",
        "@modelcontextprotocol/server-puppeteer"
      ]
    },
    "playwright": {
      "command": "${pkgs.nodejs_20}/bin/node",
      "args": [
        "${pkgs.nodejs_20}/bin/npm",
        "exec",
        "--",
        "@microsoft/mcp-server-playwright"
      ]
    },
    "mcp-omnisearch": {
      "command": "${pkgs.nodejs_20}/bin/node",
      "args": [
        "${pkgs.nodejs_20}/bin/npm",
        "exec",
        "--",
        "mcp-omnisearch"
      ],
      "env": {
        "TAVILY_API_KEY": "$TAVILY_API_KEY",
        "BRAVE_API_KEY": "$BRAVE_API_KEY",
        "KAGI_API_KEY": "$KAGI_API_KEY",
        "PERPLEXITY_API_KEY": "$PERPLEXITY_API_KEY",
        "JINA_AI_API_KEY": "$JINA_AI_API_KEY",
        "FIRECRAWL_API_KEY": "$FIRECRAWL_API_KEY"
      }
    }
  }
}
EOF
    
    # Make the file writable
    chmod 644 "$CURSOR_MCP_PATH"
  '';
}
