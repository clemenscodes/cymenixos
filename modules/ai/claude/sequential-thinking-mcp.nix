{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
  makeWrapper,
}:
buildNpmPackage {
  pname = "mcp-server-sequential-thinking";
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
    cd src/sequentialthinking
    npm run build
  '';

  installPhase = ''
    mkdir -p $out/bin $out/lib/mcp-server-sequential-thinking
    cp dist/index.js $out/lib/mcp-server-sequential-thinking/
    chmod +x $out/lib/mcp-server-sequential-thinking/index.js
    makeWrapper ${nodejs_22}/bin/node $out/bin/mcp-server-sequential-thinking \
      --add-flags "$out/lib/mcp-server-sequential-thinking/index.js"
  '';

  meta = {
    description = "MCP server for structured sequential reasoning and problem decomposition";
    homepage = "https://github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking";
    license = lib.licenses.mit;
    mainProgram = "mcp-server-sequential-thinking";
  };
}
