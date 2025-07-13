{ pkgs, lib, config, ... }:
let
  # Get environment variable with default
  getEnvWithDefault = varName: default:
    let value = builtins.getEnv varName;
    in if value == "" then default else value;
  
  # Get git configuration from environment variables
  gitName  = getEnvWithDefault "GIT_NAME" "Angleito";
  gitEmail = getEnvWithDefault "GIT_EMAIL" "arainey555@gmail.com";
in
{
  programs.git = {
    enable = true;
    userName  = if gitName != "" then gitName else "Unknown";
    userEmail = if gitEmail != "" then gitEmail else "unknown@example.com";
    
    # Use SSH for GitHub
    extraConfig = {
      url = {
        "git@github.com:" = {
          insteadOf = "https://github.com/";
        };
      };
      
      # Sign commits with SSH key
      commit.gpgsign = true;
      gpg.format = "ssh";
      user.signingkey = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
      
      # SSH signature verification
      gpg.ssh.allowedSignersFile = "${config.home.homeDirectory}/.ssh/allowed_signers";
      
      # Use macOS keychain for credentials
      credential.helper = "osxkeychain";
      
      # Hooks configuration
      core.hooksPath = "~/.config/git/hooks";
      
      # Additional git settings
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = false;
    };
  };
  
  # SSH configuration
  programs.ssh = {
    enable = true;
    
    # Use macOS keychain for SSH keys
    extraConfig = ''
      Host github.com
        HostName github.com
        User git
        IdentityFile ~/.ssh/id_ed25519
        AddKeysToAgent yes
        UseKeychain yes
    '';
  };
}
