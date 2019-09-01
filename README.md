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
git init --bare configuration.git
cd configuration.git
rm -r hooks
ln -s /path/to/basalt/git-hooks hooks
```

* Everything that used to be in /etc/nixos moves to the configuration repo
* You *must* have both `nixpkgs` and `basalt` as git subtrees or [subrepos](https://github.com/ingydotnet/git-subrepo) at /nixpkgs and /basalt  in your configuration repo.  Note that submodules won't work, because we want to ensure that we have the full configuration source.  (Note: we could support submodules if we had a way of ensuring that their sources don't become unavailable, for example by sandboxing the build process; however, this work has not been done yet.)

### Update your configuration

Note: This also works for reconfiguring a system that you have mounted, e.g. when booted from a NixOS installation disk.  It will automatically use chroot appropriately.

```bash
# Create a checkout of your system config, owned by your user
git clone /etc/nixos/configuration.git
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

## Design Goals

1. Ensure that, prior to switching to any configuration, the full source is committed to git.  This ensures that a single git hash is sufficient to completely reconstruct your configuration as it was at any point in history.
1. Ensure that it's always possible to rollback or reconfigure without network access.  In particular, we want to be able to recover from a scenario where a configuration change makes the internet unreachable.
