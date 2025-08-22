#!/usr/bin/env bash
#
# setup-docker-socket.sh
# 
# This script sets up Docker socket compatibility for OrbStack by creating
# a symlink from /var/run/docker.sock to /var/run/orbstack.sock
#
# It handles cases where Docker Desktop might have been previously installed
# and ensures proper permissions on the socket.
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if script is run with sudo when needed
check_sudo() {
    if [ "$EUID" -ne 0 ] && [ "$1" = "true" ]; then
        log_error "This operation requires sudo privileges"
        log_info "Please run: sudo $0"
        exit 1
    fi
}

# Backup existing Docker Desktop socket if present
backup_docker_desktop_socket() {
    if [ -e /var/run/docker.sock ] && [ ! -L /var/run/docker.sock ]; then
        local backup_name="/var/run/docker.sock.backup.$(date +%Y%m%d_%H%M%S)"
        log_warn "Found existing Docker Desktop socket"
        log_info "Backing up to: $backup_name"
        sudo mv /var/run/docker.sock "$backup_name"
        return 0
    fi
    return 1
}

# Remove existing symlinks
remove_existing_symlink() {
    if [ -L /var/run/docker.sock ]; then
        log_info "Removing existing Docker socket symlink"
        sudo rm -f /var/run/docker.sock
        return 0
    fi
    return 1
}

# Create symlink to OrbStack socket
create_orbstack_symlink() {
    # Ensure /var/run directory exists
    sudo mkdir -p /var/run
    
    # Check for OrbStack socket at standard location
    if [ -S /var/run/orbstack.sock ]; then
        log_info "Found OrbStack socket at /var/run/orbstack.sock"
        sudo ln -sf /var/run/orbstack.sock /var/run/docker.sock
        log_info "Created symlink: /var/run/docker.sock -> /var/run/orbstack.sock"
        return 0
    fi
    
    # Fallback: Check user directory
    local user_socket="$HOME/.orbstack/run/docker.sock"
    if [ -S "$user_socket" ]; then
        log_warn "OrbStack socket not found at standard location"
        log_info "Found OrbStack socket at: $user_socket"
        sudo ln -sf "$user_socket" /var/run/docker.sock
        log_info "Created fallback symlink: /var/run/docker.sock -> $user_socket"
        return 0
    fi
    
    log_error "OrbStack socket not found at any expected location"
    log_info "Please ensure OrbStack is installed and running"
    return 1
}

# Verify socket permissions
verify_permissions() {
    # Ensure /var/run directory has proper permissions
    sudo chmod 755 /var/run
    
    # Verify symlink exists and show details
    if [ -L /var/run/docker.sock ]; then
        log_info "Docker socket symlink details:"
        ls -la /var/run/docker.sock
        
        # Test if socket is accessible
        if [ -S /var/run/docker.sock ]; then
            log_info "Socket is accessible"
            return 0
        else
            log_error "Socket exists but is not accessible"
            return 1
        fi
    else
        log_error "Docker socket symlink was not created"
        return 1
    fi
}

# Test Docker connectivity
test_docker_connection() {
    log_info "Testing Docker connectivity..."
    
    # Check if docker command exists
    if ! command -v docker &> /dev/null; then
        log_warn "Docker CLI not found in PATH"
        log_info "You may need to install docker-client or add OrbStack's docker to your PATH"
        return 1
    fi
    
    # Try to connect to Docker
    if docker version &> /dev/null; then
        log_info "Successfully connected to Docker daemon"
        docker version --format 'Server Version: {{.Server.Version}}'
        return 0
    else
        log_error "Failed to connect to Docker daemon"
        log_info "Please ensure OrbStack is running"
        return 1
    fi
}

# Main setup function
main() {
    log_info "Setting up Docker socket compatibility for OrbStack"
    
    # Check if we need sudo (we do for most operations)
    if [ "$EUID" -ne 0 ]; then
        log_info "This script requires sudo privileges for some operations"
        log_info "You may be prompted for your password"
    fi
    
    # Step 1: Backup any existing Docker Desktop socket
    backup_docker_desktop_socket || log_info "No Docker Desktop socket found to backup"
    
    # Step 2: Remove existing symlinks
    remove_existing_symlink || log_info "No existing symlink found"
    
    # Step 3: Create new symlink to OrbStack
    if ! create_orbstack_symlink; then
        log_error "Failed to create OrbStack socket symlink"
        exit 1
    fi
    
    # Step 4: Verify permissions
    if ! verify_permissions; then
        log_error "Failed to verify socket permissions"
        exit 1
    fi
    
    # Step 5: Test Docker connectivity (optional)
    echo
    test_docker_connection || log_warn "Docker connectivity test failed (this is normal if OrbStack is not running)"
    
    echo
    log_info "Docker socket setup completed successfully!"
    log_info "The symlink will be maintained by the system activation script"
}

# Handle command line arguments
case "${1:-setup}" in
    setup)
        main
        ;;
    test)
        test_docker_connection
        ;;
    verify)
        verify_permissions
        ;;
    *)
        echo "Usage: $0 [setup|test|verify]"
        echo "  setup  - Set up Docker socket symlink (default)"
        echo "  test   - Test Docker connectivity"
        echo "  verify - Verify socket permissions"
        exit 1
        ;;
esac
