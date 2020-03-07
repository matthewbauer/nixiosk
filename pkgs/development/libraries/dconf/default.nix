{ stdenv, fetchurl, meson, ninja, python3, libxslt, pkgconfig, glib, bash-completion, dbus, gnome3
, libxml2, docbook_xsl, docbook_xml_dtd_42, fetchpatch
, enableVapi ? stdenv.hostPlatform == stdenv.buildPlatform, vala
, enableDoc ? stdenv.hostPlatform == stdenv.buildPlatform, gtk-doc }:

let
  pname = "dconf";
in
stdenv.mkDerivation rec {
  name = "${pname}-${version}";
  version = "0.34.0";

  src = fetchurl {
    url = "mirror://gnome/sources/${pname}/${stdenv.lib.versions.majorMinor version}/${name}.tar.xz";
    sha256 = "0lnsl85cp2vpzgp8pkf6l6yd2i3lp02jdvga1icfa78j2smr8fll";
  };

  patches = [
    # Fix build with Meson 0.52
    (fetchpatch {
      url = "https://gitlab.gnome.org/GNOME/dconf/commit/cc32667c5d7d9ff95e65cc21f59905d8f9218394.patch";
      sha256 = "02gfadn34bg818a7vb3crhsiahskiflcvx9l6iqwf1v269q93mr8";
    })
  ];

  postPatch = ''
    chmod +x meson_post_install.py tests/test-dconf.py
    patchShebangs meson_post_install.py
    patchShebangs tests/test-dconf.py
  '';

  outputs = [ "out" "lib" "dev" ] ++ stdenv.lib.optional enableDoc "devdoc";

  nativeBuildInputs = [ meson ninja pkgconfig python3 libxslt libxml2 glib docbook_xsl docbook_xml_dtd_42 ]
    ++ stdenv.lib.optional enableVapi vala
    ++ stdenv.lib.optional enableDoc gtk-doc;
  buildInputs = [ glib bash-completion dbus ];

  mesonFlags = [
    "--sysconfdir=/etc"
    "-Dgtk_doc=${if enableDoc then "true" else "false"}"
  ] ++ stdenv.lib.optional (!enableVapi) "-Dvapi=false";

  doCheck = !stdenv.isAarch32 && !stdenv.isAarch64 && !stdenv.isDarwin;

  passthru = {
    updateScript = gnome3.updateScript {
      packageName = pname;
      attrPath = "gnome3.${pname}";
    };
  };

  meta = with stdenv.lib; {
    homepage = https://wiki.gnome.org/Projects/dconf;
    license = licenses.lgpl21Plus;
    platforms = platforms.linux ++ platforms.darwin;
    maintainers = gnome3.maintainers;
  };
}
