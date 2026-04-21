{
  description = "Paquets personnels de Philippe";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    hyprland.url = "github:hyprwm/Hyprland/v0.54.3";
  };

  outputs = { self, nixpkgs, hyprland }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      # Create base nixpkgs with hyprland overlay
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          hyprland.overlays.hyprland-packages
          (import ./overlays/aquamarine-evdi.nix)
          (import ./overlays/displaylink.nix)
          (final: prev:
            let
              # callPackage for our custom packages
              callPackage = prev.lib.callPackageWith prev;

              # Build our custom packages
              packageDirs = builtins.readDir ./pkgs;
              
              # First build jdk26 (needed by motivewave)
              jdk26 = callPackage ./pkgs/jdk26 { };

              # Then build other packages (except motivewave and jdk26 which is already built)
              packagesNames = builtins.attrNames (prev.lib.filterAttrs (name: type: name != "motivewave" && name != "jdk26" && type == "directory") packageDirs);
              packagesWithout = builtins.listToAttrs (map (name: {
                name = name;
                value = callPackage (./pkgs + "/${name}") { };
              }) packagesNames);

            in
              # Finally build motivewave with jdk26 passed explicitly
              packagesWithout // {
                inherit jdk26;
                motivewave = callPackage ./pkgs/motivewave {
                  pkgsUnstable = prev;
                  jdk26 = jdk26;
                };
              }
          )
        ];
        config.allowUnfree = true;
      };

    in
    {
      overlays.default = final: prev: {
        # Expose patched packages
        inherit (pkgs) aquamarine displaylink;
        # Expose our custom packages
        inherit (pkgs)
          hyprland hyprspace
          jdk26 plasma-panel-colorizer plasma-window-title-applet krohnkite motivewave;
      };

      packages.${system} = {
        inherit (pkgs)
          hyprland hyprspace
          jdk26 plasma-panel-colorizer plasma-window-title-applet krohnkite motivewave;

        default = pkgs.buildEnv {
          name = "all-my-packages";
          paths = with pkgs; [
            hyprland hyprspace
            jdk26 plasma-panel-colorizer plasma-window-title-applet krohnkite motivewave
          ];
        };
      };
    };
}
