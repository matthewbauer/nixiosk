{ stdenv
, fetchFromGitHub
, autoreconfHook
, boost
, libcec
, libcec_platform
, pkg-config
, log4cplus }:

stdenv.mkDerivation {
  name = "libcec-daemon";
  src = fetchFromGitHub {
    owner = "matthewbauer";
    repo = "libcec-daemon";
    rev = "48e943dee0d8fae90327456a3b2b250fe0e6d103";
    sha256 = "19nhymi4y6mmf8yb1rjfh74dm3qdrkhnnc9dhx13y5gk9br6jdg7";
  };
  nativeBuildInputs = [ autoreconfHook pkg-config ];
  buildInputs = [ libcec libcec_platform boost log4cplus ];
}
