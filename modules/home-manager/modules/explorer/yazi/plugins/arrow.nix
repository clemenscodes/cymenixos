{pkgs, ...}: let
  initLua = pkgs.writeText "arrow-init-lua" ''
    --- @sync entry
    return {
    	entry = function(_, job)
    		local current = cx.active.current
    		local new = (current.cursor + job.args[1]) % #current.files
    		ya.manager_emit("arrow", { new - current.cursor })
    	end,
    }
  '';
in
  pkgs.stdenv.mkDerivation {
    name = "arrow";
    phases = "installPhase";
    installPhase = ''
      mkdir -p $out
      ln -sf ${initLua} $out/init.lua
    '';
  }
