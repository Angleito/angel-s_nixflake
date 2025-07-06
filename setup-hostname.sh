#!/bin/bash

# Get the current hostname without domain suffix
HOSTNAME=$(hostname | sed 's/\..*//')

echo "🔍 Detected hostname: $HOSTNAME"

# Check if this hostname already exists in flake.nix
if grep -q "\"$HOSTNAME\"" flake.nix; then
    echo "✅ Hostname configuration already exists"
else
    echo "📝 Adding hostname configuration..."
    
    # Create a backup
    cp flake.nix flake.nix.backup
    
    # Add the new hostname to the darwinConfigurations
    sed -i '' "/# Add more patterns as needed/i\\
        \"$HOSTNAME\" = mkDarwinConfig \"$HOSTNAME\";
" flake.nix
    
    echo "✅ Added configuration for hostname: $HOSTNAME"
fi

echo ""
echo "You can now run:"
echo "  sudo darwin-rebuild switch --flake .#$HOSTNAME"
echo "  or simply: rebuild (if using the shell alias)"