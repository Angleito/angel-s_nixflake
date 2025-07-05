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
  
  # Power management settings - prevent display from turning off
  system.activationScripts.powerManagement.text = ''
    echo "Configuring power management settings..."
    
    # Prevent display from sleeping (0 = never)
    pmset -a displaysleep 0
    
    # Prevent system from sleeping when on AC power (0 = never)
    pmset -c sleep 0
    
    # Prevent disk from sleeping
    pmset -a disksleep 0
    
    # Keep the system awake when the display is off
    pmset -a powernap 0
    
    # Prevent automatic sleep when on AC power
    pmset -c autopoweroff 0
    
    # Optional: Keep display awake even when system is idle
    pmset -a lessbright 0
    
    echo "Power management settings configured"
  '';
  
  # Install Xcode Command Line Tools if not already installed
  system.activationScripts.xcodeTools.text = ''
    if ! xcode-select -p &> /dev/null; then
      echo "Installing Xcode Command Line Tools..."
      touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
      PROD=$(softwareupdate -l | grep "\*.*Command Line" | tail -n 1 | sed 's/^[^:]*: //')
      if [ -n "$PROD" ]; then
        softwareupdate -i "$PROD" --verbose
      else
        echo "Could not find Xcode Command Line Tools in software update catalog"
        echo "You may need to install manually with: xcode-select --install"
      fi
      rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    else
      echo "Xcode Command Line Tools already installed"
    fi
  '';
  
  # System-wide npm configuration for other CLI tools
  system.activationScripts.postActivation.text = ''
    # Configure npm globally for all users
    export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/nix/var/nix/profiles/default/bin"
    
    # Create npm global directory for the primary user
    sudo -u ${config.system.primaryUser} mkdir -p /Users/${config.system.primaryUser}/.npm-global
    sudo -u ${config.system.primaryUser} mkdir -p /Users/${config.system.primaryUser}/.npm-cache
    
    # Note: npm configuration moved to user-level to avoid permission issues
    # Users can configure npm manually with:
    # npm config set prefix ~/.npm-global
    # npm config set cache ~/.npm-cache
    
    # Install Sei CLI via binary download (avoiding npm permission issues)
    if ! sudo -u ${config.system.primaryUser} test -f /Users/${config.system.primaryUser}/.local/bin/sei; then
      echo "Installing Sei CLI..."
      sudo -u ${config.system.primaryUser} mkdir -p /Users/${config.system.primaryUser}/.local/bin
      # Download and install Sei CLI binary for macOS
      if [[ "$(uname -m)" == "arm64" ]]; then
        curl -L https://github.com/sei-protocol/sei-chain/releases/latest/download/seid-darwin-arm64 -o /tmp/seid
      else
        curl -L https://github.com/sei-protocol/sei-chain/releases/latest/download/seid-darwin-amd64 -o /tmp/seid
      fi
      sudo chown ${config.system.primaryUser}:staff /tmp/seid
      chmod +x /tmp/seid
      sudo -u ${config.system.primaryUser} mv /tmp/seid /Users/${config.system.primaryUser}/.local/bin/sei
      echo "Sei CLI installed successfully!"
    else
      echo "Sei CLI is already installed"
    fi
    
    # Note: Sui and Walrus CLI installations moved to user-level to avoid permission issues
    # Users can install them manually with: npm install -g @mysten/sui @mysten/walrus
    echo "📝 To install Sui and Walrus CLI tools, run:"
    echo "   npm install -g @mysten/sui @mysten/walrus"
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

  # macOS system defaults
  system.defaults = {
    # Dock settings
    dock = {
      autohide = false; # Keep dock visible
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
