{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.editor;
in {
  config = lib.mkIf (cfg.enable && cfg.vscode.enable) {
    programs = {
      vscode = {
        profiles = {
          default = {
            extensions = with pkgs.vscode-marketplace; [
              ahmadalli.vscode-nginx-conf
              mskelton.one-dark-theme
              asvetliakov.vscode-neovim
              vscode-icons-team.vscode-icons
              vspacecode.whichkey
              ms-vscode-remote.remote-wsl
              mark-wiemer.vscode-autohotkey-plus-plus
              angular.ng-template
              biomejs.biome
              ambar.bundle-size
              ms-azuretools.vscode-containers
              fill-labs.dependi
              ms-azuretools.vscode-docker
              editorconfig.editorconfig
              dbaeumer.vscode-eslint
              tamasfe.even-better-toml
              exiasr.hadolint
              tim-koehler.helm-intellisense
              firsttris.vscode-jest-runner
              ms-kubernetes-tools.vscode-kubernetes-tools
              bierner.markdown-mermaid
              moonrepo.moon-console
              arrterian.nix-env-selector
              jnoortheen.nix-ide
              mkhl.direnv
              kamadorueda.alejandra
              dioxuslabs.dioxus
              anthropic.claude-code
              ms-playwright.playwright
              esbenp.prettier-vscode
              rust-lang.rust-analyzer
              bradlc.vscode-tailwindcss
              rluvaton.vscode-vitest
              redhat.vscode-yaml
              ms-vscode-remote.remote-containers
              ms-vscode.remote-server
              ms-vscode-remote.remote-ssh-edit
            ];
          };
        };
      };
    };
  };
}
