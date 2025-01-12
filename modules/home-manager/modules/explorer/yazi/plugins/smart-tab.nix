{pkgs, ...}: let
  initLua = pkgs.writeText "smart-tab-init-lua" ''
    --- @sync entry
    return {
    	entry = function()
    		local h = cx.active.current.hovered
    		ya.manager_emit("tab_create", h and h.cha.is_dir and { h.url } or { current = true })
    	end,
    }
  '';
in
  pkgs.stdenv.mkDerivation {
    name = "smart-tab";
    phases = "installPhase";
    installPhase = ''
      mkdir -p $out
      ln -sf ${initLua} $out/init.lua
    '';
  }
