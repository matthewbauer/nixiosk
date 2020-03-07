{ pkgs, custom, ... }:

let

  self = builtins.fetchgit {
    url = ./.;
  };

in {

  environment.systemPackages = [ pkgs.git pkgs.openssh ];

  boot.postBootCommands = ''
    mkdir -p /root/.ssh
    if ! [ -f /root/.ssh/id_rsa ]; then
        ssh-keygen -q -t rsa -b 4096 -N "" -f /root/.ssh/id_rsa
    fi

    git clone ${self} /root/configuration

    cd /root/configuration
    cp ${builtins.toFile "config.json" (builtins.toJSON custom)} config.json
    git add --force config.json

    env GIT_AUTHOR_NAME="NixOS Basalt Module" \
        GIT_AUTHOR_EMAIL=matthewbauer@users.noreply.github.com \
        GIT_COMMITTER_NAME="NixOS Basalt Module" \
        GIT_COMMITTER_EMAIL=matthewbauer@users.noreply.github.com \
      git commit -m "Add config.json" --author="NixOS Basalt module"

    mkdir -p /etc/nixos
    git clone --bare ${self} /etc/nixos/configuration.git

    rm -rf /root/configuration

    rm -rf /etc/nixos/configuration.git/hooks
    ln -s ../basalt/targets/nixos/git-hooks /etc/nixos/configuration.git/hooks
  '';

}
