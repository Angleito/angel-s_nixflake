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
    
    # Blockchain tools
    # sui-cli      # Temporarily disabled due to build issues
    # walrus-cli   # Temporarily disabled due to build issues
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
      
      # Claude CLI
      claude = "/Users/angel/.npm-global/bin/claude";
    };
    
    initContent = ''
      # Add local bin to PATH
      export PATH="$HOME/.local/bin:$PATH"
      
      # Function to properly load .env files
      load_env_file() {
        if [ -f "$1" ]; then
          set -a  # automatically export all variables
          source "$1"
          set +a
          return 0
        fi
        return 1
      }
      
      # Try loading .env files in order of priority
      load_env_file "/Users/angel/Projects/nix-project/.env" || \
      load_env_file "$HOME/Projects/nix-project/.env" || \
      load_env_file "./.env" || \
      load_env_file "$HOME/.env"
      
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
    "$HOME/.npm-global/bin"
  ];

  
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
      
      # Always add omnisearch server with available API keys
      finalConfig = baseConfig // {
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
      };
      
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
    
    # Create blockchain-specific command files
    cat > "$HOME/.claude/commands/sei.md" << 'EOF'
# SEI Blockchain Guide for AI Agents

## Overview
SEI is a high-performance, parallelized EVM blockchain designed for speed, scalability, and AI integration. It combines the best of Solana's performance with Ethereum's development ecosystem, making it the first fully parallelized EVM blockchain.

## Key Features

### Performance Characteristics
- **Block Finality**: 390ms (fastest chain in existence)
- **Transaction Speed**: 45+ TPS consistently, with capability for 28,300 batched transactions per second
- **Throughput**: 5 gigagas per second (50x improvement over standard chains)
- **Gas Efficiency**: Significantly lower transaction costs than Ethereum

### Technical Architecture
- **Parallelized EVM**: Optimistic parallelization without requiring developers to define dependencies
- **SeiDB**: Optimized storage layer preventing state bloat and improving performance
- **Twin Turbo Consensus**: Hybrid consensus mechanism separating data availability from finalization
- **Interoperability**: Seamless interaction between EVM and CosmWasm smart contracts

## SEI v2 - The Parallelized EVM

### EVM Compatibility
- **Backwards Compatible**: Deploy existing Ethereum smart contracts with no code changes
- **Bytecode Compatible**: Full Geth integration for processing Ethereum transactions
- **Familiar Tooling**: Use MetaMask, Hardhat, Foundry, Remix without modification
- **Standard RPC**: Identical RPC interface to Ethereum for seamless integration

### Unique Capabilities
- **Optimistic Parallelization**: Automatically runs transactions in parallel, resolving conflicts deterministically
- **Multi-VM Support**: Native support for both EVM and CosmWasm smart contracts
- **Cross-Chain Features**: Built-in IBC protocol support for interoperability

## AI Integration Through MCP (Model Context Protocol)

### What is MCP Integration?
SEI has integrated with Anthropic's Model Context Protocol, enabling AI agents to:
- **Query blockchain state** in real-time
- **Execute transactions** through standardized interfaces
- **Interact with DeFi protocols** across multiple chains
- **Verify actions** cryptographically on-chain

### Key MCP Capabilities for AI Agents

1. **Standardized Blockchain Access**
   - Query network state, manage portfolios, execute transactions
   - Sub-400ms finality enables real-time AI applications
   - No custom blockchain APIs required

2. **Verifiable Agent Actions**
   - Cryptographically prove blockchain interactions
   - Share verified context between agents
   - Build trust through verifiable on-chain history

3. **Multi-Protocol Operations**
   - Execute complex cross-protocol trades
   - Unified MCP interfaces for multiple DeFi protocols
   - Parallel execution for efficient multi-protocol strategies

### Setting Up SEI MCP Kit
- Compatible with Cursor, Windsurf, and Claude
- Easy deployment through app settings
- Documentation: https://docs.sei.io/learn/mcp-server

## Development Environment

### Network Information
- **Mainnet**: 
  - Chain ID: 531
  - RPC: `https://evm-rpc.sei-apis.com`
  - Currency: SEI
- **Testnet**:
  - Chain ID: 713715
  - RPC: `https://evm-rpc-testnet.sei-apis.com`
  - Faucet: Available through Sei docs

### Smart Contract Development
- **Languages**: Solidity and Vyper fully supported
- **Tools**: Hardhat, Foundry, Remix, Truffle
- **Verification**: Contract verification available on block explorers

