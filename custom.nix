{ lib, config, pkgs, ... }: {
  options = {
    nixiosk.hostName = lib.mkOption {
      type = lib.types.str;
    };
    nixiosk.hardware = lib.mkOption {
      type = lib.types.str;
    };
    nixiosk.authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
    nixiosk.program.package = lib.mkOption {
      type = lib.types.str;
    };
    nixiosk.program.executable = lib.mkOption {
      type = lib.types.str;
    };
    nixiosk.program.args = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
    nixiosk.networks = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
    };
    nixiosk.locale.lang = lib.mkOption {
      type = lib.types.str;
      default = "en_US.UTF-8";
    };
    nixiosk.locale.regDom = lib.mkOption {
      type = lib.types.str;
      default = "US";
    };
    nixiosk.locale.timeZone = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    nixiosk.localSystem.system = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    nixiosk.localSystem.sshUser = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    nixiosk.localSystem.hostName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    nixiosk.raspberryPi.firmwareConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    nixiosk.raspberryPi.enableExtraFirmware = lib.mkOption {
      type = lib.types.bool;
      default = builtins.elem config.nixiosk.hardware ["raspberryPi0" "raspberryPi1" "raspberryPi2"];
    };
  };

  config = {
    time = { timeZone = config.nixiosk.locale.timeZone; };
    services.localtime.enable = config.nixiosk.locale.timeZone == null && !(builtins.elem config.nixiosk.hardware ["ova" "qemu" "qemu-no-virtfs"]);

    i18n.defaultLocale = config.nixiosk.locale.lang;
    i18n.supportedLocales = [ "${config.nixiosk.locale.lang}/UTF-8" ];
    boot.extraModprobeConfig = ''
        options cfg80211 ieee80211_regdom="${config.nixiosk.locale.regDom}"
    '';
    nix.distributedBuilds = true;
    nix.buildMachines = lib.optional ((config.nixiosk.localSystem.hostName != null) && (config.nixiosk.localSystem.sshUser != null) && (config.nixiosk.localSystem.system != null)) {
      inherit (config.nixiosk.localSystem) system sshUser hostName;

      # ??? is this okay to use for ssh keys?
      sshKey = "/etc/ssh/ssh_host_rsa_key";
    };
    users.users.root.openssh.authorizedKeys.keys = config.nixiosk.authorizedKeys;
    services.cage.program = "${lib.getBin pkgs.${config.nixiosk.program.package}}${config.nixiosk.program.executable} ${toString (config.nixiosk.program.args)}";
    networking.hostName = config.nixiosk.hostName;
    networking.wireless.networks = builtins.mapAttrs (_: value: { pskRaw = value; }) (config.nixiosk.networks or {});

    # services.ddclient = {
    #   enable = config.nixiosk.custom.ddclient.enable;
    #   protocol = "${config.nixiosk.ddclient.protocol}";
    #   password = "${config.nixiosk.ddclient.password}";
    #   domains = ["${config.nixiosk.ddclient.domain}"];
    # };

    # systemd.services.port-map = {
    #   enable = config.nixiosk.upnp.enable;
    #   wantedBy = [ "multi-user.target" ];
    #   after = [ "network.target" ];
    #   serviceConfig = {
    #     Type = "oneshot";
    #     ExecStart = "${pkgs.miniupnpc}/bin/upnpc -r 22 ${toString cnofig.nixiosk.upnp.sshPort} tcp";
    #   };
    # };

  } // lib.optionalAttrs (builtins.pathExists ./nixiosk.json) {
    nixiosk = builtins.fromJSON (builtins.readFile ./nixiosk.json);
  };
}
