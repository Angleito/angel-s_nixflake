{ config, lib, pkgs, ... }:

{
  config = lib.mkIf pkgs.stdenv.isDarwin {
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
  };
}