### Key Differences from Ethereum
- **State Storage**: Uses IAVL tree instead of Patricia Merkle Tree
- **Mixed Transactions**: Non-EVM transactions can update EVM-accessible state
- **Gas Token**: Uses SEI instead of ETH
- **Precompiles**: Custom precompiles for Cosmos features (staking, governance, etc.)

## AI Agent Use Cases

### Portfolio Management
- **Real-time monitoring** of token balances and positions
- **Automated rebalancing** across multiple DeFi protocols
- **Risk management** through programmatic position sizing

### DeFi Automation
- **Cross-protocol arbitrage** opportunities
- **Yield farming optimization** across multiple platforms
- **Liquidity provision** management

### On-Chain Analytics
- **Transaction pattern analysis** for trading insights
- **Market data aggregation** from multiple sources
- **Predictive modeling** using on-chain data

### Agent Coordination
- **Multi-agent systems** for complex trading strategies
- **Decentralized autonomous organizations** (DAOs) management
- **Collaborative decision-making** with verifiable outcomes

## Technical Specifications for AI Agents

### Transaction Types
- **EVM Transactions**: Standard Ethereum-compatible transactions
- **Cosmos Transactions**: Native Cosmos SDK transactions
- **Interoperability**: Cross-VM transactions between EVM and CosmWasm

### State Access Patterns
- **Fast reads**: Sub-second state queries
- **Batch operations**: Efficient multi-transaction processing
- **Historical data**: Full transaction history access

### Gas and Fees
- **Predictable costs**: Stable gas prices for AI automation
- **Bulk operations**: Efficient batching for multiple transactions
- **Account abstraction**: EIP-7702 support for advanced wallet features

## Future Developments

### Sei Giga Upgrade
- **5 gigagas throughput** with 400ms finality
- **Autobahn consensus** for improved geographic distribution
- **Enhanced parallel processing** capabilities

### AI-Specific Features
- **Agentic wallets** with session keys and gas abstraction
- **Decentralized Agent Swarm Network** (DASN) for multi-agent coordination
- **Cross-chain agent collaboration** protocols

## Best Practices for AI Agents

### Security Considerations
- **Rate limiting**: Implement appropriate request throttling
- **Error handling**: Robust error recovery mechanisms
- **Key management**: Secure private key storage and rotation

### Performance Optimization
- **Batch transactions**: Group related operations
- **Parallel execution**: Leverage SEI's parallelization capabilities
- **State caching**: Cache frequently accessed data

### Monitoring and Maintenance
- **Health checks**: Regular system status monitoring
- **Performance metrics**: Track transaction success rates and timing
- **Alerting**: Automated notifications for system issues

## Resources and Documentation

### Official Documentation
- **Main docs**: https://docs.sei.io/
- **EVM Guide**: https://docs.sei.io/evm/
- **MCP Server**: https://docs.sei.io/learn/mcp-server

### Developer Tools
- **Block Explorer**: https://seitrace.com/
- **Bridge**: https://app.sei.io/bridge
- **Faucet**: Available through Sei docs
- **GitHub**: https://github.com/sei-protocol

### Community Resources
- **Discord**: https://discord.com/invite/sei
- **Telegram**: https://t.me/seinetwork
- **Developers Chat**: https://t.me/+KZdhZ1eE-G01NmZk
- **Blog**: https://blog.sei.io/

## Conclusion

SEI blockchain represents a significant advancement in blockchain technology, combining high performance with AI-native features. Its parallelized EVM, sub-second finality, and native MCP integration make it ideal for AI agents requiring fast, reliable, and cost-effective blockchain interactions. The platform's dual-VM architecture (EVM + CosmWasm) and extensive tooling ecosystem provide flexibility for various AI applications, from simple portfolio management to complex multi-agent coordination systems.

For AI agents, SEI offers:
- **Speed**: 390ms finality for real-time applications
- **Scalability**: Parallel transaction processing
- **Compatibility**: Full Ethereum tooling support
- **Cost-effectiveness**: Lower gas fees than Ethereum
- **AI Integration**: Native MCP protocol support
- **Interoperability**: Cross-chain capabilities through IBC

This makes SEI an excellent choice for AI agents requiring robust, fast, and cost-effective blockchain interactions.
EOF
    
    chmod 644 "$HOME/.claude/commands/sei.md"
    
    # Create Sui blockchain command file
    cat > "$HOME/.claude/commands/sui.md" << 'EOF'
# Sui Blockchain and Move Language Guide

## Overview

**Sui** is a next-generation blockchain platform designed for high throughput, low latency, and an asset-oriented programming model. Built by Mysten Labs, Sui leverages the **Move** programming language to provide developers with a secure, scalable, and intuitive platform for building decentralized applications.

