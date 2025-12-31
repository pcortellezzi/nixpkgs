{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation rec {
  pname = "plasma-panel-colorizer";
  version = "0.5.2";

  src = fetchFromGitHub {
    owner = "luisbocanegra";
    repo = "plasma-panel-colorizer";
    rev = "v${version}";
    hash = "sha256-+JweNB+zjbXh6Htyvu2vgogAr5Fl5wDPCpm6GV18NJ0=";
  };

  installPhase = ''
    mkdir -p $out/share/plasma/plasmoids/luisbocanegra.panel.colorizer
    cp -r $src/* $out/share/plasma/plasmoids/luisbocanegra.panel.colorizer
  '';

  meta = with lib; {
    description = "Plasma 6 Panel Colorizer applet";
    homepage = "https://github.com/luisbocanegra/plasma-panel-colorizer";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
