{ stdenv, lib, fetchurl, makeWrapper, bubblewrap, ripgrep }:

stdenv.mkDerivation rec {
  pname = "codex";
  version = "0.144.5";

  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-package-x86_64-unknown-linux-musl.tar.gz";
    sha256 = "sha256-I6cCKkk8VATFDGKkrVZVg2rb7gGdk8cxFJVNja/yAFM=";
  };

  codeModeHostSrc = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-code-mode-host-x86_64-unknown-linux-musl.tar.gz";
    sha256 = "sha256-8nySwT0S6P9x9f72g5TTDE24CcJLMufyUcoq1q62oJA=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontUnpack = true;
  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    tar xzf $src -C $out
    chmod +x $out/bin/codex $out/bin/codex-code-mode-host 2>/dev/null || true

    # Extract code-mode-host binary and rename to standard name
    mkdir -p $out/bin
    tar xzf $codeModeHostSrc -C $out/bin
    mv $out/bin/codex-code-mode-host-x86_64-unknown-linux-musl $out/bin/codex-code-mode-host 2>/dev/null || true
    chmod +x $out/bin/codex-code-mode-host 2>/dev/null || true

    wrapProgram $out/bin/codex \
      --prefix PATH : ${lib.makeBinPath [ bubblewrap ripgrep ]}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Lightweight coding agent that runs in your terminal";
    homepage = "https://github.com/openai/codex";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "codex";
  };
}
