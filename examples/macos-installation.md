# macOS Installation Guide

This guide provides detailed instructions for installing the project on macOS systems.

## Prerequisites

- macOS 10.15 (Catalina) or later
- Xcode Command Line Tools
- Homebrew (recommended)

## Installation Steps

### 1. Install Xcode Command Line Tools

```bash
xcode-select --install
```

### 2. Install Homebrew (if not already installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 3. Install Dependencies

```bash
# Install required system dependencies
brew install git curl wget

# Install project-specific dependencies
brew install [project-specific-packages]
```

### 4. Clone and Build

```bash
# Clone the repository
git clone https://github.com/your-org/your-project.git
cd your-project

# Build the project
make build
```

### 5. Install to System

```bash
# Install to /usr/local/bin (requires sudo)
sudo make install

# Or install to user directory
make install PREFIX=$HOME/.local
```

## Verification

```bash
# Verify installation
your-project --version

# Run basic tests
make test
```

## Configuration

### Environment Variables

Add to your `~/.zshrc` or `~/.bash_profile`:

```bash
export YOUR_PROJECT_HOME=$HOME/.your-project
export PATH=$PATH:$HOME/.local/bin
```

### Configuration File

Create a configuration file at `~/.your-project/config.yaml`:

```yaml
# Default configuration for macOS
log_level: info
cache_dir: ~/.cache/your-project
data_dir: ~/.local/share/your-project
```

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure you have proper permissions or use `sudo`
2. **Command Not Found**: Check that the installation directory is in your `PATH`
3. **Library Not Found**: Run `brew doctor` to check for homebrew issues

### Apple Silicon (M1/M2) Considerations

```bash
# For Apple Silicon Macs, you may need to use arch prefix
arch -arm64 brew install [package]

# Or for x86_64 compatibility
arch -x86_64 brew install [package]
```

## Uninstallation

```bash
# Remove installed binaries
sudo rm -f /usr/local/bin/your-project

# Remove configuration
rm -rf ~/.your-project

# Remove cache
rm -rf ~/.cache/your-project
```

## Next Steps

- See [Configuration Guide](../docs/configuration.md) for advanced setup
- Check [Usage Examples](../docs/usage.md) for common use cases
- Join our [Community](../docs/community.md) for support
