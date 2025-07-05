{ config, pkgs, lib, ... }:

{
  options = {
    development.rust.enable = lib.mkEnableOption "Rust development environment";
  };

  config = lib.mkIf config.development.rust.enable {
    # Install Rust toolchain
    environment.systemPackages = with pkgs; [
      rustup
    ];

    # Configure git to use HTTPS for cargo
    environment.etc."gitconfig".text = ''
      [url "https://github.com/"]
        insteadOf = git@github.com:
    '';

    # Set up user environment for Rust
    system.activationScripts.rustSetup.text = ''
      USER_HOME="${config.users.users.${config.system.primaryUser}.home}"
      
      # Create Rust directories for primary user
      sudo -u ${config.system.primaryUser} mkdir -p "$USER_HOME/.rustup" "$USER_HOME/.cargo" "$USER_HOME/.cargo/bin"
      
      # Initialize rustup if not already done
      if ! sudo -u ${config.system.primaryUser} bash -c "test -f $USER_HOME/.cargo/bin/cargo"; then
        echo "Initializing Rust toolchain..."
        sudo -u ${config.system.primaryUser} bash -c "
          export HOME=$USER_HOME
          export RUSTUP_HOME=$USER_HOME/.rustup
          export CARGO_HOME=$USER_HOME/.cargo
          ${pkgs.rustup}/bin/rustup toolchain install stable
          ${pkgs.rustup}/bin/rustup default stable
        "
      fi
    '';
  };
}