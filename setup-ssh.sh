#!/usr/bin/env bash

set -e

echo "Setting up SSH for GitHub authentication..."

# Check if SSH key already exists
if [ -f "$HOME/.ssh/id_ed25519" ]; then
    echo "SSH key already exists at ~/.ssh/id_ed25519"
    echo "Using existing key..."
else
    echo "Generating new SSH key..."
    # Create .ssh directory if it doesn't exist
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    # Generate SSH key
    ssh-keygen -t ed25519 -C "${GIT_EMAIL:-arainey555@gmail.com}" -f ~/.ssh/id_ed25519 -N ""
    
    echo "SSH key generated successfully!"
fi

# Start ssh-agent if not running
if ! ssh-add -l &>/dev/null; then
    echo "Starting ssh-agent..."
    eval "$(ssh-agent -s)"
fi

# Add SSH key to ssh-agent and macOS keychain
echo "Adding SSH key to ssh-agent and macOS keychain..."
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# Display the public key
echo ""
echo "========================================="
echo "Your SSH public key:"
echo "========================================="
cat ~/.ssh/id_ed25519.pub
echo "========================================="
echo ""
echo "To complete setup:"
echo "1. Copy the SSH key above"
echo "2. Go to https://github.com/settings/keys"
echo "3. Click 'New SSH key'"
echo "4. Paste the key and save"
echo ""
echo "After adding the key to GitHub, your remote will automatically use SSH."
