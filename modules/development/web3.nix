{ config, pkgs, lib, ... }:

{
  options = {
    development.web3.enable = lib.mkEnableOption "Web3 development tools";
    development.web3.enableSui = lib.mkEnableOption "Sui CLI";
    development.web3.enableWalrus = lib.mkEnableOption "Walrus CLI";
    development.web3.enableVercel = lib.mkEnableOption "Vercel CLI";
  };

  config = lib.mkIf config.development.web3.enable {
    # Install Web3 development tools
    environment.systemPackages = with pkgs; [
      # Core development tools
      claude-code
    ] ++ lib.optionals config.development.web3.enableSui [
      sui-cli
    ] ++ lib.optionals config.development.web3.enableWalrus [
      walrus-cli
      suiup
    ] ++ lib.optionals config.development.web3.enableVercel [
      vercel-cli
    ];

    # Set up Walrus via suiup if enabled
    system.activationScripts.walrusConfig = lib.mkIf config.development.web3.enableWalrus {
      text = ''
        USER_HOME="${config.users.users.${config.system.primaryUser}.home}"
        
        # Create Walrus directories
        sudo -u ${config.system.primaryUser} mkdir -p "$USER_HOME/.config/walrus"
        sudo -u ${config.system.primaryUser} mkdir -p "$USER_HOME/.suiup"
        sudo -u ${config.system.primaryUser} mkdir -p "$USER_HOME/.local/bin"
        
        # Install Walrus via suiup
        sudo -u ${config.system.primaryUser} bash -c "
          export HOME=$USER_HOME
          export SUIUP_HOME=$USER_HOME/.suiup
          export SUIUP_DEFAULT_BIN_DIR=$USER_HOME/.local/bin
          export PATH=$USER_HOME/.local/bin:$PATH
          
          # Install walrus using suiup
          ${pkgs.suiup}/bin/suiup install walrus --latest || true
        "
        
        # Copy default config if it doesn't exist
        if [ ! -f "$USER_HOME/.config/walrus/client_config.yaml" ]; then
          sudo -u ${config.system.primaryUser} cp ${pkgs.walrus-cli}/share/walrus/client_config.yaml "$USER_HOME/.config/walrus/"
        fi
      '';
    };

    # Ensure required dependencies are enabled
    development.rust.enable = lib.mkIf config.development.web3.enableSui true;
    development.nodejs.enable = lib.mkIf config.development.web3.enableVercel true;
  };
}