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
    claude-code   # NEW – install from nixpkgs instead of npm
  ];
  
  # System-wide npm configuration for other CLI tools
  system.activationScripts.postActivation.text = ''
    # Configure npm globally for all users
    export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/nix/var/nix/profiles/default/bin"
    
    # Create npm global directory for the primary user
    sudo -u ${config.system.primaryUser} mkdir -p /Users/${config.system.primaryUser}/.npm-global
    
    # Configure npm to use global directory for the primary user
    sudo -u ${config.system.primaryUser} ${pkgs.nodejs_20}/bin/npm config set prefix /Users/${config.system.primaryUser}/.npm-global
    
    # Install Sui CLI
    if ! sudo -u ${config.system.primaryUser} test -f /Users/${config.system.primaryUser}/.npm-global/bin/sui; then
      echo "Installing Sui CLI..."
      sudo -u ${config.system.primaryUser} ${pkgs.nodejs_20}/bin/npm install -g @mysten/sui
      echo "Sui CLI installed successfully!"
    else
      echo "Sui CLI is already installed"
    fi
    
    # Install Walrus CLI
    if ! sudo -u ${config.system.primaryUser} test -f /Users/${config.system.primaryUser}/.npm-global/bin/walrus; then
      echo "Installing Walrus CLI..."
      sudo -u ${config.system.primaryUser} ${pkgs.nodejs_20}/bin/npm install -g @mysten/walrus
      echo "Walrus CLI installed successfully!"
    else
      echo "Walrus CLI is already installed"
    fi
    
    # Install Sei CLI (if available as npm package)
    if ! sudo -u ${config.system.primaryUser} test -f /Users/${config.system.primaryUser}/.npm-global/bin/sei; then
      echo "Installing Sei CLI..."
      # Note: Sei CLI might need to be installed differently if not available via npm
      # Check if sei-cli package exists, otherwise install via other method
      if sudo -u ${config.system.primaryUser} ${pkgs.nodejs_20}/bin/npm view sei-chain > /dev/null 2>&1; then
        sudo -u ${config.system.primaryUser} ${pkgs.nodejs_20}/bin/npm install -g sei-chain
      else
        echo "Sei CLI npm package not found, installing via binary download..."
        # Download and install Sei CLI binary for macOS
        if [[ "$(uname -m)" == "arm64" ]]; then
          curl -L https://github.com/sei-protocol/sei-chain/releases/latest/download/seid-darwin-arm64 -o /tmp/seid
        else
          curl -L https://github.com/sei-protocol/sei-chain/releases/latest/download/seid-darwin-amd64 -o /tmp/seid
        fi
        chmod +x /tmp/seid
        sudo -u ${config.system.primaryUser} mkdir -p /Users/${config.system.primaryUser}/.local/bin
        sudo -u ${config.system.primaryUser} mv /tmp/seid /Users/${config.system.primaryUser}/.local/bin/sei
      fi
      echo "Sei CLI installed successfully!"
    else
      echo "Sei CLI is already installed"
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
