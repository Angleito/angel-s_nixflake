{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.orbstack;
in
{
  options.programs.orbstack = {
    enable = mkEnableOption "OrbStack - Fast, light, simple Docker & Linux on macOS";

    dockerCompat = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Docker CLI compatibility mode";
    };

    shellAliases = mkOption {
      type = types.bool;
      default = true;
      description = "Set up shell aliases for Docker and Docker Compose";
    };

    dockerSocketSymlink = mkOption {
      type = types.bool;
      default = true;
      description = "Create symlink for Docker socket at /var/run/docker.sock";
    };

    environmentVariables = mkOption {
      type = types.attrsOf types.str;
      default = {};
      example = {
        DOCKER_HOST = "unix:///Users/$USER/.orbstack/run/docker.sock";
      };
      description = "Additional environment variables for OrbStack";
    };
  };

  config = mkIf cfg.enable {
    # Environment variables
    environment.variables = mkMerge [
      {
        # OrbStack Docker socket location
        DOCKER_HOST = mkDefault "unix:///var/run/orbstack.sock";
        
        # Add OrbStack xbin to PATH
        PATH = mkBefore "/Applications/OrbStack.app/Contents/MacOS/xbin";
      }
      cfg.environmentVariables
    ];

    # Shell aliases for Docker compatibility
    environment.shellAliases = mkIf cfg.shellAliases {
      docker = "/Applications/OrbStack.app/Contents/MacOS/xbin/docker";
      docker-compose = "/Applications/OrbStack.app/Contents/MacOS/xbin/docker-compose";
      
      # Kubernetes aliases if needed
      kubectl = "orbctl kubectl";
      k = "orbctl kubectl";
    };

    # System-wide Docker socket symlink
    system.activationScripts.orbstackDockerSocket = mkIf cfg.dockerSocketSymlink ''
      echo "Configuring OrbStack Docker socket compatibility..."
      
      # Create directory if it doesn't exist
      sudo mkdir -p /var/run
      
      # Handle existing Docker Desktop installation
      if [ -e /var/run/docker.sock ] && [ ! -L /var/run/docker.sock ]; then
        echo "Found existing Docker Desktop socket, backing it up..."
        sudo mv /var/run/docker.sock /var/run/docker.sock.backup.$(date +%Y%m%d_%H%M%S)
      fi
      
      # Remove any existing symlinks
      if [ -L /var/run/docker.sock ]; then
        echo "Removing existing Docker socket symlink..."
        sudo rm -f /var/run/docker.sock
      fi
      
      # Check if OrbStack socket exists
      if [ -S /var/run/orbstack.sock ]; then
        echo "Found OrbStack socket at /var/run/orbstack.sock"
        
        # Create symlink from docker.sock to orbstack.sock
        sudo ln -sf /var/run/orbstack.sock /var/run/docker.sock
        
        # Ensure proper permissions on the socket
        # OrbStack should manage the actual socket permissions, but we ensure the symlink is accessible
        sudo chmod 755 /var/run
        
        # Verify the symlink
        if [ -L /var/run/docker.sock ]; then
          echo "Successfully created Docker socket symlink:"
          ls -la /var/run/docker.sock
        else
          echo "ERROR: Failed to create Docker socket symlink"
        fi
      else
        echo "OrbStack socket not found at /var/run/orbstack.sock"
        echo "Please ensure OrbStack is installed and running"
        
        # Alternative: Check for OrbStack socket in user directory
        if [ -S "$HOME/.orbstack/run/docker.sock" ]; then
          echo "Found OrbStack socket in user directory, creating symlink..."
          sudo ln -sf "$HOME/.orbstack/run/docker.sock" /var/run/docker.sock
          echo "Created fallback symlink from user directory"
        fi
      fi
    '';

    # LaunchDaemon to maintain Docker socket symlink
    launchd.daemons.orbstack-docker-socket = mkIf cfg.dockerSocketSymlink {
      serviceConfig = {
        ProgramArguments = [
          "/bin/sh"
          "-c"
          ''
            # Ensure /var/run directory exists
            mkdir -p /var/run
            
            # Primary check: OrbStack socket at standard location
            if [ -S /var/run/orbstack.sock ]; then
              # Only recreate symlink if it doesn't exist or points to wrong location
              if [ ! -L /var/run/docker.sock ] || [ "$(readlink /var/run/docker.sock)" != "/var/run/orbstack.sock" ]; then
                rm -f /var/run/docker.sock
                ln -sf /var/run/orbstack.sock /var/run/docker.sock
                echo "$(date): Updated Docker socket symlink to point to /var/run/orbstack.sock"
              fi
            # Fallback: Check user directory for OrbStack socket
            elif [ -S "$HOME/.orbstack/run/docker.sock" ]; then
              if [ ! -L /var/run/docker.sock ] || [ "$(readlink /var/run/docker.sock)" != "$HOME/.orbstack/run/docker.sock" ]; then
                rm -f /var/run/docker.sock
                ln -sf "$HOME/.orbstack/run/docker.sock" /var/run/docker.sock
                echo "$(date): Updated Docker socket symlink to point to user directory"
              fi
            else
              echo "$(date): OrbStack socket not found at expected locations"
            fi
          ''
        ];
        RunAtLoad = true;
        KeepAlive = {
          SuccessfulExit = false;
        };
        StartInterval = 300; # Check every 5 minutes
        StandardOutPath = "/var/log/orbstack-docker-socket.log";
        StandardErrorPath = "/var/log/orbstack-docker-socket.error.log";
      };
    };

    # Additional system packages that might be useful with OrbStack
    environment.systemPackages = with pkgs; mkIf cfg.dockerCompat [
      # Docker CLI tools that work with OrbStack
      docker-client
      docker-compose
      
      # Container-related tools
      dive
      lazydocker
      ctop
    ];

    # Homebrew integration for OrbStack installation
    homebrew = {
      casks = [ "orbstack" ];
    };
  };
}
