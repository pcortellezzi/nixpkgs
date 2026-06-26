{ stdenv, lib, fetchFromGitLab, qtbase, qttools, signond, pkg-config }:

stdenv.mkDerivation rec {
  pname = "signon-plugin-oauth2";
  version = "0.25";

  src = fetchFromGitLab {
    owner = "nicolasfella";
    repo = "signon-plugin-oauth2";
    rev = "fab698862466994a8fdc9aa335c87b4f05430ce6";
    hash = "sha256-KCBLaqQdBkb6KfVKMmFSLOiXx3rUiEmK41Bc3mi86Ls=";
  };

  dontWrapQtApps = true;

  nativeBuildInputs = [
    qttools
    pkg-config
  ];

  buildInputs = [
    qtbase
    signond
  ];

  configurePhase = ''
    qmake PREFIX=$out LIBDIR=$out/lib SIGNON_PLUGINS_DIR=$out/lib/signon $qmakeFlags
  '';

  meta = with lib; {
    description = "Signon OAuth 1.0 and 2.0 plugin (Qt6 fork)";
    homepage = "https://gitlab.com/nicolasfella/signon-plugin-oauth2";
    license = licenses.lgpl21;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
