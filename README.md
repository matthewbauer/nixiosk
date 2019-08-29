## IMPORTANT

This software is not yet stable; please do not use it on important systems yet.

## Introduction

Basalt is a tool for using git to manage your nixos configuration.  Rather than using nixos-rebuild switch, we push to a branch.

One big reason to do this is that, even though NixOS makes rolling back to a particular generation trivial, it can be difficult or impossible to figure out what set of inputs actually produced that generation.  With a git-based approach, we hope to ensure that each NixOS generation is completely described by a single git hash.

## How To

### Set up Basalt

As root:

```bash
cd /etc/nixos
git init --bare configuration
cd configuration
rm -r hooks
ln -s /path/to/basalt/git-hooks hooks
```

* Your configuration.nix becomes default.nix in the configuration repo
* You *must* have `nixpkgs` as a submodule at /nixpkgs in your configuration repo

TODO: Better way of managing Basalt itself

### Update your configuration

Note: This also works for reconfiguring a system that you have mounted, e.g. when booted from a NixOS installation disk.  It will automatically use chroot appropriately.

```bash
# Create a checkout of your system config, owned by your user
git clone /etc/nixos/configuration
cd configuration

# If you aren't root, do this to allow `git push` to update the system config, with proper authorization
git config remote.origin.receivepack 'sudo git-receive-pack'
```

Now you have a local copy of the system config that you can update with your editor(s) of choice.  When you're done, push to the master branch:

```bash
git push
```

Note that, in order to be built/deployed, the target branch must be called `master`.

You will need to authenticate however you usually do when you run commands with sudo.
