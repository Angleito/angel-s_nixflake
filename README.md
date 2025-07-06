# Angel's Pure Nix Darwin Configuration

A complete macOS system configuration using **pure Nix architecture** with modular design. This setup eliminates shell script complexity and provides declarative package management for your entire development environment with a single command.

## Privacy Safeguards

This configuration implements several privacy safeguards to protect your personal information:

### 1. Environment Variables are Git-Ignored
- The `.env` file containing personal identity information is explicitly ignored by Git (see `.gitignore`)
- This ensures your personal details (name, email, GitHub username) are never committed to version control
- Each user must create their own `.env` file based on `.env.sample`

### 2. Identity Information is Build-Time Only
- Personal identity values are only used during the Nix build process
- They are injected as build arguments and not stored in the final system configuration
- The built system does not expose these values at runtime

### 3. CI/CD Uses Placeholder Values
- Continuous Integration and Deployment pipelines run with generic placeholder values
- This allows automated testing without exposing real user information
- The `.env.sample` file provides the template with safe default values

### 4. API Keys for MCP Omnisearch
For Claude Code's MCP omnisearch functionality, create a `.env` file in one of these locations:
- `./.env` (current directory when running claude)
- `~/Projects/nix-project/.env` (default project location)
- `~/.env` (home directory)

Add your API keys (all optional):
```bash
# Search providers
TAVILY_API_KEY=your_key_here
BRAVE_API_KEY=your_key_here
KAGI_API_KEY=your_key_here
PERPLEXITY_API_KEY=your_key_here

# Content processing
JINA_AI_API_KEY=your_key_here
FIRECRAWL_API_KEY=your_key_here
```

## 🚀 Quick Start

### Prerequisites
- macOS (Apple Silicon or Intel)
- Internet connection

### Important: Configuration Name
This configuration uses a **fixed configuration name "angel"** for maximum portability across different Macs. This means:
- You can run `darwin-rebuild switch --flake .` on any Mac
- No need to worry about hostname matching
- All commands will automatically use the "angel" configuration

### Installation

1. **Clone this repository:**
   ```bash
   git clone https://github.com/Angleito/angelsnixconfig.git
   cd angelsnixconfig
   ```

2. **Run the installation script:**
   ```bash
   ./install.sh
   ```

   The script will:
   - Check for Nix (provides installation instructions if missing)
   - Install nix-darwin if not present
   - Install Homebrew for GUI applications
   - Apply the complete system configuration
   - Install all packages and applications declaratively

3. **Restart your terminal** to load the new configuration

**Alternative installation methods:**
```bash
# Using the flake app
nix run .#install

# Manual installation with automatic "angel" configuration
sudo darwin-rebuild switch --flake .#angel

# Or just use the wrapper (works after first installation)
darwin-rebuild switch --flake .
```

## 📦 What Gets Installed

### GUI Applications (via Homebrew)
- **Warp** - AI-powered terminal
- **Cursor** - AI code editor  
- **Brave Browser** - Privacy-focused browser
- **Orbstack** - Docker/container management
- **Zoom** - Video conferencing
- **Slack** - Team messaging
- **GarageBand** - Music creation (Mac App Store)

### Development Tools (Pure Nix Packages)
- **Languages:** Node.js, Python, Go, Rust
- **Version Control:** Git, GitHub CLI, Lazygit
- **Containers:** Docker, Docker Compose
- **Web3 Tools:**
  - **Sui CLI** - Custom Nix package with npm wrapper
  - **Walrus CLI** - Custom Nix package with binary download
  - **Vercel CLI** - Custom Nix package with npm wrapper
- **CLI Tools:** ripgrep, fzf, bat, eza, htop, and more
- **Shell:** Zsh with autosuggestions, syntax highlighting, and Starship prompt
- **AI Tools:** Claude Code CLI with comprehensive configuration

## 🤖 Claude Code Configuration

This setup includes a complete Claude Code configuration with custom slash commands and MCP servers.

### Custom Slash Commands

The following custom commands are automatically available:

- **`/user:security-review`** - Comprehensive security audit of codebase
  - Runs `npm audit`
  - Scans for hardcoded secrets
  - Reviews authentication logic
  - Checks for SQL injection vulnerabilities
  - Validates input sanitization

- **`/user:optimize`** - Code performance analysis and optimization
  - Analyzes current git status and recent commits
  - Runs existing tests and benchmarks
  - Identifies performance bottlenecks
  - Provides specific optimization suggestions

- **`/user:deploy`** - Smart deployment with comprehensive checks
  - Pre-deployment validation (tests, build, security)
  - Branch-based deployment strategy
  - Requires explicit confirmation for production

