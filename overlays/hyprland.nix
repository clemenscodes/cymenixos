# nixpkgs hat glaze inzwischen auf 9.0.0 gehoben, hyprland 0.56.2 sucht in seiner
# CMakeLists aber nach "find_package(glaze 7...<8 QUIET)". Die Systembibliothek
# fällt damit aus dem Versionsfenster, CMake schaltet auf den FetchContent
# Fallback um und der Build stirbt in der Sandbox mit "could not find git for
# clone of glaze", weil dort weder git noch Netz zur Verfügung stehen.
#
# Hier bekommt ausschließlich hyprland ein glaze 7.2.0, also genau die Version,
# die der Fallback selbst geholt hätte. Alle anderen Konsumenten von glaze
# behalten 9.0.0. Sobald hyprland in nixpkgs glaze 8+ akzeptiert, kann dieses
# Overlay ersatzlos verschwinden.
#
# patches muss mit zurueckgesetzt werden: nixpkgs' glaze 9.0.0 traegt einen
# Patch (PR 2977, benennt eine emit-Lambda in put um), der gegen den 9.0.0 Baum
# gemacht ist. Beim Downgrade der src auf 7.2.0 wuerde overrideAttrs diesen
# Patch erben, und er passt auf keinen Hunk der 7.2.0 Quelle -> patchPhase
# bricht ab. 7.2.0 braucht ihn nicht (der FetchContent Fallback zieht dieselbe
# Version ungepatcht).
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
      patches = [ ];
    });
  };
}
