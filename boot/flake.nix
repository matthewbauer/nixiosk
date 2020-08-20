{ pkgs, lib, config, ... }:

# TODO: construct a real flake from nixiosk.json

{

  boot.postBootCommands = ''
    ln -sf ${builtins.toFile "nixiosk.json" (builtins.toJSON config.nixiosk)} /etc/nixiosk.json
  '';

}
