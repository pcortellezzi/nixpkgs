{ lib, stdenvNoCC, fetchurl }:

stdenvNoCC.mkDerivation rec {
  pname = "opencode-voice-models";
  version = "0.1.4";

  srcs = [
    (fetchurl {
      name = "ggml-large-v3-turbo-q5_0.bin";
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin";
      sha256 = "1qm7zxamlvac564c3270wqqqks5wc7532q3fqi01zbfmkiq22hir";
    })
    (fetchurl {
      name = "en_US-ryan-high.onnx";
      url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/high/en_US-ryan-high.onnx";
      sha256 = "1jjf2nxn1zyih00jwh8c3bg65wblf1ha8w5spy6yr0z10rv0v6dk";
    })
    (fetchurl {
      name = "en_US-ryan-high.onnx.json";
      url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/high/en_US-ryan-high.onnx.json";
      sha256 = "04c0ni1qb8jw7p6l1fb47i81njgzqh7xaj8dpyzb8p1i127vkly6";
    })
  ];

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/share/opencode-voice/whisper
    mkdir -p $out/share/opencode-voice/piper

    cp ${builtins.elemAt srcs 0} $out/share/opencode-voice/whisper/ggml-large-v3-turbo-q5_0.bin
    cp ${builtins.elemAt srcs 1} $out/share/opencode-voice/piper/en_US-ryan-high.onnx
    cp ${builtins.elemAt srcs 2} $out/share/opencode-voice/piper/en_US-ryan-high.onnx.json
  '';

  meta = with lib; {
    description = "Voice models for opencode-voice plugin (whisper + piper)";
    homepage = "https://github.com/renjfk/opencode-voice";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
