{ pkgs, lib, ... }:

let
  # Import platform detection
  platform = import ./lib/platform.nix { inherit lib pkgs; };
  isDarwin = platform.lib.platform.isDarwin;
  isLinux = platform.lib.platform.isLinux;
in
{
  imports = [
    # Platform detection helper
    ./lib/platform.nix
    
    # Development modules (cross-platform)
    ./development/rust.nix
    ./development/nodejs.nix
    ./development/web3.nix
    ./development/database.nix
    
    # System modules
    ./system/defaults.nix  # This now handles platform detection internally
    ./system/environment.nix
    
    # Program modules (cross-platform)
    ./programs/git-env.nix
    ./programs/claude-code.nix
  ]
  # Darwin-specific modules
  ++ lib.optionals isDarwin [
    ./system/power.nix
    ./system/xcode.nix
    ./system/auto-update.nix
    ./programs/cursor.nix
    ./applications/homebrew.nix
  ]
  # Linux-specific modules
  ++ lib.optionals isLinux [
    ./system/power-linux.nix
  ];
}