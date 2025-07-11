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

    # Cargo-based installation scripts
    system.activationScripts.cargoInstallSui = lib.mkIf (config.development.web3.enableSui && config.development.web3.useCargoInstall) {
      text = ''
        USER_HOME="${config.users.users.${config.system.primaryUser}.home}"
        
        # Install sui CLI via cargo if not already installed
        if ! sudo -u ${config.system.primaryUser} command -v sui &> /dev/null; then
          echo "Installing sui CLI via cargo..."
          sudo -u ${config.system.primaryUser} /run/current-system/sw/bin/cargo install --locked sui-client
        fi
      '';
    };

    system.activationScripts.cargoInstallWalrus = lib.mkIf (config.development.web3.enableWalrus && config.development.web3.useCargoInstall) {
      text = ''
        USER_HOME="${config.users.users.${config.system.primaryUser}.home}"
        
        # Install walrus CLI via cargo if not already installed
        if ! sudo -u ${config.system.primaryUser} command -v walrus &> /dev/null; then
          echo "Installing walrus CLI via cargo..."
          sudo -u ${config.system.primaryUser} /run/current-system/sw/bin/cargo install --git https://github.com/MystenLabs/walrus.git --branch testnet walrus-cli
        fi
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