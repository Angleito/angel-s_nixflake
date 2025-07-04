# Nix Darwin Configuration

This repository contains a personalized Nix Darwin configuration for macOS systems.

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

## Quick Start

1. Copy the sample environment file and add your personal information:
   ```bash
   cp .env.sample .env
   # Edit .env with your actual values
   ```

2. Run the installation script:
   ```bash
   ./install.sh
   ```

## Updating Configuration

After making changes to your identity in `.env` or modifying the Nix configuration, refresh your system with this one-liner:

```shell
direnv allow && darwin-rebuild switch --flake .
```

This command:
- `direnv allow` - Reloads environment variables from `.env`
- `darwin-rebuild switch --flake .` - Rebuilds and switches to the new system configuration

## Security Best Practices

- Never commit `.env` to version control
- Keep `.env.sample` updated with placeholder values only
- Review changes before rebuilding to ensure no personal information is accidentally included
