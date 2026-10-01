{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  asar,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  libcap_ng,
  libdrm,
  libgbm,
  libseccomp,
  libxkbcommon,
  nspr,
  nss,
  pango,
  systemd,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxtst,
  libxcb,
  libGL,
  libnotify,
  libpulseaudio,
  libsecret,
  pipewire,
  xdg-utils,
}: let
  pname = "claude-desktop";
  # Official Anthropic apt repository for the native Linux build. New version:
  #   curl -s https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages
  # take the last stanza and convert its SHA256 with
  #   nix hash convert --hash-algo sha256 --to sri <hex>
  version = "2.9939.4";
  aptRepo = "https://downloads.claude.ai/claude-desktop/apt/stable";
  srcs = {
    x86_64-linux = fetchurl {
      url = "${aptRepo}/pool/main/c/claude-desktop/claude-desktop_${version}_amd64.deb";
      hash = "sha256-PP3bI78pEeBeJ7TtOFa455XflGQ7LDW1nesxfPmVvKA=";
    };
    aarch64-linux = fetchurl {
      url = "${aptRepo}/pool/main/c/claude-desktop/claude-desktop_${version}_arm64.deb";
      hash = "sha256-EI7XnqFksIxPoLtDh97vR3mVez8Pmy2YmONZ82Pr8bw=";
    };
  };
in
  stdenv.mkDerivation {
    inherit pname version;

    src =
      srcs.${stdenv.hostPlatform.system}
      or (throw "claude-desktop: unsupported system ${stdenv.hostPlatform.system}");

    nativeBuildInputs = [
      dpkg
      asar
      autoPatchelfHook
      makeWrapper
    ];

    buildInputs = [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      dbus
      expat
      gdk-pixbuf
      glib
      gtk3
      libcap_ng
      libdrm
      libgbm
      libseccomp
      libxkbcommon
      nspr
      nss
      pango
      (lib.getLib stdenv.cc.cc)
      (lib.getLib systemd)
      libx11
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxtst
      libxcb
    ];

    # dlopen'd by Chromium/Electron, so not visible in DT_NEEDED.
    appendRunpaths = map (p: "${lib.getLib p}/lib") [
      libGL
      libnotify
      libpulseaudio
      libsecret
      pipewire
      systemd
    ];

    unpackPhase = ''
      runHook preUnpack
      # dpkg-deb -x would keep the SUID bit on chrome-sandbox, which the
      # sandboxed builder refuses.
      mkdir unpacked
      dpkg-deb --fsys-tarfile $src \
        | tar -x -C unpacked --no-same-owner --no-same-permissions
      runHook postUnpack
    '';
    sourceRoot = "unpacked";

    dontConfigure = true;
    dontStrip = true;

    # Two env vars the app already implements but the release build disables:
    #
    # CLAUDE_CODE_LOCAL_BINARY: resolveHostBinary prefers a local Claude Code
    # override, but the constructor call reading the variable was minified to
    # a bare expression. Restored, so the Code tab runs the system claude
    # instead of downloading its own into <userData>/claude-code/<version>/.
    #
    # CLAUDE_USER_DATA_DIR: sets userData (profile, login, single-instance
    # lock), but packaged builds delete it at startup. Kept, so every account
    # gets its own profile and the instances run side by side.
    buildPhase = ''
      runHook preBuild
      resources=usr/lib/${pname}/resources
      asar extract $resources/app.asar app
      needle='process.env.CLAUDE_CODE_LOCAL_BINARY}async initLocalBinary('
      target=$(grep -lF "$needle" app/.vite/build/*.js)
      substituteInPlace "$target" --replace-fail "$needle" \
        'process.env.CLAUDE_CODE_LOCAL_BINARY&&(this.localBinaryInitPromise=this.initLocalBinary(process.env.CLAUDE_CODE_LOCAL_BINARY))}async initLocalBinary('
      substituteInPlace app/.vite/build/index.pre.js \
        --replace-fail 'delete process.env.CLAUDE_USER_DATA_DIR,' ""
      rm -rf $resources/app.asar $resources/app.asar.unpacked
      asar pack app $resources/app.asar --unpack '{*.node,github-mcp-server}'
      # asar drops the executable bit on unpacked files.
      chmod +x $resources/app.asar.unpacked/resources/github-mcp/github-mcp-server
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r usr/lib usr/share $out/
      rm -rf $out/share/lintian

      # The store cannot carry SUID bits, and NixOS has unprivileged user
      # namespaces, so Chromium uses the userns sandbox instead.
      rm $out/lib/${pname}/chrome-sandbox

      desktopFile=$out/share/applications/com.anthropic.Claude.desktop
      substituteInPlace $desktopFile \
        --replace-fail "Exec=claude-desktop" "Exec=$out/bin/claude-desktop"

      mkdir -p $out/bin
      makeWrapper $out/lib/${pname}/${pname} $out/bin/${pname} \
        --add-flags "--ozone-platform-hint=auto" \
        --add-flags "--enable-features=WaylandWindowDecorations" \
        --add-flags "--enable-wayland-ime" \
        --add-flags "--wayland-text-input-version=3" \
        --set-default GTK_USE_PORTAL 1 \
        --set-default CHROME_DESKTOP com.anthropic.Claude.desktop \
        --prefix PATH : ${lib.makeBinPath [xdg-utils]} \
        --prefix XDG_DATA_DIRS : "$out/share"

      runHook postInstall
    '';

    meta = {
      description = "Claude Desktop (official Linux build) with local Claude Code and userData overrides enabled";
      homepage = "https://claude.ai/download";
      license = lib.licenses.unfree;
      platforms = ["x86_64-linux" "aarch64-linux"];
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      mainProgram = pname;
    };
  }
