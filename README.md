## Introduction

Basalt is a tool for using git to manage your nixos configuration.  Rather than using nixos-rebuild switch, we push to a branch.

One big reason to do this is that, even though NixOS makes rolling back to a particular generation trivial, it can be difficult or impossible to figure out what set of inputs actually produced that generation.  With a git-based approach, we hope to ensure that each NixOS generation is completely described by a single git hash.

## How To

### Update your configuration

```bash
# Create a checkout of your system config, owned by your user
git clone /etc/nixos/configuration
cd configuration

# Allow `git push` to update the system config, with proper authorization
git config remote.origin.receivepack 'sudo git-receive-pack'
```

Now you have a local copy of the system config that you can update with your editor(s) of choice.  When you're done, do:

```bash
git push
```

You will need to authenticate however you usually do when you run commands with sudo.
