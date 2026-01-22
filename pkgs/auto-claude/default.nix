{ lib
, appimageTools
, fetchurl
}:

let
  pname = "auto-claude";
  version = "2.7.5";
  src = fetchurl {
    url = "https://github.com/AndyMik90/Auto-Claude/releases/download/v${version}/Auto-Claude-${version}-linux-x86_64.AppImage";
    sha256 = "06n26zbccmv3g7p9kpcm9izwnsylxy10nr9n6h7raf0ia33achzi";
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