**Move** is a secure, platform-agnostic programming language originally developed for the Diem blockchain. On Sui, Move has been enhanced with unique features that make it ideal for building smart contracts and managing digital assets.

## What is Sui?

Sui is a Layer 1 blockchain that introduces several breakthrough innovations:

### Key Features

1. **Object-Centric Data Model**: Unlike traditional blockchains that use account-based models, Sui treats everything as objects with unique identifiers
2. **Parallel Transaction Processing**: Transactions that don't conflict can be processed simultaneously, achieving up to 297,000 TPS in testing
3. **Low Latency**: Mysticeti consensus protocol provides extremely low end-to-end latency
4. **Built-in Security**: Move's type system prevents common vulnerabilities like double-spending and resource leaks

### Technical Advantages

- **Horizontal Scaling**: Parallel execution of non-conflicting transactions
- **Asset Safety**: Linear type system ensures digital assets cannot be duplicated or accidentally destroyed
- **Developer Experience**: Intuitive object model that mirrors real-world contract structures
- **Gas Efficiency**: Optimized execution model reduces transaction costs

## What is Move Language?

Move is a resource-oriented programming language designed specifically for blockchain development. On Sui, Move has been enhanced to support the object-centric model.

### Core Concepts

#### 1. **Objects and Abilities**
Move uses four key abilities to define how types behave:

- `copy` - Value can be copied/cloned
- `drop` - Value can be dropped at the end of scope  
- `key` - Value can be used as a key for global storage (makes it an object)
- `store` - Value can be stored inside global storage

#### 2. **Object Model**
Every object in Sui has:
- **Unique ID (UID)**: Globally unique identifier
- **Ownership**: Can be owned by an address, another object, or shared
- **Type**: Defined by Move struct with `key` ability

#### 3. **Resource Safety**
Move's linear type system ensures:
- Resources cannot be duplicated
- Resources cannot be accidentally lost
- Ownership transfers are explicit and safe

## Move on Sui: Key Differences

Sui's implementation of Move includes several enhancements:

### 1. **Object-Centric Global Storage**
- No traditional global storage operations (`move_to`, `move_from`)
- Objects are stored with unique identifiers
- Transaction inputs are explicitly specified upfront

### 2. **Enhanced Address System**
- 32-byte addresses (vs 16-byte in original Move)
- Addresses represent both objects and accounts
- Each object contains `id: UID` field

### 3. **Module Initializers**
- Special `init` function runs once when module is published
- Used for creating singleton objects and initial setup

### 4. **Entry Functions**
- Functions marked with `entry` can be called in Programmable Transaction Blocks
- Used for public APIs and preventing composition in certain contexts

## Code Examples

### Hello World Smart Contract

```move
module hello_world::hello_world {
    use std::string;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    // Define an object with key and store abilities
    struct Hello has key, store {
        id: UID,
        text: string::String
    }

    // Entry function to create and transfer a Hello object
    public entry fun mint_hello_world(ctx: &mut TxContext) {
        let hello_object = Hello {
            id: object::new(ctx),
            text: string::utf8(b"Hello World!")
        };
        
        // Transfer the object to the transaction sender
        transfer::public_transfer(hello_object, tx_context::sender(ctx));
    }
}
```

### Basic Token Contract

```move
module my_token::coin {
    use std::option;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    /// The type identifier of coin
    struct COIN has drop {}

    /// Module initializer to create the currency
    fun init(witness: COIN, ctx: &mut TxContext) {
        let (treasury, metadata) = coin::create_currency(
            witness,
            9, // decimals
            b"TOKEN", // symbol
            b"My Token", // name
            b"Description of my token", // description
            option::none(), // icon url
            ctx
        );
        
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury, tx_context::sender(ctx));
    }

    /// Mint new tokens
    public entry fun mint(
        treasury_cap: &mut TreasuryCap<COIN>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        coin::mint_and_transfer(treasury_cap, amount, recipient, ctx);
    }
}
```

### Object with Dynamic Fields

```move
module dynamic_fields::example {
    use sui::dynamic_field as df;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct Container has key {
        id: UID,
    }

    struct Key has copy, drop, store {
        name: vector<u8>
    }

    /// Create a new container
    public entry fun create_container(ctx: &mut TxContext) {
        let container = Container {
            id: object::new(ctx),
        };
        transfer::public_transfer(container, tx_context::sender(ctx));
    }

    /// Add a dynamic field to the container
    public entry fun add_field(
        container: &mut Container,
        key_name: vector<u8>,
        value: u64,
    ) {
        let key = Key { name: key_name };
        df::add(&mut container.id, key, value);
    }

    /// Get a dynamic field value
    public fun get_field(container: &Container, key_name: vector<u8>): &u64 {
        let key = Key { name: key_name };
        df::borrow(&container.id, key)
    }
}
```

