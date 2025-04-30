final: pkgs: {
  grub2 = pkgs.grub2.overrideAttrs (attrs: {
    version = "2.06.r499.ge67a551a4";

    src = pkgs.fetchgit {
      url = "https://git.savannah.gnu.org/git/grub.git";
      rev = "e67a551a48192a04ab705fca832d82f850162b64";
      hash = "sha256-HycIXy8qf56JVQP5KUavfNShyU0hE+/HrdbT/ZBnzzI=";
    };

    patches = [
      (pkgs.fetchpatch {
        name = "fix-bash-completion.patch";
        url = "https://github.com/NixOS/nixpkgs/raw/master/pkgs/tools/misc/grub/fix-bash-completion.patch";
        sha256 = "sha256-XDM3dCAbrOnTRTbOP/4RSaEe+YSF1iTAuuEWQmXw5CQ=";
      })
      (pkgs.fetchpatch {
        name = "Add-hidden-menu-entries.patch";
        url = "https://marc.info/?l=grub-devel&m=146193404929072&q=mbox";
        sha256 = "00wa1q5adiass6i0x7p98vynj9vsz1w0gn1g4dgz89v35mpyw2bi";
      })
      (pkgs.fetchpatch {
        name = "argon_1.patch";
        url = "https://aur.archlinux.org/cgit/aur.git/plain/argon_1.patch?h=grub-improved-luks2-git";
        sha256 = "sha256-WCt+sVr8Ss/bAI41yMJmcZoIPVO1HFEjw1OVRUPYb+w=";
      })
      (pkgs.fetchpatch {
        name = "argon_2.patch";
        url = "https://aur.archlinux.org/cgit/aur.git/plain/argon_2.patch?h=grub-improved-luks2-git";
        sha256 = "sha256-OMQYjTFq0PpO38wAAXRsYUfY8nWoAMcPhKUlbqizIS8=";
      })
      ../patches/argon_3.patch
      (pkgs.fetchpatch {
        name = "argon_4.patch";
        url = "https://aur.archlinux.org/cgit/aur.git/plain/argon_4.patch?h=grub-improved-luks2-git";
        sha256 = "sha256-Hz88P8T5O2ANetnAgfmiJLsucSsdeqZ1FYQQLX0WP3I=";
      })
      (pkgs.fetchpatch {
        name = "argon_5.patch";
        url = "https://aur.archlinux.org/cgit/aur.git/plain/argon_5.patch?h=grub-improved-luks2-git";
        sha256 = "sha256-cs5dKI2Am+Kp0/ZqSWqd2h/7Oj+WEBeKgWPVsCeMgwk=";
      })
      (pkgs.fetchpatch {
        name = "grub-install_luks2.patch";
        url = "https://aur.archlinux.org/cgit/aur.git/plain/grub-install_luks2.patch?h=grub-improved-luks2-git";
        sha256 = "sha256-I+1Yl0DVBDWFY3+EUPbE6FTdWsKH81DLP/2lGPVJtLI=";
      })
    ];

    nativeBuildInputs = (builtins.filter (x: x.name != "autoreconf-hook") attrs.nativeBuildInputs) ++ (with final; [autoconf automake]);

    preConfigure = let
      gnulib = pkgs.fetchgit {
        url = "https://git.savannah.gnu.org/r/gnulib.git";
        rev = "06b2e943be39284783ff81ac6c9503200f41dba3";
        sha256 = "sha256-xhxN8Tw15ENAMSE/cTkigl5yHR3T2d7B1RMFqiMvmxU=";
      };
    in
      builtins.replaceStrings ["patchShebangs ."] [
        ''
          patchShebangs .

          ./bootstrap --no-git --gnulib-srcdir=${gnulib}
        ''
      ]
      attrs.preConfigure;

    configureFlags = let
      argonConfigureFlags = [
        "--disable-nls"
        "--disable-silent-rules"
        "--disable-werror"
      ];
    in
      attrs.configureFlags ++ argonConfigureFlags;
  });
}
