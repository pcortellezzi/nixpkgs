final: prev: {
  kmsvnc = prev.kmsvnc.overrideAttrs (old: {
    src = prev.fetchFromGitHub {
      owner = "pcortellezzi";
      repo = "kmsvnc";
      rev = "51995012548b68f46a410468ffe81dce4116426c";
      hash = "sha256-T7H0k9hEI92b7ibkYC2ByXJkeXh83Fb/crDPQIjvf5c=";
    };
    version = "${old.version}-embed-cursor";
  });
}
