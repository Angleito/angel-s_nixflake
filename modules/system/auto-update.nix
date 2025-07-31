{ config, lib, pkgs, ... }:

let
  cfg = config.system.autoUpdate;
in
{
  options.system.autoUpdate = {
    enable = lib.mkEnableOption "automatic package updates";
    
    interval = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      description = "How often to check for updates (daily, weekly, monthly)";
    };
  };

  config = lib.mkIf (pkgs.stdenv.isDarwin && cfg.enable) {
    # Create update scripts
    environment.systemPackages = with pkgs; [
      (writeScriptBin "update-all-packages" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        
        echo "🔄 Updating all package managers and their packages..."
        echo ""
        
        # Update Homebrew and all packages
        if command -v brew &> /dev/null; then
          echo "📦 Updating Homebrew..."
          brew update
          brew upgrade --greedy
          brew cleanup
          echo "✅ Homebrew updated"
          echo ""
        fi
        
        # Update npm packages globally
        if command -v npm &> /dev/null; then
          echo "📦 Updating npm packages..."
          # Update npm itself
          npm install -g npm@latest
          # List and update all global packages
          npm update -g
          # Clean cache
          npm cache clean --force
          echo "✅ npm packages updated"
          echo ""
        fi
        
        # Update cargo packages
        if command -v cargo &> /dev/null; then
          echo "📦 Updating cargo packages..."
          # Install cargo-update if not present
          cargo install cargo-update 2>/dev/null || true
          # Update all cargo packages
          cargo install-update -a
          echo "✅ Cargo packages updated"
          echo ""
        fi
        
        # Update pip packages
        if command -v pip3 &> /dev/null; then
          echo "📦 Updating pip packages..."
          # Update pip itself
          pip3 install --upgrade pip
          # Update all packages
          pip3 list --outdated --format=json | python3 -c "import json, sys; print('\n'.join([x['name'] for x in json.load(sys.stdin)]))" | xargs -n1 pip3 install -U 2>/dev/null || true
          echo "✅ pip packages updated"
          echo ""
        fi
        
        # Update gem packages
        if command -v gem &> /dev/null; then
          echo "📦 Updating gem packages..."
          gem update --system
          gem update
          gem cleanup
          echo "✅ gem packages updated"
          echo ""
        fi
        
        # Update nix flake
        if [ -f "${config.users.users.angel.home}/Projects/nix-project/flake.nix" ]; then
          echo "📦 Updating nix flake..."
          cd "${config.users.users.angel.home}/Projects/nix-project"
          nix flake update
          echo "✅ Nix flake updated"
          echo ""
        fi
        
        echo "✨ All package managers updated!"
      '')
    ];
    
    # Create launchd service for automatic updates
    launchd.agents.update-packages = {
      script = ''
        export PATH="${pkgs.nodejs_20}/bin:${pkgs.python3}/bin:${pkgs.ruby}/bin:$PATH"
        
        # Update Homebrew and all packages
        if command -v brew &> /dev/null; then
          echo "📦 Updating Homebrew..."
          brew update
          brew upgrade --greedy
          brew cleanup
          echo "✅ Homebrew updated"
        fi
        
        # Update npm packages globally
        if command -v npm &> /dev/null; then
          echo "📦 Updating npm packages..."
          npm install -g npm@latest
          npm update -g
          npm cache clean --force
          echo "✅ npm packages updated"
        fi
        
        # Update cargo packages
        if command -v cargo &> /dev/null; then
          echo "📦 Updating cargo packages..."
          cargo install cargo-update 2>/dev/null || true
          cargo install-update -a
          echo "✅ Cargo packages updated"
        fi
        
        # Update pip packages
        if command -v pip3 &> /dev/null; then
          echo "📦 Updating pip packages..."
          pip3 install --upgrade pip
          pip3 list --outdated --format=json | python3 -c "import json, sys; print('\n'.join([x['name'] for x in json.load(sys.stdin)]))" | xargs -n1 pip3 install -U 2>/dev/null || true
          echo "✅ pip packages updated"
        fi
        
        # Update gem packages
        if command -v gem &> /dev/null; then
          echo "📦 Updating gem packages..."
          gem update --system
          gem update
          gem cleanup
          echo "✅ gem packages updated"
        fi
        
        echo "✨ All package managers updated!"
      '';
      
      serviceConfig = {
        StartCalendarInterval = if cfg.interval == "daily" then
          [{ Hour = 3; Minute = 0; }]
        else if cfg.interval == "weekly" then
          [{ Weekday = 0; Hour = 3; Minute = 0; }]
        else # monthly
          [{ Day = 1; Hour = 3; Minute = 0; }];
        
        StandardOutPath = "/tmp/update-packages.log";
        StandardErrorPath = "/tmp/update-packages.error.log";
      };
    };
  };
}