let

  kiosk = custom: import ./boot { inherit custom; };

in

{

  raspberryPi0 = (kiosk {
    hostName = "kiosk";
    hardware = "raspberryPi0";
    authorizedKeys = [];
    program = { package = "epiphany"; path = "/bin/epiphany"; };
    networks = {};
    locale = { timeZone = "America/New_York"; country = "US"; };
    localSystem = { system = "x86_64-linux"; };
  }).config.system.build.sdImage;

  raspberryPi1 = (kiosk {
    hostName = "kiosk";
    hardware = "raspberryPi1";
    authorizedKeys = [];
    program = { package = "epiphany"; path = "/bin/epiphany"; };
    networks = {};
    locale = { timeZone = "America/New_York"; country = "US"; };
    localSystem = { system = "x86_64-linux"; };
  }).config.system.build.sdImage;

  raspberryPi2 = (kiosk {
    hostName = "kiosk";
    hardware = "raspberryPi2";
    authorizedKeys = [];
    program = { package = "epiphany"; path = "/bin/epiphany"; };
    networks = {};
    locale = { timeZone = "America/New_York"; country = "US"; };
    localSystem = { system = "x86_64-linux"; };
  }).config.system.build.sdImage;

  raspberryPi3 = (kiosk {
    hostName = "kiosk";
    hardware = "raspberryPi3";
    authorizedKeys = [];
    program = { package = "epiphany"; path = "/bin/epiphany"; };
    networks = {};
    locale = { timeZone = "America/New_York"; country = "US"; };
    localSystem = { system = "x86_64-linux"; };
  }).config.system.build.sdImage;

  raspberryPi4 = (kiosk {
    hostName = "kiosk";
    hardware = "raspberryPi4";
    authorizedKeys = [];
    program = { package = "epiphany"; path = "/bin/epiphany"; };
    networks = {};
    locale = { timeZone = "America/New_York"; country = "US"; };
    localSystem = { system = "x86_64-linux"; };
  }).config.system.build.sdImage;

}
