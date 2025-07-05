{ config, pkgs, lib, ... }:

{
  options = {
    development.nodejs.enable = lib.mkEnableOption "Node.js development environment";
  };

  config = lib.mkIf config.development.nodejs.enable {
    # Install Node.js
    environment.systemPackages = with pkgs; [
      nodejs_20
    ];

    # Set up npm global directories for user
    system.activationScripts.npmSetup.text = ''
      USER_HOME="${config.users.users.${config.system.primaryUser}.home}"
      
      # Create npm global directories
      sudo -u ${config.system.primaryUser} mkdir -p "$USER_HOME/.npm-global" "$USER_HOME/.npm-cache"
      
      # Configure npm for user
      sudo -u ${config.system.primaryUser} bash -c "
        export HOME=$USER_HOME
        ${pkgs.nodejs_20}/bin/npm config set prefix $USER_HOME/.npm-global
        ${pkgs.nodejs_20}/bin/npm config set cache $USER_HOME/.npm-cache
      "
    '';
  };
}