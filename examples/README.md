# Examples Directory

This directory contains platform-specific installation guides, setup instructions, and integration examples for the project.

## Contents

### Platform-Specific Installation

- **[macOS Installation Guide](macos-installation.md)** - Complete installation instructions for macOS systems
  - Prerequisites and system requirements
  - Homebrew-based installation
  - Apple Silicon (M1/M2) considerations
  - Configuration and troubleshooting

- **[Linux Installation Guide](linux-installation.md)** - Installation instructions for various Linux distributions
  - Distribution-specific instructions (Ubuntu, CentOS, Arch, etc.)
  - Package manager integration
  - System service configuration
  - Troubleshooting common issues

- **[WSL Setup Guide](wsl-setup.md)** - Windows Subsystem for Linux setup instructions
  - WSL2 installation and configuration
  - Windows-WSL integration
  - Development environment setup
  - Performance optimization tips

### Containerization and Orchestration

- **[Docker Usage Guide](docker-usage.md)** - Comprehensive Docker integration guide
  - Container building and deployment
  - Docker Compose examples
  - Multi-stage builds
  - Production deployment strategies
  - Kubernetes integration

### CI/CD Integration

- **[CI/CD Integration Examples](cicd-integration.md)** - Integration with various CI/CD platforms
  - GitHub Actions workflows
  - GitLab CI/CD pipelines
  - Jenkins configurations
  - Azure DevOps, CircleCI, and more
  - Kubernetes and Helm deployment examples

## Quick Start

Choose the appropriate guide based on your platform and requirements:

1. **For macOS users**: Start with [macOS Installation Guide](macos-installation.md)
2. **For Linux users**: Use [Linux Installation Guide](linux-installation.md)
3. **For Windows users**: Follow [WSL Setup Guide](wsl-setup.md)
4. **For containerized deployments**: See [Docker Usage Guide](docker-usage.md)
5. **For CI/CD setup**: Check [CI/CD Integration Examples](cicd-integration.md)

## Platform Matrix

| Platform | Installation Guide | Container Support | CI/CD Examples |
|----------|-------------------|-------------------|----------------|
| macOS | ✅ [macOS Guide](macos-installation.md) | ✅ Docker Desktop | ✅ GitHub Actions |
| Linux | ✅ [Linux Guide](linux-installation.md) | ✅ Native Docker | ✅ All platforms |
| Windows | ✅ [WSL Guide](wsl-setup.md) | ✅ Docker Desktop | ✅ Azure DevOps |
| Containers | ✅ [Docker Guide](docker-usage.md) | ✅ Native | ✅ All platforms |

## Common Use Cases

### Development Environment

1. **Local Development**: Use platform-specific installation guides
2. **Containerized Development**: Use Docker development configurations
3. **Cross-platform Development**: Use WSL for Windows developers

### Production Deployment

1. **Cloud Deployment**: Use Docker containers with CI/CD pipelines
2. **Kubernetes**: Use Helm charts and Kubernetes manifests
3. **Traditional Servers**: Use systemd services and package managers

### Testing and Validation

1. **Multi-platform Testing**: Use CI/CD matrix builds
2. **Integration Testing**: Use Docker Compose for service dependencies
3. **Performance Testing**: Use production-like container configurations

## Prerequisites by Platform

### macOS
- macOS 10.15 (Catalina) or later
- Xcode Command Line Tools
- Homebrew (recommended)

### Linux
- Linux kernel 4.4+ (recommended 5.0+)
- glibc 2.17+ or musl libc 1.1.20+
- Package manager (apt, yum, dnf, pacman, etc.)

### Windows (WSL)
- Windows 10 version 2004 or later, or Windows 11
- WSL2 enabled
- Ubuntu or preferred Linux distribution

### Docker
- Docker Engine 20.10+ or Docker Desktop
- Docker Compose 2.0+ (optional)
- Kubernetes cluster (for K8s examples)

## Getting Help

If you encounter issues with any of these examples:

1. **Check the troubleshooting sections** in each guide
2. **Review the prerequisites** for your platform
3. **Consult the main documentation** in the `docs/` directory
4. **Join our community** for support and discussions

## Contributing

To improve these examples:

1. **Test on your platform** and report issues
2. **Add missing platforms** or configurations
3. **Update outdated instructions** or dependencies
4. **Improve documentation** clarity and completeness

## Related Documentation

- [Configuration Guide](../docs/configuration.md) - Advanced configuration options
- [Usage Examples](../docs/usage.md) - Common usage patterns
- [API Reference](../docs/api.md) - API documentation
- [Contributing Guide](../docs/contributing.md) - How to contribute

## License

These examples are provided under the same license as the main project. See the [LICENSE](../LICENSE) file for details.
