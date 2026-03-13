{
  lib,
  stdenv,
  fetchurl,
  nodejs_22,
  makeWrapper,
}:
stdenv.mkDerivation {
  pname = "chrome-devtools-mcp";
  version = "0.20.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/chrome-devtools-mcp/-/chrome-devtools-mcp-0.20.0.tgz";
    hash = "sha256-bM78yB6NV7OAwRevJTN+sJBlv7UbcCcHgJTJafUGK+8=";
  };

  nativeBuildInputs = [makeWrapper];

  unpackPhase = ''
    tar xzf $src
    mv package source
  '';

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin $out/lib/chrome-devtools-mcp
    cp -r source/build/src/. $out/lib/chrome-devtools-mcp/
    chmod +x $out/lib/chrome-devtools-mcp/bin/chrome-devtools-mcp.js
    makeWrapper ${nodejs_22}/bin/node $out/bin/chrome-devtools-mcp \
      --add-flags "$out/lib/chrome-devtools-mcp/bin/chrome-devtools-mcp.js"
  '';

  meta = {
    description = "Chrome DevTools MCP server (official, by Google)";
    homepage = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
    license = lib.licenses.asl20;
    mainProgram = "chrome-devtools-mcp";
  };
}
