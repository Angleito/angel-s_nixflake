# WSL Setup Guide

This guide provides detailed instructions for setting up and using the project in Windows Subsystem for Linux (WSL).

## Prerequisites

- Windows 10 version 2004 or later, or Windows 11
- WSL2 enabled
- A Linux distribution installed in WSL (Ubuntu recommended)

## WSL Installation and Setup

### 1. Enable WSL2

Open PowerShell as Administrator and run:

```powershell
# Enable WSL and Virtual Machine Platform
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Restart Windows
shutdown /r /t 0
```

### 2. Install WSL2 Kernel Update

Download and install the WSL2 Linux kernel update package from Microsoft.

### 3. Set WSL2 as Default

```powershell
wsl --set-default-version 2
```

### 4. Install Ubuntu (Recommended)

```powershell
# Install Ubuntu from Microsoft Store or using command line
wsl --install -d Ubuntu

# Or install Ubuntu 22.04 LTS specifically
wsl --install -d Ubuntu-22.04
```

## Project Installation in WSL

### 1. Update Ubuntu

```bash
# Update package list
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y curl wget git build-essential
```

### 2. Install Project Dependencies

```bash
# Install development tools
sudo apt install -y gcc g++ make cmake

# Install project-specific dependencies
sudo apt install -y [project-specific-packages]
```

### 3. Clone and Build

```bash
# Clone the repository
git clone https://github.com/your-org/your-project.git
cd your-project

# Build the project
make build

# Install
make install PREFIX=$HOME/.local
```

## WSL-Specific Configuration

### 1. Environment Variables

Add to your `~/.bashrc`:

```bash
# WSL-specific environment variables
export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0.0
export LIBGL_ALWAYS_INDIRECT=1

# Project environment
export YOUR_PROJECT_HOME=$HOME/.config/your-project
export PATH=$PATH:$HOME/.local/bin
```

### 2. Windows Integration

```bash
# Configure Windows PATH integration
echo 'export PATH="$PATH:/mnt/c/Windows/System32"' >> ~/.bashrc

# Access Windows files
cd /mnt/c/Users/YourUsername/Documents

# Run Windows applications from WSL
explorer.exe .
notepad.exe file.txt
```

### 3. WSL Configuration File

Create `/etc/wsl.conf`:

```ini
[boot]
systemd=true

[network]
hostname=your-project-wsl
generateHosts=true

[interop]
enabled=true
appendWindowsPath=true

[user]
default=yourusername
```

## Development Setup

### 1. VS Code Integration

```bash
# Install VS Code in Windows, then from WSL:
code .

# Or install VS Code Server directly
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

sudo apt update
sudo apt install code
```

### 2. Git Configuration

```bash
# Configure Git for WSL
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Use Windows credential manager
git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/libexec/git-core/git-credential-manager.exe"
```

### 3. SSH Key Setup

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your.email@example.com"

# Start SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy public key to clipboard (requires xclip)
sudo apt install xclip
xclip -sel clip < ~/.ssh/id_ed25519.pub
```

## Performance Optimization

### 1. File System Location

```bash
# Store project files in WSL filesystem for better performance
# Good: /home/username/projects
# Avoid: /mnt/c/Users/username/projects

# Move existing projects
mv /mnt/c/Users/YourUsername/projects ~/projects
```

### 2. Memory Configuration

Create or edit `%USERPROFILE%\.wslconfig`:

```ini
[wsl2]
memory=4GB
processors=4
swap=2GB
swapfile=C:\\temp\\wsl-swap.vhdx
```

### 3. Docker Integration

```bash
# Install Docker in WSL
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Enable Docker service
sudo systemctl enable docker
sudo systemctl start docker
```

## Windows-WSL Interoperability

### 1. Accessing Windows Files

```bash
# Windows C: drive
cd /mnt/c/

# Windows Programs
cd /mnt/c/Program\ Files/

# User directory
cd /mnt/c/Users/YourUsername/
```

### 2. Running Windows Commands

```bash
# Open Windows Explorer
explorer.exe .

# Open file in Windows notepad
notepad.exe config.txt

# PowerShell from WSL
powershell.exe -Command "Get-Process"
```

### 3. Network Configuration

```bash
# Check WSL IP address
ip addr show eth0

# Access WSL services from Windows
# Use localhost:port or WSL IP address
```

## Troubleshooting

### Common Issues

1. **Performance Issues**: Use WSL filesystem (`/home/`) instead of Windows filesystem (`/mnt/c/`)
2. **Permission Denied**: Check file permissions with `chmod` and `chown`
3. **Network Issues**: Restart WSL with `wsl --shutdown` and reopen terminal
4. **Memory Issues**: Configure memory limits in `.wslconfig`

### WSL Commands

```bash
# List installed distributions
wsl --list --verbose

# Stop WSL
wsl --shutdown

# Restart specific distribution
wsl --terminate Ubuntu

# Export/Import WSL distribution
wsl --export Ubuntu ubuntu-backup.tar
wsl --import Ubuntu-Backup C:\WSL\Ubuntu-Backup ubuntu-backup.tar

# Uninstall distribution
wsl --unregister Ubuntu
```

### Reset WSL

```bash
# Reset to clean state (from Windows)
wsl --unregister Ubuntu
wsl --install -d Ubuntu
```

## Advanced Configuration

### 1. Custom Kernel

```bash
# Build custom kernel (advanced users)
git clone https://github.com/microsoft/WSL2-Linux-Kernel.git
cd WSL2-Linux-Kernel
make KCONFIG_CONFIG=Microsoft/config-wsl
```

### 2. Systemd Support

```bash
# Enable systemd in WSL2
echo -e "[boot]\nsystemd=true" | sudo tee -a /etc/wsl.conf

# Restart WSL
wsl --shutdown
```

### 3. GPU Support

```bash
# Install NVIDIA drivers in WSL (if available)
wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-keyring_1.0-1_all.deb
sudo dpkg -i cuda-keyring_1.0-1_all.deb
sudo apt update
sudo apt install cuda-toolkit-11-8
```

## Best Practices

1. **File Storage**: Keep project files in WSL filesystem for better performance
2. **Memory Management**: Configure appropriate memory limits
3. **Backup**: Regularly export WSL distributions
4. **Updates**: Keep WSL and Linux distribution updated
5. **Integration**: Use VS Code with WSL extension for development

## Next Steps

- See [Configuration Guide](../docs/configuration.md) for advanced setup
- Check [Usage Examples](../docs/usage.md) for common use cases
- Join our [Community](../docs/community.md) for support
