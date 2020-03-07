{ stdenv, intltool, fetchurl
, pkgconfig, gtk3, glib
, wrapGAppsHook, itstool, libxml2, docbook_xsl
, gnome3, gdk-pixbuf, libxslt, gsettings-desktop-schemas
, enableIntrospection ? stdenv.hostPlatform == stdenv.buildPlatform, gobject-introspection
, enablePython ? stdenv.hostPlatform == stdenv.buildPlatform, python3
 }:

stdenv.mkDerivation rec {
  pname = "glade";
  version = "3.22.1";

  src = fetchurl {
    url = "mirror://gnome/sources/glade/${stdenv.lib.versions.majorMinor version}/${pname}-${version}.tar.xz";
    sha256 = "16p38xavpid51qfy0s26n0n21f9ws1w9k5s65bzh1w7ay8p9my6z";
  };

  configureFlags =
       stdenv.lib.optional (!enablePython) "--disable-python"
    ++ stdenv.lib.optional (!enableIntrospection) "--disable-introspection";

  passthru = {
    updateScript = gnome3.updateScript { packageName = "glade"; attrPath = "gnome3.glade"; };
  };

  nativeBuildInputs = [
    pkgconfig intltool itstool wrapGAppsHook docbook_xsl libxslt libxml2
  ] ++ stdenv.lib.optional enableIntrospection gobject-introspection;
  buildInputs = [
    gtk3 glib libxml2
    gsettings-desktop-schemas
    gdk-pixbuf gnome3.adwaita-icon-theme
  ] ++ stdenv.lib.optionals enablePython [ python3 python3.pkgs.pygobject3 ];

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    homepage = https://wiki.gnome.org/Apps/Glade;
    description = "User interface designer for GTK applications";
    maintainers = gnome3.maintainers;
    license = licenses.lgpl2;
    platforms = platforms.linux;
  };
}
