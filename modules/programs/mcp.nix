{ config, lib, pkgs, ... }:

let
  cfg = config.programs.mcp;
in {
  options.programs.mcp = {
    enable = lib.mkEnableOption "Global MCP server configurations";
    
    configDir = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/.claude";
      description = "Directory for MCP configuration";
    };
    
    servers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          command = lib.mkOption {
            type = lib.types.str;
            description = "Command to run the MCP server";
          };
          args = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Arguments for the MCP server command";
          };
          env = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = {};
            description = "Environment variables for the MCP server";
          };
        };
      });
      default = {};
      description = "MCP server configurations";
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure required packages are available
    environment.systemPackages = with pkgs; [
      python3
      python3Packages.pip
      nodejs_20  # For npx and MCP servers
      jq         # For updating JSON configuration
    ];

    # Create MCP configuration
    system.activationScripts.mcpSetup = {
      text = ''
        echo "Setting up global MCP server configuration..."
        
        # Get the primary user
        PRIMARY_USER="${config.system.primaryUser}"
        USER_HOME="/Users/$PRIMARY_USER"
        
        # Create global MCP servers directory
        MCP_GLOBAL_DIR="$USER_HOME/.local/share/mcp-servers"
        mkdir -p "$MCP_GLOBAL_DIR"
        chown $PRIMARY_USER:staff "$MCP_GLOBAL_DIR"
        
        # Install Qdrant MCP server globally if configured
        QDRANT_SOURCE_DIR="$USER_HOME/angelsnixconfig/mcp-qdrant-code-search"
        if [ -d "$QDRANT_SOURCE_DIR" ] && \
           echo '${builtins.toJSON cfg.servers}' | grep -q "qdrant-code-search"; then
          echo "Installing Qdrant MCP server globally..."
          
          # Create global Qdrant MCP directory
          QDRANT_MCP_DIR="$MCP_GLOBAL_DIR/qdrant-code-search"
          
          # Copy Qdrant MCP source to global location
          if [ ! -d "$QDRANT_MCP_DIR" ]; then
            echo "Copying Qdrant MCP source from $QDRANT_SOURCE_DIR to $QDRANT_MCP_DIR"
            cp -r "$QDRANT_SOURCE_DIR" "$QDRANT_MCP_DIR"
            chown -R $PRIMARY_USER:staff "$QDRANT_MCP_DIR"
          fi
          
          # Create global virtual environment
          if [ ! -d "$QDRANT_MCP_DIR/venv" ]; then
            echo "Creating global virtual environment for Qdrant MCP..."
            cd "$QDRANT_MCP_DIR"
            sudo -u $PRIMARY_USER python3 -m venv venv
            sudo -u $PRIMARY_USER venv/bin/pip install --upgrade pip
            sudo -u $PRIMARY_USER venv/bin/pip install -r requirements.txt
          fi
          
          echo "Qdrant MCP server installed globally at: $QDRANT_MCP_DIR"
        else
          echo "Qdrant MCP source not found at $QDRANT_SOURCE_DIR or not configured"
        fi
        
        # Update claude.json to add MCP servers globally
        # This preserves existing configuration while adding MCP servers
        if [ -f "$USER_HOME/.claude.json" ]; then
          # Use jq to update the existing file, preserving all other settings
          # Add MCP servers globally for all projects
          jq '.mcpServers = ${builtins.toJSON cfg.servers}' \
              "$USER_HOME/.claude.json" > "$USER_HOME/.claude.json.tmp" && \
              mv "$USER_HOME/.claude.json.tmp" "$USER_HOME/.claude.json"
        else
          # Create new file if it doesn't exist
          cat > "$USER_HOME/.claude.json" << 'EOF'
          {
            "mcpServers": ${builtins.toJSON cfg.servers}
          }
          EOF
        fi
        
        # Set proper permissions
        chown $PRIMARY_USER:staff "$USER_HOME/.claude.json"
        chmod 644 "$USER_HOME/.claude.json"
        
        echo "Global MCP server configuration complete!"
      '';
    };
  };
}