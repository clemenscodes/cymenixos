{
  lib,
  buildNpmPackage,
  fetchurl,
  nodejs_22,
  makeWrapper,
}:
buildNpmPackage {
  pname = "git-mcp-server";
  version = "2.10.0";

  # Use the pre-built npm tarball (dist/index.js is included)
  src = fetchurl {
    url = "https://registry.npmjs.org/@cyanheads/git-mcp-server/-/git-mcp-server-2.10.0.tgz";
    hash = "sha256-ySBGO+YraVrMX9Wj/bvSsTcncLG5lr413r2DGQrqXug=";
  };

  # Use a generated package-lock.json for the 3 runtime deps
  postPatch = ''
    cp ${./git-mcp-package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-7Pf6qBWkXA8fGoY4yOlOUHzOQdVSSw6Ti5LgjEwxwKc=";
  nodejs = nodejs_22;

  nativeBuildInputs = [makeWrapper];

  # Already pre-built in the npm tarball
  dontNpmBuild = true;

  installPhase = ''
    mkdir -p $out/bin $out/lib/git-mcp-server
    cp dist/index.js $out/lib/git-mcp-server/
    cp -r node_modules $out/lib/git-mcp-server/
    chmod +x $out/lib/git-mcp-server/index.js
    makeWrapper ${nodejs_22}/bin/node $out/bin/git-mcp-server \
      --add-flags "$out/lib/git-mcp-server/index.js" \
      --chdir "$out/lib/git-mcp-server"
  '';

  meta = {
    description = "MCP server for Git operations — repository management, commits, branches, and diffs";
    homepage = "https://github.com/cyanheads/git-mcp-server";
    license = lib.licenses.asl20;
    mainProgram = "git-mcp-server";
  };
}
