{ stdenv, fetchurl, glib, libxml2, meson, ninja, pkgconfig, gnome3
, gnomeSupport ? true, sqlite, glib-networking
, libpsl, python3, brotli
, enableIntrospection ? stdenv.hostPlatform == stdenv.buildPlatform, gobject-introspection
, enableVapi ? stdenv.hostPlatform == stdenv.buildPlatform, vala }:

stdenv.mkDerivation rec {
  pname = "libsoup";
  version = "2.68.3";

  src = fetchurl {
    url = "mirror://gnome/sources/${pname}/${stdenv.lib.versions.majorMinor version}/${pname}-${version}.tar.xz";
    sha256 = "1yxs0ax4rq3g0lgkbv7mz497rqj16iyyizddyc13gzxh6n7b0jsk";
  };

  postPatch = ''
    patchShebangs libsoup/
  '';

  outputs = [ "out" "dev" ];

  buildInputs = [ python3 sqlite libpsl brotli ];
  nativeBuildInputs = [ meson ninja pkgconfig glib ]
    ++ stdenv.lib.optional enableVapi vala
    ++ stdenv.lib.optional enableIntrospection gobject-introspection;
  propagatedBuildInputs = [ glib libxml2 ];

  mesonFlags = [
    "-Dtls_check=false" # glib-networking is a runtime dependency, not a compile-time dependency
    "-Dgssapi=disabled"
    "-Dvapi=${if enableVapi then "enabled" else "disabled"}"
    "-Dgnome=${if gnomeSupport then "true" else "false"}"
    "-Dntlm=disabled"
  ] ++ stdenv.lib.optional (!enableIntrospection) "-Dintrospection=disabled";

  doCheck = false; # ERROR:../tests/socket-test.c:37:do_unconnected_socket_test: assertion failed (res == SOUP_STATUS_OK): (2 == 200)

  passthru = {
    propagatedUserEnvPackages = [ glib-networking.out ];
    updateScript = gnome3.updateScript {
      packageName = pname;
    };
  };

  meta = {
    description = "HTTP client/server library for GNOME";
    homepage = https://wiki.gnome.org/Projects/libsoup;
    license = stdenv.lib.licenses.gpl2;
    inherit (glib.meta) maintainers platforms;
  };
}
