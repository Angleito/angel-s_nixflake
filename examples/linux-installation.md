# Linux Installation Guide

This guide provides detailed instructions for installing the project on various Linux distributions.

## Prerequisites

- Linux kernel 4.4+ (recommended 5.0+)
- glibc 2.17+ or musl libc 1.1.20+
- 64-bit architecture (x86_64 or ARM64)

## Distribution-Specific Installation

### Ubuntu/Debian

```bash
# Update package list
sudo apt update

# Install dependencies
sudo apt install -y build-essential git curl wget

# For older Ubuntu versions, you may need:
sudo apt install -y software-properties-common

# Install project-specific dependencies
sudo apt install -y [project-specific-packages]
```

### CentOS/RHEL/Fedora

```bash
# For CentOS/RHEL 8+
sudo dnf install -y gcc gcc-c++ make git curl wget

# For CentOS/RHEL 7
sudo yum install -y gcc gcc-c++ make git curl wget

# For Fedora
sudo dnf install -y gcc gcc-c++ make git curl wget

# Install project-specific dependencies
sudo dnf install -y [project-specific-packages]
```

### Arch Linux

```bash
# Update system
sudo pacman -Syu

# Install dependencies
sudo pacman -S base-devel git curl wget

# Install project-specific dependencies
sudo pacman -S [project-specific-packages]
```

### openSUSE

```bash
# Install dependencies
sudo zypper install -y gcc gcc-c++ make git curl wget

# Install project-specific dependencies
sudo zypper install -y [project-specific-packages]
```

### Alpine Linux

```bash
# Install dependencies
sudo apk add --no-cache build-base git curl wget

# Install project-specific dependencies
sudo apk add --no-cache [project-specific-packages]
```

## Generic Installation

### Method 1: From Source

```bash
# Clone the repository
git clone https://github.com/your-org/your-project.git
cd your-project

# Build the project
make build

# Install system-wide
sudo make install

# Or install to user directory
make install PREFIX=$HOME/.local
```

### Method 2: Using Package Manager

```bash
# Add repository (if available)
curl -fsSL https://packages.yourproject.com/gpg | sudo apt-key add -
echo "deb https://packages.yourproject.com/apt stable main" | sudo tee /etc/apt/sources.list.d/yourproject.list

# Update and install
sudo apt update
sudo apt install your-project
```

### Method 3: Using Snap

```bash
# Install snap if not available
sudo apt install snapd

# Install project
sudo snap install your-project
```

### Method 4: Using Flatpak

```bash
# Install flatpak if not available
sudo apt install flatpak

# Add flathub repository
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install project
flatpak install flathub com.yourorg.YourProject
```

## Configuration

### System-wide Configuration

```bash
# Create system configuration
sudo mkdir -p /etc/your-project
sudo tee /etc/your-project/config.yaml > /dev/null <<EOF
# System-wide configuration
log_level: info
cache_dir: /var/cache/your-project
data_dir: /var/lib/your-project
EOF
```

### User Configuration

```bash
# Create user configuration
mkdir -p ~/.config/your-project
cat > ~/.config/your-project/config.yaml <<EOF
# User-specific configuration
log_level: debug
cache_dir: ~/.cache/your-project
data_dir: ~/.local/share/your-project
EOF
```

### Environment Variables

Add to your `~/.bashrc` or `~/.profile`:

```bash
export YOUR_PROJECT_HOME=$HOME/.config/your-project
export PATH=$PATH:$HOME/.local/bin
```

## Verification

```bash
# Verify installation
your-project --version

# Check system info
your-project --system-info

# Run basic tests
make test
```

## Service Configuration (Optional)

### systemd Service

```bash
# Create service file
sudo tee /etc/systemd/system/your-project.service > /dev/null <<EOF
[Unit]
Description=Your Project Service
After=network.target

[Service]
Type=simple
User=your-project
Group=your-project
ExecStart=/usr/local/bin/your-project daemon
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable your-project
sudo systemctl start your-project
```

## Troubleshooting

### Common Issues

1. **Permission Denied**: Check file permissions and use `sudo` if needed
2. **Library Not Found**: Install missing dependencies or update `LD_LIBRARY_PATH`
3. **Command Not Found**: Ensure installation directory is in your `PATH`

### Library Path Issues

```bash
# Add to ~/.bashrc if libraries are in non-standard locations
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

# Or create a config file
echo "/usr/local/lib" | sudo tee /etc/ld.so.conf.d/yourproject.conf
sudo ldconfig
```

### SELinux Issues (CentOS/RHEL)

```bash
# Check SELinux status
sestatus

# If SELinux is enforcing and causing issues:
sudo setsebool -P httpd_can_network_connect 1

# Or temporarily disable
sudo setenforce 0
```

## Uninstallation

```bash
# Remove installed binaries
sudo rm -f /usr/local/bin/your-project

# Remove configuration
sudo rm -rf /etc/your-project
rm -rf ~/.config/your-project

# Remove cache and data
sudo rm -rf /var/cache/your-project
sudo rm -rf /var/lib/your-project
rm -rf ~/.cache/your-project
rm -rf ~/.local/share/your-project

# Remove service (if installed)
sudo systemctl stop your-project
sudo systemctl disable your-project
sudo rm -f /etc/systemd/system/your-project.service
sudo systemctl daemon-reload
```

## Next Steps

- See [Configuration Guide](../docs/configuration.md) for advanced setup
- Check [Usage Examples](../docs/usage.md) for common use cases
- Join our [Community](../docs/community.md) for support