## Programmable Transaction Blocks (PTBs)

PTBs are a unique feature of Sui that allows composing multiple function calls into a single transaction:

```typescript
// Example using TypeScript SDK
import { TransactionBlock } from '@mysten/sui.js';

const txb = new TransactionBlock();

// Call multiple functions in sequence
const coin1 = txb.moveCall({
    target: `\$\{PACKAGE_ID}::coin::mint`,
    arguments: [txb.object(treasuryCapId), txb.pure(1000)],
});

const coin2 = txb.moveCall({
    target: `\$\{PACKAGE_ID}::coin::mint`, 
    arguments: [txb.object(treasuryCapId), txb.pure(2000)],
});

// Merge coins
txb.moveCall({
    target: `0x2::coin::join`,
    arguments: [coin1, coin2],
});
```

## Development Workflow

### 1. **Setting Up Development Environment**

```bash
# Install Sui CLI
cargo install --locked --git https://github.com/MystenLabs/sui.git --branch devnet sui

# Create new project
sui move new my_project

# Build project
sui move build

# Test project
sui move test
```

### 2. **Project Structure**

```
my_project/
├── Move.toml          # Project configuration
├── sources/           # Move source files
│   └── example.move
└── tests/            # Test files
    └── example_test.move
```

### 3. **Publishing to Network**

```bash
# Publish to devnet
sui client publish --gas-budget 10000000 .

# Publish to testnet
sui client publish --gas-budget 10000000 . --network testnet
```

## Common Use Cases

### 1. **DeFi Applications**
- Decentralized exchanges with atomic swaps
- Lending protocols with collateral management
- Yield farming with composable strategies

### 2. **Gaming**
- In-game asset management
- Trading card games
- Virtual world economies

### 3. **NFTs and Digital Assets**
- Unique collectibles with rich metadata
- Fractionalized ownership
- Royalty mechanisms

### 4. **Enterprise Applications**
- Supply chain tracking
- Identity management
- Document verification

## Best Practices

### 1. **Security Considerations**
- Always use abilities (`key`, `store`, `copy`, `drop`) appropriately
- Validate all function parameters
- Use proper access controls
- Test thoroughly before mainnet deployment

### 2. **Gas Optimization**
- Use PTBs for batch operations
- Minimize storage operations
- Optimize data structures
- Use shared objects wisely

### 3. **Code Organization**
- Separate concerns into different modules
- Use meaningful naming conventions
- Add comprehensive documentation
- Implement proper error handling

## Resources and Learning Materials

