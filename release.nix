let

  pkgs = import ./nixpkgs {};

  boot = { hardware ? null, program, name, locale ? {} }: import ./boot {
    inherit pkgs;
    custom = {
      inherit hardware program locale;
      hostName = name;
      localSystem = {
        system = if builtins.currentSystem == "x86_64-darwin"
                 then "x86_64-linux"
                 else builtins.currentSystem;
      };
    };
  };

  rebuilder = { hardware, program, name, locale ? {} }: import (pkgs.path + /nixos/lib/eval-config.nix) {
    modules = [
      ./configuration.nix
      ({lib, ...}: {
        system.build = {
          custom = {
            inherit hardware program locale;
            hostName = name;
            localSystem = {
              system = if builtins.currentSystem == "x86_64-darwin"
                       then "x86_64-linux"
                       else builtins.currentSystem;
            };
          }; }; })
    ];
  };

in

{

  rebuildRetroPi0 = (rebuilder {
    name = "rebuilderRetroPi0";
    hardware = "raspberryPi0";
    program = { package = "retroarch"; executable = "/bin/retroarch"; };
    locale.timeZone = "America/New_York";
  });

  retroPi0 = (boot {
    name = "retroPi0";
    hardware = "raspberryPi0";
    program = { package = "retroarch"; executable = "/bin/retroarch"; };
    locale.timeZone = "America/New_York";
  }).config.system.build.toplevel;

  retroPi4 = (boot {
    name = "retroPi4";
    hardware = "raspberryPi4";
    program = { package = "retroarch"; executable = "/bin/retroarch"; };
    locale.timeZone = "America/New_York";
  }).config.system.build.toplevel;

  retroOva = (boot {
    name = "retroOva";
    hardware = "ova";
    program = { package = "retroarch"; executable = "/bin/retroarch"; };
  }).config.system.build.toplevel;

  retroIso = (boot {
    name = "retroIso";
    hardware = "iso";
    program = { package = "retroarch"; executable = "/bin/retroarch"; };
  }).config.system.build.toplevel;

  epiphanyPi0 = (boot {
    name = "epiphanyPi0";
    hardware = "raspberryPi0";
    program = { package = "epiphany"; executable = "/bin/epiphany"; };
    locale.timeZone = "America/New_York";
  }).config.system.build.toplevel;

  epiphanyPi4 = (boot {
    name = "epiphanyPi4";
    hardware = "raspberryPi4";
    program = { package = "epiphany"; executable = "/bin/epiphany"; };
    locale.timeZone = "America/New_York";
  }).config.system.build.toplevel;

  demoPi0 = (boot {
    name = "demoPi0";
    hardware = "raspberryPi0";
    program = { package = "gtk3"; executable = "/bin/gtk3-demo"; };
    locale.timeZone = "America/New_York";
  }).config.system.build.toplevel;

  demoPi1 = (boot {
    name = "demoPi1";
    hardware = "raspberryPi1";
    program = { package = "gtk3"; executable = "/bin/gtk3-demo"; };
    locale.timeZone = "America/New_York";
  }).config.system.build.toplevel;

  demoPi2 = (boot {
    name = "demoPi2";
    hardware = "raspberryPi2";
    program = { package = "gtk3"; executable = "/bin/gtk3-demo"; };
    locale.timeZone = "America/New_York";
  }).config.system.build.toplevel;

  demoPi3 = (boot {
    name = "demoPi3";
    hardware = "raspberryPi3";
    program = { package = "gtk3"; executable = "/bin/gtk3-demo"; };
    locale.timeZone = "America/New_York";
  }).config.system.build.toplevel;

  demoPi4 = (boot {
    name = "demoPi4";
    hardware = "raspberryPi4";
    program = { package = "gtk3"; executable = "/bin/gtk3-demo"; };
    locale.timeZone = "America/New_York";
  }).config.system.build.toplevel;

  # Currently broken, missing atomics in armv6l.
  # kodiPi1 = (boot {
  #   name = "kodiPi1";
  #   hardware = "raspberryPi1";
  #   program = { package = "kodi"; executable = "/bin/kodi"; };
  #   locale.timeZone = "America/New_York";
  # }).config.system.build.sdImage;

  kodiPi2 = (boot {
    name = "kodiPi2";
    hardware = "raspberryPi2";
    program = { package = "kodi"; executable = "/bin/kodi"; };
    locale.timeZone = "America/New_York";
  }).config.system.build.toplevel;

  kodiPi3 = (boot {
    name = "kodiPi3";
    hardware = "raspberryPi3";
    program = { package = "kodi"; executable = "/bin/kodi"; };
    locale.timeZone = "America/New_York";
  }).config.system.build.toplevel;

  kodiPi4 = (boot {
    name = "kodiPi4";
    hardware = "raspberryPi4";
    program = { package = "kodi"; executable = "/bin/kodi"; };
    locale.timeZone = "America/New_York";
  }).config.system.build.toplevel;

  kodiOva = (boot {
    name = "kodiOva";
    hardware = "ova";
    program = { package = "kodi"; executable = "/bin/kodi"; };
  }).config.system.build.toplevel;

}
