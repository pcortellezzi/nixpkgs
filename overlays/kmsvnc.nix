final: prev: {
  kmsvnc = prev.kmsvnc.overrideAttrs (old: {
    src = prev.fetchFromGitHub {
      owner = "pcortellezzi";
      repo = "kmsvnc";
      rev = "feature/embed-cursor";
      hash = "sha256-lm5zf0tj0qPooYv13EaPpR2KEQSSSpp9L00hwya1wrI=";
    };
    version = "${old.version}-embed-cursor";
  });
}
