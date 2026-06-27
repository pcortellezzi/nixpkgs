{ lib, stdenv, fetchFromGitHub, python3, writeText, runCommandNoCC
, makeDesktopItem, pkgsCross, fetchurl, patchelf
, nss, gnutls, vulkan-loader, libGL, freetype, fontconfig, libpng
, zlib, bzip2, brotli, expat, wayland, libdecor, libxkbcommon, xorg
, pkgsi686Linux, cacert, winetricks
}:

let
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "pcortellezzi";
    repo = "atas-x-wine";
    rev = "2e1e7e30f1f1c21d80df46c6f81a49b24617890f";
    hash = "sha256-RfnT5C5eLcPpkXfDzi0ELahcLUrzNsQGHdnYtUz+1VI=";
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

  wine-bin = runCommandNoCC "wine-wrapper" {
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

  runtimeLibs = lib.makeLibraryPath [
    nss gnutls vulkan-loader libGL freetype fontconfig libpng zlib
    bzip2 brotli expat wayland libdecor libxkbcommon xorg.libX11
    xorg.libXext pkgsi686Linux.freetype pkgsi686Linux.fontconfig
    pkgsi686Linux.libpng pkgsi686Linux.zlib pkgsi686Linux.bzip2
    pkgsi686Linux.brotli pkgsi686Linux.expat pkgsi686Linux.wayland
    pkgsi686Linux.libdecor pkgsi686Linux.libxkbcommon
    pkgsi686Linux.libx11 pkgsi686Linux.libxext
  ];

  wineLibPath = lib.concatStringsSep ":" [
    "${wine-bin}/lib/x86_64-linux-gnu"
    "${wine-bin}/lib"
    "${wine-bin}/lib/wine/x86_64-unix"
    "${wine-bin}/lib/wine/i386-unix"
    "/run/opengl-driver/lib"
    "/run/opengl-driver-32/lib"
  ];

  desktopItemAtas = makeDesktopItem {
    name = "atas";
    exec = "atas";
    desktopName = "ATAS X";
    comment = "ATAS X trading platform (Wine/Proton)";
    categories = [ "Finance" ];
    terminal = false;
  };

  desktopItemAtasUpdater = makeDesktopItem {
    name = "atas-updater";
    exec = "atas-updater";
    desktopName = "ATAS X Updater";
    comment = "Update ATAS X trading platform";
    categories = [ "Finance" ];
    terminal = true;
  };
in
runCommandNoCC "atas-x-wine-${version}" {
  inherit wine-bin window-hider-hook atas-launcher winetricks
    desktopItemAtas desktopItemAtasUpdater stdenv runtimeLibs wineLibPath cacert;
  meta = with lib; {
    description = "ATAS X trading platform compatibility layer for Linux/Wine";
    homepage = "https://github.com/pcortellezzi/atas-x-wine";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "atas";
  };
} ''
mkdir -p $out/bin $out/lib $out/share/applications

cp ${window-hider-hook}/lib/window_hider_hook.dll $out/lib/
cp ${atas-launcher}/bin/atas_launcher.exe $out/bin/

cat > $out/bin/atas << 'ATASEOF'
#!${stdenv.shell}
set -e
export WINEPREFIX="''${WINEPREFIX:-$HOME/.local/share/wineprefixes/atas}"
export WINEARCH=win64
export WINEDEBUG="''${WINEDEBUG:--all}"
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
export DISPLAY="''${DISPLAY:-:0}"
export WINE_WAYLAND_DISPLAY="''${WINE_WAYLAND_DISPLAY:-''${WAYLAND_DISPLAY}}"
export XAUTHORITY="''${XAUTHORITY}"
export PATH="${wine-bin}/bin:${winetricks}/bin:$PATH"
export LD_LIBRARY_PATH="${runtimeLibs}:${wineLibPath}"
export SSL_CERT_DIR="${cacert.unbundled}/etc/ssl/certs"
export VK_ICD_FILENAMES="/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json"
export VK_DRIVER_FILES="/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json"
export __NV_PRIME_RENDER_OFFLOAD=0
export __GLX_VENDOR_LIBRARY_NAME=mesa
export AVALONIA_RENDERER=vulkan WINEFSYNC=1 WINEESYNC=1
export WINEDLLOVERRIDES="mscoree=b;mshtml=b;wmiutils=b;wbemprox=b;uiautomationcore=d;oleacc=d;dwrite=b"
export WINE_X11_NO_MITSHM=1
export DXVK_CONFIG="dxgi.maxDeviceMemory=0;dxvk.allowMemoryOvercommit=True;dxgi.syncInterval=0;dxgi.numBackBuffers=3;dxvk.enableAsync=True;dxgi.nvapiHack=False;dxvk.numCompilerThreads=0;dxgi.enableDummyCompositionSwapchain=True"
export ANGLE_DEFAULT_PLATFORM=d3d11
export DOTNET_SYSTEM_GLOBALIZATION_USENLS=1
GUID="6F88E200-A973-11EE-8C90-0800200C9A66"

if [ ! -d "$WINEPREFIX" ] || [ "$1" = "--install" ]; then
  echo "=== Installation ATAS ==="
  pkill -9 -f "wineserver|winedevice|explorer.exe|services.exe|rpcss.exe" || true
  wineserver -k || true
  rm -rf "$WINEPREFIX"/* "$WINEPREFIX"/.[!.]* 2>/dev/null || true
  mkdir -p "$WINEPREFIX"
  echo "[1/4] wine prefix..."
  wine wineboot -i 2>&1 | grep -v fixme | tail -3
  for f in libvkd3d-1.dll libvkd3d-shader-1.dll libvkd3d-utils-1.dll; do
    [ -f "$WINEPREFIX/drive_c/windows/system32/$f" ] || cp "${wine-bin}/share/default_pfx/drive_c/windows/system32/$f" "$WINEPREFIX/drive_c/windows/system32/" 2>/dev/null || true
  done
  echo "[2/4] prerequisites..."
  winetricks -q vcrun2022 dotnetdesktop8 winhttp d3dcompiler_47 corefonts 2>&1 | grep -v fixme | tail -5
  cat << 'REGEOF' > "$WINEPREFIX/wmi_com_fix.reg"
Windows Registry Editor Version 5.00
[HKEY_CLASSES_ROOT\CLSID\{CF4CC405-E2C5-4DDD-B3CE-5E7582D8C9FA}]
@="WbemDefPath"
[HKEY_CLASSES_ROOT\CLSID\{CF4CC405-E2C5-4DDD-B3CE-5E7582D8C9FA}\InprocServer32]
@="C:\\windows\\system32\\wbem\\wmiutils.dll"
"ThreadingModel"="Both"
[HKEY_LOCAL_MACHINE\Software\Classes\CLSID\{CF4CC405-E2C5-4DDD-B3CE-5E7582D8C9FA}]
@="WbemDefPath"
[HKEY_LOCAL_MACHINE\Software\Classes\CLSID\{CF4CC405-E2C5-4DDD-B3CE-5E7582D8C9FA}\InprocServer32]
@="C:\\windows\\system32\\wbem\\wmiutils.dll"
"ThreadingModel"="Both"
REGEOF
  echo "[3/4] HWID spoofing..."
  wine regedit /C "$WINEPREFIX/wmi_com_fix.reg" 2>&1 | grep -v fixme || true
  for kv in "HKLM\\HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0 /v ProcessorId /t REG_SZ /d BFEBFBFF000B0671" \
            "HKLM\\HARDWARE\\DEVICEMAP\\Scsi\\Scsi Port 0\\Scsi Bus 0\\Target Id 0\\Logical Unit Id 0 /v Identifier /t REG_SZ /d DISK-ATAS-SD-512GB"; do
    wine reg add $kv /f >/dev/null 2>&1 || true
  done
  if [ -f "$2" ]; then
    echo "[4/4] installer..."
    timeout 900 wine "$2" 2>&1 | grep -v fixme | tail -5 || true
  fi
  echo "=== Install complete ==="
  exit 0
fi

for d in system32 syswow64; do
  for dll in d3d11.dll dxgi.dll d3d9.dll d3d10core.dll dxvk_config.dll; do
    rm -f "$WINEPREFIX/drive_c/windows/$d/$dll" 2>/dev/null || true
  done
  for dll in libvkd3d-1.dll libvkd3d-shader-1.dll libvkd3d-utils-1.dll; do
    [ -f "$WINEPREFIX/drive_c/windows/$d/$dll" ] || cp "${wine-bin}/share/default_pfx/drive_c/windows/$d/$dll" "$WINEPREFIX/drive_c/windows/$d/" 2>/dev/null || true
  done
done

wine reg add "HKLM\\System\\CurrentControlSet\\Control\\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 36 /f >/dev/null 2>&1
wine reg add "HKLM\\Software\\Microsoft\\Cryptography" /v MachineGuid /t REG_SZ /d "$GUID" /f >/dev/null 2>&1
wine reg add "HKLM\\HARDWARE\\Description\\System\\BIOS" /v BIOSSerialNumber /t REG_SZ /d "ATAS-SN-2026-X11" /f >/dev/null 2>&1
wine reg add "HKLM\\HARDWARE\\Description\\System\\BIOS" /v BaseBoardSerialNumber /t REG_SZ /d "MB-ATAS-998877" /f >/dev/null 2>&1
wine reg add "HKCU\\Software\\Wine\\Drivers" /v Graphics /t REG_SZ /d "wayland,x11" /f >/dev/null 2>&1
wine reg delete "HKCU\\Software\\Wine\\Explorer" /v Desktop /f >/dev/null 2>&1 || true
wine reg delete "HKCU\\Software\\Wine\\Explorer\\Desktops" /f >/dev/null 2>&1 || true

if [ "$1" = "--command" ]; then shift; exec wine "$@"; fi
if [ "$1" = "--trace" ]; then export WINEDEBUG="+winsock,+ws2_32,+iphlpapi,+winhttp,+secur32,+crypt,+module"; fi

wine net start winmgmt 2>/dev/null || true
EXE_PATH=$(find "$WINEPREFIX/drive_c/Program Files" -name "OFT.PlatformX.exe" 2>/dev/null | head -n 1)
[ -z "$EXE_PATH" ] && EXE_PATH=$(find "$WINEPREFIX/drive_c/Program Files" -name "OFT.Platform.exe" 2>/dev/null | head -n 1)
[ -z "$EXE_PATH" ] && EXE_PATH=$(find "$WINEPREFIX/drive_c" -name "ATAS*" 2>/dev/null | head -n 1)
if [ -n "$EXE_PATH" ]; then
  cp -f "$out/lib/window_hider_hook.dll" "$WINEPREFIX/drive_c/window_hider_hook.dll"
  cp -f "$out/bin/atas_launcher.exe" "$WINEPREFIX/drive_c/atas_launcher.exe"
  wine C:\\atas_launcher.exe "$@"
else
  echo "ATAS not found"
fi
ATASEOF

cat > $out/bin/atas-updater << 'UPDEOF'
#!${stdenv.shell}
set -e
export WINEPREFIX="''${WINEPREFIX:-$HOME/.local/share/wineprefixes/atas}"
export WINEARCH=win64
export WINEDEBUG="-all"
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
export DISPLAY="''${DISPLAY:-:0}"
export WAYLAND_DISPLAY="" WINE_WAYLAND_DISPLAY=""
export XAUTHORITY="''${XAUTHORITY}"
export PATH="${wine-bin}/bin:${winetricks}/bin:$PATH"
export LD_LIBRARY_PATH="${runtimeLibs}:${wineLibPath}"
export SSL_CERT_DIR="${cacert.unbundled}/etc/ssl/certs"
export WINEDLLOVERRIDES="mscoree=b;dwrite=b;gdiplus=b"
EXE_PATH=$(find "$WINEPREFIX/drive_c/Program Files" -name "OFT.Platform.Updater.exe" 2>/dev/null | head -n 1)
[ -z "$EXE_PATH" ] && EXE_PATH=$(find "$WINEPREFIX/drive_c" -name "OFT.Platform.Updater.exe" 2>/dev/null | head -n 1)
[ -n "$EXE_PATH" ] && exec wine "$EXE_PATH" "$@" || echo "Updater not found"
UPDEOF

chmod +x $out/bin/atas $out/bin/atas-updater

cp ${desktopItemAtas}/share/applications/*.desktop $out/share/applications/
cp ${desktopItemAtasUpdater}/share/applications/*.desktop $out/share/applications/
''
