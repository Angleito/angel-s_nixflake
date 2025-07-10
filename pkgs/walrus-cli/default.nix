{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
, zlib
, libgcc
, darwin
}:

let
  version = "1.28.1";
  
  # Platform-specific configuration
  platformConfig = {
    x86_64-linux = {
      url = "https://github.com/MystenLabs/walrus/releases/download/testnet-v${version}/walrus-testnet-v${version}-ubuntu-x86_64.tgz";
      sha256 = "18qcki3kj76l4ld4dmi7panlc7wilikmjr0g2pn9k1925rfx5qka";
    };
    aarch64-linux = {
      url = "https://github.com/MystenLabs/walrus/releases/download/testnet-v${version}/walrus-testnet-v${version}-ubuntu-aarch64.tgz";
      sha256 = "0x8iqzsk8pmcs91i7wmck64g0vxrrxv8ii4pd4baqrravp6rnap2";
    };
    x86_64-darwin = {
      url = "https://github.com/MystenLabs/walrus/releases/download/testnet-v${version}/walrus-testnet-v${version}-macos-x86_64.tgz";
      sha256 = "1iv8ginz6sbf71psd49vv0m8gjsfaw0n8fcsn5i1xxkh8h2zbyiv";
    };
    aarch64-darwin = {
      url = "https://github.com/MystenLabs/walrus/releases/download/testnet-v${version}/walrus-testnet-v${version}-macos-arm64.tgz";
      sha256 = "1m5j4606kx7jg14kdq20472xsfysb46zcdn024kv65ys38knrjfj";
    };
  };
  
  # Get platform configuration for current system
  platform = platformConfig.${stdenv.hostPlatform.system} or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");
  
in stdenv.mkDerivation {
  pname = "walrus-cli";
  inherit version;
  
  src = fetchurl {
    inherit (platform) url sha256;
  };
  
  # The tar file contains binaries directly without directory structure
  sourceRoot = ".";
  
  # Dependencies for Linux systems
  nativeBuildInputs = [ makeWrapper ] ++ lib.optionals stdenv.isLinux [
    autoPatchelfHook
  ];
  
  buildInputs = lib.optionals stdenv.isLinux [
    zlib
    libgcc.lib
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.Security
    darwin.apple_sdk.frameworks.CoreFoundation
    darwin.apple_sdk.frameworks.SystemConfiguration
  ];
  
  # Don't strip debug symbols as they might be needed for the binary
  dontStrip = true;
  
  # Extract and install
  installPhase = ''
    runHook preInstall
    
    # Create bin directory
    mkdir -p $out/bin
    
    # Create configuration directory
    mkdir -p $out/share/walrus
    
    # Copy the walrus binary
    cp walrus $out/bin/walrus
    
    # Make it executable
    chmod +x $out/bin/walrus
    
    # Create default configuration file
    cat > $out/share/walrus/client_config.yaml << 'EOF'
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
    
    # Copy other related binaries if they exist
    for bin in walrus-client walrus-storage walrus-aggregator; do
      if [ -f "$bin" ]; then
        cp "$bin" $out/bin/
        chmod +x $out/bin/"$bin"
      fi
    done
    
    runHook postInstall
  '';
  
  # Platform-specific post-installation fixes
  postInstall = lib.optionalString stdenv.isDarwin ''
    # For macOS, we might need to handle code signing
    # Remove any existing signatures first (only if codesign is available)
    if command -v codesign &> /dev/null; then
      codesign --remove-signature $out/bin/walrus || true
    fi
    
    # Fix any dylib references if needed
    # This is a placeholder for future macOS-specific handling
  '' + lib.optionalString stdenv.isLinux ''
    # For Linux, autoPatchelfHook should handle most dependencies
    # Additional Linux-specific handling can be added here
  '';
  
  # Create a wrapper script that sets up config if needed
  postFixup = ''
    # Create a simple wrapper that ensures config exists
    mv $out/bin/walrus $out/bin/.walrus-wrapped
    
    cat > $out/bin/walrus << EOF
#!/bin/bash
CONFIG_DIR="\$HOME/.config/walrus"
CONFIG_FILE="\$CONFIG_DIR/client_config.yaml"

# Create config directory if it doesn't exist
mkdir -p "\$CONFIG_DIR"

# Copy default config if user config doesn't exist
if [ ! -f "\$CONFIG_FILE" ]; then
  cp "$out/share/walrus/client_config.yaml" "\$CONFIG_FILE"
fi

# Unset LOG_FORMAT to avoid conflicts
unset LOG_FORMAT

# Execute the real walrus command
exec "$out/bin/.walrus-wrapped" "\$@"
EOF
    
    chmod +x $out/bin/walrus
  '';
  
  meta = with lib; {
    description = "Walrus CLI - Command line interface for the Walrus decentralized storage and data availability protocol";
    longDescription = ''
      Walrus is a decentralized storage and data availability protocol designed to provide
      high-performance, low-cost storage for large data objects. The Walrus CLI allows you to
      interact with the Walrus network to store and retrieve data.
    '';
    homepage = "https://github.com/MystenLabs/walrus";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    maintainers = [ ];
    mainProgram = "walrus";
  };
}
