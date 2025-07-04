{ pkgs, ... }:
let
  gitName  = builtins.getEnv "GIT_NAME";
  gitEmail = builtins.getEnv "GIT_EMAIL";
in
{
  programs.git = {
    enable = true;
    userName  = gitName  or "Unknown";
    userEmail = gitEmail or "unknown@example.com";
    # any extra git options here
  };
}
