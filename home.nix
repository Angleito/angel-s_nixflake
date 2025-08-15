{ config, pkgs, lib, ... }:

let
  # Simple JSON utilities for Claude configuration
  jsonUtils = import ./json-utils.nix { inherit lib; };
  
  # Convert string path to proper attribute set path
  pathList = lib.splitString "." "users.angel.programs.ssh.sshKeys";
  
  # Function to check if a value at a path exists
  hasPath = path: attrs: lib.hasAttrByPath (lib.splitString "." path) attrs;
  
  # Get value at path with default
  getPath = path: default: attrs: lib.getAttrFromPath (lib.splitString "." path) attrs;
in

{
  home.stateVersion = "25.05";
  
  # Git configuration is handled in ./home/git.nix
  
  imports = [
    ./home/git.nix
  ];

  home.packages = with pkgs; [
    # Development essentials
    # Node.js is managed by NVM, not included here
    
    # Core tools
    bat             # Better cat with syntax highlighting
    eza             # Better ls with modern features  
    fd              # Better find
    delta           # Better git diff viewer
    sd              # Better sed
    du-dust         # Better du
    procs           # Better ps
    bottom          # Better top/htop
    
    # Development tools
    gitui           # Terminal UI for git
    broot           # Interactive directory navigation
    xh              # Better HTTP client (like httpie)
    grex            # Generate regex from examples
    zoxide          # Smart cd with directory jumping
    
    # JSON/YAML/TOML tools
    jq              # JSON processor
    yq              # YAML processor
    gojq            # Go implementation of jq (faster)
    jless           # Interactive JSON viewer
    
    # Text processing
    choose          # Better cut
    ast-grep        # Structural search and replace
    
    # File tools
    lsd             # Better ls with icons
    broot           # Interactive tree
    dua             # Disk usage analyzer
    
    # Process management
    bandwhich       # Network utilization monitor
    zenith          # Better htop
    
    # Misc utilities
    pastel          # Color manipulation
    vivid           # LS_COLORS generator
    
    # Clipboard managers
    # pbcopy and pbpaste are built-in macOS commands
    
    # Code formatting/linting
    shfmt           # Shell script formatter
    shellcheck      # Shell script linter
    hadolint        # Dockerfile linter
    
    # Archive tools
    zip
    unzip
    p7zip
    
    # Search tools
    hyperfine       # Command-line benchmarking
    tokei           # Code statistics
    
    # Security tools
    bandwhich       # Network monitor
    gping           # Ping with graph
    
    # Data science
    visidata        # Terminal spreadsheet
    
    # Terminal multiplexer
    zellij          # Modern terminal workspace
    
    # Better shell experience
    starship        # Cross-shell prompt
    atuin           # Shell history sync
    navi            # Interactive cheatsheet
    mcfly           # Smart shell history
    
    # File watching
    watchexec       # Execute commands on file change
    
    # Modern replacements
    duf             # Better df
    gdu             # Better du with NCurses interface
    
    # Networking
    dogdns          # Better dig
    curlie          # Better curl
    xh              # Better HTTPie
    
    # Linters and formatters
    typos           # Spell checker for code
    
    # System monitoring
    btop            # Resource monitor
    
    # Fun but useful
    glow            # Markdown renderer in terminal
    slides          # Terminal presentation tool
    
    # Search and replace
    sad             # Simple find and replace CLI
    
    # File managers
    yazi            # Terminal file manager
    lf              # Terminal file manager
    
    # Process viewer
    pueue           # Command queue manager
    
    # Database tools
    usql            # Universal SQL CLI
    
    # Image processing
    viu             # Terminal image viewer
    
    # Docker/Container tools
    lazydocker      # Terminal UI for docker
    dive            # Docker image layer explorer
    
    # Hex viewer
    hexyl           # Command-line hex viewer
    
    # REPL for various languages
    evcxr           # Rust REPL
    
    # API testing
    hurl            # HTTP testing tool
    
    # Git tools
    gh              # GitHub CLI
    git-absorb      # Auto fixup commits
    
    # System info
    macchina        # Fast system info tool
    
    # CSV tools
    xan             # CSV toolkit (xsv replacement)
    
    # Modern Unix rewrites
    uutils-coreutils # Rust coreutils
  ];

  # Shell aliases
  home.shellAliases = {
    # Shortcuts for new tools
    ls = "eza";
    ll = "eza -la";
    la = "eza -a";
    lt = "eza --tree";
    cat = "bat";
    find = "fd";
    ps = "procs";
    grep = "rg";
    du = "dust";
    df = "duf";
    top = "btop";
    htop = "bottom";
    dig = "dog";
    
    # Git shortcuts
    g = "git";
    gs = "git status";
    ga = "git add";
    gc = "git commit";
    gp = "git push";
    gl = "git log";
    gd = "git diff";
    
    # Quick navigation
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
    
    # Safety nets
    cp = "cp -i";
    mv = "mv -i";
    rm = "rm -i";
    
    # Clipboard aliases
    copy = "pbcopy";
    paste = "pbpaste";
    
    # Quick edits
    zshrc = "vim ~/.zshrc";
    vimrc = "vim ~/.vimrc";
    
    # Docker shortcuts
    d = "docker";
    dc = "docker-compose";
    
    # Nix shortcuts
    nrs = "nix run nixpkgs#";
    nsh = "nix-shell";
    ndev = "nix develop";
    
    # Misc
    weather = "curl wttr.in";
    cheat = "curl cheat.sh/";
    
    # Claude alias removed - using nix package
  };

  # Add local bin to PATH
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
    "$HOME/.npm-global/bin"  # For global npm packages
  ];
  
  # Shell program configurations
  programs.zsh = {
    enable = true;
    initExtra = ''
      # Ensure basic system paths are available first
      # This fixes issues with basic commands not being found
      export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
      
      # Claude function to ensure NVM is loaded
      claude() {
        # Load NVM if not already loaded
        if [ -z "$NVM_DIR" ]; then
          export NVM_DIR="$HOME/.nvm"
          [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 2>/dev/null
        fi
        
        # Use the correct node version
        nvm use --delete-prefix v24.5.0 --silent 2>/dev/null || true
        
        # Execute claude from NVM
        command "$HOME/.nvm/versions/node/v24.5.0/bin/claude" "$@"
      }
    '';
  };
  
  programs.bash = {
    enable = true;
    initExtra = ''
      # Ensure basic system paths are available first
      # This fixes issues with basic commands not being found
      export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
      
      # Claude function to ensure NVM is loaded
      claude() {
        # Load NVM if not already loaded
        if [ -z "$NVM_DIR" ]; then
          export NVM_DIR="$HOME/.nvm"
          [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 2>/dev/null
        fi
        
        # Use the correct node version
        nvm use --delete-prefix v24.5.0 --silent 2>/dev/null || true
        
        # Execute claude from NVM
        command "$HOME/.nvm/versions/node/v24.5.0/bin/claude" "$@"
      }
    '';
  };

  # Main Claude configuration using Nix builtins.toJSON
  home.activation.claudeConfig = 
    let
      # Base Claude configuration
      claudeConfig = {
        version = "1.0.0";
        globalShortcuts = {};
        # MCP servers will be added by claudeMcpConfig
      };
      
      # Convert to pretty JSON
      configJson = builtins.toJSON claudeConfig;
    in
    config.lib.dag.entryAfter ["writeBoundary"] ''
      # Create Claude configuration directory
      mkdir -p "$HOME/.config/claude"
      
      # Write the configuration file only if it doesn't exist
      CLAUDE_CONFIG_PATH="$HOME/.claude.json"
      
      if [ ! -f "$CLAUDE_CONFIG_PATH" ]; then
        # Write the JSON configuration
        cat > "$CLAUDE_CONFIG_PATH" << 'EOF'
      ${configJson}
      EOF
        
        # Make the file writable
        chmod 644 "$CLAUDE_CONFIG_PATH"
      fi
    '';

  # Claude configuration is now handled by the claude-code module in darwin-configuration.nix
  # Add Claude MCP configuration and installation
  home.activation.claudeMcpConfig = config.lib.dag.entryAfter ["writeBoundary"] ''
    echo "Installing and configuring Claude Code..."
    
    # Load NVM for Node.js access
    export NVM_DIR="$HOME/.nvm"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
      \. "$NVM_DIR/nvm.sh" || echo "Warning: Failed to load NVM"
      
      # Use default node version if available
      if [ -f "$NVM_DIR/alias/default" ] && command -v nvm >/dev/null 2>&1; then
        DEFAULT_VERSION=$(cat "$NVM_DIR/alias/default")
        echo "Setting NVM default version to: $DEFAULT_VERSION"
        nvm use "$DEFAULT_VERSION" --silent 2>/dev/null || echo "Note: Using system Node.js version"
      else
        echo "Note: No default NVM version set or nvm command not available"
      fi
    else
      echo "Warning: NVM not found at $NVM_DIR"
    fi
    
    # Configure npm for global installations
    mkdir -p "$HOME/.npm-global"
    
    # Use npm from NVM
    NPM_PATH="$(which npm 2>/dev/null)"
    NODE_PATH="$(which node 2>/dev/null)"
    
    if [ -x "$NPM_PATH" ]; then
      $NPM_PATH config set prefix "$HOME/.npm-global"
      export PATH="$HOME/.npm-global/bin:$PATH"
      
      # Claude Code is installed via npm in NVM
      echo "Claude Code should be installed via npm globally"
    else
      echo "npm not found, skipping Claude Code installation"
    fi
    
echo "Installing Claude MCP servers..."
    
    # Install MCP servers one by one to handle failures gracefully
    echo "Installing filesystem server..."
    npm install -g @modelcontextprotocol/server-filesystem@latest || echo "Warning: Failed to install filesystem server"
    
    echo "Installing memory server..."
    npm install -g @modelcontextprotocol/server-memory@latest || echo "Warning: Failed to install memory server"
    
    echo "Installing sequential-thinking server..."
    npm install -g @modelcontextprotocol/server-sequential-thinking@latest || echo "Warning: Failed to install sequential-thinking server"
    
    echo "Installing puppeteer server..."
    npm install -g puppeteer-mcp-server@latest || echo "Warning: Failed to install puppeteer server"
    
    echo "Installing playwright server..."
    npm install -g @playwright/mcp@latest || echo "Warning: Failed to install playwright server"
    
    echo "Installing mcp-omnisearch..."
    npm install -g mcp-omnisearch@latest || echo "Warning: Failed to install mcp-omnisearch"
    
    # ruv-swarm might not exist or have issues, so we'll skip it for now
    # echo "Installing ruv-swarm..."
    # npm install -g ruv-swarm@latest || echo "Warning: Failed to install ruv-swarm"
    
    echo "Configuring Claude MCP servers..."
    
    # Source the .env file to load API keys
    if [ -f "/Users/angel/angelsnixconfig/.env" ]; then
      echo "Loading environment variables from .env file..."
      set -a  # automatically export all variables
      source "/Users/angel/angelsnixconfig/.env"
      set +a
    else
      echo "Warning: .env file not found at /Users/angel/angelsnixconfig/.env"
    fi

    # Create MCP server configuration template
    cat > /tmp/claude-mcp-template.json << 'MCPEOF'
    {
      "puppeteer": {
        "command": "npx",
        "args": ["-y", "puppeteer-mcp-server"]
      },
      "playwright": {
        "command": "npx",
        "args": ["-y", "@playwright/mcp"]
      },
      "mcp-omnisearch": {
        "command": "npx",
        "args": ["-y", "mcp-omnisearch"],
        "env": {
          "TAVILY_API_KEY": "$TAVILY_API_KEY",
          "BRAVE_API_KEY": "$BRAVE_API_KEY",
          "KAGI_API_KEY": "$KAGI_API_KEY",
          "PERPLEXITY_API_KEY": "$PERPLEXITY_API_KEY",
          "JINA_AI_API_KEY": "$JINA_AI_API_KEY",
          "FIRECRAWL_API_KEY": "$FIRECRAWL_API_KEY"
        }
      },
      "ruv-swarm": {
        "command": "npx",
        "args": ["-y", "ruv-swarm", "mcp", "start"],
        "env": {
          "NODE_ENV": "production"
        }
      },
      "sequential-thinking": {
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
      },
      "memory": {
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-memory"]
      },
      "filesystem": {
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/angel/Projects", "/Users/angel/Documents", "/Users/angel/.claude", "/tmp"]
      }
    }
MCPEOF
    
    # Substitute environment variables
    ENVSUBST_PATH="${pkgs.envsubst}/bin/envsubst"
    MCP_SERVERS=$("$ENVSUBST_PATH" < /tmp/claude-mcp-template.json)
    
    # Update ~/.claude.json with MCP servers
    JQ_PATH="${pkgs.jq}/bin/jq"
    
    if [ -f "$HOME/.claude.json" ]; then
      echo "$MCP_SERVERS" > /tmp/mcp-servers.json
      $JQ_PATH --slurp '.[0] as $orig | .[1] as $new | $orig | .mcpServers = $new' "$HOME/.claude.json" /tmp/mcp-servers.json > "$HOME/.claude.json.tmp" && \
      mv "$HOME/.claude.json.tmp" "$HOME/.claude.json"
      rm -f /tmp/mcp-servers.json
    else
      echo '{}' | $JQ_PATH --argjson servers "$MCP_SERVERS" '.mcpServers = $servers' > "$HOME/.claude.json"
    fi
    
    echo "Claude MCP configuration complete!"
  '';

  # Cursor MCP Configuration
  # Create the Cursor MCP configuration file with environment variable support
  home.activation.cursorMcpConfig = config.lib.dag.entryAfter ["writeBoundary"] ''
    # Load NVM for Node.js access
    export NVM_DIR="$HOME/.nvm"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
      \. "$NVM_DIR/nvm.sh" || echo "Warning: Failed to load NVM"
      
      # Use default node version if available
      if [ -f "$NVM_DIR/alias/default" ] && command -v nvm >/dev/null 2>&1; then
        DEFAULT_VERSION=$(cat "$NVM_DIR/alias/default")
        echo "Setting NVM default version to: $DEFAULT_VERSION"
        nvm use "$DEFAULT_VERSION" --silent 2>/dev/null || echo "Note: Using system Node.js version"
      else
        echo "Note: No default NVM version set or nvm command not available"
      fi
    else
      echo "Warning: NVM not found at $NVM_DIR"
    fi
    
    CURSOR_MCP_PATH="$HOME/.cursor/mcp.json"
    
    # Create .cursor directory if it doesn't exist
    mkdir -p "$HOME/.cursor"
    
    # Source the .env file - check multiple locations
    ENV_FILES=(
        "/Users/angel/angelsnixconfig/.env"
        "/Users/angel/Projects/nix-project/.env"
        "$HOME/.config/nix-project/.env"
        "$HOME/.env"
    )
    
    ENV_LOADED=false
    for env_file in "''${ENV_FILES[@]}"; do
        if [ -f "$env_file" ]; then
            set -a
            source "$env_file"
            set +a
            ENV_LOADED=true
            echo "Loaded environment from: $env_file"
            break
        fi
    done
    
    if [ "$ENV_LOADED" = false ]; then
        echo "Warning: No .env file found in expected locations"
    fi
    
    # Create the MCP configuration template for Cursor
    cat > /tmp/cursor-mcp-template.json << 'EOF'
    {
      "mcpServers": {
        "filesystem": {
          "command": "npx",
          "args": ["@modelcontextprotocol/server-filesystem", "/Users/angel/Projects", "/Users/angel/Documents"],
          "env": {}
        },
        "memory": {
          "command": "npx",
          "args": ["@modelcontextprotocol/server-memory"],
          "env": {}
        },
        "puppeteer": {
          "command": "npx",
          "args": ["@cloudflare/mcp-server-puppeteer"],
          "env": {}
        },
        "mcp-omnisearch": {
          "command": "npx",
          "args": ["mcp-omnisearch"],
          "env": {
            "PERPLEXITY_API_KEY": "$PERPLEXITY_API_KEY",
            "BRAVE_API_KEY": "$BRAVE_API_KEY",
            "TAVILY_API_KEY": "$TAVILY_API_KEY",
            "KAGI_API_KEY": "$KAGI_API_KEY",
            "JINA_AI_API_KEY": "$JINA_AI_API_KEY",
            "FIRECRAWL_API_KEY": "$FIRECRAWL_API_KEY"
          }
        },
        "ruv-swarm": {
          "command": "npx",
          "args": ["ruv-swarm", "mcp", "start"],
          "env": {
            "NODE_ENV": "production"
          }
        }
      }
    }
    EOF
    
    # Substitute environment variables
    ENVSUBST_PATH="${pkgs.envsubst}/bin/envsubst"
    "$ENVSUBST_PATH" < /tmp/cursor-mcp-template.json > "$CURSOR_MCP_PATH"
    
    # Make the file writable
    chmod 644 "$CURSOR_MCP_PATH"
  '';
}