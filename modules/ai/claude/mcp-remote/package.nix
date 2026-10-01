{
  lib,
  buildNpmPackage,
  fetchurl,
  nodejs_22,
  jq,
  makeWrapper,
}:
buildNpmPackage {
  pname = "mcp-remote";
  version = "0.14.3";

  # The registry tarball ships the tsup bundle in dist/, so only the four
  # runtime dependencies are needed.
  src = fetchurl {
    url = "https://registry.npmjs.org/mcp-remote/-/mcp-remote-0.14.3.tgz";
    hash = "sha256-9KsOM7OLJP/2qLMjT51oPkeZXKRPMYZIFxbURINvclQ=";
  };

  # package-lock.json was generated from package.json without devDependencies
  postPatch = ''
    ${jq}/bin/jq 'del(.devDependencies, .scripts)' package.json > package.json.new
    mv package.json.new package.json
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-ARvvoP4Pu7xk50CfCJlREHbO53ggM9tBkIHgVihl8xc=";
  nodejs = nodejs_22;
  dontNpmBuild = true;

  nativeBuildInputs = [makeWrapper];

  installPhase = ''
    mkdir -p $out/bin $out/lib/mcp-remote
    cp -r dist package.json node_modules $out/lib/mcp-remote/
    makeWrapper ${nodejs_22}/bin/node $out/bin/mcp-remote \
      --add-flags "$out/lib/mcp-remote/dist/proxy.js"
  '';

  meta = {
    description = "stdio bridge to remote MCP servers with OAuth";
    homepage = "https://github.com/geelen/mcp-remote";
    license = lib.licenses.mit;
    mainProgram = "mcp-remote";
  };
}
