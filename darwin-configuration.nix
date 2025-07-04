{ config, pkgs, ... }:

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
  
  # Fix nixbld group ID
  ids.gids.nixbld = 350;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    nodejs_20  # Include Node.js for npm
  ];
  
  # System-wide npm configuration and Claude Code CLI installation
  system.activationScripts.postActivation.text = ''
    # Configure npm globally for all users
    export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/nix/var/nix/profiles/default/bin"
    
    # Create npm global directory for the primary user
    sudo -u ${config.system.primaryUser} mkdir -p /Users/${config.system.primaryUser}/.npm-global
    
    # Configure npm to use global directory for the primary user
    sudo -u ${config.system.primaryUser} ${pkgs.nodejs_20}/bin/npm config set prefix /Users/${config.system.primaryUser}/.npm-global
    
    # Install Claude Code CLI globally
    if ! sudo -u ${config.system.primaryUser} test -f /Users/${config.system.primaryUser}/.npm-global/bin/claude; then
      echo "Installing Claude Code CLI system-wide..."
      sudo -u ${config.system.primaryUser} ${pkgs.nodejs_20}/bin/npm install -g @anthropic-ai/claude-code
      echo "Claude Code CLI installed successfully!"
    else
      echo "Claude Code CLI is already installed system-wide"
    fi
  '';

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
      "brave-browser"  # Brave browser
      "orbstack"       # Docker/container management
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
