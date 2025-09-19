{pkgs, ...}:
pkgs.writeShellScriptBin "polkitagent" ''
  ${pkgs.kdePackages.polkit-kde-agent}/libexec/.polkit-kde-authentication-agent-1-wrapped
''
