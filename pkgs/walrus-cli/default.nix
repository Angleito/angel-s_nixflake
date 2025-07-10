{ lib
, stdenv
, fetchFromGitHub
, rustPlatform
, pkg-config
, openssl
, darwin
}:

rustPlatform.buildRustPackage {
  pname = "walrus-cli";
  version = "testnet";
  
  src = fetchFromGitHub {
    owner = "MystenLabs";
    repo = "walrus";
    rev = "testnet";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # To be updated with actual hash
  };
  
  cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # To be updated with actual hash
  
  # Build only the walrus binary
  cargoBuildFlags = [ "--bin" "walrus" ];
  
  nativeBuildInputs = [
    pkg-config
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
  
  # Install default configuration
  postInstall = ''
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