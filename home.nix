{ config, pkgs, ... }:

{
  # Import git configuration
  imports = [
    ./home/git.nix
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "angel";
  home.homeDirectory = "/Users/angel";

  # This value determines the Home Manager release that your
  # configuration is compatible with.
  home.stateVersion = "23.11";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # User packages
  home.packages = with pkgs; [
    # Development tools
    nodejs_20
    python3
    go
    rustup
    docker
    docker-compose
    
    # CLI utilities
    htop
    neofetch
    tree
    ripgrep
    fd
    bat
    exa
    fzf
    jq
    yq
    gh  # GitHub CLI
    lazygit
    tmux
    
    # Nix tools
    nixpkgs-fmt
    nil  # Nix LSP
    
    # Productivity
    direnv
    starship
    zoxide
    
    # System tools
    coreutils
    findutils
    gnugrep
    gnused
    gawk
    
    # Archive tools
    unzip
    p7zip
  ];

  # Zsh configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    shellAliases = {
      ll = "ls -l";
      la = "ls -la";
      ".." = "cd ..";
      "..." = "cd ../..";
      
      # Git aliases
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log";
      gd = "git diff";
      
      # Nix aliases
      rebuild = "darwin-rebuild switch --flake .";
      update = "nix flake update";
    };
    
    initExtra = ''
      # Starship prompt
      eval "$(starship init zsh)"
      
      # Zoxide (better cd)
      eval "$(zoxide init zsh)"
      
      # FZF
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh
      source ${pkgs.fzf}/share/fzf/completion.zsh
    '';
  };

  # Starship prompt configuration
  programs.starship = {
    enable = true;
    settings = {
      format = "$all$character";
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
    };
  };

  # VS Code configuration
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      # Add VS Code extensions here
    ];
  };
}
