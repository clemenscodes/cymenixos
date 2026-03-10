{
  lib,
  buildNpmPackage,
  fetchurl,
  nodejs_22,
  makeWrapper,
}:
buildNpmPackage {
  pname = "ms-365-mcp-server";
  version = "0.45.1";

  src = fetchurl {
    url = "https://registry.npmjs.org/@softeria/ms-365-mcp-server/-/ms-365-mcp-server-0.45.1.tgz";
    hash = "sha256-sKgjicorX7pRol9YWMt4EdNFZkmiqkd711RUCmOibpw=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-gb1y3YdBWxZ0sP3/8Mhft4P9yx+ps88VrnxkEWcU+o0=";
  nodejs = nodejs_22;
  makeCacheWritable = true;

  # npm tarball ships pre-built dist; no build needed
  dontNpmBuild = true;

  npmFlags = ["--legacy-peer-deps" "--ignore-scripts"];

  nativeBuildInputs = [makeWrapper];

  dontNpmInstall = true;

  installPhase = ''
    mkdir -p $out/bin $out/lib/ms-365-mcp-server
    cp -r dist $out/lib/ms-365-mcp-server/
    cp -r node_modules $out/lib/ms-365-mcp-server/
    chmod +x $out/lib/ms-365-mcp-server/dist/index.js
    makeWrapper ${nodejs_22}/bin/node $out/bin/ms-365-mcp-server \
      --add-flags "$out/lib/ms-365-mcp-server/dist/index.js" \
      --chdir "$out/lib/ms-365-mcp-server"
  '';

  # remove dangling symlinks before noBrokenSymlinks check
  preFixup = ''
    find $out -xtype l -delete
  '';

  meta = {
    description = "Microsoft 365 MCP server — 90+ tools for mail, calendar, Teams, OneDrive, SharePoint, Excel, OneNote";
    homepage = "https://github.com/Softeria/ms-365-mcp-server";
    license = lib.licenses.mit;
    mainProgram = "ms-365-mcp-server";
  };
}
