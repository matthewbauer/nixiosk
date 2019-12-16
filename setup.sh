#!/usr/bin/env bash

# Initial setup script.

unset TARGET

case "$TARGET" in
    "nixos" )
        echo "not implemented"
        ;;

    "home-manager" )
        echo "not implemented"
        ;;

    * )
        echo "unknown target type"
        exit 1;
        ;;
esac

unset SOURCE_REPO

unset DESTINATION_REPO

setup_nixos ()
{
    echo "will setup for NixOS system-wide configuration"
    cp -r ./targets/nixos/git-hooks "$DESTINATION_REPO"/.git/
    cp -r ./targets/nixos/git-hook-impls "$DESTINATION_REPO"
}

setup_home-manager ()
{
    echo "will setup for home-manager configuration"
    cp -r ./targets/home-manager/git-hooks "$DESTINATION_REPO"/.git/
    cp -r ./targets/nixos/git-hook-implds "$DESTINATION_REPO"
}