- **`/user:debug`** - Systematic debugging with context analysis
  - Analyzes recent git changes
  - Searches for error logs
  - Reviews dependencies and configuration
  - Provides step-by-step debugging approach

- **`/user:frontend:component`** - React/Vue component generator
  - Creates TypeScript components with proper typing
  - Includes styling and prop validation
  - Generates unit tests
  - Follows project style guide

- **`/user:backend:api`** - API endpoint generator
  - Creates endpoints with input validation
  - Includes proper error handling
  - Adds authentication/authorization
  - Generates comprehensive tests

- **`/user:research`** - Comprehensive research using multiple search engines and AI tools
  - Queries multiple search engines (Tavily, Brave, Kagi)
  - Uses AI analysis (Perplexity AI)
  - Content processing and summarization
  - Provides actionable insights with source attribution

### MCP Servers

Pre-configured Model Context Protocol servers provide enhanced capabilities:

#### Basic Servers
- **Filesystem** - Access to ~/Projects, ~/Documents, and home directory
- **Memory** - Persistent memory across conversations
- **Sequential Thinking** - Enhanced reasoning capabilities

#### Browser Automation
- **Puppeteer** - Browser automation with Puppeteer
- **Playwright** - Official Microsoft Playwright MCP server (cross-browser support)

#### Search & AI Tools (mcp-omnisearch)
- **Search Engines**: Tavily, Brave, and Kagi search
- **AI Response Tools**: Perplexity AI and Kagi FastGPT
- **Content Processing**: Jina AI Reader, Kagi Summarizer, Firecrawl
- **Unified Interface**: Single server combining multiple search and AI capabilities

### API Key Configuration

MCP servers that require API keys are automatically configured from environment variables:

1. **Edit your `.env` file** (created during setup):
   ```bash
   # Add your API keys (all optional)
   TAVILY_API_KEY="your-tavily-key"
   BRAVE_API_KEY="your-brave-key"
   KAGI_API_KEY="your-kagi-key"
   PERPLEXITY_API_KEY="your-perplexity-key"
   JINA_AI_API_KEY="your-jina-key"
   FIRECRAWL_API_KEY="your-firecrawl-key"
   ```

2. **Rebuild your configuration**:
   ```bash
   direnv allow && rebuild
   ```

**Note**: All API keys are optional. The mcp-omnisearch server will work with whichever services you have API keys for.

**API Key Setup**: Replace the placeholder values in your `.env` file with actual API keys to enable the respective services. The configuration will automatically use these keys when you rebuild.

### Configuration Files

Claude Code configuration is automatically created:

- `~/.claude.json` - Main configuration with MCP servers and global settings
- `~/.claude/commands/` - Directory containing all custom slash commands
- `~/.claude/settings.json` - Advanced settings with security defaults

## 📚 Development Best Practices

### Core Principles

1. **Reuse Before Create**
   - Always check the repo for existing implementations first
   - Reuse existing code/files & edit before creating new ones
   - Use `grep`, `search_codebase`, or `file_glob` to find existing patterns

2. **Deep Planning with Sequential Thinking**
   - Leverage `!Task ultrathink` for complex planning tasks
   - Break down problems into sequential steps before implementation
   - Create dependency graphs to identify task relationships

3. **Research-Driven Development**
   - Use `mcp-omnisearch` for research sub-tasks
   - Gather context from multiple sources before implementing
   - Validate approaches with external documentation

4. **Modular Code Design**
   - Generate short, modular code snippets
   - Separate concerns into distinct functions/modules
   - Keep each component focused on a single responsibility

5. **Smart Task Parallelization**
   - Parallelize independent tasks with max 10 agents
   - Preserve order for dependent tasks
   - Use dependency graphs to determine execution order

### Workflow Example: Feature Implementation

```bash
# Step 1: Sequential Planning Phase
!Task ultrathink "Plan implementation of user authentication feature"
# Output: Detailed plan with task breakdown and dependencies

# Step 2: Create Dependency Graph
Tasks:
1. Research auth best practices (independent)
2. Check existing auth code (independent)  
3. Design auth schema (depends on 1,2)
4. Implement auth middleware (depends on 3)
5. Create login endpoint (depends on 4)
6. Create register endpoint (depends on 4)
7. Add auth tests (depends on 5,6)

# Step 3: Execute Independent Tasks in Parallel
# Batch 1 (parallel execution):
- Agent 1: mcp-omnisearch "JWT authentication best practices Node.js 2024"
- Agent 2: grep -r "auth" ./src && search_codebase "authentication middleware"

# Step 4: Execute Dependent Tasks Sequentially
# After batch 1 completes:
- Design schema based on research findings
- Implement middleware using existing patterns
- Create endpoints (can parallelize login/register)
- Write comprehensive tests
```

### Code Reuse Example

