{ lib
, writeShellScriptBin
, nodejs
}:

# Create a wrapper that installs Vercel CLI via npm on first use
writeShellScriptBin "vercel" ''
  #!/usr/bin/env bash
  set -euo pipefail
  
  VERCEL_PATH="$HOME/.npm-global/bin/vercel"
  
  # Check if vercel is already installed
  if [ ! -f "$VERCEL_PATH" ]; then
    echo "Installing Vercel CLI via npm..."
    
    # Ensure npm global directory exists
    mkdir -p "$HOME/.npm-global" "$HOME/.npm-cache"
    
    # Configure npm for global installation
    export NPM_CONFIG_PREFIX="$HOME/.npm-global"
    export NPM_CONFIG_CACHE="$HOME/.npm-cache"
    
    # Install Vercel CLI
    ${nodejs}/bin/npm install -g vercel
  fi
  
  # Execute the real vercel command
  exec "$VERCEL_PATH" "$@"
''