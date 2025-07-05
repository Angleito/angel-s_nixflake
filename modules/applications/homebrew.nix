{ config, lib, ... }:

{
  options = {
    applications.homebrew.enable = lib.mkEnableOption "Homebrew package manager";
    applications.homebrew.autoUpdate = lib.mkEnableOption "automatically update Homebrew" // { default = true; };
    applications.homebrew.autoUpgrade = lib.mkEnableOption "automatically upgrade Homebrew packages" // { default = true; };
  };

  config = lib.mkIf config.applications.homebrew.enable {
    # Homebrew configuration
    homebrew = {
      enable = true;
      
      # Keep Homebrew up to date
      onActivation = {
        autoUpdate = config.applications.homebrew.autoUpdate;
        cleanup = "zap"; # Remove unused formulae and casks
        upgrade = config.applications.homebrew.autoUpgrade;
      };
      
      # Taps - removed deprecated/unnecessary taps
      taps = [
        # homebrew/core and homebrew/cask are now built-in and don't need to be tapped
        # homebrew/services has been deprecated
      ];
      
      # Homebrew formulae (CLI tools)
      brews = [
        "mas" # Mac App Store CLI
      ];
      
      # Homebrew casks (GUI applications)
      casks = [
        "warp"           # Warp terminal
        "cursor"         # Cursor AI editor
        "brave-browser"  # Brave browser
        "orbstack"       # Docker/container management
        "zoom"           # Zoom video conferencing
        "slack"          # Slack messaging
      ];
      
      # Mac App Store apps (requires 'mas' brew)
      masApps = {
        # "App Name" = App_ID;
        # To find App IDs, use: mas search "app name"
        "GarageBand" = 682658836;
      };
    };
  };
}