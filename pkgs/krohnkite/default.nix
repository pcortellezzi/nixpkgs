{
  lib,
  stdenv,
  fetchurl,
  kdePackages,
}:

stdenv.mkDerivation rec {
  pname = "krohnkite";
  version = "0.9.9.2";

  src = fetchurl {
    url = "https://codeberg.org/anametologin/Krohnkite/releases/download/${version}/krohnkite.kwinscript";
    sha256 = "0zngiyd6xazw4b0q07ydvi6cnz2ilcfkhq68bx5wfrnk65jzdxs2";
  };

  nativeBuildInputs = with kdePackages; [
    kpackage
  ];

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/share/kwin/scripts
    kpackagetool6 -i $src --packageroot $out/share/kwin/scripts
  '';

  meta = with lib; {
    description = "Dynamic tiling extension for KWin";
    homepage = "https://codeberg.org/anametologin/Krohnkite";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}