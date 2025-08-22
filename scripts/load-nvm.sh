#!/usr/bin/env bash
# Load NVM for use in Nix activation scripts
# This ensures we use the user's NVM-managed Node.js instead of Nix-managed versions

load_nvm() {
    local USER_HOME="${1:-$HOME}"
    local NVM_DIR="$USER_HOME/.nvm"
    
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # Source NVM
        \. "$NVM_DIR/nvm.sh"
        
        # Use default node version if set
        if [ -f "$NVM_DIR/alias/default" ]; then
            nvm use default --silent
        fi
        
        # Export paths for npm and node
        export NODE_PATH="$(which node)"
        export NPM_PATH="$(which npm)"
        export NPX_PATH="$(which npx)"
        
        # Get NVM's npm global directory
        export NVM_NPM_GLOBAL_DIR="$(npm config get prefix)/bin"
        
        echo "Loaded NVM with Node $(node --version) and npm $(npm --version)"
        return 0
    else
        echo "Warning: NVM not found at $NVM_DIR"
        return 1
    fi
}

# If script is sourced, make the function available
# If executed directly, run the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    load_nvm "$@"
fi