```bash
# BAD: Creating new file without checking
❌ create_file auth/middleware.js

# GOOD: Check first, then edit
✅ grep -r "middleware" ./src
✅ search_codebase "authentication middleware Express"
✅ # Found existing middleware/base.js
✅ edit_files middleware/base.js  # Extend existing code
```

### Modular Code Example

```javascript
// BAD: Monolithic function
❌ function handleUserRegistration(req, res) {
  // 100+ lines doing validation, hashing, DB ops, email, etc.
}

// GOOD: Modular approach
✅ // Separate concerns into focused modules
const validateUser = require('./validators/user');
const hashPassword = require('./utils/crypto');
const createUser = require('./db/users');
const sendWelcomeEmail = require('./email/welcome');

async function handleUserRegistration(req, res) {
  const validation = validateUser(req.body);
  if (!validation.valid) return res.status(400).json(validation.errors);
  
  const hashedPassword = await hashPassword(req.body.password);
  const user = await createUser({ ...req.body, password: hashedPassword });
  await sendWelcomeEmail(user);
  
  res.status(201).json({ id: user.id });
}
```

### Parallel Execution Example

```bash
# Dependency Analysis
Tasks for API refactoring:
A. Analyze current API structure (independent)
B. Research REST best practices (independent)
C. Design new API schema (depends on A, B)
D. Update user endpoints (depends on C)
E. Update product endpoints (depends on C)
F. Update order endpoints (depends on C)
G. Update API documentation (depends on D, E, F)
H. Write integration tests (depends on D, E, F)

# Execution Plan
Batch 1 (parallel): A, B
Batch 2 (sequential): C
Batch 3 (parallel): D, E, F
Batch 4 (parallel): G, H

# Command execution
# Batch 1
Agent 1: search_codebase "API routes endpoints"
Agent 2: mcp-omnisearch "REST API design patterns 2024"

# Batch 3 (after C completes)
Agent 1: edit_files api/users.js
Agent 2: edit_files api/products.js  
Agent 3: edit_files api/orders.js
```

### Research-First Development

```bash
# Before implementing a complex feature
!Task ultrathink "Plan WebSocket implementation for real-time chat"

# Research phase (parallel):
mcp-omnisearch "WebSocket vs Socket.io production comparison"
mcp-omnisearch "WebSocket scaling strategies Redis"
grep -r "websocket\|socket" ./src

# Only after research, begin implementation
# This prevents costly refactors and ensures best practices
```

### Development Configuration

For smoother development experience, the `claude` command includes several optimizations:

- **Automatic permissions bypass**: Includes `--dangerously-skip-permissions` flag
- **Command cache refresh**: Runs `hash -r` automatically to prevent "command not found" issues
- **Dynamic binary detection**: Automatically finds the claude-code binary in the nix store

This configuration is suitable for development environments with no internet access or sandboxed setups.

### Usage Examples

```bash
# Start Claude Code
claude

# Use custom commands in Claude Code
> /user:security-review
> /user:optimize src/performance.js
> /user:research "Next.js 14 performance optimization"
> /user:frontend:component UserProfile
> /user:backend:api user-management
> /user:deploy
> /user:debug "authentication not working"
```

## 🏗️ Pure Nix Architecture

This configuration uses a **pure Nix modular architecture** that eliminates complex shell scripts:

### Key Features
- **Custom Package Overlays**: Web3 tools (Sui, Walrus, Vercel) as proper Nix packages
- **Modular Configuration**: Separate modules for development, system settings, and applications
- **Declarative Management**: Everything defined in Nix expressions
- **No Shell Script Complexity**: Eliminates activation script issues and variable escaping

### Architecture Overview
```
├── flake.nix                 # Main flake with overlays and outputs
├── pkgs/                     # Custom package definitions
│   ├── default.nix          # Package overlay
│   ├── sui-cli/             # Sui CLI Nix package
│   ├── walrus-cli/          # Walrus CLI Nix package
│   └── vercel-cli/          # Vercel CLI Nix package
├── modules/                  # Modular system configuration
│   ├── default.nix          # Module entry point
│   ├── development/         # Development tools modules
│   └── system/              # System configuration modules
├── darwin-configuration.nix  # Main system configuration
└── home.nix                 # Home Manager configuration
```

## 🔧 Configuration

### Adding Custom Packages

**Custom Web3 Tools** (in `modules/development/web3.nix`):
```nix
development.web3 = {
  enable = true;
  enableSui = true;      # Custom Sui CLI package
  enableWalrus = true;   # Custom Walrus CLI package  
  enableVercel = true;   # Custom Vercel CLI package
};
```

