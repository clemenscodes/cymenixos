{
  lib,
  buildNpmPackage,
  fetchurl,
  nodejs_22,
  makeWrapper,
}:
buildNpmPackage {
  pname = "mcp-server-postgres";
  version = "0.6.2";

  # Use the pre-built npm tarball (dist/index.js included)
  src = fetchurl {
    url = "https://registry.npmjs.org/@modelcontextprotocol/server-postgres/-/server-postgres-0.6.2.tgz";
    hash = "sha256-r1UgCgGxOuMZSftKiGTuYEO4kdAP+DMw0XebGKpbom8=";
  };

  postPatch = ''
    cp ${./postgres-package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-e2jHhGuSHBf3bQeHmlIfYbOsEV/mrPwEWPwodOUXe48=";
  nodejs = nodejs_22;
  dontNpmBuild = true;

  nativeBuildInputs = [makeWrapper];

  installPhase = ''
    mkdir -p $out/bin $out/lib/mcp-server-postgres
    cp dist/index.js $out/lib/mcp-server-postgres/
    cp -r node_modules $out/lib/mcp-server-postgres/
    chmod +x $out/lib/mcp-server-postgres/index.js
    makeWrapper ${nodejs_22}/bin/node $out/bin/mcp-server-postgres \
      --add-flags "$out/lib/mcp-server-postgres/index.js" \
      --chdir "$out/lib/mcp-server-postgres"
  '';

  meta = {
    description = "MCP server for PostgreSQL databases";
    homepage = "https://github.com/modelcontextprotocol/servers/tree/main/src/postgres";
    license = lib.licenses.mit;
    mainProgram = "mcp-server-postgres";
  };
}
