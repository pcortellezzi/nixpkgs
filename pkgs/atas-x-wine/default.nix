{ lib, stdenv, fetchFromGitHub, python3, writeText, runCommand, writeShellScriptBin
, makeDesktopItem, pkgsCross, fetchurl, patchelf
, nss, gnutls, vulkan-loader, libGL, freetype, fontconfig, libpng
, zlib, bzip2, brotli, expat, wayland, libdecor, libxkbcommon, libx11, libxext
, pkgsi686Linux, cacert, winetricks
}:

let
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "pcortellezzi";
    repo = "atas-x-wine";
    rev = "ec4a582cdbe0d57ec998d12ac3514919104c941a";
    hash = "sha256-fz2HusNPt3YTZOvc7aNugAJXkIXrWLAv2G+14Upy9Zg=";
  };

  ge-proton-src = fetchurl {
    url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton11-1/GE-Proton11-1.tar.gz";
    hash = "sha256-zm3WY+oBcloxgF7VwWVyOiU83wlFpmQpBzMHQq4t5eQ=";
  };

  patch-wbemprox = writeText "patch-wbemprox.py" ''
import sys
d = open(sys.argv[1],"rb").read()
for o,n in [("Serial number","ATAS-SN-2026X"),("deaddead-dead-dead-dead-deaddeaddead","6F88E200-A973-11EE-8C90-0800200C9A66"),("None","ATAS"),("WINEHDISK","DISK-ATAS"),("Base Board","ATAS-MB-X1"),("VideoController1","NVidiaGeForceRTX"),("VideoProcessor","GeForceRTX4050")]:
    ob=o.encode("utf-16-le"); nb=n.encode("utf-16-le")
    assert len(ob)==len(nb)
    c=d.count(ob)
    if c: d=d.replace(ob,nb); print(f"OK: {o!r} ({c}x)")
    else: print(f"SKIP: {o!r} not found")
