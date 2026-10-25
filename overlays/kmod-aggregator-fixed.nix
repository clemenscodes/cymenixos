# Vendored from nixpkgs pkgs/os-specific/linux/kmod/aggregator.nix (rev 3ec636),
# with a single change, marked below.
#
# nixpkgs' new kmodigest feature (single-module certificates, see the modules.cer
# step in the kernel build.nix) added a postBuild here that appends EXTERNAL
# modules' .ko.cer to modules.cer. It treats the lines of modules.dep after the
# first `wc -l modules.order` lines as external modules. But depmod orders
# modules.dep by dependency, not like modules.order, so in-tree modules (bluetooth,
# mt76, ...) also land in that tail. Their individual .cer were already concatenated
# into modules.cer and removed by the base kernel step, so `xargs cat` dies with
# "No such file or directory" and the whole modules derivation fails with exit 123,
# but only once the kernel has extraModulePackages. This kernel has them
# (kvm-vanix from vanix, v4l2loopback from modules/boot), so it broke on the bump
# that introduced the feature.
#
# The only change vs upstream: skip .ko.cer files that do not exist instead of
# cat-ing them unconditionally. External modules that really carry a cert are still
# merged; in-tree modules wrongly left in the tail are simply skipped. Drop this
# overlay once nixpkgs fixes aggregator.nix.
{
  stdenvNoCC,
  kmod,
  modules,
  buildEnv,
  name ? "kernel-modules",
}:

buildEnv {
  inherit name;

  paths = modules;

  pathsToLink = [
    "/lib/modules"
    "/etc/depmod.d"
  ];

  postBuild = ''
    source ${stdenvNoCC}/setup

    if ! test -d "$out/lib/modules"; then
      echo "No modules found."
      # To support a kernel without modules
      exit 0
    fi

    kernelVersion=$(cd $out/lib/modules && ls -d *)
    if test "$(echo $kernelVersion | wc -w)" != 1; then
       echo "inconsistent kernel versions: $kernelVersion"
       exit 1
    fi

    echo "kernel version is $kernelVersion"

    shopt -s extglob

    # Regenerate the depmod map files.  Be sure to pass an explicit
    # kernel version number, otherwise depmod will use `uname -r'.
    if test -w $out/lib/modules/$kernelVersion; then
        rm -f $out/lib/modules/$kernelVersion/modules.!(builtin*|order*|cer)
        ${kmod}/bin/depmod -b $out -C $out/etc/depmod.d -a $kernelVersion
        cd -- "$out/lib/modules/$kernelVersion"

        # Merge the single-module certificates for external modules.
        cp --no-preserve=mode,ownership --remove-destination \
          -- "$(readlink -f modules.cer)" modules.cer
        # CHANGE vs upstream: tolerate missing .ko.cer (see file header).
        sed "1,$(wc -l < modules.order)d; s/\.ko.*/.ko.cer/" modules.dep \
            | { while IFS= read -r cerf; do if [ -e "$cerf" ]; then cat "$cerf"; fi; done; } >> modules.cer
    fi
  '';
}
