{ ... }:

{
  imports = [
    # Development modules (cross-platform)
    ./development/rust.nix
    ./development/nodejs.nix
    ./development/web3.nix
    ./development/database.nix
    
    # System modules
    ./system/defaults.nix
    ./system/environment.nix
    
    # Program modules (cross-platform)
    ./programs/git-env.nix
    ./programs/claude-code.nix
    
    # Darwin-specific modules
    ./system/power.nix
    ./system/xcode.nix
    ./system/auto-update.nix
    ./programs/cursor.nix
    ./applications/homebrew.nix
  ];
}
