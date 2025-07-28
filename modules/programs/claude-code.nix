{ config, lib, pkgs, ... }:

let
  cfg = config.programs.claude-code;
  
  # MCP server configurations for Claude Code
  mcpServers = {
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
    claude-flow = {
      command = "/Users/angel/Projects/claude-flow/bin/claude-flow";
      args = [ "mcp" "start" "--transport" "stdio" ];
      env = {
        NODE_ENV = "production";
      };
    };
    ruv-swarm = {
      command = "npx";
      args = [ "ruv-swarm" "mcp" "start" ];
      env = {
        NODE_ENV = "production";
      };
    };
  };

  # Memory integration scripts
  memoryScripts = {
    "memory-retrieve.sh" = ''
      #!/bin/bash
      # Memory retrieval script for Claude Code pre-hook
      
      set -e
      
      # Source environment variables
      if [ -f ~/.env ]; then
        source ~/.env
      fi
      
      # Get repository context
      REPO_ID=$(${cfg.scriptsDir}/repo-identifier.sh 2>/dev/null || echo "default")
      
      # Retrieve memories if mem0 is available
      if command -v python3 &> /dev/null && python3 -c "import mem0" 2>/dev/null; then
        python3 -c "
      import mem0
      import os
      import json
      
      try:
          client = mem0.Memory()
          memories = client.search('$1', user_id='$REPO_ID')
          if memories:
              print(json.dumps({'memories': memories}, indent=2))
      except Exception:
          pass
      "
      fi
    '';
    
    "memory-save.sh" = ''
      #!/bin/bash
      # Memory storage script for Claude Code post-hook
      
      set -e
      
      # Source environment variables
      if [ -f ~/.env ]; then
        source ~/.env
      fi
      
      # Get repository context
      REPO_ID=$(${cfg.scriptsDir}/repo-identifier.sh 2>/dev/null || echo "default")
      
      # Save memory if mem0 is available and content provided
      if command -v python3 &> /dev/null && python3 -c "import mem0" 2>/dev/null && [ -n "$1" ]; then
        python3 -c "
      import mem0
      import sys
      
      try:
          client = mem0.Memory()
          client.add('$1', user_id='$REPO_ID')
      except Exception:
          pass
      "
      fi
    '';
    
    "repo-identifier.sh" = ''
      #!/bin/bash
      # Generate repository identifier for memory context
      
      # Try to get git repository info
      if git rev-parse --is-inside-work-tree &>/dev/null; then
        REPO_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")
        if [ -n "$REPO_URL" ]; then
          echo "$REPO_URL" | sed -E 's|.*[:/]([^/]+/[^/]+)\.git.*|\1|' | tr '/' '_'
        else
          basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
        fi
      else
        basename "$(pwd)"
      fi
    '';
    
    "test-memory.sh" = ''
      #!/bin/bash
      # Test memory integration
      
      echo "Testing Claude Code memory integration..."
      
      # Check if mem0 is available
      if command -v python3 &> /dev/null && python3 -c "import mem0" 2>/dev/null; then
        echo "✓ mem0 is available"
      else
        echo "✗ mem0 not available - install with: pip install mem0ai"
        exit 1
      fi
      
      # Test repository identifier
      REPO_ID=$(${./scripts/repo-identifier.sh})
      echo "✓ Repository ID: $REPO_ID"
      
      # Test memory storage
      ${./scripts/memory-save.sh} "Test memory entry from $(date)"
      echo "✓ Memory save test completed"
      
      # Test memory retrieval
      RESULT=$(${./scripts/memory-retrieve.sh} "test")
      echo "✓ Memory retrieve test completed"
      
      echo "Memory integration test complete!"
    '';
  };

  # Claude Code settings configuration
  claudeSettings = {
    environment = {
      CLAUDE_CODE_TELEMETRY = "false";
      CLAUDE_CODE_API_KEY = "\${CLAUDE_CODE_API_KEY:-}";
    };
    
    tools = {
      allowed = [
        "Bash" "Glob" "Grep" "LS" "exit_plan_mode" "Read" "Edit" "MultiEdit"
        "Write" "NotebookRead" "NotebookEdit" "WebFetch" "TodoRead" "TodoWrite"
        "WebSearch" "Task"
      ];
    };
    
    limits = {
      maxFileSize = 10485760;
      maxContextWindow = 200000;
    };
    
    hooks = {
      pre = {
        "*" = "${cfg.scriptsDir}/memory-retrieve.sh \"$CLAUDE_ARGS\"";
      };
      post = {
        "*" = "${cfg.scriptsDir}/memory-save.sh \"$CLAUDE_OUTPUT\"";
      };
    };
    
    mcpServers = mcpServers;
  };

in {
  options.programs.claude-code = {
    enable = lib.mkEnableOption "Claude Code configuration management";
    
    configDir = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/.claude";
      description = "Directory for Claude Code configuration";
    };
    
    scriptsDir = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/.claude/scripts";
      description = "Directory for Claude Code scripts";
    };
    
    enableMemoryIntegration = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable memory integration with mem0";
    };
    
    enableMcpServers = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable MCP server configurations";
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure Python packages are available for memory integration
    environment.systemPackages = with pkgs; [
      python3
      python3Packages.pip
    ];

    # Create Claude Code configuration files
    system.activationScripts.claudeCodeSetup = {
      text = ''
        echo "Setting up Claude Code configuration..."
        
        # Create configuration directory
        mkdir -p ${cfg.configDir}
        mkdir -p ${cfg.scriptsDir}
        
        # Create settings.json
        cat > ${cfg.configDir}/settings.json << 'EOF'
        ${builtins.toJSON claudeSettings}
        EOF
        
        # Create memory integration scripts
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: content: ''
          cat > ${cfg.scriptsDir}/${name} << 'SCRIPT_EOF'
          ${content}
          SCRIPT_EOF
          chmod +x ${cfg.scriptsDir}/${name}
        '') memoryScripts)}
        
        # Create Claude wrapper script
        cat > ${cfg.configDir}/claude-wrapper.sh << 'EOF'
        #!/bin/bash
        # Claude Code wrapper with environment loading
        
        # Source environment files in order of precedence
        for env_file in ~/.env ~/Projects/nix-project/.env ~/config/.env; do
          if [ -f "$env_file" ]; then
            set -a
            source "$env_file"
            set +a
          fi
        done
        
        # Bypass macOS gatekeeper if needed
        if [[ "$OSTYPE" == "darwin"* ]]; then
          export CLAUDE_CODE_BYPASS_GATEKEEPER=1
        fi
        
        # Execute Claude Code with all arguments
        exec claude-code "$@"
        EOF
        chmod +x ${cfg.configDir}/claude-wrapper.sh
        
        echo "Claude Code configuration complete!"
      '';
    };
    
    # Add claude wrapper to PATH via shell alias
    environment.shellAliases = {
      claude = "${cfg.configDir}/claude-wrapper.sh";
    };
    
    # Install mem0 for memory integration if enabled
    system.activationScripts.mem0Setup = lib.mkIf cfg.enableMemoryIntegration {
      text = ''
        if ! python3 -c "import mem0" 2>/dev/null; then
          echo "Installing mem0 for Claude Code memory integration..."
          python3 -m pip install --user mem0ai
        fi
      '';
    };
  };
}