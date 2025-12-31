{ lib
, stdenv
, fetchFromGitHub
, quickshell
, libqalculate
, makeWrapper
, qt6
, python3
, wl-clipboard
, cliphist
, fd
, fzf
, xdg-utils
, libnotify
, libpulseaudio
, jq
, gnome-desktop
, gtk3
, gobject-introspection
, wrapGAppsHook3
}:

let
  pythonEnv = python3.withPackages (ps: with ps; [
    click
    loguru
    tqdm
    pygobject3
  ]);
in
stdenv.mkDerivation rec {
  pname = "hamr";
  version = "0.11.0";

  src = fetchFromGitHub {
    owner = "Stewart86";
    repo = "hamr";
    rev = "v${version}";
    hash = "sha256-cFja12s46pia3pmnrJn1LPDEKK9ovERda6K2cn+Ijcc=";
  };

  nativeBuildInputs = [
    makeWrapper
    qt6.wrapQtAppsHook
    gobject-introspection
    wrapGAppsHook3
  ];

  buildInputs = [
    quickshell
    libqalculate
    qt6.qtbase
    qt6.qt5compat
    qt6.qtsvg
    pythonEnv
    gnome-desktop
    gtk3
    libpulseaudio
  ];

  installPhase = ''
    mkdir -p $out/etc/xdg/quickshell/hamr
    cp -r . $out/etc/xdg/quickshell/hamr

    mkdir -p $out/bin

    # We use a custom script but leverage wrapGAppsHook3's variables
    cat > $out/bin/hamr <<EOF
    #!${stdenv.shell}
    
    # Dependencies path
    export PATH="${lib.makeBinPath [
      libqalculate
      pythonEnv
      wl-clipboard
      cliphist
      fd
      fzf
      xdg-utils
      libnotify
      jq
    ]}:\''${PATH:-}"
    
    # Quickshell config discovery
    export XDG_CONFIG_DIRS="$out/etc/xdg:\''${XDG_CONFIG_DIRS:-}"
    
    # Qt modules (QML and Plugins)
    export QML2_IMPORT_PATH="${qt6.qt5compat}/${qt6.qtbase.qtQmlPrefix}:\''${QML2_IMPORT_PATH:-}"
    export QT_PLUGIN_PATH="${qt6.qtsvg}/${qt6.qtbase.qtPluginPrefix}:\''${QT_PLUGIN_PATH:-}"

    # GObject Introspection paths (handled by wrapGAppsHook3 logic usually, but explicit here for safety in custom script)
    export GI_TYPELIB_PATH="$GI_TYPELIB_PATH:\''${GI_TYPELIB_PATH:-}"

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
