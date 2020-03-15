let

  kiosk = { hardware, program, name }: import ./boot {
    custom = {
      inherit hardware program;
      hostName = name;
      authorizedKeys = [];
      networks = {};
      locale = { timeZone = "America/New_York"; regDom = "US"; lang = "en_US.UTF-8"; };
      localSystem = { system = "x86_64-linux"; };
    };
  };

in

{

  rebuild = (import ((import ./nixpkgs {}).path + /nixos/lib/eval-config.nix) {
    modules = [
      ./configuration.nix
      ({lib, ...}: {
        system.build = {
          custom = {
            hardware = "raspberryPi4";
            program = { package = "gtk3"; executable = "/bin/gtk3-demo"; };
            hostName = "rebuilder";
            authorizedKeys = [];
            networks = {};
            locale = { timeZone = "America/New_York"; regDom = "US"; lang = "en_US.UTF-8"; };
            localSystem = { system = "x86_64-linux"; };
          }; }; })
    ];
  }).config.system.build.toplevel;

  retroPi0 = (kiosk {
    name = "retroPi0";
    hardware = "raspberryPi0";
    program = { package = "retroarch"; executable = "/bin/retroarch"; args = [ "-f" ]; };
  }).config.system.build.toplevel;

  retroPi4 = (kiosk {
    name = "retroPi4";
    hardware = "raspberryPi4";
    program = { package = "retroarch"; executable = "/bin/retroarch"; args = [ "-f" ]; };
  }).config.system.build.toplevel;

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
