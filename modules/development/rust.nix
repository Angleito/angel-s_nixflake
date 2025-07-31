{ config, pkgs, lib, ... }:

let
  # Platform detection using pkgs directly
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  
  # Get the primary user based on platform
  primaryUser = if isDarwin then 
    config.system.primaryUser
  else
    # On NixOS, we'll need to specify this in the configuration
    config.development.rust.primaryUser or "angel";
in

{
  options = {
    development.rust = {
      enable = lib.mkEnableOption "Rust development environment";
      
      primaryUser = lib.mkOption {
        type = lib.types.str;
        default = "angel";
        description = "Primary user for Rust setup (used on Linux)";
      };
    };
  };

  config = lib.mkIf config.development.rust.enable {
    # Install Rust toolchain
    environment.systemPackages = with pkgs; [
      rustup
      gcc # Required for linking
      pkg-config # Often needed for Rust crates
      openssl # Common dependency
    ];

    # Configure git to use HTTPS for cargo (cross-platform)
    environment.etc."gitconfig".text = ''
      [url "https://github.com/"]
        insteadOf = git@github.com:
    '';

    # Platform-specific Rust setup
  } // lib.mkMerge [
    # Darwin-specific configuration
    (lib.mkIf (config.development.rust.enable && isDarwin) {
      system.activationScripts.rustSetup.text = ''
        USER_HOME="${config.users.users.${primaryUser}.home}"
        
        # Create Rust directories for primary user
        sudo -u ${primaryUser} mkdir -p "$USER_HOME/.rustup" "$USER_HOME/.cargo" "$USER_HOME/.cargo/bin"
        
        # Initialize rustup if not already done
        if ! sudo -u ${primaryUser} bash -c "test -f $USER_HOME/.cargo/bin/cargo"; then
          echo "Initializing Rust toolchain..."
          sudo -u ${primaryUser} bash -c "
            export HOME=$USER_HOME
            export RUSTUP_HOME=$USER_HOME/.rustup
            export CARGO_HOME=$USER_HOME/.cargo
            ${pkgs.rustup}/bin/rustup toolchain install stable
            ${pkgs.rustup}/bin/rustup default stable
          "
        fi
      '';
    })
    
    # Linux-specific configuration
    # TODO: Re-enable when running on Linux
    # (lib.mkIf (config.development.rust.enable && isLinux) {
    #   # On Linux/NixOS, we'll handle this through systemd user service
    #   systemd.user.services.rust-setup = {
    #     description = "Setup Rust development environment";
    #     wantedBy = [ "default.target" ];
    #     after = [ "network.target" ];
    #     serviceConfig = {
    #       Type = "oneshot";
    #       RemainAfterExit = true;
    #       ExecStart = pkgs.writeShellScript "rust-setup" ''
    #         # Create Rust directories
    #         mkdir -p "$HOME/.rustup" "$HOME/.cargo" "$HOME/.cargo/bin"
    #         
    #         # Initialize rustup if not already done
    #         if [ ! -f "$HOME/.cargo/bin/cargo" ]; then
    #           echo "Initializing Rust toolchain..."
    #           export RUSTUP_HOME="$HOME/.rustup"
    #           export CARGO_HOME="$HOME/.cargo"
    #           ${pkgs.rustup}/bin/rustup toolchain install stable
    #           ${pkgs.rustup}/bin/rustup default stable
    #         fi
    #       '';
    #     };
    #   };
    #   
    #   # Environment variables for all users
    #   environment.variables = {
    #     RUSTUP_HOME = "$HOME/.rustup";
    #     CARGO_HOME = "$HOME/.cargo";
    #   };
    #   
    #   # Add cargo bin to PATH
    #   environment.shellInit = ''
    #     export PATH="$HOME/.cargo/bin:$PATH"
    #   '';
    # })
  ];
}