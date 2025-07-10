{ config, pkgs, lib, ... }:

let
  jsonUtils = import ./json-utils.nix { inherit lib; };
in

{
  # Set the primary user (required for the options below)
  system.primaryUser = "angel";
  
  # Nix configuration
  nix = {
    package = pkgs.nix;
    settings.experimental-features = "nix-command flakes";
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
  ];

  # Module configurations
  development = {
    rust.enable = true;
    nodejs.enable = true;
    web3 = {
      enable = true;
      enableSui = true;
      enableWalrus = true;
      enableVercel = true;
    };
  };

  # Program configurations
  programs = {
    git-env.enable = true;
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
  };

  applications.homebrew.enable = true;

  # Used for backwards compatibility
  system.stateVersion = 4;
}