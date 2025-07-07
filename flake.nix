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

  outputs = { self, nixpkgs, darwin, home-manager }:
  let
    system = "aarch64-darwin";
    
    # Create pkgs with our custom overlay
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [ self.overlays.default ];
    };
    
  in {
    # Custom package overlay
    overlays.default = final: prev: 
      let
        customPkgs = import ./pkgs { pkgs = final; };
      in
      customPkgs;
    
    # Packages available as flake outputs
    packages.${system} = {
      sui-cli = pkgs.sui-cli;
      walrus-cli = pkgs.walrus-cli;
      vercel-cli = pkgs.vercel-cli;
      
      # Meta packages for convenience
      web3-tools = pkgs.buildEnv {
        name = "web3-tools";
        paths = with pkgs; [
          sui-cli
          walrus-cli
          vercel-cli
        ];
      };
    };
    
    # Apps for easy running
    apps.${system} = {
      sui = {
        type = "app";
        program = "${pkgs.sui-cli}/bin/sui";
      };
      walrus = {
        type = "app";
        program = "${pkgs.walrus-cli}/bin/walrus";
      };
      vercel = {
        type = "app";
        program = "${pkgs.vercel-cli}/bin/vercel";
      };
      
      # Environment management apps
      setup-env = {
        type = "app";
        program = toString (pkgs.writeShellScript "setup-env" ''
          set -euo pipefail
          
          ENV_FILE="$HOME/.config/nix-project/.env"
          ENV_SAMPLE="${./.env.sample}"
          
          echo "🔧 Setting up environment configuration..."
          
          # Create config directory if it doesn't exist
          mkdir -p "$(dirname "$ENV_FILE")"
          
          # Copy .env.sample to config directory
          cp "$ENV_SAMPLE" "$HOME/.config/nix-project/.env.sample"
          
          # Copy .env.sample to .env if .env doesn't exist
          if [[ ! -f "$ENV_FILE" ]]; then
            cp "$ENV_SAMPLE" "$ENV_FILE"
            echo "✅ Created $ENV_FILE from sample"
            echo "📝 Please edit $ENV_FILE with your actual values"
          else
            echo "ℹ️  $ENV_FILE already exists"
          fi
          
          # Make sure the file is readable only by the user
          chmod 600 "$ENV_FILE"
          
          echo "🔒 Set secure permissions on $ENV_FILE"
          echo "🎉 Environment setup complete!"
          echo ""
          echo "To edit your environment variables, run:"
          echo "  $EDITOR $ENV_FILE"
        '');
      };
      
      deploy-env = {
        type = "app";
        program = toString (pkgs.writeShellScript "deploy-env" ''
          set -euo pipefail
          
          echo "🚀 Deploying environment configuration across systems..."
          
          # Run environment setup
          ${self.apps.${system}.setup-env.program}
          
          echo "📦 Configuration deployment complete!"
          echo ""
          echo "Next steps:"
          echo "  1. Edit $HOME/.config/nix-project/.env with your actual values"
          echo "  2. Run 'direnv allow' in your project directories"
          echo "  3. Your environment variables will be automatically loaded"
        '');
      };
      
      # Deployment helper
      deploy = {
        type = "app";
        program = toString (pkgs.writeShellScript "deploy" ''
          set -euo pipefail
          echo "🔄 Deploying Darwin configuration..."
          sudo ${darwin.packages.${system}.darwin-rebuild}/bin/darwin-rebuild switch --flake ".#angel"
          echo "✅ Deployment complete!"
        '');
      };
      
      # Installation helper
      install = {
        type = "app";
        program = toString (pkgs.writeShellScript "install" ''
          set -euo pipefail
          
          echo "🚀 Installing Angel's Nix Darwin Configuration"
          echo ""
          
          # Check if Nix is installed
          if ! command -v nix &> /dev/null; then
              echo "❌ Nix is not installed. Please install Nix first:"
              echo "   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
              exit 1
          fi
          
          # Check if nix-darwin is installed
          if ! command -v darwin-rebuild &> /dev/null; then
              echo "📦 Installing nix-darwin..."
              nix run nix-darwin -- switch --flake ".#angel"
          else
              echo "🔄 Updating configuration..."
              sudo darwin-rebuild switch --flake ".#angel"
          fi
          
          echo ""
          echo "✅ Installation complete!"
          echo "🎉 Your development environment is ready to use!"
        '');
      };
    };
    
    # Darwin configuration - always use "angel" for portability
    darwinConfigurations."angel" = darwin.lib.darwinSystem {
      inherit system;
      
      specialArgs = { inherit self; };
      
      modules = [
        # Allow unfree packages
        {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.overlays = [ self.overlays.default ];
        }
        
        # Import our modules
        ./modules
        
        # Main configuration
        ./darwin-configuration.nix
        
        # Home Manager integration
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            users.angel = import ./home.nix;
          };
        }
      ];
    };
    
    # Development shells for direnv
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        # Development tools
        git
        curl
        jq
        
        # Our custom packages
        sui-cli
        walrus-cli
        vercel-cli
      ];
      
      shellHook = ''
        echo "🚀 Welcome to your Nix development environment!"
        echo "Available tools:"
        echo "  • sui-cli: $(sui --version 2>/dev/null || echo 'installed')"
        echo "  • walrus-cli: $(walrus --version 2>/dev/null || echo 'installed')" 
        echo "  • vercel-cli: $(vercel --version 2>/dev/null || echo 'installed')"
        echo ""
        echo "Run 'nix flake show' to see all available packages and apps"
      '';
    };
  };
}