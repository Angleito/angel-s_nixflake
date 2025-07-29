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
    nodejs_20       # Node.js for npm and Claude Code
    
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
    
    # Claude alias to use npm global installation with skip permissions
    claude = "$HOME/.npm-global/bin/claude --dangerously-skip-permissions";
  };

  # Add local bin to PATH
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
    "$HOME/.npm-global/bin"  # For Claude Code and global npm packages
  ];

  # Main Claude configuration using Nix builtins.toJSON
  home.activation.claudeConfig = 
    let
      # Base Claude configuration
      claudeConfig = {
        version = "1.0.0";
        globalShortcuts = {};
      };
      
      # Convert to pretty JSON
      configJson = builtins.toJSON claudeConfig;
    in
    config.lib.dag.entryAfter ["writeBoundary"] ''
      # Create Claude configuration directory
      mkdir -p "$HOME/.config/claude"
      
      # Write the configuration file
      CLAUDE_CONFIG_PATH="$HOME/.claude.json"
      
      # Write the JSON configuration
      cat > "$CLAUDE_CONFIG_PATH" << 'EOF'
      ${configJson}
      EOF
      
      # Make the file writable
      chmod 644 "$CLAUDE_CONFIG_PATH"
    '';

  # Claude configuration is now handled by the claude-code module in darwin-configuration.nix
  # Add Claude MCP configuration and installation
  home.activation.claudeMcpConfig = config.lib.dag.entryAfter ["writeBoundary"] ''
    echo "Installing and configuring Claude Code..."
    
    # Configure npm for global installations
    mkdir -p "$HOME/.npm-global"
    
    # Use the npm from nix packages
    NPM_PATH="${pkgs.nodejs_20}/bin/npm"
    NODE_PATH="${pkgs.nodejs_20}/bin/node"
    
    if [ -x "$NPM_PATH" ]; then
      $NPM_PATH config set prefix "$HOME/.npm-global"
      export PATH="$HOME/.npm-global/bin:$PATH"
      
      # Install Claude Code CLI (latest version)
      echo "Installing Claude Code CLI..."
      $NPM_PATH install -g @anthropic-ai/claude-code || echo "Failed to install Claude Code"
    else
      echo "npm not found, skipping Claude Code installation"
    fi
    
    echo "Configuring Claude MCP servers..."
    
    # Create MCP server configuration
    MCP_SERVERS=$(cat << 'EOF'
    {
      "puppeteer": {
        "command": "npx",
        "args": ["-y", "@puppeteer/mcp-server"]
      },
      "playwright": {
        "command": "npx",
        "args": ["-y", "@michaeltliu/mcp-server-playwright"]
      },
      "mcp-omnisearch": {
        "command": "npx",
        "args": ["-y", "mcp-omnisearch"],
        "env": {
          "TAVILY_API_KEY": "''${TAVILY_API_KEY}",
          "BRAVE_API_KEY": "''${BRAVE_API_KEY}",
          "KAGI_API_KEY": "''${KAGI_API_KEY}",
          "PERPLEXITY_API_KEY": "''${PERPLEXITY_API_KEY}",
          "JINA_AI_API_KEY": "''${JINA_AI_API_KEY}",
          "FIRECRAWL_API_KEY": "''${FIRECRAWL_API_KEY}"
        }
      },
      "claude-flow": {
        "command": "/Users/angel/Projects/claude-flow/bin/claude-flow",
        "args": ["mcp", "start", "--transport", "stdio"],
        "env": {
          "NODE_ENV": "production"
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
    EOF
    )
    
    # Update ~/.claude.json with MCP servers
    JQ_PATH="${pkgs.jq}/bin/jq"
    
    if [ -f "$HOME/.claude.json" ]; then
      echo "$MCP_SERVERS" > /tmp/mcp-servers.json
      $JQ_PATH '.mcpServers = $servers' --slurpfile servers /tmp/mcp-servers.json "$HOME/.claude.json" > "$HOME/.claude.json.tmp" && \
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
    CURSOR_MCP_PATH="$HOME/.cursor/mcp.json"
    
    # Create .cursor directory if it doesn't exist
    mkdir -p "$HOME/.cursor"
    
    # Source the .env file - check multiple locations
    ENV_FILES=(
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
    
    # Create the MCP configuration for Cursor
    cat > "$CURSOR_MCP_PATH" << 'EOF'
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
            "PERPLEXITY_API_KEY": "''${PERPLEXITY_API_KEY:-}",
            "BRAVE_API_KEY": "''${BRAVE_API_KEY:-}",
            "TAVILY_API_KEY": "''${TAVILY_API_KEY:-}",
            "KAGI_API_KEY": "''${KAGI_API_KEY:-}",
            "JINA_AI_API_KEY": "''${JINA_AI_API_KEY:-}",
            "FIRECRAWL_API_KEY": "''${FIRECRAWL_API_KEY:-}"
          }
        },
        "claude-flow": {
          "command": "''${CLAUDE_FLOW_PATH:-/Users/angel/Projects/claude-flow/bin/claude-flow}",
          "args": ["mcp", "start", "--transport", "stdio"],
          "env": {
            "NODE_ENV": "production"
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
    
    # Make the file writable
    chmod 644 "$CURSOR_MCP_PATH"
  '';
}