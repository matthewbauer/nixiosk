{ lib, config, pkgs, ... }:

{
  # Create the squashfs image that contains the Nix store.
  system.build.squashfsStore = pkgs.callPackage (pkgs.path + /nixos/lib/make-squashfs.nix) {
    storeContents = [ config.system.build.toplevel ];
  };

  # Create the initrd
  system.build.netbootRamdisk = pkgs.makeInitrd {
    inherit (config.boot.initrd) compressor;
    prepend = [ "${config.system.build.initialRamdisk}/initrd" ];

    contents =
      [ { object = config.system.build.squashfsStore;
          symlink = "/nix-store.squashfs";
        }
      ];
  };

  system.build.netbootIpxeScript = pkgs.writeTextDir "netboot.ipxe" ''
    #!ipxe
    kernel ${pkgs.stdenv.hostPlatform.platform.kernelTarget} init=${config.system.build.toplevel}/init initrd=initrd ${toString config.boot.kernelParams}
    initrd initrd
    boot
  '';

  boot.postBootCommands = ''
    # After booting, register the contents of the Nix store
    # in the Nix database in the tmpfs.
    ${config.nix.package}/bin/nix-store --load-db < /nix/store/nix-path-registration

    # nixos-rebuild also requires a "system" profile and an
    # /etc/NIXOS tag.
    touch /etc/NIXOS
    ${config.nix.package}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
  '';

}
