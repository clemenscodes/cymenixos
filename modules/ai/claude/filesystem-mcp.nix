{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
  makeWrapper,
}:
buildNpmPackage {
  pname = "mcp-server-filesystem";
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
    cd src/filesystem
    npm run build
  '';

  installPhase = ''
    mkdir -p $out/bin $out/lib/mcp-server-filesystem
    cp dist/index.js $out/lib/mcp-server-filesystem/
    chmod +x $out/lib/mcp-server-filesystem/index.js
    makeWrapper ${nodejs_22}/bin/node $out/bin/mcp-server-filesystem \
      --add-flags "$out/lib/mcp-server-filesystem/index.js"
  '';

  meta = {
    description = "MCP server for local filesystem access with configurable allowed directories";
    homepage = "https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem";
    license = lib.licenses.mit;
    mainProgram = "mcp-server-filesystem";
  };
}
