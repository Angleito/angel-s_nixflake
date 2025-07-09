{ config, pkgs, lib, ... }:

{
  options = {
    development.nodejs.enable = lib.mkEnableOption "Node.js development environment";
  };

  config = lib.mkIf config.development.nodejs.enable {
    # Install Node.js and npm packages
    environment.systemPackages = with pkgs; [
      nodejs_20
      bun
    ];

    # Set up npm global directories and install web dev tools
    system.activationScripts.npmSetup.text = ''
      USER_HOME="${config.users.users.${config.system.primaryUser}.home}"
      
      # Create npm global directories
      sudo -u ${config.system.primaryUser} mkdir -p "$USER_HOME/.npm-global" "$USER_HOME/.npm-cache"
      
      # Configure npm for user
      sudo -u ${config.system.primaryUser} bash -c "
        export HOME=$USER_HOME
        ${pkgs.nodejs_20}/bin/npm config set prefix $USER_HOME/.npm-global
        ${pkgs.nodejs_20}/bin/npm config set cache $USER_HOME/.npm-cache
      "
      
      # Install web development tools globally with bun
      sudo -u ${config.system.primaryUser} bash -c "
        export HOME=$USER_HOME
        export PATH=$USER_HOME/.npm-global/bin:$PATH
        
        # Install global web dev tools
        ${pkgs.bun}/bin/bun install -g vite@latest
        ${pkgs.bun}/bin/bun install -g create-vite@latest
        ${pkgs.bun}/bin/bun install -g create-next-app@latest
        ${pkgs.bun}/bin/bun install -g @tailwindcss/cli@latest
        ${pkgs.bun}/bin/bun install -g tailwindcss@latest
        ${pkgs.bun}/bin/bun install -g postcss@latest
        ${pkgs.bun}/bin/bun install -g autoprefixer@latest
        ${pkgs.bun}/bin/bun install -g typescript@latest
        ${pkgs.bun}/bin/bun install -g tsx@latest
        ${pkgs.bun}/bin/bun install -g @types/node@latest
        ${pkgs.bun}/bin/bun install -g @types/react@latest
        ${pkgs.bun}/bin/bun install -g @types/react-dom@latest
        ${pkgs.bun}/bin/bun install -g eslint@latest
        ${pkgs.bun}/bin/bun install -g prettier@latest
        ${pkgs.bun}/bin/bun install -g nodemon@latest
        ${pkgs.bun}/bin/bun install -g concurrently@latest
        ${pkgs.bun}/bin/bun install -g serve@latest
        ${pkgs.bun}/bin/bun install -g http-server@latest
        ${pkgs.bun}/bin/bun install -g live-server@latest
        
        # Create symlinks in ~/.local/bin for easy access
        mkdir -p $USER_HOME/.local/bin
        ln -sf $USER_HOME/.npm-global/bin/vite $USER_HOME/.local/bin/vite 2>/dev/null || true
        ln -sf $USER_HOME/.npm-global/bin/create-vite $USER_HOME/.local/bin/create-vite 2>/dev/null || true
        ln -sf $USER_HOME/.npm-global/bin/create-next-app $USER_HOME/.local/bin/create-next-app 2>/dev/null || true
        ln -sf $USER_HOME/.npm-global/bin/tailwindcss $USER_HOME/.local/bin/tailwindcss 2>/dev/null || true
        ln -sf $USER_HOME/.npm-global/bin/tsc $USER_HOME/.local/bin/tsc 2>/dev/null || true
        ln -sf $USER_HOME/.npm-global/bin/tsx $USER_HOME/.local/bin/tsx 2>/dev/null || true
        ln -sf $USER_HOME/.npm-global/bin/eslint $USER_HOME/.local/bin/eslint 2>/dev/null || true
        ln -sf $USER_HOME/.npm-global/bin/prettier $USER_HOME/.local/bin/prettier 2>/dev/null || true
        ln -sf $USER_HOME/.npm-global/bin/serve $USER_HOME/.local/bin/serve 2>/dev/null || true
        ln -sf $USER_HOME/.npm-global/bin/http-server $USER_HOME/.local/bin/http-server 2>/dev/null || true
        ln -sf $USER_HOME/.npm-global/bin/live-server $USER_HOME/.local/bin/live-server 2>/dev/null || true
      "
    '';
  };
}