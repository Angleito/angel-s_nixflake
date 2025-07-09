{ lib
, stdenv
, makeWrapper
, suiup
}:

stdenv.mkDerivation {
  pname = "walrus-cli";
  version = "latest";
  
  # No source needed - we'll use suiup to install
  dontUnpack = true;
  
  nativeBuildInputs = [ makeWrapper ];
  
  buildInputs = [ suiup ];
  
  # No build phase needed
  dontBuild = true;
  
  # Install via suiup
  installPhase = ''
    runHook preInstall
    
    # Create bin directory
    mkdir -p $out/bin
    
    # Create configuration directory
    mkdir -p $out/share/walrus
    
    # Create default configuration file
    cat > $out/share/walrus/client_config.yaml << 'EOF'
system_object: 0x20266a17b4f1a216727f3eef5772f8d486a9e3b5e319af80a5b75809c035561d
storage_nodes:
  - name: wal-testnet-0
    rpc_url: https://rpc-walrus-testnet.nodes.guru:443
    rest_url: https://walrus-testnet.blockscope.net/v1
  - name: wal-testnet-1
    rpc_url: https://walrus-testnet-rpc.bartestnet.com
    rest_url: https://walrus-testnet-storage.bartestnet.com/v1
  - name: wal-testnet-2
    rpc_url: https://walrus-testnet.blockscope.net
    rest_url: https://walrus-testnet-storage.blockscope.net/v1
  - name: wal-testnet-3
    rpc_url: https://walrus-testnet-rpc.nodes.guru
    rest_url: https://walrus-testnet-storage.nodes.guru/v1
  - name: wal-testnet-4
    rpc_url: https://walrus.testnet.arcadia.global
    rest_url: https://walrus-storage.testnet.arcadia.global/v1
EOF
    
    # Create wrapper script that uses suiup to install and run walrus
    cat > $out/bin/walrus << 'EOF'
#!/bin/bash

# Set up environment
export SUIUP_HOME="$HOME/.suiup"
export SUIUP_DEFAULT_BIN_DIR="$HOME/.local/bin"

# Create necessary directories
mkdir -p "$SUIUP_HOME"
mkdir -p "$SUIUP_DEFAULT_BIN_DIR"

# Add to PATH if not already there
if [[ ":$PATH:" != *":$SUIUP_DEFAULT_BIN_DIR:"* ]]; then
    export PATH="$SUIUP_DEFAULT_BIN_DIR:$PATH"
fi

# Check if walrus is installed via suiup
if [[ ! -f "$SUIUP_DEFAULT_BIN_DIR/walrus" ]]; then
    echo "Installing Walrus CLI via suiup..."
    ${suiup}/bin/suiup install walrus --latest
fi

# Set up config if needed
CONFIG_DIR="$HOME/.config/walrus"
CONFIG_FILE="$CONFIG_DIR/client_config.yaml"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Copy default config if user config doesn't exist
if [[ ! -f "$CONFIG_FILE" ]]; then
    cp "${placeholder "out"}/share/walrus/client_config.yaml" "$CONFIG_FILE"
fi

# Try to run walrus from suiup installation
if [[ -f "$SUIUP_DEFAULT_BIN_DIR/walrus" ]]; then
    exec "$SUIUP_DEFAULT_BIN_DIR/walrus" "$@"
else
    echo "Error: Walrus CLI not found. Please run 'suiup install walrus' manually."
    exit 1
fi
EOF
    
    chmod +x $out/bin/walrus
    
    runHook postInstall
  '';
  
  # Create activation script for system setup
  postInstall = ''
    # Create activation script
    cat > $out/share/walrus/activate.sh << 'EOF'
#!/bin/bash

# Set up walrus for the user
USER_HOME="$1"
USER_NAME="$2"

# Create walrus directories
sudo -u "$USER_NAME" mkdir -p "$USER_HOME/.config/walrus"
sudo -u "$USER_NAME" mkdir -p "$USER_HOME/.suiup"
sudo -u "$USER_NAME" mkdir -p "$USER_HOME/.local/bin"

# Install walrus via suiup
sudo -u "$USER_NAME" bash -c "
  export HOME=$USER_HOME
  export SUIUP_HOME=$USER_HOME/.suiup
  export SUIUP_DEFAULT_BIN_DIR=$USER_HOME/.local/bin
  export PATH=$USER_HOME/.local/bin:$PATH
  
  # Install walrus
  ${suiup}/bin/suiup install walrus --latest || true
  
  # Copy default config if it doesn't exist
  if [[ ! -f $USER_HOME/.config/walrus/client_config.yaml ]]; then
    cp ${placeholder "out"}/share/walrus/client_config.yaml $USER_HOME/.config/walrus/client_config.yaml
  fi
"
EOF

    chmod +x $out/share/walrus/activate.sh
  '';
  
  meta = with lib; {
    description = "Walrus CLI - Command line interface for the Walrus decentralized storage and data availability protocol (installed via suiup)";
    longDescription = ''
      Walrus is a decentralized storage and data availability protocol designed to provide
      high-performance, low-cost storage for large data objects. This package uses suiup
      to install and manage the Walrus CLI, ensuring you always have the latest version.
    '';
    homepage = "https://github.com/MystenLabs/walrus";
    license = licenses.asl20;
    platforms = platforms.unix;
    maintainers = [ ];
    mainProgram = "walrus";
  };
}