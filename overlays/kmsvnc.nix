final: prev: {
  kmsvnc = prev.kmsvnc.overrideAttrs (old: {
    src = prev.fetchFromGitHub {
      owner = "pcortellezzi";
      repo = "kmsvnc";
      rev = "59727d6384367574dcd32d1f398685691e060a66";
      hash = "sha256-ujwTcUYghdAf8izg6wc7K0alyjX3shmAnk1pfg/n7H4=";
    };
    version = "${old.version}-embed-cursor";
  });
}
