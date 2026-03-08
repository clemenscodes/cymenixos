{
  lib,
  buildNpmPackage,
  fetchurl,
  nodejs_22,
  makeWrapper,
}:
buildNpmPackage {
  pname = "mcp-server-sequential-thinking";
  version = "0.6.2";

  src = fetchurl {
    url = "https://registry.npmjs.org/@modelcontextprotocol/server-sequential-thinking/-/server-sequential-thinking-0.6.2.tgz";
    hash = "sha256-9RKojbXO5zqyYZ0KtYmRNvmfiLkwiPpq6OLujCkkKeg=";
  };

  postPatch = ''
    cp ${./sequential-thinking-package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-23JquybSxH5Ku3d7OwrEDaRiscYCzrCh7/lvcuujqGw=";
  nodejs = nodejs_22;
  dontNpmBuild = true;

  nativeBuildInputs = [makeWrapper];

  installPhase = ''
    mkdir -p $out/bin $out/lib/mcp-server-sequential-thinking
    cp dist/index.js $out/lib/mcp-server-sequential-thinking/
    cp -r node_modules $out/lib/mcp-server-sequential-thinking/
    chmod +x $out/lib/mcp-server-sequential-thinking/index.js
    makeWrapper ${nodejs_22}/bin/node $out/bin/mcp-server-sequential-thinking \
      --add-flags "$out/lib/mcp-server-sequential-thinking/index.js" \
      --chdir "$out/lib/mcp-server-sequential-thinking"
  '';

  meta = {
    description = "MCP server for structured sequential reasoning and problem decomposition";
    homepage = "https://github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking";
    license = lib.licenses.mit;
    mainProgram = "mcp-server-sequential-thinking";
  };
}
