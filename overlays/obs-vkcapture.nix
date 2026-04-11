{inputs, ...}:
final: prev: {
  obs-studio-plugins = prev.obs-studio-plugins // {
    obs-vkcapture = prev.obs-studio-plugins.obs-vkcapture.overrideAttrs (_old: {
      src = inputs.obs-vkcapture;
    });
  };
}
