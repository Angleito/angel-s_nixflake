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
      user.signingkey = "~/.ssh/id_ed25519.pub";
      
      # Use macOS keychain for credentials
      credential.helper = "osxkeychain";
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
