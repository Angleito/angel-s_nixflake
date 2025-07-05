{ pkgs }:

{
  # Custom packages overlay
  sui-cli = pkgs.callPackage ./sui-cli { };
  walrus-cli = pkgs.callPackage ./walrus-cli { };
  vercel-cli = pkgs.callPackage ./vercel-cli { };
}