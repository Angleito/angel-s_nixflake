{ config, lib, ... }:

{
  options = {
    system.xcode.autoInstall = lib.mkEnableOption "automatically install Xcode Command Line Tools";
  };

  config = lib.mkIf config.system.xcode.autoInstall {
    # Install Xcode Command Line Tools if not already installed
    system.activationScripts.xcodeTools.text = ''
      if ! xcode-select -p &> /dev/null; then
        echo "Installing Xcode Command Line Tools..."
        touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
        PROD=$(softwareupdate -l | grep "\\*.*Command Line" | tail -n 1 | sed 's/^[^:]*: //')
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
  };
}