final: prev: {
  kmsvnc = prev.kmsvnc.overrideAttrs (old: {
    src = prev.fetchFromGitHub {
      owner = "pcortellezzi";
      repo = "kmsvnc";
      rev = "add1c34c6fc2110d99503db12ce395095e9b60f7";
      hash = "sha256-XjyTCPbkHgxuQrnLjuUwjKmQg8Pq4Y4rdsvYPWsejWs=";
    };
    version = "${old.version}-embed-cursor";
  });
}
