{ lib
, writeShellScriptBin
, curl
, stdenv
}:

# Create a wrapper that downloads and installs Walrus CLI on first use
writeShellScriptBin "walrus" ''
  #!/usr/bin/env bash
  set -euo pipefail
  
  WALRUS_PATH="$HOME/.local/bin/walrus-binary"
  CONFIG_PATH="$HOME/.config/walrus/client_config.yaml"
  
  # Check if walrus binary is already downloaded
  if [ ! -f "$WALRUS_PATH" ]; then
    echo "Downloading Walrus CLI..."
    
    # Determine architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "arm64" ]; then
      WALRUS_ARCH="arm64"
    else
      WALRUS_ARCH="x86_64"
    fi
    
    # Create directories
    mkdir -p "$HOME/.local/bin" "$HOME/.config/walrus"
    
    # Download Walrus binary
    ${curl}/bin/curl -L "https://github.com/MystenLabs/walrus-sites/releases/latest/download/site-builder-macos-$WALRUS_ARCH" -o "$WALRUS_PATH"
    chmod +x "$WALRUS_PATH"
    
    echo "Walrus CLI downloaded successfully!"
  fi
  
  # Create default configuration if it doesn't exist
  if [ ! -f "$CONFIG_PATH" ]; then
    echo "Creating default Walrus configuration..."
    cat > "$CONFIG_PATH" << 'EOF'
system_object: 0x70a61a5cf43b2c00aacf57e6784f5c8a09b4dd68de16f96b7c5a3bb5c3c8c04e5
storage_nodes:
  - name: wal-devnet-0
    rpc_url: https://rpc-walrus-testnet.nodes.guru:443
    rest_url: https://storage.testnet.sui.walrus.site/v1
  - name: wal-devnet-1
    rpc_url: https://walrus-testnet-rpc.bartestnet.com
    rest_url: https://walrus-testnet-storage.bartestnet.com/v1
  - name: wal-devnet-2
    rpc_url: https://walrus-testnet.blockscope.net
    rest_url: https://walrus-testnet-storage.blockscope.net/v1
  - name: wal-devnet-3
    rpc_url: https://walrus-testnet-rpc.nodes.guru
    rest_url: https://walrus-testnet-storage.nodes.guru/v1
  - name: wal-devnet-4
    rpc_url: https://walrus.testnet.arcadia.global
    rest_url: https://walrus-storage.testnet.arcadia.global/v1
EOF
  fi
  
  # Execute the real walrus command
  exec "$WALRUS_PATH" "$@"
''