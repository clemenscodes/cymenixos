{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
  makeWrapper,
}:
buildNpmPackage {
  pname = "mcp-server-docker";
  version = "0.18.0";

  src = fetchFromGitHub {
    owner = "docker";
    repo = "hub-mcp";
    rev = "98cf1b9cbec64316ea2b465462468a2d2204a406";
    hash = "sha256-n4JQKOUOu2OK9RvsOrddTu8bLCUlhDCRW8jkc4a4Ayk=";
  };

  npmDepsHash = "sha256-di/EDkHKQrUySc5wtyK2z/nqwAT1UEymx69bVPf+oaM=";
  nodejs = nodejs_22;
  makeCacheWritable = true;

  # esbuild's postinstall downloads a platform binary; skip all scripts since tsc builds the package
  npmFlags = ["--ignore-scripts"];

  nativeBuildInputs = [makeWrapper];

  # package.json has no bin field; wrap the entry point manually
  dontNpmInstall = true;

  installPhase = ''
    mkdir -p $out/bin $out/lib/dockerhub-mcp-server
    cp -r dist node_modules $out/lib/dockerhub-mcp-server/
    chmod +x $out/lib/dockerhub-mcp-server/dist/index.js
    makeWrapper ${nodejs_22}/bin/node $out/bin/mcp-server-docker \
      --add-flags "$out/lib/dockerhub-mcp-server/dist/index.js" \
      --chdir "$out/lib/dockerhub-mcp-server"
  '';

  meta = {
    description = "Official Docker Hub MCP server — manage images, repositories, and builds";
    homepage = "https://github.com/docker/hub-mcp";
    license = lib.licenses.asl20;
    mainProgram = "mcp-server-docker";
  };
}
