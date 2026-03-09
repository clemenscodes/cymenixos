{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
  makeWrapper,
}:
buildNpmPackage {
  pname = "context7-mcp";
  version = "1.0.30";

  src = fetchFromGitHub {
    owner = "upstash";
    repo = "context7";
    rev = "f35c002beeada90ed6fdddf19c0345f9f41cccdb";
    hash = "sha256-cNm/NROFHy+3cOozzvC1WUhGb7bwccvOIiMt30lAN3E=";
  };

  # context7 uses bun.lock; inject a generated npm package-lock.json
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-WKm1M8oeB/YfC1gXpzhNMsRCMwuXXJ+d9KEpDdeB9PA=";
  nodejs = nodejs_22;

  nativeBuildInputs = [makeWrapper];

  buildPhase = ''
    npm run build
    chmod +x dist/index.js
  '';

  installPhase = ''
    mkdir -p $out/bin $out/lib/context7-mcp
    cp -r dist/. $out/lib/context7-mcp/
    cp -r node_modules $out/lib/context7-mcp/
    chmod +x $out/lib/context7-mcp/index.js
    makeWrapper ${nodejs_22}/bin/node $out/bin/context7-mcp \
      --add-flags "$out/lib/context7-mcp/index.js" \
      --chdir "$out/lib/context7-mcp"
  '';

  meta = {
    description = "MCP server providing up-to-date library and framework documentation";
    homepage = "https://github.com/upstash/context7";
    license = lib.licenses.mit;
    mainProgram = "context7-mcp";
  };
}
