{ config, lib, pkgs, ... }:

let
  cfg = config.development.database;
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  
  # Get the primary user based on platform
  primaryUser = if isDarwin then 
    config.system.primaryUser
  else
    cfg.primaryUser;
in {
  options.development.database = {
    enable = lib.mkEnableOption "Database development tools";
    
    primaryUser = lib.mkOption {
      type = lib.types.str;
      default = "angel";
      description = "Primary user for database setup (used on Linux)";
    };
    
    postgresql = {
      enable = lib.mkEnableOption "PostgreSQL database";
      version = lib.mkOption {
        type = lib.types.str;
        default = "14";
        description = "PostgreSQL version to install";
      };
      enableService = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable PostgreSQL service (requires additional setup)";
      };
    };
    
    redis = {
      enable = lib.mkEnableOption "Redis database";
      enableService = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Redis service";
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Common configuration for all platforms
    {
      # Install database packages
      environment.systemPackages = with pkgs; [
        # PostgreSQL
      ] ++ lib.optionals cfg.postgresql.enable [
        postgresql_14
        postgresql_14.lib
      ] ++ lib.optionals cfg.redis.enable [
        redis
      ];
    }
    
    # Darwin-specific configuration
    (lib.mkIf isDarwin {
      # PostgreSQL setup script
      system.activationScripts.postgresqlSetup = lib.mkIf cfg.postgresql.enable {
        text = ''
          USER_HOME="${config.users.users.${primaryUser}.home}"
          POSTGRES_DATA_DIR="$USER_HOME/.postgresql/data"
          
          # Create PostgreSQL data directory
          sudo -u ${primaryUser} mkdir -p "$POSTGRES_DATA_DIR"
          
          # Initialize database if not already done
          if [ ! -f "$POSTGRES_DATA_DIR/PG_VERSION" ]; then
            echo "Initializing PostgreSQL database..."
            sudo -u ${primaryUser} ${pkgs.postgresql_14}/bin/initdb -D "$POSTGRES_DATA_DIR"
          fi
          
          # Create start/stop scripts
          sudo -u ${primaryUser} mkdir -p "$USER_HOME/.local/bin"
          
          cat > "$USER_HOME/.local/bin/postgres-start" << 'EOF'
          #!/bin/bash
          # Start PostgreSQL server
          DATA_DIR="$HOME/.postgresql/data"
          LOG_FILE="$HOME/.postgresql/postgres.log"
          
          if [ -f "$DATA_DIR/postmaster.pid" ]; then
            echo "PostgreSQL is already running"
            exit 0
          fi
          
          echo "Starting PostgreSQL..."
          ${pkgs.postgresql_14}/bin/pg_ctl -D "$DATA_DIR" -l "$LOG_FILE" start
          EOF
          
          cat > "$USER_HOME/.local/bin/postgres-stop" << 'EOF'
          #!/bin/bash
          # Stop PostgreSQL server
          DATA_DIR="$HOME/.postgresql/data"
          
          if [ ! -f "$DATA_DIR/postmaster.pid" ]; then
            echo "PostgreSQL is not running"
            exit 0
          fi
          
          echo "Stopping PostgreSQL..."
          ${pkgs.postgresql_14}/bin/pg_ctl -D "$DATA_DIR" stop
          EOF
          
          cat > "$USER_HOME/.local/bin/postgres-status" << 'EOF'
          #!/bin/bash
          # Check PostgreSQL status
          DATA_DIR="$HOME/.postgresql/data"
          
          if [ -f "$DATA_DIR/postmaster.pid" ]; then
            echo "PostgreSQL is running"
            ${pkgs.postgresql_14}/bin/pg_ctl -D "$DATA_DIR" status
          else
            echo "PostgreSQL is not running"
          fi
          EOF
          
          # Make scripts executable
          chmod +x "$USER_HOME/.local/bin/postgres-start"
          chmod +x "$USER_HOME/.local/bin/postgres-stop"
          chmod +x "$USER_HOME/.local/bin/postgres-status"
          
          echo "PostgreSQL setup complete!"
          echo "Use 'postgres-start', 'postgres-stop', and 'postgres-status' to manage the database"
        '';
      };

      # Redis setup script  
      system.activationScripts.redisSetup = lib.mkIf cfg.redis.enable {
        text = ''
          USER_HOME="${config.users.users.${primaryUser}.home}"
          REDIS_DATA_DIR="$USER_HOME/.redis"
          
          # Create Redis data directory
          sudo -u ${primaryUser} mkdir -p "$REDIS_DATA_DIR"
          
          # Create start/stop scripts
          sudo -u ${primaryUser} mkdir -p "$USER_HOME/.local/bin"
          
          cat > "$USER_HOME/.local/bin/redis-start" << 'EOF'
          #!/bin/bash
          # Start Redis server
          DATA_DIR="$HOME/.redis"
          
          if pgrep redis-server >/dev/null; then
            echo "Redis is already running"
            exit 0
          fi
          
          echo "Starting Redis..."
          ${pkgs.redis}/bin/redis-server --daemonize yes --dir "$DATA_DIR"
          EOF
          
          cat > "$USER_HOME/.local/bin/redis-stop" << 'EOF'
          #!/bin/bash
          # Stop Redis server
          
          if ! pgrep redis-server >/dev/null; then
            echo "Redis is not running"
            exit 0
          fi
          
          echo "Stopping Redis..."
          ${pkgs.redis}/bin/redis-cli shutdown
          EOF
          
          cat > "$USER_HOME/.local/bin/redis-status" << 'EOF'
          #!/bin/bash
          # Check Redis status
          
          if pgrep redis-server >/dev/null; then
            echo "Redis is running"
            ${pkgs.redis}/bin/redis-cli ping
          else
            echo "Redis is not running"
          fi
          EOF
          
          # Make scripts executable
          chmod +x "$USER_HOME/.local/bin/redis-start"
          chmod +x "$USER_HOME/.local/bin/redis-stop"
          chmod +x "$USER_HOME/.local/bin/redis-status"
          
          echo "Redis setup complete!"
          echo "Use 'redis-start', 'redis-stop', and 'redis-status' to manage Redis"
        '';
      };
    })
    
    # Linux-specific configuration
    # TODO: Re-enable when running on Linux
    # (lib.mkIf isLinux {
    #   # On NixOS, we can use proper systemd services
    #   services.postgresql = lib.mkIf (cfg.postgresql.enable && cfg.postgresql.enableService) {
    #     enable = true;
    #     package = pkgs.postgresql_14;
    #     enableTCPIP = true;
    #     authentication = pkgs.lib.mkOverride 10 ''
    #       local all all trust
    #       host all all 127.0.0.1/32 trust
    #       host all all ::1/128 trust
    #     '';
    #   };
    #   
    #   services.redis.servers."" = lib.mkIf (cfg.redis.enable && cfg.redis.enableService) {
    #     enable = true;
    #   };
    #   
    #   # Create helper scripts for Linux users
    #   systemd.user.services.database-setup = lib.mkIf (cfg.postgresql.enable || cfg.redis.enable) {
    #     description = "Setup database helper scripts";
    #     wantedBy = [ "default.target" ];
    #     serviceConfig = {
    #       Type = "oneshot";
    #       RemainAfterExit = true;
    #       ExecStart = pkgs.writeShellScript "database-setup" ''
    #         mkdir -p "$HOME/.local/bin"
    #         
    #         ${lib.optionalString cfg.postgresql.enable ''
    #           cat > "$HOME/.local/bin/postgres-start" << 'EOF'
    #           #!/bin/bash
    #           echo "PostgreSQL is managed by systemd. Use:"
    #           echo "  sudo systemctl start postgresql"
    #           echo "  sudo systemctl status postgresql"
    #           EOF
    #           chmod +x "$HOME/.local/bin/postgres-start"
    #         ''}
    #         
    #         ${lib.optionalString cfg.redis.enable ''
    #           cat > "$HOME/.local/bin/redis-start" << 'EOF'
    #           #!/bin/bash
    #           echo "Redis is managed by systemd. Use:"
    #           echo "  sudo systemctl start redis"
    #           echo "  sudo systemctl status redis"
    #           EOF
    #           chmod +x "$HOME/.local/bin/redis-start"
    #         ''}
    #       '';
    #     };
    #   };
    # })
  ]);
}