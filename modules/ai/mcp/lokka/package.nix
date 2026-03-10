{
  lib,
  buildNpmPackage,
  fetchurl,
  nodejs_22,
  makeWrapper,
}:
buildNpmPackage {
  pname = "lokka-mcp-server";
  version = "0.3.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/@merill/lokka/-/lokka-0.3.0.tgz";
    hash = "sha256-dCOtnKhtstYxVZ1vezpMKuElSKSZr5gQ0M6oHTe7yrc=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-grnxp1cCfHDpFkUfzpPEgiE38xWmOdz6pC2VbdeGOlI=";
  nodejs = nodejs_22;
  makeCacheWritable = true;

  # npm tarball ships pre-built dist; no build needed
  dontNpmBuild = true;

  npmFlags = ["--legacy-peer-deps" "--ignore-scripts"];

  nativeBuildInputs = [makeWrapper];

  dontNpmInstall = true;

  installPhase = ''
    mkdir -p $out/bin $out/lib/lokka-mcp-server
    cp -r build $out/lib/lokka-mcp-server/
    cp -r node_modules $out/lib/lokka-mcp-server/
    chmod +x $out/lib/lokka-mcp-server/build/main.js
    makeWrapper ${nodejs_22}/bin/node $out/bin/lokka-mcp-server \
      --add-flags "$out/lib/lokka-mcp-server/build/main.js" \
      --chdir "$out/lib/lokka-mcp-server"
  '';

  # remove dangling symlinks before noBrokenSymlinks check
  preFixup = ''
    find $out -xtype l -delete
  '';

  meta = {
    description = "Microsoft 365 MCP server via Lokka — covers Graph API, Azure, Entra, Exchange, Teams, SharePoint";
    homepage = "https://github.com/merill/lokka";
    license = lib.licenses.mit;
    mainProgram = "lokka-mcp-server";
  };
}
