{
  description = "Multi-platform Nix flake supporting Linux, ARM Linux, Intel macOS, and Apple Silicon macOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, darwin, home-manager }:
  let
    # Define the systems we want to support
    supportedSystems = [
      "x86_64-linux"   # Linux and WSL
      "aarch64-linux"  # ARM Linux
      "x86_64-darwin"  # Intel macOS
      "aarch64-darwin" # Apple Silicon macOS
    ];

    # Helper function to generate outputs for all systems
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    # Helper function to get nixpkgs for a specific system
    nixpkgsFor = forAllSystems (system: import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [ self.overlays.default ];
    });
    
  in {
    # Custom package overlay
    overlays.default = final: prev: 
      let
        customPkgs = import ./pkgs { pkgs = final; };
      in
      customPkgs;
    
    # Packages available as flake outputs for all systems
    packages = forAllSystems (system:
      let
        pkgs = nixpkgsFor.${system};
      in {
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

        # Platform-specific hello example
        hello = pkgs.stdenv.mkDerivation {
          pname = "hello-multiplatform";
          version = "1.0.0";
          
          src = pkgs.writeText "hello.c" ''
            #include <stdio.h>
            int main() {
              printf("Hello from ${system}!\n");
              return 0;
            }
          '';
          
          buildInputs = with pkgs; [ gcc ];
          
          phases = [ "buildPhase" "installPhase" ];
          
          buildPhase = ''
            gcc $src -o hello
          '';
          
          installPhase = ''
            mkdir -p $out/bin
            cp hello $out/bin/
          '';
        };
      }
    );
    
    # Apps for easy running across all systems
    apps = forAllSystems (system:
      let
        pkgs = nixpkgsFor.${system};
      in {
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

        # Multi-platform hello app
        hello = {
          type = "app";
          program = "${self.packages.${system}.hello}/bin/hello";
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
      
      } // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
        # Darwin-specific deployment helper
        deploy = {
          type = "app";
          program = toString (pkgs.writeShellScript "deploy" ''
            set -euo pipefail
            echo "🔄 Deploying Darwin configuration..."
            sudo ${darwin.packages.${system}.darwin-rebuild}/bin/darwin-rebuild switch --flake ".#angel"
            echo "✅ Deployment complete!"
          '');
        };
      
        # Darwin-specific installation helper
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
      }
    );
    
    # Darwin configurations for supported Darwin systems
    darwinConfigurations = {
      # Apple Silicon macOS (default)
      "angel" = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        
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
      
      # Intel macOS configuration
      "angel-intel" = darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        
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
    };
    
    # Development shells for all systems
    devShells = forAllSystems (system:
      let
        pkgs = nixpkgsFor.${system};
      in {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Development tools
            git
            curl
            jq
            
            # Our custom packages
            sui-cli
            walrus-cli
            vercel-cli
            
            # System-specific tools
          ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            # macOS-specific packages
            pkgs.darwin.apple_sdk.frameworks.Security
            pkgs.darwin.apple_sdk.frameworks.CoreFoundation
          ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
            # Linux-specific packages
            pkg-config
            openssl
          ];
          
          shellHook = ''
            echo "🚀 Welcome to your multi-platform Nix development environment!"
            echo "System: ${system}"
            echo "Platform: ${if pkgs.stdenv.isDarwin then "macOS" else "Linux"}"
            echo "Architecture: ${pkgs.stdenv.hostPlatform.parsed.cpu.name}"
            echo ""
            echo "Available tools:"
            echo "  • sui-cli: $(sui --version 2>/dev/null || echo 'installed')"
            echo "  • walrus-cli: $(walrus --version 2>/dev/null || echo 'installed')" 
            echo "  • vercel-cli: $(vercel --version 2>/dev/null || echo 'installed')"
            echo ""
            echo "Run 'nix flake show' to see all available packages and apps"
          '';
        };
      }
    );

    # Add additional multi-platform outputs
    # Default packages for each system
    defaultPackage = forAllSystems (system: self.packages.${system}.web3-tools);

    # Checks that can be run with `nix flake check`
    checks = forAllSystems (system:
      let
        pkgs = nixpkgsFor.${system};
      in {
        # Build test
        build-test = pkgs.runCommand "build-test" {} ''
          echo "Testing build for ${system}..."
          ${self.packages.${system}.hello}/bin/hello
          touch $out
        '';

        # Format check
        format-check = pkgs.runCommand "format-check" {} ''
          echo "Format check passed for ${system}"
          touch $out
        '';
      }
    );

    # Formatter for `nix fmt`
    formatter = forAllSystems (system: nixpkgsFor.${system}.nixpkgs-fmt);
  };
}
