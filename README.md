# Angel's Pure Nix Darwin Configuration

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/Angleito/angelsnixconfig)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Nix](https://img.shields.io/badge/built%20with-Nix-5277C3.svg)](https://nixos.org/)
[![Platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20Linux-lightgrey.svg)](#supported-platforms)

A complete **multi-platform** system configuration using **pure Nix architecture** with modular design. This setup eliminates shell script complexity and provides declarative package management for your entire development environment with a single command.

## 🚀 Quick Installation

### Prerequisites

| Operating System | Requirements |
|------------------|-------------|
| **macOS** (Apple Silicon) | Nix package manager |
| **macOS** (Intel) | Nix package manager |
| **Linux** (x86_64) | Nix package manager |
| **Linux** (ARM64) | Nix package manager |

#### Install Nix (Required)

**All Platforms:**
```bash
# Recommended: Determinate Systems Nix Installer
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

**Alternative (Official Nix Installer):**
```bash
curl -L https://nixos.org/nix/install | sh -s -- --daemon
```

### Installation Commands

#### macOS (Recommended)

```bash
# Clone the repository
git clone https://github.com/Angleito/angelsnixconfig.git
cd angelsnixconfig

# Quick install (installs Homebrew + nix-darwin automatically)
./install.sh
```

#### Linux / WSL

```bash
# Clone the repository
git clone https://github.com/Angleito/angelsnixconfig.git
cd angelsnixconfig

# Enter development shell
nix develop

# Install packages
nix profile install .#web3-tools
```

#### Alternative Installation Methods

```bash
# Using flake app (all platforms)
nix run .#install

# Manual Darwin installation
sudo darwin-rebuild switch --flake .#angel

# Build for specific platform
nix build .#packages.x86_64-linux.web3-tools
```

## 🔧 Platform-Specific Setup

### macOS Additional Setup

**Homebrew Installation (Automatic):**
The `install.sh` script automatically installs Homebrew for GUI applications.

**Manual Homebrew Installation:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Linux Additional Setup

**For Ubuntu/Debian:**
```bash
# Install build dependencies
sudo apt update
sudo apt install build-essential pkg-config libssl-dev
```

**For Arch Linux:**
```bash
# Install build dependencies
sudo pacman -S base-devel openssl pkg-config
```

## 🎯 Usage Examples

### Basic Usage

```bash
# Apply configuration changes
rebuild

# Start development environment
nix develop

# Use custom CLI tools
sui --help
walrus --help
vercel --help

# Start Claude Code with AI assistance
claude
```

### Development Workflow

```bash
# Check current configuration
nix flake check

# Update all dependencies
nix flake update

# Test build without installation
nix build .#packages.aarch64-darwin.web3-tools

# Enter development shell with all tools
nix develop
```

### Claude Code AI Commands

```bash
# In Claude Code CLI
/user:security-review    # Comprehensive security audit
/user:optimize          # Performance optimization
/user:deploy            # Smart deployment
/user:debug             # Systematic debugging
/user:research "topic"  # Multi-source research
```

## 📋 Supported Platforms

| Platform | Architecture | Status | Notes |
|----------|-------------|--------|---------|
| **macOS** | Apple Silicon (M1/M2/M3) | ✅ Full Support | Primary development platform |
| **macOS** | Intel x86_64 | ✅ Full Support | Complete Darwin integration |
| **Linux** | x86_64 | ✅ Full Support | Ubuntu, Arch, NixOS tested |
| **Linux** | ARM64/aarch64 | ✅ Full Support | Raspberry Pi, ARM servers |
| **WSL** | x86_64 | ✅ Full Support | Windows Subsystem for Linux |
| **Windows** | Native | ❌ Not Supported | Use WSL instead |

### Platform-Specific Features

| Feature | macOS | Linux | WSL |
|---------|-------|-------|-----|
| GUI Applications | ✅ Homebrew | ❌ CLI Only | ❌ CLI Only |
| nix-darwin | ✅ Yes | ❌ No | ❌ No |
| System Configuration | ✅ Full | ⚠️ Limited | ⚠️ Limited |
| Docker Integration | ✅ OrbStack | ✅ Native | ✅ Native |
| Development Tools | ✅ Complete | ✅ Complete | ✅ Complete |

## 🛠️ Troubleshooting

### Common Issues

#### 1. "Nix command not found"

**Solution:**
```bash
# Reinstall Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Reload shell
source ~/.zshrc
# or
source ~/.bashrc
```

#### 2. "Permission denied" on install.sh

**Solution:**
```bash
chmod +x install.sh
./install.sh
```

#### 3. Build failures

**Diagnosis:**
```bash
# Check flake configuration
nix flake check

# Test specific package
nix build .#packages.aarch64-darwin.sui-cli

# Verbose build for debugging
nix build .#packages.aarch64-darwin.sui-cli --verbose
```

**Common fixes:**
```bash
# Clear Nix cache
nix-collect-garbage -d

# Update flake inputs
nix flake update

# Force rebuild
nix build .#packages.aarch64-darwin.sui-cli --rebuild
```

#### 4. Custom packages not working

**Solution:**
```bash
# Ensure flake is committed to git
git add .
git commit -m "update config"

# Check package definitions
ls -la pkgs/

# Verify overlay import
grep -r "overlay" flake.nix
```

#### 5. Apps not appearing after install (macOS)

**Solution:**
```bash
# Restart terminal
source ~/.zshrc

# Check Applications folder
ls /Applications/

# Retry installation
sudo darwin-rebuild switch --flake .

# Check Homebrew status
brew list
```

#### 6. Environment variables not loaded

**Solution:**
```bash
# Check .env file exists
ls -la .env

# Check direnv configuration
cat .envrc

# Allow direnv
direnv allow

# Reload environment
rebuild
```

### Platform-Specific Issues

#### macOS

**Issue:** "xcode-select: error: tool 'xcodebuild' requires Xcode"
```bash
# Install Xcode Command Line Tools
xcode-select --install
```

**Issue:** Homebrew casks fail to install
```bash
# Update Homebrew
brew update

# Check cask availability
brew search --cask warp
```

#### Linux

**Issue:** "error: cannot build on 'x86_64-linux'"
```bash
# Install build dependencies
sudo apt install build-essential  # Ubuntu/Debian
sudo pacman -S base-devel         # Arch Linux
```

**Issue:** SSL certificate errors
```bash
# Update certificates
sudo apt update && sudo apt install ca-certificates  # Ubuntu/Debian
sudo pacman -S ca-certificates                       # Arch Linux
```

### Getting Help

1. **Check logs:**
   ```bash
   # Nix build logs
   nix log .#packages.aarch64-darwin.sui-cli
   
   # System logs (macOS)
   log show --predicate 'process == "darwin-rebuild"' --last 1h
   ```

2. **Community support:**
   - [Nix Community Discord](https://discord.gg/RbvHtGa)
   - [NixOS Discourse](https://discourse.nixos.org/)
   - [GitHub Issues](https://github.com/Angleito/angelsnixconfig/issues)

3. **Documentation:**
   - [Nix Manual](https://nixos.org/manual/nix/stable/)
   - [nix-darwin Documentation](https://github.com/LnL7/nix-darwin)
   - [Home Manager Manual](https://nix-community.github.io/home-manager/)

## 📦 Version Information

### Core Components

| Component | Version | Status |
|-----------|---------|--------|
| **Nix Darwin Config** | 1.0.0 | ✅ Stable |
| **Nix Package Manager** | 2.18+ | ✅ Required |
| **nix-darwin** | Latest | ✅ Auto-installed |
| **Home Manager** | Latest | ✅ Auto-installed |
| **nixpkgs** | unstable | ✅ Auto-updated |

### Custom Packages

| Package | Version | Platforms | Status |
|---------|---------|-----------|--------|
| **Sui CLI** | 1.51.4 | All | ✅ Stable |
| **Walrus CLI** | 1.28.1 | All | ✅ Stable |
| **Vercel CLI** | Latest | All | ✅ NPM Wrapper |
| **Claude Code** | Latest | All | ✅ AI Assistant |

### GUI Applications (macOS)

| Application | Installation Method | Status |
|-------------|-------------------|--------|
| **Warp** | Homebrew | ✅ Auto-installed |
| **Cursor** | Homebrew | ✅ Auto-installed |
| **Brave Browser** | Homebrew | ✅ Auto-installed |
| **OrbStack** | Homebrew | ✅ Auto-installed |
| **Zoom** | Homebrew | ✅ Auto-installed |
| **Slack** | Homebrew | ✅ Auto-installed |
| **GarageBand** | Mac App Store | ⚠️ Manual install |

### Development Tools

| Tool Category | Included Packages | Status |
|---------------|-------------------|--------|
| **Languages** | Node.js, Python, Go, Rust | ✅ Latest versions |
| **Version Control** | Git, GitHub CLI, Lazygit | ✅ Configured |
| **Containers** | Docker, Docker Compose | ✅ Multi-platform |
| **CLI Tools** | ripgrep, fzf, bat, eza, htop | ✅ Modern alternatives |
| **Shell** | Zsh + Starship prompt | ✅ Enhanced experience |

## 🔐 Privacy & Security

This configuration implements several privacy safeguards:

### 1. Environment Variables Protection
- `.env` file is git-ignored and never committed
- Personal identity information is build-time only
- API keys are stored securely in user-specific locations

### 2. API Key Management
For Claude Code's MCP omnisearch functionality, create a `.env` file:

**Supported locations:**
- `./.env` (current directory)
- `~/Projects/nix-project/.env` (default project location)
- `~/.env` (home directory)

**API keys (all optional):**
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

### 3. Security Features
- Pure Nix architecture eliminates shell script vulnerabilities
- Declarative packages with controlled dependencies
- HTTPS-only downloads from official sources
- macOS Keychain integration for secure credential storage

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
  - **Sui CLI** - Custom Nix package with precompiled binaries
  - **Walrus CLI** - Custom Nix package with precompiled binaries  
  - **Vercel CLI** - Custom Nix package with npm wrapper
- **CLI Tools:** ripgrep, fzf, bat, eza, htop, and more
- **Shell:** Zsh with autosuggestions, syntax highlighting, and Starship prompt
- **AI Tools:** Claude Code CLI with comprehensive configuration

## 🤖 AI Development Environment Integration

This setup includes complete declarative management of both Claude Code and Cursor AI editor configurations, ensuring consistent AI-enhanced development environments across all machines.

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

### Automatic Configuration Management

#### Claude Code (`modules/programs/claude-code.nix`)
- **Settings**: `~/.claude/settings.json` with MCP servers and security defaults
- **Memory Integration**: Automated mem0 setup with context-aware scripts
- **Environment Loading**: Custom wrapper that sources .env files automatically
- **MCP Servers**: puppeteer, playwright, mcp-omnisearch pre-configured

#### Cursor AI Editor (`modules/programs/cursor.nix`)  
- **MCP Configuration**: `~/.cursor/mcp.json` with sequential-thinking, omnisearch, openmemory
- **User Settings**: Editor preferences, themes, auto-save automatically configured
- **Keybindings**: Custom shortcuts (cmd+i for composer mode)
- **Launch Arguments**: Performance optimization and crash reporting settings

#### Database Management (`modules/development/database.nix`)
- **PostgreSQL**: Full nix package installation with user scripts
- **Management Scripts**: `postgres-start`, `postgres-stop`, `postgres-status`
- **Data Directory**: `~/.postgresql/data` for user-owned databases
- **Redis Support**: Optional Redis configuration with similar management

### Integration Benefits

✅ **One-Command Setup**: Complete AI environment from `darwin-rebuild switch`
✅ **No Reconfiguration**: Claude Code and Cursor work immediately on new machines  
✅ **Centralized Management**: All configurations tracked in git
✅ **Environment Consistency**: Same setup across all development machines
✅ **Tool Lifecycle**: Automated installation and updates for cargo-based tools

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
- `./scripts/validate-integration.sh` - Validate all integrated configurations

### AI Development Tools
- `claude` - Start Claude Code CLI (with environment loading and permissions bypass)
- `/user:security-review` - Run security audit
- `/user:optimize [files]` - Analyze and optimize performance
- `/user:deploy` - Smart deployment with checks
- `/user:debug [issue]` - Systematic debugging
- `/user:research [topic]` - Comprehensive research using multiple search engines
- `/user:frontend:component [name]` - Generate React/Vue component
- `/user:backend:api [name]` - Generate API endpoint

### Database Management
- `postgres-start` - Start PostgreSQL server
- `postgres-stop` - Stop PostgreSQL server
- `postgres-status` - Check PostgreSQL status
- `redis-start` - Start Redis server (if enabled)
- `redis-stop` - Stop Redis server (if enabled)

### Web3 Development
- `sui` - Sui blockchain CLI (custom Nix package or cargo-installed)
- `walrus` - Walrus decentralized storage CLI (custom Nix package or cargo-installed)
- `vercel` - Vercel deployment CLI (custom Nix package)
- `update-web3-tools` - Update all cargo-installed web3 tools

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
│   ├── applications/       # Application management
│   │   └── homebrew.nix   # GUI applications via Homebrew
│   ├── development/        # Development tools modules
│   │   ├── rust.nix       # Rust development setup
│   │   ├── nodejs.nix     # Node.js development setup
│   │   ├── web3.nix       # Web3 tools configuration
│   │   └── database.nix   # PostgreSQL/Redis management
│   ├── programs/          # Program configurations
│   │   ├── claude-code.nix # Claude Code AI configuration
│   │   ├── cursor.nix     # Cursor AI editor configuration
│   │   └── git-env.nix    # Git environment integration
│   └── system/            # System configuration modules
│       ├── defaults.nix   # macOS system defaults
│       ├── environment.nix # Environment variable management
│       ├── power.nix      # Power management settings
│       └── xcode.nix      # Xcode command line tools
├── scripts/                # Utility scripts
│   └── validate-integration.sh # Integration validation script
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
