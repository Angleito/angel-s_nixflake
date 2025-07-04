# Angel's Nix Darwin Configuration with Claude Code

A complete macOS system configuration using Nix Darwin and Home Manager with **comprehensive Claude Code integration**. This setup allows you to automatically install and configure your entire development environment, including a fully configured Claude Code environment with custom commands and MCP servers, with a single command.

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

## 🚀 Quick Start

### Prerequisites
- macOS (Apple Silicon or Intel)
- Internet connection

### Installation

1. **Clone this repository:**
   ```bash
   git clone https://github.com/Angleito/angel-s_nixflake.git
   cd angel-s_nixflake
   ```

2. **Run the bootstrap script:**
   ```bash
   ./bootstrap.sh
   ```

   The script will:
   - Check for Nix (provides installation instructions if missing)
   - Set up your personal environment variables
   - Install all required dependencies
   - Configure your system automatically
   - Install Claude Code from nixpkgs
   - Set up complete Claude Code configuration with custom commands
   - Configure MCP servers for enhanced capabilities

3. **Restart your terminal** to load the new configuration

4. **Start Claude Code:**
   ```bash
   claude
   ```

## 📦 What Gets Installed

### GUI Applications
- **Warp** - AI-powered terminal
- **Cursor** - AI code editor  
- **Brave Browser** - Privacy-focused browser
- **Orbstack** - Docker/container management

### Development Tools
- **Languages:** Node.js, Python, Go, Rust
- **Version Control:** Git, GitHub CLI, Lazygit
- **Containers:** Docker, Docker Compose
- **AI Tools:**
  - **Claude Code CLI** (from nixpkgs) - Complete configuration with custom commands
  - Sui CLI, Walrus CLI, Sei CLI (npm-based)
- **CLI Tools:** ripgrep, fzf, bat, eza, htop, and more
- **Shell:** Zsh with autosuggestions, syntax highlighting, and Starship prompt
- **Package Management:** npm configured globally in user directory

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
- **Fetch** - Web content retrieval capabilities
- **Sequential Thinking** - Enhanced reasoning capabilities

#### Browser Automation
- **Puppeteer** - Browser automation with Puppeteer
- **Playwright** - Browser automation with Playwright (cross-browser support)

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

## 🔧 Configuration

### Adding/Removing Applications

**GUI Applications** (in `darwin-configuration.nix`):
```nix
casks = [
  "warp"
  "cursor"
  "brave-browser"
  "orbstack"
  # Add new apps here
];
```

**CLI Tools** (in `home.nix`):
```nix
home.packages = with pkgs; [
  nodejs_20
  python3
  # Add new tools here
];
```

### Applying Changes

After making any configuration changes:

```bash
rebuild  # Alias for: darwin-rebuild switch --flake .
```

Or if you've changed your `.env` file:

```bash
direnv allow && rebuild
```

## 🛠️ Useful Commands

### System Management
- `rebuild` - Apply system configuration changes
- `update` - Update all flake inputs to latest versions
- `direnv allow` - Reload environment variables
- `darwin-rebuild switch --flake .` - Full rebuild command
- `./bootstrap.sh` - Complete setup from scratch

### Claude Code
- `claude` - Start Claude Code CLI (with permissions bypass for development)
- `/user:security-review` - Run security audit
- `/user:optimize [files]` - Analyze and optimize performance
- `/user:deploy` - Smart deployment with checks
- `/user:debug [issue]` - Systematic debugging
- `/user:research [topic]` - Comprehensive research using multiple search engines
- `/user:frontend:component [name]` - Generate React/Vue component
- `/user:backend:api [name]` - Generate API endpoint

### Other CLI Tools
- `sui`, `walrus`, `sei` - Blockchain CLI tools (npm-based)

## 📁 Project Structure

```
.
├── darwin-configuration.nix  # System-level configuration and GUI apps
├── home.nix                 # User packages and dotfiles
├── home/
│   └── git.nix             # Git configuration with SSH setup
├── flake.nix               # Nix flake definition
├── flake.lock              # Locked flake dependencies
├── install.sh              # Automated installation script
├── setup-ssh.sh            # SSH key generation for GitHub
├── .env.sample             # Template for personal variables
├── .env                    # Personal variables (git-ignored)
└── .envrc                  # Direnv configuration
```

## 🔒 Security & Privacy

- `.env` file is git-ignored and never committed
- Personal information is injected at build time only
- CI/CD systems use placeholder values
- SSH keys are generated locally and stored in macOS Keychain
- npm global packages installed in user directory (no sudo required)
- Nix build results (`result` symlink) are git-ignored

## 🆘 Troubleshooting

**Nix not found:**
```bash
sh <(curl -L https://nixos.org/nix/install)
```

**Permission denied on install.sh:**
```bash
chmod +x install.sh
```

**Claude command not found:**
- The `claude` command automatically refreshes the shell cache
- If issues persist, restart your terminal or run `direnv reload`

**Apps not appearing after install:**
- Restart your terminal
- Check `/Applications` folder
- Run `rebuild` to retry
