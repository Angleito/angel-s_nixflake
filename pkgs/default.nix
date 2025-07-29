{ pkgs }:

{
  # Custom packages overlay
  sui-cli = pkgs.callPackage ./sui-cli { };
  walrus-cli = pkgs.callPackage ./walrus-cli { };
  vercel-cli = pkgs.callPackage ./vercel-cli { };
  suiup = pkgs.callPackage ./suiup { };
  claude-code = pkgs.callPackage ./claude-code { };  # Latest Claude Code
}