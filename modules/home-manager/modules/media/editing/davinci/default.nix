{
  inputs,
  lib,
  ...
}: {
  system,
  config,
  ...
}: let
  cfg = config.modules.media.editing;

  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "davinci-resolve"
          "davinci-resolve-studio"
        ];
    };
  };

  version = "20.3.1";

  davinciStudioSrc =
    pkgs.runCommand "davinci-resolve-studio-src.zip"
    {
      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash = "sha256-JaP0O+bSc9wd2YTqRwRQo35kdDkq//5WMb+7MtC9S/A=";

      nativeBuildInputs = [pkgs.curl pkgs.jq];
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    }
    ''
      set -euo pipefail

      REFERID="263d62f31cbb49e0868005059abcb0c9"
      DOWNLOADSURL="https://www.blackmagicdesign.com/api/support/us/downloads.json"
      SITEURL="https://www.blackmagicdesign.com/api/register/us/download"
      PRODUCT="DaVinci Resolve Studio"
      VERSION="${version}"

      USERAGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.75 Safari/537.36"

      REQJSON='{
        "firstname": "NixOS",
        "lastname": "Linux",
        "email": "someone@nixos.org",
        "phone": "+31 71 452 5670",
        "country": "nl",
        "street": "-",
        "state": "Province of Utrecht",
        "city": "Utrecht",
        "product": "DaVinci Resolve Studio"
      }'

      echo "Fetching download ID..."

      DOWNLOADID=$(
        curl -s --compressed "$DOWNLOADSURL" \
          | jq -r \
            ".downloads[]
             | .urls.Linux?[]?
             | select(.downloadTitle | test(\"^$PRODUCT $VERSION( Update)?$\"))
             | .downloadId"
      )

      echo "downloadid is $DOWNLOADID"

      RESOLVEURL=$(
        curl -s \
          -H "User-Agent: $USERAGENT" \
          -H "Content-Type: application/json;charset=UTF-8" \
          -H "Referer: https://www.blackmagicdesign.com/support/download/$REFERID/Linux" \
          --data "$REQJSON" \
          --compressed \
          "$SITEURL/$DOWNLOADID"
      )

      echo "resolveurl is $RESOLVEURL"

      FILESIZE=$(curl -sI "$RESOLVEURL" | awk '/content-length:/ {print $2}' | tr -d '\r')
      echo "Total size: $FILESIZE bytes"

      CHUNK=$((100 * 1024 * 1024))
      START=0

      TMPFILE=$(mktemp)
      > "$TMPFILE"

      while [ "$START" -lt "$FILESIZE" ]; do
        END=$((START + CHUNK - 1))
        if [ "$END" -ge "$FILESIZE" ]; then
          END=$((FILESIZE - 1))
        fi

        echo "Downloading bytes $START-$END"

        curl \
          -4 \
          --http1.1 \
          --fail \
          --location \
          --range "$START-$END" \
          "$RESOLVEURL" >> "$TMPFILE"

        START=$((END + 1))
      done

      mv "$TMPFILE" "$out"

      echo "Download complete."
    '';
in {
  options = {
    modules.media.editing.davinci = {
      enable = lib.mkEnableOption "Enable DaVinci Resolve" // {default = false;};
      studio = lib.mkEnableOption "Enable DaVinci Resolve Studio" // {default = false;};
    };
  };

  config = lib.mkIf (cfg.enable && cfg.davinci.enable) {
    home.packages = [
      (
        if cfg.davinci.studio
        then
          pkgs.davinci-resolve-studio.overrideAttrs (old: {
            passthru =
              old.passthru
              // {
                davinci = old.passthru.davinci.overrideAttrs (_: {
                  src = davinciStudioSrc;
                });
              };
          })
        else pkgs.davinci-resolve
      )
    ];
  };
}
