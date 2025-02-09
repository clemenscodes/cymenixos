{pkgs, ...}: let
  initLua = pkgs.writeText "smart-paste-init-lua" ''
    --- @sync entry
    return {
    	entry = function()
    		local h = cx.active.current.hovered
    		if h and h.cha.is_dir then
    			ya.manager_emit("enter", {})
    			ya.manager_emit("paste", {})
    			ya.manager_emit("leave", {})
    		else
    			ya.manager_emit("paste", {})
    		end
    	end,
    }
  '';
in
  pkgs.stdenv.mkDerivation {
    name = "smart-paste";
    phases = "installPhase";
    installPhase = ''
      mkdir -p $out
      ln -sf ${initLua} $out/main.lua
    '';
  }
