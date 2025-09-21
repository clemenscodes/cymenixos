{pkgs, ...}:
pkgs.writeShellScriptBin "polkitagent" ''
  ${pkgs.kdePackages.polkit-kde-agent-1}/libexec/.polkit-kde-authentication-agent-1-wrapped
''
