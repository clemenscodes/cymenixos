{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: {
  # required to listen for keyboard shortcuts
  users.users.${config.modules.users.user}.extraGroups = ["input"];

  # have it auto start as a systemd unit with
  services.hyprwhspr-rs.enable = true;
  # or just add it to your systemPackages
  environment.systemPackages = [pkgs.hyprwhspr-rs];

  # optional: to enable cuda (for AMD do `rocmSupport` instead of `cudaSupport`)
  # cuda is unfree so not in the default nixos build caches
  # I highly recommend adding the cuda build cache to your nixconfig https://discourse.nixos.org/t/cuda-cache-for-nix-community/56038
  services.hyprwhspr-rs = {
    enable = true;
    package = pkgs.hyprwhspr-rs.override {
      # to optimize build time you can skip enabling cudaSupport for one of these two
      # for whisper do whisper-cpp, for NVIDIA Parakeet do onnxruntime
      whispercpp = pkgs.whisper-cpp.override {cudaSupport = true;};
      onnxruntime = pkgs.onnxruntime.override {cudaSupport = true;};
    };
  };
  # you can also enable cuda/rocm globally, but this will increase the build time for your entire system if you dont add the cuda build cache
  nixpkgs.config.cudaSupport = true;

  # if you use groq or gemini for transcription, you can autoload their keys with
  services.hyprwhspr-rs = {
    enable = true;
    # put `GROQ_API_KEY=...` or `GEMINI_API_KEY=...` in the file you put at this path
    environmentFile = "/path/to/hyprwhspr_secret_file";
  };
}
