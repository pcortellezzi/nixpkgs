{ buildNpmPackage, lib }:

buildNpmPackage rec {
  pname = "opencode-plugins";
  version = "1.0.0";
  src = ./.;

  npmDepsHash = "sha256-VJzvtAz+ro+hhYHbpM1ZImmN9bJdg9lSx/Lrktagf+4=";
  makeCacheWritable = true;
  npmFlags = [ "--ignore-scripts" ];
  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib
    cp -r node_modules $out/lib/
    runHook postInstall
  '';

  meta = with lib; {
    description = "Meta-package bundling opencode npm plugins (snippets, snip, notify, mem, etc.)";
    homepage = "https://github.com/pcortellezzi/nixpkgs";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
