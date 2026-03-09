{
  lib,
  buildNpmPackage,
  fetchurl,
  nodejs_22,
  makeWrapper,
}:
buildNpmPackage {
  pname = "mcp-server-filesystem";
  version = "0.6.2";

  src = fetchurl {
    url = "https://registry.npmjs.org/@modelcontextprotocol/server-filesystem/-/server-filesystem-0.6.2.tgz";
    hash = "sha256-+kg0UGUoLBGwSukJp8GW17EK6uscVNF9KgKzOxouFPI=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-wL5EtK4sey3CPy4zdPEf1aoZ6dD9+tx/xcCZGE45NgA=";
  nodejs = nodejs_22;
  dontNpmBuild = true;

  nativeBuildInputs = [makeWrapper];

  installPhase = ''
    mkdir -p $out/bin $out/lib/mcp-server-filesystem
    cp dist/index.js $out/lib/mcp-server-filesystem/
    cp -r node_modules $out/lib/mcp-server-filesystem/
    chmod +x $out/lib/mcp-server-filesystem/index.js
    makeWrapper ${nodejs_22}/bin/node $out/bin/mcp-server-filesystem \
      --add-flags "$out/lib/mcp-server-filesystem/index.js" \
      --chdir "$out/lib/mcp-server-filesystem"
  '';

  meta = {
    description = "MCP server for local filesystem access with configurable allowed directories";
    homepage = "https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem";
    license = lib.licenses.mit;
    mainProgram = "mcp-server-filesystem";
  };
}
