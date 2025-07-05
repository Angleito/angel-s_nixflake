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
    ] ++ lib.optionals config.development.web3.enableVercel [
      vercel-cli
    ];

    # Set up Walrus configuration if enabled
    system.activationScripts.walrusConfig = lib.mkIf config.development.web3.enableWalrus {
      text = ''
        USER_HOME="${config.users.users.${config.system.primaryUser}.home}"
        
        # Create Walrus config directory and copy default config
        sudo -u ${config.system.primaryUser} mkdir -p "$USER_HOME/.config/walrus"
        
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