{ pkgs ? import (builtins.fetchTarball {
    url = "https://github.com/matthewbauer/nixpkgs/archive/f1becbaafef23a4aa538d0bc0249fd9b2b867c67.tar.gz";
    sha256 = "16yvharvm5gpzpz7dnlw158rnjc489m9h9cb878g9g3fd6zqzj29";
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
      networking.hostName = hostName;

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
          webkitgtk = super.webkitgtk.override { gst-plugins-bad = null; enableGeoLocation = false; stdenv = super.stdenv; };
          python27 = super.python27.override {
            packageOverrides = self: super: { cython = super.cython.override { gdb = null; }; };
          };
          python37 = super.python37.override {
            packageOverrides = self: super: { cython = super.cython.override { gdb = null; }; };
          };
          libass = super.libass.override { encaSupport = false; };
          midori-unwrapped = super.midori-unwrapped.override { libpeas = null; };
          libproxy = super.libproxy.override { networkmanager = null; };
          enchant2 = super.enchant2.override { hspell = null; };
          cage = super.cage.override { xwayland = null; };
        }) ];
        config = { allowUnfree = true; };
        inherit crossSystem;
      };

      # Disable some stuff that doesn’t cross compile / take a long time.
      boot.supportedFilesystems = lib.mkForce [ "vfat" ];
      programs.command-not-found.enable = false;
      programs.ssh.setXAuthLocation = false;
      security.pam.services.su.forwardXAuth = lib.mkForce false;
      powerManagement.enable = false;
      documentation.enable = false;
      services.nixosManual.showManual = false;
      services.udisks2.enable = false;
      fonts.fontconfig.enable = false;
      security.polkit.enable = false;
    }) ];
}).config.system.build.sdImage
