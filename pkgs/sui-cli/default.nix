{ lib
, stdenv
, fetchFromGitHub
, rustPlatform
, pkg-config
, openssl
, darwin
}:

let
  version = "1.51.4";
in rustPlatform.buildRustPackage {
  pname = "sui-cli";
  inherit version;
  
  src = fetchFromGitHub {
    owner = "MystenLabs";
    repo = "sui";
    rev = "mainnet-v${version}";
    hash = "sha256-9bM1Dypl/z7vOi76HsaIXIBOQ7D3B+20JbDwKh3aILY=";
  };
  
  cargoHash = "sha256-lRJA/Rz8+n1dY7iiY6hsNcYSFdGCdbvb9u7F6V0IpUw=";
  
  # Build only the sui binary
  cargoBuildFlags = [ "--bin" "sui" ];
  
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
  
  # Disable failing tests
  doCheck = false;
  
  meta = with lib; {
    description = "Sui CLI - Command line interface for the Sui blockchain";
    homepage = "https://github.com/MystenLabs/sui";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    maintainers = [ ];
    mainProgram = "sui";
  };
}
