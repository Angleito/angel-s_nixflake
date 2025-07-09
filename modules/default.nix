{ ... }:

{
  imports = [
    # Development modules
    ./development/rust.nix
    ./development/nodejs.nix
    ./development/web3.nix
    
    # System modules
    ./system/power.nix
    ./system/defaults.nix
    ./system/xcode.nix
    ./system/environment.nix
    
    # Program modules
    ./programs/git-env.nix
    
    # Application modules
    ./applications/homebrew.nix
  ];
}