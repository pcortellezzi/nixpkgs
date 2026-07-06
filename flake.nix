{
  description = "Paquets personnels de Philippe";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-26.05";
    atas-x-wine.url = "github:pcortellezzi/atas-x-wine";
    hermes-agent.url = "github:NousResearch/hermes-agent/v2026.7.1";
    hermes-workspace.url = "github:outsourc-e/hermes-workspace/c1e6ed979dcb8dddf79c5b163150c6c23c4dce0c";
  };

  outputs = { self, nixpkgs, atas-x-wine, hermes-agent, hermes-workspace }@inputs:
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
              signon-plugin-oauth2 = callPackage ./pkgs/signon-plugin-oauth2 { signond = f.kdePackages.signond; qtbase = f.kdePackages.qtbase; qttools = f.kdePackages.qttools; };
              atas-x-wine = inputs.atas-x-wine.packages.${f.system}.atas-x-wine;
              hermes-agent = inputs.hermes-agent.packages.${f.system}.default;
              hermes-workspace = inputs.hermes-workspace.packages.${f.system}.default.overrideAttrs (old: {
                pnpmDeps = f.fetchPnpmDeps {
                  inherit (old) pname version src;
                  pnpm = f.pnpm;
                  fetcherVersion = 3;
                  hash = "sha256-vNFqFVLC9oX4i17xTl3Vh/0FJ27o5lyIpStL3rR2z5s=";
                };
              });
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
          opencode-plugins virtual-display-edid signon-plugin-oauth2 atas-x-wine hermes-agent hermes-workspace;
        kmsvnc = pkgs.kmsvnc;
        default = pkgs.buildEnv {
          name = "all-my-packages";
          paths = with pkgs; [
            jdk26 krohnkite motivewave tealstreet
            opencode-voice-models opencode-plugins
            kmsvnc virtual-display-edid signon-plugin-oauth2 atas-x-wine hermes-agent hermes-workspace
          ];
          ignoreCollisions = true;
        };
      };
    };
}
