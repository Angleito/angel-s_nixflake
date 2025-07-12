{ config, pkgs, lib, ... }:

{
  options = {
    development.web3.enable = lib.mkEnableOption "Web3 development tools";
    development.web3.enableSui = lib.mkEnableOption "Sui CLI";
    development.web3.enableWalrus = lib.mkEnableOption "Walrus CLI";
    development.web3.enableVercel = lib.mkEnableOption "Vercel CLI";
    development.web3.useCargoInstall = lib.mkEnableOption "Use cargo install instead of nix packages for Sui and Walrus";
  };

  config = lib.mkIf config.development.web3.enable {
    # Install Web3 development tools
    environment.systemPackages = with pkgs; [
      # Core development tools
      claude-code
    ] ++ lib.optionals (config.development.web3.enableSui && !config.development.web3.useCargoInstall) [
      sui-cli
    ] ++ lib.optionals (config.development.web3.enableWalrus && !config.development.web3.useCargoInstall) [
      walrus-cli
    ] ++ lib.optionals config.development.web3.enableVercel [
      vercel-cli
    ];

    # Enhanced cargo-based installation scripts with better lifecycle management
    system.activationScripts.cargoInstallSui = lib.mkIf (config.development.web3.enableSui && config.development.web3.useCargoInstall) {
      text = ''
        USER_HOME="${config.users.users.${config.system.primaryUser}.home}"
        CARGO_BIN_DIR="$USER_HOME/.cargo/bin"
        SUI_BIN="$CARGO_BIN_DIR/sui"
        
        # Create cargo bin directory if it doesn't exist
        sudo -u ${config.system.primaryUser} mkdir -p "$CARGO_BIN_DIR"
        
        # Check if sui CLI exists and is accessible
        if ! sudo -u ${config.system.primaryUser} test -f "$SUI_BIN" || ! sudo -u ${config.system.primaryUser} "$SUI_BIN" --version &>/dev/null; then
          echo "Installing/updating sui CLI via cargo..."
          
          # Remove old installation if it exists but is broken
          if sudo -u ${config.system.primaryUser} test -f "$SUI_BIN"; then
            sudo -u ${config.system.primaryUser} rm -f "$SUI_BIN"
          fi
          
          # Install with better error handling
          if sudo -u ${config.system.primaryUser} /run/current-system/sw/bin/cargo install --locked sui-client; then
            echo "✓ sui CLI installed successfully"
          else
            echo "✗ Failed to install sui CLI"
          fi
        else
          echo "✓ sui CLI already installed and working"
        fi
        
        # Ensure it's in PATH by creating symlink in /usr/local/bin if needed
        if [ -f "$SUI_BIN" ] && [ ! -L "/usr/local/bin/sui" ]; then
          ln -sf "$SUI_BIN" "/usr/local/bin/sui" 2>/dev/null || true
        fi
      '';
    };

    system.activationScripts.cargoInstallWalrus = lib.mkIf (config.development.web3.enableWalrus && config.development.web3.useCargoInstall) {
      text = ''
        USER_HOME="${config.users.users.${config.system.primaryUser}.home}"
        CARGO_BIN_DIR="$USER_HOME/.cargo/bin"
        WALRUS_BIN="$CARGO_BIN_DIR/walrus"
        
        # Create cargo bin directory if it doesn't exist
        sudo -u ${config.system.primaryUser} mkdir -p "$CARGO_BIN_DIR"
        
        # Check if walrus CLI exists and is accessible
        if ! sudo -u ${config.system.primaryUser} test -f "$WALRUS_BIN" || ! sudo -u ${config.system.primaryUser} "$WALRUS_BIN" --version &>/dev/null; then
          echo "Installing/updating walrus CLI via cargo..."
          
          # Remove old installation if it exists but is broken
          if sudo -u ${config.system.primaryUser} test -f "$WALRUS_BIN"; then
            sudo -u ${config.system.primaryUser} rm -f "$WALRUS_BIN"
          fi
          
          # Install with better error handling and timeout
          if timeout 300 sudo -u ${config.system.primaryUser} /run/current-system/sw/bin/cargo install --git https://github.com/MystenLabs/walrus.git --branch testnet walrus-cli; then
            echo "✓ walrus CLI installed successfully"
          else
            echo "✗ Failed to install walrus CLI (may have timed out)"
          fi
        else
          echo "✓ walrus CLI already installed and working"
        fi
        
        # Ensure it's in PATH by creating symlink in /usr/local/bin if needed
        if [ -f "$WALRUS_BIN" ] && [ ! -L "/usr/local/bin/walrus" ]; then
          ln -sf "$WALRUS_BIN" "/usr/local/bin/walrus" 2>/dev/null || true
        fi
      '';
    };
    
    # Cargo tool maintenance script
    system.activationScripts.cargoToolMaintenance = lib.mkIf config.development.web3.useCargoInstall {
      text = ''
        USER_HOME="${config.users.users.${config.system.primaryUser}.home}"
        
        # Create a maintenance script for cargo-installed tools
        cat > "$USER_HOME/.local/bin/update-web3-tools" << 'EOF'
        #!/bin/bash
        # Update cargo-installed web3 tools
        
        echo "Updating web3 tools installed via cargo..."
        
        ${lib.optionalString config.development.web3.enableSui ''
        if command -v sui &>/dev/null; then
          echo "Updating sui CLI..."
          cargo install --locked sui-client --force
        fi
        ''}
        
        ${lib.optionalString config.development.web3.enableWalrus ''
        if command -v walrus &>/dev/null; then
          echo "Updating walrus CLI..."
          cargo install --git https://github.com/MystenLabs/walrus.git --branch testnet walrus-cli --force
        fi
        ''}
        
        echo "Web3 tools update complete!"
        EOF
        
        # Make maintenance script executable
        chmod +x "$USER_HOME/.local/bin/update-web3-tools"
      '';
    };

    # Set up Walrus configuration directory if enabled
    system.activationScripts.walrusConfig = lib.mkIf config.development.web3.enableWalrus {
      text = ''
        USER_HOME="${config.users.users.${config.system.primaryUser}.home}"
        
        # Create Walrus configuration directory
        sudo -u ${config.system.primaryUser} mkdir -p "$USER_HOME/.config/walrus"
        
        # Copy default config if it doesn't exist or if using cargo install
        CONFIG_FILE="$USER_HOME/.config/walrus/client_config.yaml"
        if [ ! -f "$CONFIG_FILE" ] || ${lib.boolToString config.development.web3.useCargoInstall}; then
          # Create default walrus config when using cargo install
          sudo -u ${config.system.primaryUser} cat > "$CONFIG_FILE" << 'EOF'
system_object: 0x70a61a5cf43b2c00aacf57e6784f5c8a09b4dd68de16f96b7c5a3bb5c3c8c04e5
storage_nodes:
  - name: wal-devnet-0
    rpc_url: https://rpc-walrus-testnet.nodes.guru:443
    rest_url: https://storage.testnet.sui.walrus.site/v1
  - name: wal-devnet-1
    rpc_url: https://walrus-testnet-rpc.bartestnet.com
    rest_url: https://walrus-testnet-storage.bartestnet.com/v1
  - name: wal-devnet-2
    rpc_url: https://walrus-testnet.blockscope.net
    rest_url: https://walrus-testnet-storage.blockscope.net/v1
  - name: wal-devnet-3
    rpc_url: https://walrus-testnet-rpc.nodes.guru
    rest_url: https://walrus-testnet-storage.nodes.guru/v1
  - name: wal-devnet-4
    rpc_url: https://walrus.testnet.arcadia.global
    rest_url: https://walrus-storage.testnet.arcadia.global/v1
EOF
        elif [ ! -f "$CONFIG_FILE" ]; then
          sudo -u ${config.system.primaryUser} cp ${pkgs.walrus-cli}/share/walrus/client_config.yaml "$CONFIG_FILE"
        fi
      '';
    };

    # Ensure required dependencies are enabled
    development.rust.enable = lib.mkIf config.development.web3.enableSui true;
    development.nodejs.enable = lib.mkIf config.development.web3.enableVercel true;
  };
}