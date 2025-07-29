{ lib
, stdenv
, fetchurl
, makeWrapper
, nodejs_20
, unzip
}:

stdenv.mkDerivation rec {
  pname = "claude-code";
  version = "1.0.62"; # Update this to latest version

  src = fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    sha256 = "1ff27y39li09aqq69andn25j7jk80155kmjb2p9p9amgnyi75qfr";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ nodejs_20 ];

  unpackPhase = ''
    tar -xzf $src
  '';

  installPhase = ''
    mkdir -p $out/lib/node_modules/@anthropic-ai/claude-code
    cp -r package/* $out/lib/node_modules/@anthropic-ai/claude-code/
    
    # Create bin directory
    mkdir -p $out/bin
    
    # Create wrapper script
    makeWrapper ${nodejs_20}/bin/node $out/bin/claude \
      --add-flags "$out/lib/node_modules/@anthropic-ai/claude-code/cli.js" \
      --prefix PATH : ${lib.makeBinPath [ nodejs_20 ]}
    
    # Make cli.js executable
    chmod +x $out/lib/node_modules/@anthropic-ai/claude-code/cli.js
  '';

  meta = with lib; {
    description = "Agentic coding tool that lives in your terminal";
    homepage = "https://github.com/anthropics/claude-code";
    license = licenses.mit;
    maintainers = [];
    platforms = platforms.all;
  };
}