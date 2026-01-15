{ lib
, appimageTools
, fetchurl
}:

let
  pname = "auto-claude";
  version = "2.7.4";
  src = fetchurl {
    url = "https://github.com/AndyMik90/Auto-Claude/releases/download/v${version}/Auto-Claude-${version}-linux-x86_64.AppImage";
    sha256 = "16xsc7mh69qpy26f4580zyh9szgaidzm612r25g9mqgs9dcbrapi";
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs = pkgs: with pkgs; [
    libsecret
    libnotify
    udev
  ];

  meta = with lib; {
    description = "Auto-Claude - An automated Claude client";
    homepage = "https://github.com/AndyMik90/Auto-Claude";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "auto-claude";
  };
}
