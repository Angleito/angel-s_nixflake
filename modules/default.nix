{ ... }:

{
  imports = [
    # Development modules
    ./development/rust.nix
    ./development/nodejs.nix
    ./development/web3.nix
    ./development/database.nix
    
    # System modules
    ./system/power.nix
    ./system/defaults.nix
    ./system/xcode.nix
    ./system/environment.nix
    
    # Program modules
    ./programs/git-env.nix
    ./programs/claude-code.nix
    ./programs/cursor.nix
    
    # Application modules
    ./applications/homebrew.nix
  ];
}