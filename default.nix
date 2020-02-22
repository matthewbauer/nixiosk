{ pkgs ? import <nixpkgs> {} }:

(import (pkgs.path + /nixos/lib/eval-config.nix) {
  modules = [
    (pkgs.path + /nixos/modules/profiles/clone-config.nix)
    (pkgs.path + /nixos/modules/installer/cd-dvd/channel.nix)
    (pkgs.path + /nixos/modules/installer/cd-dvd/sd-image.nix)
    ./rpi-sd.nix
    ./configuration.nix
    ({lib, ...}: {
      # Setup cross compilation.
      nixpkgs = {
        overlays = [(self: super: {
          libnl = super.libnl.override { pythonSupport = false; };
          gobject-introspection = super.gobject-introspection.override {
            x11Support = false;
          };
          dbus = super.dbus.override { x11Support = false; };
          texinfoInteractive = super.texinfo;
          btrfs-progs = null;
          webkitgtk = super.webkitgtk.override { gst-plugins-bad = null; };
          python27 = super.python27.override {
            packageOverrides = self: super: { cython = super.cython.override { gdb = null; }; };
          };
          python37 = super.python37.override {
            packageOverrides = self: super: { cython = super.cython.override { gdb = null; }; };
          };
        }) ];
        config = { allowUnfree = true; };
        crossSystem = { system = "armv6l-linux"; config = "armv6l-unknown-linux-gnueabihf"; };
      };

      # Disable some stuff that doesn’t cross compile.
      boot.supportedFilesystems = lib.mkForce [ "vfat" ];
      programs.command-not-found.enable = false;
      programs.ssh.setXAuthLocation = false;
      security.pam.services.su.forwardXAuth = lib.mkForce false;
      powerManagement.enable = false;

      # Setup includes so nixos-rebuild works.
      # installer.cloneConfigIncludes = [
      #   "<nixpkgs/nixos/modules/profiles/base.nix>"
      #   "<nixpkgs/nixos/modules/installer/cd-dvd/sd-image.nix>"
      #   "./headless.nix"
      #   "./hardware-configuration.nix"
      #   "(import ./private.nix ${name})"
      # ];

      # boot.postBootCommands = ''
      #   install -D ${hardware-config} /etc/nixos/hardware-configuration.nix
      #   install -D ${./headless.nix} /etc/nixos/headless.nix
      #   install -D ${./hosts.json} /etc/nixos/hosts.json
      #   install -D ${./private.nix} /etc/nixos/private.nix
      # '';
    }) ];
}).config.system.build.sdImage
