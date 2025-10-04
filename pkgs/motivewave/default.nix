{ stdenv, lib, fetchurl, autoPatchelfHook, dpkg, makeWrapper, coreutils, bc, ffmpeg, gtk2, gtk3, openjdk24, xorg, licenseFile ? null }:


stdenv.mkDerivation rec {
  pname = "motivewave";
  version = "7.0.1";
  _build_id = "615";

  src = fetchurl {
    url = "https://downloads.motivewave.com/builds/${_build_id}/motivewave_${version}_amd64.deb";
    sha256 = "fc672408c92aa02176df8a8c28b2ea3fad2af48c792d7cf0ce8daf29c41abc67";
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

    mkdir -p $out/share/applications
    mv $out/usr/share/applications/motivewave.desktop $out/share/applications/$pname.desktop
    sed -i -e "s#^Exec=.*#Exec=$out/bin/$pname#" \
           -e "s#^Icon=.*#Icon=$pname#" "$out/share/applications/$pname.desktop"
    sed -i -e "s#^\(SCRIPTDIR=\).*#\1$out/usr/share/$pname#"  "$out/usr/share/$pname/run.sh"
    install -Dm644 -t "$out/usr/share/licenses/$pname" "$out/usr/share/$pname/license.html"

    install -Dm644 "$out/usr/share/$pname/icons/mwave_256x256.png" \
                   "$out/share/icons/hicolor/256x256/apps/$pname.png"

    find $out -type d -exec chmod 755 {} +
    find $out -type f -exec chmod 644 {} +

    chmod +x $out/usr/share/$pname/run.sh
    #chmod +x $out/usr/share/$pname/jre/bin/*

    install -d $out/bin
    makeWrapper $out/usr/share/$pname/run.sh $out/bin/$pname --prefix PATH : "${lib.makeBinPath [ coreutils bc openjdk24 ]}" \
      --run "mkdir -p \$HOME/.$pname" \
      ${lib.optionalString (licenseFile != null) ''--run 'sh -c "cat ${licenseFile} > $HOME/.${pname}/mwave_license.txt"' ''}
  '';


  meta = with lib; {
    description = "Advanced trading and charting application.";
    homepage = "https://www.motivewave.com";
    license = licenses.unfree;
    platforms = platforms.linux;
  };
}