**GUI Applications** (in `darwin-configuration.nix`):
```nix
homebrew.casks = [
  "warp"
  "cursor" 
  "brave-browser"
  "orbstack"
  # Add new apps here
];
```

**System Packages** (in `modules/development/`):
```nix
# Enable entire module categories
development = {
  rust.enable = true;
  nodejs.enable = true;
  web3.enable = true;
};
```

### Applying Changes

After making any configuration changes:

```bash
# Option 1: Use the rebuild alias (simplest)
rebuild

# Option 2: Use darwin-rebuild directly (wrapper will add #angel automatically)
sudo darwin-rebuild switch --flake .

# Option 3: Explicitly specify the configuration
sudo darwin-rebuild switch --flake .#angel
```

**Note:** All commands use the fixed "angel" configuration for portability across different Macs.

**Available flake commands:**
```bash
# Build and test
nix flake check                    # Validate configuration
nix build .#packages.aarch64-darwin.sui-cli  # Build custom packages

# Run apps
nix run .#sui                      # Run Sui CLI
nix run .#deploy                   # Deploy configuration (uses "angel" automatically)
nix run .#install                  # Install from scratch (uses "angel" automatically)
```

## 🛠️ Useful Commands

### System Management
- `rebuild` - Apply configuration changes (alias for darwin-rebuild)
- `sudo darwin-rebuild switch --flake .` - Apply configuration (auto-uses "angel")
- `nix flake update` - Update all flake inputs to latest versions
- `nix flake check` - Validate configuration
- `./install.sh` - Complete setup from scratch

### Claude Code
- `claude` - Start Claude Code CLI (with permissions bypass for development)
- `/user:security-review` - Run security audit
- `/user:optimize [files]` - Analyze and optimize performance
- `/user:deploy` - Smart deployment with checks
- `/user:debug [issue]` - Systematic debugging
- `/user:research [topic]` - Comprehensive research using multiple search engines
- `/user:frontend:component [name]` - Generate React/Vue component
- `/user:backend:api [name]` - Generate API endpoint

### Custom CLI Tools
- `sui` - Sui blockchain CLI (custom Nix package)
- `walrus` - Walrus decentralized storage CLI (custom Nix package)  
- `vercel` - Vercel deployment CLI (custom Nix package)

## 📁 Project Structure

```
.
├── flake.nix                 # Main flake with overlays and packages
├── flake.lock                # Locked flake dependencies  
├── darwin-configuration.nix  # System-level configuration
├── home.nix                 # Home Manager configuration
├── home/
│   └── git.nix             # Git configuration with SSH setup
├── pkgs/                    # Custom package definitions
│   ├── default.nix         # Package overlay
│   ├── sui-cli/            # Sui CLI custom package
│   ├── walrus-cli/         # Walrus CLI custom package
│   └── vercel-cli/         # Vercel CLI custom package
├── modules/                 # Modular configuration system
│   ├── default.nix         # Module entry point
│   ├── development/        # Development tools modules
│   │   ├── rust.nix       # Rust development setup
│   │   ├── nodejs.nix     # Node.js development setup
│   │   └── web3.nix       # Web3 tools configuration
│   └── system/            # System configuration modules
│       ├── defaults.nix   # macOS system defaults
│       ├── power.nix      # Power management settings
│       └── xcode.nix      # Xcode command line tools
├── install.sh              # Automated installation script
├── .env.sample             # Template for personal variables
├── .env                    # Personal variables (git-ignored)
└── .envrc                  # Direnv configuration
```

## 🔒 Security & Privacy

- **Pure Nix Architecture**: No complex shell scripts with potential vulnerabilities
- **Declarative Packages**: All tools defined as proper Nix packages with controlled dependencies
- **No Hardcoded Secrets**: Configuration validated to contain no API keys or passwords
- **Secure Downloads**: All downloads use HTTPS from official sources
- **Environment Isolation**: `.env` file is git-ignored and never committed
- **Controlled Execution**: All `exec` calls use proper wrapper scripts with error handling
- **macOS Integration**: Uses macOS Keychain for secure credential storage

## 🆘 Troubleshooting

**Nix not found:**
```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

**Permission denied on install.sh:**
```bash
chmod +x install.sh
```

**Build failures:**
```bash
# Validate flake configuration
nix flake check

# Test individual packages
nix build .#packages.aarch64-darwin.sui-cli

# Test system configuration
nix build .#darwinConfigurations.angels-MacBook-Pro.system
```

**Custom packages not working:**
- Ensure flake is committed to git: `git add . && git commit -m "update config"`
- Check package definitions in `pkgs/` directory
- Verify overlay is properly imported in `flake.nix`

**Apps not appearing after install:**
- Restart your terminal
- Check `/Applications` folder  
- Run `sudo darwin-rebuild switch --flake .` to retry
