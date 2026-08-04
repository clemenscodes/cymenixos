# nixpkgs hat glaze auf 8.0.0 gehoben, hyprland 0.56.1 sucht in seiner
# CMakeLists aber nach "find_package(glaze 7...<8 QUIET)". Die Systembibliothek
# fällt damit aus dem Versionsfenster, CMake schaltet auf den FetchContent
# Fallback um und der Build stirbt in der Sandbox mit "could not find git for
# clone of glaze", weil dort weder git noch Netz zur Verfügung stehen.
#
# Hier bekommt ausschließlich hyprland ein glaze 7.2.0, also genau die Version,
# die der Fallback selbst geholt hätte. Alle anderen Konsumenten von glaze
# behalten 8.0.0. Sobald hyprland in nixpkgs glaze 8 akzeptiert, kann dieses
# Overlay ersatzlos verschwinden.
final: prev: {
  hyprland = prev.hyprland.override {
    glaze = prev.glaze.overrideAttrs (_old: rec {
      version = "7.2.0";
      src = final.fetchFromGitHub {
        owner = "stephenberry";
        repo = "glaze";
        tag = "v${version}";
        hash = "sha256-f3NVRi3SXKo42hn0WCw7JsOK3EkdOVJIcuzhPorKjFY=";
      };
    });
  };
}
