{
  lib,
  stdenv,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
  makeWrapper,
  bash,
  gnused,
  coreutils,
}:
let
  server = buildNpmPackage rec {
    pname = "azure-devops-mcp-server";
    version = "2.4.0";

    src = fetchFromGitHub {
      owner = "microsoft";
      repo = "azure-devops-mcp";
      tag = "v${version}";
      hash = "sha256-I5EOPTxWJcfPV8I1Lwvyj3ljo8Y9W7GojtTWCAreU/g=";
    };

    npmDepsHash = "sha256-zr6k0ZaE/TZpgSW/FB2zX61t09h8t0xyJyxuaURrCkI=";

    nodejs = nodejs_22;

    meta.license = lib.licenses.mit;
  };
in
  stdenv.mkDerivation {
    pname = "azure-devops-mcp";
    version = server.version;
    dontUnpack = true;
    nativeBuildInputs = [makeWrapper];
    installPhase = ''
      mkdir -p $out/bin
      cat > $out/bin/mcp-server-azuredevops << 'WRAPPER'
      #!${bash}/bin/bash
      set -euo pipefail
      config="$HOME/.azure/azuredevops/config"
      if [[ ! -f "$config" ]]; then
        echo "Error: Azure DevOps CLI config not found at $config" >&2
        exit 1
      fi
      org_url=$(${gnused}/bin/sed -n '/^\[defaults\]/,/^\[/{ s/^[[:space:]]*organization[[:space:]]*=[[:space:]]*//p }' "$config" | ${coreutils}/bin/head -1 | ${gnused}/bin/sed 's|[[:space:]]*$||')
      org=$(echo "$org_url" | ${gnused}/bin/sed 's|.*/||; s|/$||')
      if [[ -z "$org" ]]; then
        echo "Error: Could not read organization from $config" >&2
        exit 1
      fi
      exec ${server}/bin/mcp-server-azuredevops "$org" "$@"
      WRAPPER
      chmod +x $out/bin/mcp-server-azuredevops
    '';
    meta = {
      changelog = "https://github.com/microsoft/azure-devops-mcp/releases/tag/v${server.version}";
      description = "MCP server for Azure DevOps";
      homepage = "https://github.com/microsoft/azure-devops-mcp";
      license = lib.licenses.mit;
      mainProgram = "mcp-server-azuredevops";
      maintainers = [];
    };
  }
