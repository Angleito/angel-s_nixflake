{
  description = "Angel's Nix Darwin System Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, darwin, home-manager }: {
    darwinConfigurations."angels-MBP" = darwin.lib.darwinSystem {
      system = "aarch64-darwin"; # or "x86_64-darwin" for Intel Macs
      
      modules = [
        ./darwin-configuration.nix
        
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.angel = import ./home.nix;
          };
        }
      ];
    };
  };
}
