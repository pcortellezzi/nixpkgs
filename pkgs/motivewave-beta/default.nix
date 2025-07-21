{ stdenv, lib, fetchurl, autoPatchelfHook, dpkg, makeWrapper, coreutils, bc, ffmpeg, gtk2, gtk3, openjdk24, xorg, licenseFile ? null }:


stdenv.mkDerivation rec {
  pname = "motivewave-beta";
  version = "7.0.0B8";
  _build_id = "608";

  src = fetchurl {
    url = "https://downloads.motivewave.com/builds/${_build_id}/motivewave_${version}_amd64.deb";
    sha256 = "1h61hfyhaig9wrba73cg128ii1yhgcsqzvcay2f87w6npsd6g751";
  };

  nativeBuildInputs = [ autoPatchelfHook dpkg makeWrapper ];

  autoPatchelfIgnoreMissingDeps = [
    "libavcodec.so.56"
    "libavformat.so.56"
    "libavcodec.so.57"
    "libavformat.so.57"
    "libavcodec-ffmpeg.so.56"
    "libavformat-ffmpeg.so.56"
    "libavcodec.so.59"
    "libavformat.so.59"
    "libavcodec.so.58"
    "libavformat.so.58"
    "libavcodec.so.54"
    "libavformat.so.54"
    "libavcodec.so.60"
    "libavformat.so.60"
  ];

  buildInputs = [
    bc
    ffmpeg
    gtk2
    gtk3
    openjdk24
    xorg.xrandr
    xorg.libXxf86vm
    xorg.libXtst
  ];

  installPhase = ''
    dpkg-deb -X $src $out

    mv $out/usr/share/motivewave $out/usr/share/$pname
    mv $out/usr/share/applications/motivewave.desktop $out/usr/share/applications/$pname.desktop
    sed -i -e 's/^\(Name=.*\)$/\1 Beta/' \
           -e "s#/motivewave#/$pname#" "$out/usr/share/applications/$pname.desktop"
    sed -i -e "s#^\\(SCRIPTDIR=\\).*#\\1$out/usr/share/$pname#" \
           -e "s#\\.motivewave#.$pname/.motivewave#" \
           -e "s#\\(-DUserHome=\$HOME\\)#\\1/.$pname#" \
	   -e "/-DUserHome/ a COMMAND+=(\"-Duser.home=\$HOME/.$pname\")" \
           -e "s#\\(-Duser.dir=\$HOME\\)#\\1/.$pname#" "$out/usr/share/$pname/run.sh"
    install -Dm644 -t "$out/usr/share/licenses/$pname" "$out/usr/share/$pname/license.html"

    find $out -type d -exec chmod 755 {} +
    find $out -type f -exec chmod 644 {} +

    chmod +x $out/usr/share/$pname/run.sh
    #chmod +x $out/usr/share/$pname/jre/bin/*

    install -d $out/bin
    makeWrapper $out/usr/share/$pname/run.sh $out/bin/$pname --prefix PATH : "${lib.makeBinPath [ coreutils bc openjdk24 ]}" \
      --run "mkdir -p \$HOME/.$pname/.motivewave" \
      ${lib.optionalString (licenseFile != null) ''--run 'sh -c "cat ${licenseFile} > $HOME/.${pname}/.motivewave/mwave_license.txt"' ''}
  '';


  meta = with lib; {
    description = "Advanced trading and charting application.";
    homepage = "https://www.motivewave.com";
    license = licenses.unfree;
    platforms = platforms.linux;
  };
}
