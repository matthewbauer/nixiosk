let

  kiosk = { hardware, program, name }: import ./boot {
    custom = {
      inherit hardware program;
      hostName = name;
      authorizedKeys = [];
      networks = {};
      locale = { timeZone = "America/New_York"; country = "US"; lang = "en_US.UTF-8"; };
      localSystem = { system = "x86_64-linux"; };
      basalt = false;
    };
  };

in

{

  retroPi0 = (kiosk {
    name = "kiosk";
    hardware = "raspberryPi0";
    program = { package = "retroarchBare"; path = "/bin/retroarch"; };
  }).config.system.build.toplevel;

  retroPi4 = (kiosk {
    name = "kiosk";
    hardware = "raspberryPi4";
    program = { package = "retroarchBare"; path = "/bin/retroarch"; };
  }).config.system.build.toplevel;

  epiphanyPi0 = (kiosk {
    name = "kiosk";
    hardware = "raspberryPi0";
    program = { package = "epiphany"; path = "/bin/epiphany"; };
  }).config.system.build.toplevel;

  epiphanyPi4 = (kiosk {
    name = "kiosk";
    hardware = "raspberryPi4";
    program = { package = "retroarchBare"; path = "/bin/epiphany"; };
  }).config.system.build.toplevel;

  demoPi0 = (kiosk {
    name = "kiosk";
    hardware = "raspberryPi0";
    program = { package = "gtk3"; path = "/bin/gtk3-demo"; };
  }).config.system.build.toplevel;

  demoPi1 = (kiosk {
    name = "kiosk";
    hardware = "raspberryPi1";
    program = { package = "gtk3"; path = "/bin/gtk3-demo"; };
  }).config.system.build.toplevel;

  demoPi2 = (kiosk {
    name = "kiosk";
    hardware = "raspberryPi2";
    program = { package = "gtk3"; path = "/bin/gtk3-demo"; };
  }).config.system.build.toplevel;

  demoPi3 = (kiosk {
    name = "kiosk";
    hardware = "raspberryPi3";
    program = { package = "gtk3"; path = "/bin/gtk3-demo"; };
  }).config.system.build.toplevel;

  demoPi4 = (kiosk {
    name = "kiosk";
    hardware = "raspberryPi4";
    program = { package = "gtk3"; path = "/bin/gtk3-demo"; };
  }).config.system.build.toplevel;

}
