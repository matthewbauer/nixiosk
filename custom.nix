{ lib, config, pkgs, ... }: {
  options = {
    kioskix.hostName = lib.mkOption {
      type = lib.types.str;
    };
    kioskix.hardware = lib.mkOption {
      type = lib.types.str;
    };
    kioskix.authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
    kioskix.program.package = lib.mkOption {
      type = lib.types.str;
    };
    kioskix.program.executable = lib.mkOption {
      type = lib.types.str;
    };
    kioskix.program.args = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
    kioskix.networks = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
    };
    kioskix.locale.lang = lib.mkOption {
      type = lib.types.str;
      default = "en_US.UTF-8";
    };
    kioskix.locale.regDom = lib.mkOption {
      type = lib.types.str;
      default = "US";
    };
    kioskix.locale.timeZone = lib.mkOption {
      type = lib.types.str;
      default = "America/New_York";
    };
    kioskix.localSystem.system = lib.mkOption {
      type = lib.types.str;
    };
    kioskix.localSystem.sshUser = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    kioskix.localSystem.hostName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config = {
    time = { timeZone = config.kioskix.locale.timeZone; };
    i18n.defaultLocale = config.kioskix.locale.lang;
    i18n.supportedLocales = [ "${config.kioskix.locale.lang}/UTF-8" ];
    boot.extraModprobeConfig = ''
        options cfg80211 ieee80211_regdom="${config.kioskix.locale.regDom}"
    '';
    nix.buildMachines = lib.optional ((config.kioskix.localSystem.sshUser != null) && (config.kioskix.localSystem.hostName != null)) {
      inherit (config.kioskix.localSystem) system sshUser hostName;

      # ??? is this okay to use for ssh keys?
      sshKey = "/etc/ssh/ssh_host_rsa_key";
    };
    users.users.root.openssh.authorizedKeys.keys = config.kioskix.authorizedKeys;
    services.cage.program = "${lib.getBin pkgs.${config.kioskix.program.package}}${config.kioskix.program.executable} ${toString (config.kioskix.program.args)}";
    networking.hostName = config.kioskix.hostName;
    networking.wireless.networks = builtins.mapAttrs (_: value: { pskRaw = value; }) (config.kioskix.networks or {});

    # services.ddclient = {
    #   enable = config.kioskix.custom.ddclient.enable;
    #   protocol = "${config.kioskix.ddclient.protocol}";
    #   password = "${config.kioskix.ddclient.password}";
    #   domains = ["${config.kioskix.ddclient.domain}"];
    # };

    # systemd.services.port-map = {
    #   enable = config.kioskix.upnp.enable;
    #   wantedBy = [ "multi-user.target" ];
    #   after = [ "network.target" ];
    #   serviceConfig = {
    #     Type = "oneshot";
    #     ExecStart = "${pkgs.miniupnpc}/bin/upnpc -r 22 ${toString cnofig.kioskix.upnp.sshPort} tcp";
    #   };
    # };

  } // lib.optionalAttrs (builtins.pathExists ./kioskix.json) {
    kioskix = builtins.fromJSON (builtins.readFile ./kioskix.json);
  };
}
