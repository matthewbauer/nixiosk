{ lib, pkgs, config
, custom ? builtins.fromJSON (builtins.readFile ./custom.json)
, ...}: {
  imports = [
    ({
      raspberryPi0 = ./hardware/raspberrypi.nix;
      raspberryPi1 = ./hardware/raspberrypi.nix;
      raspberryPi2 = ./hardware/raspberrypi.nix;
      raspberryPi3 = ./hardware/raspberrypi.nix;
      raspberryPi4 = ./hardware/raspberrypi.nix;
    }.${custom.hardware} or {})
  ];

  boot.plymouth.enable = true;
  sdImage.compressImage = false;
  hardware.opengl.enable = true;

  time = { inherit (custom.locale) timeZone; };

  gtk.iconCache.enable = true;
  services.udev.packages = [ pkgs.libinput.out ];
  environment.systemPackages = [
    pkgs.gnome3.adwaita-icon-theme
    pkgs.hicolor-icon-theme
  ];

  nix = {
    buildMachines = lib.optional (custom.localSystem ? sshUser && custom.localSystem ? hostName) {
      inherit (custom.localSystem) system sshUser hostName;
      sshKey = "/root/.ssh/id_rsa";
    };
  };

  services.openssh = {
    enable = true;
    permitRootLogin = "without-password";
  };

  users.users.root = {
    openssh.authorizedKeys.keys = custom.authorizedKeys;
  };

  users.users.kiosk = {
    isNormalUser = true;
    useDefaultShell = true;
  };

  systemd.services."cage-tty1".environment.WLR_LIBINPUT_NO_DEVICES = "1";
  systemd.services."cage-tty1".environment.XDG_DATA_DIRS = "/nix/var/nix/profiles/default/share:/run/current-system/sw/share";
  systemd.services."cage-tty1".environment.XDG_CONFIG_DIRS = "/nix/var/nix/profiles/default/etc/xdg:/run/current-system/sw/etc/xdg";
  systemd.services."cage-tty1".environment.GDK_PIXBUF_MODULE_FILE = config.environment.variables.GDK_PIXBUF_MODULE_FILE;

  systemd.enableEmergencyMode = false;
  systemd.services."serial-getty@ttyS0".enable = false;
  systemd.services."serial-getty@hvc0".enable = false;
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@".enable = false;

  services.cage = {
    enable = true;
    user = "kiosk";
    program = "${pkgs.${custom.program.package}}${custom.program.path}";
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
        enableGeoLocation = false;
        stdenv = super.stdenv;
      };
      gst_all_1 = super.gst_all_1 // {
        gst-plugins-good = null;
        gst-plugins-bad = null;
        gst-plugins-ugly = null;
        gst-libav = null;
      };
      python37 = super.python37.override {
        packageOverrides = self: super: { cython = super.cython.override { gdb = null; }; };
      };
      libass = super.libass.override { encaSupport = false; };
      libproxy = super.libproxy.override { networkmanager = null; };
      enchant2 = super.enchant2.override { hspell = null; };
      cage = super.cage.override { xwayland = null; };
    }) ];
    crossSystem = {
      raspberryPi0 = "armv6l-unknown-linux-gnueabihf";
      raspberryPi1 = "armv6l-unknown-linux-gnueabihf";
      raspberryPi2 = "armv7l-unknown-linux-gnueabihf";
      raspberryPi3 = "armv7l-unknown-linux-gnueabihf";
      raspberryPi4 = "aarch64-unknown-linux-gnueabihf";
    } or throw "No known crossSystem for ${custom.hardware}.";
    inherit localSystem;
  };

  boot.supportedFilesystems = lib.mkForce [ "vfat" ];
  programs.command-not-found.enable = false;
  powerManagement.enable = false;
  documentation.enable = false;
  services.udisks2.enable = false;
  security.polkit.enable = false;

  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="${custom.locale.country}"
  '';

  networking = {
    inherit (custom) hostName;
    wireless = {
      enable = true;
      networks = builtins.mapAttrs (name: value: { pskRaw = value; }) custom.networks;
    };
  };

}
