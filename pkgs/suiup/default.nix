{ lib
, stdenv
, fetchFromGitHub
, rustPlatform
, pkg-config
, openssl
, darwin
}:

rustPlatform.buildRustPackage rec {
  pname = "suiup";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "MystenLabs";
    repo = "suiup";
    rev = "v${version}";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

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

  # Set environment variables for compilation
  OPENSSL_NO_VENDOR = 1;

  # Create post-install setup
  postInstall = ''
    # Create suiup directory structure
    mkdir -p $out/share/suiup
    
    # Create a wrapper script that sets up the environment
    cat > $out/bin/suiup-setup << 'EOF'
#!/bin/bash

# Set up suiup environment
export SUIUP_HOME="$HOME/.suiup"
export SUIUP_DEFAULT_BIN_DIR="$HOME/.local/bin"

# Create necessary directories
mkdir -p "$SUIUP_HOME"
mkdir -p "$SUIUP_DEFAULT_BIN_DIR"

# Add to PATH if not already there
if [[ ":$PATH:" != *":$SUIUP_DEFAULT_BIN_DIR:"* ]]; then
    export PATH="$SUIUP_DEFAULT_BIN_DIR:$PATH"
fi

# Run the actual suiup command
exec ${placeholder "out"}/bin/suiup "$@"
EOF

    chmod +x $out/bin/suiup-setup
    
    # Create a simple activation script for system setup
    cat > $out/share/suiup/activate.sh << 'EOF'
#!/bin/bash

# Set up suiup for the user
USER_HOME="$1"
USER_NAME="$2"

# Create suiup directories
sudo -u "$USER_NAME" mkdir -p "$USER_HOME/.suiup"
sudo -u "$USER_NAME" mkdir -p "$USER_HOME/.local/bin"

# Install walrus via suiup
sudo -u "$USER_NAME" bash -c "
  export HOME=$USER_HOME
  export SUIUP_HOME=$USER_HOME/.suiup
  export SUIUP_DEFAULT_BIN_DIR=$USER_HOME/.local/bin
  export PATH=$USER_HOME/.local/bin:$PATH
  
  # Initialize suiup and install walrus
  ${placeholder "out"}/bin/suiup install walrus --latest || true
"
EOF

    chmod +x $out/share/suiup/activate.sh
  '';

  meta = with lib; {
    description = "Installer and version manager for Sui toolchain";
    longDescription = ''
      Suiup is a tool to install and manage different versions of CLI tools
      for working in the Sui ecosystem. It allows you to easily install and
      switch between different versions of sui, mvr, and walrus.
    '';
    homepage = "https://github.com/MystenLabs/suiup";
    license = licenses.asl20;
    platforms = platforms.unix;
    maintainers = [ ];
    mainProgram = "suiup";
  };
}