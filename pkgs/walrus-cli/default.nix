{ lib
, stdenv
, fetchFromGitHub
, rustPlatform
, pkg-config
, openssl
, darwin
, makeWrapper
}:

rustPlatform.buildRustPackage {
  pname = "walrus-cli";
  version = "testnet";
  
  src = fetchFromGitHub {
    owner = "MystenLabs";
    repo = "walrus";
    rev = "testnet";
    hash = "sha256-FyrIPhHfeIOcrHcj+vlqHHnWnYkf0UrIXLLK0ETFFJo=";
  };
  
  cargoHash = "sha256-RTrLZDKz6pN6o5lZxbXr/03vlUuEGEUstnSt4QPufBE=";
  
  # Build only the walrus binary
  cargoBuildFlags = [ "--bin" "walrus" ];
  
  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];
  
  buildInputs = [
    openssl
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.Security
    darwin.apple_sdk.frameworks.CoreFoundation
    darwin.apple_sdk.frameworks.SystemConfiguration
  ];
  
  # Set environment variables for OpenSSL
  OPENSSL_NO_VENDOR = 1;
  
  # Disable failing tests
  doCheck = false;
  
  # Install default configuration and create wrapper
  postInstall = ''
    # Create configuration directory
    mkdir -p $out/share/walrus
    
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
    
    # Create wrapper script
    wrapProgram $out/bin/walrus \
      --run 'CONFIG_DIR="$HOME/.config/walrus"; CONFIG_FILE="$CONFIG_DIR/client_config.yaml"; mkdir -p "$CONFIG_DIR"; if [ ! -f "$CONFIG_FILE" ]; then cp "'$out'/share/walrus/client_config.yaml" "$CONFIG_FILE"; fi' \
      --unset LOG_FORMAT
  '';
  
  meta = with lib; {
    description = "Walrus CLI - Command line interface for the Walrus decentralized storage and data availability protocol";
    longDescription = ''
      Walrus is a decentralized storage and data availability protocol designed to provide
      high-performance, low-cost storage for large data objects. This package builds the
      Walrus CLI from source using cargo.
    '';
    homepage = "https://github.com/MystenLabs/walrus";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    maintainers = [ ];
    mainProgram = "walrus";
  };
}
