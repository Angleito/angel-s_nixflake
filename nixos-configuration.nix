{ config, pkgs, lib, ... }:

let
  jsonUtils = import ./json-utils.nix { inherit lib; };
in

{
  imports = [
    # Hardware configuration (you'll need to generate this with nixos-generate-config)
    # ./hardware-configuration.nix
    
    # Import shared modules
    ./modules/lib/platform.nix
    ./modules/development/rust.nix
    ./modules/development/nodejs.nix
    ./modules/development/web3.nix
    ./modules/development/database.nix
    ./modules/programs/git-env.nix
    ./modules/programs/claude-code.nix
    
    # Linux-specific modules
    # ./modules/system/power-linux.nix
    # ./modules/system/defaults-linux.nix
  ];

  # Boot loader
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Networking
  networking = {
    hostName = "angel-nixos"; # Change this to your preferred hostname
    networkmanager.enable = true;
  };

  # Time zone and localization
  time.timeZone = "America/Los_Angeles"; # Change to your timezone
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable sound
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  # OR use pipewire:
  # services.pipewire = {
  #   enable = true;
  #   alsa.enable = true;
  #   alsa.support32Bit = true;
  #   pulse.enable = true;
  # };

  # Enable OpenGL
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # X11/Wayland configuration
  services.xserver = {
    enable = true;
    
    # Display manager
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
    
    # Desktop environment (choose one)
    desktopManager.gnome.enable = true;
    # desktopManager.plasma5.enable = true;
    # windowManager.i3.enable = true;
    
    # Keyboard layout
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Enable CUPS for printing
  services.printing.enable = true;

  # Define your user account
  users.users.angel = {
    isNormalUser = true;
    description = "Angel";
    extraGroups = [ "networkmanager" "wheel" "audio" "video" "docker" ];
    shell = pkgs.zsh;
  };

  # Enable zsh
  programs.zsh.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages
  environment.systemPackages = with pkgs; [
    # Core utilities
    vim
    git
    curl
    wget
    htop
    tmux
    
    # Development tools
    gcc
    gnumake
    pkg-config
    openssl
    
    # Custom packages
    claude-code
    
    # Desktop applications (if using GUI)
    firefox
    chromium
    vscode
    
    # System tools
    networkmanagerapplet
    pavucontrol
  ];

  # Module configurations
  development = {
    rust.enable = true;
    nodejs.enable = true;
    web3 = {
      enable = true;
      enableSui = true;
      enableWalrus = true;
      enableVercel = true;
      useCargoInstall = true;
    };
    database = {
      enable = true;
      postgresql = {
        enable = true;
        enableService = false;
      };
      redis = {
        enable = true;
        enableService = false;
      };
    };
  };

  # Programs configuration
  programs = {
    git-env.enable = true;
    claude-code.enable = true;
  };

  # Services
  services = {
    # Enable Docker
    docker = {
      enable = true;
      enableOnBoot = true;
    };
    
    # Enable SSH daemon
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };
    
    # Enable automatic updates
    # system.autoUpgrade = {
    #   enable = true;
    #   allowReboot = false;
    # };
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ];
    # allowedUDPPorts = [ ... ];
  };

  # System state version (don't change this after initial install)
  system.stateVersion = "24.05"; # Did you read the comment?
}