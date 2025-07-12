{ config, lib, pkgs, ... }:

let
  cfg = config.programs.cursor;
  
  # MCP server configurations for Cursor
  cursorMcpServers = {
    "sequential-thinking" = {
      command = "npx";
      args = [ "-y" "@modelcontextprotocol/server-sequential-thinking" ];
    };
    puppeteer = {
      command = "npx";
      args = [ "@puppeteer/mcp-server" ];
    };
    playwright = {
      command = "npx";
      args = [ "@michaeltliu/mcp-server-playwright" ];
    };
    mcp-omnisearch = {
      command = "npx";
      args = [ "mcp-omnisearch" ];
      env = {
        TAVILY_API_KEY = "\${TAVILY_API_KEY}";
        BRAVE_API_KEY = "\${BRAVE_API_KEY}";
        KAGI_API_KEY = "\${KAGI_API_KEY}";
        PERPLEXITY_API_KEY = "\${PERPLEXITY_API_KEY}";
        JINA_AI_API_KEY = "\${JINA_AI_API_KEY}";
        FIRECRAWL_API_KEY = "\${FIRECRAWL_API_KEY}";
      };
    };
    openmemory = {
      command = "npx";
      args = [ "-y" "openmemory" ];
    };
  };

  # Cursor user settings
  cursorSettings = {
    "window.commandCenter" = true;
    "git.autofetch" = true;
    "editor.fontSize" = 14;
    "editor.fontFamily" = "'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace";
    "workbench.colorTheme" = "Default Dark+";
    "editor.minimap.enabled" = false;
    "editor.wordWrap" = "on";
    "files.autoSave" = "afterDelay";
    "editor.formatOnSave" = true;
  };

  # Cursor keybindings
  cursorKeybindings = [
    {
      key = "cmd+i";
      command = "composerMode.agent";
    }
  ];

  # Cursor launch arguments
  cursorArgv = {
    "enable-crash-reporting" = false;
    "crash-reporter-id" = lib.mkDefault "cursor-user";
    "disable-hardware-acceleration" = false;
    "disable-gpu-sandbox" = false;
  };

in {
  options.programs.cursor = {
    enable = lib.mkEnableOption "Cursor AI editor configuration management";
    
    configDir = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/.cursor";
      description = "Directory for Cursor configuration";
    };
    
    userConfigDir = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/Library/Application Support/Cursor/User";
      description = "Directory for Cursor user configuration";
    };
    
    enableMcpServers = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable MCP server configurations";
    };
    
    customSettings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Additional user settings for Cursor";
    };
    
    customKeybindings = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [];
      description = "Additional keybindings for Cursor";
    };
  };

  config = lib.mkIf cfg.enable {
    # Create Cursor configuration files
    system.activationScripts.cursorSetup = {
      text = ''
        echo "Setting up Cursor configuration..."
        
        # Create configuration directories
        mkdir -p ${cfg.configDir}
        mkdir -p "${cfg.userConfigDir}"
        
        # Create MCP configuration
        ${lib.optionalString cfg.enableMcpServers ''
          cat > ${cfg.configDir}/mcp.json << 'EOF'
          {
            "mcpServers": ${builtins.toJSON cursorMcpServers}
          }
          EOF
        ''}
        
        # Create launch arguments configuration
        cat > ${cfg.configDir}/argv.json << 'EOF'
        ${builtins.toJSON cursorArgv}
        EOF
        
        # Create user settings
        cat > "${cfg.userConfigDir}/settings.json" << 'EOF'
        ${builtins.toJSON (cursorSettings // cfg.customSettings)}
        EOF
        
        # Create keybindings
        cat > "${cfg.userConfigDir}/keybindings.json" << 'EOF'
        ${builtins.toJSON (cursorKeybindings ++ cfg.customKeybindings)}
        EOF
        
        # Set proper permissions
        chmod 644 ${cfg.configDir}/*.json 2>/dev/null || true
        chmod 644 "${cfg.userConfigDir}"/*.json 2>/dev/null || true
        
        echo "Cursor configuration complete!"
      '';
    };
    
    # Ensure Node.js is available for MCP servers
    environment.systemPackages = with pkgs; [
      nodejs_20
      nodePackages.npm
    ];
    
    # Install MCP server packages if enabled
    system.activationScripts.cursorMcpSetup = lib.mkIf cfg.enableMcpServers {
      text = ''
        echo "Setting up Cursor MCP servers..."
        
        # Install global MCP packages if they don't exist
        if ! npm list -g @modelcontextprotocol/server-sequential-thinking &>/dev/null; then
          npm install -g @modelcontextprotocol/server-sequential-thinking
        fi
        
        if ! npm list -g @puppeteer/mcp-server &>/dev/null; then
          npm install -g @puppeteer/mcp-server
        fi
        
        if ! npm list -g @michaeltliu/mcp-server-playwright &>/dev/null; then
          npm install -g @michaeltliu/mcp-server-playwright
        fi
        
        if ! npm list -g mcp-omnisearch &>/dev/null; then
          npm install -g mcp-omnisearch
        fi
        
        if ! npm list -g openmemory &>/dev/null; then
          npm install -g openmemory
        fi
        
        echo "Cursor MCP servers setup complete!"
      '';
    };
  };
}