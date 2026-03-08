{
  lib,
  stdenv,
  fetchurl,
  nodejs_22,
  makeWrapper,
}:
stdenv.mkDerivation {
  pname = "nx-mcp";
  version = "0.23.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/nx-mcp/-/nx-mcp-0.23.0.tgz";
    hash = "sha256-4WDwqpGJcp0+PaJ7ZQ2QwOVGKO2yiMh8YjnnbB6i8ZE=";
  };

  nativeBuildInputs = [makeWrapper];

  # Pre-built single-file bundle with no dependencies
  installPhase = ''
    mkdir -p $out/bin $out/lib/nx-mcp
    cp main.js $out/lib/nx-mcp/
    chmod +x $out/lib/nx-mcp/main.js
    makeWrapper ${nodejs_22}/bin/node $out/bin/nx-mcp \
      --add-flags "$out/lib/nx-mcp/main.js"
  '';

  meta = {
    description = "MCP server for Nx monorepo — workspace awareness, task graph, and generators";
    homepage = "https://github.com/nrwl/nx-console";
    license = lib.licenses.mit;
    mainProgram = "nx-mcp";
  };
}
