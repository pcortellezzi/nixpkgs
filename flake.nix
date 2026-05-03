{
  description = "Paquets personnels de Philippe";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    hyprland.url = "github:hyprwm/Hyprland/v0.54.3";
  };

  outputs = { self, nixpkgs, hyprland }:
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
              plasma-panel-colorizer = callPackage ./pkgs/plasma-panel-colorizer { };
              plasma-window-title-applet = callPackage ./pkgs/plasma-window-title-applet { };
              krohnkite = callPackage ./pkgs/krohnkite { };
              tealstreet = callPackage ./pkgs/tealstreet { };
              opencode-voice-models = callPackage ./pkgs/opencode-voice-models { };

              # Force hyprland à utiliser l'aquamarine patché (défini par l'overlay précédent)
              hyprland = p.hyprland.override {
                aquamarine = f.aquamarine;
              };
              
              # Force hyprspace à utiliser le hyprland et l'aquamarine patchés
              hyprspace = callPackage ./pkgs/hyprspace {
                hyprland = f.hyprland;
                aquamarine = f.aquamarine;
              };
            };
        in
        compose [
          hyprland.overlays.hyprland-packages
          (import ./overlays/aquamarine-evdi.nix)
          (import ./overlays/displaylink.nix)
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
          hyprland hyprspace
          jdk26 plasma-panel-colorizer plasma-window-title-applet krohnkite motivewave tealstreet opencode-voice-models;

        default = pkgs.buildEnv {
          name = "all-my-packages";
          paths = with pkgs; [
            hyprland hyprspace
            jdk26 plasma-panel-colorizer plasma-window-title-applet krohnkite motivewave tealstreet opencode-voice-models
          ];
        };
      };
    };
}
