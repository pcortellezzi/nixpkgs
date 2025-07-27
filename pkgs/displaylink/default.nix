# overlays/default.nix
(
  final: prev: {
    # Surcharge la fonction displaylink pour utiliser notre version locale.
    displaylink = prev.displaylink.overrideAttrs (oldAttrs: {
      src = prev.fetchurl {
        url = "https://www.synaptics.com/sites/default/files/exe_files/2024-10/DisplayLink%20USB%20Graphics%20Software%20for%20Ubuntu6.1-EXE.zip";
        hash = "sha256-RJgVrX+Y8Nvz106Xh+W9N9uRLC2VO00fBJeS8vs7fKw=";
      };
    });
  }
)
