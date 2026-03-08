{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  nodejs_22,
  pnpm_10,
  pnpmConfigHook,
  makeWrapper,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "mongodb-mcp-server";
  version = "1.8.0";

  src = fetchFromGitHub {
    owner = "mongodb-js";
    repo = "mongodb-mcp-server";
    rev = "111092099ca9c149e217d196018d1286e3a95752";
    hash = "sha256-qmCFp9kVuT6pl46Ph5aCMneet4jJLeJ6GeupOFdjpdI=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 1;
    hash = "sha256-QFjC2nT1fBj41dV3lx1SHdhK7JsF59PaAmnBMqhlwlk=";
  };

  nativeBuildInputs = [pnpm_10 pnpmConfigHook nodejs_22 makeWrapper];

  buildPhase = ''
    pnpm run build:esm
  '';

  installPhase = ''
    mkdir -p $out/bin $out/lib/mongodb-mcp-server
    cp -r dist/esm $out/lib/mongodb-mcp-server/
    chmod +x $out/lib/mongodb-mcp-server/esm/index.js
    makeWrapper ${nodejs_22}/bin/node $out/bin/mongodb-mcp-server \
      --add-flags "$out/lib/mongodb-mcp-server/esm/index.js"
  '';

  meta = {
    description = "Official MongoDB MCP server";
    homepage = "https://github.com/mongodb-js/mongodb-mcp-server";
    license = lib.licenses.asl20;
    mainProgram = "mongodb-mcp-server";
  };
})
