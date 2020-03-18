{ lib, pkgs, config, ...}: {

  imports = [ ./nixiosk.nix ./hardware/raspberrypi.nix ];

  hardware.opengl.enable = true;
  hardware.bluetooth.enable = true;
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  services.dbus.enable = true;

  # HACKS!
  systemd.services.rngd.serviceConfig = {
    NoNewPrivileges = lib.mkForce false;
    PrivateNetwork = lib.mkForce false;
    ProtectSystem = lib.mkForce false;
    ProtectHome = lib.mkForce false;
  };

  # theming
  gtk.iconCache.enable = true;
  environment.systemPackages = [
    pkgs.gnome3.adwaita-icon-theme pkgs.hicolor-icon-theme
  ];

  # input
  services.udev.packages = [ pkgs.libinput.out ];

  # nix.package = pkgs.nixUnstable;

  services.openssh = {
    enable = true;
    permitRootLogin = "without-password";
  };

  users.users.kiosk = {
    isNormalUser = true;
    useDefaultShell = true;
  };

  systemd.services."cage-tty1" = {
    serviceConfig.Restart = "always";
    environment = {
      WLR_LIBINPUT_NO_DEVICES = "1";
      XDG_DATA_DIRS = "/nix/var/nix/profiles/default/share:/run/current-system/sw/share";
      XDG_CONFIG_DIRS = "/nix/var/nix/profiles/default/etc/xdg:/run/current-system/sw/etc/xdg";
      # GDK_PIXBUF_MODULE_FILE = config.environment.variables.GDK_PIXBUF_MODULE_FILE;
      WEBKIT_DISABLE_COMPOSITING_MODE = "1";
    };
  };

  systemd.enableEmergencyMode = false;
  systemd.services."serial-getty@ttyS0".enable = false;
  systemd.services."serial-getty@hvc0".enable = false;
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@".enable = false;

  services.udisks2.enable = false;
  documentation.enable = false;
  powerManagement.enable = false;
  programs.command-not-found.enable = false;

  services.cage = {
    enable = true;
    user = "kiosk";
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
    overlays = [(self: super: (lib.optionalAttrs (super.stdenv.hostPlatform != super.stdenv.buildPlatform) {

      # doesn’t cross compile
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

      # cython pulls in target-specific gdb
      python37 = super.python37.override {
        packageOverrides = self: super: { cython = super.cython.override { gdb = null; }; };
      };

      # doesn’t cross compile
      libass = super.libass.override { encaSupport = false; };
      libproxy = super.libproxy.override { networkmanager = null; };
      enchant2 = super.enchant2.override { hspell = null; };
      cage = super.cage.override { xwayland = null; };
      alsaPlugins = super.alsaPlugins.override { libjack2 = null; };

      ffmpeg_4 = super.ffmpeg_4.override ({
        sdlSupport = false;
        # some ffmpeg libs are compiled with neon which rpi0 doesn’t support
      } // lib.optionalAttrs (super.stdenv.hostPlatform.parsed.cpu.name == "armv6l") {
        libopus = null;
        x264 = null;
        x265 = null;
        soxr = null;
      });
      ffmpeg = super.ffmpeg.override ({
        sdlSupport = false;
      } // lib.optionalAttrs (super.stdenv.hostPlatform.parsed.cpu.name == "armv6l") {
        libopus = null;
        x264 = null;
        x265 = null;
        soxr = null;
      });

      retroarchBare = (super.retroarchBare.override {
        SDL2 = null;
        withVulkan = false;
        withX11 = false;
      }).overrideAttrs (o: {
        patches = (o.patches or []) ++ [ ./retroarch-lakkaish.patch ];
      });

      mesa = super.mesa.override {
        eglPlatforms = ["wayland"];
      };

      # armv6l (no NEON) and aarch64 don’t have prebuilt cores, so
      # provide some here that are known to work well. Feel free to
      # include more that are known to work here. To add more cores,
      # or update existing core, contribute them upstream in Nixpkgs
      retroarch = super.retroarch.override {
        cores = {
          armv6l = with super.libretro; [ snes9x stella fba fceumm vba-next vecx handy prboom bluemsx ];
          aarch64 = with super.libretro; [ _4do atari800 beetle-gba beetle-lynx beetle-ngp beetle-pce-fast beetle-pcfx beetle-psx beetle-saturn beetle-snes beetle-supergrafx beetle-vb beetle-wswan bluemsx bsnes-mercury dosbox fba fceumm gambatte genesis-plus-gx gpsp handy mesen mgba mupen64plus nestopia o2em pcsx_rearmed prboom prosystem quicknes snes9x stella vba-m vba-next vecx virtualjaguar yabause ];
        }.${super.stdenv.hostPlatform.parsed.cpu.name} or [];
      };

    })) ];

    # We use remote builders for things like 32-bit arm where there is
    # no binary cache, otherwise, we can might as well build it
    # natively, with the cache covering most of it.
    localSystem = let
      cachedSystems = [ "aarch64-linux" "x86_64-linux" "x86_64-darwin" ];
    in if builtins.elem (config.nixpkgs.crossSystem.system or null) cachedSystems
       then config.nixpkgs.crossSystem
       else config.nixiosk.localSystem;
  };

  boot.plymouth.enable = true;
  boot.supportedFilesystems = lib.mkForce [ "vfat" ];
  boot.kernelParams = ["quiet"];

  networking = {
    wireless.enable = true;
    dhcpcd.extraConfig = "timeout 0";
  };

}
