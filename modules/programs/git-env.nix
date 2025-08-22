{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.git-env;
  
  # Script to update git config from .env
  updateGitConfigScript = pkgs.writeScriptBin "update-git-config" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    
    echo "Updating git configuration from .env file..."
    
    # Source .env file if it exists
    ENV_FILES=(
        "/Users/angel/Projects/nix-project/.env"
        "$HOME/.config/nix-project/.env"
        "$HOME/.env"
    )
    
    ENV_LOADED=false
    for env_file in "''${ENV_FILES[@]}"; do
        if [[ -f "$env_file" ]]; then
            echo "Loading environment from: $env_file"
            set -a
            source "$env_file"
            set +a
            ENV_LOADED=true
            break
        fi
    done
    
    if [[ "$ENV_LOADED" == false ]]; then
        echo "No .env file found"
        exit 1
    fi
    
    # Update git config if variables are available
    if [[ -n "''${GIT_NAME:-}" ]]; then
        echo "Setting git user.name to: $GIT_NAME"
        ${pkgs.git}/bin/git config --global user.name "$GIT_NAME"
    fi
    
    if [[ -n "''${GIT_EMAIL:-}" ]]; then
        echo "Setting git user.email to: $GIT_EMAIL"
        ${pkgs.git}/bin/git config --global user.email "$GIT_EMAIL"
    fi
    
    echo "Git configuration updated successfully!"
  '';
in
{
  options.programs.git-env = {
    enable = mkEnableOption "git configuration from environment variables";
    
    envFile = mkOption {
      type = types.str;
      default = "/Users/angel/Projects/nix-project/.env";
      description = "Path to the .env file containing git configuration";
    };
  };
  
  config = mkIf cfg.enable {
    # Add the update script to system packages
    environment.systemPackages = [ updateGitConfigScript ];
    
    # Create a launchd service to update git config on login (Darwin only)
    launchd = mkIf pkgs.stdenv.isDarwin {
      user.agents.git-env-update = {
        serviceConfig = {
          ProgramArguments = [ "${updateGitConfigScript}/bin/update-git-config" ];
          RunAtLoad = true;
          StandardOutPath = "/tmp/git-env-update.log";
          StandardErrorPath = "/tmp/git-env-update.log";
        };
      };
    };
  };
}