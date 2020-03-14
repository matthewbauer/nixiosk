{ hardware, pkgs, lib, config }:

import ({
  raspberryPi0 = ./raspberrypi.nix;
  raspberryPi1 = ./raspberrypi.nix;
  raspberryPi2 = ./raspberrypi.nix;
  raspberryPi3 = ./raspberrypi.nix;
  raspberryPi4 = ./raspberrypi.nix;
}.${hardware} or (throw "Unknown hardware: ${hardware}")) { inherit hardware pkgs lib config; }
