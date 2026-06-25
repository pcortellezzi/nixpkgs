final: prev: {
  kmsvnc = prev.kmsvnc.overrideAttrs (old: {
    src = prev.fetchFromGitHub {
      owner = "pcortellezzi";
      repo = "kmsvnc";
      rev = "c08bfc58639f8897355f1a469ce44d661773c4d5";
      hash = "sha256-oGhY6+MnfQp//PT6J3kniDyZdBthn6LgXKtxfljbx9k=";
    };
    version = "${old.version}-embed-cursor";
  });
}
