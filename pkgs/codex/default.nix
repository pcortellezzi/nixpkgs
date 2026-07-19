{ stdenv, lib, fetchurl, makeWrapper, bubblewrap, ripgrep }:

stdenv.mkDerivation rec {
  pname = "codex";
  version = "0.144.6";

  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-package-x86_64-unknown-linux-musl.tar.gz";
    sha256 = "07ff0rxw0dl2ra6wi4215w4jqmv6gqpsp66rxhqcb9ixfkj4iblr";
  };

  codeModeHostSrc = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-code-mode-host-x86_64-unknown-linux-musl.tar.gz";
    sha256 = "14s4q1gy4r9vdd3kckbz778vxs780gq6jvnh169p0697yr1lq41p";
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
