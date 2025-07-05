{ lib
, writeShellScriptBin
, nodejs
, rustup
, git
}:

# For now, create a simple wrapper that installs Sui CLI via npm
# This avoids the complexity of building from source initially
writeShellScriptBin "sui" ''
  #!/usr/bin/env bash
  set -euo pipefail
  
  SUI_PATH="$HOME/.npm-global/bin/sui"
  
  # Check if sui is already installed
  if [ ! -f "$SUI_PATH" ]; then
    echo "Installing Sui CLI via npm..."
    
    # Ensure npm global directory exists
    mkdir -p "$HOME/.npm-global" "$HOME/.npm-cache"
    
    # Configure npm for global installation
    export NPM_CONFIG_PREFIX="$HOME/.npm-global"
    export NPM_CONFIG_CACHE="$HOME/.npm-cache"
    
    # Install Sui CLI
    ${nodejs}/bin/npm install -g @mysten/sui
  fi
  
  # Execute the real sui command
  exec "$SUI_PATH" "$@"
''