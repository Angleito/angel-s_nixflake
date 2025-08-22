{ config, pkgs, lib, ... }:

{
  options = {
    development.nodejs.enable = lib.mkEnableOption "Node.js development environment";
  };

  config = lib.mkIf config.development.nodejs.enable {
    # Only install bun - Node.js is managed by NVM
    environment.systemPackages = with pkgs; [
      bun
    ];

    # Set up npm global directories and install web dev tools using NVM
    system.activationScripts.npmSetup.text = ''
      USER_HOME="${config.users.users.${config.system.primaryUser}.home}"
      
      # Load NVM before running any Node.js commands
      echo "Loading NVM for npm setup..."
      source "$USER_HOME/angelsnixconfig/scripts/load-nvm.sh"
      
      # Run as the primary user with NVM loaded
      sudo -u ${config.system.primaryUser} bash -c "
        export HOME=$USER_HOME
        
        # Load NVM
        export NVM_DIR=\"$USER_HOME/.nvm\"
        [ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"
        
        # Use default node version if available
        if [ -f \"\$NVM_DIR/alias/default\" ]; then
          nvm use default --silent
        fi
        
        # Verify Node.js is available
        if ! command -v node &> /dev/null; then
          echo \"Error: Node.js not found via NVM\";
          exit 1
        fi
        
        echo \"Using Node.js version: \$(node --version)\";
        echo \"Using npm version: \$(npm --version)\";
        
        # Get NVM's global npm directory
        NPM_GLOBAL_DIR=\"\$(npm config get prefix)/lib/node_modules\"
        NPM_BIN_DIR=\"\$(npm config get prefix)/bin\"
        echo \"NVM npm global directory: \$NPM_GLOBAL_DIR\"
        echo \"NVM npm bin directory: \$NPM_BIN_DIR\"
        
        # Install global web dev tools
        ${pkgs.bun}/bin/bun install -g vite@latest
        ${pkgs.bun}/bin/bun install -g create-vite@latest
        ${pkgs.bun}/bin/bun install -g create-next-app@latest
        ${pkgs.bun}/bin/bun install -g @tailwindcss/cli@latest
        ${pkgs.bun}/bin/bun install -g tailwindcss@latest
        ${pkgs.bun}/bin/bun install -g postcss@latest
        ${pkgs.bun}/bin/bun install -g autoprefixer@latest
        ${pkgs.bun}/bin/bun install -g typescript@latest
        ${pkgs.bun}/bin/bun install -g tsx@latest
        ${pkgs.bun}/bin/bun install -g @types/node@latest
        ${pkgs.bun}/bin/bun install -g @types/react@latest
        ${pkgs.bun}/bin/bun install -g @types/react-dom@latest
        ${pkgs.bun}/bin/bun install -g eslint@latest
        ${pkgs.bun}/bin/bun install -g prettier@latest
        ${pkgs.bun}/bin/bun install -g nodemon@latest
        ${pkgs.bun}/bin/bun install -g concurrently@latest
        ${pkgs.bun}/bin/bun install -g serve@latest
        ${pkgs.bun}/bin/bun install -g http-server@latest
        ${pkgs.bun}/bin/bun install -g live-server@latest
        
        # Install claude-code-router
        ${pkgs.bun}/bin/bun install -g @tehreet/claude-code-router@latest
        ${pkgs.bun}/bin/bun install -g @musistudio/claude-code-router@latest
        
        # Install MCP servers globally using NVM's npm
        npm install -g @modelcontextprotocol/server-filesystem@latest || echo \"Failed to install server-filesystem\"
        npm install -g @modelcontextprotocol/server-memory@latest || echo \"Failed to install server-memory\"
        npm install -g @modelcontextprotocol/server-puppeteer@latest || echo \"Failed to install server-puppeteer\"
        npm install -g @modelcontextprotocol/server-sequential-thinking@latest || echo \"Failed to install server-sequential-thinking\"
        npm install -g @microsoft/mcp-server-playwright@latest || echo \"Failed to install mcp-server-playwright\"
        npm install -g mcp-omnisearch@latest || echo \"Failed to install mcp-omnisearch\"

        # Create symlinks in ~/.local/bin for easy access
        # This runs after npm packages are installed and before PATH is set up
        echo "Managing npm symlinks..."
        
        # Use the new symlink management script
        if [ -f "$USER_HOME/angelsnixconfig/scripts/manage-npm-symlinks.sh" ]; then
          bash "$USER_HOME/angelsnixconfig/scripts/manage-npm-symlinks.sh"
        else
          # Fallback to inline symlink creation if script is not found
          echo "Warning: manage-npm-symlinks.sh not found, using fallback method"
          
          mkdir -p $USER_HOME/.local/bin
          
          # Use NVM's npm bin directory
          if [ -d "\$NPM_BIN_DIR" ]; then
            for executable in \"\$NPM_BIN_DIR\"/*; do
              if [ -f "$executable" ] && [ -x "$executable" ]; then
                exec_name=$(basename "$executable")
                target_link="$USER_HOME/.local/bin/$exec_name"
                
                if [ ! -e "$target_link" ]; then
                  echo "Creating symlink: $exec_name"
                  ln -sf "$executable" "$target_link"
                fi
              fi
            done
          fi
        fi
      "
    '';
  };
}