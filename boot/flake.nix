{ pkgs, lib, config, ... }:

{

  boot.postBootCommands = lib.optionalString (config.nixiosk.flake != null) ''
    mkdir -p /etc
    cp -R ${config.nixiosk.flake} /etc/nixos
    chmod -R u+w /etc/nixos
  '';

}
