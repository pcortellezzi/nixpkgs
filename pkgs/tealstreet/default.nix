{ appimageTools, lib, fetchurl }:

let
  pname = "tealstreet";
  version = "3.0.12";
  src = fetchurl {
    url = "https://github.com/Tealstreet/tealstreet-v3/releases/download/v${version}/TealstreetV3-${version}.AppImage";
    sha256 = "1rxc6fmi9dzl7p5ayq60pn461z28khd3mf0gdb09j7ad6928xnzj";
  };
  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/tealstreet-v3.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/tealstreet-v3.desktop \
      --replace 'Exec=AppRun' 'Exec=${pname}'
    cp -r ${appimageContents}/usr/share/icons $out/share
  '';

  meta = with lib; {
    description = "Tealstreet Terminal - Professional crypto trading terminal";
    homepage = "https://tealstreet.io/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "tealstreet";
  };
}
