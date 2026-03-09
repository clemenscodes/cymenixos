{
  lib,
  buildNpmPackage,
  fetchurl,
  nodejs_22,
  makeWrapper,
}:
buildNpmPackage {
  pname = "mongodb-mcp-server";
  version = "1.8.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/mongodb-mcp-server/-/mongodb-mcp-server-1.8.0.tgz";
    hash = "sha256-lIQbxiCpPAD397jYbVIXxE9ozI3+OpCcu/sFW98nHBg=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-bFoftK9bkb/tfqWL1Os2lic/g8lbpTsAs9b/q+H8Hxw=";
  nodejs = nodejs_22;
  makeCacheWritable = true;

  # npm tarball ships pre-built dist/esm; no build needed
  dontNpmBuild = true;

  npmFlags = ["--legacy-peer-deps" "--ignore-scripts"];

  nativeBuildInputs = [makeWrapper];

  dontNpmInstall = true;

  installPhase = ''
    mkdir -p $out/bin $out/lib/mongodb-mcp-server
    cp -r dist/esm $out/lib/mongodb-mcp-server/
    cp -r node_modules $out/lib/mongodb-mcp-server/
    chmod +x $out/lib/mongodb-mcp-server/esm/index.js
    makeWrapper ${nodejs_22}/bin/node $out/bin/mongodb-mcp-server \
      --add-flags "$out/lib/mongodb-mcp-server/esm/index.js" \
      --chdir "$out/lib/mongodb-mcp-server"
  '';

  # remove dangling symlinks before noBrokenSymlinks check
  preFixup = ''
    find $out -xtype l -delete
  '';

  meta = {
    description = "Official MongoDB MCP server";
    homepage = "https://github.com/mongodb-js/mongodb-mcp-server";
    license = lib.licenses.asl20;
    mainProgram = "mongodb-mcp-server";
  };
}
