final: pkgs: let
  owner = "clemenscodes";
  repo = "VSCode-PowerPC-Syntax";
  rev = "d46f43e9873cdd8ab3e6f9c57f4ffd7ed2543552";
  hash = "sha256-ypTx/tINh6JpM23HvBdkoIyTpJRfFDWWaP7UebAFBqk=";
  version = "1.1.9";
  publisher = "ogoodness";
  name = "powerpc-syntax";
  identifier = "${publisher}.${name}";
  src = pkgs.fetchFromGitHub {inherit owner repo rev hash;};
  nodejs = pkgs.nodejs_22;
  modulesOf = directory: depsHash:
    pkgs.buildNpmPackage {
      inherit nodejs version;
      pname = "${name}-${directory}-modules";
      src = "${src}/${directory}";
      npmDepsHash = depsHash;
      dontNpmBuild = true;
      npmFlags = ["--ignore-scripts" "--legacy-peer-deps"];
      installPhase = ''
        runHook preInstall
        mkdir --parents $out
        cp --recursive node_modules $out/node_modules
        runHook postInstall
      '';
    };
  rootModules = pkgs.buildNpmPackage {
    inherit nodejs version src;
    pname = "${name}-modules";
    npmDepsHash = "sha256-Ma2z4roqhUhenxJBdWnOfa7ziOfvpRGJ3TWyUr0ywi8=";
    dontNpmBuild = true;
    npmFlags = ["--ignore-scripts" "--legacy-peer-deps"];
    installPhase = ''
      runHook preInstall
      mkdir --parents $out
      cp --recursive node_modules $out/node_modules
      runHook postInstall
    '';
  };
  clientModules = modulesOf "client" "sha256-ueEMJZ31dQ2tz7puHIMA+1GtFHD5fvTPf6ezxeOzAlY=";
  serverModules = modulesOf "server" "sha256-2eFjnlV3rfLQR12cNi/SdkaFkulVqQCjBTCcCtJov40=";
in {
  vscode-powerpc-syntax = pkgs.stdenvNoCC.mkDerivation {
    pname = "vscode-extension-${name}";
    inherit version src;

    nativeBuildInputs = [nodejs];

    buildPhase = ''
      runHook preBuild
      cp --recursive --no-preserve=mode ${rootModules}/node_modules node_modules
      cp --recursive --no-preserve=mode ${clientModules}/node_modules client/node_modules
      cp --recursive --no-preserve=mode ${serverModules}/node_modules server/node_modules
      node node_modules/typescript/bin/tsc -b
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      extension="$out/share/vscode/extensions/${identifier}"
      mkdir --parents "$extension/client" "$extension/server"
      cp package.json language-configuration.json "$extension/"
      cp --recursive syntax snippets images "$extension/"
      cp --recursive client/out client/node_modules "$extension/client/"
      cp --recursive server/out server/node_modules "$extension/server/"
      runHook postInstall
    '';

    passthru = {
      vscodeExtPublisher = publisher;
      vscodeExtName = name;
      vscodeExtUniqueId = identifier;
    };

    meta = {
      description = "PowerPC assembly for Visual Studio Code, with the instructions and registers of the Cell";
      homepage = "https://github.com/${owner}/${repo}";
      license = pkgs.lib.licenses.mit;
      platforms = pkgs.lib.platforms.all;
    };
  };
}
