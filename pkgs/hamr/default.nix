{ lib
, stdenv
, fetchFromGitHub
, quickshell
, libqalculate
, makeWrapper
, qt6
, python3
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
  buildInputs = [
    quickshell
    libqalculate
    qt6.qtbase
    qt6.qt5compat
    python3
  ];

  installPhase = ''
    mkdir -p $out/share/quickshell/hamr
    cp -r . $out/share/quickshell/hamr

    mkdir -p $out/bin

    cat > $out/bin/hamr <<EOF
    #!${stdenv.shell}
    export XDG_CONFIG_DIRS="$out/share:\''${XDG_CONFIG_DIRS:-}"
    export PATH="${lib.makeBinPath [ libqalculate python3 ]}:\''${PATH:-}"

    if [ "\$1" = "ipc" ]; then
      exec ${quickshell}/bin/qs --config hamr "\$@"
    else
      exec ${quickshell}/bin/quickshell --config hamr "\$@"
    fi
    EOF

    chmod +x $out/bin/hamr
  '';

  meta = with lib; {
    description = "Extensible launcher for Hyprland/Niri built with Quickshell";
    homepage = "https://github.com/Stewart86/hamr";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "hamr";
  };
}
