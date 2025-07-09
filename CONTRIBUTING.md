# Contributing to Nix Project

Thank you for your interest in contributing to this Nix project! This document provides guidelines and information for contributors.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Contributing Guidelines](#contributing-guidelines)
- [Code Style](#code-style)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Issue Reporting](#issue-reporting)
- [Community](#community)

## Getting Started

### Prerequisites

- [Nix](https://nixos.org/download.html) installed on your system
- Git for version control
- Basic understanding of Nix flakes and the Nix language

### Development Setup

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd nix-project
   ```

2. **Enter the development environment:**
   ```bash
   nix develop
   ```

3. **Build the project:**
   ```bash
   nix build
   ```

4. **Run tests:**
   ```bash
   nix flake check
   ```

## Contributing Guidelines

### Code of Conduct

Please be respectful and inclusive in all interactions. We aim to create a welcoming environment for all contributors.

### Types of Contributions

We welcome various types of contributions:

- **Bug fixes:** Help us identify and fix issues
- **Feature additions:** Propose and implement new functionality
- **Documentation:** Improve existing docs or add new ones
- **Testing:** Add tests to improve coverage
- **Performance improvements:** Optimize existing code

### Before You Start

- Check existing issues and pull requests to avoid duplicates
- For significant changes, create an issue first to discuss the proposal
- Make sure your development environment is properly set up

## Code Style

### Nix Code Style

- Use 2-space indentation
- Follow the [Nix style guide](https://nixos.org/manual/nix/stable/contributing/style-guide.html)
- Use meaningful variable and function names
- Add comments for complex logic
- Prefer explicit imports over `with` statements where possible

### Example:
```nix
{
  description = "Example flake description";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        # Your configuration here
      });
}
```

### Shell Script Style

- Use `#!/usr/bin/env bash` shebang
- Use `set -euo pipefail` for better error handling
- Quote variables to prevent word splitting
- Use meaningful function names

## Testing

### Running Tests

```bash
# Run all checks
nix flake check

# Build specific outputs
nix build .#<output-name>

# Test in a clean environment
nix build --no-link
```

### Adding Tests

- Add unit tests for new functions
- Test edge cases and error conditions
- Ensure tests are deterministic and don't depend on external state
- Use descriptive test names

## Submitting Changes

### Commit Messages

Use clear and descriptive commit messages:

```
feat: add support for custom package configurations

- Add configuration options for package customization
- Update documentation with examples
- Add tests for new functionality

Fixes #123
```

### Commit Message Format

- Use present tense ("add feature" not "added feature")
- Use imperative mood ("move cursor to..." not "moves cursor to...")
- Limit first line to 72 characters or less
- Reference issues and pull requests when applicable

### Pull Request Process

1. **Fork the repository** and create a feature branch
2. **Make your changes** following the style guidelines
3. **Add tests** for new functionality
4. **Update documentation** if necessary
5. **Ensure all tests pass** with `nix flake check`
6. **Submit a pull request** with a clear description

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tests pass locally
- [ ] New tests added (if applicable)
- [ ] Manual testing performed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes (or properly documented)
```

## Issue Reporting

### Bug Reports

When reporting bugs, please include:

- **Environment information** (OS, Nix version, etc.)
- **Steps to reproduce** the issue
- **Expected behavior** vs actual behavior
- **Error messages** or logs
- **Minimal example** if possible

### Feature Requests

For feature requests, please describe:

- **Use case** and motivation
- **Proposed solution** or approach
- **Alternatives considered**
- **Additional context** or examples

## Community

### Getting Help

- Check the [README](README.md) for basic information
- Search existing issues before creating new ones
- Join discussions in pull requests and issues
- Be patient and respectful when seeking help

### Recognition

Contributors are recognized through:

- Git commit history
- Changelog entries for significant contributions
- Thanks in release notes

## Development Tips

### Nix Development Workflow

1. **Use `nix develop`** for consistent development environment
2. **Test changes incrementally** with `nix build`
3. **Use `nix flake show`** to explore available outputs
4. **Leverage `nix log`** for debugging build failures

### Common Commands

```bash
# Enter development shell
nix develop

# Build and show build log
nix build --log-format bar-with-logs

# Update flake inputs
nix flake update

# Show flake outputs
nix flake show

# Format Nix code
nix fmt
```

## Release Process

Releases are handled by maintainers and follow semantic versioning:

- **Major version** (x.0.0): Breaking changes
- **Minor version** (0.x.0): New features, backward compatible
- **Patch version** (0.0.x): Bug fixes

## Questions?

If you have questions not covered in this guide, please:

1. Check existing documentation
2. Search through issues and discussions
3. Create a new issue with the "question" label

Thank you for contributing to this project!
