{ pkgs ? import (builtins.fetchTarball {
    url = "https://github.com/matthewbauer/nixpkgs/archive/4b3d8a9a7e370afc32f2052ce3ad384c9f2a4b06.tar.gz";
    sha256 = "0ad7cyaknfk2k6m67wzgrizchf5xca90lbnf4a62g5g3f9ainj7m";
  }) {}
, hostName
, programFunc
, authorizedKeys
, crossSystem }:

import (pkgs.path + /nixos/lib/eval-config.nix) {
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

      services.avahi = {
        enable = true;
        nssmdns = true;
        publish = {
          enable = true;
          userServices = true;
          addresses = true;
          hinfo = true;
          workstation = true;
          domain = true;
        };
      };
      environment.etc."avahi/services/ssh.service" = {
        text = ''
<?xml version="1.0" standalone='no'?><!--*-nxml-*-->
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">%h</name>
  <service>
    <type>_ssh._tcp</type>
    <port>22</port>
  </service>
</service-group>
        '';
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

      # Disable some stuff that doesn’t cross compile / takes a long time.
      boot.supportedFilesystems = lib.mkForce [ "vfat" ];
      programs.command-not-found.enable = false;
      security.pam.services.su.forwardXAuth = lib.mkForce false;
      powerManagement.enable = false;
      documentation.enable = false;
      services.udisks2.enable = false;
      fonts.fontconfig.enable = false;
      security.polkit.enable = false;
    }) ];
}
