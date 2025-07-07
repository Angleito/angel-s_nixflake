{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.system.environment;
  
  # Script to setup .env file from .env.sample
  envSetupScript = pkgs.writeShellScript "setup-env" ''
    set -euo pipefail
    
    ENV_FILE="$HOME/.config/nix-project/.env"
    ENV_SAMPLE="$HOME/.config/nix-project/.env.sample"
    
    echo "🔧 Setting up environment configuration..."
    
    # Create config directory if it doesn't exist
    mkdir -p "$(dirname "$ENV_FILE")"
    
    # Copy .env.sample to .env if .env doesn't exist
    if [[ ! -f "$ENV_FILE" ]]; then
      if [[ -f "$ENV_SAMPLE" ]]; then
        cp "$ENV_SAMPLE" "$ENV_FILE"
        echo "✅ Created $ENV_FILE from sample"
        echo "📝 Please edit $ENV_FILE with your actual values"
      else
        echo "❌ No .env.sample file found at $ENV_SAMPLE"
        echo "Creating minimal .env file..."
        cat > "$ENV_FILE" << 'EOF'
# Git configuration
GIT_NAME="Your Name"
GIT_EMAIL="your@email.com"

# API Keys (optional)
TAVILY_API_KEY=""
BRAVE_API_KEY=""
KAGI_API_KEY=""
PERPLEXITY_API_KEY=""
JINA_AI_API_KEY=""
FIRECRAWL_API_KEY=""
EOF
        echo "✅ Created minimal $ENV_FILE"
      fi
    else
      echo "ℹ️  $ENV_FILE already exists"
    fi
    
    # Make sure the file is readable only by the user
    chmod 600 "$ENV_FILE"
    
    echo "🔒 Set secure permissions on $ENV_FILE"
    echo "🎉 Environment setup complete!"
    echo ""
    echo "To edit your environment variables, run:"
    echo "  $EDITOR $ENV_FILE"
  '';
  
  # Script to deploy configuration files across systems
  deployScript = pkgs.writeShellScript "deploy-env-config" ''
    set -euo pipefail
    
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    CONFIG_DIR="$HOME/.config/nix-project"
    
    echo "🚀 Deploying environment configuration across systems..."
    
    # Create config directory structure
    mkdir -p "$CONFIG_DIR"
    
    # Copy configuration files to user config directory
    if [[ -f "$SCRIPT_DIR/../../.env.sample" ]]; then
      cp "$SCRIPT_DIR/../../.env.sample" "$CONFIG_DIR/.env.sample"
      echo "✅ Deployed .env.sample to $CONFIG_DIR"
    fi
    
    # Copy any additional config files
    if [[ -f "$SCRIPT_DIR/../../.envrc" ]]; then
      cp "$SCRIPT_DIR/../../.envrc" "$CONFIG_DIR/.envrc"
      echo "✅ Deployed .envrc to $CONFIG_DIR"
    fi
    
    # Run environment setup
    ${envSetupScript}
    
    echo "📦 Configuration deployment complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Edit $CONFIG_DIR/.env with your actual values"
    echo "  2. Run 'direnv allow' in your project directories"
    echo "  3. Your environment variables will be automatically loaded"
  '';
  
  # Script to sync environment variables to system
  syncEnvScript = pkgs.writeShellScript "sync-env-vars" ''
    set -euo pipefail
    
    ENV_FILE="$HOME/.config/nix-project/.env"
    
    if [[ -f "$ENV_FILE" ]]; then
      echo "🔄 Syncing environment variables from $ENV_FILE"
      
      # Source the .env file in a safe way
      while IFS= read -r line; do
        # Skip empty lines and comments
        if [[ "$line" =~ ^[[:space:]]*$ ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
          continue
        fi
        
        # Export the variable
        if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
          export "''${BASH_REMATCH[1]}"="''${BASH_REMATCH[2]//\"/}"
        fi
      done < "$ENV_FILE"
      
      echo "✅ Environment variables synchronized"
    else
      echo "⚠️  No .env file found at $ENV_FILE"
      echo "Run 'nix run .#setup-env' to create one"
    fi
  '';

in {
  options = {
    system.environment = {
      enableEnvManagement = mkEnableOption "Enable environment variable management";
      
      defaultVariables = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Default environment variables to set system-wide";
        example = {
          EDITOR = "vim";
          BROWSER = "firefox";
        };
      };
      
      envFilePath = mkOption {
        type = types.str;
        default = "$HOME/.config/nix-project/.env";
        description = "Path to the .env file";
      };
    };
  };
  
  config = mkIf cfg.enableEnvManagement {
    # Set default environment variables
    environment.variables = cfg.defaultVariables;
    
    # Add environment management scripts to system packages
    environment.systemPackages = with pkgs; [
      (writeShellScriptBin "setup-env" ''
        exec ${envSetupScript} "$@"
      '')
      
      (writeShellScriptBin "deploy-env-config" ''
        exec ${deployScript} "$@"
      '')
      
      (writeShellScriptBin "sync-env-vars" ''
        exec ${syncEnvScript} "$@"
      '')
    ];
    
    # Create a launchd service to ensure environment is set up on login
    launchd.user.agents.env-setup = {
      serviceConfig = {
        ProgramArguments = [ "${envSetupScript}" ];
        RunAtLoad = true;
        StandardOutPath = "/tmp/env-setup.log";
        StandardErrorPath = "/tmp/env-setup.log";
      };
    };
    
    # Add shell integration for automatic environment loading
    programs.zsh.enable = true;
    programs.zsh.interactiveShellInit = ''
      # Load environment variables from .env file
      if [[ -f "$HOME/.config/nix-project/.env" ]]; then
        set -a
        source "$HOME/.config/nix-project/.env"
        set +a
      fi
    '';
    
    programs.bash.enable = true;
    programs.bash.interactiveShellInit = ''
      # Load environment variables from .env file
      if [[ -f "$HOME/.config/nix-project/.env" ]]; then
        set -a
        source "$HOME/.config/nix-project/.env"
        set +a
      fi
    '';
  };
}
