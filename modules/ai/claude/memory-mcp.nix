{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
  makeWrapper,
}:
buildNpmPackage {
  pname = "mcp-server-memory";
  version = "0.6.2";

  src = fetchFromGitHub {
    owner = "modelcontextprotocol";
    repo = "servers";
    rev = "typescript-servers-0.6.2";
    hash = "sha256-FKotJUzP29iZzfRqfWGhdZosWxGX7BBOExxznfLi7Us=";
  };

  npmDepsHash = "sha256-fuJQxbHrv/x49I3WDMQxXC/+kuv/JiTDdHiAEaN94Zw=";
  nodejs = nodejs_22;

  nativeBuildInputs = [makeWrapper];

  buildPhase = ''
    cd src/memory
    npm run build
  '';

  installPhase = ''
    mkdir -p $out/bin $out/lib/mcp-server-memory
    cp dist/index.js $out/lib/mcp-server-memory/
    chmod +x $out/lib/mcp-server-memory/index.js
    makeWrapper ${nodejs_22}/bin/node $out/bin/mcp-server-memory \
      --add-flags "$out/lib/mcp-server-memory/index.js"
  '';

  meta = {
    description = "MCP server providing persistent memory via a knowledge graph";
    homepage = "https://github.com/modelcontextprotocol/servers/tree/main/src/memory";
    license = lib.licenses.mit;
    mainProgram = "mcp-server-memory";
  };
}
