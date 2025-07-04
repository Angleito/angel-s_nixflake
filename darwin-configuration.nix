{ config, pkgs, ... }:

{
  # Auto upgrade nix package and the daemon service
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;

  # Enable experimental features
  nix.settings.experimental-features = "nix-command flakes";

  # Set your username
  users.users.angel = {
    name = "angel";
    home = "/Users/angel";
  };

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
  ];

  # Homebrew configuration
  homebrew = {
    enable = true;
    
    # Keep Homebrew up to date
    onActivation = {
      autoUpdate = true;
      cleanup = "zap"; # Remove unused formulae and casks
      upgrade = true;
    };
    
    # Taps
    taps = [
      "homebrew/core"
      "homebrew/cask"
      "homebrew/services"
    ];
    
    # Homebrew formulae (CLI tools)
    brews = [
      "mas" # Mac App Store CLI
    ];
    
    # Homebrew casks (GUI applications)
    casks = [
      "warp"           # Warp terminal
      "cursor"         # Cursor AI editor
    ];
    
    # Mac App Store apps (requires 'mas' brew)
    masApps = {
      # "App Name" = App_ID;
      # To find App IDs, use: mas search "app name"
    };
  };

  # macOS system defaults
  system.defaults = {
    # Dock settings
    dock = {
      autohide = true;
      show-recents = false;
      minimize-to-application = true;
      mru-spaces = false; # Don't rearrange spaces
    };
    
    # Finder settings
    finder = {
      AppleShowAllExtensions = true;
      ShowPathbar = true;
      ShowStatusBar = true;
      FXEnableExtensionChangeWarning = false;
    };
    
    # Trackpad settings
    trackpad = {
      Clicking = true; # Tap to click
      TrackpadThreeFingerDrag = true;
    };
    
    # Other macOS settings
    NSGlobalDomain = {
      AppleKeyboardUIMode = 3; # Full keyboard access
      ApplePressAndHoldEnabled = false; # Key repeat
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
    };
  };

  # Used for backwards compatibility
  system.stateVersion = 4;
}
