# OBS Studio 32.2.1 marks obs_properties_add_button OBS_DEPRECATED, superseded by
# obs_properties_add_button2 which takes a private data pointer. Four exeldro plugins
# still call the old one, and their CMake builds with -Werror, so gcc promotes the
# deprecation warning to an error and each of them dies with "cc1: all warnings being
# treated as errors". That takes obs-studio-plugins and wrapped-obs-studio down with it,
# so OBS does not build at all.
#
# -Wno-error=deprecated-declarations demotes it back to a warning. The symbol is
# deprecated and not removed, so the call still resolves and behaves exactly as before,
# no code changes. NIX_CFLAGS_COMPILE is appended by the cc wrapper after the flags
# CMake passes, so it wins over the -Werror the plugins set themselves.
#
# nixpkgs knows. PR 556032 and issue 556310 are open and Hydra is red on it, but the
# plugins are not channel blocking, so obs-studio 32.1.2 to 32.2.1 went into the channel
# with them broken. The open PR only fixes obs-move-transition, so waiting on it would
# still leave the other three dead. Drop this once they move to
# obs_properties_add_button2 upstream, or once nixpkgs carries the flag.
#
# This belongs here and not in a consumer's nixpkgs.overlays. The home-manager obs
# module closes over the pkgs this overlay list builds, passed in as a plain function
# argument by modules/home-manager/default.nix, so useGlobalPkgs and a consumer side
# nixpkgs.overlays never reach it. Same reason obs-vkcapture.nix sits here.
#
# Same -Werror problem, different warning and different plugins: gcc 16 promotes
# assigning a const-qualified pointer (e.g. the result of strrchr on a const char*)
# to a plain char* to an error under -Werror=discarded-qualifiers. The four
# FiniteSingularity plugins below (obs-noise, obs-advanced-masks,
# obs-stroke-glow-shadow, obs-retro-effects) share an obs-utils.c that does exactly
# this, so each dies the same way and takes wrapped-obs-studio down with it.
# -Wno-error=discarded-qualifiers demotes it back to a warning; no code changes.
# Drop once they fix it upstream or nixpkgs carries the flag.
final: prev: {
  obs-studio-plugins =
    prev.obs-studio-plugins
    // prev.lib.genAttrs [
      "obs-move-transition"
      "obs-replay-source"
      "obs-shaderfilter"
      "obs-source-switcher"
    ] (
      name:
        prev.obs-studio-plugins.${name}.overrideAttrs (old: {
          env =
            (old.env or {})
            // {
              NIX_CFLAGS_COMPILE = (old.env.NIX_CFLAGS_COMPILE or "") + " -Wno-error=deprecated-declarations";
            };
        })
    )
    // prev.lib.genAttrs [
      "obs-noise"
      "obs-advanced-masks"
      "obs-stroke-glow-shadow"
      "obs-retro-effects"
    ] (
      name:
        prev.obs-studio-plugins.${name}.overrideAttrs (old: {
          env =
            (old.env or {})
            // {
              NIX_CFLAGS_COMPILE = (old.env.NIX_CFLAGS_COMPILE or "") + " -Wno-error=discarded-qualifiers";
            };
        })
    );
}
