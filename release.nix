let

  kiosk = import ./kiosk.nix;

in

{

  rasperryPi0 = (kiosk {
    hostName = "kiosk";
    crossSystem.config = "armv6l-unknown-linux-gnueabihf";
    authorizedKeys = [];
    programFunc = pkgs: "${pkgs.epiphany}/bin/epiphany";
  }).config.system.build.sdImage;

}
