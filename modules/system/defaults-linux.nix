{ config, lib, pkgs, ... }:

{
  config = lib.mkIf pkgs.stdenv.isLinux {
    # Linux system defaults
    
    # Font configuration
    fonts = {
      fontconfig = {
        enable = true;
        defaultFonts = {
          monospace = [ "JetBrains Mono" "DejaVu Sans Mono" ];
          sansSerif = [ "Inter" "DejaVu Sans" ];
          serif = [ "DejaVu Serif" ];
        };
      };
    };
    
    # Enable automatic timezone detection
    services.automatic-timezoned.enable = true;
    
    # System performance tuning
    boot.kernel.sysctl = {
      # Increase inotify watchers for development
      "fs.inotify.max_user_watches" = 524288;
      "fs.inotify.max_user_instances" = 512;
      
      # Network performance
      "net.core.rmem_max" = 134217728;
      "net.core.wmem_max" = 134217728;
      "net.ipv4.tcp_rmem" = "4096 87380 134217728";
      "net.ipv4.tcp_wmem" = "4096 65536 134217728";
      
      # Virtual memory
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
    };
    
    # Enable SSD optimization if applicable
    services.fstrim.enable = true;
    
    # System security defaults
    security = {
      # Enable sudo
      sudo = {
        enable = true;
        wheelNeedsPassword = true;
      };
      
      # Polkit for GUI authentication
      polkit.enable = true;
    };
    
    # Console settings
    console = {
      font = "Lat2-Terminus16";
      useXkbConfig = true; # Use X11 keyboard config
    };
    
    # Default system services
    services = {
      # Enable ACPI daemon for power management
      acpid.enable = true;
      
      # Enable Avahi for network discovery
      avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
      
      # Enable locate/updatedb
      locate = {
        enable = true;
        interval = "daily";
      };
    };
    
    # Default environment variables
    environment.variables = {
      EDITOR = "vim";
      BROWSER = "firefox";
      TERMINAL = "gnome-terminal";
    };
  };
}