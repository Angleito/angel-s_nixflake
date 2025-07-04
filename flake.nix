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
    darwinConfigurations."angels-MacBook-Pro" = darwin.lib.darwinSystem {
      system = "aarch64-darwin"; # or "x86_64-darwin" for Intel Macs
      
      modules = [
        # Allow unfree packages
        {
          nixpkgs.config.allowUnfree = true;
        }
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
    
    # Development shells for direnv
    devShells.aarch64-darwin.default = let
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
    in pkgs.mkShell {
      buildInputs = with pkgs; [
        # Add any development tools you need here
        # For example:
        # git
        # curl
        # jq
      ];
      
      shellHook = ''
        echo "Welcome to your Nix development environment!"
      '';
    };
  };
}
