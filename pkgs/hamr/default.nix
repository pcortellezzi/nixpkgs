{ lib
, stdenv
, fetchFromGitHub
, quickshell
, libqalculate
, makeWrapper
, qt6
}:

stdenv.mkDerivation rec {
  pname = "hamr";
  version = "0.11.0";

  src = fetchFromGitHub {
    owner = "Stewart86";
    repo = "hamr";
    rev = "v${version}";
    hash = "sha256-cFja12s46pia3pmnrJn1LPDEKK9ovERda6K2cn+Ijcc=";
  };

  nativeBuildInputs = [ makeWrapper qt6.wrapQtAppsHook ];
  buildInputs = [ quickshell libqalculate qt6.qtbase ];

  installPhase = ''
    mkdir -p $out/share/hamr
    cp -r . $out/share/hamr

    mkdir -p $out/bin
    makeWrapper ${quickshell}/bin/quickshell $out/bin/hamr \
      --add-flags "-p $out/share/hamr/shell.qml" \
      --prefix PATH : ${lib.makeBinPath [ libqalculate ]}
  '';

  meta = with lib; {
    description = "Extensible launcher for Hyprland/Niri built with Quickshell";
    homepage = "https://github.com/Stewart86/hamr";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "hamr";
  };
}
