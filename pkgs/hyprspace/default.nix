{ lib
, stdenv
, fetchFromGitHub
, hyprland-0_54_3
, hyprutils
, hyprgraphics
, aquamarine
, hyprlang
, hyprcursor
, hyprland-protocols
, wayland-protocols
, pkg-config
, pixman
, libdrm
, pango
, cairo
, libinput
, udev
, wayland
, libxkbcommon
, mesa
, libglvnd
, nix-update-script
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "hyprspace";
  version = "0.1.0+date=2026-04-20";

  src = fetchFromGitHub {
    owner = "pcortellezzi";
    repo = "Hyprspace";
    rev = "921f248ad5f8234e22c42ab0b8a66fd48ed9c9f2";
    hash = "sha256-EKF38I7EC9zb/QjpGCtziry4tygI9eohW93Y5t7G1K4=";
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    hyprland-0_54_3
    hyprutils
    hyprgraphics
    aquamarine
    hyprlang
    hyprcursor
    hyprland-protocols
    wayland-protocols
    pixman
    libdrm
    pango
    cairo
    libinput
    udev
    wayland
    libxkbcommon
    mesa
    libglvnd
  ];

  postPatch = ''
    # Patch the Makefile to add additional include paths for hyprland dependencies
    sed -i 's|INCLUDES = `pkg-config|INCLUDES = -I${libdrm.dev}/include/libdrm -I${hyprland-0_54_3.dev}/include/hyprland/protocols `pkg-config|' Makefile
  '';

  buildPhase = ''
    make all
  '';

  installPhase = ''
    mkdir -p $out/lib
    install -D -m 0755 Hyprspace.so $out/lib/Hyprspace.so
  '';

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    homepage = "https://github.com/pcortellezzi/Hyprspace";
    description = "Hyprland plugin for workspace overview";
    license = licenses.bsd3;
    maintainers = with maintainers; [ pcortellezzi ];
    platforms = platforms.linux;
  };
})
