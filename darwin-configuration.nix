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
    claude-code  # Latest Claude Code CLI
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
    git-env.enable = true;
    cursor.enable = true;
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
