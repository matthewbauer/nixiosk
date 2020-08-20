(import (fetchTarball https://github.com/matthewbauer/flake-compat/archive/lockless-flake.tar.gz) {
  src = ./.;
}).defaultNix
