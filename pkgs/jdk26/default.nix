{ stdenv, lib, fetchurl, autoPatchelfHook, alsa-lib, freetype, fontconfig, cups, zlib
, libx11, libxext, libxi, libxrender, libxtst
}:

stdenv.mkDerivation rec {
  pname = "adoptium-temurin-jdk";
  version = "26+35";

  src = fetchurl {
    url = "https://github.com/adoptium/temurin26-binaries/releases/download/jdk-26%2B35/OpenJDK26U-jdk_x64_linux_hotspot_26_35.tar.gz";
    sha256 = "68e19ba53b7f1f74635c13f809e5db36cebccf3ae9e752423dd92d2ad7d831ef";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib zlib libx11 libxext libxi libxrender libxtst alsa-lib freetype fontconfig cups ];

  dontStrip = true;

  installPhase = ''
    mkdir -p $out
    cp -r * $out/
  '';

  meta = with lib; {
    description = "Adoptium Temurin JDK 26";
    homepage = "https://adoptium.net/";
    license = licenses.gpl2Plus;
    platforms = [ "x86_64-linux" ];
  };
}
