{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    system.power = {
      enable = mkEnableOption "Linux power management";
      
      profileOnAC = mkOption {
        type = types.enum [ "performance" "balanced" "powersave" ];
        default = "balanced";
        description = "Power profile when on AC power";
      };
      
      profileOnBattery = mkOption {
        type = types.enum [ "performance" "balanced" "powersave" ];
        default = "powersave";
        description = "Power profile when on battery";
      };
      
      enableTLP = mkOption {
        type = types.bool;
        default = true;
        description = "Enable TLP for advanced power management";
      };
      
      enableThermald = mkOption {
        type = types.bool;
        default = true;
        description = "Enable thermald for thermal management";
      };
    };
  };

  config = mkIf config.system.power.enable {
    # TLP for power management
    services.tlp = mkIf config.system.power.enableTLP {
      enable = true;
      settings = {
        # CPU settings
        CPU_SCALING_GOVERNOR_ON_AC = config.system.power.profileOnAC;
        CPU_SCALING_GOVERNOR_ON_BAT = config.system.power.profileOnBattery;
        
        CPU_BOOST_ON_AC = if config.system.power.profileOnAC == "performance" then 1 else 0;
        CPU_BOOST_ON_BAT = 0;
        
        # Turbo boost
        CPU_HWP_DYN_BOOST_ON_AC = if config.system.power.profileOnAC == "performance" then 1 else 0;
        CPU_HWP_DYN_BOOST_ON_BAT = 0;
        
        # Disk settings
        DISK_DEVICES = "nvme0n1 sda";
        DISK_APM_LEVEL_ON_AC = "254 254";
        DISK_APM_LEVEL_ON_BAT = "128 128";
        
        # PCIe power management
        RUNTIME_PM_ON_AC = "auto";
        RUNTIME_PM_ON_BAT = "auto";
        
        # USB autosuspend
        USB_AUTOSUSPEND = 1;
        USB_EXCLUDE_BTUSB = 1; # Don't suspend Bluetooth
        
        # WiFi power saving
        WIFI_PWR_ON_AC = "off";
        WIFI_PWR_ON_BAT = "on";
        
        # Sound power saving
        SOUND_POWER_SAVE_ON_AC = 0;
        SOUND_POWER_SAVE_ON_BAT = 1;
        
        # Battery charge thresholds (if supported)
        START_CHARGE_THRESH_BAT0 = 40;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };

    # Thermald for thermal management
    services.thermald.enable = config.system.power.enableThermald;

    # Power profiles daemon (alternative to TLP)
    services.power-profiles-daemon.enable = !config.system.power.enableTLP;

    # ACPI daemon
    services.acpid = {
      enable = true;
      
      # Handle lid events
      lidEventCommands = ''
        case "$3" in
          close)
            systemctl suspend
            ;;
          open)
            # Resume actions if needed
            ;;
        esac
      '';
      
      # Handle power button
      powerEventCommands = ''
        systemctl poweroff
      '';
    };

    # Powertop for power analysis
    powerManagement.powertop.enable = true;

    # CPU frequency scaling
    powerManagement.cpuFreqGovernor = mkDefault config.system.power.profileOnAC;

    # Enable power management
    powerManagement.enable = true;

    # Install power management tools
    environment.systemPackages = with pkgs; [
      powertop
      acpi
      lm_sensors
      s-tui # Terminal UI for monitoring
    ] ++ optional config.system.power.enableTLP tlp;

    # System startup commands for power optimization
    systemd.services.power-optimization = {
      description = "Additional power optimizations";
      after = [ "multi-user.target" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        
        ExecStart = pkgs.writeShellScript "power-optimize" ''
          # Disable NMI watchdog
          echo 0 > /proc/sys/kernel/nmi_watchdog
          
          # VM writeback timeout
          echo 1500 > /proc/sys/vm/dirty_writeback_centisecs
          
          # Enable ASPM
          echo powersupersave > /sys/module/pcie_aspm/parameters/policy
          
          # Disable wake-on-lan for ethernet
          for i in /sys/class/net/*/device/power/wakeup; do
            echo disabled > $i 2>/dev/null || true
          done
        '';
      };
    };
  };
}