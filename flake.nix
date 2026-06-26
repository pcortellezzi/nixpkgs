{
  description = "Paquets personnels de Philippe";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-26.05";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      
      # Définition de l'overlay principal
      defaultOverlay = final: prev:
        let
          # Fonction utilitaire pour composer les overlays
          compose = overlays: f: p:
            builtins.foldl' (acc: overlay: 
              let 
                currentFinal = f;
                currentPrev = p // acc;
                newSet = overlay currentFinal currentPrev;
              in acc // newSet
            ) { } overlays;

          # Overlay pour nos paquets personnalisés et overrides de cohérence
          customPkgsOverlay = f: p: 
            let
              callPackage = f.lib.callPackageWith f;
              jdk26 = callPackage ./pkgs/jdk26 { };
            in {
              inherit jdk26;
              motivewave = callPackage ./pkgs/motivewave { pkgsUnstable = f; inherit jdk26; };
              krohnkite = callPackage ./pkgs/krohnkite { };
              tealstreet = callPackage ./pkgs/tealstreet { };
              opencode-voice-models = callPackage ./pkgs/opencode-voice-models { };
              opencode-plugins = callPackage ./pkgs/opencode-plugins { };
              virtual-display-edid = callPackage ./pkgs/virtual-display-edid { };


            };
        in
        compose [
          (import ./overlays/displaylink.nix)
          (import ./overlays/kmsvnc.nix)
          customPkgsOverlay
        ] final prev;

      # Instance de pkgs pour les sorties locales du flake
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ defaultOverlay ];
        config.allowUnfree = true;
      };
    in {
      overlays.default = defaultOverlay;

      packages.${system} = {
        inherit (pkgs)
          jdk26 krohnkite motivewave tealstreet opencode-voice-models
          opencode-plugins virtual-display-edid;
        kmsvnc = pkgs.kmsvnc;
        default = pkgs.buildEnv {
          name = "all-my-packages";
          paths = with pkgs; [
            jdk26 krohnkite motivewave tealstreet
            opencode-voice-models opencode-plugins
            kmsvnc virtual-display-edid
          ];
        };
      };
    };
}