### Official Documentation
- [Sui Documentation](https://docs.sui.io/) - Complete developer guide
- [Move Book](https://move-book.com/) - Comprehensive Move language guide
- [Sui Move Examples](https://docs.sui.io/guides/developer/app-examples) - Code examples and patterns

### Development Tools
- [Sui CLI](https://docs.sui.io/references/cli) - Command-line development tools
- [Sui TypeScript SDK](https://sdk.docs.sui.io/typescript) - Frontend integration
- [Sui Explorer](https://suiexplorer.com/) - Blockchain explorer
- [Move Studio](https://www.movestudio.dev/) - Web-based IDE

### Learning Resources
- [Sui Foundation Course](https://github.com/sui-foundation/sui-move-intro-course) - Structured learning path
- [Move by Example](https://examples.sui.io/) - Component-by-component examples
- [Sui Developer Forum](https://forums.sui.io/) - Community support
- [Sui University](https://sui.io/university) - Academic partnerships

### Community and Support
- [Discord](https://discord.gg/sui) - Developer community
- [GitHub](https://github.com/MystenLabs/sui) - Source code and issues
- [Twitter](https://twitter.com/SuiNetwork) - News and updates
- [Engineering Office Hours](https://docs.google.com/forms/d/e/1FAIpQLSdWPf0H-t-QWV0Ik_5o86mKFlVNFsu_r5fyDxIL9BW_oSxpwA/viewform) - Direct support from core team

## Common Commands for Claude Code

When working with Sui projects, these commands will be frequently used:

```bash
# Initialize new project
sui move new <project_name>

# Build and check for errors
sui move build

# Run tests
sui move test

# Deploy to network
sui client publish --gas-budget 10000000 .

# Check active network
sui client active-env

# Switch networks
sui client switch --env devnet|testnet|mainnet

# Check gas coins
sui client gas

# Check objects owned by address
sui client objects <address>

# Execute a function
sui client call --function <function_name> --module <module_name> --package <package_id>
```

## Troubleshooting Common Issues

### 1. **Build Errors**
- Check Move.toml dependencies
- Verify import statements
- Ensure proper module structure

### 2. **Gas Issues**
- Increase gas budget for complex operations
- Check network connection
- Verify sufficient balance

### 3. **Object Ownership**
- Understand object ownership model
- Use correct transfer functions
- Check object IDs and addresses

This guide provides a comprehensive foundation for understanding and working with Sui blockchain and Move language. The object-centric model, enhanced security features, and developer-friendly tools make Sui an excellent choice for building next-generation decentralized applications.
EOF
    
    chmod 644 "$HOME/.claude/commands/sui.md"
    
    # Create Walrus storage command file
    cat > "$HOME/.claude/commands/walrus.md" << 'EOF'
# Walrus Storage Protocol on Sui Blockchain

## Overview

Walrus is a decentralized storage and data availability protocol built on the Sui blockchain, designed specifically for efficient, scalable, and secure storage of large binary files (blobs) such as multimedia content, datasets, and application assets. It serves as both a storage network and an application development platform, enabling developers to store, read, manage, and program large data files with blockchain-level security and availability.

## Key Features

### 1. Decentralized Storage Architecture
- **Horizontal Scaling**: Scales to hundreds or thousands of networked decentralized storage nodes
- **Byzantine Fault Tolerance**: Ensures high availability and reliability even with malicious or failed nodes
- **Cost-Effective**: Uses advanced erasure coding to maintain storage costs at approximately 5x the size of stored blobs

### 2. Integration with Sui Blockchain
- **Move Programming Language**: Fully integrated with Sui's Move language for smart contract interactions
- **Sui Objects**: Each stored blob becomes a Sui object, enabling on-chain programmability
- **Metadata on Sui**: Storage metadata and proofs of availability are stored on Sui blockchain

### 3. RedStuff Erasure Coding
- **Two-Dimensional Encoding**: Innovative algorithm that shards files efficiently
- **Distributed Storage**: Breaks data into slivers distributed across peer-to-peer storage nodes
- **Resilient Recovery**: Enables data recovery even when some nodes are offline

### 4. Programmable Storage
- **Storage as Asset**: Storage capacity can be tokenized and used as programmable assets
- **Smart Contract Integration**: Direct interaction with stored data through Move smart contracts
- **Cross-Chain Compatibility**: While metadata lives on Sui, storage can be accessed by other blockchains

## Architecture Components

### Core Components
1. **Storage Nodes**: Decentralized network of nodes that store data slivers
2. **Aggregators**: Collect and deliver data through CDN or read cache
3. **Publishers**: Encode and store data securely
4. **Sui Integration**: Handles coordination, attestation, and payments

### Token Economics
- **WAL Token**: Native token for payments, staking, and governance
- **FROST**: Subdivision of WAL (1 WAL = 1 billion FROST)
- **Delegated Proof of Stake**: Storage nodes stake WAL to participate in the network

## How AI Coding Assistants Can Use Walrus

### 1. Installation and Setup

```bash
# Install Walrus CLI
curl -sSf https://install.wal.app | sh

# Or install via Cargo
cargo install --git https://github.com/MystenLabs/walrus --branch mainnet walrus-service --locked

# Generate a new Sui wallet for Walrus
walrus generate-sui-wallet --network mainnet
```

### 2. Configuration

Create a configuration file at `~/.config/walrus/client_config.yaml`:

```yaml
contexts:
  mainnet:
    system_object: 0x2134d52768ea07e8c43570ef975eb3e4c27a39fa6396bef985b5abc58d03ddd2
    staking_object: 0x10b9d30c28448939ce6c4d6c6e0ffce4a7f8a4ada8248bdad09ef8b70e4a3904
    subsidies_object: 0xb606eb177899edc2130c93bf65985af7ec959a2755dc126c953755e59324209e
    wallet_config:
      active_env: mainnet
    rpc_urls:
      - https://fullnode.mainnet.sui.io:443
default_context: mainnet
```

### 3. Basic Operations

#### Store Files
```bash
# Store a new blob
walrus store FILE_PATH

# Store with custom duration (3 epochs)
walrus store FILE_PATH --epochs 3

# Store deletable blob
walrus store FILE_PATH --deletable

# Force store even if blob exists
walrus store FILE_PATH --force
```

#### Read Files
```bash
# Read blob to stdout
walrus read BLOB_ID

# Read blob to file
walrus read BLOB_ID --out FILE_PATH

# List all blobs for current wallet
walrus list-blobs

# List including expired blobs
walrus list-blobs --include-expired
```

#### Blob Management
```bash
# Get blob ID from file
walrus blob-id FILE_PATH

# Check blob status
walrus blob-status --blob-id BLOB_ID

# Delete blob (only if created with --deletable)
walrus delete --blob-id BLOB_ID
```

### 4. System Information
```bash
# Get Walrus system info
walrus info

# Get detailed developer info
walrus info --dev
```

## Walrus Sites: Decentralized Website Hosting

### Overview
Walrus Sites are decentralized websites built using Walrus storage and the Sui blockchain. They enable truly serverless, censorship-resistant web hosting where no central authority controls the content. Only the site owner has control over updates and content management.

### Key Features

#### 1. Decentralized Architecture
- **No Central Servers**: Files stored on Walrus, metadata on Sui blockchain
- **Censorship Resistant**: No single point of failure or control
- **Tamper-Proof**: Immutable storage with cryptographic guarantees
- **High Availability**: Accessible as long as Walrus network is operational

#### 2. Smart Contract Integration
- **Sui Objects**: Each site is represented as a Sui object with ownership
- **Programmable**: Integration with Move smart contracts for dynamic functionality
- **NFT Integration**: Sites can be linked to NFTs for exclusive content
- **Transferable Ownership**: Sites can be transferred between Sui addresses

#### 3. Portal Access
- **Multiple Portals**: Access through various portal implementations
- **Public Portal**: [wal.app](https://wal.app) for public access
- **Self-Hosted**: Run your own portal for complete control
- **Domain Resolution**: Human-readable domains via SuiNS

### Installation and Setup

#### Prerequisites
- Walrus CLI installed and configured
- Sui wallet with SUI and WAL tokens
- Site-builder tool for deployment

#### Install Site-Builder
```bash
# Download site-builder binary for your system
# Ubuntu x86_64
curl https://storage.googleapis.com/mysten-walrus-binaries/site-builder-mainnet-latest-ubuntu-x86_64 -o site-builder
chmod +x site-builder
mv site-builder /usr/local/bin/

# macOS arm64
curl https://storage.googleapis.com/mysten-walrus-binaries/site-builder-mainnet-latest-macos-arm64 -o site-builder
chmod +x site-builder
mv site-builder /usr/local/bin/
```

#### Configuration
Create `~/.config/walrus/sites-config.yaml`:
```yaml
contexts:
  mainnet:
    package: 0x6fb382ac9a32d0e351506e70b13d0a75abacb55c7c0d41b6b2b5b84f8e7c8b1c
    staking_object: 0x10b9d30c28448939ce6c4d6c6e0ffce4a7f8a4ada8248bdad09ef8b70e4a3904
    wallet_config:
      active_env: mainnet
    rpc_urls:
      - https://fullnode.mainnet.sui.io:443
default_context: mainnet
```

### Publishing Your First Walrus Site

#### Step 1: Prepare Your Site
```bash
# Your site directory must contain index.html
mkdir my-site
cd my-site
echo '<html><body><h1>My Walrus Site</h1></body></html>' > index.html
```

#### Step 2: Publish to Walrus
```bash
# Publish new site with 100 epoch duration
site-builder publish ./my-site --epochs 100

# Example output:
# Created new site: My Walrus Site
# New site object ID: 0x123abc...
# Browse the site at: https://abc123.wal.app
```

#### Step 3: Update Your Site
```bash
# Make changes to your site
echo '<html><body><h1>Updated Walrus Site</h1></body></html>' > index.html

# Update existing site
site-builder update --epochs 100 ./my-site 0x123abc...
```

### Domain Management with SuiNS

#### Register a Domain
1. Visit [https://suins.io](https://suins.io)
2. Purchase a domain name (e.g., "mysite")
3. Link domain to your Walrus Site object ID

#### Access Your Site
- **Object ID URL**: `https://[base36-object-id].wal.app`
- **SuiNS Domain**: `https://mysite-wal.wal.app`

### Advanced Features

#### File Browser Mode
```bash
# Create file browser instead of website
site-builder publish ./assets --list-directory --epochs 100
```

#### Custom Headers and Routing
Create `_headers` file in your site directory:
```
/*
  Cache-Control: max-age=31536000
  Content-Security-Policy: default-src 'self'

/api/*
  Access-Control-Allow-Origin: *
```

#### Deletable Resources
```bash
# Create deletable site (can be removed before expiration)
site-builder publish ./my-site --deletable --epochs 100
```

### GitHub Actions Integration

#### Automated Deployment
Create `.github/workflows/deploy-walrus-site.yml`:
```yaml
name: Deploy to Walrus Sites

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy to Walrus Sites
        uses: MystenLabs/walrus-sites/.github/actions/deploy@main
        with:
          site-directory: ./dist
          walrus-config: $''${{ secrets.WALRUS_CONFIG }}
          sui-keystore: $''${{ secrets.SUI_KEYSTORE }}
          epochs: 100
```

#### Required Secrets
- `WALRUS_CONFIG`: Your Walrus configuration
- `SUI_KEYSTORE`: Your Sui wallet keystore

### Site-Builder Commands Reference

| Command | Description | Example |
|---------|-------------|---------|
| `publish` | Deploy new site | `site-builder publish ./site --epochs 100` |
| `update` | Update existing site | `site-builder update ./site 0x123abc...` |
| `sitemap` | View site resources | `site-builder sitemap 0x123abc...` |
| `convert` | Get Base36 subdomain | `site-builder convert 0x123abc...` |

### Portal Development

#### Server Portal (Production)
```bash
# Clone portal code
git clone https://github.com/MystenLabs/walrus-sites.git
cd walrus-sites/portal/server

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your settings

# Start server
npm start
```

#### Docker Deployment
```bash
# Build portal container
docker build -f portal/docker/server/Dockerfile --target release --tag walrus-portal .

# Run portal
docker run -p 3000:3000 walrus-portal
```

### Use Cases for AI Coding Assistants

#### 1. Decentralized Web Applications
- **Frontend Hosting**: Deploy React, Vue, or Angular apps
- **Static Site Generators**: Host Jekyll, Hugo, or Gatsby sites
- **Documentation Sites**: Decentralized documentation portals
- **Portfolio Sites**: Personal or professional portfolios

#### 2. Content Publishing
- **Blogs**: Censorship-resistant publishing platforms
- **Media Galleries**: Decentralized image and video galleries
- **Educational Content**: Learning platforms and tutorials
- **News Sites**: Independent journalism and reporting

#### 3. Development Tools
- **Project Showcases**: Demonstrate web applications
- **API Documentation**: Host OpenAPI/Swagger documentation
- **Component Libraries**: Showcase design systems
- **Demo Applications**: Interactive product demonstrations

#### 4. Data Science and AI Applications
- **Large dataset management and versioning**
- **Model weights and training data storage**
- **Result caching for expensive computations**
- **Interactive data visualizations**

#### 5. Backup and Archival
- **Long-term data preservation**
- **Distributed backup systems**
- **Immutable record keeping**
- **Historical data archives**

### Best Practices for Walrus Sites

#### 1. Site Structure
- **Always include `index.html`** as the entry point
- **Organize assets** in logical directory structure
- **Use relative paths** for internal links
- **Optimize file sizes** to reduce storage costs

#### 2. Content Security
- **All content is public** - don't store sensitive information
- **Use HTTPS** when accessing through portals
- **Implement proper CSP headers** for security
- **Consider content immutability** - updates create new versions

#### 3. Performance Optimization
- **Compress images** and optimize media files
- **Minify CSS/JavaScript** before publishing
- **Use efficient file formats** (WebP, AVIF for images)
- **Implement caching strategies** via headers

#### 4. Cost Management
- **Choose appropriate epoch duration** based on content lifecycle
- **Use deletable resources** for temporary content
- **Monitor storage costs** and optimize regularly
- **Consider content deduplication** across updates

### Examples and Templates

#### Simple HTML Site
```html
<!DOCTYPE html>
<html>
<head>
    <title>My Walrus Site</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to My Walrus Site</h1>
        <p>This site is hosted on decentralized storage!</p>
    </div>
</body>
</html>
```

#### React App Deployment
```bash
# Build React app
npm run build

# Deploy to Walrus Sites
site-builder publish ./build --epochs 100
```

#### NFT Gallery Example
```javascript
// Connect to Sui wallet and display NFTs
import { SuiClient } from '@mysten/sui.js';

const client = new SuiClient({ url: 'https://fullnode.mainnet.sui.io:443' });

async function displayNFTs(address) {
    const objects = await client.getOwnedObjects({
        owner: address,
        filter: { StructType: 'NFT' }
    });
    
    // Render NFTs in gallery
    objects.data.forEach(obj => {
        // Display NFT metadata from Walrus
    });
}
```

### Troubleshooting Common Issues

#### Site Not Loading
1. **Check object ID**: Verify correct site object ID in URL
2. **Verify portal**: Try different portal (wal.app, localhost)
3. **Check epochs**: Ensure site hasn't expired
4. **Network issues**: Verify Walrus network status

#### Update Failures
1. **Wallet ownership**: Ensure you own the site object
2. **Insufficient funds**: Check SUI and WAL balances
3. **Network connectivity**: Verify Sui RPC access
4. **File permissions**: Check read access to site directory

#### Domain Resolution
1. **SuiNS configuration**: Verify domain points to correct object ID
2. **DNS propagation**: Allow time for DNS updates
3. **Portal support**: Ensure portal supports SuiNS resolution
4. **Subdomain format**: Use correct format (domain-wal.portal.tld)

## Smart Contract Integration Examples

### Move Smart Contract Example
```move
module walrus_integration::blob_manager {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;
    
    struct BlobReference has key {
        id: UID,
        blob_id: vector<u8>,
        owner: address,
        description: vector<u8>,
    }
    
    public fun store_blob_reference(
        blob_id: vector<u8>,
        description: vector<u8>,
        ctx: &mut TxContext
    ) {
        let blob_ref = BlobReference {
            id: object::new(ctx),
            blob_id,
            owner: tx_context::sender(ctx),
            description,
        };
        transfer::transfer(blob_ref, tx_context::sender(ctx));
    }
}
```

### JavaScript Integration Example
```javascript
import { WalrusClient } from '@mysten/walrus';

// Initialize client
const client = new WalrusClient({
  network: 'mainnet',
  suiNetwork: 'mainnet'
});

// Store blob
async function storeFile(filePath) {
  const result = await client.store(filePath);
  console.log('Blob ID:', result.blobId);
  return result.blobId;
}

// Read blob
async function readFile(blobId) {
  const data = await client.read(blobId);
  return data;
}
```

## Best Practices for AI Coding Assistants

### 1. Data Privacy
- **Public Storage**: All blobs stored in Walrus are public and discoverable
- **Encryption**: Encrypt sensitive data before storing
- **Access Control**: Use Move smart contracts for access management

### 2. Cost Optimization
- **Epochs Planning**: Choose appropriate storage duration
- **Blob Deduplication**: Check if blob exists before storing
- **Subsidies**: Use subsidies contracts to reduce costs

### 3. Error Handling
- **Timeout Configuration**: Set appropriate timeouts for operations
- **Retry Logic**: Implement retry mechanisms for network failures
- **Status Monitoring**: Regular blob status checks

### 4. Performance Optimization
- **Concurrent Operations**: Use parallel operations for batch processing
- **Caching**: Implement local caching for frequently accessed data
- **Network Configuration**: Tune networking parameters for your use case

## Network Information

### Available Networks
- **Mainnet**: Production network with real WAL tokens
- **Testnet**: Development network for testing
- **Devnet**: Early development and experimental features

### Required Tokens
- **SUI**: For transaction fees on Sui blockchain
- **WAL**: For storage payments and staking

## Development Resources

### Documentation
- [Official Walrus Documentation](https://docs.wal.app/)
- [Sui Documentation](https://docs.sui.io/)
- [Move Language Guide](https://sui.io/move)

### Tools and SDKs
- **Walrus CLI**: Command-line interface for all operations
- **REST API**: HTTP/JSON API for web integration
- **SDKs**: Available for various programming languages
- **Walrus Explorer**: [walruscan.com](https://walruscan.com/) for network monitoring

### Community Resources
- [GitHub Repository](https://github.com/MystenLabs/walrus)
- [Sui Developer Forum](https://forums.sui.io/)
- [Walrus CLI Cheat Sheet](https://gist.github.com/bartosian/dcfed3a1cb09c3263222255f8354e2df)

## Common Commands Reference

| Operation | Command | Description |
|-----------|---------|-------------|
| Store | `walrus store FILE` | Store a new blob |
| Read | `walrus read BLOB_ID` | Read a blob by ID |
| List | `walrus list-blobs` | List all blobs |
| Status | `walrus blob-status --blob-id ID` | Check blob status |
| Delete | `walrus delete --blob-id ID` | Delete blob (if deletable) |
| Info | `walrus info` | System information |
| Stake | `walrus stake --node-id ID` | Stake with storage node |

## Troubleshooting

### Common Issues
1. **Insufficient WAL tokens**: Ensure wallet has enough WAL for storage
2. **Network connectivity**: Check RPC URLs and internet connection
3. **Configuration errors**: Verify client_config.yaml is correct
4. **Blob not found**: Blob may have expired or been deleted

### Debug Commands
```bash
# Check wallet balance
sui client gas

# Verify network connection
walrus info

# Check blob existence
walrus blob-status --blob-id BLOB_ID

# List available contexts
walrus --help
```

This comprehensive guide provides AI coding assistants with everything needed to understand and effectively use Walrus storage protocol for decentralized data storage and management on the Sui blockchain.
EOF
    
    chmod 644 "$HOME/.claude/commands/walrus.md"
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
