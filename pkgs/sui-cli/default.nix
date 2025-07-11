{ lib
, stdenv
, fetchurl
, unzip
}:

let
  version = "1.51.5";
  
  # System-specific binary URLs
  urls = {
    "x86_64-linux" = "https://github.com/MystenLabs/sui/releases/download/mainnet-v${version}/sui-mainnet-v${version}-ubuntu-x86_64.tgz";
    "aarch64-linux" = "https://github.com/MystenLabs/sui/releases/download/mainnet-v${version}/sui-mainnet-v${version}-ubuntu-aarch64.tgz";
    "x86_64-darwin" = "https://github.com/MystenLabs/sui/releases/download/mainnet-v${version}/sui-mainnet-v${version}-macos-x86_64.tgz";
    "aarch64-darwin" = "https://github.com/MystenLabs/sui/releases/download/mainnet-v${version}/sui-mainnet-v${version}-macos-arm64.tgz";
  };
  
  # System-specific hashes
  hashes = {
    "x86_64-linux" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";  # Placeholder
    "aarch64-linux" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";  # Placeholder
    "x86_64-darwin" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";   # Placeholder
    "aarch64-darwin" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";  # Placeholder
  };
  
  url = urls.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
  hash = hashes.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in

stdenv.mkDerivation {
  pname = "sui-cli";
  inherit version;
  
  src = fetchurl {
    inherit url;
    # Use lib.fakeSha256 to get the actual hash during build
    sha256 = lib.fakeSha256;
  };
  
  sourceRoot = ".";
  
  installPhase = ''
    mkdir -p $out/bin
    
    # The archive should contain the sui binary
    if [ -f sui ]; then
      cp sui $out/bin/sui
    elif [ -f ./sui ]; then
      cp ./sui $out/bin/sui
    else
      # Look for sui binary in extracted files
      find . -name "sui" -type f -executable | head -1 | xargs -I {} cp {} $out/bin/sui
    fi
    
    chmod +x $out/bin/sui
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
