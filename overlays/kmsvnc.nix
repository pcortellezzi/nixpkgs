final: prev: {
  kmsvnc = prev.kmsvnc.overrideAttrs (old: {
    src = prev.fetchFromGitHub {
      owner = "pcortellezzi";
      repo = "kmsvnc";
      rev = "789da2a0106880c21f87aad09f66fb5ec556c995";
      hash = "sha256-hi9lwGiMadvf+r/7MZdc7DxYXo6f/G4XylkXuponW30=";
    };
    version = "${old.version}-embed-cursor";
  });
}
