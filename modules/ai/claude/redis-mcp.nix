{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
  makeWrapper,
}:
buildNpmPackage {
  pname = "mcp-server-redis";
  version = "0.0.4";

  src = fetchFromGitHub {
    owner = "farhankaz";
    repo = "redis-mcp";
    rev = "741164a1cbd4c6a4c487933be2629212b046e6bb";
    hash = "sha256-BKchv31/6ubnXO6dV3hBkS1OAiGNbt49bgsd4oIonzU=";
  };

  npmDepsHash = "sha256-+74TOErtz+moqZi+5yrMj7c0eUkPdJT5QPDwfE4qkMI=";
  nodejs = nodejs_22;

  nativeBuildInputs = [makeWrapper];

  # The package has a build script that compiles TypeScript
  postBuild = ''
    chmod +x dist/redis_server.js
  '';

  installPhase = ''
    mkdir -p $out/bin $out/lib/mcp-server-redis
    cp dist/redis_server.js $out/lib/mcp-server-redis/
    cp -r node_modules $out/lib/mcp-server-redis/
    makeWrapper ${nodejs_22}/bin/node $out/bin/mcp-server-redis \
      --add-flags "$out/lib/mcp-server-redis/redis_server.js" \
      --chdir "$out/lib/mcp-server-redis"
  '';

  meta = {
    description = "MCP server for Redis key-value store operations";
    homepage = "https://github.com/farhankaz/redis-mcp";
    license = lib.licenses.isc;
    mainProgram = "mcp-server-redis";
  };
}
