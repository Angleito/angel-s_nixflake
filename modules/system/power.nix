{ config, lib, pkgs, ... }:

{
  options = {
    system.power.preventDisplaySleep = lib.mkEnableOption "prevent display from sleeping";
    system.power.preventSystemSleep = lib.mkEnableOption "prevent system from sleeping on AC power";
    system.power.preventDiskSleep = lib.mkEnableOption "prevent disk from sleeping";
  };

  config = lib.mkIf pkgs.stdenv.isDarwin {
    # Power management settings
    system.activationScripts.powerManagement.text = ''
      echo "Configuring power management settings..."
      
      ${lib.optionalString config.system.power.preventDisplaySleep ''
        # Prevent display from sleeping (0 = never)
        pmset -a displaysleep 0
      ''}
      
      ${lib.optionalString config.system.power.preventSystemSleep ''
        # Prevent system from sleeping when on AC power (0 = never)
        pmset -c sleep 0
        
        # Prevent automatic sleep when on AC power
        pmset -c autopoweroff 0
      ''}
      
      ${lib.optionalString config.system.power.preventDiskSleep ''
        # Prevent disk from sleeping
        pmset -a disksleep 0
      ''}
      
      # Keep the system awake when the display is off
      pmset -a powernap 0
      
      # Optional: Keep display awake even when system is idle
      pmset -a lessbright 0
      
      echo "Power management settings configured"
    '';
  };
}