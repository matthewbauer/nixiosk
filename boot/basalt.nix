{ pkgs, custom, ... }:

let

  git = pkgs.git.override {
    withManual = false;
    pythonSupport = false;
    withpcre2 = false;
    perlSupport = false;
  };

  configuration = pkgs.runCommand "configuration.git" { nativeBuildInputs = [ pkgs.buildPackages.gitMinimal ]; } ''
    git clone ${builtins.path {
      path = ../.git;
      name = "configuration-bare.git";
    }} configuration

    cd configuration
    cp ${builtins.toFile "config.json" (builtins.toJSON custom)} config.json
    git add --force config.json

    env GIT_AUTHOR_NAME="NixOS Basalt Module" \
        GIT_AUTHOR_EMAIL=matthewbauer@users.noreply.github.com \
        GIT_COMMITTER_NAME="NixOS Basalt Module" \
        GIT_COMMITTER_EMAIL=matthewbauer@users.noreply.github.com \
      git commit -m "Add config.json"

    git clone --bare . $out
  '';

in {

  environment.systemPackages = [ git pkgs.openssh ];

  boot.postBootCommands = ''
    mkdir -p /root/.ssh
    if ! [ -f /root/.ssh/id_rsa ]; then
        ssh-keygen -q -t rsa -b 4096 -N "" -f /root/.ssh/id_rsa
    fi

    mkdir -p /etc/nixos
    git clone --bare ${configuration} /etc/nixos/configuration.git

    rm -rf /etc/nixos/configuration.git/hooks
    ln -s ../basalt/targets/nixos/git-hooks /etc/nixos/configuration.git/hooks
  '';

}
