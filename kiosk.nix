{ pkgs ? import (builtins.fetchTarball {
    url = "https://github.com/matthewbauer/nixpkgs/archive/e829d02c7298fcf811b3708253809ae5ce4ba0c4.tar.gz";
    sha256 = "1h8276r37r3rlka311v555j8xyx1nkysnwk9sfn7hlpb4yqk7dk8";
  }) {}
, hostName
, programFunc
, authorizedKeys
, crossSystem }:

(import (pkgs.path + /nixos/lib/eval-config.nix) {
  modules = [
    (pkgs.path + /nixos/modules/profiles/clone-config.nix)
    (pkgs.path + /nixos/modules/installer/cd-dvd/channel.nix)
    (pkgs.path + /nixos/modules/installer/cd-dvd/sd-image.nix)
    ./rpi-sd.nix
    ./cage.nix
    ({lib, pkgs, ...}: {
      boot.plymouth.enable = true;

      sdImage.compressImage = false;

      networking.hostName = hostName;

      hardware.opengl.enable = true;

      services.openssh = {
        enable = true;
        permitRootLogin = "without-password";
      };

      users.users.root = {
        openssh.authorizedKeys.keys = authorizedKeys;
      };

      users.users.kiosk = {
        isNormalUser = true;
        useDefaultShell = true;
      };

      services.cage = {
        enable = true;
        user = "kiosk";
        program = programFunc pkgs;
      };

      # Setup cross compilation.
      nixpkgs = {
        overlays = [(self: super: {
          gtk3 = super.gtk3.override { cupsSupport = false; };
          webkitgtk = super.webkitgtk.override {
            gst-plugins-bad = null;
            enableGeoLocation = false;
            stdenv = super.stdenv;
          };
          epiphany = super.epiphany.override {
            gst_all_1 = super.gst_all_1 // {
              gst-plugins-bad = null;
              gst-plugins-ugly = null;
              gst-plugins-good = null;
            };
          };
          python37 = super.python37.override {
            packageOverrides = self: super: { cython = super.cython.override { gdb = null; }; };
          };
          libass = super.libass.override { encaSupport = false; };
          libproxy = super.libproxy.override { networkmanager = null; };
          enchant2 = super.enchant2.override { hspell = null; };
          cage = super.cage.override { xwayland = null; };
        }) ];
        inherit crossSystem;
      };

      # Disable some stuff that doesn’t cross compile / take a long time.
      boot.supportedFilesystems = lib.mkForce [ "vfat" ];
      programs.command-not-found.enable = false;
      security.pam.services.su.forwardXAuth = lib.mkForce false;
      powerManagement.enable = false;
      documentation.enable = false;
      services.udisks2.enable = false;
      fonts.fontconfig.enable = false;
      security.polkit.enable = false;
    }) ];
}).config.system.build.sdImage