open(sys.argv[1],"wb").write(d)
  '';

  ge-proton = stdenv.mkDerivation {
    name = "ge-proton-11-1";
    src = ge-proton-src;
    sourceRoot = "GE-Proton11-1/files";
    nativeBuildInputs = [ python3 ];
    installPhase = ''
      mkdir -p $out
      cp -r * $out/
    '';
    fixupPhase = ''
      for dll in "$out/lib/wine/x86_64-windows/wbemprox.dll" "$out/lib/wine/i386-windows/wbemprox.dll"; do
        [ -f "$dll" ] && python3 ${patch-wbemprox} "$dll"
      done
    '';
  };

  wine-bin = runCommand "wine-wrapper" {
    nativeBuildInputs = [ patchelf ];
  } ''
    cp -r ${ge-proton} $out
    chmod -R u+w $out
    for f in $(find $out -type f); do
      if file -b "$f" 2>/dev/null | grep -q "ELF 64-bit"; then
        patchelf --set-interpreter "${stdenv.cc.bintools.dynamicLinker}" "$f" 2>/dev/null || true
      elif file -b "$f" 2>/dev/null | grep -q "ELF 32-bit"; then
        patchelf --set-interpreter "${pkgsi686Linux.glibc}/lib/ld-linux.so.2" "$f" 2>/dev/null || true
      fi
    done
  '';

  window-hider-hook = pkgsCross.mingwW64.stdenv.mkDerivation {
    name = "window-hider-hook";
    src = src;
    dontUnpack = true;
    buildPhase = ''
      $CXX -shared -static -s -o window_hider_hook.dll $src/window_hider_hook.cpp -luser32
    '';
    installPhase = ''
      mkdir -p $out/lib
      cp window_hider_hook.dll $out/lib/
    '';
  };

  atas-launcher = pkgsCross.mingwW64.stdenv.mkDerivation {
    name = "atas-launcher";
    src = src;
    dontUnpack = true;
    buildPhase = ''
      $CXX -static -s -o atas_launcher.exe $src/atas_launcher.cpp
    '';
    installPhase = ''
      mkdir -p $out/bin
      cp atas_launcher.exe $out/bin/
    '';
  };

  # Read and substitute the scripts from the source repo
  substituteScript = name: file: writeShellScriptBin name (builtins.replaceStrings [
    "@wineBin@" "@winetricks@" "@nss@" "@gnutls@" "@vulkanLoader@"
    "@libGL@" "@freetype@" "@fontconfig@" "@libpng@" "@zlib@"
    "@bzip2@" "@brotli@" "@expat@" "@wayland@" "@libdecor@"
    "@libxkbcommon@" "@libX11@" "@libXext@"
    "@pkgsi686Freetype@" "@pkgsi686Fontconfig@" "@pkgsi686Libpng@"
    "@pkgsi686Zlib@" "@pkgsi686Bzip2@" "@pkgsi686Brotli@"
    "@pkgsi686Expat@" "@pkgsi686Wayland@" "@pkgsi686Libdecor@"
    "@pkgsi686Libxkbcommon@" "@pkgsi686Libx11@" "@pkgsi686Libxext@"
    "@cacert@" "@windowHiderHook@" "@atasLauncher@"
  ] [
    "${wine-bin}" "${winetricks}" "${nss.out}" "${gnutls.out}" "${vulkan-loader}"
    "${libGL}" "${freetype}" "${fontconfig.lib}" "${libpng}" "${zlib}"
    "${bzip2.out}" "${brotli.lib}" "${expat}" "${wayland}" "${libdecor}"
    "${libxkbcommon}" "${libx11}" "${libxext}"
    "${pkgsi686Linux.freetype}" "${pkgsi686Linux.fontconfig.lib}" "${pkgsi686Linux.libpng}"
    "${pkgsi686Linux.zlib}" "${pkgsi686Linux.bzip2.out}" "${pkgsi686Linux.brotli.lib}"
    "${pkgsi686Linux.expat}" "${pkgsi686Linux.wayland}" "${pkgsi686Linux.libdecor}"
    "${pkgsi686Linux.libxkbcommon}" "${pkgsi686Linux.libx11}" "${pkgsi686Linux.libxext}"
    "${cacert.unbundled}" "${window-hider-hook}" "${atas-launcher}"
  ] (builtins.readFile file));

  desktopItemAtas = makeDesktopItem {
    name = "atas";
    exec = "atas";
    icon = "atas";
    desktopName = "ATAS X";
    comment = "ATAS X trading platform (Wine/Proton)";
    categories = [ "Finance" ];
    terminal = false;
  };

  desktopItemAtasUpdater = makeDesktopItem {
    name = "atas-updater";
    exec = "atas-updater";
    icon = "atas";
    desktopName = "ATAS X Updater";
    comment = "Update ATAS X trading platform";
    categories = [ "Finance" ];
    terminal = true;
  };
in
runCommand "atas-x-wine-${version}" {
  inherit desktopItemAtas desktopItemAtasUpdater;
  meta = with lib; {
    description = "ATAS X trading platform compatibility layer for Linux/Wine";
    homepage = "https://github.com/pcortellezzi/atas-x-wine";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "atas";
  };
} ''
  mkdir -p $out/bin $out/lib $out/share/applications $out/share/icons/hicolor/48x48/apps $out/share/icons/hicolor/128x128/apps

  cp ${window-hider-hook}/lib/window_hider_hook.dll $out/lib/
  cp ${atas-launcher}/bin/atas_launcher.exe $out/bin/

  cp ${substituteScript "atas" "${src}/atas.sh"}/bin/atas $out/bin/atas
  cp ${substituteScript "atas-updater" "${src}/atas-updater.sh"}/bin/atas-updater $out/bin/atas-updater

  chmod +x $out/bin/atas $out/bin/atas-updater

  cp ${src}/icon.png $out/share/icons/hicolor/48x48/apps/atas.png
  cp ${src}/icon-128.png $out/share/icons/hicolor/128x128/apps/atas.png

  cp ${desktopItemAtas}/share/applications/*.desktop $out/share/applications/
  cp ${desktopItemAtasUpdater}/share/applications/*.desktop $out/share/applications/
''
