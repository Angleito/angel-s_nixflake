# Angel's Nix Darwin Configuration

A complete macOS system configuration using Nix Darwin and Home Manager. This setup allows you to automatically install and configure your entire development environment with a single command.

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

2. **Run the install script:**
   ```bash
   ./install.sh
   ```

   The script will:
   - Check for Nix (provides installation instructions if missing)
   - Set up your personal environment variables
   - Install all required dependencies
   - Configure your system automatically

3. **Restart your terminal** to load the new configuration

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
  - Claude Code CLI (`@anthropic-ai/claude-code`)
  - Sui CLI, Walrus CLI, Sei CLI
- **CLI Tools:** ripgrep, fzf, bat, eza, htop, and more
- **Shell:** Zsh with autosuggestions, syntax highlighting, and Starship prompt
- **Package Management:** npm configured globally in user directory

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

- `rebuild` - Apply system configuration changes
- `update` - Update all flake inputs to latest versions
- `direnv allow` - Reload environment variables
- `darwin-rebuild switch --flake .` - Full rebuild command
- `claude` - Claude Code CLI (automatically installed)
- `sui`, `walrus`, `sei` - Sui, Walrus, and Sei CLI tools (automatically installed)

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

**Apps not appearing after install:**
- Restart your terminal
- Check `/Applications` folder
- Run `rebuild` to retry
