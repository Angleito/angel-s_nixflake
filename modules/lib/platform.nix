{ lib, pkgs, ... }:

{
  # Platform detection helpers
  lib.platform = {
    # Check if running on Darwin/macOS
    isDarwin = pkgs.stdenv.isDarwin;
    
    # Check if running on Linux
    isLinux = pkgs.stdenv.isLinux;
    
    # Check if running on NixOS specifically
    isNixOS = pkgs.stdenv.isLinux && builtins.pathExists /etc/nixos;
    
    # Architecture checks
    isAarch64 = pkgs.stdenv.hostPlatform.isAarch64;
    isX86_64 = pkgs.stdenv.hostPlatform.isx86_64;
    
    # Combined checks
    isAarch64Darwin = pkgs.stdenv.isDarwin && pkgs.stdenv.hostPlatform.isAarch64;
    isX86_64Darwin = pkgs.stdenv.isDarwin && pkgs.stdenv.hostPlatform.isx86_64;
    isAarch64Linux = pkgs.stdenv.isLinux && pkgs.stdenv.hostPlatform.isAarch64;
    isX86_64Linux = pkgs.stdenv.isLinux && pkgs.stdenv.hostPlatform.isx86_64;
    
    # Helper to conditionally include based on platform
    onDarwin = value: if pkgs.stdenv.isDarwin then value else null;
    onLinux = value: if pkgs.stdenv.isLinux then value else null;
    onNixOS = value: if (pkgs.stdenv.isLinux && builtins.pathExists /etc/nixos) then value else null;
    
    # Helper to choose between platform-specific values
    select = {
      darwin ? null,
      linux ? null,
      nixos ? null,
      default ? null
    }: 
      if pkgs.stdenv.isDarwin then darwin
      else if (pkgs.stdenv.isLinux && builtins.pathExists /etc/nixos) then (if nixos != null then nixos else linux)
      else if pkgs.stdenv.isLinux then linux
      else default;
  };
}