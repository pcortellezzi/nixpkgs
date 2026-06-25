final: prev: {
  kmsvnc = prev.kmsvnc.overrideAttrs (old: {
    src = prev.fetchFromGitHub {
      owner = "pcortellezzi";
      repo = "kmsvnc";
      rev = "f741bcdcecefe3d176700ba55a7efb12dde5e842";
      hash = "sha256-TIVQcpVdq7a3KfyFJvtbXHb8tN2QK3TyXX51aq7KX9M=";
    };
    version = "${old.version}-embed-cursor";
  });
}
