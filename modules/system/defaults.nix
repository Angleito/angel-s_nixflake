{ config, lib, pkgs, ... }:

let
  # Import platform detection
  platform = import ../lib/platform.nix { inherit lib pkgs; };
in
{
  imports = 
    if platform.lib.platform.isDarwin then
      [ ./defaults-darwin.nix ]
    else if platform.lib.platform.isLinux then
      [ ./defaults-linux.nix ]
    else
      [];
}