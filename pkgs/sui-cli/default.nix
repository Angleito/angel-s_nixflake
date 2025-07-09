{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, zlib
, libgcc
, darwin
}:

let
  version = "1.51.4";
  
  # Platform-specific configuration
  platformConfig = {
    x86_64-linux = {
      url = "https://github.com/MystenLabs/sui/releases/download/mainnet-v${version}/sui-mainnet-v${version}-ubuntu-x86_64.tgz";
      hash = "sha256-qc8ZaooiR8Bf6hTz3iK/aoBkQnisupOBpllWMH0h4/M=";
    };
    aarch64-linux = {
      url = "https://github.com/MystenLabs/sui/releases/download/mainnet-v${version}/sui-mainnet-v${version}-ubuntu-aarch64.tgz";
      hash = "sha256-Kz7uEjumC1ORDqGKrM6CWl4n7jtqrKF+iYYn0k7UOoE=";
    };
    x86_64-darwin = {
      url = "https://github.com/MystenLabs/sui/releases/download/mainnet-v${version}/sui-mainnet-v${version}-macos-x86_64.tgz";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # To be updated
    };
    aarch64-darwin = {
      url = "https://github.com/MystenLabs/sui/releases/download/mainnet-v${version}/sui-mainnet-v${version}-macos-arm64.tgz";
      hash = "sha256-HAvtZxM48cxF/9wCfyVUqGaERrHOzibmIAXHvaTULVI=";
    };
  };
  
  # Get platform configuration for current system
  platform = platformConfig.${stdenv.hostPlatform.system} or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");
  
in stdenv.mkDerivation {
  pname = "sui-cli";
  inherit version;
  
  src = fetchurl {
    inherit (platform) url hash;
  };
  
  # The tar file contains binaries directly without directory structure
  sourceRoot = ".";
  
  # Dependencies for Linux systems
  nativeBuildInputs = lib.optionals stdenv.isLinux [
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
    
    # Copy the sui binary
    cp sui $out/bin/sui
    
    # Make it executable
    chmod +x $out/bin/sui
    
    # Copy other related binaries if they exist
    for bin in sui-tool sui-debug sui-test-validator move-analyzer sui-graphql-rpc sui-bridge-cli sui-data-ingestion sui-bridge; do
      if [ -f "$bin" ]; then
        cp "$bin" $out/bin/
        chmod +x $out/bin/"$bin"
      fi
    done
    
    runHook postInstall
  '';
  
  # Platform-specific post-installation fixes
  postInstall = lib.optionalString stdenv.isDarwin ''
    # For macOS, remove code signatures to avoid issues
    if command -v codesign &> /dev/null; then
      codesign --remove-signature $out/bin/sui || true
      for bin in $out/bin/*; do
        if [ -f "$bin" ] && [ -x "$bin" ]; then
          codesign --remove-signature "$bin" || true
        fi
      done
    fi
  '' + lib.optionalString stdenv.isLinux ''
    # For Linux, autoPatchelfHook should handle most dependencies
    # Additional Linux-specific handling can be added here
  '';
  
  meta = with lib; {
    description = "Sui CLI - Command line interface for the Sui blockchain";
    homepage = "https://github.com/MystenLabs/sui";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    maintainers = [ ];
    mainProgram = "sui";
  };
}
