# Basalt

## IMPORTANT

This software is not yet stable; please do not use it on important systems yet.

## Introduction

Basalt is a tool for using Git to manage your NixOS or home-manager
configuration.  Rather than using `nixos-rebuild switch` or `home-manager
switch`, we push to a branch.

One big reason to do this is that, even though NixOS makes rolling back to a
particular generation trivial, it can be difficult or impossible to figure out
what set of inputs actually produced that generation.  With a git-based
approach, we hope to ensure that each NixOS generation is completely described
by a single git hash.

## Recommended tools

We recommend that you use `git-subtree` for tracking external dependencies in a
configuration repository.  It has been included as a standard command since Git
`v1.7.11` and may simplify the process of updating the dependencies.  It also
makes sure they can be accessed simply by cloning the configuration repository,
without requiring a separate dependency fetching step.  No extra files are
needed for `git-subtree` to track the metadata associated with the dependency
subdirectories, unlike `git-submodule` or `git-subrepo`, for example.

You may wish to add named remotes for each dependency so you don't forget where
to pull from.  Take `nixpkgs`, for example:

```bash
git remote add -f nixpkgs-github https://github.com/NixOS/nixpkgs.git
```

However, you will still need to remember which branch you want to use when
pulling updates.  It is not recommended to pull directly from the `master`
branch of `nixpkgs`, so perhaps instead you could make a comment in your
configuration somewhere that documents which branch/release it is using.

## home-manager configuration target

For Basalt to manage your [home-manager](https://github.com/rycee/home-manager)
configuration (i.e. `home.nix`), you must first create a Git repository with all
the required dependencies for the build input.  This includes Basalt itself, the
home-manager source, and Nixpkgs for your user packages.  These dependencies are
also referred to as "thunks".

```bash
git init home-manager-config
cd home-manager-config
cp ~/.config/nixpkgs/home.nix .  # if you are already using home-manager
git add home.nix
git commit
git subtree add --prefix=basalt https://gitlab.com/obsidian.systems/basalt.git master --squash
git subtree add --prefix=home-manager https://github.com/rycee/home-manager.git master --squash
git subtree add --prefix=nixpkgs https://github.com/NixOS/nixpkgs.git nixpkgs-unstable --squash
```

For consistency, it is important to have an existing initial commit before
attempting to add the dependencies.  Do not forget the `--squash` option!
Please note cloning the Nixpkgs repository may take an extended period of time,
as it is quite large.  You may also wish to specify a particular release branch
other than `nixpkgs-unstable` when cloning Nixpkgs, such as `release-19.09`, to
match your desired release!  If you are using a stable release of Nixpkgs, then
you will also need to use a corresponding stable branch of home-manager.

Next you must create a target git repo, whose only purpose is to run the Git
hooks and keep a record of successful revisions.  You probably also want a
separate Basalt repo outside of your config repo to actually store the hooks.

```bash
git clone https://gitlab.com/obsidian.systems/basalt.git basalt
git init --bare home-manager-config-target.git
```

Then install the hooks by symlinking.

```bash
cd home-manager-config-target.git
rm -r hooks
ln -s ../basalt/targets/home-manager/git-hooks hooks
```

Set the target repo as the origin for your non-bare repo, and then push to build
your new configuration and install it if successful.  You must use the `master`
branch for this to work properly.

```bash
cd home-manager-config
git remote add origin ../home-manager-config-target.git
git push --set-upstream origin master
```

You can also add a remote repository and store, or back up, your configuration
there as well, of course.  However, the home-manager build and activation
process will only run when you push to your local target repo.

## NixOS configuration target

### Set up Basalt

As root:

```bash
cd /etc/nixos
git clone https://gitlab.com/obsidian.systems/basalt
git init --bare configuration.git
cd configuration.git
rm -r hooks
ln -s ../basalt/targets/nixos/git-hooks hooks
```

* Everything that used to be in /etc/nixos moves to the configuration repo
* You *must* have both `nixpkgs` and `basalt` as git subtrees or [subrepos](https://github.com/ingydotnet/git-subrepo) at /nixpkgs and /basalt  in your configuration repo.  Note that submodules won't work, because we want to ensure that we have the full configuration source.  (Note: we could support submodules if we had a way of ensuring that their sources don't become unavailable, for example by sandboxing the build process; however, this work has not been done yet.)
* You cannot refer to `<nixpkgs>` or other angle-bracketed paths, because basalt clears NIX_PATH before evaluating your expression.  Commonly, nix modules are imported with angle-bracketed paths, so you may need to modify configuration.nix or hardware-configuration.nix to change `<nixpkgs/path/to/module>` to `./nixpkgs/path/to/module`.

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

1. Ensure that, prior to switching to any configuration, the full source is
   committed to git.  This ensures that a single git hash is sufficient to
   completely reconstruct your configuration as it was at any point in history.
2. Ensure that it's always possible to rollback or reconfigure without network
   access.  In particular, we want to be able to recover from a scenario where a
   configuration change makes the internet unreachable.
3. Built-in backward compatibility for Basalt itself.
