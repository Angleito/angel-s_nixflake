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
  src = fetchFromGitHub {
    owner = "MystenLabs";
    repo = "sui";
    rev = "mainnet-v${version}";
    hash = "sha256-e9t7f5Y2ZKndP0gpBhuyQQ2an5NmwJRuelJCJX1Udt0=";
  };
in rustPlatform.buildRustPackage {
  pname = "sui-cli";
  inherit version src;
  
  cargoHash = "sha256-we5MbrtxZM68Xpozs7Ai/WTB4qEpFXPZwyPxkNgq7Gs=";
  
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
  
  meta = with lib; {
    description = "Sui CLI - Command line interface for the Sui blockchain";
    homepage = "https://github.com/MystenLabs/sui";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    maintainers = [ ];
    mainProgram = "sui";
  };
}
