{ config, pkgs, lib, ... }:

{
  # Set the primary user (required for the options below)
  system.primaryUser = "angel";
  
  # Nix configuration
  nix = {
    # Disable nix-darwin's management for Determinate compatibility
    enable = false;
    # package = pkgs.nix;
    # settings.experimental-features = "nix-command flakes";
  };

  # Set your username
  users.users.angel = {
    name = "angel";
    home = "/Users/angel";
  };
  
  # Set nixbld group ID to match existing installation
  ids.gids.nixbld = 350;

  # Core system packages
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    # claude-code is installed via npm/NVM, not as a Nix package
  ];

  # Import modules
  imports = [
    ./modules/default.nix
  ];

  # Module configurations
  development = {
    rust.enable = true;
    nodejs.enable = true;
    web3 = {
      enable = true;
      enableSui = true;     # Using cargo installation
      enableWalrus = true;  # Using cargo installation
      enableVercel = true;
      useCargoInstall = true; # New flag to use cargo instead of nix packages
    };
    database = {
      enable = true;
      postgresql.enable = true;
      postgresql.version = "14";
    };
  };
  
  # Program configurations
  programs = {
    claude-code = {
      enable = true;
      configDir = "$HOME/.claude";
      scriptsDir = "$HOME/.claude/scripts";
      enableMcpServers = true;
    };
    mcp = {
      enable = true;
      servers = {
        puppeteer = {
          command = "npx";
          args = [ "-y" "@puppeteer/mcp-server" ];
        };
        playwright = {
          command = "npx";
          args = [ "-y" "@michaeltliu/mcp-server-playwright" ];
        };
        "claude-flow" = {
          command = "/Users/angel/Projects/claude-flow/bin/claude-flow";
          args = [ "mcp" "start" "--transport" "stdio" ];
          env = {
            NODE_ENV = "production";
          };
        };
        "ruv-swarm" = {
          command = "npx";
          args = [ "-y" "ruv-swarm" "mcp" "start" ];
          env = {
            NODE_ENV = "production";
          };
        };
        "sequential-thinking" = {
          command = "npx";
          args = [ "-y" "@modelcontextprotocol/server-sequential-thinking" ];
        };
        memory = {
          command = "npx";
          args = [ "-y" "@modelcontextprotocol/server-memory" ];
        };
        filesystem = {
          command = "npx";
          args = [ "-y" "@modelcontextprotocol/server-filesystem" "/Users/angel/Projects" "/Users/angel/Documents" "/Users/angel/.claude" "/tmp" ];
        };
        "qdrant-code-search" = {
          command = "$HOME/.local/share/mcp-servers/qdrant-code-search/venv/bin/python";
          args = [ "$HOME/.local/share/mcp-servers/qdrant-code-search/server.py" ];
          env = {
            QDRANT_URL = "http://localhost:6333";
            EMBEDDING_MODEL = "openai/text-embedding-3-large";  # Better quality
            COLLECTION_PREFIX = "claude-code";
            VECTOR_SIZE = "3072";  # Matches text-embedding-3-large
            CHUNK_SIZE = "1000";
            SEARCH_LIMIT = "10";
            SIMILARITY_THRESHOLD = "0.7";
            OPENAI_API_KEY = "";  # To be set by user via environment variable
            BATCH_SIZE = "50";
            MAX_CONCURRENT_REQUESTS = "5";
          };
        };
        "hrm-reasoning" = {
          command = "uv";
          args = [ "run" "--project" "/Users/angel/Projects/hrmmcp" "python" "-m" "src.hrm_mcp_server" ];
          env = {
            PYTHONPATH = "/Users/angel/Projects/hrmmcp";
          };
        };
      };
    };
    git-env.enable = true;
    cursor.enable = true;
    orbstack = {
      enable = true;
      dockerCompat = true;
      shellAliases = true;
      dockerSocketSymlink = true;
    };
  };

  system = {
    power = {
      preventDisplaySleep = true;
      preventSystemSleep = true;
      preventDiskSleep = true;
    };
    xcode.autoInstall = true;
    environment = {
      enableEnvManagement = true;
      defaultVariables = {
        EDITOR = "vim";
        PAGER = "less";
        BROWSER = "open";
      };
    };
    autoUpdate = {
      enable = true;
      interval = "daily";  # Options: daily, weekly, monthly
    };
  };

  applications.homebrew.enable = true;

  # Used for backwards compatibility
  system.stateVersion = 4;
}
