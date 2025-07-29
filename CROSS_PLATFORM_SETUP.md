# Cross-Platform Nix Configuration

This configuration now supports both macOS (Darwin) and NixOS systems, allowing you to maintain a consistent development environment across different platforms.

## Supported Platforms

- **macOS** (Darwin)
  - Apple Silicon (aarch64-darwin)
  - Intel (x86_64-darwin)
- **NixOS** (Linux)
  - x86_64-linux
  - aarch64-linux (ARM)

## Quick Start

### On macOS

```bash
# Clone the repository
git clone <your-repo-url> nix-project
cd nix-project

# Run the installation
nix run .#install

# Or rebuild an existing configuration
./rebuild.sh
```

### On NixOS

```bash
# Clone the repository
git clone <your-repo-url> nix-project
cd nix-project

# Generate hardware configuration (first time only)
sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix

# Review and edit the hardware configuration if needed
vim hardware-configuration.nix

# Run the installation
nix run .#install

# Or rebuild an existing configuration
./rebuild.sh
```

## Configuration Structure

### Platform Detection

The configuration automatically detects your platform and applies the appropriate settings:

- `modules/lib/platform.nix` - Platform detection helpers
- `modules/system/defaults.nix` - Routes to platform-specific defaults
- `modules/system/defaults-darwin.nix` - macOS-specific settings
- `modules/system/defaults-linux.nix` - Linux/NixOS-specific settings

### Cross-Platform Modules

These modules work on both platforms:

- `modules/development/rust.nix` - Rust development environment
- `modules/development/nodejs.nix` - Node.js development environment
- `modules/development/web3.nix` - Web3 development tools
- `modules/development/database.nix` - Database tools
- `modules/programs/git-env.nix` - Git configuration
- `modules/programs/claude-code.nix` - Claude Code CLI

### Platform-Specific Modules

#### macOS Only
- `modules/system/power.nix` - macOS power management
- `modules/system/xcode.nix` - Xcode Command Line Tools
- `modules/system/auto-update.nix` - macOS auto-update settings
- `modules/applications/homebrew.nix` - Homebrew integration
- `modules/programs/cursor.nix` - Cursor editor (macOS only currently)

#### NixOS Only
- `modules/system/power-linux.nix` - Linux power management (TLP, thermald)

## Customization

### Selecting Configuration

The rebuild script automatically selects the appropriate configuration based on your platform and hostname. You can override this:

```bash
# Use a specific configuration
NIX_CONFIG_NAME=angel-nixos-arm ./rebuild.sh

# Available configurations:
# - macOS: angel, angels-MacBook-Pro, angel-intel
# - NixOS: angel-nixos, angel-nixos-arm
```

### Adding New Modules

1. Create your module in the appropriate directory
2. Add platform detection if needed:

```nix
{ config, pkgs, lib, ... }:

let
  platform = import ../lib/platform.nix { inherit lib pkgs; };
  isDarwin = platform.lib.platform.isDarwin;
  isLinux = platform.lib.platform.isLinux;
in
{
  # Your module configuration
}
```

3. Import it in `modules/default.nix` with platform conditions:

```nix
imports = [
  # ...
] ++ lib.optionals isDarwin [
  ./your-darwin-module.nix
] ++ lib.optionals isLinux [
  ./your-linux-module.nix
];
```

## Environment Variables

Create a `.env` file in one of these locations:
- `$(pwd)/.env` (project directory)
- `$HOME/.config/nix-project/.env`
- `$HOME/.env`

Example `.env`:
```bash
GIT_NAME="Your Name"
GIT_EMAIL="your.email@example.com"
```

## Troubleshooting

### NixOS Hardware Configuration

If you encounter hardware-specific issues on NixOS:

1. Regenerate hardware configuration:
   ```bash
   sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
   ```

2. Edit `nixos-configuration.nix` to uncomment the hardware import:
   ```nix
   imports = [
     ./hardware-configuration.nix  # Uncomment this line
     # ...
   ];
   ```

### Platform Detection Issues

If the rebuild script doesn't detect your platform correctly:

```bash
# Force platform detection
OSTYPE=darwin ./rebuild.sh  # For macOS
OSTYPE=linux-gnu ./rebuild.sh  # For Linux
```

### Module Conflicts

If you encounter conflicts between platform-specific modules:

1. Check that modules use platform detection
2. Ensure platform-specific code is wrapped in conditionals
3. Use `lib.mkIf` for conditional configuration

## Development Workflow

### Testing Changes

1. **Test on current platform:**
   ```bash
   ./rebuild.sh
   ```

2. **Check configuration:**
   ```bash
   nix flake check
   ```

3. **Build without switching:**
   ```bash
   # macOS
   darwin-rebuild build --flake .#angel
   
   # NixOS
   nixos-rebuild build --flake .#angel-nixos
   ```

### Cross-Platform Development

When developing modules that should work on both platforms:

1. Use the platform detection helpers
2. Test on both platforms if possible
3. Use conditional imports for platform-specific dependencies
4. Document any platform-specific behavior

## Next Steps

1. Review the generated `hardware-configuration.nix` on NixOS
2. Customize the configuration for your specific needs
3. Add your preferred desktop environment on NixOS
4. Configure platform-specific services
5. Set up your development tools and environments

For more information, see:
- [Nix Darwin documentation](https://github.com/LnL7/nix-darwin)
- [NixOS manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager documentation](https://github.com/nix-community/home-manager)