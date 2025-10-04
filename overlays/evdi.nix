final: prev: {
  linuxPackages_latest = prev.lib.recursiveUpdate prev.linuxPackages_latest {
    evdi = prev.linuxPackages_latest.evdi.overrideAttrs (oldAttrs: {
      version = "1.14.11";
      src = oldAttrs.src.override {
        tag = "v1.14.11";
        hash = "sha256-SxYUhu76vwgCQgjOYVpvdWsFpNcyzuSjZe3x/v566VU=";
      };
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ prev.pkg-config ];
      postPatch = ''
        sed -i '/\/etc\/os-release/d' module/Makefile
      '';
      kernel = final.linuxPackages_latest.kernel;
    });
  };
}
