{ lib
, stdenv
, fetchurl
, bun
, makeWrapper
}:

let
  pname = "oh-my-opencode";
  version = "3.14.0";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://registry.npmjs.org/oh-my-opencode/-/oh-my-opencode-${version}.tgz";
    hash = "sha256-341xbFmHZDFVEIfbDPis5BUItHrK3ufqa96hVWl6Uro=";
  };

  nativeBuildInputs = [ makeWrapper ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/oh-my-opencode
    cp -r package/dist $out/lib/oh-my-opencode/
    cp package/package.json $out/lib/oh-my-opencode/

    mkdir -p $out/bin
    makeWrapper ${bun}/bin/bun $out/bin/oh-my-opencode \
      --add-flags "run $out/lib/oh-my-opencode/dist/cli/index.js"

    runHook postInstall
  '';

  meta = with lib; {
    description = "AI agent harness - Batteries-Included OpenCode Plugin with Multi-Model Orchestration";
    homepage = "https://github.com/code-yeongyu/oh-my-openagent";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "oh-my-opencode";
  };
}
