{pkgs, ...}: let
  initLua = pkgs.writeText "smart-enter-lua" ''
    --- @sync entry
    return {
    	entry = function()
    		local h = cx.active.current.hovered
    		ya.manager_emit(h and h.cha.is_dir and "enter" or "open", { hovered = true })
    	end,
    }
  '';
in
  pkgs.stdenv.mkDerivation {
    name = "smart-enter";
    phases = "installPhase";
    installPhase = ''
      mkdir -p $out
      ln -sf ${initLua} $out/init.lua
    '';
  }
