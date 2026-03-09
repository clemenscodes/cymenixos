{
  lib,
  buildNpmPackage,
  fetchurl,
  nodejs_22,
  makeWrapper,
}:
buildNpmPackage {
  pname = "mcp-server-memory";
  version = "0.6.2";

  src = fetchurl {
    url = "https://registry.npmjs.org/@modelcontextprotocol/server-memory/-/server-memory-0.6.2.tgz";
    hash = "sha256-5JIbSQ0MQJbymt7yQMUy50s9hHbGDZIu6zIDclHgf1w=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-bUEeqOlwv/hfbT7tQYL9kbwYy6Ul5Nu8mTyhCTB6bM8=";
  nodejs = nodejs_22;
  dontNpmBuild = true;

  nativeBuildInputs = [makeWrapper];

  installPhase = ''
    mkdir -p $out/bin $out/lib/mcp-server-memory
    cp dist/index.js $out/lib/mcp-server-memory/
    cp -r node_modules $out/lib/mcp-server-memory/
    chmod +x $out/lib/mcp-server-memory/index.js
    makeWrapper ${nodejs_22}/bin/node $out/bin/mcp-server-memory \
      --add-flags "$out/lib/mcp-server-memory/index.js" \
      --chdir "$out/lib/mcp-server-memory"
  '';

  meta = {
    description = "MCP server providing persistent memory via a knowledge graph";
    homepage = "https://github.com/modelcontextprotocol/servers/tree/main/src/memory";
    license = lib.licenses.mit;
    mainProgram = "mcp-server-memory";
  };
}
