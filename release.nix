let

  kiosk = { hardware ? null, program, name }: import ./boot {
    custom = {
      inherit hardware program;
      hostName = name;
      localSystem = { system = builtins.currentSystem; };
    };
  };

  rebuilder = { hardware, program, name }: import ((import ./nixpkgs {}).path + /nixos/lib/eval-config.nix) {
    modules = [
      ./configuration.nix
      ({lib, ...}: {
        system.build = {
          custom = {
            inherit hardware program;
            hostName = name;
            localSystem = { system = builtins.currentSystem; };
          }; }; })
    ];
  };

in

{

  rebuildRetroPi0 = (rebuilder {
    name = "rebuilderRetroPi0";
    hardware = "raspberryPi0";
    program = { package = "retroarch"; executable = "/bin/retroarch"; };
  });

  retroPi0 = (kiosk {
    name = "retroPi0";
    hardware = "raspberryPi0";
    program = { package = "retroarch"; executable = "/bin/retroarch"; };
  }).config.system.build.toplevel;

  retroPi4 = (kiosk {
    name = "retroPi4";
    hardware = "raspberryPi4";
    program = { package = "retroarch"; executable = "/bin/retroarch"; };
  }).config.system.build.toplevel;

  retroOva = (kiosk {
    name = "retroOva";
    hardware = "ova";
    program = { package = "retroarch"; executable = "/bin/retroarch"; };
  }).config.system.build.virtualBoxOVA;

  retroIso = (kiosk {
    name = "retroIso";
    hardware = "iso";
    program = { package = "retroarch"; executable = "/bin/retroarch"; };
  }).config.system.build.isoImage;

  epiphanyPi0 = (kiosk {
    name = "epiphanyPi0";
    hardware = "raspberryPi0";
    program = { package = "epiphany"; executable = "/bin/epiphany"; };
  }).config.system.build.toplevel;

  epiphanyPi4 = (kiosk {
    name = "epiphanyPi4";
    hardware = "raspberryPi4";
    program = { package = "epiphany"; executable = "/bin/epiphany"; };
  }).config.system.build.toplevel;

  demoPi0 = (kiosk {
    name = "demoPi0";
    hardware = "raspberryPi0";
    program = { package = "gtk3"; executable = "/bin/gtk3-demo"; };
  }).config.system.build.toplevel;

  demoPi1 = (kiosk {
    name = "demoPi1";
    hardware = "raspberryPi1";
    program = { package = "gtk3"; executable = "/bin/gtk3-demo"; };
  }).config.system.build.toplevel;

  demoPi2 = (kiosk {
    name = "demoPi2";
    hardware = "raspberryPi2";
    program = { package = "gtk3"; executable = "/bin/gtk3-demo"; };
  }).config.system.build.toplevel;

  demoPi3 = (kiosk {
    name = "demoPi3";
    hardware = "raspberryPi3";
    program = { package = "gtk3"; executable = "/bin/gtk3-demo"; };
  }).config.system.build.toplevel;

  demoPi4 = (kiosk {
    name = "demoPi4";
    hardware = "raspberryPi4";
    program = { package = "gtk3"; executable = "/bin/gtk3-demo"; };
  }).config.system.build.toplevel;

  # kodiPi4 = (kiosk {
  #   name = "kodiPi4";
  #   hardware = "raspberryPi0";
  #   program = { package = "kodi"; executable = "/bin/kodi"; };
  # }).config.system.build.toplevel;

}
